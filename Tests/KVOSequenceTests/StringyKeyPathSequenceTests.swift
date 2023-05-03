import XCTest

@testable import KVOSequence

final class StringyKeyPathSequenceTests: XCTestCase {
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

    func testProducesValues() async throws {
        let sequence = defaults.sequence(
            of: [String: Any].self,
            forKeyPath: "user",
            options: [.new]
        )
        let iterator = sequence.makeAsyncIterator()

        defaults.set(["name": "Alice", "age": 23] as [String: Any], forKey: "user")
        var element = await iterator.next()
        var value = try XCTUnwrap(element?.newValue)
        XCTAssertEqual(value["name"] as? String, "Alice")
        XCTAssertEqual(value["age"] as? Int, 23)

        defaults.set(["name": "Bob"] as [String: Any], forKey: "user")
        element = await iterator.next()
        value = try XCTUnwrap(element?.newValue)
        XCTAssertEqual(value["name"] as? String, "Bob")

        defaults.set(["name": "Charlie", "age": 42] as [String: Any], forKey: "user")
        element = await iterator.next()
        value = try XCTUnwrap(element?.newValue)
        XCTAssertEqual(value["name"] as? String, "Charlie")
        XCTAssertEqual(value["age"] as? Int, 42)

        defaults.removeObject(forKey: "user")
        element = await iterator.next()
        let unwrappedElement = try XCTUnwrap(element)
        XCTAssertNil(unwrappedElement.newValue)
    }

    func testIncludesOldAndNewValues() async throws {
        let sequence = defaults.sequence(
            of: [String: Any].self,
            forKeyPath: "user",
            options: [.old, .new]
        )
        let iterator = sequence.makeAsyncIterator()

        // The second set will overwrite the first, but the first should still get included
        // as the "old" value
        defaults.set(["name": "Alice"], forKey: "user")
        defaults.set(["name": "Bob"], forKey: "user")

        let element = await iterator.next()
        XCTAssertEqual(element?.oldValue?["name"] as? String, "Alice")
        XCTAssertEqual(element?.newValue?["name"] as? String, "Bob")
    }
}
