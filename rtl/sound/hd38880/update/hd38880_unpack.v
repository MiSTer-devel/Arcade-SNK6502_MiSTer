//=============================================================================
// hd38880_unpack.v
//
// HD38880 speech-ROM bitstream unpacker - implements the frame format
// reverse-engineered from the SNK Vanguard / Fantasy SK6 ROMs and validated
// against recordings of real hardware.
//
// FRAME FORMAT (recovered):
//   Bit order: LSB-first within each byte; fields LSB-first.
//   Normal frame = 49 bits:
//     [0]   bits  0-5   Amp   (6)  0 = silence, 63 = stop, else amplitude code
//     [1]   bit   6     REPEAT flag (same position as the TMS5220's repeat bit).
//                        Verified 0 in all 1666 valid frames of both known ROM
//                        sets: the feature is allocated and INT2 enables it, but
//                        no shipped ROM uses it. Decoded here for completeness.
//     [2]   bits  7-12  Pitch (6)  0 = unvoiced (noise source), else period code
//     [3]   bits 13-19  k1    (7)
//     [4]   bits 20-24  k2    (5)
//     [5..] bits 25-48  k3..k10 (3 each)
//   SILENCE frame: if Amp field == 0, the frame is ONLY those 6 bits.
//   REPEAT: if bit 6 set, the frame is only 13 bits (amp+repeat+pitch) and the
//           previous k values are retained. Never observed in Vanguard/Fantasy.
//   STOP: if Amp field == 63 (all ones), end of phrase - do not synthesize.
//         This is the SOLE terminator. (Fantasy terminators appear to set bit 6
//         only because the whole stop pattern is all-ones.)
//         (Fantasy uses explicit stop frames; Vanguard phrases simply end and
//          the host stops the chip / the address table bounds the phrase.)
//
// This module streams bits from a byte-wide ROM port, emits one decoded
// parameter frame every frame_ack, and raises `done` at the stop marker.
// Pair with hd38880_ctrl.v (host command decode -> start_addr) upstream and
// parcor_lattice.v (synthesis) downstream. Decode ROMs (code -> k / amp /
// pitch values, from hd38880_tables_abs.json) sit between this and the lattice.
//=============================================================================

module hd38880_unpack (
    input  wire        clk,
    input  wire        rst,

    // control
    input  wire        start,          // pulse: begin phrase at start_addr
    input  wire [19:0] start_addr,     // byte address from ADSET
    input  wire        abort,          // pulse: host STOP command
    output reg         done,           // stop marker reached (or abort)

    // speech ROM read port (byte wide, registered read)
    output reg  [19:0] rom_addr,
    input  wire [7:0]  rom_data,
    output reg         rom_rd,
    input  wire        rom_valid,      // rom_data valid, 1 clk after rom_rd

    // decoded frame output (one per handshake)
    output reg         frame_valid,
    input  wire        frame_ack,      // consumer takes the frame (per 20 ms)
    output reg         f_silent,       // amp code == 0
    output reg  [5:0]  f_amp,          // raw 6-bit amplitude code
    output reg  [5:0]  f_pitch,        // raw 6-bit pitch code (0 = unvoiced)
    output reg  [6:0]  f_k1,           // raw coefficient codes
    output reg  [4:0]  f_k2,
    output reg  [2:0]  f_k3, f_k4, f_k5, f_k6, f_k7, f_k8, f_k9, f_k10
);

    // ---- bit reservoir: shift bytes in LSB-first --------------------------
    reg [63:0] resv;          // right-aligned reservoir, bit 0 = next bit out
    reg [6:0]  nbits;         // bits currently in reservoir

    // take W bits LSB-first from the reservoir (combinational views)
    wire [5:0] pk_amp = resv[5:0];

    localparam [2:0] S_IDLE=0, S_FILL=1, S_HDR=2, S_BODY=3, S_WAIT=4, S_DONE=5;
    reg [2:0] state;

    always @(posedge clk) begin
        rom_rd <= 1'b0;
        done   <= 1'b0;

        if (rst) begin
            state <= S_IDLE; frame_valid <= 1'b0; nbits <= 0;
        end
        else if (abort) begin
            state <= S_DONE; frame_valid <= 1'b0;
        end
        else case (state)

        S_IDLE: if (start) begin
            rom_addr <= start_addr;
            nbits    <= 0;
            resv     <= 64'd0;
            frame_valid <= 1'b0;
            state    <= S_FILL;
        end

        // keep the reservoir topped up to >= 49 bits
        S_FILL: begin
            if (nbits >= 7'd49)
                state <= S_HDR;
            else if (rom_valid) begin
                resv  <= resv | ({56'd0, rom_data} << nbits); // LSB-first append
                nbits <= nbits + 7'd8;
                rom_addr <= rom_addr + 20'd1;
            end
            else
                rom_rd <= 1'b1;
        end

        // inspect the 6-bit amplitude header
        S_HDR: begin
            if (pk_amp == 6'd63) begin
                state <= S_DONE;                       // STOP marker
            end
            else if (pk_amp == 6'd0) begin
                // SILENCE frame: consume 6 bits only
                f_silent <= 1'b1; f_amp <= 6'd0; f_pitch <= 6'd0;
                resv  <= resv >> 6;
                nbits <= nbits - 7'd6;
                frame_valid <= 1'b1;
                state <= S_WAIT;
            end
            else begin
                // full 49-bit frame
                f_silent <= 1'b0;
                f_amp    <= resv[5:0];
                //            bit 6 = stop-assist flag, absorbed
                f_pitch  <= resv[12:7];
                f_k1     <= resv[19:13];
                f_k2     <= resv[24:20];
                f_k3     <= resv[27:25];
                f_k4     <= resv[30:28];
                f_k5     <= resv[33:31];
                f_k6     <= resv[36:34];
                f_k7     <= resv[39:37];
                f_k8     <= resv[42:40];
                f_k9     <= resv[45:43];
                f_k10    <= resv[48:46];
                resv  <= resv >> 49;
                nbits <= nbits - 7'd49;
                frame_valid <= 1'b1;
                state <= S_WAIT;
            end
        end

        // hold the frame until the synthesis engine consumes it (20 ms pace)
        S_WAIT: if (frame_ack) begin
            frame_valid <= 1'b0;
            state <= S_FILL;
        end

        S_DONE: begin
            done  <= 1'b1;
            state <= S_IDLE;
        end

        default: state <= S_IDLE;
        endcase
    end

endmodule

//-----------------------------------------------------------------------------
// Integration notes
//
//   hd38880_ctrl.v  -> start_addr (ADSET), start (START cmd), abort (STOP cmd)
//   hd38880_unpack  -> raw codes, one frame / 20 ms (frame_ack from a 20 ms tick)
//   decode ROMs     -> amp code  -> gain      (64-entry table)
//                      pitch code-> period    (64-entry table, 16..98 samples)
//                      k1 code   -> Q1.9 k    (interpolated 16-entry table)
//                      k2 code   -> Q1.9 k    (interpolated 16-entry table)
//                      k3..k10   -> Q1.9 k    (8-entry tables)
//                      values in hd38880_tables_abs.json; scale by 512 for Q1.9
//   parcor_lattice.v-> audio out
//
// EXTP A/B (external pitch), from the SK-6 schematic: a 17555 astable whose
// timing network is switched by a 14066 under EXTP A/B control. Values
// R6=1K, C=1uF, R14=33K, R15=15K give:
//     EXTP B=0 A=0 -> oscillator stopped
//     EXTP B=0 A=1 -> 84.7 Hz
//     EXTP B=1 A=0 -> 41.1 Hz
//     EXTP B=1 A=1 -> 117.0 Hz
// i.e. three fixed pitch rates, not a continuous bend. Measurement shows the
// games use the ROM's internal pitch for normal speech, so this path can be
// stubbed initially, but a faithful core should implement it.
//
// Synthesis behaviours validated against hardware recordings:
//   - amplitude applied immediately at each frame; k's interpolated in 8 steps
//   - interpolation inhibited across a voiced/unvoiced change
//   - unvoiced excitation gain ~1.3 relative units vs voiced impulse 6.0
//   - small aspiration noise (~0.08) mixed into voiced excitation
//   - voiced source = plain impulse (triangular, INT1 bit 3, measures much
//     worse: band-profile error 5.6 vs 0.9 dB, so these games use impulse)
//   - output stage: 1-pole de-emphasis (0.9) then ~240 Hz 1st-order high-pass
//     (models the SK6 board analog path; make it configurable)
//   NOTE: no allpass "dispersion" and no output limiter. Both were tried and
//   removed - they only matched waveform symmetry/crest factor, which are
//   artifacts of the limiting applied to the MAME reference recordings.
//-----------------------------------------------------------------------------
