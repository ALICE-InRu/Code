clear all, clc;
spaces={'j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc'};
dims={'6x5','10x10','14x14'};
addpath ../
Set='train';
%%
for s=1:length(spaces)
    distr=spaces{s};
    for d=1:length(dims)
        dim=dims{d};
        problems  = getproblem(sprintf('../../rawData/%s.%s.%s.txt',distr,dim,Set));
        fName=sprintf('procs.%s.%s.csv',distr,dim);
        %%
        fid = fopen(fName,'w');            %# Open the file
        if fid ~= -1
            p=problems(1).p; sigma=problems(1).sigma;
            NumMacs=size(p,2);
            NumJobs=size(p,1);
            header=sprintf('Problem,Dimension,PID,Set,%s%ssum,mean,sd',sprintf('J%d,',1:NumJobs),sprintf('M%d,',1:NumMacs));
            fprintf(fid,'%s\r\n',header);    %# Print the header
                        
            for PID=1:length(problems)
                p=problems(PID).p; sigma=problems(PID).sigma;
                pTotalJob=sort(sum(p,2))';
                pTotalMac=sort(sum(p,1));
                pTotal=sum(pTotalMac);
                m=mean(p(:));
                sd=std(p(:));
                fprintf(fid,'%s,%s,%d,%s,%s%d,%.2f,%.2f\r\n',distr,dim,PID,Set,sprintf('%d,',pTotalJob,pTotalMac),pTotal,m,sd);
            end
        end
        fclose(fid);                     %# Close the file        
    end    
end