# ===========================================================================
# Co-channel AM broadcast channel interference simulator
# Version 2.1 - December 15, 2020
# By Dave Hershberger
# Nevada City, California
# dave@w9gr.com
#
# For NRSC AIWG
#
# Create random signal parameters for co-channel simulation
#
# Also write flac files with interpolated complex fading gain
# RF fading complex amplitudes are greatly undersampled,
# 5 values per interferer, then interpolated to fs.
#
# New parameters to be set:
#
# RF frequency offset normal distribution, standard dev 3 Hz,
#   limited to +/- 30 Hz maximum
# RF amplitudes -20 dB to 0 dB
#
# ===========================================================================
tic;
nsigs=71;
fs=44100;
nsecs=60;
freqerr=min(30,max(-30,3*randn(nsigs,1)));
npts=4;
nfade=npts+1;
nsamp=nsecs*fs;
# Create fading amplitude values
fadeam=rand(nsigs,nfade);
# This limits PM to +/- pmax
pmax=pi;
fadepm=2*pmax*(rand(nsigs,nfade)-0.5);
fade=fadeam.*exp(1i*fadepm);
rfamp=-20*rand(nsigs,1);
save "parameters.txt" freqerr rfamp;
# Interpolate, normalize, and write fading functions
  nup=round(fs*nsecs/npts);
for k=1:nsigs
  fadefs=resample(fade(k,:),nup,1).';
  fadefs=fadefs(1:nsamp);
  peak=max(max(abs(real(fadefs))),max(abs(imag(fadefs))));
  fadefs=0.9*fadefs/peak;
  fname=sprintf('fade%2.2i.flac',k+1);
  afout=[real(fadefs) imag(fadefs)];
  audiowrite(fname,afout,fs);
endfor
toc;
