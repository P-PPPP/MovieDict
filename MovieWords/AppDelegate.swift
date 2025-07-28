import SwiftUI

// 创建一个遵从 NSApplicationDelegate 协议的类
class AppDelegate: NSObject, NSApplicationDelegate {
    
    // 当应用即将终止时，这个方法会被系统调用
    func applicationWillTerminate(_ aNotification: Notification) {
        // 在这里，我们发送一个自定义的通知
        // 项目中任何关心“应用即将关闭”这件事的对象，都可以监听这个通知
        NotificationCenter.default.post(name: .appWillTerminate, object: nil)
    }
}

// 在一个方便的地方定义我们自定义通知的名称
extension Notification.Name {
    static let appWillTerminate = Notification.Name("appWillTerminateNotification")
}
