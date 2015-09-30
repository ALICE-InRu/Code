source('global.R')
source('rollout.R')

input <- list(problems=c('j.rnd','f.rnd'))

CDR.global.6x5=get.CDR.Rollout(input$problems,'6x5')
CDR.global.10x10=get.CDR.Rollout(input$problems[1],'10x10')

CDR.full.6x5 = get.CDR.Rollout.Compare(CDR.global.6x5, '6x5',1)
CDR.full.10x10 = get.CDR.Rollout.Compare(CDR.global.10x10, '10x10',1)

CDR.global=subset(rbind(CDR.global.6x5,CDR.global.10x10),Set=='train')

CDR.global=CDR.fortified(CDR.global)
x=better.CDR(CDR.global,'Track',c('Problem','Dimension','CDR','Track','Bias','Fortified'),set='train','Track')
x[x$BetterTrack!="<SAME>",]

x=better.CDR(CDR.global,'Bias',c('Problem','Dimension','CDR','Track','Bias','Fortified'),set='train','Bias')
x[x$BetterTrack!="<SAME>",]


print(xtable(arrange(stat.Rollout(CDR.global),Dimension,Problem,Track,Bias)),include.rownames=F)

CDR=subset(rbind(CDR.full.6x5,CDR.full.10x10),NrFeat>1&Set=='train')
p=boxplot.rollout(CDR,NULL)
ggsave(paste('../../Thesis/figures/ALL/boxplot.multi.rollout','ALL','pdf',sep='.'),width=Width, height=Height.third*2,dpi=dpi,units=units)

mdat=ddply(CDR,~Problem+Dimension+Fortified+Track+Bias+NrFeat,summarise,mu=median(Rho))
dat=tidyr::spread(mdat,NrFeat,mu)
dat$SDR = dat[,'16']-dat[,'20']
dat$RND = dat[,'20']-dat[,'24']
ddply(dat,~Problem+Dimension,summarise,roll4=round(mean(SDR,na.rm = T),1),roll100=round(mean(RND,na.rm = T),1))

ggplot(mdat,aes(x=NrFeat,y=mu,color=Bias,linetype=Track,shape=Fortified))+
  geom_line()+geom_point(aes(size=Fortified))+scale_size_manual(values=c(1,2))+
  facet_wrap(~Problem+Dimension)





source('pref.trajectories.R'); source('cmaes.R'); source('feat.R')
tracks=c('SPT','CMAESMINCMAX'); #c('LWR','MWR','CMAESMINRHO','CMAESMINCMAX')
CDR.compare.6x5 <- get.CDRTracksRanksComparison(input$problems,'6x5',tracks)
CDR.compare.10x10 <- get.CDRTracksRanksComparison(input$problems[1],'10x10',tracks)
colorPalette='Greys';factor=1.1
p=boxplot.rollout(subset(CDR.full.6x5,Track=='ES.Cmax'&Bias=='adjdbl2nd'),subset(CDR.compare.6x5,SDR!='SPT'))
ggsave(paste('../../Thesis/figures/ALL/boxplot.multi.rollout','6x5','pdf',sep='.'),width=Width*factor, height=Height.third*2*factor,dpi=dpi,units=units)
p=boxplot.rollout(subset(CDR.full.10x10,Track=='ES.Cmax'&Bias=='adjdbl2nd'),subset(CDR.compare.10x10,SDR!='SPT'))
p=p+facet_grid(Problem~Set)+theme(legend.position="none")
ggsave(paste('../../Thesis/figures/j.rnd/boxplot.multi.rollout','10x10','pdf',sep='.'),width=Width*factor, height=Height.third*factor,dpi=dpi,units=units)


CDR.full.6x5 = get.CDR.Rollout.Compare(CDR.global.6x5, '6x5',3)
CDR.full.10x10 = get.CDR.Rollout.Compare(CDR.global.10x10, '10x10',3)

CDR=subset(rbind(CDR.full.6x5,CDR.full.10x10),NrFeat==1&Set=='train'&PID<=500)
SDR=subset(rbind(CDR.compare.6x5,CDR.compare.10x10),SDR=='SPT')
mdat=merge(ddply(CDR,~Problem+Dimension+CDR+Set+Fortified,summarise,mu1=mean(Rho)),ddply(SDR,~Problem+Dimension+SDR+Set,summarise,mu2=mean(Rho)),by=c('Problem','Dimension','Set'))
mdat$Boost=mdat$mu1-mdat$mu2
ddply(mdat,~Problem+Dimension,summarise,mu=round(mean(Boost)))

p=boxplot.rollout(CDR,SDR)+guides(colour=FALSE)
ggsave(paste('../../Thesis/figures/ALL/boxplot.single.rollout','ALL','pdf',sep='.'),width=Width, height=Height.half,dpi=dpi,units=units)
