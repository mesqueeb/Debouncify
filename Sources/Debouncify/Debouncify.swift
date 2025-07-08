import Foundation

/// `Debouncify` is an actor to easily wrap a function and make it debounce on every call by a specified duration
///
/// ## Usage
///
/// Use `Debouncify` to wrap a function and it will automatically get debounced each subsequent call.
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
///     try await Task.sleep(for: .milliseconds(100))
///     Task { await searchAfter300ms() }
///     try await Task.sleep(for: .milliseconds(100))
///     Task { await searchAfter300ms() }
/// }
/// // it will only print "searching!" once after 300ms
/// ```
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
/// // if the search needs to be cancelled before the Task above finishes
/// Task { await searchAfter300ms.cancel() }
/// ```
public actor Debouncify<each Parameter: Sendable>: Sendable {
  private let delay: Duration
  private let fn: @Sendable (repeat each Parameter) async -> Void
  private var currentTask: Task<Void, Never>?

  public init(
    call fn: @Sendable @escaping (repeat each Parameter) async -> Void,
    after delay: Duration
  ) {
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
