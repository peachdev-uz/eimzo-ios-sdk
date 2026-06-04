import SwiftUI
import EimzoSDK

/// Two-button demo screen mirroring the `eimzo_flutter` sample. Both buttons
/// open `EImzoView` — one with no deeplink (Home), the other with a sample
/// `eimzo://sign?qc=…` URL pre-populated.
struct ContentView: View {
    @Binding var incomingDeepLink: String?
    @State private var showEimzo = false
    @State private var presentedLink: String?
    /// Mirror of the SDK's `isTestMode` — flips the API endpoint between
    /// `m.e-imzo.uz` (prod) and `m.test.e-imzo.uz` (QA). Scanned/incoming
    /// QRs only work against the same environment they were generated for,
    /// so keep this aligned with whatever issued the QR.
    @State private var isTestMode = false

    /// Sample deeplink captured from the Android E-IMZO server during QA.
    private let sampleLink =
        "eimzo://sign?qc=1a4759282737518b091cc3878831103872e422ec71d2e6ee501e255dce3290af02042edfcd6989e4017b"

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Spacer()
                Image(systemName: "signature")
                    .font(.system(size: 56))
                    .foregroundStyle(.indigo)
                Text("E-IMZO Demo")
                    .font(.title2.bold())
                Text("iOS native SDK")
                    .foregroundStyle(.secondary)

                Toggle(isOn: $isTestMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Test rejimi")
                            .font(.subheadline.weight(.semibold))
                        Text(isTestMode
                             ? "m.test.e-imzo.uz"
                             : "m.e-imzo.uz")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                Button {
                    presentedLink = nil
                    showEimzo = true
                } label: {
                    Label("Open E-IMZO native UI", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    presentedLink = sampleLink
                    showEimzo = true
                } label: {
                    Label("Open with deep link (sign flow)", systemImage: "qrcode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("E-IMZO iOS")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showEimzo) {
                EImzoView(
                    config: EImzoConfig(isTestMode: isTestMode),
                    deepLink: presentedLink,
                    // Auto-close the sheet after a successful sign — the
                    // SDK shows IMZOLANDI for ~1.5 s and then calls back.
                    onSignComplete: { _ in showEimzo = false }
                )
            }
            .onChange(of: incomingDeepLink) { newValue in
                // External deeplink arrived — surface the sheet automatically.
                guard let link = newValue else { return }
                presentedLink = link
                showEimzo = true
                incomingDeepLink = nil
            }
        }
    }
}

#Preview {
    ContentView(incomingDeepLink: .constant(nil))
}
