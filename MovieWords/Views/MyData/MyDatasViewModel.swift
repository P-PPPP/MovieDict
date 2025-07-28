//
//  MyDatasViewModel.swift
//  MovieWords
//
//  Created by pei on 2025/7/20.
//

import Foundation
import SwiftUI

@MainActor // 确保所有对 @Published 属性的更新都在主线程上
class MyDatasViewModel: ObservableObject {
    
    enum Tab {
        case words
        case sentences
    }
    
    @Published var selectedTab: Tab = .words
    @Published var words: [MyWord] = []
    @Published var sentences: [MySentence] = []
    
    private let dbHandler = DatabaseHandler.shared
    
    init() {
        // 初始化时加载默认标签页的数据
        fetchData(for: selectedTab)
    }
    
    func fetchData(for tab: Tab) {
        switch tab {
        case .words:
            fetchWords()
        case .sentences:
            fetchSentences()
        }
    }
    
    private func fetchWords() {
        let result = dbHandler.list_words() // 使用默认范围
        switch result {
        case .success(let fetchedWords):
            self.words = fetchedWords
            print(self.words)
            print("成功获取 \(fetchedWords.count) 个单词。")
        case .failure(let error):
            print("获取单词列表失败: \(error.localizedDescription)")
            self.words = [] // 出错时清空列表
        }
    }
    
    private func fetchSentences() {
        let result = dbHandler.list_sentences() // 使用默认范围
        switch result {
        case .success(let fetchedSentences):
            self.sentences = fetchedSentences
            print("成功获取 \(fetchedSentences.count) 个句子。")
        case .failure(let error):
            print("获取句子列表失败: \(error.localizedDescription)")
            self.sentences = [] // 出错时清空列表
        }
    }
}
