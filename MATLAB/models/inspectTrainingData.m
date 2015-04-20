function inspectTrainingData(distr,dim, saveCSV, showPlots)
if(nargin<3) saveCSV=0; end
if(nargin<4) showPlots=~saveCSV; end
%close all
useDiff=true;
data=csv2mat(distr,dim,'OPT','Local','p',useDiff,500);
%%
global Dimension NumInstances
Dimension=data.NrJobs*data.NrMacs;
NumInstances=data.NumInstances;
Main{NumInstances}=[];
SDR{NumInstances}=[];
Extremal{NumInstances}=[];
%%
for PID = 1:NumInstances, disp(PID)
    %% For each instance
    if isempty(data.opt_track(PID).dat)
        warning(sprintf('#%d missing',PID));
    else
        [Main{PID},SDR{PID},Extremal{PID}]=loopInstance(data.opt_track(PID),data.NrJobs,data.NrMacs,1,1,1);
    end
end

%% Prepare for figures
if showPlots
    RHOw=zeros(NumInstances,Dimension);
    RHOb=zeros(NumInstances,Dimension);
    RND_IS_OPTIMAL=zeros(NumInstances,Dimension);
    SPT_IS_OPTIMAL=zeros(NumInstances,Dimension);
    MWR_IS_OPTIMAL=zeros(NumInstances,Dimension);
    OPT_IS_UNIQUE=zeros(NumInstances,Dimension);
    nrFeat=size(Extremal{1}.IS_OPTIMAL_MAX,1);
    for feat=1:nrFeat
        FEATURE_IS_OPTIMAL_MIN{feat}=zeros(NumInstances,Dimension);
        FEATURE_IS_OPTIMAL_MAX{feat}=zeros(NumInstances,Dimension);
    end
    
    for PID=1:NumInstances
        RHOw(PID,1:Dimension)=Main{PID}.RHOw;
        RHOb(PID,1:Dimension)=Main{PID}.RHOb;
        RND_IS_OPTIMAL(PID,1:Dimension)=Main{PID}.RND_IS_OPTIMAL;
        OPT_IS_UNIQUE(PID,1:Dimension)=Main{PID}.OPT_IS_UNIQUE;
        SPT_IS_OPTIMAL(PID,1:Dimension)=SDR{PID}.SPT_IS_OPTIMAL;
        MWR_IS_OPTIMAL(PID,1:Dimension)=SDR{PID}.MWR_IS_OPTIMAL;
        for feat=1:nrFeat
            for step=1:Dimension
                FEATURE_IS_OPTIMAL_MIN{feat}(PID,step)=Extremal{PID}.IS_OPTIMAL_MIN(feat,step);
                FEATURE_IS_OPTIMAL_MAX{feat}(PID,step)=Extremal{PID}.IS_OPTIMAL_MAX(feat,step);
            end
        end
    end
    %% Decision accuracy
    figure,
    plot(1:Dimension,mean(RND_IS_OPTIMAL),'k');
    legends={'RND'}; hold on
    plot(1:Dimension,mean(MWR_IS_OPTIMAL),'r-',1:Dimension,mean(SPT_IS_OPTIMAL),'g-')
    legends=[legends 'MWR' 'SPT'];
    plot(1:Dimension,mean(OPT_IS_UNIQUE)/data.NrJobs,'k:')
    legends=[legends 'unique'];
    
    xlabel('decision step');
    ylabel('decision accuracy on optimal trajectory');
    
    legend(legends,'Location','best')
    title(distr)
    
    shg
    % print(gcf, '-depsc', ['plots/decisionAcc.' distr '.' dim '.eps'])
    
    %% All features w.r.t. mininum/maximum value
    figure,
    plot(1:Dimension,mean(RND_IS_OPTIMAL),'k','LineWidth',2);
    hold on
    for i=1:nrFeat
        plot(1:Dimension,mean(FEATURE_IS_OPTIMAL_MIN{i}),'r')
        plot(1:Dimension,mean(FEATURE_IS_OPTIMAL_MAX{i}),'b')
    end
    xlabel('decision step');
    ylabel('decision accuracy on optimal trajectory');
    legend({'RND' 'min' 'max'},'Location','NorthEastOutSide')
    title(distr)
    % print(gcf, '-depsc', sprintf('plots/decisionAcc.%s.%s.Full.eps',distr,dim));
    
    %% Best case vs. worst case scenario
    figure
    plot(1:Dimension,mean(RHOw)*100,'r-',1:Dimension,mean(RHOb)*100,'b-')
    xlabel('decision step');
    ylabel('(suboptimal-optimal)/optimal \times 100 %');
    legend('Worst Case','Best Case','Location','best')
    title(distr)
    % print(gcf, '-depsc', ['plots/bestworst.' distr '.' dim '.eps'])
end

if saveCSV          
    csvname=sprintf('csv/optimality.%s',data.Name);
    saveExtremal(Extremal,sprintf('%s.extremal.csv',csvname));
    saveCaseScenario(Main,sprintf('%s.casescenario.csv',csvname));
    saveRndUnique(Main,sprintf('%s.csv',csvname));
else
    save debug
end
end

function [featureOrder,features]= getFeatureOrder
addpath ../common/
info = featureInfo();
features=info.features;

featName = {'phi.proc', 'phi.startTime', 'phi.endTime' , 'phi.wrmJob', 'phi.wait', 'phi.arrivalTime', 'phi.jobOps' , ...
    'phi.mac', 'phi.macfree' , 'phi.wrmMac', 'phi.macOps', ...
    'phi.slotReduced', 'phi.slots', 'phi.slotsTotal', ...
    'phi.makespan', 'phi.wrmTotal', 'phi.step'};

featureOrder = [];
for name = featName
    featureOrder=[featureOrder find(strcmp(name,features))];
end

end

function saveExtremal(Extremal,fname)
global Dimension NumInstances

[featureOrder,features]=getFeatureOrder();  

fid = fopen(fname,'w'); %# Open the file
if fid ~= -1
    fprintf(fid,'Objective,Step%s\r\n',sprintf(',%s',features{featureOrder}));  %# Print the header
    for Step=1:Dimension
        for PID=1:NumInstances
            if ~isempty(Extremal{PID})
                tmpMin =sprintf('min,%d',Step);
                tmpMax =sprintf('max,%d',Step);
                
                for i=featureOrder
                    tmpMin = sprintf('%s,%d', tmpMin, Extremal{PID}.IS_OPTIMAL_MIN(i,Step));
                    tmpMax = sprintf('%s,%d', tmpMax, Extremal{PID}.IS_OPTIMAL_MAX(i,Step));
                end
                fprintf(fid,sprintf('%s\r\n',tmpMin));
                fprintf(fid,sprintf('%s\r\n',tmpMax));
            end
        end
    end
    fclose(fid); %# Close the file
end
end

function saveCaseScenario(Main,fname)
global Dimension NumInstances
fid = fopen(fname,'w'); %# Open the file
if fid ~= -1
    fprintf(fid,'Step,objective,rho\r\n');
    for Step=1:Dimension
        for PID=1:NumInstances
            if ~isempty(Main{PID})
                fprintf(fid,sprintf('%d,best,%.3f\r\n',Step,Main{PID}.RHOb(Step)));
                fprintf(fid,sprintf('%d,worst,%.3f\r\n',Step,Main{PID}.RHOw(Step)));
            end
        end
    end
    fclose(fid); %# Close the file
end
end

function saveRndUnique(Main,fname)
global Dimension NumInstances
%%
fid = fopen(fname,'w'); %# Open the file
if fid ~= -1
    fprintf(fid,'Step,rnd,unique\r\n');
    for Step=1:Dimension
        for PID=1:NumInstances
            if ~isempty(Main{PID})
            fprintf(fid,sprintf('%d,%.3f,%.3f\r\n',Step,...
                Main{PID}.RND_IS_OPTIMAL(Step),...
                Main{PID}.OPT_IS_UNIQUE(Step)));
            end
        end
    end
    fclose(fid); %# Close the file
end
end

