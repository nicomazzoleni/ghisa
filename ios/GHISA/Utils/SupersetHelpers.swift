import Foundation

/// Computes display labels (A, B, C...) for superset groups.
/// Only assigns a label when 2+ exercises share the same group number.
func supersetGroupLabels<T: Identifiable>(
    for items: [T],
    groupKeyPath: KeyPath<T, Int?>
) -> [T.ID: String] where T.ID == UUID {
    var labels: [UUID: String] = [:]
    let withGroup = items.compactMap { item in
        item[keyPath: groupKeyPath].map { (item, $0) }
    }
    let grouped = Dictionary(grouping: withGroup, by: \.1).mapValues { $0.map(\.0) }
    for (group, members) in grouped where members.count >= 2 {
        let letter = supersetGroupLetter(group)
        for member in members {
            labels[member.id] = letter
        }
    }
    return labels
}

/// Converts a 1-based group number to a letter (1→A, 2→B, etc.)
func supersetGroupLetter(_ group: Int) -> String {
    let index = group - 1
    guard index >= 0, index < 26, let scalar = UnicodeScalar(65 + index) else { return "\(group)" }
    return String(scalar)
}
