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
.def		D_UNI_ALRM = R10
.def		D_DEC_ALRM = R11

.def		MUX = R22

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
UNI_ALRM:	.byte	1
DEC_ALRM:	.byte	1

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
	LDI		R16, (1 << PCINT1) | (1 << PCINT0)
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
	LDI		R22, 0x00		// MUX
	LDI		R23, 0x00		// 
	LDI		R24, 0x00		// 

	LDI     R16, 0x00
	STS     UNI_MIN, R16
	STS     DEC_MIN, R16
	STS     UNI_HORA, R16
	STS     DEC_HORA, R16
	STS     UNI_DIA, R16
	STS     DEC_DIA, R16
	STS     UNI_MES, R16
	STS     DEC_MES, R16
	STS     UNI_ALRM, R16
	STS     DEC_ALRM, R16

	CALL	OVER

	LPM		D_UNI_MIN, Z
	LPM		D_DEC_MIN, Z
	LPM		D_UNI_HORA, Z
	LPM		D_DEC_HORA, Z
	LPM		D_UNI_DIA, Z
	LPM		D_DEC_DIA, Z
	LPM		D_UNI_MES, Z
	LPM		D_DEC_MES, Z
	LPM		D_UNI_ALRM, Z
	LPM		D_DEC_ALRM, Z


	// Activamos las interrupciones
	SEI

// Main loop
MAIN_LOOP:
	SEI

	SBRC	R19, 0
	SBI		PORTD, 7

	OUT		PORTC, MUX

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
	BRNE	MODO_END
	OUT		PORTD, D_DEC_HORA
	
	MODO_END:
	CPI		R19, 2			// Se esperan 200 overflows para hacer un segundo
	BRNE	MAIN_LOOP		

	CLR		R19				// Se limpia el registro de R19

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
	CPI		R16, 10
	BRNE	SM1_JMP			
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_MIN, R16	// Se sube valor a la RAM
	CALL	SUMA_MINS_2		// En caso de overflow incrementar siguiente unidad
	SM1_JMP:
	STS		UNI_MIN, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MIN, Z	// Subir valor del puntero a registro
	RET

SUMA_MINS_2:
	LDS		R16, DEC_MIN	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	CPI		R16, 6
	BRNE	SM2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_MIN, R16	// Se sube valor a la RAM
	CALL	SUMA_MINS_2		// En caso de overflow incrementar siguiente unidad
	SM2_JMP:
	STS		DEC_MIN, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MIN, Z	// Subir valor del puntero a registro
	RET

SUMA_HRS_1:
	LDS		R16, UNI_HORA	// Se trae el valor de la RAM
	LDS		R17, DEC_HORA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	CPI		R17, 2			// Se observa en que decada esta la hora
	BRNE	NO_NOCHE
	CPI		R16, 5
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
	STS		UNI_HORA, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_HORA, Z	// Subir valor del puntero a registro
	RET

SUMA_HRS_2:
	LDS		R16, DEC_HORA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	CPI		R16, 3
	BRNE	SH2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_HORA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_1		// En caso de overflow incrementar siguiente unidad
	SH2_JMP:
	STS		DEC_HORA, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_HORA, Z	// Subir valor del puntero a registro
	RET

SUMA_DIA_1:
	LDS		R16, UNI_DIA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	CPI		R16, 3
	BRNE	SD1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_DIA_2		// En caso de overflow incrementar siguiente unidad
	SD1_JMP:
	STS		UNI_DIA, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_DIA, Z	// Subir valor del puntero a registro
	RET

SUMA_DIA_2:
	LDS		R16, DEC_DIA	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	CPI		R16, 3
	BRNE	SD2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	CALL	SUMA_MES_1		// En caso de overflow incrementar siguiente unidad
	SD2_JMP:
	STS		DEC_DIA, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_DIA, Z	// Subir valor del puntero a registro
	RET

SUMA_MES_1:
	LDS		R16, UNI_MES	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	CPI		R16, 3
	BRNE	SME1_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CALL	SUMA_MES_2		// En caso de overflow incrementar siguiente unidad
	SME1_JMP:
	STS		UNI_MES, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_UNI_MES, Z	// Subir valor del puntero a registro
	RET

SUMA_MES_2:
	LDS		R16, DEC_MES	// Se trae el valor de la RAM
	INC		R16				// Se incrementa el valor
	CPI		R16, 3
	BRNE	SME2_JMP			// Se observa si tiene más de 4 bits
	LDI		R16, 0x00		// En caso de overflow y debe regresar a 0
	STS		DEC_MES, R16	// Se sube valor a la RAM
	SME2_JMP:
	STS		DEC_MES, R16	// Se sube valor a la RAM
	CALL	OVER			// Se resetea el puntero
	ADD		ZL, R16			// Se ingresa el registro del contador al puntero
	ADD		ZH, R1			// Se ingresa el registro del contador al puntero
	LPM		D_DEC_MES, Z	// Subir valor del puntero a registro
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

	IN		R17, PINB		// Se ingresa la configuración del PIND
	CPI		R17, 0x1D		// Se compara para ver si el botón está presionado
	BRNE	DECREMENTO		// Si no esta preionado termina la interrupción
	INC		R16				// Si está presionado incrementa
	SBRC	R16, 4			// Si genera overflow reinicia contador
	LDI		R16, 0x00
	JMP		FINAL			// Regreso de la interrupción
	DECREMENTO:
	CPI		R17, 0x1E		// Se compara para ver si el botón está presionado
	BRNE	FINAL			// Si no esta preionado termina la interrupción
	DEC		R16				// Si está presionado decrementa
	SBRC	R16, 4			// Si genera underflow reinicia contador
	LDI		R16, 0x0F
	FINAL: 

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

	LDI		R16, MAX_VAL_0
	OUT		TCNT0, R16		// Cargar valor inicial en TCNT0
	INC		R21				// Se incrementa el tiempo del timer

	CLR		MUX
	CPI		R21, 4
	BRNE	DISPLAYS
	CLR		R21

	DISPLAYS:
	DISPLAY1:
	CPI		R21, 0
	BRNE	DISPLAY2
	LDI		MUX, 0b00001000
	DISPLAY2:
	CPI		R21, 1
	BRNE	DISPLAY3
	LDI		MUX, 0b00000100
	DISPLAY3:
	CPI		R21, 2
	BRNE	DISPLAY4
	LDI		MUX, 0b00000010
	DISPLAY4:
	CPI		R21, 3
	BRNE	DISPLAY_END
	LDI		MUX, 0b00000001

	DISPLAY_END:
	POP		R17				// Se trae el registro del SREG
    OUT		SREG, R17		// Se ingresa el registro del SREG a R18
    POP		R17				// Se trae el registro anterior de R18	

	RETI
