/*
* SQLRDD Test
* Copyright (c) 2008 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"
#include "dbinfo.ch"

#define RECORDS_IN_TEST                   1000
#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

/*------------------------------------------------------------------------*/

FUNCTION Main(cDSN, lLog, cRdd)

   LOCAL aStruct := { ;
                     {"CODE_ID" , "C",  8, 0}, ;
                     {"CARDID"  , "C",  1, 0}, ;
                     {"DESCR"   , "C", 50, 0}, ;
                     {"PERCENT" , "N", 10, 2}, ;
                     {"DAYS"    , "N",  8, 0}, ;
                     {"DATE_LIM", "D",  8, 0}, ;
                     {"ENABLE"  , "L",  1, 0}, ;
                     {"OBS"     , "M", 10, 0}, ;
                     {"VALUE"   , "N", 18, 6} ;
                    }
   LOCAL nCnn
   LOCAL i

   IF Empty(cRdd)
      cRDD := "SQLRDD"
   ENDIF

   ? ""
   ? "filter.exe"
   ? ""
   ? "Smart SET FILTER demo"
   ? "(c) 2008 - Marcelo Lombardo"
   ? ""

   ? "Connecting to database..."

   Connect(cDSN)    // see connect.prg

   ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "Creating table      :", dbCreate("TEST_FILTER", aStruct, cRDD)

   USE "TEST_FILTER" EXCLUSIVE VIA (cRDD) CODEPAGE "ES850"

   REQUEST HB_CODEPAGE_ESWIN
   REQUEST HB_CODEPAGE_ES850

   ? "Creating 02 indexes..."
   ? DbInfo(DBI_CPID, "ES850")
   ? DbInfo(DBI_CPCONVERTTO, "ESWIN")

   INDEX ON CODE_ID + DESCR TO TEST_FILTER_IND01
   INDEX ON str(DAYS) + dtos(DATE_LIM) TO TEST_FILTER_IND02

   ? "Appending " + alltrim(str(RECORDS_IN_TEST)) + " records.."

   s := seconds()

   FOR i := 1 TO RECORDS_IN_TEST
      APPEND BLANK
      REPLACE CODE_ID  WITH strZero(i, 5)
      REPLACE DESCR    WITH dtoc(date()) + " - " + time()
      REPLACE DAYS     WITH (RECORDS_IN_TEST - i)
      REPLACE DATE_LIM WITH date()
      REPLACE ENABLE   WITH .T.
      REPLACE OBS      WITH "This is a memo field. Seconds since midnight : " + alltrim(str(seconds()))
   NEXT i

   ? "dbCloseArea()       :", dbCloseArea()

   USE "TEST_FILTER" SHARED VIA (cRDD)

   ? "Opening Indexes"
   SET INDEX TO TEST_FILTER_IND01
   SET INDEX TO TEST_FILTER_IND02 ADDITIVE

   SET FILTER TO DAYS < 10    // Very fast and optimized back end filter

   ? "Set Filter DAYS < 10:", dbFilter()     // Returning filter expression is translated to SQL
   ? " "
   ? "Press any key to browse()"

   inkey(0)
   CLEAR

   browse(row() + 1, 1, row() + 20, 80)

   CLEAR

   SET FILTER TO

   ? "Removing filter    :", dbFilter()
   ? "Press any key to browse()"

   inkey(0)
   CLEAR

   dbGoTop()
   browse(row() + 1, 1, row() + 20, 80)

   CLEAR

   SET FILTER TO MyFunc()    // Slow and non optimized filter

   ? "Set Filter MyFunc()  ", dbFilter()     // Returning filter expression is translated to SQL
   ? " "
   ? "Note this is pretty slower!"
   ? " "
   ? "Press any key to browse()"

   inkey(0)
   CLEAR

   browse(row() + 1, 1, row() + 20, 80)

   CLEAR
   SET FILTER TO
   ? "OrdKeyCount() ->" + Str(OrdKeyCount())
   SET SCOPE TO strZero(10, 5), strZero(20, 5)
   ? "SET SCOPE TO '" + strZero(10, 5) + "', '" + strZero(20, 5) + "'"
   DBGOTOP()
   ? "OrdKeyNo() ->" + Str(OrdKeyNo())
   ? "OrdKeyCount() ->" + Str(OrdKeyCount())
   ? "Press any key to browse()"

   inkey(0)
   CLEAR

   dbGoTop()
   browse(row() + 1, 1, row() + 20, 80)

   DbCloseAll()

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION MyFunc()

RETURN DAYS < 10

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
