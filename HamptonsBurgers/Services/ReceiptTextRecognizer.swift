import UIKit
import Vision

enum ReceiptTextRecognizer {
    static func recognizeLines(in image: UIImage) async throws -> [String] {
        let prepared = preparedForOCR(image)
        guard let cgImage = prepared.cgImage else { return [] }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let observations = (request.results as? [VNRecognizedTextObservation])?
                    .sorted { $0.boundingBox.minY > $1.boundingBox.minY }
                    ?? []

                let lines = observations.compactMap { observation -> String? in
                    let candidates = observation.topCandidates(3).map(\.string)
                    return candidates.first(where: containsReceiptKeyword) ?? candidates.first
                }

                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]
            request.customWords = [
                "Subtotal",
                "Subtotal:",
                "Sub Total",
                "Tax",
                "Sales Tax",
                "Total",
                "Tip",
                "Hamptons",
                "Burgers"
            ]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func parseSubtotal(from image: UIImage) async throws -> Double? {
        let lines = try await recognizeLines(in: image)
        return ReceiptSubtotalParser.parseSubtotal(from: lines)
    }

    private static func containsReceiptKeyword(_ line: String) -> Bool {
        let lower = line.lowercased()
        return lower.contains("subtotal")
            || lower.contains("sub total")
            || lower.contains("tax")
            || lower.contains("total")
            || lower.contains("$")
            || lower.contains("tip")
    }

    private static func preparedForOCR(_ image: UIImage) -> UIImage {
        let upright = image.normalizedOrientation()
        let minWidth: CGFloat = 1_600
        guard upright.size.width > 0, upright.size.width < minWidth else { return upright }

        let scale = minWidth / upright.size.width
        let newSize = CGSize(width: minWidth, height: upright.size.height * scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1

        return UIGraphicsImageRenderer(size: newSize, format: format).image { _ in
            upright.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
