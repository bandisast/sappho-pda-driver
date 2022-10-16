/****************************************************
*                                                   *
*---------------------------------------------------*
*  PDA Drivers                                      *
*---------------------------------------------------*
*                                                   *
* Copyright (C) 2019, Gkagkanis Efstratios,         *
*    				all rights reserved.            *
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


#include "pda_drivers.h"
#include "sample_file.h"
#include "debug.h"
#include "gpio.h"

/**********/
/* MACROS */
/**********/
#define RED_TIME 5 /* Turn on RED LED for 5 seconds in case of error */

/************************/
/* Variable Definitions */
/************************/
uint32_t *pru_shared_ram = 0;	//Int pointer for RAM addressing.
uint16_t *ddr_casted = 0;
uint32_t sample_len;

double clkfreq;
uint16_t frames;
double intgr_time;
double fps;

uint16_t intgr_delay;
uint32_t extra_time;
uint16_t prog_total_cycles = 3099; //number of CLK pulses/frame, without the extra time delay (2 * 1500 pixels + 2 * 32 dummy outputs + 2* 14 dummy outputs + 7 CLK pulses for the ICG stage)

/*************************/
/* Function Declarations */
/*************************/	
static uint32_t Argv_Handler(int *argc, char *argv[]);
static uint32_t Delay_Calculation(void);
static uint32_t Mem_Alloc(void);
static uint32_t Init_PRUSS(void);
static uint32_t Start_PRUs(void);
static void Wait_For_PRUs(void);
static uint32_t Deinit_PRU(void);

int main(int argc, char *argv[])
{
	uint32_t result, file_number;
		
	#if DEBUG_MODE == 1
		printf("Debug Mode ON\n");
	#endif
	
	result = Argv_Handler(&argc, argv);
	Debug_Print("Argv_Handler result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Init_GPIO();
	Debug_Print("Init_GPIO result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Write_LED(BLUE);
	Debug_Print("Write_LED result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Button_Wait_To_Press();
	Debug_Print("Button_Wait_To_Press result:", &result);
	if (result != NO_ERR) goto exit;

	result = Write_LED(GREEN);
	Debug_Print("Write_LED result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Create_File();
	Debug_Print("Make_File result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Delay_Calculation();
	Debug_Print("Delay_Calculation result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Init_PRUSS();
	Debug_Print("Init_PRUSS result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Mem_Alloc();
	Debug_Print("Mem_Alloc result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Start_PRUs();
	Debug_Print("Start_PRUs result:", &result);
	if (result != NO_ERR) goto exit;
	
	Wait_For_PRUs();
	
	file_number = Save_Samples();
	Debug_Print("Save_Samples result:", &file_number);
	if (file_number >= ARGU_ERR) goto exit;
	
	result = Deinit_PRU();
	Debug_Print("Deinit_PRU result:", &result);
	if (result != NO_ERR) goto exit;
	
	result = Write_LED(OFF);
	Debug_Print("Write_LED result:", &result);
	if (result != NO_ERR) goto exit;

	result = Button_Wait_To_Release();
	Debug_Print("Button_Wait_To_Release result:", &result);
	if (result != NO_ERR) goto exit;
	
	return file_number;
	
exit:
	Debug_Print("Error code:", &result);
	Write_LED(RED);
	sleep(RED_TIME);
	Write_LED(OFF);
	return result;
}

/********************/
/* HELPER FUNCTIONS */
/********************/

static uint32_t Argv_Handler(int *argc, char *argv[])
{
	uint32_t result = ARGU_ERR;
	
	if (*argc != ARGUMENTS_NUM) {
		printf("Incorrect arguments.\n");
		printf("Example: ./sappho_exec 10 120 50\n");
		printf("First argument: Number of Frames \n");
		printf("Second argument: Integration Time in us. Min = 10 us, Max = 10 ms \n");
		printf("Third argument: Frames per second (fps). Min = 1 fps. Max = 161 fps \n");
		printf("Please try again.\n");
		goto exit;
	}
	
	clkfreq = 500;
	frames = abs(atoi(argv[1]));
	frames++; //The first frame always contains junk data, so we skip it. Therefore, we add an extra frame here for parity. :)
	intgr_time = abs(atof(argv[2]));
	fps = abs(atof(argv[3]));
	
	if(intgr_time < MIN_INTGR_TIME || intgr_time > MAX_INTGR_TIME) {
		goto exit;
	}
	
	result = NO_ERR;

	if (fps >= (int) (S_TO_uS/prog_total_cycles/(1000/clkfreq)) || fps < 1)
	{
		fps = (int) (S_TO_uS/prog_total_cycles);
		printf("Warning: Invalid fps argument; Fps automatically set to its maximum value.\n");
	}
exit:
	return result;
}

static uint32_t Delay_Calculation(void)
{
	intgr_delay=(int) intgr_time*(clkfreq/1000);  //Kinda useless when your clock is 1000 KHz but keeping this here in case the clock frequency changes again
	extra_time = ((S_TO_uS/fps) - (KHZ_TO_MHZ*prog_total_cycles)/clkfreq)*(clkfreq/1000); // ^--- I should play the lottery next time; now the clock frequency is 500 KHz 
	return NO_ERR;
}

static uint32_t Init_PRUSS(void)
{
	uint32_t result = PRU_INIT_ERR;
	int res;
	
	res = prussdrv_init();
	res |= prussdrv_open (PRU_EVTOUT_0);
	res |= prussdrv_open (PRU_EVTOUT_1);
	if (res != 0) goto exit;
	
	/* PRU Interrupt Setup */
	tpruss_intc_initdata pruss_intc_initdata = PRUSS_INTC_INITDATA;
	result = (uint32_t) prussdrv_pruintc_init(&pruss_intc_initdata);
	if (result != 0) goto exit;
	
	result = NO_ERR;
exit:
	return result;
}

static uint32_t Mem_Alloc(void)
{
	uint32_t result = MEM_ERR;
	void *pru_shared_ram_void;
	void *ddr_ram_void;
	uint32_t ddr_address;
	
	/* PRU Shared RAM & DDR Setup */
	prussdrv_map_prumem(PRUSS0_SHARED_DATARAM, &pru_shared_ram_void);
	pru_shared_ram = (uint32_t *) pru_shared_ram_void;
	prussdrv_map_extmem((void **) &ddr_ram_void);
	ddr_address = prussdrv_get_phys_addr((void *) ddr_ram_void);
	
	sample_len = (PIXELS * frames * sizeof(frames));
	if (sample_len > prussdrv_extmem_size()) {
		goto exit; /*If DDR memory allocated to PRUs is not enough, terminate. */
	}
	
	pru_shared_ram[Pixels_Offset] = PIXELS;
	pru_shared_ram[Frames_Offset] = frames;
	pru_shared_ram[ExtraTime_Offset] = extra_time;
	pru_shared_ram[DDR_Addr_Offset] = ddr_address; 
	pru_shared_ram[DDR_Size_Offset] = sample_len;
	pru_shared_ram[Integr_Time] = intgr_delay;


	//CLEAR MEMORY
	ddr_casted = (uint16_t *) ddr_ram_void;
	memset(ddr_casted, 0x00, (sample_len+1));
	
	result = NO_ERR;
exit:
	return result;
}

static uint32_t Start_PRUs(void)
{
	uint32_t result = PRU_START_ERR;
	int res;
	
	pru_shared_ram[Handshake0_Offset] = 0;
	pru_shared_ram[Handshake1_Offset] = 0;

	res = prussdrv_exec_program (PRU0, PRU0_BIN_PATH);
	res |= prussdrv_exec_program (PRU1, PRU1_BIN_PATH);
	if (res != 0) goto exit;
	
	while(pru_shared_ram[Handshake0_Offset] != 22522);	//PRU0 Handshake through pru_shared_ram

	prussdrv_pru_wait_event(PRU_EVTOUT_1);	//PRU1 Handshake through INTC
	prussdrv_pru_clear_event (PRU_EVTOUT_1, PRU1_ARM_INTERRUPT);
	if (res != 0) goto exit;
	pru_shared_ram[Handshake0_Offset] = 111;
	pru_shared_ram[Handshake1_Offset] = 222;
	
	result = NO_ERR;
exit:
	return result;
}

static void Wait_For_PRUs(void)
{
	while(pru_shared_ram[Handshake0_Offset] != 55255);	//Wait for PRU0 to finish.

	//printf("PRU0 handshake sent\n");
	prussdrv_pru_wait_event(PRU_EVTOUT_1);	//Wait for PRU1 to finish.
	//printf("PRU1 handshake sent\n");
	prussdrv_pru_clear_event (PRU_EVTOUT_1, PRU1_ARM_INTERRUPT);
	//printf("PRU clear event sent\n");
}

static uint32_t Deinit_PRU(void)
{
	uint32_t result;
	int res;
	
	res = prussdrv_pru_disable(PRU0);
	res |= prussdrv_pru_disable(PRU1);
	res |= prussdrv_exit ();
	
	if (res == 0) {
		result = NO_ERR;
	}
	else {
		result = PRU_DEINIT_ERR;
	}

	return result;
}
