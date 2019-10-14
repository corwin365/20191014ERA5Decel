clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%prepare ERA5 data for an analysis to see if SSW deceleration is localised
%spatially over the Andes
%
%Corwin Wright, c.wright@bath.ac.uk
%14/OCT/2019
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir     = [LocalDataDir,'/ERA5'];
Settings.TimeScale   = datenum(2002,6,1):1:datenum(2002,11,1);
Settings.HourScale   = 0:6:18;
Settings.LatScale    = -90:2.5:-40;
Settings.LonScale    = -180:5:180;
Settings.HeightScale = 0:5:60; 
Settings.Vars        = {'u','v'};
Settings.OutFile     = 'era5_winds.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% setup of stuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%variable storage fields
for iVar=1:1:numel(Settings.Vars)
  Results.(Settings.Vars{iVar}) = NaN(numel(Settings.TimeScale),   ...
                                      numel(Settings.HourScale),   ...
                                      numel(Settings.HeightScale), ...
                                      numel(Settings.LonScale),    ...
                                      numel(Settings.LatScale));
end
            
%regridding parameters
[a,b,c,d] = ndgrid(Settings.LonScale,Settings.LatScale, ...
                   Settings.HeightScale,Settings.HourScale);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and process data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    

for iDay=1:1:numel(Settings.TimeScale)
  disp(datestr(Settings.TimeScale(iDay)))
  
  %load file
  EcmwfFile = era5_path(Settings.TimeScale(iDay));
  if ~exist(EcmwfFile,'file'); clear EcmwfFile; continue; end
  Data = cjw_readnetCDF(EcmwfFile);
  clear EcmwfFile
  
  %compute pressure axis
  Data.Prs = ecmwf_prs_v2([],137);
  
  %convert to height
  Data.Z = p2h(Data.Prs);
  
  %flip latitudes and heights to ascend monotonically
  [~,idxA] = sort(Data.latitude,'ascend');
  [~,idxB] = sort(Data.Z,'ascend');
  Data.latitude = Data.latitude(idxA);
  Data.Z = Data.Z(idxB);
  for iVar=1:1:numel(Settings.Vars)
    Var = Data.(Settings.Vars{iVar});
    Var = Var(:,idxA,:,:);
    Var = Var(:,:,idxB,:);
    Data.(Settings.Vars{iVar}) = Var;
  end
  clear idxA idxB Var iVar
    
  %create a gridded interpolant of the data fields, interpolate and store
  for iVar=1:1:numel(Settings.Vars)  
    I = griddedInterpolant({Data.longitude, ...
                            Data.latitude,  ...
                            Data.Z,         ...
                            0:3:21}, ...
                           Data.(Settings.Vars{iVar}));
    I = I(a,b,c,d);
    Field = Results.(Settings.Vars{iVar});
    Field(iDay,:,:,:,:) = permute(I,[4,3,1,2]);
    Results.(Settings.Vars{iVar}) = Field;
  end
  clear iVar I Field
                   
  %save every so often
  if mod(iDay,20) == 0;
    save(Settings.OutFile,'Results','Settings');
    disp('Saved!')
  end
  
  
end
clear iDay a b c d

save(Settings.OutFile,'Results','Settings');
disp('Saved!')