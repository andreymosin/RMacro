import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(RMacrosMacros)
import RMacrosMacros

let testMacros: [String: Macro.Type] = [
    "FeatureTest": FeatureTestMacro.self,
]
#endif

final class RMacrosTests: XCTestCase {
    func testFeatureTest() {
        assertMacroExpansion(
            """
@FeatureTest<BrowseTabFeature, BrowseTabView>
class BrowseTabFeatureTests: XCTestCase {
}
""",
            expandedSource: """
            class BrowseTabFeatureTests: XCTestCase {

                typealias Feature = BrowseTabFeature

                typealias State = BrowseTabFeature.State

                func takeSnapshot(state: BrowseTabFeature.State, testName: String) {
                    let store = StoreOf<BrowseTabFeature>(initialState: state, reducer: EmptyReducer.init)
                    let view = BrowseTabView(store: store)

                    assertSnapshots(
                        of: view.toVC(backgroundColor: .white),
                        as: [
                            .image(on: .iPhone13Pro, perceptualPrecision: perceptualPrecision),
                            .image(on: .iPadPro11(.portrait), perceptualPrecision: perceptualPrecision)
                        ],
                        testName: testName
                    )
                }
            }
            """,
            macros: testMacros
        )
    }
}
