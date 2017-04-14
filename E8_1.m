%Main function of ex8_1

clear all;

NFFT=64;                            %FFT length
G=0;                                %Guard interval length
M_ary=16;                           %Multilevel of M-ary symbol
t_a=50*10^(-9);                     %Sampling duration of HiperLan/2
%load rho.am-ascii;                  %load discrete multi-path channel profile
rho=[1, 0.6095, 0.4945, 0.3940, 0.2371, 0.19, 0.1159, 0.0699, 0.0462];
h=sqrt(rho);
N_P=length(rho);
H=fft([h,zeros(1,NFFT-N_P)]);
NofOFDMSymbol=100;                  %Number of OFDM symbols
length_data=(NofOFDMSymbol)*NFFT;   %The total data length

%Source bites
source_data=randint(length_data,sqrt(M_ary));

%bit to symbol coder
symbols=bi2de(source_data);

%QAM modulator in base band
QAM_Symbol=qammod(symbols,M_ary);

%Preparing data pattern
Data_Pattern=[];                     %Transmitted signal before IFFT
for i=0:NofOFDMSymbol-1;
    QAM_tem=[];
    for n=1:NFFT;
        QAM_tem=[QAM_tem,QAM_Symbol(i*NFFT+n)];
    end;
    Data_Pattern=[Data_Pattern;QAM_tem];
    
    clear QAM_tem;
end;

ser=[];                              %set the counter of symbol error ratio to be a empty vector
snr_min=0;
snr_max=25;
step=1;
for snr=snr_min:step:snr_max;
    snr=snr-10*log10((NFFT+G)/NFFT); %Miss matching effect
    rs_frame=[];                     %A matrix of received signal
    for i=0:NofOFDMSymbol-1;
        %OFDM modulator
        OFDM_signal_tem=OFDM_Modulator(Data_Pattern(i+1,:),NFFT,G);
        
        %The received signal over multi-path channel is created by a
        %convolutional operation
        
        rs=conv(OFDM_signal_tem,h);
        
        %Additive noise is added
        rs=awgn(rs,snr,'measured','dB');
        rs_frame=[rs_frame;rs];
        clear OFDM_signal_tem;
    end;
    
    %Receiver
    
    Receiver_Data=[];                    %Prepare a matrix for received data symbols
    
   d=[];                                 %Demodulated symbols
   data_symbol=[];
   for i=1:NofOFDMSymbol;
       if(N_P>G+1)&(i>1)
           previous_symbol=rs_frame(i-1,:);  %previous OFDM symbol
           ISI_term=previous_symbol(NFFT+2*G+1:NFFT+G+N_P-1);
           ISI=[ISI_term,zeros(1,length(previous_symbol)-length(ISI_term))];
           rs_i=rs_frame(i,:)+ISI;           %the ISI term is added to the current OFDM symbol
       else
           rs_i=rs_frame(i,:);
       end;
       
       %OFDM demodulator
       
       Demodulated_signal_i=OFDM_Demodulator(rs_i,NFFT,NFFT,G);
       
       %OFDM Equalization
       d=Demodulated_signal_i./H;
       demodulated_symbol_i= qamdemod(d,M_ary);
       data_symbol=[data_symbol, demodulated_symbol_i];
   end;
   data_symbol= data_symbol';
   %calculation of error symbols
   [number, ratio]=symerr(symbols, data_symbol);
   ser=[ser, ratio];
end;

snr=snr_min:step:snr_max;
semilogy(snr,ser,'bo');
ylabel('SER');
xlabel('SNR in dB');
%save e8p1_Res snr ser;