//
//  CodableIgnoreInitializedProperties.swift
//  CodableIgnoreInitializedProperties
//
//  Created by Morris Richman on 1/3/25.
//

import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftCompilerPlugin
import SwiftDiagnostics
import Foundation

enum MacroExpansionError: Error {
    case unsupportedDeclaration
}

public struct CodableIgnoreInitializedProperties: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax, in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionError.unsupportedDeclaration
        }
        let existingEnums = structDecl.memberBlock.members.compactMap {
            $0.decl.as(EnumDeclSyntax.self)
        }

        let hasCodingKeys = existingEnums.contains { decl in
            decl.name.text == "CodingKeys"
        }
        guard !hasCodingKeys else {
            throw "Coding keys already exist."
        }
        
        let properties = structDecl.memberBlock.members.compactMap { $0.decl.as(VariableDeclSyntax.self) }

        let initEligibleProperties = properties.filter { prop in
            guard let binding = prop.bindings.first else { return false }
            return binding.initializer == nil && binding.accessorBlock == nil
        }
        
        let enumCases: [String] = initEligibleProperties.compactMap { decl in
            guard let name = decl.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text
                  
            else {
                return nil
            }
            
            return "case \(name)"
        }

        guard !enumCases.isEmpty else {
            return []
        }

        let codingKeysEnum = """
        enum CodingKeys: String, CodingKey {
            \(enumCases.joined(separator: "\n"))
        }
        """

        return [.init(stringLiteral: codingKeysEnum)]
    }
}

@main
struct CodableIgnoreInitializedPropertiesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableIgnoreInitializedProperties.self,
    ]
}

extension String: @retroactive Error {}
