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

#include "sample_file.h"

static char file_name[50];
static int32_t file_number;
extern uint32_t sample_len;
extern uint16_t *ddr_casted;

extern double clkfreq;
extern uint16_t frames;
extern double intgr_time;
extern double fps;

uint32_t Create_File(void)
{
	uint32_t result = FOLDER_ERR;
	struct dirent *samples_entry;
	DIR *samples_dir;
	
	samples_dir = opendir(SAMPLES_PATH);
	if (samples_dir == NULL) {
		goto exit;
	}
	while((samples_entry = readdir(samples_dir)) != NULL)
	{
		if (strlen(samples_entry->d_name) > SAMPLES_NAME_LEN) {
			strncpy(file_name, samples_entry->d_name, SAMPLES_NAME_LEN);
			file_name[SAMPLES_NAME_LEN] = '\0';
			if (strcmp(file_name, SAMPLES_NAME) == 0) {
				strncpy(file_name, samples_entry->d_name+SAMPLES_NAME_LEN,11);
				file_name[5] = 0;
				if(strtol(file_name,NULL,10) > file_number) {
					file_number = strtol(file_name,NULL,10);
				}
			}
		}
	}
	closedir (samples_dir);
	sprintf(file_name, "%s%s%.5u.txt", SAMPLES_PATH, SAMPLES_NAME, (((uint32_t)file_number)+1));
	
	result = NO_ERR;
exit:
	return result;
}

uint32_t Save_Samples(void)
{
	uint32_t result = FILE_ERR;
	uint32_t i = 1500; //legit the only thing that actually worked for skipping the first frame is to pretend it doesn't exist. There is no war in Ba Sing Se.
	FILE *samples_file = fopen(file_name, "w");
	
	if (samples_file != NULL) {
		
		fprintf(samples_file, "Number of frames: %u\n", frames);
		fprintf(samples_file, "Integration time: %.2fus\n", intgr_time);
		fprintf(samples_file, "Frames per second: %.2f\n", fps);
		fprintf(samples_file, "CLK signal frequency: 500KHz");
		fprintf(samples_file, "==============================\n");
		
		for( i = 1500; i < (sample_len / 2); i++) {
			fprintf(samples_file, "%d\n", ddr_casted[i]);
		}
		
		if (fclose(samples_file) == 0 && ddr_casted[i] == END_OF_SAMPLES) {
			result = (uint32_t) (file_number+1);
		}
	}

	return result;
}
