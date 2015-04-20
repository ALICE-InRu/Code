function [warray,wstruct] = getWeight(problem,dim,track,NrFeat,Model,wname)
if nargin<1, problem='j.rnd'; end
if nargin<2, dim='10x10'; end
if nargin<3, track='OPT'; end
if nargin<4, NrFeat=16; end
if nargin<5, Model=1; end
if nargin<6, wname='full'; end

if(isempty(track)), warray=[]; wstruct=[]; return; end
warray=zeros(1,15);
    
if strcmpi(track,'SPT') % shortest processing time
    warray(6)=-1; %myphi[5] = p[j + n * mac]; /* processing time for job, used by heuristics like SPT and LPT */
elseif strcmpi(track,'LPT') % largest processing time
    warray(6)=+1;%myphi[5] = p[j + n * mac]; /* processing time for job, used by heuristics like SPT and LPT */
elseif strcmpi(track,'MWR') % most work remaining
    warray(5)=+1;%myphi[4] = jobworkremaining[j]; /* MWRM, work remaining for this job */
elseif strcmpi(track,'LWR') % least work remaining
    warray(5)=-1;%myphi[4] = jobworkremaining[j]; /* MWRM, work remaining for this job */
else
    weightType='equal'; rank='p';
    fname=sprintf('../../liblinear/%s/%s.%s.%s.%s.%s.%s.weights.timeindependent.csv',dim,wname,problem,dim,rank,track,weightType);
    
    wstruct=struct();
    fid = fopen(fname,'r'); %# Open the file
    if(fid~=-1), disp(sprintf('Reading %s',fname));
        header=fgetl(fid);
        header=regexp(header, '[_,]', 'split');
        while(1)
            line=fgetl(fid);
            if(line==-1); break; end
            line=regexp(line, '[_,]', 'split');
            if (strcmp(line{1},'Weight'))
                if (str2num(line{2})==NrFeat & str2num(line{3})==Model)
                    field=line{4}; field=field(5:length(field));
                    value=str2num(line{6});
                    wstruct=setfield(wstruct,field,value);
                end
            end
        end
        fclose(fid);
    elseif strcmp(wname,'full')
        wstruct = getWeight(problem,dim,track,NrFeat,Model,'exhaust');
        return
    else
        error(sprintf('%s does not exist',fname));
    end
    
    %%       
    warray(1)=0; % phi[k +  0*n] = job + 1;  /* The job to be dispatched */
    warray(2)=wstruct.mac; % phi[k +  1*n] = mac + 1;     /* Are jobs on the same machine? */
    warray(3)=wstruct.startTime; % phi[k +  2*n] = starttime;   /* start time for this job */
    warray(4)=wstruct.arrivalTime; % phi[k +  3*n] = jobtime[j];  /* arrival time for a job, FIFO, AT, C_{i,j-1} in Haupt88 */
    warray(5)=wstruct.wrmJob; % phi[k +  4*n] = jobworkremaining[j]; /* MWRM, work remaining for this job */
    warray(6)=wstruct.proc; % phi[k +  5*n] = p[j + n * mac]; /* processing time for job, used by heuristics like SPT and LPT */
    warray(7)=wstruct.jobOps; % phi[k +  6*n] = jobcount[j];  /* Greatest/fewest number of jobs remaining assumes number of operation to be the same for all jobs */
    warray(8)=0;%phi(8)=w.wrmTotal; % phi[k +  7*n] = totalwork[j]; /* the greatest total work */
    warray(9)=wstruct.wait; % phi[k +  8*n] = starttime - jobtime[j]; /* the waiting time for this job */
    warray(10)=wstruct.slotReduced; % phi[k +  9*n] = (double)(eTime[slot] < (infinity-1)); /* is the job inserted in an available slot, or attached to the end? */
    warray(11)=wstruct.macfree; % phi[k + 10*n] = MAX(mactime[mac], starttime + p[j + n * mac]); /* new completion time for the machine */
    warray(12)=wstruct.makespan; % phi[k + 11*n] = MAX(Makespan[0],MAX(mactime[mac], starttime + p[j + n * mac])); /* new global makespan */
    warray(13)=wstruct.wrmMac; % phi[k + 12*n] = macworkremaining[mac]; /* This would only make sense when comparing different machines, else anyway zero, total Work In Queue WINQ for machine mac */
    warray(14)=wstruct.slots; % phi[k + 13*n] = starttime - sTime[mac + m * slot]; /* size of slot insert space created */
    warray(15)=wstruct.endTime; % phi[k + 14*n] = starttime + p[j + n * mac]; /* new completion time for this job */    
end
disp(warray); 
end