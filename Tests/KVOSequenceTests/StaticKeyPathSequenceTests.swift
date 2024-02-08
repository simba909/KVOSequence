import XCTest

@testable import KVOSequence

final class StaticKeyPathSequenceTests: XCTestCase {
    var person: Person!

    override func setUpWithError() throws {
        try super.setUpWithError()

        person = Person()
    }

    func testProducesValues() async throws {
        let sequence = person.sequence(for: \.name)
        let iterator = sequence.makeAsyncIterator()

        person.name = "Hika"
        var element = await iterator.next()
        XCTAssertEqual(element, "Hika")

        person.name = "Mai"
        element = await iterator.next()
        XCTAssertEqual(element, "Mai")

        person.name = nil
        element = await iterator.next()

        // Unfortunate, but double optional is messy...
        if case let value?? = element {
            XCTFail("Expected newValue to be nil, but was: \(value)")
        }
    }
}
