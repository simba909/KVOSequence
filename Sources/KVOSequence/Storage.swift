import Foundation

final class KeyPathStorage<Subject, Value>: @unchecked Sendable where Subject: NSObject, Value: Sendable {
    typealias Element = Value

    private let subject: Subject
    private let stateMachine: ManagedCriticalState<StateMachine<Subject, Element>>

    init(subject: Subject, keyPath: KeyPath<Subject, Value>, options: NSKeyValueObservingOptions) {
        self.subject = subject
        self.stateMachine = ManagedCriticalState(StateMachine())

        // In order not to miss KVO events, set up the underlying observation immediately.
        // Any events received before the first call to next() will be buffered using
        // the state machine.
        setupObservation(on: keyPath, options: options)
    }

    func next() async -> Element? {
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

    private func setupObservation(
        on keyPath: KeyPath<Subject, Value>,
        options: NSKeyValueObservingOptions
    ) {
        let token = subject.observe(
            keyPath,
            options: options,
            changeHandler: { [weak self] (_, change: NSKeyValueObservedChange<Value>) in
                if let value = change.newValue {
                    self?.elementProduced(value)
                }
            }
        )

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

final class StringyKeyPathStorage<Subject, Value>: @unchecked Sendable where Subject: NSObject, Value: Sendable {
    typealias Element = NSObject.StringyKeyValueSequence<Subject, Value>.Element

    private let subject: Subject
    private let stateMachine: ManagedCriticalState<StateMachine<Subject, Element>>

    init(subject: Subject, keyPath: String, options: NSKeyValueObservingOptions) {
        self.subject = subject
        self.stateMachine = ManagedCriticalState(StateMachine())

        // In order not to miss KVO events, set up the underlying observation immediately.
        // Any events received before the first call to next() will be buffered using
        // the state machine.
        setupObservation(on: keyPath, options: options)
    }

    func next() async -> Element? {
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

    private func setupObservation(on keyPath: String, options: NSKeyValueObservingOptions) {
        let token = StringyObserver<Subject, Value>(
            subject: subject,
            keyPath: keyPath,
            options: options,
            changeHandler: { [weak self] change in
                let element = Element(newValue: change.newValue, oldValue: change.oldValue)
                self?.elementProduced(element)
            }
        )

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
