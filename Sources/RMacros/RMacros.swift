// The Swift Programming Language
// https://docs.swift.org/swift-book

import ComposableArchitecture
import SwiftUI

@attached(member)
public macro FeatureTest<R: Reducer, V: View>() = #externalMacro(module: "RMacrosMacros", type: "FeatureTestMacro")

