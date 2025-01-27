//
//  EpisodeCell.swift
//  Sora
//
//  Created by Francesco on 18/12/24.
//

import SwiftUI
import Kingfisher

struct EpisodeLink: Identifiable {
    let id = UUID()
    let number: Int
    let href: String
}

struct EpisodeCell: View {
    let episode: String
    let episodeID: Int
    let progress: Double
    let itemID: Int
    
    @State private var episodeTitle: String = ""
    @State private var episodeImageUrl: String = ""
    @State private var isLoading: Bool = true
    @State private var currentProgress: Double = 0.0
    
    private func markAsWatched() {
        UserDefaults.standard.set(9999999.0, forKey: "lastPlayedTime_\(episode)")
        UserDefaults.standard.set(9999999.0, forKey: "totalTime_\(episode)")
        updateProgress()
    }
    
    private func resetProgress() {
        UserDefaults.standard.set(0.0, forKey: "lastPlayedTime_\(episode)")
        UserDefaults.standard.set(0.0, forKey: "totalTime_\(episode)")
        updateProgress()
    }
    
    private func updateProgress() {
        let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(episode)")
        let totalTime = UserDefaults.standard.double(forKey: "totalTime_\(episode)")
        currentProgress = totalTime > 0 ? lastPlayedTime / totalTime : 0
    }
    
    var body: some View {
        HStack {
            ZStack {
                KFImage(URL(string: episodeImageUrl.isEmpty ? "https://raw.githubusercontent.com/cranci1/Sora/refs/heads/main/assets/banner2.png" : episodeImageUrl))
                    .resizable()
                    .aspectRatio(16/9, contentMode: .fill)
                    .frame(width: 100, height: 56)
                    .cornerRadius(8)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
            }
            
            VStack(alignment: .leading) {
                Text("Episode \(episodeID + 1)")
                    .font(.system(size: 15))
                if !episodeTitle.isEmpty {
                    Text(episodeTitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            CircularProgressBar(progress: currentProgress)
                .frame(width: 40, height: 40)
        }
        .contextMenu {
            Button(action: markAsWatched) {
                Label("Mark as Watched", systemImage: "checkmark.circle")
            }
            
            Button(action: resetProgress) {
                Label("Reset Progress", systemImage: "arrow.counterclockwise")
            }
        }
        .onAppear {
            fetchEpisodeDetails()
            updateProgress()
        }
    }
    
    func fetchEpisodeDetails() {
        guard let url = URL(string: "https://api.ani.zip/mappings?anilist_id=\(itemID)") else {
            isLoading = false
            return
        }
        
        URLSession.custom.dataTask(with: url) { data, _, error in
            if let error = error {
                Logger.shared.log("Failed to fetch episode details: \(error)", type: "Error")
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            do {
                let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
                guard let json = jsonObject as? [String: Any],
                      let episodes = json["episodes"] as? [String: Any],
                      let episodeDetails = episodes["\(episodeID + 1)"] as? [String: Any],
                      let title = episodeDetails["title"] as? [String: String],
                      let image = episodeDetails["image"] as? String else {
                          Logger.shared.log("Invalid response format", type: "Error")
                          DispatchQueue.main.async {
                              self.isLoading = false
                          }
                          return
                      }
                
                DispatchQueue.main.async {
                    self.episodeTitle = title["en"] ?? ""
                    self.episodeImageUrl = image
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
