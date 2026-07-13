//
//  ListView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import SwiftData
import SwiftUI

private let imageSercice: ImageService = ImageServiceImpl()
private let size: CGFloat = 64

struct ListView: View {

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    @State private var viewModel = ListViewModel()

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        ItemView(item: item)
                    } label: {
                        ListRow(item: item)
                    }
                }
                .onDelete { offsets in
                    withAnimation {
                        try! viewModel.deleteItems(
                            items: items,
                            offsets: offsets
                        )
                    }
                }
            }
            .navigationTitle("Photo Board")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    NavigationLink {
                        ItemView(item: nil)
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
        .onAppear {
            viewModel = ListViewModel(modelContext: modelContext)
        }
    }

    struct ListRow: View {
        private let item: Item
        private let thumbnail: UIImage?

        init(
            item: Item,
        ) {
            self.item = item
            self.thumbnail = imageSercice.loadThumbnail(
                fileId: item.imageFileId
            )
        }

        var body: some View {
            HStack {
                Group {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: "photo")
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: size, height: size)
                .background(Color(.secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                VStack(alignment: .leading) {
                    Text(item.title)
                    Text(
                        item.timestamp,
                        format: Date.FormatStyle(
                            date: .numeric,
                            time: .standard
                        )
                    )
                    if !item.note.isEmpty {
                        Text(item.note)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! makeModelContiner(isStoredInMemoryOnly: true)
    ListView().modelContainer(container)
}
