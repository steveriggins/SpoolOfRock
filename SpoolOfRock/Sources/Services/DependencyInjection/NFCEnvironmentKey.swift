import SwiftUI

private struct NFCManagerKey: EnvironmentKey {
    static let defaultValue: NFCManager? = nil
}

extension EnvironmentValues {
    var nfcManager: NFCManager? {
        get { self[NFCManagerKey.self] }
        set { self[NFCManagerKey.self] = newValue }
    }
}

extension View {
    func nfcManager(_ manager: NFCManager) -> some View {
        environment(\.nfcManager, manager)
    }
}
