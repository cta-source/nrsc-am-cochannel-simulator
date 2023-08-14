# Scale fading function to provide a desired value of
# percent skywave. 10% and 50% are typical.
# fadepct is the desired skywave percentage (1 to 99)
# fadein is the complex fading function to be scaled
# fadeout is the scaled output
function [fadeout,gain]=pctskywave(fadepct,fadein)
envsort=sort(abs(abs(fadein)));
f=0.01*fadepct;
nfade=length(fadein);
npoint=max(1,min(nfade,nfade-round(f*nfade)));
apoint=envsort(npoint);
gain=1/apoint;
fadeout=gain*fadein;
endfunction
