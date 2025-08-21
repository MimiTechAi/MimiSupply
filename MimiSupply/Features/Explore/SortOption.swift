import Foundation

enum SortOption: String, CaseIterable, Identifiable {
    case recommended
    case rating
    case deliveryTime
    case distance

    var id: String { self.rawValue }

    var displayName: String {
        switch self {
        case .recommended:
            return "Recommended"
        case .rating:
            return "Rating"
        case .deliveryTime:
            return "Delivery Time"
        case .distance:
            return "Distance"
        }
    }
}