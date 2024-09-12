import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

@main
struct RMacrosPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        FeatureTestMacro.self
    ]
}
