public enum LoadState<Value: Sendable>: Sendable {
    case loading
    case loaded(Value)
    case failed(message: String)

    public var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }
}

extension LoadState: Equatable where Value: Equatable {}
