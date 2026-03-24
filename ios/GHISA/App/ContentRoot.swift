import SwiftData
import SwiftUI

struct ContentRoot: View {
    @Environment(\.modelContext) private var modelContext
    @State private var isReady = false

    var body: some View {
        Group {
            if isReady {
                MainTabView()
            } else {
                Color.clear.onAppear { seed() }
            }
        }
    }

    private func seed() {
        let service = DataSeedService(modelContext: modelContext)
        try? service.seedIfNeeded()
        isReady = true
    }
}
