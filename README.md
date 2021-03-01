# nrsc-am-cochannel-simulator
GNU Octave code to simulate AM cochannel reception, with and without carrier synchronization.  Produces audio and graphics files.

This software is used to subjectively evaluate the effects of carrier synchronization on cochannel interference. It runs under GNU Octave, which is a free open source matrix math tool. Versions are available for Linux, macOS, BSD, and Microsoft Windows. 

GNU Octave is available here:
  https://www.gnu.org/software/octave/

GNU Octave scripts are interpreted, not compiled. **So you must install GNU Octave to run the source code in this repo.**

The software reads from a number of flac audio files to produce a desired signal with a number of interferers. The number of interferers can be from 1 to 71. The interferers may 
be set to randomly selected amplitudes or their amplitudes may be specified to simulate reception at a specific location of a specific station. Each interferer fades in both 
amplitude and phase.

The audio files are all 60 seconds in length. The desired signal is a talk show, chosen because the speaker pauses between phrases and words, making it possible to hear the 
interferers.

The flac audio file format is lossless. So it is just as accurate as a WAV file, but file size is smaller than WAV. Most audio players (such as VLC) can play the flac format.

The software includes a typical narrowband envelope detector receiver model with fast AGC.

The output files are generated in both mono and stereo formats. In the stereo files, one channel has synchronized carriers and the other channel does not, making it possible to 
hear both simultaneously.

There are also files where the desired signal is mostly canceled by subtracting it, leaving just the interferers. The cancellation is not perfect because envelope detection is 
nonlinear.

The software also generates graphics, showing the close-in RF spectra, the interferer (fading) amplitudes, the interferer (fading) phases, and the receiver AGC for both 
synchronous and nonsynchronous operation.
