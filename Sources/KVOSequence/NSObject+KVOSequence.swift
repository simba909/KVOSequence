import Foundation

public extension NSObject {
    /// An `AsyncSequence` that produces a new element whenever the observed value changes.
    struct KeyValueSequence<Subject, Value> where Subject: NSObject, Value: Sendable {
        // This is @unchecked Sendable since KeyPath isn't marked as Sendable but
        // _probably_ should be.
        public enum KeyPathType: @unchecked Sendable {
            case `static`(KeyPath<Subject, Value>)
            case stringy(String)
        }

        public let subject: Subject
        public let keyPath: KeyPathType
        public let options: NSKeyValueObservingOptions

        public init(subject: Subject, keyPath: KeyPathType, options: NSKeyValueObservingOptions) {
            self.subject = subject
            self.keyPath = keyPath
            self.options = options
        }
    }
}

public extension NSObjectProtocol {
    func sequence<Value>(
        for keyPath: KeyPath<Self, Value>,
        options: NSKeyValueObservingOptions = [.initial, .new]
    ) -> NSObject.KeyValueSequence<Self, Value> {
        NSObject.KeyValueSequence(subject: self, keyPath: .static(keyPath), options: options)
    }

    func sequence<Value>(
        of value: Value.Type = Value.self,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions = [.initial, .new]
    ) -> NSObject.KeyValueSequence<Self, Value> {
        NSObject.KeyValueSequence(subject: self, keyPath: .stringy(keyPath), options: options)
    }
}

// MARK: - AsyncSequence

extension NSObject.KeyValueSequence: AsyncSequence {
    public struct Element {
        public var newValue: Value?
        public var oldValue: Value?
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        var storage: Storage<Subject, Value>

        public func next() async -> Element? {
            await storage.next()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        let storage = Storage(subject: subject, keyPath: keyPath, options: options)
        return AsyncIterator(storage: storage)
    }
}

// MARK: - Sendable

extension NSObject.KeyValueSequence: Sendable where Subject: Sendable, Value: Sendable {}

@available(*, unavailable)
extension NSObject.KeyValueSequence.AsyncIterator: Sendable {}
