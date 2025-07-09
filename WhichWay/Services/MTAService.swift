//
//  MTAService.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import Foundation
import SwiftProtobuf
import Zip

// MARK: - Error Types

enum GTFSDataError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case extractionFailed
    case processingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid GTFS URL"
        case .downloadFailed:
            return "Failed to download GTFS data"
        case .extractionFailed:
            return "Failed to extract GTFS data"
        case .processingFailed:
            return "Failed to process GTFS data"
        }
    }
}

/// Fetch and update SwiftData models weekly to see where the train positioning is and if any new stations or tracks have been added
actor MTAService {
    private let session = URLSession.shared
    private let feedURL = URL(string: "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace")!
    private let baseSubwayInfoURL = URL(string: "https://rrgtfsfeeds.s3.amazonaws.com/gtfs_subway.zip")
    
    
    /// Fetches and decodes the GTFS-RT FeedMessage.
    func fetchFeed() async throws -> TransitRealtime_FeedMessage {
        var req = URLRequest(url: feedURL)
        req.httpMethod = "GET"
        let (data, _) = try await session.data(for: req)
        // Decode binary into generated Swift struct:
        //print(try TransitRealtime_FeedMessage(serializedBytes: data))
        return try TransitRealtime_FeedMessage(serializedBytes: data)
    }
    
    /// Fetches the base subway data weekly to ensure no stale data on track and station closures
    func fetchBaseData() async throws {
        guard let url = baseSubwayInfoURL else {
            throw GTFSDataError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GTFSDataError.downloadFailed
        }
    }
    
    /// Decodes the base subway data persists to swiftdata
    func decodeBaseData() async throws {
        
    }
}
