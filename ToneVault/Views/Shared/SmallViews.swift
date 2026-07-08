import SwiftUI

struct EmptyStateView<Actions: View>: View {
    let systemImage: String
    let title: String
    let message: String
    @ViewBuilder var actions: () -> Actions

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text(title).font(.title3.bold())
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            actions()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Shown to free users; reports how close they are to the free limits and links to the paywall.
struct FreeTierBanner: View {
    let gearCount: Int
    let settingCount: Int
    var onUpgrade: () -> Void

    var body: some View {
        Button(action: onUpgrade) {
            VStack(alignment: .leading, spacing: 6) {
                Label("ToneVault Pro", systemImage: "sparkles")
                    .font(.subheadline.bold())
                    .foregroundStyle(.tint)
                Text("Free plan: \(gearCount)/\(EntitlementManager.freeGearLimit) gear · \(settingCount)/\(EntitlementManager.freeSettingLimit) tones. Unlock unlimited for a one-time $5.99. Backup & export are always free.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .buttonStyle(.plain)
    }
}

/// Reusable "this is a Pro feature" inline lock row.
struct ProLockLabel: View {
    let text: String
    var body: some View {
        HStack {
            Image(systemName: "lock.fill").foregroundStyle(.secondary)
            Text(text)
            Spacer()
            Text("Pro").font(.caption.bold())
                .padding(.horizontal, 8).padding(.vertical, 2)
                .background(Color.tvAccent.opacity(0.15), in: Capsule())
                .foregroundStyle(Color.tvAccent)
        }
    }
}
