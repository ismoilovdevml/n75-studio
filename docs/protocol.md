# The lighting protocol (Evision 320F:5055)

Everything here was verified against a VGN N75 RGB on macOS over IOKit. The dialect
itself comes from [kreoctl](https://github.com/myaumyauverse/kreoctl), which drives the
same controller on Linux; the facts below are what this app implements in
`N75Studio/KreoProtocol.swift`.

## Transport

- USB HID, VID `0x320F`, PID `0x5055` (Evision; sold as VGN N75 RGB, VGN S99, Kreo Hive).
- Output reports, **Report ID `0x04`**, **64 bytes including the ID byte**.
- On macOS the device must be opened with `kIOHIDOptionsTypeSeizeDevice`. Without seizing,
  `IOHIDDeviceSetReport` returns success for *anything* and nothing reaches the firmware;
  with it, macOS validates the report and only the 64-byte Report ID 4 form is accepted
  (`0x0`) — the other shapes fail with `0xe00002cd`.
- Seizing a keyboard requires the **Input Monitoring** TCC grant.
- Read the reply back after every write (`IOHIDDeviceGetReport`) or the control pipe stalls.

## Frame

```
byte  0      report ID (0x04)
bytes 1..2   16-bit little-endian checksum = sum(bytes[3..63]) & 0xFFFF
byte  3      command
byte  4      payload size
bytes 5..6   offset, little-endian
byte  7      0
bytes 8..63  payload (56 bytes max)
```

## Commands

| Command | Value | Meaning |
|---|---|---|
| `BEGIN` | `0x01` | open a config transaction |
| `END` | `0x02` | commit |
| `WRITE_CONFIG` | `0x06` | write into the config block at `offset` |
| `WRITE_CUSTOM_COLORS` | `0x0B` | per-key color buffer (128 LEDs × RGB) |
| `SEND_DYNAMIC_COLORS` | `0x12` | stream a frame of per-key colors |
| `END_DYNAMIC_COLORS` | `0x13` | stop streaming |

Config offsets: `0x00` selects the current profile, `0x01` is the first profile; profiles
are `0x40` apart.

## Mode block (18 bytes, written at offset `0x01`)

```
[0] effect byte
[1] brightness (0–4; 0 reads as off)
[2] speed, inverted: 5 - speed, speed in 1–5
[3] direction: 1 = normal, 0 = reverse
[4] 0xFF = cycle all colors (rainbow), 0 = use the chosen color
[5] R
[6] G
[7] B
[8] color offset (0)
```

Effect bytes: `0x01` Ridges, `0x02` Cloud, `0x03` Serpentine, `0x04` Spectrum,
`0x05` Breathing, `0x06` Solid, `0x07` Reactive, `0x08` Ripples, `0x09` Traverse,
`0x0A` Starfield, `0x0B` Bloom, `0x0C` Roll, `0x0D` Wave, `0x0E` Cartoon, `0x0F` Rain,
`0x10` Scan, `0x11` Summit, `0x14` Custom (per-key). "Off" is Solid at brightness 0.

## Applying a change

```
BEGIN                                  cmd 0x01
WRITE_CONFIG offset 0x00  data [0]     select profile 0
WRITE_CONFIG offset 0x01  data mode    the 18-byte block
END                                    cmd 0x02
```

Roughly 15 ms between reports is enough; the app spaces them that way.

## What the vendor app does instead

`hub.vgnlab.com` (the WebHID "Sparklink" SDK) frames differently — `[0x5C, len, opcode,
checksum, …]` with a single-byte checksum, RGB sent as B,G,R,255. That dialect is correct
for the web app but this firmware ignores it, and Chrome will not expose the device on
macOS anyway, because its usage page is a protected keyboard usage. The kreoctl dialect
above is the one the hardware obeys.
