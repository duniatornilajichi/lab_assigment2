#include <dsplib.h>
#include <stdio.h>
#include <usbstk5515.h>
#include "aic3204.h"
//#include "anf.h" //INCLUDE FOR C IMPLEMENTATION
#define SAMPLES_PER_SECOND 8000
#define GAIN_IN_dB 10

int main() {
  // declare variables
    short left, right;
    int e;
    unsigned int index = 0;
    int s[3] = {0,0,0};
    int a[1] = {16384}; // a = 1
    int rho[2] = {26214, 28836}; // rho adaptive {rho=0.8, rho_inf=0.88}

  USBSTK5515_init(); // Initializing the Processor
  aic3204_init();    // Initializing the Audio Codec

  set_sampling_frequency_and_gain(SAMPLES_PER_SECOND, GAIN_IN_dB);

  while (1) {
    // Read from microphone
     aic3204_codec_read(&left, &right);

	// Implementation goes here...
    e = anf(left ,&s[0], &a[0], &rho[0], &index);

    // Write to line out
    aic3204_codec_write(e, e);
  }

  return 0;
}

