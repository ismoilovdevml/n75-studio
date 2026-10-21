// KreoProtocol.swift — VGN N75 RGB (Kreo Hive / 320F:5055) lighting protocol.
// Ported from myaumyauverse/kreoctl (reverse-engineered firmware dialect).
// Report: 64 bytes, Report ID 0x04, bytes[1..2] = 16-bit LE checksum of bytes[3..64].
// Layout: [0x04, chkLo, chkHi, cmd, size, offLo, offHi, 0, ...data]
import Foundation

enum Kreo {
    static let reportID: Int = 0x04
    static let reportLen: Int = 64
    static let maxPayload: Int = reportLen - 8

    // Commands
    static let cmdBegin = 0x01
    static let cmdEnd = 0x02
    static let cmdWriteConfig = 0x06
    static let cmdWriteCustomColors = 0x0B
    static let cmdSendDynamicColors = 0x12
    static let cmdEndDynamicColors = 0x13

    // Config offsets
    static let offsetCurrentProfile = 0x00
    static let offsetFirstProfile = 0x01

    static let brightnessMax = 4
    static let totalLEDs = 128
    static let modeCustomByte = 0x14

    /// Chunk a byte buffer into write reports (MAX_PAYLOAD per chunk, offset = i*MAX_PAYLOAD).
    static func chunkedWrites(cmd: Int, buffer: [UInt8]) -> [[UInt8]] {
        var out: [[UInt8]] = []
        var i = 0
        while i < buffer.count {
            let chunk = Array(buffer[i..<min(i + maxPayload, buffer.count)])
            out.append(report(cmd: cmd, offset: i, data: chunk.map { Int($0) }))
            i += maxPayload
        }
        return out
    }

    /// Mode block that switches the keyboard into Custom (per-key) mode.
    static func customModeBlock(brightness: Int) -> [Int] {
        var b = [Int](repeating: 0, count: 18)
        b[0] = modeCustomByte
        b[1] = min(brightness, brightnessMax)
        b[2] = 2; b[3] = 1
        return b
    }

    /// Build a 64-byte report with the 16-bit LE checksum filled in.
    static func report(cmd: Int, offset: Int, data: [Int]) -> [UInt8] {
        var r = [Int](repeating: 0, count: reportLen)
        r[0] = reportID
        r[3] = cmd
        r[4] = min(data.count, maxPayload)
        r[5] = offset & 0xFF
        r[6] = (offset >> 8) & 0xFF
        for (i, v) in data.enumerated() where 8 + i < reportLen { r[8 + i] = v & 0xFF }
        var sum = 0
        for i in 3..<reportLen { sum = (sum + r[i]) & 0xFFFF }
        r[1] = sum & 0xFF
        r[2] = (sum >> 8) & 0xFF
        return r.map { UInt8($0) }
    }

    static func speedToHW(_ speed: Int) -> Int { 5 - min(max(speed, 1), 5) }
    static func directionToHW(_ dir: Int) -> Int { dir == 0 ? 1 : 0 }

    /// 18-byte mode parameter block (encode_mode_block).
    static func modeBlock(mode: LightingEffect, color: RGBColor, brightness: Int,
                          speed: Int, direction: Int, multicolor: Bool) -> [Int] {
        var b = [Int](repeating: 0, count: 18)
        let off = mode == .off
        b[0] = mode.hardwareByte
        b[1] = off ? 0 : min(brightness, brightnessMax)
        b[2] = speedToHW(speed)
        b[3] = directionToHW(direction)
        b[4] = (multicolor && mode.hasRandom) ? 0xFF : 0
        let c = off ? RGBColor(r: 0, g: 0, b: 0) : color
        b[5] = c.r; b[6] = c.g; b[7] = c.b   // PARAM_MODE_COLOR
        b[8] = 0                              // PARAM_COLOR_OFFSET
        return b
    }

    static func profileOffset(_ profile: Int) -> Int {
        offsetFirstProfile + min(profile, 2) * 0x40
    }
}

struct RGBColor: Equatable {
    var r: Int, g: Int, b: Int
    var hex: String { String(format: "#%02X%02X%02X", r, g, b) }
    init(r: Int, g: Int, b: Int) { self.r = r; self.g = g; self.b = b }
    init?(hex: String) {
        var s = hex.trimmingCharacters(in: .whitespaces)
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6, let v = Int(s, radix: 16) else { return nil }
        self.init(r: (v >> 16) & 0xFF, g: (v >> 8) & 0xFF, b: v & 0xFF)
    }
}

/// The 18 hardware lighting effects (+ Off, Custom) from kreoctl's protocol.rs.
enum LightingEffect: Int, CaseIterable, Identifiable {
    case normal, breath, spectrum, wave, ripples, reaction, scan, rain, stars
    case flowers, roll, cartoon, traverse, serpentine, cloud, corrugated, surmount, off

    var id: Int { rawValue }

    var hardwareByte: Int {
        switch self {
        case .corrugated: return 0x01
        case .cloud:      return 0x02
        case .serpentine: return 0x03
        case .spectrum:   return 0x04
        case .breath:     return 0x05
        case .normal:     return 0x06
        case .reaction:   return 0x07
        case .ripples:    return 0x08
        case .traverse:   return 0x09
        case .stars:      return 0x0A
        case .flowers:    return 0x0B
        case .roll:       return 0x0C
        case .wave:       return 0x0D
        case .cartoon:    return 0x0E
        case .rain:       return 0x0F
        case .scan:       return 0x10
        case .surmount:   return 0x11
        case .off:        return 0x06   // Normal + brightness 0
        }
    }

    var title: String {
        switch self {
        case .normal: return "Solid"
        case .breath: return "Breathing"
        case .spectrum: return "Spectrum"
        case .wave: return "Wave"
        case .ripples: return "Ripples"
        case .reaction: return "Reactive"
        case .scan: return "Scan"
        case .rain: return "Rain"
        case .stars: return "Starfield"
        case .flowers: return "Bloom"
        case .roll: return "Roll"
        case .cartoon: return "Cartoon"
        case .traverse: return "Traverse"
        case .serpentine: return "Serpentine"
        case .cloud: return "Cloud"
        case .corrugated: return "Ridges"
        case .surmount: return "Summit"
        case .off: return "Off"
        }
    }

    var symbol: String {
        switch self {
        case .normal: return "circle.fill"
        case .breath: return "wind"
        case .spectrum: return "rainbow"
        case .wave: return "water.waves"
        case .ripples: return "drop.fill"
        case .reaction: return "hand.tap.fill"
        case .scan: return "barcode.viewfinder"
        case .rain: return "cloud.rain.fill"
        case .stars: return "sparkles"
        case .flowers: return "camera.macro"
        case .roll: return "arrow.triangle.2.circlepath"
        case .cartoon: return "theatermasks.fill"
        case .traverse: return "arrow.left.and.right"
        case .serpentine: return "scribble"
        case .cloud: return "cloud.fill"
        case .corrugated: return "waveform.path"
        case .surmount: return "mountain.2.fill"
        case .off: return "power"
        }
    }

    /// Solid and Off have nothing to animate, so speed and direction do not apply.
    var isStatic: Bool { self == .normal || self == .off }

    /// Effects that animate through colors (vs a single chosen color).
    var usesSingleColor: Bool {
        switch self {
        case .normal, .breath, .reaction, .off: return true
        default: return false
        }
    }

    var hasRandom: Bool { !usesSingleColor }
}
