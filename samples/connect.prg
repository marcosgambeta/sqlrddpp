/* IMPORTANT: THIS FILE IS NOT TO BE USED DIRECTLY. YOU SHOULD INCLUDE IT IN PROPER APPLICATION PRG FILE
              AS SHOWN IN DEMO01.PRG, PARSER2.PRG, MEMO.PRG, ETC., AND CALL CONNECT() FUNCTION.
*/

/*
* SQLRDD connection
* Sample applications connect routine
* Copyright (c) 2005 - Marcelo Lombardo  <lombardo@uol.com.br>
* All Rights Reserved
*/

#include "pgs.ch"          // Needed if you plan to use native connection to Postgres
#include "mysql.ch"        // Needed if you plan to use native connection to MySQL
#include "oracle.ch"       // Needed if you plan to use native connection to Oracle
#include "firebird.ch"     // Needed if you plan to use native connection to Firebird

REQUEST SQLRDD             // SQLRDD should be linked in
REQUEST SQLEX              // SQLRDD Extreme should be linked in

REQUEST SR_ODBC            // Needed if you plan to connect with ODBC
REQUEST SR_PGS             // Needed if you plan to use native connection to Postgres
REQUEST SR_MYSQL           // Needed if you plan to use native connection to MySQL
REQUEST SR_ORACLE          // Needed if you plan to use native connection to Oracle
REQUEST SR_FIREBIRD        // Needed if you plan to use native connection to Firebird

REQUEST DBFNTX
REQUEST DBFCDX
REQUEST DBFFPT
REQUEST DBFDBT

/*------------------------------------------------------------------------*/

FUNCTION Connect(cRDD, cDatabase)

   LOCAL nCnn
   LOCAL nDrv
   LOCAL cDriver
   LOCAL nOpt
   LOCAL nDetected
   LOCAL hIniFile
   LOCAL aKeys
   LOCAL nKey
   LOCAL cConnString
   LOCAL oldScreen
   LOCAL hDsn

   Public cRDDName

   SetMode(35, 80)

   hIniFile := HB_ReadIni("sqlrdd.ini", .F., ,.F.)     // Read ini file in a hash table

   IF hIniFile == NIL
      ? "Could not read from sqlrdd.ini"
      QUIT
   ENDIF

   IF cDatabase == NIL
      aKeys := HGetKeys(hIniFile)
      IF len(aKeys) == 0
         ? "No connections available in sqlrdd.ini"
         QUIT
      ELSEIF len(aKeys) == 1
         nKey := 1
      ELSE
         CLEAR SCREEN
         @ 5, 1 SAY PadC("Choose connection option", 80)
         nKey := achoice(5, 20, 22, 60, aKeys)
         CLEAR SCREEN

         IF nKey == 0
            ? "No connection selected"
            QUIT
         ENDIF
      ENDIF

      hDsn := HGetValueAt(hIniFile, nKey)

      IF !("CONNSTRING" $ hDsn)
         ? "ConnString not found in " + aKeys[nKey]
         QUIT
      ENDIF
   ELSE
      IF !(cDatabase $ hIniFile)
         ? "Connection [" + cDatabase + "] not found in sqlrdd.ini"
         QUIT
      ENDIF

      hDsn := hIniFile[cDatabase]

      IF !("CONNSTRING" $ hDsn)
         ? "ConnString not found in " + cDatabase
         QUIT
      ENDIF
   ENDIF

   cConnString := hDsn["CONNSTRING"]
   nDetected   := DetectDBFromDSN(cConnString)

   IF nDetected > SYSTEMID_UNKNOW
      ? "Connecting to", cConnString
      nCnn := SR_AddConnection(nDetected, cConnString)
   ELSE
      CLEAR SCREEN
      nOpt := Alert("Please, select connection type", {"ODBC", "Postgres", "MySQL", "Oracle", "Firebird"})
      IF nOpt > 0
         nCnn := SR_AddConnection(IIf(nOpt == 1, CONNECT_ODBC, iif(nOpt == 2, CONNECT_POSTGRES, iif(nOpt == 3, CONNECT_MYSQL, iif(nOpt == 4, CONNECT_ORACLE, CONNECT_FIREBIRD)))), cConnString)
      ELSE
         ? "No connection type selected"
         QUIT
      ENDIF
   ENDIF

   /* returns the connection handle or -1 if it fails */
   IF nCnn < 0
      ? "Connection error. See sqlerror.log for details."
      QUIT
   ENDIF

   IF valtype(cRDD) == "C"
      cRDD := alltrim(Upper(cRDD))
   ENDIF

   IF cRDD == NIL
      i := alert("Please select RDD", {"Automatic", "SQLRDD Extreme", "SQLRDD"})
      IF i == 1 .AND. SR_GetConnection():nConnectionType == CONNECT_ODBC
         cRDD := "SQLEX"
      ELSEIF i == 1
         cRDD := "SQLRDD"
      ELSEIF i == 2
         cRDD := "SQLEX"
      ELSEIF i == 3
         cRDD := "SQLRDD"
      ELSE
         QUIT
      ENDIF
   ENDIF

   IF SR_GetConnection():nConnectionType != CONNECT_ODBC .AND. cRDD == "SQLEX"
      Alert("SQLRDD Extreme supports only ODBC connections.", {"Quit"})
      QUIT
   ENDIF

RETURN .T.

/*------------------------------------------------------------------------*/
