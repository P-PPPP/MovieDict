import Foundation
import SQLite

// MARK: - 数据模型 (保持不变)
struct MyWord {
    let word: String
    let createTime: Date
    let sourceMedia: String
    let mediaTimestamp: Int
}

struct MySentence {
    let sentence: String
    let relatedWords: [String]
    let sourceMedia: String
    let createTime: Date
}


// MARK: - Database Handler
class DatabaseHandler {
    
    static let shared = DatabaseHandler()
    private var db: Connection?
    
    // MARK: - Table and Column Definitions
    private let myWords = Table("My_Words")
    private let wordCol = Expression<String>("Word")
    private let createTimeCol = Expression<Date>("Create_Time")
    private let sourceMediaCol = Expression<String>("Source_Media")
    private let mediaTimestampCol = Expression<Int>("Meida_TimeStamp")
    
    private let mySentences = Table("My_Sentences")
    private let sentencesCol = Expression<String>("Sentences")
    private let relatedWordsCol = Expression<String>("Related_Words")
    
    private init() {
        do {
            // 直接使用 AppPath 工具获取数据库的准确URL
            db = try Connection(AppPath.databaseURL.path)
        } catch {
            db = nil
            print("无法连接到数据库: \(error)")
        }
    }
    
    // MARK: - Public API
    
    // 1. 将所有返回类型从 Result 改为 Swift.Result
    func addWord(word_to_added: String, _source_media: String = "", _media_timestamp: Int = 0) -> Swift.Result<Int64, Error> {
        guard let db = db else { return .failure(DatabaseError.connectionFailed) }
        do {
            let count = try db.scalar(myWords.filter(wordCol.lowercaseString == word_to_added.lowercased()).count)
            if count > 0 { return .failure(DatabaseError.duplicateEntry) }
            
            let insert = myWords.insert(wordCol <- word_to_added, createTimeCol <- Date(), sourceMediaCol <- _source_media, mediaTimestampCol <- _media_timestamp)
            let rowid = try db.run(insert)
            return .success(rowid)
        } catch {
            return .failure(error)
        }
    }
    
    func addSentence(_sentence: String, _related_words: [String], _source_media: String = "") -> Swift.Result<Int64, Error> {
        guard let db = db else { return .failure(DatabaseError.connectionFailed) }
        do {
            let relatedWordsData = try JSONEncoder().encode(_related_words)
            let relatedWordsJSON = String(data: relatedWordsData, encoding: .utf8) ?? "[]"
            
            let insert = mySentences.insert(sentencesCol <- _sentence, relatedWordsCol <- relatedWordsJSON, sourceMediaCol <- _source_media, createTimeCol <- Date())
            let rowid = try db.run(insert)
            return .success(rowid)
        } catch {
            return .failure(error)
        }
    }
    
    func searchWord(_word_to_search: String) -> Swift.Result<MyWord, Error> {
        guard let db = db else { return .failure(DatabaseError.connectionFailed) }
        do {
            if let wordRow = try db.pluck(myWords.filter(wordCol.lowercaseString == _word_to_search.lowercased())) {
                let word = MyWord(word: wordRow[wordCol], createTime: wordRow[createTimeCol], sourceMedia: wordRow[sourceMediaCol], mediaTimestamp: wordRow[mediaTimestampCol])
                return .success(word)
            } else {
                return .failure(DatabaseError.notFound)
            }
        } catch {
            return .failure(error)
        }
    }
    
    func delWord(_word_to_del: String) -> Swift.Result<Bool, Error> {
        guard let db = db else { return .failure(DatabaseError.connectionFailed) }
        do {
            let changes = try db.run(myWords.filter(wordCol.lowercaseString == _word_to_del.lowercased()).delete())
            if changes > 0 {
                return .success(true)
            } else {
                return .failure(DatabaseError.notFound)
            }
        } catch {
            return .failure(error)
        }
    }
    
    func searchSentence(_sentence_to_search: String) -> Swift.Result<[MySentence], Error> {
        guard let db = db else { return .failure(DatabaseError.connectionFailed) }
        var results: [MySentence] = []
        do {
            for sentenceRow in try db.prepare(mySentences.filter(sentencesCol.like("%\(_sentence_to_search)%"))) {
                let relatedWordsData = Data(sentenceRow[relatedWordsCol].utf8)
                let relatedWords = (try? JSONDecoder().decode([String].self, from: relatedWordsData)) ?? []
                
                let sentence = MySentence(sentence: sentenceRow[sentencesCol], relatedWords: relatedWords, sourceMedia: sentenceRow[sourceMediaCol], createTime: sentenceRow[createTimeCol])
                results.append(sentence)
            }
            return .success(results)
        } catch {
            return .failure(error)
        }
    }
    
    
    /// 按照创建时间降序，列出指定范围的单词
    func list_words(length_range: [Int]? = nil) -> Swift.Result<[MyWord], Error> {
        guard let db = db else { return .failure(DatabaseError.connectionFailed) }
        
        let range = length_range ?? [0, 100] // 如果未提供，则使用默认值
        let offset = range.first ?? 0
        let limit = (range.count > 1) ? (range[1] - offset) : 100
        
        guard limit > 0 else { return .success([]) } // 如果范围无效，返回空数组
        
        var results: [MyWord] = []
        do {
            let query = myWords.order(createTimeCol.desc).limit(limit, offset: offset)
            for wordRow in try db.prepare(query) {
                let word = MyWord(
                    word: wordRow[wordCol],
                    createTime: wordRow[createTimeCol],
                    sourceMedia: wordRow[sourceMediaCol],
                    mediaTimestamp: wordRow[mediaTimestampCol]
                )
                results.append(word)
            }
            return .success(results)
        } catch {
            return .failure(error)
        }
    }
    
    /// 按照创建时间降序，列出指定范围的句子
    func list_sentences(length_range: [Int]? = nil) -> Swift.Result<[MySentence], Error> {
        guard let db = db else { return .failure(DatabaseError.connectionFailed) }
        
        let range = length_range ?? [0, 100]
        let offset = range.first ?? 0
        let limit = (range.count > 1) ? (range[1] - offset) : 100
        
        guard limit > 0 else { return .success([]) }
        
        var results: [MySentence] = []
        do {
            let query = mySentences.order(createTimeCol.desc).limit(limit, offset: offset)
            for sentenceRow in try db.prepare(query) {
                let relatedWordsJSON = sentenceRow[relatedWordsCol]
                let relatedWordsData = Data(relatedWordsJSON.utf8)
                let relatedWords = (try? JSONDecoder().decode([String].self, from: relatedWordsData)) ?? []
                
                let sentence = MySentence(
                    sentence: sentenceRow[sentencesCol],
                    relatedWords: relatedWords,
                    sourceMedia: sentenceRow[sourceMediaCol],
                    createTime: sentenceRow[createTimeCol]
                )
                results.append(sentence)
            }
            return .success(results)
        } catch {
            return .failure(error)
        }
    }
}


// MARK: - Custom Errors (保持不变)
enum DatabaseError: Error, LocalizedError {
    case connectionFailed
    case duplicateEntry
    case notFound
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed: return "数据库连接失败。"
        case .duplicateEntry: return "条目已存在，无法重复添加。"
        case .notFound: return "未找到指定的条目。"
        }
    }
}
