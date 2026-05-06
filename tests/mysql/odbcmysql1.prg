// SQLRDD++
// test with ODBC/MySQL
// To compile:
// hbmk2 odbcmysql1

#include "sqlrdd.ch"

// To run the test:
// odbcmysql1 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> --options <options>
// NOTE: the database must exist before runnning the test.

#define RDD_NAME "SQLEX"
#define TABLE_NAME "test"

REQUEST SQLEX
REQUEST SR_ODBC

STATIC s_ODBC_DRIVER   := "MySQL ODBC 9.4 ANSI Driver"
STATIC s_ODBC_SERVER   := "localhost"
STATIC s_ODBC_PORT     := "3306"
STATIC s_ODBC_UID      := "root"
STATIC s_ODBC_PWD      := "password"
STATIC s_ODBC_DATABASE := "dbtest"
STATIC s_ODBC_OPTIONS  := "TCPIP=1"

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL cConnectionString

   SetMode(25, maxcol() + 1)

   n := 1
   DO WHILE n <= PCount()
      IF HB_PValue(n) == "--driver"
         ++n
         s_ODBC_DRIVER := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--server"
         ++n
         s_ODBC_SERVER := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--port"
         ++n
         s_ODBC_PORT := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--uid"
         ++n
         s_ODBC_UID := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--pwd"
         ++n
         s_ODBC_PWD := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--database"
         ++n
         s_ODBC_DATABASE := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--options"
         ++n
         s_ODBC_OPTIONS := HB_PValue(n)
         LOOP
      ENDIF
      ++n
   ENDDO

   rddSetDefault(RDD_NAME)

   cConnectionString := "Driver="   + s_ODBC_DRIVER   + ";" + ;
                        "Server="   + s_ODBC_SERVER   + ";" + ;
                        "Port="     + s_ODBC_PORT     + ";" + ;
                        "Database=" + s_ODBC_DATABASE + ";" + ;
                        "Uid="      + s_ODBC_UID      + ";" + ;
                        "Pwd="      + s_ODBC_PWD      + ";" + ;
                        ""          + s_ODBC_OPTIONS  + ";"

   Alert(cConnectionString)

   nConnection := sr_AddConnection(CONNECT_ODBC, cConnectionString)

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
