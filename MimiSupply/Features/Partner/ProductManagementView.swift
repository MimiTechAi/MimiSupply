import SwiftUI
import PhotosUI

struct ProductManagementView: View {
    @StateObject private var viewModel = ProductManagementViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddProduct = false
    @State private var searchText = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Search products...")
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                
                // Product List
                if viewModel.isLoading && viewModel.products.isEmpty {
                    AppLoadingView(message: "Loading products...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredProducts.isEmpty {
                    EmptyStateView(
                        icon: "square.grid.2x2",
                        title: searchText.isEmpty ? "No Products" : "No Results",
                        message: searchText.isEmpty ? "Add your first product to get started" : "Try adjusting your search"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(viewModel.filteredProducts) { product in
                            ProductManagementRow(
                                product: product,
                                onEdit: { viewModel.editProduct(product) },
                                onToggleAvailability: { viewModel.toggleProductAvailability(product) },
                                onDelete: { viewModel.deleteProduct(product) }
                            )
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Manage Products")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add product")
                }
            }
            .refreshable {
                await viewModel.refresh()
            }
            .sheet(isPresented: $showingAddProduct) {
                AddEditProductView(mode: .add) { product in
                    await viewModel.addProduct(product)
                }
            }
            .sheet(item: $viewModel.editingProduct) { product in
                AddEditProductView(mode: .edit(product)) { updatedProduct in
                    await viewModel.updateProduct(updatedProduct)
                }
            }
        }
        .task {
            await viewModel.loadProducts()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
    }
}

// MARK: - Product Management Row
struct ProductManagementRow: View {
    let product: Product
    let onEdit: () -> Void
    let onToggleAvailability: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Product Image
            AsyncImage(url: product.imageURLs.first) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray200)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray400)
                    )
            }
            .frame(width: 60, height: 60)
            .cornerRadius(8)
            
            // Product Info
            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                    .foregroundColor(.graphite)
                    .lineLimit(1)
                
                Text(product.category.displayName)
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
                
                HStack {
                    Text(formatCurrency(product.priceCents))
                        .font(.bodyMedium)
                        .fontWeight(.semibold)
                        .foregroundColor(.graphite)
                    
                    if let originalPrice = product.originalPriceCents,
                       originalPrice > product.priceCents {
                        Text(formatCurrency(originalPrice))
                            .font(.bodySmall)
                            .foregroundColor(.gray500)
                            .strikethrough()
                    }
                    
                    Spacer()
                    
                    // Availability Badge
                    Text(product.isAvailable ? "Available" : "Unavailable")
                        .font(.labelSmall)
                        .foregroundColor(product.isAvailable ? .success : .error)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            (product.isAvailable ? Color.success : Color.error)
                                .opacity(0.1)
                        )
                        .cornerRadius(4)
                }
            }
            
            // Action Menu
            Menu {
                Button("Edit") {
                    onEdit()
                }
                
                Button(product.isAvailable ? "Mark Unavailable" : "Mark Available") {
                    onToggleAvailability()
                }
                
                Divider()
                
                Button("Delete", role: .destructive) {
                    showingDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundColor(.gray600)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(.vertical, 8)
        .alert("Delete Product", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete \(product.name)? This action cannot be undone.")
        }
    }
    
    private func formatCurrency(_ cents: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: Double(cents) / 100.0)) ?? "$0.00"
    }
}

// MARK: - Add/Edit Product View
struct AddEditProductView: View {
    enum Mode {
        case add
        case edit(Product)
        
        var title: String {
            switch self {
            case .add: return "Add Product"
            case .edit: return "Edit Product"
            }
        }
    }
    
    let mode: Mode
    let onSave: (Product) async -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var price = ""
    @State private var originalPrice = ""
    @State private var category: ProductCategory = .food
    @State private var isAvailable = true
    @State private var stockQuantity = ""
    @State private var selectedImages: [PhotosPickerItem] = []
    @State private var imageURLs: [URL] = []
    @State private var isSaving = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Product Name", text: $name)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                    
                    Picker("Category", selection: $category) {
                        ForEach(ProductCategory.allCases, id: \.self) { category in
                            Text(category.displayName).tag(category)
                        }
                    }
                }
                
                Section("Pricing") {
                    HStack {
                        Text("$")
                        TextField("0.00", text: $price)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Original Price $")
                        TextField("0.00", text: $originalPrice)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Availability") {
                    Toggle("Available for Order", isOn: $isAvailable)
                    
                    HStack {
                        Text("Stock Quantity")
                        Spacer()
                        TextField("Optional", text: $stockQuantity)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Images") {
                    PhotosPicker(
                        selection: $selectedImages,
                        maxSelectionCount: 5,
                        matching: .images
                    ) {
                        Label("Select Images", systemImage: "photo.on.rectangle.angled")
                    }
                    
                    if !imageURLs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(imageURLs, id: \.self) { url in
                                    AsyncImage(url: url) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray200)
                                    }
                                    .frame(width: 80, height: 80)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                }
            }
            .navigationTitle(mode.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveProduct()
                        }
                    }
                    .disabled(name.isEmpty || price.isEmpty || isSaving)
                }
            }
        }
        .onAppear {
            setupForMode()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func setupForMode() {
        switch mode {
        case .add:
            break // Already initialized with defaults
        case .edit(let product):
            name = product.name
            description = product.description
            price = String(format: "%.2f", Double(product.priceCents) / 100.0)
            if let originalPriceCents = product.originalPriceCents {
                originalPrice = String(format: "%.2f", Double(originalPriceCents) / 100.0)
            }
            category = product.category
            isAvailable = product.isAvailable
            if let stock = product.stockQuantity {
                stockQuantity = String(stock)
            }
            imageURLs = product.imageURLs
        }
    }
    
    private func saveProduct() async {
        isSaving = true
        
        do {
            let priceCents = Int((Double(price) ?? 0) * 100)
            let originalPriceCents = originalPrice.isEmpty ? nil : Int((Double(originalPrice) ?? 0) * 100)
            let stock = stockQuantity.isEmpty ? nil : Int(stockQuantity)
            
            let product = Product(
                id: (mode.isEdit ? mode.editingProduct?.id : nil) ?? UUID().uuidString,
                partnerId: "", // Will be set by the service
                name: name,
                description: description,
                priceCents: priceCents,
                originalPriceCents: originalPriceCents,
                category: category,
                imageURLs: imageURLs,
                isAvailable: isAvailable,
                stockQuantity: stock,
                nutritionInfo: nil,
                allergens: [],
                tags: [],
                weight: nil,
                dimensions: nil,
                createdAt: Date(),
                updatedAt: Date()
            )
            
            await onSave(product)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isSaving = false
    }
}

// MARK: - Extensions
extension AddEditProductView.Mode {
    var isEdit: Bool {
        switch self {
        case .add: return false
        case .edit: return true
        }
    }
    
    var editingProduct: Product? {
        switch self {
        case .add: return nil
        case .edit(let product): return product
        }
    }
}

// ProductCategory displayName is already defined in Product.swift

#Preview {
    ProductManagementView()
}