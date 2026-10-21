// ContentView.swift — N75 Studio main window, built to the design export in design/.
// Two layouts ship in that export; the window picks one from its own size.
import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var hid = HIDController()

    @State private var rgb = RGBColor(r: 52, g: 181, b: 89)
    @State private var effect: LightingEffect = .normal
    @State private var brightness: Double = 3
    @State private var speed: Double = 3
    @State private var direction = 0
    @State private var rainbow = false
    @State private var live = true
    @State private var debounce: DispatchWorkItem?

    var body: some View {
        GeometryReader { geo in
            let d: Density = (geo.size.width < 980 || geo.size.height < 780) ? .compact : .regular
            VStack(spacing: 0) {
                header(d)
                if !hid.hasInputMonitoring { permissionBanner(d) }
                Group {
                    if d.isCompact { compactMain(d) } else { regularMain(d) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                footer(d)
            }
            .ignoresSafeArea(.container, edges: .top)
        }
        .background(Theme.bg)
        .background(WindowConfigurator())
        .foregroundStyle(Theme.text)
        .preferredColorScheme(.dark)
        .onChange(of: rgb) { applyIfLive() }
        .onChange(of: effect) { applyIfLive() }
        .onChange(of: brightness) { applyIfLive() }
        .onChange(of: speed) { applyIfLive() }
        .onChange(of: direction) { applyIfLive() }
        .onChange(of: rainbow) { applyIfLive() }
    }

    // MARK: - Chrome

    private func header(_ d: Density) -> some View {
        HStack(spacing: d.isCompact ? 10 : 12) {
            if d.isCompact {
                Text("N75 Studio")
                    .font(.system(size: 13, weight: .semibold))
                + Text("  ·  VGN N75 RGB")
                    .font(.system(size: 13))
                    .foregroundColor(Theme.textDim)
                Spacer()
                HStack(spacing: 5) {
                    Circle().fill(hid.isConnected ? Theme.green : Theme.amber)
                        .frame(width: 6, height: 6)
                    Text(hid.isConnected ? "Connected" : "Not found")
                        .font(.system(size: 11))
                        .foregroundStyle(hid.isConnected ? Theme.greenText : Theme.amber)
                }
            } else {
                appIcon
                VStack(alignment: .leading, spacing: 1) {
                    Text("N75 Studio").font(.system(size: 14, weight: .semibold))
                    Text("VGN N75 RGB · Evision 320F:5055")
                        .font(.system(size: 12)).foregroundStyle(Theme.textDim)
                }
                Spacer(minLength: 12)
                statusPill
            }
        }
        // Clear the real traffic lights (the window runs with a hidden title bar).
        .padding(.leading, d.isCompact ? 76 : 82)
        .padding(.trailing, d.headerPaddingH)
        .padding(.vertical, d.headerPaddingV)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.chrome)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.border).frame(height: 1) }
    }

    private var appIcon: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Theme.iconTile)
            .frame(width: 34, height: 34)
            .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1))
            .overlay(Image(systemName: "keyboard")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Theme.text))
    }

    private var statusPill: some View {
        HStack(spacing: 6) {
            Circle().fill(hid.isConnected ? Theme.green : Theme.amber).frame(width: 7, height: 7)
            Text(hid.isConnected ? "Connected" : "Not found")
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(hid.isConnected ? Theme.greenText : Theme.amber)
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(hid.isConnected ? Theme.greenTint : Theme.amberTint)
        .clipShape(Capsule())
    }

    private func permissionBanner(_ d: Density) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.shield.fill").foregroundStyle(Theme.amber)
            VStack(alignment: .leading, spacing: 1) {
                Text("Input Monitoring needed").font(.system(size: 12, weight: .semibold))
                Text("macOS blocks keyboard access until you allow N75 Studio, then relaunch.")
                    .font(.system(size: 11)).foregroundStyle(Theme.textDim)
            }
            Spacer(minLength: 8)
            PillButton(title: "Open Settings", prominent: true, d: d) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                    NSWorkspace.shared.open(url)
                }
            }
        }
        .padding(.horizontal, d.headerPaddingH).padding(.vertical, 10)
        .background(Theme.amberTint)
        .overlay(alignment: .bottom) { Rectangle().fill(Theme.border).frame(height: 1) }
    }

    private func footer(_ d: Density) -> some View {
        HStack(spacing: d.isCompact ? 10 : 12) {
            Button { live.toggle() } label: {
                HStack(spacing: d.isCompact ? 8 : 10) {
                    DesignSwitch(isOn: live, d: d)
                    Text("Live").font(.system(size: d.btnFont, weight: .semibold))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Text(statusText)
                .font(.system(size: d.dimSize))
                .foregroundStyle(Theme.textDim)
                .lineLimit(1).truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            PillButton(title: "Turn Off", systemImage: "power",
                       iconOnly: d.isCompact, d: d) {
                effect = .off
                apply()
            }
            PillButton(title: "Apply", prominent: true, d: d) { apply() }
                .disabled(!hid.isConnected)
                .opacity(hid.isConnected ? 1 : 0.5)
        }
        .padding(.horizontal, d.isCompact ? 12 : 24)
        .padding(.vertical, d.isCompact ? 8 : 12)
        .background {
            if d.isCompact {
                Theme.chrome
            } else {
                Theme.chrome.opacity(0.92).background(.ultraThinMaterial)
            }
        }
        .overlay(alignment: .top) { Rectangle().fill(Theme.border).frame(height: 1) }
    }

    private var statusText: String {
        if !hid.isConnected { return hid.lastStatus }
        let problem = hid.lastStatus.hasPrefix("Blocked") || hid.lastStatus.hasPrefix("Partial")
            || hid.lastStatus.hasPrefix("No device")
        if problem { return hid.lastStatus }
        if live { return "Live — changes apply instantly" }
        return hid.lastStatus.hasPrefix("Applied")
            ? "Last applied: " + hid.lastStatus.dropFirst("Applied ".count)
            : hid.lastStatus
    }

    // MARK: - Layouts

    private func regularMain(_ d: Density) -> some View {
        ScrollView {
            VStack(spacing: d.mainGap) {
                PreviewCard(color: rgb, effect: effect, brightness: Int(brightness),
                            rainbow: rainbow, d: d)
                HStack(alignment: .top, spacing: d.mainGap) {
                    ColorPanel(rgb: $rgb, d: d, effectName: effect.title)
                        .frame(width: 320)
                    VStack(spacing: d.mainGap) {
                        EffectPanel(effect: $effect, d: d) { EmptyView() }
                        ParamsPanel(brightness: $brightness, speed: $speed, direction: $direction,
                                    rainbow: $rainbow, effect: effect, d: d)
                    }
                }
            }
            .padding(d.mainPadding)
            .frame(maxWidth: 1240)
            .frame(maxWidth: .infinity)
        }
    }

    private func compactMain(_ d: Density) -> some View {
        VStack(spacing: d.mainGap) {
            HStack(alignment: .top, spacing: d.mainGap) {
                ColorPanel(rgb: $rgb, d: d, effectName: effectCaption)
                    .frame(width: 240)
                    .frame(maxHeight: .infinity, alignment: .top)
                EffectPanel(effect: $effect, d: d) {
                    KeyboardPreview(style: .mini, color: rgb, effect: effect,
                                    brightness: Int(brightness), rainbow: rainbow)
                        .frame(width: 134)
                        .padding(.horizontal, 8).padding(.vertical, 6)
                        .background(Theme.well)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }
            .fixedSize(horizontal: false, vertical: true)
            ParamsPanel(brightness: $brightness, speed: $speed, direction: $direction,
                        rainbow: $rainbow, effect: effect, d: d)
            Spacer(minLength: 0)
        }
        .padding(d.mainPadding)
    }

    private var effectCaption: String {
        (rainbow && effect != .off) ? "\(effect.title) · Rainbow" : effect.title
    }

    // MARK: - Actions

    private func applyIfLive() {
        guard live else { return }
        debounce?.cancel()
        let work = DispatchWorkItem { apply() }
        debounce = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12, execute: work)
    }

    private func apply() {
        hid.apply(effect: effect, color: rgb, brightness: Int(brightness),
                  speed: Int(speed), direction: direction, multicolor: rainbow)
    }
}

/// The window runs with a hidden title bar and the header drawn under the traffic
/// lights (as the design has it), so dragging has to come from the background.
private struct WindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            guard let window = view.window else { return }
            window.isMovableByWindowBackground = true
            window.titlebarAppearsTransparent = true
            window.backgroundColor = NSColor(Theme.bg)
        }
        return view
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}

#Preview { ContentView().frame(width: 1180, height: 940) }
