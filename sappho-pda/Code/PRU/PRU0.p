//PRU0 Code
//200MHz Clock | 1 Machine Cycle per instruction | 5ns per instruction | 100% Deterministic PRU.
//Original author:  Stratos Gkagkanis (GH: @StratosGK)
//Adapted for the S.AP.P.H.O. PDA by: Bantis Asterios (GH: @bandisast)


//                    +------------------------------------------------------------------------------------------------------+
//                    v                                                                                                      |
//+-----------+     +-----------+     +---------------+     +----------+     +--------------+     +------------------+     +-------------+     +------+
//| INIT_PRU0 | --> | MAIN_PRU0 | --> | DummyOutStart | --> | Sampling | --> | DummyOutLast | --> | WaitForNextFrame | --> | CheckFrames | --> | DONE |
//+-----------+     +-----------+     +---------------+     +----------+     +--------------+     +------------------+     +-------------+     +------+
//                                      ^           |         ^      |         ^          |         ^              |
//                                      +-----------+         +------+         +----------+         +--------------+


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
#define ExtraTime_Offset            16

//Registers
#define Rtemp			r1		//Temp register for any use.
#define Rdata			r2		//
#define RramPointer		r3		//Shared RAM pointer.
#define Rpixels			r4
#define Rpixelscntr		r5		//Inner Loop Counter (128 Samples from 1 Integration Cycle).
#define Rframescntr		r6		//Outer Loop Counter (Integration Cycles).
#define Rshtimer        r7      //Stores the number that Rshcntr will use to time the SH signal
#define Rrandom         r8      //Usad as a counter for pseudo-pixel loops (dummy outputs)
#define Rextratime      r9      //stores the number of clock cycles for the extra time between frames
#define Rextratimecntr  r10     //counts the number of clock cycles that passed during the extra time stage
#define	Rdonothing		r13     //Used as a delay() by repeatedly performing x <- x + 0
#define Rshcntr         r14     //SH timing counter

//GPIO
#define CLK			r30.t5 //P9_27
#define	SH			r30.t7 //P9_25
#define ICG         r30.t2 //P9_30

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

.macro CLOCK_FIX //add a delay of 10ns between CLOCK_RISING_EDGE AND CLOCK_FALLING_EDGE
//this will allow us to fit TWO instructions between clock pulses, if needed, without skewing the clock
    ADD Rdonothing, Rdonothing, 0
    ADD Rdonothing, Rdonothing, 0
.endm

.macro CLOCK_FALLING_EDGE_SH //clock = 0, then delay 980ns
    CLR CLK
	MOV Rtemp, 97 //980 ns delay 
DELAY3: 
	SUB Rtemp, Rtemp, 1 //This allows us to fit 4 instructions afterwards, rather than 2
	QBNE DELAY3, Rtemp, 0
.endm

.macro CLOCK_WAVE //a full 0.5MHz wave (2000ns)
    CLOCK_RISING_EDGE
    CLOCK_FIX 
    CLOCK_FALLING_EDGE
    CLOCK_FIX
.endm

.macro CLOCK_NO_OP_QUARTER_DELAY //490 ns delay, no operation
	MOV Rtemp, 48 //490 ns delay
DELAY4:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY4, Rtemp, 0
.endm

INIT_PRU0:
	CLR SH						//SH pin = 0
	CLR CLK						//CLK pin = 0
    SET ICG                     //ICG pin = 1
	MOV Rdonothing, 0			//Register value init.
	MOV r0, BRO_RAM				//Point to PRU1 RAM
	MOV Rtemp, SHARED_RAM		//Point to SHARED_RAM
	LBBO Rpixels, Rtemp, Pixels_Offset, 4	//Get the pixel count of the PDA.
	LBBO Rframescntr, Rtemp, Frames_Offset, 4	//Get the frame count
    LBBO Rshtimer, Rtemp, Integr_Time, 4 //Get how many clock cycles the period of the SH pulse will last
    LBBO Rextratime, Rtemp, ExtraTime_Offset, 4 //Get the extra time between each frame

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

 
    	//MAIN CODE PRU0
MAIN_PRU0:
//Initial SH / ICG pulses stage
    SET CLK
    CLR ICG //ICG start 
    CLOCK_RISING_EDGE
    CLOCK_FALLING_EDGE
    SET SH //SH t3 START
    MOV Rextratimecntr, Rextratime //Reset extra time counter

    CLOCK_RISING_EDGE
    LSR Rextratimecntr, Rextratimecntr, 1  //divide Rextratimecntr by 2, because the loops last 2 CLK pulses
    CLOCK_FALLING_EDGE
    CLR SH //SH t3 END -> 2000ns
    MOV Rrandom, 32  //32 dummy outputs in the beginning

    CLOCK_WAVE
    CLOCK_WAVE
    CLOCK_WAVE
    SET CLK   
    SET ICG //ICG STOP (t1+t3) | t1 ~ 6015ns
    CLOCK_RISING_EDGE
    CLOCK_FALLING_EDGE
    CLOCK_FIX
//ENTER SAMPLING STAGE
    CLOCK_RISING_EDGE
    MOV Rpixelscntr, Rpixels
    MOV Rshcntr, Rshtimer
    CLOCK_FALLING_EDGE
	LSR Rshcntr, Rshcntr, 1 //divide integration time by 2 because the sampling loops have two clock cycles
    SUB Rshcntr, Rshcntr, 3 //remove 3*2 clock cycles from SH counter


//   +-------------------------------------------+
//   |                                           v
// +----------------+     +--------------+     +----------------+
// | DummyOutStart1 | --> | DummyStartSH | --> | DummyOutStart2 |
// +----------------+     +--------------+     +----------------+
//      ^                                          |
//      +------------------------------------------+
//Loop between DummyOutStart1 and DummyOutStart2 until it's time for an SH pulse. If it's time, for an SH pulse, go to DummyOutSH.
DummyOutStart1:
    CLOCK_RISING_EDGE
    SUB Rshcntr, Rshcntr, 1
    QBEQ DummyOutSH, Rshcntr, 0
    CLOCK_FALLING_EDGE
    CLOCK_FIX
    CLOCK_RISING_EDGE
    CLOCK_FIX

DummyOutStart2:
    CLOCK_FALLING_EDGE_SH
    ADD Rdonothing, Rdonothing, 0
    SUB Rrandom, Rrandom, 1 //32 times for 32 dummy outputs
    CLR SH //keep SH low. Yes, I am overcomplicating the program for the sake of not being even 5ns off clock, m'kay. 
           //With so many pixels + pseudopixels in total, we could end up being even 100ns off by the time a frame ends!
    QBNE DummyOutStart1, Rrandom, 0

//   +-------------------------------------------+
//   |                                           v
// +---------------+     +------------+     +---------------+
// | SamplingLoop1 | --> | SamplingSH | --> | SamplingLoop2 |
// +---------------+     +------------+     +---------------+
//      ^                                          |
//      +------------------------------------------+
SamplingLoop1: 
    CLOCK_RISING_EDGE //almost the same loops as above, but with sampling enabled
    SUB Rshcntr, Rshcntr, 1
    QBEQ SamplingLoopSH, Rshcntr, 0
    CLOCK_FALLING_EDGE
    CLOCK_FIX 
    SET CLK //we sample every two CLK pulses
    CLOCK_NO_OP_QUARTER_DELAY
    MOV r31, 32 | 2	//interrupt PRU1 -> Request interrupt
    CLOCK_NO_OP_QUARTER_DELAY
    MOV Rrandom, 14 //Load the value of 14 pseudopixels for the DummyOutLast loops. Yes, this will run 1500 times, but there is no room to put it elsewhere without skewing the clock
    CLOCK_FIX 

SamplingLoop2:
    CLOCK_FALLING_EDGE_SH //similarly to DummyOutStart2, 1500 loops for 1500 pixels
    ADD Rdonothing, Rdonothing, 0
    SUB Rpixelscntr, Rpixelscntr, 1
    CLR SH
    QBNE SamplingLoop1, Rpixelscntr, 0

//   +-------------------------------------------+
//   |                                           v
// +---------------+     +-------------+     +---------------+
// | DummyOutLast1 | --> | DummyLastSH | --> | DummyOutLast2 |
// +---------------+     +-------------+     +---------------+
//      ^                                          |
//      +------------------------------------------+
DummyOutLast1:
    CLOCK_RISING_EDGE
    SUB Rshcntr, Rshcntr, 1
    QBEQ DummyLastSH, Rshcntr, 0
    CLOCK_FALLING_EDGE
    CLOCK_FIX
    CLOCK_RISING_EDGE
    CLOCK_FIX

DummyOutLast2:
    CLOCK_FALLING_EDGE_SH
    ADD Rdonothing, Rdonothing, 0
    SUB Rrandom, Rrandom, 1 //32 times for 32 dummy outputs
    CLR SH //keep SH low. Yes, I am overcomplicating the program for the sake of not being even 5ns off clock, m'kay. 
           //With so many pixels + pseudopixels in total, we could end up being even 100ns off by the time a frame ends!
    QBNE DummyOutLast1, Rrandom, 0

//Same panic, different disco. 
//   +-------------------------------------------+
//   |                                           v
// +-----------------+     +-------------+     +-----------------+
// | Wait4NextFrame1 | --> | WaitStageSH | --> | Wait4NextFrame2 |
// +-----------------+     +-------------+     +-----------------+
//      ^                                          |
//      +------------------------------------------+
WaitForNextFrame:
    CLOCK_RISING_EDGE
    SUB Rshcntr, Rshcntr, 1
    QBEQ WaitStageSH, Rshcntr, 0
    CLOCK_FALLING_EDGE
    CLOCK_FIX
    CLOCK_RISING_EDGE
    CLOCK_FIX

WaitForNextFrame2:
    CLR CLK
	MOV Rtemp, 96 //970 ns delay 
    DELAYFin: 
	    SUB Rtemp, Rtemp, 1 //This allows us to fit 4 instructions afterwards, rather than 2
	    QBNE DELAYFin, Rtemp, 0

    ADD Rdonothing, Rdonothing, 0
    SUB Rextratimecntr, Rextratimecntr, 1 //32 times for 32 dummy outputs
    QBEQ CheckFrames, Rextratimecntr, 0 //skip the next 3 instructions if it's time for the next frame (to prevent clock skew) and jump to CheckFrames
    ADD Rdonothing, Rdonothing, 0
    CLR SH //keep SH low. Yes, I am overcomplicating the program for the sake of not being even 5ns off clock, m'kay. 
           //With so many pixels + pseudopixels in total, we could end up being even 200ns off by the time a frame ends!
    QBNE WaitForNextFrame, Rextratimecntr, 0

//================================CHECK FRAMES================================
CheckFrames:
    SUB Rframescntr, Rframescntr, 1	//Decrease outer counter.
    CLR SH
    QBNE MAIN_PRU0, Rframescntr, 0	//If outer counter != 0 there is at least one more integration cycle so start again.
    
DONE:
	MOV Rdata, 55255				//END_CODE
	MOV Rtemp, SHARED_RAM
	SBBO Rdata, Rtemp, Handshake_Offset, 4
	HALT		//CPU stops working.

DummyOutSH:
    CLOCK_FALLING_EDGE_SH
    ADD Rdonothing, Rdonothing, 0
    MOV Rshcntr, Rshtimer   //reset SH counter
    SET SH
    LSR Rshcntr, Rshcntr, 1 //divide SH counter by 2

    CLOCK_RISING_EDGE 
    ADD Rdonothing, Rdonothing, 0
    JMP DummyOutStart2 //1000ns since SH
    

SamplingLoopSH:
    CLOCK_FALLING_EDGE_SH
    ADD Rdonothing, Rdonothing, 0
    MOV Rshcntr, Rshtimer   //reset SH counter
    SET SH
    LSR Rshcntr, Rshcntr, 1 //divide SH counter by 2

    SET CLK //we sample every two CLK pulses
    CLOCK_NO_OP_QUARTER_DELAY
    MOV r31, 32 | 2	//interrupt PRU1 -> Request interrupt
    CLOCK_NO_OP_QUARTER_DELAY
    CLOCK_FIX 
    JMP SamplingLoop2 //1000ns since SH

DummyLastSH:
    CLOCK_FALLING_EDGE_SH
    ADD Rdonothing, Rdonothing, 0
    MOV Rshcntr, Rshtimer   //reset SH counter
    SET SH
    LSR Rshcntr, Rshcntr, 1 //divide SH counter by 2

    CLOCK_RISING_EDGE 
    ADD Rdonothing, Rdonothing, 0
    JMP DummyOutLast2 //1000ns since SH

WaitStageSH:
    CLOCK_FALLING_EDGE_SH
    ADD Rdonothing, Rdonothing, 0
    MOV Rshcntr, Rshtimer   //reset SH counter
    SET SH
    LSR Rshcntr, Rshcntr, 1 //divide SH counter by 2

    CLOCK_RISING_EDGE 
    ADD Rdonothing, Rdonothing, 0
    JMP WaitForNextFrame2 //1000ns since SH
    