"""SNK6502 sound-effect boards for dsnd_engine (circuits traced in Claude/snk6502_schematic_facts.md).
Source byte 0 = sound port 0 latch ($3100 / $2100 / $B100): bit 5 SHOT A, bit 6 SHOT B, bit 7 BOMB.
   vanguard: SK-4  BOMB (always-on SN76477 noise -> 4066 on the D7 envelope -> MFB band-pass -> RC chain),
                   SHOT A (LM3900 envelope-controlled oscillator), SHOT B (SN76477, 10K noise clock through 4.7uF)
   fantasy:  SK-7/8 BOMB (Fantasy, Nibbler, Pioneer Balloon)"""
import math
import dsnd_rate  # noqa: F401  (sets dsnd.FS)
import dsnd
from dsnd import Board, q, ONE, rc_exp, k_rc

LATCH = 0
FS = dsnd.FS
NOISE_GUARD = 4                                         # NOISE b[2]: SN76477 lock-up guard


def sn76477_noise(b, out, lfsr, freq_reg, rc_ch, rc_dc):
    """SN76477 noise generator + noise-filter Schmitt. freq_reg = noise bits per sample (Q24 register). out = 1.0
    while the filtered bit is 1 (chip output above centre). rc_ch / rc_dc = filter cap V per sample (Filter caps),
    None = no cap"""
    b.op("LD", out + "_ph")
    b.op("ADD", freq_reg)
    b.op("ST", out + "_ph")
    for _ in range(3):                                  # up to 3 noise bits per sample (SHOT B starts at ~2)
        b.op("LD", out + "_ph")
        b.op("CMPI", imm=ONE)
        at = b.skip_if(False)
        b.op("ADDI", imm=-ONE)
        b.op("ST", out + "_ph")
        b.op("NOISE", 0, lfsr | NOISE_GUARD)
        b.op("LDI", imm=0)
        b.op("LDIF", imm=ONE)
        b.op("ST", out + "_raw")
        b.land(at)
    if rc_ch is None:                                   # no filter cap: the cap follows the bit at once
        b.op("LD", out + "_raw")
        b.op("CMPI", imm=q(0.5))
        b.op("LDI", imm=ONE)
        b.op("LDIF", imm=0)
        b.op("ST", out)
        return
    b.kreg(out + "_kch", rc_ch, "F", clamp=False)
    b.kreg(out + "_kdc", rc_dc, "F", clamp=False)
    b.op("LD", out + "_cap"); b.op("ADD", out + "_kch"); b.op("MINI", imm=q(5.0)); b.op("ST", out + "_u")
    b.op("LD", out + "_cap"); b.op("SUB", out + "_kdc"); b.op("MAXI", imm=0); b.op("ST", out + "_d")
    b.op("LD", out + "_raw"); b.op("CMPI", imm=q(0.5))
    b.op("LD", out + "_d"); b.op("LDF", out + "_u"); b.op("ST", out + "_cap")
    b.op("CMPI", imm=q(3.35))                           # cap >= 3.35 V -> 0
    b.op("LD", out); b.op("LDIF", imm=0); b.op("ST", out)
    b.op("LD", out + "_cap"); b.op("CMPI", imm=q(0.74) + 1); b.op("NOT")   # cap <= 0.74 V -> 1
    b.op("LD", out); b.op("LDIF", imm=ONE); b.op("ST", out)


def noise_470k(b, out, lfsr):
    """470K noise clock, 1.5M / 220P noise filter (MAME's measured-curve formulas)"""
    rc = 1.5e6 * 220e-12
    b.init(out + "_f", 339100000 * 470e3 ** -0.8849 / FS)
    sn76477_noise(b, out, lfsr, out + "_f", 5.0 / (0.1571 * rc + 0.00001430) / FS, 5.0 / (0.1331 * rc + 0.00001734) / FS)


def bomb(b, out, nz, invert, r1, discharge, gated, vref, vp, vn, rc, ctl=None):
    """D7 -> 1K + diode -> C24 1uF (to TTL high - 0.5 V); discharge through R52 + R53 (only while the 4066 conducts
    when gated); 4066 switched by the noise (inverted for Vanguard's LM324); MFB band-pass (C41 = C42 10n, R48 470K,
    R53 33K); RC chain"""
    b.op("LD", nz); b.op("CMPI", imm=q(0.5))
    if invert:
        b.op("NOT")
    if ctl is None:
        b.op("LDI", imm=0); b.op("LDIF", imm=ONE); b.op("ST", out + "_sw")
    else:                                               # 4066 control through R37 / C25: on above the threshold
        v_hi, v_th, r, c = ctl
        b.op("LDI", imm=0); b.op("LDIF", imm=q(v_hi))
        b.kreg(out + "_ck", rc_exp(r * c), "F")
        b.op("RCM", out + "_ctl", b.r(out + "_ck"))
        b.op("CMPI", imm=q(v_th))
        b.op("LDI", imm=0); b.op("LDIF", imm=ONE); b.op("ST", out + "_sw")
    b.kreg(out + "_kd", rc_exp(discharge * 1e-6), "T")
    b.kreg(out + "_kc", rc_exp(1e3 * 1e-6), "T")
    if gated:
        b.op("LDI", imm=0)
    else:
        b.op("LD", out + "_kd")
    b.op("LDF", out + "_kd")
    b.op("BIT", 0, b.src(LATCH, 7))
    b.op("LDF", out + "_kc")
    b.op("ST", out + "_k")
    b.op("LDI", imm=0)
    b.op("LDIF", imm=q(3.4 - 0.5))
    b.op("RCM", out + "_env", b.r(out + "_k"))
    b.op("LD", out + "_sw"); b.op("CMPI", imm=q(0.5))
    b.op("LDI", imm=0); b.op("LDF", out + "_env"); b.op("ST", out + "_x")
    b.op_amp_filt_bp1m(out + "_bp", out + "_x", r1, 470e3, 0.01e-6, 0.01e-6, r2=33e3, vref=vref, vp=vp, vn=vn)
    src = out + "_bp"
    b.op("LD", src); b.op("ADDI", imm=q(-vref)); b.op("ST", out + "_ac")   # AC part (C48 / the mixer's coupling)
    src = out + "_ac"
    if rc == "ladder":                                  # R57-59 22K / C45 C46 C31 10n into R60 1M, exact nodes
        b.kreg(out + "_lk", (1.0 / FS) / (22e3 * 0.01e-6), "F", clamp=False)
        for i in range(3):
            up = src if i == 0 else out + "_l%d" % (i - 1)
            b.op("LD", up); b.op("SUB", out + "_l%d" % i)                       # current in (x R)
            if i < 2:
                b.op("SUB", out + "_l%d" % i); b.op("ADD", out + "_l%d" % (i + 1))   # minus current out
            else:
                b.op("ST", out + "_t"); b.op("LD", out + "_l2"); b.op("MULI", imm=q(-22e3 / 1e6)); b.op("ADD", out + "_t")
            b.op("MUL", out + "_lk"); b.op("ADD", out + "_l%d" % i); b.op("ST", out + "_l%d" % i)
        return out + "_l2"
    for i, (r, c) in enumerate(rc):
        b.rcfilter(out + "_rc%d" % i, src, r, c)
        src = out + "_rc%d" % i
    return src


def vanguard(scale_bomb, scale_a, scale_b, mfb_vs=5.0):
    b = Board("vanguard")
    # BOMB noise source: SN76477 IC45 (pin 9 = GND, always on)
    noise_470k(b, "nz", 0)
    vref = mfb_vs * 22 / 55                           # + input: 33K to the supply, 22K to ground
    o = bomb(b, "bm", "nz", True, 100.5e3, 133e3, True, vref, mfb_vs, 0.0,
             "ladder",
             ctl=(3.5, 2.5, 6.8e3, 0.033e-6))           # LM324 (5 V) high, 4066 threshold ~VDD / 2
    b.output(o, scale_bomb)

    # SHOT A: LM3900 (IC37) at 5 V; currents into input nodes at VBE 0.5 V; dt / (C27 x 1M)
    b.kreg("a_g", (1.0 / FS) / (220e-12 * 1e6), "O", clamp=False)
    b.kreg("a_kd", rc_exp(1e-6 * 1.0 / (1 / 1e6 + 1 / 470e3)), "T")
    b.kreg("a_kc", rc_exp(1e3 * 1e-6), "T")
    b.init("a_vc", 0.5)
    b.op("BIT", 0, b.src(LATCH, 5))
    b.op("LDI", imm=q(0.5)); b.op("LDIF", imm=q(3.4 - 0.6)); b.op("ST", "a_t")
    b.op("LD", "a_kd"); b.op("LDF", "a_kc")
    b.op("ST", "a_k"); b.op("LD", "a_t"); b.op("RCM", "a_vc", b.r("a_k"))
    b.op("ADDI", imm=q(-0.5)); b.op("MAXI", imm=0); b.op("ST", "a_i")              # (Vc - VBE)
    b.op("LD", "a_o2"); b.op("CMPI", imm=q(0.5))                                   # F = Schmitt output (NPN on)
    b.op("LDI", imm=q(1e6 / 470e3 - 1.0)); b.op("LDIF", imm=q(-1.0)); b.op("ST", "a_gn")
    b.op("LD", "a_i"); b.op("MUL", "a_gn"); b.op("SUB", "a_v1"); b.op("ADDI", imm=q(0.5))
    b.op("MUL", "a_g"); b.op("ADD", "a_v1"); b.op("MAXI", imm=0); b.op("MINI", imm=q(4.0)); b.op("ST", "a_v1")
    th_lo = 0.5 + 470e3 * ((5.0 - 0.5) / 1.5e6 - (4.0 - 0.5) / 1e6)                 # Schmitt (stage 2) thresholds
    th_hi = 0.5 + 470e3 * ((5.0 - 0.5) / 1.5e6 - (0.1 - 0.5) / 1e6)
    b.op("LD", "a_o2"); b.op("CMPI", imm=q(0.5))
    b.op("LDI", imm=q(th_hi)); b.op("LDIF", imm=q(th_lo)); b.op("ST", "a_th")
    b.op("LD", "a_v1"); b.op("CMP", "a_th")
    b.op("LDI", imm=0); b.op("LDIF", imm=ONE); b.op("ST", "a_o2")
    i3 = (5.0 - 0.5) / 476e3 - (5.0 - 0.5) / 1.5e6                                  # stage 3 (inverting, x14.2)
    b.op("LD", "a_v1"); b.op("MULI", imm=q(-470e3 / 33e3))
    b.op("ADDI", imm=q(0.5 + 470e3 * i3 + 470e3 / 33e3 * 0.5)); b.op("MAXI", imm=0); b.op("MINI", imm=q(4.0))
    b.op("ST", "a_s3")
    b.crfilter("a_out", "a_s3", 33e3, 0.1e-6)                                       # R20 + C26 into the amp
    b.output("a_out", scale_a)

    # SHOT B: SN76477 enabled while D6 = 1; noise clock 10K through C44 4.7uF (shorted by the 4066 while disabled):
    # bit rate falls as the cap charges, f ~ I^0.8849 (MAME's R curve) -> f0 * exp(-t / (RC / 0.8849))
    f0 = 339100000 * 10e3 ** -0.8849 / FS
    b.op("BIT", 0, b.src(LATCH, 6))                     # F = enabled: the rate decays; disabled: back to f0
    b.kreg("b_d", 1.0 - math.exp(-0.8849 / (FS * 10e3 * 4.7e-6)), "T", clamp=False)
    b.op("LD", "b_f"); b.op("MUL", "b_d"); b.op("ST", "b_t"); b.op("LD", "b_f"); b.op("SUB", "b_t")
    b.op("NOT")
    b.op("LDIF", imm=q(f0))
    b.op("ST", "b_f")
    sn76477_noise(b, "nb", 1, "b_f", None, None)
    b.op("LD", "nb"); b.op("CMPI", imm=q(0.5))
    b.op("LDI", imm=q(-0.85 * 0.4118)); b.op("LDIF", imm=q(0.4118)); b.op("ST", "b_v")
    b.op("BIT", 0, b.src(LATCH, 6))
    b.op("LDI", imm=0); b.op("LDF", "b_v")
    b.op("ST", "b_s")
    b.output("b_s", scale_b)
    b.init("b_f", f0)
    return b.finish()


def fantasy(scale_bomb):
    """MAME's fantasy_discrete values (10.5K = R52 + switch, ungated RCDISC2, +-12 V rails)"""
    b = Board("fantasy")
    noise_470k(b, "nz", 0)
    o = bomb(b, "bm", "nz", False, 10.5e3, 43e3, False, 0.0, 12.0, -12.0,
             [(22e3, 0.01e-6), (44e3, 2200e-12), (66e3, 1000e-12)])
    b.output(o, scale_bomb)
    return b.finish()
