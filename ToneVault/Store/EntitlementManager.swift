import Foundation
import StoreKit
import SwiftUI

/// Central source of truth for the one-time "ToneVault Pro" unlock.
///
/// Uses StoreKit 2 `Transaction.currentEntitlements` plus a `Transaction.updates`
/// listener. No receipts servers, no account — fully local verification.
@MainActor
final class EntitlementManager: ObservableObject {

    static let productID = "com.yourorg.tonevault.pro"

    /// Free-tier limits (backup/export is always free — never gated).
    static let freeGearLimit = 5
    static let freeSettingLimit = 10

    @Published private(set) var isPro: Bool = false
    @Published private(set) var product: Product?
    @Published private(set) var isLoadingProducts = false
    @Published var purchaseError: String?

    #if DEBUG
    /// DEBUG-only override so you can exercise Pro paths in the simulator without buying.
    /// Compiled out of Release builds entirely.
    @Published var debugSimulatePro = false {
        didSet { recomputeEntitlement() }
    }
    #endif

    private var updatesTask: Task<Void, Never>?
    private var storeKitEntitled = false

    init() {
        updatesTask = listenForTransactions()
        Task {
            await refreshEntitlements()
            await loadProducts()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Effective entitlement

    private func recomputeEntitlement() {
        #if DEBUG
        isPro = storeKitEntitled || debugSimulatePro
        #else
        isPro = storeKitEntitled
        #endif
    }

    // MARK: - Products

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let products = try await Product.products(for: [Self.productID])
            self.product = products.first
        } catch {
            self.purchaseError = "Couldn’t load the store. Check your connection and try again."
        }
    }

    // MARK: - Purchase

    func purchase() async {
        purchaseError = nil
        guard let product else {
            await loadProducts()
            guard product != nil else {
                purchaseError = "The upgrade isn’t available right now. Please try again."
                return
            }
            return
        }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await refreshEntitlements()
            case .userCancelled:
                break
            case .pending:
                purchaseError = "Your purchase is pending approval."
            @unknown default:
                break
            }
        } catch StoreKitError.userCancelled {
            // no-op
        } catch {
            purchaseError = "Purchase failed. You were not charged. \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    func restore() async {
        purchaseError = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !storeKitEntitled {
                purchaseError = "No previous ToneVault Pro purchase was found for this Apple ID."
            }
        } catch {
            purchaseError = "Couldn’t restore purchases. \(error.localizedDescription)"
        }
    }

    // MARK: - Entitlement refresh

    func refreshEntitlements() async {
        var entitled = false
        for await result in Transaction.currentEntitlements {
            if let transaction = try? checkVerified(result),
               transaction.productID == Self.productID,
               transaction.revocationDate == nil {
                entitled = true
            }
        }
        storeKitEntitled = entitled
        recomputeEntitlement()
    }

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { continue }
                if let transaction = try? await self.checkVerified(result) {
                    await transaction.finish()
                    await self.refreshEntitlements()
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Gating helpers

    func canAddGear(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeGearLimit
    }

    func canAddSetting(currentCount: Int) -> Bool {
        isPro || currentCount < Self.freeSettingLimit
    }

    /// Audio attachments and PDF export are Pro features.
    var canAttachAudio: Bool { isPro }
    var canExportPDF: Bool { isPro }

    var displayPrice: String {
        product?.displayPrice ?? "$5.99"
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "This purchase could not be verified by the App Store."
        }
    }
}
