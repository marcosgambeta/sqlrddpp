/*
* SQLRDD info
* Sample application to get extended database info
* Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"
#include "dbinfo.ch"

#define RECORDS_IN_TEST       100
#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

FUNCTION MAIN(cRDD, cDsn)

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
   ? "RDD in use          :", cRDD
   ? "Creating table"

   oSql := SR_GetConnection()

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

   ? "Workarea number :", i
   ? "RDD Version     :", dbInfo(DBI_RDD_VERSION)
   ? "RDD Build       :", dbInfo(DBI_RDD_BUILD)
   ? "Current table   :", dbInfo(DBI_FULLPATH)
   ? "Bof             :", dbInfo(DBI_BOF)
   ? "Eof             :", dbInfo(DBI_EOF)
   dbGoBottom()
   SKIP
   ? "Bof             :", dbInfo(DBI_BOF)
   ? "Eof             :", dbInfo(DBI_EOF)

   ? "Host Database   :", dbInfo(DBI_DB_VERSION), "(see sqlrdd.ch for details)"
   ? "WorkArea Object :", (i)->(dbInfo(DBI_INTERNAL_OBJECT):classname())
   ? "Connection Obj  :", (i)->(dbInfo(DBI_INTERNAL_OBJECT):oSql:classname())
   ? ""
   ? "Locking a, b    :", SR_SetLocks({"a", "b"})
   ? "RecSize()       :", RecSize()
   ? "RecCount()      :", RecCount()
   ? "OrdKeyCOunt()   :", OrdKeyCount()
   ? "OrdKeyNo()      :", OrdKeyNo()
   ? "SQLRDD Conn ID  :", SR_GetnConnection()
   ? "Connection ID   :", oSql:GetConnectionID()
   ? "Kill Connection :", oSql:KillConnectionID(9999)

   SET ORDER TO 2

   dbGoTop()

   ? "OrdKeyNo()      :", OrdKeyNo()
   dbSkip()
   ? "OrdKeyNo()      :", OrdKeyNo()

   ? ""
   ? "Press any key to quit"

   inkey(0)

RETURN

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
