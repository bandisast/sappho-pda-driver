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


#include "gpio.h"

static const uint8_t exportTable[4] = {60, 26, 47, 46};
static const char directionTable[4][4] = {"in", "out", "out", "out"};
static const char *directionPaths[4] = {DIRECTION_BUTTON, DIRECTION_LED_R, DIRECTION_LED_G, DIRECTION_LED_B};
static const char *valuePaths[3] = {VALUE_LED_R, VALUE_LED_G, VALUE_LED_B};
static uint8_t valueTable[3] = {0, 0, 0};

/*	Initialization of GPIO controlled
	controlled by the higher level part of the drivers */
uint32_t Init_GPIO(void)
{
	FILE *gpio_file = NULL;
	uint32_t result = GPIO_ERR;
	uint8_t i = 0;

	/* Export gpio files */
	gpio_file = fopen(EXPORT_PATH, "w");
	if (gpio_file == NULL) {
		goto exit;
	}
	
	for (i = 0; i < 4; i++) {
		fseek(gpio_file,0,SEEK_SET);
		fprintf(gpio_file,"%u",exportTable[i]);
	}
    fflush(gpio_file);
	if(fclose(gpio_file) != 0) {
		goto exit;
	}
    /* All gpio files exported */

	/* Set direction on gpio */
	for (i = 0; i < 4; i++) {
		gpio_file = fopen(directionPaths[i], "w");
		if (gpio_file == NULL) {
			goto exit;
		}
		fseek(gpio_file,0,SEEK_SET);
		fprintf(gpio_file,"%s",directionTable[i]);
		fflush(gpio_file);
		if(fclose(gpio_file) != 0) {
			goto exit;
		}
	}
	/* Direction set */
	
	result = NO_ERR;
exit:
	return result;
}

/* Reads the current status of the button */
static uint32_t Read_Button(char *button_state)
{
	FILE *button_file = NULL;
	uint32_t result = BUTTON_ERR;
	
	/* open value file and read it */
	button_file = fopen(VALUE_BUTTON, "r");
	if (button_file == NULL) {
		goto exit;
	}
	fseek(button_file,0,SEEK_SET);
	fread(button_state, 1, 1, button_file);
	if(fclose(button_file) != 0) {
		goto exit;
	}
	/* value has been read */
	
	result = NO_ERR;
exit:
	return result;
}

/*	Updates the pins driving the RGB LED with the
	correct color according to the current status
	of the drivers */
uint32_t Write_LED(rgb_led_t rgb_led)
{
	FILE *led_file = NULL;
	uint32_t result = LED_ERR;
	uint8_t i = 0;

	switch(rgb_led) {
		case OFF:
			valueTable[0] = 0;	//Red
			valueTable[1] = 0;	//Green
			valueTable[2] = 0;	//Blue
			break;
		case RED:	//GREEN
			valueTable[0] = 1;	//Red
			valueTable[1] = 0;	//Green
			valueTable[2] = 0;	//Blue
			break;
		case GREEN:	//BLUE
			valueTable[0] = 0;	//Red
			valueTable[1] = 1;	//Green
			valueTable[2] = 0;	//Blue
			break;
		case BLUE:	//ALL OFF
			valueTable[0] = 0;	//Red
			valueTable[1] = 0;	//Green
			valueTable[2] = 1;	//Blue
			break;
		default:
			break;
	}
	
	for (i = 0; i < 3; i++) {
		led_file = fopen(valuePaths[i], "w");
		if (led_file == NULL) {
			goto exit;
		}
		fseek(led_file,0,SEEK_SET);
		fprintf(led_file,"%u",valueTable[i]);
		fflush(led_file);
		if(fclose(led_file) != 0) {
			goto exit;
		}
	}

	result = NO_ERR;
exit:
	return 0;
}

/* Polls the Button until it is pressed*/
//Temporarily disabled
uint32_t Button_Wait_To_Press(void)
{
	uint32_t result;
	char button_state;
	do{ 
		result = Read_Button(&button_state);
                button_state='1';
	} while(button_state != '1');
	
	return result;
}

/* Polls the Button until it is pressed*/
//Temporarily disabled
uint32_t Button_Wait_To_Release(void)
{
	uint32_t result;
	char button_state;
	while(button_state != '0'){
		Write_LED(BLUE);
		usleep(250*1000);
		Write_LED(OFF);
		usleep(250*1000);
		result = Read_Button(&button_state);
                button_state='0';
	};
	
	return result;
}