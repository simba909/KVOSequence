# KVOSequence

[![Test](https://github.com/simba909/KVOSequence/actions/workflows/swift.yml/badge.svg)](https://github.com/simba909/KVOSequence/actions/workflows/swift.yml)

A small library enabling seamless `AsyncSequence` support for KVO observation, similar to `NSObject.KeyValueObservingPublisher` in Combine.

#### Usage
You can retrieve an `AsyncSequence` using both `KeyPath` and `String`-based APIs. For `KeyPath`:
```swift
class Person: NSObject {
    @objc dynamic var name: String?

    init(name: String? = nil) {
        self.name = name
    }
}

let person = Person()
Task {
    // The type of each change is inferred from the keypath
    for change in person.sequence(for: \.name, options: [.old, .new]) {
        print(change.newValue)
    }
}

// Prints "John"
person.name = "John"
```

and for `String`:

```swift
let defaults = UserDefaults.standard
Task {
    let sequence = defaults.sequence(
        // Since the type cannot be inferred from String-based APIs,
        // we need to manually specify the expected type here.
        of: [String: Any].self,
        forKeyPath: "user",
        options: [.new]
    )

    for change in sequence {
        print(change.newValue)
    }
}

// Prints ["name": "Alice", "age": 23]
defaults.set(["name": "Alice", "age": 23] as [String: Any], forKey: "user")
```
