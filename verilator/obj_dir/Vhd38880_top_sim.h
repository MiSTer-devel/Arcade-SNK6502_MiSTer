// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Primary design header
//
// This header should be included by all source files instantiating the design.
// The class here is then constructed to instantiate the design.
// See the Verilator manual for examples.

#ifndef VERILATED_VHD38880_TOP_SIM_H_
#define VERILATED_VHD38880_TOP_SIM_H_  // guard

#include "verilated_heavy.h"

//==========

class Vhd38880_top_sim__Syms;

//----------

VL_MODULE(Vhd38880_top_sim) {
  public:

    // PORTS
    // The application code writes and reads these signals to
    // propagate new values into/out from the Verilated model.
    VL_IN8(clk,0,0);
    VL_IN8(reset,0,0);
    VL_IN8(pause,0,0);
    VL_IN8(host_wr,0,0);
    VL_IN8(host_din,5,0);
    VL_IN8(game_is_fantasy,0,0);
    VL_IN8(force_en,0,0);
    VL_IN8(force_start,0,0);
    VL_IN8(rom_data,7,0);
    VL_OUT8(dbg_ctrl_start,0,0);
    VL_OUT8(dbg_phrase,3,0);
    VL_OUT8(dbg_phrase_ok,0,0);
    VL_OUT8(dbg_int1,3,0);
    VL_OUT8(dbg_int2,3,0);
    VL_OUT8(dbg_frame_valid,0,0);
    VL_OUT8(dbg_frame_ack,0,0);
    VL_OUT8(dbg_frame_we,0,0);
    VL_OUT8(dbg_unpack_done,0,0);
    VL_OUT8(dbg_rom_rd,0,0);
    VL_OUT8(dbg_f_silent,0,0);
    VL_OUT8(dbg_f_amp,5,0);
    VL_OUT8(dbg_f_pitch,5,0);
    VL_OUT8(dbg_f_k1,6,0);
    VL_OUT8(dbg_f_k2,4,0);
    VL_OUT8(dbg_f_k3,2,0);
    VL_OUT8(dbg_f_k4,2,0);
    VL_OUT8(dbg_f_k5,2,0);
    VL_OUT8(dbg_f_k6,2,0);
    VL_OUT8(dbg_f_k7,2,0);
    VL_OUT8(dbg_f_k8,2,0);
    VL_OUT8(dbg_f_k9,2,0);
    VL_OUT8(dbg_f_k10,2,0);
    VL_OUT8(dbg_dec_amp,7,0);
    VL_OUT8(dbg_dec_pitch,7,0);
    VL_OUT8(dbg_audio_stb,0,0);
    VL_OUT16(rom_addr,12,0);
    VL_OUT16(audio_out,14,0);
    VL_IN(force_addr,19,0);
    VL_OUT(dbg_adset_addr,19,0);
    VL_OUT(dbg_unpack_rom_addr,19,0);

    // LOCAL SIGNALS
    // Internals; generally not touched by application code
    // Anonymous structures to workaround compiler member-count bugs
    struct {
        CData/*0:0*/ hd38880_top_sim__DOT__start_vg;
        CData/*0:0*/ hd38880_top_sim__DOT__stop_vg;
        CData/*0:0*/ hd38880_top_sim__DOT__phrase_ok_vg;
        CData/*3:0*/ hd38880_top_sim__DOT__int1_cfg_vg;
        CData/*3:0*/ hd38880_top_sim__DOT__int2_cfg_vg;
        CData/*3:0*/ hd38880_top_sim__DOT__phrase_vg;
        CData/*0:0*/ hd38880_top_sim__DOT__start_fy;
        CData/*0:0*/ hd38880_top_sim__DOT__stop_fy;
        CData/*0:0*/ hd38880_top_sim__DOT__phrase_ok_fy;
        CData/*3:0*/ hd38880_top_sim__DOT__int1_cfg_fy;
        CData/*3:0*/ hd38880_top_sim__DOT__int2_cfg_fy;
        CData/*3:0*/ hd38880_top_sim__DOT__phrase_fy;
        CData/*0:0*/ hd38880_top_sim__DOT__ctrl_start;
        CData/*3:0*/ hd38880_top_sim__DOT__ctrl_int1;
        CData/*3:0*/ hd38880_top_sim__DOT__ctrl_int2;
        CData/*0:0*/ hd38880_top_sim__DOT__unpack_done;
        CData/*0:0*/ hd38880_top_sim__DOT__unpack_rom_valid;
        CData/*0:0*/ hd38880_top_sim__DOT__unpack_rom_rd;
        CData/*0:0*/ hd38880_top_sim__DOT__frame_valid;
        CData/*0:0*/ hd38880_top_sim__DOT__frame_ack;
        CData/*0:0*/ hd38880_top_sim__DOT__f_silent;
        CData/*5:0*/ hd38880_top_sim__DOT__f_amp;
        CData/*5:0*/ hd38880_top_sim__DOT__f_pitch;
        CData/*6:0*/ hd38880_top_sim__DOT__f_k1;
        CData/*4:0*/ hd38880_top_sim__DOT__f_k2;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k3;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k4;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k5;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k6;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k7;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k8;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k9;
        CData/*2:0*/ hd38880_top_sim__DOT__f_k10;
        CData/*7:0*/ hd38880_top_sim__DOT__dec_amp;
        CData/*7:0*/ hd38880_top_sim__DOT__dec_pitch;
        CData/*0:0*/ hd38880_top_sim__DOT__frame_tick;
        CData/*0:0*/ hd38880_top_sim__DOT__frame_we;
        CData/*7:0*/ hd38880_top_sim__DOT__amp_lat;
        CData/*7:0*/ hd38880_top_sim__DOT__pitch_lat;
        CData/*0:0*/ hd38880_top_sim__DOT__done_d;
        CData/*0:0*/ hd38880_top_sim__DOT__audio_stb_w;
        CData/*2:0*/ hd38880_top_sim__DOT__ctrl_vanguard__DOT__state;
        CData/*2:0*/ hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt;
        CData/*3:0*/ hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx;
        CData/*0:0*/ hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit;
        CData/*2:0*/ hd38880_top_sim__DOT__ctrl_fantasy__DOT__state;
        CData/*2:0*/ hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt;
        CData/*3:0*/ hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx;
        CData/*0:0*/ hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit;
        CData/*6:0*/ hd38880_top_sim__DOT__unpack__DOT__nbits;
        CData/*5:0*/ hd38880_top_sim__DOT__unpack__DOT__pk_amp;
        CData/*2:0*/ hd38880_top_sim__DOT__unpack__DOT__state;
        CData/*7:0*/ hd38880_top_sim__DOT__lattice__DOT__amp_tgt;
        CData/*7:0*/ hd38880_top_sim__DOT__lattice__DOT__amp_cur;
        CData/*7:0*/ hd38880_top_sim__DOT__lattice__DOT__pitch_tgt;
        CData/*7:0*/ hd38880_top_sim__DOT__lattice__DOT__pitch_cur;
        CData/*3:0*/ hd38880_top_sim__DOT__lattice__DOT__interp_idx;
        CData/*0:0*/ hd38880_top_sim__DOT__lattice__DOT__sample_tick;
        CData/*7:0*/ hd38880_top_sim__DOT__lattice__DOT__pitch_cnt;
        CData/*4:0*/ hd38880_top_sim__DOT__lattice__DOT__stage;
        CData/*1:0*/ hd38880_top_sim__DOT__lattice__DOT__phase;
        CData/*0:0*/ hd38880_top_sim__DOT__lattice__DOT__busy;
        SData/*9:0*/ hd38880_top_sim__DOT__k1_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k2_lat;
    };
    struct {
        SData/*9:0*/ hd38880_top_sim__DOT__k3_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k4_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k5_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k6_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k7_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k8_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k9_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__k10_lat;
        SData/*9:0*/ hd38880_top_sim__DOT__lattice__DOT__samp_cnt;
        SData/*15:0*/ hd38880_top_sim__DOT__lattice__DOT__div_cnt;
        SData/*15:0*/ hd38880_top_sim__DOT__lattice__DOT__lfsr;
        SData/*14:0*/ hd38880_top_sim__DOT__lattice__DOT__excite;
        SData/*14:0*/ hd38880_top_sim__DOT__lattice__DOT__f_val;
        SData/*9:0*/ hd38880_top_sim__DOT__lattice__DOT__k_now;
        IData/*19:0*/ hd38880_top_sim__DOT__adset_addr_vg;
        IData/*19:0*/ hd38880_top_sim__DOT__adset_addr_fy;
        IData/*19:0*/ hd38880_top_sim__DOT__real_adset;
        IData/*19:0*/ hd38880_top_sim__DOT__unpack_rom_addr;
        IData/*23:0*/ hd38880_top_sim__DOT__frame_cnt;
        IData/*25:0*/ hd38880_top_sim__DOT__lattice__DOT__b_loss_p;
        IData/*24:0*/ hd38880_top_sim__DOT__lattice__DOT__p_kf;
        QData/*63:0*/ hd38880_top_sim__DOT__unpack__DOT__resv;
        VlUnpacked<CData/*7:0*/, 64> hd38880_top_sim__DOT__dectab__DOT__amp_table;
        VlUnpacked<CData/*7:0*/, 64> hd38880_top_sim__DOT__dectab__DOT__pitch_table;
        VlUnpacked<SData/*9:0*/, 16> hd38880_top_sim__DOT__dectab__DOT__k1_table;
        VlUnpacked<SData/*9:0*/, 16> hd38880_top_sim__DOT__dectab__DOT__k2_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k3_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k4_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k5_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k6_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k7_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k8_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k9_table;
        VlUnpacked<SData/*9:0*/, 8> hd38880_top_sim__DOT__dectab__DOT__k10_table;
        VlUnpacked<SData/*9:0*/, 10> hd38880_top_sim__DOT__lattice__DOT__k_in;
        VlUnpacked<SData/*9:0*/, 10> hd38880_top_sim__DOT__lattice__DOT__k_tgt;
        VlUnpacked<SData/*9:0*/, 10> hd38880_top_sim__DOT__lattice__DOT__k_cur;
        VlUnpacked<SData/*14:0*/, 10> hd38880_top_sim__DOT__lattice__DOT__b_delay;
        VlUnpacked<SData/*14:0*/, 10> hd38880_top_sim__DOT__lattice__DOT__b_new;
    };

    // LOCAL VARIABLES
    // Internals; generally not touched by application code
    CData/*0:0*/ __Vclklast__TOP__clk;
    SData/*14:0*/ hd38880_top_sim__DOT__lattice__DOT____Vlvbound3;
    SData/*14:0*/ hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
    SData/*9:0*/ hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
    SData/*9:0*/ hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;

    // INTERNAL VARIABLES
    // Internals; generally not touched by application code
    Vhd38880_top_sim__Syms* __VlSymsp;  // Symbol table

    // CONSTRUCTORS
  private:
    VL_UNCOPYABLE(Vhd38880_top_sim);  ///< Copying not allowed
  public:
    /// Construct the model; called by application code
    /// If contextp is null, then the model will use the default global context
    /// If name is "", then makes a wrapper with a
    /// single model invisible with respect to DPI scope names.
    Vhd38880_top_sim(VerilatedContext* contextp, const char* name = "TOP");
    Vhd38880_top_sim(const char* name = "TOP")
      : Vhd38880_top_sim(nullptr, name) {}
    /// Destroy the model; called (often implicitly) by application code
    ~Vhd38880_top_sim();

    // API METHODS
    /// Return current simulation context for this model.
    /// Used to get to e.g. simulation time via contextp()->time()
    VerilatedContext* contextp();
    /// Evaluate the model.  Application must call when inputs change.
    void eval() { eval_step(); }
    /// Evaluate when calling multiple units/models per time step.
    void eval_step();
    /// Evaluate at end of a timestep for tracing, when using eval_step().
    /// Application must call after all eval() and before time changes.
    void eval_end_step() {}
    /// Simulation complete, run final blocks.  Application must call on completion.
    void final();

    // INTERNAL METHODS
    static void _eval_initial_loop(Vhd38880_top_sim__Syms* __restrict vlSymsp);
    void __Vconfigure(Vhd38880_top_sim__Syms* symsp, bool first);
  private:
    static QData _change_request(Vhd38880_top_sim__Syms* __restrict vlSymsp);
    static QData _change_request_1(Vhd38880_top_sim__Syms* __restrict vlSymsp);
  public:
    static void _combo__TOP__4(Vhd38880_top_sim__Syms* __restrict vlSymsp);
  private:
    static void _ctor_var_reset(Vhd38880_top_sim* self) VL_ATTR_COLD;
  public:
    static void _eval(Vhd38880_top_sim__Syms* __restrict vlSymsp);
  private:
#ifdef VL_DEBUG
    void _eval_debug_assertions();
#endif  // VL_DEBUG
  public:
    static void _eval_initial(Vhd38880_top_sim__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _eval_settle(Vhd38880_top_sim__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _initial__TOP__1(Vhd38880_top_sim__Syms* __restrict vlSymsp) VL_ATTR_COLD;
    static void _sequent__TOP__2(Vhd38880_top_sim__Syms* __restrict vlSymsp);
    static void _settle__TOP__3(Vhd38880_top_sim__Syms* __restrict vlSymsp) VL_ATTR_COLD;
} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

//----------


#endif  // guard
