# airpods

Battery and controls for Apple AirPods on Linux, in a single file with no
dependencies beyond the Python standard library.

BlueZ exposes nothing for AirPods — no battery, no settings. They speak neither
the GATT Battery Service nor anything `bluetoothd` surfaces from HFP. So this
talks Apple's proprietary AAP/AACP protocol directly, over L2CAP PSM `0x1001`.

No root. No kernel patches. No `Experimental = true`.

```
 Digvijay's AirPods   A3055 · 81.2675000075000000.6814

   Left    ████████████████░░░░   81%
   Right   ████████████████░░░░   81%
   Case    ────────────────────   —

   Wearing               in ear / in ear

 LISTENING MODE
 ▸ Mode                ○ Off   ● ANC   ○ Transparency   ○ Adaptive

 TOGGLES
   [ ] Conversational Awareness
   [ ] Adaptive Volume
   [ ] One-Bud ANC
   [✓] Volume Swipe
   [ ] Sleep Detection

 LEVELS
   Adaptive ANC Strength   ▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░  50
   Chime Volume            ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░  80

 j/k move   h/l adjust   space toggle   r reconnect   q quit
```

## Install

```sh
git clone https://github.com/<you>/airpods.git
cd airpods
./install.sh              # -> ~/.local/bin/airpods
```

It is one self-contained script; copying `airpods` anywhere on your `PATH`
works just as well.

**Requirements:** Python 3, `bluez-utils` (for `bluetoothctl`), and `busctl`
(part of systemd). On Arch: `pacman -S python bluez bluez-utils`.

Pair the AirPods normally first — this tool reads and controls them, it does not
handle pairing.

## Usage

```sh
airpods              # terminal UI (default)
airpods --battery    # Left: 81%  Right: 81%  Case: --
airpods --json
airpods --waybar     # waybar JSON module format
airpods --watch      # stream updates; combines with the above
```

The menu is generated from whatever your buds actually advertise, so it shows
only controls that exist on your model.

**Only one AAP session can exist at a time.** The TUI holds it, so one-shot
invocations will fail while it is running.

## Notes on the protocol

Everything below was derived from packet captures against AirPods 4 ANC
(A3055/A3056, firmware 81.2675) plus the excellent protocol documentation in
[librepods](https://github.com/librepods-org/librepods).

Session setup:

```
connect L2CAP PSM 0x1001
-> 00000400 01000200 00000000 00000000   handshake
-> 04000400 4d00 ff00000000000000        host capabilities
-> 04000400 0f00 ffffffffff              subscribe to notifications
```

Packets are `04 00 04 00 <opcode LE16> <payload>`.

**Battery** (opcode `0x0004`) — `<count>` then five bytes per component:
`<kind> <?> <level> <status> <?>`, where kind is `0x01` single / `0x02` right /
`0x04` left / `0x08` case, and status is `0x01` charging / `0x02` normal /
`0x04` disconnected.

The case reports `0x04` whenever both pods are out of it. That is normal Apple
behaviour, not a failure — a real case level appears only once a pod is seated.

**Settings** (opcode `0x0009`) — `<id> <d1> <d2> <d3> <d4>`, 11 bytes total.
Verified writable on this hardware: `0x0D` listening mode, `0x28` conversational
awareness, `0x26` adaptive volume, `0x1B` one-bud ANC, `0x35` sleep detection,
`0x17` double-press speed, `0x18` press-and-hold speed, `0x2E` adaptive ANC
strength, `0x1F` chime volume. Silently refused by this firmware: `0x25` volume
swipe, `0x23` volume swipe speed, `0x3E` uplink EQ.

### The one real gotcha

**A setting change is often not echoed in the session that made it.** The write
lands, but the buds may only report the new value after a reconnect. Do not read
a missing echo as a rejection — an early version of this tool did exactly that,
and wrongly reported nine writable settings as read-only.

So the UI shows your change immediately, marks it `…` while awaiting
confirmation, downgrades to `unconfirmed` after 12 seconds, and never reverts
it. For ground truth, reconnect and read.

## Troubleshooting

**`Errno 110` / `Errno 112` while `bluetoothctl` still shows them connected.**
The buds idle out the L2CAP channel when not worn; BlueZ keeps the ACL link up
regardless. Put them in your ears and press `r`, or just retry.

**Nothing found.** Confirm they are connected (`bluetoothctl devices Connected`)
and that the device advertises the AAP UUID
`74ec2172-0bad-4d01-8f77-997b2be0722a`.

## Android?

Not feasible as a normal app. Android's public
`createInsecureL2capChannel()` validates `psm < 0x0100` (LE CoC only), but
AirPods need classic PSM `0x1001`; the hidden `createInsecureL2capSocket` is
denied under non-SDK API restrictions, and most Android Bluetooth stacks then
reject the connection outright. This is why LibrePods requires Xposed/LSPosed
and often root. Battery alone is readable root-free from BLE Continuity
advertisements — [CapOD](https://github.com/d4rken-org/capod) already does that.

## Credits

Protocol documentation from [librepods](https://github.com/librepods-org/librepods),
which is a far more featureful project and worth using if you want more than this.

## License

MIT
