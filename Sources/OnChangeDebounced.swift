import SwiftUI

public extension View {
  /// `onChangeDebounced` is a SwiftUI View modifier like `onChange` but makes it debounce on every call by a specified duration
  ///
  /// ## Usage
  ///
  /// Suppose you have a function that you want to execute on every keystroke, but debounce it by 300ms to only execute it after the user has stopped typing for a certain amount of time.
  ///
  /// Example:
  ///
  /// ```swift
  /// @State private var query: String = ""
  ///
  /// func search(_ query: String) async {
  ///     print("searching!")
  ///     // your search API call logic...
  /// }
  ///
  /// var body: some View {
  ///     TextField("Search...", text: $query)
  ///         .onChangeDebounced(of: query, after: .milliseconds(300)) { _oldValue, newValue in
  ///             search(newValue)
  ///         }
  /// }
  /// ```
  ///
  /// ### Canceling the debounced Task
  ///
  /// If you need to cancel the debounced execution of your search function, eg. when the user hits ESC, you can pass a binding with a `Task` which you can then cancel.
  ///
  /// Example:
  ///
  /// ```swift
  /// @State private var query: String = ""
  ///
  /// func search(_ query: String) async {
  ///     print("searching!")
  ///     // your search API call logic...
  /// }
  ///
  /// /// The search Task is added by `onChangeDebounced` below
  /// @State private var searchTask: Task<Void, never>? = nil
  ///
  /// var body: some View {
  ///     TextField("Search...", text: $query)
  ///         .onChangeDebounced(of: query, after: .milliseconds(300), task: $searchTask) { _oldValue, newValue in
  ///             search(newValue)
  ///         }
  ///         .onKeyPress(.return) {
  ///             searchTask?.cancel()
  ///             search(query)
  ///             return .handled
  ///         }
  ///         .onKeyPress(.escape) {
  ///             searchTask?.cancel()
  ///             return .handled
  ///         }
  /// }
  /// ```
  func onChangeDebounced<Value>(
    of value: Value,
    after: Duration,
    task: Binding<Task<Void, Never>?>? = nil,
    initial: Bool = false,
    _ action: @escaping (_ oldValue: Value, _ newValue: Value) -> Void
  ) -> some View where Value: Equatable {
    modifier(
      DebouncifyViewModifier(
        trigger: value,
        delay: after,
        task: task,
        initial: initial,
        action: action
      )
    )
  }
}

private struct DebouncifyViewModifier<Value>: ViewModifier where Value: Equatable {
  private let trigger: Value
  private let delay: Duration
  private let initial: Bool
  private let action: (Value, Value) -> Void

  /// When a Binding of is passed we will use this
  @Binding private var parentTask: Task<Void, Never>?
  /// In case no Binding was passed we will use this
  @State private var internalTask: Task<Void, Never>? = nil
  /// This is our switch to decide wether to rely on the `parentTask` or on our `internalTask`
  @State private var useParentTask: Bool
  /// A writable computed getter to the Task Binding we use `onChange` below
  private var currentTask: Binding<Task<Void, Never>?> {
    return Binding<Task<Void, Never>?>(
      get: { useParentTask ? parentTask : internalTask },
      set: { newValue in
        if useParentTask { self.parentTask = newValue } else { self.internalTask = newValue }
      }
    )
  }

  public init(
    trigger: Value,
    delay: Duration,
    task: Binding<Task<Void, Never>?>?,
    initial: Bool,
    action: @escaping (Value, Value) -> Void
  ) {
    self.trigger = trigger
    self.delay = delay
    self.initial = initial
    self.action = action
    if let task {
      self._parentTask = task
      self.useParentTask = true
    } else {
      self._parentTask = .constant(nil)
      self.useParentTask = false
    }
  }

  func body(content: Content) -> some View {
    content.onChange(of: trigger, initial: initial) { lhs, rhs in
      currentTask.wrappedValue?.cancel()
      // Create a new task that executes the function after the debounce interval
      currentTask.wrappedValue = Task {
        try? await Task.sleep(for: delay)
        guard !Task.isCancelled else { return }
        action(lhs, rhs)
        currentTask.wrappedValue = nil
      }
    }
  }
}
