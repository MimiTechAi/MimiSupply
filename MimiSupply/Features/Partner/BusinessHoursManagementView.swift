import SwiftUI

struct BusinessHoursManagementView: View {
    @StateObject private var viewModel = BusinessHoursViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Open for Business", isOn: $viewModel.isCurrentlyOpen)
                        .onChange(of: viewModel.isCurrentlyOpen) { _, newValue in
                            viewModel.toggleBusinessStatus(newValue)
                        }
                } header: {
                    Text("Current Status")
                } footer: {
                    Text(viewModel.isCurrentlyOpen ? "Your business is currently accepting orders" : "Your business is currently closed to new orders")
                }
                
                Section("Weekly Schedule") {
                    ForEach(WeekDay.allCases, id: \.self) { day in
                        BusinessHourRow(
                            day: day,
                            hours: viewModel.businessHours[day] ?? OpeningHours.closed,
                            onUpdate: { hours in
                                viewModel.updateHours(for: day, hours: hours)
                            }
                        )
                    }
                }
                
                Section("Special Hours") {
                    Button("Add Holiday Hours") {
                        viewModel.showingHolidayHours = true
                    }
                    
                    ForEach(viewModel.specialHours) { specialHour in
                        SpecialHourRow(
                            specialHour: specialHour,
                            onDelete: { viewModel.deleteSpecialHour(specialHour) }
                        )
                    }
                }
                
                Section("Delivery Settings") {
                    HStack {
                        Text("Preparation Time")
                        Spacer()
                        Picker("", selection: $viewModel.preparationTime) {
                            ForEach(5...60, id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Delivery Radius")
                        Spacer()
                        Picker("", selection: $viewModel.deliveryRadius) {
                            ForEach([1, 2, 3, 5, 10], id: \.self) { km in
                                Text("\(km) km").tag(Double(km))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Minimum Order")
                        Spacer()
                        TextField("$0.00", value: $viewModel.minimumOrderAmount, format: .currency(code: "USD"))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .navigationTitle("Business Hours")
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
                            await viewModel.saveChanges()
                            dismiss()
                        }
                    }
                    .disabled(viewModel.isSaving)
                }
            }
            .sheet(isPresented: $viewModel.showingHolidayHours) {
                AddSpecialHoursView { specialHour in
                    viewModel.addSpecialHour(specialHour)
                }
            }
        }
        .task {
            await viewModel.loadBusinessHours()
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}

// MARK: - Business Hour Row
struct BusinessHourRow: View {
    let day: WeekDay
    let hours: OpeningHours
    let onUpdate: (OpeningHours) -> Void
    
    @State private var isOpen: Bool
    @State private var openTime: Date
    @State private var closeTime: Date
    
    init(day: WeekDay, hours: OpeningHours, onUpdate: @escaping (OpeningHours) -> Void) {
        self.day = day
        self.hours = hours
        self.onUpdate = onUpdate
        
        if !hours.isOpen {
            self._isOpen = State(initialValue: false)
            self._openTime = State(initialValue: Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date())
            self._closeTime = State(initialValue: Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date())
        } else {
            self._isOpen = State(initialValue: true)
            
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            
            let openTime = hours.openTime.flatMap { formatter.date(from: $0) } ?? Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
            let closeTime = hours.closeTime.flatMap { formatter.date(from: $0) } ?? Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
            
            self._openTime = State(initialValue: openTime)
            self._closeTime = State(initialValue: closeTime)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(day.displayName)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                
                Spacer()
                
                Toggle("", isOn: $isOpen)
                    .onChange(of: isOpen) { _, newValue in
                        updateHours()
                    }
            }
            
            if isOpen {
                HStack {
                    DatePicker("Open", selection: $openTime, displayedComponents: .hourAndMinute)
                        .onChange(of: openTime) { _, _ in
                            updateHours()
                        }
                    
                    Text("to")
                        .foregroundColor(.gray600)
                    
                    DatePicker("Close", selection: $closeTime, displayedComponents: .hourAndMinute)
                        .onChange(of: closeTime) { _, _ in
                            updateHours()
                        }
                }
                .font(.bodySmall)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func updateHours() {
        let newHours: OpeningHours = isOpen ? OpeningHours.open(openTime, closeTime) : OpeningHours.closed
        onUpdate(newHours)
    }
}

// MARK: - Special Hour Row
struct SpecialHourRow: View {
    let specialHour: SpecialHour
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(specialHour.name)
                    .font(.bodyMedium)
                    .fontWeight(.medium)
                
                Text(formatDateRange(specialHour.startDate, specialHour.endDate))
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
                
                Text(specialHour.hours.displayText)
                    .font(.bodySmall)
                    .foregroundColor(.gray600)
            }
            
            Spacer()
            
            Button("Delete") {
                onDelete()
            }
            .foregroundColor(.error)
            .font(.bodySmall)
        }
    }
    
    private func formatDateRange(_ start: Date, _ end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        
        if Calendar.current.isDate(start, inSameDayAs: end) {
            return formatter.string(from: start)
        } else {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }
}

// MARK: - Add Special Hours View
struct AddSpecialHoursView: View {
    let onSave: (SpecialHour) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var startDate = Date()
    @State private var endDate = Date()
    @State private var isOpen = true
    @State private var openTime = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var closeTime = Calendar.current.date(bySettingHour: 17, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Holiday Information") {
                    TextField("Holiday Name", text: $name)
                    
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    
                    DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Hours") {
                    Toggle("Open on this day", isOn: $isOpen)
                    
                    if isOpen {
                        DatePicker("Open Time", selection: $openTime, displayedComponents: .hourAndMinute)
                        
                        DatePicker("Close Time", selection: $closeTime, displayedComponents: .hourAndMinute)
                    }
                }
            }
            .navigationTitle("Add Special Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        let hours: OpeningHours = isOpen ? OpeningHours.open(openTime, closeTime) : OpeningHours.closed
                        let specialHour = SpecialHour(
                            id: UUID().uuidString,
                            name: name,
                            startDate: startDate,
                            endDate: endDate,
                            hours: hours
                        )
                        onSave(specialHour)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

// MARK: - Supporting Types
// WeekDay enum is defined in Partner.swift

// Using existing OpeningHours model from Partner.swift
extension OpeningHours {
    static let closed = OpeningHours(isOpen: false)
    
    static func open(_ openTime: Date, _ closeTime: Date) -> OpeningHours {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return OpeningHours(
            isOpen: true,
            openTime: formatter.string(from: openTime),
            closeTime: formatter.string(from: closeTime)
        )
    }
    
    // displayText is already defined in Partner.OpeningHours
}

struct SpecialHour: Identifiable, Codable {
    let id: String
    let name: String
    let startDate: Date
    let endDate: Date
    let hours: OpeningHours
}

#Preview {
    BusinessHoursManagementView()
}