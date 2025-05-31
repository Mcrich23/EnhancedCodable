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

public enum CodableIgnoreInitializedProperties: ExtensionMacro {
    public static func expansion(
        of node: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structDecl = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionError.unsupportedDeclaration
        }

        let existingInits = structDecl.memberBlock.members.compactMap {
            $0.decl.as(InitializerDeclSyntax.self)
        }

        let hasFromDecoderInit = existingInits.contains { initDecl in
            guard let firstParam = initDecl.signature.parameterClause.parameters.first else { return false }
            return firstParam.firstName.text == "decoder" &&
                   firstParam.type.description.contains("Decoder")
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

        guard !decodeInitBody.isEmpty, !hasFromDecoderInit else {
            return []
        }

        let decodeInit = """
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            \(decodeInitBody)
        }
        """

        let extensionSyntax = try ExtensionDeclSyntax("extension \(type.trimmed): Decodable {\n\(decodeInit)\n}")

        return [extensionSyntax]
    }
}

@main
struct CodableIgnoreInitializedPropertiesPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        CodableIgnoreInitializedProperties.self,
    ]
}
