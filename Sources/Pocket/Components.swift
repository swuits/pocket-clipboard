import PocketCore
import SwiftUI

struct KeyCap: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium, design: .monospaced))
            .foregroundStyle(Theme.mute)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.07)))
    }
}

struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    @Local private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Text(title)
                if count > 0 {
                    Text("\(count)").opacity(0.55).monospacedDigit()
                }
            }
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(isSelected ? Theme.ink : Theme.cream.opacity(isHovering ? 0.95 : 0.7))
            .padding(.horizontal, 11)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(isSelected ? AnyShapeStyle(Theme.emberGradient) : AnyShapeStyle(Color.white.opacity(isHovering ? 0.1 : 0.06)))
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

struct SectionLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 9, weight: .bold))
            Text(title.uppercased()).font(.system(size: 10, weight: .semibold, design: .monospaced)).tracking(1.2)
            Rectangle().fill(Theme.hairline).frame(height: 1)
        }
        .foregroundStyle(Theme.mute)
        .padding(.horizontal, 6)
        .padding(.top, 6)
    }
}

/// Seven bars, oldest to newest; today is lit in ember.
struct Sparkline: View {
    let values: [Int]

    var body: some View {
        let peak = max(values.max() ?? 1, 1)
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let isToday = index == values.count - 1
                Capsule()
                    .fill(isToday ? AnyShapeStyle(Theme.emberGradient) : AnyShapeStyle(Color.white.opacity(0.18)))
                    .frame(width: 5, height: max(4, 30 * CGFloat(value) / CGFloat(peak)))
            }
        }
        .frame(height: 30, alignment: .bottom)
        .help("Clips over the last 7 days")
        .animation(.snappy, value: values)
    }
}

struct EmptyState: View {
    let hasItems: Bool
    let query: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            ZStack {
                Circle().fill(Theme.ember.opacity(0.12)).frame(width: 84, height: 84)
                Image(systemName: hasItems ? "magnifyingglass" : "tray")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(Theme.emberGradient)
            }
            Text(hasItems ? "Nothing matches" : "Your pocket is empty")
                .font(.system(size: 17, weight: .semibold, design: .serif)).italic()
                .foregroundStyle(Theme.cream)
            Text(hasItems ? "No clips found\(query.isEmpty ? "" : " for “\(query)”")." : "Copy something with ⌘C and it will land here.")
                .font(.system(size: 12))
                .foregroundStyle(Theme.mute)
                .multilineTextAlignment(.center)
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 40)
    }
}
