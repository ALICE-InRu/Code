function [training,validation,testing,feature_names,NrTrain]=csv2mat(distr,dim,track,type,rank,useDiff,NrTrain,onlyFollowed)
%% [training,testing,feature_names,NrTrain] = csv2mat(distr,dim,track,type,rank,useDiff,NrTrain,onlyFollowed)
% Track either 'OPT','MWR','LWR','SPT','LPT','RND','ALL'
% Type either 'Local' or 'Global'
% Rank either 'b', 'f' or 'p'
if nargin<3, track='OPT'; end
if nargin<4, type='Local'; end
if nargin<5, rank='p'; end
if nargin<6, useDiff = 1; end 
if nargin<7, if strcmp(dim,'10x10'), NrTrain=300; else NrTrain=500; end; end
if nargin<8, onlyFollowed=0; end

%%
if(useDiff)
    name=sprintf('%s.%s.%s.%s.diff.%s',distr,dim,track,type,rank);
else 
    name=sprintf('%s.%s.%s.%s',distr,dim,track,type);
end
fname=sprintf('../../trainingData/trdat.%s.csv',name);

fid=fopen(fname,'r');
if(fid~=-1), disp(sprintf('Reading %s',fname));
    header=fgetl(fid);
    fclose(fid);
    header=regexp(header, '[_,]', 'split');    
    fcols=find(strncmp(header,'phi.',4)>0);
    lcols=find(strcmp(header,'ResultingOptMakespan')>0);
    pcol=find(strcmp(header,'PID')>0);
    feature_names=header(fcols);
    
    %%
    allDat=dlmread(fname,',',1,0);
    %%
    PID_label=allDat(:,pcol);
    instance_matrix=allDat(:,fcols);
    label_vector=allDat(:,lcols);
else
    error(sprintf('%s does not exist',fname));
    instance_matrix=[];
    label_vector=[];
    feature_names=[];
end
%%
if(onlyFollowed)
    followed=find(allDat(:,find(strcmp(header,'Followed')))>0);
    instance_matrix=instance_matrix(followed,:);
    label_vector=label_vector(followed);
    PID_label=PID_label(followed);
end
%%
addpath ../common/
[instance_matrix,feature_names]=formatTrainingData(instance_matrix,feature_names);
problems=getproblem(['../../rawData/' distr '.' dim '.train.txt']);
[NrJobs,NrMacs]=size(problems(1).p);
tname=sprintf('../trainingData/%s.%s.train.OPT.tpr.mat',distr,dim);
if(exist(tname,'file'))
    tr=load(tname);
else
    tr=struct('DAT',[]);
end

%%
testidx=PID_label>NrTrain;
NrVal=round(prctile(unique(PID_label(~testidx)),80));
validx=PID_label<=NrVal;
tridx=PID_label(~testidx)>NrVal;

training=struct('instance_matrix',sparse(instance_matrix(tridx,:)),...
    'label_vector',sign(label_vector(tridx)),...
    'weight_vector',label_vector(tridx),...
    'PID_label',PID_label(tridx),...
    'problems',problems(1:NrVal),...
    'opt_track',tr.DAT(1:NrVal),...
    'NumInstances',NrVal,...
    'NrJobs',NrJobs,'NrMacs',NrMacs,...
    'Name',[name '.train']);

validation=struct('instance_matrix',sparse(instance_matrix(validx,:)),...
    'label_vector',sign(label_vector(validx)),...
    'weight_vector',label_vector(validx),...
    'PID_label',PID_label(validx),...
    'problems',problems((NrVal+1):NrTrain),...
    'opt_track',tr.DAT((NrVal+1):NrTrain),...
    'NumInstances',NrTrain-NrVal,...
    'NrJobs',NrJobs,'NrMacs',NrMacs,...
    'Name',[name '.validation']);

if any(testidx)
    testing=struct('instance_matrix',sparse(instance_matrix(testidx,:)),...
        'label_vector',sign(label_vector(testidx)),...
        'weight_vector',label_vector(testidx),...
        'PID_label',PID_label(testidx),...
        'problems',problems((NrTrain+1):end),...
        'opt_track',tr.DAT((NrTrain+1):end),...
        'NumInstances',max(PID_label)-NrTrain,...
        'NrJobs',NrJobs,'NrMacs',NrMacs,...
        'Name',[name '.test']);
else
    testing=[];
end
end

function [dat,feature_names]= formatTrainingData(dat,feature_names)
if size(dat,2)~=length(feature_names)
    save debug
    error('dat and feature_names dimension do not match. Check debug.mat')
end

info=featureInfo();
[tmp,ia1,ib1]=intersect(info.features,feature_names);
if(length(tmp)~=info.nr_features)
    save debug
    error('Feature names do not match. Check debug.mat')
end

[~,ia2]=sort(ia1);
order=ib1(ia2);

feature_names=feature_names(order);
dat=dat(:,order);

%disp([info.features;feature_names])

end
