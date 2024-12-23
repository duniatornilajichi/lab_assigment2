#ifndef ANF_H
#define ANF_H

#define mu 200  // 2 * MU ( 2 * Step size )
#define lambda 32440 // time constant = 0,99

int anf(int y, int *s , int *a, int *rho, unsigned int* index);

#endif
