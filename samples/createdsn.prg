/*
* SQLRDD Create Dynamic DSN
* Sample application to create an ODBC panel entry
* Copyright (c) 2006 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"
#include "dbinfo.ch"

#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

FUNCTION MAIN(cDsn)

   LOCAL nDetected
   LOCAL cConnString
   LOCAL cAtributes
   LOCAL cDriver
   LOCAL i

   CLEAR SCREEN

   Alert("This sample works only with MSSQL Server under Windows. Changing 'cDriver' and 'cAtributes' you can adapt to other databases.")

   ? "This will create a System DSN named " + chr(34) + "xHB001" + chr(34) + " in ODBC panel to access Nothwind sample database in MSSQL Server"

   cAtributes := "DSN=xHB001;Description=xHB Test;Server=.;Database=Northwind;UseProcForPrepare=Yes;Trusted_Connection=Yes;AnsiNPW=Yes;"
   cDriver    := "SQL Server"

   IF SR_InstallDSN(cDriver, cAtributes)

      Alert("If you go to ODBC setup panel you should find created DSN. Hit ok to try to connect to data source.")

      cConnString := "DSN=xHB001"
      nDetected   := DetectDBFromDSN(cConnString)

      IF nDetected > SYSTEMID_UNKNOW
         ? "Connecting to", cConnString
         IF SR_AddConnection(nDetected, cConnString) > 0
            ? "Connected to ", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
         ELSE
            ? "Connection failure"
         ENDIF
      ENDIF
   ELSE
      ? "DSN creation failure:"
      FOR i := 1 TO 8
         ? SR_InstallError(i)
      NEXT i
   ENDIF

   ? ""
   ? "Press any key to quit"

   inkey(0)

RETURN

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/