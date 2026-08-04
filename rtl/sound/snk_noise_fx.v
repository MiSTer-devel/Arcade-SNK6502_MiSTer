//============================================================================
// snk_noise_fx.v  --  synthesized noise effects for SNK6502 (Vanguard/Fantasy)
//
// SNK-NOISE-FX-2026-08-03   (supersedes sn76477_noise.v)
//
// Everything here is SYNTHESIZED. No sample data is stored or played back.
//
// ---- Why this is fitted to measurements, and where they came from ----------
//
// MAME emulates only ONE of these effects. For Vanguard SHOT A and BOMB it
// plays recordings (`fire.wav`, `explsion.wav`) and never drives the chip:
// `sn76477_1` is constructed with SHOT A's component values but `enable_w()` is
// never called on it, so that configuration produces no audio in MAME and has
// therefore never been validated against anything.
//
// Those recordings ARE of the real board, so they were analysed (spectrum +
// envelope) purely to obtain targets. The WAVs are NOT shipped, NOT in the MRA,
// and NOT read at runtime - they were a measuring instrument only.
//
// MEASURED TARGETS (11025 Hz 8-bit recordings, band energy over the loud window):
//
//   fire.wav (SHOT A), 427 ms
//     1-2k 10.3% | 2-3k 24.6% | 3-4k 38.4% | 4-5.5k 22.1% | <1k only 4.6%
//     => BAND-PASS roughly 2-5.5 kHz. Note this is the OPPOSITE of what MAME's
//        unused sn76477_1 config (470k clock + 1.5M/220pF = 482 Hz low-pass)
//        would give, which is why that config is not used here.
//     envelope (8 slices): .66 .85 .95 1.0 .76 .47 .18 .08
//        => attack ~150 ms, decay ~280 ms
//
//   explsion.wav (Vanguard BOMB), 1156 ms
//     <125 10.0% | 125-250 66.8% | 250-500 17.3% | 500-1k 5.3% | >1k ~0%
//     => NARROW BAND-PASS ~125-250 Hz, peak bin 153 Hz. Needs a high-pass as
//        well as a low-pass: a plain low-pass would peak at DC, but only 10% of
//        the energy sits below 125 Hz.
//     envelope: 1.0 .72 .49 .23 .19 .12 .07 .05  => instant attack, ~1100 ms decay
//
// SHOT B is NOT fitted - MAME genuinely emulates `sn76477_2` (10k noise clock,
// filter cap = 0), so its parameters stay derived from the component values.
// Fantasy BOMB is likewise left component-derived; no recording of it exists
// (fantasy.zip contains only speech), so it remains the one unvalidated leg.
//
// ---- Filters ---------------------------------------------------------------
// One-pole IIR at the ~48 kHz tick: y += (x-y) >> S, corner = 48000/(2*pi*2^S).
//   S=2 -> 1910 Hz   S=3 -> 955 Hz   S=4 -> 477 Hz
//   S=5 ->  239 Hz   S=6 -> 119 Hz   S=7 ->  60 Hz
// LPF output = y. HPF output = x - y (same pole, complementary).
// Setting a shift to 0 disables that stage.
//============================================================================

module snk_noise_fx #(
    parameter integer CLK_HZ    = 11_289_000,
    parameter integer NOISE_HZ  = 12000,  // LFSR rate; sets raw brightness
    parameter integer LPF_SHIFT = 0,      // 0 = bypass
    parameter integer HPF_SHIFT = 0,      // 0 = bypass
    parameter integer HPF2_SHIFT = 0,     // optional 2nd high-pass pole (12 dB/oct)
    parameter integer ATTACK_MS  = 0,     // 0 = instant
    // EXPONENTIAL decay: env -= env>>DECAY_SHIFT each tick, tau = 2^S/48000 s.
    // The recordings decay exponentially (BOMB is at 0.23 by slice 5 where a
    // linear ramp sits at 0.54), so a linear ramp cannot match them.
    //   S=11 -> tau  43 ms    S=12 -> tau  85 ms
    //   S=13 -> tau 171 ms    S=14 -> tau 341 ms
    parameter integer DECAY_SHIFT = 12,
    parameter integer LPF2_SHIFT  = 0,    // optional 2nd low-pass pole (12 dB/oct)
    parameter integer AMPLITUDE = 6000,
    parameter         ONESHOT   = 1'b1    // 1: fire on rising edge, run envelope
                                          // 0: sustain while trig high
)(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire trig,
    output reg signed [15:0] audio_out
);

    // ---- ~48 kHz processing tick -------------------------------------------
    localparam integer FS       = 48000;
    localparam integer FILT_DIV = CLK_HZ / FS;
    reg  [11:0] fdiv;
    wire        tick = (fdiv == FILT_DIV[11:0] - 12'd1);
    always @(posedge clk) begin
        if (reset)      fdiv <= 12'd0;
        else if (pause) fdiv <= fdiv;
        else if (tick)  fdiv <= 12'd0;
        else            fdiv <= fdiv + 12'd1;
    end

    // ---- noise LFSR --------------------------------------------------------
    localparam integer NOISE_DIV = CLK_HZ / NOISE_HZ;
    reg [15:0] ndiv;
    wire       noise_ce = (ndiv == NOISE_DIV[15:0] - 16'd1);
    always @(posedge clk) begin
        if (reset)         ndiv <= 16'd0;
        else if (pause)    ndiv <= ndiv;
        else if (noise_ce) ndiv <= 16'd0;
        else               ndiv <= ndiv + 16'd1;
    end

    reg [16:0] lfsr;
    always @(posedge clk) begin
        if (reset)                  lfsr <= 17'h1ACE7;
        else if (noise_ce & ~pause) lfsr <= {lfsr[15:0], lfsr[16] ^ lfsr[13]};
    end

    // full-scale noise; the envelope scales it later
    wire signed [15:0] raw = lfsr[16] ? 16'sd16384 : -16'sd16384;

    // ---- envelope ----------------------------------------------------------
    // Linear ramp in 1/65536 steps per tick. steps = FS * ms / 1000.
    localparam integer ATK_TICKS = (FS * ATTACK_MS) / 1000;

    localparam integer ATK_STEP  = (ATTACK_MS == 0) ? 65535 : (65535 / ((ATK_TICKS == 0) ? 1 : ATK_TICKS));


    reg [15:0] env;
    reg        trig_d, running;
    wire       trig_rise = trig & ~trig_d;

    always @(posedge clk) begin
        if (reset) begin
            env <= 16'd0; trig_d <= 1'b0; running <= 1'b0;
        end else if (!pause) begin
            trig_d <= trig;
            if (trig_rise) running <= 1'b1;
            // gate mode: releasing trig ends sustain. one-shot: a falling edge
            // also cuts it, matching MAME's samples->stop() on SHOT A release.
            if (~trig) running <= 1'b0;

            if (tick) begin
                if (running) begin
                    // attack toward full scale
                    if (env < 16'hFFFF - ATK_STEP[15:0]) env <= env + ATK_STEP[15:0];
                    else                                 env <= 16'hFFFF;
                end else begin
                    if (ONESHOT) begin
                        // exponential decay
                        // DECAY-STALL-FIX: env>>DECAY_SHIFT truncates to ZERO once
                        // env < 2^DECAY_SHIFT, which froze the envelope at a floor
                        // (measured: BOMB stuck at 0.27 forever). Force a minimum
                        // decrement of 1 LSB so it always reaches silence.
                        if (env > 16'd32) env <= env - ((env >> DECAY_SHIFT) | 16'd1);
                        else              env <= 16'd0;
                    end else begin
                        env <= 16'd0;   // hard gate
                    end
                end
            end
        end
    end

    // ---- filters + output --------------------------------------------------
    reg signed [15:0] lp_hp, lp_hp2, lp_lo, lp_lo2;
    wire signed [15:0] hp_out  = raw    - lp_hp;      // complementary high-pass
    wire signed [15:0] stage0  = (HPF_SHIFT  == 0) ? raw    : hp_out;
    wire signed [15:0] hp_out2 = stage0 - lp_hp2;
    wire signed [15:0] stage1  = (HPF2_SHIFT == 0) ? stage0 : hp_out2;
    wire signed [15:0] stage1b= (LPF_SHIFT  == 0) ? stage1 : lp_lo;
    wire signed [15:0] stage2 = (LPF2_SHIFT == 0) ? stage1b: lp_lo2;

    // env (0..65535) * AMPLITUDE, scaled back down; stage2 is +/-16384 full scale
    wire signed [31:0] scaled = (stage2 * $signed({1'b0, env})) >>> 16;
    wire signed [31:0] outmul = (scaled * AMPLITUDE) >>> 14;

    always @(posedge clk) begin
        if (reset) begin
            lp_hp <= 16'sd0; lp_hp2 <= 16'sd0; lp_lo <= 16'sd0; lp_lo2 <= 16'sd0; audio_out <= 16'sd0;
        end else if (!pause && tick) begin
            if (HPF_SHIFT  != 0) lp_hp  <= lp_hp  + ((raw    - lp_hp ) >>> HPF_SHIFT);
            if (HPF2_SHIFT != 0) lp_hp2 <= lp_hp2 + ((stage0 - lp_hp2) >>> HPF2_SHIFT);
            if (LPF_SHIFT  != 0) lp_lo  <= lp_lo  + ((stage1  - lp_lo ) >>> LPF_SHIFT);
            if (LPF2_SHIFT != 0) lp_lo2 <= lp_lo2 + ((stage1b - lp_lo2) >>> LPF2_SHIFT);
            audio_out <= outmul[15:0];
        end
    end

endmodule
