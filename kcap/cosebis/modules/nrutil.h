#ifndef NRUTIL_H
#define NRUTIL_H

using namespace std;

#include <iostream>
#include <stdlib.h>

#include "globaldef.h"

#define NR_END 1
#define FREE_ARG char*
#define SWAP(a,b) {tempr=(a);(a)=(b);(b)=tempr;}

static number sqrarg=0.;
#define SQR(a) ((sqrarg=(a)) == 0.0 ? 0.0 : sqrarg*sqrarg)

static number dsqrarg=sqrarg;
#define DSQR(a) ((dsqrarg=(a)) == 0.0 ? 0.0 : dsqrarg*dsqrarg)

static number dmaxarg1=dsqrarg,dmaxarg2=dsqrarg;
#define DMAX(a,b) (dmaxarg1=(a),dmaxarg2=(b),(dmaxarg1) > (dmaxarg2) ?\
        (dmaxarg1) : (dmaxarg2))

static number dminarg1=dmaxarg1,dminarg=dmaxarg2;
#define DMIN(a,b) (dminarg1=(a),dminarg2=(b),(dminarg1) < (dminarg2) ?\
        (dminarg1) : (dminarg2))

static number maxarg1=dminarg1,maxarg2=dminarg;
#define FMAX(a,b) (maxarg1=(a),maxarg2=(b),(maxarg1) > (maxarg2) ?\
        (maxarg1) : (maxarg2))

static number minarg1=maxarg1,minarg2=maxarg2;
#define FMIN(a,b) (minarg1=(a),minarg2=(b),(minarg1) < (minarg2) ?\
        (minarg1) : (minarg2))

static long lmaxarg1=0,lmaxarg2=lmaxarg2;
#define LMAX(a,b) (lmaxarg1=(a),lmaxarg2=(b),(lmaxarg1) > (lmaxarg2) ?\
        (lmaxarg1) : (lmaxarg2))

static long lminarg1=lmaxarg1,lminarg2=lmaxarg2;
#define LMIN(a,b) (lminarg1=(a),lminarg2=(b),(lminarg1) < (lminarg2) ?\
        (lminarg1) : (lminarg2))

static int imaxarg1=lminarg1,imaxarg2=lminarg2;
#define IMAX(a,b) (imaxarg1=(a),imaxarg2=(b),(imaxarg1) > (imaxarg2) ?\
        (imaxarg1) : (imaxarg2))

static int iminarg1=imaxarg1,iminarg2=imaxarg2;
#define IMIN(a,b) (iminarg1=(a),iminarg2=(b),(iminarg1) < (iminarg2) ?\
        (iminarg1) : (iminarg2))

#define SIGN(a,b) ((b) >= 0.0 ? fabs(a) : -fabs(a))

 void   nrerror(char[]);
 int    *ivector(long, long);
 void   free_ivector(int*, long, long);
 number *Vector(long, long);
 number **Matrix(long nrl, long nrh, long ncl, long nch);
 void   free_vector(number*, long, long);
 void   free_Matrix(number **m, long nrl, long nrh, long ncl, long nch);

#endif
