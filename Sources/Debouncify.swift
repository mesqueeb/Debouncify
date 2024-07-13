import Foundation

/// `Debouncify` is a helper class to easily debounce function calls.
///
/// ## Usage
///
/// Suppose you have a function that you want to execute on every keystroke, but debounce it by 300ms to only execute it after the user has stopped typing for a certain amount of time.
///
/// You can use `Debouncify` to wrap this function and it will automatically get debounced each subsequent call.
///
/// Example:
///
/// ```swift
/// // Example debounced function
/// func search() async {
///     print("searching!")
///     // your search API call logic...
/// }
///
/// // Using Debouncify to wrap the function
/// let searchAfter300ms = Debouncify(call: search, after: .milliseconds(300))
///
/// // Usage
/// Task {
///     Task { await searchAfter300ms() }
///     try await Task.sleep(for: .seconds(0.1))
///     Task { await searchAfter300ms() }
///     try await Task.sleep(for: .seconds(0.1))
///     Task { await searchAfter300ms() }
/// }
/// // it will only print "searching!" once after 300ms
/// ```
///
/// This example demonstrates how `Debouncify` can be used to make sure a function is only called after a certain amount of time has passed since the last call, canceling out any previous executions. Otherwise known as debouncing.
///
/// ### Canceling the debounced Task
///
/// You can cancel the debounced task by calling the `cancel` method on the `Debouncify` instance.
///
/// Example:
///
/// ```swift
/// // Example debounced function
/// func search() async {}
///
/// let searchAfter300ms = Debouncify(by: .milliseconds(300), search)
/// var task: Task<Any, Any>? = nil
///
/// Task { await searchAfter300ms() }
/// // now eg. the user has hit ESC to cancel
/// Task { await searchAfter300ms.cancel() }
/// ```
public actor Debouncify<each Parameter: Sendable>: Sendable {
  private let delay: Duration
  private let fn: @Sendable (repeat each Parameter) async -> Void
  private var currentTask: Task<Void, Never>?

  public init(call fn: @Sendable @escaping (repeat each Parameter) async -> Void, after delay: Duration) {
    self.delay = delay
    self.fn = fn
  }

  public func callAsFunction(_ parameter: repeat each Parameter) {
    // Cancel the previous task if it exists
    currentTask?.cancel()

    // Create a new task that executes the function after the debounce interval
    currentTask = Task {
      try? await Task.sleep(for: delay)
      guard !Task.isCancelled else { return }
      await fn(repeat each parameter)
    }
  }

  public func cancel() {
    currentTask?.cancel()
    currentTask = nil
  }
}
