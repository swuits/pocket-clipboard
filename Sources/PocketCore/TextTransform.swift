import Foundation

/// One-click rewrites offered on text clips. `apply` returns nil when the
/// input can't be transformed (e.g. invalid JSON), so callers can say so.
public enum TextTransform: String, CaseIterable, Identifiable, Sendable {
    case uppercase, lowercase, titleCase, slugify
    case trimWhitespace, sortLines, uniqueLines
    case prettyJSON, minifyJSON
    case base64Encode, base64Decode, urlEncode, urlDecode

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .uppercase: "UPPERCASE"
        case .lowercase: "lowercase"
        case .titleCase: "Title Case"
        case .slugify: "slug-ify"
        case .trimWhitespace: "Trim whitespace"
        case .sortLines: "Sort lines"
        case .uniqueLines: "Remove duplicate lines"
        case .prettyJSON: "Prettify JSON"
        case .minifyJSON: "Minify JSON"
        case .base64Encode: "Base64 encode"
        case .base64Decode: "Base64 decode"
        case .urlEncode: "URL encode"
        case .urlDecode: "URL decode"
        }
    }

    public var symbol: String {
        switch self {
        case .uppercase, .lowercase, .titleCase: "textformat"
        case .slugify: "link"
        case .trimWhitespace: "scissors"
        case .sortLines: "arrow.up.arrow.down"
        case .uniqueLines: "line.3.horizontal.decrease"
        case .prettyJSON, .minifyJSON: "curlybraces"
        case .base64Encode, .base64Decode: "lock.rotation"
        case .urlEncode, .urlDecode: "globe"
        }
    }

    public func apply(to input: String) -> String? {
        switch self {
        case .uppercase: return input.uppercased()
        case .lowercase: return input.lowercased()
        case .titleCase: return input.capitalized
        case .slugify: return Self.slugify(input)
        case .trimWhitespace: return input.trimmingCharacters(in: .whitespacesAndNewlines)
        case .sortLines: return Self.lines(input).sorted().joined(separator: "\n")
        case .uniqueLines: return Self.uniqueLines(input)
        case .prettyJSON: return Self.json(input, pretty: true)
        case .minifyJSON: return Self.json(input, pretty: false)
        case .base64Encode: return Data(input.utf8).base64EncodedString()
        case .base64Decode: return Self.base64Decode(input)
        case .urlEncode: return input.addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(.init(charactersIn: "-._~")))
        case .urlDecode: return input.removingPercentEncoding
        }
    }

    private static func lines(_ input: String) -> [String] {
        input.components(separatedBy: .newlines)
    }

    private static func uniqueLines(_ input: String) -> String {
        var seen = Set<String>()
        return lines(input).filter { seen.insert($0).inserted }.joined(separator: "\n")
    }

    private static func slugify(_ input: String) -> String {
        let folded = input.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let dashed = folded.lowercased().map { $0.isLetter || $0.isNumber ? String($0) : "-" }.joined()
        return dashed.split(separator: "-", omittingEmptySubsequences: true).joined(separator: "-")
    }

    private static func json(_ input: String, pretty: Bool) -> String? {
        guard let data = input.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
        else { return nil }
        var options: JSONSerialization.WritingOptions = [.sortedKeys, .withoutEscapingSlashes, .fragmentsAllowed]
        if pretty { options.insert(.prettyPrinted) }
        guard let out = try? JSONSerialization.data(withJSONObject: object, options: options) else { return nil }
        return String(data: out, encoding: .utf8)
    }

    private static func base64Decode(_ input: String) -> String? {
        let cleaned = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let data = Data(base64Encoded: cleaned, options: .ignoreUnknownCharacters) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
