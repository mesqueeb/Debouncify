# Debouncify 🔂

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FDebouncify%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mesqueeb/Debouncify)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FDebouncify%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mesqueeb/Debouncify)

```
.package(url: "https://github.com/mesqueeb/Debouncify", from: "0.0.1")
```

`Debouncify` is a helper class to easily debounce function calls.

## Usage

Suppose you have a function that you want to execute on every keystroke, but debounce it by 300ms to only execute it after the user has stopped typing for a certain amount of time.

You can use `Debouncify` to wrap this function and it will automatically get debounced each subsequent call.

Example:

```swift
// Example debounced function
func search() async {
    print("searching!")
    // your search API call logic...
}

// Using Debouncify to wrap the function
let searchAfter300ms = Debouncify(call: search, after: .milliseconds(300))

// Usage
Task {
    Task { await searchAfter300ms() }
    try await Task.sleep(for: .seconds(0.1))
    Task { await searchAfter300ms() }
    try await Task.sleep(for: .seconds(0.1))
    Task { await searchAfter300ms() }
}
// it will only print "searching!" once after 300ms
```

This example demonstrates how `Debouncify` can be used to make sure a function is only called after a certain amount of time has passed since the last call, canceling out any previous executions. Otherwise known as debouncing.

### Canceling the debounced Task

You can cancel the debounced task by calling the `cancel` method on the `Debouncify` instance.

Example:

```swift
// Example debounced function
func search() async {}

let searchAfter300ms = Debouncify(by: .milliseconds(300), search)
var task: Task<Any, Any>? = nil

Task { await searchAfter300ms() }
// now eg. the user has hit ESC to cancel
Task { await searchAfter300ms.cancel() }
```

## Documentation

See the [documentation](https://swiftpackageindex.com/mesqueeb/Debouncify/main/documentation/Debouncify/Debouncify) for more info.
