// SQLRDD++
// test with MySQL
// To compile:
// hbmk2 mysql1 -llibmysql

#include "sqlrdd.ch"

// To run the test:
// mysql1 --server <servername> --uid <username> --pwd <userpassword> --dtb <databasename>
// NOTE: the database must exist before runnning the test.

REQUEST SQLRDD
REQUEST SQLEX
REQUEST SR_MYSQL

STATIC s_SERVER := "localhost"
STATIC s_UID    := "root"
STATIC s_PWD    := "password"
STATIC s_DTB    := "dbtest"

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n

   SetMode(25, maxcol() + 1)

   n := 1
   DO WHILE n <= PCount()
      IF HB_PValue(n) == "--server"
         ++n
         s_SERVER := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--uid"
         ++n
         s_UID := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--pwd"
         ++n
         s_PWD := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--dtb"
         ++n
         s_DTB := HB_PValue(n)
         LOOP
      ENDIF
      ++n
   ENDDO

   rddSetDefault("SQLRDD")

   nConnection := sr_AddConnection(CONNECT_MYSQL, "MySQL=" + s_SERVER + ";UID=" + s_UID + ";PWD=" + s_PWD + ";DTB=" + s_DTB)

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
