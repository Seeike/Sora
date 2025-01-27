//
//  SettingsViewUI.swift
//  Sora
//
//  Created by Francesco on 27/01/25.
//

import SwiftUI

struct SettingsViewUI: View {
    @AppStorage("episodeChunkSize") private var episodeChunkSize: Int = 100
    @EnvironmentObject var settings: Settings
    
    var body: some View {
        Form {
            Section(header: Text("Interface")) {
                ColorPicker("Accent Color", selection: $settings.accentColor)
                HStack() {
                    Text("Appearance")
                    Picker("Appearance", selection: $settings.selectedAppearance) {
                        Text("System").tag(Appearance.system)
                        Text("Light").tag(Appearance.light)
                        Text("Dark").tag(Appearance.dark)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
            }
            
            Section(header: Text("Media View"), footer: Text("The episode range controls how many episodes appear on each page. Episodes are grouped into sets (like 1-25, 26-50, and so on), allowing you to navigate through them more easily.")) {
                HStack {
                    Text("Episodes Range")
                    Spacer()
                    Menu {
                        Button(action: { episodeChunkSize = 25 }) {
                            Text("25")
                        }
                        Button(action: { episodeChunkSize = 50 }) {
                            Text("50")
                        }
                        Button(action: { episodeChunkSize = 75 }) {
                            Text("75")
                        }
                        Button(action: { episodeChunkSize = 100 }) {
                            Text("100")
                        }
                    } label: {
                        Text("\(episodeChunkSize)")
                    }
                }
            }
        }
        .navigationTitle("UI Settings")
    }
}
