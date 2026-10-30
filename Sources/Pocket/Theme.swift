import SwiftUI
import PocketCore

/// "Ember on ink": a warm, low-light palette with one hot accent.
enum Theme {
    static let ink = Color(red: 0.075, green: 0.063, blue: 0.086)
    static let ember = Color(red: 1.0, green: 0.42, blue: 0.24)
    static let emberLight = Color(red: 1.0, green: 0.66, blue: 0.36)
    static let cream = Color(red: 0.97, green: 0.94, blue: 0.89)
    static let mute = cream.opacity(0.48)
    static let hairline = Color.white.opacity(0.07)

    static let emberGradient = LinearGradient(
        colors: [emberLight, ember], startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static func accent(for kind: ClipKind) -> Color {
        switch kind {
        case .text: cream
        case .link: Color(red: 0.42, green: 0.72, blue: 1.0)
        case .color: emberLight
        case .code: Color(red: 0.46, green: 0.92, blue: 0.72)
        case .image: Color(red: 0.76, green: 0.62, blue: 1.0)
        }
    }

    static func symbol(for kind: ClipKind) -> String {
        switch kind {
        case .text: "text.alignleft"
        case .link: "link"
        case .color: "paintpalette.fill"
        case .code: "chevron.left.forwardslash.chevron.right"
        case .image: "photo.fill"
        }
    }

    static let mono = Font.system(size: 11, design: .monospaced)
}

struct VisualEffect: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {
        view.material = material
    }
}

extension Color {
    init(_ hex: HexColor) {
        self.init(.sRGB, red: hex.red, green: hex.green, blue: hex.blue, opacity: hex.alpha)
    }
}
