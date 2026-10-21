// HIDController.swift — talks to the VGN N75 over IOKit HID using the Kreo protocol.
// Opens with kIOHIDOptionsTypeSeizeDevice and writes Report ID 0x04 (the channel macOS validates).
import Foundation
import IOKit
import IOKit.hid
import Combine
import os

private let log = Logger(subsystem: "com.reverse.N75Studio", category: "hid")

final class HIDController: ObservableObject {
    static let vid = 0x320F
    static let pid = 0x5055

    @Published var isConnected = false
    @Published var hasInputMonitoring = false
    @Published var lastStatus: String = "Searching…"

    private let manager: IOHIDManager
    private let queue = DispatchQueue(label: "hid.n75")

    init() {
        // Seizing a keyboard needs Input Monitoring (TCC). Trigger the system prompt.
        let granted = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        log.notice("Input Monitoring access granted=\(granted, privacy: .public)")
        hasInputMonitoring = granted

        manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        let match: [String: Any] = [kIOHIDVendorIDKey: Self.vid, kIOHIDProductIDKey: Self.pid]
        IOHIDManagerSetDeviceMatching(manager, match as CFDictionary)

        let ctx = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { ctx, _, _, _ in
            guard let ctx else { return }
            let me = Unmanaged<HIDController>.fromOpaque(ctx).takeUnretainedValue()
            DispatchQueue.main.async { me.refresh() }
        }, ctx)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { ctx, _, _, _ in
            guard let ctx else { return }
            let me = Unmanaged<HIDController>.fromOpaque(ctx).takeUnretainedValue()
            DispatchQueue.main.async { me.refresh() }
        }, ctx)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
        refresh()
    }

    private func devices() -> [IOHIDDevice] {
        guard let set = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> else { return [] }
        return Array(set)
    }

    func refresh() {
        let found = !devices().isEmpty
        isConnected = found
        hasInputMonitoring = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent) == kIOHIDAccessTypeGranted
        lastStatus = found ? "VGN N75 RGB connected" : "Keyboard not found — plug it in"
    }

    /// Apply a full lighting configuration to the keyboard.
    func apply(effect: LightingEffect, color: RGBColor, brightness: Int,
               speed: Int, direction: Int, multicolor: Bool) {
        let block = Kreo.modeBlock(mode: effect, color: color, brightness: brightness,
                                   speed: speed, direction: direction, multicolor: multicolor)
        let begin = Kreo.report(cmd: Kreo.cmdBegin, offset: 0, data: [])
        let selectP0 = Kreo.report(cmd: Kreo.cmdWriteConfig, offset: Kreo.offsetCurrentProfile, data: [0])
        let write = Kreo.report(cmd: Kreo.cmdWriteConfig, offset: Kreo.offsetFirstProfile, data: block)
        let end = Kreo.report(cmd: Kreo.cmdEnd, offset: 0, data: [])

        queue.async { [weak self] in
            guard let self else { return }
            // Use a FRESH IOHIDManager per apply (mirrors the working CLI) so repeated
            // seize/close cycles stay reliable instead of fighting the persistent manager.
            let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
            let match: [String: Any] = [kIOHIDVendorIDKey: Self.vid, kIOHIDProductIDKey: Self.pid]
            IOHIDManagerSetDeviceMatching(mgr, match as CFDictionary)
            IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))
            defer { IOHIDManagerClose(mgr, IOOptionBits(kIOHIDOptionsTypeNone)) }
            let devs = (IOHIDManagerCopyDevices(mgr) as? Set<IOHIDDevice>).map(Array.init) ?? []
            guard !devs.isEmpty else {
                DispatchQueue.main.async { self.lastStatus = "No device to send to" }
                return
            }
            var anyOK = false
            var lastErr: IOReturn = kIOReturnSuccess
            for d in devs {
                let opt = IOOptionBits(kIOHIDOptionsTypeSeizeDevice)
                let openRes = IOHIDDeviceOpen(d, opt)
                log.info("open=\(String(format: "0x%08x", openRes), privacy: .public)")
                for (name, pkt) in [("BEGIN", begin), ("SELECT", selectP0), ("WRITE", write), ("END", end)] {
                    let r = self.send(d, pkt)
                    if r == kIOReturnSuccess { anyOK = true } else { lastErr = r }
                    log.info("\(name, privacy: .public) set=\(String(format: "0x%08x", r), privacy: .public)")
                    usleep(15_000)
                }
                IOHIDDeviceClose(d, opt)
            }
            DispatchQueue.main.async {
                if anyOK && lastErr == kIOReturnSuccess {
                    self.lastStatus = "Applied \(effect.title) · \(color.hex)"
                } else if !anyOK {
                    // 0xe00002c2 / not permitted → Input Monitoring missing
                    self.lastStatus = "Blocked (\(String(format: "0x%08x", lastErr))) — allow Input Monitoring"
                } else {
                    self.lastStatus = "Partial send (\(String(format: "0x%08x", lastErr)))"
                }
            }
        }
    }

    @discardableResult
    private func send(_ d: IOHIDDevice, _ bytes: [UInt8]) -> IOReturn {
        var buf = bytes
        let res = IOHIDDeviceSetReport(d, kIOHIDReportTypeOutput, CFIndex(Kreo.reportID), &buf, buf.count)
        // drain reply so the control pipe doesn't stall
        var rb = [UInt8](repeating: 0, count: 64); var rl = CFIndex(64)
        _ = IOHIDDeviceGetReport(d, kIOHIDReportTypeInput, CFIndex(Kreo.reportID), &rb, &rl)
        return res
    }
}
