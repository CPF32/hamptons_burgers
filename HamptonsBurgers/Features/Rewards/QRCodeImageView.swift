import CoreImage.CIFilterBuiltins
import SwiftUI

struct QRCodeImageView: View {
    let payload: String
    var size: CGFloat = 200

    private var image: UIImage? {
        QRCodeImageGenerator.makeImage(from: payload, size: size)
    }

    var body: some View {
        Group {
            if let image {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .accessibilityLabel("QR code")
            } else {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Theme.surface)
                    .frame(width: size, height: size)
                    .overlay {
                        Text("Unable to create QR code")
                            .font(.caption)
                            .foregroundStyle(Theme.mutedText)
                            .multilineTextAlignment(.center)
                            .padding(8)
                    }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

enum QRCodeImageGenerator {
    private static let context = CIContext()

    static func makeImage(from string: String, size: CGFloat) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scale = size / output.extent.width
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
