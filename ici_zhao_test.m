% FFT length
fft_len = 64;

% guard_lenuard length
guard_len = fft_len / 4;

% Modulation order
m_ary = 16;

% Number of symbols
no_of_symbols = 100;

rho = [1, 0.6095, 0.4945, 0.3940, 0.2371, 0.19, 0.1159, 0.0699];
n_p = length (rho);

% The length of the input bit sequence
data_len = no_of_symbols * fft_len;

% guard_lenenerating random bit sequence in matrix form
input_bit_seq = randi ([0 1], data_len, sqrt (m_ary));

% Converting each row of the matrix to decimal value
input_dec_seq = zeros (1, data_len);
for i = 1:data_len
	input_dec_seq(i) = bi2de (input_bit_seq(i, :));
end

% Putting source data through the PSK Modulator
modulated_data = pskmod (input_dec_seq, 16, 0, 'gray');

% Implementing ICI canceling modulation
ici_modulated_data = zeros (1, (data_len * 2));
indx_ici = 1;
for j = 1:2:(data_len * 2)
	ici_modulated_data(j) = modulated_data(indx_ici);
	ici_modulated_data(j + 1) = -(modulated_data(indx_ici));
	indx_ici = indx_ici + 1; 
end

% N-point IFFT implementation with N equals 64
N = fft_len;
data_ifft = zeros (N, no_of_symbols * 2);
indx_ff = 0;
for i = 1:(no_of_symbols * 2)
    for j = 1:N
        data_ifft(j, i) = ici_modulated_data(indx_ff + j);
    end
    
    indx_ff = indx_ff + fft_len;
end

ifft_data = ifft (data_ifft, fft_len, 1);

% Adding guard
guarded_data = vertcat (ifft_data((end - (guard_len - 1)):end, :), ifft_data);

% Parametereceived_data for Monte Carlo channel
no_of_realizations = 50;
no_of_summations = 40;

t_a = 50 * 10^(-9);
sym_duration = fft_len * t_a;
f_dmax = 50;

% Channel simulation
snr_min = 0;
snr_max = 25;
step = 1;

received_data_frame = zeros ((fft_len + guard_len + n_p - 1), (no_of_symbols * 2));
h_frame = zeros ((no_of_symbols * 2), n_p);
processed_data = zeros ((fft_len + guard_len), (no_of_symbols * 2));

for n_r = 1:no_of_realizations;
    u = rand (n_p, no_of_summations);
    
    % A random variable for Monte-Carlo method
    for snr = snr_min:step:snr_max;
        snr = snr - 10 * log10 ((fft_len + guard_len) / fft_len);
        
        % Miss matching effect caused by using guard interval
        initial_time = 0;
        
        for i = 1:(no_of_symbols * 2);
            [h, t] = MCM_channel_model (u, initial_time, no_of_summations, sym_duration, f_dmax, rho);
            h_frame(i, :) = h;
            
            % Received signal over multipath channel by convolutional operation
            
            received_data = conv (guarded_data(:, i), h);
            
            % Adding additive noise
            received_data = awgn (received_data, snr, 'measured', 'dB');
            received_data_frame(:, i) = received_data;
            initial_time = t;
        end;
        
        % ISI simulation
        for i = 1:(no_of_symbols * 2);
            if (n_p > guard_len + 1) && (i > 1)
                previous_symbol = received_data_frame(:, i-1);
                isi_term = previous_symbol(fft_len+guard_len+n_p-1:fft_len+2*guard_len+1);
                isi = [isi_term, zeros(1,length (previous_symbol) - length (isi_term))];
                received_data_frame(:, i) = received_data_frame(:, i) + ISI;
            end;
            
        end;
        
    end;
    
end;

% Signal retrieving
for i = 1:(no_of_symbols * 2)
	h_freq = fft ([h_frame(i, :), zeros(1, fft_len+guard_len-1)]);
	h_freq_trans = transpose (h_freq);
	processed_col = received_data_frame(:, i) ./ h_freq_trans;
	processed_col = processed_col(1:(fft_len + guard_len));
	processed_data(:, i) = processed_col;
end

% Removing guard
offguarded_data = processed_data((end - (fft_len - 1)):end, :);

% N-point FFT implementation with N equals 64
fft_data = fft (offguarded_data, N, 1);

% Implementing ICI canceling demodulation
ici_demodulated_data = zeros (1, data_len);
indx_ici = 1;
for j = 1:2:(data_len * 2)
  ici_demodulated_data(indx_ici) = fft_data(j);
  indx_ici = indx_ici + 1;
end

% Putting ICI demodulated data through PSK Demodulator
demodulated_data = pskdemod (ici_demodulated_data, 16, 0, 'gray');

% Converting output decimal values to binary rows
output_bit_seq = de2bi (demodulated_data);
%output_bit_seq = vec2mat (output_de2bi_seq, 4);

% Calculating the number of symbol erroreceived_data and symbol error rate
[no_of_bits, ser] = symerr (input_bit_seq, output_bit_seq);
disp ('number of bits: ');
disp (no_of_symerreceived_data);
disp ('bit error rate: ');
disp (ser);

a = demodulated_data - input_dec_seq;
if nnz (a) == 0
  disp ('all zero');
end
