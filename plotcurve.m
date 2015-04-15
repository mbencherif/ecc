function [] = plotcurve(c)
    h = ezplot(c);
    set(h, 'LineWidth', 4);
    set(h, 'color', 'b');
    ha = refline(0,0);
    set(ha, 'color', 'k');
    va = line([0,0], ylim);
    set(va, 'color', 'k');
end
