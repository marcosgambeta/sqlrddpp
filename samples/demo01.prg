/*
* SQLRDD Test
* Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"

#define RECORDS_IN_TEST                   1000
#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

/*------------------------------------------------------------------------*/

FUNCTION Main(cRDD, cDSN)

   LOCAL aStruct := { ;
                     {"CODE_ID" ,"C",  8, 0}, ;
                     {"CARDID"  ,"C",  1, 0}, ;
                     {"DESCR"   ,"C", 50, 0}, ;
                     {"PERCENT" ,"N", 10, 2}, ;
                     {"DAYS"    ,"N",  8, 0}, ;
                     {"DATE_LIM","D",  8, 0}, ;
                     {"ENABLE"  ,"L",  1, 0}, ;
                     {"OBS"     ,"M", 10, 0}, ;
                     {"VALUE"   ,"N", 18, 6} ;
                    }
   LOCAL nCnn
   LOCAL i

   SR_SETSQL2008NEWTYPES(.T.)
   ? ""
   ? "demo01.exe"
   ? ""
   ? "Small SQLRDD demo"
   ? "(c) 2003 - Marcelo Lombardo"
   ? ""

   ? "Connecting to database..."
   SR_SetMininumVarchar2Size(2)
   SR_SetOracleSyntheticVirtual(.F.)

   sr_usedeleteds(.F.)
   Connect(@cRDD, cDSN)    // see connect.prg

   ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "RDD in use          :", cRDD
   altd()
   ? "Creating table      :", dbCreate("test_table4", aStruct, cRDD)
   ? "Creating table      :", dbCreate("test_table41", aStruct, cRDD)
   USE "test_table41" NEW EXCLUSIVE VIA cRDD
   INDEX ON CODE_ID + DESCR            TAG test_table4_IND01
   INDEX ON str(DAYS) + dtos(DATE_LIM) TAG test_table4_IND02
   INDEX ON code_id + str(DAYS) + dtos(DATE_LIM) TAG test_table4_IND03

   USE "test_table4" NEW EXCLUSIVE VIA cRDD

   ? "Table opened. Alias :", select(), alias(), RddName()
   ? "Fieldpos(CODE_ID)   :", Fieldpos("CODE_ID")
   ? "Fieldpos(DESCR)     :", Fieldpos("DESCR")

   ? "Creating 02 indexes..."

   INDEX ON CODE_ID + DESCR            TO test_table4_IND01
   INDEX ON str(DAYS) + dtos(DATE_LIM) TO test_table4_IND02
   INDEX ON code_id + str(DAYS) + dtos(DATE_LIM) TO test_table4_IND03
   INDEX ON dtos(date_lim) TO test_table4_IND04

   ? "Appending " + alltrim(str(RECORDS_IN_TEST)) + " records.."

   s := seconds()

   FOR i := 1 TO RECORDS_IN_TEST
      APPEND BLANK
      REPLACE CODE_ID  WITH strZero(i, 5)
      REPLACE DESCR    WITH dtoc(date()) + " - " + time()
      REPLACE DAYS     WITH (RECORDS_IN_TEST - i)
      REPLACE DATE_LIM WITH date() + iif(i%2 == 0, 4, iif(i%3 == 0, 12, 3))
      REPLACE ENABLE   WITH .T.
      REPLACE OBS      WITH "This is a memo field. Seconds since midnight : " + alltrim(str(seconds()))
   NEXT i

   ? "dbClearIndex()      :", dbClearIndex()
   ? "dbCloseArea()       :", dbCloseArea()

   USE "test_table4" SHARED VIA cRDD

   ? "Opening Indexes"
   SET INDEX TO test_table4_IND01
   SET INDEX TO test_table4_IND02 ADDITIVE
   SET INDEX TO test_table4_IND03 ADDITIVE
   SET INDEX TO test_table4_IND04 ADDITIVE
   altd()
   SET ORDER TO 4
   ? "dbseek(dtos(date()), .T.)     ", dbseek(dtos(date()), .T.), date_lim
   ? "dbseek(dtos(date() + 4), .T.) ", dbseek(dtos(date() + 4), .T.), date_lim
   ? "dbseek(dtos(date() + 5), .T.) ", dbseek(dtos(date() + 5), .T.), date_lim
   ? "dbseek(dtos(date() + 12), .T.)", dbseek(dtos(date() + 12), .T.), date_lim
   ? "dbseek(dtos(date()))          ", dbseek(dtos(date())), date_lim
   ? "dbseek(dtos(date() + 4))      ", dbseek(dtos(date() + 4)), date_lim
   ? "dbseek(dtos(date() + 5))      ", dbseek(dtos(date() + 5)), date_lim
   ? "dbseek(dtos(date() + 12))     ", dbseek(dtos(date() + 12)), date_lim
   inkey(0)
   sr_starttrace()
   SET ORDER TO 1
   GO TOP
   BROWSE()
   SET ORDER TO 2
   GO TOP
   BROWSE()
   SET ORDER TO 3
   GO TOP
   BROWSE()

   ? "Set Order to 1      :", OrdSetFocus(1)
   ? "Seek                :", dbSeek("00002")

   ? "found()             :", found()
   ? "Recno(),bof(),eof() :", recno(), bof(), eof()
   ? "dbUnLock()          :", dbUnLock()
   ? "RLock(), dbRLockList:", rlock(), sr_showVector(dbRLockList())
   ? "Writes to the WA    :", FIELD->DESCR := "Hello, SQL!", FIELD->PERCENT  := 23.55
   ? "dbCommit()          :", dbCommit()
   ? " "
   ? "Press any key to browse()"

   inkey(0)
   CLEAR

   browse(row() + 1, 1, row() + 20, 80)

   CLEAR

   ? "Order 2, key is     :", OrdSetFocus(2), ordKey()

   OrdScope(0, str(RECORDS_IN_TEST / 4, 8))
   OrdScope(1, str(RECORDS_IN_TEST / 2, 8))

   ? "TOP Scope           :", OrdScope(0)
   ? "BOTTOM Scope        :", OrdScope(1)

   ? "Press any key to browse() with another index and scope"
   inkey(0)
   dbGoTop()
   CLEAR
   browse(row() + 1, 1, row() + 20, 80)

   SET SCOPE TO

   ? "Scope removed"
   ? "Press any key to browse()"
   inkey(0)

   dbGoTop()
   CLEAR
   browse(row() + 1, 1, row() + 20, 80)

RETURN NIL

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
