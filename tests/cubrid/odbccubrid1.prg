// SQLRDD++
// test with ODBC/CUBRID
// To compile:
// hbmk2 odbccubrid1

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"

// To run the test:
// odbccubrid1 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> -rdd <rddname> --tablename <tablename> --newtable --droptable --records <num_records>
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
STATIC s_TABLE_NAME := "test"
STATIC s_NEW_TABLE  := .F.
STATIC s_DROP_TABLE := .F.
STATIC s_NUM_REC    := 100

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL cConnectionString

   hb_RandomSeed()

   SetMode(25, maxcol() + 1)

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--driver"    ; s_DRIVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--server"    ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"      ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--database"  ; s_DATABASE := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"       ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"       ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--rdd"       ; s_RDD_NAME := upper(HB_PValue(++n))
      CASE HB_PValue(n) == "--tablename" ; s_TABLE_NAME := HB_PValue(++n)
      CASE HB_PValue(n) == "--newtable"  ; s_NEW_TABLE := .T.
      CASE HB_PValue(n) == "--droptable" ; s_DROP_TABLE := .T.
      CASE HB_PValue(n) == "--records"   ; s_NUM_REC := val(HB_PValue(++n))
      OTHERWISE
         ? "Unknow parameter:", HB_PValue(n)
      ENDCASE
      ++n
   ENDDO

   rddSetDefault(s_RDD_NAME)

   cConnectionString := "DRIVER="   + s_DRIVER   + ";" + ;
                        "SERVER="   + s_SERVER   + ";" + ;
                        "PORT="     + s_PORT     + ";" + ;
                        "DB_NAME="  + s_DATABASE + ";" + ;
                        "UID="      + s_UID      + ";" + ;
                        "PWD="      + s_PWD      + ";"

   ? cConnectionString
   WAIT

   ? "Adding connection"

   nConnection := sr_AddConnection(CONNECT_ODBC, cConnectionString)

   ? "nConnection", nConnection

   IF nConnection < 0
      ? "Connection error. See sqlerror.log for details."
      WAIT
      QUIT
   ENDIF

   ? "Starting log"
   sr_StartLog(nConnection)

   IF s_NEW_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      ? "Removing table"
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   IF !sr_ExistTable(s_TABLE_NAME)
      ? "Creating table"
      dbCreate(s_TABLE_NAME, {{"ID",      "N", 10, 0}, ;
                              {"FIRST",   "C", 30, 0}, ;
                              {"LAST",    "C", 30, 0}, ;
                              {"AGE",     "N",  3, 0}, ;
                              {"DATE",    "D",  8, 0}, ;
                              {"MARRIED", "L",  1, 0}, ;
                              {"VALUE",   "N", 12, 2}}, s_RDD_NAME)

   ENDIF

   ? "Opening table"
   USE (s_TABLE_NAME) EXCLUSIVE VIA (s_RDD_NAME)

   ? "rddname()", rddname()
   ? "bof()=", bof()
   ? "eof()=", eof()
   ? "reccount()=", reccount()

   WAIT

   IF reccount() == 0
      ? "Adding records"
      FOR n := 1 TO s_NUM_REC
         ? "Adding record", n
         APPEND BLANK
         REPLACE ID      WITH n
         REPLACE FIRST   WITH "FIRST" + hb_ntos(n)
         REPLACE LAST    WITH "LAST" + hb_ntos(n)
         REPLACE AGE     WITH hb_RandomInt(18, 90) // n + 18
         REPLACE DATE    WITH date() - n
         REPLACE MARRIED WITH iif(n / 2 == int(n / 2), .T., .F.)
         REPLACE VALUE   WITH n * 1000 / 100 // TODO: browse dont show the decimals
         ? recno(), id, first, last, age, date, married, value
      NEXT n
   ENDIF

   ? "GO TOP"
   GO TOP
   ? "bof()=", bof()
   ? "eof()=", eof()
   ? "reccount()=", reccount()

   WAIT

   CLS

   browse()

   CLS

   ? "Closing database"
   CLOSE DATABASE

   IF s_DROP_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      ? "Removing table"
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   ? "Stoping log"
   sr_StopLog(nConnection)

   ? "Ending connection"
   sr_EndConnection(nConnection)

   WAIT

RETURN
