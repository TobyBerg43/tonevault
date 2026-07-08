import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct AppSettingsView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var entitlements: EntitlementManager
    @AppStorage(PrefKey.knobDisplayStyle) private var styleRaw = KnobDisplayStyle.numeric.rawValue

    @State private var showingPaywall = false
    @State private var showingShareBackup = false
    @State private var backupURL: URL?
    @State private var showingImporter = false
    @State private var importResult: ImportOutcome?
    @State private var isWorking = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: Pro
                Section {
                    if entitlements.isPro {
                        Label("ToneVault Pro — unlocked", systemImage: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    } else {
                        Button { showingPaywall = true } label: {
                            Label("Upgrade to Pro — \(entitlements.displayPrice) once", systemImage: "sparkles")
                        }
                    }
                    Button("Restore Purchases") {
                        Task { await entitlements.restore() }
                    }
                }

                // MARK: Display
                Section("Knob display") {
                    Picker("Show knob values as", selection: $styleRaw) {
                        ForEach(KnobDisplayStyle.allCases) { Text($0.displayName).tag($0.rawValue) }
                    }
                }

                // MARK: Data ownership (always free)
                Section {
                    Button {
                        Task { await exportBackup() }
                    } label: {
                        Label("Back up everything", systemImage: "square.and.arrow.up")
                    }
                    .disabled(isWorking)

                    Button {
                        showingImporter = true
                    } label: {
                        Label("Restore from backup", systemImage: "square.and.arrow.down")
                    }
                    .disabled(isWorking)
                } header: {
                    Text("Your data")
                } footer: {
                    Text("Your tones are yours — export anytime to Files, iCloud Drive, or email-to-self. No account, no cloud. Backup & restore are always free.")
                }

                // MARK: About / legal
                Section("About") {
                    NavigationLink { PrivacyView() } label: {
                        Label("Privacy", systemImage: "hand.raised")
                    }
                    Link(destination: LegalLinks.eula) {
                        Label("Terms of Use (EULA)", systemImage: "doc.text")
                    }
                    NavigationLink { AboutView() } label: {
                        Label("About ToneVault", systemImage: "info.circle")
                    }
                }

                #if DEBUG
                Section("Developer (DEBUG only)") {
                    Toggle("Simulate Pro", isOn: Binding(
                        get: { entitlements.debugSimulatePro },
                        set: { entitlements.debugSimulatePro = $0 }
                    ))
                }
                #endif
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingPaywall) { PaywallView() }
            .sheet(isPresented: $showingShareBackup) {
                if let backupURL { ShareSheet(items: [backupURL]) }
            }
            .fileImporter(isPresented: $showingImporter,
                          allowedContentTypes: [UTType(filenameExtension: "tonevault") ?? .data, .json, .data]) { result in
                Task { await handleImport(result) }
            }
            .alert(item: $importResult) { outcome in
                Alert(title: Text(outcome.title), message: Text(outcome.message), dismissButton: .default(Text("OK")))
            }
            .overlay {
                if isWorking { ProgressView().padding().background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12)) }
            }
        }
    }

    private func exportBackup() async {
        isWorking = true
        defer { isWorking = false }
        do {
            let url = try BackupService.exportBackup(context: context)
            backupURL = url
            showingShareBackup = true
        } catch {
            importResult = ImportOutcome(title: "Backup failed", message: error.localizedDescription)
        }
    }

    private func handleImport(_ result: Result<URL, Error>) async {
        isWorking = true
        defer { isWorking = false }
        switch result {
        case .success(let url):
            do {
                let counts = try BackupService.importBackup(from: url, context: context)
                importResult = ImportOutcome(
                    title: "Restore complete",
                    message: "Imported \(counts.gear) gear, \(counts.settings) tones, \(counts.songs) songs, \(counts.setlists) setlists."
                )
                Haptics.success()
            } catch {
                importResult = ImportOutcome(title: "Restore failed", message: error.localizedDescription)
            }
        case .failure(let error):
            importResult = ImportOutcome(title: "Restore failed", message: error.localizedDescription)
        }
    }
}

struct ImportOutcome: Identifiable {
    let id = UUID()
    let title: String
    let message: String
}
