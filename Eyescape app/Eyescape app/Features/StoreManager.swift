import Foundation
import StoreKit
import SwiftData
import Observation

// MARK: - Product IDs

enum EyescapeProduct {
    /// One-time lifetime purchase.
    static let proLifetime = "com.FL.fire.Eyescape-app.pro"
}

// MARK: - Purchase State

enum PurchaseState: Equatable {
    case idle
    case loading
    case success
    case failed(String)
}

// MARK: - StoreManager

/// Handles StoreKit 2 product loading, purchasing, restoration and entitlement checks.
///
/// Usage:
///   1. Inject via `.environment(storeManager)` in App.
///   2. Call `configure(modelContext:)` once (same pattern as SessionManager).
///   3. Observe `purchaseState` in PaywallView.
///   4. After a verified purchase, `isPro` in UserSettings is updated automatically.

@Observable
final class StoreManager {
    private(set) var product: Product?
    private(set) var purchaseState: PurchaseState = .idle
    private(set) var isLoadingProducts = false

    private var modelContext: ModelContext?
    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = Task { [weak self] in
            await self?.observeTransactionUpdates()
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    // MARK: - Configure

    func configure(modelContext: ModelContext) {
        guard self.modelContext == nil else { return }
        self.modelContext = modelContext
        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            let products = try await Product.products(for: [EyescapeProduct.proLifetime])
            product = products.first
        } catch {
            // Product load failure is non-fatal — user can retry by reopening paywall
        }
    }

    // MARK: - Purchase

    func purchase() async {
        guard let product else {
            purchaseState = .failed("Product unavailable. Check your connection and try again.")
            return
        }

        purchaseState = .loading
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                updateEntitlement(isPro: true)
                await transaction.finish()
                purchaseState = .success
            case .userCancelled:
                purchaseState = .idle
            case .pending:
                // Ask to buy / parental approval
                purchaseState = .idle
            @unknown default:
                purchaseState = .idle
            }
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Restore

    func restorePurchases() async {
        purchaseState = .loading
        do {
            try await AppStore.sync()
            let restored = await refreshEntitlement()
            purchaseState = restored ? .success : .failed("No previous purchases found.")
        } catch {
            purchaseState = .failed(error.localizedDescription)
        }
    }

    // MARK: - Entitlement Check

    /// Returns true if user has a valid Pro entitlement.
    @discardableResult
    func refreshEntitlement() async -> Bool {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let tx) = result,
               tx.productID == EyescapeProduct.proLifetime,
               tx.revocationDate == nil {
                hasPro = true
                break
            }
        }
        updateEntitlement(isPro: hasPro)
        return hasPro
    }

    // MARK: - Transaction Updates (background listener)

    private func observeTransactionUpdates() async {
        for await result in Transaction.updates {
            if case .verified(let tx) = result {
                if tx.productID == EyescapeProduct.proLifetime {
                    let active = tx.revocationDate == nil
                    updateEntitlement(isPro: active)
                }
                await tx.finish()
            }
        }
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value): return value
        case .unverified: throw StoreError.failedVerification
        }
    }

    private func updateEntitlement(isPro: Bool) {
        guard let context = modelContext else { return }
        let settings = UserSettings.fetchOrCreate(context: context)
        settings.isPro = isPro
        try? context.save()
    }
}

// MARK: - StoreError

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return "Purchase verification failed. Please contact support."
        }
    }
}
