import SwiftUI

struct SettingsView: View {
    
    @StateObject private var viewModel = SettingsViewModel()
    @State private var isSaving = false
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 16) {
                    // 热键修改提示
                    if viewModel.hotkeyDidChange {
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
                    
                    // 未保存更改提示
                    if viewModel.isModified {
                        GroupBox {
                            HStack {
                                Image(systemName: "info.circle.fill")
                                Text("您有未保存的更改")
                                Spacer()
                            }
                            .padding(4)
                            .foregroundColor(.accentColor.opacity(0.9))
                        }
                    }
                    
                    // 核心设置
                    GroupBox {
                        VStack(spacing: 12) {
                            // MARK: - 修正
                            // 使用正确的 Toggle 视图代替了不存在的 Switch。
                            // Toggle 在 macOS 上默认显示为开关样式。
                            HStack {
                                Text("查询所有词典")
                                Spacer()
                                Toggle("", isOn: $viewModel.dictControl.Using_All_Dicts)
                                    .labelsHidden() // 隐藏 Toggle 的内部标签，因为我们在外部已有 Text
                                    .controlSize(.small)
                            }
                            
                            // 选择可用词典
                            Picker("选择可用字典", selection: $viewModel.dictControl.Selected_Dictionary_ShortName) {
                                Text("— 未选择 —").tag("")
                                ForEach(viewModel.availableSystemDictionaries, id: \.shortName) { dictionary in
                                    Text(dictionary.name).tag(dictionary.shortName)
                                }
                            }
                            .disabled(viewModel.dictControl.Using_All_Dicts)
                            .frame(maxWidth: 220)
                            Divider()
                            
                            // 热键设置
                            HStack {
                                Text("热键设置")
                                Spacer()
                                Picker("热键设置", selection: $viewModel.currentSettings.HotKeys) {
                                    ForEach(viewModel.availableHotkeys) { hotkey in
                                        Text(hotkey.name).tag(hotkey.id)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 220)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // 作者信息等
                    GroupBox {
                        VStack(spacing: 12) {
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

                    // 重置设置
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
            
            // 底部操作栏
            HStack {
                Spacer()
                
                Button("取消") {
                    viewModel.cancelChanges()
                }
                .disabled(!viewModel.isModified || isSaving)
                
                Button(action: {
                    Task {
                        isSaving = true
                        await viewModel.saveSettings()
                        isSaving = false
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .controlSize(.small)
                            .padding(.horizontal, 10)
                    } else {
                        Text("保存")
                    }
                }
                .disabled(!viewModel.isModified || isSaving || !viewModel.isSaveConfigurationValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
            .background(.bar)
        }
        .navigationTitle("设置")
        .frame(maxWidth: .infinity)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
