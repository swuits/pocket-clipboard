import Foundation
import Testing
@testable import PocketCore

@Suite("Classifier")
struct ClassifierTests {
    @Test("detects hex colors", arguments: ["#fff", "#FF6A3D", "#ff6a3d80"])
    func colors(_ input: String) {
        #expect(Classifier.kind(of: input) == .color)
    }

    @Test("rejects malformed hex", arguments: ["#ff", "#GGGGGG", "ff6a3d", "#12345"])
    func notColors(_ input: String) {
        #expect(Classifier.kind(of: input) != .color)
    }

    @Test func detectsLinks() {
        #expect(Classifier.kind(of: "https://example.com/a?b=1") == .link)
        #expect(Classifier.kind(of: "see https://example.com") == .text)
        #expect(Classifier.kind(of: "ftp://example.com") == .text)
    }

    @Test func detectsCode() {
        #expect(Classifier.kind(of: "func hi() {\n  return 1;\n}") == .code)
        #expect(Classifier.kind(of: "just a plain sentence") == .text)
    }
}

@Suite("HexColor")
struct HexColorTests {
    @Test func expandsShorthand() {
        #expect(HexColor("#f60")?.hexString == "#FF6600")
    }

    @Test func formatsRGB() {
        #expect(HexColor("#FF6A3D")?.rgbString == "rgb(255, 106, 61)")
    }

    @Test func parsesAlpha() throws {
        let color = try #require(HexColor("#00000080"))
        #expect(abs(color.alpha - 0.502) < 0.01)
    }
}

@Suite("TextTransform")
struct TextTransformTests {
    @Test func casing() {
        #expect(TextTransform.uppercase.apply(to: "abc") == "ABC")
        #expect(TextTransform.titleCase.apply(to: "hello world") == "Hello World")
    }

    @Test func slug() {
        #expect(TextTransform.slugify.apply(to: "  Héllo, Wörld!! ") == "hello-world")
    }

    @Test func lines() {
        #expect(TextTransform.sortLines.apply(to: "b\na\nc") == "a\nb\nc")
        #expect(TextTransform.uniqueLines.apply(to: "a\nb\na") == "a\nb")
    }

    @Test func json() {
        #expect(TextTransform.minifyJSON.apply(to: "{ \"b\": 1, \"a\": [1, 2] }") == "{\"a\":[1,2],\"b\":1}")
        #expect(TextTransform.prettyJSON.apply(to: "{\"a\":1}")?.contains("\n") == true)
        #expect(TextTransform.prettyJSON.apply(to: "{nope") == nil)
    }

    @Test func roundTrips() {
        let encoded = TextTransform.base64Encode.apply(to: "pocket ✨")
        #expect(encoded.flatMap { TextTransform.base64Decode.apply(to: $0) } == "pocket ✨")
        let url = TextTransform.urlEncode.apply(to: "a b&c")
        #expect(url == "a%20b%26c")
        #expect(url.flatMap { TextTransform.urlDecode.apply(to: $0) } == "a b&c")
    }
}

@Suite("History")
struct HistoryTests {
    @Test func movesDuplicatesToFrontKeepingPin() {
        let old = ClipItem.text("hello", source: nil).pinned(true)
        let other = ClipItem.text("world", source: nil)
        let result = History.inserting(ClipItem.text("hello", source: nil), into: [other, old], limit: 10)
        #expect(result.items.map(\.text) == ["hello", "world"])
        #expect(result.items.first?.isPinned == true)
    }

    @Test func evictsOldestUnpinnedOnly() {
        let pinned = ClipItem.text("keep", source: nil).pinned(true)
        let a = ClipItem.text("a", source: nil)
        let b = ClipItem.text("b", source: nil)
        let result = History.inserting(ClipItem.text("c", source: nil), into: [a, b, pinned], limit: 2)
        #expect(result.evicted.map(\.text) == ["b"])
        #expect(result.items.contains(where: { $0.text == "keep" }))
        #expect(result.items.count == 3)
    }

    @Test func dailyCountsEndToday() {
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let items = [ClipItem.text("a", source: nil, at: now), ClipItem.text("b", source: nil, at: yesterday),
                     ClipItem.text("c", source: nil, at: yesterday)]
        let counts = History.dailyCounts(items, days: 3, now: now)
        #expect(counts == [0, 2, 1])
    }
}
