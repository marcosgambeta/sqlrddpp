// SQLRDD++
// test with ODBC/MySQL and Multithreading
// To compile:
// hbmk2 odbcmysql2 -mt

#include "sqlrdd.ch"

// To run the test:
// odbcmysql2 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> --options <options>
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

   FOR n := 1 TO 3
      hb_threadstart(@connect(), n) // 3 connections per thread
   NEXT n

   WAIT

RETURN

STATIC FUNCTION connect(nThread)

   LOCAL cConnectionString
   LOCAL nConnection1
   LOCAL nConnection2
   LOCAL nConnection3

   //? "Thread#=", nThread

   cConnectionString := "Driver="   + s_ODBC_DRIVER   + ";" + ;
                        "Server="   + s_ODBC_SERVER   + ";" + ;
                        "Port="     + s_ODBC_PORT     + ";" + ;
                        "Database=" + s_ODBC_DATABASE + ";" + ;
                        "Uid="      + s_ODBC_UID      + ";" + ;
                        "Pwd="      + s_ODBC_PWD      + ";" + ;
                        ""          + s_ODBC_OPTIONS  + ";"

   //? "cConnectionString=", cConnectionString

   nConnection1 := sr_AddConnection(CONNECT_ODBC, cConnectionString)
   ? "Thread=", nThread, "nConnection1=", nConnection1
   IF nConnection1 < 0
      ? "Connection 1 error. See sqlerror.log for details."
   ENDIF

   nConnection2 := sr_AddConnection(CONNECT_ODBC, cConnectionString)
   ? "Thread=", nThread, "nConnection2=", nConnection2
   IF nConnection2 < 0
      ? "Connection 2 error. See sqlerror.log for details."
   ENDIF

   nConnection3 := sr_AddConnection(CONNECT_ODBC, cConnectionString)
   ? "Thread=", nThread, "nConnection3=", nConnection3
   IF nConnection3 < 0
      ? "Connection 3 error. See sqlerror.log for details."
   ENDIF

   IF nConnection1 > 0
      sr_EndConnection(nConnection1)
   ENDIF
   IF nConnection2 > 0
      sr_EndConnection(nConnection2)
   ENDIF
   IF nConnection3 > 0
      sr_EndConnection(nConnection3)
   ENDIF

RETURN NIL
