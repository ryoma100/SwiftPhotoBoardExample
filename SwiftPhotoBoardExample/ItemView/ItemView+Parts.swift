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
        let viewModel: ItemViewModel

        var body: some View {
            if let imageSource = viewModel.imageSource {
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
        let viewModel: ItemViewModel

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
                if let localIdentifier = newValue?.itemIdentifier {
                    Task { await viewModel.selectPhoto(localIdentifier) }
                }
            }
        }
    }

    struct TakeCameraButton: View {
        let viewModel: ItemViewModel

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
                            viewModel.takeCamera(image)
                        }
                    }
                    .ignoresSafeArea()
                }
            }
        }
    }

    struct RemoveImageButton: View {
        let viewModel: ItemViewModel

        var body: some View {
            Button(role: .destructive) {
                viewModel.removeImage()
            } label: {
                Label("Delete Photo", systemImage: "trash")
            }
            .disabled(viewModel.imageSource == nil)
        }
    }

    struct SaveButton: View {
        let viewModel: ItemViewModel
        let onSuccess: () -> Void

        @State private var isShowingEmptyTitleAlert: Bool = false
        @State private var isShowingSaveErrorAlert = false

        private var isTitleEmpty: Bool {
            viewModel.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
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
            .alert("Save error", isPresented: $isShowingSaveErrorAlert) {
                Button("OK", role: .cancel) {}
            }
        }

        private func handleSave() {
            if isTitleEmpty {
                isShowingEmptyTitleAlert = true
                return
            }

            Task {
                do {
                    try await viewModel.save()
                    onSuccess()
                } catch {
                    isShowingSaveErrorAlert = true
                }
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
