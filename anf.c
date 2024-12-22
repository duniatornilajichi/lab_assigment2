#include "anf.h"

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
    s[(k+2)%3] = s[(k+1)%3];
    s[(k+1)%3] = s[k%3];
    AC1 = (((long) rho[0]) >> 3) * a_i; // Q12 * Q12 = Q24
    AC1 += 2048; // Round the part we'll truncate by adding 2^11
    AC1 >>= 12; // Q24 -> Q12
    AC1 = AC1 * (long) s[(k+1)%3]; // Q12 * Q12 -> Q24

    AC0 = ((long) y) << 9; // Q15 -> Q24
    AC0 += AC1; // Q24

    AC1 = (((long) rho[1]) >> 3) * (long) s[(k+2)%3];  //Q12 * Q12 = Q24
    AC0 -= AC1;
    AC0 += 2048; // Round the part we'll truncate by adding 2^11
    s[k%3] = (short) (AC0 >> 12); // Q24 -> Q12

    // 3) update e
    AC0 = a_i * (long) s[(k+1)%3]; // Q14 * Q12 = Q26
    AC0 = (((long) s[k%3]) << 14) + (((long) s[(k+2)%3]) << 14) - AC0; // Q26
    AC0 += 1024; // Round the part we'll truncate by adding 2^10
    e = (short) (AC0 >> 11); // Q26 -> Q15

    // 4) update a
    AC0 = (long) (2 << 14) * (long) mu; // Q14 * Q15 = Q29
    AC0 += 16384; // Round the part we'll truncate by adding 2^14
    AC0 = AC0 >> 15; //Q29->Q14

    AC1 = (long) e * (long) s[(k+1)%3]; // Q15 * Q12 = Q27
    AC0 += 4096; // Round the part we'll truncate by adding 2^12
    AC1 = AC1 >> 13; // Q27 -> Q14

    AC1 = AC0 * AC1;
    AC0 += 8192; // Round the part we'll truncate by adding 2^13
    *a  = (short) (a_i + (AC1 >> 14)); // Q28 -> Q14

    *index = (k == 0) ? 2 : k - 1;   // Update circular buffer index
    
    return e;
}
