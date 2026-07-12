//
//  ListView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import SwiftData
import SwiftUI

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
            viewModel = ListViewModel(modelContext: modelContext, )
        }
    }

    struct ListRow: View {
        private let item: Item
        private let thmbnailService: ThumbnailService

        init(
            item: Item,
            thmbnailService: ThumbnailService = ThumbnailServiceImpl()
        ) {
            self.item = item
            self.thmbnailService = thmbnailService
        }

        var body: some View {
            HStack {
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
