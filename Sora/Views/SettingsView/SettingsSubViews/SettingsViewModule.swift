//
//  SettingsViewModule.swift
//  Sora
//
//  Created by Francesco on 05/01/25.
//

import SwiftUI
import Kingfisher

struct SettingsViewModule: View {
    @AppStorage("selectedModuleId") private var selectedModuleId: String?
    @EnvironmentObject var moduleManager: ModuleManager
    
    @State private var errorMessage: String?
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            Form {
                if moduleManager.modules.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "plus.app")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Modules")
                            .font(.headline)
                        Text("Click the plus button to add a module!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                else {
                    ForEach(moduleManager.modules) { module in
                        HStack {
                            KFImage(URL(string: module.metadata.iconUrl))
                                .resizable()
                                .frame(width: 50, height: 50)
                                .clipShape(Circle())
                                .padding(.trailing, 10)
                            
                            VStack(alignment: .leading) {
                                HStack(alignment: .bottom, spacing: 4) {
                                    Text(module.metadata.sourceName)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("v\(module.metadata.version)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text("Author: \(module.metadata.author)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Text("Language: \(module.metadata.language)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if module.id.uuidString == selectedModuleId {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.accentColor)
                                    .frame(width: 25, height: 25)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedModuleId = module.id.uuidString
                        }
                        .contextMenu {
                            Button(action: {
                                UIPasteboard.general.string = module.metadataUrl
                                DropManager.shared.showDrop(title: "Copied to Clipboard", subtitle: "", duration: 1.0, icon: UIImage(systemName: "doc.on.clipboard.fill"))
                            }) {
                                Label("Copy URL", systemImage: "doc.on.doc")
                            }
                            Button(role: .destructive) {
                                if selectedModuleId != module.id.uuidString {
                                    moduleManager.deleteModule(module)
                                    DropManager.shared.showDrop(title: "Module Removed", subtitle: "", duration: 1.0, icon: UIImage(systemName: "trash"))
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            .disabled(selectedModuleId == module.id.uuidString)
                        }
                        .swipeActions {
                            if selectedModuleId != module.id.uuidString {
                                Button(role: .destructive) {
                                    moduleManager.deleteModule(module)
                                    DropManager.shared.showDrop(title: "Module Removed", subtitle: "", duration: 1.0, icon: UIImage(systemName: "trash"))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Modules")
            .navigationBarItems(trailing: Button(action: {
                showAddModuleAlert()
            }) {
                Image(systemName: "plus")
                    .resizable()
                    .padding(5)
            })
        }
        .alert(isPresented: .constant(errorMessage != nil)) {
            Alert(
                title: Text("Error"),
                message: Text(errorMessage ?? "Unknown error"),
                dismissButton: .default(Text("OK")) {
                    errorMessage = nil
                }
            )
        }
    }
    
    func showAddModuleAlert() {
        let alert = UIAlertController(title: "Add Module", message: "Enter the URL of the module file", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "https://real.url/module.json"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Add", style: .default, handler: { _ in
            if let url = alert.textFields?.first?.text {
                addModule(from: url)
            }
        }))
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    private func addModule(from url: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                _ = try await moduleManager.addModule(metadataUrl: url)
                DispatchQueue.main.async {
                    isLoading = false
                    DropManager.shared.showDrop(title: "Module Added", subtitle: "clicking it to select it", duration: 2.0, icon: UIImage(systemName: "app.badge.checkmark"))
                }
            } catch {
                DispatchQueue.main.async {
                    isLoading = false
                    if (error as NSError).domain == "Module already exists" {
                        errorMessage = "Module already exists"
                    } else {
                        errorMessage = "Failed to add module: \(error.localizedDescription)"
                    }
                    Logger.shared.log("Failed to add module: \(error.localizedDescription)")
                }
            }
        }
    }
}
