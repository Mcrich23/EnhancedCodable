# EnhancedCodable
Here are some quality of life additions I have developed for Swift's Codable protocol.

## Macros
### `@CodableIgnoreInitializedProperties`
When you initialize constants in a structure without a custom decode initializer, you recieve a warning. Simply append this macro to the structure and that warning will go away.
