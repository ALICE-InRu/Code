source('global.R')
source('gantt.R')
subdir='../../Thesis/figures';

problem='j.rnd'
dim='4x5'
tracks=c(sdrs,'OPT')

all.gantt <- do.call(rbind, lapply(tracks, function(sdr){get.gantt(problem,dim,sdr,1)}))
p <- plot.gantt(all.gantt,numericDimension(dim))
ggsave(paste0(subdir,'/example.gantt.SDRs.eps'),plot=p,width=Width,height=Height.full)

gantt=get.gantt(problem,dim,'SPT',1)
p <- plot.gantt(gantt,10,T,T)
ggsave(paste0(subdir,'/example.gantt.eps'),plot=p,width=Width,height=Height.full)

plot.gantt(gantt,0)
plot.gantt(gantt,1)
plot.gantt(gantt,2)

subdir=paste(subdir,'animation',sep='/')
lapply(tracks, function(track){ gif.gantt(problem,dim,track)})
