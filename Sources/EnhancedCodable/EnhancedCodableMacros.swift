// The Swift Programming Language
// https://docs.swift.org/swift-book

/// Applies `@Codable` to an object and `@CodableIgnored` to all inline initialized properties.
@attached(member, names: arbitrary)
public macro CodableIgnoreInitializedProperties() = #externalMacro(module: "EnhancedCodableMacros", type: "CodableIgnoreInitializedProperties")

/// Conforms an object to `Codable` and synthesizes `CodingKeys` for it.
@attached(member, names: arbitrary)
@attached(extension, conformances: Codable, names: arbitrary)
public macro Codable() = #externalMacro(module: "EnhancedCodableMacros", type: "Codable")

/// Tells `@Codable` to exclude a property from the `CodingKeys`.
@attached(peer)
public macro CodableIgnored() = #externalMacro(module: "EnhancedCodableMacros", type: "CodableIgnored")
