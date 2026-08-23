# HD38880 Speech Synthesizer — Reverse Engineering Summary & Integration Guide

The Hitachi HD38880 (with HD38882 EPROM interface) is the PARCOR speech chipset
on SNK's SK6 board, used by Vanguard (1981) and Fantasy (1981). Its ROM data
format was never publicly documented; MAME has played WAV samples instead for
~25 years. This project recovered the format from the ROMs themselves, validated
it against recordings of real hardware, and produced working Python and Verilog
implementations.

---

## 1. What was known vs unknown at the start

KNOWN (MAME + Hitachi Hyoron Vol.63 No.12, 1981):
- Host command protocol: 6-bit port (SYBS1-4 nibble, CTP strobe, CMV valid);
  commands ADSET=2, READ=3, INT1=4, INT2=6, SYSPD=8, STOP=10, CONDT=11,
  START=12, SSTART=14. ADSET takes 5 nibbles LSB-first = 20-bit byte address.
- Architecture: 8 kHz, 10-stage 2-multiply PARCOR lattice, vocal-tract loss
  alpha=0.992, 10x15-bit multiplier, impulse/triangular voiced source,
  M-sequence unvoiced source, parameter interpolation, decode ROM with
  tanh^-1 companding on k1/k2 and linear coding on k3..k10.
- Frame parameters: Amp, Pitch, k1..k10; "48 bits/frame, 20 ms" for these games.

UNKNOWN: the bit-level frame layout, all quantiser tables, silence/stop
handling — i.e. everything needed to actually synthesize.

## 2. How it was solved

1. **Frame period by bit-agreement autocorrelation.** Adjacent LPC frames are
   similar, so bits one frame apart agree above chance. Sweeping the lag over
   all phrases gave a sharp peak at **49 bits, LSB-first** (0.68-0.71 agreement
   vs 0.505 baseline) on both games independently. Frames slip 1 bit/frame vs
   the byte grid — which is why phrase lengths aren't multiples of 6 bytes.
2. **Field boundaries by per-position agreement.** Within the 49-bit grid, an
   LSB-first field is noisy at its LSB and stable at its MSB, so agreement
   drops mark field starts: 0,7,13,20,25,28,31,34,37,40,43,46 — twelve fields,
   identical in both games = Amp(6) + flag(1) + Pitch(6) + k1(7) + k2(5) +
   8 x 3-bit k. Parameter bits = 48, matching Hitachi's published figure.
3. **Alignment to hardware recordings.** MAME's vg_voi-*/ft_voi-* WAVs are
   recordings of the real chip. Aligning decoded amplitude tracks to their
   energy envelopes confirmed the 20 ms frame (160 samples) and gave a
   per-frame correspondence for fitting.
4. **Quantiser recovery.** Amp: r=0.9 vs log-RMS; final law is a fitted
   64-entry monotone table. Pitch: solved only after adding Fantasy (Vanguard
   is monotone); robust fit with octave correction gives a 64-entry monotone
   table, approx period = 1.5*code + 3 samples (code 0 -> 500 Hz .. 63 -> 82 Hz;
   code 0 in the field = unvoiced). k1..k10: analysis-by-synthesis coordinate
   descent against pitch-adaptive cepstral envelope targets (LPC targets are
   biased at high F0), monotone-constrained, train/test split. The recovered
   k1 curve is uniform in the tanh^-1 domain — Hitachi's documented companding,
   recovered empirically.
5. **Structural rules found by listening + measurement** (user's ear found
   every one of these):
   - **Silence frames are 6 bits** (Amp=0, nothing follows). A fixed 49-bit
     stride desynchronises at the first pause.
   - **Stop marker = Amp all-ones (63)**, never valid mid-phrase (0/1400+
     frames); bit 6 rides along on Fantasy terminators. Do not synthesize it.
     Vanguard's phrases carry no stop markers (host/address-table bounded).
   - **Amplitude is applied immediately** each frame; interpolating it leaves
     an audible tail after words. k's interpolate in 8 sub-steps.
   - **Interpolation is inhibited across voiced/unvoiced changes** (crisp
     consonants; TMS5220 does the same).
   - Unvoiced excitation needed a ~4x gain over the naive guess to balance
     fricatives ("Bon Voyage" vs "Bun Voya").
6. **Output-stage modelling.** The de-emphasis integrator's LF gain must be
   tamed by a ~240 Hz first-order high-pass (SK6 AC coupling + speaker);
   ~0.08 aspiration noise in voiced frames. Voiced source is a plain impulse:
   triangular excitation (INT1 bit 3 = 1) measures far worse on band-profile
   error (5.6 vs 0.9 dB), so these games select impulse.
   TWO EARLIER ADDITIONS WERE REMOVED after being shown to chase artifacts of
   the reference recordings rather than chip behaviour:
     - a crest-matching soft limiter (added audible distortion only -28 dB down);
     - a 2-stage allpass "pulse dispersion" (only affected waveform symmetry and
       crest factor, both of which are artifacts of the limiting applied to the
       MAME WAVs; removing it changed band-profile error 0.93 -> 0.92 dB and
       left valley depth unchanged).
   The chain after the lattice is now fully linear: de-emphasis, high-pass, gain.

Final quality: envelope LSD ~4.4 dB held-out (white noise ~18-20 dB); band
profile within ~1 dB of hardware; correct durations, voicing, pitch tracks,
consonant balance. Remaining gap (~2 dB formant softness) is set by the 3-bit
k3..k10 quantisers and residual alignment error.

## 3. Deliverables

| File | Role |
|---|---|
| `hd38880_frame_format.md` | Full research log: evidence, method, all findings |
| `hd38880_decode.py` | Reference decoder + synthesizer (both games), generates WAVs |
| `hd38880_analyse.py` | Structural analyser (autocorrelation, field profile) |
| `hd38880_tables_abs.json` | All decode tables: amp_table[64], pitch_table_full[64], k1_bins[16], k2_bins[16], k3..k10[8] |
| `hd38880_ctrl.v` | Host command FSM (CTP/CMV nibble protocol, ADSET/START/STOP/INT1/INT2/SYSPD) |
| `hd38880_unpack.v` | Bitstream unpacker (49-bit frames, 6-bit silence, amp=63 stop) |
| `parcor_lattice.v` | 10-stage lattice synthesis engine (8 kHz, alpha=0.992, time-shared MAC) |
| `audio/` | 90 WAVs: per-phrase synth + real-vs-synth A/B + combined, both games |

Verilog datapath: `hd38880_ctrl` -> `hd38880_unpack` -> decode ROMs (tables
JSON, x512 for Q1.9) -> `parcor_lattice` -> de-emphasis + high-pass -> DAC.
Compute: 20 lattice MACs + 2 allpass + interpolation per 125 us sample — one
shared multiplier at any modest clock. Tables: 64+64+16+16+64 entries = trivial
BRAM/LUTROM.

## 4. Interfacing with the chipset (any SK6-style game)

Sound CPU writes a 6-bit value; a nibble is accepted when bits 4 (CTP) and
5 (CMV) are both set. Observed sequence per phrase:

```
INT1, operand          ; excitation config (bit3 tri/impulse, bit2 loss,
                       ;  bit1&3 external pitch via EXTP A/B latch lines)
INT2, operand          ; frame format — both games use 0xF:
                       ;  48 bits, 20 ms, repeat-enable, 10 stages
SYSPD, operand         ; speed (n+1)/10, optional
ADSET, n0..n4          ; 20-bit byte address, LSB nibble first
START                  ; begin synthesis (chip fetches ROM serially itself)
...                    ; STOP at any time to halt
```

Per-game specifics:
- **Vanguard**: speech ROMs sk6_ic07/08/11 at 0x4000-0x57FF (external space
  begins at 0x4000 = end of the 128 kbit HD38881 region). 16 phrases at
  0x4000, 0x4325, 0x44A2, 0x45B7, 0x46EE, 0x4838, 0x4984, 0x4B01, 0x4C38,
  0x4DE6, 0x4F43, 0x5048, 0x5160, 0x5289, 0x539E, 0x54CE. No stop markers —
  end each phrase at the next table address (last programmed byte 0x5604).
  EXTP A/B (sound latch port 1, bits 4-5) provide live pitch bend.
- **Fantasy**: ROMs fs_d_7/e_8/f_11, same mapping. 12 phrases at 0x4000,
  0x4297, 0x44B6, 0x4682, 0x4927, 0x4BE0, 0x4CC2, 0x4E36, 0x5000, 0x5163,
  0x52C9, 0x53FD. Phrases self-terminate with the amp=63 stop frame.
- **Other games / unknown ROMs**: the format is game-independent (identical
  across both known sets). To support a new dump: capture the ADSET addresses
  the game writes (or run `hd38880_analyse.py` — the 49-bit autocorrelation
  peak and 12-field profile confirm alignment), honour INT2 (a 96-bit/10 ms
  mode exists but is unobserved — field widths for it are unknown), and apply
  the same silence/stop rules. Chips paired with the HD38881 mask ROM instead
  of EPROMs would need that 128 kbit internal ROM dumped (addresses < 0x4000).

## 4b. Hardware facts from the SK6 schematic + parts list

Confirmed from the Vanguard manual's SK6 parts list and audio schematic:

| item | value | consequence |
|---|---|---|
| Crystal | **640 kHz** | 640000/80 = **8000 Hz sample rate exactly**; 20 ms frame = 160 samples exactly. Both previously *assumed*, now *derived*. |
| EPROMs | 3 x 2716 | confirms the 6 KB (0x4000-0x57FF) speech space |
| Speech ICs | 1 x 38880, 1 x 38882 | as mapped |
| Latch/decode | 74LS174, 74LS365, 74LS138, 74LS10 | host command latch path |
| Audio op-amp | LM324 (3 stages used) | output chain below |
| C14 0.1uF -> R13 5.6K | **284 Hz high-pass** | replaces the previously fitted 240 Hz guess |
| R12 22K / C12 2.2nF | **3288 Hz low-pass** | reconstruction filter - was entirely missing from the model |
| R10 22K / C11 1nF | **7234 Hz low-pass** | second pole |

The derived chain measures 0.89 dB band-profile error vs 0.85 dB for the old
fitted guess - statistically identical, but now physically justified rather than
tuned against contaminated reference recordings. A pure-integrator first stage
was also tested and is clearly wrong (3.57 dB), so the de-emphasis pole (0.9)
stands.

CAVEAT: component *designators* were read from a low-resolution schematic image
and matched against the parts list. The list constrains the possible values
(it contains 100pF, 1nF, 2.2nF, 0.1uF, 1uF, 2.2uF, 470uF and a single 5.6K),
which makes the readings well-constrained but not certain. Verify against a real
board before treating the exact corner frequencies as authoritative.

## 4c. SK-6 schematic: the 555 external-pitch oscillator, and the ROM path

Tracing the SK-6 sheet (375-17-0300) resolves two more unknowns.

**IC1 (17555) is the external pitch oscillator.** Its timing network is switched
by IC2 (14066 quad analog switch), whose control inputs are EXTP A and EXTP B -
the two sound-latch bits MAME labels "HD38880 external pitch control". With
R6 = 1K, a 1uF timing cap, and R14 = 33K / R15 = 15K switched in:

| EXTP B | EXTP A | R_A | resulting F0 |
|---|---|---|---|
| off | off | - | oscillator stopped |
| off | on  | 15K | 84.7 Hz |
| on  | off | 33K | 41.1 Hz |
| on  | on  | 10.3K | 117.0 Hz |

So EXTP is NOT a continuous pitch bend: it selects one of three fixed pitch
rates (or off). This is a real hardware feature an accurate core should model,
but measurement shows the games use the ROM's internal pitch for normal speech:
every phrase with genuine pitch variation correlates strongly NEGATIVELY between
ROM pitch code and measured F0 (va00 -0.99, va09 -0.88, fa02 -0.88, fa10 -0.98),
and no phrase sits at 41 Hz or 85 Hz, the two unambiguous external-only states.
INT1's external-pitch mode therefore appears unused for the phrase library.

**ROM path confirmed.** IC10 (HD38882, 42-pin - matching Hitachi's DILP-42) drives
ROMA0..A10 to all three 2716s in parallel, with an LS138-style decoder selecting
which device. That is a flat, linear, byte-addressed 6 KB space - exactly the
memory model the decoder assumes, and independent confirmation of the ROM map.

**Host latch confirmed.** IC3 (74LS174 hex D flip-flop) is the 6-bit command
latch feeding SYBS1-4 + CTP + CMV, matching the documented host protocol width.

**Package check.** 28-pin socket for the HD38880, 42-pin for the HD38882, three
24-pin for the 2716s - consistent with Hitachi's published packages (HD38880
DILP-28, HD38882 DILP-42).

## 4d. Sound-CPU disassembly: the command sequence, confirmed by observation

Disassembling Vanguard's 6502 code (sk4_ic07..ic16, speech port at $3400)
settles the mode questions that were previously inferred from audio.

**Nibble transmit ($6F8E)** - exactly the documented CTP/CMV handshake:

    $6F8E  LDA #$30      ; CTP=1, CMV=1   (bits 4 and 5)
    $6F90  ORA $10       ; OR in the 4-bit nibble
    $6F92  STA $3400     ; nibble latched on this write
    $6F95  AND #$2F      ; drop CTP, keep CMV + nibble
    $6F97  ORA $10
    $6F99  STA $3400     ; strobe low
    $6F9C  RTS

**Byte transmit ($6F7B)** sends HIGH nibble first, then low nibble.

**Per-phrase sequence ($6F30)**, with $3400 cleared to 0 between bytes:

| byte sent | nibbles | meaning |
|---|---|---|
| `$44` (from table) | 4, 4 | **INT1, operand 4** |
| `$6F` | 6, F | **INT2, operand F** |
| `$89` | 8, 9 | **SYSPD, operand 9** -> speed (9+1)/10 = 1.0x |
| 3 table bytes | 2 + five address nibbles | **ADSET** + 20-bit start address |
| `$C0` | C, 0 | **START** (low nibble 0 = ignored) |

**INT1 operand = 4 = binary 0100 resolves three open questions:**
- bit 3 = 0 -> **impulse excitation, not triangular**
- bit 2 = 1 -> **vocal-tract loss ENABLED** (alpha = 0.992 confirmed in use)
- bit 1 = 0 -> **external pitch NOT used** (the 555/14066 path is idle)

All three match what was independently inferred from the audio: impulse beat
triangular by 5.6 vs 0.9 dB band error; alpha=1.0 tested worse than 0.992; and
ROM pitch codes correlate strongly with measured F0.

**INT2 operand = F confirms** 48 bits/frame, 20 ms/frame, repeat enable, 10 stages.

**The address table at $6F9D** is 4 bytes per phrase: the INT1 byte followed by
ADSET plus five address nibbles, LSB-first. Decoding all sixteen entries
reproduces the MAME phrase table **16/16 exactly** - independent confirmation of
both the address list and the nibble ordering, straight from the game code.

## 4e. Fantasy sound-CPU disassembly (speech port $2400, routine $BE28)

Fantasy uses the identical protocol and an identical 4-byte table (at $BE95),
decoding **12/12** phrase addresses exactly. Two differences from Vanguard:

**1. Fantasy varies INT1 per phrase.** Vanguard sends $44 for all 16 phrases;
Fantasy alternates between two settings:

| INT1 | bit 3 (source) | bit 2 (vocal-tract loss) | phrases |
|---|---|---|---|
| `$44` | 0 = impulse | 1 = **loss ON** (alpha 0.992) | 2, 3, 4, 8, 9, 11 |
| `$48` | 1 = triangular | 0 = **loss OFF** (alpha 1.0) | 0, 1, 5, 6, 7, 10 |

**Bit 2 is confirmed by audio measurement.** Sweeping alpha separately per group
gives opposite optima, exactly as the ROM predicts:

| alpha | group $44 | group $48 |
|---|---|---|
| 0.970 | **2.22 dB** | 2.84 dB |
| 0.992 | 2.55 dB | 2.73 dB |
| 1.000 | 2.71 dB | **2.72 dB** |

This is now implemented: `alpha_for(int1)` in hd38880_decode.py, with the INT1
tables read straight from the game ROMs (`INT1_VAN`, `INT1_FAN`).

**Bit 3 is NOT confirmed.** Every triangular pulse shape tried (falling ramp,
rising ramp, symmetric, exponential, lengths 2-25 samples and period-proportional)
measures worse than a plain impulse on the very phrases whose INT1 says
"triangular" (best symmetric 2.67 dB vs impulse 2.72 dB - within noise; all
others 3.2-5.4 dB). Either MAME's bit-3 label is wrong, or the chip's triangular
source has a shape not yet guessed. **Open question.**

**2. Fantasy sends an explicit STOP.** A separate routine at $BEC5 writes `$A0`
(nibble A = STOP). Vanguard has no such call - consistent with Vanguard's phrases
carrying no amp=63 stop frames while Fantasy's all do.

## 5. Caveats (honest status)

- k3..k10 tables are the least constrained (3-bit fields, weak correlations);
  the ~2 dB formant-contrast gap lives there.
- The 96-bit INT2 mode, the 8-stage mode, SYSPD speed scaling, EXTP A/B live
  pitch bend, and the CONDT/READ/SSTART commands are unmodelled.
- INT2 bit 1 is documented as "repeat enable" and the game DOES set it (INT2=F),
  but no repeat mechanism was ever found in the frame data — still unexplained.
- The DAC (bit depth, any output companding) and the chip's fixed-point
  truncation/saturation behaviour are unmodelled; the reference model is float.
- Nothing has been validated against real hardware AUDIO, only against processed
  recordings. See verify.py for the falsifiable format checks and null control.
  The clock and analog output stage ARE now taken from the SK6 schematic.
- Still fudge, not hardware: VMIX (aspiration noise), UGAIN (unvoiced gain),
  the de-emphasis pole 0.9, and the interpolation schedule.
- Instant-amplitude and interpolation-inhibit are fitted behaviours that match
  the recordings; the silicon's exact interpolator isn't proven. Keep both
  configurable in RTL.
- VMIX and the high-pass model the analog output path and source texture, not
  the digital core — tune against real-cabinet references. VMIX (aspiration
  noise mixed into voiced frames) is NOT documented for this chip; it is an
  empirical addition and should be treated as suspect.
- Reference recordings are the weak link in every fit. They are peak-normalised,
  limited (15.8 dB dynamic range) and coarsely re-quantised. Three separate
  times an optimisation chased those artifacts rather than the chip (crest
  limiter, allpass dispersion, and an RSM that drove noise up to lower MCD).
  Any future tuning needs an unprocessed recording from a real SK6 board.
- Reference WAVs are normalised, limited and coarsely re-quantised: trust them
  for spectrum and timing, not dynamics.
