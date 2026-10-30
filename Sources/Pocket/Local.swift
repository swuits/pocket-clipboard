import SwiftUI

/// Drop-in for `@State`. The SDK now ships `@State` as a macro whose plugin
/// only exists inside Xcode; this keeps the project buildable with just the
/// Command Line Tools by forwarding to the underlying `State` storage.
@propertyWrapper
struct Local<Value>: DynamicProperty {
    private let storage: State<Value>

    init(wrappedValue: Value) {
        storage = State<Value>(wrappedValue: wrappedValue)
    }

    var wrappedValue: Value {
        get { storage.wrappedValue }
        nonmutating set { storage.wrappedValue = newValue }
    }

    var projectedValue: Binding<Value> { storage.projectedValue }
}
