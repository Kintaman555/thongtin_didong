%OFDM modulator NFFT:FFT length
%chnr: number of subcarrier
%G: guard length
%N_P: channel impulse response length
%save this program to filename "OFDM_Demodulator.m" for use in the main
%function

function [y]=OFDM_Demodulator(data,chnr,NFFT,G);

%insert the guard interval
x_remove_guard_interval=[data(G+1:NFFT+G)];
x=fft(x_remove_guard_interval);
y=x(1:chnr);                                        %zero removing
