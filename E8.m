%Main function: OFDM system over a time-variant channel
clear all;
NFFT=64;
G=9;
M_ary=16;
t_a=50*10^(-9);
%load rho.am-ascii;
rho=[1, 0.6095, 0.4945, 0.3940, 0.2371, 0.19, 0.1159, 0.0699];
N_P=length(rho);

%Parameters for Monte Carlo channel
symbol_duration=NFFT*t_a;
number_of_summations=40;

%Number of summations for Monte-Carlo method
f_dmax=50;

NofOFDMSymbol=100;
length_data=(NofOFDMSymbol)*NFFT;

%Source bites
source_data=randint(length_data,sqrt(M_ary));

%bit to symbol coder
symbols=bi2de(source_data);

%QAM modulation in base band
QAM_Symbol=qammod(symbols,M_ary);

%Preparing data pattern
Data_Pattern=[];
for i=0:NofOFDMSymbol-1;
    QAM_tem=[];
    for n=1:NFFT;
        QAM_tem=[QAM_tem,QAM_Symbol(i*NFFT+n)];
    end;
    Data_Pattern=[Data_Pattern;QAM_tem];
    
    clear QAM_tem;
end;

Number_Relz=50;
ser_relz=[];
for number_of_relialization=1:Number_Relz;
    u=rand(N_P,number_of_summations);
    
    %A random variable for Monte-Carlo method
    ser=[];
    snr_min=0;
    snr_max=25;
    step=1;
    for snr=snr_min:step:snr_max;
        snr=snr-10*log10((NFFT+G)/NFFT);
        
        %Miss matching effect caused by using guard interval
        rs_frame=[];
        h_frame=[];
        initial_time=0;
        
        for i=0:NofOFDMSymbol-1;
            %OFDM modulation
            OFDM_signal_tem=OFDM_Modulator(Data_Pattern(i+1,:),NFFT,G);
            
            [h, t]=MCM_channel_model(u, initial_time, number_of_summations, symbol_duration, f_dmax, rho);
            h_frame=[h_frame; h];
            
            %The received signal over multipath channel is created by a
            %convolutional operation
            
            rs=conv(OFDM_signal_tem,h);
            
            %Additive noise is added
            rs=awgn(rs,snr,'measured','dB');
            rs_frame=[rs_frame;rs];
            initial_time=t;
            clear OFDM_signal_tem;
        end;
        
        %Receiver
        Receiver_Data=[];
        d=[];
        data_symbol=[];
        for i=1:NofOFDMSymbol;
            if (N_P>G+1)&(i>1)
                previous_symbol=rs_frame(i-1,:);
                ISI_term=previous_symbol(NFFT+2*G+1:NFFT+G+N_P-1);
                ISI=[ISI_term,zeros(1,length(previous_symbol)-length(ISI_term))];
                rs_i=rs_frame(i,:)+ISI;
            else
                rs_i=rs_frame(i,:);
            end;
            
            %OFDM demodulator
            Demodulated_signal_i=OFDM_Demodulator(rs_i,NFFT,NFFT,G);
            
            %OFDM Equalization
            h=h_frame(i,:);
            H=fft([h,zeros(1,NFFT-N_P)]);
            d=Demodulated_signal_i./H;
            demodulated_symbol_i=qamdemod(d,M_ary);
            data_symbol=[data_symbol, demodulated_symbol_i];
        end;
            data_symbol=data_symbol';
            
            %Calculation of error symbols
            [number, ratio]=symerr(symbols, data_symbol);
            ser=[ser, ratio];
    end;
    ser_relz=[ser_relz;ser];
end;
ser=sum(ser_relz)/Number_Relz;
snr=snr_min:step:snr_max;
semilogy(snr, ser, '*--');
hold off
    
ylabel('SER');
xlabel('SNR in dB');
legend('time-variant', 'time-invariant');