function hs=ScatterBoxPlots_Unequal(D,varargin)
% hs=ScatterBoxPlots(D,varargin)
%
% Draws data-points with a jitter on x-axis. Alt to box plots.
%
%%%INPUTS:
% D         : #sub x #measures
% hndl      : [Optional] handle to the figures. 
% PointSize : [Optional] Size of each point, PointSize=30;
% Colk      : [Optional] Colour for data points, Colk=[0,0.4470,0.7410]
%
%
%   SA, 2017, UoW
%   srafyouni@gmail.com
%
% orange=[0.8500,0.3250,0.0980];

if sum(strcmpi(varargin,'subplot'))
   hndl  = varargin{find(strcmpi(varargin,'subplot'))+1};
   subplot(hndl)
elseif sum(strcmpi(varargin,'figure'))
   hndl  = varargin{find(strcmpi(varargin,'figure'))+1};
   figure(hndl)
else
    hndl = figure; hold on; box on;
end
%
if sum(strcmpi(varargin,'PointSize'))
   PointSize  = varargin{find(strcmpi(varargin,'PointSize'))+1};
else
    PointSize = 30;
end
%
if sum(strcmpi(varargin,'MedLineColor'))
   MedLineColor = varargin{find(strcmpi(varargin,'MedLineColor'))+1};
else
   MedLineColor = 'r';
end
%
if sum(strcmpi(varargin,'Col'))
   Col = varargin{find(strcmpi(varargin,'Col'))+1};
else
   Col = [0,0.4470,0.7410];
end
%##############################################

nmeas = size(D,2);
for cnt_vv = 1:nmeas
    nsub  = size(D{cnt_vv},1);
    xxxlim = (cnt_vv) + randn(1,nsub) ./20;
    hs{cnt_vv} = scatter(xxxlim,D{cnt_vv},ones(1,nsub)*PointSize,'MarkerEdgeColor',Col,'marker','o','markerfacecolor',Col);
    line([min(xxxlim) max(xxxlim)],[median(D{cnt_vv}) median(D{cnt_vv})],'Color',MedLineColor,'linewidth',3)
end
plot(1:nmeas,cellfun(@median,D),'color','r','linewidth',0.5,'linestyle','-.')

set(gca,'xgrid','on')
set(gca,'Xtick',1:nmeas)