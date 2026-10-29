//============================================================================
//
//  SNK6502 — board top (dispatcher)
//  Copyright (C) 2026 Rodimus
//
//  Pools (CPU / sound chip, ROM, RAM) live here; the board (rtl/boards/snk6502_board.sv) drives them through bus
//  ports (Projects/Arcade-Konami82_MiSTer/Claude/chip_pool_convention.md). Boards never instantiate their own CPU /
//  sound chip / ROM / RAM.
//
//  One board family so far, every game (game_id = MRA index 1 byte 0; MAME snk/snk6502.cpp):
//    0 Sasuke vs. Commander   1 Satan of Saturn / Zarzon   2 Vanguard   3 Fantasy   4 Pioneer Balloon   5 Nibbler
//  Clocks: clk_master = 11.289 MHz (CPU, video, sound), clk_sys = the ROM download clock.
//
//============================================================================

module snk6502_dispatcher
(
    input  logic        clk_master,
    input  logic        clk_sys,
    input  logic        reset,
    input  logic        pause,
    input  logic        crt_flip,
    output logic        ce_pix,

    input  logic  [3:0] game_id,

    input  logic  [7:0] p1,             // {btn4, btn3, btn2, btn1, up, down, left, right}, active high
    input  logic  [7:0] p2,
    input  logic  [3:0] p1_rstick,      // {U, D, L, R}
    input  logic  [3:0] sys_ctl,        // {start2, start1, coin2, coin1}
    input  logic  [7:0] dsw,

    input  logic [16:0] dn_addr,        // ROM download (ioctl index 0), clk_sys
    input  logic  [7:0] dn_data,
    input  logic        dn_wr,

    output logic  [7:0] rgb_r,
    output logic  [7:0] rgb_g,
    output logic  [7:0] rgb_b,
    output logic        hsync,
    output logic        vsync,
    output logic        hblank,
    output logic        vblank,

    output logic [15:0] audio,
    output logic        flip_screen
);

/////////////////////////////  Shared CPU / sound chip pool  /////////////////////////////

// 6502 core (stock T65, Mode 00):
// t65_0: every game's main CPU. res_n on the bus: the board holds the CPU in reset 16 clocks past the core reset.
chip_pool_pkg::t65_i_t t65_0_i;
chip_pool_pkg::t65_o_t t65_0_o;

wire [23:0] t65_0_a24;
wire        t65_0_sync;                                // opcode fetch (Verilator harness cpu_m1)
/* verilator lint_off PINCONNECTEMPTY */
T65 t65_0
(
    .Mode(2'b00), .Res_n(t65_0_i.res_n), .Enable(t65_0_i.enable), .Clk(clk_master), .Rdy(t65_0_i.rdy),
    .Abort_n(1'b1), .IRQ_n(t65_0_i.irq_n), .NMI_n(t65_0_i.nmi_n), .SO_n(1'b1), .R_W_n(t65_0_o.rw), .Sync(t65_0_sync),
    .EF(), .MF(), .XF(), .ML_n(), .VP_n(), .VDA(), .VPA(), .A(t65_0_a24), .DI(t65_0_i.di), .DO(t65_0_o.dout), .Regs(),
    .NMI_ack()
);
/* verilator lint_on PINCONNECTEMPTY */
assign t65_0_o.a = t65_0_a24[15:0];

// MC6845 CRTC (rtl/video/mc6845.vhd):
// mc6845_0: every game's video timing / tilemap address. reset_n on the bus (the board's CPU reset).
chip_pool_pkg::mc6845_i_t mc6845_0_i;
chip_pool_pkg::mc6845_o_t mc6845_0_o;

wire  [7:0] mc6845_0_do;
wire        mc6845_0_vs, mc6845_0_hs, mc6845_0_vbl, mc6845_0_hbl, mc6845_0_de;
wire [13:0] mc6845_0_ma;
wire  [4:0] mc6845_0_ra;

mc6845 mc6845_0
(
    .CLOCK(clk_master), .CLKEN(mc6845_0_i.clken), .nRESET(mc6845_0_i.reset_n),
    .ENABLE(mc6845_0_i.enable), .R_nW(mc6845_0_i.r_nw), .RS(mc6845_0_i.rs), .DI(mc6845_0_i.di), .DO(mc6845_0_do),
    .VSYNC(mc6845_0_vs), .HSYNC(mc6845_0_hs), .VBLANK(mc6845_0_vbl), .HBLANK(mc6845_0_hbl), .DE(mc6845_0_de),
    .CURSOR(), .LPSTB(1'b0), .MA(mc6845_0_ma), .RA(mc6845_0_ra)
);

assign mc6845_0_o.dout = mc6845_0_do;      assign mc6845_0_o.vsync = mc6845_0_vs;   assign mc6845_0_o.hsync = mc6845_0_hs;
assign mc6845_0_o.vblank = mc6845_0_vbl;   assign mc6845_0_o.hblank = mc6845_0_hbl; assign mc6845_0_o.de = mc6845_0_de;
assign mc6845_0_o.ma = mc6845_0_ma;        assign mc6845_0_o.ra = mc6845_0_ra;

// HD38880 speech synthesizer (rtl/sound/hd38880/, ours):
// hd38880_0: Vanguard / Fantasy speech (the other games never write its host port).
chip_pool_pkg::hd38880_i_t hd38880_0_i;
chip_pool_pkg::hd38880_o_t hd38880_0_o;

wire signed [14:0] hd38880_0_audio;
wire [12:0]        hd38880_0_rom_addr;

hd38880_top #(.CLK_HZ(11_289_000)) hd38880_0
(
    .clk(clk_master), .reset(reset), .pause(pause),
    .host_wr(hd38880_0_i.host_wr), .host_din(hd38880_0_i.host_din), .game_is_fantasy(hd38880_0_i.game_is_fantasy),
    .rom_addr(hd38880_0_rom_addr), .rom_data(hd38880_0_i.rom_data), .audio_out(hd38880_0_audio)
);

assign hd38880_0_o.rom_addr = hd38880_0_rom_addr;
assign hd38880_0_o.audio    = hd38880_0_audio;

// SN76477 noise legs (rtl/sound/sn76477_noise.v, ours), part values per slot:
// sn76477_noise_0: 470k noise clock (3081.7 Hz) + 1.5M / 220pF filter: Vanguard SHOT A, Fantasy BOMB
// sn76477_noise_1: 10k noise clock (97493 Hz), no filter cap: Vanguard SHOT B (routed at half SHOT A's level)
chip_pool_pkg::sn76477_noise_i_t sn76477_noise_0_i, sn76477_noise_1_i;
chip_pool_pkg::sn76477_noise_o_t sn76477_noise_0_o, sn76477_noise_1_o;

wire signed [15:0] sn76477_noise_0_audio, sn76477_noise_1_audio;

sn76477_noise #(.CLK_HZ(11_289_000), .NOISE_HZ(3082), .FILTER_EN(1'b1), .AMPLITUDE(6000)) sn76477_noise_0
(
    .clk(clk_master), .reset(reset), .pause(pause), .gate(sn76477_noise_0_i.gate), .audio_out(sn76477_noise_0_audio)
);

sn76477_noise #(.CLK_HZ(11_289_000), .NOISE_HZ(97493), .FILTER_EN(1'b0), .AMPLITUDE(3000)) sn76477_noise_1
(
    .clk(clk_master), .reset(reset), .pause(pause), .gate(sn76477_noise_1_i.gate), .audio_out(sn76477_noise_1_audio)
);

assign sn76477_noise_0_o.audio = sn76477_noise_0_audio;
assign sn76477_noise_1_o.audio = sn76477_noise_1_audio;

/////////////////////////////  Shared ROM blocks  /////////////////////////////

// ioctl index 0 (MRA layout; load decode never depends on game_id):
//   $00000-$0FFFF maincpu (64K, sparse)   -> rom0        $10000-$10FFF gfx plane 0 -> rom1
//   $11000-$11FFF gfx plane 1             -> rom2        $12000-$1203F colour PROMs -> rom3
//   $12040-$137FF sound ROM (6K)          -> rom4 (at 0) $14000-$157FF speech ROM (HD38880 PARCOR data) -> rom5
// Port A = the download (clk_sys), port B = the board's reader (clk_master, one clock to data).
wire dn_maincpu = (dn_addr[16:16] == 1'b0);                    // $00000-$0FFFF
wire dn_gfx1    = (dn_addr[16:13] == 4'b1_000);                // $10000-$11FFF
wire dn_proms   = (dn_addr[16:6]  == 11'b1_0010_0000_00);      // $12000-$1203F
wire dn_sndrom  = (dn_addr[16:13] == 4'b1_001) & ~dn_proms;    // $12040-$13FFF
wire dn_speech  = (dn_addr[16:13] == 4'b1_010);                // $14000-$15FFF

wire [15:0] rom0_a;  wire [7:0] rom0_d;
wire [11:0] rom1_a;  wire [7:0] rom1_d;
wire [11:0] rom2_a;  wire [7:0] rom2_d;
wire  [5:0] rom3_a;  wire [7:0] rom3_d;
wire [12:0] rom4_a;  wire [7:0] rom4_d;
wire [12:0] rom5_a;  wire [7:0] rom5_d;

dpram_dc #(.widthad_a(16)) rom0
(
    .clock_a(clk_sys), .address_a(dn_addr[15:0]), .data_a(dn_data), .wren_a(dn_wr & dn_maincpu), .q_a(),
    .clock_b(clk_master), .address_b(rom0_a), .data_b(8'd0), .wren_b(1'b0), .q_b(rom0_d)
);

dpram_dc #(.widthad_a(12)) rom1
(
    .clock_a(clk_sys), .address_a(dn_addr[11:0]), .data_a(dn_data), .wren_a(dn_wr & dn_gfx1 & ~dn_addr[12]), .q_a(),
    .clock_b(clk_master), .address_b(rom1_a), .data_b(8'd0), .wren_b(1'b0), .q_b(rom1_d)
);

dpram_dc #(.widthad_a(12)) rom2
(
    .clock_a(clk_sys), .address_a(dn_addr[11:0]), .data_a(dn_data), .wren_a(dn_wr & dn_gfx1 & dn_addr[12]), .q_a(),
    .clock_b(clk_master), .address_b(rom2_a), .data_b(8'd0), .wren_b(1'b0), .q_b(rom2_d)
);

dpram_dc #(.widthad_a(6)) rom3
(
    .clock_a(clk_sys), .address_a(dn_addr[5:0]), .data_a(dn_data), .wren_a(dn_wr & dn_proms), .q_a(),
    .clock_b(clk_master), .address_b(rom3_a), .data_b(8'd0), .wren_b(1'b0), .q_b(rom3_d)
);

dpram_dc #(.widthad_a(13)) rom4
(
    .clock_a(clk_sys), .address_a(dn_addr[12:0] - 13'h040), .data_a(dn_data), .wren_a(dn_wr & dn_sndrom), .q_a(),
    .clock_b(clk_master), .address_b(rom4_a), .data_b(8'd0), .wren_b(1'b0), .q_b(rom4_d)
);

dpram_dc #(.widthad_a(13)) rom5
(
    .clock_a(clk_sys), .address_a(dn_addr[12:0]), .data_a(dn_data), .wren_a(dn_wr & dn_speech), .q_a(),
    .clock_b(clk_master), .address_b(rom5_a), .data_b(8'd0), .wren_b(1'b0), .q_b(rom5_d)
);

/////////////////////////////  Shared RAM pool  /////////////////////////////

// ram_pool_pkg buses: block n = pool_i[n] / pool_o[n], two read / write ports, one clock to q (dpram_dc).
// Port A = CPU, port B = video. Every game has the same map ($0000-$1FFF):
//   block 0  1K  work RAM                     $0000-$03FF (port B unused)
//   block 1  1K  video RAM 2 (FG tilemap)     $0400-$07FF
//   block 2  1K  video RAM 1 (BG tilemap)     $0800-$0BFF
//   block 3  1K  colour RAM, FG copy          $0C00-$0FFF (CPU reads back this copy)
//   block 4  1K  colour RAM, BG copy          $0C00-$0FFF (same CPU writes; the scrolled BG reads it)
//   block 5  2K  character RAM plane 0        $1000-$17FF
//   block 6  2K  character RAM plane 1        $1800-$1FFF
localparam int RAM_BLOCKS = 7;
function automatic int ram_aw(input int n);           // block address width
    case (n)
        5, 6:    ram_aw = 11;
        default: ram_aw = 10;
    endcase
endfunction

ram_pool_pkg::pram_i_t [RAM_BLOCKS-1:0] snk_pr_i, pool_i;
ram_pool_pkg::pram_o_t [RAM_BLOCKS-1:0] pool_o;
assign pool_i = snk_pr_i;                              // one board family so far
genvar n;                                              // Quartus 17: no genvar declared in the for header
generate
    for (n = 0; n < RAM_BLOCKS; n++) begin : rpool
        dpram_dc #(.widthad_a(ram_aw(n))) ram
        (
            .clock_a(clk_master), .address_a(pool_i[n].a_addr[ram_aw(n)-1:0]), .data_a(pool_i[n].a_d),
            .wren_a(pool_i[n].a_we), .q_a(pool_o[n].a_q),
            .clock_b(clk_master), .address_b(pool_i[n].b_addr[ram_aw(n)-1:0]), .data_b(pool_i[n].b_d),
            .wren_b(pool_i[n].b_we), .q_b(pool_o[n].b_q)
        );
    end
endgenerate

// Pooled multipliers: none.

/////////////////////////////  Boards  /////////////////////////////

// SNK6502 board (every game; game_id gates inside). Pool inputs from the board: <board>_<chip>_<n>_i, selected by
// variant (one board family so far, so the mux is the SNK6502 board alone); pool outputs fan out unmuxed.
chip_pool_pkg::t65_i_t           snk_t65_0_i;
chip_pool_pkg::mc6845_i_t        snk_mc6845_0_i;
chip_pool_pkg::hd38880_i_t       snk_hd38880_0_i;
chip_pool_pkg::sn76477_noise_i_t snk_sn76477_noise_0_i, snk_sn76477_noise_1_i;
assign t65_0_i           = snk_t65_0_i;
assign mc6845_0_i        = snk_mc6845_0_i;
assign hd38880_0_i       = snk_hd38880_0_i;
assign sn76477_noise_0_i = snk_sn76477_noise_0_i;
assign sn76477_noise_1_i = snk_sn76477_noise_1_i;

snk6502_board snk
(
    .clk_master(clk_master), .reset(reset), .pause(pause), .crt_flip(crt_flip), .ce_pix(ce_pix),
    .game_id(game_id), .p1(p1), .p2(p2), .p1_rstick(p1_rstick), .sys_ctl(sys_ctl), .dsw(dsw),
    .rgb_r(rgb_r), .rgb_g(rgb_g), .rgb_b(rgb_b), .hsync(hsync), .vsync(vsync), .hblank(hblank), .vblank(vblank),
    .audio(audio), .flip_screen(flip_screen),
    .t65_0_i(snk_t65_0_i), .t65_0_o(t65_0_o), .mc6845_0_i(snk_mc6845_0_i), .mc6845_0_o(mc6845_0_o),
    .hd38880_0_i(snk_hd38880_0_i), .hd38880_0_o(hd38880_0_o),
    .sn76477_noise_0_i(snk_sn76477_noise_0_i), .sn76477_noise_0_o(sn76477_noise_0_o),
    .sn76477_noise_1_i(snk_sn76477_noise_1_i), .sn76477_noise_1_o(sn76477_noise_1_o),
    .rom0_a(rom0_a), .rom0_d(rom0_d), .rom1_a(rom1_a), .rom1_d(rom1_d), .rom2_a(rom2_a), .rom2_d(rom2_d),
    .rom3_a(rom3_a), .rom3_d(rom3_d), .rom4_a(rom4_a), .rom4_d(rom4_d), .rom5_a(rom5_a), .rom5_d(rom5_d),
    .pr_i(snk_pr_i), .pr_o(pool_o)
);

/* verilator lint_off UNUSED */
wire unused_ok = &{1'b0, t65_0_a24[23:16], t65_0_sync};
/* verilator lint_on UNUSED */

endmodule
