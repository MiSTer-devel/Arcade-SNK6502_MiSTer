//============================================================================
//  board_template.sv - start a new SNK6502-core board by copying this file (NOT in files.qip, never compiled).
//  Copyright (C) 2026 Rodimus
//
//  Boards never instantiate a CPU, sound chip, ROM store or board RAM. They live ONCE in the dispatcher
//  rtl/snk6502_dispatcher.sv: 6502 t65_0, CRTC mc6845_0, speech hd38880_0, noise legs sn76477_noise_0 / _1
//  (chip_pool_pkg buses), the ROM blocks rom0-rom5 (program, gfx plane 0 / 1, colour PROMs, sound, speech) and the
//  seven board RAM pool blocks (ram_pool_pkg; map in the dispatcher's "Shared RAM pool" section: 0 work 1K, 1 FG
//  tilemap 1K, 2 BG tilemap 1K, 3 / 4 colour RAM FG / BG copy 1K, 5 / 6 character RAM plane 0 / 1 2K).
//  To add the board: copy this file to rtl/boards/<board>_board.sv (the port list below is snk6502_board's, the only
//  board so far), add it to files.qip + verilator/Makefile SRC, instance it in the dispatcher, put its *_i buses on
//  the variant muxes (pool_i, every chip bus; today a plain assign: one board family) and tie the blocks it doesn't use
//  to '0. A RAM bigger than its block = grow the block, never a private dpram_dc. A RAM / chip that truly can't pool =
//  "// POOL-EXCEPTION: <reason>" on its instance line + a Pool contract row (Claude/snk6502_core_2026-10-28.md).
//  verilator/common/pool_check.sh (POOL_MODS in verilator/Makefile) enforces it.
//============================================================================

module board_template
(
    input         clk_master,     // 11.289 MHz master clock
    input         reset,
    input         pause,
    input         crt_flip,       // OSD CRT Flip: 180 degree mirror of the whole raster
    output        ce_pix,

    input  [3:0]  game_id,        // which game variant (see defines below)

    // Player controls, active high: p1 / p2 = {btn4, btn3, btn2, btn1, up, down, left, right}
    input  [7:0]  p1,
    input  [7:0]  p2,
    input  [3:0]  p1_rstick,      // P1 right stick {U, D, L, R}: Vanguard's second set of fire buttons
    input  [3:0]  sys_ctl,        // {start2, start1, coin2, coin1}
    input  [7:0]  dsw,            // DIP switches

    // Video output
    output [7:0]  rgb_r,
    output [7:0]  rgb_g,
    output [7:0]  rgb_b,
    output        hsync,
    output        vsync,
    output        hblank,
    output        vblank,

    output [15:0] audio,
    output        flip_screen,

    // Shared CPU / sound chip pool
    output chip_pool_pkg::t65_i_t           t65_0_i,
    input  chip_pool_pkg::t65_o_t           t65_0_o,
    output chip_pool_pkg::mc6845_i_t        mc6845_0_i,
    input  chip_pool_pkg::mc6845_o_t        mc6845_0_o,
    output chip_pool_pkg::hd38880_i_t       hd38880_0_i,
    input  chip_pool_pkg::hd38880_o_t       hd38880_0_o,
    output chip_pool_pkg::sn76477_noise_i_t sn76477_noise_0_i,
    input  chip_pool_pkg::sn76477_noise_o_t sn76477_noise_0_o,
    output chip_pool_pkg::sn76477_noise_i_t sn76477_noise_1_i,
    input  chip_pool_pkg::sn76477_noise_o_t sn76477_noise_1_o,

    // Shared ROM blocks (read port, one clock to data)
    output [15:0] rom0_a,         // program ROM
    input  [7:0]  rom0_d,
    output [11:0] rom1_a,         // gfx plane 0
    input  [7:0]  rom1_d,
    output [11:0] rom2_a,         // gfx plane 1
    input  [7:0]  rom2_d,
    output [5:0]  rom3_a,         // colour PROMs
    input  [7:0]  rom3_d,
    output [12:0] rom4_a,         // sound ROM
    input  [7:0]  rom4_d,
    output [12:0] rom5_a,         // speech ROM
    input  [7:0]  rom5_d,

    // Shared board RAM pool (ram_pool_pkg): block n = pr_i[n] / pr_o[n], map in the dispatcher
    output ram_pool_pkg::pram_i_t [6:0] pr_i,
    input  ram_pool_pkg::pram_o_t [6:0] pr_o
);

endmodule
