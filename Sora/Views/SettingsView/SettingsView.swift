//
//  SettingsView.swift
//  Sora
//
//  Created by Francesco on 05/01/25.
//

import SwiftUI

struct SettingsView: View {
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Main Settings")) {
                    NavigationLink(destination: SettingsViewUI()) {
                        Text("UI Settings")
                    }
                    NavigationLink(destination: SettingsViewModule()) {
                        Text("Media Player")
                    }
                    NavigationLink(destination: SettingsViewModule()) {
                        Text("Modules")
                    }
                }
                
                Section(header: Text("Debug")) {
                    NavigationLink(destination: SettingsViewLogger()) {
                        Text("Logs")
                    }
                }
                
                Section(header: Text("Info")) {
                    Button(action: {
                        if let url = URL(string: "https://github.com/cranci1/Sora") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Sora github repo")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                        }
                    }
                    Button(action: {
                        if let url = URL(string: "https://github.com/cranci1/Sora/issues") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Report an issue")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                        }
                    }
                    Button(action: {
                        if let url = URL(string: "https://discord.gg/x7hppDWFDZ") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Join the Discord")
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "safari")
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

enum Appearance: String, CaseIterable, Identifiable {
    case system, light, dark
    
    var id: String { self.rawValue }
}

class Settings: ObservableObject {
    @Published var accentColor: Color {
        didSet {
            saveAccentColor(accentColor)
        }
    }
    @Published var selectedAppearance: Appearance {
        didSet {
            UserDefaults.standard.set(selectedAppearance.rawValue, forKey: "selectedAppearance")
            updateAppearance()
        }
    }
    
    init() {
        if let colorData = UserDefaults.standard.data(forKey: "accentColor"),
           let uiColor = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(colorData) as? UIColor {
            self.accentColor = Color(uiColor)
        } else {
            self.accentColor = .accentColor
        }
        if let appearanceRawValue = UserDefaults.standard.string(forKey: "selectedAppearance"),
           let appearance = Appearance(rawValue: appearanceRawValue) {
            self.selectedAppearance = appearance
        } else {
            self.selectedAppearance = .system
        }
        updateAppearance()
    }
    
    private func saveAccentColor(_ color: Color) {
        let uiColor = UIColor(color)
        do {
            let colorData = try NSKeyedArchiver.archivedData(withRootObject: uiColor, requiringSecureCoding: false)
            UserDefaults.standard.set(colorData, forKey: "accentColor")
        } catch {
            Logger.shared.log("Failed to save accent color: \(error.localizedDescription)")
        }
    }
    
    func updateAppearance() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        switch selectedAppearance {
        case .system:
            windowScene.windows.first?.overrideUserInterfaceStyle = .unspecified
        case .light:
            windowScene.windows.first?.overrideUserInterfaceStyle = .light
        case .dark:
            windowScene.windows.first?.overrideUserInterfaceStyle = .dark
        }
    }
}
