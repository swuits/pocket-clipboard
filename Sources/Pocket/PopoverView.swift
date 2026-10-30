import PocketCore
import SwiftUI

struct PopoverView: View {
    @ObservedObject var store: ClipStore
    let close: () -> Void

    @Local private var query = ""
    @Local private var filter: ClipFilter = .all
    @Local private var selection: UUID?
    @FocusState private var searchFocused: Bool

    private var results: [ClipItem] { store.results(query: query, filter: filter) }
    private var pinned: [ClipItem] { results.filter(\.isPinned) }
    private var recent: [ClipItem] { results.filter { !$0.isPinned } }
    private var ordered: [ClipItem] { pinned + recent }

    var body: some View {
        ZStack {
            background
            VStack(spacing: 0) {
                header
                searchField
                filterChips
                content
                footer
            }
            toastOverlay
        }
        .frame(width: 400, height: 600)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
        .onReceive(NotificationCenter.default.publisher(for: .pocketDidShow)) { _ in
            query = ""
            filter = .all
            selection = nil
            searchFocused = true
        }
        .onChange(of: query) { _, _ in selection = ordered.first?.id }
        .onChange(of: filter) { _, _ in selection = ordered.first?.id }
        .onKeyPress(.escape) { close(); return .handled }
    }

    // MARK: Chrome

    private var background: some View {
        ZStack {
            VisualEffect(material: .hudWindow)
            Theme.ink.opacity(0.72)
            RadialGradient(
                colors: [Theme.ember.opacity(0.22), .clear],
                center: .topLeading, startRadius: 0, endRadius: 320
            )
            RadialGradient(
                colors: [Color(red: 0.45, green: 0.3, blue: 0.9).opacity(0.14), .clear],
                center: .bottomTrailing, startRadius: 0, endRadius: 360
            )
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text("pocket")
                        .font(.system(size: 30, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundStyle(Theme.cream)
                    Text(".")
                        .font(.system(size: 30, weight: .black, design: .serif))
                        .foregroundStyle(Theme.emberGradient)
                }
                Text("\(store.items.count) clips · \(store.dailyCounts.last ?? 0) today")
                    .font(Theme.mono)
                    .foregroundStyle(Theme.mute)
            }
            Spacer()
            Sparkline(values: store.dailyCounts)
        }
        .padding(.horizontal, 22)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(searchFocused ? Theme.ember : Theme.mute)
            TextField("Search your clips", text: $query)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .foregroundStyle(Theme.cream)
                .focused($searchFocused)
                .onSubmit(copySelected)
                .onKeyPress(.downArrow) { moveSelection(by: 1); return .handled }
                .onKeyPress(.upArrow) { moveSelection(by: -1); return .handled }
                .onKeyPress(characters: .decimalDigits, phases: .down, action: handleDigit)
                .onKeyPress(.delete, phases: .down) { press in
                    guard press.modifiers.contains(.command), let item = selectedItem else { return .ignored }
                    store.delete(item)
                    selection = ordered.first?.id
                    return .handled
                }
            if query.isEmpty {
                KeyCap(text: "⌃⌘V")
            } else {
                Button { query = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(Theme.mute)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 38)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Color.white.opacity(0.06)))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .strokeBorder(searchFocused ? Theme.ember.opacity(0.7) : Theme.hairline, lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .animation(.easeOut(duration: 0.15), value: searchFocused)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(ClipFilter.allCases) { option in
                    let count = store.count(for: option)
                    if option == .all || option == filter || count > 0 {
                        FilterChip(title: option.title, count: count, isSelected: option == filter) {
                            withAnimation(.snappy(duration: 0.2)) { filter = option }
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 44)
    }

    // MARK: List

    @ViewBuilder
    private var content: some View {
        if results.isEmpty {
            EmptyState(hasItems: !store.items.isEmpty, query: query)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8, pinnedViews: []) {
                        if !pinned.isEmpty { SectionLabel(title: "Pinned", symbol: "pin.fill") }
                        ForEach(pinned) { row($0) }
                        if !pinned.isEmpty && !recent.isEmpty { SectionLabel(title: "Recent", symbol: "clock") }
                        ForEach(recent) { row($0) }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .padding(.bottom, 8)
                }
                .scrollIndicators(.never)
                .onChange(of: selection) { _, id in
                    guard let id else { return }
                    withAnimation(.easeOut(duration: 0.15)) { proxy.scrollTo(id, anchor: .center) }
                }
            }
        }
    }

    private func row(_ item: ClipItem) -> some View {
        ClipCard(
            item: item,
            image: store.image(for: item),
            index: ordered.firstIndex(where: { $0.id == item.id }),
            isSelected: selection == item.id,
            onCopy: { copy(item) },
            onPin: { withAnimation(.snappy) { store.togglePin(item) } },
            onDelete: { withAnimation(.snappy) { store.delete(item) } },
            onTransform: { store.apply($0, to: item) }
        )
        .id(item.id)
        .transition(.opacity.combined(with: .scale(scale: 0.97)))
    }

    private var footer: some View {
        HStack {
            Text("↑↓ move   ⏎ copy   ⌘1–9 quick   ⌘⌫ delete")
                .font(.system(size: 10, design: .monospaced))
                .foregroundStyle(Theme.mute.opacity(0.8))
            Spacer()
            Menu {
                Button(LaunchAtLogin.isEnabled ? "Don't Launch at Login" : "Launch at Login") { LaunchAtLogin.toggle() }
                Button("Clear Unpinned Clips", role: .destructive) { store.clearUnpinned() }
                Divider()
                Button("Quit Pocket") { NSApp.terminate(nil) }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.mute)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
        }
        .padding(.horizontal, 18)
        .frame(height: 38)
        .overlay(alignment: .top) { Rectangle().fill(Theme.hairline).frame(height: 1) }
    }

    private var toastOverlay: some View {
        VStack {
            Spacer()
            if let message = store.toast {
                HStack(spacing: 7) {
                    Image(systemName: "checkmark.circle.fill").foregroundStyle(Theme.emberGradient)
                    Text(message).font(.system(size: 12, weight: .medium)).foregroundStyle(Theme.cream)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(Capsule().fill(Theme.ink.opacity(0.95)))
                .overlay(Capsule().strokeBorder(Theme.ember.opacity(0.4), lineWidth: 1))
                .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
                .padding(.bottom, 52)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35, bounce: 0.3), value: store.toast)
        .allowsHitTesting(false)
    }

    // MARK: Actions

    private var selectedItem: ClipItem? {
        ordered.first(where: { $0.id == selection }) ?? ordered.first
    }

    private func moveSelection(by delta: Int) {
        guard !ordered.isEmpty else { return }
        let current = ordered.firstIndex(where: { $0.id == selection }) ?? (delta > 0 ? -1 : ordered.count)
        let next = min(max(current + delta, 0), ordered.count - 1)
        selection = ordered[next].id
    }

    private func handleDigit(_ press: KeyPress) -> KeyPress.Result {
        guard press.modifiers.contains(.command), let number = Int(press.characters), (1...9).contains(number),
              ordered.indices.contains(number - 1)
        else { return .ignored }
        copy(ordered[number - 1])
        return .handled
    }

    private func copySelected() {
        if let item = selectedItem { copy(item) }
    }

    private func copy(_ item: ClipItem) {
        store.copy(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) { close() }
    }
}
