/*
 * JSP scheduling heurstic using min stlot insection and tight left packing
 * Written by Thomas P. Runarsson, version: 21.11.2013 updated by Helga!
 */

#include "mex.h"
#define infinity    999999999999.0
#define numfeatures 15
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

double* findFeature(int job, int mac, double starttime, int slot, int n, int m, 
        double *p, double *sigma, double *sTime, double *eTime, double *totalwork, double *Makespan,
        int *jobcount, 
        double *jobtime, double *mactime, 
        double *jobworkremaining, double *macworkremaining)
{
    double myphi[numfeatures];
    myphi[0] = job + 1;  /* The job to be dispatched */
    myphi[1] = mac + 1;     /* Are jobs on the same machine? */
    myphi[2] = starttime;   /* start time for this job */
    myphi[3] = jobtime[job];  /* arrival time for a job, FIFO, AT, C_{i,job-1} in Haupt88 */
    myphi[4] = jobworkremaining[job]; /* MWRM, work remaining for this job */
    myphi[5] = p[job + n * mac]; /* processing time for job, used by heuristics like SPT and LPT */
    myphi[6] = jobcount[job];  /* Greatest/fewest number of jobs remaining assumes number of operation to be the same for all jobs */
    myphi[7] = totalwork[job]; /* the greatest total work */
    myphi[8] = starttime - jobtime[job]; /* the waiting time for this job */
    myphi[9] = (double)(eTime[slot] < (infinity-1)); /* is the job inserted in an available slot, or attached to the end? */
    myphi[10] = MAX(mactime[mac], starttime + p[job + n * mac]); /* new completion time for the machine */
    myphi[11] = MAX(Makespan[0],MAX(mactime[mac], starttime + p[job + n * mac])); /* new global makespan */
    myphi[12] = macworkremaining[mac]; /* This would only make sense when comparing different machines, else anyway zero, total Work In Queue WINQ for machine mac */
    myphi[13] = starttime - sTime[mac + m * slot]; /* size of slot insert space created */
    myphi[14] = starttime + p[job + n * mac]; /* new completion time for this job */
    return(myphi);
}

/* main entry point for jsp_data.c */
void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]) {
    
    int slot, i, j, n, m, job, optjob, mac, *jobcount, *maccount;
    double *Makespan, *xTime, *sTime, *eTime, *jobworkremaining, *macworkremaining, *totalwork, *jobtime, *mactime, *p, *sigma;
    double *xpath = NULL;
    double *trajectory, *lookahead, *steptr;
    unsigned int index, k, l, steplength;
    double time, starttime, minvalue, maxvalue, value;
    double *phi, *myphi, *weights, *useoptimal;    
        
    if (nrhs < 5) mexErrMsgTxt("usage: [makespan,xTime,trajectory,lookahead,properties] = jsp_data(p,sigma,xTime,steplength,weights,useoptimal)");
    
    n = mxGetM(prhs[0]);
    m = mxGetN(prhs[0]);
    p = mxGetPr(prhs[0]);
    sigma = mxGetPr(prhs[1]);
    xpath = mxGetPr(prhs[2]);
    steptr = mxGetPr(prhs[3]);
    weights = mxGetPr(prhs[4]);
    useoptimal = mxGetPr(prhs[5]);
    
    steplength = MIN((int)steptr[0], n*m);
    
    if (n*m != mxGetN(prhs[1])*mxGetM(prhs[1]))
        mexErrMsgTxt("length(p(:)) == length(seq) == length(sigma(:))");
    
    /* Allocate memory and assign pointers */
    plhs[0] = mxCreateDoubleMatrix(1, 1, mxREAL);
    Makespan = mxGetPr(plhs[0]);
    plhs[1] = mxCreateDoubleMatrix(n, m, mxREAL);
    xTime = mxGetPr(plhs[1]);
    plhs[2] = mxCreateDoubleMatrix(steplength, 4+2, mxREAL); /* job, machine, starttime, variable index */
    trajectory = mxGetPr(plhs[2]);
    plhs[3] = mxCreateDoubleMatrix(n, 4+2, mxREAL); /* job, machine, starttime, index for lookahead, sTime and eTime for the slot */
    lookahead = mxGetPr(plhs[3]);
    plhs[4] = mxCreateDoubleMatrix(n, numfeatures, mxREAL); /* the look-ahead features */
    phi = mxGetPr(plhs[4]);
    
    /* allocate memory for matrices used */
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
    k = 0;
    for (i = 0; i < steplength; i++) {
        /* perform look-ahead search for each legal dispatch */
        job = -1;
        optjob = -1;
        minvalue = infinity+10;
        for (j = 0; j < n; j++) { /* here we determine what is the optimal path, note that there are more than one but we use just one */
            if (maccount[j] < m) {
                if (xpath[j + ((int)sigma[j + n * maccount[j]] - 1) * n] < minvalue) {
                    minvalue = xpath[j + ((int)sigma[j + n * maccount[j]] - 1) * n];
                    optjob = j;
                }
            }
        }
        if (i == (steplength-1)) { /* only do this once we have reached the steplength requested */
            for (j = 0, k = 0; j < n; j++) { /* here we are actually performing some sort of single ply look ahead to determine a post-decision state */
                if (maccount[j] < m) {
                    /* legal move is j and its properties are: */
                    mac = (int)sigma[j + n * maccount[j]] - 1; /* machine needed for this job */
                    slot = findslot(j, mac, p[j + n * mac], jobcount, jobtime, sTime, eTime, n, m);
                    starttime = MAX(jobtime[j], sTime[mac + m * slot]);
                    myphi = findFeature(j, mac, starttime, slot, n, m, p, sigma, sTime, eTime, totalwork, Makespan, jobcount, jobtime, mactime, jobworkremaining, macworkremaining);
                    for(l=0; l<numfeatures; l++)
                        phi[k +  l*n] = myphi[l]; 
                    
                    lookahead[k ] = j+1;
                    lookahead[k + n] = mac+1;
                    lookahead[k + 2*n] = starttime;
                    lookahead[k + 3*n] = (mac*n+j)+1;
                    lookahead[k + 4*n] = sTime[mac + m * slot];
                    lookahead[k + 5*n] = eTime[mac + m * slot];
                    k = k + 1;
                }
            }
        }
        job = optjob; /* select the job with the minimum start-time this is the path requested */
        
        
        /* use weights vector */
        if (useoptimal[i] == 0) {
            job = -1;
            maxvalue = -1.0 * infinity;
            for (j = 0; j < n; j++) { /* here we determine what is the optimal path, note that there are more than one but we use just one */
                if (maccount[j] < m) {
                    mac = (int)sigma[j + n * maccount[j]] - 1; /* machine needed for this job */
                    slot = findslot(j, mac, p[j + n * mac], jobcount, jobtime, sTime, eTime, n, m);
                    starttime = MAX(jobtime[j], sTime[mac + m * slot]);                    
                    myphi = findFeature(j, mac, starttime, slot, n, m, p, sigma, sTime, eTime, totalwork, Makespan, jobcount, jobtime, mactime, jobworkremaining, macworkremaining);
                    value = 0.0;
                    for (k = 0; k < numfeatures; k++)
                        value += myphi[k] * weights[k];
                    if (value > maxvalue) {
                        maxvalue = value;
                        job = j;
                    }
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
}
