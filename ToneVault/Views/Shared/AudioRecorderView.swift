import SwiftUI
import AVFoundation

/// Records a short local audio clip (m4a). Fully functional if mic permission is
/// granted; degrades gracefully with a clear message if denied.
struct AudioRecorderView: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: (String) -> Void

    @StateObject private var recorder = AudioRecorderController()

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                Image(systemName: recorder.isRecording ? "waveform.circle.fill" : "mic.circle")
                    .font(.system(size: 88))
                    .foregroundStyle(recorder.isRecording ? Color.red : Color.tvAccent)
                    .symbolEffect(.pulse, isActive: recorder.isRecording)

                Text(recorder.statusText)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(recorder.permissionDenied ? .red : .primary)

                if recorder.permissionDenied {
                    Text("Enable microphone access in Settings to record clips. Everything else in ToneVault works without it.")
                        .font(.caption).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Spacer()

                if !recorder.permissionDenied {
                    Button {
                        if recorder.isRecording {
                            if let filename = recorder.stop() {
                                onSaved(filename)
                                Haptics.success()
                                dismiss()
                            }
                        } else {
                            recorder.start()
                        }
                    } label: {
                        Text(recorder.isRecording ? "Stop & save" : "Start recording")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(recorder.isRecording ? .red : .tvAccent)
                    .padding(.horizontal)
                }
            }
            .padding()
            .navigationTitle("Record Clip")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { recorder.cancel(); dismiss() }
                }
            }
            .onAppear { recorder.requestPermission() }
        }
    }
}

@MainActor
final class AudioRecorderController: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var permissionDenied = false
    @Published var statusText = "Tap to record a short clip of your tone."

    private var recorder: AVAudioRecorder?
    private var currentFilename: String?

    func requestPermission() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                self?.permissionDenied = !granted
                if !granted { self?.statusText = "Microphone access is off." }
            }
        }
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)
            let (filename, url) = FileStorage.newAudioURL()
            currentFilename = filename
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.record()
            isRecording = true
            statusText = "Recording…"
            Haptics.impact(.medium)
        } catch {
            statusText = "Couldn’t start recording."
        }
    }

    /// Stops and returns the saved filename.
    func stop() -> String? {
        recorder?.stop()
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false)
        statusText = "Saved."
        return currentFilename
    }

    func cancel() {
        recorder?.stop()
        isRecording = false
        FileStorage.deleteAudio(currentFilename)
        currentFilename = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

@MainActor
final class AudioPlayerController: NSObject, ObservableObject, AVAudioPlayerDelegate {
    @Published var isPlaying = false
    private var player: AVAudioPlayer?

    func toggle(url: URL) {
        if isPlaying { stop() } else { play(url: url) }
    }

    func play(url: URL) {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
            isPlaying = true
        } catch {
            isPlaying = false
        }
    }

    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false }
    }
}
