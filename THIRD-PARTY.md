# Third-party components

No third-party code is vendored or compiled into this app. One project was read to
learn the wire format.

## Protocol reference — read, not copied

- [kreoctl](https://github.com/myaumyauverse/kreoctl) (MIT) — a Rust CLI for the same
  Evision controller on Linux. Its `src/protocol.rs` is where the command numbers, the
  16-bit checksum rule, the 18-byte mode block and the effect byte values come from.
  No Rust source is present here; `KreoProtocol.swift` was written in Swift from those
  facts and re-verified against the keyboard over IOKit.

The vendor's own WebHID app (`hub.vgnlab.com`) was also decompiled while working this
out. It speaks a different dialect (`0x5C` header, single-byte checksum) that this
firmware ignores, so none of it is used here. See [docs/protocol.md](docs/protocol.md).

VGN, N75 and Evision are trademarks of their respective owners. This project is not
affiliated with or endorsed by any of them.
