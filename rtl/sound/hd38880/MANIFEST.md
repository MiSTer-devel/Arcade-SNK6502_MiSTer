# HD38880 / SNK SK-6 speech — package contents

Start with **README.md** (method, findings, integration guide, caveats).

## rtl/            Verilog for the FPGA core
| file | role |
|---|---|
| `hd38880_ctrl.v` | Host command FSM. Decodes the CTP/CMV nibble protocol (confirmed against the games' 6502 code), handles ADSET/START/STOP/INT1/INT2/SYSPD, outputs the 20-bit phrase start address. |
| `hd38880_unpack.v` | Speech-ROM bitstream unpacker. 49-bit frames LSB-first, 6-bit silence frames (amp==0), amp==63 stop marker. Emits one raw parameter frame per 20 ms. |
| `parcor_lattice.v` | 10-stage 2-multiply PARCOR lattice synthesis engine, 8 kHz, time-shared MAC, switchable vocal-tract loss (drive from INT1 bit 2). |

Datapath: `ctrl -> unpack -> decode ROMs (tables JSON, x512 for Q1.9) -> lattice
-> de-emphasis -> 284 Hz HP -> 3288/7234 Hz LP -> DAC`.

## python/         Reference model and tools
| file | role |
|---|---|
| `hd38880_decode.py` | Golden reference decoder + synthesizer for both games. Verify RTL against this. |
| `hd38880_tables_abs.json` | All decode tables: amp[64], pitch[64], k1[16], k2[16], k3..k10[8]. |
| `verify.py` | Independent falsifiable checks of the format claims, **with a null control**. Run this first if you doubt any of it. |
| `hd38880_analyse.py` | Re-derives the frame format from any HD38880 ROM dump (autocorrelation + field profile). |
| `disasm6502.py`, `disasm6502_fantasy.py` | Sound-CPU disassembly that recovered the command sequences and phrase tables. |

## golden/         RTL verification vectors
Per-frame decoded parameters for every phrase in both games
(1002 Vanguard frames, 894 Fantasy frames): phrase, frame, silent, amp,
stopbit, pitch, k1..k10. Your unpacker must reproduce these exactly.

## audio/          90 WAVs, 8 kHz mono
`<game>_ALL_real_vs_synth.wav` plays each phrase as hardware recording, gap,
then synthesis. Per-phrase files under `vanguard/` and `fantasy/`.

## docs/
`hd38880_frame_format.md` — the full research log with all the evidence.

## Status in one line
Frame format: solved and independently verified on two ROM sets. Clock, output
stage, ROM addressing, host protocol and INT1/INT2 modes: taken from hardware
(schematic + game code). Quantiser tables: empirical fits, not silicon values.
Not bit-exact; never validated against a real board.
