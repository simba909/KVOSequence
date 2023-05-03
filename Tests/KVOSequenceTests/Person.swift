import Foundation

class Person: NSObject {
    @objc dynamic var name: String?

    init(name: String? = nil) {
        self.name = name
    }
}
