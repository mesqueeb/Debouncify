import Foundation
import Testing

@testable import Debouncify

public actor TestSearchState: Sendable {
  public var searchedFor: Any? = nil

  public var hasSearched: Bool { return searchedFor != nil }

  public var x: Int = 0

  public func search(_ _for: Any? = true, _ _x: Int = 0) {
    searchedFor = _for
    x = _x
  }
}

@Test func simpleTest() async throws {
  let state = TestSearchState()
  @Sendable func search() async { await state.search() }

  let searchAfter300ms = Debouncify(call: search, after: .milliseconds(300))

  Task { await searchAfter300ms() }
  #expect(!(await state.hasSearched))
  try await Task.sleep(for: .milliseconds(100))
  #expect(!(await state.hasSearched))
  Task { await searchAfter300ms() }
  #expect(!(await state.hasSearched))
  try await Task.sleep(for: .milliseconds(100))
  #expect(!(await state.hasSearched))
  Task { await searchAfter300ms() }
  #expect(!(await state.hasSearched))
  try await Task.sleep(for: .milliseconds(320))
  #expect(await state.hasSearched)
}

@Test func simpleTestCancel() async throws {
  let state = TestSearchState()
  @Sendable func search() async { await state.search() }

  let searchAfter300ms = Debouncify(call: search, after: .milliseconds(300))

  Task { await searchAfter300ms() }
  #expect(!(await state.hasSearched))
  try await Task.sleep(for: .milliseconds(100))
  #expect(!(await state.hasSearched))
  Task { await searchAfter300ms() }
  #expect(!(await state.hasSearched))
  try await Task.sleep(for: .milliseconds(100))
  #expect(!(await state.hasSearched))
  Task { await searchAfter300ms() }
  #expect(!(await state.hasSearched))
  try await Task.sleep(for: .milliseconds(100))
  await searchAfter300ms.cancel()
  try await Task.sleep(for: .milliseconds(400))
  #expect(!(await state.hasSearched))
}

// Exposes the race in `Debouncify.callAsFunction`'s Task body:
//   sleep → `guard !Task.isCancelled` → `await fn(...)`
// If cancel() lands after the guard but before fn finishes, fn still runs.
// The loop calls cancel right when the sleep would end, racing the guard.
@Test func cancelDoesNotRaceWithFnInvocation() async throws {
  for _ in 0 ..< 30 {
    let state = TestSearchState()
    @Sendable func search() async { await state.search() }

    let searchAfter50ms = Debouncify(call: search, after: .milliseconds(50))

    Task { await searchAfter50ms() }
    try await Task.sleep(for: .milliseconds(50))
    await searchAfter50ms.cancel()
    try await Task.sleep(for: .milliseconds(100))
    #expect(!(await state.hasSearched))
  }
}

@Test func simpleTestWith1Param() async throws {
  let state = TestSearchState()
  @Sendable func search(_ _for: String) async { await state.search(_for) }

  let searchAfter300ms = Debouncify(call: search, after: .milliseconds(300))

  Task { await searchAfter300ms("H") }
  #expect((await state.searchedFor) == nil)
  try await Task.sleep(for: .milliseconds(100))
  #expect((await state.searchedFor) == nil)
  Task { await searchAfter300ms("He") }
  #expect((await state.searchedFor) == nil)
  try await Task.sleep(for: .milliseconds(100))
  #expect((await state.searchedFor) == nil)
  Task { await searchAfter300ms("Hel") }
  #expect((await state.searchedFor) == nil)
  try await Task.sleep(for: .milliseconds(320))
  if let str = (await state.searchedFor) as? String {
    #expect(str == "Hel")
  } else {
    Issue.record("searchedFor is not a string")
  }
}

@Test func simpleTestWith2Params() async throws {
  let state = TestSearchState()
  @Sendable func search(_ _for: String, _ _x: Int) async { await state.search(_for, _x) }

  let searchAfter300ms = Debouncify(call: search, after: .milliseconds(300))

  Task { await searchAfter300ms("H", 1) }
  #expect((await state.searchedFor) == nil)
  try await Task.sleep(for: .milliseconds(100))
  #expect((await state.searchedFor) == nil)
  Task { await searchAfter300ms("He", 2) }
  #expect((await state.searchedFor) == nil)
  try await Task.sleep(for: .milliseconds(100))
  #expect((await state.searchedFor) == nil)
  Task { await searchAfter300ms("Hel", 3) }
  #expect((await state.searchedFor) == nil)
  #expect(await (state.x) == 0)
  try await Task.sleep(for: .milliseconds(320))
  if let str = (await state.searchedFor) as? String {
    #expect(str == "Hel")
    #expect(await (state.x) == 3)
  } else {
    Issue.record("searchedFor is not a string")
  }
}
