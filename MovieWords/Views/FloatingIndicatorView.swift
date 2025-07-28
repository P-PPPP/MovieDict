import SwiftUI

struct FloatingIndicatorView: View {
    @State private var isAnimating = false

    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color.red)
                .frame(width: 10, height: 10)
                .scaleEffect(isAnimating ? 1.2 : 1.0) // 动画效果
            
            Text("Listening...")
                .font(.system(.body, design: .monospaced))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar, in: Capsule()) // 使用胶囊形状和栏背景
        .onAppear {
            // 创建一个无限循环的脉冲动画
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}
