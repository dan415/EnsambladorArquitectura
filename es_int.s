* Inicializa el SP y el PC
**************************
        ORG     $0
        DC.L    $8000           * Pila
        DC.L    PLEE            * PC

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







INICIO: MOVE.L          #BUS_ERROR,8        * Bus error handler
        MOVE.L          #ADDRESS_ER,12      * Address error handler
        MOVE.L          #ILLEGAL_IN,16      * Illegal instruction handler
        MOVE.L          #PRIV_VIOLT,32      * Privilege violation handler
        MOVE.L          #ILLEGAL_IN,40      * Illegal instruction handler
        MOVE.L          #ILLEGAL_IN,44      * Illegal instruction handler
        BSR             INIT
        MOVE.W          #$2000,SR           * Permite interrupciones
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
        LEA            BAR,A1
        LEA            $2(A1),A5          * A5 <- dir fin pila 
        MOVE.B          #$83,(A5)          * Pongo dato al final de pila
        MOVE.L          A5,D1              * D1 <- dir fin de pila
        ADD.L           #1,D1              * dir_fin<-dir_fin+1B
        MOVE.L          D1,(A5)            * actualizo dir_finin
        MOVE.B          #0,D0               * Descriptor param
        BSR             LEECAR
        BREAK




**************************** INIT *************************************************************
INIT:
        MOVE.B          #%00010000,CRA      * Reinicia el puntero MR1
        MOVE.B          #%00000011,MR1A     * 8 bits por caracter.
        MOVE.B          #%00000000,MR2A     * Eco desactivado.
        MOVE.B          #%11001100,CSRA     * Velocidad = 38400 bps.
        MOVE.B          #%00000000,ACR      * Velocidad = 38400 bps.
        MOVE.B          #%00000101,CRA      * Transmision y recepcion activados.
        LEA            BAR,A1              * Cargo dirs de buffers
        LEA            BAT,A2
        LEA            BBR,A3
        LEA            BBT,A4
                                            * Procedo a inicializar punteros a principio y final de pila, de momento esta vacia
                                            * asi que principio = final
        MOVE.L          A1,D1               
        ADD.L           $8,D1               * D1 <-A1+8  
        MOVE.L          D1,(A1)             * M(A1) <-A1+8
        MOVE.L          D1,$2(A1)           * M(A1+2) <-A1+8 (El desplazamiento es a palabras 16b=1W; 2*16b=4B=1L)

        MOVE.L          A2,D1               
        ADD.L           $8,D1              
        MOVE.L          D1,(A2)            
        MOVE.L          D1,$2(A2)    

        MOVE.L          A3,D1               
        ADD.L           $8,D1              
        MOVE.L          D1,(A3)            
        MOVE.L          D1,$2(A3)    
        
        MOVE.L          A4,D1               
        ADD.L           $8,D1              
        MOVE.L          D1,(A4)            
        MOVE.L          D1,$2(A4)  
        RTS
**************************** FIN INIT *********************************************************



**************************** PRINT ************************************************************
PRINT:  RTS                                 
**************************** FIN PRINT ********************************************************



**************************** LEECAR ************************************************************
LEECAR: BTST            #0,D0
        BEQ             LEEA
        BTST            #1,D0
        BEQ             LLEEB
        LEA             BBT,A1             * A1 <- dir bus
        BRA             LFIND
LEEA:   BTST            #1,D0
        BEQ             LLEEA
        LEA             BAT,A1
        BRA             LFIND
LLEEA:  LEA             BAR,A1
        BRA             LFIND
LLEEB:  LEA             BBR,A1 
LFIND:  MOVE.L          (A1),D1            * D1 <- M(BUS) = dir_principio
        MOVE.L          $2(A1),D2          * D2 <- M(BUS+2) = dir final
        CMP.L           D1,D2              * si D1==D2 => bus vacio
        BEQ             EMPTY
        MOVE.L          D1,A2              * A2 <- dir_principio
        MOVE.B          (A2),D0            * D0 <- M(dir_principio) = char
        MOVE.B          0,(A2)+           * M(dir_principio) <- 0 ; dir_principio+=1
        ADD.L           2008,A1           * A1+=2008B == fin de pila
        CMP.L           A1,A2              * si dir_principio == fin de pila => dir_principio == M(dir_bus+4)
        BNE             LMOVE
        SUB.L           2008,A1           * A1  <- dir bus
        MOVE.L          A1,D4              * d4 <- A1
        ADD.L           8,D4              * D4 <- primer_espacio_pila
        MOVE.L          D4,(A1)            * dir_principio = primer espacio_pila
        BRA             ENDL
LMOVE:  SUB.L           2008,A1           * A1 <- dir bus 
        MOVE.L          A2,(A1)            * update dir_principio
        BRA             ENDL
EMPTY:  MOVE.L          $FFFFFFFF,D0
ENDL:   RTS
**************************** FIN LEECAR ************************************************************



**************************** ESCCAR ************************************************************
ESCCAR: RTS
**************************** FIN ESCCAR ************************************************************



**************************** SCAN ************************************************************
SCAN:  RTS                                 
**************************** FIN SCAN ************************************************************



**************************** PROGRAMA PRINCIPAL **********************************************

**************************** FIN PROGRAMA PRINCIPAL ******************************************

