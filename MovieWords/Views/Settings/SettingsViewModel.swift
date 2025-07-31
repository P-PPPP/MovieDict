import Foundation
import SwiftUI

// MARK: - 数据模型
struct AppInfo: Codable, Equatable {
    var GitHub: String
    var Version: String
    var Author: String
}

struct SettingsData: Codable, Equatable {
    var HotKeys: Int
}

struct AppSettings: Codable {
    var Info: AppInfo
    var Settings: SettingsData
    var Dict_Control: DictControl
}

// MARK: - ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var appInfo: AppInfo
    @Published var hotkeyDidChange = false
    @Published var currentSettings: SettingsData
    @Published var dictControl: DictControl
    @Published var availableSystemDictionaries: [TTTDictionary] = []
    
    private var originalSettings: SettingsData?
    private var originalDictControl: DictControl?
    
    var isModified: Bool {
        guard let originalSettings = originalSettings, let originalDictControl = originalDictControl else { return false }
        return originalSettings != currentSettings || originalDictControl != dictControl
    }
    
    var isSaveConfigurationValid: Bool {
        if dictControl.Using_All_Dicts { return true }
        else { return !dictControl.Selected_Dictionary_ShortName.isEmpty }
    }
    
    struct HotkeyOption: Identifiable, Hashable {
        let id: Int
        let name: String
    }
    
    let availableHotkeys: [HotkeyOption] = [
        HotkeyOption(id: 49, name: "空格 (Space)"), HotkeyOption(id: 122, name: "F1"),
        HotkeyOption(id: 120, name: "F2"), HotkeyOption(id: 99, name: "F3"),
        HotkeyOption(id: 118, name: "F4"), HotkeyOption(id: 96, name: "F5")
    ]
    
    private var configPlistURL: URL? { AppPath.configURL }
    
    init() {
        self.appInfo = AppInfo(GitHub: "", Version: "N/A", Author: "N/A")
        self.currentSettings = SettingsData(HotKeys: 49)
        self.dictControl = AppSettingsManager.shared.dictControl
        
        loadSettings()
        fetchAvailableDictionaries()
    }
    
    func loadSettings() {
        guard let url = configPlistURL, FileManager.default.fileExists(atPath: url.path) else {
            self.originalSettings = self.currentSettings
            self.originalDictControl = self.dictControl
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let decodedData = try decoder.decode(AppSettings.self, from: data)
            
            self.appInfo = decodedData.Info
            self.currentSettings.HotKeys = decodedData.Settings.HotKeys
            self.dictControl = decodedData.Dict_Control
            
            self.originalSettings = self.currentSettings
            self.originalDictControl = decodedData.Dict_Control
        } catch {
            print("加载或解析 plist 文件失败: \(error)")
            self.originalSettings = self.currentSettings
            self.originalDictControl = self.dictControl
        }
    }
    
    func saveSettings() async {
        AppSettingsManager.shared.dictControl = self.dictControl
        AppSettingsManager.shared.save()
        
        if self.currentSettings.HotKeys != self.originalSettings?.HotKeys {
            saveHotKeySetting()
            self.hotkeyDidChange = true
        }
        
        self.originalSettings = self.currentSettings
        self.originalDictControl = self.dictControl
        print("设置视图更改已保存。")
    }
    
    // MARK: - DEFINITIVE FIX
    // This function is rewritten to use the modern Codable pattern.
    private func saveHotKeySetting() {
        guard let url = configPlistURL, FileManager.default.fileExists(atPath: url.path) else { return }
        do {
            // 1. Decode the entire plist.
            let data = try Data(contentsOf: url)
            var fullSettings = try PropertyListDecoder().decode(AppSettings.self, from: data)

            // 2. Modify the hotkey setting.
            fullSettings.Settings.HotKeys = self.currentSettings.HotKeys

            // 3. Encode the entire modified struct back to data.
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let finalData = try encoder.encode(fullSettings)
            
            // 4. Write the new data to the file.
            try finalData.write(to: url, options: .atomic)
            
        } catch {
            print("❌ 保存热键设置失败: \(error)")
        }
    }
    
    func cancelChanges() {
        if let original = originalSettings { self.currentSettings = original }
        if let original = originalDictControl { self.dictControl = original }
        self.hotkeyDidChange = false
    }

    func resetToDefaults() {
        self.currentSettings.HotKeys = 49
        self.dictControl = DictControl(Using_All_Dicts: true, Selected_Dictionary_ShortName: "")
    }
    
    private func fetchAvailableDictionaries() {
        self.availableSystemDictionaries = TTTDictionary.availableDictionaries().sorted { $0.name < $1.name }
    }
}
