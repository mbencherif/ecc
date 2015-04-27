set(gcf,'renderer','opengl')
set(0,'DefaultLineLineSmoothing','on')
set(0,'DefaultPatchLineSmoothing','on')

plotcurve('x.^3 - 3.*x + 1 - y.^2')
print('images/ec1', '-dpng')

plotcurve('x.^3 - 3.*x + 2 - y.^2')
print('images/ec2', '-dpng')

plotcurve('x.^3 - y.^2')
print('images/ec3', '-dpng')

plotcurve('x.^3 - 2.*x + 2 - y.^2')
print('images/ec4g', '-dpng')