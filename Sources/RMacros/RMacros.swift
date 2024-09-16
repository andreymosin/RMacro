// The Swift Programming Language
// https://docs.swift.org/swift-book

import SwiftUI

@attached(member, names: arbitrary)
public macro FeatureTest<R, V>() = #externalMacro(module: "RMacrosMacros", type: "FeatureTestMacro")

