import PocketCore

enum ClipFilter: String, CaseIterable, Identifiable {
    case all, pinned, text, links, colors, code, images

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "All"
        case .pinned: "Pinned"
        case .text: "Text"
        case .links: "Links"
        case .colors: "Colors"
        case .code: "Code"
        case .images: "Images"
        }
    }

    func matches(_ item: ClipItem) -> Bool {
        switch self {
        case .all: true
        case .pinned: item.isPinned
        case .text: item.kind == .text
        case .links: item.kind == .link
        case .colors: item.kind == .color
        case .code: item.kind == .code
        case .images: item.kind == .image
        }
    }
}
