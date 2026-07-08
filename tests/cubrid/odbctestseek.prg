// SQLRDD++
// test with ODBC/CUBRID
// To compile:
// hbmk2 odbctestseek

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"

// Make a copy of this file and change the values below or use the command line parameters.
// To run the test:
// odbccubrid1 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> -rdd <rddname> --tablename <tablename> --newtable --droptable --records <num_rec> --times <num_times>
// NOTE: the database must exist before runnning the test.

REQUEST SQLRDD
REQUEST SQLEX
REQUEST SR_ODBC

STATIC s_DRIVER     := "CUBRID Driver"
STATIC s_SERVER     := "localhost"
STATIC s_PORT       := "33000"
STATIC s_DATABASE   := "sqlrdd"
STATIC s_UID        := "dba"
STATIC s_PWD        := ""
STATIC s_RDD_NAME   := "SQLRDD"
STATIC s_TABLE_NAME := "testseek"
STATIC s_NEW_TABLE  := .F.
STATIC s_DROP_TABLE := .F.
STATIC s_NUM_REC    := 1000
STATIC s_NUM_TIMES  := 1

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL nSeekFound
   LOCAL nSeekNotFound
   LOCAL nSeekFailed
   LOCAL nId
   LOCAL cName
   LOCAL dDate
   LOCAL nRand

   hb_RandomSeed()

   //SetMode(25, maxcol() + 1)

   //CLS

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--driver"    ; s_DRIVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--server"    ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"      ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"       ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"       ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--database"  ; s_DATABASE := HB_PValue(++n)
      CASE HB_PValue(n) == "--rdd"       ; s_RDD_NAME := upper(HB_PValue(++n))
      CASE HB_PValue(n) == "--tablename" ; s_TABLE_NAME := HB_PValue(++n)
      CASE HB_PValue(n) == "--newtable"  ; s_NEW_TABLE := .T.
      CASE HB_PValue(n) == "--droptable" ; s_DROP_TABLE := .T.
      CASE HB_PValue(n) == "--records"   ; s_NUM_REC := val(HB_PValue(++n))
      CASE HB_PValue(n) == "--times"     ; s_NUM_TIMES := val(HB_PValue(++n))
      ENDCASE
      ++n
   ENDDO

   rddSetDefault(s_RDD_NAME)

   nConnection := sr_AddConnection(CONNECT_ODBC, ;
      "DRIVER="   + s_DRIVER   + ";" + ;
      "SERVER="   + s_SERVER   + ";" + ;
      "PORT="     + s_PORT     + ";" + ;
      "DB_NAME="  + s_DATABASE + ";" + ;
      "UID="      + s_UID      + ";" + ;
      "PWD="      + s_PWD      + ";")

   IF nConnection < 0
      ? "Connection error. See sqlerror.log for details."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   IF s_NEW_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      ? "Removing indexes"
      sr_DropIndex("index1")
      sr_DropIndex("index2")
      sr_DropIndex("index3")
      sr_DropIndex("index4")
      ? "Removing table"
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   // TODO: add more data types
   IF !sr_ExistTable(s_TABLE_NAME)
      ? "Creating table"
      dbCreate(s_TABLE_NAME, {{"ID        ", "N", 10, 0}, ;
                              {"NAME      ", "C", 10, 0}, ;
                              {"DATE      ", "D",  8, 0}}, s_RDD_NAME)
      ? "Opening table"
      USE (s_TABLE_NAME) EXCLUSIVE VIA (s_RDD_NAME)
      ? "Creating indexes"
      INDEX ON ID TO index1
      INDEX ON NAME TO index2
      INDEX ON DATE TO index3
      INDEX ON NAME + dtos(DATE) TO index4
      ? "Closing table"
      USE
   ENDIF

   ? "Opening table"
   USE (s_TABLE_NAME) EXCLUSIVE VIA (s_RDD_NAME)
   ? "Opening indexes"
   SET INDEX TO index1, index2, index3, index4
   ? "rddname()", rddname()
   ? "bof()", bof()
   ? "eof()", eof()
   ? "reccount()", reccount()

   IF reccount() == 0 // < s_NUM_REC
      ? "Adding records"
      FOR n := 1 TO s_NUM_REC
         APPEND BLANK
         REPLACE ID WITH n
         REPLACE NAME WITH strzero(n, 10)
         REPLACE DATE WITH date() - n
      NEXT n
   ENDIF

   ? "Testing index 1 (ID)"
   SET ORDER TO 1
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO s_NUM_REC * s_NUM_TIMES
      // create a valid id
      nID := hb_RandomInt(1, s_NUM_REC)
      SEEK nID
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->ID == nId
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid id
      nID := hb_RandomInt(s_NUM_REC + 1, s_NUM_REC + s_NUM_REC)
      SEEK nId
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   ? "Testing index 1 (ID) with scope"
   SET ORDER TO 1
   SET SCOPE TO 101, (s_NUM_REC - 100)
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO s_NUM_REC * s_NUM_TIMES
      // create a valid id
      nID := hb_RandomInt(101, s_NUM_REC - 100)
      SEEK nID
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->ID == nId
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid id
      SWITCH hb_RandomInt(1, 3)
      CASE 1; nID := hb_RandomInt(1, 100); EXIT // key is valid, but out of scope
      CASE 2; nID := hb_RandomInt(s_NUM_REC - 100 + 1, s_NUM_REC); EXIT // key is valid, but out of scope
      CASE 3; nID := hb_RandomInt(s_NUM_REC + 1, s_NUM_REC + s_NUM_REC); EXIT // key is invalid
      ENDSWITCH
      SEEK nId
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")
   SET SCOPE TO

   ? "Testing index 2 (NAME)"
   SET ORDER TO 2
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO s_NUM_REC * s_NUM_TIMES
      // create a valid name
      cName := strzero(hb_RandomInt(1, s_NUM_REC), 10)
      SEEK cName
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->NAME == cName
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid name
      cName := strzero(hb_RandomInt(s_NUM_REC + 1, s_NUM_REC + s_NUM_REC), 10)
      SEEK cName
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   ? "Testing index 3 (DATE)"
   SET ORDER TO 3
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO s_NUM_REC * s_NUM_TIMES
      // create a valid date
      dDate := date() - hb_RandomInt(1, s_NUM_REC)
      SEEK dDate
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->DATE == dDate
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid date
      dDate := date() + hb_RandomInt(1, s_NUM_REC)
      SEEK dDate
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   ? "Testing index 4 (NAME+DTOS(DATE))"
   SET ORDER TO 4
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO s_NUM_REC * s_NUM_TIMES
      nRand := hb_RandomInt(1, s_NUM_REC)
      // create a valid name
      cName := strzero(nRand, 10)
      // create a valid date
      dDate := date() - nRand
      SEEK cName + dtos(dDate)
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->NAME == cName .AND. FIELD->DATE == dDate
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid name
      cName := strzero(hb_RandomInt(s_NUM_REC + 1, s_NUM_REC + s_NUM_REC), 10)
      // create a invalid date
      dDate := date() + hb_RandomInt(1, s_NUM_REC)
      SEEK cName + dtos(dDate)
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be s_NUM_REC * s_NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == s_NUM_REC * s_NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   IF s_DROP_TABLE
      ? "Removing indexes"
      sr_DropIndex("index1")
      sr_DropIndex("index2")
      sr_DropIndex("index3")
      sr_DropIndex("index4")
   ENDIF

   ? "Closing table"
   CLOSE DATABASE

   IF s_DROP_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      ? "Removing table"
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

   WAIT

RETURN
