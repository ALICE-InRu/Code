function [reducedModel,fullModel,featuresInUse]=readReducedPrefModel(distr,NrFeat,Model,dim,track,type,rank,training,testing,allFeatures)
onlyFollowed=false;
useDiff=true;
scaled=false;
if(nargin<1) distr='j.rnd'; end
if(nargin<2) Model=549; end
if(nargin<3) NrFeat=3; end
if(nargin<4) dim='10x10'; end
if(nargin<5) track='OPT'; end
if(nargin<6) type='Local'; end
if(nargin<7) rank='p'; end
if(nargin<10)
    [training,testing,allFeatures]=csv2mat(distr,dim,track,type,onlyFollowed,rank,useDiff);
end

%%
fname=sprintf('../../liblinear/%s.%s/exhaust.',dim,rank);
if(scaled) fname=[fname 'sc.']; end
fname=[fname sprintf('%s.equal.weights',distr)];
if ~exist(fname,'file')
   error(sprintf('%s does not exist, cannot go forward',fname));
end
%%
readModel=[];
fid=fopen(fname,'r');
if(fid~=-1), disp(sprintf('Reading %s',fname));
    nrFeat=-1;model=-1;
    while(true)        
        line=fgetl(fid);
        if(line==-1) break; end
        m=regexp(line,'Linear weights based on #(\d+) features','tokens');
        if(~isempty(m))            
            nrFeat=str2num(m{1}{1});                        
        end       
        if NrFeat==nrFeat
            m=regexp(line,'Model #(\d+) with validation:\d+.\d+% training:\d+.\d+%','tokens');
            if(~isempty(m))
                model=str2num(m{1}{1});
            end
        end
        
        if(NrFeat==nrFeat & Model==model)
            m=regexp(line,'(phi.\w+) ([\-.0-9]+)','tokens');
            if(~isempty(m))
                readModel=[readModel;m{1}];
            end
            if(size(readModel)==NrFeat)
                break;
            end
        end
    end
end
if(size(readModel)~=NrFeat)
    error(sprintf('Couldnt read model %d.%d',NrFeat,Model));
end
%%
for i=1:NrFeat
    activeFeatures{i}=readModel{i};  
    weights(i)=str2double(readModel{NrFeat+i});
    featuresInUse(i)=find(strcmp(readModel{i},allFeatures));
end

%% Benchmark model, using all features
fullModel = train2(training);
fullModel.testing_accuracy = predict2(testing,fullModel);

%% Reduced model
reducedModel = train2(training,featuresInUse);
reducedModel.testing_accuracy = predict2(testing,reducedModel);
% sanity check
% disp(readModel');
% disp(reducedModel.w(featuresInUse));