# ===========================================================================
# Co-channel AM broadcast channel interference simulator
# Version 2.6 - April 17, 2022
# By Dave Hershberger
# Nevada City, California
# dave@w9gr.com
#
# For NRSC AIWG
#
# This is a GNU Octave script that simulates co-channel interference.
# It can simulate 1 to 71 interferers. The parameters for each interferer
# include:
#   Frequency offset
#   Fading samples (complex)
#   Amplitude
#     
# These parameters are read in from a required file called "parameters.txt"
# The file "parameters.txt" is created by another Octave script "makeparams.m"
# The limits for frequency offset etc. are set up in makeparams.m.
#
# Frequency offset is generated at random with a Gaussian distribution.
# Standard deviation is set to 3 Hz.
#
# Fading samples have a uniform amplitude distribution of 0 to 1.
# The fading phase values have a uniform distribution of -pi to +pi.
# There are 5 such complex values set, over a 60 second time interval.
# In other words, a new complex value is set every 15 seconds, at 0, 15, 30,
# 45, and 60 seconds. These 5 values, sampled at 1/15 Hz, are interpolated to
# the sampling rate of 44.1 kHz, which produces smooth, slowly moving fading
# functions.
#
# Amplitude of each interferer is set randomly with a uniform distribution
# over the -20 to 0 dB range. The rms of the total interference is then 
# adjusted to provide the desired average SIR (signal to interference ratio)
# value (10 dB is the default). 
#
# This script requires the function "addsig.m" which adds interferers
# to a signal.
#
# This script runs the simulation twice. First it runs with all of the
# interferers unsynchronized. Then it sets all of the frequency offsets
# to zero and runs the simulation again.
#
# There is a software receiver in this code which is intended to emulate
# a typical narrow bandwidth envelope detector radio. Bandwidth is 5 kHz
# so audio response is 2.5 kHz. The receiver uses envelope detection. It
# includes a 50 Hz highpass filter, which removes the subsonic beat notes
# which appear in the nonsynchronous case (but it does not remove the AGC
# pumping produced by the nonsynchronized carriers). And it includes AGC.
#
# This script also requires the presence of 72 audio files. The first
# one contains the desired signal. The other 71 files are used for
# interferers. The first file is Rush Limbaugh, selected because he pauses
# between phrases and words, which allows hearing the interference beneath
# the signal.
#
# The 72 audio files are exactly one minute long, sampled at 44100 Hz. They
# are in the FLAC audio format. FLAC is a lossless, but compressed format.
# So the audio is the exactly same that you would get from an uncompressed
# WAV file, but the file size is only about half of what a WAV file would be.
#
# The audio files have been peak limited such that the maximum amplitude
# is 0.9 times full scale. In other words, a signal reaching a value of 0.9
# times full scale will be envelope modulated 100 percent.
#
# The output files are also in the FLAC format. Most modern audio player
# software (such as VLC, Audacity, etc.) supports the FLAC format.
#
# The relative amplitudes of the interfering signals may be set at random,
# with a specified SIR value (such as 10 dB). Or, this script may be operated
# in "NIF mode," where NIF means "Nighttime Interference Free." In NIF mode,
# the relative rms amplitudes of the interferers are set by a file named
# "nif.txt" where the linear or dB relative amplitude of each interferer is set.
# The desired signal is assigned an amplitude of 1 (unity).
# POSITIVE values (including zero) are interpreted as linear amplitudes.
# NEGATIVE values are interpreted as decibel amplitudes.
# Examples: If you wanted
# three interferers at -20, -26, and -30 dB for instance, then the nif.txt
# file could look like this:
#
#   0.1
#   0.05
#   0.0316
#
#  Or you could specify the amplitudes using negative dB values:
#
#  -20
#  -26
#  -30
#
# Positive linear and negative dB values may be intermixed as shown here:
#
#  -20
#  0.05
#  -30
#
# The nif.txt file may include comment lines beginning with the "#" character.
#
# The sir value is ignored in NIF mode.
# To use NIF mode, set the variable NIFMODE=1. To use the random amplitude
# levels, with a combined SIR value, set NIFMODE=0 and SIR to the value in
# dB that you want (such as 10 dB).
#
# These values are set up in another file called graveyard.cfg. This file
# contains six values:
#
# NIF (Set to 1 for NIF mode, where you specify interferer amplitudes, or
#   0 for random interferer amplitudes.)
#
# nfile1 (This value selects the audio file for the first interferer, 1 to 71.)
# nfile2 (This value selects the audio file for the last interferer, 1 to 71,
#   nfile2>=nfile1. The number of interferers is nfile2-nfile1+1. nfile1 and
#   nfile2 are ignored in NIF mode.)
#
# sir (Sets average SIR value in decibels. Ignored in NIF mode.)
# emph (0 for flat audio, 1 for 75 microsecond pre-emphasized audio)
# snr (Sets SNR value in decibels, no noise if >= 90 dB)
#
# There are six audio files produced by this script. They begin with the
# string "cochannelXX" where XX is the number of interferers. So you would
# have "cochannel03" or "cochannel64" for 3 or 64 interferers, respectively.
# If NIF mode is invoked, the file names will start with "nifXX" instead.
# The files are:
#   cochannelXX.flac - stereo file, synchronous case on left channel,
#                      nonsynchronous case on the right channel
#   cochannelXXqrm.flac - stereo file, with just the interference signal.
#                         The envelope signal is canceled, but since envelope
#                         detection is nonlinear, the cancellation is not
#                         perfect, so the envelope detector nonlinear distortion
#                         will appear in this file. Synchronous on left,
#                         nonsynchronous on right.
#   cochannelXXsync.flac - monophonic file, synchronous case
#   cochannelXXnonsync.flac - monophonic file, nonsynchronous case
#   cochannelXXsyncqrm.flac - monophonic file, synchronous case,
#                             interference only
#   cochannelXXnonsyncqrm.flac - monophonic file, nonsynchronous case,
#                                interference only
#
# There are also seven graphics files produced:
#   cochannelXXspecsync.png - close in spectrum of synchronous spectrum
#   cochannelXXspecnonsync.png -0 close in spectrum of nonsynchronous spectrum
#   cochannelXXagc.png - shows receiver AGC signal for both synchronous
#                        and nonsynchronous cases.
#   cochannelXXampqrm.png - shows amplitude versus time for interferers
#                           (both synchronous and nonsynchronous)
#   cochannelXXampqrmsum.png - shows amplitude versus time for the sum of all
#                              interferers (both synchronous and nonsynchronous)
#   cochannelXXphaseqrmnonsync.png - shows phase versus time for nonsynchronous
#                                    interferers.
#   cochannelXXphaseqrmsync.png - shows phase versus time for synchronous
#                                 interferers.
#
# To use this script, change the number of interferers by changing the values
# of nfile1 and nfile2 in the config.txt file. For example if you want 4
# intererers you could set nfile1=1 and nfile2=4. Or if you want 4 different
# interfering signals, you might select nfile1=50 and nfile2=53.
#
# To change the signal to interference ratio, change the SIR value. This is the
# signal to interference ratio in dB. 10 dB is the default. It creates a lot of
# interference at 10 dB, but the desired signal is still audible, and every
# word is discernible in the desired signal.
#
# To select flat or 75 microsecond pre-emphasized audio, change the
# "emph" value. Use 0 for flat, 1 for pre-emphasized.
#
# To add Gaussian noise, specify a value for SNR less than 90 dB.
#
# The required GNU Octave packages include:
#   signal
#   ltfat
#
# Happy simulating!
#
# ===========================================================================
clear;
tic;
# Read control parameters from the file config.txt:
load config.txt;
NIFMODE=config(1);
nfile1=config(2);
nfile2=config(3);
sir=config(4);
emph=config(5);
snr=config(6);
fadepct=config(7);
if (emph==0)
  basename="audio";
else
  basename="audioemph";
endif
# NIFMODE=0 for random amplitudes, NIFMODE=1 to read relative amplitudes
#   from the file nif.txt
# Read in the previously randomly generated interference parameters
load "parameters.txt";
nfreqs=length(freqerr);
sdfreq=sqrt(sum(freqerr.^2)/(nfreqs-1));
fprintf('Standard deviation of 71 carrier offset frequencies = %f\n',sdfreq);
fprintf('Max carrier offset = %f\n',max(freqerr));
fprintf('Min carrier offset = %f\n',min(freqerr));
# Read in the desired signal
[desired,fs]=audioread([basename '01.flac']);
# Convert to AM by adding carrier (DC) and clipping negative peaks (if any)
desired=max(0,desired/0.9+1);
nsamp=length(desired);
qrm=zeros(size(desired));
nskip=round(100*60);
ngplot=round(nsamp/nskip);
raddeg=180/pi;
if (NIFMODE==0)
  nqrm=nfile2-nfile1+1;
  foutname=sprintf('cochannel%2.2i',nqrm);
else
  load nif.txt;
  nnif=length(nif)
  nfile2=nfile1+nnif-1;
  nqrm=nfile2-nfile1+1;
# Interpret positive values as linear (convert to dB)
# Interpret negative values as dB
  sir=0;
  for k=1:nnif
    if (nif(k)<0)
      rfamp(nfile1+k-1)=nif(k);
    else
      rfamp(nfile1+k-1)=20*log10(max(1e-20,nif(k)));
    endif
    sir=sir+10^(0.1*rfamp(nfile1+k-1));
  endfor
  sir=-10*log10(sir);
  foutname=sprintf('nif%2.2i',nqrm);
endif
gplot=zeros(nqrm,ngplot);
for jfile=nfile1:nfile2
  ifile=jfile+1;
  afname=sprintf([basename '%2.2i.flac'],ifile);
  ffname=sprintf('fade%2.2i.flac',ifile);
  [qrmout,gplot(ifile-nfile1,:)]=addsig(qrm,afname,ffname,freqerr(jfile),rfamp(jfile),NIFMODE,fadepct);
  qrm=qrmout;
# If you want to see the offset frequencies, uncomment the next line
  fprintf('freqerr(%i)=%f\n',jfile,freqerr(jfile));
endfor
t=linspace(0,nsamp-1,nsamp)/fs;
figure(1);
plot(t(1:nskip:nsamp),raddeg*unwrap(angle(gplot.')));
title('Phases (Unwrapped) of Interferers - Nonsynchronous Case');
xlabel('Time (seconds)');
ylabel('Phase (degrees)');
grid on;
saveas(1,[foutname 'phaseqrmnonsync.png']);
if (NIFMODE==0)
# Calculate QRM amplitude
  qrmrms=rms(qrm);
  sigrms=rms(desired);
# Scale the QRM to the desired amplitude
  qrmamp=10^(-sir*0.05)*sigrms/qrmrms;
else
  qrmamp=1;
endif
fprintf('QRM gain for nonsynchronous case = %f\n',qrmamp);
figure(2);
plot(t(1:nskip:nsamp),20*log10(qrmamp*abs(gplot.')));
title('dB Amplitudes of Interferers');
xlabel('Time (seconds)');
ylabel('Relative Amplitude (decibels)');
axis([0 t(nsamp) -80 0]);
grid on;
saveas(2,[foutname 'ampqrm.png']);
figure(3);
if(nqrm==1)
  pqrm=(qrmamp^2)*real(gplot(1,:)).^2+imag(gplot(1,:)).^2;
else
  pqrm=(qrmamp^2)*sum(real(gplot(:,:)).^2+imag(gplot(:,:)).^2);
endif
#pqrm=qrmamp^2*sum(real(gplot(:,:)).^2+imag(gplot(:,:)).^2);
#pqrm=zeros(1,nqrm);
#for k=1:nqrm
#  pqrm=pqrm+real(gplot(k,:)).^2+imag(gplot(k,:)).^2;
#endfor
#pqrm=pqrm*qrmamp^2;
plot(t(1:nskip:nsamp),10*log10(pqrm));
title('dB Amplitude of Total Interferers');
xlabel('Time (seconds)');
ylabel('Relative Amplitude (decibels)');
axis([0 t(nsamp) -2*sir 0]);
grid on;
saveas(3,[foutname 'ampqrmsum.png']);
rf=desired+qrm*qrmamp;
# To simulate 5 kHz receiver bandwidth, make a 2.5 kHz 5th order Butterworth LPF
fcutoff=2500;
[bbpf,abpf]=butter(5,2*fcutoff/fs);
# If snr<90 then read in and add noise
if(snr<90)
  [qrn,fs]=audioread('qrn.flac');
  qrn=qrn(:,1)+1i*qrn(:,2);
  qrnbpf=filter(bbpf,abpf,qrn);
  rmsqrnbpf=rms(qrnbpf);
  qrngain=10^(-snr*0.05)/rmsqrnbpf;  
  qrn=qrn*qrngain;
  rf=rf+qrn;
endif
rf=filter(bbpf,abpf,rf);
envelopenonsync=abs(rf);
# According to ST Micro, simple AM receiver AGC time constant
# is set to produce 1% distortion on 100 Hz 100% AM.
# This results in a 2.2 Hz first order Butterworth LPF.
fagc=2.2;
[b,a]=butter(1,2*fagc/fs);
# Subtract 1 from AGC lowpass signal before filtering, then restore it
agc=1+filter(b,a,envelopenonsync-1);
agc=max(0.25,agc);
envelopenonsync=envelopenonsync./agc;
dc=mean(envelopenonsync);
envelopenonsync=envelopenonsync-dc;
# Tukeywin applies a brief fade-in and fade-out at beginning and end
envelopenonsync=tukeywin(nsamp,0.02).*envelopenonsync;
# Resample audio to 16 kHz to make output files smaller
p=160;
q=441;
fslo=round(fs*p/q);
envelopenonsync16=resample(envelopenonsync,p,q);
# Make a 50 Hz highpass filter to remove subsonic beats and to simulate typical receiver
fhpf=50;
[bhpf,ahpf]=butter(3, 2*fhpf/fslo, 'high');
envelopenonsync16=filter(bhpf,ahpf,envelopenonsync16);

ndecim=2048;
# Downsample signal to create close-in spectrum showing interfering carriers
rfnarrow=resample(rf,1,ndecim);
nnarrow=length(rfnarrow);
nfft=floor(nnarrow/4);
winnarrow=gausswin(nfft);
[pspec,fspec]=pwelch(rfnarrow,winnarrow,[],nfft,fs/ndecim,'centerdc','plot','no-strip');
dbpspec=10*log10(pspec);
dbpspec=dbpspec-max(dbpspec);
figure(4);
plot(fspec,dbpspec);
title('Received Signal Close-In Spectrum (nonsynchronized)');
xlabel('Frequency Offset (Hertz)');
ylabel('Amplitude (decibels)');
grid on;
saveas(4,[foutname 'specnonsync.png']);

# Write out IF file
# Shift the baseband signal up 12 kHz:
fif=12e3;
ifsig=rf.'.*exp(2i*pi*fif*t);
#{
[ifspec,iffreq]=pwelch(ifsig,[],[],[],fs,'centerdc','plot','no-strip');
dbifspec=10*log10(ifspec);
figure(10);
plot(iffreq,dbifspec);
title('IF Spectrum');
xlabel('Frequency (Hertz)');
ylabel('Amplitude (dB)');
grid on;
#}
ifout=real(ifsig);
ifout=0.9*ifout/max(abs(ifout));
audiowrite([foutname 'nonsyncifout.flac'],ifout,fs);


# Now do the synchronous case
# Zero out the frequency error - set all frequency offsets to zero
# Everything else (fading, amplitude, etc.) remains the same
freqerr=zeros(size(freqerr));
qrm=zeros(size(desired));
for jfile=nfile1:nfile2
  ifile=jfile+1;
  afname=sprintf([basename '%2.2i.flac'],ifile);
  ffname=sprintf('fade%2.2i.flac',ifile);
  [qrmout,gplot(ifile-nfile1,:)]=addsig(qrm,afname,ffname,freqerr(jfile),rfamp(jfile),NIFMODE,fadepct);
  qrm=qrmout;
endfor
figure(5);
plot(t(1:nskip:nsamp),raddeg*unwrap(angle(gplot.')));
title('Phases (Unwrapped) of Interferers - Synchronous Case');
xlabel('Time (seconds)');
ylabel('Phase (degrees)');
grid on;
saveas(5,[foutname 'phaseqrmsync.png']);
# Must use the SAME QRM amplitude for the synchronous case!
rfsync=desired+qrm*qrmamp;
if(snr<90)
  rfsync=rfsync+qrn;
endif
# Bandpass filter
rfsync=filter(bbpf,abpf,rfsync);
envelopesync=abs(rfsync);
# Subtract 1 from AGC lowpass signal before filtering, then restore it
agcsync=1+filter(b,a,envelopesync-1);
agcsync=max(0.25,agcsync);
t=linspace(0,nsamp-1,nsamp)/fs;
# Show the receiver AGC waveforms for synchronous and nonsynchronous cases
figure(6);
plot(t,1./agc,t,1./agcsync);
title('Receiver AGC Gain');
xlabel('Time (seconds)');
ylabel('Gain (linear)');
legend('Nonsync','Sync','location','south');
grid on;
saveas(6,[foutname 'agc.png']);
envelopesync=envelopesync./agcsync;
dc=mean(envelopesync);
envelopesync=envelopesync-dc;
# Tukeywin applies a brief fade-in and fade-out at beginning and end
envelopesync=tukeywin(nsamp,0.02).*envelopesync;
# Resample audio to 16 kHz to make output files smaller
envelopesync16=resample(envelopesync,p,q);
# 50 Hz HPF
envelopesync16=filter(bhpf,ahpf,envelopesync16);

# Show the close-in carrier spectrum for the synchronous case
rfnarrow=resample(rfsync,1,ndecim);
[pspec,fspec]=pwelch(rfnarrow,winnarrow,[],nfft,fs/ndecim,'centerdc','plot','no-strip');
dbpspec=10*log10(pspec);
dbpspec=dbpspec-max(dbpspec);
figure(7);
plot(fspec,dbpspec);
title('Received Signal Close-In Spectrum (synchronized)');
xlabel('Frequency Offset (Hertz)');
ylabel('Amplitude (decibels)');
grid on;
saveas(7,[foutname 'specsync.png']);

# Write out IF file
# Shift the baseband signal up 12 kHz:
ifsig=rfsync.'.*exp(2i*pi*fif*t);
ifout=real(ifsig);
ifout=0.9*ifout/max(abs(ifout));
audiowrite([foutname 'syncifout.flac'],ifout,fs);

# Form stereo output file, with synchronous case on the left channel
# and nonsynchronous case in the right channel

peaksync16=max(abs(envelopesync16));
peak16=max(abs(envelopenonsync16));

envelopenonsync16=0.9*envelopenonsync16/peak16;
envelopesync16=0.9*envelopesync16/peaksync16;
pk=max(abs(envelopenonsync16));
pksync=max(abs(envelopesync16));
fprintf('Peak synchronized audio level = %f\nPeak nonsynchronized audio level = %f\n',pksync,pk);

# combine both synchronized and nonsynchronized signals into a stereo matrix 
afout=[envelopesync16 envelopenonsync16];
audiowrite([foutname '.flac'],afout,fslo);

# Form just the interference signal, with the desired signal canceled
# (except for the nonlinear distortion generated by envelope detection)

desiredfilt=filter(bbpf,abpf,desired);
desiredfilt=desiredfilt./agcsync;
dc=mean(desiredfilt);
# Tukeywin applies a brief fade-in and fade-out at beginning and end
desiredfilt=tukeywin(nsamp,0.02).*(desiredfilt-dc);
desiredfilt=resample(desiredfilt,p,q);
desiredfilt=0.9*desiredfilt/peaksync16;
desiredfilt=filter(bhpf,ahpf,desiredfilt);
syncqrm=envelopesync16-desiredfilt;
pksyncqrm=max(abs(syncqrm));


desiredfilt=filter(bbpf,abpf,desired);
desiredfilt=desiredfilt./agc;
dc=mean(desiredfilt);
# Tukeywin applies a brief fade-in and fade-out at beginning and end
desiredfilt=tukeywin(nsamp,0.02).*(desiredfilt-dc);
desiredfilt=resample(desiredfilt,p,q);
desiredfilt=0.9*desiredfilt/peak16;
desiredfilt=filter(bhpf,ahpf,desiredfilt);
nonsyncqrm=envelopenonsync16-desiredfilt;
pknonsyncqrm=max(abs(nonsyncqrm));


pk=max(pksyncqrm,pknonsyncqrm);
syncqrm=0.9*syncqrm/pk;
nonsyncqrm=0.9*nonsyncqrm/pk;
# combine both qrm signals into a stereo matrix 
qrm=[syncqrm nonsyncqrm];
# write to a wave file
audiowrite([foutname 'qrm.flac'],qrm,fslo);

# Write monophonic files

audiowrite([foutname 'sync.flac'],envelopesync16,fslo);
audiowrite([foutname 'nonsync.flac'],envelopenonsync16,fslo);
audiowrite([foutname 'syncqrm.flac'],syncqrm,fslo);
audiowrite([foutname 'nonsyncqrm.flac'],nonsyncqrm,fslo);

fprintf('Number of interferers = %i\n',nqrm);
fprintf('Signal to Interference Ratio =%6.2f dB\n',sir);
if(snr<90)
  fprintf('Signal to Noise Ratio =%6.2f dB\n',snr);
endif
toc;
