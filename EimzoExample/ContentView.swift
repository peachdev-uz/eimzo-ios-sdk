import SwiftUI
import EimzoSDK

/// Demo screen mirroring the `eimzo_flutter` sample. Two buttons open
/// `EImzoView` — one with no sign request (Home), the other with one made in
/// the app from a document's values (`EImzoSignLink`). Two more show the Keys
/// API (`EImzoAPI`): the keys the user has added to the SDK, and the same
/// sign request signed with the one picked.
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

    /// What this screen reads from `EImzoAPI.getKeys`' JSON:
    /// `{"status":"ok","keys":[{"id":…,"pinfl":…,"name":…,"validFrom":…,"validTo":…}]}`.
    /// An error has no `keys`.
    private struct KeyList: Decodable {
        struct Key: Decodable, Identifiable {
            let id: String
            let name: String
            let validTo: String?
        }
        let keys: [Key]?
    }

    @State private var presentation: Presentation?
    /// Mirror of the SDK's `environment` — `.prod` is `m.e-imzo.uz`, `.dev`
    /// YT's test environment on `test.e-imzo.uz`. The SDK signs through that
    /// environment's YT gateway, which must have this app registered. A sign
    /// request or a scanned QR only works in the environment it was made
    /// for, so keep this aligned with whatever issued it.
    @State private var environment = EImzoEnvironment.dev

    /// The Keys API: the keys from the last `getKeys`, the one picked to sign
    /// with, and the JSON the last call returned, shown as it came.
    @State private var keys: [KeyList.Key] = []
    @State private var keyId: String?
    @State private var apiResult: String?

    /// The SDK's step-by-step log, in debug builds only — never ship it on.
    #if DEBUG
    private static let debugLogging = true
    #else
    private static let debugLogging = false
    #endif

    /// One configuration for `EImzoView` and the Keys API alike.
    private var config: EImzoConfig {
        EImzoConfig(environment: environment, debugLogging: Self.debugLogging)
    }

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

                // The Keys API works only for an integrator YT has given the
                // permission; without it every call returns `api_not_allowed`.
                Text("Kalitlar API")
                    .font(.subheadline.weight(.semibold))
                    .padding(.top, 8)

                Button {
                    Task { await listKeys() }
                } label: {
                    Label("Kalitlar ro'yxati", systemImage: "list.bullet")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)

                if !keys.isEmpty {
                    Picker("Kalit", selection: $keyId) {
                        ForEach(keys) { key in
                            Text(key.validTo.map { "\(key.name) · \($0)" } ?? key.name)
                                .tag(Optional(key.id))
                        }
                    }
                }

                Button {
                    Task { await signWithPickedKey() }
                } label: {
                    Label("Tanlangan kalit bilan imzolash", systemImage: "signature")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(keyId == nil)

                if let apiResult {
                    ScrollView {
                        Text(apiResult)
                            .font(.caption.monospaced())
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                }
            }
            .padding()
            .navigationTitle("E-IMZO iOS")
            .navigationBarTitleDisplayMode(.inline)
            // A key belongs to the environment it was added in: list again.
            .onChange(of: environment) { _ in
                keys = []
                keyId = nil
                apiResult = nil
            }
            .sheet(item: $presentation) { shown in
                EImzoView(
                    config: config,
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

    /// `EImzoAPI.getKeys`: shows the JSON and offers its keys to pick from,
    /// keeping the one picked while it is still there.
    private func listKeys() async {
        let json = await EImzoAPI.getKeys(config: config)
        apiResult = json
        keys = (try? JSONDecoder().decode(KeyList.self, from: Data(json.utf8)))?.keys ?? []
        if !keys.contains(where: { $0.id == keyId }) {
            keyId = keys.first?.id
        }
    }

    /// `EImzoAPI.sign`: the sign request the second button opens `EImzoView`
    /// with, signed with the picked key. The SDK shows its own sign sheet over
    /// this screen; the password or PIN is typed there, never here. The
    /// signed document goes from E-IMZO to the backend, not to the app.
    private func signWithPickedKey() async {
        guard let keyId, let link = sampleLink else { return }
        apiResult = await EImzoAPI.sign(keyId: keyId, deepLink: link, config: config)
    }
}

#Preview {
    ContentView()
}
