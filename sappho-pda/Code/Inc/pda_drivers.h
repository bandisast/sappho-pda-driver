/****************************************************
*                                                   *
*---------------------------------------------------*
*  PDA Drivers                                      *
*---------------------------------------------------*
*                                                   *
* Copyright (C) 2019, Gkagkanis Efstratios,         *
*    				all rights reserved.*
*                                                   *
* Redistribution and use in source and binary forms,*
* with or without modification, are permitted       *
* provided that the following condition is met:     *
*                                                   *
* 1. Redistributions of source code must retain the *
* the above copyright notice, this condition and    *
* the following disclaimer.                         *
*                                                   *
*                                                   *
* This software is provided by the copyright holder *
* and any warranties related to this software       *
* are DISCLAIMED.                                   *
* The copyright owner or contributors be NOT LIABLE *
* for any damages caused by use of this software.   *
*                                                   *
*****************************************************

*****************************************************
*                                                   *
* Adapted for the S,AP.P.H.O PDA project by:        *
* Bantis Asterios (@bandisast), AutomE, 2022        *
*                                                   *
****************************************************/

#include <stdio.h>
#include <stdint.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <dirent.h>
#include <unistd.h>
#include <prussdrv.h>
#include <pruss_intc_mapping.h>

/***************/
/* Definitions */
/***************/
#define ARGUMENTS_NUM (4)
#define PRU0 0
#define PRU1 1

#define ErrorSecondsSleep (2)	//How many seconds will the LED stay Red.

/* PDA */
#define PIXELS 			(1500)
#define MIN_INTGR_TIME	(10)
#define MAX_INTGR_TIME	(10000)

/* CALCULATION MACROS */
#define EXTRA_PULSE				(14) // 14 extra pulses are required at the end
#define EXTRA_WAIT_B4_NEXT_SI	(10) // 20us exta time between integrations
#define uS_TO_S					(0.000001) // conversion from us to s
#define S_TO_uS					(1000000)
#define INSTRUCTION_DELAY		(0.00000001) // Minimum delay time for a delay loop
#define FIRST_32_PULSES			(32) // The first 32 setup clock pulses
#define KHZ_TO_MHZ				(1000)

/* PATHS */
#define PRU0_BIN_PATH "/home/debian/sappho-pda/Code/PRU/PRU0.bin"
#define PRU1_BIN_PATH "/home/debian/sappho-pda/Code/PRU/PRU1.bin"

/* Return Codes
unsigned int (32bit, big endian, 0 ~ 4.294.967.295) */
#define NO_ERR			0
#define ARGU_ERR 		100000	//Incorrect number of arguments.
#define	CLK_ERR 		100001	//Clock frequency out of bounds.
#define INTGR_ERR 		100002	//Integration time out of bounds.
#define FILE_ERR 		100003	//Error while opening the data file.
#define PRU_INIT_ERR 	100004	//Failed to initialize PRU.
#define PRU_DEINIT_ERR 	100005	//Failed to de initialize PRU.
#define PRU_START_ERR 	100006	//Failed to start PRUs.
#define PRU_EVENT_ERR	100007
#define CALC_ERR		100008
#define MEM_ERR			100009	//Not enough RAM for the requested samples.
#define FOLDER_ERR		100010	//"Samples" folder not found in the directory.
#define GPIO_ERR		100011
#define BUTTON_ERR		100012
#define LED_ERR			100013


/* RAM Offset */
#define Pixels_Offset				0
#define Frames_Offset				1
#define Integr_Time              	2
#define Handshake0_Offset			3
#define ExtraTime_Offset            4
#define Handshake1_Offset			5
#define DDR_Addr_Offset				6
#define DDR_Size_Offset				7