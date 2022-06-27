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
#define Intgr_Stage_Half_Offset		8
#define Intgr_Stage_Full_Offset		12
#define Intgr_Stage_Charge_Offset	16
#define Read_Stage_Half_Offset		20
#define Read_Stage_Full_Offset		24
#define ExtraTime_Stage_Offset		28
#define Handshake_Offset			32

//Registers
#define Rtemp			r1		//Temp register for any use.
#define Rdata			r2		//
#define RramPointer		r3		//Shared RAM pointer.
#define Rpixels			r4
#define Rpixelscntr		r5		//Inner Loop Counter (128 Samples from 1 Integration Cycle).
#define Rframescntr		r6		//Outer Loop Counter (Integration Cycles).
#define RreadHALF		r10
#define RreadFULL		r11
#define	Rdonothing		r13

//GPIO
#define CLK			r30.t5 //P9_27
#define	SH			r30.t7 //P9_25
#define ICG         		r30.t2 //P9_30

//CLOCK: 2MHz <-> 500ns
.macro CLOCK_FALLING_EDGE //clock = 1, then delay 240ns
    CLR CLK
	MOV Rtemp, 24 //(24 * 2 + 2)(instructions) * 5 (ns/instruction) = 240ns delay
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
	MOV RreadHALF, 0			//Register value init.
	MOV r0, BRO_RAM				//Point to PRU1 RAM
	MOV Rtemp, SHARED_RAM		//Point to SHARED_RAM
	LBBO Rpixels, Rtemp, Pixels_Offset, 4	//Get the pixel count of the PDA.
	LBBO Rframescntr, Rtemp, Frames_Offset, 4	//Get the integration cycles.
	LBBO RreadHALF, Rtemp, Read_Stage_Half_Offset, 4		//Get the calculated time for read stage.
	LBBO RreadFULL, Rtemp, Read_Stage_Full_Offset, 4		//Get the calculated time for read stage.
			
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
//=========PDA-Initiation=========
//First pulse | ICG -> LOW | SH -> HIGH
//Pulse timing of ICG and SH
    MOV Rpixelscntr, 1500 
    CLR CLK //begin sampling cycle
    SET ICG //clear initiation gate
    CLOCK_NO_OP_QUARTER_DELAY //Time since FALLING edge: 125ns
    CLR SH //SH pin = 1
    CLOCK_NO_OP_QUARTER_DELAY //t2 (datasheet) = 125ns | Time since FALLING edge: 250ns
    CLOCK_RISING_EDGE 
    CLOCK_FIX //First pulse done (500ns)

    //SH -> LOW
    //t3 (shift pulse width) ~ 1000ns = 2CLK pulses
    CLOCK_WAVE
    CLOCK_WAVE
    CLR CLK
    SET SH //5ns
    CLOCK_FALLING_EDGE //240+5+5 (second CLR) = 250ns
    CLOCK_RISING_EDGE
    CLOCK_FIX 

    //ICG -> HIGH
    //t1 (icg pulse delay) ~ 4010ns = 10CLK pulses
    CLOCK_WAVE
    CLOCK_WAVE //1000ns
    CLOCK_WAVE
    CLOCK_WAVE //2000ns
    CLOCK_WAVE 
    CLOCK_WAVE //3000ns
    CLOCK_WAVE 
    CLOCK_WAVE //4000ns
    CLR CLK
    CLR ICG //CLR initiation gate | 4010ns | sampling start
    CLOCK_FALLING_EDGE //t4 (pulse timing of ICG and CLK) is OK.
    CLOCK_RISING_EDGE 
    MOV Rdonothing, 31 
    ADD Rdonothing, Rdonothing, 0 //4500ns
DummyOutFirstLoop:
    CLOCK_FALLING_EDGE //These outputs do not contain meaningful data
    CLOCK_FIX       //This loop just ignores them while still producing a CLK pulse
    CLOCK_RISING_EDGE
    SUB Rdonothing, Rdonothing, 1
    QBNE DummyOutFirstLoop, Rdonothing, 0 //31 (+1 outside the loop) CLK pulses for trash data

SamplingLoop:
    CLR CLK
    MOV r31, 32 | 2	 //Interrupt PRU1 in order to Sample.
    CLOCK_FALLING_EDGE 
    CLOCK_RISING_EDGE
    SUB Rpixelscntr, Rpixelscntr, 1
    QBNE SamplingLoop, Rpixelscntr, 0 //1500 CLK pulses for effective outputs

PreDummyOutLast:
    CLR CLK
    MOV Rdonothing, 13 //just to CLR the timer without skewing the clock
    CLOCK_FALLING_EDGE //1 of 14 dummy outputs with trash data
    CLOCK_RISING_EDGE
    CLOCK_FIX

DummyOutLastLoop:
    CLOCK_FALLING_EDGE //These outputs do not contain meaningful data
    CLOCK_FIX       //This loop just ignores them while still producing a CLK pulse
    CLOCK_RISING_EDGE
    SUB Rdonothing, Rdonothing, 1
    QBNE DummyOutLastLoop, Rdonothing, 0 //31 (+1 outside the loop) CLK pulses for trash data

CheckFrames:
    CLOCK_FALLING_EDGE
    CLOCK_FIX           //Ccheck if there are more frames, without skewing the clock
    CLOCK_RISING_EDGE
    SUB Rframescntr, Rframescntr, 1	//Decrease outer counter.
    QBNE MAIN_PRU0, Rframescntr, 0	//If outer counter != 0 there is at least one more integration cycle so start again.

DONE:
	MOV Rdata, 55255				//END_CODE
	MOV Rtemp, SHARED_RAM
	SBBO Rdata, Rtemp, Handshake_Offset, 4
	HALT		//CPU stops working.




