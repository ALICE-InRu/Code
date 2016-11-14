res <- dbSendQuery(conCHESHIRE, "
                   select dd.name, case when dd.d=30 then '6x5' else '10x10' end as dim, sdr.SDR, t.id
                   from trdat_phi_def t
                   inner join data_distributions dd on dd.id = t.ddID
                   inner join models m on m.id = t.mID
                   inner join models_SDR sdr on sdr.id = m.sdrID
                   order by t.id ")
info <- fetch(res, n = -1);

for(i in info$id){
  problem = subset(info,i==id)$name
  dim = subset(info,i==id)$dim
  SDR = subset(info,i==id)$SDR
  myID = subset(info,i==id)$id
  file = paste('C:/Users/helga/Documents/GitHub/Cheshire/Data/Training/trdat',problem,dim,SDR,'Global.csv',sep='.')
  if(file.exists(file)){

    trdat <- read_csv(file)
    res <- dbSendQuery(conCHESHIRE, paste("select * from trdat_phi_values where id =",phiID))
    tbl <- fetch(res, n = -1); tbl <- subset(tbl, phiID==myID)
    tbl[1:nrow(trdat),] = NA
    tbl$phiID = myID
    tbl$pID = trdat$PID
    tbl$step = trdat$Step
    tbl$followed = trdat$Followed

    m=regexpr('(?<Job>[0-9]+).(?<Mac>[0-9]+).(?<Time>[0-9]+)',trdat$Dispatch,perl=T)
    tbl$dispatch_job=getAttribute(trdat$Dispatch,m,'Job',F)
    tbl$dispatch_mac=getAttribute(trdat$Dispatch,m,'Mac',F)
    tbl$dispatch_time=getAttribute(trdat$Dispatch,m,'Time',F)

    tbl$resulting_opt_makespan=trdat$ResultingOptMakespan
    tbl$rank=trdat$Rank
    tbl$phi_proc=trdat$phi.proc
    tbl$phi_startTime=trdat$phi.startTime
    tbl$phi_endTime=trdat$phi.endTime
    tbl$phi_arrival=trdat$phi.arrival
    tbl$phi_wait=trdat$phi.wait
    tbl$phi_macFree=trdat$phi.macFree
    tbl$phi_makespan=trdat$phi.makespan
    tbl$phi_reducedSlack=trdat$phi.reducedSlack
    tbl$phi_macSlack=trdat$phi.macSlack
    tbl$phi_allSlack=trdat$phi.allSlack
    tbl$phi_jobOps=trdat$phi.jobOps
    tbl$phi_macOps=trdat$phi.macOps
    tbl$phi_jobWrm=trdat$phi.jobWrm
    tbl$phi_macWrm=trdat$phi.macWrm
    tbl$phi_jobTotProcTime=trdat$phi.jobTotProcTime
    tbl$phi_macTotProcTime=trdat$phi.macTotProcTime
    tbl$xi_step=trdat$xi.step
    tbl$xi_totProcTime=trdat$xi.totProcTime
    tbl$xi_totWrm=trdat$xi.totWrm

    dbWriteTable(conCHESHIRE, "trdat_phi_values", value=tbl, overwrite=FALSE, append=TRUE, row.names=FALSE)
    file.remove(file)
  }
}

