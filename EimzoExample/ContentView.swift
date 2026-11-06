import SwiftUI
import EimzoSDK

/// Two-button demo screen mirroring the `eimzo_flutter` sample. Both buttons
/// open `EImzoView` — one with no sign request (Home), the other with one
/// made in the app from a document's values (`EImzoSignLink`).
struct ContentView: View {

    /// What the sheet shows: the SDK, with or without a sign request.
    ///
    /// One item rather than a flag plus a separate link: with
    /// `sheet(isPresented:)` the content closure could read the link before
    /// its update landed, and the SDK opened with none.
    private struct Presentation: Identifiable {
        let id = UUID()
        let deepLink: String?
    }

    @State private var presentation: Presentation?
    /// Mirror of the SDK's `environment` — `.prod` is `m.e-imzo.uz`, `.dev`
    /// YT's test environment on `test.e-imzo.uz`. The SDK signs through that
    /// environment's YT gateway, which must have this app registered. A sign
    /// request or a scanned QR only works in the environment it was made
    /// for, so keep this aligned with whatever issued it.
    @State private var environment = EImzoEnvironment.dev

    /// The SDK's step-by-step log, in debug builds only — never ship it on.
    #if DEBUG
    private static let debugLogging = true
    #else
    private static let debugLogging = false
    #endif

    /// A sign request the way an integrator makes one: the site's id, the
    /// document's id and the hash come from the integrator's own backend —
    /// here, a document captured from E-IMZO during QA — and the SDK makes
    /// the link. Never an `eimzo://` link taken from outside.
    private var sampleLink: String? {
        try? EImzoSignLink.create(
            siteId: "1a47",
            documentId: "59282737",
            hash: "518b091cc3878831103872e422ec71d2e6ee501e255dce3290af02042edfcd69"
        )
    }

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

                Toggle(isOn: Binding(get: { environment == .dev },
                                     set: { environment = $0 ? .dev : .prod })) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Test muhiti (dev)")
                            .font(.subheadline.weight(.semibold))
                        Text(environment == .dev ? "test.e-imzo.uz" : "m.e-imzo.uz")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                Button {
                    presentation = Presentation(deepLink: nil)
                } label: {
                    Label("Open E-IMZO native UI", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    presentation = Presentation(deepLink: sampleLink)
                } label: {
                    Label("Open with a sign request", systemImage: "qrcode")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .padding()
            .navigationTitle("E-IMZO iOS")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(item: $presentation) { shown in
                EImzoView(
                    config: EImzoConfig(environment: environment, debugLogging: Self.debugLogging),
                    deepLink: shown.deepLink,
                    // E-IMZO has the signature: the SDK calls back from
                    // «Ilovaga qaytish» — tapped, or by itself after about
                    // 3 s — or, for a QR it scanned, from «Tayyor». It does
                    // not close itself, so the sheet is closed here.
                    onSignComplete: { _ in presentation = nil }
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
