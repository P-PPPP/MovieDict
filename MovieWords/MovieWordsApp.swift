import SwiftUI

@main
struct YourAppNameApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // 在 App struct 的初始化方法中调用我们的检查函数
    init() {
        App_Init_Checks()
    }

    var body: some Scene {
        WindowGroup {
            //KeyboardDebugView()
            ContentView()
                .frame(minWidth: 960, minHeight: 640)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
    }

    /// 应用初始化检查：创建必要的目录并复制默认配置文件。
    private func App_Init_Checks() {
        print("执行应用初始化检查...")
        let fileManager = FileManager.default
        
        // 1. 获取我们应用专属的文件夹路径 (来自新的 AppPath 工具)
        let appDirectoryURL = AppPath.supportDirectory
        
        // 2. 检查并创建这个专属文件夹
        if !fileManager.fileExists(atPath: appDirectoryURL.path) {
            do {
                try fileManager.createDirectory(at: appDirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("成功创建应用专属目录于: \(appDirectoryURL.path)")
            } catch {
                fatalError("致命错误：无法创建应用专属目录: \(error)。应用无法继续。")
            }
        }
        
        // 3. 定义并检查配置文件
        let finalPlistURL = AppPath.configURL
        if !fileManager.fileExists(atPath: finalPlistURL.path) {
            guard let bundleURL = Bundle.main.url(forResource: "Basic_Config", withExtension: "plist") else {
                fatalError("致命错误：在应用包中找不到默认的 Basic_Config.plist。")
            }
            do {
                try fileManager.copyItem(at: bundleURL, to: finalPlistURL)
                print("配置文件已成功复制到: \(finalPlistURL.path)")
            } catch {
                fatalError("致命错误：复制 plist 文件失败: \(error)。")
            }
        } else {
            print("配置文件已存在。")
        }
        
        // 4. 定义并检查数据库文件
        let finalDbURL = AppPath.databaseURL
        if !fileManager.fileExists(atPath: finalDbURL.path) {
            guard let bundleURL = Bundle.main.url(forResource: "MyDatas", withExtension: "db") else {
                fatalError("致命错误：在应用包中找不到默认的 MyDatas.db。")
            }
            do {
                try fileManager.copyItem(at: bundleURL, to: finalDbURL)
                print("数据库文件已成功复制到: \(finalDbURL.path)")
            } catch {
                fatalError("致命错误：复制数据库文件失败: \(error)。")
            }
        } else {
            print("数据库文件已存在。")
        }
    }
}
