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
#define RintgrHALF		r7
#define RintgrFULL		r8
#define RintgrCHARGE	r9
#define RreadHALF		r10
#define RreadFULL		r11
#define RextraDelay		r12
#define	Rdonothing		r13

//GPIO
#define CLK			r30.t5
#define	SH			r30.t7

.macro INTdelayHALF
	MOV Rtemp, RintgrHALF
	SUB Rtemp, Rtemp, 3
	ADD Rtemp, Rtemp, 1
DELAY0:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY0, Rtemp, 0
.endm

.macro INTdelayFULLoff
	MOV Rtemp, RintgrFULL
	SUB Rtemp, Rtemp, 4
	ADD Rtemp, Rtemp, 1
DELAY1:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY1, Rtemp, 0
.endm

.macro INTdelayFULLon
	MOV Rtemp, RintgrFULL
	SUB Rtemp, Rtemp, 3
	ADD Rtemp, Rtemp, 1
DELAY2:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY2, Rtemp, 0
.endm

.macro INTdelayCHARGE	//Charge Transfer Time is the minimum time needed for the sampling capacitor
						//to charge to the voltage level of the integrating capacitor.
	MOV Rtemp, 1998		//20us
	ADD Rtemp, Rtemp, RintgrCHARGE
DELAY3:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY3, Rtemp, 0
.endm

.macro READdelayHALF0
	MOV Rtemp, RreadHALF
	SUB Rtemp, Rtemp, 3
	ADD Rtemp, Rtemp, 1
DELAY4:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY4, Rtemp, 0
.endm

.macro READdelayHALF1
	MOV Rtemp, RreadHALF
	SUB Rtemp, Rtemp, 4
	ADD Rtemp, Rtemp, 1
	ADD Rdonothing, Rdonothing, 0
DELAY5:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY5, Rtemp, 0
.endm

.macro READdelayFULLon
	MOV Rtemp, RreadFULL
	SUB Rtemp, Rtemp, 4
	ADD Rtemp, Rtemp, 1
	ADD Rdonothing, Rdonothing, 0
DELAY6:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY6, Rtemp, 0
.endm

.macro READdelayFULLoff0
	MOV Rtemp, RreadFULL
	SUB Rtemp, Rtemp, 3
	ADD Rtemp, Rtemp, 1
DELAY7:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY7, Rtemp, 0
.endm

.macro READdelayFULLoff1
	MOV Rtemp, RreadFULL
	SUB Rtemp, Rtemp, 4
	ADD Rtemp, Rtemp, 1
DELAY8:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY8, Rtemp, 0
.endm

.macro DelayPhase
	MOV Rtemp, RextraDelay
	SUB Rtemp, Rtemp, 6
	ADD Rtemp, Rtemp, 1
	ADD Rdonothing, Rdonothing, 0
DELAY9:
	SUB Rtemp, Rtemp, 1
	QBNE DELAY9, Rtemp, 0
.endm

//---------------------------------------------------------------------
//---------------------------------------------------------------------

INIT_PRU0:
	CLR SH						//SH pin = 0
	CLR CLK						//CLK pin = 0
	MOV Rdonothing, 0			//Register value init.
	MOV RreadHALF, 0			//Register value init.
	MOV r0, BRO_RAM				//Point to PRU1 RAM
	MOV Rtemp, SHARED_RAM		//Point to SHARED_RAM
	LBBO Rpixels, Rtemp, Pixels_Offset, 4	//Get the pixel count of the PDA.
	LBBO Rframescntr, Rtemp, Frames_Offset, 4	//Get the integration cycles.
	LBBO RintgrHALF, Rtemp, Intgr_Stage_Half_Offset, 4
	LBBO RintgrFULL, Rtemp, Intgr_Stage_Full_Offset, 4	//Get the calculated delay cycles for the integration stage.
	LBBO RintgrCHARGE, Rtemp, Intgr_Stage_Charge_Offset, 4
	LBBO RreadHALF, Rtemp, Read_Stage_Half_Offset, 4		//Get the calculated time for read stage.
	LBBO RreadFULL, Rtemp, Read_Stage_Full_Offset, 4		//Get the calculated time for read stage.
	LBBO RextraDelay, Rtemp, ExtraTime_Stage_Offset, 4 //Get the calculated cycles for extra time stage.
			
	MOV Rdata, 22522
	SBBO Rdata, Rtemp, Handshake_Offset, 4
HANDSHAKE:
	LBBO Rdata, Rtemp, Handshake_Offset, 4		//ARM HANDSHAKE
	QBNE HANDSHAKE, Rdata, 111					//Stay here until Rdata = 111.
	
	//MAIN_CODE_PRU0
MAIN_PRU0:
	//A.	Dummy "Clock Out" cycle.
	//		This Clock Out cycle will not be sampled, due to indeterminate data after power up.
	//		After 18 clock cycles the integration cycle for the next clock out cycle will begin.
	//INTdelayCHARGE				//We need this delay. 20.005us
	MOV Rpixelscntr, Rpixels
	SET SH
	INTdelayHALF
	SET CLK			
	INTdelayHALF
	CLR SH			
	INTdelayHALF
	CLR CLK
	ADD Rdonothing, Rdonothing, 0
	ADD Rdonothing, Rdonothing, 0
DummyLoop:
	INTdelayFULLoff
	SET CLK			
	INTdelayFULLon
	CLR CLK
	SUB Rpixelscntr, Rpixelscntr, 1
	QBNE DummyLoop, Rpixelscntr, 0
	INTdelayCHARGE
	

	//B.	Real "Clock Out" cycle.
	//		From this point on, every sample is saved and used.
	//		Data from the light sampled during one integration period is made avalaible
	//		on the AO during the next integration period.
	//		The PDA integrates the next period while it clocks out the previous.
	MOV Rpixelscntr, Rpixels 	//Inner Counter will count the pixels as they get clocked out.
	SET SH					//NEW CYCLE. Integration will begin after 18 clock cycles.
	READdelayHALF0				//Wait for a quarter of a period.
	SET CLK					
	MOV r31, 32 | 2			//Interrupt PRU1 in order to Sample.
	READdelayHALF1				//Wait for a quarter of a period.
	CLR SH					
	READdelayHALF0				//Wait for a quarter of a period.
	CLR CLK
	READdelayFULLoff0			//Wait for half a period.
REPEAT:
	SET CLK
	QBEQ SkipSample, Rpixelscntr, 1	//If Inner Counter = 1, Dont take sample. Its the n+1 clock which clocks out SH pulse.
	MOV r31, 32 | 2			//Interrupt PRU1 in order to Sample.
SkipSample:
	READdelayFULLon		//Wait for half a period.
	CLR CLK			//CLK = 0. After this instruction we are done with 1 sample out of 128 of the cycle.
	READdelayFULLoff1	//Wait half a period.
	SUB Rpixelscntr, Rpixelscntr, 1	//Decease inner counter.
	QBNE REPEAT, Rpixelscntr, 0		//If inner counter != 0 current cycle is not over.
	DelayPhase
	SUB Rframescntr, Rframescntr, 1	//Decrease outer counter.
	QBNE MAIN_PRU0, Rframescntr, 0	//If outer counter != 0 there is at least one more integration cycle so start again.
	
DONE:
	MOV Rdata, 55255				//END_CODE
	MOV Rtemp, SHARED_RAM
	SBBO Rdata, Rtemp, Handshake_Offset, 4
	HALT		//CPU stops working.