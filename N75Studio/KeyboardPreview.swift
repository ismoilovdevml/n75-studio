// KeyboardPreview.swift — the lit 75% keyboard from the design mockup.
// Two styles: `full` (the preview card in the full window) and `mini`
// (the 150pt strip in the compact window's Effect card header).
import SwiftUI

extension LightingEffect {
    /// Effects the preview renders as a spectrum rather than the chosen color.
    var previewIsMultiColor: Bool {
        switch self {
        case .spectrum, .wave, .cloud, .serpentine: return true
        default: return false
        }
    }
}

struct KeyboardPreview: View {
    enum Style { case full, mini }

    let style: Style
    let color: RGBColor
    let effect: LightingEffect
    let brightness: Int
    let rainbow: Bool

    /// Unit widths per row; every row sums to 15u (75% layout, as exported).
    private static let layout: [[CGFloat]] = [
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2],
        [1.5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.5],
        [1.75, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2.25],
        [2.25, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1.75, 1],
        [1.25, 1.25, 1.25, 6.25, 1, 1, 1, 1, 1],
    ]

    private var isFull: Bool { style == .full }
    private var gap: CGFloat { isFull ? 6 : 2 }
    private var radius: CGFloat { isFull ? 6 : 1.5 }
    private func keyHeight(_ row: Int) -> CGFloat {
        isFull ? (row == 0 ? 26 : 36) : (row == 0 ? 4 : 6)
    }

    private var isOff: Bool { effect == .off || brightness == 0 }
    private var isMulti: Bool { rainbow || effect.previewIsMultiColor }
    private var alpha: Double {
        let scale: [Double] = isFull ? [0, 0.35, 0.6, 0.8, 1] : [0, 0.4, 0.65, 0.85, 1]
        return scale[min(max(brightness, 0), 4)]
    }

    var totalHeight: CGFloat {
        let heights = (0..<Self.layout.count).map { keyHeight($0) }
        return heights.reduce(0, +) + gap * CGFloat(Self.layout.count - 1)
    }

    /// hsl(pos·330 + row·6, 85%, 58%) from the mockup, converted to SwiftUI HSB.
    private func keyColor(pos: CGFloat, row: Int) -> Color {
        guard isMulti else {
            return Color(.sRGB, red: Double(color.r) / 255, green: Double(color.g) / 255,
                         blue: Double(color.b) / 255)
        }
        let deg = Double(pos) * 330 + Double(row) * 6
        return Color(hue: (deg / 360).truncatingRemainder(dividingBy: 1),
                     saturation: 0.762, brightness: 0.937)
    }

    var body: some View {
        VStack(spacing: gap) {
            ForEach(Array(Self.layout.enumerated()), id: \.offset) { ri, units in
                row(index: ri, units: units)
            }
        }
        .frame(height: totalHeight)
    }

    private func row(index ri: Int, units: [CGFloat]) -> some View {
        let h = keyHeight(ri)
        // Cumulative unit position of each key centre, as the mockup computes it.
        var x: CGFloat = 0
        let centres: [CGFloat] = units.map { u in
            let c = (x + u / 2) / 15
            x += u
            return c
        }
        return GeometryReader { geo in
            let free = max(geo.size.width - gap * CGFloat(units.count - 1), 0)
            HStack(spacing: gap) {
                ForEach(units.indices, id: \.self) { i in
                    key(color: keyColor(pos: centres[i], row: ri))
                        .frame(width: free * units[i] / 15, height: h)
                }
            }
        }
        .frame(height: h)
    }

    @ViewBuilder
    private func key(color col: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        if isFull {
            ZStack(alignment: .bottom) {
                shape.fill(isOff ? Theme.keyOff : Theme.keyFill)
                Rectangle().fill(Color.black.opacity(0.5)).frame(height: 2)
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(isOff ? Color.clear : col.opacity(alpha * 0.55), lineWidth: 1))
            .shadow(color: isOff ? .clear : col.opacity(alpha * 0.45), radius: 5, y: 2)
        } else {
            shape.fill(isOff ? Theme.segTrack : col.opacity(alpha))
        }
    }
}

/// The preview card in the full window: dark well + caption.
struct PreviewCard: View {
    let color: RGBColor
    let effect: LightingEffect
    let brightness: Int
    let rainbow: Bool
    let d: Density

    private var isMulti: Bool { rainbow || effect.previewIsMultiColor }
    private var effectName: String {
        (rainbow && effect != .off) ? "\(effect.title) · Rainbow" : effect.title
    }

    var body: some View {
        Card(d: d, padding: 28, background: Theme.cardAlt, spacing: 18, alignment: .center) {
            KeyboardPreview(style: .full, color: color, effect: effect,
                            brightness: brightness, rainbow: rainbow)
                .padding(16)
                .background(Theme.well)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.45), radius: 30, y: 20)
                .frame(maxWidth: 760)

            HStack(spacing: 10) {
                captionDot
                Text(effectName).font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.text)
                Text("·").foregroundStyle(Theme.textDim)
                Text(color.hex)
                    .font(.system(size: 13, design: .monospaced))
                    .foregroundStyle(Theme.textDim)
            }
            .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private var captionDot: some View {
        if isMulti {
            Circle()
                .fill(AngularGradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red],
                                      center: .center))
                .frame(width: 10, height: 10)
        } else {
            Circle()
                .fill(Color(.sRGB, red: Double(color.r) / 255, green: Double(color.g) / 255,
                            blue: Double(color.b) / 255))
                .frame(width: 10, height: 10)
        }
    }
}
