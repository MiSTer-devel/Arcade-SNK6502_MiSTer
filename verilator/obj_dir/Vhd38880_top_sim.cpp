// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vhd38880_top_sim.h for the primary calling header

#include "Vhd38880_top_sim.h"
#include "Vhd38880_top_sim__Syms.h"

//==========

VerilatedContext* Vhd38880_top_sim::contextp() {
    return __VlSymsp->_vm_contextp__;
}

void Vhd38880_top_sim::eval_step() {
    VL_DEBUG_IF(VL_DBG_MSGF("+++++TOP Evaluate Vhd38880_top_sim::eval\n"); );
    Vhd38880_top_sim__Syms* __restrict vlSymsp = this->__VlSymsp;  // Setup global symbol table
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
#ifdef VL_DEBUG
    // Debug assertions
    _eval_debug_assertions();
#endif  // VL_DEBUG
    // Initialize
    if (VL_UNLIKELY(!vlSymsp->__Vm_didInit)) _eval_initial_loop(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        VL_DEBUG_IF(VL_DBG_MSGF("+ Clock loop\n"););
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("hd38880_top_sim.v", 21, "",
                "Verilated model didn't converge\n"
                "- See https://verilator.org/warn/DIDNOTCONVERGE");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

void Vhd38880_top_sim::_eval_initial_loop(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    vlSymsp->__Vm_didInit = true;
    _eval_initial(vlSymsp);
    // Evaluate till stable
    int __VclockLoop = 0;
    QData __Vchange = 1;
    do {
        _eval_settle(vlSymsp);
        _eval(vlSymsp);
        if (VL_UNLIKELY(++__VclockLoop > 100)) {
            // About to fail, so enable debug to see what's not settling.
            // Note you must run make with OPT=-DVL_DEBUG for debug prints.
            int __Vsaved_debug = Verilated::debug();
            Verilated::debug(1);
            __Vchange = _change_request(vlSymsp);
            Verilated::debug(__Vsaved_debug);
            VL_FATAL_MT("hd38880_top_sim.v", 21, "",
                "Verilated model didn't DC converge\n"
                "- See https://verilator.org/warn/DIDNOTCONVERGE");
        } else {
            __Vchange = _change_request(vlSymsp);
        }
    } while (VL_UNLIKELY(__Vchange));
}

VL_INLINE_OPT void Vhd38880_top_sim::_sequent__TOP__2(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_sequent__TOP__2\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Variables
    CData/*0:0*/ __Vdly__hd38880_top_sim__DOT__frame_ack;
    CData/*2:0*/ __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state;
    CData/*2:0*/ __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt;
    CData/*2:0*/ __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state;
    CData/*2:0*/ __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt;
    CData/*0:0*/ __Vdly__hd38880_top_sim__DOT__unpack_rom_rd;
    CData/*2:0*/ __Vdly__hd38880_top_sim__DOT__unpack__DOT__state;
    CData/*6:0*/ __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits;
    CData/*7:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cnt;
    CData/*0:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__busy;
    CData/*4:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__stage;
    CData/*1:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v0;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v1;
    CData/*3:0*/ __Vdlyvdim0__hd38880_top_sim__DOT__lattice__DOT__b_new__v10;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_new__v10;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v10;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v11;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v12;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v13;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v14;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v15;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v16;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v17;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v18;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v19;
    CData/*3:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__interp_idx;
    CData/*7:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__amp_cur;
    CData/*7:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cur;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v0;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v10;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v11;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v12;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v13;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v14;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v15;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v16;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v17;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v18;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v19;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v0;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v10;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v11;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v12;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v13;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v14;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v15;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v16;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v17;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v18;
    CData/*0:0*/ __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v19;
    SData/*15:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__div_cnt;
    SData/*15:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__lfsr;
    SData/*14:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__f_val;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_new__v10;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v10;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v11;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v12;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v13;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v14;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v15;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v16;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v17;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v18;
    SData/*14:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v19;
    SData/*9:0*/ __Vdly__hd38880_top_sim__DOT__lattice__DOT__samp_cnt;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v10;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v11;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v12;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v13;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v14;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v15;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v16;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v17;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v18;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v19;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v10;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v11;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v12;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v13;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v14;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v15;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v16;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v17;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v18;
    SData/*9:0*/ __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v19;
    IData/*23:0*/ __Vdly__hd38880_top_sim__DOT__frame_cnt;
    IData/*19:0*/ __Vdly__hd38880_top_sim__DOT__adset_addr_vg;
    IData/*19:0*/ __Vdly__hd38880_top_sim__DOT__adset_addr_fy;
    QData/*63:0*/ __Vdly__hd38880_top_sim__DOT__unpack__DOT__resv;
    // Body
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__div_cnt 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt;
    __Vdly__hd38880_top_sim__DOT__frame_cnt = vlTOPp->hd38880_top_sim__DOT__frame_cnt;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__lfsr 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__lfsr;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cnt 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt;
    __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt 
        = vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt;
    __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state 
        = vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state;
    __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt 
        = vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt;
    __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state 
        = vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state;
    __Vdly__hd38880_top_sim__DOT__adset_addr_fy = vlTOPp->hd38880_top_sim__DOT__adset_addr_fy;
    __Vdly__hd38880_top_sim__DOT__adset_addr_vg = vlTOPp->hd38880_top_sim__DOT__adset_addr_vg;
    __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits 
        = vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits;
    __Vdly__hd38880_top_sim__DOT__unpack__DOT__state 
        = vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state;
    __Vdly__hd38880_top_sim__DOT__unpack__DOT__resv 
        = vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv;
    __Vdly__hd38880_top_sim__DOT__unpack_rom_rd = vlTOPp->hd38880_top_sim__DOT__unpack_rom_rd;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__phase;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__busy 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__busy;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_new__v10 = 0U;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__f_val 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__f_val;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__stage 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage;
    __Vdly__hd38880_top_sim__DOT__frame_ack = vlTOPp->hd38880_top_sim__DOT__frame_ack;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v10 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v11 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v12 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v13 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v14 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v15 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v16 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v17 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v18 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v19 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v0 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v1 = 0U;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cur 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cur;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__amp_cur 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__interp_idx 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__interp_idx;
    __Vdly__hd38880_top_sim__DOT__lattice__DOT__samp_cnt 
        = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__samp_cnt;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v0 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v10 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v11 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v12 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v13 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v14 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v15 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v16 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v17 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v18 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v19 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v0 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v10 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v11 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v12 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v13 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v14 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v15 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v16 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v17 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v18 = 0U;
    __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v19 = 0U;
    if (vlTOPp->reset) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__div_cnt = 0U;
        __Vdly__hd38880_top_sim__DOT__frame_cnt = 0U;
    } else {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__div_cnt 
            = (0xffffU & ((IData)(vlTOPp->pause) ? (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt)
                           : ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__sample_tick)
                               ? 0U : ((IData)(1U) 
                                       + (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt)))));
        __Vdly__hd38880_top_sim__DOT__frame_cnt = (0xffffffU 
                                                   & ((IData)(vlTOPp->pause)
                                                       ? vlTOPp->hd38880_top_sim__DOT__frame_cnt
                                                       : 
                                                      ((IData)(vlTOPp->hd38880_top_sim__DOT__frame_tick)
                                                        ? 0U
                                                        : 
                                                       ((IData)(1U) 
                                                        + vlTOPp->hd38880_top_sim__DOT__frame_cnt))));
    }
    __Vdly__hd38880_top_sim__DOT__frame_ack = 0U;
    if ((1U & (~ (IData)(vlTOPp->reset)))) {
        if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                            == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
             & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
            __Vdly__hd38880_top_sim__DOT__frame_ack = 1U;
        }
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k1_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k1_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table
            [(0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__f_k1) 
                      >> 3U))];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k2_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k2_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table
            [(0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__f_k2) 
                      >> 1U))];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k10_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k10_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table
            [vlTOPp->hd38880_top_sim__DOT__f_k10];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k9_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k9_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table
            [vlTOPp->hd38880_top_sim__DOT__f_k9];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k8_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k8_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table
            [vlTOPp->hd38880_top_sim__DOT__f_k8];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k7_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k7_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table
            [vlTOPp->hd38880_top_sim__DOT__f_k7];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k3_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k3_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table
            [vlTOPp->hd38880_top_sim__DOT__f_k3];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k4_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k4_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table
            [vlTOPp->hd38880_top_sim__DOT__f_k4];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k5_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k5_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table
            [vlTOPp->hd38880_top_sim__DOT__f_k5];
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__k6_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__k6_lat = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table
            [vlTOPp->hd38880_top_sim__DOT__f_k6];
    }
    vlTOPp->hd38880_top_sim__DOT__audio_stb_w = 0U;
    if (vlTOPp->reset) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__busy = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__stage = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__f_val = 0U;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v0 = 1U;
        vlTOPp->audio_out = 0U;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v1 = 1U;
    } else if ((0x582U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt))) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__f_val 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__excite;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__stage 
            = ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_int2))
                ? 0xaU : 8U);
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__busy = 1U;
    } else if (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__busy) {
        if ((0U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__phase))) {
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__f_val 
                = (0x7fffU & ((0x1ffffffU & VL_EXTENDS_II(25,15, (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__f_val))) 
                              - (0x1ffffffU & VL_SHIFTRS_III(25,25,32, 
                                                             (0x1ffffffU 
                                                              & VL_MULS_III(25,25,25, 
                                                                            (0x1ffffffU 
                                                                             & VL_EXTENDS_II(25,10, (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_now))), 
                                                                            (0x1ffffffU 
                                                                             & VL_EXTENDS_II(25,15, 
                                                                                (0x7fffU 
                                                                                & VL_SHIFTRS_III(26,26,32, vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_loss_p, 9U)))))), 9U))));
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase = 1U;
        } else if ((1U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__phase))) {
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound3 
                = (0x7fffU & ((0x1ffffffU & VL_EXTENDS_II(25,15, 
                                                          (0x7fffU 
                                                           & VL_SHIFTRS_III(26,26,32, vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_loss_p, 9U)))) 
                              + (0x1ffffffU & VL_SHIFTRS_III(25,25,32, vlTOPp->hd38880_top_sim__DOT__lattice__DOT__p_kf, 9U))));
            if ((9U >= (0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                                - (IData)(1U))))) {
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_new__v10 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound3;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_new__v10 = 1U;
                __Vdlyvdim0__hd38880_top_sim__DOT__lattice__DOT__b_new__v10 
                    = (0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                               - (IData)(1U)));
            }
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase = 0U;
            if ((1U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage))) {
                __Vdly__hd38880_top_sim__DOT__lattice__DOT__busy = 0U;
                vlTOPp->audio_out = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__f_val;
                vlTOPp->hd38880_top_sim__DOT__audio_stb_w = 1U;
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v10 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__f_val;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v10 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [0U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v11 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v11 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [1U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v12 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v12 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [2U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v13 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v13 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [3U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v14 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v14 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [4U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v15 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v15 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [5U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v16 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v16 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [6U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v17 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v17 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [7U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v18 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v18 = 1U;
                vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new
                    [8U];
                __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v19 
                    = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4;
                __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v19 = 1U;
            } else {
                __Vdly__hd38880_top_sim__DOT__lattice__DOT__stage 
                    = (0x1fU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                                - (IData)(1U)));
            }
        } else {
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase = 0U;
        }
    }
    if (vlTOPp->reset) {
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v0 = 1U;
    } else if (vlTOPp->hd38880_top_sim__DOT__frame_we) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [0U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v10 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v10 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [1U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v11 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v11 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [2U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v12 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v12 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [3U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v13 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v13 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [4U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v14 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v14 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [5U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v15 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v15 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [6U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v16 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v16 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [7U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v17 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v17 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [8U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v18 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v18 = 1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in
            [9U];
        __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v19 
            = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v19 = 1U;
    }
    if (vlTOPp->reset) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__samp_cnt = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__interp_idx = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__amp_cur = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cur = 0U;
        __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v0 = 1U;
    } else if (vlTOPp->hd38880_top_sim__DOT__frame_we) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__samp_cnt = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__interp_idx = 0U;
    } else if ((0x582U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt))) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__samp_cnt 
            = (0x3ffU & ((IData)(1U) + (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__samp_cnt)));
        if (((0U == VL_MODDIV_III(32, (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__samp_cnt), (IData)(0x14U))) 
             & (8U > (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__interp_idx)))) {
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__amp_cur 
                = (0xffU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur) 
                            + (0x1fU & (((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_tgt) 
                                         - (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur)) 
                                        >> 3U))));
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cur 
                = (0xffU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cur) 
                            + (0x1fU & (((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_tgt) 
                                         - (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cur)) 
                                        >> 3U))));
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__interp_idx 
                = (0xfU & ((IData)(1U) + (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__interp_idx)));
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [0U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [0U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [0U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v10 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v10 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [1U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [1U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [1U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v11 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v11 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [2U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [2U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [2U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v12 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v12 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [3U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [3U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [3U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v13 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v13 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [4U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [4U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [4U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v14 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v14 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [5U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [5U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [5U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v15 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v15 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [6U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [6U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [6U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v16 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v16 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [7U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [7U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [7U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v17 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v17 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [8U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [8U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [8U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v18 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v18 = 1U;
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 
                = (0x3ffU & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                             [9U] + VL_SHIFTRS_III(10,10,32, 
                                                   (0x3ffU 
                                                    & (vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt
                                                       [9U] 
                                                       - 
                                                       vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
                                                       [9U])), 3U)));
            __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v19 
                = vlTOPp->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8;
            __Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v19 = 1U;
        }
    }
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__busy 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__busy;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__phase 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__phase;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__f_val 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__f_val;
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v0) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[0U] = 0U;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v1) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[1U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[2U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[3U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[4U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[5U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[6U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[7U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[8U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[9U] = 0U;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_new__v10) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_new[__Vdlyvdim0__hd38880_top_sim__DOT__lattice__DOT__b_new__v10] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_new__v10;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v0) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[0U] = 0U;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v1) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[1U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[2U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[3U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[4U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[5U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[6U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[7U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[8U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[9U] = 0U;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v10) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[0U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v10;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v11) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[1U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v11;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v12) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[2U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v12;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v13) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[3U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v13;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v14) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[4U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v14;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v15) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[5U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v15;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v16) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[6U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v16;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v17) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[7U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v17;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v18) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[8U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v18;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__b_delay__v19) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay[9U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__b_delay__v19;
    }
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__stage;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__samp_cnt 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__samp_cnt;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__interp_idx 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__interp_idx;
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v0) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[0U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[1U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[2U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[3U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[4U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[5U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[6U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[7U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[8U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[9U] = 0U;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v10) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[0U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v10;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v11) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[1U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v11;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v12) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[2U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v12;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v13) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[3U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v13;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v14) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[4U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v14;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v15) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[5U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v15;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v16) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[6U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v16;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v17) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[7U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v17;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v18) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[8U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v18;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v19) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_tgt[9U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_tgt__v19;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v0) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[0U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[1U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[2U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[3U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[4U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[5U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[6U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[7U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[8U] = 0U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[9U] = 0U;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v10) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[0U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v10;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v11) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[1U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v11;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v12) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[2U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v12;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v13) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[3U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v13;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v14) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[4U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v14;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v15) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[5U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v15;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v16) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[6U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v16;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v17) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[7U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v17;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v18) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[8U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v18;
    }
    if (__Vdlyvset__hd38880_top_sim__DOT__lattice__DOT__k_cur__v19) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur[9U] 
            = __Vdlyvval__hd38880_top_sim__DOT__lattice__DOT__k_cur__v19;
    }
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[0U] 
        = vlTOPp->hd38880_top_sim__DOT__k1_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[1U] 
        = vlTOPp->hd38880_top_sim__DOT__k2_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[9U] 
        = vlTOPp->hd38880_top_sim__DOT__k10_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[8U] 
        = vlTOPp->hd38880_top_sim__DOT__k9_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[7U] 
        = vlTOPp->hd38880_top_sim__DOT__k8_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[6U] 
        = vlTOPp->hd38880_top_sim__DOT__k7_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[2U] 
        = vlTOPp->hd38880_top_sim__DOT__k3_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[3U] 
        = vlTOPp->hd38880_top_sim__DOT__k4_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[4U] 
        = vlTOPp->hd38880_top_sim__DOT__k5_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[5U] 
        = vlTOPp->hd38880_top_sim__DOT__k6_lat;
    vlTOPp->dbg_audio_stb = vlTOPp->hd38880_top_sim__DOT__audio_stb_w;
    if (vlTOPp->reset) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cnt = 0U;
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__lfsr = 0xace1U;
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__excite = 0U;
    } else if ((0x582U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt))) {
        __Vdly__hd38880_top_sim__DOT__lattice__DOT__lfsr 
            = ((0xfffeU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__lfsr) 
                           << 1U)) | (1U & VL_REDXOR_32(
                                                        (0xb400U 
                                                         & (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__lfsr)))));
        if ((0U != (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cur))) {
            __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cnt 
                = (((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt) 
                    >= ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cur) 
                        - (IData)(1U))) ? 0U : (0xffU 
                                                & ((IData)(1U) 
                                                   + (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt))));
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT__excite 
                = (0x7fffU & ((8U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_int1))
                               ? ((8U > (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt))
                                   ? ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur) 
                                      - (0xfffU & (
                                                   ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur) 
                                                    * 
                                                    (0x7fU 
                                                     & (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt))) 
                                                   >> 3U)))
                                   : 0U) : ((0U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt))
                                             ? ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur) 
                                                << 3U)
                                             : 0U)));
        } else {
            vlTOPp->hd38880_top_sim__DOT__lattice__DOT__excite 
                = (0x7fffU & ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__lfsr))
                               ? (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur)
                               : (- (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur))));
        }
    }
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_now 
        = ((9U >= (0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                           - (IData)(1U)))) ? vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
           [(0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                     - (IData)(1U)))] : 0U);
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_tgt = 0U;
    } else if (vlTOPp->hd38880_top_sim__DOT__frame_we) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_tgt 
            = vlTOPp->hd38880_top_sim__DOT__pitch_lat;
    }
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_tgt = 0U;
    } else if (vlTOPp->hd38880_top_sim__DOT__frame_we) {
        vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_tgt 
            = vlTOPp->hd38880_top_sim__DOT__amp_lat;
    }
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cnt;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__lfsr 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__lfsr;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__pitch_cur 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__pitch_cur;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__amp_cur 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__amp_cur;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt 
        = __Vdly__hd38880_top_sim__DOT__lattice__DOT__div_cnt;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__p_kf 
        = (0x1ffffffU & VL_MULS_III(25,25,25, (0x1ffffffU 
                                               & VL_EXTENDS_II(25,10, (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_now))), 
                                    (0x1ffffffU & VL_EXTENDS_II(25,15, (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__f_val)))));
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__sample_tick 
        = (0x582U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt));
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__pitch_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__pitch_lat = vlTOPp->hd38880_top_sim__DOT__dec_pitch;
    }
    vlTOPp->hd38880_top_sim__DOT__frame_we = 0U;
    if (vlTOPp->reset) {
        vlTOPp->hd38880_top_sim__DOT__amp_lat = 0U;
    } else if ((((~ (IData)(vlTOPp->pause)) & (0x371f3U 
                                               == vlTOPp->hd38880_top_sim__DOT__frame_cnt)) 
                & (IData)(vlTOPp->hd38880_top_sim__DOT__frame_valid))) {
        vlTOPp->hd38880_top_sim__DOT__frame_we = 1U;
        vlTOPp->hd38880_top_sim__DOT__amp_lat = vlTOPp->hd38880_top_sim__DOT__dec_amp;
    } else if (((IData)(vlTOPp->hd38880_top_sim__DOT__unpack_done) 
                & (~ (IData)(vlTOPp->hd38880_top_sim__DOT__done_d)))) {
        vlTOPp->hd38880_top_sim__DOT__frame_we = 1U;
        vlTOPp->hd38880_top_sim__DOT__amp_lat = 0U;
    }
    vlTOPp->hd38880_top_sim__DOT__frame_cnt = __Vdly__hd38880_top_sim__DOT__frame_cnt;
    vlTOPp->dbg_frame_we = vlTOPp->hd38880_top_sim__DOT__frame_we;
    vlTOPp->hd38880_top_sim__DOT__frame_tick = (0x371f3U 
                                                == vlTOPp->hd38880_top_sim__DOT__frame_cnt);
    vlTOPp->hd38880_top_sim__DOT__done_d = vlTOPp->hd38880_top_sim__DOT__unpack_done;
    __Vdly__hd38880_top_sim__DOT__unpack_rom_rd = 0U;
    vlTOPp->hd38880_top_sim__DOT__unpack_done = 0U;
    if (vlTOPp->reset) {
        __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 0U;
        vlTOPp->hd38880_top_sim__DOT__frame_valid = 0U;
        __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits = 0U;
    } else if (((IData)(vlTOPp->game_is_fantasy) ? (IData)(vlTOPp->hd38880_top_sim__DOT__stop_fy)
                 : (IData)(vlTOPp->hd38880_top_sim__DOT__stop_vg))) {
        __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 5U;
        vlTOPp->hd38880_top_sim__DOT__frame_valid = 0U;
    } else if ((4U & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state))) {
        if ((2U & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state))) {
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 0U;
        } else if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state))) {
            vlTOPp->hd38880_top_sim__DOT__unpack_done = 1U;
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 0U;
        } else if (vlTOPp->hd38880_top_sim__DOT__frame_ack) {
            vlTOPp->hd38880_top_sim__DOT__frame_valid = 0U;
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 1U;
        }
    } else if ((2U & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state))) {
        if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state))) {
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 0U;
        } else if ((0x3fU == (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__pk_amp))) {
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 5U;
        } else if ((0U == (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__pk_amp))) {
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits 
                = (0x7fU & ((IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits) 
                            - (IData)(6U)));
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__resv 
                = (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                   >> 6U);
            vlTOPp->hd38880_top_sim__DOT__f_silent = 1U;
            vlTOPp->hd38880_top_sim__DOT__f_amp = 0U;
            vlTOPp->hd38880_top_sim__DOT__f_pitch = 0U;
            vlTOPp->hd38880_top_sim__DOT__frame_valid = 1U;
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 4U;
        } else {
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits 
                = (0x7fU & ((IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits) 
                            - (IData)(0x31U)));
            vlTOPp->hd38880_top_sim__DOT__f_silent = 0U;
            vlTOPp->hd38880_top_sim__DOT__f_amp = (0x3fU 
                                                   & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv));
            vlTOPp->hd38880_top_sim__DOT__frame_valid = 1U;
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 4U;
            vlTOPp->hd38880_top_sim__DOT__f_pitch = 
                (0x3fU & (IData)((vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                  >> 7U)));
            vlTOPp->hd38880_top_sim__DOT__f_k1 = (0x7fU 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0xdU)));
            vlTOPp->hd38880_top_sim__DOT__f_k2 = (0x1fU 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x14U)));
            vlTOPp->hd38880_top_sim__DOT__f_k3 = (7U 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x19U)));
            vlTOPp->hd38880_top_sim__DOT__f_k4 = (7U 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x1cU)));
            vlTOPp->hd38880_top_sim__DOT__f_k5 = (7U 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x1fU)));
            vlTOPp->hd38880_top_sim__DOT__f_k6 = (7U 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x22U)));
            vlTOPp->hd38880_top_sim__DOT__f_k7 = (7U 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x25U)));
            vlTOPp->hd38880_top_sim__DOT__f_k8 = (7U 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x28U)));
            vlTOPp->hd38880_top_sim__DOT__f_k9 = (7U 
                                                  & (IData)(
                                                            (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                             >> 0x2bU)));
            vlTOPp->hd38880_top_sim__DOT__f_k10 = (7U 
                                                   & (IData)(
                                                             (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                                                              >> 0x2eU)));
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__resv 
                = (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                   >> 0x31U);
        }
    } else if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state))) {
        if ((0x31U <= (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits))) {
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 2U;
        } else if (vlTOPp->hd38880_top_sim__DOT__unpack_rom_valid) {
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__resv 
                = (vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
                   | ((0x3fU >= (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits))
                       ? ((QData)((IData)(vlTOPp->rom_data)) 
                          << (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits))
                       : 0ULL));
            vlTOPp->hd38880_top_sim__DOT__unpack_rom_addr 
                = (0xfffffU & ((IData)(1U) + vlTOPp->hd38880_top_sim__DOT__unpack_rom_addr));
            __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits 
                = (0x7fU & ((IData)(8U) + (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits)));
        } else {
            __Vdly__hd38880_top_sim__DOT__unpack_rom_rd = 1U;
        }
    } else if (vlTOPp->hd38880_top_sim__DOT__ctrl_start) {
        vlTOPp->hd38880_top_sim__DOT__unpack_rom_addr 
            = ((IData)(vlTOPp->force_en) ? vlTOPp->force_addr
                : vlTOPp->hd38880_top_sim__DOT__real_adset);
        __Vdly__hd38880_top_sim__DOT__unpack__DOT__resv = 0ULL;
        __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits = 0U;
        vlTOPp->hd38880_top_sim__DOT__frame_valid = 0U;
        __Vdly__hd38880_top_sim__DOT__unpack__DOT__state = 1U;
    }
    vlTOPp->hd38880_top_sim__DOT__unpack__DOT__state 
        = __Vdly__hd38880_top_sim__DOT__unpack__DOT__state;
    vlTOPp->hd38880_top_sim__DOT__unpack__DOT__nbits 
        = __Vdly__hd38880_top_sim__DOT__unpack__DOT__nbits;
    vlTOPp->hd38880_top_sim__DOT__frame_ack = __Vdly__hd38880_top_sim__DOT__frame_ack;
    vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv 
        = __Vdly__hd38880_top_sim__DOT__unpack__DOT__resv;
    vlTOPp->dbg_frame_ack = vlTOPp->hd38880_top_sim__DOT__frame_ack;
    vlTOPp->dbg_unpack_done = vlTOPp->hd38880_top_sim__DOT__unpack_done;
    vlTOPp->dbg_frame_valid = vlTOPp->hd38880_top_sim__DOT__frame_valid;
    vlTOPp->hd38880_top_sim__DOT__unpack__DOT__pk_amp 
        = (0x3fU & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv));
    vlTOPp->dbg_f_silent = vlTOPp->hd38880_top_sim__DOT__f_silent;
    vlTOPp->dbg_f_k1 = vlTOPp->hd38880_top_sim__DOT__f_k1;
    vlTOPp->dbg_f_k2 = vlTOPp->hd38880_top_sim__DOT__f_k2;
    vlTOPp->dbg_f_k3 = vlTOPp->hd38880_top_sim__DOT__f_k3;
    vlTOPp->dbg_f_k4 = vlTOPp->hd38880_top_sim__DOT__f_k4;
    vlTOPp->dbg_f_k5 = vlTOPp->hd38880_top_sim__DOT__f_k5;
    vlTOPp->dbg_f_k6 = vlTOPp->hd38880_top_sim__DOT__f_k6;
    vlTOPp->dbg_f_k7 = vlTOPp->hd38880_top_sim__DOT__f_k7;
    vlTOPp->dbg_f_k8 = vlTOPp->hd38880_top_sim__DOT__f_k8;
    vlTOPp->dbg_f_k9 = vlTOPp->hd38880_top_sim__DOT__f_k9;
    vlTOPp->dbg_f_k10 = vlTOPp->hd38880_top_sim__DOT__f_k10;
    vlTOPp->rom_addr = (0x1fffU & vlTOPp->hd38880_top_sim__DOT__unpack_rom_addr);
    vlTOPp->dbg_unpack_rom_addr = vlTOPp->hd38880_top_sim__DOT__unpack_rom_addr;
    vlTOPp->hd38880_top_sim__DOT__unpack_rom_valid 
        = vlTOPp->hd38880_top_sim__DOT__unpack_rom_rd;
    vlTOPp->dbg_f_amp = vlTOPp->hd38880_top_sim__DOT__f_amp;
    vlTOPp->hd38880_top_sim__DOT__dec_amp = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table
        [vlTOPp->hd38880_top_sim__DOT__f_amp];
    vlTOPp->dbg_f_pitch = vlTOPp->hd38880_top_sim__DOT__f_pitch;
    vlTOPp->hd38880_top_sim__DOT__dec_pitch = ((0U 
                                                == (IData)(vlTOPp->hd38880_top_sim__DOT__f_pitch))
                                                ? 0U
                                                : vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table
                                               [vlTOPp->hd38880_top_sim__DOT__f_pitch]);
    vlTOPp->hd38880_top_sim__DOT__start_fy = 0U;
    vlTOPp->hd38880_top_sim__DOT__stop_fy = 0U;
    if (vlTOPp->reset) {
        __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 0U;
        __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt = 0U;
        __Vdly__hd38880_top_sim__DOT__adset_addr_fy = 0U;
        vlTOPp->hd38880_top_sim__DOT__int1_cfg_fy = 0U;
        vlTOPp->hd38880_top_sim__DOT__int2_cfg_fy = 0xfU;
        vlTOPp->hd38880_top_sim__DOT__phrase_fy = 0U;
        vlTOPp->hd38880_top_sim__DOT__phrase_ok_fy = 0U;
    } else if ((((IData)(vlTOPp->host_wr) & ((IData)(vlTOPp->host_din) 
                                             >> 5U)) 
                & ((IData)(vlTOPp->host_din) >> 4U))) {
        if ((4U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state))) {
            if ((2U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 0U;
            } else if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 0U;
            } else {
                __Vdly__hd38880_top_sim__DOT__adset_addr_fy 
                    = (0xfffffU & (vlTOPp->hd38880_top_sim__DOT__adset_addr_fy 
                                   | ((0x13U >= ((IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt) 
                                                 << 2U))
                                       ? ((0xfU & (IData)(vlTOPp->host_din)) 
                                          << ((IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt) 
                                              << 2U))
                                       : 0U)));
                if ((4U == (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt))) {
                    __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 0U;
                } else {
                    __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt 
                        = (7U & ((IData)(1U) + (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt)));
                }
            }
        } else if ((2U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state))) {
            if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 0U;
            } else {
                vlTOPp->hd38880_top_sim__DOT__int2_cfg_fy 
                    = (0xfU & (IData)(vlTOPp->host_din));
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 0U;
            }
        } else if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state))) {
            vlTOPp->hd38880_top_sim__DOT__int1_cfg_fy 
                = (0xfU & (IData)(vlTOPp->host_din));
            __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 0U;
        } else if ((8U & (IData)(vlTOPp->host_din))) {
            if ((4U & (IData)(vlTOPp->host_din))) {
                if ((1U & (~ ((IData)(vlTOPp->host_din) 
                              >> 1U)))) {
                    if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                        vlTOPp->hd38880_top_sim__DOT__phrase_fy 
                            = vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx;
                        vlTOPp->hd38880_top_sim__DOT__phrase_ok_fy 
                            = vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit;
                        if (vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit) {
                            vlTOPp->hd38880_top_sim__DOT__start_fy = 1U;
                        }
                    }
                }
            } else if ((2U & (IData)(vlTOPp->host_din))) {
                if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                    vlTOPp->hd38880_top_sim__DOT__stop_fy = 1U;
                }
            } else if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 3U;
            }
        } else if ((4U & (IData)(vlTOPp->host_din))) {
            if ((2U & (IData)(vlTOPp->host_din))) {
                if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                    __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 2U;
                }
            } else if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 1U;
            }
        } else if ((2U & (IData)(vlTOPp->host_din))) {
            if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = 4U;
                __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt = 0U;
                __Vdly__hd38880_top_sim__DOT__adset_addr_fy = 0U;
            }
        }
    }
    vlTOPp->hd38880_top_sim__DOT__start_vg = 0U;
    vlTOPp->hd38880_top_sim__DOT__stop_vg = 0U;
    if (vlTOPp->reset) {
        __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 0U;
        __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt = 0U;
        __Vdly__hd38880_top_sim__DOT__adset_addr_vg = 0U;
        vlTOPp->hd38880_top_sim__DOT__int1_cfg_vg = 0U;
        vlTOPp->hd38880_top_sim__DOT__int2_cfg_vg = 0xfU;
        vlTOPp->hd38880_top_sim__DOT__phrase_vg = 0U;
        vlTOPp->hd38880_top_sim__DOT__phrase_ok_vg = 0U;
    } else if ((((IData)(vlTOPp->host_wr) & ((IData)(vlTOPp->host_din) 
                                             >> 5U)) 
                & ((IData)(vlTOPp->host_din) >> 4U))) {
        if ((4U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state))) {
            if ((2U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 0U;
            } else if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 0U;
            } else {
                __Vdly__hd38880_top_sim__DOT__adset_addr_vg 
                    = (0xfffffU & (vlTOPp->hd38880_top_sim__DOT__adset_addr_vg 
                                   | ((0x13U >= ((IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt) 
                                                 << 2U))
                                       ? ((0xfU & (IData)(vlTOPp->host_din)) 
                                          << ((IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt) 
                                              << 2U))
                                       : 0U)));
                if ((4U == (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt))) {
                    __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 0U;
                } else {
                    __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt 
                        = (7U & ((IData)(1U) + (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt)));
                }
            }
        } else if ((2U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state))) {
            if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 0U;
            } else {
                vlTOPp->hd38880_top_sim__DOT__int2_cfg_vg 
                    = (0xfU & (IData)(vlTOPp->host_din));
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 0U;
            }
        } else if ((1U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state))) {
            vlTOPp->hd38880_top_sim__DOT__int1_cfg_vg 
                = (0xfU & (IData)(vlTOPp->host_din));
            __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 0U;
        } else if ((8U & (IData)(vlTOPp->host_din))) {
            if ((4U & (IData)(vlTOPp->host_din))) {
                if ((1U & (~ ((IData)(vlTOPp->host_din) 
                              >> 1U)))) {
                    if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                        vlTOPp->hd38880_top_sim__DOT__phrase_vg 
                            = vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx;
                        vlTOPp->hd38880_top_sim__DOT__phrase_ok_vg 
                            = vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit;
                        if (vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit) {
                            vlTOPp->hd38880_top_sim__DOT__start_vg = 1U;
                        }
                    }
                }
            } else if ((2U & (IData)(vlTOPp->host_din))) {
                if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                    vlTOPp->hd38880_top_sim__DOT__stop_vg = 1U;
                }
            } else if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 3U;
            }
        } else if ((4U & (IData)(vlTOPp->host_din))) {
            if ((2U & (IData)(vlTOPp->host_din))) {
                if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                    __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 2U;
                }
            } else if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 1U;
            }
        } else if ((2U & (IData)(vlTOPp->host_din))) {
            if ((1U & (~ (IData)(vlTOPp->host_din)))) {
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = 4U;
                __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt = 0U;
                __Vdly__hd38880_top_sim__DOT__adset_addr_vg = 0U;
            }
        }
    }
    vlTOPp->hd38880_top_sim__DOT__unpack_rom_rd = __Vdly__hd38880_top_sim__DOT__unpack_rom_rd;
    vlTOPp->dbg_dec_amp = vlTOPp->hd38880_top_sim__DOT__dec_amp;
    vlTOPp->dbg_dec_pitch = vlTOPp->hd38880_top_sim__DOT__dec_pitch;
    vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state 
        = __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__state;
    vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt 
        = __Vdly__hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt;
    vlTOPp->hd38880_top_sim__DOT__adset_addr_fy = __Vdly__hd38880_top_sim__DOT__adset_addr_fy;
    vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state 
        = __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__state;
    vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt 
        = __Vdly__hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt;
    vlTOPp->hd38880_top_sim__DOT__adset_addr_vg = __Vdly__hd38880_top_sim__DOT__adset_addr_vg;
    vlTOPp->dbg_rom_rd = vlTOPp->hd38880_top_sim__DOT__unpack_rom_rd;
    vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 0U;
    vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 0U;
    if ((0x4000U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy)) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 0U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x4297U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 1U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x44b6U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 2U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x4682U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 3U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x4927U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 4U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x4be0U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 5U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x4cc2U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 6U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x4e36U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 7U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x5000U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 8U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x5163U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 9U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x52c9U == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 0xaU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit)) 
         & (0x53fdU == vlTOPp->hd38880_top_sim__DOT__adset_addr_fy))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = 0xbU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = 1U;
    }
    vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0U;
    vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 0U;
    if ((0x4000U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg)) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x4325U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 1U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x44a2U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 2U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x45b7U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 3U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x46eeU == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 4U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x4838U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 5U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x4984U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 6U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x4b01U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 7U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x4c38U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 8U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x4de6U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 9U;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x4f43U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0xaU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x5048U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0xbU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x5160U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0xcU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x5289U == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0xdU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x539eU == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0xeU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
    if (((~ (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit)) 
         & (0x54ceU == vlTOPp->hd38880_top_sim__DOT__adset_addr_vg))) {
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = 0xfU;
        vlTOPp->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = 1U;
    }
}

VL_INLINE_OPT void Vhd38880_top_sim::_combo__TOP__4(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_combo__TOP__4\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if (vlTOPp->game_is_fantasy) {
        vlTOPp->dbg_phrase = vlTOPp->hd38880_top_sim__DOT__phrase_fy;
        vlTOPp->dbg_phrase_ok = vlTOPp->hd38880_top_sim__DOT__phrase_ok_fy;
        vlTOPp->hd38880_top_sim__DOT__ctrl_int2 = vlTOPp->hd38880_top_sim__DOT__int2_cfg_fy;
    } else {
        vlTOPp->dbg_phrase = vlTOPp->hd38880_top_sim__DOT__phrase_vg;
        vlTOPp->dbg_phrase_ok = vlTOPp->hd38880_top_sim__DOT__phrase_ok_vg;
        vlTOPp->hd38880_top_sim__DOT__ctrl_int2 = vlTOPp->hd38880_top_sim__DOT__int2_cfg_vg;
    }
    vlTOPp->hd38880_top_sim__DOT__ctrl_start = ((IData)(vlTOPp->force_en)
                                                 ? (IData)(vlTOPp->force_start)
                                                 : 
                                                ((IData)(vlTOPp->game_is_fantasy)
                                                  ? (IData)(vlTOPp->hd38880_top_sim__DOT__start_fy)
                                                  : (IData)(vlTOPp->hd38880_top_sim__DOT__start_vg)));
    if (vlTOPp->game_is_fantasy) {
        vlTOPp->hd38880_top_sim__DOT__real_adset = vlTOPp->hd38880_top_sim__DOT__adset_addr_fy;
        vlTOPp->hd38880_top_sim__DOT__ctrl_int1 = vlTOPp->hd38880_top_sim__DOT__int1_cfg_fy;
    } else {
        vlTOPp->hd38880_top_sim__DOT__real_adset = vlTOPp->hd38880_top_sim__DOT__adset_addr_vg;
        vlTOPp->hd38880_top_sim__DOT__ctrl_int1 = vlTOPp->hd38880_top_sim__DOT__int1_cfg_vg;
    }
    vlTOPp->dbg_int2 = vlTOPp->hd38880_top_sim__DOT__ctrl_int2;
    vlTOPp->dbg_ctrl_start = vlTOPp->hd38880_top_sim__DOT__ctrl_start;
    vlTOPp->dbg_adset_addr = vlTOPp->hd38880_top_sim__DOT__real_adset;
    vlTOPp->dbg_int1 = vlTOPp->hd38880_top_sim__DOT__ctrl_int1;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_loss_p 
        = (0x3ffffffU & VL_MULS_III(26,26,26, (0x3ffffffU 
                                               & VL_EXTENDS_II(26,15, 
                                                               ((9U 
                                                                 >= 
                                                                 (0xfU 
                                                                  & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                                                                     - (IData)(1U))))
                                                                 ? 
                                                                vlTOPp->hd38880_top_sim__DOT__lattice__DOT__b_delay
                                                                [
                                                                (0xfU 
                                                                 & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                                                                    - (IData)(1U)))]
                                                                 : 0U))), 
                                    ((4U & (IData)(vlTOPp->hd38880_top_sim__DOT__ctrl_int1))
                                      ? 0x1fcU : 0x3fffe00U)));
}

void Vhd38880_top_sim::_eval(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_eval\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    if (((IData)(vlTOPp->clk) & (~ (IData)(vlTOPp->__Vclklast__TOP__clk)))) {
        vlTOPp->_sequent__TOP__2(vlSymsp);
    }
    vlTOPp->_combo__TOP__4(vlSymsp);
    // Final
    vlTOPp->__Vclklast__TOP__clk = vlTOPp->clk;
}

VL_INLINE_OPT QData Vhd38880_top_sim::_change_request(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_change_request\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    return (vlTOPp->_change_request_1(vlSymsp));
}

VL_INLINE_OPT QData Vhd38880_top_sim::_change_request_1(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_change_request_1\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    // Change detection
    QData __req = false;  // Logically a bool
    return __req;
}

#ifdef VL_DEBUG
void Vhd38880_top_sim::_eval_debug_assertions() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_eval_debug_assertions\n"); );
    // Body
    if (VL_UNLIKELY((clk & 0xfeU))) {
        Verilated::overWidthError("clk");}
    if (VL_UNLIKELY((reset & 0xfeU))) {
        Verilated::overWidthError("reset");}
    if (VL_UNLIKELY((pause & 0xfeU))) {
        Verilated::overWidthError("pause");}
    if (VL_UNLIKELY((host_wr & 0xfeU))) {
        Verilated::overWidthError("host_wr");}
    if (VL_UNLIKELY((host_din & 0xc0U))) {
        Verilated::overWidthError("host_din");}
    if (VL_UNLIKELY((game_is_fantasy & 0xfeU))) {
        Verilated::overWidthError("game_is_fantasy");}
    if (VL_UNLIKELY((force_en & 0xfeU))) {
        Verilated::overWidthError("force_en");}
    if (VL_UNLIKELY((force_start & 0xfeU))) {
        Verilated::overWidthError("force_start");}
    if (VL_UNLIKELY((force_addr & 0xfff00000U))) {
        Verilated::overWidthError("force_addr");}
}
#endif  // VL_DEBUG
