import Foundation
import SwiftUI

// MARK: - 数据模型
struct DictionaryInfo: Codable, Hashable, Identifiable {
    var id: String { name }
    let name: String
    let path: String
}

struct AppInfo: Codable, Equatable {
    var GitHub: String
    var Version: String
    var Author: String
}

struct SettingsData: Codable, Equatable {
    var Currnet_Dictionary: String
    var HotKeys: Int

    // 定义 CodingKeys 以匹配 plist 文件中的键名
    enum CodingKeys: String, CodingKey {
        case Currnet_Dictionary
        case HotKeys
    }

    // 自定义解码逻辑
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Currnet_Dictionary 是必须的，正常解码
        self.Currnet_Dictionary = try container.decode(String.self, forKey: .Currnet_Dictionary)
        
        // HotKeys 是新增的，可能在旧文件中不存在
        // 我们使用 decodeIfPresent，如果键存在就解码，如果不存在就返回 nil
        // 然后我们使用 ?? 操作符提供一个默认值 49 (空格)
        self.HotKeys = try container.decodeIfPresent(Int.self, forKey: .HotKeys) ?? 49
    }
    init(Currnet_Dictionary: String, HotKeys: Int) {
        self.Currnet_Dictionary = Currnet_Dictionary
        self.HotKeys = HotKeys
    }
}

struct AppSettings: Codable {
    var Dictions: [String: TmpDict]
    var Info: AppInfo
    var Settings: SettingsData
    
    struct TmpDict: Codable {
        var Name: String
        var Path: String
    }
}


// MARK: - ViewModel
@MainActor
class SettingsViewModel: ObservableObject {
    
    @Published var currentSettings: SettingsData
    @Published var appInfo: AppInfo
    @Published var availableDictionaries: [String: DictionaryInfo] = [:]
    @Published var hotkeyDidChange = false // <-- 新增这一行
    private var originalSettings: SettingsData?
    
    var isModified: Bool {
        guard let original = originalSettings else { return false }
        return original != currentSettings
    }
    
    struct HotkeyOption: Identifiable, Hashable {
        let id: Int // 直接用键码作为ID
        let name: String
    }
    let availableHotkeys: [HotkeyOption] = [
        HotkeyOption(id: 49, name: "空格 (Space)"),
        HotkeyOption(id: 122, name: "F1"),
        HotkeyOption(id: 120, name: "F2"),
        HotkeyOption(id: 99, name: "F3"),
        HotkeyOption(id: 118, name: "F4"),
        HotkeyOption(id: 96, name: "F5")
    ]
    
    private var Config_Plist_URL: URL? {
        // 直接返回由 AppPath 管理的配置文件URL
        return AppPath.configURL
    }
    
    // MARK: - Initialization
    init() {
        // 为 HotKeys 设置默认值（49是空格键）
        self.currentSettings = SettingsData(Currnet_Dictionary: "Dict1", HotKeys: 49) // <-- 修改这一行
        self.appInfo = AppInfo(GitHub: "", Version: "N/A", Author: "N/A")
        loadSettings()
    }
    
    // MARK: - Public Methods
    
    /// 从应用支持目录加载设置
    func loadSettings() {
        guard let url = Config_Plist_URL, FileManager.default.fileExists(atPath: url.path) else {
            print("错误：配置文件不存在于预期的路径，无法加载。")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            let decodedData = try decoder.decode(AppSettings.self, from: data)
            
            self.currentSettings = decodedData.Settings
            self.appInfo = decodedData.Info
            
            var dicts: [String: DictionaryInfo] = [:]
            for (key, value) in decodedData.Dictions {
                dicts[key] = DictionaryInfo(name: value.Name, path: value.Path)
            }
            self.availableDictionaries = dicts
            
            self.originalSettings = decodedData.Settings
            
            print("设置从 \(url.path) 加载成功！")
        } catch {
            print("加载或解析 plist 文件失败: \(error)")
        }
    }
    
    /// 将当前设置保存到应用支持目录
    func saveSettings() async {
        guard let url = Config_Plist_URL else { return }
        
        // ... (构建 settingsToSave 的代码保持不变)
        var dictsToSave: [String: AppSettings.TmpDict] = [:]
        for (key, value) in self.availableDictionaries {
            dictsToSave[key] = AppSettings.TmpDict(Name: value.name, Path: value.path)
        }
        let settingsToSave = AppSettings(Dictions: dictsToSave, Info: self.appInfo, Settings: self.currentSettings)
        
        do {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml
            let data = try encoder.encode(settingsToSave)
            
            // 最小改动：在同步的IO操作前插入一个微小的挂起点，以消除编译器警告。
            try await Task.sleep(for: .nanoseconds(1))
            
            try data.write(to: url, options: .atomic)

            // 检查保存的设置和原始设置的HotKeys是否不同
            if self.currentSettings.HotKeys != self.originalSettings?.HotKeys {
                self.hotkeyDidChange = true
            }

            self.originalSettings = self.currentSettings
            print("设置已成功保存到 \(url.path)！")
        } catch {
            print("保存 plist 文件失败: \(error)")
        }
    }
    
    /// 撤销所有未保存的更改
    func cancelChanges() {
        if let original = originalSettings {
            self.currentSettings = original
        }
        self.hotkeyDidChange = false // <-- 新增这一行
    }

    func resetToDefaults() {
        let defaultSettings = SettingsData(
            Currnet_Dictionary: "Dict1",
            HotKeys: 49 // 49 是空格键
        )
        self.currentSettings = defaultSettings
        print("设置已重置为默认值。")
    }
}
