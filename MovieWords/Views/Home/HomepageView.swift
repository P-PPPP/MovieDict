import SwiftUI
import ScreenCaptureKit

// MARK: - 新增：全屏窗口控制器
// 这个类将负责创建和管理我们的全屏选择窗口
class FullScreenWindowController<Content: View>: NSWindowController {
    convenience init(rootView: Content) {
        // 创建一个无标题栏、无阴影、透明的窗口
        let styleMask: NSWindow.StyleMask = [.borderless]
        let screenRect = NSScreen.main?.frame ?? NSRect(x: 0, y: 0, width: 800, height: 600)
        let window = NSWindow(
            contentRect: screenRect,
            styleMask: styleMask,
            backing: .buffered,
            defer: false
        )
        window.isReleasedWhenClosed = true
        window.level = .screenSaver // 让窗口浮在所有其他窗口之上
        window.backgroundColor = .clear // 窗口背景透明
        window.isOpaque = false // 允许视图中的透明度
        window.contentView = NSHostingView(rootView: rootView)
        self.init(window: window)
    }

    func show() {
        self.window?.makeKeyAndOrderFront(nil)
    }
}



struct HomepageView: View {
    
    // 1. 从 @StateObject 改为 @ObservedObject
    // 它现在观察一个由父视图(ContentView)创建并传递进来的ViewModel
    @ObservedObject var viewModel: HomepageViewModel
    @Environment(\.openURL) private var openURL
    // --- UI State (只保留与本视图相关的临时状态) ---
    @State private var showWindowPicker = false
    @State private var selectionWindowController: FullScreenWindowController<AreaSelectionView>?
    @State private var selectedWindowID: CGWindowID?
    
    // 视图不再自己持有数据或业务逻辑对象
    // private let captureHandler = CaptureHandler() // <-- REMOVED

    var body: some View {
        ZStack {
            // UI完全由ViewModel的`state`属性驱动
            switch viewModel.state {
            case .selection:
                selectionView
            case .capturing:
                capturingView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // 视图出现时，请求ViewModel检查权限
        .onAppear(perform: viewModel.checkPermission)
        // 模态弹出窗口选择列表
        .sheet(isPresented: $showWindowPicker) {
            windowPickerView
        }
        // v-- 从这里开始添加新的代码 --v
        .alert("需要辅助功能权限", isPresented: $viewModel.showAccessibilityAlert) {
            Button("前往设置") {
                // 这是一种非常稳定和可靠的打开系统特定设置页面的方法
                let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
                openURL(url)
            }
            
            Button("取消", role: .cancel) {}
        } message: {
            Text("需要此权限才能在其他应用中响应全局热键。\n请在“系统设置 > 隐私与安全 > 辅助功能”中启用本应用。")
        }
        // ^-- 添加代码到这里结束 --^
    }
    
    // MARK: - Subviews

    /// 初始选择视图 (功能: 显示选项，提示权限)
    private var selectionView: some View {
        VStack {
            Spacer()
            
            Text("请选择一种方式开始")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .padding(.bottom, 50)
            
            HStack(spacing: 40) {
                // 选项1: 选定范围
                StartOptionView(
                    systemImageName: "rectangle.dashed.badge.record",
                    labelText: "选定一块范围开始"
                ) {
                    presentAreaSelector()
                }
                
                // 选项2: 选定窗口
                StartOptionView(
                    systemImageName: "macwindow",
                    labelText: "选定一个窗口开始"
                ) {
                    handleWindowSelection()
                }
            }
            
            // 如果ViewModel报告没有权限，则显示提示
            if !viewModel.hasScreenRecordingPermission {
                Text("需要屏幕录制权限才能开始。请在系统设置中授权。")
                    .foregroundColor(.red)
                    .padding(.top)
            }
            
            Spacer()
        }
    }
    /// 捕获中视图 (功能: 显示状态和分组的识别结果)
    private var capturingView: some View {
        ScrollView {
            LazyVStack(spacing: 15) { // 为 GroupBox 之间添加一些垂直间距
                // 遍历 ViewModel 中的每一个单词组
                ForEach(viewModel.wordGroups) { group in
                    // 为每一组单词创建一个新的 GroupBox
                    GroupBox {
                        VStack(spacing: 0) { // 使用无间距的VStack
                            // 上方：保持原来的网格布局
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 6) {
                                ForEach(group.words, id: \.self) { word in
                                    Text(word)
                                        .font(.title3)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Color.secondary.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.bottom, 10) // 让网格和分割线之间有间距

                            Divider()

                            // 下方：新的HStack状态栏
                            HStack {
                                // 使用 .time 样式只显示时间
                                Text(group.timestamp, style: .time)
                                Spacer()
                                Text("\(group.words.count) 个单词")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(8)
                            .background(.bar) // 使用系统标准的栏背景效果
                        }
                    }
                }
            }
            .padding() // 给整个列表的四周留出间距
        }
        // toolbar 部分保持不变
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack {
                    Text("捕获进行中...")
                        .font(.headline)
                    if let rect = viewModel.Target_OCR_Area {
                        Text("区域: \(Int(rect.width))x\(Int(rect.height)) @ (\(Int(rect.origin.x)), \(Int(rect.origin.y)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button(action: viewModel.endCapture) {
                    Label("结束捕获", systemImage: "stop.circle.fill")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    /// 窗口选择列表视图 (功能: 显示列表，传递用户选择)
    private var windowPickerView: some View {
        VStack(spacing: 0) {
            Text("选择一个窗口").font(.title).padding()
            Divider()
            
            ScrollView {
                VStack(spacing: 8) {
                    // 2. 关键: ForEach直接遍历viewModel中的数据源
                    ForEach(viewModel.availableWindows) { window in
                        windowRow(for: window)
                    }
                }
                .padding()
            }
            
            Divider()
            
            GroupBox {
                VStack(spacing: 12) {
                    Button(action: {
                        // 确认按钮的逻辑：找到选中的窗口并通知ViewModel
                        if let selectedID = selectedWindowID,
                           let windowToSet = viewModel.availableWindows.first(where: { $0.id == selectedID }) {
                            viewModel.setTargetWindow(windowToSet)
                            showWindowPicker = false
                        }
                    }) {
                        Text("确认").fontWeight(.semibold).frame(maxWidth: .infinity)
                    }
                    .disabled(selectedWindowID == nil)
                    .buttonStyle(.borderedProminent).tint(.blue)
                    
                    Button("取消") { showWindowPicker = false }
                        .buttonStyle(.bordered)
                }
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 600)
    }
    
    /// 用于创建列表中每一行的辅助视图
    @ViewBuilder
    private func windowRow(for window: CapturableWindow) -> some View {
        let isSelected = selectedWindowID == window.id
        
        GroupBox {
            HStack(spacing: 15) {
                Image(systemName: "macwindow").font(.title).frame(width: 40)
                VStack(alignment: .leading) {
                    Text(window.appName).fontWeight(.bold)
                    Text(window.windowTitle).font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                let frame = window.frame
                Text("(\(Int(frame.origin.x)), \(Int(frame.origin.y)))")
                    .font(.caption2).foregroundColor(.secondary)
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
        .background(Color.clear).border(Color.clear, width: 0)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.primary : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            selectedWindowID = window.id
        }
    }
    
    // MARK: - Helper Functions (只处理UI事件，不处理业务逻辑)
    
    /// 处理“选定窗口”按钮的点击事件
    private func handleWindowSelection() {
        guard viewModel.hasScreenRecordingPermission else {
            print("无权限，无法选择窗口。"); return
        }
        
        Task {
            // 视图的职责简化为：通知ViewModel去获取数据
            await viewModel.fetchAvailableWindows()
            // 重置本地的UI选择状态
            self.selectedWindowID = nil
            // 触发Sheet的显示
            self.showWindowPicker = true
        }
    }
    
    /// 处理“选定范围”按钮的点击事件
    private func presentAreaSelector() {
        // 创建AreaSelectionView，并为其提供一个回调闭包
        let areaSelectionView = AreaSelectionView { rect in
            // 当用户完成选择时，这个闭包被调用
            // 我们通知ViewModel设置目标区域
            viewModel.setTargetArea(rect)
            // 然后关闭我们创建的全屏窗口
            self.selectionWindowController?.close()
            self.selectionWindowController = nil
        }
        
        // 创建并显示承载AreaSelectionView的全屏窗口
        self.selectionWindowController = FullScreenWindowController(rootView: areaSelectionView)
        self.selectionWindowController?.show()
    }

}

// MARK: - StartOptionView (可重用组件)
fileprivate struct StartOptionView: View {
    let systemImageName: String
    let labelText: String
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                Image(systemName: systemImageName)
                    .font(.system(size: 60, weight: .light))
                    .foregroundStyle(.secondary)
                Text(labelText).font(.title3)
            }
            .padding(40)
            .frame(width: 280, height: 220)
            .background(isHovering ? Color.secondary.opacity(0.1) : Color.clear)
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) { isHovering = hovering }
        }
    }
}


struct FloatingIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .scaleEffect(isAnimating ? 1.2 : 1.0)
            
            Text("Listening...")
                .font(.system(.body, design: .monospaced))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar, in: Capsule())
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
