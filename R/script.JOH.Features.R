source('startUp.R')

mainPalette='Set1'
extension='pdf'; 
dpi=300; 
redoPlot=F;
subdir='../../Papers/JOH.Features/figures/';

# ----- Box plots for SDRs -----------------------------------------

SDR=SDR[!(SDR$Dimension == '8x8' & SDR$Set=='train'),]
SDR=SDR[!(SDR$Dimension == '12x12' & SDR$Set=='train'),]
SDR=SDR[!(SDR$Dimension == '14x14' & SDR$Set=='train'),]
SDR=subset(SDR, Problem %in% problems.10x10)

source('difficultywrtSDR.R'); 
boxplotSDRs(SDR,'10x10')

# ----- Box plots for BDR ------------------------------------------
source('inspectBDR.R')
p=checkBDR(OPT,SDR,'SPT','MWR',40)
p = p + ggplotFill('Dispatching rule',3,c('SPT (first 40%), MWR (last 60%)','Most Work Remaining','Shortest Processing Time'))
fname=paste(subdir,'boxplotRho.BDR.10x10.pdf',sep='')
ggsave(fname,width=Width,height=Height.half,dpi=dpi,units=units)

# ----- Exhaustive search for feature selection --------------------
subdir='../../Papers/JOH.Features/figures/exhaust';
source('liblinear.R')

info.equal=plotLiblinearModels(problems.10x10,'10x10','p','equal',F)
liblinearXtable(info.equal)
best.equal=liblinearComparedToOptimal(info.equal,'10x10'); print(best.equal)
best.liblinearBoxplot(best.equal,info.equal$Probability,SDR=SDR)
ks.j.rnd.equal=liblinearKolmogorov(info.equal,'j.rnd',onlyPareto = F,SDR=NULL)
ks.j.rndn.equal=liblinearKolmogorov(info.equal,'j.rndn',onlyPareto = F,SDR=NULL)
ks.f.rnd.equal=liblinearKolmogorov(info.equal,'f.rnd',onlyPareto = F,SDR=NULL)
#i='16.1'; dat=ks.j.rnd.equal$Acc; tmp=dat[i,]>1-0.05; length(tmp);ncol(dat); colnames(dat)[tmp]

info.all=plotLiblinearModels(problems.10x10,'10x10','p',c('equal','bcs','wcs','opt','dbl1st','dbl2nd'),F)
liblinearXtable(info.all,T)
best.all=liblinearComparedToOptimal(info.all,'10x10'); print(best.all)
best.liblinearBoxplot(best.all,info.all$Probability)
ks.j.rnd.all=liblinearKolmogorov(info.all,'j.rnd',onlyPareto = T)
ks.j.rndn.all=liblinearKolmogorov(info.all,'j.rndn',onlyPareto = T)
ks.f.rnd.all=liblinearKolmogorov(info.all,'f.rnd',onlyPareto = T)


stat=ddply(info.all$Liblinear.Summary,~Problem+NrFeat+Model,summarise,min.Rho=min(Validation.Rho),max.Rho=max(Validation.Rho),diff.rho=max.Rho-min.Rho,min.Acc=min(Validation.Accuracy.Optimality),max.Acc=max(Validation.Accuracy.Optimality),diff.acc=max.Acc-min.Acc)
summary(stat)

stat=ddply(info.all$Liblinear.Summary,~Problem+NrFeat+Model,mutate,min.Rho=min(Validation.Rho),max.Rho=max(Validation.Rho),diff.rho=max.Rho-min.Rho,min.Acc=min(Validation.Accuracy.Optimality),max.Acc=max(Validation.Accuracy.Optimality),diff.acc=max.Acc-min.Acc)

stat.r=subset(stat,diff.rho>0)
stat.a=subset(stat,diff.acc>0)

stat=NULL
stat$min.Rho=summary(ddply(stat.r,~Problem+NrFeat+Model,summarise,min.Rho=Prob[Validation.Rho==min.Rho])$min.Rho)
stat$max.Rho=summary(ddply(stat.r,~Problem+NrFeat+Model,summarise,max.Rho=Prob[Validation.Rho==max.Rho])$max.Rho)
stat$min.Acc=summary(ddply(stat.a,~Problem+NrFeat+Model,summarise,min.Acc=Prob[Validation.Accuracy.Optimality==min.Acc])$min.Acc)
stat$max.Acc=summary(ddply(stat.a,~Problem+NrFeat+Model,summarise,max.Acc=Prob[Validation.Accuracy.Optimality==max.Acc])$max.Acc)