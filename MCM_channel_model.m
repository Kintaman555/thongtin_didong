%Monte carlo method for a time-variant channel modelling

function [h,t_next]= MCM_channel_model(u, initial_time, number_of_summations, symbol_duration, f_dmax, channel_coefficients);
t=initial_time;
Channel_Length=length(channel_coefficients);
h_vecto=[];
for k=1:Channel_Length;
    u_k=u(k,:);
    phi=2*pi*u_k;
    f_d=f_dmax*sin(2*pi*u_k);
    h_tem=channel_coefficients(k)*1/(sqrt(number_of_summations))*sum(exp(j*phi).*exp(j*2*pi*f_d*t));
    h_vecto=[h_vecto, h_tem];
end;
h=h_vecto;
t_next=initial_time+symbol_duration;
