import XCTest

@testable import KVOSequence

final class StaticKeyPathSequenceTests: XCTestCase {
    var person: Person!

    override func setUpWithError() throws {
        try super.setUpWithError()

        person = Person()
    }

    func testProducesValues() async throws {
        let sequence = person.sequence(for: \.name, options: [.old, .new])
        let iterator = sequence.makeAsyncIterator()

        person.name = "Hika"
        var element = await iterator.next()
        XCTAssertEqual(element?.newValue, "Hika")

        person.name = "Mai"
        element = await iterator.next()
        XCTAssertEqual(element?.newValue, "Mai")
        XCTAssertEqual(element?.oldValue, "Hika")

        person.name = nil
        element = await iterator.next()

        // Unfortunate, but double optional is messy...
        if case let value?? = element?.newValue {
            XCTFail("Expected newValue to be nil, but was: \(value)")
        }

        XCTAssertEqual(element?.oldValue, "Mai")
    }
}
