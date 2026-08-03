// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Symbol table implementation internals

#include "Vhd38880_top_sim__Syms.h"
#include "Vhd38880_top_sim.h"



// FUNCTIONS
Vhd38880_top_sim__Syms::~Vhd38880_top_sim__Syms()
{
}

Vhd38880_top_sim__Syms::Vhd38880_top_sim__Syms(VerilatedContext* contextp, Vhd38880_top_sim* topp, const char* namep)
    // Setup locals
    : VerilatedSyms{contextp}
    , __Vm_namep(namep)
    , __Vm_didInit(false)
    // Setup submodule names
{
    // Pointer to top level
    TOPp = topp;
    // Setup each module's pointers to their submodules
    // Setup each module's pointer back to symbol table (for public functions)
    TOPp->__Vconfigure(this, true);
}
