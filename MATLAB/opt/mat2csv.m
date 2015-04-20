function mat2csv(distribution)
if nargin<1, distribution='j.rnd'; end
%%
files=dir(sprintf('opt.%s.*.mat',distribution));
Shop=distribution(1);
Distribution=distribution(3:end);
fopt=sprintf('opt.%s.csv',distribution);
if exist(fopt,'file'), delete(fopt); end % start from scratch
%%
for F=1:length(files)
    fname=sprintf(files(F).name);
    Set = regexp(fname, '(?<train>train)|(?<test>test)', 'match');
    n = regexp(fname, '(?<NumJobs>\d+)x(?<NumMacs>\d+)', 'names');    
    innerMat2csv(fopt,fname,Shop,Distribution,str2num(n.NumJobs),str2num(n.NumMacs),Set{1});
end

end
function innerMat2csv(fopt,fname,Shop,Distribution,NumJobs,NumMacs,Set)
%%
load(fname,'DAT')
Dimension=NumJobs*NumMacs;
DimStr=sprintf('%dx%d',NumJobs,NumMacs);
%%
if(~exist(fopt,'file'))
    fid = fopen(fopt,'w');            %# Open the file
    if fid~=-1
        header=sprintf('%s,','Name','Shop','Distribution','Set','PID','NumJobs','NumMachines','Dimension','Makespan','Solved','Solver','Simplex');
        header=header(1:end-1); % remove last comma
        fprintf(fid,'%s\r\n',header); %# Print the header
    end
else
    fid = fopen(fopt,'a');            %# Open the file
end
%%
if fid ~= -1
    disp(fname)
    for PID=1:length(DAT), %PID        
        Name=sprintf('%s.%s.%s.%s.%d',Shop,Distribution,DimStr,Set,PID);
        if ~isempty(DAT(PID)) && ~isempty(DAT(PID).result)
            Makespan=DAT(PID).makespan;
            Solved=DAT(PID).solved;
            Simplex=DAT(PID).result.itercount;
            fprintf(fid,'%s,%s,%s,%s,%d,%d,%d,%d,%d,%s,Gurobi,%d\r\n',Name,Shop,Distribution,Set,PID,NumJobs,NumMacs,Dimension,Makespan,Solved,Simplex);
        else
            disp(sprintf('%s is empty',Name));
        end
    end
    fclose(fid);                     %# Close the file
    
end
end