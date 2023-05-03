import XCTest

@testable import KVOSequence

final class StringyObserverTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()

        defaults = UserDefaults(suiteName: #file)
        defaults.removePersistentDomain(forName: #file)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        let defaultsFilename = "\(#file).plist"
        if FileManager.default.fileExists(atPath: defaultsFilename) {
            try FileManager.default.removeItem(atPath: defaultsFilename)
        }
    }

    func testReceivesChanges() throws {
        var change: StringyObserver<UserDefaults, [String: Any]>.ObservedChange?
        let observer = StringyObserver<UserDefaults, [String: Any]>(
            subject: defaults,
            keyPath: "user",
            options: [.old, .new],
            changeHandler: { change = $0 }
        )

        // Ensure that the observer isn't deallocated before all assertions are done
        withExtendedLifetime(observer) {
            // Alice
            defaults.set(["name": "Alice", "age": 23] as [String: Any], forKey: "user")
            XCTAssertEqual(change?.newValue?["name"] as? String, "Alice")
            XCTAssertNil(change?.oldValue)

            // Remove object
            defaults.removeObject(forKey: "user")
            XCTAssertEqual(change?.oldValue?["name"] as? String, "Alice")
            XCTAssertNil(change?.newValue)
        }
    }
}
