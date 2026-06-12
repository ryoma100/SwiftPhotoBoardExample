//
//  ListView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        ItemView(item: item)
                    } label: {
                        HStack {
                            PhotoThumbnailView(thumbnailFileID: item.thumbnailFileID)
                            VStack(alignment: .leading) {
                                Text(item.timestamp, format: Date.FormatStyle(date: .numeric, time: .standard))
                                if !item.note.isEmpty {
                                    Text(item.note)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("Photo Board")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    NavigationLink {
                        ItemView()
                    } label: {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
        } detail: {
            Text("Select an item")
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                let item = items[index]
                if let thumbnailFileID = item.thumbnailFileID {
                    ItemView.deleteThumbnail(fileID: thumbnailFileID)
                }
                modelContext.delete(item)
            }
        }
    }
}

#Preview {
    ListView()
        .modelContainer(for: Item.self, inMemory: true)
}
