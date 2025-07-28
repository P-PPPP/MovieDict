import SwiftUI

struct MyDatasView: View {
    
    @StateObject private var viewModel = MyDatasViewModel()
    
    var body: some View {
        // 1. 使用 VStack 作为根容器。这是解决问题的关键。
        VStack(spacing: 0) {
            // switch 语句被包裹在 VStack 内部
            switch viewModel.selectedTab {
            case .words:
                wordsListView
            case .sentences:
                sentencesListView
            }
        }
        // 2. 将修饰符应用到 VStack 上。现在它们的调用对象是合法的View。
        .navigationTitle("记忆列表")
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button { /* 手动添加功能 */ } label: {
                    Label("手动添加", systemImage: "plus")
                }
            }
            
            ToolbarItem(placement: .principal) {
                Picker("查看", selection: $viewModel.selectedTab) {
                    Text("Words").tag(MyDatasViewModel.Tab.words)
                    Text("Sentences").tag(MyDatasViewModel.Tab.sentences)
                }
                .pickerStyle(.segmented)
                .frame(minWidth: 200)
            }
            
            ToolbarItemGroup(placement: .primaryAction) {
                Button { /* 多选功能 */ } label: {
                    Image(systemName: "list.dash")
                }
                Button { /* 导出功能 */ } label: {
                    Image(systemName: "tray.and.arrow.down")
                }
            }
        }
    }
    
    // 单词列表和句子列表视图 (wordsListView, sentencesListView) 的代码保持不变
    private var wordsListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.words, id: \.word) { word in
                    GroupBox {
                        HStack {
                            Text(word.word).fontWeight(.bold).frame(minWidth: 120, alignment: .leading)
                            Spacer()
                            Text(word.sourceMedia).foregroundColor(.secondary)
                            Spacer()
                            Text("\(word.mediaTimestamp)s").foregroundColor(.secondary).frame(width: 80)
                            Spacer()
                            Text(word.createTime, style: .date).foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .padding(.top)
        }
    }
    
    private var sentencesListView: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.sentences, id: \.sentence) { sentence in
                    GroupBox {
                        VStack(alignment: .leading) {
                            Text(sentence.sentence)
                            Divider()
                            HStack {
                                Text(sentence.relatedWords.joined(separator: ", ")).font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(sentence.sourceMedia).font(.caption).foregroundColor(.secondary)
                                Spacer()
                                Text(sentence.createTime, style: .date).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
            }
            .padding(.top)
        }
    }
}

struct MyDatasView_Previews: PreviewProvider {
    static var previews: some View {
        // 为了让预览正常工作，必须将 MyDatasView 放入一个导航容器中
        NavigationView {
            MyDatasView()
        }
    }
}
