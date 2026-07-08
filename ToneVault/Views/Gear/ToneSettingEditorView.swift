import SwiftUI
import SwiftData
import PhotosUI

/// Create or edit a saved tone: name it, drag the controls to match, attach photo/audio.
struct ToneSettingEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var entitlements: EntitlementManager
    @AppStorage(PrefKey.knobDisplayStyle) private var styleRaw = KnobDisplayStyle.numeric.rawValue

    /// The gear this tone belongs to. Required — a tone always has gear.
    let gear: Gear
    /// nil = new tone.
    let setting: ToneSetting?

    @State private var workingSetting: ToneSetting?
    @State private var name: String = ""
    @State private var notes: String = ""
    @State private var isFavorite = false
    @State private var photoItem: PhotosPickerItem?
    @State private var loadedPhoto: UIImage?
    @State private var showingPaywall = false
    @State private var showingRecorder = false

    private var style: KnobDisplayStyle { KnobDisplayStyle(rawValue: styleRaw) ?? .numeric }
    private var isEditing: Bool { setting != nil }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    nameField

                    if let ws = workingSetting {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Set the controls")
                                .font(.headline)
                            Text("Drag each knob or fader to match your hardware. Tap toggles and rotary switches.")
                                .font(.caption).foregroundStyle(.secondary)
                            ControlBoardView(
                                controlValues: ws.controlValues ?? [],
                                specs: gear.controls,
                                displayStyle: style,
                                isEditable: true
                            )
                            .padding(.vertical, 8)
                        }
                    }

                    attachmentsSection
                    notesField
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Tone" : "New Tone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { cancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear(perform: setUp)
            .onChange(of: photoItem) { _, item in Task { await loadPickedPhoto(item) } }
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingRecorder) {
                AudioRecorderView { filename in
                    workingSetting?.audioFilename = filename
                }
            }
        }
    }

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Tone name").font(.headline)
            TextField("e.g. Verse tone, Solo boost", text: $name)
                .textFieldStyle(.roundedBorder)
            Toggle("Mark as favorite", isOn: $isFavorite)
        }
    }

    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Attachments").font(.headline)

            if let loadedPhoto {
                Image(uiImage: loadedPhoto)
                    .resizable().scaledToFit()
                    .frame(maxHeight: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            HStack {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label(loadedPhoto == nil ? "Photo" : "Replace photo", systemImage: "photo")
                }
                if loadedPhoto != nil {
                    Button(role: .destructive) { removePhoto() } label: {
                        Image(systemName: "trash")
                    }
                }
            }

            // Audio is a Pro feature.
            if entitlements.canAttachAudio {
                HStack {
                    Button {
                        showingRecorder = true
                    } label: {
                        Label(workingSetting?.audioFilename == nil ? "Record audio clip" : "Re-record clip",
                              systemImage: "mic")
                    }
                    if workingSetting?.audioFilename != nil {
                        Button(role: .destructive) { removeAudio() } label: { Image(systemName: "trash") }
                    }
                }
            } else {
                Button { showingPaywall = true } label: {
                    ProLockLabel(text: "Audio clip attachments")
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var notesField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Notes").font(.headline)
            TextField("Optional notes", text: $notes, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...5)
        }
    }

    // MARK: - Lifecycle

    private func setUp() {
        if let setting {
            workingSetting = setting
            name = setting.name
            notes = setting.notes
            isFavorite = setting.isFavorite
            loadedPhoto = FileStorage.loadPhoto(setting.photoFilename)
            setting.syncControlValues(in: context)
        } else {
            // Create a draft setting up-front so knob drags bind to real ControlValues.
            let draft = ToneSetting(name: "", gear: gear)
            context.insert(draft)
            draft.syncControlValues(in: context)
            workingSetting = draft
        }
    }

    private func loadPickedPhoto(_ item: PhotosPickerItem?) async {
        guard let item,
              let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            FileStorage.deletePhoto(workingSetting?.photoFilename)
            let filename = FileStorage.savePhoto(image)
            workingSetting?.photoFilename = filename
            loadedPhoto = image
        }
    }

    private func removePhoto() {
        FileStorage.deletePhoto(workingSetting?.photoFilename)
        workingSetting?.photoFilename = nil
        loadedPhoto = nil
        photoItem = nil
    }

    private func removeAudio() {
        FileStorage.deleteAudio(workingSetting?.audioFilename)
        workingSetting?.audioFilename = nil
    }

    private func save() {
        guard let ws = workingSetting else { return }
        ws.name = name.trimmingCharacters(in: .whitespaces)
        ws.notes = notes
        ws.isFavorite = isFavorite
        ws.dateModified = Date()
        Haptics.success()
        dismiss()
    }

    private func cancel() {
        // If we created a brand-new draft and the user cancels, discard it.
        if setting == nil, let ws = workingSetting {
            FileStorage.deletePhoto(ws.photoFilename)
            FileStorage.deleteAudio(ws.audioFilename)
            context.delete(ws)
        }
        dismiss()
    }
}
