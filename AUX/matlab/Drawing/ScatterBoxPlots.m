function [hs,xxxlim]=ScatterBoxPlots(D,varargin)
% hs=ScatterBoxPlots(D,varargin)
%
% Draws data-points with a jitter on x-axis. Alt to box plots.
%
%%%INPUTS:
% D         : #sub x #measures
% PointSize : [Optional] Size of each point, PointSize=30;
% Colk      : [Optional] Colour for data points, Colk=[0,0.4470,0.7410]
%
%
%   SA, 2017, UoW/Ox
%   srafyouni@gmail.com

% orange=[0.8500,0.3250,0.0980];
% blue=[0,0.4470,0.7410];

nmeas = size(D,2);

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
if sum(strcmpi(varargin,'DownSample'))
   DS  = varargin{find(strcmpi(varargin,'DownSample'))+1};
else
   DS = 1;
end
%
if sum(strcmpi(varargin,'MarkerFaceAlpha'))
   malp  = varargin{find(strcmpi(varargin,'MarkerFaceAlpha'))+1};
else
   malp = 1;
end
%
if sum(strcmpi(varargin,'MarkerEdgeAlpha'))
   ealp  = varargin{find(strcmpi(varargin,'MarkerEdgeAlpha'))+1};
else
   ealp = 1;
end
%
if sum(strcmpi(varargin,'MedLineColor'))
   MedLineColor = varargin{find(strcmpi(varargin,'MedLineColor'))+1};
else
   MedLineColor = 'r';
end
%
if sum(strcmpi(varargin,'Line'))
   LineFlag = 1;
   if sum(strcmpi(varargin,'LineColor'))
       LineColor = varargin{find(strcmpi(varargin,'LineColor'))+1};
   else
       LineColor = 'r';
   end
   
   if sum(strcmpi(varargin,'LineWidth'))
       LineWidth = varargin{find(strcmpi(varargin,'LineWidth'))+1};
   else
       LineWidth = 0.5;
   end   
   
else
   LineFlag = 0;
end
%
% if sum(strcmpi(varargin,'xaxis'))
%    LineFlag = 1;
% else
%    LineFlag = 0;
% end
%
if sum(strcmpi(varargin,'Unequal'))
    disp('OO')
   EqFlag = 0;
else
   EqFlag = 1;
end
%
if sum(strcmpi(varargin,'Color'))
   Col = varargin{find(strcmpi(varargin,'Color'))+1};
else
   Col = repmat([0,0.4470,0.7410],nmeas,1);
end
%##############################################
if EqFlag
    nsub  = round(size(D,1)./DS);
    for cnt_vv = 1:nmeas
        Y0 = D(:,cnt_vv);
        
        if DS>1
            Y00 = datasample(Y0,nsub);
        else
            Y00 = Y0;
        end
        
        xxxlim_tmp = (cnt_vv) + randn(1,nsub) ./20;
        xxxlim(:,cnt_vv)=xxxlim_tmp;
        hs{cnt_vv} = scatter(xxxlim_tmp,Y00,ones(1,nsub)*PointSize,'MarkerEdgeColor',Col(cnt_vv,:),'marker','o','markerfacecolor',Col(cnt_vv,:),'MarkerFaceAlpha',malp,'MarkerEdgeAlpha',ealp);
        line([min(xxxlim_tmp) max(xxxlim_tmp)],[mean(Y0) mean(Y0)],'Color',MedLineColor,'linewidth',3)
    end
    if LineFlag
        plot(1:nmeas,mean(D),'color',LineColor,'linewidth',LineWidth,'linestyle','-.')
    end
else
    nmeas = numel(D);
    for cnt_vv = 1:nmeas
        Y0 = D{cnt_vv};
        
        if isempty(Y0); continue; end;
        
        %size(Y0)
        nsub  = round(size(Y0,1)./DS);
        
        if DS>1
            Y0 = datasample(Y0,nsub);
        end
        
        xxxlim_tmp = (cnt_vv) + randn(1,numel(Y0)) ./20;
        xxxlim{cnt_vv}=xxxlim_tmp;
        hs{cnt_vv} = scatter(xxxlim_tmp,Y0,ones(1,nsub)*PointSize,'MarkerEdgeColor',Col(cnt_vv,:),'marker','o','markerfacecolor',Col(cnt_vv,:),'MarkerFaceAlpha',malp,'MarkerEdgeAlpha',ealp);
        line([min(xxxlim_tmp) max(xxxlim_tmp)],[mean(Y0) mean(Y0)],'Color',MedLineColor,'linewidth',3)
    end
    if LineFlag
        plot(1:nmeas,cellfun(@mean,D),'color',LineColor,'linewidth',LineWidth,'linestyle','-.');
    end
end
%##############################################
set(gca,'xgrid','on')
set(gca,'Xtick',1:nmeas)