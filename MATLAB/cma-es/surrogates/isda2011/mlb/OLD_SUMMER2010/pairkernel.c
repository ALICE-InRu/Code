/*
 * Copyright (C) 2006, Thomas Philip Runarsson. All rights reserved.
 */

#include <math.h>
#include "mex.h"

#define	max(A, B)	((A) > (B) ? (A) : (B))
#define	min(A, B)	((A) < (B) ? (A) : (B))

double gamma_ = 1.0 / 1.0;

double
kernelpoly(double *x, double *y, int n)
{
  int i;
  double K = 0.0, R = 1.0, a = 1.0, d = 4.0;

  for (i = 0; i < n; i++)
    K += x[i] * y[i];
  K = pow(K/a + R, d);
/*  K = (K + 1.0) * (1.0 + K); */
  return (K);
}

double
kernelspline(double *x, double *y, int n)
{
  int i;
  double K = 1.0, minxy;

  for (i = 0; i < n; i++)
  {
    minxy = min(x[i],y[i]);
   /*
    K = K * (1.0 + x[i] * y[i] + x[i] * y[i] * minxy -minxy*minxy*(x[i] + y[i])/2.0+minxy*minxy*minxy/3.0); 
    */
    K = K * minxy;
  }
  return (K);
}



double
kernelrbf(double *x, double *y, int n)
{
  int i;
  double K = 0.0;

  for (i = 0; i < n; i++)
    K += (x[i] - y[i]) * (x[i] - y[i]);
  K = exp(-1.0 * gamma_ * K);
  return (K);
}

double
kernel(double *x, double *y, int n)
{
  return (kernelrbf(x, y, n));
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
  int ell, n, m, i, j;
  double *X1, *X2, *K;
  double k1, k2, k3, k4;

  /* check input arguments */
  if (nrhs < 2)
    mexErrMsgTxt("usage: K = pairkernel(Xi,Xj);\nOr K = pairkernel(Xi,Xj,0) for just normal kernel calculations\n");

  /* get pointers to input */
  ell = mxGetN(prhs[0]);
  n = mxGetM(prhs[0]);
  X1 = mxGetPr(prhs[0]);
  X2 = mxGetPr(prhs[1]);

  /* check if its the correct format! */
  if (n !=  mxGetM(prhs[1]))
    mexErrMsgTxt("usage: size(Xi,1) must be size(Xj,1), attribute length");

  if (nrhs == 3)
    {
      m = mxGetN(prhs[1]);
      /* initialize memory for kernel matrix */
      plhs[0] = mxCreateDoubleMatrix(ell, m, mxREAL) ;
      K = mxGetPr(plhs[0]);

      for (i = 0; i < ell; i++) 
	{
	  for (j = 0; j < m; j++)
	    {
	      K[j * ell + i] = kernel(&X1[i * n],&X2[j * n], n);
	    }
	}
    }
  else
    {
      if (ell !=  mxGetN(prhs[1]))
	mexErrMsgTxt("usage: size(Xi,2) must be size(Xj,2), data length");

      /* initialize memory for kernel matrix */
      plhs[0] = mxCreateDoubleMatrix(ell, ell, mxREAL) ;
      K = mxGetPr(plhs[0]);
      
      /* kernel computation, symmetric matrix */
      for (i = 0; i < ell; i++) 
	{
	  for (j = i; j < ell; j++)
	    {
	      k1 = kernel(&X1[i * n],&X1[j * n], n);
	      k2 = kernel(&X1[i * n],&X2[j * n], n);
	      k3 = kernel(&X2[i * n],&X1[j * n], n);
	      k4 = kernel(&X2[i * n],&X2[j * n], n);
	      K[i * ell + j] = k1 - k2 - k3 + k4;
	      K[j * ell + i] = K[i * ell + j]; /* symmetry */
	    }
	}
    }
}

