import Foundation

/// 一个专门用来管理应用关键文件路径的工具
enum AppPath {

    /// 应用在 Application Support 目录下的专属文件夹URL
    /// 使用 Bundle Identifier 可以确保目录名的唯一性，这是最推荐的做法
    static let supportDirectory: URL = {
        let fileManager = FileManager.default
        guard let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            fatalError("致命错误：无法获取 Application Support 目录。")
        }
        
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
             fatalError("致命错误：无法获取应用的 Bundle Identifier。请在项目设置中检查。")
        }
        
        return appSupportURL.appendingPathComponent(bundleIdentifier)
    }()
    
    /// 数据库文件的完整URL
    static let databaseURL: URL = {
        return supportDirectory.appendingPathComponent("MyDatas.db")
    }()
    
    /// 配置文件的完整URL
    static let configURL: URL = {
        return supportDirectory.appendingPathComponent("Basic_Config.plist")
    }()
}
