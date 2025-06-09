import EnhancedCodable
import Foundation

@CodableIgnoreInitializedProperties
struct DocCIndex: Codable, Identifiable {
    let id: UUID = UUID()
    
    let interfaceLanguages: [String : [InterfaceLanguage]]
    
    struct InterfaceLanguage: Codable {
        let title: String
        let path: String?
        var type: String
        
        let children: [InterfaceLanguage]?
    }
}

let doc = DocCIndex(interfaceLanguages: [:])
//print(doc)
