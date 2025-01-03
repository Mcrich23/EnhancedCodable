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

enum InitWithDefaultID: MemberMacro {
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
        let initBody = properties.map { property in
            guard property.bindings.first?.initializer == nil else {
                return ""
            }
            guard let name = property.bindings.first?.pattern.as(IdentifierPatternSyntax.self)?.identifier.text else {
                return ""
            }
            
            return "self.\(name) = try container.decode(\(property.bindings.first?.typeAnnotation?.type.description ?? "Unknown").self, forKey: .\(name))"
        }.joined(separator: "\n")

        // Create the full `init(from:)` method
        let initMethod = """
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            \(initBody)
        }
        """

        // Return the generated method wrapped in DeclSyntax
        return [DeclSyntax(stringLiteral: initMethod)]
//        return [.init(stringLiteral: "var foo = \"\"")]
    }
}

@main
struct CodableIgnoreInitializedPropertiesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        InitWithDefaultID.self,
    ]
}
