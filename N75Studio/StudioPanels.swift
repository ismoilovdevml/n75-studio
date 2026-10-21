// StudioPanels.swift — the three control panels from the design mockup:
// Color, Effect and the parameter stack. Each renders at both densities.
import SwiftUI
import AppKit

// MARK: - Color

struct ColorPanel: View {
    @Binding var rgb: RGBColor
    let d: Density
    let effectName: String

    /// The mockup's 10 presets, in order.
    static let presets: [RGBColor] = [
        .init(r: 217, g: 119, b: 87), .init(r: 255, g: 69, b: 90),
        .init(r: 255, g: 159, b: 10), .init(r: 255, g: 214, b: 10),
        .init(r: 52, g: 181, b: 89), .init(r: 100, g: 210, b: 255),
        .init(r: 10, g: 132, b: 255), .init(r: 191, g: 90, b: 242),
        .init(r: 255, g: 255, b: 255), .init(r: 142, g: 142, b: 147),
    ]

    private var swiftColor: Color {
        Color(.sRGB, red: Double(rgb.r) / 255, green: Double(rgb.g) / 255, blue: Double(rgb.b) / 255)
    }

    private var pickerBinding: Binding<Color> {
        Binding(get: { swiftColor }, set: { new in
            let ns = NSColor(new).usingColorSpace(.sRGB) ?? .white
            rgb = RGBColor(r: Int(round(ns.redComponent * 255)),
                           g: Int(round(ns.greenComponent * 255)),
                           b: Int(round(ns.blueComponent * 255)))
        })
    }

    var body: some View {
        Card(d: d) {
            if d.isCompact {
                HStack(spacing: 10) {
                    swatch
                    VStack(alignment: .leading, spacing: 1) {
                        Text(rgb.hex)
                            .font(.system(size: d.hexSize, weight: .semibold, design: .monospaced))
                        Text(effectName)
                            .font(.system(size: d.dimSize)).foregroundStyle(Theme.textDim)
                    }
                    Spacer(minLength: 4)
                    picker
                }
            } else {
                HStack {
                    SectionLabel(text: "Color", d: d)
                    Spacer()
                    picker
                }
                HStack(spacing: 14) {
                    swatch
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rgb.hex)
                            .font(.system(size: d.hexSize, weight: .semibold, design: .monospaced))
                            .tracking(-0.2)
                        Text("RGB \(rgb.r), \(rgb.g), \(rgb.b)")
                            .font(.system(size: d.dimSize)).foregroundStyle(Theme.textDim)
                    }
                    Spacer(minLength: 0)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: d.isCompact ? 6 : 10),
                                     count: 5),
                      spacing: d.isCompact ? 6 : 10) {
                ForEach(Self.presets.indices, id: \.self) { i in presetDot(Self.presets[i]) }
            }

            VStack(spacing: d.isCompact ? 6 : 10) {
                if !d.isCompact { Hairline() }
                channel("R", \.r)
                channel("G", \.g)
                channel("B", \.b)
            }
        }
    }

    private var swatch: some View {
        RoundedRectangle(cornerRadius: d.swatchRadius, style: .continuous)
            .fill(swiftColor)
            .frame(width: d.swatch, height: d.swatch)
            .overlay(RoundedRectangle(cornerRadius: d.swatchRadius, style: .continuous)
                .strokeBorder(Theme.inset, lineWidth: 1))
    }

    private var picker: some View {
        ColorPicker("Pick a color", selection: pickerBinding, supportsOpacity: false)
            .labelsHidden()
            .frame(width: 36)
    }

    private func presetDot(_ c: RGBColor) -> some View {
        let selected = c == rgb
        return Button { rgb = c } label: {
            Circle()
                .fill(Color(.sRGB, red: Double(c.r) / 255, green: Double(c.g) / 255, blue: Double(c.b) / 255))
                .overlay(Circle().strokeBorder(selected ? Theme.card : Theme.inset,
                                               lineWidth: selected ? 2 : 1))
                .overlay(Circle().strokeBorder(selected ? Color.white : .clear, lineWidth: 2)
                    .padding(-2))
                .frame(width: d.dot, height: d.dot)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .help("rgb(\(c.r), \(c.g), \(c.b))")
    }

    private func channel(_ label: String, _ key: WritableKeyPath<RGBColor, Int>) -> some View {
        HStack(spacing: d.isCompact ? 8 : 10) {
            Text(label)
                .font(.system(size: d.dimSize))
                .foregroundStyle(Theme.textDim)
                .frame(width: d.isCompact ? 12 : 14, alignment: .leading)
            Slider(value: Binding(get: { Double(rgb[keyPath: key]) },
                                  set: { rgb[keyPath: key] = Int($0.rounded()) }),
                   in: 0...255)
                .tint(Theme.accent)
                .controlSize(d.isCompact ? .small : .regular)
            Text("\(rgb[keyPath: key])")
                .font(.system(size: d.dimSize).monospacedDigit())
                .foregroundStyle(Theme.textDim)
                .frame(width: d.isCompact ? 28 : 30, alignment: .trailing)
        }
    }
}

// MARK: - Effect

struct EffectPanel<Accessory: View>: View {
    @Binding var effect: LightingEffect
    let d: Density
    @ViewBuilder var accessory: Accessory

    @State private var hovered: LightingEffect?

    private var columns: [GridItem] {
        d.isCompact
            ? Array(repeating: GridItem(.flexible(), spacing: d.fxGap), count: 6)
            : [GridItem(.adaptive(minimum: 96), spacing: d.fxGap)]
    }

    var body: some View {
        Card(d: d) {
            HStack(alignment: .center) {
                SectionLabel(text: "Effect", d: d)
                if d.isCompact {
                    Spacer()
                    accessory
                }
            }
            LazyVGrid(columns: columns, spacing: d.fxGap) {
                ForEach(LightingEffect.allCases) { tile($0) }
            }
        }
    }

    private func tile(_ e: LightingEffect) -> some View {
        let selected = e == effect
        let hot = hovered == e
        return Button { effect = e } label: {
            VStack(spacing: d.isCompact ? 4 : 6) {
                Image(systemName: e.symbol)
                    .font(.system(size: d.fxIcon, weight: .medium))
                    .foregroundStyle(selected ? Theme.accentIcon : Theme.textSoft)
                Text(e.title)
                    .font(.system(size: d.fxFont, weight: .medium))
                    .foregroundStyle(selected ? Color.white : Theme.textSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .padding(.horizontal, 2)
            .frame(maxWidth: .infinity)
            .frame(height: d.fxMinHeight)
            .background(selected ? Theme.accentTint : (hot ? Theme.fillHover : Theme.fill))
            .clipShape(RoundedRectangle(cornerRadius: d.fxRadius, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: d.fxRadius, style: .continuous)
                .strokeBorder(selected ? Theme.accent : .clear, lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovered = $0 ? e : (hovered == e ? nil : hovered) }
        .animation(.easeOut(duration: 0.12), value: selected)
    }
}

// MARK: - Brightness / speed / direction / rainbow

struct ParamsPanel: View {
    @Binding var brightness: Double
    @Binding var speed: Double
    @Binding var direction: Int
    @Binding var rainbow: Bool
    let effect: LightingEffect
    let d: Density

    private var animatable: Bool { !effect.isStatic }
    private var dim: Double { animatable ? 1 : 0.4 }

    var body: some View {
        if d.isCompact { compactBody } else { regularBody }
    }

    // MARK: regular

    private var regularBody: some View {
        Card(d: d, spacing: 6) {
            VStack(spacing: 8) {
                sliderLabel("Brightness", "\(Int(brightness)) / 4")
                Slider(value: $brightness, in: 0...4, step: 1).tint(Theme.accent)
            }
            .padding(.top, 6).padding(.bottom, 10)

            Hairline()
            VStack(spacing: 8) {
                sliderLabel("Speed", "\(Int(speed)) / 5")
                Slider(value: $speed, in: 1...5, step: 1).tint(Theme.accent)
            }
            .padding(.vertical, 10)
            .opacity(dim).disabled(!animatable)

            Hairline()
            HStack {
                Text("Direction").font(.system(size: d.bodySize))
                Spacer()
                SegmentedPair(titles: ["Normal", "Reverse"], selection: $direction, d: d)
            }
            .frame(minHeight: 48)
            .opacity(dim).disabled(!animatable)

            Hairline()
            SwitchRow(isOn: $rainbow, d: d) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rainbow").font(.system(size: d.bodySize))
                    Text("Use all colors instead of one")
                        .font(.system(size: d.dimSize)).foregroundStyle(Theme.textDim)
                }
            }
            .frame(minHeight: 52)
            .opacity(effect.hasRandom ? 1 : 0.4).disabled(!effect.hasRandom)
        }
    }

    private func sliderLabel(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).font(.system(size: d.bodySize))
            Spacer()
            Text(value)
                .font(.system(size: d.dimSize).monospacedDigit())
                .foregroundStyle(Theme.textDim)
        }
    }

    // MARK: compact

    private var compactBody: some View {
        Card(d: d, insets: EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12), spacing: 4) {
            compactSlider("Brightness", value: $brightness, range: 0...4, display: "\(Int(brightness))/4")
            Hairline()
            compactSlider("Speed", value: $speed, range: 1...5, display: "\(Int(speed))/5")
                .opacity(dim).disabled(!animatable)
            Hairline()
            HStack(spacing: 12) {
                HStack(spacing: 10) {
                    Text("Direction").font(.system(size: d.dimSize)).foregroundStyle(Theme.textDim)
                        .frame(width: 72, alignment: .leading)
                    SegmentedPair(titles: ["Normal", "Reverse"], selection: $direction, d: d)
                }
                .opacity(dim).disabled(!animatable)
                Spacer(minLength: 0)
                Button { rainbow.toggle() } label: {
                    HStack(spacing: 8) {
                        Text("Rainbow").font(.system(size: d.bodySize))
                        DesignSwitch(isOn: rainbow, d: d)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .opacity(effect.hasRandom ? 1 : 0.4).disabled(!effect.hasRandom)
            }
            .frame(minHeight: 40)
        }
    }

    private func compactSlider(_ title: String, value: Binding<Double>,
                               range: ClosedRange<Double>, display: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(.system(size: d.dimSize)).foregroundStyle(Theme.textDim)
                .frame(width: 72, alignment: .leading)
            Slider(value: value, in: range, step: 1).tint(Theme.accent).controlSize(.small)
            Text(display)
                .font(.system(size: d.dimSize).monospacedDigit())
                .foregroundStyle(Theme.textDim)
                .frame(width: 28, alignment: .trailing)
        }
        .frame(height: 34)
    }
}
