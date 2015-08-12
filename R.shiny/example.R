source('global.R')
source('gantt.R')
subdir='../../Thesis/figures';

tracks=c(sdrs,'OPT')
all.gantt <- do.call(rbind, lapply(tracks, function(sdr){get.gantt('j.rnd','4x5',sdr,1)}))
p <- plot.gantt(all.gantt,20)
ggsave(paste0(subdir,'/example.gantt.SDRs.eps'),plot=p,width=Width,height=Height.full)

gantt=get.gantt('j.rnd','4x5','SPT',1)
for(k in 0:20){
  print(plot.gantt(gantt,k,T)+ggtitle(paste0('Step k=',k)))
  Sys.sleep(2)
}

lapply(tracks, function(x){ gif.gantt('j.rnd','4x5',track,1)})
