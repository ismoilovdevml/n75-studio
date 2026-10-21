// Theme.swift — design tokens from the N75 Studio design mockup (design/*.zip).
// The mockup is dark-only macOS chrome with a blue accent; values are replicated 1:1.
import SwiftUI

private func rgbHex(_ v: UInt32, _ a: Double = 1) -> Color {
    Color(.sRGB,
          red: Double((v >> 16) & 0xFF) / 255,
          green: Double((v >> 8) & 0xFF) / 255,
          blue: Double(v & 0xFF) / 255,
          opacity: a)
}

enum Theme {
    // Surfaces
    static let bg        = rgbHex(0x161618)
    static let chrome    = rgbHex(0x1B1B1E)
    static let card      = rgbHex(0x1F1F22)
    static let cardAlt   = rgbHex(0x18181B)
    static let well      = rgbHex(0x0E0E10)
    static let keyFill   = rgbHex(0x1C1C1F)
    static let keyOff    = rgbHex(0x1A1A1D)
    static let segTrack  = rgbHex(0x2A2A2E)
    static let segOn     = rgbHex(0x5A5A60)
    static let iconTile  = rgbHex(0x2C2C30)

    // Lines & fills
    static let border     = Color.white.opacity(0.07)
    static let hairline   = Color.white.opacity(0.06)
    static let fill       = Color.white.opacity(0.05)
    static let fillHover  = Color.white.opacity(0.09)
    static let fillButton = Color.white.opacity(0.08)
    static let trackOff   = Color.white.opacity(0.20)
    static let inset      = Color.white.opacity(0.15)

    // Text
    static let text     = rgbHex(0xF5F5F7)
    static let textSoft = rgbHex(0xE5E5EA)
    static let textMid  = rgbHex(0xC7C7CC)
    static let textDim  = rgbHex(0xA1A1A6)

    // Accents
    static let accent      = rgbHex(0x0A84FF)
    static let accentIcon  = rgbHex(0x4DA3FF)
    static let accentTint  = rgbHex(0x0A84FF, 0.16)
    static let primary     = rgbHex(0x0071E3)
    static let green       = rgbHex(0x30D158)
    static let greenText   = rgbHex(0x5BE37D)
    static let greenTint   = rgbHex(0x30D158, 0.14)
    static let amber       = rgbHex(0xFF9F0A)
    static let amberTint   = rgbHex(0xFF9F0A, 0.14)
}

/// Two densities ship in the design export: the full window (1280×1000) and the
/// compact window (780×600). Every size that differs between them lives here.
struct Density {
    var isCompact: Bool

    var mainPadding: CGFloat
    var mainGap: CGFloat
    var headerPaddingH: CGFloat
    var headerPaddingV: CGFloat

    var cardRadius: CGFloat
    var cardPadding: CGFloat
    var cardGap: CGFloat

    var labelSize: CGFloat
    var bodySize: CGFloat
    var dimSize: CGFloat

    var swatch: CGFloat
    var swatchRadius: CGFloat
    var hexSize: CGFloat
    var dot: CGFloat

    var fxMinHeight: CGFloat
    var fxRadius: CGFloat
    var fxGap: CGFloat
    var fxIcon: CGFloat
    var fxFont: CGFloat

    var segRadius: CGFloat
    var segHeight: CGFloat
    var segWidth: CGFloat
    var switchW: CGFloat
    var switchH: CGFloat

    var btnRadius: CGFloat
    var btnHeight: CGFloat
    var btnFont: CGFloat

    static let regular = Density(
        isCompact: false,
        mainPadding: 24, mainGap: 16, headerPaddingH: 24, headerPaddingV: 14,
        cardRadius: 16, cardPadding: 18, cardGap: 14,
        labelSize: 12, bodySize: 13, dimSize: 12,
        swatch: 56, swatchRadius: 14, hexSize: 20, dot: 30,
        fxMinHeight: 72, fxRadius: 12, fxGap: 8, fxIcon: 20, fxFont: 12,
        segRadius: 9, segHeight: 30, segWidth: 200, switchW: 40, switchH: 24,
        btnRadius: 10, btnHeight: 36, btnFont: 13
    )

    static let compact = Density(
        isCompact: true,
        mainPadding: 12, mainGap: 10, headerPaddingH: 14, headerPaddingV: 10,
        cardRadius: 14, cardPadding: 12, cardGap: 10,
        labelSize: 11, bodySize: 12, dimSize: 11,
        swatch: 40, swatchRadius: 10, hexSize: 15, dot: 24,
        fxMinHeight: 52, fxRadius: 10, fxGap: 6, fxIcon: 17, fxFont: 11,
        segRadius: 8, segHeight: 26, segWidth: 160, switchW: 34, switchH: 20,
        btnRadius: 8, btnHeight: 32, btnFont: 12
    )
}

// MARK: - Primitives

struct Card<Content: View>: View {
    let d: Density
    var padding: CGFloat? = nil
    var insets: EdgeInsets? = nil
    var background: Color? = nil
    var spacing: CGFloat? = nil
    var alignment: HorizontalAlignment = .leading
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: alignment, spacing: spacing ?? d.cardGap) { content }
            .padding(insets ?? EdgeInsets(top: padding ?? d.cardPadding,
                                          leading: padding ?? d.cardPadding,
                                          bottom: padding ?? d.cardPadding,
                                          trailing: padding ?? d.cardPadding))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(background ?? Theme.card)
            .clipShape(RoundedRectangle(cornerRadius: d.cardRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: d.cardRadius, style: .continuous)
                .strokeBorder(Theme.border, lineWidth: 1))
    }
}

struct SectionLabel: View {
    let text: String
    let d: Density
    var body: some View {
        Text(text)
            .font(.system(size: d.labelSize, weight: .semibold))
            .tracking(0.24)
            .foregroundStyle(Theme.textDim)
    }
}

/// The mockup's own switch (iOS-style), not the AppKit one — 40×24 / 34×20, green when on.
struct DesignSwitch: View {
    let isOn: Bool
    let d: Density
    var body: some View {
        let knob = d.switchH - 4
        Capsule()
            .fill(isOn ? Theme.green : Theme.trackOff)
            .frame(width: d.switchW, height: d.switchH)
            .overlay(alignment: isOn ? .trailing : .leading) {
                Circle()
                    .fill(Color.white)
                    .frame(width: knob, height: knob)
                    .shadow(color: .black.opacity(0.4), radius: 1.5, y: 1)
                    .padding(2)
            }
            .animation(.easeOut(duration: 0.15), value: isOn)
    }
}

/// Row that behaves like a switch: whole row is the hit target.
struct SwitchRow<Label: View>: View {
    @Binding var isOn: Bool
    let d: Density
    @ViewBuilder var label: Label

    var body: some View {
        Button { isOn.toggle() } label: {
            HStack(spacing: 12) {
                label
                Spacer(minLength: 8)
                DesignSwitch(isOn: isOn, d: d)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct SegmentedPair: View {
    let titles: [String]
    @Binding var selection: Int
    let d: Density

    var body: some View {
        HStack(spacing: 2) {
            ForEach(titles.indices, id: \.self) { i in
                let on = selection == i
                Button { selection = i } label: {
                    Text(titles[i])
                        .font(.system(size: d.isCompact ? 12 : 13, weight: .medium))
                        .foregroundStyle(on ? Color.white : Theme.textMid)
                        .frame(maxWidth: .infinity)
                        .frame(height: d.segHeight)
                        .background {
                            if on {
                                RoundedRectangle(cornerRadius: d.segRadius - 2, style: .continuous)
                                    .fill(Theme.segOn)
                                    .shadow(color: .black.opacity(0.4), radius: 1, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .frame(width: d.segWidth)
        .background(Theme.segTrack)
        .clipShape(RoundedRectangle(cornerRadius: d.segRadius, style: .continuous))
    }
}

struct PillButton: View {
    let title: String
    var systemImage: String? = nil
    var prominent: Bool = false
    var iconOnly: Bool = false
    let d: Density
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: d.isCompact ? 6 : 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: d.isCompact ? 11 : 12, weight: .bold))
                }
                if !iconOnly {
                    Text(title).font(.system(size: d.btnFont, weight: .semibold))
                }
            }
            .foregroundStyle(prominent ? Color.white : Theme.text)
            .padding(.horizontal, iconOnly ? 10 : (d.isCompact ? 14 : 16))
            .frame(height: d.btnHeight)
            .background(prominent ? Theme.primary : Theme.fillButton)
            .clipShape(RoundedRectangle(cornerRadius: d.btnRadius, style: .continuous))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(title)
    }
}

struct Hairline: View {
    var body: some View { Rectangle().fill(Theme.hairline).frame(height: 1) }
}
