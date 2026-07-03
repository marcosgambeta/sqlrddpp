// SQLRDD++
// test with ODBC/Firebird
// To compile:
// hbmk2 odbcfirebird1

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"

// Make a copy of this file and change the values below (if necessary) or pass the parameters via command line:
// odbcfirebird1 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> --client <options> --charset <charset> --tablename <tablename> --newtable --droptable
// NOTE: the database must exist before runnning the test.

STATIC s_DRIVER     := "Firebird/InterBase(r) driver"
STATIC s_SERVER     := "localhost"
STATIC s_PORT       := "3050"
STATIC s_UID        := "SYSDBA"
STATIC s_PWD        := "masterkey"
STATIC s_DATABASE   := "C:\PATHTODATABASE\TEST.FDB"
STATIC s_CLIENT     := "fbclient.dll"
STATIC s_CHARSET    := "ISO8859_1"
STATIC s_TABLE_NAME := "test"
STATIC s_NEW_TABLE  := .F.
STATIC s_DROP_TABLE := .F.

#define RDD_NAME "SQLEX"
#define NUM_REC 100

REQUEST SQLEX
REQUEST SR_ODBC

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n

   hb_RandomSeed()

   SetMode(25, maxcol() + 1)

   CLS

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--driver"    ; s_DRIVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--server"    ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"      ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"       ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"       ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--database"  ; s_DATABASE := HB_PValue(++n)
      CASE HB_PValue(n) == "--client"    ; s_CLIENT := HB_PValue(++n)
      CASE HB_PValue(n) == "--charset"   ; s_CHARSET := HB_PValue(++n)
      CASE HB_PValue(n) == "--tablename" ; s_TABLE_NAME := HB_PValue(++n)
      CASE HB_PValue(n) == "--newtable"  ; s_NEW_TABLE := .T.
      CASE HB_PValue(n) == "--droptable" ; s_DROP_TABLE := .T.
      ENDCASE
      ++n
   ENDDO

   rddSetDefault(RDD_NAME)

   nConnection := sr_AddConnection(CONNECT_ODBC, ;
      "driver="   + s_DRIVER   + ";" + ;
      "server="   + s_SERVER   + ";" + ;
      "port="     + s_PORT     + ";" + ;
      "uid="      + s_UID      + ";" + ;
      "pwd="      + s_PWD      + ";" + ;
      "database=" + s_DATABASE + ";" + ;
      "client="   + s_CLIENT   + ";" + ;
      "charset="  + s_CHARSET  + ";")

   IF nConnection < 0
      ? "Connection error. See sqlerror.log for details."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   IF s_NEW_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   IF !sr_ExistTable(s_TABLE_NAME)
      dbCreate(s_TABLE_NAME, {{"ID",      "N", 10, 0}, ;
                              {"FIRST",   "C", 30, 0}, ;
                              {"LAST",    "C", 30, 0}, ;
                              {"AGE",     "N",  3, 0}, ;
                              {"DATE",    "D",  8, 0}, ;
                              {"MARRIED", "L",  1, 0}, ;
                              {"VALUE",   "N", 12, 2}}, RDD_NAME)
   ENDIF

   USE (s_TABLE_NAME) EXCLUSIVE VIA (RDD_NAME)

   IF reccount() == 0
      FOR n := 1 TO NUM_REC
         APPEND BLANK
         REPLACE ID      WITH n
         REPLACE FIRST   WITH "FIRST" + hb_ntos(n)
         REPLACE LAST    WITH "LAST" + hb_ntos(n)
         REPLACE AGE     WITH hb_RandomInt(18, 90) // n + 18
         REPLACE DATE    WITH date() - n
         REPLACE MARRIED WITH iif(n / 2 == int(n / 2), .T., .F.)
         REPLACE VALUE   WITH n * 1000 / 100
      NEXT n
   ENDIF

   GO TOP

   browse()

   CLOSE DATABASE

   IF s_DROP_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

RETURN
