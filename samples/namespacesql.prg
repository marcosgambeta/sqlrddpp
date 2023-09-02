/*
* SQLRDD namespace demo
* Copyright (c) 2008 - Marcelo Lombardo  <lombardo@uol.com.br>
* All Rights Reserved
*/

// NOTE: this code is not compatible with Harbour

#include "sqlrdd.ch"
#include "dbinfo.ch"

#define RECORDS_IN_TEST                    100
#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

FUNCTION MAIN(cRdd, cDsn)

   LOCAL aStruct := { ;
                     {"CODE_ID" , "C",  8, 0}, ;
                     {"CARDID"  , "C",  1, 0}, ;
                     {"DESCR"   , "C", 50, 0}, ;
                     {"PERCENT" , "N",  8, 2}, ;
                     {"DAYS"    , "N",  6, 0}, ;
                     {"DATE_LIM", "D",  8, 0}, ;
                     {"ENABLE"  , "L",  1, 0}, ;
                     {"OBS"     , "M", 10, 0}, ;
                     {"VALUE"   , "N", 18, 6} ;
                    }
   LOCAL cComm
   LOCAL apCode
   LOCAL cOut
   LOCAL nErr
   LOCAL nPos
   LOCAL vEmp := {}
   LOCAL nCnn
   LOCAL s
   LOCAL i
   LOCAL oSql

   Connect(@cRDD, cDSN)    // see connect.prg

   ? "Connected to ", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "Creating table"

   oSql   := SR_GetConnection()

   dbCreate("TEST_TABLE3", aStruct, cRDD)
   USE TEST_TABLE3 via cRDD
   INDEX ON CODE_ID TO TBL3_INDX
   INDEX ON CODE_ID TAG CODE_ID FOR DAYS < 20

   FOR i := 1 TO RECORDS_IN_TEST
      APPEND BLANK
      REPLACE CODE_ID  WITH strZero(i, 5)
      REPLACE DESCR    WITH dtoc(date()) + " - " + time()
      REPLACE DAYS     WITH (RECORDS_IN_TEST - i)
      REPLACE DATE_LIM WITH date()
      REPLACE ENABLE   WITH .T.
      REPLACE OBS      WITH "This is a memo field. Seconds since midnight : " + alltrim(str(seconds()))
   NEXT i

   dbGoTop()

   i := select()

   ? "RDD Version     :", dbInfo(DBI_RDD_VERSION)
   ? "RDD Build       :", dbInfo(DBI_RDD_BUILD)

   // Now lets play with NAMESPACES

   ? "SR_FILE()       :", sr_file("TEST_TABLE3")
   ? "FILE()          :", file("TEST_TABLE3")  // There is no phisical file with such name, should return .F.
   ? "SQLRDD.FILE()   :", sqlrdd.file("TEST_TABLE3")
   ? "Standard table structure"
   ? sr_showVector(dbStruct())

   WITH NAMESPACE SQLRDD
      ? "FILE()          :", file("TEST_TABLE3")  // now it will use SQLRDD's file(), should return .T.
      ? "GLOBAL.FILE()   :", global.file("TEST_TABLE3")  // back to original xHB file(), should return .F.
      ? "Extended table structure"
      ? sr_showVector(dbStruct())    // SQLRDD internal dbStruct() extended function
   END

   WAIT

RETURN

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
