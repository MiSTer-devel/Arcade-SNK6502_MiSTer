// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table internal header
//
// Internal details; most calling programs do not need this header,
// unless using verilator public meta comments.

#ifndef VERILATED_VHD38880_TOP_SIM__SYMS_H_
#define VERILATED_VHD38880_TOP_SIM__SYMS_H_  // guard

#include "verilated_heavy.h"

// INCLUDE MODULE CLASSES
#include "Vhd38880_top_sim.h"

// SYMS CLASS
class Vhd38880_top_sim__Syms : public VerilatedSyms {
  public:

    // LOCAL STATE
    const char* __Vm_namep;
    bool __Vm_didInit;

    // SUBCELL STATE
    Vhd38880_top_sim*              TOPp;

    // CREATORS
    Vhd38880_top_sim__Syms(VerilatedContext* contextp, Vhd38880_top_sim* topp, const char* namep);
    ~Vhd38880_top_sim__Syms();

    // METHODS
    inline const char* name() { return __Vm_namep; }

} VL_ATTR_ALIGNED(VL_CACHE_LINE_BYTES);

#endif  // guard
