import Foundation

public enum ClipKind: String, Codable, CaseIterable, Sendable {
    case text, link, color, code, image
}

public enum Classifier {
    private static let codeSignals = [
        "{", "}", ";", "=>", "->", "func ", "def ", "import ", "return ",
        "const ", "let ", "var ", "class ", "</", "();", " == ", "#include", "SELECT ",
    ]

    public static func kind(of raw: String) -> ClipKind {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if HexColor(text) != nil { return .color }
        if isLink(text) { return .link }
        if looksLikeCode(text) { return .code }
        return .text
    }

    static func isLink(_ text: String) -> Bool {
        guard !text.contains(where: \.isWhitespace),
              let url = URL(string: text),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = url.host, !host.isEmpty
        else { return false }
        return true
    }

    static func looksLikeCode(_ text: String) -> Bool {
        let score = codeSignals.filter { text.contains($0) }.count
        let isMultiline = text.contains("\n")
        return score >= 2 && (isMultiline || score >= 3)
    }
}
