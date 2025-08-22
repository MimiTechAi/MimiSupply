import Foundation

struct LocalNotification {
    let title: String
    let body: String
    let timeInterval: TimeInterval
    let userInfo: [String: Any]?
}