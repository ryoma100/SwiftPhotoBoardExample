//
//  PhotoSection.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/17.
//

import SwiftUI

struct PhotoSection: View {
    @Binding var isShowingPhotosPicker: Bool
    @Binding var isShowingCamera: Bool
    let image: UIImage?
    let isShowingFallback: Bool
    let hasPhoto: Bool
    let onRemove: () -> Void

    var body: some View {
        Section("Photo") {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityIdentifier("CapturedPhoto")
            }
            if isShowingFallback {
                Text(
                    "Photo from the library is unavailable. Showing thumbnail instead."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Button {
                isShowingPhotosPicker = true
            } label: {
                Label("Select Photo", systemImage: "photo.on.rectangle")
            }
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    isShowingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
            }
            if hasPhoto {
                Button(role: .destructive) {
                    onRemove()
                } label: {
                    Label("Delete Photo", systemImage: "trash")
                }
            }
        }
    }
}
