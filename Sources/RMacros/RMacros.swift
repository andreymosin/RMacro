// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

@attached(member)
public macro FeatureTest<R, V: View>() = #externalMacro(module: "RMacrosMacros", type: "FeatureTestMacro")

