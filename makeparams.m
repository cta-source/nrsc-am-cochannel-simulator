# ===========================================================================
# Co-channel AM broadcast channel interference simulator
# Version 2.6 - April 17, 2022
# By Dave Hershberger
# Nevada City, California
# dave@w9gr.com
#
# For NRSC AIWG
#
# Create random signal parameters for co-channel simulation
#
# Also writes flac files with interpolated complex fading gain.
# RF fading complex amplitudes are greatly undersampled,
# 11 values per interferer, then interpolated to fs.
#
# Other parameters randomly set:
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
npts=10;
nfade=npts+1;
nsamp=nsecs*fs;
# Create fading amplitude values
fadeam=rand(nsigs,nfade);
# Create normal random complex fading values,
# which will result in a modulus with Rayleigh distribution
fade=randn(nsigs,nfade)+1i*randn(nsigs,nfade);
# This squares the modulus but keeps the phase angle
# to obtain 6-10 dB average peak to average ratio
fade=fade.*abs(fade);
rfamp=-20*rand(nsigs,1);
save "parameters.txt" freqerr rfamp;
# Interpolate, normalize, and write fading functions
nup=round(fs*nsecs/npts);
fadefs=zeros(nsigs,nsamp);
for k=1:nsigs
  fadeup=resample(fade(k,:),nup,1).';
  fadefs(k,:)=fadeup(1:nsamp);
  peak=max(max(abs(real(fadefs(k,:)))),max(abs(imag(fadefs(k,:)))));
  fadefs(k,:)=0.9*fadefs(k,:)/peak;
  fname=sprintf('fade%2.2i.flac',k+1);
  afout=[real(fadefs(k,:)).' imag(fadefs(k,:)).'];
  audiowrite(fname,afout,fs);
endfor
toc;
pardb=zeros(k,1);
for k=1:nsigs
pardb(k,1)=20*log10(max(abs(fadefs(k,:)))/rms(fadefs(k,:)));
endfor
dbavg=mean(pardb);
dbmax=max(pardb);
dbmin=min(pardb);
fprintf('Avg PAR = %5.2f dB; Max PAR = %5.3f dB; Min PAR = %5.3f dB\n',dbavg,dbmax,dbmin);
figure(1);
plot(abs(fadefs(1:16,:).'));
title('Fading Functions');
xlabel('Samples');
ylabel('Relative Amplitude');
grid on;


figure(2);
semilogy(abs(fadefs(1:16,:).'));
title('Fading Functions');
xlabel('Samples');
ylabel('Relative Amplitude');
grid on;

