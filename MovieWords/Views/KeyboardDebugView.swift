//
//  KeyboardDebugView.swift
//  MovieWords
//
//  Created by pei on 2025/7/26.
//

import SwiftUI

struct KeyboardDebugView: View {
    
    // 用一个状态变量来持有我们的监听器，以便之后可以移除它
    @State private var keyMonitor: Any?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("键盘事件监听器")
                .font(.largeTitle)
            
            Text("请在此窗口激活的状态下，按下任意按键。")
                .font(.title2)
            
            Text("在 Xcode 的控制台查看按键的详细信息。")
                .foregroundColor(.secondary)
            
            Text("调试结束后，请务必将 MovieWordsApp.swift 文件恢复原状。")
                .padding()
                .background(Color.yellow.opacity(0.2))
                .cornerRadius(8)
        }
        .frame(width: 600, height: 400)
        .onAppear(perform: startMonitoringKeys) // 当视图出现时，开始监听
        .onDisappear(perform: stopMonitoringKeys) // 当视图消失时，停止监听
    }
    
    /// 开始监听键盘事件
    private func startMonitoringKeys() {
        // 我们使用 addLocalMonitorForEvents，它只监听我们自己应用内的事件
        // 这比全局监听器更适合进行窗口内的调试
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            
            // --- 核心调试代码 ---
            // 每次有按键按下，就在控制台打印它的信息
            let keyName = event.characters ?? "无字符"
            let keyCode = event.keyCode
            
            print("--- 键盘事件捕捉 ---")
            print("按下的按键字符: \(keyName)")
            print("按键的物理键码 (KeyCode): \(keyCode)")
            print("---------------------\n")
            
            // 返回 event 表示我们已经处理了它，系统可以继续传递
            return event
        }
        print("✅ 键盘监听器已启动。")
    }
    
    /// 停止监听，防止内存泄漏
    private func stopMonitoringKeys() {
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
            print("🛑 键盘监听器已停止。")
        }
    }
}

struct KeyboardDebugView_Previews: PreviewProvider {
    static var previews: some View {
        KeyboardDebugView()
    }
}
