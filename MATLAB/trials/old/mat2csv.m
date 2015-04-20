function mat2csv(fname,shop,distribution,track,numJobs,numMacs)
load(fname)

header='Shop,Distribution,Track,PID,Step,Dispatch,Followed,ResultingOptMakespan,Simplex';
same=sprintf('%s,%s,%s',shop,distribution,track);

csvname = sprintf('trdat.%s.%s.%dx%d.%s.csv',shop,distribution,numJobs,numMacs,track);

fid = fopen(csvname,'wb');
fprintf(fid,'%s\n',header);
%%
for IDNUM = 1:1%length(DAT),
    count=zeros(1,n);
    dat = DAT(IDNUM).dat;
    optimal = min(dat(:,2));
    for step=1:numJobs*numMacs
        foundopt=false;
        sdat = dat((step==dat(:,1)),:); 
        ready=find(count<numMacs);
        for r=1:size(sdat,1)
            job=ready(r);
            mac=-1;
            starttime=-1;
            optms=sdat(r,2);
            if(~foundopt & optms==optimal) 
                followed=true; foundopt=true; count(job)=count(job)+1;
            else followed=false; end
            info=sprintf('%s,%d,%d,%d.%d.%d,%d,%d,%d',same,IDNUM,step,job,mac,starttime,followed,optms,simplex);
            fprintf(fid,'%s\n',info);
        end
    end
end

%%
end
