// SQLRDD++
// test with PostgreSQL
// To compile:
// hbmk2 pgsql4 -llibpq

#include "sqlrdd.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.
#define SERVER "localhost"
#define UID    "postgres"
#define PWD    "password"
#define DTB    "dbtest"

REQUEST SQLRDD
REQUEST SR_PGS

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL cQuery

   setMode(25, 80)

   rddSetDefault("SQLRDD")

   nConnection := sr_AddConnection(CONNECT_POSTGRES, "PGS=" + SERVER + ";UID=" + UID + ";PWD=" + PWD + ";DTB=" + DTB)

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
      alert("before INDEX ON...=" + alltrim(str(ordCount()))) // =0
      INDEX ON ID TO TESTIDX1
      INDEX ON FIRST TO TESTIDX2
      INDEX ON LAST TO TESTIDX3
      INDEX ON DATE TO TESTIDX4
      INDEX ON MARRIED TO TESTIDX5
      alert("after INDEX ON...=" + alltrim(str(ordCount()))) // =5
      sr_DropIndex("TESTIDX5")
      alert("after DROPINDEX=" + alltrim(str(ordCount()))) // =5
   ENDIF

   CLOSE DATABASE

   USE test VIA "SQLRDD" ALIAS test

   alert("after USE...=" + alltrim(str(ordCount()))) // =4

   dbSetOrder(3) // LAST

   browse()

   CLOSE DATABASE

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

RETURN
