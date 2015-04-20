/*
 * JSP scheduling heurstic using min stlot insection and tight left packing
 * Written by Thomas P. Runarsson, version: 21.11.2013
 */

#include "mex.h"
#define infinity    999999999999.0
#define MAX(A, B)    ((A) > (B) ? (A):(B))
#define MIN(a, b)  (((a) < (b)) ? (a) : (b))


/* return the smallest feasible available idle machine slot, this is the Insert option */
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

/* main entry point for jsp_data.c */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
  
  int slot, i, j, n, m, job, optjob, mac, *jobcount, *maccount;
  double *Makespan, *xTime, *sTime, *eTime, *jobworkremaining, *macworkremaining, *totalwork, *jobtime, *mactime, *p, *sigma;
  double *w;
  double *trajectory;
  unsigned int index, k, steplength;
  double time, starttime, maxvalue, V;
  double *phi;
  int numfeatures = 15;
  
  if (nrhs < 3) mexErrMsgTxt("usage: [makespan,xTime,trajectory] = jsp_heuristic(p,sigma,w)");
  
  n = mxGetM(prhs[0]);
  m = mxGetN(prhs[0]);
  steplength = n*m;
  p = mxGetPr(prhs[0]);
  sigma = mxGetPr(prhs[1]);
  w = mxGetPr(prhs[2]);

  if ((numfeatures-1) != mxGetN(prhs[2])*mxGetM(prhs[2]))
    mexErrMsgTxt("length(w(:)) == 14");

  if (n*m != mxGetN(prhs[1])*mxGetM(prhs[1]))
    mexErrMsgTxt("length(p(:)) == length(sigma(:))");
  
  /* Allocate memory and assign pointers */
  plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
  Makespan = mxGetPr(plhs[0]);
  plhs[1] = mxCreateDoubleMatrix(n, m, mxREAL);
  xTime = mxGetPr(plhs[1]);
  plhs[2] = mxCreateDoubleMatrix(n*m, 4+2, mxREAL); /* job, machine, starttime, variable index */
  trajectory = mxGetPr(plhs[2]);
  
  /* allocate memory for matrices used */
  phi = (double *) mxCalloc(numfeatures, sizeof(double));
  mactime = (double *) mxCalloc(m, sizeof(double));
  maccount = (int *) mxCalloc(n, sizeof(int));
  jobtime = (double *) mxCalloc(n, sizeof(double));
  jobcount = (int *) mxCalloc(m, sizeof(int));
  jobworkremaining = (double *) mxCalloc(n, sizeof(double)); /* note this is zeroed since we are using calloc */
  totalwork = (double *) mxCalloc (n, sizeof(double));
  macworkremaining = (double *) mxCalloc(m, sizeof(double));
  sTime = (double *) mxCalloc(m * n, sizeof(double));
  eTime = (double *) mxCalloc(m * n, sizeof(double));
  
  /* initialize variables */
  for (i=0; i<n*m; i++) {
    sTime[i] = 0.0; /* note: not needed when using Calloc */
    eTime[i] = 0.0;
  }
  for (i=0; i<m; i++)
    eTime[i] = infinity;
  for (j=0; j<n; j++) {
    for (i=0; i<m; i++) {
      jobworkremaining[j] += p[j + n * i];
      totalwork[j] += p[j + n * i];
      macworkremaining[i] += p[j + n * i];
    }
  }
  Makespan[0] = 0.0;
  /* build schedule based on heuristic rule */
  for (i = 0; i < n*m; i++) {
    /* perform look-ahead search for each legal dispatch */
    job = -1;
    maxvalue = -1.0 * infinity;
    for (j = 0; j < n; j++) { /* here we are actually performing some sort of single ply look ahead to determine a post-decision state */
      if (maccount[j] < m) {
        /* legal move is j and its properties are: */
        mac = (int)sigma[j + n * maccount[j]] - 1; /* machine needed for this job */
        slot = findslot(j, mac, p[j + n * mac], jobcount, jobtime, sTime, eTime, n, m);
        starttime = MAX(jobtime[j], sTime[mac + m * slot]);
        phi[0] = optjob + 1;  /* The job to be dispatched */
        phi[1] = mac + 1;     /* Are jobs on the same machine? */
        phi[2] = starttime;   /* start time for this job */
        phi[3] = jobtime[j];  /* arrival time for a job, FIFO, AT, C_{i,j-1} in Haupt88 */
        phi[4] = jobworkremaining[j]; /* MWRM, work remaining for this job */
        phi[5] = p[j + n * mac]; /* processing time for job, used by heuristics like SPT and LPT */
        phi[6] = jobcount[j];  /* Greatest/fewest number of jobs remaining assumes number of operation to be the same for all jobs */
        phi[7] = totalwork[j]; /* the greatest total work */
        phi[8] = starttime - jobtime[j]; /* the waiting time for this job */
        phi[9] = (double)(eTime[slot] < (infinity-1)); /* is the job inserted in an available slot, or attached to the end? */
        phi[10] = MAX(mactime[mac], starttime + p[j + n * mac]); /* new completion time for the machine */
        phi[11] = MAX(Makespan[0],MAX(mactime[mac], starttime + p[j + n * mac])); /* new global makespan */
        phi[12] = macworkremaining[mac]; /* This would only make sense when comparing different machines, else anyway zero, total Work In Queue WINQ for machine mac */
        phi[13] = starttime - sTime[mac + m * slot]; /* size of slot insert space created */
        phi[14] = starttime + p[j + n * mac]; /* new completion time for this job */
        V = 0.0;
        for (k=1;k<numfeatures;k++)
          V += phi[k] * w[k-1];
        if (V > maxvalue) {
          maxvalue = V;
          job = j;
        }
      }
    }
    
    if (job < 0)
      mexErrMsgTxt("no feasible job found in lookahead (this should never happen)!");
    
    mac = (int)sigma[job + n * maccount[job]] - 1; /* get the machine ID for this job */
    time = p[job + n * mac]; /* the processing time for (job on mac) */
    
    jobworkremaining[job] -= p[job + n * mac]; /* reduce the amount of work remaining for this job by p */
    macworkremaining[mac] -= p[job + n * mac]; /* reduce the amount of work remaining for this machine by p */
    
    /* find the smallest slot that could be used to assign this job */
    slot = findslot(job, mac, time, jobcount, jobtime, sTime, eTime, n, m);
    
    starttime = MAX(jobtime[job], sTime[mac + m * slot]);
    /*  starttime = xpath[job + mac * n]; */ /* choose this if you want to use exact input times (may be different for Gurobi solution) */
    
    /* index to variable in Gurobi model, the trajectory is used to fix partial solution in Gurobi */
    index = mac*n+job;
    trajectory[i ] = job + 1;
    trajectory[i + steplength] = mac + 1;
    trajectory[i + 2*steplength] = starttime;
    trajectory[i + 3*steplength] = index + 1; /* plus one to make it a MATLAB index */
    trajectory[i + 4*steplength] = sTime[mac + m * slot]; /* the slot use in this trajectory */
    trajectory[i + 5*steplength] = eTime[mac + m * slot];
    
    if (jobcount[mac] < (n-1)) { /* only update slots on machines when needed */
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
  /* free all Calloc-s */
  mxFree(eTime);
  mxFree(sTime);
  mxFree(mactime);
  mxFree(maccount);
  mxFree(jobtime);
  mxFree(jobcount);
  mxFree(macworkremaining);
  mxFree(jobworkremaining);
  mxFree(totalwork);
  mxFree(phi);
}
