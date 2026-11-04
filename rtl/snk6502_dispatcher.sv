//  Copyright (C) 2026 Rodimus

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
    input  logic  [3:0] vol_music,      // OSD Game Audio: 8 = unity, 0 = off, 15 = loudest
    input  logic  [3:0] vol_sfx,
    input  logic  [3:0] vol_speech,
    input  logic [15:0] ds_caps,        // dsnd source bytes 7:6 (Game Audio caps)
    input  logic  [3:0] h_adj,          // OSD H / V Position (CRT)
    input  logic  [3:0] v_adj,

    input  logic [16:0] dn_addr,
    input  logic  [7:0] dn_data,
    input  logic        dn_wr,
    input  logic        snd_prog_wr,    // MRA index 5 byte (dn_addr / dn_data), clk_sys
    input  logic        snd_prog_on,    // an index-5 program is loaded for this game

    input  logic [15:0] hs_address,     // hiscore (clk_sys): work RAM block 0, port B
    input  logic  [7:0] hs_data_in,
    output logic  [7:0] hs_data_out,
    input  logic        hs_write,

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

// t65_0: every game's main CPU. res_n on the bus: the board holds the CPU in reset 16 clocks past the core reset.
chip_pool_pkg::t65_i_t t65_0_i;
chip_pool_pkg::t65_o_t t65_0_o;

wire [23:0] t65_0_a24;
wire        t65_0_sync;
/* verilator lint_off PINCONNECTEMPTY */
t65sv_T65 t65_0
(
    .Mode(2'b00), .Res_n(t65_0_i.res_n), .Enable(t65_0_i.enable), .Clk(clk_master), .Rdy(t65_0_i.rdy),
    .Abort_n(1'b1), .IRQ_n(t65_0_i.irq_n), .NMI_n(t65_0_i.nmi_n), .SO_n(1'b1), .R_W_n(t65_0_o.rw), .Sync(t65_0_sync),
    .EF(), .MF(), .XF(), .ML_n(), .VP_n(), .VDA(), .VPA(), .A(t65_0_a24), .DI(t65_0_i.di), .DO(t65_0_o.dout), .Regs(),
    .NMI_ack()
);
/* verilator lint_on PINCONNECTEMPTY */
assign t65_0_o.a = t65_0_a24[15:0];
assign t65_0_o.sync = t65_0_sync;

// mc6845_0: every game's video timing / tilemap address. reset_n on the bus (the board's CPU reset).
chip_pool_pkg::mc6845_i_t mc6845_0_i;
chip_pool_pkg::mc6845_o_t mc6845_0_o;

wire  [7:0] mc6845_0_do;
wire        mc6845_0_vs, mc6845_0_hs, mc6845_0_vbl, mc6845_0_hbl, mc6845_0_de;
wire [13:0] mc6845_0_ma;
wire  [4:0] mc6845_0_ra;

crtc6845sv_mc6845 mc6845_0
(
    .CLOCK(clk_master), .CLKEN(mc6845_0_i.clken), .nRESET(mc6845_0_i.reset_n),
    .ENABLE(mc6845_0_i.enable), .R_nW(mc6845_0_i.r_nw), .RS(mc6845_0_i.rs), .DI(mc6845_0_i.di), .DO(mc6845_0_do),
    .VSYNC(mc6845_0_vs), .HSYNC(mc6845_0_hs), .VBLANK(mc6845_0_vbl), .HBLANK(mc6845_0_hbl), .DE(mc6845_0_de),
    .CURSOR(), .LPSTB(1'b0), .MA(mc6845_0_ma), .RA(mc6845_0_ra)
);

assign mc6845_0_o.dout = mc6845_0_do;      assign mc6845_0_o.vsync = mc6845_0_vs;   assign mc6845_0_o.hsync = mc6845_0_hs;
assign mc6845_0_o.vblank = mc6845_0_vbl;   assign mc6845_0_o.hblank = mc6845_0_hbl; assign mc6845_0_o.de = mc6845_0_de;
assign mc6845_0_o.ma = mc6845_0_ma;        assign mc6845_0_o.ra = mc6845_0_ra;

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

// dsnd_0: discrete sound engine (rtl/rodimus/dsnd_engine/dsnd_engine.sv) on clk_sys, 45.1584 MHz / 941 = 47990 Hz;
// program = MRA index 5, silent while none is loaded (snd_prog_on)
chip_pool_pkg::dsnd_i_t dsnd_0_i;
chip_pool_pkg::dsnd_o_t dsnd_0_o;
wire signed [15:0] dsnd_0_out;

dsnd_engine #(.TICK(941)) dsnd_0
(
    .clk(clk_sys), .reset(reset), .pause(pause), .prog_wr(snd_prog_wr), .prog_addr(dn_addr[12:0]),
    .prog_data(dn_data), .src(dsnd_0_i.src), .out(dsnd_0_out), .out_r(dsnd_0_o.out_r), .sample(dsnd_0_o.sample)
);

assign dsnd_0_o.out = snd_prog_on ? dsnd_0_out : 16'sd0;

/////////////////////////////  Shared ROM blocks  /////////////////////////////

//   $00000-$0FFFF maincpu (64K, sparse)   -> rom0        $10000-$10FFF gfx plane 0 -> rom1
//   $11000-$11FFF gfx plane 1             -> rom2        $12000-$1203F colour PROMs -> rom3
//   $12040-$137FF sound ROM (6K)          -> rom4 (at 0) $14000-$157FF speech ROM (HD38880 PARCOR data) -> rom5
wire dn_maincpu = (dn_addr[16:16] == 1'b0);
wire dn_gfx1    = (dn_addr[16:13] == 4'b1_000);
wire dn_proms   = (dn_addr[16:6]  == 11'b1_0010_0000_00);
wire dn_sndrom  = (dn_addr[16:13] == 4'b1_001) & ~dn_proms;
wire dn_speech  = (dn_addr[16:13] == 4'b1_010);

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

//   block 0  1K  work RAM                     $0000-$03FF (port B = hiscore, clk_sys)
//   block 1  1K  video RAM 2 (FG tilemap)     $0400-$07FF
//   block 2  1K  video RAM 1 (BG tilemap)     $0800-$0BFF
//   block 3  1K  colour RAM, FG copy          $0C00-$0FFF (CPU reads back this copy)
//   block 4  1K  colour RAM, BG copy          $0C00-$0FFF (same CPU writes; the scrolled BG reads it)
//   block 5  2K  character RAM plane 0        $1000-$17FF
//   block 6  2K  character RAM plane 1        $1800-$1FFF
localparam int RAM_BLOCKS = 7;
function automatic int ram_aw(input int n);
    case (n)
        5, 6:    ram_aw = 11;
        default: ram_aw = 10;
    endcase
endfunction

ram_pool_pkg::pram_i_t [RAM_BLOCKS-1:0] snk_pr_i, pool_i;
ram_pool_pkg::pram_o_t [RAM_BLOCKS-1:0] pool_o;
assign pool_i = snk_pr_i;
genvar n;
generate
    for (n = 0; n < RAM_BLOCKS; n++) begin : rpool
        dpram_dc #(.widthad_a(ram_aw(n))) ram
        (
            .clock_a(clk_master), .address_a(pool_i[n].a_addr[ram_aw(n)-1:0]), .data_a(pool_i[n].a_d),
            .wren_a(pool_i[n].a_we), .q_a(pool_o[n].a_q),
            .clock_b(n == 0 ? clk_sys : clk_master), .address_b(pool_i[n].b_addr[ram_aw(n)-1:0]), .data_b(pool_i[n].b_d),
            .wren_b(pool_i[n].b_we), .q_b(pool_o[n].b_q)
        );
    end
endgenerate

/////////////////////////////  Boards  /////////////////////////////

chip_pool_pkg::t65_i_t           snk_t65_0_i;
chip_pool_pkg::mc6845_i_t        snk_mc6845_0_i;
chip_pool_pkg::hd38880_i_t       snk_hd38880_0_i;
chip_pool_pkg::dsnd_i_t          snk_dsnd_0_i;
assign t65_0_i           = snk_t65_0_i;
assign mc6845_0_i        = snk_mc6845_0_i;
assign hd38880_0_i       = snk_hd38880_0_i;
assign dsnd_0_i          = snk_dsnd_0_i;

snk6502_board snk
(
    .clk_master(clk_master), .reset(reset), .pause(pause), .crt_flip(crt_flip), .ce_pix(ce_pix),
    .game_id(game_id), .p1(p1), .p2(p2), .p1_rstick(p1_rstick), .sys_ctl(sys_ctl), .dsw(dsw),
    .vol_music(vol_music), .vol_sfx(vol_sfx), .vol_speech(vol_speech), .ds_caps(ds_caps),
    .h_adj(h_adj), .v_adj(v_adj),
    .rgb_r(rgb_r), .rgb_g(rgb_g), .rgb_b(rgb_b), .hsync(hsync), .vsync(vsync), .hblank(hblank), .vblank(vblank),
    .audio(audio), .flip_screen(flip_screen),
    .hs_address(hs_address), .hs_data_in(hs_data_in), .hs_data_out(hs_data_out), .hs_write(hs_write),
    .t65_0_i(snk_t65_0_i), .t65_0_o(t65_0_o), .mc6845_0_i(snk_mc6845_0_i), .mc6845_0_o(mc6845_0_o),
    .hd38880_0_i(snk_hd38880_0_i), .hd38880_0_o(hd38880_0_o),
    .dsnd_0_i(snk_dsnd_0_i), .dsnd_0_o(dsnd_0_o),
    .rom0_a(rom0_a), .rom0_d(rom0_d), .rom1_a(rom1_a), .rom1_d(rom1_d), .rom2_a(rom2_a), .rom2_d(rom2_d),
    .rom3_a(rom3_a), .rom3_d(rom3_d), .rom4_a(rom4_a), .rom4_d(rom4_d), .rom5_a(rom5_a), .rom5_d(rom5_d),
    .pr_i(snk_pr_i), .pr_o(pool_o)
);

/* verilator lint_off UNUSED */
wire unused_ok = &{1'b0, t65_0_a24[23:16], t65_0_sync};
/* verilator lint_on UNUSED */

endmodule
