# ===========================================================================
# Co-channel AM broadcast channel interference simulator
# Version 2.1 - December 15, 2020
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
# adjusted to provide the desired average SNR value (10 dB is the default). 
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
# The output files are also in the FLAC format. Most modern audio player
# software (such as VLC, Audacity, etc.) supports the FLAC format.
#
# The relative amplitudes of the interfering signals may be set at random,
# with a specified SNR value (such as 10 dB). Or, this script may be operated
# in "NIF mode," where NIF means "Nighttime Interference Free." In NIF mode,
# the relative rms amplitudes of the interferers are set by a file named
# "nif.txt" where the linear relative amplitude of each interferer is set.
# The desired signal is assigned an amplitude of 1 (unity). If you wanted
# three interferers at -20, -26, and -30 dB for instance, then the nif.txt
# file would look like this:
#
#   0.1
#   0.05
#   0.0316
#
# The snr value is ignored in NIF mode.
# To use NIF mode, set the variable NIFMODE=1. To use the random amplitude
# levels, with a combined SNR value, set NIFMODE=0 and SNR to the value in
# dB that you want (such as 10 dB).
#
# There are six audio files produced by this script. They begin with the
# string "cochannelXX" where XX is the number of interferers. So you would
# have "cochannel03" or "cochannel64" for 3 or 64 interferers, respectively.
# If NIF mode is invoked, the file names will start with "nifXX" instead.
# The files are:
#   cochannelXX.flac - stereo file, synchronous case on left channel,
#                      nonsynchronouse case on the right channel
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
# There are also six graphics files produced:
#   cochannelXXspecsync.png - close in spectrum of synchronous spectrum
#   cochannelXXspecnonsync.png -0 close in spectrum of nonsynchronous spectrum
#   cochannelXXagc.png - shows receiver AGC signal for both synchronous
#                        and nonsynchronous cases.
#   cochannelXXampqrm.png - shows amplitude versus time for interferers
#                           (both synchronous and nonsynchronous)
#   cochannelXXphaseqrmnonsync.png - shows phase versus time for nonsynchronous
#                                    interferers.
#   cochannelXXphaseqrmsync.png - shows phase versus time for synchronous
#                                 interferers.
#   
#   
#
# To use this script, change the number of interferers by changing the value
# for nfile2. You can also change the nfile1 value if you want to try some
# different interfering signals.
#
# To change the signal to noise ratio, change the SNR value. This is the
# signal to noise ratio in dB. 10 dB is the default. It creates a lot of
# interference at 10 dB, but the desired signal is still audible, and every
# word is discernible in the desired signal.
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
# Set NIFMODE=0 for random amplitudes, NIFMODE=1 to read relative amplitudes
#   from the file nif.txt:
NIFMODE=0;
# Set SNR (in decibels) (ignored if NIFMODE is used):
snr=10;
# Set the number of interferers here:
# For graveyard simulation use 64 interferers:
# nfile1=1;
# nfile2=64;
# For non-graveyard simulation use 3 interferers:
# nfile1=1;
# nfile2=3;
nfile1=1;
nfile2=64;
# Read in the previously randomly generated interference parameters
load "parameters.txt";
nfreqs=length(freqerr);
sdfreq=sqrt(sum(freqerr.^2)/(nfreqs-1));
fprintf('Standard deviation of carrier offset frequencies = %f\n',sdfreq);
fprintf('Max carrier offset = %f\n',max(freqerr));
fprintf('Min carrier offset = %f\n',min(freqerr));
# Read in the desired signal
[desired,fs]=audioread('audio01.flac');
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
  nfile1=1;
  nfile2=length(nif);
  nqrm=nfile2-nfile1+1;
  rfamp(1:nfile2)=20*log10(nif);
  foutname=sprintf('nif%2.2i',nqrm);
endif
gplot=zeros(nqrm,ngplot);
for jfile=nfile1:nfile2
  ifile=jfile+1;
  afname=sprintf('audio%2.2i.flac',ifile);
  ffname=sprintf('fade%2.2i.flac',ifile);
  [qrmout,gplot(ifile-nfile1,:)]=addsig(qrm,afname,ffname,freqerr(jfile),rfamp(jfile));
  qrm=qrmout;
# If you want to see the offset frequencies, uncomment the next line
#  fprintf('freqerr(%i)=%f\n',jfile,freqerr(jfile));
endfor
t=linspace(0,nsamp-1,nsamp)/fs;
figure(2);
plot(t(1:nskip:nsamp),raddeg*unwrap(angle(gplot.')));
title('Phases (Unwrapped) of Interferers - Nonsynchronous Case');
xlabel('Time (seconds)');
ylabel('Phase (degrees)');
grid on;
saveas(2,[foutname 'phaseqrmnonsync.png']);
if (NIFMODE==0)
# Calculate QRM amplitude
  qrmrms=rms(qrm);
  sigrms=rms(desired);
# Scale the QRM to the desired amplitude
  qrmamp=10^(-snr*0.05)*sigrms/qrmrms;
else
  qrmamp=1;
endif
fprintf('QRM gain for nonsynchronous case = %f\n',qrmamp);
figure(1);
plot(t(1:nskip:nsamp),qrmamp*abs(gplot.'));
title('Amplitudes of Interferers');
xlabel('Time (seconds)');
ylabel('Relative Linear Amplitude');
grid on;
saveas(1,[foutname 'ampqrm.png']);
rf=desired+qrm*qrmamp;
# To simulate 5 kHz receiver bandwidth, make a 2.5 kHz 5th order Butterworth LPF
fcutoff=2500;
[bbpf,abpf]=butter(5,2*fcutoff/fs);
rf=filter(bbpf,abpf,rf);
envelopenonsync=abs(rf);
# Make 10 Hz LPF for receiver AGC (single pole)
# This was 1 Hz in earlier versions. 10 Hz makes AGC faster.
fagc=10;
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
figure(3);
plot(fspec,dbpspec);
title('Received Signal Close-In Spectrum (nonsynchronized)');
xlabel('Frequency Offset (Hertz)');
ylabel('Amplitude (decibels)');
grid on;
saveas(3,[foutname 'specnonsync.png']);


# Now do the synchronous case
# Zero out the frequency error - set all frequency offsets to zero
# Everything else (fading, amplitude, etc.) remains the same
freqerr=zeros(size(freqerr));
qrm=zeros(size(desired));
for jfile=nfile1:nfile2
  ifile=jfile+1;
  afname=sprintf('audio%2.2i.flac',ifile);
  ffname=sprintf('fade%2.2i.flac',ifile);
  [qrmout,gplot(ifile-nfile1,:)]=addsig(qrm,afname,ffname,freqerr(jfile),rfamp(jfile));
  qrm=qrmout;
endfor
figure(4);
plot(t(1:nskip:nsamp),raddeg*unwrap(angle(gplot.')));
title('Phases (Unwrapped) of Interferers - Synchronous Case');
xlabel('Time (seconds)');
ylabel('Phase (degrees)');
grid on;
saveas(4,[foutname 'phaseqrmsync.png']);
# Must use the SAME QRM amplitude for the synchronous case!
rfsync=desired+qrm*qrmamp;
# Bandpass filter
rfsync=filter(bbpf,abpf,rfsync);
envelopesync=abs(rfsync);
# Subtract 1 from AGC lowpass signal before filtering, then restore it
agcsync=1+filter(b,a,envelopesync-1);
agcsync=max(0.25,agcsync);
t=linspace(0,nsamp-1,nsamp)/fs;
# Show the receiver AGC waveforms for synchronous and nonsynchronous cases
figure(5);
plot(t,agc,t,agcsync);
title('Receiver AGC (divided by this waveform)');
xlabel('Time (seconds)');
ylabel('Reciprocal of Gain');
legend('Nonsync','Sync','location','south');
grid on;
saveas(5,[foutname 'agc.png']);
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
figure(6);
plot(fspec,dbpspec);
title('Received Signal Close-In Spectrum (synchronized)');
xlabel('Frequency Offset (Hertz)');
ylabel('Amplitude (decibels)');
grid on;
saveas(6,[foutname 'specsync.png']);


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
toc;
