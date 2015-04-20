function PREFS = getLiblinearModelsFromR(distribution,dimension,rank,track,scaledModel,weightType)
addpath ../common/
[training,actualFeatures]=featureInfo();

if(scaledModel) scaledModel='.sc'; else scaledModel=''; end;
weightFile = sprintf('../../liblinear/%s/exhaust%s.%s.%s.%s.%s.%s.weights.timeindependent.csv',dimension,scaledModel,distribution,dimension,rank,track,weightType)
fid = fopen(weightFile);
if (-1==fid), error(sprintf('could not find file %s',weightFile)); end
%%
patWeight = 'Weight,(?<NrFeat>\d+),(?<Model>\d+),(?<Feature>phi.[a-zA-Z]+),NA,(?<value>[-]?[0-9.]*)';
patAccVal = '^Validation.Accuracy';
patAccTra = '^Training.Accuracy';
nr_models=0;
PREF = {};
featFound=0;
%%
while 1
    %%
    tline = fgetl(fid);
    if ~ischar(tline), break, end
    if regexp(tline,patAccTra)
    elseif regexp(tline,patAccVal)
    elseif regexp(tline,patWeight)
        %%
        m=regexp(tline,patWeight ,'names');
        nrFeat=str2num(m.NrFeat);
        model=str2num(m.Model);
        feature=m.Feature;
        value=str2num(m.value);
        %%
        if(featFound==0)
            pref=struct('w',zeros(1,training.nr_features),...
                'NrFeat',nrFeat, 'NrModel',model);
        end
        %%
        featFound=featFound+1;
        for f=1:training.nr_features
            if strcmp(feature,training.features(f))
                pref.w(f)=value;
            end
        end
        %%
        if(featFound==nrFeat)        
            nr_models=nr_models+1;
            PREF{nr_models}=pref;
            featFound=0;
            if(length(find(pref.w~=0))>nrFeat)
                error('Error! Should not be more weights active than number of features');
            end
            pref=[];
        end
        %%
    else
        disp(tline);
        pause(0.1)
    end
end
fclose(fid);
%%
PREFS=struct('Model',[],'nr_models',nr_models,'weightFile',weightFile);
PREFS.Model=PREF;

end