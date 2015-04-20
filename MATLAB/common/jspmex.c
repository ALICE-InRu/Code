/*
 * JSP scheduling using most work remaining dispatching heuristic
 */

#include "mex.h"
#define infinity    999999999999.0
#define MAX(A, B)    ((A) > (B) ? (A):(B))
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))


/* return the smallest feasible available idle machine slot */
int findslot(int job, int mac, double time, int *jobcount, double *jobtime, double *sTime, double *eTime, int n, int m)
{
  int j;
  int slot = -1;
  double newslotsize, slotsize = infinity + 1.0;
  
  for (j = 0; j <= jobcount[mac]; j++) {
    /* the endtime of the slot minus the time the job is released or when the slot starts which ever is later */
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
  return (slot);
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  int slot, i, j, k, n, m, job, optjob, mac, *jobcount, *maccount;
  double *Makespan, *xTime, *sTime, *eTime, *workremaining, *jobtime, *mactime, *p, *sigma;
  double *xpath = NULL, *seq;
  int usepath = 0;
  double time, starttime, slotsize, newslotsize, maxvalue, minvalue;
  double sumslack = 0.0, operations = 0.0;
  
  if (nrhs < 2) mexErrMsgTxt("usage: [makespan,xtime,stime,etime] = jspmex(p,sigma,SolnTime)");
  
  n = mxGetM(prhs[0]);
  m = mxGetN(prhs[0]);
  p = mxGetPr(prhs[0]);
  sigma = mxGetPr(prhs[1]);
  if (nrhs == 3) {
    xpath = mxGetPr(prhs[2]);
    usepath = 1;
  }
  
  if (n*m != mxGetN(prhs[1])*mxGetM(prhs[1]))
    mexErrMsgTxt("length(p(:)) == length(seq) == length(sigma(:))");
  
  /* Allocate memory and assign pointers */
  plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
  plhs[1] = mxCreateDoubleMatrix(n, m, mxREAL);
  plhs[4] = mxCreateDoubleMatrix(1, n*m, mxREAL);
  plhs[2] = mxCreateDoubleMatrix(m, n, mxREAL);
  plhs[3] = mxCreateDoubleMatrix(m, n, mxREAL);
  
  Makespan = mxGetPr(plhs[0]);
  xTime = mxGetPr(plhs[1]);
  seq = mxGetPr(plhs[4]);
  
  mactime = (double *) mxCalloc(m, sizeof(double));
  maccount = (int *) mxCalloc(n, sizeof(int));
  jobtime = (double *) mxCalloc(n, sizeof(double));
  jobcount = (int *) mxCalloc(m, sizeof(int));
  workremaining = (double *) mxCalloc(n, sizeof(double));
  
  sTime = mxGetPr(plhs[2]); /*(double *) mxCalloc(m * n, sizeof(double));*/
  eTime = mxGetPr(plhs[3]); /*(double *) mxCalloc(m * n, sizeof(double));*/
  
  /* initialize variables */
  for (i=0; i<n*m; i++) {
    sTime[i] = 0.0; /* note: not needed when using Calloc */
    eTime[i] = 0.0;
  }
  for (i=0; i<m; i++)
    eTime[i] = infinity;
  for (j=0; j<n; j++) {
    workremaining[j] = 0.0;
    for (i=0; i<m; i++)
      workremaining[j] += p[j + n * i];
  }
  Makespan[0] = 0.0;
  /* build schedule based on heuristic rule */
  for (i = 0; i < (n * m); i++) {
    /* perform look-ahead search for each legal dispatch */
    job = -1;
    optjob = -1;
    maxvalue = 0.0;
    minvalue = infinity+10;
    for (j = 0; j < n; j++) {
      if (maccount[j] < m) {
        /* legal move is j and value is = heuristic();*/
        
        if (xpath[j + ((int)sigma[j + n * maccount[j]] - 1) * n] < minvalue) {
          minvalue = xpath[j + ((int)sigma[j + n * maccount[j]] - 1) * n];
          optjob = j;
        }
        
        if (workremaining[j] > maxvalue) {
          maxvalue = workremaining[j];
          job = j;
        }
      }
    }
    seq[i] = (optjob==job);
    job = optjob;
    if (job < 0)
      mexErrMsgTxt("no feasible job found in lookahead!");
    
    mac = (int)sigma[job + n * maccount[job]] - 1; /* get the machine ID for this job */
    time = p[job + n * mac]; /* the processing time for (job on mac) */
    
    workremaining[job] -=  p[job + n * mac]; /* reduce the amount of work remaining for this job by p */
    
    /* find a slot that could be used to assign this job */
    slot = findslot(job, mac, time, jobcount, jobtime, sTime, eTime, n, m);
    
    starttime = MAX(jobtime[job], sTime[mac + m * slot]);
    if (jobcount[mac]<(n-1)) {
      eTime[mac + m*(jobcount[mac]+1)] = eTime[mac + m * slot]; /* the new slot create inherits the old end time of slot */
      sTime[mac + m*(jobcount[mac]+1)] = starttime + time; /* the start time of this new slot is the end time of the new job */
    }
    eTime[mac + m * slot] = starttime; /* the end time of the old slot is now the start time of the job, the start remains as before */
    xTime[job + n * mac] = starttime; /* actual starttime for this job on machine mac */
    jobtime[job] = starttime + time; /* the time this job will be released */
    mactime[mac] = MAX(mactime[mac], jobtime[job]); /* the new makespan for this machine  */
    if (mactime[mac] > Makespan[0]) Makespan[0] = mactime[mac];
    
    maccount[job] += 1; /* the machine we are up to for job */
    jobcount[mac] += 1; /* the machine we are up to for the job */
    
  }
  
/*  mxFree(sTime); */
/*  mxFree(eTime); */
  
  mxFree(mactime);
  mxFree(maccount);
  mxFree(jobtime);
  mxFree(jobcount);
  
  mxFree(workremaining);
}
