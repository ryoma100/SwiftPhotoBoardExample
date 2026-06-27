//
//  ItemView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import PhotosUI
import SwiftData
import SwiftUI

struct ItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let item: Item?
    @State private var viewModel: ItemViewModel = ItemViewModel()
    @State private var isShowingSaveErrorAlert: Bool = false

    var body: some View {
        Form {
            ClearableTextField(
                titleKey: "Title",
                text: $viewModel.title,
                axis: .horizontal,
                fieldIdentifier: "Title",
                clearIdentifier: "ClearTitle"
            )
            DatePicker("Timestamp", selection: $viewModel.timestamp)
            ClearableTextField(
                titleKey: "Note",
                text: $viewModel.note,
                fieldIdentifier: "Note",
                clearIdentifier: "ClearNote"
            )
            Section("Photo") {
                ImageOrThumbnail(imageSource: viewModel.imageSource)
                SelectPhotoButton { localIdentifier in
                    Task { await viewModel.selectPhoto(localIdentifier) }
                }
                TakeCameraButton { viewModel.takeCamera($0) }
                RemoveImageButton(disabled: viewModel.imageSource == nil) {
                    viewModel.removeImage()
                }
            }
        }
        .navigationTitle(item == nil ? "Add Item" : "Edit Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                SaveButton(title: viewModel.title) {
                    Task { await handleSave() }
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                KeyboardDownButton()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .alert("Save error", isPresented: $isShowingSaveErrorAlert) {
            Button("OK", role: .cancel) {}
        }
        .task {
            viewModel = await ItemViewModel(
                modelContext: modelContext,
                item: item
            )
        }
    }

    private func handleSave() async {
        do {
            try await viewModel.save()
            dismiss()
        } catch {
            isShowingSaveErrorAlert = true
        }
    }
}

#Preview {
    let container = try! makeModelContiner(isStoredInMemoryOnly: true)
    ItemView(item: nil).modelContainer(container)
}
