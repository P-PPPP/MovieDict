//
//  DictionaryWrapper.swift
//  MovieWords
//
//  在 Services 文件夹下
//

import Foundation

/// 一个封装了 DictionaryKit 功能的 Swift 结构体，提供更友好的接口。
struct DictionaryWrapper {

    // MARK: - DEFINITIVE FIX
    // Add the @MainActor attribute to this function.
    // This ensures it runs on the main thread, which is required to safely
    // access the @MainActor-isolated 'dictControl' property on the shared AppSettingsManager.
    @MainActor
    static func searchAccordingToUserSettings(term: String) -> [String: [TTTDictionaryEntry]] {
        // 从全局设置管理器获取当前配置
        let settings = AppSettingsManager.shared.dictControl
        
        if settings.Using_All_Dicts {
            // 如果用户选择查询所有词典，则调用现有函数
            return searchInAllActiveDictionaries(term: term)
        } else {
            // 否则，只在用户选择的那个词典中搜索
            let shortName = settings.Selected_Dictionary_ShortName
            return search(term: term, inDictionaryWithShortName: shortName)
        }
    }

    /// 获取当前在系统词典 App 中所有已激活的词典列表。
    /// - Returns: 一个 `TTTDictionary` 对象数组。
    static func getActiveDictionaries() -> [TTTDictionary] {
        return TTTDictionary.activeDictionaries()
    }
    
    /// 检查具有指定 shortName 的词典是否存在于系统中。
    /// - Parameter shortName: 要验证的词典短名称
    /// - Returns: 如果找到该词典则返回 `true`，否则返回 `false`。
    static func dictionaryExists(with shortName: String) -> Bool {
        return TTTDictionary.availableDictionaries().contains { $0.shortName == shortName }
    }
    
    /// 在所有激活的词典中搜索一个词条。
    /// - Parameter term: 需要搜索的词语或短语。
    /// - Returns: 一个字典，Key 是词典名称，Value 是在该词典中找到的 `TTTDictionaryEntry` 结果数组。
    static func searchInAllActiveDictionaries(term: String) -> [String: [TTTDictionaryEntry]] {
        let dictionaries = getActiveDictionaries()
        var results = [String: [TTTDictionaryEntry]]()
        
        for dict in dictionaries {
            let entries = dict.entries(forSearchTerm: term)
            if !entries.isEmpty {
                results[dict.name] = entries
            }
        }
        return results
    }
    
    /// 在具有特定 shortName 的词典中搜索。
    /// - Parameters:
    ///   - term: 搜索词.
    ///   - shortName: 词典的 shortName.
    /// - Returns: 包含单个词典结果的字典。
    static func search(term: String, inDictionaryWithShortName shortName: String) -> [String: [TTTDictionaryEntry]] {
        // 找到 shortName 匹配的那个词典
        guard let dictionary = TTTDictionary.availableDictionaries().first(where: { $0.shortName == shortName }) else {
            // 如果找不到词典（例如，用户卸载了它），返回空结果
            return [:]
        }
        
        // 在找到的词典中执行搜索
        let entries = dictionary.entries(forSearchTerm: term)
        if !entries.isEmpty {
            // 以与 `searchInAllActiveDictionaries` 相同的格式返回结果
            return [dictionary.name: entries]
        }
        
        return [:]
    }
    
    /// 获取语言代码到词典名称的映射。
    static func getLanguageToDictionaryNameMap() -> [String: String] {
        return TTTDictionary.languageToDictionaryNameMap
    }
}
