import Foundation

public extension NSObject {
    /// An `AsyncSequence` that produces a new element whenever the observed value on the subject changes.
    struct KeyValueSequence<Subject, Value> where Subject: NSObject, Value: Sendable {
        public let subject: Subject
        public let keyPath: KeyPath<Subject, Value>
        public let options: NSKeyValueObservingOptions

        public init(
            subject: Subject,
            keyPath: KeyPath<Subject, Value>,
            options: NSKeyValueObservingOptions
        ) {
            self.subject = subject
            self.keyPath = keyPath
            self.options = options
        }
    }

    /// An `AsyncSequence` that produces a new element whenever the observed value on the subject changes.
    struct StringyKeyValueSequence<Subject, Value> where Subject: NSObject, Value: Sendable {
        public let subject: Subject
        public let keyPath: String
        public let options: NSKeyValueObservingOptions

        public init(subject: Subject, keyPath: String, options: NSKeyValueObservingOptions) {
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
        NSObject.KeyValueSequence(subject: self, keyPath: keyPath, options: options)
    }

    func sequence<Value>(
        of value: Value.Type = Value.self,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions = [.initial, .new]
    ) -> NSObject.StringyKeyValueSequence<Self, Value> {
        NSObject.StringyKeyValueSequence(subject: self, keyPath: keyPath, options: options)
    }
}

// MARK: - AsyncSequence

extension NSObject.KeyValueSequence: AsyncSequence {
    public typealias Element = Value

    public struct AsyncIterator: AsyncIteratorProtocol {
        var storage: KeyPathStorage<Subject, Value>

        public func next() async -> Value? {
            await storage.next()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        let storage = KeyPathStorage<Subject, Value>(
            subject: subject,
            keyPath: keyPath,
            options: options
        )
        return AsyncIterator(storage: storage)
    }
}

extension NSObject.StringyKeyValueSequence: AsyncSequence {
    public struct Element {
        public var newValue: Value?
        public var oldValue: Value?
    }

    public struct AsyncIterator: AsyncIteratorProtocol {
        var storage: StringyKeyPathStorage<Subject, Value>

        public func next() async -> Element? {
            await storage.next()
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        let storage = StringyKeyPathStorage<Subject, Value>(
            subject: subject,
            keyPath: keyPath,
            options: options
        )
        return AsyncIterator(storage: storage)
    }
}

// MARK: - Sendable

extension NSObject.KeyValueSequence: @unchecked Sendable where Subject: Sendable, Value: Sendable {}

extension NSObject.StringyKeyValueSequence: Sendable where Subject: Sendable, Value: Sendable {}

@available(*, unavailable)
extension NSObject.KeyValueSequence.AsyncIterator: Sendable {}

@available(*, unavailable)
extension NSObject.StringyKeyValueSequence.AsyncIterator: Sendable {}
