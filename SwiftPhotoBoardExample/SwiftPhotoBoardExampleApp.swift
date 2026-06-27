//
//  SwiftPhotoBoardExampleApp.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/09.
//

import SwiftData
import SwiftUI

@main
struct SwiftPhotoBoardExampleApp: App {
    var sharedModelContainer: ModelContainer = {
        do {
            return try makeModelContiner(isStoredInMemoryOnly: false)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ListView()
        }
        .modelContainer(sharedModelContainer)
    }
}

func makeModelContiner(isStoredInMemoryOnly: Bool) throws -> ModelContainer {
    let schema = Schema(versionedSchema: SchemaV1.self)
    let container = try ModelContainer(
        for: schema,
        migrationPlan: MigrationPlan.self,
        configurations: ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly
        )
    )
    return container
}
