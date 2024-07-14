# Debouncify 🔂

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FDebouncify%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/mesqueeb/Debouncify)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmesqueeb%2FDebouncify%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/mesqueeb/Debouncify)

```
.package(url: "https://github.com/mesqueeb/Debouncify", from: "0.1.0")
```

- `onChangeDebounced` is a SwiftUI View modifier like `onChange` but makes it debounce on every call by a specified duration
- `Debouncify` is a Swift actor to easily wrap a function and make it debounce on every call by a specified duration

"Debouncing" is to execute a function after a short delay. If the function is called twice within this time, the function will only be executed once after the specified duration has passed after the last call.

## SwiftUI `onChangeDebounced` View modifier

Suppose you have a function that you want to execute on every keystroke, but debounce it by 300ms to only execute it after the user has stopped typing for a certain amount of time.

Example:

```swift
@State private var query: String = ""

func search(_ query: String) async {
    print("searching!")
    // your search API call logic...
}

var body: some View {
    TextField("Search...", text: $query)
        .onChangeDebounced(of: query, after: .milliseconds(300)) { _oldValue, newValue in
            search(newValue)
        }
}
```

### Canceling the debounced Task

If you need to cancel the debounced execution of your search function, eg. when the user hits ESC, you can pass a binding with a `Task` which you can then cancel.

Example:

```swift
@State private var query: String = ""

func search(_ query: String) async {
    print("searching!")
    // your search API call logic...
}

/// The search Task is added by `onChangeDebounced` below
@State private var searchTask: Task<Void, never>? = nil

var body: some View {
    TextField("Search...", text: $query)
    .onChangeDebounced(of: query, after: .milliseconds(300), task: $searchTask) { _oldValue, newValue in
        search(newValue)
    }
    .onKeyPress(.return) {
        searchTask?.cancel()
        search(query)
        return .handled
    }
    .onKeyPress(.escape) {
        searchTask?.cancel()
        return .handled
    }
}
```

## Swift `Debouncify` Actor

Use `Debouncify` to wrap a function and it will automatically get debounced each subsequent call.

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
    try await Task.sleep(for: .milliseconds(100))
    Task { await searchAfter300ms() }
    try await Task.sleep(for: .milliseconds(100))
    Task { await searchAfter300ms() }
}
// it will only print "searching!" once after 300ms
```

### Canceling the debounced Task

You can cancel the debounced task by calling the `cancel` method on the `Debouncify` instance.

Example:

```swift
// Example debounced function
func search() async {}

let searchAfter300ms = Debouncify(by: .milliseconds(300), search)
var task: Task<Any, Any>? = nil

Task { await searchAfter300ms() }
// if the search needs to be cancelled before the Task above finishes
Task { await searchAfter300ms.cancel() }
```

## Documentation

See the [documentation](https://swiftpackageindex.com/mesqueeb/Debouncify/main/documentation/Debouncify) for more info.
