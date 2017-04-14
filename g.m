% a function which creates the deterministic process g(t)
%Save this funtion to a file name "g.m"

function y=g(c,f,th,t);
y=zeros(size(t));
for n=1:length(f);
    y=y+c(n)*cos(2*pi*f(n).*t+th(n));
end;