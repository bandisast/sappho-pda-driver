//PRU1 Code
//200MHz Clock | 1 Machine Cycle per instruction | 5ns per instruction | Nondeterministic PRU.
//Original author:  Stratos Gkagkanis (GH: @StratosGK)
//Adapted for the S.AP.P.H.O. PDA by: Bantis Asterios (GH: @bandisast) 

.origin 0
.entrypoint INIT_PRU1
//Constants
#define IRQSTATUS_RAW		0x44E0D024
#define IRQSTATUS			0x44E0D028
#define IRQENABLE_SET		0x44E0D02C
#define CTRL 				0x44E0D040
#define ADC_CLKDIV			0x44E0D04C
#define STEPCONFIG1 		0x44E0D064
#define STEPDELAY1			0x44E0D068
#define STEPENABLE			0x44E0D054
#define FIFO0COUNT			0x44E0D0E4
#define FIFO0THRESHOLD		0x44E0D0E8
#define FIFO0DATA			0x44E0D100

#define ADC_EVT_CAPT		0x44E10FD8

#define PRU1_R31_VEC_VALID	32	//Output event to Linux Host.
#define PRU_EVTOUT_1		4	//
//RAM ADDRESSES & OFFSETS
#define MY_RAM				0x00000000	//Current PRU RAM Address
#define BRO_RAM				0x00002000	//Others PRU RAM Address
#define SHARED_RAM			0x00000100	//Shared RAM Address
#define Handshake_Offset	20
#define DDR_Addr_Offset		24
#define DDR_Size_Offset		28

//Registers
#define Rtemp			r1		//Temp register for any use.
#define Rdata			r2		//
#define RramPointer		r3		//Shared RAM pointer.
#define Rpixelscntr		r4		//Inner Loop Counter (1500 Samples from 1 Integration Cycle)
#define Rframescntr		r5		//Outer Loop Counter (Integration Cycles)
#define Rddr			r6
#define Rbytes2write	r7
//GPIO
#define	DEBUG_PIN		r30.t13

#define GER_REG			0x0010
#define SICR_REG		0x0024		//INDEX__Clears the status of an interrupt. Clears Raw Status. bits 0 - 9
#define SECR0_REG		0x0280		//Show the pending enabled status of the system interrupts 0 o 31. Interrupt per bit.
#define SECR1_REG		0x0284
#define CMR13_REG		0x0434
#define CMR0_REG		0x0400
#define CMR4_REG		0x0410
#define ESR0_REG		0x0300
#define ESR1_REG		0x0304
#define EISR_REG		0x0028
#define SITR0_REG		0x0D80
#define ADCSTAT			0x0044
#define SRSR0_REG		0x0200
#define SRSR1_REG		0x0204

.macro SHORTdelay	
	LDI Rtemp, 40			//1 = 10ns
	delay0:					//405ns delay
	SUB Rtemp, Rtemp, 1
	QBNE delay0, Rtemp, 0
.endm

.macro SlewRateDelay	
	LDI Rtemp, 9			//2 * 5ns * Rtemp + 5 = Delay in ns.
	delay1:					//95ns delay
	SUB Rtemp, Rtemp, 1		
	QBNE delay1, Rtemp, 0
.endm

INIT_PRU1:
	CLR DEBUG_PIN	//Only for Debug
	
	LBCO r0, C4, 4, 4			//Enable OCP master port.
	CLR r0, r0, 4				//Clear bit STANDBY_INIT so PRU0 can access L3.
	SBCO r0,C4, 4, 4			//After this instruction, PRU0 will be able to access the L3.
	
	LDI Rtemp.w0, 0x2C
	MOV Rdata, 0
	SBCO Rdata, c4, Rtemp.w0, 1
	
	//CONTROL MODULE -> ADC_EVT_CAPT = pr1_host_intr0
	MOV Rtemp, ADC_EVT_CAPT
	MOV Rdata.b0, 0
	SBBO Rdata.b0, Rtemp, 0, 1
	
	//DISABLE INTERRUPTS (ALL PRUSS INTERRUPTS DISABLED)
	MOV Rtemp, 0x00000000
    SBCO Rtemp.b0, c0, GER_REG, 1
	
	//ADC START CONV INTERRUPT SETUP
	//Enable SYS_16
    LDI Rtemp.w0, EISR_REG
	MOV Rdata.w0, 16
	SBCO Rdata.w0, c0, Rtemp.w0, 2
	//CLR SYS_16
	LDI Rtemp.w0, SICR_REG
	LDI Rdata.w2, 0x0000
	LDI Rdata.w0, 16
	SBCO Rdata, c0, Rtemp.w0, 4
	//SYS_16 -> CHANNEL 2
    LDI Rtemp.w0, CMR4_REG
	MOV Rdata.b0, 2
	SBCO Rdata.b0, c0, Rtemp.w0, 1
	
	//ADC CONV DONE INTERRUPT SETUP
	// Enable SYS_53
    LDI Rtemp.w0, EISR_REG
	MOV Rdata.w0, 53
	SBCO Rdata.w0, c0, Rtemp.w0, 2
	// SYS_53 -> CHANNEL 1
    LDI Rtemp.w0, CMR13_REG	+ 1	 	//+1 IS FOR SYSTEM EVENT 53
	MOV Rdata.b1, 1					//CHANNEL 1
	SBCO Rdata.b1, c0, Rtemp.w0, 1

	//ADC MODULE SETUP
	MOV Rtemp, CTRL				//CTRL REGISTER
    MOV Rdata, 0x00000004		//Step Config Enabled, ADC is not active yet.
    SBBO Rdata, Rtemp, 0, 4	
	MOV Rtemp, ADC_CLKDIV		//ADC_CLKDIV REGISTER
    MOV Rdata, 0x00000000		//ADC CLOCK = 24MHz
    SBBO Rdata, Rtemp, 0, 4	
	MOV Rtemp, STEPCONFIG1		//STEPCONFIG1 REGISTER
    MOV Rdata, 0x00000003		//Step1 Mode = HW sync contin, Averaging = 0
    SBBO Rdata, Rtemp, 0, 4
	MOV Rtemp, STEPDELAY1		//STEPDELAY1 REGISTER
    MOV Rdata, 0x00000000		//SampleDelay = 0 // OpenDelay = 0
    SBBO Rdata, Rtemp, 0, 4
	MOV Rtemp, FIFO0THRESHOLD	//FIFO0THRESHOLDREGISTER
    MOV Rdata, 0x00000000		//Threshold = 1 (value - 1)
    SBBO Rdata, Rtemp, 0, 4
	MOV Rtemp, IRQENABLE_SET	//IRQENABLE_SET REGISTER
    MOV Rdata, 0x00000004		//FIFO0_THRESHOLD = 1
    SBBO Rdata, Rtemp, 0, 4
	
	//ADC INTERRUPT FLAG CLEARING
	MOV Rtemp, IRQSTATUS		//FIFO0_THRESHOLD FLAG CLEARING.
	LDI Rdata.w2, 0x0000
	LDI Rdata.w0, 0x0004
	SBBO Rdata, Rtemp, 0, 4
	LDI Rtemp.w0, SICR_REG		//ADC CONV DONE INTERRUPT CLEARING.
	LDI Rdata.w2, 0x0000
	LDI Rdata.w0, 53
	SBCO Rdata, c0, Rtemp.w0, 4
	
	MOV Rtemp, CTRL				//CTRL REGISTER
    MOV Rdata, 0x00000101		//TSC_ADC_SS ENABLED  & hw_event_mapping = HW event input
    SBBO Rdata, Rtemp, 0, 4		//ADC MODULE IS NOW ACTIVE!!!!
	
	MOV Rtemp, STEPENABLE		//STEPENABLE REGISTER
    MOV Rdata, 0x00000002		//STEP1 ENABLED
	SBBO Rdata, Rtemp, 0, 1		//ADC CONVERSION WILL TRIGGER WHEN HW EVENT HAPPENS.
	
	//ENABLE INTERRUPTS	(ALL PRUSS INTERRUPTS ENABLED)
	MOV Rtemp, 0x00000001
    SBCO Rtemp.b0, c0, GER_REG, 1
	
	//SHARED RAM ADDRESSING & CRITICAL DATA READ
	MOV r0, SHARED_RAM			//Points the address 0x0001_0000 (12KB Shared Data Ram )
	MOV Rtemp, 0x24028			//Points CTPPR0 register of PRU1.
	SBBO r0, Rtemp, 0, 4		//CTPPR0 = 0x100 = C28 points the Shared Data Ram.
	LBCO Rddr, c28, DDR_Addr_Offset, 4			//DDR ADDRESS POINTER
	LBCO Rbytes2write, c28, DDR_Size_Offset, 4	//ARRAY SIZE
	
	LDI Rpixelscntr, 0
	
	//===============================================
	//HANDSHAKE CODE
	MOV r31.b0, PRU1_R31_VEC_VALID | PRU_EVTOUT_1
	MOV Rtemp, 0x00000000
HANDSHAKE:
	LBCO Rtemp, c28, Handshake_Offset, 4
	QBNE HANDSHAKE, Rtemp, 222
	
MAIN_PRU1:
	CLR DEBUG_PIN	//Only for Debug
	WBS r31.t30		//HOST 0 INTERRUPT POLLING (PRU0 SIGNAL)

	//SYS_18 (HOST 0) INTERRUPT CLEARING
	LDI Rtemp.w0, SICR_REG
	LDI Rdata.w2, 0x0000
	LDI Rdata.w0, 18
	SBCO Rdata, c0, Rtemp.w0, 4
		
	SHORTdelay		//DELAY FOR INTERRUPT LATENCY
	SlewRateDelay
	SET DEBUG_PIN
	
	MOV r31, 32		//SYS_16 -> TRIGGER ADC CONVERSION
	//SYS_16 (ADC CONV) INTERRUPT CLEARING
	LDI Rtemp.w0, SICR_REG
	LDI Rdata.w2, 0x0000
	LDI Rdata.w0, 16
	SBCO Rdata, c0, Rtemp.w0, 4	
		
	WBS r31.t31		//HOST 1 INTERRUPT POLLING (ADC_CONV DONE SIGNAL)
	//READ ADC CONVERSION RESULT
	MOV Rtemp, FIFO0DATA		
    LBBO Rdata, Rtemp, 0, 2		//Read ADC Sample.
	SBBO Rdata, Rddr, 0, 2		//Write Sample to DDR.
	ADD Rddr, Rddr, 2
	
	//CLEAR ADC_CONV_DONE FLAG
	SHORTdelay
	MOV Rtemp, IRQSTATUS
	LDI Rdata.w2, 0x0000
	LDI Rdata.w0, 0x0004
	SBBO Rdata, Rtemp, 0, 4
	//CLEAR ADC_CONV_DONE INTERRUPT
	SHORTdelay
	LDI Rtemp.w0, SICR_REG
	LDI Rdata.w2, 0x0000
	LDI Rdata.w0, 53
	SBCO Rdata, c0, Rtemp.w0, 4
		
	//DECREASE LOOP COUNTER & CHECK IF DONE.
	SUB Rbytes2write, Rbytes2write, 2
	QBNE MAIN_PRU1, Rbytes2write, 0
DONE:
	MOV Rtemp, 59595
	SBBO Rtemp, Rddr, 0, 2
	CLR DEBUG_PIN	//Only for Debug
	MOV r31.b0, PRU1_R31_VEC_VALID | PRU_EVTOUT_1	//Send event to Linux.
	HALT	