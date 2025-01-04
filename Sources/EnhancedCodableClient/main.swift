import EnhancedCodable
import EnhancedCodableMacros
import Foundation

@CodableIgnoreInitializedProperties
struct DocCIndex: Codable, Identifiable {
    let id: UUID = UUID()
    
    let interfaceLanguages: [String : [InterfaceLanguage]]
    
    @CodableIgnoreInitializedProperties
    struct InterfaceLanguage: Codable {
        let title: String
        let path: String?
        var type: String
        
        let children: [InterfaceLanguage]?
    }
    
}
