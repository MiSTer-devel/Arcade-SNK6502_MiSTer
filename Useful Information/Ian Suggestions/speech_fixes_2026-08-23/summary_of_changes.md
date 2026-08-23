# Summary of Changes — HD38880 Speech Fixes (2026-08-23)

## Symptoms addressed

| Game | Symptom |
|---|---|
| Vanguard | **Zero speech** — no phrase ever plays at the right moment |
| Fantasy | Speech audible but garbled / "clipped" compared to the golden Python synthesis |

Both trace to defects in the speech datapath glue, not in the reverse-engineered
format or the decode tables. Two root causes, one shared and one
Vanguard-specific, plus two smaller fixes found during the audit.

---

## Root cause 1 (both games): ROM fetch handshake ingested every byte twice

`SPEECH-ROMFETCH-2026-08-23` — [rtl/sound/hd38880/hd38880_unpack.v](rtl/sound/hd38880/hd38880_unpack.v)

In S_FILL the unpacker asserted `rom_rd` on **every** cycle until it saw
`rom_valid`. But `rom_valid` is `rom_rd` delayed one clock (hd38880_top), so
`rom_rd` was always high for two cycles, `rom_valid` answered for two cycles,
and each fetch **appended the same byte twice** while `rom_addr` advanced by
two. The bitstream fed to the 49-bit frame parser was therefore
"byte N, byte N, skip byte N+1" for every phrase of both games.

Cycle-accurate simulation of the old RTL (ctrl + top glue + registered dpram +
unpacker, driven by the real 6502 CTP/CMV nibble protocol) confirmed the fetch
stream `134,134,81,81,141,141,…` and showed the parser drifting in and out of
alignment — decoded amplitude track `6,7,31,3,4,8,13,13,…` against a true track
of `6,7,8,9,10,…`. That quasi-alignment is why Fantasy remained *recognizable
but degraded*, and why the earlier Verilator bench measured only 0.51
correlation on Vanguard phrase 2: the corruption was present in simulation too.

**Fix:** request only when no fetch is in flight (`else if (!rom_rd)
rom_rd <= 1'b1;`). One fetch = one append; 3 clocks per byte, ample for the
~6 bytes per 20 ms frame the format needs.

## Root cause 2 (Vanguard): unpacker wedged forever after the first phrase

`SPEECH-PHRASE-END-2026-08-23` + `SPEECH-RESTART-2026-08-23` —
[hd38880_unpack.v](rtl/sound/hd38880/hd38880_unpack.v),
[hd38880_ctrl.v](rtl/sound/hd38880/hd38880_ctrl.v),
[hd38880_top.v](rtl/sound/hd38880/hd38880_top.v)

As documented in the package README: **Vanguard's phrases carry no amp==63 stop
marker and its host never sends STOP** — phrases are bounded by the next
address-table entry. The RTL implemented neither bound:

- the unpacker reached S_DONE only on amp==63 or host STOP (never, in Vanguard);
- START was honoured only in S_IDLE.

So the first phrase Vanguard ever triggered started the unpacker, which then
consumed the entire 8KB BRAM window forever (real data → zeros → wrap), and
**every subsequent START was silently ignored**. Fantasy survived only because
its game code sends an explicit STOP ($BEC5), rescuing the FSM each time.

**Fixes:**

1. `hd38880_ctrl` now outputs `end_addr` — the next phrase-table address
   (Vanguard phrase 15 ends at $5605, i.e. after the last programmed byte
   $5604; Fantasy phrase 11 is bounded by ROM end $5800). For Fantasy this is
   a safety net; its amp==63 terminator still fires first.
2. `hd38880_unpack` takes `end_addr` and enters S_DONE when it needs bytes at
   or past it — the phrase ends cleanly, the existing done-pulse forces a
   silence frame into the lattice, and the FSM returns to S_IDLE.
3. START is now honoured in **any** state (restart, as the real chip does),
   so the unpacker can never wedge. A `fetch_skip` flag discards the one
   potentially in-flight ROM byte belonging to the old address stream when a
   restart lands mid-fetch.

## Fix 3 (fidelity, both games): lattice backward-wave off-by-one

`SPEECH-LATTICE-DELAY-2026-08-23` —
[rtl/sound/hd38880/parcor_lattice.v](rtl/sound/hd38880/parcor_lattice.v)

At the stage-1 completion edge, the delay-line shift read `b_new[0]` on the
same clock edge that writes it, so `b_delay[1]` received the **previous**
sample's value — stage 2's backward input ran one sample late, skewing the
lattice transfer function of every phrase. The shift now uses the freshly
computed value (`b_loss + (p_kf >>> 9)`, the same expression that feeds
`b_new[0]`).

## Fix 4 (hardening): exact speech-port address decode

`SPEECH-ADDR-DECODE-2026-08-23` — [rtl/snk6502.v](rtl/snk6502.v)

The speech write strobe matched the whole $34xx / $24xx page; MAME maps
`speech_w` at $3400 / $2400 **exactly**. A stray write anywhere else in the
page would inject a spurious nibble into the HD38880 command FSM and desync
it. Both decodes tightened to the exact address.

---

## Files modified

| File | Change |
|---|---|
| `rtl/sound/hd38880/hd38880_unpack.v` | Single-in-flight ROM fetch; `end_addr` input + end-of-phrase bound; START honoured in any state (+ `fetch_skip` restart guard) |
| `rtl/sound/hd38880/hd38880_ctrl.v` | New `end_addr` output + `end_lookup()` table (latched with START); reset value $FFFFF |
| `rtl/sound/hd38880/hd38880_top.v` | `end_addr` wired from both ctrl instances through the game mux into the unpacker |
| `rtl/sound/hd38880/parcor_lattice.v` | Delay-line shift uses the same-edge fresh `b_new[0]` value |
| `rtl/snk6502.v` | `vg_speech_wr` / `fy_speech_wr` decode $3400 / $2400 exactly |

No changes to: decode tables (`hd38880_dectab.v`), MRAs, ROM download layout,
`files.qip` (no new files — all changes are in already-built sources).

## Verification

A cycle-accurate Python model of the datapath (ctrl FSM, top glue with the
1-cycle `rom_valid` delay and 20 ms frame pacing, registered-dpram timing,
unpacker), driven by the genuine 6502 nibble protocol (INT1/INT2/SYSPD/ADSET/
START, high-nibble-first, port cleared between bytes) against a format-valid
synthetic speech ROM:

- **Old RTL:** every byte fetched twice / odd bytes skipped; decoded frames
  garbled; after the first Vanguard phrase, a second START was ignored
  (unpacker stuck past the end of the phrase data, `done` never fired).
- **Fixed RTL:** zero duplicate fetches, every fetched value correct;
  **all frames of both test phrases decode bit-exact** (amp, pitch, k1, k10);
  `done` fires at the table boundary and a forced silence frame is latched;
  back-to-back phrases both play; a 60-case stress sweep restarting mid-phrase
  at varying cycle alignments (to hit the in-flight-fetch window) decodes the
  new phrase bit-exact in all 60 cases.

Not verified here: FPGA synthesis/timing (rebuild in Quartus required) and
audio on real hardware.

## Expected result

- **Vanguard:** every phrase plays on cue and terminates at its table
  boundary. Repeated triggers work indefinitely.
- **Fantasy:** phrases should now match the golden `hd38880_decode.py`
  synthesis (the unpacker reproduces the golden frame vectors exactly);
  terminators (amp==63) are detected reliably, so no more premature/garbled
  endings.
- Both games gain a small clarity improvement from the lattice delay fix.

## Notes

- `rtl/sound/hd38880/update/hd38880_unpack.v` (and the zips) are **stale
  package staging copies, not built** (see `files.qip`). They do NOT contain
  these fixes — do not copy them over the fixed files.
- If speech is now correct but slightly loud/quiet in the mix, the tuning
  point is `speech_audio_scaled` in `rtl/snk6502.v` (currently `<<< 1`, see
  SPEECH-GAIN-2026-08-03).
