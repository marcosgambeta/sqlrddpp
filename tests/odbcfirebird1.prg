// SQLRDD
// test with ODBC/Firebird
// To compile:
// hbmk2 odbcfirebird1

#include "sqlrdd.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.
#define ODBC_DRIVER   "Firebird/InterBase(r) driver"
#define ODBC_SERVER   "localhost"
#define ODBC_PORT     "3050"
#define ODBC_UID      "SYSDBA"
#define ODBC_PWD      "masterkey"
#define ODBC_DATABASE "C:\PATHTODATABASE\TEST.FDB"
#define ODBC_CLIENT   "fbclient.dll"
#define ODBC_CHARSET  "ISO8859_1"

//REQUEST SQLRDD
REQUEST SQLEX
REQUEST SR_ODBC
//REQUEST SR_FIREBIRD3

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n

   setMode(25, 80)

   rddSetDefault("SQLRDD")

   nConnection := sr_AddConnection(CONNECT_ODBC, ;
      "driver="   + ODBC_DRIVER   + ";" + ;
      "server="   + ODBC_SERVER   + ";" + ;
      "port="     + ODBC_PORT     + ";" + ;
      "uid="      + ODBC_UID      + ";" + ;
      "pwd="      + ODBC_PWD      + ";" + ;
      "database=" + ODBC_DATABASE + ";" + ;
      "client="   + ODBC_CLIENT   + ";" + ;
      "charset="  + ODBC_CHARSET  + ";")

   IF nConnection < 0
      alert("Connection error. See sqlerror.log for details.")
      QUIT
   ENDIF
   
   sr_StartLog(nConnection)

   IF !sr_ExistTable("test")
      dbCreate("test", {{"ID",      "N", 10, 0}, ;
                        {"FIRST",   "C", 30, 0}, ;
                        {"LAST",    "C", 30, 0}, ;
                        {"AGE",     "N",  3, 0}, ;
                        {"DATE",    "D",  8, 0}, ;
                        {"MARRIED", "L",  1, 0}, ;
                        {"VALUE",   "N", 12, 2}}, "SQLRDD")
   ENDIF

   USE test EXCLUSIVE VIA "SQLRDD"

   IF reccount() < 100
      FOR n := 1 TO 100
         APPEND BLANK
         REPLACE ID      WITH n
         REPLACE FIRST   WITH "FIRST" + hb_ntos(n)
         REPLACE LAST    WITH "LAST" + hb_ntos(n)
         REPLACE AGE     WITH n + 18
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
