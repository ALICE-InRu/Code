source('global.R');source('cmaes.R')
OR.opt <- get.files.OPT(list.files('../../Data/OPT/','ORLIB.test.csv$'))
OR.opt=subset(OR.opt,!is.na(Optimum))
colnames(OR.opt)[grep('Optimum',colnames(OR.opt))]='BKS'

input=list(problem='j.rnd',problems=c('j.rnd','j.rndn','f.rnd','f.rndn','f.jc','f.mc','f.mxc','j.rnd_pj1doubled','j.rnd_p1mdoubled'))

or.vars=c('ORSet','GivenName','Dimension','BKS')
pickBest <- function(dat,cnt=1){
  if(cnt>0){
    best=ddply(subset(dat,!is.nan(Rho)),~Problem+ORSet+GivenName,
               function(x) head(x[x$Rho==min(x$Rho),],cnt))
  } else { best=subset(dat,!is.nan(Rho)) }
  best=join(OR.opt,best,type='right',by = c('Name','Problem','Set','PID','GivenName'))
  return(best)
}

CDR.CMA.orlib <- subset(get.CDR.CMA('j.rnd','10x10',times = F, testProblems = 'ORLIB'),Rho>=0)
CDR.CMA.orlib$ObjFun <- factor(CDR.CMA.orlib$ObjFun,
                               levels=c('min Cmax','min Rho'), labels=c('ES.Cmax','ES.rho'))
CDR.CMA.orlib$CDR='16.1'

files=list.files('../../Data/PREF//CDR/','ORLIB.test.csv',recursive = T)
files=files[grep('j.rnd.10x10',files)]
loc.files=files[grep('Globalweights|SDRweights',files,invert = T)]
glo.files=files[grep('Globalweights|SDRweights',files)]
PREF.local=unique(get.CDR(loc.files,set='ORLIB'))
PREF.global=unique(get.CDR(glo.files,set='ORLIB'))
PREF.global$RhoFort <- factorRho(PREF.global,'BestFoundMakespan')

cma.vars = c('ObjFun','CDR')
ddply(CDR.CMA.orlib,c('Problem',cma.vars),function(x) nrow(x))

pref.vars = c('Track','Bias','CDR')
levels(PREF.local$Supervision)=c('','UNSUP')
PREF.local$Track=interaction(PREF.local$Track,PREF.local$Supervision,sep='')
ddply(PREF.local,c('Problem',pref.vars),function(x) nrow(x))

PREF.global=subset(PREF.global,CDR=='20.1' | Track=='ES.Cmax')
ddply(PREF.global,c('Problem',pref.vars),function(x) nrow(x))

best.CMA <- pickBest(CDR.CMA.orlib)[,c(or.vars,c(cma.vars,'Rho'))]
best.loc16 <- pickBest(subset(PREF.local,CDR=='16.1'))[,c(or.vars,c(pref.vars,'Rho'))]
best.loc3 <- pickBest(subset(PREF.local,CDR!='16.1'))[,c(or.vars,c(pref.vars,'Rho'))]
best.sdr <- pickBest(subset(PREF.global,CDR=='20.1'))[,c(or.vars,c(pref.vars,'RhoFort'))]
best.rnd <- pickBest(subset(PREF.global,CDR=='24.1'))[,c(or.vars,c(pref.vars,'RhoFort'))]

bestGlo=merge(best.sdr,best.rnd,by=or.vars,suffixes = c('SDR','RND'))
bestLoc=merge(best.loc16,best.loc3,by=or.vars,suffixes = c('16','3'))
best=merge(bestLoc,bestGlo,by=or.vars,suffixes = c('Local','Global'))
best=merge(best.CMA,best,by=or.vars,suffixes = c('CMA','PREF'))
head(best)

best$Dimension=stringr::str_replace_all(best$Dimension,'x','&')
best=subset(best,Rho>=0 & Rho3>=0 & Rho16>=0 & RhoFortSDR>=0 & RhoFortRND>=0)

summary(best)
for(col in colnames(best)){
  tmp=best[,col]
  n=length(unique(tmp))
  if(n<=1){
    print(paste('Remove',col))
    best[,col]=NULL
  }
}

colRho=grep('Rho',colnames(best))
best$minRho=matrixStats::rowMins(as.matrix(best[,colRho]))
for(col in colRho){
  isMin=best[,col]==best$minRho
  best[,col]=paste0(ifelse(isMin,'textbf{',''),best[,col],ifelse(isMin,'}',''))
}
best$minRho=NULL
print(xtable(arrange(best,ORSet,GivenName)),include.rownames=F)

PREF.local=pickBest(PREF.local,0)
PREF.global=pickBest(PREF.global,0)
CDR.CMA.orlib=pickBest(CDR.CMA.orlib,0)

all <- rbind(data.frame(Type='PREF',
                        Problem=PREF.global$Problem,
                        GivenName=PREF.global$GivenName,
                        CDR=PREF.global$CDR,
                        Track=PREF.global$Track,
                        Bias=PREF.global$Bias,
                        Model=interaction(PREF.global$Track,PREF.global$Bias),
                        Rho=PREF.global$RhoFort),
             data.frame(Type='PREF',
                        Problem=PREF.local$Problem,
                        GivenName=PREF.local$GivenName,
                        CDR=PREF.local$CDR,
                        Track=PREF.local$Track,
                        Bias=PREF.local$Bias,
                        Model=interaction(PREF.local$Track,PREF.local$Bias),
                        Rho=PREF.local$Rho),
             data.frame(Type='CMA-ES',
                        Problem=CDR.CMA.orlib$Problem,
                        GivenName=CDR.CMA.orlib$GivenName,
                        CDR=CDR.CMA.orlib$CDR,
                        Track=CDR.CMA.orlib$ObjFun,
                        Bias='equal',
                        Model=CDR.CMA.orlib$ObjFun,
                        Rho=CDR.CMA.orlib$Rho))

all=subset(all,GivenName%in%best$GivenName)
all$Problem <- factorProblem(all,F)
all$CDR<-factor(all$CDR,levels=sort(as.numeric(levels(all$CDR))))

if(F){
  p=ggplot(all,aes(x=CDR,y=Rho))+
    geom_boxplot(data=subset(all,Type=='PREF'),aes(color=Track,linetype=Bias))+
    geom_boxplot(data=subset(all,Type=='CMA-ES'),aes(color=Model))+
    scale_linetype_manual(values=c(2,1))+
    ggplotColor('Policy',length(levels(all$Track)))+themeBoxplot+ylab(bksLabel)+
    guides(color=guide_legend(nrow=2,byrow=TRUE),
           linetype=guide_legend(nrow=2,byrow=TRUE))+
    facet_grid(Problem~Type,scales='free',space = 'free')
  ggsave('tmp.png',width = Width,height = Height.half,dpi=dpi,units=units)
}

all <- ddply(all,~GivenName,mutate,minRho=min(Rho))
mdat=ddply(all,~Problem+Type+CDR+Model,summarise,N=sum(Rho>=0),
           BKS=round(100*mean(Rho==0),2),
           best_pct=round(100*mean(Rho==minRho),2),
           pct1=round(100*mean(Rho<=minRho+1),2),
           pct5=round(100*mean(Rho<=minRho+5),2),
           pct10=round(100*mean(Rho<=minRho+10),2))
print(xtable(mdat),include.rownames=F)

mdat=ddply(all,~Problem+Type+CDR+Model,summarise,N=sum(Rho>=0),
           BKS=sum(Rho==0),
           best_pct=sum(Rho==minRho))
