function logx2raw(base,precision)
%logx2raw([base],[precision])
%
%Converts X-axis labels from log to raw values.
%base:    	base of log transform; default base is e.
%precision:	number of decimal places;  default  is two.
%
%Example:
% x=linspace(-3,0,11);
% plot(log(x),log(x.^2));
% logx2raw
% logy2raw

%SEE ALSO;   Logy2raw
%11/17/96	gmb	Wrote it.
%6/6/96	        gmb added precision argument
%01/30/02       gmb updated it to use cell arrays, and to use original
%                xtick values instead of converting labels.  This way,
%		multiple calls to this function doesn't keep converting
%		the axis.

if nargin==0
	base=exp(1);
end
if nargin<2
	precision=2;
end
qt='''';

origXTick = get(gca,'XTick');

newXTick = base.^(origXTick);

for i=1:length(newXTick)
  estr=(['newXLabel{i}=num2str(sprintf(',qt,'%',sprintf('%2.1f',precision*1.1), ...
	'f',qt,',newXTick(i)));']);
  eval(estr)
end
set(gca,'XTickLabel',newXLabel);