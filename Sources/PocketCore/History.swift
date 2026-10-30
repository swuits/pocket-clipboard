import Foundation

/// Pure helpers over the clip list so the store stays thin and testable.
public enum History {
    /// Inserts `new` at the front, replacing any older clip with the same
    /// fingerprint (and inheriting its pin), then evicts the oldest unpinned
    /// clips beyond `limit`.
    public static func inserting(
        _ new: ClipItem, into items: [ClipItem], limit: Int
    ) -> (items: [ClipItem], evicted: [ClipItem]) {
        let duplicates = items.filter { $0.fingerprint == new.fingerprint }
        let wasPinned = new.isPinned || duplicates.contains(where: \.isPinned)
        let rest = items.filter { $0.fingerprint != new.fingerprint }
        let combined = [new.pinned(wasPinned)] + rest

        var unpinned = combined.filter { !$0.isPinned }.count
        var kept: [ClipItem] = []
        var evicted: [ClipItem] = []
        for item in combined.reversed() {
            if !item.isPinned && unpinned > limit {
                evicted.append(item)
                unpinned -= 1
            } else {
                kept.append(item)
            }
        }
        return (kept.reversed(), evicted)
    }

    /// Clip counts for the last `days` days, oldest first, ending today.
    public static func dailyCounts(
        _ items: [ClipItem], days: Int = 7, now: Date = Date(), calendar: Calendar = .current
    ) -> [Int] {
        let today = calendar.startOfDay(for: now)
        return (0..<days).reversed().map { offset in
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { return 0 }
            return items.filter { calendar.isDate($0.createdAt, inSameDayAs: day) }.count
        }
    }
}
