
//
//  ContentView.swift
//  MovieWords
//
//  这是一个临时的测试视图，用于验证 DictionaryKit 的功能。
//  测试完成后，请恢复您原来的 ContentView.swift 代码。
//

import SwiftUI

struct ContentView: View {
    
    // MARK: - State Properties
    
    // 用于存储从 DictionaryKit 获取的数据
    @State private var activeDictionaries: [TTTDictionary] = []
    @State private var searchResults: [String: [TTTDictionaryEntry]] = [:]
    
    // 用于控制加载状态的显示
    @State private var isLoading = true
    
    // 我们要测试搜索的单词
    private let searchTerm = "apple"
    
    // MARK: - Body
    
    var body: some View {
        // 使用 VStack 垂直排列所有UI元素
        VStack(alignment: .leading, spacing: 15) {
            
            Text("DictionaryKit 功能测试")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Divider()
            
            // 根据加载状态显示不同内容
            if isLoading {
                // 如果正在加载，显示一个加载指示器
                ProgressView("正在加载词典和搜索结果...")
                    .progressViewStyle(.linear)
                    .padding(.vertical)
            } else {
                // 加载完成后，显示结果
                
                // --- 1. 显示激活的词典列表 ---
                Section(header: Text("系统激活的词典 (\(activeDictionaries.count) 个)")
                                    .font(.title2)
                                    .fontWeight(.semibold)) {
                    // 使用 List 来展示列表数据
                    List(activeDictionaries, id: \.self) { dictionary in
                        Text(dictionary.name)
                    }
                    .frame(height: 200) // 给列表一个固定的高度，防止占用过多空间
                    .border(Color.gray.opacity(0.3), width: 1)
                }
                
                // --- 2. 显示搜索结果 ---
                Section(header: Text("搜索 “\(searchTerm)” 的结果")
                                    .font(.title2)
                                    .fontWeight(.semibold)) {
                    if searchResults.isEmpty {
                        Text("未在任何词典中找到结果。")
                            .foregroundColor(.secondary)
                    } else {
                        // 遍历搜索结果字典
                        List {
                            // 对字典的 key 进行排序，以确保每次显示的顺序一致
                            ForEach(searchResults.keys.sorted(), id: \.self) { dictionaryName in
                                VStack(alignment: .leading) {
                                    Text(dictionaryName)
                                        .font(.headline)
                                    
                                    // 获取该词典下的词条
                                    if let entries = searchResults[dictionaryName] {
                                        ForEach(entries, id: \.self) { entry in
                                            Text("  - \(entry.headword)")
                                                .font(.body)
                                                .padding(.leading, 8)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            
            Spacer() // 将所有内容推到顶部
        }
        .padding()
        .frame(minWidth: 400, idealWidth: 600, minHeight: 600, idealHeight: 700) // 给窗口一个合适的尺寸
        .onAppear(perform: runDictionaryTasks) // 当视图出现时，执行测试任务
    }
    
    // MARK: - Private Methods
    
    /// 执行词典查询任务
    private func runDictionaryTasks() {
        // 确保只在初次加载时执行
        guard isLoading else { return }
        
        print("--- 🚀 开始执行词典查询任务 ---")
        
        // 将耗时操作放到后台线程，防止UI卡顿
        DispatchQueue.global(qos: .userInitiated).async {
            // 任务1: 获取所有激活的词典
            let dictionaries = DictionaryWrapper.getActiveDictionaries()
            
            // 任务2: 搜索单词
            let results = DictionaryWrapper.searchInAllActiveDictionaries(term: searchTerm)
            
            // 任务完成后，回到主线程更新UI
            DispatchQueue.main.async {
                self.activeDictionaries = dictionaries
                self.searchResults = results
                self.isLoading = false // 更新加载状态
                print("--- ✅ 词典查询任务完成 ---")
            }
        }
    }
}

// SwiftUI 预览 (可选)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
