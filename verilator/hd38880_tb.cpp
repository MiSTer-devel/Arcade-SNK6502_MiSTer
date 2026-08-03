// hd38880_tb.cpp -- Verilator bench for the SNK6502 HD38880 speech chain.
//
// PROOF OF PATH: the host stimulus below is not invented. It is the exact
// $3400 write stream produced by Vanguard's own speech routine, reconstructed
// from Useful Information/vanguard_maincpu-4000.dasm:
//
//   $6F30 phrase routine : INT1byte, $6F, $89, addr0, addr1, addr2, $C0
//                          with `lda #$00 / sta $3400` separators before
//                          INT1, INT2, SYSPD, the first ADSET byte, and START
//   $6F7B byte transmit  : HIGH nibble first, then low nibble
//   $6F8E nibble transmit: write ($30|n)  [CTP=1,CMV=1 -> latch]
//                          write ($20|n)  [CTP=0,CMV=1 -> strobe low]
//   $6F9D address table  : 16 groups of 4 bytes (verified: all 16 decode to
//                          the documented phrase addresses)
//
// The MAME trace (vanguard_maincpu.trace) confirms this path executes 16 times
// with the $9A gate never blocking, firing phrases 1 ($04), 2 ($08) and 14 ($38).

#include "Vhd38880_top_sim.h"
#include "verilated.h"
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <cstdint>
#include <vector>
#include <string>

static Vhd38880_top_sim* dut;
static vluint64_t main_time = 0;
double sc_time_stamp() { return main_time; }

// ---- speech ROM model: 8KB window, 1-cycle synchronous read (matches dpram) --
static uint8_t rom[8192];
static uint8_t rom_q;         // registered output presented to the DUT

// ---- capture ---------------------------------------------------------------
struct Frame {
    int silent, amp, pitch, k1, k2, k3, k4, k5, k6, k7, k8, k9, k10;
};
static std::vector<Frame> frames;
static std::vector<int16_t> audio;
static long audio_nonzero = 0;
static int  audio_peak = 0;

// ctrl observation
static bool  seen_start = false;
static int   seen_phrase = -1, seen_phrase_ok = -1;
static unsigned seen_adset = 0;
static int   seen_int1 = -1, seen_int2 = -1;

static void tick() {
    // ---- negedge ----
    dut->clk = 0;
    dut->eval();

    // ---- posedge ----
    dut->clk = 1;
    dut->rom_data = rom_q;          // present last cycle's fetch (1-cyc latency)
    dut->eval();
    main_time++;

    // capture AFTER the edge
    if (dut->dbg_ctrl_start && !seen_start) {
        seen_start     = true;
        seen_phrase    = dut->dbg_phrase;
        seen_phrase_ok = dut->dbg_phrase_ok;
        seen_adset     = dut->dbg_adset_addr;
        seen_int1      = dut->dbg_int1;
        seen_int2      = dut->dbg_int2;
    }
    if (dut->dbg_frame_ack) {
        Frame f;
        f.silent = dut->dbg_f_silent;
        f.amp    = dut->dbg_f_amp;
        f.pitch  = dut->dbg_f_pitch;
        f.k1     = dut->dbg_f_k1;   f.k2  = dut->dbg_f_k2;
        f.k3     = dut->dbg_f_k3;   f.k4  = dut->dbg_f_k4;
        f.k5     = dut->dbg_f_k5;   f.k6  = dut->dbg_f_k6;
        f.k7     = dut->dbg_f_k7;   f.k8  = dut->dbg_f_k8;
        f.k9     = dut->dbg_f_k9;   f.k10 = dut->dbg_f_k10;
        frames.push_back(f);
    }
    if (dut->dbg_audio_stb) {
        // audio_out is signed [14:0]; Verilator hands it back zero-extended in
        // a 16-bit word, so sign-extend from bit 14 before treating it as PCM.
        int v = dut->audio_out & 0x7FFF;
        if (v & 0x4000) v -= 0x8000;
        int16_t s = (int16_t)v;
        audio.push_back(s);
        if (s != 0) audio_nonzero++;
        int a = s < 0 ? -s : s;
        if (a > audio_peak) audio_peak = a;
    }

    // schedule next cycle's ROM fetch from the address the DUT is presenting
    rom_q = rom[dut->rom_addr & 0x1FFF];
}

static void idle(long n) { for (long i = 0; i < n; i++) tick(); }

// ---- host write: host_wr is exactly 1 clk wide (matches io_wr & cpu_clken) ---
static const long WRITE_GAP = 200;   // ~12 CPU cycles @ clk/16, realistic spacing

static void host_write(uint8_t val) {
    dut->host_wr  = 1;
    dut->host_din = val & 0x3F;
    tick();
    dut->host_wr  = 0;
    idle(WRITE_GAP);
}

// $6F8E: two writes per nibble
static void send_nibble(uint8_t n) {
    n &= 0x0F;
    host_write(0x30 | n);   // CTP=1, CMV=1  -> latched here
    host_write(0x20 | n);   // CTP=0, CMV=1  -> strobe low
}

// $6F7B: high nibble first
static void send_byte(uint8_t b) {
    send_nibble(b >> 4);
    send_nibble(b & 0x0F);
}

static void clear_port() { host_write(0x00); }

// Vanguard address table at $6F9D, raw bytes straight out of the disassembly.
static const uint8_t vg_table[16][4] = {
    {0x44,0x20,0x00,0x40}, {0x44,0x25,0x23,0x40},
    {0x44,0x22,0xA4,0x40}, {0x44,0x27,0xB5,0x40},
    {0x44,0x2E,0xE6,0x40}, {0x44,0x28,0x38,0x40},
    {0x44,0x24,0x89,0x40}, {0x44,0x21,0x0B,0x40},
    {0x44,0x28,0x3C,0x40}, {0x44,0x26,0xED,0x40},
    {0x44,0x23,0x4F,0x40}, {0x44,0x28,0x40,0x50},
    {0x44,0x20,0x61,0x50}, {0x44,0x29,0x82,0x50},
    {0x44,0x2E,0x93,0x50}, {0x44,0x2E,0xC4,0x50},
};

// Faithful replay of routine $6F30 for phrase p.
static void play_phrase(int p) {
    const uint8_t* t = vg_table[p];
    clear_port();  send_byte(t[0]);   // INT1 byte ($44)
    clear_port();  send_byte(0x6F);   // INT2, operand F
    clear_port();  send_byte(0x89);   // SYSPD, operand 9
    clear_port();  send_byte(t[1]);   // ADSET + addr nibbles
                   send_byte(t[2]);   // (no separator between ADSET bytes)
                   send_byte(t[3]);
    clear_port();  send_byte(0xC0);   // START
}

static void write_wav(const char* path, const std::vector<int16_t>& d, int rate) {
    FILE* f = fopen(path, "wb");
    if (!f) return;
    uint32_t dlen = (uint32_t)(d.size() * 2), rlen = 36 + dlen;
    uint32_t fmtlen = 16, brate = rate * 2; uint16_t one = 1, ch = 1, ba = 2, bps = 16;
    fwrite("RIFF", 1, 4, f); fwrite(&rlen, 4, 1, f); fwrite("WAVE", 1, 4, f);
    fwrite("fmt ", 1, 4, f); fwrite(&fmtlen, 4, 1, f);
    fwrite(&one, 2, 1, f);  fwrite(&ch, 2, 1, f);
    fwrite(&rate, 4, 1, f); fwrite(&brate, 4, 1, f);
    fwrite(&ba, 2, 1, f);   fwrite(&bps, 2, 1, f);
    fwrite("data", 1, 4, f); fwrite(&dlen, 4, 1, f);
    // scale 15-bit -> 16-bit for listenable output
    for (size_t i = 0; i < d.size(); i++) { int16_t v = (int16_t)(d[i] * 2); fwrite(&v, 2, 1, f); }
    fclose(f);
}

int main(int argc, char** argv) {
    Verilated::commandArgs(argc, argv);

    int phrase = 2;            // default: the one the trace fires 13x
    bool force = false;        // reproduce the DIAG forced-start instead
    bool zerorom = false;      // model "speech ROM never landed in BRAM"
    const char* rompath = "roms/vanguard_speech.bin";
    for (int i = 1; i < argc; i++) {
        if (!strncmp(argv[i], "--phrase=", 9)) phrase = atoi(argv[i] + 9);
        else if (!strcmp(argv[i], "--force"))    force = true;
        else if (!strcmp(argv[i], "--zerorom"))  zerorom = true;
        else if (!strncmp(argv[i], "--rom=", 6)) rompath = argv[i] + 6;
    }

    memset(rom, 0, sizeof(rom));
    size_t got = 0;
    if (zerorom) {
        printf("speech ROM: *** ALL ZEROS (modelling a failed/absent load) ***\n");
    } else {
        FILE* rf = fopen(rompath, "rb");
        if (!rf) { fprintf(stderr, "cannot open %s\n", rompath); return 1; }
        got = fread(rom, 1, sizeof(rom), rf);
        fclose(rf);
        printf("speech ROM: %s (%zu bytes)\n", rompath, got);
    }
    printf("mode: %s, phrase %d (expect ADSET $%05X)\n",
           force ? "FORCED-START (reproduces DIAG-REVERT-2026-08-01)" : "REAL CPU stimulus via hd38880_ctrl",
           phrase, 0x4000 + 0);

    dut = new Vhd38880_top_sim;
    dut->clk = 0; dut->reset = 1; dut->pause = 0;
    dut->host_wr = 0; dut->host_din = 0; dut->game_is_fantasy = 0;
    dut->force_en = force ? 1 : 0; dut->force_start = 0; dut->force_addr = 0;
    dut->rom_data = 0;
    idle(64);
    dut->reset = 0;
    idle(64);

    if (force) {
        // decode the expected address from the table the same way the CPU does
        const uint8_t* t = vg_table[phrase];
        uint8_t nb[6] = { (uint8_t)(t[1]>>4), (uint8_t)(t[1]&0xF),
                          (uint8_t)(t[2]>>4), (uint8_t)(t[2]&0xF),
                          (uint8_t)(t[3]>>4), (uint8_t)(t[3]&0xF) };
        unsigned addr = 0;
        for (int i = 0; i < 5; i++) addr |= (unsigned)nb[1 + i] << (4 * i);
        dut->force_addr  = addr;
        dut->force_start = 1; tick(); dut->force_start = 0;
        printf("forced start at $%05X\n", addr);
    } else {
        play_phrase(phrase);
    }

    // run long enough for the whole phrase: 53 frames * 225780 clk + margin
    const long MAXC = 25000000;
    long c = 0;
    int  done_seen = 0;
    while (c < MAXC) {
        tick(); c++;
        if (dut->dbg_unpack_done) { if (++done_seen > 400000) break; }
    }

    printf("\n=== CTRL DECODE ===\n");
    if (!force) {
        printf("start pulse seen : %s\n", seen_start ? "YES" : "NO");
        printf("adset_addr       : $%05X\n", seen_adset);
        printf("phrase / ok      : %d / %d\n", seen_phrase, seen_phrase_ok);
        printf("int1 / int2      : $%X / $%X\n", seen_int1, seen_int2);
    } else {
        printf("(forced mode - ctrl bypassed)\n");
    }

    printf("\n=== UNPACK FRAMES ===\n");
    printf("frames produced  : %zu\n", frames.size());
    {
        size_t sil = 0, voiced = 0;
        for (size_t i = 0; i < frames.size(); i++) {
            if (frames[i].silent || frames[i].amp == 0) sil++; else voiced++;
        }
        printf("  silent / voiced: %zu / %zu\n", sil, voiced);
    }

    printf("\n=== LATTICE AUDIO ===\n");
    printf("samples          : %zu\n", audio.size());
    printf("nonzero samples  : %ld\n", audio_nonzero);
    printf("peak |amplitude| : %d  (of 16384 full-scale 15-bit)\n", audio_peak);
    printf("after >>>6 mix   : %d  (of 32768 output full-scale)\n", audio_peak >> 6);

    char fn[256];
    snprintf(fn, sizeof(fn), "out_frames_p%d%s.csv", phrase, force ? "_forced" : "");
    FILE* cf = fopen(fn, "w");
    if (cf) {
        fprintf(cf, "frame,silent,amp,pitch,k1,k2,k3,k4,k5,k6,k7,k8,k9,k10\n");
        for (size_t i = 0; i < frames.size(); i++) {
            const Frame& f = frames[i];
            fprintf(cf, "%zu,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n", i,
                    f.silent, f.amp, f.pitch, f.k1, f.k2, f.k3, f.k4,
                    f.k5, f.k6, f.k7, f.k8, f.k9, f.k10);
        }
        fclose(cf);
        printf("\nwrote %s\n", fn);
    }
    snprintf(fn, sizeof(fn), "out_audio_p%d%s.wav", phrase, force ? "_forced" : "");
    write_wav(fn, audio, 8000);
    printf("wrote %s\n", fn);

    dut->final();
    delete dut;
    return 0;
}
