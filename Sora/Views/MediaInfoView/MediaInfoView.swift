//
//  MediaInfoView.swift
//  Sora
//
//  Created by Francesco on 05/01/25.
//

import SwiftUI
import Kingfisher
import SafariServices

struct MediaItem: Identifiable {
    let id = UUID()
    let description: String
    let aliases: String
    let airdate: String
}

struct MediaInfoView: View {
    let title: String
    let imageUrl: String
    let href: String
    let module: ScrapingModule
    
    @State var aliases: String = ""
    @State var synopsis: String = ""
    @State var airdate: String = ""
    @State var episodeLinks: [EpisodeLink] = []
    @State var itemID: Int?
    
    @State var isLoading: Bool = true
    @State var showFullSynopsis: Bool = false
    @State var hasFetched: Bool = false
    @State var isRefetching: Bool = true
    @State var isFetchingEpisode: Bool = false
    
    @AppStorage("externalPlayer") private var externalPlayer: String = "Default"
    @AppStorage("episodeChunkSize") private var episodeChunkSize: Int = 100
    
    @StateObject private var jsController = JSController()
    @EnvironmentObject var moduleManager: ModuleManager
    @EnvironmentObject private var libraryManager: LibraryManager
    
    @State private var selectedRange: Range<Int> = 0..<100
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .top, spacing: 10) {
                            KFImage(URL(string: imageUrl))
                                .resizable()
                                .aspectRatio(2/3, contentMode: .fill)
                                .cornerRadius(10)
                                .frame(width: 150, height: 225)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(title)
                                    .font(.system(size: 17))
                                    .fontWeight(.bold)
                                    .onLongPressGesture {
                                        UIPasteboard.general.string = title
                                        DropManager.shared.showDrop(title: "Copied to Clipboard", subtitle: "", duration: 1.0, icon: UIImage(systemName: "doc.on.clipboard.fill"))
                                    }
                                
                                if !aliases.isEmpty && aliases != title && aliases != "N/A" && aliases != "No Data" {
                                    Text(aliases)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if !airdate.isEmpty && airdate != "N/A" && airdate != "No Data" {
                                    HStack(alignment: .center, spacing: 12) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "calendar")
                                                .resizable()
                                                .frame(width: 15, height: 15)
                                                .foregroundColor(.secondary)
                                            
                                            Text(airdate)
                                                .font(.system(size: 12))
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(4)
                                    }
                                }
                                
                                HStack(alignment: .center, spacing: 12) {
                                    Button(action: {
                                        openSafariViewController(with: href)
                                    }) {
                                        HStack(spacing: 4) {
                                            Text(module.metadata.sourceName)
                                                .font(.system(size: 13))
                                                .foregroundColor(.primary)
                                            
                                            Image(systemName: "safari")
                                                .resizable()
                                                .frame(width: 20, height: 20)
                                                .foregroundColor(.primary)
                                        }
                                        .padding(4)
                                        .background(Capsule().fill(Color.accentColor.opacity(0.4)))
                                    }
                                }
                            }
                        }
                        
                        if !synopsis.isEmpty {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .center) {
                                    Text("Synopsis")
                                        .font(.system(size: 18))
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    Button(action: {
                                        showFullSynopsis.toggle()
                                    }) {
                                        Text(showFullSynopsis ? "Less" : "More")
                                            .font(.system(size: 14))
                                    }
                                }
                                
                                Text(synopsis)
                                    .lineLimit(showFullSynopsis ? nil : 4)
                                    .font(.system(size: 14))
                            }
                        }
                        
                        HStack {
                            Button(action: {
                            }) {
                                HStack {
                                    Image(systemName: "play.fill")
                                        .foregroundColor(.primary)
                                    Text("Start Watching")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.accentColor)
                                .cornerRadius(10)
                            }
                            
                            Button(action: {
                                libraryManager.toggleBookmark(
                                    title: title,
                                    imageUrl: imageUrl,
                                    href: href,
                                    moduleId: module.id.uuidString
                                )
                            }) {
                                Image(systemName: libraryManager.isBookmarked(href: href) ? "bookmark.fill" : "bookmark")
                                    .resizable()
                                    .frame(width: 20, height: 27)
                                    .foregroundColor(Color.accentColor)
                            }
                        }
                        
                        if !episodeLinks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Episodes")
                                        .font(.system(size: 18))
                                        .fontWeight(.bold)
                                    
                                    Spacer()
                                    
                                    if episodeLinks.count > episodeChunkSize {
                                        Menu {
                                            ForEach(generateRanges(), id: \.self) { range in
                                                Button(action: {
                                                    selectedRange = range
                                                }) {
                                                    Text("\(range.lowerBound + 1)-\(range.upperBound)")
                                                }
                                            }
                                        } label: {
                                            Text("\(selectedRange.lowerBound + 1)-\(selectedRange.upperBound)")
                                                .font(.system(size: 14))
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                                
                                ForEach(episodeLinks.indices.filter { selectedRange.contains($0) }, id: \.self) { i in
                                    let ep = episodeLinks[i]
                                    let lastPlayedTime = UserDefaults.standard.double(forKey: "lastPlayedTime_\(ep.href)")
                                    let totalTime = UserDefaults.standard.double(forKey: "totalTime_\(ep.href)")
                                    let progress = totalTime > 0 ? lastPlayedTime / totalTime : 0
                                    
                                    EpisodeCell(episode: ep.href, episodeID: ep.number - 1, progress: progress, itemID: itemID ?? 0)
                                        .onTapGesture {
                                            if !isFetchingEpisode {
                                                isFetchingEpisode = true
                                                fetchStream(href: ep.href)
                                                DropManager.shared.showDrop(title: "Fetching Stream", subtitle: "", duration: 1.0, icon: UIImage(systemName: "arrow.triangle.2.circlepath"))
                                            }
                                        }
                                        .disabled(isFetchingEpisode)
                                }
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Episodes")
                                    .font(.system(size: 18))
                                    .fontWeight(.bold)
                            }
                            VStack(spacing: 8) {
                                if isRefetching {
                                    ProgressView()
                                        .padding()
                                } else {
                                    Image(systemName: "exclamationmark.triangle")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    HStack(spacing: 2) {
                                        Text("No episodes Found:")
                                            .foregroundColor(.secondary)
                                        Button(action: {
                                            isRefetching = true
                                            fetchDetails()
                                        }) {
                                            Text("Retry")
                                                .foregroundColor(.accentColor)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                    .navigationBarTitleDisplayMode(.inline)
                    .navigationBarTitle("")
                    .navigationViewStyle(StackNavigationViewStyle())
                }
            }
        }
        .onAppear {
            if !hasFetched {
                DropManager.shared.showDrop(title: "Fetching Data", subtitle: "Please wait while fetching", duration: 1.0, icon: UIImage(systemName: "arrow.triangle.2.circlepath"))
                fetchDetails()
                fetchItemID(byTitle: title) { result in
                    switch result {
                    case .success(let id):
                        itemID = id
                    case .failure(let error):
                        Logger.shared.log("Failed to fetch Item ID: \(error)")
                    }
                }
                hasFetched = true
            }
            selectedRange = 0..<episodeChunkSize
        }
    }
    
    private func generateRanges() -> [Range<Int>] {
        let chunkSize = episodeChunkSize
        let totalEpisodes = episodeLinks.count
        var ranges: [Range<Int>] = []
        
        for i in stride(from: 0, to: totalEpisodes, by: chunkSize) {
            let end = min(i + chunkSize, totalEpisodes)
            ranges.append(i..<end)
        }
        
        return ranges
    }
    
    func fetchDetails() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                do {
                    let jsContent = try moduleManager.getModuleContent(module)
                    jsController.loadScript(jsContent)
                    if module.metadata.asyncJS == true {
                        jsController.fetchDetailsJS(url: href) { items, episodes in
                            if let item = items.first {
                                self.synopsis = item.description
                                self.aliases = item.aliases
                                self.airdate = item.airdate
                            }
                            self.episodeLinks = episodes
                            self.isLoading = false
                            self.isRefetching = false
                        }
                    }
                    else {
                        jsController.fetchDetails(url: href) { items, episodes in
                            if let item = items.first {
                                self.synopsis = item.description
                                self.aliases = item.aliases
                                self.airdate = item.airdate
                            }
                            self.episodeLinks = episodes
                            self.isLoading = false
                            self.isRefetching = false
                        }
                    }
                } catch {
                    Logger.shared.log("Error loading module: \(error)", type: "Error")
                    self.isLoading = false
                    self.isRefetching = false
                }
            }
        }
    }
    
    func fetchStream(href: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                do {
                    let jsContent = try moduleManager.getModuleContent(module)
                    jsController.loadScript(jsContent)
                    
                    if module.metadata.asyncJS == true {
                        jsController.fetchStreamUrlJS(episodeUrl: href) { streamUrl in
                            guard let url = streamUrl, url != "null" else {
                                handleStreamFailure()
                                return
                            }
                            playStream(url: url, fullURL: href)
                            isFetchingEpisode = false
                        }
                    } else {
                        jsController.fetchStreamUrl(episodeUrl: href) { streamUrl in
                            guard let url = streamUrl, url != "null" else {
                                handleStreamFailure()
                                return
                            }
                            playStream(url: url, fullURL: href)
                            isFetchingEpisode = false
                        }
                    }
                } catch {
                    handleStreamFailure(error: error)
                    isFetchingEpisode = false
                }
            }
        }
    }
    
    func handleStreamFailure(error: Error? = nil) {
        if let error = error {
            Logger.shared.log("Error loading module: \(error)", type: "Error")
        }
        DropManager.shared.showDrop(title: "Stream not Found", subtitle: "", duration: 1.0, icon: UIImage(systemName: "xmark"))
        self.isLoading = false
    }
    
    func playStream(url: String, fullURL: String) {
        DispatchQueue.main.async {
            let videoPlayerViewController = VideoPlayerViewController(module: module)
            videoPlayerViewController.streamUrl = url
            videoPlayerViewController.fullUrl = fullURL
            videoPlayerViewController.modalPresentationStyle = .fullScreen
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                rootVC.present(videoPlayerViewController, animated: true, completion: nil)
            }
        }
    }
    
    private func openSafariViewController(with urlString: String) {
        guard let url = URL(string: urlString) else {
            Logger.shared.log("Unable to open the webpage", type: "Error")
            return
        }
        let safariViewController = SFSafariViewController(url: url)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(safariViewController, animated: true, completion: nil)
        }
    }
    
    private func fetchItemID(byTitle title: String, completion: @escaping (Result<Int, Error>) -> Void) {
        let query = """
        query {
            Media(search: "\(title)", type: ANIME) {
                id
            }
        }
        """
        
        guard let url = URL(string: "https://graphql.anilist.co") else {
            completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters: [String: Any] = ["query": query]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        
        URLSession.custom.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let media = data["Media"] as? [String: Any],
                   let id = media["id"] as? Int {
                    completion(.success(id))
                } else {
                    let error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
                    completion(.failure(error))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
