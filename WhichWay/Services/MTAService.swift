//
//  MTAService.swift
//  WhichWay
//
//  Created by Jack Anderson on 6/15/25.
//

import Foundation
import SwiftProtobuf

actor MTAService {
  private let session = URLSession.shared
  private let feedURL = URL(string:
    "https://api-endpoint.mta.info/Dataservice/mtagtfsfeeds/nyct%2Fgtfs-ace"
  )!

  /// Fetches and decodes the GTFS-RT FeedMessage.
  func fetchFeed() async throws -> TransitRealtime_FeedMessage {
    var req = URLRequest(url: feedURL)
    req.httpMethod = "GET"
    let (data, _) = try await session.data(for: req)
    // Decode binary into generated Swift struct:
      print(try TransitRealtime_FeedMessage(serializedBytes: data))
      return try TransitRealtime_FeedMessage(serializedBytes: data)
  }
}
