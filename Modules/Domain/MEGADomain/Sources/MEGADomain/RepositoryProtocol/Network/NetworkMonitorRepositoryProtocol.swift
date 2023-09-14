public protocol NetworkMonitorRepositoryProtocol {
    func networkPathChanged(completion: @escaping (Bool) -> Void)
    func isConnected() -> Bool
}
