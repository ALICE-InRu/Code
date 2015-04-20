/*
 * Copyright (C) 2006, Thomas Philip Runarsson. All rights reserved.
 */

#include <math.h>
#include "mex.h"

double kendl(double *data1, double *data2, unsigned long n)
{
  unsigned long n2 = 0, n1 = 0, k, j;
  long is = 0;
  double tau, aa, a2, a1;
  
  for (j=0;j<n-1;j++) 
    {
      for (k=(j+1);k<n;k++) 
	{
	  a1 = data1[j]-data1[k];
	  a2 = data2[j]-data2[k];
	  aa = a1*a2;
	  if (aa) 
	    {
	      ++n1;
	      ++n2;
	      aa > 0.0 ? ++is : --is;
	    } 
	  else 
	    {
	      if (a1) 
		++n1;
	      if (a2) 
		++n2;
	    }
	}
    }
  tau = is/(sqrt((double) n1)*sqrt((double) n2));
  return (tau);
}

#ifdef __STDC__
extern void mexFunction(int nlhs,mxArray *plhs[],int nrhs,const mxArray *prhs[])
#else
extern mexFunction(nlhs, plhs, nrhs, prhs)
int nlhs, nrhs;
mxArray *plhs[];
const mxArray *prhs[];
#endif
{
  int ell;
  double *X1, *X2, *T;

  /* check input arguments */
  if (nrhs != 2)
    mexErrMsgTxt("usage: tau = kendaltau(Xi,Xj);");

  /* get pointers to input */
  ell = mxGetN(prhs[0]) * mxGetM(prhs[0]);
  X1 = mxGetPr(prhs[0]);
  X2 = mxGetPr(prhs[1]);

  /* check if its the correct format! */
  if (ell !=  mxGetM(prhs[1]) * mxGetN(prhs[1]))
    mexErrMsgTxt("usage: length(Xi) must be length(Xj)");

  /* initialize memory for tau mayrix 1x1 */
  plhs[0] = mxCreateDoubleMatrix(1,1,mxREAL) ;
  T = mxGetPr(plhs[0]);

  /* kernel computation, symmetric matrix */
  T[0] = kendl(X1, X2, (unsigned long)ell);
}

