//
//  CodableIgnoreInitializedProperties.swift
//  EnhancedCodable
//
//  Created by Morris Richman on 6/7/25.
//

import Foundation
import SwiftSyntax
import SwiftSyntaxMacros

public struct CodableIgnoreInitializedProperties: MemberAttributeMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax, providingAttributesFor member: some DeclSyntaxProtocol, in context: some MacroExpansionContext) throws -> [AttributeSyntax] {
        guard let property = member.as (VariableDeclSyntax.self),
              !(property.bindings.first?.initializer == nil && property.bindings.first?.accessorBlock == nil)
        else {
            return []
        }
        
        guard let syntax = AttributeSyntax(IdentifierTypeSyntax(name: .identifier("CodableIgnored"))) else {
            throw MacroExpansionError.unsupportedDeclaration
        }
        
        return [
            syntax
        ]
    }
}
