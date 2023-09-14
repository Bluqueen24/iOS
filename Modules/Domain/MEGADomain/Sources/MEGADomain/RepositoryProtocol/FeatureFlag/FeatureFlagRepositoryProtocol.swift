public protocol FeatureFlagRepositoryProtocol: RepositoryProtocol {
    func savedFeatureFlags() -> [FeatureFlagEntity]
    func isFeatureFlagEnabled(for key: FeatureFlagName) -> Bool
    func configFeatureFlag(for key: FeatureFlagName, isEnabled: Bool)
    func removeFeatureFlag(for key: FeatureFlagName)
}
