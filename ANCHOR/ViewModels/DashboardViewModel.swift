//
//  DashboardViewModel.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/26/25.
//

import Foundation
import Combine

class DashboardViewModel: ObservableObject, Identifiable, Codable {
    let id: UUID
    var title: String
    var body: String?
    
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case id, title, body, isLoading, showAlert, alertMessage
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try container.decode(String.self, forKey: .title)
        body = try container.decodeIfPresent(String.self, forKey: .body)
        isLoading = try container.decode(Bool.self, forKey: .isLoading)
        showAlert = try container.decode(Bool.self, forKey: .showAlert)
        alertMessage = try container.decode(String.self, forKey: .alertMessage)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(body, forKey: .body)
        try container.encode(isLoading, forKey: .isLoading)
        try container.encode(showAlert, forKey: .showAlert)
        try container.encode(alertMessage, forKey: .alertMessage)
    }
    
    // MARK: - Initializers
    
    init(id: UUID = UUID(), title: String, body: String? = nil) {
        self.id = id
        self.title = title
        self.body = body
    }
    
    // Add any other methods needed for the dashboard
}
