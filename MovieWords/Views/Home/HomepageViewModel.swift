import Foundation
import SwiftUI
import ScreenCaptureKit
import Carbon.HIToolbox


struct WordGroup: Identifiable {
    let id = UUID()
    let words: [String]
    let timestamp = Date() // 自动记录创建时间
}
@MainActor
class HomepageViewModel: ObservableObject {
    private var floatingWindow: NSWindow? // <-- 新增这一行
    enum ViewState {
        case selection, capturing
    }
    @Published var state: ViewState = .selection
    @Published var hotkeyDidChange = false
    @Published var showAccessibilityAlert = false // <-- 新增这一行
    @Published var wordGroups: [WordGroup] = []
    @Published var hasScreenRecordingPermission = false
    // 新增：ViewModel现在持有可用的窗口列表
    @Published var availableWindows: [CapturableWindow] = []
    
    private(set) var Target_OCR_Area: CGRect? = nil {
        didSet {
            if Target_OCR_Area != nil { startHotKeyMonitor() }
            else { stopHotKeyMonitor() }
        }
    }
    
    private var hotKeyMonitor: Any?
    // 将键码存储为属性，方便引用
    private var hotKeyCode: UInt16 = UInt16(kVK_Space) // <-- 修改这一行
    
    private let captureHandler = CaptureHandler()
    
    init() {
        // MARK: - 修改
        // 调用 loadSettings() 以确保在视图模型初始化时加载了最新的热键配置
        loadSettings()
        checkPermission()
        
        // 新增：监听“应用即将终止”的通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAppWillTerminate),
            name: .appWillTerminate,
            object: nil
        )
    }
    
    @objc private func onAppWillTerminate() {
        print("应用即将终止，正在执行最后的清理工作...")
        // 使用 Task 将任务派发到主线程 (因为 self 是 @MainActor)
        Task { @MainActor in
            self.stopHotKeyMonitor()
        }
    }
    private func showFloatingWindow() {
        // 如果窗口已存在，直接显示即可
        if let window = floatingWindow {
            window.orderFront(nil)
            return
        }

        // 创建一个无边框、置顶的窗口
        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.level = .floating // 让窗口浮在大多数窗口之上
        window.isOpaque = false
        window.backgroundColor = .clear
        window.contentView = NSHostingView(rootView: FloatingIndicatorView())
        
        // 将窗口定位在屏幕右上角
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            let windowSize = window.contentView!.fittingSize
            let windowX = screenFrame.maxX - windowSize.width - 20
            let windowY = screenFrame.maxY - windowSize.height - 20
            window.setFrameOrigin(NSPoint(x: windowX, y: windowY))
        }

        self.floatingWindow = window
        window.orderFront(nil)
    }

    private func hideFloatingWindow() {
        floatingWindow?.orderOut(nil)
    }
    // MARK: - Public Functions
    func checkPermission() {
        Task {
            do {
                _ = try await SCShareableContent.current
                self.hasScreenRecordingPermission = true
            } catch {
                self.hasScreenRecordingPermission = false
            }
        }
    }
    
    func _recg() {
        // --- 诊断日志 5 ---
        print("✅ [诊断 5] _recg() 函数被成功调用！")
        
        guard let targetArea = Target_OCR_Area else {
            // --- 诊断日志 6 ---
            print("❌ [诊断 6] OCR 执行失败，因为目标区域 (Target_OCR_Area) 为空 (nil)。")
            return
        }
        
        print("监听到热键: KeyCode \(hotKeyCode)")
        Task {
            print("\n--- OCR识别开始 ---")
            print("目标区域: \(NSStringFromRect(targetArea))")
            let results = await captureHandler._capture_area(rect: targetArea)
            
            // 1. 数据清理：移除符号、数字、并去除首尾空格
            let newWords = results.compactMap { ocrResult -> String? in
                // 移除所有非英文字母的字符
                let cleanedWord = ocrResult.word.replacingOccurrences(of: "[^a-zA-Z]", with: "", options: .regularExpression)
                // 去除首尾的空格和换行符
                let trimmedWord = cleanedWord.trimmingCharacters(in: .whitespacesAndNewlines)
                // 如果处理后字符串不为空，则返回它
                return trimmedWord.isEmpty ? nil : trimmedWord
            }

            // 2. 如果清理后的单词列表不为空，则创建一个新的组并插入到最前面
            // 2. 如果清理后的单词列表不为空，则进行下一步处理
            if !newWords.isEmpty {
                // 获取最近一次记录的单词组（如果存在）
                let lastGroupWords = self.wordGroups.first?.words
                
                // 检查新识别的单词列表是否与最近一次记录的相同
                // 为了确保比较的准确性，我们将它们都转换为 Set 进行比较，
                // 因为 Set 不关心元素的顺序。
                if let lastWords = lastGroupWords, Set(newWords) == Set(lastWords) {
                    // 如果内容完全相同，则打印一条信息，并且不添加新的组
                    print("识别内容与上次相同，不进行重复记录。")
                } else {
                    // 如果内容不同，或者这是第一次记录，则创建一个新的组并插入到最前面
                    let newGroup = WordGroup(words: newWords)
                    self.wordGroups.insert(newGroup, at: 0)
                }
            }
            
            if results.isEmpty {
                print("识别结果：未找到任何单词。")
            } else {
                print("识别到 \(newWords.count) 个有效单词。")
            }
            print("--- OCR识别结束 ---\n")
        }
    }
    
    func fetchAvailableWindows() async {
        self.availableWindows = await captureHandler._available_windows()
    }
    
    func setTargetArea(_ rect: CGRect) {
        self.Target_OCR_Area = rect
        self.state = .capturing
        // 在状态切换时启动监视器
        startHotKeyMonitor()
        print("目标区域已更新，区域: \(rect)")
    }
    
    func setTargetWindow(_ window: CapturableWindow) {
        setTargetArea(window.frame)
    }
    
    func endCapture() {
        wordGroups.removeAll()
        self.Target_OCR_Area = nil
        self.state = .selection
        stopHotKeyMonitor()
        print("捕获已结束。")
    }

    // MARK: - Hotkey Handling & Settings Loading
    
    // MARK: - 修改
    // 将函数重命名为 loadSettings，以反映其更通用的职责
    private func loadSettings() {
        let url = AppPath.configURL

        guard FileManager.default.fileExists(atPath: url.path) else {
            print("配置文件不存在，使用默认热键 (空格)。")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = PropertyListDecoder()
            // 我们只需要解码包含热键和词典设置的部分
            let decodedData = try decoder.decode(AppSettings.self, from: data)
            
            // 更新 hotKeyCode 属性
            self.hotKeyCode = UInt16(decodedData.Settings.HotKeys)
            print("成功加载自定义热键，键码: \(self.hotKeyCode)")
            
            // 未来可以在这里加载词典相关的设置
            // let useAllDicts = decodedData.Dict_Control.Using_All_Dicts
            // let selectedDict = decodedData.Dict_Control.Selected_Dictionary_ShortName
            
        } catch {
            print("加载配置失败: \(error)。将使用默认设置。")
        }
    }
    
    private func startHotKeyMonitor() {
        // --- 第一步：检查权限 ---
        // 'trusted' 参数设为 true 表示我们希望请求权限（如果尚未授予）
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isAccessibilityEnabled = AXIsProcessTrustedWithOptions(options)

        // 如果权限未被授予，则直接返回，并准备弹出提示
        guard isAccessibilityEnabled else {
            print("❌ 辅助功能权限未被授予。无法启动全局热键监听器。")
            // 在主线程上更新状态以显示弹窗
            DispatchQueue.main.async {
                self.showAccessibilityAlert = true
            }
            return
        }

        // --- 第二步：如果权限已授予，则继续执行原来的逻辑 ---
        showFloatingWindow()
        stopHotKeyMonitor() // 确保只有一个监视器
        
        print("✅ 正在尝试启动热键监听器... 目标键码: \(hotKeyCode)")
        
        hotKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == self?.hotKeyCode {
                self?._recg()
            }
        }
        
        if hotKeyMonitor != nil {
            print("✅ 热键监听器已成功创建并启动。")
        } else {
            print("❌ 错误：热键监听器未能成功创建！")
        }
    }
    
    
    private func stopHotKeyMonitor() {
        hideFloatingWindow()
        if let monitor = hotKeyMonitor {
            NSEvent.removeMonitor(monitor)
            hotKeyMonitor = nil
            print("热键监视器已停止。")
        }
    }
    
    public func cleanup() {
        print("View is disappearing. Cleaning up resources.")
        stopHotKeyMonitor()
    }
} 
