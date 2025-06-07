# EnhancedCodable
Here are some quality of life additions I have developed for Swift's Codable protocol.

## Macros
### `@CodableIgnoreInitializedProperties`
When you initialize constants in a structure without a custom decode initializer, you recieve a warning. Simply append this macro to the structure and that warning will go away.

#### Built on:
- `@Codable`
- `@CodableIgnored`

### `@Codable`
Conform an object to `Codable` with just this macro. It automatically synthesizes `CodingKeys` and operates in conjunction with `@CodableIgnored`.

### `@CodableIgnored`
Removes a property from `CodingKeys` when using `@Codable`.
