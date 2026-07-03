// SQLRDD++
// test with ODBC/Firebird
// To compile:
// hbmk2 odbcfirebird1

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.
// To use the command line parameters:
// odbcfirebird1 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> --client <options> --charset <charset>

STATIC s_ODBC_DRIVER   := "Firebird/InterBase(r) driver"
STATIC s_ODBC_SERVER   := "localhost"
STATIC s_ODBC_PORT     := "3050"
STATIC s_ODBC_UID      := "SYSDBA"
STATIC s_ODBC_PWD      := "masterkey"
STATIC s_ODBC_DATABASE := "C:\PATHTODATABASE\TEST.FDB"
STATIC s_ODBC_CLIENT   := "fbclient.dll"
STATIC s_ODBC_CHARSET  := "ISO8859_1"

#define RDD_NAME "SQLEX"
#define TABLE_NAME "test"
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
      CASE HB_PValue(n) == "--driver"   ; s_ODBC_DRIVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--server"   ; s_ODBC_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"     ; s_ODBC_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"      ; s_ODBC_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"      ; s_ODBC_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--database" ; s_ODBC_DATABASE := HB_PValue(++n)
      CASE HB_PValue(n) == "--client"   ; s_ODBC_CLIENT := HB_PValue(++n)
      CASE HB_PValue(n) == "--charset"  ; s_ODBC_CHARSET := HB_PValue(++n)
      ENDCASE
      ++n
   ENDDO

   rddSetDefault(RDD_NAME)

   nConnection := sr_AddConnection(CONNECT_ODBC, ;
      "driver="   + s_ODBC_DRIVER   + ";" + ;
      "server="   + s_ODBC_SERVER   + ";" + ;
      "port="     + s_ODBC_PORT     + ";" + ;
      "uid="      + s_ODBC_UID      + ";" + ;
      "pwd="      + s_ODBC_PWD      + ";" + ;
      "database=" + s_ODBC_DATABASE + ";" + ;
      "client="   + s_ODBC_CLIENT   + ";" + ;
      "charset="  + s_ODBC_CHARSET  + ";")

   IF nConnection < 0
      ? "Connection error. See sqlerror.log for details."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   IF !sr_ExistTable(TABLE_NAME)
      dbCreate(TABLE_NAME, {{"ID",      "N", 10, 0}, ;
                            {"FIRST",   "C", 30, 0}, ;
                            {"LAST",    "C", 30, 0}, ;
                            {"AGE",     "N",  3, 0}, ;
                            {"DATE",    "D",  8, 0}, ;
                            {"MARRIED", "L",  1, 0}, ;
                            {"VALUE",   "N", 12, 2}}, RDD_NAME)
   ENDIF

   USE (TABLE_NAME) EXCLUSIVE VIA (RDD_NAME)

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

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

RETURN
