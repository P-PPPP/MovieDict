//
//  DBTEST.swift
//  MovieWords
//
//  Created by pei on 2025/7/19.
//

import SwiftUI

struct DatabaseTestView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("数据库功能测试")
                .font(.largeTitle)
            
            Button("运行所有测试 (结果见控制台)") {
                runAllTests()
            }
            .font(.title2)
        }
        .frame(width: 400, height: 300)
    }
    
    func runAllTests() {
        let handler = DatabaseHandler.shared
        print("\n--- 数据库测试开始 ---\n")
        
        // --- Word 测试 ---
        print("1. 添加新单词 'serendipity'...")
        handleResult(handler.addWord(word_to_added: "serendipity", _source_media: "Movie1.mp4", _media_timestamp: 123))

        print("\n2. 尝试重复添加 'serendipity'...")
        handleResult(handler.addWord(word_to_added: "serendipity"))
        
        print("\n3. 搜索单词 'serendipity'...")
        handleResult(handler.searchWord(_word_to_search: "serendipity"))
        
        print("\n4. 搜索不存在的单词 'xyz'...")
        handleResult(handler.searchWord(_word_to_search: "xyz"))

        print("\n5. 删除单词 'serendipity'...")
        handleResult(handler.delWord(_word_to_del: "serendipity"))
        
        print("\n6. 再次搜索已删除的 'serendipity'...")
        handleResult(handler.searchWord(_word_to_search: "serendipity"))

        print("\n7. 尝试删除不存在的单词 'serendipity'...")
        handleResult(handler.delWord(_word_to_del: "serendipity"))

        // --- Sentence 测试 ---
        print("\n8. 添加新句子...")
        let sentence = "The quick brown fox jumps over the lazy dog."
        let words = ["quick", "brown", "fox", "lazy", "dog"]
        handleResult(handler.addSentence(_sentence: sentence, _related_words: words, _source_media: "Documentary.mkv"))

        print("\n9. 搜索包含 'fox' 的句子...")
        handleResult(handler.searchSentence(_sentence_to_search: "fox"))
        
        print("\n10. 搜索不包含 'cat' 的句子...")
        handleResult(handler.searchSentence(_sentence_to_search: "cat"))
        // --- 新增：List 测试 ---
        print("\n--- 开始列表功能测试 ---")
        
        // 先添加一些测试数据
        print("11. 添加多个单词用于排序测试...")
        _ = handler.addWord(word_to_added: "ephemeral")
        _ = handler.addWord(word_to_added: "gregarious")
        _ = handler.addWord(word_to_added: "eloquent")
        
        print("\n12. 获取最新的 100 个单词 (默认范围)...")
        handleResult(handler.list_words())
        
        print("\n13. 获取第 1 到 3 个单词 (范围 [1, 3])...")
        handleResult(handler.list_words(length_range: [1, 3]))

        print("\n14. 添加多个句子用于排序测试...")
        _ = handler.addSentence(_sentence: "Second sentence added.", _related_words: ["second"])
        _ = handler.addSentence(_sentence: "Third sentence added.", _related_words: ["third"])

        print("\n15. 获取最新的 100 个句子 (默认范围)...")
        handleResult(handler.list_sentences())

        print("\n--- 数据库测试结束 ---\n")
    }
    
    // 辅助函数，用于打印Result的结果
    func handleResult<T>(_ result: Result<T, Error>) {
        switch result {
        case .success(let value):
            print("  ✅ 成功: \(value)")
        case .failure(let error):
            if let dbError = error as? DatabaseError {
                print("  ❌ 失败: \(dbError.localizedDescription)")
            } else {
                print("  ❌ 失败: \(error.localizedDescription)")
            }
        }
    }
}
