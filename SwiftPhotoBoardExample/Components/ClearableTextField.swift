//
//  ClearableTextField.swift
//  SwiftPhotoBoardExample
//
//  Created by Ryouichi Matsuda on 2026/06/15.
//

import SwiftUI

struct ClearableTextField: View {
    let titleKey: LocalizedStringKey
    @Binding var text: String
    var axis: Axis = .vertical
    var fieldIdentifier: String = ""
    var clearIdentifier: String = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        ZStack(alignment: .topTrailing) {
            TextField(titleKey, text: $text, axis: axis)
                .padding(.trailing, 24)
                .focused($isFocused)
                .accessibilityIdentifier(fieldIdentifier)
                .toolbar {
                    ToolbarItemGroup(placement: .keyboard) {
                        Spacer()
                        Button {
                            isFocused = false
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                        .accessibilityLabel("Done")
                    }
                }
            if !text.isEmpty {
                Button {
                    isFocused = false
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier(clearIdentifier)
            }
        }
    }
}
