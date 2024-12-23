#include "anf.h"
#include <stdio.h>

int anf(int y, int *s, int *a, int *rho, unsigned int* index)
{
    /*
     y in Q15 : newly captured sample
     s in Q12 : x[3] databuffer - Hint: Reserve a sufficiently number of integer bits such that summing intermediate values does not cause overflow (so no shift is needed after summing numbers)
     a in Q14 : the adaptive coefficient
     e in Q15 : output signal
     rho in Q15 : fixed {rho, rho^2} or variable {rho, rho_inf} pole radius
     index : points to (t-1) sample (t current time index) in s -> circular buffer
     */

    int e, k;
    long AC0, AC1;

    k = *index;
    long a_i = (long) *a;

    // 1) update rho (is fixed here)
    // TODO: add rho update

    // 2) shift buffer and calculate new inserted s
    // Shift the buffer
    s[2] = s[1];
    s[1] = s[0];

    AC1 = (((long) rho[0]) >> 1) * a_i; // Q14 * Q14 = Q28
    AC1 += 32768; // Round the part we'll truncate by adding 2^15
    AC1 >>= 16; // Q28 -> Q12
    AC1 = AC1 * (long) s[1]; // Q12 * Q12 -> Q24

    AC0 = ((long) y) << 9; // Q15 -> Q24
    AC0 += AC1; // Q24

    AC1 = (((long) rho[1]) >> 3) * (long) s[2];  //Q12 * Q12 = Q24

    AC0 -= AC1;
    AC0 += 2048; // Round the part we'll truncate by adding 2^11
    s[0] = (int) (AC0 >> 12); // Q24 -> Q12

    // 3) update e
    AC0 = a_i * (long) s[1]; // Q14 * Q12 = Q26
    AC0 = (((long) s[0]) << 14) + (((long) s[2]) << 14) - AC0; // Q26
    AC0 += 1024; // Round the part we'll truncate by adding 2^10
    e = (int) (AC0 >> 11); // Q26 -> Q15

    // 4) update a
    AC0 = (long) (2 << 13) * (long) mu; // Q13 * Q15 = Q28
    AC0 += 8192; // Round the part we'll truncate by adding 2^13
    AC0 = AC0 >> 14; //Q28->Q14

    AC1 = (long) e * (long) s[1]; // Q15 * Q12 = Q27
    AC1 += 4096; // Round the part we'll truncate by adding 2^12
    AC1 = AC1 >> 13; // Q27 -> Q14

    AC1 = AC0 * AC1; // Q14 * Q14 = Q28
    AC1 += 8192; // Round the part we'll truncate by adding 2^13
    *a  = (int) (a_i + (AC1 >> 14)); // Q28 -> Q14

    *index = (k == 0) ? 2 : k - 1;   // Update circular buffer index
    
    return e;
}
