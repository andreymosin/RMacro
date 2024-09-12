import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Foundation


public struct FeatureTestMacros: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        in context:
        some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDelc = declaration as? ClassDeclSyntax else { return [] }

        let attributes = classDelc.attributes

        let first = attributes.first!.as(AttributeSyntax.self)

        let firstArgs = first!.arguments!.as(LabeledExprListSyntax.self)!

        let reducer = firstArgs.first!.expression.description.dropLast(5)
        let view = firstArgs.last!.expression.description.dropLast(5)

        let result: DeclSyntax =
        """
        typealias State = \(raw: reducer).State
        
        func makeSut(state: State = .init()) -> TestStoreOf<\(raw: reducer)> {
            .init(initialState: state, reducer: \(raw: reducer).init)
        }

        func takeSnapshot(state: State, testName: String) {
            let store = StoreOf<\(raw: reducer)>(initialState: state, reducer: EmptyReducer.init)
            let view = \(raw: view)(store: store)

            assertSnapshots(
                of: view.toVC(backgroundColor: .white),
                as: [
                    .image(on: .iPhone13Pro, perceptualPrecision: perceptualPrecision),
                    .image(on: .iPadPro11(.portrait), perceptualPrecision: perceptualPrecision)
                ],
                testName: testName
            )
        }
        """


        return [result]
    }
}
