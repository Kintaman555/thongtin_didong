% a functon which equalizes the received symbols according a known channel
% then demodulates QPSK symbols and counts the error symbols
function chann_1=receiver(SNR_db,S_m,FS,x,S,g);
Es=var(S);                                %variance of QPSK symbols (symbol energy)
Eb=Es/2;                                  %bit energy
N_0=Eb/10^(SNR_db/10);                    %noise level in linear
N0=sqrt(N_0/2)*(randn(size(FS))+j*randn(size(FS)));
NFS=(FS+N0)./g;                           %received symbols after channel equalization

for i=1:length(FS)                        %calculate the distance of the received symbol to all possible reference symbols
    d=abs(S_m-NFS(i));
    %QPSK demudulation
    md=min(d);
    if md==d(1);
        R(2*i-1)=0;
        R(2*i)=0;
    elseif md==d(2)
        R(2*i-1)=0;
        R(2*i)=1;
    elseif md==d(3)
        R(2*i-1)=1;
        R(2*i)=1;
    elseif md==d(4)
        R(2*i-1)=1;
        R(2*i)=0;
    end
end

c=0;                                     %set the counter of the bit error to zero
for i=1:length(x)
    if R(i)~=x(i);
        c=c+1;                           %increase the counter if an error occurs
    end
end
chann_1=c;
