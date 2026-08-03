//=============================================================================
// hd38880_top.v
//
// Glue: hd38880_ctrl (x2, Vanguard + Fantasy phrase tables, muxed by
// game_is_fantasy) -> hd38880_unpack -> hd38880_dectab -> parcor_lattice.
// One shared unpack/decode/lattice pipeline per README section 4 ("the
// format is game-independent"); only the phrase-address table differs
// between games, so only hd38880_ctrl is instanced twice.
//
// Owns:
//   - the external speech-ROM read port (byte-wide, 1-cycle synchronous
//     read; caller provides the BRAM), base-$4000-subtracted to a 13-bit
//     local offset
//   - the 20 ms frame-pacing tick that paces hd38880_unpack -> parcor_lattice
//     handshake (frame_ack / frame_we)
//   - cutting cleanly to silence on STOP / natural phrase end (hd38880_unpack
//     drops into S_DONE with no further frames; without this the lattice
//     would loop the last frame's parameters forever)
//=============================================================================

module hd38880_top #(
    parameter CLK_HZ = 11_289_000   // clk_master, see rtl/snk6502.v
)(
    input  wire        clk,
    input  wire        reset,
    input  wire        pause,

    // Host (sound CPU) interface — top level gates host_wr to only pulse
    // while the active game is Vanguard or Fantasy.
    input  wire         host_wr,
    input  wire  [5:0]  host_din,
    input  wire         game_is_fantasy,

    // Speech ROM read port: external BRAM, 1-cycle synchronous read.
    // Address is already offset so 0 == game address $4000.
    output wire [12:0] rom_addr,
    input  wire [7:0]  rom_data,

    output wire signed [14:0] audio_out
);

    // ---- Command decode: one instance per phrase table, muxed by game -----
    wire        start_vg, stop_vg, phrase_ok_vg;
    wire [19:0] adset_addr_vg;
    wire [3:0]  int1_cfg_vg, int2_cfg_vg, syspd_vg, phrase_vg;

    hd38880_ctrl #(.GAME(0)) ctrl_vanguard (
        .clk(clk), .rst(reset),
        .wr(host_wr), .din(host_din),
        .start(start_vg), .stop(stop_vg),
        .phrase(phrase_vg), .phrase_ok(phrase_ok_vg), .adset_addr(adset_addr_vg),
        .int1_cfg(int1_cfg_vg), .int2_cfg(int2_cfg_vg), .syspd(syspd_vg)
    );

    wire        start_fy, stop_fy, phrase_ok_fy;
    wire [19:0] adset_addr_fy;
    wire [3:0]  int1_cfg_fy, int2_cfg_fy, syspd_fy, phrase_fy;

    hd38880_ctrl #(.GAME(1)) ctrl_fantasy (
        .clk(clk), .rst(reset),
        .wr(host_wr), .din(host_din),
        .start(start_fy), .stop(stop_fy),
        .phrase(phrase_fy), .phrase_ok(phrase_ok_fy), .adset_addr(adset_addr_fy),
        .int1_cfg(int1_cfg_fy), .int2_cfg(int2_cfg_fy), .syspd(syspd_fy)
    );

    // DIAG-REVERT-2026-08-01: REVERTED 2026-08-03. The forced phrase-0 kick is
    // removed and the real muxed signals restored. Verilator bench
    // (verilator/hd38880_tb.cpp, driven by the real $3400 write stream
    // reconstructed from vanguard_maincpu-4000.dasm) confirmed BOTH paths in
    // simulation: the real CPU->ctrl path decodes ADSET $044A2 -> phrase 2,
    // phrase_ok=1, and the forced path the diagnostic used was also sound.
    // The diagnostic had done its job; silence was not a triggering problem.
    wire        ctrl_start     = game_is_fantasy ? start_fy      : start_vg;
    wire [19:0] ctrl_adset     = game_is_fantasy ? adset_addr_fy : adset_addr_vg;
    wire        ctrl_stop      = game_is_fantasy ? stop_fy       : stop_vg;
    wire [3:0]  ctrl_int1      = game_is_fantasy ? int1_cfg_fy   : int1_cfg_vg;
    wire [3:0]  ctrl_int2      = game_is_fantasy ? int2_cfg_fy   : int2_cfg_vg;

    // ---- Bitstream unpacker -------------------------------------------------
    wire        unpack_done;
    wire [19:0] unpack_rom_addr;
    reg         unpack_rom_valid;
    wire        unpack_rom_rd;

    wire        frame_valid;
    reg         frame_ack;
    wire        f_silent;
    wire [5:0]  f_amp, f_pitch;
    wire [6:0]  f_k1;
    wire [4:0]  f_k2;
    wire [2:0]  f_k3, f_k4, f_k5, f_k6, f_k7, f_k8, f_k9, f_k10;

    hd38880_unpack unpack (
        .clk(clk), .rst(reset),
        .start(ctrl_start), .start_addr(ctrl_adset),
        .abort(ctrl_stop), .done(unpack_done),
        .rom_addr(unpack_rom_addr), .rom_data(rom_data),
        .rom_rd(unpack_rom_rd), .rom_valid(unpack_rom_valid),
        .frame_valid(frame_valid), .frame_ack(frame_ack),
        .f_silent(f_silent), .f_amp(f_amp), .f_pitch(f_pitch),
        .f_k1(f_k1), .f_k2(f_k2), .f_k3(f_k3), .f_k4(f_k4), .f_k5(f_k5),
        .f_k6(f_k6), .f_k7(f_k7), .f_k8(f_k8), .f_k9(f_k9), .f_k10(f_k10)
    );

    // BRAM latency glue: rom_valid is rom_rd delayed one clock (see
    // hd38880_unpack.v header). Address is base-$4000-subtracted for the
    // external 8KB BRAM window (see rtl/snk6502.v speech ROM instance).
    always @(posedge clk) unpack_rom_valid <= unpack_rom_rd;

    wire [19:0] rom_addr_rel = unpack_rom_addr - 20'h04000;
    assign rom_addr = rom_addr_rel[12:0];

    // ---- Decode ROM (chip-internal tables, not game data) -------------------
    wire [7:0]        dec_amp, dec_pitch;
    wire signed [9:0] dec_k1, dec_k2, dec_k3, dec_k4, dec_k5,
                       dec_k6, dec_k7, dec_k8, dec_k9, dec_k10;

    hd38880_dectab dectab (
        .amp_code(f_amp), .pitch_code(f_pitch),
        .k1_code(f_k1), .k2_code(f_k2), .k3_code(f_k3), .k4_code(f_k4),
        .k5_code(f_k5), .k6_code(f_k6), .k7_code(f_k7), .k8_code(f_k8),
        .k9_code(f_k9), .k10_code(f_k10),
        .amp_out(dec_amp), .pitch_out(dec_pitch),
        .k1_out(dec_k1), .k2_out(dec_k2), .k3_out(dec_k3), .k4_out(dec_k4),
        .k5_out(dec_k5), .k6_out(dec_k6), .k7_out(dec_k7), .k8_out(dec_k8),
        .k9_out(dec_k9), .k10_out(dec_k10)
    );

    // ---- 20 ms frame pacing --------------------------------------------------
    // hd38880_unpack fills its bit reservoir from ROM far faster than
    // real-time; frame_ack must be paced at the chip's 20 ms/frame rate so
    // parcor_lattice's own 160-samples-per-frame interpolation stays in sync.
    localparam integer FRAME_DIV = (CLK_HZ / 1000) * 20;
    reg [23:0] frame_cnt;
    wire       frame_tick = (frame_cnt == FRAME_DIV - 1);

    always @(posedge clk) begin
        if (reset)      frame_cnt <= 24'd0;
        else if (pause) frame_cnt <= frame_cnt;
        else if (frame_tick) frame_cnt <= 24'd0;
        else            frame_cnt <= frame_cnt + 24'd1;
    end

    reg               frame_we;
    reg  [7:0]         amp_lat, pitch_lat;
    reg  signed [9:0]  k1_lat, k2_lat, k3_lat, k4_lat, k5_lat,
                        k6_lat, k7_lat, k8_lat, k9_lat, k10_lat;
    reg                done_d;

    always @(posedge clk) begin
        frame_ack <= 1'b0;
        frame_we  <= 1'b0;
        done_d    <= unpack_done;

        if (reset) begin
            amp_lat <= 8'd0; pitch_lat <= 8'd0;
            k1_lat <= 10'sd0; k2_lat <= 10'sd0; k3_lat <= 10'sd0; k4_lat <= 10'sd0;
            k5_lat <= 10'sd0; k6_lat <= 10'sd0; k7_lat <= 10'sd0; k8_lat <= 10'sd0;
            k9_lat <= 10'sd0; k10_lat <= 10'sd0;
        end
        else if (!pause && frame_tick && frame_valid) begin
            // normal case: advance unpack to the next frame, latch this one
            frame_ack <= 1'b1;
            frame_we  <= 1'b1;
            amp_lat   <= dec_amp;
            pitch_lat <= dec_pitch;
            k1_lat  <= dec_k1;  k2_lat <= dec_k2;  k3_lat <= dec_k3;  k4_lat <= dec_k4;
            k5_lat  <= dec_k5;  k6_lat <= dec_k6;  k7_lat <= dec_k7;  k8_lat <= dec_k8;
            k9_lat  <= dec_k9;  k10_lat <= dec_k10;
        end
        else if (unpack_done && !done_d) begin
            // phrase ended (STOP marker or host STOP): force a silence frame
            // so the lattice doesn't keep looping the last spoken frame.
            frame_we <= 1'b1;
            amp_lat  <= 8'd0;
        end
    end

    // SPEECH-IDLE-MUTE-2026-08-03: parcor_lattice does NOT settle to zero when a
    // phrase ends. Measured in the Verilator bench (verilator/hd38880_tb.cpp,
    // Vanguard phrase 2): unpack_done asserts exactly at sample 8480 (= 53 frames
    // x 160, correct), but the lattice output then holds a CONSTANT peak of 1408
    // for the rest of the run - flat, no decay, block after block. Its de-emphasis
    // / filter state simply retains its last value with zero excitation.
    //
    // At the old >>>6 mix that residue was 22/32768 (-63 dB, inaudible). After
    // SPEECH-GAIN-2026-08-03 raised the mix 128x it became ~2816/32768 (-21 dB) =
    // the continuous background hum the user reported on Vanguard.
    //
    // Fix here rather than in Fable's DSP: hold output at silence unless a phrase
    // is actually playing. The real chip emits nothing when stopped, so this is
    // also the faithful behaviour.
    reg speaking;
    always @(posedge clk) begin
        if (reset)                          speaking <= 1'b0;
        else if (ctrl_start)                speaking <= 1'b1;
        else if (unpack_done || ctrl_stop)  speaking <= 1'b0;
    end

    wire signed [14:0] lattice_audio;
    assign audio_out = speaking ? lattice_audio : 15'sd0;

    parcor_lattice #(.CLK_HZ(CLK_HZ)) lattice (
        .clk(clk), .rst(reset), .pause(pause),
        .k1_in(k1_lat),  .k2_in(k2_lat),  .k3_in(k3_lat),  .k4_in(k4_lat),  .k5_in(k5_lat),
        .k6_in(k6_lat),  .k7_in(k7_lat),  .k8_in(k8_lat),  .k9_in(k9_lat), .k10_in(k10_lat),
        .amp_in(amp_lat), .pitch_in(pitch_lat), .frame_we(frame_we),
        .tri_src(ctrl_int1[3]), .loss_en(ctrl_int1[2]), .ten_stage(ctrl_int2[0]),
        .ext_pitch(8'd0), .ext_pitch_en(1'b0),
        .audio_out(lattice_audio), .audio_stb()
    );

endmodule
