//
//  OCRHelper.swift
//  CareCircle
//
//  Extracts text from PDF data using Vision framework OCR.
//

import UIKit
import Vision
import PDFKit

struct OCRHelper {
    /// Extract text from PDF data using Vision's text recognition.
    static func extractText(from pdfData: Data) async -> String? {
        guard let pdfDocument = PDFDocument(data: pdfData) else { return nil }

        var allText = ""

        for pageIndex in 0..<pdfDocument.pageCount {
            guard let page = pdfDocument.page(at: pageIndex) else { continue }
            let pageImage: UIImage = page.thumbnail(of: CGSize(width: 2048, height: 2048), for: .mediaBox)

            guard let cgImage = pageImage.cgImage else { continue }

            let text = await recognizeText(in: cgImage)
            if !text.isEmpty {
                if !allText.isEmpty { allText += "\n\n" }
                allText += text
            }
        }

        return allText.isEmpty ? nil : allText
    }

    private static func recognizeText(in image: CGImage) async -> String {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, _ in
                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: image, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: "")
            }
        }
    }
}
