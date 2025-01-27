//
//  SoraApp.swift
//  Sora
//
//  Created by Francesco on 06/01/25.
//

import SwiftUI

@main
struct SoraApp: App {
    @StateObject private var settings = Settings()
    @StateObject private var moduleManager = ModuleManager()
    @StateObject private var librarykManager = LibraryManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(moduleManager)
                .environmentObject(settings)
                .environmentObject(librarykManager)
                .accentColor(settings.accentColor)
                .onAppear {
                    settings.updateAppearance()
                }
                .onOpenURL { url in
                    handleURL(url)
                }
        }
    }
    
    private func handleURL(_ url: URL) {
        guard url.scheme == "sora",
              url.host == "module",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let moduleURL = components.queryItems?.first(where: { $0.name == "url" })?.value else {
                  return
              }
        
        Task {
            do {
                let module = try await moduleManager.addModule(metadataUrl: moduleURL)
                DropManager.shared.showDrop(title: "Added \(module.metadata.sourceName)", subtitle: "Check settings to select it", duration: 2.0, icon: UIImage(systemName: "app.badge.checkmark"))
            } catch {
                Logger.shared.log("Failed to add module from URL scheme: \(error.localizedDescription)", type: "Error")
            }
        }
    }
}
