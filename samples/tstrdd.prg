/*
* SQLRDD Test
* Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"

#xcommand DEFAULT <uVar1> := <uVal1> ;
               [, <uVarN> := <uValN> ] => ;
                  <uVar1> := IIf(<uVar1> == NIL, <uVal1>, <uVar1>) ;;
                [ <uVarN> := IIf(<uVarN> == NIL, <uValN>, <uVarN>); ]

#define RECORDS_IN_TEST                  10000
#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

/*------------------------------------------------------------------------*/

FUNCTION Main(nRDD, cPath, lRecreate, cDSN)

   LOCAL aStruct := { ;
                     {"CODE_ID" , "C",  8, 0}, ;
                     {"DESCR"   , "C", 50, 0}, ;
                     {"CARDID"  , "C",  1, 0}, ;
                     {"PERCENT" , "N", 10, 2}, ;
                     {"DAYS"    , "N",  8, 0}, ;
                     {"ENABLE"  , "L",  1, 0}, ;
                     {"VALUE"   , "N", 18, 6}, ;
                     {"OBS"     , "M", 10, 0}, ;
                     {"DATE_LIM", "D",  8, 0};
                    }
   LOCAL nCnn
   LOCAL i
   LOCAL cRDD
   LOCAL oSql
   LOCAL nMinTime
   LOCAL nIdealBuff
   LOCAL nTime
   LOCAL xVal
   LOCAL s

   PUBLIC cRDDName

//   REQUEST DBFNSX

   ? ""
   ? "tstRDD.exe [nRdd] [cPath]"
   ? "           1 => SQLRDD Extreme (default)"
   ? "           2 => SQLRDD"
   ? "           3 => DBFNTX"
   ? "           4 => DBFCDX"
   ? "           5 => DBFNSX"
   ? ""
   ? "RDD performance test"
   ? "(c) 2008 - Marcelo Lombardo"
   ? ""

   DEFAULT nRdd := "1"

   IF nRDD == NIL
      QUIT
   ENDIF

   DEFAULT cPath := "z:\temp\"      // We suggest a network drive to have a fair comparison
   DEFAULT lRecreate := .T.

   sr_useDeleteds(.F.)

   IF valtype(lRecreate) == "C"
      lRecreate := lRecreate $ "sSyY"
   ENDIF

   SWITCH Val(nRdd)
   CASE 2
      cRDD := "SQLRDD"
      cPath := ""
      EXIT
   CASE 3
      cRDD := "DBFNTX"
      EXIT
   CASE 4
      cRDD := "DBFCDX"
      EXIT
   CASE 5
      cRDD := "DBFNSX"
      EXIT
   OTHERWISE
      cRDD := "SQLEX"
      cPath := ""
   ENDSWITCH

   IF Val(nRdd) < 3
      ? "Connecting to database..."

      Connect(@cRDD, cDSN)    // see connect.prg
      ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)

      oSql := sr_GetConnection()
   ENDIF

   ? " "
   ? "Current RDD:", cRDD
   ? " "

   IF (!IIf("RDD" $ cRDD, ;
            sr_File(cPath + "TEST_TABLE_RDD_" + cRDD), ;
            File(cPath + "TEST_TABLE_RDD_" + cRDD + ".dbf"))) .OR. lRecreate

      ? "Creating table      :", dbCreate(cPath + "TEST_TABLE_RDD_" + cRDD, aStruct, cRDD)

      USE (cPath + "TEST_TABLE_RDD_" + cRDD) EXCLUSIVE VIA cRDD

      ? "Appending " + alltrim(str(RECORDS_IN_TEST)) + " records.."

      s := seconds() * 100

      FOR i := 1 TO RECORDS_IN_TEST
         APPEND BLANK
         REPLACE CODE_ID  WITH strZero(i, 5)
         REPLACE DESCR    WITH dtoc(date()) + " - " + strZero(i, 5) + " - " + time()
         REPLACE PERCENT  WITH i / (RECORDS_IN_TEST / 10)
         REPLACE DAYS     WITH (RECORDS_IN_TEST - i)
         REPLACE DATE_LIM WITH date()
         REPLACE CARDID   WITH "X"
         REPLACE ENABLE   WITH .T.
         REPLACE VALUE    WITH i / 10
         REPLACE OBS      WITH "This is a memo field. Seconds since midnight : " + alltrim(str(seconds())) + " record " + strZero(i, 5)
      NEXT i

      ? "Append performed in ", ((seconds() * 100) - s) / 100
      ? "Creating 02 indexes..."

      IF "CDX" $ cRDD
         INDEX ON CODE_ID + DESCR            TAG IND01
         INDEX ON str(DAYS) + dtos(DATE_LIM) TAG IND02
         INDEX ON CODE_ID + DESCR            TAG IND03 DESCEND
      ELSE
         INDEX ON CODE_ID + DESCR TO (cPath + "TEST_TABLE_RDD_IND01")
         INDEX ON str(DAYS)       TO (cPath + "TEST_TABLE_RDD_IND02") // + dtos(DATE_LIM)
         INDEX ON CODE_ID + DESCR TO (cPath + "TEST_TABLE_RDD_IND03") DESCEND
      ENDIF
      ? "dbClearIndex()      :", dbClearIndex()
      ? "dbCloseArea()       :", dbCloseArea()

   ELSE
      ? "Reusing existing table"
   ENDIF

   nMinTime   := 99999999999
   nIdealBuff := 0

   s := seconds() * 100

   FOR nBuffer := 1 TO 1

      USE (cPath + "TEST_TABLE_RDD_" + cRDD) SHARED VIA cRDD
      IF "CDX" $ cRDD
         SET INDEX TO (cPath + "TEST_TABLE_RDD_" + cRDD)
      ELSE
         SET INDEX TO (cPath + "TEST_TABLE_RDD_IND01")
         SET INDEX TO (cPath + "TEST_TABLE_RDD_IND02") ADDITIVE
         SET INDEX TO (cPath + "TEST_TABLE_RDD_IND03") ADDITIVE
      ENDIF

      FOR j := 1 TO 2

         ? "Starting pass:", j, "Elapsed time:", ((seconds() * 100) - s) / 100
         DoTest(j)

      NEXT j

      USE

   NEXT nBuffer

   ? " performing in ", ((seconds() * 100) - s) / 100

RETURN NIL

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/

FUNCTION DoTest(nLoop)

   PRIVATE lError := .F.
   PRIVATE s := seconds() * 100

   // DBGOTOP() / DBGOBOTTOM() test

   dbGotop()
   ChekStatusFlags3()

   dbGoBottom()
   ChekStatusFlags4()

   dbGotop()
   ChekStatusFlags3()

   dbGoBottom()
   ChekStatusFlags4()

   // DBGOTO() test

   DbGoTo(1)
   ChekStatusFlags1(1)

   DbGoTo(2)
   ChekStatusFlags1(2)

   DbGoTo(3)
   ChekStatusFlags1(3)

   DbGoTo(900)
   ChekStatusFlags1(900)

   DbGoTo(901)
   ChekStatusFlags1(901)

   DbGoTo(911)
   ChekStatusFlags1(911)

   DbGoTo(921)
   ChekStatusFlags1(921)

   DbSkip(1)
   ChekStatusFlags1(922)

   DbGoTo(RECORDS_IN_TEST + 1)

   DbSkip(-1)
   ChekStatusFlags1(RECORDS_IN_TEST)

   DbGoTo(RECORDS_IN_TEST + 1)
   ChekStatusFlags2()

   DbGoTo(0)
   ChekStatusFlags2()

   DbGoTo(RECORDS_IN_TEST)
   ChekStatusFlags1(RECORDS_IN_TEST)

   // SKIP permormance test

   FOR i := 1 TO fcount() - 7
      xVal := FieldGet(i)
   NEXT i

   SET ORDER TO 1

   dbGoTop()

   FOR i := 1 TO RECORDS_IN_TEST - 2

      dbSkip()

      IF recno() != i + 1
         ? "Skip para o registro errado()", i + 1, recno(), code_id
         lError := .T.
      ENDIF

      IF recno() != val(code_id)
         ? "Erro em dbSkip()", i, recno(), code_id
         lError := .T.
      ENDIF
      IF bof()
         ? "Erro - nao deveria estar em BOF()", recno()
         lError := .T.
      ENDIF
      IF eof()
         ? "Erro - nao deveria estar em EOF()", recno()
         lError := .T.
      ENDIF

      IF lError
         WAIT
         EXIT
      ENDIF

   NEXT i

   dbGoBottom()

   FOR i := RECORDS_IN_TEST TO 2 STEP -1

      dbSkip(-1)
      IF recno() != i - 1
         ? "Skip para o registro errado", i - 1, recno(), code_id
         lError := .T.
      ENDIF

      IF recno() != val(code_id)
         ? "Erro em dbSkip()", i, recno(), code_id
         lError := .T.
      ENDIF
      IF bof()
         ? "Erro - nao deveria estar em BOF()", recno()
         lError := .T.
      ENDIF
      IF eof()
         ? "Erro - nao deveria estar em EOF()", recno()
         lError := .T.
      ENDIF

      IF lError
         WAIT
         EXIT
      ENDIF

   NEXT i

   SET ORDER TO 0  // Natural order

   dbGoTop()

   FOR i := 1 TO RECORDS_IN_TEST - 2

      dbSkip()

      IF recno() != i + 1
         ? "Skip para o registro errado()", i + 1, recno(), code_id
         lError := .T.
      ENDIF

      IF recno() != val(code_id)
         ? "Erro em dbSkip()", i, recno(), code_id
         lError := .T.
      ENDIF
      IF bof()
         ? "Erro - nao deveria estar em BOF()", recno()
         lError := .T.
      ENDIF
      IF eof()
         ? "Erro - nao deveria estar em EOF()", recno()
         lError := .T.
      ENDIF

      IF lError
         WAIT
         EXIT
      ENDIF

   NEXT i

   dbGoBottom()

   FOR i := RECORDS_IN_TEST TO 2 STEP -1
      dbSkip(-1)
      IF recno() != i - 1
         ? "Skip para o registro errado()", i - 1, recno(), code_id
         lError := .T.
      ENDIF

      IF recno() != val(code_id)
         ? "Erro em dbSkip()", i, recno(), code_id
         lError := .T.
      ENDIF
      IF bof()
         ? "Erro - nao deveria estar em BOF()", recno()
         lError := .T.
      ENDIF
      IF eof()
         ? "Erro - nao deveria estar em EOF()", recno()
         lError := .T.
      ENDIF

      IF lError
         WAIT
         EXIT
      ENDIF
   NEXT i

   // Seek test

   SET ORDER TO 1

   FOR i := 1 TO RECORDS_IN_TEST

      IF !dbSeek(strZero(i, 5))
         ? "dbSeek() deveria retornar .T."
         lError := .T.
      ENDIF

      IF !found()
         ? "found() deveria retornar .T."
         lError := .T.
      ENDIF

      IF eof()
         ? "não deveria estar em eof()"
         lError := .T.
      ENDIF

      IF bof()
         ? "não deveria estar em bof()"
         lError := .T.
      ENDIF

      IF recno() != i
         ? "Posição de registro errado", i, recno(), code_id
         lError := .T.
      ENDIF

      IF code_id != strZero(i, 5)
         ? "Posição de registro errado", i, recno(), code_id
         lError := .T.
      ENDIF

      IF lError
         WAIT
         EXIT
      ENDIF

   NEXT i

   // Replace test

   dbGoTop()

   FOR i := 1 TO RECORDS_IN_TEST - 2

      REPLACE VALUE WITH nLoop + i

      dbSkip()

      IF recno() != i + 1
         ? "Skip para o registro errado após update", i + 1, recno(), code_id
         lError := .T.
      ENDIF

      IF recno() != val(code_id)
         ? "Erro em dbSkip() apos update", i, recno(), code_id
         lError := .T.
      ENDIF
      IF bof()
         ? "Erro - nao deveria estar em BOF() apos update", recno()
         lError := .T.
      ENDIF
      IF eof()
         ? "Erro - nao deveria estar em EOF() apos update", recno()
         lError := .T.
      ENDIF

      IF lError
         WAIT
         EXIT
      ENDIF

   NEXT i

   // Reverse Index test

   SET ORDER TO 3

   dbGoBottom()

   FOR i := 1 TO RECORDS_IN_TEST - 2

      dbSkip(-1)

      IF recno() != i + 1
         ? "Skip Reverse para o registro errado()", i + 1, recno(), code_id
         lError := .T.
      ENDIF

      IF recno() != val(code_id)
         ? "Erro em dbSkip(-1) on reverse index", i, recno(), code_id
         lError := .T.
      ENDIF
      IF bof()
         ? "Erro - nao deveria estar em BOF()", recno()
         lError := .T.
      ENDIF
      IF eof()
         ? "Erro - nao deveria estar em EOF()", recno()
         lError := .T.
      ENDIF

      IF lError
         WAIT
         EXIT
      ENDIF

   NEXT i

   SET ORDER TO 1

RETURN ((seconds() * 100) - s) / 100

/*------------------------------------------------------------------------*/

FUNCTION ChekStatusFlags1(nExpected)    // Check navigation not hitting TOP or BOTTOM

   LOCAL lError := .F.

   IF recno() != nExpected
      ? "Error: recno() in ChekStatusFlags1 is not the expected", recno(), nExpected
      lError := .T.
   ENDIF

   IF recno() != val(code_id)
      ? "Error: CODE_ID in ChekStatusFlags1 is not the expected", recno(), code_id
      lError := .T.
   ENDIF
   IF bof()
      ? "Error: Should not be at BOF() in ChekStatusFlags1", recno()
      lError := .T.
   ENDIF
   IF eof()
      ? "Error: Should not be at EOF() in ChekStatusFlags1", recno()
      lError := .T.
   ENDIF

   IF lError
      WAIT
   ENDIF

RETURN lError

/*------------------------------------------------------------------------*/

FUNCTION ChekStatusFlags2()      // Check phantom record condition for invalid DBGOTO()

   LOCAL lError := .F.

   IF recno() != RECORDS_IN_TEST + 1
      ? "Error: Should be at phantom record", recno(), code_id
      lError := .T.
   ENDIF
   IF !bof()
      ? "Should be at BOF() with phantom record", recno()
      lError := .T.
   ENDIF
   IF !eof()
      ? "Should be at EOF() with phantom record", recno()
      lError := .T.
   ENDIF

   IF lError
      WAIT
   ENDIF

RETURN lError

/*------------------------------------------------------------------------*/

FUNCTION ChekStatusFlags3()    // Check for TOP condition

   LOCAL lError := .F.
   LOCAL nExpected := 1

   IF recno() != nExpected
      ? "Error: Should be on first record, but is at", recno()
      lError := .T.
   ENDIF

   IF recno() != val(code_id)
      ? "Error: Invalid value for CODE_ID in first record:", code_id
      lError := .T.
   ENDIF
   IF bof()
      ? "Error: should not be in BOF() at top", recno()
      lError := .T.
   ENDIF
   IF eof()
      ? "Error: should not be in EOF() at top", recno()
      lError := .T.
   ENDIF

   IF lError
      WAIT
   ENDIF

RETURN lError

/*------------------------------------------------------------------------*/

FUNCTION ChekStatusFlags4()    // Check for BOTTOM condition

   LOCAL lError := .F.
   LOCAL nExpected := RECORDS_IN_TEST

   IF recno() != nExpected
      ? "Error: Should be at last record, but is at", recno()
      lError := .T.
   ENDIF

   IF recno() != val(code_id)
      ? "Error: Invalid value for CODE_ID in last record:", code_id
      lError := .T.
   ENDIF
   IF bof()
      ? "Error: should not be in BOF() at bottom", recno()
      lError := .T.
   ENDIF
   IF eof()
      ? "Error: should not be in EOF() at bottom", recno()
      lError := .T.
   ENDIF

   IF lError
      WAIT
   ENDIF

RETURN lError
