//PRU0 Code
//200MHz Clock | 1 Machine Cycle per instruction | 5ns per instruction | 100% Deterministic PRU.
//Original author:  Stratos Gkagkanis (GH: @StratosGK)
//Adapted for the S.AP.P.H.O. PDA by: Bantis Asterios (GH: @bandisast)

//                    +------------------------------------------------------------------------------------------------------+
//                    v                                                                                                      |
//+-----------+     +-----------+     +----------------+     +-------------+     +---------------+     +-------------+     +-----------------+     +------+
//| INIT_PRU0 | --> | MAIN_PRU0 | --> | icg_init loops | --> | DummyLoops1 | --> | SamplingLoops | --> | DummyLoops2 | --> | FrameCheckLoops | --> | DONE |
//+-----------+     +-----------+     +----------------+     +-------------+     +---------------+     +-------------+     +-----------------+     +------+
//                                      ^            |         ^         |         ^           |         ^         |         ^             |
//                                      +------------+         +---------+         +-----------+         +---------+         +-------------+

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
#define Rshtimer        r7      //Stores the number that Rshcntr will use to time the SH signal
#define	Rdonothing		r13     //Used both as a delay() by repeatedly performing x <- x + 0, and as a counter for loops
#define Rshcntr         r14     //SH timing counter

//GPIO
#define CLK			r30.t5 //P9_27
#define	SH			r30.t7 //P9_25
#define ICG         r30.t2 //P9_30

//CLOCK: 2MHz <-> 500ns
.macro CLOCK_FALLING_EDGE //clock = 1, then delay 240ns
    CLR CLK
	MOV Rtemp, 24 //((24-1) * 2 + 2)(instructions) * 5 (ns/instruction) = 240ns delay
DELAY1:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY1, Rtemp, 0
.endm

.macro CLOCK_RISING_EDGE //clock = 0, then delay 240ns
    SET CLK
	MOV Rtemp, 24 //240 ns delay
DELAY2:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY2, Rtemp, 0
.endm

.macro CLOCK_FIX //add a delay of 10ns between CLOCK_FALLING_EDGE AND CLOCK_RISING_EDGE
//this will allow us to fit TWO instructions between clock pulses, if needed, without skewing the clock
    ADD Rdonothing, Rdonothing, 0
    ADD Rdonothing, Rdonothing, 0
.endm

.macro CLOCK_WAVE //a full 2MHz wave (500ns)
    CLOCK_FALLING_EDGE
    CLOCK_FIX 
    CLOCK_RISING_EDGE
    CLOCK_FIX
.endm

.macro CLOCK_NO_OP_QUARTER_DELAY //120ns delay, no operation
	MOV Rtemp, 12 //120 ns delay
DELAY3:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY2, Rtemp, 0
.endm

INIT_PRU0:
	SET SH						//SH pin = 0
	SET CLK						//CLK pin = 0
    CLR ICG                     //ICG pin = 1
	MOV Rdonothing, 0			//Register value init.
	MOV r0, BRO_RAM				//Point to PRU1 RAM
	MOV Rtemp, SHARED_RAM		//Point to SHARED_RAM
	LBBO Rpixels, Rtemp, Pixels_Offset, 4	//Get the pixel count of the PDA.
	LBBO Rframescntr, Rtemp, Frames_Offset, 4	//Get the integration cycles.
    LBBO Rshtimer, Rtemp, Integr_Time, 4
			
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
//================PDA INITIATION================
//First pulses | ICG -> LOW | SH -> HIGH

//Pulse 1:
//Pulse timing of ICG and SH
    CLR CLK //first pulse start
    SET ICG //clear integration gate
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE 
    MOV Rdonothing, 9 //For pulses after t2
    MOV Rpixelscntr, 1500  //first pulse end

//Pulse 2:
    CLR CLK
    CLR SH //SH --> HIGH | 500ns after ICG (t2, datasheet)
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE
    MOV Rshcntr, Rshtimer
    SUB Rshcntr, Rshcntr, 11 //SH timer - 5500ns to keep the signal in phase after ICG goes up

//Pulse 3:
    CLOCK_WAVE

//Pulse 4:
    CLR CLK
    SET SH //t3 = 1000ns
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE
    CLOCK_FIX

//Pulses until ICG -> HIGH
icg_init:
    CLOCK_FALLING_EDGE 
    CLOCK_FIX
    CLOCK_RISING_EDGE
    SUB Rdonothing, Rdonothing, 1 
    QBNE icg_init, Rdonothing, 0 //loop until enough clock cycles pass, to change the integration time

icg_init_after:
//ICG -> HIGH
    CLR CLK
    //At this point, t1=5000
    CLR ICG
    CLOCK_FALLING_EDGE
    CLOCK_RISING_EDGE
    LDI Rdonothing, 30 //30 (+2 outside the loop) SH pulses for trash data
    ADD Rdonothing, Rdonothing, 0

//================FIRST DUMMY OUTPUTS================


//  +--------------------------------------------------+
//  v                                                  | (cur. pixel <=32)
//+-------------------+     +------------------+     +--------------------+     +--------------+
//| DummyOutFirstLoop | --> | DummyOutFirst_SH | --> | Check pixel number | --> | SamplingLoop |
//+-------------------+     +------------------+     +--------------------+     +--------------+

// Produce CLK pulses         SH pin "on" time             Loopy loop            Actual samples

DummyOutFirstLoop:
    CLOCK_FALLING_EDGE   //These outputs do not contain meaningful data 
    SUB Rshcntr, Rshcntr, 1  //This loop just ignores them while still producing a SH pulse
    SUB Rdonothing, Rdonothing, 1
    CLOCK_RISING_EDGE
    ADD Rdonothing, Rdonothing, 0 
    QBNE DummyOutFirstLoop, Rshcntr, 0 //loop until it's time for the next SH pulse

//DummyOutFirst_SH Lasts 3 clock cycles
DummyOutFirst_SH:
    CLR CLK
    CLR SH //t3 start
    CLOCK_FALLING_EDGE
    CLOCK_RISING_EDGE
    MOV Rshcntr, Rshtimer
    ADD Rdonothing, Rdonothing, 0 

    CLOCK_WAVE

    CLR CLK
    SET SH //t3 = 1000ns
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE
    ADD Rdonothing, Rdonothing, 0 
    QBNE DummyOutFirstLoop, Rdonothing, 0 //30 (+2 outside the loop) SH pulses for trash data


//================SAMPLING================

//  +--------------------------------------------+
//  v                                            | (cur. pixel >32 && <=1500+32)
//+--------------+     +-----------------+     +--------------------+     +-----------------+
//| SamplingLoop | --> | SamplingLoop_SH | --> | Check pixel number | --> | PreDummyOutLast |
//+--------------+     +-----------------+     +--------------------+     +-----------------+

SamplingLoop:
    CLOCK_FALLING_EDGE   //basically almost the same loop as above
    SUB Rshcntr, Rshcntr, 1  
    SUB Rpixelscntr, Rpixelscntr, 1
    CLOCK_RISING_EDGE
    ADD Rdonothing, Rdonothing, 0 
    QBNE SamplingLoop, Rshcntr, 0 //loop until it's time for the next SH pulse

SamplingLoop_SH:
    CLR CLK
    CLR SH
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE
    MOV r31, 32 | 2	 //Interrupt PRU1 in order to Sample.
    MOV Rshcntr, Rshtimer

    CLOCK_WAVE

    CLR CLK
    SET SH //t3 = 1000ns
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE
    SUB Rpixelscntr, Rpixelscntr, 1
    QBNE SamplingLoop, Rpixelscntr, 0 //1500 CLK pulses for effective outputs


//================================LAST DUMMY OUTPUTS================================

//  +-----------------------------------------------+
//  v                                               |
//+-----------------+     +-----------------+     +--------------------+     +----------------+
//| PreDummyOutLast | --> | DummyOutLast_SH | --> | Check pixel number | --> | PreCheckFrames |
//+-----------------+     +-----------------+     +--------------------+     +----------------+

PreDummyOutLast:
    CLR CLK
    MOV Rdonothing, 13 //just to set the timer without skewing the clock
    CLOCK_FALLING_EDGE //1 of 14 dummy outputs with trash data
    CLOCK_RISING_EDGE

DummyOutLastLoop:
    CLOCK_FALLING_EDGE   //These outputs do not contain meaningful data 
    SUB Rshcntr, Rshcntr, 1  //This loop just ignores them while still producing a SH pulse
    SUB Rdonothing, Rdonothing, 1
    CLOCK_RISING_EDGE
    ADD Rdonothing, Rdonothing, 0 
    QBNE DummyOutLastLoop, Rshcntr, 0 //loop until it's time for the next SH pulse

DummyOutLast_SH:
    CLR CLK
    CLR SH //t3 start
    CLOCK_FALLING_EDGE
    CLOCK_RISING_EDGE
    MOV Rshcntr, Rshtimer
    ADD Rdonothing, Rdonothing, 0 

    CLOCK_WAVE

    CLR CLK
    SET SH //t3 = 1000ns
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE
    ADD Rdonothing, Rdonothing, 0 
    QBNE DummyOutLastLoop, Rdonothing, 0 //13 (+1 outside the loop) SH pulses for trash data


//================================WAIT ONE FULL SH SIGNAL PERIOD UNTIL FRAME CHECK================================

//   +----------------------+
//   v                      |
//  +----------------+     +-------------------------------------------------+     +-------------+     +------+
//  | PreCheckFrames | --> | PreCheckFrames2 (and CycleEnd_SH for same T_sh) | --> | CheckFrames | --> | DONE |
//  +----------------+     +-------------------------------------------------+     +-------------+     +------+
//                                                                                      |
//                                                                                      |
//                                                                                      v
//                                                                                 +-------------+
//                                                                                 |  MAIN_PRU0  |
//                                                                                 +-------------+


PreCheckFrames:
    CLOCK_FALLING_EDGE
    CLOCK_FIX           //Check if there are more frames, without skewing the clock
    SET CLK
	MOV Rtemp, 23 //230 ns delay
DELAY2:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY2, Rtemp, 0 //room for 4 instructions after this part

PreCheckFrames2:
    SUB Rshcntr, Rshcntr, 1
    QBNE CycleEnd_SH, Rshcntr, 0 //jump to CycleEnd_SH every loop, until it's time for SH


//================================CHECK FRAMES================================
CheckFrames:
    SUB Rframescntr, Rframescntr, 1	//Decrease outer counter.
    QBNE MAIN_PRU0, Rframescntr, 0	//If outer counter != 0 there is at least one more integration cycle so start again.

DONE:
	MOV Rdata, 55255				//END_CODE
	MOV Rtemp, SHARED_RAM
	SBBO Rdata, Rtemp, Handshake_Offset, 4
	HALT		//CPU stops working.

CycleEnd_SH:
    ADD Rdonothing, Rdonothing, 0 //Remaining 2 free instructions after PreCheckFrames2
    JMP PreCheckFrames
