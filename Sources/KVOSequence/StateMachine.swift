import DequeModule

struct StateMachine<Value> {
    typealias ObservationToken = AnyObject
    typealias SuspendedConsumer = UnsafeContinuation<Value?, Never>

    enum State {
        case awaitingObservation(Deque<Value?>)
        case buffering(Deque<Value?>, SuspendedConsumer?, ObservationToken)
        case finished
    }

    private var state: State = .awaitingObservation([])

    enum NextAction {
        case returnValue(Value?)
    }

    mutating func next() -> NextAction? {
        switch state {
        case .awaitingObservation:
            preconditionFailure("Invalid state: next() called before observation was set up")
        case .buffering(let buffer, let consumer, _) where buffer.isEmpty:
            precondition(consumer == nil, "Invalid state. There is already a suspended consumer.")
            return nil
        case .buffering(var buffer, let consumer, let observation):
            precondition(consumer == nil, "Invalid state. There is already a suspended consumer.")
            let value = buffer.popFirst()!
            state = .buffering(buffer, consumer, observation)
            return .returnValue(value)
        case .finished:
            return .returnValue(nil)
        }
    }

    mutating func observationCreated(_ observation: ObservationToken) {
        switch state {
        case .awaitingObservation(let buffer):
            state = .buffering(buffer, nil, observation)
        case .buffering, .finished:
            preconditionFailure("Unexpectedly received an observation")
        }
    }

    enum NextSuspendedAction {
        case resumeConsumer(Value?)
    }

    mutating func nextSuspended(_ consumer: SuspendedConsumer) -> NextSuspendedAction? {
        switch state {
        case .awaitingObservation:
            preconditionFailure("Unexpected state transition")
        case .buffering(let buffer, let suspendedConsumer, let observation) where buffer.isEmpty:
            precondition(
                suspendedConsumer == nil,
                "Invalid states. There is already a suspended consumer."
            )
            state = .buffering(buffer, consumer, observation)
            return nil
        case .buffering(var buffer, let suspendedConsumer, let observation):
            precondition(
                suspendedConsumer == nil,
                "Invalid states. There is already a suspended consumer."
            )
            let value = buffer.popFirst()!
            state = .buffering(buffer, nil, observation)
            return .resumeConsumer(value)
        case .finished:
            return .resumeConsumer(nil)
        }
    }

    enum ValueProducedAction {
        case resumeContinuation(SuspendedConsumer)
    }

    mutating func valueProduced(_ value: Value?) -> ValueProducedAction? {
        switch state {
        case .awaitingObservation:
            // Before there is an observation, only keep the latest value around to avoid overflow
            // and unexpected initial values.
            state = .awaitingObservation([value])
            return nil
        case .buffering(_, .none, let observation):
            // Before there is a consumer, only keep the latest value around to avoid overflow
            // and unexpected initial values.
            state = .buffering([value], nil, observation)
            return nil
        case .buffering(let buffer, .some(let consumer), let observation):
            precondition(buffer.isEmpty, "Invalid state. The buffer should be empty.")
            state = .buffering(buffer, nil, observation)
            return .resumeContinuation(consumer)
        case .finished:
            return nil
        }
    }

    enum FinishAction {
        case resumeConsumer(SuspendedConsumer)
    }

    mutating func finish() -> FinishAction? {
        switch state {
        case .awaitingObservation, .buffering(_, .none, _):
            state = .finished
            return nil
        case .buffering(_, .some(let consumer), _):
            state = .finished
            return .resumeConsumer(consumer)
        case .finished:
            return nil
        }
    }
}
