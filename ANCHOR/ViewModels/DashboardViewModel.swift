//
//  DashboardViewModel.swift
//  ANCHOR
//
//  Created by Angad Kumar on 10/26/25.
//

import Foundation
import Combine

class DashboardViewModel: ObservableObject, Codable {
    @Published var isLoading = false
    @Published var showAlert = false
    @Published var alertMessage = ""
    
    // MARK: - Codable
    
    enum CodingKeys: String, CodingKey {
        case isLoading, showAlert, alertMessage
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        isLoading = try container.decode(Bool.self, forKey: .isLoading)
        showAlert = try container.decode(Bool.self, forKey: .showAlert)
        alertMessage = try container.decode(String.self, forKey: .alertMessage)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(isLoading, forKey: .isLoading)
        try container.encode(showAlert, forKey: .showAlert)
        try container.encode(alertMessage, forKey: .alertMessage)
    }
    
    // Add any other properties and methods needed for the dashboard
    
    init() {
        // Initialize any required services or data
    }
    
    // Add methods for fetching data, handling user actions, etc.
}
