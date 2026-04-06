import SwiftUI
import UIKit
import ImageIO

// MARK: - PetView

/// Displays the pixel-cat GIF for a given mood and color.
/// GIFs are fetched from exsec-dev/pixel-cat (GitHub raw) and cached to disk.
struct PetView: View {
    let mood: PetMood
    let petColor: PetColor

    private var gifURL: URL {
        let base = "https://raw.githubusercontent.com/exsec-dev/pixel-cat/main/src/icon/cat"
        let file = "\(petColor.rawValue)_\(mood.gifAnimation)_8fps.gif"
        return URL(string: "\(base)/\(file)")!
    }

    var body: some View {
        GIFImageView(url: gifURL)
            .id(gifURL.absoluteString)  // force view refresh when mood/color changes
    }
}

// MARK: - GIFImageView

/// UIViewRepresentable that downloads, caches, and animates a GIF from a remote URL.
/// Uses only system ImageIO framework — no third-party dependencies.
private struct GIFImageView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> UIImageView {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.clipsToBounds = true
        load(into: view)
        return view
    }

    func updateUIView(_ view: UIImageView, context: Context) {
        load(into: view)
    }

    // MARK: - Load

    private func load(into view: UIImageView) {
        let cacheURL = Self.cacheURL(for: url)

        // Serve from disk cache if available.
        if let data = try? Data(contentsOf: cacheURL) {
            Self.animate(view: view, with: data)
            return
        }

        // Download, cache to disk, then animate.
        URLSession.shared.dataTask(with: url) { data, _, _ in
            guard let data else { return }
            try? data.write(to: cacheURL)
            DispatchQueue.main.async { Self.animate(view: view, with: data) }
        }.resume()
    }

    // MARK: - GIF → UIImageView animation

    private static func animate(view: UIImageView, with data: Data) {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else { return }

        let count = CGImageSourceGetCount(source)
        var frames: [UIImage] = []
        var totalDuration = 0.0

        for i in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, i, nil) else { continue }
            frames.append(UIImage(cgImage: cgImage))

            if let props = CGImageSourceCopyPropertiesAtIndex(source, i, nil) as? [String: Any],
               let gif   = props[kCGImagePropertyGIFDictionary as String] as? [String: Any] {
                let delay = (gif[kCGImagePropertyGIFUnclampedDelayTime as String] as? Double)
                         ?? (gif[kCGImagePropertyGIFDelayTime as String]          as? Double)
                         ?? 0.1
                totalDuration += max(delay, 0.02)  // GIF spec minimum 20ms
            }
        }

        guard !frames.isEmpty else { return }
        view.animationImages   = frames
        view.animationDuration = totalDuration > 0 ? totalDuration : Double(count) * 0.1
        view.startAnimating()
    }

    // MARK: - Cache

    private static func cacheURL(for url: URL) -> URL {
        let dir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PixelCat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(url.lastPathComponent)
    }
}
