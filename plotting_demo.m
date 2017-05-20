x = 0:0.1:10;
y1 = sin(2*x);
y2 = cos(2*x);

figure
hold off
for  i=1:4
    subplot(2,2,i)       % add first plot in 2 x 2 grid
    plot(x,y1)           % line plot
    title(['Subplot ' int2str(i)])
    hold on
end