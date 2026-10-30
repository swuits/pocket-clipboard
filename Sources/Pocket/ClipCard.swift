import PocketCore
import SwiftUI

struct ClipCard: View {
    let item: ClipItem
    let image: NSImage?
    let index: Int?
    let isSelected: Bool
    let onCopy: () -> Void
    let onPin: () -> Void
    let onDelete: () -> Void
    let onTransform: (TextTransform) -> Void

    @Local private var isHovering = false

    private var accent: Color { Theme.accent(for: item.kind) }
    private var canTransform: Bool { [.text, .code, .link].contains(item.kind) }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            glyph
            VStack(alignment: .leading, spacing: 7) {
                preview
                meta
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(cardBackground)
        .overlay(alignment: .topTrailing) { trailing }
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .onTapGesture(perform: onCopy)
        .onHover { isHovering = $0 }
        .animation(.easeOut(duration: 0.12), value: isHovering)
        .animation(.easeOut(duration: 0.12), value: isSelected)
        .contextMenu {
            Button("Copy", action: onCopy)
            Button(item.isPinned ? "Unpin" : "Pin", action: onPin)
            if canTransform {
                Menu("Transform") {
                    ForEach(TextTransform.allCases) { t in
                        Button(t.title) { onTransform(t) }
                    }
                }
            }
            Divider()
            Button("Delete", role: .destructive, action: onDelete)
        }
    }

    // MARK: Pieces

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(isSelected ? Theme.ember.opacity(0.13) : Color.white.opacity(isHovering ? 0.085 : 0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isSelected ? Theme.ember.opacity(0.55) : Theme.hairline, lineWidth: 1)
            )
    }

    @ViewBuilder
    private var glyph: some View {
        if item.kind == .color, let text = item.text, let color = HexColor(text) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(color))
                .frame(width: 38, height: 38)
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.white.opacity(0.18), lineWidth: 1))
                .shadow(color: Color(color).opacity(0.5), radius: 8, y: 2)
        } else {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(accent.opacity(0.14))
                .frame(width: 38, height: 38)
                .overlay(Image(systemName: Theme.symbol(for: item.kind)).font(.system(size: 14, weight: .semibold)).foregroundStyle(accent))
        }
    }

    @ViewBuilder
    private var preview: some View {
        switch item.kind {
        case .text:
            Text(snippet(lines: 3))
                .font(.system(size: 13))
                .foregroundStyle(Theme.cream)
                .lineLimit(3)
        case .link:
            VStack(alignment: .leading, spacing: 2) {
                Text(URL(string: item.text ?? "")?.host ?? "link")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.cream)
                Text(item.text ?? "")
                    .font(Theme.mono)
                    .foregroundStyle(accent.opacity(0.9))
                    .lineLimit(2)
                    .truncationMode(.middle)
            }
        case .color:
            if let hex = item.text.flatMap({ HexColor($0) }) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(hex.hexString).font(.system(size: 15, weight: .semibold, design: .monospaced)).foregroundStyle(Theme.cream)
                    Text(hex.rgbString).font(Theme.mono).foregroundStyle(Theme.mute)
                }
            }
        case .code:
            Text(snippet(lines: 4))
                .font(.system(size: 11.5, design: .monospaced))
                .foregroundStyle(accent)
                .lineLimit(4)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.28)))
        case .image:
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 96)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
            } else {
                Text("Image unavailable").font(.system(size: 12)).foregroundStyle(Theme.mute)
            }
        }
    }

    private var meta: some View {
        HStack(spacing: 5) {
            Text(metaText)
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.mute)
                .lineLimit(1)
        }
    }

    private var metaText: String {
        var parts: [String] = []
        if let app = item.sourceApp { parts.append(app) }
        parts.append(item.createdAt.formatted(.relative(presentation: .named, unitsStyle: .abbreviated)))
        switch item.kind {
        case .image:
            if let w = item.imageWidth, let h = item.imageHeight { parts.append("\(w)×\(h)") }
        case .text, .code:
            parts.append("\(item.characterCount) chars")
        default: break
        }
        return parts.joined(separator: " · ")
    }

    @ViewBuilder
    private var trailing: some View {
        if isHovering || isSelected {
            HStack(spacing: 2) {
                IconButton(symbol: item.isPinned ? "pin.slash.fill" : "pin.fill", help: item.isPinned ? "Unpin" : "Pin", action: onPin)
                if canTransform {
                    Menu {
                        ForEach(TextTransform.allCases) { t in
                            Button { onTransform(t) } label: { Label(t.title, systemImage: t.symbol) }
                        }
                    } label: {
                        Image(systemName: "wand.and.stars").font(.system(size: 11, weight: .semibold))
                            .frame(width: 24, height: 24)
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .fixedSize()
                    .foregroundStyle(Theme.cream)
                    .help("Transform")
                }
                IconButton(symbol: "trash.fill", help: "Delete", action: onDelete)
            }
            .padding(3)
            .background(Capsule().fill(Theme.ink.opacity(0.92)))
            .overlay(Capsule().strokeBorder(Theme.hairline, lineWidth: 1))
            .padding(8)
            .transition(.opacity)
        } else {
            HStack(spacing: 6) {
                if item.isPinned { Image(systemName: "pin.fill").font(.system(size: 9)).foregroundStyle(Theme.ember) }
                if let index, index < 9 { KeyCap(text: "⌘\(index + 1)").opacity(isSelected ? 1 : 0.7) }
            }
            .padding(10)
        }
    }

    private func snippet(lines: Int) -> String {
        let text = (item.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let head = text.components(separatedBy: .newlines).prefix(lines + 1).joined(separator: "\n")
        return String(head.prefix(360))
    }
}

struct IconButton: View {
    let symbol: String
    let help: String
    let action: () -> Void
    @Local private var isHovering = false

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(isHovering ? Theme.ember : Theme.cream)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.white.opacity(isHovering ? 0.1 : 0)))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
        .help(help)
    }
}
