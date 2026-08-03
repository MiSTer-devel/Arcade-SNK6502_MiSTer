#!/usr/bin/env python3
"""
HD38880 speech decoder + PARCOR synthesizer, with decode curves fitted against
MAME's vg_voi-*.wav reference recordings of the real chip.

Frame format (recovered): 49 bits, LSB-first, fields LSB-first
   bits 0-5  Amp (6)      bits 13-19 k1 (7)     bits 25-48 k3..k10 (3 each)
   bit  6    STOP-assist  bits 20-24 k2 (5)   |  Amp==63 (all ones) = STOP marker
   bits 7-12 Pitch (6), 0 = unvoiced
   Amp == 0 -> SILENCE frame, only 6 bits long (no other fields follow).
Parameter bits = 48 (matches Hitachi's published figure); +1 control bit = 49.
Frame period 20 ms, sample rate 8 kHz, 10-stage lattice, vocal-tract loss 0.992.

Usage: hd38880_decode.py <rom-dir> <out-dir>
"""
import numpy as np, sys, os, wave, json
from scipy.signal import lfilter, butter

BASE=0x4000; FRAME=49; FS=8000; HOP=160; ALPHA=0.992; PRE=0.9
FIELDS=[6,1,6,7,5,3,3,3,3,3,3,3,3]
VAN=[0x04000,0x04325,0x044a2,0x045b7,0x046ee,0x04838,0x04984,0x04b01,
     0x04c38,0x04de6,0x04f43,0x05048,0x05160,0x05289,0x0539e,0x054ce]
# INT1 byte the game's 6502 sends per phrase, read from the sound-CPU ROM
# (Vanguard table $6F9D, Fantasy table $BE95). Bit 2 = vocal-tract loss enable;
# confirmed by audio: the two Fantasy groups have opposite optimal alpha.
INT1_VAN=[0x44]*16
INT1_FAN=[0x48,0x48,0x44,0x44,0x44,0x48,0x48,0x48,0x44,0x44,0x48,0x44]
FAN=[0x04000,0x04297,0x044b6,0x04682,0x04927,0x04be0,0x04cc2,0x04e36,
     0x05000,0x05163,0x052c9,0x053fd]
ROMS={'vanguard':(['sk6_ic07.bin','sk6_ic08.bin','sk6_ic11.bin'],VAN),
      'fantasy' :(['fs_d_7.bin','fs_e_8.bin','fs_f_11.bin'],FAN)}
# fitted decode curves: k = slope*code + intercept
_D=os.path.dirname(os.path.abspath(__file__))
_A=os.path.join(_D,'hd38880_tables_abs.json')
_T=json.load(open(_A if os.path.exists(_A) else os.path.join(_D,'hd38880_decode_tables.json')))
_ABS='k1_bins' in _T
if _ABS:
    _K1=np.array(_T['k1_bins']); _K1C=np.arange(16)*8+4      # 7-bit code -> 16 bins
    _K2=np.array(_T['k2_bins']); _K2C=np.arange(16)*2+1      # 5-bit code -> 16 bins
    _KN=[np.array(_T['k%d'%(m+1)]) for m in range(2,10)]     # 3-bit, 8 entries
_PT=np.array(_T['pitch_table_full']) if 'pitch_table_full' in _T else None
_AT=np.array(_T['amp_table']) if 'amp_table' in _T else None
KTAB=[tuple(_T['k%d'%(m+1)]) for m in range(10)] if not _ABS else None
AMP=tuple(_T['amp'])      # log(rms)   = a*code + b
PITCH=tuple(_T['pitch'])  # period_smp = a*code + b  (~1.5*code + 3)

def load(d,game='vanguard'):
    b=bytearray()
    for f in ROMS[game][0]:
        b+=open(os.path.join(d,f),'rb').read()
    return b
def rom_end(img):
    i=len(img)-1
    while img[i]==0xff: i-=1
    return BASE+i+1
def decode_phrase(img,s,e):
    """Frames are 49 bits, EXCEPT a silence frame: if the 6-bit Amp field is 0
    the frame is only those 6 bits (no repeat/pitch/k fields follow)."""
    bits=[]
    for a in range(s,e):
        by=img[a-BASE]
        for i in range(8): bits.append((by>>i)&1)
    def val(p,w):
        v=0
        for j in range(w): v|=bits[p+j]<<j
        return v
    out=[]; p=0
    while p+FRAME<=len(bits):
        amp=val(p,6)
        if amp==63:                 # all-ones energy = STOP marker (do not play)
            break
        if amp==0:
            out.append(dict(amp=0,rep=0,pitch=0,k=[0]*10,silent=True)); p+=6
        else:
            out.append(dict(amp=amp,rep=val(p+6,1),pitch=val(p+7,6),
                            k=[val(p+13,7),val(p+20,5)]+[val(p+25+3*i,3) for i in range(8)],
                            silent=False)); p+=FRAME
            if out[-1]['rep']: break        # bit 6 set also terminates
    return out

def params(F):
    if _ABS:
        k=[float(np.interp(F['k'][0],_K1C,_K1)), float(np.interp(F['k'][1],_K2C,_K2))]
        k+=[float(_KN[m][F['k'][m+2]]) for m in range(8)]
        k=[float(np.clip(v,-0.985,0.985)) for v in k]
    else:
        k=[float(np.clip(KTAB[m][0]*F['k'][m]+KTAB[m][1],-0.985,0.985)) for m in range(10)]
    if _AT is not None: g=float(_AT[min(F['amp'],63)])*20000.0
    else: g=np.exp(AMP[0]*F['amp']+AMP[1]) if F['amp']>0 else 0.0
    if not F['pitch']: per=0
    elif _PT is not None: per=int(round(_PT[min(F['pitch'],63)]))
    else: per=int(round(PITCH[0]*F['pitch']+PITCH[1]))
    return g,per,k

class Lat:
    def __init__(s,M=10): s.M=M; s.bd=np.zeros(M); s.alpha=ALPHA
    def step(s,e,k):
        bd=s.bd*s.alpha; f=e; nb=np.zeros(s.M)
        for m in range(s.M,0,-1):
            fm=f-k[m-1]*bd[m-1]; nb[m-1]=bd[m-1]+k[m-1]*fm; f=fm
        s.bd=np.concatenate(([f],nb[:-1])); return f

# Excitation/output-stage constants.
# NAP/APC (allpass dispersion) REMOVED: it was added to match waveform symmetry
# and crest factor, but those targets are artifacts of the limiting applied to
# the MAME reference WAVs, and removing it costs nothing on the trustworthy
# metrics (band-profile error 0.93 -> 0.92 dB, valley depth unchanged).
# Voiced source is a plain impulse: triangular excitation (INT1 bit 3 = 1)
# measures far worse on band-profile error (5.6 vs 0.9 dB), so these games
# select impulse.
# Output stage now DERIVED from the SK6 schematic + parts list, not fitted:
#   crystal 640 kHz -> /80 -> 8000 Hz sample rate exactly (160 smp / 20 ms frame)
#   C14 0.1uF into R13 5.6K   -> 284 Hz high-pass  (output AC coupling)
#   R12 22K  with C12 2.2nF   -> 3288 Hz low-pass  (LM324 reconstruction stage)
#   R10 22K  with C11 1nF     -> 7234 Hz low-pass  (LM324 first stage)
# Derived chain measures 0.89 dB band error vs 0.85 dB for the old fitted
# 240 Hz guess - i.e. identical, but physically justified.
NAP=0; APC=0.0; HP_HZ=284.0; LP1_HZ=3288.0; LP2_HZ=7234.0; VMIX=0.08; UGAIN=1.3

def alpha_for(int1):
    """INT1 bit 2 selects the vocal-tract loss (alpha=0.992) or none (1.0)"""
    return ALPHA if (int1 & 0x04) else 1.0

def synth(frames, int1=0x44):
    lat=Lat(); lfsr=0xACE1; out=[]; prev=None; pc=0; pk=[0.0]*10
    lat.alpha=alpha_for(int1)
    apst=np.zeros(NAP)
    for F in frames:
        g,per,k=params(F)
        if F.get('silent'): g=0.0
        cur=(g,per,k)
        if prev is None: prev=cur
        # interpolation is inhibited across a voiced/unvoiced boundary so that
        # consonant onsets stay crisp instead of gliding out of the vowel
        vchg=(prev[1]==0)!=(per==0)
        for n in range(HOP):
            t=1.0 if vchg else min(1.0,(n//(HOP//8)+1)/8.0)
            # amplitude is applied immediately; only the filter coefficients are
            # interpolated. Interpolating gain lags the real envelope on decays
            # and leaves an audible tail after each word.
            gg=cur[0]
            kk=[prev[2][j]+(k[j]-prev[2][j])*t for j in range(10)]
            lfsr=((lfsr<<1)|(((lfsr>>15)^(lfsr>>13)^(lfsr>>12)^(lfsr>>10))&1))&0xFFFF
            nz=(1 if lfsr&1 else -1)
            if per==0: e=gg*nz*UGAIN
            else:
                if pc>=per: pc=0
                e=gg*6.0 if pc==0 else 0.0
                pc+=1
                e+=gg*VMIX*nz          # aspiration noise: real chip is not purely periodic
            # allpass chain: flat magnitude, disperses the impulse so the output
            # is symmetric with a realistic crest factor (matches the real chip)
            for _s in range(NAP):
                v=-APC*e+apst[_s]; apst[_s]=e+APC*v; e=v
            out.append(lat.step(e,kk))
        prev=cur; pk=k
    y=lfilter([1],[1,-PRE],np.array(out))   # de-emphasis (external integrator)
    def _rc_hp(x,fc):
        a=np.exp(-2*np.pi*fc/FS); return lfilter([1,-1],[1,-a],x)
    def _rc_lp(x,fc):
        a=np.exp(-2*np.pi*fc/FS); return lfilter([1-a],[1,-a],x)
    y=_rc_hp(y,HP_HZ)                       # C14/R13 AC coupling
    y=_rc_lp(y,LP1_HZ)                      # R12/C12 reconstruction pole
    y=_rc_lp(y,LP2_HZ)                      # R10/C11 pole
    return y

def wav(p,x):
    x=x/(np.max(np.abs(x))+1e-9)*0.9
    w=wave.open(p,'wb'); w.setnchannels(1); w.setsampwidth(2); w.setframerate(FS)
    w.writeframes((x*32767).astype('<i2').tobytes()); w.close()

if __name__=='__main__':
    src=sys.argv[1]; dst=sys.argv[2]
    game=sys.argv[3] if len(sys.argv)>3 else 'vanguard'
    os.makedirs(dst,exist_ok=True)
    img=load(src,game); tabl=ROMS[game][1]; b=tabl+[rom_end(img)]; allx=[]
    for i in range(len(tabl)):
        _i1=(INT1_FAN if game=='fantasy' else INT1_VAN)[i]
        fr=decode_phrase(img,b[i],b[i+1]); x=synth(fr,_i1)
        wav(os.path.join(dst,'%s_synth_%02d.wav'%(game[:2],i)),x)
        allx+= [x,np.zeros(FS//3)]
        print("phrase %2d: %3d frames %.2fs  voiced %d  repeat %d"%(
            i,len(fr),len(fr)*0.02,sum(1 for f in fr if f['pitch']),sum(f['rep'] for f in fr)))
    wav(os.path.join(dst,'%s_synth_all.wav'%game[:2]),np.concatenate(allx))
