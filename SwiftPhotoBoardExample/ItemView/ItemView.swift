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
    let item: Item?

    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = ItemViewModel()

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
                ImageOrThumbnail(viewModel: viewModel)
                SelectPhotoButton(viewModel: viewModel)
                TakeCameraButton(viewModel: viewModel)
                RemoveImageButton(viewModel: viewModel)
            }
        }
        .navigationTitle(item == nil ? "Add Item" : "Edit Item")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                SaveButton(viewModel: viewModel)
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                KeyboardDownButton()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .task {
            if viewModel.modelContext == nil {
                viewModel = await ItemViewModel(
                    modelContext: modelContext,
                    item: item
                )
            }
        }
    }
}

#Preview {
    let container = try! makeModelContiner(isStoredInMemoryOnly: true)
    ItemView(item: nil).modelContainer(container)
}
