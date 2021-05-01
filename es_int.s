* Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000           * Pila
        DC.L    PPRINT3           * PC

        ORG     $400

* Definici�n de equivalencias
*********************************

MR1A    EQU     $effc01       * de modo A (escritura)
MR2A    EQU     $effc01       * de modo A (2� escritura)
SRA     EQU     $effc03       * de estado A (lectura)
CSRA    EQU     $effc03       * de seleccion de reloj A (escritura)
CRA     EQU     $effc05       * de control A (escritura)
TBA     EQU     $effc07       * buffer transmision A (escritura)
RBA     EQU     $effc07       * buffer recepcion A  (lectura)
ACR	EQU	$effc09	      * de control auxiliar
IMR     EQU     $effc0B       * de mascara de interrupcion A (escritura)
ISR     EQU     $effc0B       * de estado de interrupcion A (lectura)
MR1B    EQU     $effc11       * de modo B (escritura)
MR2B    EQU     $effc11       * de modo B (2� escritura)
CRB     EQU     $effc15	      * de control A (escritura)
TBB     EQU     $effc17       * buffer transmision B (escritura)
RBB	EQU	$effc17       * buffer recepcion B (lectura)
SRB     EQU     $effc13       * de estado B (lectura)
CSRB	EQU	$effc13       * de seleccion de reloj B (escritura)
IVR     EQU     $effc19       * del vector de interrupcion
CR	EQU	$0D	      * Carriage Return
LF	EQU	$0A	      * Line Feed
FLAGT	EQU	2	      * Flag de transmisi�n
FLAGR   EQU     0	      * Flag de recepci�n


* Bufferes internos
*********************************

BAR:     DS.B    2008
BAT:     DS.B    2008
BBR:     DS.B    2008
BBT:     DS.B    2008

CBAR:    DS.B    1           * Estas variables sirven para almecenar dos estados booleanos. Si
CBAT:    DS.B    1           * el bit 0 está a 1 => l buffer está vacio
CBBR:    DS.B    1           * Si el bit 1 está a 1 => el buffer esta lleno
CBBT:    DS.B    1

CIMR:   DS.B     1   


* Diseño y codificacion de casos de pruebas
*********************************************************************************************

BUFFER: DS.B    2100         * Buffer para lectura y escritura de caracteres
PARDIR: DC.L    0            * Dirección que se pasa como parámetro
PARTAM: DC.W    0            * Tamaño que se pasa como parámetro
CONTC:  DC.W    0            * Contador de caracteres a imprimir
DESA:   EQU     0            * Descriptor lı́nea A
DESB:   EQU     1            * Descriptor lı́nea B
TAMBS:  EQU     30           * Tamaño de bloque para SCAN
TAMBP:  EQU     7            * Tamaño de bloque para PRINT



INICIO: 
        BSR             INIT
BUCPR:  MOVE.W          #TAMBS,PARTAM       * Inicializa parámetro de tamaño
        MOVE.L          #BUFFER,PARDIR      * Parámetro BUFFER = comienzo del buffer
OTRAL:  MOVE.W          PARTAM,-(A7)        * Tamaño de bloque
        MOVE.W          #DESA,-(A7)         * Puerto A
        MOVE.L          PARDIR,-(A7)        * Dirección de lectura
ESPL:   BSR             SCAN
        ADD.L           #8,A7               * Restablece la pila
        ADD.L           D0,PARDIR           * Calcula la nueva dirección de lectura
        SUB.W           D0,PARTAM           * Actualiza el número de caracteres leı́dos
        BNE             OTRAL               * Si no se han leı́do todas los caracteres
                                            * del bloque se vuelve a leer
        MOVE.W          #TAMBS,CONTC        * Inicializa contador de caracteres a imprimir
        MOVE.L          #BUFFER,PARDIR      * Parámetro BUFFER = comienzo del buffer
OTRAE:  MOVE.W          #TAMBP,PARTAM       * Tamaño de escritura = Tamaño de bloque
ESPE:   MOVE.W          PARTAM,-(A7)        * Tamaño de escritura
        MOVE.W          #DESB,-(A7)         * Puerto B
        MOVE.L          PARDIR,-(A7)        * Dirección de escritura
        BSR             PRINT
        ADD.L           #8,A7               * Restablece la pila
        ADD.L           D0,PARDIR           * Calcula la nueva dirección del buffer
        SUB.W           D0,CONTC            * Actualiza el contador de caracteres
        BEQ             SALIR               * Si no quedan caracteres se acaba
        SUB.W           D0,PARTAM           * Actualiza el tamaño de escritura
        BNE             ESPE                * Si no se ha escrito todo el bloque se insiste
        CMP.W           #TAMBP,CONTC        * Si el n o de caracteres que quedan es menor que
                                            * el tamaño establecido se imprime ese número
        BHI             OTRAE               * Siguiente bloque
        MOVE.W          CONTC,PARTAM        
        BRA             ESPE                * Siguiente bloque
SALIR:  BRA             BUCPR               



BUS_ERROR:              BREAK               * Bus error handler
                        NOP
ADDRESS_ER:             BREAK               * Address error handler
                        NOP
ILLEGAL_IN:             BREAK               * Illegal instruction handler
                        NOP
PRIV_VIOLT:             BREAK               * Privilege violation handler
                        NOP



* Casos de pruebas
*********************************************************************************************
PLEE:   BSR             INIT
        LEA             BAR,A1
        LEA             CBAR,A4
        MOVE.B          #0,(A4)            * la pila deja de estar vacía
        LEA             $4(A1),A2          * A2 <- dir fin pila
        MOVE.L          (A2),A3
        MOVE.B          #$83,(A3)          * Pongo dato al final de pila
        MOVE.L          A3,D1              * D1 <- dir fin de pila
        ADD.L           #1,D1              * dir_fin<-dir_fin+1B
        MOVE.L          D1,(A2)            * actualizo dir_finin
        MOVE.B          #0,D0              * Descriptor param
        BSR             LEECAR
        BREAK

PLEE1:  BSR             INIT
        LEA             BAR,A1
        LEA             CBAR,A4
        MOVE.B          #0,(A4)            * la pila deja de estar vacía
        MOVE.L          A1,D2
        ADD.L           #2007,D2           *D2  <- ultima dir de pila
        MOVE.L          D2,(A1)
        MOVE.L          D2,A1
        MOVE.B          #$79,(A1)
        MOVE.B          #0,D0              * Descriptor param
        BSR             LEECAR
        BREAK

PLEE2:  BSR             INIT               * leo pila vacia
        MOVE.B          #0,D0              * Descriptor param
        BSR             LEECAR
        BREAK
		
PESC: 	BSR 		INIT
        LEA 		BBT,A1      
        MOVE.L 		A1,D1
        ADD.L 		#8,D1
        MOVE.L 		D1,A2
        MOVE.B 		#$43,(A2)+
        MOVE.B 		#$4F,(A2)+
        MOVE.B 		#$53,(A2)+
        MOVE.L 		A2,$4(A1)
        MOVE.B 		#$41,D1
        MOVE.B 		#3,D0
        BSR 		ESCCAR
        RTS
        BREAK
		
PESC2: 	BSR 		INIT            * escribo en pila llena (simulado)
        LEA 		BBR,A1
        LEA             CBBR,A4
        MOVE.B          #2,(A4)
        MOVE.L 		A1,D1
        ADD.L 		#8,D1
        MOVE.L 		D1,A2
        MOVE.B 		#$43,(A2)
        MOVE.B 		#$41,D1
        MOVE.L 		#1,D0
        BSR             ESCCAR
        BREAK

PESC3: 	BSR 		INIT            * escribo en pila llena (simulado)
        LEA 		BBR,A1
        LEA             CBBR,A4
        MOVE.B          #0,(A4)
        MOVE.L 		A1,D1
        ADD.L 		#2007,D1
        MOVE.L 		D1,A2
        MOVE.L          A2,$4(A1)
        MOVE.B 		#$43,D1
        MOVE.L 		#1,D0
        BSR             ESCCAR
        MOVE.B 		#$41,D1
        MOVE.L 		#1,D0
        BSR             ESCCAR
        BREAK

HITO1:  BSR             INIT     
        LEA             BBR,A5
        MOVE.W          #0,D5
EBUC:   CMP.W           #2001,D5
        BEQ             NOWLEE
        MOVE.B          #$13,D1
        MOVE.B          #1,D0
        BSR             ESCCAR
        ADD.W           #1,D5
        BRA             EBUC
NOWLEE: MOVE.W          #0,D5
BUCLEE: CMP.W           #2001,D5
        BEQ             ENDH1
        MOVE.B          #1,D0
        BSR             LEECAR
        ADD.W           #1,D5
        BRA             BUCLEE
ENDH1:  BREAK


HITO2:  BSR             INIT     
        LEA             BBR,A5
        MOVE.L          (A5),D2
        ADD.L           #1000,D2
        MOVE.L          D2,(A5)
        MOVE.L          D2,$4(A5)
        MOVE.W          #0,D5
EBUC2:  CMP.W           #2001,D5
        BEQ             NOWLE2
        MOVE.B          #$13,D1
        MOVE.B          #1,D0
        BSR             ESCCAR
        ADD.W           #1,D5
        BRA             EBUC2
NOWLE2: MOVE.W          #0,D5
BUCLE2: CMP.W           #2001,D5
        BEQ             ENDH2
        MOVE.B          #1,D0
        BSR             LEECAR
        ADD.W           #1,D5
        BRA             BUCLE2
ENDH2:  BREAK

HITO3:  BSR             INIT     
        LEA             BBR,A5
        MOVE.W          #2,D5
EBUC3:  CMP.W           #200,D5
        BEQ             NOWLE3

        MOVE.B          #0,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #1,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #2,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #3,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #$4,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #$5,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #$6,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #$7,D1
        MOVE.B          #1,D0
        BSR             ESCCAR


        MOVE.B          #$8,D1
        MOVE.B          #1,D0
        BSR             ESCCAR


        MOVE.B          #$9,D1
        MOVE.B          #1,D0
        BSR             ESCCAR
        ADD.W           #1,D5

        BRA             EBUC3


NOWLE3: MOVE.B          #1,D0
        BSR             LEECAR
        
        MOVE.B          #$01,D1
        MOVE.B          #1,D0
        BSR             ESCCAR

        MOVE.B          #$23,D1
        MOVE.B          #1,D0
        BSR             ESCCAR
        BREAK

PSCAN1: BSR            PESC  
        MOVE.W         #4,-(A7)
        MOVE.W         #1,-(A7)
        MOVE.L         #BUFFER,-(A7)
        BSR            SCAN
        BREAK

PSCAN2: BSR            PESC                 * tamaño mayor que lo que hay en buffer interno
        MOVE.W         #1999,-(A7)
        MOVE.W         #1,-(A7)
        MOVE.L         #BUFFER,-(A7)
        BSR            SCAN
        BREAK

PSCAN3: BSR            PESC                 * Descriptor erróneo
        MOVE.W         #1999,-(A7)
        MOVE.W         #2,-(A7)
        MOVE.L         #BUFFER,-(A7)
        BSR            SCAN
        BREAK

PRTI:   BSR PESC
        BSET #4,CIMR
        BSET #4,IMR
        ADD #2,D2
        ADD #2,D2
        BREAK

PRTI2:  BSR INIT
WAIT1:  BRA WAIT1
        BREAK
		
PPRINT1: BSR			INIT
		 MOVE.W 		#0,-(A7)			* Prueba con Tamaño = 0
		 MOVE.W 		#1,-(A7)
		 MOVE.L 		#BUFFER,-(A7)
		 BSR 			PRINT
		 BREAK

PPRINT2: BSR 			INIT
		 MOVE.L 		#BUFFER,A2			* Prueba Tamaño = 4
         MOVE.B 		#$43,(A2)+
		 MOVE.B 		#$41,(A2)+
		 MOVE.B         #$41,(A2)+
		 MOVE.B 		#$43,(A2)+
		 MOVE.W 		#4,-(A7)
		 MOVE.W 		#1,-(A7)
		 MOVE.L 		#BUFFER,-(A7)
		 BSR			PRINT
		 BREAK

PPRINT3: BSR			INIT
		 MOVE.L 		#BUFFER,A2			* Prueba con Error en Descriptor
         MOVE.B 		#$43,(A2)+
		 MOVE.B 		#$41,(A2)+
		 MOVE.W 		#2,-(A7)
		 MOVE.W 		#2,-(A7)
		 MOVE.L 		#BUFFER,-(A7)
		 BSR 			PRINT
		 BREAK
		 
PPRINT4: BSR 			PESC				* Prueba Tamaño = 8, habiendo ya caracteres en Buffer Interno
		 MOVE.B 		#0,D1
         MOVE.L 		#BUFFER,A2
         MOVE.B 		#$43,(A2)+
		 MOVE.B 		#$41,(A2)+
		 MOVE.B 		#$43,(A2)+
		 MOVE.B 		#$41,(A2)+
		 MOVE.B 		#$43,(A2)+
		 MOVE.B 		#$41,(A2)+
		 MOVE.B 		#$43,(A2)+
		 MOVE.B 		#$41,(A2)+
		 MOVE.W 		#8,-(A7)
		 MOVE.W 		#1,-(A7)
		 MOVE.L 		#BUFFER,-(A7)
		 BSR 			PRINT
		 BREAK
		 
PPRINT5: BSR			INIT
		 MOVE.L 		#BUFFER,A2			* Prueba que llena el Buffer Interno
		 MOVE.W 		#2000,D4
BUC:     CMP.W			#0,D4
		 BEQ 			FINBUC
         MOVE.B 		#$43,(A2)+
		 SUB.W 			#1,D4
		 BRA 			BUC
FINBUC:  MOVE.W 		#2000,-(A7)
		 MOVE.W 		#0,-(A7)
		 MOVE.L 		#BUFFER,-(A7)
		 BSR			PRINT
		 BREAK
		 

		 



**************************** INIT *************************************************************
INIT:   MOVE.L          #BUS_ERROR,8        * Bus error handler
        MOVE.L          #ADDRESS_ER,12      * Address error handler
        MOVE.L          #ILLEGAL_IN,16      * Illegal instruction handler
        MOVE.L          #PRIV_VIOLT,32      * Privilege violation handler
        MOVE.L          #ILLEGAL_IN,40      * Illegal instruction handler
        MOVE.L          #ILLEGAL_IN,44      * Illegal instruction handler
        MOVE.L          #ILLEGAL_IN,44      * Illegal instruction handler
        MOVE.B          #64,$effc19
        MOVE.L          #RTI,$100


        MOVE.B         #%0001000,CRA      * Reinicia el puntero MR1
        MOVE.B         #%00010000,CRB 
        MOVE.B         #%00000011,MR1A     * 8 bits por caracter.
        MOVE.B         #%00000011,MR1B     * 8 bits por caracter. 
        MOVE.B         #%00000000,MR2A     * Eco desactivado.
        MOVE.B         #%00000000,MR2B     * Eco desactivado. 
        MOVE.B         #%11001100,CSRA     * Velocidad = 38400 bps.
        MOVE.B         #%11001100,CSRB     * Velocidad = 38400 bps.
        MOVE.B         #%00000000,ACR      
        MOVE.B         #%00000101,CRA      
        MOVE.B         #%00000101,CRB 
        MOVE.B         #%00100010,CIMR
        MOVE.B         #%00100010,IMR      
             


        LEA            BAR,A1              * Cargo dirs de buffers
        LEA            BAT,A2
        LEA            BBR,A3
        LEA            BBT,A4
                                            * Procedo a inicializar punteros a principio y final de pila, de momento esta vacia
                                            * asi que principio = final
        MOVE.L          A1,D1               
        ADD.L           #8,D1               * D1 <-A1+8  
        MOVE.L          D1,(A1)             * M(A1) <-A1+8
        MOVE.L          D1,$4(A1)           * M(A1+2) <-A1+8 (El desplazamiento es a palabras 16b=1W; 2*16b=4B=1L)

        MOVE.L          A2,D1               
        ADD.L           #8,D1              
        MOVE.L          D1,(A2)            
        MOVE.L          D1,$4(A2)    

        MOVE.L          A3,D1               
        ADD.L           #8,D1              
        MOVE.L          D1,(A3)            
        MOVE.L          D1,$4(A3)    
        
        MOVE.L          A4,D1               
        ADD.L           #8,D1              
        MOVE.L          D1,(A4)            
        MOVE.L          D1,$4(A4)  

        LEA             CBAR,A1              * Cargo dirs de buffers
        LEA             CBAT,A2
        LEA             CBBR,A3
        LEA             CBBT,A4

        MOVE.B          #1,(A1)             * Pongo a 1 las vars de control de buffer
        MOVE.B          #1,(A2)
        MOVE.B          #1,(A3)
        MOVE.B          #1,(A4)

        MOVE.W          #$2000,SR
        RTS
**************************** FIN INIT *********************************************************



**************************** PRINT ************************************************************
PRINT:    MOVE.L          	4(A7),A2                  * Buffer
          MOVE.W          	8(A7),D2                  * Descriptor
          MOVE.W          	10(A7),D3                 * Tamaño
		  AND.W 			#0,D4					  * Contador
	      CMP.W  			#0,D3
	      BLT 			   	PFAIL
		  BEQ				WRITEE
	      CMP.W		   		#0,D2
	      BEQ 			   	PRINTA
	      CMP.W		   		#1,D2
	      BNE 			   	PFAIL
	      MOVE.W 		   	#3,D2
	      MOVE.W     		#16,D6					 	
	      BRA 			   	WRITEBU
PRINTA:   MOVE.W 			#1,D2
		  AND.W 			#0,D6					 	
WRITEBU:  CMP.W 			#0,D3
		  BEQ  				WRITEE
		  MOVE.B			(A2),D1
		  MOVE.B 			#0,(A2)+
		  LINK              A6,#-20
          MOVE.W            D4,-2(A6)                * Guardo contador  
          MOVE.W            D3,-4(A6)                * Guardo tamaño
          MOVE.L            A2,-8(A6)               * Guardo buffer 
		  MOVE.W			D6,-12(A6)				 * Guardo bit IMR
		  MOVE.B 			D1,-14(A6)				 * Guardo Caracter
		  MOVE.W 			D2,-18(A6)				 * Guardo Descriptor
          AND.L             #0,D0
          OR.L              D2,D0
		  BSR 				ESCCAR
		  AND.L             #0,D4                   * Necesito una suma con L y no puede haber basura en D4
		  MOVE.W 			-18(A6),D2
		  MOVE.B 			-14(A6),D1
		  MOVE.W 			-12(A6),D6
          MOVE.L            -8(A6),A2
          MOVE.W            -4(A6),D3
          MOVE.W            -2(A6),D4
          UNLK              A6
          CMP.L             #$FFFFFFFF,D0
          BEQ               WRITEE
          SUB.W             #1,D3        
          ADD.W             #1,D4
          BRA               WRITEBU
WRITEE:   MOVE.L            D4,D0
		  BSET				D6,CIMR
		  MOVE.B			CIMR,D5
		  MOVE.B 			D5,IMR    
          RTS  
PFAIL:    MOVE.L            #$FFFFFFFF,D0
          RTS                                                     
**************************** FIN PRINT ********************************************************



**************************** LEECAR ************************************************************
LEECAR: BTST            #0,D0
        BEQ             LEEA
        BTST            #1,D0
        BEQ             LLEEB
        LEA             BBT,A1             * A1 <- dir bus
        LEA             CBBT,A3            * A3 <- dir bits de control de buffer
        BRA             LCTR
LEEA:   BTST            #1,D0
        BEQ             LLEEA
        LEA             BAT,A1
        LEA             CBAT,A3            * A3 <- dir bits de control de buffer
        BRA             LCTR
LLEEA:  LEA             BAR,A1
        LEA             CBAR,A3            * A3 <- dir bits de control de buffer
        BRA             LCTR
LLEEB:  LEA             BBR,A1
        LEA             CBBR,A3            * A3 <- dir bits de control de buffer
LCTR:   MOVE.B          (A3),D6  
        BTST            #0,D6
        BNE             EMPTY
        MOVE.B          #0,(A3)            * Si no está vacía, como voy a leer, tampoco está llena     
        AND.L           #0,D0
        MOVE.L          (A1),A2
        MOVE.B          (A2),D0            * D0 <- M(dir_principio) = char
        MOVE.B          #0,(A2)+           * M(dir_principio) <- 0 ; dir_principio+=1
        MOVE.L          A1,D1
        ADD.L           #2008,D1           * A1+=2008B == fin de pila
        CMP.L           D1,A2              * si dir_principio == fin de pila => dir_principio == dir buffer+8
        BNE             LMOVE
        MOVE.L          A1,D4              * d4 <- A1
        ADD.L           #8,D4              * D4 <- primer_espacio_pila
        MOVE.L          D4,A2            * dir_principio = primer espacio_pila
LMOVE:  MOVE.L          A2,(A1)            * update dir_principio
        MOVE.L          $4(A1),A4
        CMP.L           A2,A4              * Si dir inicio == dir final => la pila se ha vaciado
        BNE             ENDL
        MOVE.B          #1,(A3)            * Como se ha vaciado pongo a 1 la var de control de pila
        BRA             ENDL
EMPTY:  MOVE.L          #$FFFFFFFF,D0
ENDL:   RTS
**************************** FIN LEECAR ************************************************************



**************************** ESCCAR ************************************************************
ESCCAR: BTST            #0,D0
        BEQ             ESCA
        BTST            #1,D0
        BEQ             ESCB
        LEA             BBT,A1             * A1 <- dir_bus
        LEA             CBBT,A3            * A3 <- dir bits de control de pila
        BRA             ECTR
ESCA:   BTST            #1,D0
        BEQ             ESCAR
        LEA             BAT,A1
        LEA             CBAT,A3            * A3 <- dir bits de control de pila
        BRA             ECTR
ESCAR:  LEA             BAR,A1
        LEA             CBAR,A3            * A3 <- dir bits de control de pila
        BRA             ECTR
ESCB:   LEA             BBR,A1
        LEA             CBBR,A3            * A3 <- dir bits de control de pila
ECTR:	MOVE.B          (A3),D6  
        BTST            #1,D6
        BNE		FULL
        MOVE.B          #0,(A3)            * Si no está llena, como voy a escribir, tampoco está vacía     
        MOVE.L 		$4(A1),A2			   * A2 <- dir_final
        MOVE.B 		D1,(A2)+		   * M(dir_final) <- char ;A2=A2+1
        MOVE.B 		#0,D0			   * D0 <- 0
        MOVE.L 		A1,D2			   * D2 <- dir_principio
        ADD.L 		#2008,D2		   * D2 <- D2+2008 == fin_pila
        CMP.L 		D2,A2			   * si dir_final == fin_pila => dir_principio == M(dir_bus+4)
        BNE 		EMOVE
        MOVE.L          A1,D4                           * D4 <- A1
        ADD.L           #8,D4              * D4 <- primer_espacio_pila
        MOVE.L          D4,A2              * dir_final = primer espacio_pila
EMOVE: 	MOVE.L 		A2,$4(A1)	   * actualizo dir_final
        MOVE.L          (A1),A4
        CMP.L           A2,A4              * Si dir inicio == dir final => la pila se ha llenado
        BNE             ENDE
        MOVE.B          #2,(A3)            * Como se ha llenado pongo a 2 la var de control de pila
        BRA             ENDE
FULL:	MOVE.L		#$FFFFFFFF,D0
ENDE:	RTS
**************************** FIN ESCCAR ************************************************************



**************************** SCAN ************************************************************
SCAN:   MOVE.L          4(A7),A1                  * Buffer
        MOVE.W          8(A7),D2                  * Descriptor
        MOVE.W          10(A7),D3                 * Tamaño
        CMP             #0,D3
        BLT             SFAIL
        CMP.W           #0,D2
        BEQ             SCANA
        CMP.W           #1,D2
        BNE             SFAIL
        MOVE.L          BBR,A2
        BRA             READBU
SCANA:  MOVE.L          BAR,A2
        AND.W           #0,D4                    * Contador 
READBU: CMP.W           #0,D3
        LINK            A6,#-14
        MOVE.W          D4,-2(A6)                * Guardo contador  
        MOVE.W          D3,-4(A6)                * Guardo tamaño
        MOVE.L          A2,-8(A6)                * Guardo buffer
        MOVE.L          A1,-12(A6)               * Guardo buffer interno
        AND.L           #0,D0
        OR.L            D2,D0
        BSR             LEECAR
        AND.L           #0,D4                   * Necesito una suma con L y no puede haber basura en D4
        MOVE.L          -12(A6),A1
        MOVE.L          -8(A6),A2
        MOVE.W          -4(A6),D3
        MOVE.W          -2(A6),D4
        UNLK            A6
        CMP.L           #$FFFFFFFF,D0
        BEQ             SCANE
        SUB.W           #1,D3
        MOVE.L          A1,A3
        ADD.L           D4,A3                   * Posicion del buffer  
        MOVE.B          D0,(A3)         
        ADD.W           #1,D4
        BRA             READBU
SCANE:  MOVE.L          D4,D0    
        RTS
SFAIL:  MOVE.L          #$FFFFFFFF,D0
        RTS
**************************** FIN SCAN ************************************************************

**************************** RTI **********************************************
RTI:    LINK            A6,#-48
        MOVE.L          D0,-4(A6)              
        MOVE.L          D1,-8(A6)              
        MOVE.L          D2,-12(A6)                
        MOVE.L          D3,-16(A6)             
        MOVE.L          D4,-20(A6)             
        MOVE.L          D5,-24(A6)             
        MOVE.L          A1,-28(A6)             
        MOVE.L          A2,-32(A6)             
        MOVE.L          A3,-36(A6)             
        MOVE.L          A4,-40(A6)             
        MOVE.L          A5,-44(A6)             

        MOVE.B          CIMR,D1
        MOVE.B          ISR,D2
        AND.B           D1,D2
        BTST            #1,D2                   * I viene de RBA
        BNE             IBAR
        BTST            #5,D2                   * I viene de RBB
        BNE             IBBR
        BTST            #0,D2                   * I viene de TAB
        BNE             IBAT                           
        MOVE.L          #3,D0                   * I viene de TBB
        BCLR            #4,CIMR
        MOVE.B          CIMR,D5
        MOVE.B          D5,IMR
        MOVE.L          #TBB,A5

TRANS:  BSR             LEECAR
        CMP.L           #$FFFFFFFF,D0
        BEQ             FINRTI
        MOVE.B          D0,(A5)
        BRA             FINRTI

REC:    BSR             ESCCAR

FINRTI: MOVE.L          -4(A6),D0           
        MOVE.L          -8(A6),D1             
        MOVE.L          -12(A6),D2                
        MOVE.L          -16(A6),D3           
        MOVE.L          -20(A6),D4           
        MOVE.L          -24(A6),D5           
        MOVE.L          -28(A6),A1           
        MOVE.L          -32(A6),A2
        MOVE.L          -36(A6),A3           
        MOVE.L          -40(A6),A4            
        MOVE.L          -44(A6),A5                
        UNLK            A6    
        RTE

IBAR:   MOVE.B          #0,D0
        MOVE.B          RBA,D1
        BRA             REC

IBAT:   BCLR            #0,CIMR
        MOVE.B          CIMR,D5
        MOVE.B          D5,IMR
        MOVE.B          #2,D0
        MOVE.L          #TBA,A5
        BRA             TRANS

IBBR:   MOVE.B          #1,D0
        MOVE.B          RBB,D1
        BRA             REC
      
**************************** FIN RTI ******************************************

**************************** PROGRAMA PRINCIPAL **********************************************

**************************** FIN PROGRAMA PRINCIPAL ******************************************