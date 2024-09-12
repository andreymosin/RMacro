import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation


public struct FeatureTestMacro: MemberMacro {

    static func createTypealiasSyntax(name: String, type: GenericArgumentListSyntax.Element, child: TokenSyntax? = nil) -> TypeAliasDeclSyntax {
        let value: TypeSyntaxProtocol

        if let child {
            value = MemberTypeSyntax(baseType: type.argument, name: child)
        } else {
            value = type.argument
        }

        return TypeAliasDeclSyntax(
            name: TokenSyntax.identifier(name, leadingTrivia: .spaces(1)),
            initializer: TypeInitializerClauseSyntax(
                equal: .equalToken(leadingTrivia: .spaces(1), trailingTrivia: .spaces(1)),
                value: value
            )
        )
    }

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context:
        some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let generics = node.attributeName
            .as(IdentifierTypeSyntax.self)?
            .genericArgumentClause?
            .arguments
        else { return [] }

        guard
            let reducer = generics.first,
            let view = generics.last
        else { return [] }

        let featureTypeAlias = createTypealiasSyntax(name: "Feature", type: reducer)
        let stateTypeAlias = createTypealiasSyntax(name: "State", type: reducer, child: .identifier("State"))

        return [
            featureTypeAlias.as(DeclSyntax.self),
            stateTypeAlias.as(DeclSyntax.self),
            takeSnapshot(reducer: reducer, view: view).as(DeclSyntax.self)
        ]
            .compactMap { $0 }
    }

    private static func takeSnapshot(
        reducer: GenericArgumentListSyntax.Element,
        view: GenericArgumentListSyntax.Element
    ) -> FunctionDeclSyntax {

        return FunctionDeclSyntax(
            funcKeyword: .keyword(.func, trailingTrivia: .spaces(1)),
            name: .identifier("takeSnapshot"),
            signature: .init(
                parameterClause: .init(
                    parameters:
                            .init(
                                [
                                    .init(
                                        firstName: .identifier("state"),
                                        colon: .colonToken(trailingTrivia: .spaces(1)),
                                        type: MemberTypeSyntax(
                                            baseType: reducer.argument,
                                            name: .identifier("State")
                                        ),
                                        trailingComma: .commaToken(trailingTrivia: .spaces(1))
                                    ),
                                    .init(
                                        firstName: .identifier("testName"),
                                        colon: .colonToken(trailingTrivia: .spaces(1)),
                                        type: TypeSyntax(stringLiteral: "String")
                                    )
                                ]
                            )
                )
            ),
            body: .init(statements: .init(stringLiteral:
"""
let store = StoreOf<\(reducer.argument)>(initialState: state, reducer: EmptyReducer.init)
let view = \(view.argument)(store: store)

assertSnapshots(
    of: view.toVC(backgroundColor: .white),
    as: [
        .image(on: .iPhone13Pro, perceptualPrecision: perceptualPrecision),
        .image(on: .iPadPro11(.portrait), perceptualPrecision: perceptualPrecision)
    ],
    testName: testName
)
"""
                                         )
            )
        )
    }
}


