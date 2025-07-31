//
//  AppSettingsManager.swift
//  MovieWords
//
//  Created by pei on 2025/7/30.
//

import Foundation
import Combine

// The data structure for our dictionary settings.
struct DictControl: Codable, Equatable {
    var Using_All_Dicts: Bool
    var Selected_Dictionary_ShortName: String
}

/// A singleton class to manage loading, saving, and providing dictionary settings globally.
@MainActor
class AppSettingsManager: ObservableObject {
    
    static let shared = AppSettingsManager()
    @Published var dictControl: DictControl
    
    private var configPlistURL: URL {
        return AppPath.configURL
    }
    
    private init() {
        self.dictControl = DictControl(Using_All_Dicts: true, Selected_Dictionary_ShortName: "")
        load()
    }
    
    func load() {
        guard FileManager.default.fileExists(atPath: configPlistURL.path) else {
            print("Config file not found. Using default dictionary settings.")
            return
        }
        
        do {
            let data = try Data(contentsOf: configPlistURL)
            let decoder = PropertyListDecoder()
            let decodedData = try decoder.decode(AppSettings.self, from: data)
            self.dictControl = decodedData.Dict_Control
            print("✅ Dictionary settings loaded successfully.")
        } catch {
            print("❌ Failed to load or decode plist for dictionary settings: \(error)")
        }
    }
    
    // MARK: - DEFINITIVE FIX
    // The save function is rewritten to use the modern Codable pattern,
    // avoiding the problematic PropertyListSerialization API entirely.
    func save() {
        guard FileManager.default.fileExists(atPath: configPlistURL.path) else {
            print("❌ Cannot save: Config file not found at \(configPlistURL.path)")
            return
        }

        do {
            // 1. Decode the entire plist into our AppSettings struct.
            let data = try Data(contentsOf: configPlistURL)
            var fullSettings = try PropertyListDecoder().decode(AppSettings.self, from: data)
            
            // 2. Modify the part of the struct that this manager is responsible for.
            fullSettings.Dict_Control = self.dictControl
            
            // 3. Encode the entire modified struct back to data.
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml // Ensure it's saved in a readable format
            let finalData = try encoder.encode(fullSettings)
            
            // 4. Write the new data to the file, overwriting the old one.
            try finalData.write(to: configPlistURL, options: .atomic)
            print("✅ Dictionary settings saved successfully via Codable.")
            
        } catch {
            print("❌ Failed to save dictionary settings to plist: \(error)")
        }
    }
}
