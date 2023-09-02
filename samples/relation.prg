/*
* SQLRDD RELATION Test
* Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"

#define RECORDS_IN_TEST         10
#define SQL_DBMS_NAME           17
#define SQL_DBMS_VER            18

/*------------------------------------------------------------------------*/

FUNCTION Main(cRDD, cDSN)

   /* CODE_ID is the primary key 1st key. See SQLRDD.CH for details about structure array */

   LOCAL aStruct1 := { ;
                      {"CODE_ID" , "C",  8, 0, .F., , , , , 1}, ;
                      {"CARDID"  , "C",  1, 0, .T.}, ;
                      {"DESCR"   , "C", 20, 0}, ;
                      {"PERCENT" , "N",  8, 2}, ;
                      {"DAYS"    , "N",  6, 0}, ;
                      {"DATE_LIM", "D",  8, 0}, ;
                      {"ENABLE"  , "L",  1, 0}, ;
                      {"OBS"     , "M", 10, 0}, ;
                      {"VALUE"   , "N", 18, 6} ;
                     }
   LOCAL aStruct2 := { ;
                      {"CODE_ID", "C",  8, 0, .F., , , , , 1}, ;
                      {"NAME"   , "C", 20, 0, .F.} ;
                     }

   /* NOTE: Its NOT necessary to have a primary key in the table, but this is a good consistency control */

   LOCAL nCnn
   LOCAL s
   LOCAL i
   LOCAL lRet
   LOCAL nSkipped := 0
   LOCAL cTableName1 := "MASTER"
   LOCAL cTableName2 := "TARGET"
   LOCAL nReg
   LOCAL nPos

   Connect(@cRDD, cDSN)    // see connect.prg

   ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "RDD in use          :", cRDD

   /* This code block can control how SQLRDD behaves to each table */
   /* This is needed because we cannot touch the dbUseArea() params */

   ? "Creating table 1    :", dbCreate(cTableName1, aStruct1, cRDD)
   ? "Creating table 2    :", dbCreate(cTableName2, aStruct2, cRDD)

   USE (cTableName1) SHARED VIA cRDD NEW
   ? "Alias               :", alias(), select()
   USE (cTableName2) SHARED VIA cRDD NEW
   ? "Alias               :", alias(), select()

   ? "Appending " + alltrim(str(RECORDS_IN_TEST)) + " records in " + cTableName1

   s := seconds()
   dbSelectArea(cTableName1)

   FOR i := 1 TO RECORDS_IN_TEST
      APPEND BLANK
      REPLACE CODE_ID  WITH strZero(i, 5)
      REPLACE DESCR    WITH dtoc(date()) + " - " + time()
      REPLACE DAYS     WITH (1000 - i)
      REPLACE DATE_LIM WITH date()
      REPLACE ENABLE   WITH .T.
      dbUnlock()                    // Recno() is valid only after UNLOCK or COMMIT
   NEXT i

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? "Appending " + alltrim(str(RECORDS_IN_TEST)) + " records in " + cTableName2

   s := seconds()
   dbSelectArea(cTableName2)

   FOR i := 1 TO RECORDS_IN_TEST
      APPEND BLANK
      REPLACE CODE_ID WITH strZero(i, 5)
      REPLACE NAME    WITH "Record # " + strzero(i, 5) + (dtoc(date()) + " - " + time())
      dbUnlock()                    // Recno() is valid only after UNLOCK or COMMIT
   NEXT i

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? "Creating 02 indexes in " + cTableName1

   s := seconds()
   dbSelectArea(cTableName1)

   INDEX ON CODE_ID+DESCR TO TEST_TABLE1_IND01   // No functions allowed in indexes, just fields
   INDEX ON DAYS+DATE_LIM TO TEST_TABLE1_IND02   // Merge any data types in index expressions

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? "Creating 02 indexes in " + cTableName2

   s := seconds()
   dbSelectArea(cTableName2)

   INDEX ON CODE_ID TO TEST_TABLE2_IND01   // No functions allowed in indexes, just fields
   ordcreate("TEST_TABLE2_IND02", "TAG_X", "substr(NAME,5)")    // Create two synthetic indexes
   ordcreate("TEST_TABLE2_IND02", "TAG_Y", "substr(NAME,15)")   // based in xBase expressions

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? "Opening Indexes"

   dbSelectArea(cTableName1)
   SET INDEX TO ("CODE_ID")
   SET INDEX TO ("DAYS+DATE_LIM") ADDITIVE
   SET ORDER TO 1

   SELECT 2
   SET INDEX TO ("CODE_ID")

   SET ORDER TO 1

   SELECT MASTER

   ? "Set Relation        :"
   SET RELATION TO CODE_ID INTO TARGET

   ? "dbRelation()        :", dbRelation(1)
   ? "dbRSelect()         :", dbRSelect(1)
   ? "dbGotop()           :", dbGotop(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "Deleting............:", MASTER->(dbDelete())
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME

   SET DELETED ON
   ? "Set DELETED ON      :"
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip(-1)          :", dbSkip(-1), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "TARGET found()      :", TARGET->(found())
   ? "-------------------------------------------------"
   ? "dbGotop()           :", alias(), dbGotop(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "-------------------------------------------------"
   ? "dbGoBottom()        :", alias(), dbGoBottom(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip(-1)          :", dbSkip(-1), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip()            :", dbSkip(), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip(-1)          :", dbSkip(-1), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME
   ? "dbSkip(-1)          :", dbSkip(-1), recno()
   ? "Record Contents     :", MASTER->CODE_ID, TARGET->CODE_ID, TARGET->NAME

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION dbzap()
   ZAP
RETURN

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
