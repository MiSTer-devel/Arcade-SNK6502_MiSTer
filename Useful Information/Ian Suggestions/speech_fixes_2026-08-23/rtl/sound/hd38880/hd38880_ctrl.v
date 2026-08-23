//=============================================================================
// hd38880_ctrl.v
//
// Hitachi HD38880 speech synthesizer - host command interface decoder.
// Modelled on MAME's snk6502_speech_w() (audio/snk6502.c), which is the
// authoritative public description of the command protocol as used by
// SNK Vanguard (1981) and Fantasy (1981).
//
// The internal PARCOR synthesis data format is NOT publicly documented, so
// this module decodes the command stream and exposes:
//   - phrase index (matched against the game's ADSET address table)
//   - start/stop strobes for a sample-playback back-end (MAME-style), and
//   - the raw 20-bit address + config registers, for a future true-synthesis
//     back-end if the ROM bit format is ever reverse-engineered.
//
// Confirmed against Vanguard's 6502 code ($6F30 speech routine): the host
// writes each nibble twice - first with CTP=1,CMV=1 (latch), then CTP=0,CMV=1
// (strobe low), with the port cleared to 0 between bytes. Bytes are sent HIGH
// nibble first. Vanguard's per-phrase sequence is:
//     INT1 op=4 ; INT2 op=F ; SYSPD op=9 ; ADSET + 5 addr nibbles ; START
// INT1 op=4 => impulse source, vocal-tract loss ON, external pitch OFF.
//
// Host write port (6 bits, matches SK6 schematic signal names):
//   din[3:0] = SYBS1..SYBS4  (command / data nibble)
//   din[4]   = CTP           (strobe)
//   din[5]   = CMV           (command valid)
// A nibble is latched on a write strobe when CTP & CMV are both set.
//=============================================================================

module hd38880_ctrl #(
    parameter GAME = 0            // 0 = Vanguard, 1 = Fantasy (phrase table)
)(
    input  wire        clk,
    input  wire        rst,

    // Host (sound CPU) interface
    input  wire        wr,        // write strobe, 1 clk wide
    input  wire [5:0]  din,       // {CMV, CTP, SYBS4..SYBS1}

    // Decoded outputs
    output reg         start,     // 1-clk pulse: begin phrase playback
    output reg         stop,      // 1-clk pulse: halt playback
    output reg  [3:0]  phrase,    // phrase index 0..15 (valid with start)
    output reg         phrase_ok, // ADSET address matched the table
    output reg  [19:0] adset_addr,// raw 20-bit speech-ROM start address
    // SPEECH-PHRASE-END-2026-08-23: first byte past the matched phrase, for
    // hd38880_unpack's end-of-phrase bound. Vanguard's ROM has no amp==63
    // stop markers and its host never sends STOP - each phrase is bounded by
    // the next table address (README section 4; last programmed byte $5604).
    // Fantasy normally ends on its amp==63 marker; the bound is a safety net.
    output reg  [19:0] end_addr,  // valid together with start

    // Configuration registers (from INT1 / INT2 / SYSPD)
    output reg  [3:0]  int1_cfg,  // [3] tri(1)/impulse(0) excitation
                                  // [2] "losing effect of vocal tract"
                                  // [1] (with [3]) external pitch enable
    output reg  [3:0]  int2_cfg,  // [3] 48(1)/96(0) bits per frame
                                  // [2] 20(1)/10(0) ms per frame
                                  // [1] repeat enable
                                  // [0] 10(1)/8(0) ops when [3]=1
    output reg  [3:0]  syspd      // speed = (syspd+1)/10
);

    // ---- HD38880 command nibbles -------------------------------------------
    localparam [3:0] CMD_ADSET  = 4'd2,
                     CMD_READ   = 4'd3,
                     CMD_INT1   = 4'd4,
                     CMD_INT2   = 4'd6,
                     CMD_SYSPD  = 4'd8,
                     CMD_STOP   = 4'd10,
                     CMD_CONDT  = 4'd11,
                     CMD_START  = 4'd12,
                     CMD_SSTART = 4'd14;

    // ---- FSM: which multi-nibble command is in progress --------------------
    localparam [2:0] S_IDLE  = 3'd0,
                     S_INT1  = 3'd1,   // expecting 1 operand nibble
                     S_INT2  = 3'd2,   // expecting 1 operand nibble
                     S_SYSPD = 3'd3,   // expecting 1 operand nibble
                     S_ADSET = 3'd4;   // expecting 5 operand nibbles, LSB first

    reg [2:0] state;
    reg [2:0] adset_cnt;

    wire        strobe = wr & din[5] & din[4];   // CMV & CTP
    wire [3:0]  nib    = din[3:0];

    // ---- Phrase start-address tables (from MAME driver) --------------------
    // Vanguard: 16 phrases.  Fantasy: 12 phrases (entries 12..15 unused = 0).
    function [19:0] table_lookup;
        input [3:0] idx;
        begin
            if (GAME == 0) begin // Vanguard
                case (idx)
                    4'h0: table_lookup = 20'h04000;
                    4'h1: table_lookup = 20'h04325;
                    4'h2: table_lookup = 20'h044a2;
                    4'h3: table_lookup = 20'h045b7;
                    4'h4: table_lookup = 20'h046ee;
                    4'h5: table_lookup = 20'h04838;
                    4'h6: table_lookup = 20'h04984;
                    4'h7: table_lookup = 20'h04b01;
                    4'h8: table_lookup = 20'h04c38;
                    4'h9: table_lookup = 20'h04de6;
                    4'ha: table_lookup = 20'h04f43;
                    4'hb: table_lookup = 20'h05048;
                    4'hc: table_lookup = 20'h05160;
                    4'hd: table_lookup = 20'h05289;
                    4'he: table_lookup = 20'h0539e;
                    4'hf: table_lookup = 20'h054ce;
                endcase
            end else begin       // Fantasy
                case (idx)
                    4'h0: table_lookup = 20'h04000;
                    4'h1: table_lookup = 20'h04297;
                    4'h2: table_lookup = 20'h044b6;
                    4'h3: table_lookup = 20'h04682;
                    4'h4: table_lookup = 20'h04927;
                    4'h5: table_lookup = 20'h04be0;
                    4'h6: table_lookup = 20'h04cc2;
                    4'h7: table_lookup = 20'h04e36;
                    4'h8: table_lookup = 20'h05000;
                    4'h9: table_lookup = 20'h05163;
                    4'ha: table_lookup = 20'h052c9;
                    4'hb: table_lookup = 20'h053fd;
                    default: table_lookup = 20'h00000; // unused
                endcase
            end
        end
    endfunction

    // SPEECH-PHRASE-END-2026-08-23: end of phrase idx = start of phrase idx+1.
    // Vanguard's last phrase ends after programmed byte $5604 -> end $5605;
    // Fantasy's last phrase is bounded by the ROM end $57FF -> end $5800.
    function [19:0] end_lookup;
        input [3:0] idx;
        begin
            if (GAME == 0)
                end_lookup = (idx == 4'hf) ? 20'h05605 : table_lookup(idx + 4'd1);
            else
                end_lookup = (idx >= 4'hb) ? 20'h05800 : table_lookup(idx + 4'd1);
        end
    endfunction

    // Combinational address -> phrase-index match
    reg [3:0] match_idx;
    reg       match_hit;
    integer i;
    always @* begin
        match_idx = 4'd0;
        match_hit = 1'b0;
        for (i = 0; i < 16; i = i + 1) begin
            if (!match_hit &&
                table_lookup(i[3:0]) != 20'd0 &&
                table_lookup(i[3:0]) == adset_addr) begin
                match_idx = i[3:0];
                match_hit = 1'b1;
            end
        end
    end

    // ---- Main FSM ----------------------------------------------------------
    always @(posedge clk) begin
        start <= 1'b0;
        stop  <= 1'b0;

        if (rst) begin
            state      <= S_IDLE;
            adset_cnt  <= 3'd0;
            adset_addr <= 20'd0;
            end_addr   <= 20'hFFFFF;   // SPEECH-PHRASE-END-2026-08-23
            int1_cfg   <= 4'd0;
            int2_cfg   <= 4'hf;   // Vanguard/Fantasy default: 48b, 20ms, rpt, 10 ops
            syspd      <= 4'd9;   // 1.0x
            phrase     <= 4'd0;
            phrase_ok  <= 1'b0;
        end
        else if (strobe) begin
            case (state)

            S_IDLE: begin
                case (nib)
                    CMD_ADSET: begin
                        state      <= S_ADSET;
                        adset_cnt  <= 3'd0;
                        adset_addr <= 20'd0;
                    end
                    CMD_INT1:  state <= S_INT1;
                    CMD_INT2:  state <= S_INT2;
                    CMD_SYSPD: state <= S_SYSPD;
                    CMD_START: begin
                        // MAME requires all 5 ADSET nibbles received; here the
                        // FSM guarantees that, so just check the table match.
                        phrase    <= match_idx;
                        phrase_ok <= match_hit;
                        end_addr  <= end_lookup(match_idx); // SPEECH-PHRASE-END-2026-08-23
                        if (match_hit)
                            start <= 1'b1;
                    end
                    CMD_STOP:   stop <= 1'b1;
                    CMD_SSTART: ;     // observed but unused by these games
                    CMD_READ:   ;     // "                                 "
                    CMD_CONDT:  ;     // status/condition poll - not modelled
                    4'd0:       ;     // ignore
                    default:    ;     // unknown command - ignore
                endcase
            end

            // One-operand commands ------------------------------------------
            S_INT1:  begin int1_cfg <= nib; state <= S_IDLE; end
            S_INT2:  begin int2_cfg <= nib; state <= S_IDLE; end
            S_SYSPD: begin syspd    <= nib; state <= S_IDLE; end

            // ADSET: 5 nibbles, LSB-first -> 20-bit address -----------------
            S_ADSET: begin
                adset_addr <= adset_addr | ({16'd0, nib} << (adset_cnt * 4));
                if (adset_cnt == 3'd4)
                    state <= S_IDLE;
                else
                    adset_cnt <= adset_cnt + 3'd1;
            end

            default: state <= S_IDLE;
            endcase
        end
    end

endmodule

//=============================================================================
// Back-end options (not included here):
//
// 1. Sample playback (recommended, MAME-equivalent): on `start`, index a
//    BRAM/SDRAM bank holding the 16 (12) phrase recordings as signed PCM
//    (convert MAME's vg_voi-*.wav / ft_voi-*.wav). Stream at the recording
//    rate, scaled by (syspd+1)/10 if you want SYSPD honoured; kill output on
//    `stop`. Feed EXTP A/B (sound-latch port 1 bits 4-5) into a pitch/rate
//    modifier if you want the external-pitch effect approximated.
//
// 2. True PARCOR synthesis: 10-stage lattice filter (one shared multiplier,
//    ~16-bit fixed point) excited by an impulse or triangular pulse train
//    (int1_cfg[3]) or noise for unvoiced frames, fed by a serial unpacker
//    reading the SK6 EPROM image from adset_addr at 48 bits / 20 ms frame.
//    BLOCKED on the undocumented frame bit layout and quantisation tables -
//    see accompanying notes.
//=============================================================================
