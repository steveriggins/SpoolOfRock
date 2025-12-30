import SwiftUI

// MARK: - Environment Key

/// A private environment key for storing and retrieving the `SpoolRepository` from SwiftUI's environment.
///
/// This key is used internally by the environment value accessor and should not be accessed directly.
/// The default value is `nil`, indicating no repository has been injected into the environment.
private struct SpoolRepositoryKey: EnvironmentKey {
    static let defaultValue: SpoolRepository? = nil
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    /// The spool repository instance available in the current environment.
    ///
    /// This property provides access to the `SpoolRepository` through SwiftUI's environment system.
    /// Views can access this value using the `@Environment` property wrapper:
    ///
    /// ```swift
    /// @Environment(\.spoolRepository) var repository
    /// ```
    ///
    /// The value is `nil` if no repository has been injected into the environment.
    var spoolRepository: SpoolRepository? {
        get { self[SpoolRepositoryKey.self] }
        set { self[SpoolRepositoryKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Injects a spool repository into the environment for this view and its children.
    ///
    /// This modifier makes the repository available to all child views through the environment.
    /// Child views can access the repository using `@Environment(\.spoolRepository)`.
    ///
    /// Example usage:
    /// ```swift
    /// ContentView()
    ///     .spoolRepository(myRepository)
    /// ```
    ///
    /// - Parameter repository: The `SpoolRepository` instance to inject into the environment.
    /// - Returns: A view with the repository available in its environment.
    func spoolRepository(_ repository: SpoolRepository) -> some View {
        environment(\.spoolRepository, repository)
    }
}
