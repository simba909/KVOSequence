import Foundation

class StringyObserver<Subject, Value>: NSObject where Subject: NSObject {
    struct ObservedChange {
        let kind: NSKeyValueObservedChange<Value>.Kind
        let newValue: Value?
        let oldValue: Value?
    }

    let subject: Subject
    let keyPath: String
    let changeHandler: (ObservedChange) -> Void

    init(
        subject: Subject,
        keyPath: String,
        options: NSKeyValueObservingOptions,
        changeHandler: @escaping (ObservedChange) -> Void
    ) {
        self.subject = subject
        self.keyPath = keyPath
        self.changeHandler = changeHandler
        super.init()

        subject.addObserver(self, forKeyPath: keyPath, options: options, context: nil)
    }

    deinit {
        subject.removeObserver(self, forKeyPath: keyPath)
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard let change,
              let rawKind = change[.kindKey] as? UInt,
              let kind = NSKeyValueObservedChange<Value>.Kind(rawValue: rawKind) else {
            return
        }

        let oldValue = change[.oldKey] as? Value
        let newValue = change[.newKey] as? Value

        let observedChange = ObservedChange(kind: kind, newValue: newValue, oldValue: oldValue)
        changeHandler(observedChange)
    }
}
