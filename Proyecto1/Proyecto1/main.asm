/*

Proyecto1.asm

Created: 3/7/2025 3:23:41 PM
Author : Adrián Fernández

Descripción:
	
*/
.include "M328PDEF.inc"		// Include definitions specific to ATMega328P

// Definiciones de registro, constantes y variables

.equ		MAX_VAL_0 = 178
.equ		MAX_VAL_1 = 3036

.def		D_UNI_MIN  = R2
.def		D_DEC_MIN  = R3
.def		D_UNI_HORA = R4
.def		D_DEC_HORA = R5
.def		D_UNI_DIA  = R6
.def		D_DEC_DIA  = R7
.def		D_UNI_MES  = R8
.def		D_DEC_MES  = R9
.def		D_UNI_MIN_ALRM = R10
.def		D_DEC_MIN_ALRM = R11
.def		D_UNI_HORA_ALRM = R12
.def		D_DEC_HORA_ALRM = R13

.def		MUX = R22
.def		MODO = R23
.def		ESTADO = R24

.def		NUM_DIAS = R25

.dseg
.org		SRAM_START
UNI_MIN:	.byte	1
DEC_MIN:	.byte	1
UNI_HORA:	.byte	1
DEC_HORA:	.byte	1
UNI_DIA:	.byte	1
DEC_DIA:	.byte	1
UNI_MES:	.byte	1
DEC_MES:	.byte	1
UNI_MIN_ALRM:	.byte	1
DEC_MIN_ALRM:	.byte	1
UNI_HORA_ALRM:	.byte	1
DEC_HORA_ALRM:	.byte	1

.cseg
.org		0x0000			// Se dirigen el inicio
	JMP		START

.org		PCI0addr		// Se dirigen las interrupciones del pinchange
	JMP		BOTONES

.org		OVF1addr		// Se dirigen las interrupciones del timer1
	JMP		OVER_TIMER1

.org		OVF0addr		// Se dirigen las interrupciones del timer0
	JMP		OVER_TIMER0

TABLA7SEG: .DB	0x7E, 0x30, 0x6D, 0x79, 0x33, 0x5B, 0x5F, 0x70, 0x7F, 0x7B, 0x77, 0x4F, 0x4E, 0x6D, 0x4F, 0x47
//				0,    1,    2,    3,    4,    5,    6,    7,    8,    9,    A,    B,    C,    D,    E,    F

// Configuración de la pila
START:
	LDI		R16, LOW(RAMEND)
	OUT		SPL, R16
	LDI		R16, HIGH(RAMEND)
	OUT		SPH, R16

// Configuración del MCU
SETUP:
	// Desavilitamos interrupciones mientras seteamos todo
	CLI
	CALL	OVER

	// Configurar Prescaler "Principal"
	LDI		R16, (1 << CLKPCE)
	STS		CLKPR, R16		// Habilitar cambio de PRESCALER
	LDI		R16, 0x04
	STS		CLKPR, R16		// Configurar Prescaler a 16 F_cpu = 1MHz

	// Inicializar timers
	CALL	INIT_TMR1
	CALL	INIT_TMR0

	// Interrupciones de botones
	// Habilitamos interrupcionees para el PCIE0
	LDI		R16, (1 << PCINT0) | (1 << PCINT1) | (1 << PCINT2) | (1 << PCINT3)
	STS		PCMSK0, R16
	// Habilitamos interrupcionees para cualquier cambio logico
	LDI		R16, (1 << PCIE0)
	STS		PCICR, R16

	// Interrupciones de los timer
	// Habilitamos interrupcionees para el timer0
	LDI		R16, (1 << TOIE0)
	STS		TIMSK0, R16

	// Habilitamos interrupcionees para el timer1
	LDI		R16, (1 << TOIE1)
	STS		TIMSK1, R16

	// PORTB como entrada con pull-up habilitado
	LDI		R16, 0x30	
	OUT		DDRB, R16		// Setear puerto B como entrada
	LDI		R16, 0x0F
	OUT		PORTB, R16		// Habilitar pull-ups en puerto B

	// Configurar puerto C como una salida
	LDI		R16, 0xFF
	OUT		DDRC, R16		// Setear puerto C como salida

	// Configurar puerto D como una salida
	LDI		R16, 0xFF
	OUT		DDRD, R16		// Setear puerto D como salida

	// Realizar variables
	LDI		R16, 0x00		// Multiple uso
	LDI		R17, 0x00		// Comparaciones
	LDI		R18, 0x00		// Lectura de botones
	LDI		R19, 0x00		// Incrementos del timer
	LDI		R20, 0x00		// Overflow timer1
	LDI		R21, 0x00		// Contador timer0
	LDI		R22, 0xF0		// MUX
	LDI		R23, 0x00		// MODO
	LDI		R24, 0x00		// ESTADO
	LDI		R25, 0x00		// Número de días
	LDI		R26, 0x00		// Estado de la alarma

	LDI     R16, 0x00
	STS     UNI_MIN, R16
	STS     DEC_MIN, R16
	STS     UNI_HORA, R16
	STS     DEC_HORA, R16
	STS     UNI_DIA, R16
	STS     DEC_DIA, R16
	STS     UNI_MES, R16
	STS     DEC_MES, R16
	STS     UNI_MIN_ALRM, R16
	STS     DEC_MIN_ALRM, R16
	STS		UNI_HORA_ALRM, R16
	STS		DEC_HORA_ALRM, R16

	LDI     R16, 0x01
	STS     UNI_DIA, R16
	STS     UNI_MES, R16

	CALL	OVER

	LPM		D_UNI_MIN, Z
	LPM		D_DEC_MIN, Z
	LPM		D_UNI_HORA, Z
	LPM		D_DEC_HORA, Z
	LPM		D_DEC_DIA, Z
	LPM		D_DEC_MES, Z
	LPM		D_UNI_MIN_ALRM, Z
	LPM		D_DEC_MIN_ALRM, Z
	LPM		D_UNI_HORA_ALRM, Z
	LPM		D_DEC_HORA_ALRM, Z

	ADIW	Z, 1
	LPM		D_UNI_DIA, Z
	LPM		D_UNI_MES, Z

	CALL	OVER

	CALL	ID_MES

	// Activamos las interrupciones
	SEI

// Main loop
MAIN_LOOP:
	SEI

	CPI		R26, 1
	BRNE	ALRM_DESARMADA

	SBRC	R19, 0
	SBI		PORTD, 7

	MUX_OUT:
	OUT		PORTC, MUX

	MODO1:
	CPI		MODO, 0
	BRNE	MODO2
	CALL	MODO_HORA
	MODO2:
	CPI		MODO, 1
	BRNE	MODO3
	CALL	MODO_FECHA
	MODO3:
	CPI		MODO, 2
	BRNE	MODO_END
	CALL	MODO_ALARMA
	MODO_END:

	CPI		R19, 2			// Se esperan 200 overflows para hacer un segundo
	BRNE	MAIN_LOOP		

	CLR		R19				// Se limpia el registro de R19

	CPI		ESTADO, 0
	BREQ	NO_EDICON
	CPI		MODO, 0
	BREQ	MAIN_LOOP
	NO_EDICON:
	CALL	SUMA_MINS_1		// Se llama el incremento del dislpay
	JMP		MAIN_LOOP

// NON-Interrupt subroutines
INIT_TMR1:
	LDI		R16, (0 << CS10) | (1 << CS11) | (0 << CS12)
	STS		TCCR1B, R16		// Setear prescaler del TIMER 0 a 64
	LDI		R16, HIGH(MAX_VAL_1)
	STS		TCNT1H, R16		// Cargar valor inicial en TCNT1
	LDI		R16, LOW(MAX_VAL_1)
	STS		TCNT1L, R16		// Cargar valor inicial en TCNT1
	RET

INIT_TMR0:
	LDI		R16, (1 << CS00) | (1 << CS01) | (0 << CS02)
	OUT		TCCR0B, R16		// Setear prescaler del TIMER 0 a 64
	LDI		R16, MAX_VAL_0
	OUT		TCNT0, R16		// Cargar valor inicial en TCNT0
	RET

SUMA_MINS_1:				// Función para el incremento del minutos
	LDS		R16, UNI_MIN	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		UNI_MIN, R16	// Se sube valor a la RAM
	CPI		R16, 10
	BRNE	SM1_JMP			
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_MIN, R16	// Se sube valor a la RAM
	CALL	SUMA_MINS_2		// En caso de overflow incrementar siguiente unidad
	SM1_JMP:
	LDS		R16, UNI_MIN	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MIN, Z	// Subir valor del puntero a registro
	RET

SUMA_MINS_2:
	LDS		R16, DEC_MIN	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		DEC_MIN, R16	// Se sube valor a la RAM
	CPI		R16, 6
	BRNE	SM2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_MIN, R16	// Se sube valor a la RAM
	CPI		ESTADO, 0
	BRNE	SM2_JMP
	CALL	SUMA_HRS_1		// En caso de overflow incrementar siguiente unidad
	SM2_JMP:
	LDS		R16, DEC_MIN	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MIN, Z	// Subir valor del puntero a registro
	RET

SUMA_HRS_1:
	LDS		R16, UNI_HORA	// Se trae el valor de la RAM
	LDS		R17, DEC_HORA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		UNI_HORA, R16	// Se sube valor a la RAM
	CPI		R17, 2			// Se observa en que decada esta la hora
	BRNE	NO_NOCHE
	CPI		R16, 4
	BRNE	SH1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA, R16	// Se sube valor a la RAM
	CALL	SUMA_HRS_2		// En caso de overflow incrementar siguiente unidad
	JMP		SH1_JMP
	NO_NOCHE:
	CPI		R16, 10
	BRNE	SH1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA, R16	// Se sube valor a la RAM
	CALL	SUMA_HRS_2		// En caso de overflow incrementar siguiente unidad
	SH1_JMP:
	LDS		R16, UNI_HORA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_HORA, Z	// Subir valor del puntero a registro
	RET

SUMA_HRS_2:
	LDS		R16, DEC_HORA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		DEC_HORA, R16	// Se sube valor a la RAM
	CPI		R16, 3
	BRNE	SH2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_HORA, R16	// Se sube valor a la RAM
	CPI		ESTADO, 0
	BRNE	SH2_JMP
	CALL	SUMA_DIA_1		// En caso de overflow incrementar siguiente unidad
	SH2_JMP:
	LDS		R16, DEC_HORA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_HORA, Z	// Subir valor del puntero a registro
	RET

SUMA_DIA_1:
	LDS		R16, UNI_DIA	// Se trae el valor de la RAM
	LDS		R17, DEC_DIA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	FEBRERO:
	CPI		NUM_DIAS, 0x02
	BRNE	NO_31_DIA
	CPI		R17, 2
	BRNE	FEBRERO1			// Se observa si tiene más de 4 bits
	CPI		R16, 9
	BRNE	SD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_2		// En caso de overflow incrementar siguiente unidad
	JMP		SD1_JMP
	FEBRERO1:
	CPI		R16, 10
	BRNE	SD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_2		// En caso de overflow incrementar siguiente unidad
	JMP		SD1_JMP
	NO_31_DIA:
	CPI		NUM_DIAS, 0x01
	BRNE	NO_30_DIA
	CPI		R17, 3
	BRNE	NO_31_DIA1			// Se observa si tiene más de 4 bits
	CPI		R16, 2
	BRNE	SD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_2		// En caso de overflow incrementar siguiente unidad
	JMP		SD1_JMP
	NO_31_DIA1:
	CPI		R16, 10
	BRNE	SD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_2		// En caso de overflow incrementar siguiente unidad
	JMP		SD1_JMP
	NO_30_DIA:
	CPI		NUM_DIAS, 0x00
	BRNE	SD1_JMP
	CPI		R17, 3
	BRNE	NO_30_DIA1			// Se observa si tiene más de 4 bits
	CPI		R16, 1
	BRNE	SD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_2		// En caso de overflow incrementar siguiente unidad
	JMP		SD1_JMP
	NO_30_DIA1:
	CPI		R16, 10
	BRNE	SD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_2		// En caso de overflow incrementar siguiente unidad
	SD1_JMP:
	LDS		R16, UNI_DIA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_DIA, Z	// Subir valor del puntero a registro
	RET

SUMA_DIA_2:
	LDS		R16, DEC_DIA	// Se trae el valor de la RAM
	LDS		R17, UNI_DIA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	DEC_FEBRERO:
	CPI		NUM_DIAS, 0x02
	BRNE	DEC_31
	CPI		R16, 3
	BRNE	SD2_JMP		// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	CPI		ESTADO, 0
	BRNE	SD2_JMP
	CALL	SUMA_MES_1
	JMP		SD2_JMP
	DEC_31:
	CPI		NUM_DIAS, 0x01
	BRNE	DEC_30
	CPI		R16, 4
	BRNE	SD2_JMP		// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	CPI		ESTADO, 0
	BRNE	SD2_JMP
	CALL	SUMA_MES_1
	JMP		SD2_JMP
	DEC_30:
	CPI		NUM_DIAS, 0x00
	BRNE	SD2_JMP
	CPI		R16, 4
	BRNE	SD2_JMP		// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	CPI		ESTADO, 0
	BRNE	SD2_JMP
	CALL	SUMA_MES_1
	SD2_JMP:
	LDS		R16, DEC_DIA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_DIA, Z	// Subir valor del puntero a registro
	RET

SUMA_MES_1:
	CPI		ESTADO, 0
	BREQ	EDITANDING
	LDI		R16, 0x00
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	LPM		D_DEC_DIA, Z	// Subir valor del puntero a registro
	LPM		D_UNI_DIA, Z	// Subir valor del puntero a registro
	EDITANDING:
	LDS		R16, UNI_MES	// Se trae el valor de la RAM
	LDS		R17, DEC_MES	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CPI		R17, 1			// Se observa en que decada esta la hora
	BRNE	NO_MES
	CPI		R16, 3
	BRNE	SME1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x01		// En caso de overflow y debe regresar a 0
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CALL	SUMA_MES_2		// En caso de overflow incrementar siguiente unidad
	JMP		SME1_JMP
	NO_MES:
	CPI		R16, 10
	BRNE	SME1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CALL	SUMA_MES_2		// En caso de overflow incrementar siguiente unidad
	SME1_JMP:
	LDS		R16, UNI_MES	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MES, Z	// Subir valor del puntero a registro
	CALL	ID_MES
	RET

SUMA_MES_2:
	LDS		R16, DEC_MES	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		DEC_MES, R16	// Se sube valor a la RAM
	CPI		R16, 2
	BRNE	SME2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_MES, R16	// Se sube valor a la RAM
	SME2_JMP:
	LDS		R16, DEC_MES	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MES, Z	// Subir valor del puntero a registro
	RET

ID_MES:
	LDS		R16, UNI_MES
	LDS		R17, DEC_MES
	SWAP	R17
	ADD		R17, R16
	CPI		R17, 0x02
	BRNE	NO_FEBRERO
	LDI		NUM_DIAS, 0x02
	JMP		ID_FINAL
	NO_FEBRERO:
	CPI		R17, 0x08
	BRLO	IMPAR31
	SBRS	R17, 0
	LDI		NUM_DIAS, 0x01
	SBRC	R17, 0
	LDI		NUM_DIAS, 0x00	
	JMP		ID_FINAL
	IMPAR31:
	SBRS	R17, 0
	LDI		NUM_DIAS, 0x00
	SBRC	R17, 0
	LDI		NUM_DIAS, 0x01
	ID_FINAL:
	RET


RESTA_MINS_1:				// Función para el DECremento del minutos
	LDS		R16, UNI_MIN	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		UNI_MIN, R16	// Se sube valor a la RAM
	CPI		R16, 0xFF
	BRNE	RM1_JMP			
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_MIN, R16	// Se sube valor a la RAM
	CALL	RESTA_MINS_2		// En caso de overflow DECrementar siguiente unidad
	RM1_JMP:
	LDS		R16, UNI_MIN	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MIN, Z	// Subir valor del puntero a registro
	RET

RESTA_MINS_2:
	LDS		R16, DEC_MIN	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		DEC_MIN, R16	// Se sube valor a la RAM
	CPI		R16, 0xFF
	BRNE	RM2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x05		// En caso de overflow y debe regresar a 0
	STS		DEC_MIN, R16	// Se sube valor a la RAM
	RM2_JMP:
	LDS		R16, DEC_MIN	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MIN, Z	// Subir valor del puntero a registro
	RET

RESTA_HRS_1:
	LDS		R16, UNI_HORA	// Se trae el valor de la RAM
	LDS		R17, DEC_HORA	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		UNI_HORA, R16	// Se sube valor a la RAM
	CPI		R17, 0			// Se observa en que decada esta la hora
	BRNE	RNO_NOCHE
	CPI		R16, 0xFF
	BRNE	RH1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x03		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA, R16	// Se sube valor a la RAM
	CALL	RESTA_HRS_2		// En caso de overflow DECrementar siguiente unidad
	JMP		RH1_JMP
	RNO_NOCHE:
	CPI		R16, 0xFF
	BRNE	RH1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA, R16	// Se sube valor a la RAM
	CALL	RESTA_HRS_2		// En caso de overflow DECrementar siguiente unidad
	RH1_JMP:
	LDS		R16, UNI_HORA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_HORA, Z	// Subir valor del puntero a registro
	RET

RESTA_HRS_2:
	LDS		R16, DEC_HORA	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		DEC_HORA, R16	// Se sube valor a la RAM
	CPI		R16, 0xFF
	BRNE	RH2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x02		// En caso de overflow y debe regresar a 0
	STS		DEC_HORA, R16	// Se sube valor a la RAM
	RH2_JMP:
	LDS		R16, DEC_HORA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_HORA, Z	// Subir valor del puntero a registro
	RET

RESTA_DIA_1:
	LDS		R16, UNI_DIA	// Se trae el valor de la RAM
	LDS		R17, DEC_DIA	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	RFEBRERO:
	CPI		NUM_DIAS, 0x02
	BRNE	RNO_31_DIA
	CPI		R17, 0
	BRNE	RFEBRERO1			// Se observa si tiene más de 4 bits
	CPI		R16, 0xFF
	BRNE	RD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x08		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	RESTA_DIA_2		// En caso de overflow DECrementar siguiente unidad
	JMP		RD1_JMP
	RFEBRERO1:
	CPI		R16, 0xFF
	BRNE	RD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	RESTA_DIA_2		// En caso de overflow DECrementar siguiente unidad
	JMP		RD1_JMP
	RNO_31_DIA:
	CPI		NUM_DIAS, 0x01
	BRNE	RNO_30_DIA
	CPI		R17, 0
	BRNE	RNO_31_DIA1			// Se observa si tiene más de 4 bits
	CPI		R16, 0xFF
	BRNE	RD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x01		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	RESTA_DIA_2		// En caso de overflow DECrementar siguiente unidad
	JMP		RD1_JMP
	RNO_31_DIA1:
	CPI		R16, 0xFF
	BRNE	RD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	RESTA_DIA_2		// En caso de overflow DECrementar siguiente unidad
	JMP		RD1_JMP
	RNO_30_DIA:
	CPI		NUM_DIAS, 0x00
	BRNE	RD1_JMP
	CPI		R17, 0
	BRNE	RNO_30_DIA1			// Se observa si tiene más de 4 bits
	CPI		R16, 0xFF
	BRNE	RD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	RESTA_DIA_2		// En caso de overflow DECrementar siguiente unidad
	JMP		RD1_JMP
	RNO_30_DIA1:
	CPI		R16, 0xFF
	BRNE	RD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	RESTA_DIA_2		// En caso de overflow DECrementar siguiente unidad
	RD1_JMP:
	LDS		R16, UNI_DIA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_DIA, Z	// Subir valor del puntero a registro
	RET

RESTA_DIA_2:
	LDS		R16, DEC_DIA	// Se trae el valor de la RAM
	LDS		R17, UNI_DIA	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	RDEC_FEBRERO:
	CPI		NUM_DIAS, 0x02
	BRNE	RDEC_31
	CPI		R16, 0xFF
	BRNE	RD2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x02		// En caso de overflow y debe regresar a 0
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	JMP		RD2_JMP
	RDEC_31:
	CPI		NUM_DIAS, 0x01
	BRNE	RDEC_30
	CPI		R16, 0xFF
	BRNE	RD2_JMP		// Se observa si tiene más de 4 bits
	LDI		R16, 0x03		// En caso de overflow y debe regresar a 0
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	JMP		RD2_JMP
	RDEC_30:
	CPI		NUM_DIAS, 0x00
	BRNE	RD2_JMP
	CPI		R16, 0xFF
	BRNE	RD2_JMP		// Se observa si tiene más de 4 bits
	LDI		R16, 0x03		// En caso de overflow y debe regresar a 0
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	RD2_JMP:
	LDS		R16, DEC_DIA	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_DIA, Z	// Subir valor del puntero a registro
	RET

RESTA_MES_1:
	CPI		ESTADO, 0
	BREQ	REDITANDING
	LDI		R16, 0x00
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	LPM		D_DEC_DIA, Z	// Subir valor del puntero a registro
	LPM		D_UNI_DIA, Z	// Subir valor del puntero a registro
	REDITANDING:
	LDS		R16, UNI_MES	// Se trae el valor de la RAM
	LDS		R17, DEC_MES	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CPI		R17, 0			// Se observa en que decada esta la hora
	BRNE	RNO_MES
	CPI		R16, 0x00
	BRNE	RME1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x02		// En caso de overflow y debe regresar a 0
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CALL	RESTA_MES_2		// En caso de overflow DECrementar siguiente unidad
	JMP		RME1_JMP
	RNO_MES:
	CPI		R16, 0xFF
	BRNE	RME1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CALL	RESTA_MES_2		// En caso de overflow DECrementar siguiente unidad
	RME1_JMP:
	LDS		R16, UNI_MES	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MES, Z	// Subir valor del puntero a registro
	CALL	ID_MES
	RET

RESTA_MES_2:
	LDS		R16, DEC_MES	// Se trae el valor de la RAM
	DEC		R16				// Se DECrementa el valor
	STS		DEC_MES, R16	// Se sube valor a la RAM
	CPI		R16, 0xFF
	BRNE	RME2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x01		// En caso de overflow y debe regresar a 0
	STS		DEC_MES, R16	// Se sube valor a la RAM
	RME2_JMP:
	LDS		R16, DEC_MES	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MES, Z	// Subir valor del puntero a registro
	RET

MODO_HORA:
	MODO_HORA1:
	CPI		R21, 0
	BRNE	MODO_HORA2
	OUT		PORTD, D_UNI_MIN
	MODO_HORA2:
	CPI		R21, 1
	BRNE	MODO_HORA3
	OUT		PORTD, D_DEC_MIN
	MODO_HORA3:
	CPI		R21, 2
	BRNE	MODO_HORA4
	OUT		PORTD, D_UNI_HORA
	MODO_HORA4:
	CPI		R21, 3
	BRNE	MODO_HORA_END
	OUT		PORTD, D_DEC_HORA
	MODO_HORA_END:
	RET

MODO_FECHA:
	MODO_FECHA1:
	CPI		R21, 0
	BRNE	MODO_FECHA2
	OUT		PORTD, D_UNI_DIA
	MODO_FECHA2:
	CPI		R21, 1
	BRNE	MODO_FECHA3
	OUT		PORTD, D_DEC_DIA
	MODO_FECHA3:
	CPI		R21, 2
	BRNE	MODO_FECHA4
	OUT		PORTD, D_UNI_MES
	MODO_FECHA4:
	CPI		R21, 3
	BRNE	MODO_FECHA_END
	OUT		PORTD, D_DEC_MES
	MODO_FECHA_END:
	RET

MODO_ALARMA:
	MODO_ALARMA1:
	CPI		R21, 0
	BRNE	MODO_ALARMA2
	OUT		PORTD, D_UNI_MIN_ALRM
	MODO_ALARMA2:
	CPI		R21, 1
	BRNE	MODO_ALARMA3
	OUT		PORTD, D_DEC_MIN_ALRM
	MODO_ALARMA3:
	CPI		R21, 2
	BRNE	MODO_ALARMA4
	OUT		PORTD, D_UNI_HORA_ALRM
	MODO_ALARMA4:
	CPI		R21, 3
	BRNE	MODO_ALARMA_END
	OUT		PORTD, D_DEC_HORA_ALRM
	MODO_ALARMA_END:
	RET

SUMA_MINS_ALRM_1:				// Función para el incremento del minutos
	LDS		R16, UNI_MIN_ALRM	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		UNI_MIN_ALRM, R16	// Se sube valor a la RAM
	CPI		R16, 10
	BRNE	SMA1_JMP			
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_MIN_ALRM, R16	// Se sube valor a la RAM
	CALL	SUMA_MINS_ALRM_2		// En caso de overflow incrementar siguiente unidad
	SMA1_JMP:
	LDS		R16, UNI_MIN_ALRM	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MIN_ALRM, Z	// Subir valor del puntero a registro
	RET

SUMA_MINS_ALRM_2:
	LDS		R16, DEC_MIN_ALRM	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		DEC_MIN_ALRM, R16	// Se sube valor a la RAM
	CPI		R16, 6
	BRNE	SMA2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_MIN_ALRM, R16	// Se sube valor a la RAM
	SMA2_JMP:
	LDS		R16, DEC_MIN_ALRM	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MIN_ALRM, Z	// Subir valor del puntero a registro
	RET

SUMA_HRS_ALRM_1:
	LDS		R16, UNI_HORA_ALRM	// Se trae el valor de la RAM
	LDS		R17, DEC_HORA_ALRM	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	STS		UNI_HORA_ALRM, R16	// Se sube valor a la RAM
	CPI		R17, 2			// Se observa en que decada esta la hora
	BRNE	NO_NOCHE_A
	CPI		R16, 4
	BRNE	SHA1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA_ALRM, R16	// Se sube valor a la RAM
	CALL	SUMA_HRS_ALRM_2		// En caso de overflow incrementar siguiente unidad
	JMP		SHA1_JMP
	NO_NOCHE_A:
	CPI		R16, 10
	BRNE	SHA1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA_ALRM, R16	// Se sube valor a la RAM
	CALL	SUMA_HRS_ALRM_2		// En caso de overflow incrementar siguiente unidad
	SHA1_JMP:
	LDS		R16, UNI_HORA_ALRM	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_HORA_ALRM, Z	// Subir valor del puntero a registro
	RET

SUMA_HRS_ALRM_2:
	LDS		R16, DEC_HORA_ALRM	// Se trae el valor de la RAM
	INC		R16					// Se incrementa el valor
	STS		DEC_HORA_ALRM, R16	// Se sube valor a la RAM
	CPI		R16, 3
	BRNE	SHA2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00			// En caso de overflow y debe regresar a 0
	STS		DEC_HORA_ALRM, R16	// Se sube valor a la RAM
	SHA2_JMP:
	LDS		R16, DEC_HORA_ALRM	// Se trae el valor de la RAM
	CALL	OVER				// Se resetea el puntero
	ADD		ZL, R16				// Se ingresa el registro del contador al puntero
	ADD		ZH, R1				// Se ingresa el registro del contador al puntero
	LPM		D_DEC_HORA_ALRM, Z	// Subir valor del puntero a registro
	RET


RESTA_MINS_ALRM_1:				// Función para el incremento del minutos
	LDS		R16, UNI_MIN_ALRM	// Se trae el valor de la RAM
	DEC		R16				// Se incrementa el valor
	STS		UNI_MIN_ALRM, R16	// Se sube valor a la RAM
	CPI		R16, 0xFF
	BRNE	RMA1_JMP			
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_MIN_ALRM, R16	// Se sube valor a la RAM
	CALL	RESTA_MINS_ALRM_2		// En caso de overflow incrementar siguiente unidad
	RMA1_JMP:
	LDS		R16, UNI_MIN_ALRM	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MIN_ALRM, Z	// Subir valor del puntero a registro
	RET

RESTA_MINS_ALRM_2:
	LDS		R16, DEC_MIN_ALRM	// Se trae el valor de la RAM
	DEC		R16				// Se incrementa el valor
	STS		DEC_MIN_ALRM, R16	// Se sube valor a la RAM
	CPI		R16, 0xFF
	BRNE	RMA2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x05		// En caso de overflow y debe regresar a 0
	STS		DEC_MIN_ALRM, R16	// Se sube valor a la RAM
	RMA2_JMP:
	LDS		R16, DEC_MIN_ALRM	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MIN_ALRM, Z	// Subir valor del puntero a registro
	RET

RESTA_HRS_ALRM_1:
	LDS		R16, UNI_HORA_ALRM	// Se trae el valor de la RAM
	LDS		R17, DEC_HORA_ALRM	// Se trae el valor de la RAM
	DEC		R16				// Se incrementa el valor
	STS		UNI_HORA_ALRM, R16	// Se sube valor a la RAM
	CPI		R17, 0			// Se observa en que decada esta la hora
	BRNE	R_NO_NOCHE_A
	CPI		R16, 0xFF
	BRNE	RHA1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x03		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA_ALRM, R16	// Se sube valor a la RAM
	CALL	RESTA_HRS_ALRM_2		// En caso de overflow incrementar siguiente unidad
	JMP		RHA1_JMP
	R_NO_NOCHE_A:
	CPI		R16, 0xFF
	BRNE	RHA1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x09		// En caso de overflow y debe regresar a 0
	STS		UNI_HORA_ALRM, R16	// Se sube valor a la RAM
	CALL	RESTA_HRS_ALRM_2		// En caso de overflow incrementar siguiente unidad
	RHA1_JMP:
	LDS		R16, UNI_HORA_ALRM	// Se trae el valor de la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_HORA_ALRM, Z	// Subir valor del puntero a registro
	RET

RESTA_HRS_ALRM_2:
	LDS		R16, DEC_HORA_ALRM	// Se trae el valor de la RAM
	DEC		R16					// Se incrementa el valor
	STS		DEC_HORA_ALRM, R16	// Se sube valor a la RAM
	CPI		R16, 0xFF
	BRNE	RHA2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x02			// En caso de overflow y debe regresar a 0
	STS		DEC_HORA_ALRM, R16	// Se sube valor a la RAM
	RHA2_JMP:
	LDS		R16, DEC_HORA_ALRM	// Se trae el valor de la RAM
	CALL	OVER				// Se resetea el puntero
	ADD		ZL, R16				// Se ingresa el registro del contador al puntero
	ADD		ZH, R1				// Se ingresa el registro del contador al puntero
	LPM		D_DEC_HORA_ALRM, Z	// Subir valor del puntero a registro
	RET

OVER:
	LDI		ZL, LOW(TABLA7SEG << 1)				// Ingresa a Z los registros de la tabla más bajos
	LDI		ZH, HIGH(TABLA7SEG << 1)			
	RET

// Interrupt routines
BOTONES:
	CLI						// Deshabilitamos las interrupciones

	PUSH	R18				// Se guarda el registro actual de R18
    IN		R18, SREG		// Se ingresa el registro del SREG a R18
    PUSH	R18				// Se guarda el registro del SREG

	PUSH	R17
	IN		R17, PINB		// Se ingresa la configuración del PIND
	ANDI	R17, 0x0F
	CAMBIO_MODO:
	CPI		R17, 0x0D		// Se compara para ver si el botón está presionado
	BRNE	CAMBIO_ESTADO	// Si no esta preionado termina la interrupción
	LDI		ESTADO, 0
	INC		MODO
	CPI		MODO, 3
	BRNE	PUENTE_AL_FINAL
	LDI		MODO, 0x00
	JMP		FINAL			// Regreso de la interrupción
	CAMBIO_ESTADO:
	CPI		R17, 0x0E		// Se compara para ver si el botón está presionado
	BRNE	INCREMENTOS		// Si no esta preionado termina la interrupción
	INC		ESTADO
	CPI		ESTADO, 3
	BRNE	PUENTE_AL_FINAL
	LDI		ESTADO, 0x00
	JMP		FINAL
	PUENTE_AL_FINAL:
	JMP		FINAL
	INCREMENTOS:
	CPI		R17, 0x0B		// Se compara para ver si el botón está presionado
	BRNE	DECREMENTOS		// Si no esta preionado termina la interrupción
	CPI		ESTADO, 0
	BRNE	D1
	CPI		MODO, 2
	BRNE	PUENTE_AL_FINAL
	SBI		PORTB, 4
	LDI		R26, 0x01
	D1:
	CPI		ESTADO, 1
	BRNE	D2
	D1_HORA:
	CPI		MODO, 0
	BRNE	D1_FECHA
	CALL	SUMA_MINS_1
	D1_FECHA:
	CPI		MODO, 1
	BRNE	D1_ALARMA
	CALL	SUMA_DIA_1
	D1_ALARMA:
	CPI		MODO, 2
	BRNE	FINAL
	CALL	SUMA_MINS_ALRM_1
	JMP		FINAL
	D2:
	CPI		ESTADO, 2
	BRNE	FINAL
	D2_HORA:
	CPI		MODO, 0
	BRNE	D2_FECHA
	CALL	SUMA_HRS_1
	D2_FECHA:
	CPI		MODO, 1
	BRNE	D2_ALARMA
	CALL	SUMA_MES_1
	D2_ALARMA: 
	CPI		MODO, 2
	BRNE	FINAL
	CALL	SUMA_HRS_ALRM_1
	JMP		FINAL
	DECREMENTOS:
	CPI		R17, 0x07		// Se compara para ver si el botón está presionado
	BRNE	FINAL			// Si no esta preionado termina la interrupción
	CPI		ESTADO, 0
	BRNE	R_D1
	CPI		MODO, 2
	BRNE	FINAL
	CBI		PORTB, 4
	LDI		R26, 0x00
	R_D1:
	CPI		ESTADO, 1
	BRNE	R_D2
	R_D1_HORA:
	CPI		MODO, 0
	BRNE	R_D1_FECHA
	CALL	RESTA_MINS_1
	R_D1_FECHA:
	CPI		MODO, 1
	BRNE	R_D1_ALARMA
	CALL	RESTA_DIA_1
	R_D1_ALARMA:
	CPI		MODO, 2
	BRNE	FINAL
	CALL	RESTA_MINS_ALRM_1
	JMP		FINAL
	R_D2:
	CPI		ESTADO, 2
	BRNE	FINAL
	R_D2_HORA:
	CPI		MODO, 0
	BRNE	R_D2_FECHA
	CALL	RESTA_HRS_1
	R_D2_FECHA:
	CPI		MODO, 1
	BRNE	R_D2_ALARMA
	CALL	RESTA_MES_1
	R_D2_ALARMA: 
	CPI		MODO, 2
	BRNE	FINAL
	CALL	RESTA_HRS_ALRM_1
	JMP		FINAL
	FINAL: 
	POP		R17
	POP		R18				// Se trae el registro del SREG
    OUT		SREG, R18		// Se ingresa el registro del SREG a R18
    POP		R18				// Se trae el registro anterior de R18	

	RETI					// Regreso de la interrupción

OVER_TIMER1:
	CLI

	PUSH	R17				// Se guarda el registro actual de R18
    IN		R17, SREG		// Se ingresa el registro del SREG a R18
    PUSH	R17				// Se guarda el registro del SREG

	LDI		R17, HIGH(MAX_VAL_1)
	STS		TCNT1H, R17		// Cargar valor inicial en TCNT1
	LDI		R17, LOW(MAX_VAL_1)
	STS		TCNT1L, R17		// Cargar valor inicial en TCNT1
	INC		R19				// Se incrementa el tiempo del timer

	POP		R17				// Se trae el registro del SREG
    OUT		SREG, R17		// Se ingresa el registro del SREG a R18
    POP		R17				// Se trae el registro anterior de R18	

	RETI

OVER_TIMER0:
	CLI

	PUSH	R17				// Se guarda el registro actual de R18
    IN		R17, SREG		// Se ingresa el registro del SREG a R18
    PUSH	R17				// Se guarda el registro del SREG

	LDI		R17, MAX_VAL_0
	OUT		TCNT0, R17		// Cargar valor inicial en TCNT0
	INC		R21				// Se incrementa el tiempo del timer

	CPI		R21, 4
	BRNE	DISPLAYS
	CLR		R21

	HORA:
	CPI		MODO, 0
	BRNE	FECHA
	LDI		MUX, 0x10
	FECHA:
	CPI		MODO, 1
	BRNE	ALARMA
	LDI		MUX, 0x20
	ALARMA:
	CPI		MODO, 2
	BRNE	DISPLAYS
	LDI		MUX, 0x30

	DISPLAYS:
	ANDI	MUX, 0xF0 
	DISPLAY1:
	CPI		R21, 0
	BRNE	DISPLAY2
	SBRC	R19, 0
	JMP		NO_EDICION_DISPLAY1
	CPI		ESTADO, 1
	BRNE	NO_EDICION_DISPLAY1
	LDI		R17, 0b00000000
	JMP		DISPLAY_END
	NO_EDICION_DISPLAY1:
	LDI		R17, 0b00001000
	ADD		MUX, R17
	DISPLAY2:
	CPI		R21, 1
	BRNE	DISPLAY3
	SBRC	R19, 0
	JMP		NO_EDICION_DISPLAY2
	CPI		ESTADO, 1
	BRNE	NO_EDICION_DISPLAY2
	LDI		R17, 0b00000000
	JMP		DISPLAY_END
	NO_EDICION_DISPLAY2:
	LDI		R17, 0b00000100
	ADD		MUX, R17
	DISPLAY3:
	CPI		R21, 2
	BRNE	DISPLAY4
	SBRC	R19, 0
	JMP		NO_EDICION_DISPLAY3
	CPI		ESTADO, 2
	BRNE	NO_EDICION_DISPLAY3
	LDI		R17, 0b00000000
	JMP		DISPLAY_END
	NO_EDICION_DISPLAY3:
	LDI		R17, 0b00000010
	ADD		MUX, R17
	DISPLAY4:
	CPI		R21, 3
	BRNE	DISPLAY_END
	SBRC	R19, 0
	JMP		NO_EDICION_DISPLAY4
	CPI		ESTADO, 2
	BRNE	NO_EDICION_DISPLAY4
	LDI		R17, 0b00000000
	JMP		DISPLAY_END
	NO_EDICION_DISPLAY4:
	LDI		R17, 0b00000001
	ADD		MUX, R17

	DISPLAY_END:
	POP		R17				// Se trae el registro del SREG
    OUT		SREG, R17		// Se ingresa el registro del SREG a R18
    POP		R17				// Se trae el registro anterior de R18	

	RETI
