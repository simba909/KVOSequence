import Foundation

public extension NSObject {
    /// An `AsyncSequence` that produces a new element whenever the observed value changes.
    struct KeyValueSequence<Subject, Value> where Subject: NSObject {
        public enum KeyPathType {
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
        options: NSKeyValueObservingOptions = []
    ) -> NSObject.KeyValueSequence<Self, Value> {
        NSObject.KeyValueSequence(subject: self, keyPath: .static(keyPath), options: options)
    }

    func sequence<Value>(
        of value: Value.Type = Value.self,
        forKeyPath keyPath: String,
        options: NSKeyValueObservingOptions = []
    ) -> NSObject.KeyValueSequence<Self, Value> {
        NSObject.KeyValueSequence(subject: self, keyPath: .stringy(keyPath), options: options)
    }
}

// MARK: - AsyncSequence

extension NSObject.KeyValueSequence: AsyncSequence {
    public struct Element {
        var newValue: Value?
        var oldValue: Value?
    }

    final public class AsyncIterator: AsyncIteratorProtocol {
        private let subject: Subject
        private let keyPath: KeyPathType
        private let options: NSKeyValueObservingOptions

        private let stateMachine: ManagedCriticalState<StateMachine<Element>>

        init(subject: Subject, keyPath: KeyPathType, options: NSKeyValueObservingOptions) {
            self.subject = subject
            self.keyPath = keyPath
            self.options = options

            self.stateMachine = ManagedCriticalState(StateMachine())

            setupObservation()
        }

        public func next() async -> Element? {
            return await withTaskCancellationHandler {
                let action = self.stateMachine.withCriticalRegion { stateMachine in
                    stateMachine.next()
                }

                switch action {
                case .returnValue(let value):
                    return value
                case .none:
                    break
                }

                return await withUnsafeContinuation { continuation in
                    let action = self.stateMachine.withCriticalRegion { stateMachine in
                        stateMachine.nextSuspended(continuation)
                    }

                    switch action {
                    case .resumeConsumer(let value):
                        continuation.resume(returning: value)
                    case .none:
                        break
                    }
                }
            } onCancel: {
                let action = self.stateMachine.withCriticalRegion { stateMachine in
                    stateMachine.finish()
                }

                switch action {
                case .resumeConsumer(let consumer):
                    consumer.resume(returning: nil)
                case .none:
                    break
                }
            }
        }

        private func setupObservation() {
            let token: AnyObject

            switch keyPath {
            case .static(let keyPath):
                token = subject.observe(
                    keyPath,
                    options: options,
                    changeHandler: { [weak self] _, change in
                        let element = Element(
                            newValue: change.newValue,
                            oldValue: change.oldValue
                        )
                        self?.elementProduced(element)
                    }
                )
            case .stringy(let keyPath):
                token = StringyObserver<Subject, Value>(
                    subject: subject,
                    keyPath: keyPath,
                    options: options,
                    changeHandler: { [weak self] change in
                        let element = Element(
                            newValue: change.newValue,
                            oldValue: change.oldValue
                        )
                        self?.elementProduced(element)
                    }
                )
            }

            stateMachine.withCriticalRegion { stateMachine in
                stateMachine.observationCreated(token)
            }
        }

        private func elementProduced(_ element: Element) {
            let action = stateMachine.withCriticalRegion { stateMachine in
                stateMachine.valueProduced(element)
            }

            switch action {
            case .resumeContinuation(let continuation):
                continuation.resume(returning: element)
            case .none:
                break
            }
        }
    }

    public func makeAsyncIterator() -> AsyncIterator {
        AsyncIterator(subject: subject, keyPath: keyPath, options: options)
    }
}
