import Foundation
@preconcurrency import ScreenCaptureKit
import Vision
import AppKit

// MARK: - 数据模型
struct CapturableWindow: Identifiable, Hashable, Sendable {
    let id: CGWindowID
    let appName: String
    let windowTitle: String
    let windowID: CGWindowID
    let frame: CGRect // 1. 新增 frame 属性
}

struct OCR_Word: Identifiable, Sendable {
    let id = UUID()
    let word: String
    let absolutePosition: CGPoint
}

// MARK: - Capture Handler
@MainActor
class CaptureHandler: NSObject {
    
    /// 获取所有可捕获的窗口列表
    func _available_windows() async -> [CapturableWindow] {
        do {
            let content = try await SCShareableContent.current
            
            let windows = content.windows.filter { window in
                guard window.isOnScreen, window.windowLayer == 0,
                      let app = window.owningApplication,
                      app.processID != 0,
                      !app.applicationName.isEmpty,
                      app.bundleIdentifier != Bundle.main.bundleIdentifier
                else {
                    return false
                }
                return window.title != nil && !window.title!.isEmpty
            }.compactMap { window -> CapturableWindow? in
                guard let app = window.owningApplication else { return nil }
                return CapturableWindow(
                    id: window.windowID,
                    appName: app.applicationName,
                    windowTitle: window.title ?? "无标题",
                    windowID: window.windowID,
                    frame: window.frame // 2. 填充 frame 属性
                )
            }
            return windows
        } catch {
            print("获取可用窗口失败: \(error.localizedDescription)")
            return []
        }
    }


    // 4. 新增：捕获指定区域并进行OCR
    func _capture_area(rect: CGRect) async -> [OCR_Word] {
        // SCContentFilter 不支持直接按CGRect过滤，所以我们先截取全屏
        // 然后在软件层面裁剪出我们需要的区域。
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else {
                print("错误: 找不到主显示器。")
                return []
            }
            
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height
            
            let fullImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            
            // --- 坐标系转换修正 ---
            // 传入的 rect 是屏幕坐标（左下角为原点）。
            // CGImage.cropping(to:) 需要的是图像坐标（左上角为原点）。
            // 我们需要手动翻转Y轴。
            let displayHeight = CGFloat(display.height)
            let croppingRect = CGRect(
                x: rect.origin.x,
                y: displayHeight - rect.origin.y - rect.height, // Y轴翻转
                width: rect.width,
                height: rect.height
            )
            // --- 修正结束 ---

            // 使用修正后的 croppingRect 进行裁剪
            guard let croppedImage = fullImage.cropping(to: croppingRect) else {
                print("错误: 无法根据CGRect裁剪图像。")
                return []
            }
            
            // 将裁剪后的图像传递给OCR，其原点现在是目标区域的左上角相对于整个屏幕的位置
            let ocrResults = try await _ocr_wrapper(croppedImage, origin: rect.origin)
            return ocrResults
            
        } catch {
            print("区域捕获失败: \(error.localizedDescription)")
            return []
        }
    }
    /// 捕获全屏并进行OCR识别
    func _s_capture() async -> [OCR_Word] {
        do {
            let content = try await SCShareableContent.current
            guard let display = content.displays.first else {
                print("错误: 找不到主显示器。")
                return []
            }
            
            let filter = SCContentFilter(display: display, excludingApplications: [], exceptingWindows: [])
            let config = SCStreamConfiguration()
            config.width = display.width
            config.height = display.height
            
            let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
            let ocrResults = try await _ocr_wrapper(image, origin: .zero)
            return ocrResults
            
        } catch {
            print("屏幕捕获失败: \(error.localizedDescription)")
            return []
        }
    }
    
    private func _ocr_wrapper(_ image: CGImage, origin: CGPoint) async throws -> [OCR_Word] {
        let requestHandler = VNImageRequestHandler(cgImage: image)
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { (request, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                let ocrWords = observations.flatMap { observation -> [OCR_Word] in
                    guard let topCandidate = observation.topCandidates(1).first else { return [] }
                    // 使用最终修复的函数
                    return self.processRecognizedText(text: topCandidate, imageSize: image.size, absoluteOrigin: origin)
                }
                continuation.resume(returning: ocrWords)
            }
            request.recognitionLanguages = ["en-US"]
            request.recognitionLevel = .accurate
            
            do {
                try requestHandler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
    
    /// 辅助函数：处理识别到的文本 (最终正确版本)
    private func processRecognizedText(text: VNRecognizedText, imageSize: CGSize, absoluteOrigin: CGPoint) -> [OCR_Word] {
        var results: [OCR_Word] = []
        let fullString = text.string
        
        // 使用 enumerateSubstrings 来遍历每个单词，它能提供单词的精确范围 (Range<String.Index>)
        fullString.enumerateSubstrings(in: fullString.startIndex..<fullString.endIndex, options: .byWords) { (word, range, _, _) in
            
            guard let word = word, !word.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return
            }
            
            do {
                // 核心修复：使用 text.boundingBox(for:) 来获取指定范围的边界框
                if let wordBox = try text.boundingBox(for: range) {
                    // wordBox 是一个 VNRectangleObservation，其 boundingBox 是归一化的坐标
                    
                    // 1. 将归一化的坐标转换为图像像素坐标
                    let pixelRect = VNImageRectForNormalizedRect(wordBox.boundingBox, Int(imageSize.width), Int(imageSize.height))
                    
                    // 2. 计算中心点
                    let wordCenterInImage = CGPoint(x: pixelRect.midX, y: pixelRect.midY)
                    
                    // 3. 转换为绝对屏幕坐标，并翻转Y轴
                    // Vision的Y轴原点在左上角，macOS屏幕坐标原点在左下角
                    let finalAbsolutePosition = CGPoint(
                        x: absoluteOrigin.x + wordCenterInImage.x,
                        y: absoluteOrigin.y + (imageSize.height - wordCenterInImage.y)
                    )
                    
                    results.append(OCR_Word(word: word, absolutePosition: finalAbsolutePosition))
                }
            } catch {
                print("无法获取单词 '\(word)' 的边界框: \(error)")
            }
        }
        
        return results
    }
}

extension CGImage {
    var size: CGSize {
        return CGSize(width: self.width, height: self.height)
    }
}
