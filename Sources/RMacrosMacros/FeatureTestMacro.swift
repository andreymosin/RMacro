import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation

public struct FeatureTestMacro: MemberMacro {
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
            takeSnapshot(reducer: reducer, view: view).as(DeclSyntax.self),
            makeSut(reducer: reducer).as(DeclSyntax.self)
        ]
            .compactMap { $0 }
    }
}

// MARK: - takeSnapshot
extension FeatureTestMacro {
    private static func takeSnapshot(
        reducer: GenericArgumentListSyntax.Element,
        view: GenericArgumentListSyntax.Element
    ) -> FunctionDeclSyntax {
        FunctionDeclSyntax(
            funcKeyword: .keyword(.func, trailingTrivia: .spaces(1)),
            name: .identifier("takeSnapshot"),
            signature: signature(reducer: reducer),
            body: body(reducer: reducer, view: view)
        )
    }

    private static func signature(
        reducer: GenericArgumentListSyntax.Element
    ) -> FunctionSignatureSyntax {
        .init(
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
        )
    }


    private static func body(
        reducer: GenericArgumentListSyntax.Element,
        view: GenericArgumentListSyntax.Element
    ) -> CodeBlockSyntax {
        .init(statements: .init(stringLiteral:
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
    }
}

// MARK: - makeSut
extension FeatureTestMacro {
/*
 private func makeSut(state: State = .init()) -> TestStoreOf<BrowseTabFeature> {
         .init(initialState: state, reducer: BrowseTabFeature.init)
     }
 */

    static func makeSut(reducer: GenericArgumentListSyntax.Element) -> FunctionDeclSyntax {
        .init(name: "makeSut", signature: sutSignature(reducer: reducer))
    }

    private static func sutSignature(
        reducer: GenericArgumentListSyntax.Element
    ) -> FunctionSignatureSyntax {
        .init(
            parameterClause: .init(
                parameters:
                        .init(
                            [
                                .init(
                                    firstName: .identifier("state"),
                                    colon: .colonToken(trailingTrivia: .spaces(1)),
                                    type: TypeSyntax(stringLiteral: "State?")
                                )
                            ]
                        )
            )
        )
    }
}

// MARK: - Helpers
extension FeatureTestMacro {
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
}
