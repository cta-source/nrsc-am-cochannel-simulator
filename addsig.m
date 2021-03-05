# ===========================================================================
# Co-channel AM broadcast channel interference simulator
# Version 2.1 - December 15, 2020
# By Dave Hershberger
# Nevada City, California
# dave@w9gr.com
#
# For NRSC AIWG
#
# This is a function called by the main script. It adds an interferer to
# the rf signal, producing a rfout signal.
# It requires the following input arguments:
#   rf - input RF signal
#   afname - file name from which to read the interferer audio
#           90% of full scale in the wav file corresponds to 100% AM
#   ffname - file name fromw which to read the complex fading function
#   rffreq - the frequency offset (in Hertz) of the interferer
#   rfamp - the amplitude of the interferer (in dB)
#   fade - a complex vector representing the fading function
#
# rfout is the rf input signal plus the added interferer
# gplot is a subsampled version of the fading function, for plotting
#
# ===========================================================================
function [rfout,gplot]=addsig(rf,afname,ffname,rffreq,rfamp)
# Read the specified audio flac file
[y,fs]=audioread(afname);
# Read the specified fading function flac file
[fade,fs]=audioread(ffname);
# Convert it to complex
fade=fade(:,1)+1i*fade(:,2);
# Normalize fading function to unity rms amplitude
fade=fade/rms(fade);
# Convert audio to AM by adding carrier and clipping negative peaks (if any)
y=max(0,y/0.9+1);
nsamp=length(y);
# Create time vector
t=linspace(0,nsamp-1,nsamp).'/fs;
# Create phase and frequency shift
coffset=exp(2i*pi*rffreq*t);
# Calculate linear amplitude from dB value
amp=10^(rfamp/20);
# Create amplitude and phase vector
gain=amp.*fade.*coffset;
# Create faded interferer with frequency shift
rfout=rf+gain.*y;
# Create subsampled gain vector for plotting
nskip=round(100*60);
gplot=gain(1:nskip:nsamp).';
endfunction
