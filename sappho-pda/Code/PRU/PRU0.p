//PRU0 Code
//200MHz Clock | 1 Machine Cycle per instruction | 5ns per instruction | 100% Deterministic PRU.

.origin 0
.entrypoint INIT_PRU0
//Constants
#define PRU0_R31_VEC_VALID	32	//Output event to Linux Host
#define PRU_EVTOUT_0		3	//Event EVTOUT_0 means that the PRU program is almost over.
#define MY_RAM				0x00000000	//Current PRU RAM Address
#define BRO_RAM				0x00002000	//Others PRU RAM Address
#define SHARED_RAM			0x00010000	//Shared RAM Address

#define Pixels_Offset				0
#define Frames_Offset				4
#define Integr_Time		            8
#define Handshake_Offset			12

//Registers
#define Rtemp			r1		//Temp register for any use.
#define Rdata			r2		//
#define RramPointer		r3		//Shared RAM pointer.
#define Rpixels			r4
#define Rpixelscntr		r5		//Inner Loop Counter (128 Samples from 1 Integration Cycle).
#define Rframescntr		r6		//Outer Loop Counter (Integration Cycles).
#define Rshtimer 		r10
#define RintegrTime     r11
#define Rrandom         r12
#define	Rdonothing		r13

//GPIO
#define CLK			r30.t5 //P9_27
#define	SH			r30.t7 //P9_25
#define ICG         		r30.t2 //P9_30

//CLOCK: 0.5MHz <-> 2000ns
.macro CLOCK_RISING_EDGE //clock = 1, then delay 990ns
    SET CLK
	MOV Rtemp, 98 //990ns delay
DELAY1:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY1, Rtemp, 0
.endm

.macro CLOCK_FALLING_EDGE //clock = 0, then delay 990ns
    CLR CLK
	MOV Rtemp, 98 //990 ns delay
DELAY2:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY2, Rtemp, 0
.endm

.macro QuarterClockDelay //490ns
    ADD Rdonothing, Rdonothing, 0
    MOV Rtemp, 48 //490 ns delay
DELAY3:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY3, Rtemp, 0

.endm 

.macro CLOCK_FIX //add a delay of 10ns between CLOCK_FALLING_EDGE AND CLOCK_RISING_EDGE
//this will allow us to fit TWO instructions between clock pulses, if needed, without skewing the clock
    ADD Rdonothing, Rdonothing, 0
    ADD Rdonothing, Rdonothing, 0
.endm

.macro CLOCK_WAVE //a full 0.5MHz wave (2000ns)
    CLOCK_FALLING_EDGE
    CLOCK_FIX 
    CLOCK_RISING_EDGE
    CLOCK_FIX
.endm


INIT_PRU0:
	CLR SH						//SH pin = 0
	CLR CLK						//CLK pin = 0
    SET ICG                     //ICG pin = 1
	MOV Rdonothing, 0			//Register value init.

	MOV r0, BRO_RAM				//Point to PRU1 RAM
	MOV Rtemp, SHARED_RAM		//Point to SHARED_RAM
	LBBO Rpixels, Rtemp, Pixels_Offset, 4	//Get the pixel count of the PDA.
	LBBO Rframescntr, Rtemp, Frames_Offset, 4	//Get the integration cycles.
    	LBBO RintegrTime, Rtemp, Integr_Time, 4	//Get the calculated time for read stage.
			
	MOV Rdata, 22522
	SBBO Rdata, Rtemp, Handshake_Offset, 4
HANDSHAKE:
	LBBO Rdata, Rtemp, Handshake_Offset, 4		//ARM HANDSHAKE
	QBNE HANDSHAKE, Rdata, 111					//Stay here until Rdata = 111.

CLOCK_WAVE //a few clock pulses for initiation
CLOCK_WAVE
CLOCK_WAVE
CLOCK_WAVE
CLOCK_WAVE	


    	//MAIN CODE PRU0
MAIN_PRU0:
//Initial SH / ICG pulses stage
    SET CLK
    CLR ICG //ICG start 
    CLOCK_RISING_EDGE
    CLOCK_FALLING_EDGE
    SET SH //SH t3 START
    ADD Rdonothing, Rdonothing, 0
    CLOCK_WAVE
    CLOCK_RISING_EDGE
    CLOCK_FIX
    CLOCK_FALLING_EDGE
    CLR SH //SH t3 END -> 4000ns
    ADD Rdonothing, Rdonothing, 0    
    CLOCK_WAVE
    CLOCK_WAVE
    CLOCK_WAVE //t1 ~ 6000ns
    SET CLK
    SET ICG //ICG STOP (t1+t3)
    CLOCK_RISING_EDGE
    CLOCK_FALLING_EDGE
    CLOCK_FIX
//ENTER SAMPLING STAGE
    CLOCK_RISING_EDGE
    MOV Rpixelscntr, Rpixels
    MOV Rshtimer, RintegrTime
    CLOCK_FALLING_EDGE
    LSR Rshtimer, Rshtimer, 1 //divide integr. time by 2 because the loop takes 2 clock pulses
    MOV Rrandom, 32

//32 initial dummy outputs
DummyOutFirst:
    CLOCK_RISING_EDGE
    CLOCK_FIX
    CLOCK_FALLING_EDGE
    SUB Rrandom, Rrandom, 1 //sampling rate = 1 MHz
    ADD Rdonothing, Rdonothing, 0
    CLOCK_RISING_EDGE
    CLOCK_FIX
    CLOCK_FALLING_EDGE
    SUB Rshtimer, Rshtimer, 1 //remove 2 clock cycles from integration time
    QBNE DummyOutFirst, Rrandom, 0

SamplingInterrupt:
    CLOCK_RISING_EDGE
    CLOCK_FIX
    CLR CLK
    QuarterClockDelay
    MOV r31, 32 | 2	 //Interrupt PRU1 in order to Sample.
    SUB Rpixelscntr, Rpixelscntr, 1
    QuarterClockDelay
    CLOCK_RISING_EDGE
    MOV Rrandom, 14 //why waste time use many loop when few loop do trick
    //yes I know this is going to run 1500 times but it'll make the program slightly less complicated
    CLOCK_FALLING_EDGE
    SUB Rshtimer, Rshtimer, 1 //remove 2 clock cycles from integration time
    QBNE SamplingInterrupt, Rpixelscntr, 0

DummyOutLast:
    CLOCK_RISING_EDGE
    CLOCK_FIX
    CLOCK_FALLING_EDGE
    SUB Rrandom, Rrandom, 1
    ADD Rdonothing, Rdonothing, 0
    CLOCK_RISING_EDGE
    CLOCK_FIX
    CLOCK_FALLING_EDGE
    SUB Rshtimer, Rshtimer, 1 //remove 2 clock cycles from integration time
    QBNE DummyOutLast, Rrandom, 0

IntegrationWait: 
    CLOCK_WAVE //wait until t=integr_time - 2 CLK cycles
    CLOCK_RISING_EDGE
    CLOCK_FIX
    CLOCK_FALLING_EDGE
    SUB Rshtimer, Rshtimer, 1
    QBNE IntegrationWait, Rshtimer, 1 //wait until there are only 2 cycles left for the integration time

CheckFrames:
    CLOCK_RISING_EDGE
    CLOCK_FIX           //Check if there are more frames, without skewing the clock
    CLOCK_FALLING_EDGE
    SUB Rframescntr, Rframescntr, 1	//Decrease outer counter.
    QBNE MAIN_PRU0, Rframescntr, 0	//If outer counter != 0 there is at least one more integration cycle so start again.

DONE:
	MOV Rdata, 55255				//END_CODE
	MOV Rtemp, SHARED_RAM
	SBBO Rdata, Rtemp, Handshake_Offset, 4
	HALT		//CPU stops working.



