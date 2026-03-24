import Foundation

@Observable
final class SyncService {
    var isSyncing = false
    var lastSyncDate: Date?

    /// V1: no-op. V2: sync local changes to backend.
    func syncIfNeeded() async {
        // Stub — V1 is local-only, no sync needed
    }
}
