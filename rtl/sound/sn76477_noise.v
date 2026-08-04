//============================================================================
// sn76477_noise.v   --   SN76477 as used by Vanguard / Fantasy (SNK6502)
//
// SN76477-NOISE-2026-08-03
//
// This is NOT a general SN76477. It models the chip in the ONE configuration
// these boards actually wire it for, which MAME spells out exactly:
//
//   sn76477.set_vco_params(0,0,0);      // VCO      disabled
//   sn76477.set_slf_params(0,0);        // SLF      disabled
//   sn76477.set_oneshot_params(0,0);    // one-shot disabled
//   sn76477.set_attack_params(0,0);     // attack   instant
//   sn76477.set_decay_res(0);           // decay    instant
//   sn76477.set_mixer_params(0,1,0);    // mixer select 010 = NOISE
//
// i.e. a plain NOISE source, gated on/off by the ENABLE pin, through the noise
// filter. Everything else in the chip is switched out, so modelling the full
// SLF/VCO/envelope machinery (as rtl/sound/SN76477.v does, and with ABC80's
// component values at that) would be dead logic here.
//
// ---- Where the numbers come from -------------------------------------------
//
// NOISE CLOCK. MAME's sn76477.cpp compute_noise_gen_freq() carries a table of
// MEASURED resistance -> frequency points. The two resistances these boards use
// are both in it exactly, so no curve fitting is needed:
//
//     470k -> 3081.7 Hz     (Vanguard SHOT A, Fantasy BOMB)
//      10k -> 97493  Hz     (Vanguard SHOT B)
//
// NOISE FILTER. A first-order RC low-pass on the noise bit:
//     Vanguard SHOT A / Fantasy BOMB : R=1.5M, C=220pF
//         tau = 3.3e-4 s -> fc = 1/(2*pi*tau) = 482 Hz   (deep rumble)
//     Vanguard SHOT B                : R=30k,  C=0
//         C=0 -> NO filter at all -> full-bandwidth hiss  (bright zap)
//
// The two together are what make SHOT B a zap and SHOT A / BOMB an explosion:
// a 3.08 kHz LFSR rolled off at 482 Hz is a low rumble, while a 97.5 kHz LFSR
// with no filtering is broadband noise.
//
// The filter runs at ~48 kHz (CLK_HZ/236 = 47.8 kHz) as a 1-pole IIR
// y += (x-y) >> 4. At 47.8 kHz a >>4 pole sits at fc = 47800/(2*pi*16) = 476 Hz,
// versus the 482 Hz the real RC gives - a 1.2% error, so the shift is used
// directly rather than carrying a multiplier.
//
// NOT modelled (deliberate): MAME's noise-filter cap hysteresis (3.35V/0.74V
// thresholds) and the out_pos_gain/out_neg_gain measured output curve. Both
// shape the texture slightly; neither changes which sound this is. Revisit only
// if the character is wrong after HW.
//
// ALIASING NOTE: audio_out updates at the ~48 kHz tick, so the 97.5 kHz (10k)
// leg is sampled below its own rate and aliases. Aliased broadband noise is
// still broadband noise perceptually, so this is accepted rather than adding an
// oversampled path - but it is not a literal 97.5 kHz spectrum. Measured in
// verilator/sn_tb.cpp: that leg shows 23889 sign changes/sec, i.e. pinned at
// Nyquist, versus 1563/sec for the filtered 3.08 kHz leg.
//
// VERIFIED (verilator/sn_tb.cpp, 1 s per config):
//   leg      gate-OFF nonzero   sign changes/s   peak   mean|amp|
//   3082+f   0                  1563             6000   3117   (52% of peak = filtered)
//   97493    0                  23889            3000   2999   (~peak = unfiltered square)
//============================================================================

module sn76477_noise #(
    parameter integer CLK_HZ    = 11_289_000,
    parameter integer NOISE_HZ  = 3082,   // 3082 = 470k leg, 97493 = 10k leg
    parameter         FILTER_EN = 1'b1,   // 0 when the filter cap is absent (C=0)
    parameter integer AMPLITUDE = 6000
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        pause,
    input  wire        gate,      // ENABLE, active high (level, not edge)
    output reg signed [15:0] audio_out
);

    // ---- noise clock divider ------------------------------------------------
    localparam integer NOISE_DIV = CLK_HZ / NOISE_HZ;   // 3663 @3082Hz, 115 @97493Hz
    reg [15:0] ndiv;
    wire       noise_ce = (ndiv == NOISE_DIV[15:0] - 16'd1);

    always @(posedge clk) begin
        if (reset)        ndiv <= 16'd0;
        else if (pause)   ndiv <= ndiv;
        else if (noise_ce) ndiv <= 16'd0;
        else              ndiv <= ndiv + 16'd1;
    end

    // ---- 17-bit maximal LFSR (x^17 + x^14 + 1) ------------------------------
    // The SN76477's internal generator is a long shift register; any maximal
    // sequence is perceptually equivalent for noise. 17 bits = 131071 samples
    // before repeat = ~42 s at 3.08 kHz, long enough never to sound periodic.
    reg [16:0] lfsr;
    always @(posedge clk) begin
        if (reset)                 lfsr <= 17'h1ACE7;   // any nonzero seed
        else if (noise_ce & ~pause) lfsr <= {lfsr[15:0], lfsr[16] ^ lfsr[13]};
    end
    wire noise_bit = lfsr[16];

    // ---- filter tick (~48 kHz) ---------------------------------------------
    localparam integer FILT_DIV = CLK_HZ / 48000;       // 235
    reg [11:0] fdiv;
    wire       filt_ce = (fdiv == FILT_DIV[11:0] - 12'd1);
    always @(posedge clk) begin
        if (reset)        fdiv <= 12'd0;
        else if (pause)   fdiv <= fdiv;
        else if (filt_ce) fdiv <= 12'd0;
        else              fdiv <= fdiv + 12'd1;
    end

    // ---- noise -> +/-AMPLITUDE, optionally low-passed, gated ----------------
    wire signed [15:0] raw = noise_bit ?  $signed(AMPLITUDE[15:0])
                                       : -$signed(AMPLITUDE[15:0]);

    reg signed [15:0] filt;
    always @(posedge clk) begin
        if (reset) begin
            filt      <= 16'sd0;
            audio_out <= 16'sd0;
        end else if (!pause && filt_ce) begin
            // 1-pole IIR: y += (x - y) >> 4
            filt <= filt + ((raw - filt) >>> 4);
            // ENABLE low => chip output is silent; no decay tail, the envelope
            // and one-shot are switched out on these boards.
            audio_out <= ~gate ? 16'sd0
                       : (FILTER_EN ? filt : raw);
        end
    end

endmodule
