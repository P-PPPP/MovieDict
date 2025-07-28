//
//  CaptureTest.swift
//  MovieWords
//
//  Created by pei on 2025/7/20.
//

import SwiftUI

struct CaptureTestView: View {
    
    private let captureHandler = CaptureHandler()
    
    // 使用 @State 来存储和显示窗口列表
    @State private var availableWindows: [CapturableWindow] = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("屏幕捕捉与OCR测试")
                .font(.largeTitle)
            
            // --- 窗口列表测试 ---
            VStack {
                Button("获取可用窗口") {
                    // 使用 Task 来执行异步操作
                    Task {
                        self.availableWindows = await captureHandler._available_windows()
                        print("✅ 获取到 \(self.availableWindows.count) 个窗口。")
                    }
                }
                .font(.title2)
                
                // 使用列表来显示获取到的窗口
                List(availableWindows) { window in
                    VStack(alignment: .leading) {
                        Text(window.appName).fontWeight(.bold)
                        Text(window.windowTitle).font(.caption).foregroundColor(.secondary)
                    }
                }
                .border(Color.secondary, width: 1)
            }
            
            // --- 全屏捕捉测试 ---
            Button("捕获全屏并OCR (结果见控制台)") {
                Task {
                    print("\n--- 开始全屏捕捉测试 ---")
                    let ocrResult = await captureHandler._s_capture()
                    print("✅ OCR识别完成，找到 \(ocrResult.count) 个单词。")
                    for word in ocrResult {
                        print("  - 单词: '\(word.word)', 屏幕坐标: \(word.absolutePosition)")
                    }
                    print("--- 全屏捕捉测试结束 ---\n")
                }
            }
            .font(.title2)
        }
        .padding()
        .frame(minWidth: 500, minHeight: 600)
    }
}

struct CaptureTestView_Previews: PreviewProvider {
    static var previews: some View {
        CaptureTestView()
    }
}
