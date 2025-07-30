//
//  DictionaryWrapper.swift
//  MovieWords
//
//  在 Services 文件夹下
//

import Foundation

/// 一个封装了 DictionaryKit 功能的 Swift 结构体，提供更友好的接口。
struct DictionaryWrapper {
    
    /// 获取当前在系统词典 App 中所有已激活的词典列表。
    /// - Returns: 一个 `TTTDictionary` 对象数组。
    static func getActiveDictionaries() -> [TTTDictionary] {
        // TTTDictionary.activeDictionaries() 是一个 Objective-C 的类方法，在 Swift 中作为静态方法调用。
        return TTTDictionary.activeDictionaries()
    }
    
    /// 在所有激活的词典中搜索一个词条。
    /// - Parameter term: 需要搜索的词语或短语。
    /// - Returns: 一个字典，Key 是词典名称，Value 是在该词典中找到的 `TTTDictionaryEntry` 结果数组。
    static func searchInAllActiveDictionaries(term: String) -> [String: [TTTDictionaryEntry]] {
        let dictionaries = getActiveDictionaries()
        var results = [String: [TTTDictionaryEntry]]()
        
        for dict in dictionaries {
            // .entries(forSearchTerm:) 是一个 Objective-C 的实例方法，在 Swift 中正常调用。
            let entries = dict.entries(forSearchTerm: term)
            if !entries.isEmpty {
                results[dict.name] = entries
            }
        }
        
        return results
    }
    
    /// 在指定的词典中搜索一个词条。
    /// - Parameters:
    ///   - term: 需要搜索的词语或短语。
    ///   - dictionary: 指定的 `TTTDictionary` 对象。
    /// - Returns: 找到的 `TTTDictionaryEntry` 结果数组。
    static func search(term: String, in dictionary: TTTDictionary) -> [TTTDictionaryEntry] {
        return dictionary.entries(forSearchTerm: term)
    }
    
    /// 获取语言代码到词典名称的映射。
    ///
    /// 例如 "Simplified-Chinese" -> "现代汉语规范词典"
    /// - Returns: 一个 `[String: String]` 类型的字典。
    static func getLanguageToDictionaryNameMap() -> [String: String] {
        // MARK: - 修正点
        // TTTDictionary.languageToDictionaryNameMap 是一个 Objective-C 的类属性 (@property (class, ...))
        // 在 Swift 中，它被桥接为一个静态计算属性 (static var)。
        // 因此，我们直接访问它，而不是像调用方法一样使用括号 ()。
        if let map = TTTDictionary.languageToDictionaryNameMap as? [String: String] {
            return map
        }
        return [:]
    }
}
 
