/*
 * Rollout version of JSP, selective sampling using FCFS rule
 */

#include "mex.h"
#define infinity    999999999999.0
#define MAX(A, B)    ((A) > (B) ? (A):(B))
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))


/* This function simulates job assignment to the end ... */
double jspRollout(int job, double *mactime, int *maccount, double *jobtime, int *jobcount,
        double *p, double *sigma, double *sTime, double *eTime, double Makespan, int n, int m, int step, double *seq) {
  
  int i, j, mac, slot;
  double slotsize, newslotsize, time, starttime;
  int *J, nj;
  
  J = (int *) mxCalloc(n, sizeof (int));
  
  
  for (i = step; i < (n * m); i++) {
    /* perform look-ahead search */
    if (i > step) { /* the first step is job, after that its random */
      for (j = 0, nj = 0; j < n; j++) {
        if (maccount[j] < m) {
          J[nj++] = j;
        }
      }
      if (nj == 0) mexErrMsgTxt("no feasible move found");
      job = J[rand() % nj]; /* random job assignment */
    }
    if (job < 0)
      mexErrMsgTxt("no feasible job found in lookahead!");
    
    seq[i] = job + 1;
    

    
    mac = (int)sigma[job + n * maccount[job]] - 1; /* get the machine ID for this job */

    if ((mac < 0) || (mac >= m)) {
      mexPrintf("job = %d, mac = %d\n",job, mac);
      mexErrMsgTxt("mac out of range");
    }

    time = p[job + n * mac]; /* the processing time for (job on mac) */
    
    /* find a slot that could be used to assign this job */
    slotsize = infinity + 1.0;
    slot = -1;
    for (j = 0; j <= jobcount[mac]; j++) {
      newslotsize = eTime[mac + m * j] - MAX(sTime[mac + m * j], jobtime[job]);
      if (newslotsize >= time) {
        if (newslotsize < slotsize) {
          slotsize = newslotsize;
          slot = j;
        }
      }
    }
    if (slot < 0){
       mexErrMsgTxt("slot error");
    }

    starttime = MAX(jobtime[job], sTime[mac + m * slot]);
    if (jobcount[mac]<(n-1)) {
      eTime[mac + m*(jobcount[mac]+1)] = eTime[mac + m * slot];
      sTime[mac + m*(jobcount[mac]+1)] = starttime + time;
    }
    eTime[mac + m * slot] = starttime;
    jobtime[job] = starttime + time; /* the time this job will be released */
    mactime[mac] = MAX(mactime[mac], jobtime[job]); /* the new time this machine will be free again */
    if (mactime[mac] > Makespan) Makespan = mactime[mac];
   
    maccount[job] += 1; /* the machine we are up to for job */
    jobcount[mac] += 1; /* the machine we are up to for the job */
  }
  mxFree (J);
  return (Makespan);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int slot, i, j, k, n, m, job, mac, *jobcount, *maccount,nj;
  double *Seq, *tmp_seq, *best_seq, *Makespan, *xTime, *sTime, *eTime, *totaljobtime, *jobtime, *mactime, *p, *sigma, *duedate;
  double time, starttime, lateness, slotsize, newslotsize, tmpV, tmpVV,V,*NrRollout;
  double sumslack = 0.0, operations = 0.0;
  double *tmp_eTime, *tmp_sTime, *tmp_jobtime, *tmp_mactime;
  int *tmp_maccount, *tmp_jobcount;
  
  if (nrhs < 4) mexErrMsgTxt("usage: [makespan,seq,xtime] = jsprollout(p,sigma,duedate,NrRollouts)");
  n = mxGetM(prhs[0]);
  m = mxGetN(prhs[0]);
  p = mxGetPr(prhs[0]);
  sigma = mxGetPr(prhs[1]);
  duedate = mxGetPr(prhs[2]);
  NrRollout = mxGetPr(prhs[3]);
  
  if (n*m != mxGetN(prhs[1])*mxGetM(prhs[1]))
    mexErrMsgTxt("length(p(:)) == length(seq) == length(sigma(:))");
  
  plhs[0] = mxCreateDoubleMatrix(1, 2, mxREAL);
  /*plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);*/
  plhs[1] = mxCreateDoubleMatrix(1, n * m, mxREAL);
  plhs[2] = mxCreateDoubleMatrix(n, m, mxREAL);
  Makespan = mxGetPr(plhs[0]);
  Seq = mxGetPr(plhs[1]);
  xTime = mxGetPr(plhs[2]);
  
  mactime = (double *) mxCalloc(m, sizeof(double));
  maccount = (int *) mxCalloc(n, sizeof(int));
  jobtime = (double *) mxCalloc(n, sizeof(double));
  totaljobtime = (double *) mxCalloc(n, sizeof(double));
  jobcount = (int *) mxCalloc(m, sizeof(int));
  
  tmp_mactime = (double *) mxCalloc(m, sizeof(double));
  tmp_maccount = (int *) mxCalloc(n, sizeof(int));
  tmp_jobtime = (double *) mxCalloc(n, sizeof(double));
  tmp_jobcount = (int *) mxCalloc(m, sizeof(int));
  tmp_sTime = (double *) mxCalloc(n * m, sizeof(double));
  tmp_eTime = (double *) mxCalloc(m * n, sizeof(double));
  tmp_seq = (double *) mxCalloc(m * n, sizeof(double));
  best_seq = (double *) mxCalloc(m * n, sizeof(double));
    
  sTime = (double *) mxCalloc(m * n, sizeof(double));
  eTime = (double *) mxCalloc(m * n, sizeof(double));
  
  for (i=0; i<n*m; i++) {
    sTime[i] = 0.0;
    eTime[i] = 0.0;
  }
  for (i=0; i<m; i++)
    eTime[i] = infinity;
  for (j=0; j<n; j++) {
    totaljobtime[j] = 0.0;
    for (i=0; i<m; i++)
      totaljobtime[j] += p[j + n * i];
  }
  
  Makespan[0] = 0.0;
  V = infinity;
  for (i = 0; i < (n * m); i++) {
    
     nj = 0;
     for (j = 0; j < n; j++) {
        if (maccount[j] < m) {
           nj++;
        }
     }
     
    /* perform look-ahead search */
    job = -1;
    for (j = 0; j < n; j++) {
      if (maccount[j] < m) {
        for (k = 0; k < NrRollout[0]/nj; k++) {
          memcpy(tmp_mactime, mactime, m * sizeof(double));
          memcpy(tmp_maccount, maccount, n * sizeof(int));
          memcpy(tmp_jobtime, jobtime, n * sizeof(double));
          memcpy(tmp_jobcount, jobcount, m * sizeof(int));
          memcpy(tmp_sTime, sTime, n * m * sizeof(double));
          memcpy(tmp_eTime, eTime, m * n * sizeof(double));
          memcpy(tmp_seq, Seq, m * n * sizeof(double));
          tmpV = jspRollout (j, tmp_mactime, tmp_maccount, tmp_jobtime, tmp_jobcount, p, sigma, tmp_sTime, tmp_eTime, Makespan[0], n, m, i,tmp_seq);
          
          if (tmpV < V){
             memcpy(best_seq, tmp_seq, m * n * sizeof(double));
             V = tmpV;
          }
        }
      }
    }
    
    job = (int)best_seq[i]-1;
    
    if (job < 0)
      mexErrMsgTxt("no feasible job found in lookahead!");
    
    /*    job = (int)Seq[i] - 1; */ /* the job to be scheduled */
    Seq[i] = job + 1;
    
    mac = (int)sigma[job + n * maccount[job]] - 1; /* get the machine ID for this job */
    time = p[job + n * mac]; /* the processing time for (job on mac) */
    operations += time;
    
    /* find a slot that could be used to assign this job */
    slotsize = infinity + 1.0;
    slot = -1;
    for (j = 0; j <= jobcount[mac]; j++) {
      newslotsize = eTime[mac + m * j] - MAX(sTime[mac + m * j], jobtime[job]);
      if (newslotsize >= time) {
        if (newslotsize < slotsize) {
          slotsize = newslotsize;
          slot = j;
        }
      }
    }
    if (slot < 0)
       mexErrMsgTxt("slot error");
    
    starttime = MAX(jobtime[job], sTime[mac + m * slot]);
    if (jobcount[mac]<(n-1)) {
      eTime[mac + m*(jobcount[mac]+1)] = eTime[mac + m * slot];
      sTime[mac + m*(jobcount[mac]+1)] = starttime + time;
    }
    eTime[mac + m * slot] = starttime;
    xTime[mac + m * job] = starttime;
    jobtime[job] = starttime + time; /* the time this job will be released */
    mactime[mac] = MAX(mactime[mac], jobtime[job]); /* the new time this machine will be free again */
    if (mactime[mac] > Makespan[0]) Makespan[0] = mactime[mac];
    
    newslotsize = eTime[mac + m*(jobcount[mac]+1)] - sTime[mac + m*(jobcount[mac]+1)];
    if (newslotsize < Makespan[0]) { /* only add slots that are not open ended */
      sumslack += newslotsize;
    }
    if (slotsize < Makespan[0]) { /* this was a finite slot so the slack has been reduced by time */
      sumslack -= time;
    }
    sumslack += (eTime[mac + m * slot] - sTime[mac + m * slot]);
    
    maccount[job] += 1; /* the machine we are up to for job */
    jobcount[mac] += 1; /* the machine we are up to for the job */
  /*  mexPrintf("Maccount:  \n");
    for(j = 0; j < n ; j++)
       mexPrintf(" %d ",maccount[j]);
    
    mexPrintf(" \n \n");
    mexEvalString("drawnow;");*/
    
  }
  Makespan[1] = 0;
  for (job = 0; job < n; job++) {
    lateness = jobtime[job]-duedate[job];
    if (lateness > Makespan[1])
      Makespan[1] = lateness;
  }
  
  mxFree(tmp_mactime);
  mxFree(tmp_maccount);
  mxFree(tmp_jobtime);
  mxFree(tmp_jobcount);
  mxFree(tmp_sTime);
  mxFree(tmp_eTime);
  mxFree(tmp_seq);
  mxFree(best_seq);
  
  mxFree(sTime);
  mxFree(eTime);
  
  mxFree(mactime);
  mxFree(maccount);
  mxFree(jobtime);
  mxFree(totaljobtime);
  mxFree(jobcount);
}
