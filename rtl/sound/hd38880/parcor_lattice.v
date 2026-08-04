//=============================================================================
// parcor_lattice.v
//
// PARCOR (partial autocorrelation) lattice speech synthesizer, modelled on the
// documented architecture of the Hitachi HD38880 as described in
// Hitachi Hyoron Vol.63 No.12 (Dec 1981), "Speech Synthesis LSIs".
//
// Documented facts implemented here:
//   - 8 kHz sample rate (125 us per sample)
//   - 2-multiply lattice filter, 8 or 10 stages (selectable, INT2 bit0)
//   - vocal-tract loss: reflected wave scaled by alpha = 0.992 (INT1 bit2)
//   - one time-shared multiplier, 10 bit coefficient x 15 bit data
//     (20 multiply-adds per sample period for 10 stages)
//   - voiced excitation: impulse or triangular wave (INT1 bit3)
//   - unvoiced excitation: M-sequence (maximal-length LFSR)
//   - Amp / Pitch / k1..k10 updated per 20 ms frame, linearly interpolated
//
// This module takes already-decoded parameters. Drive it from hd38880_unpack.v
// via the decode tables in hd38880_tables_abs.json.
//
// HARDWARE-CONFIRMED SINCE THIS FILE WAS FIRST WRITTEN:
//   - 640 kHz crystal on SK-6, /80 -> 8000 Hz sample rate EXACTLY; a 20 ms
//     frame is exactly 160 samples.
//   - Vanguard's 6502 sends INT1=$44 for every phrase: impulse source,
//     vocal-tract loss ON, external pitch off.  Fantasy alternates $44 / $48,
//     i.e. it toggles the loss bit per phrase - drive `loss_en` from INT1 bit 2.
//   - INT2=$F on both games: 48 parameter bits, 20 ms, 10 stages. The 8-stage
//     and 96-bit modes are never exercised and remain unmodelled.
//   - Vanguard's INT1 bit 3 is always 0 (impulse). Fantasy sets it on 6 of 12
//     phrases, but NO triangular pulse shape tried measures better than a plain
//     impulse there, so `tri_src` is left unimplemented pending better evidence.
//
// Output stage (external to the chip, from the SK-6 schematic): 1-pole
// de-emphasis, then C14 0.1uF/R13 5.6K = 284 Hz high-pass, then the LM324
// stages R12 22K/C12 2.2nF = 3288 Hz and R10 22K/C11 1nF = 7234 Hz low-pass.
//
// Fixed point below is a first cut: the real chip's truncation, saturation and
// DAC word length are unknown, so this is NOT yet bit-exact.
//
// Fixed point: coefficients are signed Q1.9 (10 bit, range approx -1..+1),
// filter state is signed 15 bit. Products are >>9.
//=============================================================================

module parcor_lattice #(
    parameter CLK_HZ      = 12_000_000,
    parameter SAMPLE_HZ   = 8_000,
    // SPEECH-ALPHA-OVERFLOW-2026-08-04: was 10'sd508. The "no loss" case below
    // needs the value 512 (= 1.0 in Q9), and 512 DOES NOT FIT IN 10-BIT SIGNED
    // (max 511) - it wrapped to -512, i.e. gain -1.0, inverting the backward
    // wave at every lattice stage. Widened to 11 bits so both branches are
    // representable. Original: parameter ALPHA_Q9 = 10'sd508;
    parameter ALPHA_Q9    = 11'sd508      // 0.992 * 512 = 507.9
)(
    input  wire               clk,
    input  wire               rst,
    input  wire               pause,        // freeze sample-rate divider on MiSTer OSD halt

    // ---- Per-frame parameter input (write one frame, then pulse frame_we) ---
    // Flattened to 10 scalar ports (not an unpacked-array port): this project's
    // Quartus 17.0 / Verilog-2001 elaboration has no precedent anywhere else in
    // the codebase for array-typed module ports, so this avoids an untested
    // synthesis path. Reassembled into a local k_in[] array immediately below
    // so the rest of this module (written against k_in[n]) is unchanged.
    input  wire signed [9:0]  k1_in, k2_in, k3_in, k4_in, k5_in,
                               k6_in, k7_in, k8_in, k9_in, k10_in,
    input  wire        [7:0]  amp_in,       // linear amplitude (post decode ROM)
    input  wire        [7:0]  pitch_in,     // pitch period in samples; 0 = unvoiced
    input  wire               frame_we,     // 1-clk pulse: latch new frame

    // ---- Mode control (from INT1 / INT2 command decode) --------------------
    input  wire               tri_src,      // 1 = triangular, 0 = impulse
    input  wire               loss_en,      // 1 = apply alpha to reflected wave
    input  wire               ten_stage,    // 1 = 10 stages, 0 = 8 stages
    input  wire        [7:0]  ext_pitch,    // EXTP A/B derived pitch offset
    input  wire               ext_pitch_en,

    output reg  signed [14:0] audio_out,
    output reg                audio_stb     // 1-clk pulse at each new sample
);

    // Reassemble the flattened k*_in ports into the array shape the rest of
    // this module (unchanged below) was written against.
    wire signed [9:0] k_in [0:9];
    assign k_in[0]=k1_in; assign k_in[1]=k2_in; assign k_in[2]=k3_in; assign k_in[3]=k4_in;
    assign k_in[4]=k5_in; assign k_in[5]=k6_in; assign k_in[6]=k7_in; assign k_in[7]=k8_in;
    assign k_in[8]=k9_in; assign k_in[9]=k10_in;

    localparam integer DIV = CLK_HZ / SAMPLE_HZ;   // clocks per audio sample

    //-------------------------------------------------------------------------
    // Frame parameter registers + linear interpolation
    //
    // The HD38880 has a "parameter interpolation circuit" that smooths the
    // step change at each frame boundary. Standard practice (and what TI did)
    // is 8 linear sub-steps per frame. At 20 ms / 8 kHz that is 160 samples
    // per frame, i.e. a sub-step every 20 samples.
    //-------------------------------------------------------------------------
    localparam integer SPF     = (SAMPLE_HZ * 20) / 1000;  // samples per 20 ms frame
    localparam integer SUBSTEP = SPF / 8;

    reg signed [9:0] k_tgt  [0:9];   // target (new frame)
    reg signed [9:0] k_cur  [0:9];   // interpolated, in use
    // SPEECH-INTERP-2026-08-04: fixed per-substep delta for TRUE linear interp.
    // 11-bit so (k_in - k_cur) cannot overflow before the >>>3.
    reg signed [10:0] k_step [0:9];
    reg        [7:0] amp_tgt, amp_cur;
    reg        [7:0] pitch_tgt, pitch_cur;

    reg [9:0] samp_cnt;              // sample index within frame
    reg [3:0] interp_idx;

    integer n;

    //-------------------------------------------------------------------------
    // Sample rate divider
    //-------------------------------------------------------------------------
    reg [15:0] div_cnt;
    wire       sample_tick = (div_cnt == DIV-1);

    always @(posedge clk) begin
        if (rst) div_cnt <= 0;
        else if (pause) div_cnt <= div_cnt;  // HALT: freeze sample-rate divider on pause
        else     div_cnt <= sample_tick ? 16'd0 : div_cnt + 16'd1;
    end

    //-------------------------------------------------------------------------
    // Excitation sources
    //   voiced   : programmable counter -> impulse or triangular pulse
    //   unvoiced : M-sequence LFSR (pitch == 0 selects this)
    //-------------------------------------------------------------------------
    reg  [7:0]  pitch_cnt;
    reg  [15:0] lfsr;
    wire        voiced = (pitch_cur != 8'd0);
    wire [7:0]  pitch_eff = ext_pitch_en ? ext_pitch : pitch_cur;

    reg signed [14:0] excite;

    // triangular pulse shape: rises for the first few samples of the period.
    wire [7:0] tri_len = 8'd8;

    // SPEECH-EXCITE-2026-08-04: unvoiced UGAIN = 1.3 (reference), approximated
    // as amp + amp/4 + amp/16 = amp*1.3125. Named wire because Quartus 17.0
    // elaborates .v as Verilog-2001 (no expression bit-select).
    wire [10:0] amp_ugain = {3'd0, amp_cur} + {5'd0, amp_cur[7:2]} + {7'd0, amp_cur[7:4]};

    always @(posedge clk) begin
        if (rst) begin
            pitch_cnt <= 8'd0;
            lfsr      <= 16'hACE1;
            excite    <= 15'sd0;
        end else if (sample_tick) begin
            // M-sequence: x^16 + x^14 + x^13 + x^11 + 1
            lfsr <= {lfsr[14:0], lfsr[15]^lfsr[13]^lfsr[12]^lfsr[10]};

            if (!voiced) begin
                // SPEECH-EXCITE-2026-08-04: reference scales unvoiced excitation
                // by UGAIN = 1.3 (golden/hd38880_decode.py: `e = gg*nz*UGAIN`);
                // this had no such term. amp*1.3125 = amp + amp/4 + amp/16.
                // Original: excite <= lfsr[0] ?  $signed({7'd0, amp_cur})
                //                            : -$signed({7'd0, amp_cur});
                excite <= lfsr[0] ?  $signed({4'd0, amp_ugain})
                                  : -$signed({4'd0, amp_ugain});
            end else begin
                if (pitch_cnt >= pitch_eff - 1) pitch_cnt <= 8'd0;
                else                            pitch_cnt <= pitch_cnt + 8'd1;

                // SPEECH-NOTRI-2026-08-04: the triangular branch is DISABLED.
                //
                // `tri_src` = INT1 bit 3. Fantasy alternates INT1 $44/$48 per
                // phrase (INT1_FAN = 48 48 44 44 44 48 48 48 44 44 48 44), so
                // SIX OF TWELVE phrases were selecting triangular excitation.
                // The reference decoder NEVER uses it — golden/hd38880_decode.py
                // is unconditionally `e = gg*6.0 if pc==0`, with the note that
                // triangular "measures far worse on band-profile error (5.6 vs
                // 0.9 dB), so these games select impulse." That reference is the
                // one the user confirmed BY EAR sounds correct.
                //
                // Measured, Fantasy phrase 0 ($48) vs Fable's raw lattice:
                //   tri_src active  = 0.1529 correlation
                //   impulse (below) = see note; phrase 2 ($44) is 0.5102
                // This is why the first HW build still sounded garbled: phrase 2
                // (a $44/impulse phrase) was the only one validated in sim, so
                // the triangular path was never exercised before hardware.
                //
                // `tri_src` is left as a port (harmless, now unused) rather than
                // ripped out, in case real evidence for the mode ever appears.
                //
                // Original: if (tri_src) begin
                // Original:     if (pitch_cnt < tri_len)
                // Original:         excite <= $signed({7'd0, amp_cur}) -
                // Original:                   $signed({7'd0, amp_cur}) * $signed({1'b0,pitch_cnt[6:0]}) / tri_len;
                // Original:     else
                // Original:         excite <= 15'sd0;
                // Original: end else begin
                begin
                    // SPEECH-EXCITE-2026-08-04: reference impulse height is
                    // `gg*6.0`, not amp<<3 (= x8), and it ADDS aspiration noise
                    // `gg*VMIX*nz` (VMIX = 0.08) on voiced frames because "the
                    // real chip is not purely periodic". Both were missing.
                    //   x6 = (amp<<3) - (amp<<1);  aspiration ~= amp>>4 (0.0625)
                    // Original: excite <= (pitch_cnt == 8'd0) ? $signed({4'd0, amp_cur, 3'd0})
                    //                                         : 15'sd0;
                    excite <= (pitch_cnt == 8'd0)
                        ? ($signed({4'd0, amp_cur, 3'd0}) - $signed({6'd0, amp_cur, 1'd0}))
                          + (lfsr[0] ?  $signed({11'd0, amp_cur[7:4]})
                                     : -$signed({11'd0, amp_cur[7:4]}))
                        : (lfsr[0] ?  $signed({11'd0, amp_cur[7:4]})
                                   : -$signed({11'd0, amp_cur[7:4]}));
                end
            end
        end
    end

    //-------------------------------------------------------------------------
    // Lattice filter, time-shared single multiplier
    //
    //   for m = M down to 1:
    //       f[m-1] = f[m]   - k[m] * (alpha * b[m-1]_delayed)
    //       b[m]   = (alpha * b[m-1]_delayed) + k[m] * f[m-1]
    //   y = f[0];  b[0]_delayed <= f[0]
    //
    // Two multiplies per stage => 20 multiplies for 10 stages, matching the
    // documented "20 multiply-adds per 125 us sample".
    //-------------------------------------------------------------------------
    reg signed [14:0] b_delay [0:9];    // b[m-1] delayed one sample
    reg signed [14:0] f_val;
    reg signed [14:0] b_new  [0:9];

    reg  [4:0] stage;                   // 10..1, 0 = done
    reg  [1:0] phase;
    reg        busy;

    wire signed [9:0]  k_now  = k_cur[stage-1];
    wire signed [14:0] b_raw  = b_delay[stage-1];

    // apply vocal-tract loss to the reflected (backward) wave
    // SPEECH-ALPHA-OVERFLOW-2026-08-04: `10'sd512` wrapped to -512 (10-bit signed
    // maxes at 511), so every INT1=$48 phrase (loss_en=0 => "alpha = 1.0") ran the
    // lattice with a backward-wave gain of MINUS one. All six of Fantasy's $48
    // phrases were garbage on HW; the $44 phrases used ALPHA_Q9=508, which fits,
    // and phrase 2 ($44) is the one that sounded correct.
    // Original: wire signed [25:0] b_loss_p = b_raw * (loss_en ? ALPHA_Q9 : 10'sd512);
    wire signed [25:0] b_loss_p = b_raw * (loss_en ? ALPHA_Q9 : 11'sd512);
    wire signed [14:0] b_loss   = b_loss_p >>> 9;

    wire signed [24:0] p_kb = k_now * b_loss;
    wire signed [24:0] p_kf = k_now * f_val;

    wire [4:0] top_stage = ten_stage ? 5'd10 : 5'd8;

    always @(posedge clk) begin
        audio_stb <= 1'b0;

        if (rst) begin
            busy  <= 1'b0;
            stage <= 5'd0;
            phase <= 2'd0;
            f_val <= 15'sd0;
            for (n = 0; n < 10; n = n + 1) begin
                b_delay[n] <= 15'sd0;
                b_new[n]   <= 15'sd0;
            end
            audio_out <= 15'sd0;
        end
        else if (sample_tick) begin
            f_val <= excite;
            stage <= top_stage;
            phase <= 2'd0;
            busy  <= 1'b1;
        end
        else if (busy) begin
            case (phase)
            2'd0: begin
                // forward recursion
                f_val <= f_val - (p_kb >>> 9);
                phase <= 2'd1;
            end
            2'd1: begin
                // backward recursion (uses the just-updated f_val)
                b_new[stage-1] <= b_loss + (p_kf >>> 9);
                if (stage == 5'd1) begin
                    busy      <= 1'b0;
                    audio_out <= f_val;
                    audio_stb <= 1'b1;
                    // shift the backward delay line for the next sample
                    b_delay[0] <= f_val;
                    for (n = 1; n < 10; n = n + 1)
                        b_delay[n] <= b_new[n-1];
                end else begin
                    stage <= stage - 5'd1;
                end
                phase <= 2'd0;
            end
            default: phase <= 2'd0;
            endcase
        end
    end

    //-------------------------------------------------------------------------
    // Frame latch + LINEAR parameter interpolation
    //
    // SPEECH-INTERP-2026-08-04: this block was the speech defect. Three bugs,
    // all found by diffing against golden/hd38880_decode.py's synth(), which the
    // user CONFIRMED BY EAR sounds correct (its raw lattice output, with no
    // output filter chain at all, is right).
    //
    //  1. NOT ACTUALLY LINEAR. The old code did
    //         cur <= cur + ((tgt - cur) >>> 3)
    //     which moves 1/8 of the REMAINING distance each substep - a geometric
    //     decay. After all 8 substeps it has covered only 1-(7/8)^8 = 66% of the
    //     way, so **the coefficients NEVER REACH the frame's values**. Every
    //     frame was synthesised with k/amp/pitch permanently lagging ~34% of each
    //     step. The reference is true linear (`prev + (tgt-prev)*t`, t = n/8) and
    //     lands exactly on target. Now: precompute a fixed per-substep delta and
    //     SNAP to the target on the final substep so the endpoint is exact.
    //
    //  2. AMPLITUDE AND PITCH MUST NOT BE INTERPOLATED AT ALL. The reference
    //     applies gain immediately (`gg=cur[0]`) and uses the pitch period
    //     directly; its comment notes that interpolating gain "lags the real
    //     envelope on decays and leaves an audible tail after each word".
    //     Interpolating PITCH was worse than cosmetic: `voiced` is derived from
    //     `pitch_cur != 0`, so a voiced<->unvoiced transition GLIDED THROUGH FAKE
    //     INTERMEDIATE PITCHES instead of switching cleanly. Both now load
    //     immediately at frame_we.
    //
    //  3. NO VOICED/UNVOICED INHIBIT. The reference forces t=1.0 for the whole
    //     frame when voicing changes (`vchg`), "so that consonant onsets stay
    //     crisp instead of gliding out of the vowel". Now implemented: on a
    //     voicing change the k's snap straight to target.
    //
    // ORIGINAL BLOCK IS COMMENTED OUT AT THE BOTTOM OF THIS BLOCK - restore it
    // verbatim to revert.
    //-------------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) begin
            samp_cnt   <= 10'd0;
            interp_idx <= 4'd0;
            amp_cur    <= 8'd0;
            amp_tgt    <= 8'd0;
            pitch_cur  <= 8'd0;
            pitch_tgt  <= 8'd0;
            for (n = 0; n < 10; n = n + 1) begin
                k_cur[n]  <= 10'sd0;
                k_tgt[n]  <= 10'sd0;
                k_step[n] <= 11'sd0;
            end
        end
        else begin
            if (frame_we) begin
                // amp + pitch: applied IMMEDIATELY, never interpolated (bug 2).
                amp_cur   <= amp_in;
                amp_tgt   <= amp_in;
                pitch_cur <= pitch_in;
                pitch_tgt <= pitch_in;

                for (n = 0; n < 10; n = n + 1) k_tgt[n] <= k_in[n];

                // voicing change => no k interpolation this frame (bug 3)
                if ((pitch_in == 8'd0) != (pitch_cur == 8'd0)) begin
                    for (n = 0; n < 10; n = n + 1) begin
                        k_cur[n]  <= k_in[n];
                        k_step[n] <= 11'sd0;
                    end
                end
                else begin
                    // fixed per-substep delta = (target - current)/8 (bug 1).
                    // k_step is 11-bit so the subtraction cannot overflow.
                    for (n = 0; n < 10; n = n + 1)
                        k_step[n] <= (k_in[n] - k_cur[n]) >>> 3;
                end

                samp_cnt   <= 10'd0;
                interp_idx <= 4'd0;
            end
            else if (sample_tick) begin
                samp_cnt <= samp_cnt + 10'd1;
                if (samp_cnt % SUBSTEP == 0 && interp_idx < 4'd8) begin
                    if (interp_idx == 4'd7) begin
                        // final substep: land exactly on target, no residue
                        for (n = 0; n < 10; n = n + 1) k_cur[n] <= k_tgt[n];
                    end
                    else begin
                        for (n = 0; n < 10; n = n + 1)
                            k_cur[n] <= k_cur[n] + k_step[n];
                    end
                    interp_idx <= interp_idx + 4'd1;
                end
            end
        end
    end

    // SPEECH-INTERP-2026-08-04 - ORIGINAL BLOCK, uncomment to revert:
    // always @(posedge clk) begin
    //     if (rst) begin
    //         samp_cnt   <= 10'd0;
    //         interp_idx <= 4'd0;
    //         amp_cur    <= 8'd0;
    //         amp_tgt    <= 8'd0;
    //         pitch_cur  <= 8'd0;
    //         pitch_tgt  <= 8'd0;
    //         for (n = 0; n < 10; n = n + 1) begin
    //             k_cur[n] <= 10'sd0;
    //             k_tgt[n] <= 10'sd0;
    //         end
    //     end
    //     else begin
    //         if (frame_we) begin
    //             amp_tgt   <= amp_in;
    //             pitch_tgt <= pitch_in;
    //             for (n = 0; n < 10; n = n + 1) k_tgt[n] <= k_in[n];
    //             samp_cnt   <= 10'd0;
    //             interp_idx <= 4'd0;
    //         end
    //         else if (sample_tick) begin
    //             samp_cnt <= samp_cnt + 10'd1;
    //             if (samp_cnt % SUBSTEP == 0 && interp_idx < 4'd8) begin
    //                 // move 1/8 of the remaining distance toward the target
    //                 amp_cur   <= amp_cur   + ((amp_tgt   - amp_cur)   >>> 3);
    //                 pitch_cur <= pitch_cur + ((pitch_tgt - pitch_cur) >>> 3);
    //                 for (n = 0; n < 10; n = n + 1)
    //                     k_cur[n] <= k_cur[n] + ((k_tgt[n] - k_cur[n]) >>> 3);
    //                 interp_idx <= interp_idx + 4'd1;
    //             end
    //         end
    //     end
    // end

endmodule
