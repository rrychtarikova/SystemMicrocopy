% % Function for changing ticks on the plot.
% % Inputs: pxsize ... pixel size array [xSize ySize zSize]
% % Must be called after creation of the plot
% % gca - current axes handle

function newTicks(pxsize)

XTicks=get(gca,'XTick');
YTicks=get(gca,'YTick');
ZTicks=get(gca,'ZTick');

set(gca,'XTickLabel',num2cell(XTicks*pxsize(1)));
set(gca,'YTickLabel',num2cell(YTicks*pxsize(2)));
set(gca,'ZTickLabel',num2cell(ZTicks*pxsize(3)));