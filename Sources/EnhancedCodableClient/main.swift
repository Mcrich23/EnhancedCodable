import EnhancedCodable
import EnhancedCodableMacros
import Foundation

let a = 17
let b = 25

let (result, code) = #stringify(a + b)

print("The value \(result) was produced by the code \"\(code)\"")

@InitWithDefaultID
struct DocCIndex: Codable, Identifiable {
    let id = UUID()
    
    let interfaceLanguages: [String : [InterfaceLanguage]]
    
    struct InterfaceLanguage: Codable {
        let title: String
        let path: String?
        let type: String
        
        let children: [InterfaceLanguage]?
    }
}
