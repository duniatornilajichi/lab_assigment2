/*****************************************************************************/
/*                                                                           */
/* FILENAME                                                                  */
/*  main.c                                                                   */
/*                                                                           */
/* DESCRIPTION                                                               */
/*   TMS320C5515 ANF-LMS implementation   				                     */
/*                                                                           */
/*****************************************************************************/

#include "stdio.h"
#include "anf.h"

#pragma CODE_SECTION(anf,       ".text:anf");
/* ------------------------------------------------------------------------ *
 *                                                                          *
 *  main( )                                                                 *
 *                                                                          *
 * ------------------------------------------------------------------------ */
int main( void )
{
	int y, e, tmp1;
	unsigned int index = 0;
	
	FILE  *fpIn;
	FILE  *fpOut;
	
	char  tempc[2];

	int s[3] = {0,0,0};
	int a[1] = {16384}; // a = 1
	int rho[2] = {26214, 28836}; // rho adaptive {rho=0.8, rho_inf=0.88}

	fpIn = fopen("..\\data\\in.pcm", "rb");
	fpOut = fopen("..\\data\\out.pcm", "wb");

	if (fpIn == NULL || fpOut == NULL) {
	    printf("Can't open input or output file. Exiting. \n");
	    return 1;
	}

	//Begin filtering the data
	while (fread(tempc, sizeof(char), 2, fpIn) == 2) {

		y = (tempc[0] & 0xFF) | (tempc[1] << 8);
		e = anf(y ,&s[0], &a[0], &rho[0], &index); // Adaptive Notch Filter.

		tempc[0] = (e & 0xFF);
		tempc[1] = (e >> 8) & 0xFF;
		
		fwrite(tempc, sizeof(char), 2, fpOut);
	}
		fclose(fpIn);
    	fclose(fpOut);

    	printf( "\n***Program has Terminated***\n" );
		return 0;
}

/*****************************************************************************/
/* End of main.c                                                             */
/*****************************************************************************/
