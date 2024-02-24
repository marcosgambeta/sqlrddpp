// SQLRDD++
// test with ODBC/MariaDB
// To compile:
// hbmk2 odbcmariadb1

#include "sqlrdd.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.
#define ODBC_DRIVER   "MariaDB ODBC 3.1 Driver"
#define ODBC_SERVER   "localhost"
#define ODBC_PORT     "3306"
#define ODBC_UID      "root"
#define ODBC_PWD      "password"
#define ODBC_DATABASE "dbtest"
#define ODBC_OPTIONS  "TCPIP=1"

#define RDD_NAME "SQLEX"
#define TABLE_NAME "test"

REQUEST SQLEX
REQUEST SR_ODBC

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n

   setMode(25, 80)

   rddSetDefault(RDD_NAME)

   nConnection := sr_AddConnection(CONNECT_ODBC, ;
      "Driver="   + ODBC_DRIVER   + ";" + ;
      "Server="   + ODBC_SERVER   + ";" + ;
      "Port="     + ODBC_PORT     + ";" + ;
      "Database=" + ODBC_DATABASE + ";" + ;
      "Uid="      + ODBC_UID      + ";" + ;
      "Pwd="      + ODBC_PWD      + ";" + ;
      ""          + ODBC_OPTIONS  + ";")

   IF nConnection < 0
      alert("Connection error. See sqlerror.log for details.")
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
