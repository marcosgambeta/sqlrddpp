// SQLRDD++
// test with ODBC/MySQL and Multithreading
// To compile:
// hbmk2 odbcmysql1 -mt

#include "sqlrdd.ch"

// To run the test:
// odbcmysql1 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> --options <options>
// NOTE: the database must exist before runnning the test.

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

   LOCAL n

   rddSetDefault("SQLEX")

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

   FOR n := 1 TO 10
      hb_threadstart(@connect(), n)
   NEXT n

   WAIT

RETURN

STATIC FUNCTION connect(nThread)

   LOCAL cConnectionString
   LOCAL nConnection

   ? "Thread#=", nThread

   cConnectionString := "Driver="   + s_ODBC_DRIVER   + ";" + ;
                        "Server="   + s_ODBC_SERVER   + ";" + ;
                        "Port="     + s_ODBC_PORT     + ";" + ;
                        "Database=" + s_ODBC_DATABASE + ";" + ;
                        "Uid="      + s_ODBC_UID      + ";" + ;
                        "Pwd="      + s_ODBC_PWD      + ";" + ;
                        ""          + s_ODBC_OPTIONS  + ";"

   ? "cConnectionString=", cConnectionString

   nConnection := sr_AddConnection(CONNECT_ODBC, cConnectionString)

   ? "nConnection=", nConnection

   IF nConnection < 0
      ? "Connection error. See sqlerror.log for details."
      RETURN NIL
   ENDIF

   sr_EndConnection(nConnection)

RETURN NIL
