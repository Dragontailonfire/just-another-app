//
//  FolderFormView.swift
//  just-another-app
//
//  Created by Narayanan VK on 14/02/2026.
//

import SwiftUI
import SwiftData

struct FolderFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var folderToEdit: Folder?
    var parentFolder: Folder?

    @State private var name: String = ""
    @State private var selectedParent: Folder?
    @State private var selectedColor: String = "blue"
    @State private var selectedIcon: String = "folder.fill"
    @State private var parentSearchText = ""

    @Query(sort: \Folder.name) private var allFolders: [Folder]

    private var isEditing: Bool { folderToEdit != nil }

    private var availableParents: [Folder] {
        allFolders.filter { $0.persistentModelID != folderToEdit?.persistentModelID }
    }

    private var filteredParents: [Folder] {
        let hierarchical = Folder.hierarchicalSort(availableParents)
        guard !parentSearchText.isEmpty else { return hierarchical }
        let query = parentSearchText.lowercased()
        return hierarchical.filter {
            $0.name.lowercased().contains(query) || $0.path.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("Folder name", text: $name)
                }
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(FolderAppearance.availableColors, id: \.name) { item in
                                Circle()
                                    .fill(item.color)
                                    .frame(width: 32, height: 32)
                                    .glassEffect(selectedColor == item.name ? .regular : .identity)
                                    .overlay {
                                        if selectedColor == item.name {
                                            Image(systemName: "checkmark")
                                                .font(.caption.bold())
                                                .foregroundStyle(.white)
                                        }
                                    }
                                    .onTapGesture { selectedColor = item.name }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
                Section("Icon") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44))], spacing: 12) {
                        ForEach(FolderAppearance.availableIcons, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title2)
                                .frame(width: 44, height: 44)
                                .glassEffect(
                                    selectedIcon == icon
                                        ? .regular.tint(FolderAppearance.color(for: selectedColor))
                                        : .identity
                                )
                                .foregroundStyle(
                                    selectedIcon == icon
                                        ? FolderAppearance.color(for: selectedColor)
                                        : .secondary
                                )
                                .onTapGesture { selectedIcon = icon }
                        }
                    }
                    .padding(.vertical, 4)
                }
                Section("Parent Folder") {
                    if availableParents.count > 5 {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.secondary)
                            TextField("Search folders", text: $parentSearchText)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            if !parentSearchText.isEmpty {
                                Button {
                                    parentSearchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    Button {
                        selectedParent = nil
                    } label: {
                        HStack {
                            Text("None (top level)")
                                .foregroundStyle(.primary)
                            Spacer()
                            if selectedParent == nil {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    ForEach(filteredParents) { folder in
                        Button {
                            selectedParent = folder
                        } label: {
                            HStack {
                                Image(systemName: folder.iconName)
                                    .foregroundStyle(FolderAppearance.color(for: folder.colorName))
                                Text(folder.path)
                                    .foregroundStyle(.primary)
                                Spacer()
                                if selectedParent?.persistentModelID == folder.persistentModelID {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(.blue)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Folder" : "New Folder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: populate)
        }
    }

    private func populate() {
        if let folder = folderToEdit {
            name = folder.name
            selectedParent = folder.parent
            selectedColor = folder.colorName
            selectedIcon = folder.iconName
        } else {
            selectedParent = parentFolder
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        if let folder = folderToEdit {
            folder.name = trimmedName
            folder.parent = selectedParent
            folder.colorName = selectedColor
            folder.iconName = selectedIcon
        } else {
            let folder = Folder(name: trimmedName, colorName: selectedColor, iconName: selectedIcon, parent: selectedParent)
            modelContext.insert(folder)
            selectedParent?.children.append(folder)
        }
        dismiss()
    }
}

#Preview("Add") {
    FolderFormView()
        .modelContainer(for: [Bookmark.self, Folder.self], inMemory: true)
}
