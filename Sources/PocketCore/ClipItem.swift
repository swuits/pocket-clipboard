import Foundation

public struct ClipItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let kind: ClipKind
    public let text: String?
    public let imageFile: String?
    public let imageWidth: Int?
    public let imageHeight: Int?
    /// Identity for de-duplication: the text itself, or a hash of the image bytes.
    public let fingerprint: String
    public let createdAt: Date
    public let isPinned: Bool
    public let sourceApp: String?

    public init(
        id: UUID = UUID(), kind: ClipKind, text: String? = nil, imageFile: String? = nil,
        imageWidth: Int? = nil, imageHeight: Int? = nil, fingerprint: String,
        createdAt: Date = Date(), isPinned: Bool = false, sourceApp: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.text = text
        self.imageFile = imageFile
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.fingerprint = fingerprint
        self.createdAt = createdAt
        self.isPinned = isPinned
        self.sourceApp = sourceApp
    }

    public static func text(_ text: String, source: String?, at date: Date = Date()) -> ClipItem {
        ClipItem(kind: Classifier.kind(of: text), text: text, fingerprint: "t:" + text, createdAt: date, sourceApp: source)
    }

    public static func image(
        file: String, hash: String, width: Int, height: Int, source: String?, at date: Date = Date()
    ) -> ClipItem {
        ClipItem(
            kind: .image, imageFile: file, imageWidth: width, imageHeight: height,
            fingerprint: "i:" + hash, createdAt: date, sourceApp: source
        )
    }

    public func pinned(_ value: Bool) -> ClipItem {
        ClipItem(
            id: id, kind: kind, text: text, imageFile: imageFile, imageWidth: imageWidth,
            imageHeight: imageHeight, fingerprint: fingerprint, createdAt: createdAt,
            isPinned: value, sourceApp: sourceApp
        )
    }

    public func touched(at date: Date) -> ClipItem {
        ClipItem(
            id: id, kind: kind, text: text, imageFile: imageFile, imageWidth: imageWidth,
            imageHeight: imageHeight, fingerprint: fingerprint, createdAt: date,
            isPinned: isPinned, sourceApp: sourceApp
        )
    }

    public var characterCount: Int { text?.count ?? 0 }
}
