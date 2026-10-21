// N75StudioApp.swift — entry point.
import SwiftUI

@main
struct N75StudioApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 700, idealWidth: 1120, maxWidth: .infinity,
                       minHeight: 520, idealHeight: 980, maxHeight: .infinity)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1120, height: 980)
    }
}
