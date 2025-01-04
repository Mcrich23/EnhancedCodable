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
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
//         Make sure the macro is applied to a struct declaration
        guard let structDecl = declaration as? StructDeclSyntax else {
            throw MacroExpansionError.unsupportedDeclaration
        }
//
//        // Process properties of the struct
        let properties = structDecl.memberBlock.members.compactMap { member in
            member.decl.as(VariableDeclSyntax.self)
        }
//
//        // Generate the body of the initializer
        let decodeInitBody = properties.map { property in
            guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = property.bindings.first?.typeAnnotation?.type.description
            else {
                return ""
            }
            
            guard (property.bindings.first?.initializer) == nil && (property.bindings.first?.accessorBlock) == nil else {
                return ""
            }
            
            guard type.hasSuffix("?") else {
                return "self.\(name) = try container.decode(\(type).self, forKey: .\(name))"
            }
            
            return "self.\(name) = try container.decodeIfPresent(\(type.dropLast()).self, forKey: .\(name))"
        }.filter({ !$0.isEmpty && $0 != " " }).joined(separator: "\n")

        // Create the full `init(from:)` method
        let decodeInitMethod = """
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            \(decodeInitBody)
        }
        """
        
        let standardInitParameters = properties.map { property in
            guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                  let type = property.bindings.first?.typeAnnotation?.type.description
            else {
                return ""
            }
            
            guard (property.bindings.first?.initializer) == nil && (property.bindings.first?.accessorBlock) == nil else {
                return ""
            }
            
                return "\(name): \(type)"
        }.filter({ !$0.isEmpty && $0 != " " }).joined(separator: ", ")
        
        let standardInitBody = properties.map { property in
            guard (property.bindings.first?.initializer) == nil && (property.bindings.first?.accessorBlock) == nil else {
                return ""
            }
            
            guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                return ""
            }
            
            return "self.\(name) = \(name)"
        }.filter({ !$0.isEmpty && $0 != " " }).joined(separator: "\n")

        // Create the full `init(from:)` method
        let standardInitMethod = """
        init(\(standardInitParameters)) {
            \(standardInitBody)
        }
        """
        
//        throw MacroExpansionError.message("\(properties)")
        var returnArray: [DeclSyntax] = []

        if !declaration.description.contains("init(\(standardInitParameters))") && !standardInitBody.isEmpty {
            returnArray.append(.init(stringLiteral: standardInitMethod))
        }
        
        if !decodeInitBody.isEmpty {
            returnArray.append(.init(stringLiteral: decodeInitMethod))
        }

        // Return the generated method wrapped in DeclSyntax
        return returnArray
//        return [.init(stringLiteral: properties.description)]
    }
}

@main
struct CodableIgnoreInitializedPropertiesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableIgnoreInitializedProperties.self,
    ]
}
