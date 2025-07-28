import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    
    // 1. 新增状态，用于追踪保存操作是否正在进行
    @State private var isSaving = false
    
    private var sortedDictionaries: [(key: String, value: DictionaryInfo)] {
        viewModel.availableDictionaries.sorted { $0.key < $1.key }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 当热键被修改后，显示这个提示框
                    if viewModel.hotkeyDidChange { // <-- 新增的整个 if 代码块
                        GroupBox {
                            HStack {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text("热键设置已更新，请重启应用以生效。")
                                Spacer()
                            }
                            .padding(4)
                        }
                    }
                    
                    if viewModel.isModified {
                        GroupBox {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("您有未保存的更改")
                                Spacer()
                            }
                            .padding(4)
                            // 移除了颜色代码，使用系统默认强调色
                            .foregroundColor(.accentColor.opacity(0.9))
                        }
                    }
                    
                    GroupBox {
                        VStack(spacing: 12) {
                            HStack {
                                Text("当前词典")
                                Spacer()
                                Picker("当前词典", selection: $viewModel.currentSettings.Currnet_Dictionary) {
                                    ForEach(sortedDictionaries, id: \.key) { key, dict in
                                        Text(dict.name).tag(key)
                                    }
                                }
                                .labelsHidden()
                                .frame(minWidth: 200)
                                .scaledToFit()
                            }
                            Divider() // <-- “当前词典”下方的分割线
                            HStack {
                                Text("热键设置")
                                Spacer()
                                Picker("热键设置", selection: $viewModel.currentSettings.HotKeys) {
                                    ForEach(viewModel.availableHotkeys) { hotkey in
                                        Text(hotkey.name).tag(hotkey.id)
                                    }
                                }
                                .labelsHidden()
                                .frame(minWidth: 200)
                                .scaledToFit()
                            }
                            HStack {
                                Text("作者")
                                Spacer()
                                Text(viewModel.appInfo.Author).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack {
                                Text("版本号")
                                Spacer()
                                Text(viewModel.appInfo.Version).foregroundColor(.secondary)
                            }
                            Divider()
                            HStack {
                                Text("GitHub")
                                Spacer()
                                Link("前往链接", destination: URL(string: viewModel.appInfo.GitHub) ?? URL(string: "https://github.com")!)
                            }
                        }
                        .padding(.vertical, 8)
                    }

                    GroupBox {
                        HStack {
                            Text("将所有设置恢复为出厂默认值")
                            Spacer()
                            Button("重置设置") {
                                viewModel.resetToDefaults()
                            }
                            .tint(.red)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .padding()
            }
            
            Divider()
            
            HStack {
                Spacer()
                
                Button("取消") {
                    viewModel.cancelChanges()
                }
                // 当正在保存或没有修改时，禁用取消按钮
                .disabled(!viewModel.isModified || isSaving)
                
                // 2. 改进保存按钮，提供加载中反馈
                Button(action: {
                    // 使用 Task 来执行异步保存操作
                    Task {
                        isSaving = true
                        await viewModel.saveSettings()
                        isSaving = false
                    }
                }) {
                    if isSaving {
                        // 正在保存时，显示一个加载指示器
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 10) // 给指示器一些空间
                    } else {
                        // 不在保存时，显示文本
                        Text("保存")
                    }
                }
                // 当正在保存或没有修改时，禁用保存按钮
                .disabled(!viewModel.isModified || isSaving)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("设置")
        // 3. 移除了 .frame(maxWidth: 600)
        .frame(maxWidth: .infinity)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        // 预览中也不再需要 accentColor
        SettingsView()
    }
}
