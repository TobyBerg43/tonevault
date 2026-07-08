import SwiftUI
import SwiftData
import PhotosUI

/// Create or edit a piece of gear: name, type, control template, color, optional photo, notes.
struct GearEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// nil = creating new.
    let gear: Gear?

    @State private var name: String = ""
    @State private var type: GearType = .pedal
    @State private var template: ControlTemplate = .threeKnob
    @State private var colorHex: String = GearColorPreset.orange.rawValue
    @State private var notes: String = ""
    @State private var customLabels: [Int: String] = [:]
    @State private var photoItem: PhotosPickerItem?
    @State private var photoFilename: String?
    @State private var loadedPhoto: UIImage?

    private var isEditing: Bool { gear != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Boss DS-1, Fender Deluxe", text: $name)
                        .textInputAutocapitalization(.words)
                    Text("You name your gear. ToneVault ships no brand database or logos.")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(GearType.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Control layout") {
                    Picker("Template", selection: $template) {
                        ForEach(ControlTemplate.allCases) { Text($0.displayName).tag($0) }
                    }
                    if isEditing {
                        Text("Changing the layout keeps values for controls that still exist and seeds defaults for new ones.")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }

                Section("Control labels (optional)") {
                    ForEach(template.controls) { spec in
                        HStack {
                            Text(spec.kind.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 64, alignment: .leading)
                            TextField(spec.label, text: Binding(
                                get: { customLabels[spec.id] ?? "" },
                                set: { customLabels[spec.id] = $0 }
                            ))
                        }
                    }
                }

                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(GearColorPreset.allCases) { preset in
                                Circle()
                                    .fill(preset.color)
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle().stroke(Color.primary, lineWidth: colorHex == preset.rawValue ? 3 : 0)
                                    )
                                    .onTapGesture { colorHex = preset.rawValue }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }

                Section("Photo (optional)") {
                    if let loadedPhoto {
                        Image(uiImage: loadedPhoto)
                            .resizable().scaledToFit()
                            .frame(maxHeight: 160)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(loadedPhoto == nil ? "Attach photo" : "Replace photo", systemImage: "photo")
                    }
                    if loadedPhoto != nil {
                        Button(role: .destructive) {
                            removePhoto()
                        } label: { Label("Remove photo", systemImage: "trash") }
                    }
                }

                Section("Notes") {
                    TextField("Anything worth remembering", text: $notes, axis: .vertical)
                        .lineLimit(2...5)
                }
            }
            .navigationTitle(isEditing ? "Edit Gear" : "New Gear")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: loadIfEditing)
            .onChange(of: photoItem) { _, newItem in
                Task { await loadPickedPhoto(newItem) }
            }
        }
    }

    private func loadIfEditing() {
        guard let gear else { return }
        name = gear.name
        type = gear.type
        template = gear.template
        colorHex = gear.brandColorHex ?? GearColorPreset.orange.rawValue
        notes = gear.notes
        customLabels = gear.customLabels
        photoFilename = gear.photoFilename
        loadedPhoto = FileStorage.loadPhoto(gear.photoFilename)
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            loadedPhoto = image
            // Persist immediately to a file; delete old one if replacing.
            FileStorage.deletePhoto(photoFilename)
            photoFilename = FileStorage.savePhoto(image)
        }
    }

    private func removePhoto() {
        FileStorage.deletePhoto(photoFilename)
        photoFilename = nil
        loadedPhoto = nil
        photoItem = nil
    }

    private func save() {
        let target: Gear
        if let gear {
            target = gear
        } else {
            target = Gear()
            context.insert(target)
        }
        target.name = name.trimmingCharacters(in: .whitespaces)
        target.type = type
        target.template = template
        target.brandColorHex = colorHex
        target.notes = notes
        target.customLabels = customLabels.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
        target.photoFilename = photoFilename

        // Keep existing settings' control values consistent with any template change.
        for setting in target.settings ?? [] {
            setting.syncControlValues(in: context)
        }
        Haptics.success()
        dismiss()
    }
}

#if DEBUG
#Preview {
    GearEditorView(gear: nil)
        .modelContainer(PreviewData.container)
}
#endif
