%OFDM modulator NFFT:FFT length
%chnr: number of subcarrier
%G: guard length
%save this program to filename "OFDM_Modulator.m" for use in the main
%function

function [y]=OFDM_Modulator(data,NFFT,G);
chnr=length(data);
N=NFFT;
x=[data,zeros(1,NFFT-chnr)];             %zero padding
a=ifft(x);                               %fft
y=[a(NFFT-G+1:NFFT),a];                  %insert the guard interval
