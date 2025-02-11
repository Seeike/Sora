//
//  AniList-MediaInfo.swift
//  Sora
//
//  Created by Francesco on 11/02/25.
//

import Foundation

class AnilistServiceMediaInfo {
    static func fetchAnimeDetails(animeID: Int, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        let query = """
        query {
            Media(id: \(animeID), type: ANIME) {
                id
                idMal
                title {
                    romaji
                    english
                    native
                    userPreferred
                }
                type
                format
                status
                description
                startDate {
                    year
                    month
                    day
                }
                endDate {
                    year
                    month
                    day
                }
                season
                episodes
                duration
                countryOfOrigin
                isLicensed
                source
                hashtag
                trailer {
                    id
                    site
                }
                updatedAt
                coverImage {
                    extraLarge
                }
                bannerImage
                genres
                popularity
                tags {
                    id
                    name
                }
                relations {
                    nodes {
                        id
                        coverImage { extraLarge }
                        title { userPreferred },
                        mediaListEntry { status }
                    }
                }
                characters {
                    edges {
                        node {
                            name {
                                full
                            }
                            image {
                                large
                            }
                        }
                        role
                        voiceActors {
                            name {
                                first
                                last
                                native
                            }
                        }
                    }
                }
                siteUrl
                stats {
                    scoreDistribution {
                        score
                        amount
                    }
                }
                airingSchedule(notYetAired: true) {
                    nodes {
                        airingAt
                        episode
                    }
                }
            }
        }
        """
        
        let apiUrl = URL(string: "https://graphql.anilist.co")!
        
        var request = URLRequest(url: apiUrl)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: ["query": query], options: [])
        
        URLSession.custom.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "AnimeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data received"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                   let data = json["data"] as? [String: Any],
                   let media = data["Media"] as? [String: Any] {
                    completion(.success(media))
                } else {
                    completion(.failure(NSError(domain: "AnimeService", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
