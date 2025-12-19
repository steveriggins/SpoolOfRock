import SwiftUI

private struct SpoolRepositoryKey: EnvironmentKey {
    static let defaultValue: SpoolRepository? = nil
}

extension EnvironmentValues {
    var spoolRepository: SpoolRepository? {
        get { self[SpoolRepositoryKey.self] }
        set { self[SpoolRepositoryKey.self] = newValue }
    }
}

extension View {
    func spoolRepository(_ repository: SpoolRepository) -> some View {
        environment(\.spoolRepository, repository)
    }
}
