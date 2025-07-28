import SwiftUI

enum NavigationItem: Hashable {
    case home, history, settings
}

struct ContentView: View {
    @State private var selection: NavigationItem? = .home
    
    // 修复：在ContentView中创建ViewModel的唯一实例
    // @StateObject 确保它的生命周期与ContentView（即主窗口）绑定
    @StateObject private var homepageViewModel = HomepageViewModel()

    var body: some View {
        NavigationSplitView {
            List(selection: $selection) {
                NavigationLink(value: NavigationItem.home) {
                    Label("主页", systemImage: "house")
                }
                NavigationLink(value: NavigationItem.history) {
                    Label("记忆列表", systemImage: "text.quote")
                }
                NavigationLink(value: NavigationItem.settings) {
                    Label("设置", systemImage: "gear")
                }
            }
            .font(.title3)
            .imageScale(.large)
            .listStyle(.sidebar)
            
        } detail: {
            if let selection = selection {
                switch selection {
                case .home:
                    // 将ViewModel实例传递给HomepageView
                    HomepageView(viewModel: homepageViewModel)
                case .history:
                    MyDatasView()
                case .settings:
                    SettingsView()
                }
            } else {
                // 默认视图也需要传递ViewModel
                HomepageView(viewModel: homepageViewModel)
            }
        }
        .onDisappear {
                homepageViewModel.cleanup()
            }
    }
}
