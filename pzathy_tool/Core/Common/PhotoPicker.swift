//
//  PhotoPicker.swift
//  pzathy_tool
//
//  A single-image picker backed by PHPickerViewController. We use this instead
//  of SwiftUI's PhotosPicker because that requires iOS 16 and our deployment
//  target is iOS 15. Returns downscaled JPEG data via `onPick`.
//

import SwiftUI
import PhotosUI

struct PhotoPicker: UIViewControllerRepresentable {
    /// Called on the main thread with the picked image encoded as JPEG data.
    var onPick: (Data) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        private let parent: PhotoPicker
        init(_ parent: PhotoPicker) { self.parent = parent }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { [parent] object, _ in
                guard let image = object as? UIImage else { return }
                // Cap the long edge so covers stay small on disk.
                let resized = image.downscaled(maxDimension: 1024)
                guard let data = resized.jpegData(compressionQuality: 0.85) else { return }
                DispatchQueue.main.async { parent.onPick(data) }
            }
        }
    }
}

private extension UIImage {
    /// Returns a copy whose longest side is at most `maxDimension`, preserving
    /// aspect ratio. Returns self when already within bounds.
    func downscaled(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension, longest > 0 else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
    }
}
