// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vhd38880_top_sim.h for the primary calling header

#include "Vhd38880_top_sim.h"
#include "Vhd38880_top_sim__Syms.h"

//==========

Vhd38880_top_sim::Vhd38880_top_sim(VerilatedContext* _vcontextp__, const char* _vcname__)
    : VerilatedModule{_vcname__}
 {
    Vhd38880_top_sim__Syms* __restrict vlSymsp = __VlSymsp = new Vhd38880_top_sim__Syms(_vcontextp__, this, name());
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Reset internal values

    // Reset structure values
    _ctor_var_reset(this);
}

void Vhd38880_top_sim::__Vconfigure(Vhd38880_top_sim__Syms* vlSymsp, bool first) {
    if (false && first) {}  // Prevent unused
    this->__VlSymsp = vlSymsp;
    if (false && this->__VlSymsp) {}  // Prevent unused
    vlSymsp->_vm_contextp__->timeunit(-12);
    vlSymsp->_vm_contextp__->timeprecision(-12);
}

Vhd38880_top_sim::~Vhd38880_top_sim() {
    VL_DO_CLEAR(delete __VlSymsp, __VlSymsp = nullptr);
}

void Vhd38880_top_sim::_initial__TOP__1(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_initial__TOP__1\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0U] = 0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[1U] = 0x27U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[2U] = 0x28U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[3U] = 0x29U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[4U] = 0x29U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[5U] = 0x29U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[6U] = 0x2aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[7U] = 0x2aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[8U] = 0x2aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[9U] = 0x2aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0xaU] = 0x2aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0xbU] = 0x2bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0xcU] = 0x2dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0xdU] = 0x2dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0xeU] = 0x2dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0xfU] = 0x30U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x10U] = 0x37U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x11U] = 0x37U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x12U] = 0x37U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x13U] = 0x37U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x14U] = 0x3fU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x15U] = 0x40U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x16U] = 0x40U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x17U] = 0x40U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x18U] = 0x40U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x19U] = 0x47U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x1aU] = 0x47U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x1bU] = 0x5cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x1cU] = 0x5cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x1dU] = 0x5cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x1eU] = 0x5cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x1fU] = 0x5cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x20U] = 0x81U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x21U] = 0x8bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x22U] = 0x8bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x23U] = 0x8bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x24U] = 0x8bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x25U] = 0x8bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x26U] = 0x98U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x27U] = 0xa0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x28U] = 0xa0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x29U] = 0xa0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x2aU] = 0xa0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x2bU] = 0xa0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x2cU] = 0xbcU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x2dU] = 0xbcU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x2eU] = 0xc1U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x2fU] = 0xc2U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x30U] = 0xdbU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x31U] = 0xdbU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x32U] = 0xdbU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x33U] = 0xdbU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x34U] = 0xecU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x35U] = 0xecU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x36U] = 0xecU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x37U] = 0xecU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x38U] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x39U] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x3aU] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x3bU] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x3cU] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x3dU] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x3eU] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table[0x3fU] = 0xffU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0U] = 0x10U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[1U] = 0x10U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[2U] = 0x11U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[3U] = 0x12U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[4U] = 0x13U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[5U] = 0x14U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[6U] = 0x14U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[7U] = 0x16U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[8U] = 0x17U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[9U] = 0x18U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0xaU] = 0x18U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0xbU] = 0x1aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0xcU] = 0x1bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0xdU] = 0x1cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0xeU] = 0x1cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0xfU] = 0x1eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x10U] = 0x1fU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x11U] = 0x1fU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x12U] = 0x20U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x13U] = 0x22U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x14U] = 0x23U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x15U] = 0x23U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x16U] = 0x23U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x17U] = 0x26U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x18U] = 0x27U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x19U] = 0x28U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x1aU] = 0x29U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x1bU] = 0x29U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x1cU] = 0x2bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x1dU] = 0x2bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x1eU] = 0x2dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x1fU] = 0x2dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x20U] = 0x2eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x21U] = 0x2fU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x22U] = 0x30U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x23U] = 0x30U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x24U] = 0x34U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x25U] = 0x36U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x26U] = 0x38U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x27U] = 0x3aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x28U] = 0x3cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x29U] = 0x3eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x2aU] = 0x40U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x2bU] = 0x41U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x2cU] = 0x44U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x2dU] = 0x46U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x2eU] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x2fU] = 0x4aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x30U] = 0x4aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x31U] = 0x4cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x32U] = 0x4eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x33U] = 0x51U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x34U] = 0x53U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x35U] = 0x53U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x36U] = 0x55U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x37U] = 0x55U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x38U] = 0x55U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x39U] = 0x5eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x3aU] = 0x5eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x3bU] = 0x62U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x3cU] = 0x62U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x3dU] = 0x62U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x3eU] = 0x62U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table[0x3fU] = 0x62U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[0U] = 0x399U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[1U] = 0x36fU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[2U] = 0x365U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[3U] = 0x365U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[4U] = 0x33bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[5U] = 0x2fdU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[6U] = 0x2deU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[7U] = 0x2bfU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[8U] = 0x296U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[9U] = 0x277U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[0xaU] = 0x258U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[0xbU] = 0x24dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[0xcU] = 0x239U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[0xdU] = 0x22eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[0xeU] = 0x224U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k1_table[0xfU] = 0x224U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[0U] = 0x160U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[1U] = 0x160U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[2U] = 0x160U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[3U] = 0x160U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[4U] = 0x155U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[5U] = 0x155U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[6U] = 0x14bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[7U] = 0x14bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[8U] = 0x136U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[9U] = 0x103U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[0xaU] = 0xd9U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[0xbU] = 0xc5U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[0xcU] = 0x67U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[0xdU] = 0x5dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[0xeU] = 0x3e1U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k2_table[0xfU] = 0x3a3U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[0U] = 0x53U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[1U] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[2U] = 0x15U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[3U] = 0xaU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[4U] = 0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[5U] = 0x3c2U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[6U] = 0x384U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k3_table[7U] = 0x384U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[0U] = 0xd9U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[1U] = 0xd9U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[2U] = 0x91U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[3U] = 0x72U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[4U] = 0x72U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[5U] = 0x67U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[6U] = 0x67U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k4_table[7U] = 0x67U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[0U] = 0x91U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[1U] = 0x5dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[2U] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[3U] = 0x15U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[4U] = 0x3ccU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[5U] = 0x3ccU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[6U] = 0x38eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k5_table[7U] = 0x35aU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[0U] = 0xcfU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[1U] = 0xb0U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[2U] = 0x87U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[3U] = 0x87U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[4U] = 0x72U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[5U] = 0x5dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[6U] = 0x5dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k6_table[7U] = 0x5dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[0U] = 0x87U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[1U] = 0x3eU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[2U] = 0x34U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[3U] = 0x1fU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[4U] = 0x1fU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[5U] = 0xaU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[6U] = 0xaU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k7_table[7U] = 0x3f6U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[0U] = 0x9bU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[1U] = 0x91U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[2U] = 0x7cU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[3U] = 0x67U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[4U] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[5U] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[6U] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k8_table[7U] = 0x34U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[0U] = 0x5dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[1U] = 0x5dU;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[2U] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[3U] = 0x34U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[4U] = 0x34U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[5U] = 0x15U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[6U] = 0x15U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k9_table[7U] = 0x15U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[0U] = 0x87U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[1U] = 0x87U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[2U] = 0x53U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[3U] = 0x48U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[4U] = 0x34U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[5U] = 0x29U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[6U] = 0x15U;
    vlTOPp->hd38880_top_sim__DOT__dectab__DOT__k10_table[7U] = 0x15U;
}

void Vhd38880_top_sim::_settle__TOP__3(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_settle__TOP__3\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->dbg_audio_stb = vlTOPp->hd38880_top_sim__DOT__audio_stb_w;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_now 
        = ((9U >= (0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                           - (IData)(1U)))) ? vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_cur
           [(0xfU & ((IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__stage) 
                     - (IData)(1U)))] : 0U);
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[0U] 
        = vlTOPp->hd38880_top_sim__DOT__k1_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[1U] 
        = vlTOPp->hd38880_top_sim__DOT__k2_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[2U] 
        = vlTOPp->hd38880_top_sim__DOT__k3_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[3U] 
        = vlTOPp->hd38880_top_sim__DOT__k4_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[4U] 
        = vlTOPp->hd38880_top_sim__DOT__k5_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[5U] 
        = vlTOPp->hd38880_top_sim__DOT__k6_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[6U] 
        = vlTOPp->hd38880_top_sim__DOT__k7_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[7U] 
        = vlTOPp->hd38880_top_sim__DOT__k8_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[8U] 
        = vlTOPp->hd38880_top_sim__DOT__k9_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_in[9U] 
        = vlTOPp->hd38880_top_sim__DOT__k10_lat;
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__sample_tick 
        = (0x582U == (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__div_cnt));
    vlTOPp->hd38880_top_sim__DOT__frame_tick = (0x371f3U 
                                                == vlTOPp->hd38880_top_sim__DOT__frame_cnt);
    vlTOPp->dbg_frame_we = vlTOPp->hd38880_top_sim__DOT__frame_we;
    vlTOPp->rom_addr = (0x1fffU & vlTOPp->hd38880_top_sim__DOT__unpack_rom_addr);
    vlTOPp->dbg_frame_valid = vlTOPp->hd38880_top_sim__DOT__frame_valid;
    vlTOPp->dbg_frame_ack = vlTOPp->hd38880_top_sim__DOT__frame_ack;
    vlTOPp->dbg_unpack_done = vlTOPp->hd38880_top_sim__DOT__unpack_done;
    vlTOPp->dbg_unpack_rom_addr = vlTOPp->hd38880_top_sim__DOT__unpack_rom_addr;
    vlTOPp->dbg_f_silent = vlTOPp->hd38880_top_sim__DOT__f_silent;
    vlTOPp->dbg_f_amp = vlTOPp->hd38880_top_sim__DOT__f_amp;
    vlTOPp->dbg_f_pitch = vlTOPp->hd38880_top_sim__DOT__f_pitch;
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
    vlTOPp->hd38880_top_sim__DOT__unpack__DOT__pk_amp 
        = (0x3fU & (IData)(vlTOPp->hd38880_top_sim__DOT__unpack__DOT__resv));
    vlTOPp->dbg_rom_rd = vlTOPp->hd38880_top_sim__DOT__unpack_rom_rd;
    if (vlTOPp->game_is_fantasy) {
        vlTOPp->dbg_phrase = vlTOPp->hd38880_top_sim__DOT__phrase_fy;
        vlTOPp->dbg_phrase_ok = vlTOPp->hd38880_top_sim__DOT__phrase_ok_fy;
    } else {
        vlTOPp->dbg_phrase = vlTOPp->hd38880_top_sim__DOT__phrase_vg;
        vlTOPp->dbg_phrase_ok = vlTOPp->hd38880_top_sim__DOT__phrase_ok_vg;
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
    if (vlTOPp->game_is_fantasy) {
        vlTOPp->hd38880_top_sim__DOT__real_adset = vlTOPp->hd38880_top_sim__DOT__adset_addr_fy;
        vlTOPp->hd38880_top_sim__DOT__ctrl_int2 = vlTOPp->hd38880_top_sim__DOT__int2_cfg_fy;
    } else {
        vlTOPp->hd38880_top_sim__DOT__real_adset = vlTOPp->hd38880_top_sim__DOT__adset_addr_vg;
        vlTOPp->hd38880_top_sim__DOT__ctrl_int2 = vlTOPp->hd38880_top_sim__DOT__int2_cfg_vg;
    }
    vlTOPp->hd38880_top_sim__DOT__ctrl_start = ((IData)(vlTOPp->force_en)
                                                 ? (IData)(vlTOPp->force_start)
                                                 : 
                                                ((IData)(vlTOPp->game_is_fantasy)
                                                  ? (IData)(vlTOPp->hd38880_top_sim__DOT__start_fy)
                                                  : (IData)(vlTOPp->hd38880_top_sim__DOT__start_vg)));
    vlTOPp->hd38880_top_sim__DOT__ctrl_int1 = ((IData)(vlTOPp->game_is_fantasy)
                                                ? (IData)(vlTOPp->hd38880_top_sim__DOT__int1_cfg_fy)
                                                : (IData)(vlTOPp->hd38880_top_sim__DOT__int1_cfg_vg));
    vlTOPp->hd38880_top_sim__DOT__dec_amp = vlTOPp->hd38880_top_sim__DOT__dectab__DOT__amp_table
        [vlTOPp->hd38880_top_sim__DOT__f_amp];
    vlTOPp->hd38880_top_sim__DOT__dec_pitch = ((0U 
                                                == (IData)(vlTOPp->hd38880_top_sim__DOT__f_pitch))
                                                ? 0U
                                                : vlTOPp->hd38880_top_sim__DOT__dectab__DOT__pitch_table
                                               [vlTOPp->hd38880_top_sim__DOT__f_pitch]);
    vlTOPp->hd38880_top_sim__DOT__lattice__DOT__p_kf 
        = (0x1ffffffU & VL_MULS_III(25,25,25, (0x1ffffffU 
                                               & VL_EXTENDS_II(25,10, (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__k_now))), 
                                    (0x1ffffffU & VL_EXTENDS_II(25,15, (IData)(vlTOPp->hd38880_top_sim__DOT__lattice__DOT__f_val)))));
    vlTOPp->dbg_adset_addr = vlTOPp->hd38880_top_sim__DOT__real_adset;
    vlTOPp->dbg_int2 = vlTOPp->hd38880_top_sim__DOT__ctrl_int2;
    vlTOPp->dbg_ctrl_start = vlTOPp->hd38880_top_sim__DOT__ctrl_start;
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
    vlTOPp->dbg_dec_amp = vlTOPp->hd38880_top_sim__DOT__dec_amp;
    vlTOPp->dbg_dec_pitch = vlTOPp->hd38880_top_sim__DOT__dec_pitch;
}

void Vhd38880_top_sim::_eval_initial(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_eval_initial\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_initial__TOP__1(vlSymsp);
    vlTOPp->__Vclklast__TOP__clk = vlTOPp->clk;
}

void Vhd38880_top_sim::final() {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::final\n"); );
    // Variables
    Vhd38880_top_sim__Syms* __restrict vlSymsp = this->__VlSymsp;
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
}

void Vhd38880_top_sim::_eval_settle(Vhd38880_top_sim__Syms* __restrict vlSymsp) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_eval_settle\n"); );
    Vhd38880_top_sim* const __restrict vlTOPp VL_ATTR_UNUSED = vlSymsp->TOPp;
    // Body
    vlTOPp->_settle__TOP__3(vlSymsp);
}

void Vhd38880_top_sim::_ctor_var_reset(Vhd38880_top_sim* self) {
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vhd38880_top_sim::_ctor_var_reset\n"); );
    // Body
    if (false && self) {}  // Prevent unused
    self->clk = VL_RAND_RESET_I(1);
    self->reset = VL_RAND_RESET_I(1);
    self->pause = VL_RAND_RESET_I(1);
    self->host_wr = VL_RAND_RESET_I(1);
    self->host_din = VL_RAND_RESET_I(6);
    self->game_is_fantasy = VL_RAND_RESET_I(1);
    self->force_en = VL_RAND_RESET_I(1);
    self->force_start = VL_RAND_RESET_I(1);
    self->force_addr = VL_RAND_RESET_I(20);
    self->rom_addr = VL_RAND_RESET_I(13);
    self->rom_data = VL_RAND_RESET_I(8);
    self->audio_out = VL_RAND_RESET_I(15);
    self->dbg_adset_addr = VL_RAND_RESET_I(20);
    self->dbg_ctrl_start = VL_RAND_RESET_I(1);
    self->dbg_phrase = VL_RAND_RESET_I(4);
    self->dbg_phrase_ok = VL_RAND_RESET_I(1);
    self->dbg_int1 = VL_RAND_RESET_I(4);
    self->dbg_int2 = VL_RAND_RESET_I(4);
    self->dbg_frame_valid = VL_RAND_RESET_I(1);
    self->dbg_frame_ack = VL_RAND_RESET_I(1);
    self->dbg_frame_we = VL_RAND_RESET_I(1);
    self->dbg_unpack_done = VL_RAND_RESET_I(1);
    self->dbg_rom_rd = VL_RAND_RESET_I(1);
    self->dbg_unpack_rom_addr = VL_RAND_RESET_I(20);
    self->dbg_f_silent = VL_RAND_RESET_I(1);
    self->dbg_f_amp = VL_RAND_RESET_I(6);
    self->dbg_f_pitch = VL_RAND_RESET_I(6);
    self->dbg_f_k1 = VL_RAND_RESET_I(7);
    self->dbg_f_k2 = VL_RAND_RESET_I(5);
    self->dbg_f_k3 = VL_RAND_RESET_I(3);
    self->dbg_f_k4 = VL_RAND_RESET_I(3);
    self->dbg_f_k5 = VL_RAND_RESET_I(3);
    self->dbg_f_k6 = VL_RAND_RESET_I(3);
    self->dbg_f_k7 = VL_RAND_RESET_I(3);
    self->dbg_f_k8 = VL_RAND_RESET_I(3);
    self->dbg_f_k9 = VL_RAND_RESET_I(3);
    self->dbg_f_k10 = VL_RAND_RESET_I(3);
    self->dbg_dec_amp = VL_RAND_RESET_I(8);
    self->dbg_dec_pitch = VL_RAND_RESET_I(8);
    self->dbg_audio_stb = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__start_vg = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__stop_vg = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__phrase_ok_vg = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__adset_addr_vg = VL_RAND_RESET_I(20);
    self->hd38880_top_sim__DOT__int1_cfg_vg = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__int2_cfg_vg = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__phrase_vg = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__start_fy = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__stop_fy = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__phrase_ok_fy = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__adset_addr_fy = VL_RAND_RESET_I(20);
    self->hd38880_top_sim__DOT__int1_cfg_fy = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__int2_cfg_fy = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__phrase_fy = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__real_adset = VL_RAND_RESET_I(20);
    self->hd38880_top_sim__DOT__ctrl_start = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__ctrl_int1 = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__ctrl_int2 = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__unpack_done = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__unpack_rom_addr = VL_RAND_RESET_I(20);
    self->hd38880_top_sim__DOT__unpack_rom_valid = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__unpack_rom_rd = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__frame_valid = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__frame_ack = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__f_silent = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__f_amp = VL_RAND_RESET_I(6);
    self->hd38880_top_sim__DOT__f_pitch = VL_RAND_RESET_I(6);
    self->hd38880_top_sim__DOT__f_k1 = VL_RAND_RESET_I(7);
    self->hd38880_top_sim__DOT__f_k2 = VL_RAND_RESET_I(5);
    self->hd38880_top_sim__DOT__f_k3 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__f_k4 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__f_k5 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__f_k6 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__f_k7 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__f_k8 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__f_k9 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__f_k10 = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__dec_amp = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__dec_pitch = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__frame_cnt = VL_RAND_RESET_I(24);
    self->hd38880_top_sim__DOT__frame_tick = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__frame_we = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__amp_lat = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__pitch_lat = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__k1_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k2_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k3_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k4_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k5_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k6_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k7_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k8_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k9_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__k10_lat = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__done_d = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__audio_stb_w = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__ctrl_vanguard__DOT__state = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__ctrl_vanguard__DOT__adset_cnt = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_idx = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__ctrl_vanguard__DOT__match_hit = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__ctrl_fantasy__DOT__state = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__ctrl_fantasy__DOT__adset_cnt = VL_RAND_RESET_I(3);
    self->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_idx = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__ctrl_fantasy__DOT__match_hit = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__unpack__DOT__resv = VL_RAND_RESET_Q(64);
    self->hd38880_top_sim__DOT__unpack__DOT__nbits = VL_RAND_RESET_I(7);
    self->hd38880_top_sim__DOT__unpack__DOT__pk_amp = VL_RAND_RESET_I(6);
    self->hd38880_top_sim__DOT__unpack__DOT__state = VL_RAND_RESET_I(3);
    for (int __Vi0=0; __Vi0<64; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__amp_table[__Vi0] = VL_RAND_RESET_I(8);
    }
    for (int __Vi0=0; __Vi0<64; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__pitch_table[__Vi0] = VL_RAND_RESET_I(8);
    }
    for (int __Vi0=0; __Vi0<16; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k1_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<16; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k2_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k3_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k4_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k5_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k6_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k7_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k8_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k9_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<8; ++__Vi0) {
        self->hd38880_top_sim__DOT__dectab__DOT__k10_table[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<10; ++__Vi0) {
        self->hd38880_top_sim__DOT__lattice__DOT__k_in[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<10; ++__Vi0) {
        self->hd38880_top_sim__DOT__lattice__DOT__k_tgt[__Vi0] = VL_RAND_RESET_I(10);
    }
    for (int __Vi0=0; __Vi0<10; ++__Vi0) {
        self->hd38880_top_sim__DOT__lattice__DOT__k_cur[__Vi0] = VL_RAND_RESET_I(10);
    }
    self->hd38880_top_sim__DOT__lattice__DOT__amp_tgt = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__lattice__DOT__amp_cur = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__lattice__DOT__pitch_tgt = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__lattice__DOT__pitch_cur = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__lattice__DOT__samp_cnt = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__lattice__DOT__interp_idx = VL_RAND_RESET_I(4);
    self->hd38880_top_sim__DOT__lattice__DOT__div_cnt = VL_RAND_RESET_I(16);
    self->hd38880_top_sim__DOT__lattice__DOT__sample_tick = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__lattice__DOT__pitch_cnt = VL_RAND_RESET_I(8);
    self->hd38880_top_sim__DOT__lattice__DOT__lfsr = VL_RAND_RESET_I(16);
    self->hd38880_top_sim__DOT__lattice__DOT__excite = VL_RAND_RESET_I(15);
    for (int __Vi0=0; __Vi0<10; ++__Vi0) {
        self->hd38880_top_sim__DOT__lattice__DOT__b_delay[__Vi0] = VL_RAND_RESET_I(15);
    }
    self->hd38880_top_sim__DOT__lattice__DOT__f_val = VL_RAND_RESET_I(15);
    for (int __Vi0=0; __Vi0<10; ++__Vi0) {
        self->hd38880_top_sim__DOT__lattice__DOT__b_new[__Vi0] = VL_RAND_RESET_I(15);
    }
    self->hd38880_top_sim__DOT__lattice__DOT__stage = VL_RAND_RESET_I(5);
    self->hd38880_top_sim__DOT__lattice__DOT__phase = VL_RAND_RESET_I(2);
    self->hd38880_top_sim__DOT__lattice__DOT__busy = VL_RAND_RESET_I(1);
    self->hd38880_top_sim__DOT__lattice__DOT__k_now = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__lattice__DOT__b_loss_p = VL_RAND_RESET_I(26);
    self->hd38880_top_sim__DOT__lattice__DOT__p_kf = VL_RAND_RESET_I(25);
    self->hd38880_top_sim__DOT__lattice__DOT____Vlvbound3 = VL_RAND_RESET_I(15);
    self->hd38880_top_sim__DOT__lattice__DOT____Vlvbound4 = VL_RAND_RESET_I(15);
    self->hd38880_top_sim__DOT__lattice__DOT____Vlvbound7 = VL_RAND_RESET_I(10);
    self->hd38880_top_sim__DOT__lattice__DOT____Vlvbound8 = VL_RAND_RESET_I(10);
}
