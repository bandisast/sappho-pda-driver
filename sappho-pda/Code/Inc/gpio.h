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
****************************************************/

#include "pda_drivers.h"

/*************/
/* Variables */
/*************/
typedef enum rgb_led_t{
	OFF = 0,
	RED,
	GREEN,
	BLUE,
}rgb_led_t;

extern uint32_t Init_GPIO(void);
extern uint32_t Button_Wait_To_Press(void);
extern uint32_t Button_Wait_To_Release(void);
extern uint32_t Write_LED(rgb_led_t rgb_led);

/**********/
/* MACROS */
/**********/

/* PATHS */
#define EXPORT_PATH			"/sys/class/gpio/export"

#define DIRECTION_BUTTON	"/sys/class/gpio/gpio60/direction"
#define DIRECTION_LED_R		"/sys/class/gpio/gpio26/direction"
#define DIRECTION_LED_G		"/sys/class/gpio/gpio47/direction"
#define DIRECTION_LED_B		"/sys/class/gpio/gpio46/direction"

#define VALUE_BUTTON		"/sys/class/gpio/gpio60/value"
#define VALUE_LED_R			"/sys/class/gpio/gpio26/value"
#define VALUE_LED_G			"/sys/class/gpio/gpio47/value"
#define VALUE_LED_B			"/sys/class/gpio/gpio46/value"

/* BUTTON FUNCTIONALITY */
#define BUTTON_PRESSED "1"
#define BUTTON_RELEASED "0"