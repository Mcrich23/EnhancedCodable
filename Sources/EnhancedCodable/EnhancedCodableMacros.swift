// The Swift Programming Language
// https://docs.swift.org/swift-book

/// A macro that produces both a value and a string containing the
/// source code that generated the value. For example,
///
///     #stringify(x + y)
///
/// produces a tuple `(x + y, "x + y")`.
@attached(memberAttribute)
public macro CodableIgnoreInitializedProperties() = #externalMacro(module: "EnhancedCodableMacros", type: "CodableIgnoreInitializedProperties")

@attached(member, names: arbitrary)
@attached(extension, conformances: Codable, names: arbitrary)
public macro Codable() = #externalMacro(module: "EnhancedCodableMacros", type: "Codable")

@attached(peer)
public macro CodableIgnored() = #externalMacro(module: "EnhancedCodableMacros", type: "CodableIgnored")
