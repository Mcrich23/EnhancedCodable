//
//  File.swift
//  CodableIgnoreInitializedProperties
//
//  Created by Morris Richman on 1/3/25.
//

import Foundation
import SwiftSyntaxMacros
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftDiagnostics
import SwiftCompilerPlugin

// Define a custom error type
enum MacroExpansionError: Error {
    case unsupportedDeclaration
    case message(String)
}

enum CodableIgnoreInitializedProperties: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDecl = declaration as? StructDeclSyntax else {
            throw MacroExpansionError.unsupportedDeclaration
        }
        
        let existingInits = structDecl.memberBlock.members.compactMap {
            $0.decl.as(InitializerDeclSyntax.self)
        }
        
        let hasFromDecoderInit = existingInits.contains { initDecl in
            guard let firstParam = initDecl.signature.parameterClause.parameters.first else { return false }
            return firstParam.firstName.text == "decoder" &&
            firstParam.type.description.contains("Decoder") == true
        }
        
        let hasStandardInit = existingInits.contains { initDecl in
            !(initDecl.signature.parameterClause.parameters.count == 1 &&
              initDecl.signature.parameterClause.parameters.first?.firstName.text == "decoder" &&
              initDecl.signature.parameterClause.parameters.first?.type.description.contains("Decoder") == true)
        }
        
        let properties = structDecl.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }
        
        let initEligibleProperties = properties.filter { prop in
            guard let binding = prop.bindings.first else { return false }
            return binding.initializer == nil && binding.accessorBlock == nil
        }
        
        let decodeInitBody = initEligibleProperties.compactMap { property in
            guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = property.bindings.first?.typeAnnotation?.type.description else {
                return nil
            }
            
            if type.hasSuffix("?") {
                return "self.\(name) = try container.decodeIfPresent(\(type.dropLast()).self, forKey: .\(name))"
            } else {
                return "self.\(name) = try container.decode(\(type).self, forKey: .\(name))"
            }
        }.joined(separator: "\n")
        
        let decodeInitMethod = """
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                \(decodeInitBody)
            }
            """
        
        let standardInitParameters = initEligibleProperties.compactMap { property in
            guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = property.bindings.first?.typeAnnotation?.type.description else {
                return nil
            }
            return "\(name): \(type)"
        }.joined(separator: ", ")
        
        let standardInitBody = initEligibleProperties.compactMap { property in
            guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                return nil
            }
            return "self.\(name) = \(name)"
        }.joined(separator: "\n")
        
        let standardInitMethod = """
            init(\(standardInitParameters)) {
                \(standardInitBody)
            }
            """
        
        var returnArray: [DeclSyntax] = []
        
        if !hasStandardInit && !standardInitBody.isEmpty {
            returnArray.append(.init(stringLiteral: standardInitMethod))
        }
        
        if !hasFromDecoderInit && !decodeInitBody.isEmpty {
            let extensionDecl = """
                extension \(structDecl.name.text): Decodable {
                    \(decodeInitMethod)
                }
                """
            returnArray.append(.init(stringLiteral: extensionDecl))
        }
        
        return returnArray
    }
}

@main
struct CodableIgnoreInitializedPropertiesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableIgnoreInitializedProperties.self,
    ]
}
