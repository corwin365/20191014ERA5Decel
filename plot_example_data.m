clearvars


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot example ERA5 acceleration plot as a sanity check
%Corwin Wright, c.wright@bath.ac.uk, 14/OCT/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.Height = 30; %km


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
Data = load('era5_winds.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%compute |u|
Data.Results = quadadd(Data.Results.u,Data.Results.v);
 
% % % % %reshape the data to be a continuous time series rather than day,hour split
% % % % sz = size(Data.Results);
% % % % Data.Results = reshape(Data.Results,sz(1)*sz(2),sz(3),sz(4),sz(5));
% % % % [a,b] = meshgrid(Data.Settings.TimeScale,Data.Settings.HourScale./24);
% % % % Data.Time = a(:)+b(:);
% % % % clear a b
Data.Results = squeeze(nanmean(Data.Results,2));
Data.Time = Data.Settings.TimeScale;


%compute d/dt
Data.Results = diff(Data.Results,1,1);%.*4; %m/s/day

%pull out height
zidx = closest(Data.Settings.HeightScale,Settings.Height);
Data.Results = squeeze(Data.Results(:,zidx,:,:));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% animate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
for iTime=1:1:numel(Data.Time)
  
  Lon    = Data.Settings.LonScale;
  Lat    = Data.Settings.LatScale;
  Time   = Data.Time(iTime);
  ToPlot = squeeze(Data.Results(iTime,:,:));
  
  Levels = -20:120./16:20;
  
  ToPlot(ToPlot < min(Levels)) = min(Levels);
  
  m_proj('stereographic','lat',-90,'long',0,'radius',50);
  m_contourf(Lon,Lat,ToPlot',Levels,'edgecolor','none');
  m_coast('color','k');
  m_grid;
  colorbar
  caxis([min(Levels) max(Levels)])
  redyellowblue16
  title(datestr(Time))
  drawnow
  
% pause(0.25)
  
  
end