/*
* SQLRDD Test
* Copyright (c) 2009 - Miguel Angel Marchuet <miguelangel@marchuet.net>
* All Rights Reserved
*/

#include "sqlrdd.ch"
#include "dbinfo.ch"

#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

/*------------------------------------------------------------------------*/

FUNCTION Main(cDSN, lLog, cRdd)

   LOCAL aStruct := {{"DESCR", "C", 1, 0}}
   LOCAL nCnn
   LOCAL i

   IF Empty(cRdd)
      cRDD := "SQLRDD"
   ENDIF

   REQUEST HB_CODEPAGE_PLWIN
   REQUEST HB_CODEPAGE_PL852

   ? ""
   ? "codepage.exe"
   ? ""
   ? "CODEPAGE demo"
   ? "(c) 2009 - Miguel Angel Marchuet"
   ? ""

   ? "Connecting to database..."

   Connect(cDSN)    // see connect.prg

   ? "Connected to                    :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "Creating table                  :", dbCreate("TEST_CODEPAGE", aStruct, cRDD)

   ? ""
   hb_SetCodePage("PLWIN")
   ? "SetCodePage aplicattion to PLWIN:"
   ? ""

   USE "TEST_CODEPAGE" EXCLUSIVE VIA (cRDD) CODEPAGE "PL852"
   ? "Creating 01 index..."
   INDEX ON DESCR TO TEST_CODEPAGE_IND01
   ? "Appending records.."

   s := seconds()

   FOR i := 33 TO 128
      APPEND BLANK
      REPLACE DESCR WITH Chr(i)
   NEXT i

   ? "dbCloseArea()       :", dbCloseArea()

   USE "TEST_CODEPAGE" SHARED VIA (cRDD)
   ? "Open table with codepage " + DbInfo(DBI_CPID, "PL852")
   ? "Opening Indexes"
   SET INDEX TO TEST_CODEPAGE_IND01

   ? " "
   ? "Press any key to browse()"

   inkey(0)
   CLEAR

   browse(row() + 1, 1, row() + 20, 80)

   CLEAR

   DbCloseAll()

RETURN NIL

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
