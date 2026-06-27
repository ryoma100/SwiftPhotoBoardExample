//
//  ItemView+Parts.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/25.
//

import PhotosUI
import SwiftUI

extension ItemView {
    struct ImageOrThumbnail: View {
        let imageSource: ImageSource?

        var body: some View {
            if let imageSource {
                Image(uiImage: imageSource.image)
                    .resizable()
                    .scaledToFit()
                    .accessibilityIdentifier("CapturedPhoto")

                if case .thumbnail = imageSource {
                    Text(
                        "Photo from the library is unavailable. Showing thumbnail instead."
                    )
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    struct SelectPhotoButton: View {
        let onChangeLocalIdentifier: (String?) -> Void

        @State private var isShowingPhotosPicker: Bool = false
        @State private var pickerItem: PhotosPickerItem?

        var body: some View {
            Button {
                isShowingPhotosPicker = true
            } label: {
                Label("Select Photo", systemImage: "photo.on.rectangle")
            }
            .photosPicker(
                isPresented: $isShowingPhotosPicker,
                selection: $pickerItem,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: pickerItem) { _, newValue in
                if let identifier = newValue?.itemIdentifier {
                    onChangeLocalIdentifier(identifier)
                }
            }
        }
    }

    struct TakeCameraButton: View {
        let onTakeCamera: (UIImage) -> Void

        @State private var isShowingCamera: Bool = false

        var body: some View {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button {
                    isShowingCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera")
                }
                .fullScreenCover(isPresented: $isShowingCamera) {
                    CameraPicker { image in
                        isShowingCamera = false
                        if let image {
                            onTakeCamera(image)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }

    struct RemoveImageButton: View {
        let disabled: Bool
        let onRemove: () -> Void

        var body: some View {
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Delete Photo", systemImage: "trash")
            }
            .disabled(disabled)
        }
    }

    struct SaveButton: View {
        let title: String
        let onSave: () -> Void

        @State private var isShowingEmptyTitleAlert: Bool = false

        private var isTitleEmpty: Bool {
            title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        var body: some View {
            Button("Save") {
                handleSave()
            }
            .foregroundStyle(isTitleEmpty ? Color.gray : Color.accentColor)
            .alert(
                "Title is required",
                isPresented: $isShowingEmptyTitleAlert
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Please enter a title before saving.")
            }
        }

        private func handleSave() {
            if isTitleEmpty {
                isShowingEmptyTitleAlert = true
            } else {
                onSave()
            }
        }
    }

    struct KeyboardDownButton: View {
        var body: some View {
            Button {
                UIApplication.shared.sendAction(
                    #selector(UIResponder.resignFirstResponder),
                    to: nil,
                    from: nil,
                    for: nil
                )
            } label: {
                Image(systemName: "keyboard.chevron.compact.down")
            }
            .accessibilityLabel("Done")
        }
    }
}
