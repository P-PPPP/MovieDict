//
//  AreaSelectionView.swift
//  MovieWords
//
//  Created by pei on 2025/7/20.
//

import SwiftUI
import AppKit
import Carbon.HIToolbox
// 这个视图将作为全屏覆盖层
struct AreaSelectionView: View {
    var onSelect: (CGRect) -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        // 使用 NSViewRepresentable 来包装我们的自定义鼠标事件处理视图
        AreaSelectionRepresentable(onSelect: { rect in
            onSelect(rect)
            dismiss()
        }, onCancel: {
            dismiss()
        })
        .edgesIgnoringSafeArea(.all)
    }
}

// 这是包装器
fileprivate struct AreaSelectionRepresentable: NSViewRepresentable {
    var onSelect: (CGRect) -> Void
    var onCancel: () -> Void

    func makeNSView(context: Context) -> SelectionNSView {
        let view = SelectionNSView()
        view.onSelect = onSelect
        view.onCancel = onCancel
        return view
    }

    func updateNSView(_ nsView: SelectionNSView, context: Context) {}
}

// 这是处理鼠标事件和绘图的核心 NSView
fileprivate class SelectionNSView: NSView {
    var onSelect: ((CGRect) -> Void)?
    var onCancel: (() -> Void)?

    private var startPoint: NSPoint?
    private var currentRect: NSRect?

    override var acceptsFirstResponder: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // 获取焦点以接收键盘事件
        self.window?.makeFirstResponder(self)
        // 设置十字线光标
        NSCursor.crosshair.push()
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: newWindow)
        NSCursor.pop() // 恢复默认光标
    }

    override func keyDown(with event: NSEvent) {
        // 使用 kVK_Escape 常量代替数字 53，让人一眼就知道这是在判断 Escape 键
        if event.keyCode == kVK_Escape {
            onCancel?()
        } else {
            super.keyDown(with: event)
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = self.convert(event.locationInWindow, from: nil)
        currentRect = nil
        needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        guard let startPoint = startPoint else { return }
        let currentPoint = self.convert(event.locationInWindow, from: nil)
        currentRect = NSRect(x: min(startPoint.x, currentPoint.x),
                               y: min(startPoint.y, currentPoint.y),
                               width: abs(startPoint.x - currentPoint.x),
                               height: abs(startPoint.y - currentPoint.y))
        needsDisplay = true
    }

    override func mouseUp(with event: NSEvent) {
        if let finalRect = currentRect, finalRect.width > 5, finalRect.height > 5 {
            // 修复：确保我们有一个有效的窗口来执行坐标转换
            if let window = self.window {
                // 使用窗口的 convertToScreen 方法，这是最可靠的
                let screenRect = window.convertToScreen(finalRect)
                onSelect?(screenRect)
            } else {
                // 如果没有窗口，取消操作以避免坐标错误
                print("错误：无法获取窗口进行坐标转换。")
                onCancel?()
            }
        } else {
            onCancel?()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        // 绘制半透明的灰色遮罩
        NSColor(white: 0.0, alpha: 0.5).setFill()
        NSBezierPath(rect: self.bounds).fill()

        // 如果正在选择，将选择区域变透明
        if let rect = currentRect {
            NSColor.clear.setFill()
            let path = NSBezierPath(rect: rect)
            path.fill()
            
            // (可选) 绘制白色边框
            NSColor.white.setStroke()
            path.lineWidth = 1.0
            path.stroke()
        }
    }
}
