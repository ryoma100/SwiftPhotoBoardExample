//
//  ListView.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import SwiftData
import SwiftUI

struct ListView: View {
    @Query(sort: \Item.timestamp, order: .reverse) private var items: [Item]
    @State private var viewModel: ListViewModel

    private let thmbnailService = ThumbnailServiceImpl()

    init(modelContext: ModelContext) {
        self._viewModel = State(
            wrappedValue: ListViewModel(modelContext: modelContext)
        )
    }

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        ItemView(item: item)
                    } label: {
                        ListRow(item: item, thmbnailService: thmbnailService)
                    }
                }
                .onDelete { offsets in
                    withAnimation {
                        viewModel.deleteItems(items: items, offsets: offsets)
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
                ThumbnailImage(localIdentifier: item.localIdentifier)
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
    ListView(modelContext: container.mainContext)
        .modelContainer(container)
}
