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
    private(set) var viewModel: ListViewModel

    init(modelContext: ModelContext) {
        self.viewModel = ListViewModel(
            modelContext: modelContext,
            thumbnailStore: ThumbnailServiceImpl()
        )
    }

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(items) { item in
                    NavigationLink {
                        ItemView(item: item)
                    } label: {
                        ListItemView(item: item)
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
}

#Preview {
    let container = try! makeModelContiner(isStoredInMemoryOnly: true)
    ListView(modelContext: container.mainContext)
        .modelContainer(container)
}
