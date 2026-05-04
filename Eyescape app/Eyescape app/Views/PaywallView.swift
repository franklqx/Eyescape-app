import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    // Propagate success back to SettingsView to auto-dismiss paywall
    var onSuccess: (() -> Void)?

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.textSecondary)
                            .frame(width: 44, height: 44)
                            .background(Color.appSurface)
                            .clipShape(Circle())
                    }
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                ScrollView {
                    VStack(spacing: 0) {
                        Spacer().frame(height: 12)
                        heroSection
                        Spacer().frame(height: 36)
                        featuresSection
                        Spacer().frame(height: 36)
                        purchaseSection
                        Spacer().frame(height: 16)
                        legalSection
                        Spacer().frame(height: 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .onChange(of: storeManager.purchaseState) { _, state in
            if case .success = state {
                onSuccess?()
                dismiss()
            }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            // Icon — amber focal point logo
            AmberGlowLogo(size: 80)

            Text("Eyescape Pro")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(Color.textPrimary)

            Text("Everything your eyes deserve.")
                .font(.system(size: 15))
                .foregroundColor(Color.textSecondary)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Features

    private var featuresSection: some View {
        VStack(spacing: 10) {
            FeatureRow(
                icon: "timer",
                title: "Custom interval",
                subtitle: "Set reminders from 5 to 60 minutes — your pace."
            )
            FeatureRow(
                icon: "dial.medium.fill",
                title: "Dynamic Island alert size",
                subtitle: "Choose S / M / L to match how you hold your phone."
            )
            FeatureRow(
                icon: "iphone.radiowaves.left.and.right",
                title: "Haptic alerts",
                subtitle: "Feel the reminder even when your phone is silent."
            )
            FeatureRow(
                icon: "lock.open.fill",
                title: "All future Pro features",
                subtitle: "One purchase, every update."
            )
        }
    }

    // MARK: - Purchase

    private var purchaseSection: some View {
        VStack(spacing: 14) {
            // Price display
            if storeManager.isLoadingProducts {
                ProgressView()
                    .tint(Color.accentAmber)
                    .frame(height: 22)
            } else if let product = storeManager.product {
                VStack(spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textPrimary)
                    Text("one-time purchase · no subscription")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
            } else {
                // Product failed to load — show retry
                VStack(spacing: 6) {
                    Text("Couldn't load price")
                        .font(.system(size: 13))
                        .foregroundColor(Color.textSecondary)
                    Button {
                        Task { await storeManager.loadProducts() }
                    } label: {
                        Text("Retry")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color.accentAmber)
                    }
                }
                .frame(height: 22)
            }

            // Error message
            if case .failed(let message) = storeManager.purchaseState {
                Text(message)
                    .font(.system(size: 12))
                    .foregroundColor(Color.appError)
                    .multilineTextAlignment(.center)
            }

            // Buy button
            Button {
                Task { await storeManager.purchase() }
            } label: {
                ZStack {
                    if case .loading = storeManager.purchaseState {
                        ProgressView()
                            .tint(Color.appBackground)
                    } else {
                        Text(storeManager.product == nil ? "Loading…" : "Get Eyescape Pro")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.appBackground)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(
                    storeManager.product == nil
                        ? Color.accentAmber.opacity(0.4)
                        : Color.accentAmber
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(storeManager.product == nil || storeManager.purchaseState == .loading)

            // Restore
            Button {
                Task { await storeManager.restorePurchases() }
            } label: {
                Text("Restore purchases")
                    .font(.system(size: 13))
                    .foregroundColor(Color.textSecondary)
                    .underline()
            }
            .disabled(storeManager.purchaseState == .loading)
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        Text("Payment is charged to your Apple ID account at confirmation. This is a one-time purchase with no recurring charges.")
            .font(.system(size: 10))
            .foregroundColor(Color.textSecondary.opacity(0.6))
            .multilineTextAlignment(.center)
    }
}

// MARK: - Feature Row

private struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accentAmber.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(Color.accentAmber)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(Color.appSurface)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.07), lineWidth: 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Amber Glow Logo

/// The Eyescape logo: a soft amber focal point — the distant spot you look at during a break.
/// Reusable at any size. Background is transparent so it sits on any surface.
struct AmberGlowLogo: View {
    var size: CGFloat = 80

    var body: some View {
        ZStack {
            // Dark amber-tinted background
            RoundedRectangle(cornerRadius: size * 0.25)
                .fill(Color.accentAmber.opacity(0.12))

            // Focal dot — solid amber, 35% of container, with double glow
            Circle()
                .fill(Color.accentAmber)
                .frame(width: size * 0.35, height: size * 0.35)
                .shadow(color: Color.accentAmber, radius: size * 0.08)
                .shadow(color: Color.accentAmber.opacity(0.4), radius: size * 0.22)
        }
        .frame(width: size, height: size)
    }
}

#Preview {
    PaywallView()
        .environment(StoreManager())
}
