// SQLRDD++
// test with PostgreSQL
// To compile:
// hbmk2 pgsql1 -llibpq

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.

STATIC s_SERVER := "localhost"
STATIC s_UID    := "postgres"
STATIC s_PWD    := "password"
STATIC s_DTB    := "dbtest"

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "test"
#define NUM_REC 100

REQUEST SQLRDD
REQUEST SR_PGS

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n

   hb_RandomSeed()

   SetMode(25, maxcol() + 1)

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--server" ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"    ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"    ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--dtb"    ; s_DTB := HB_PValue(++n)
      ENDCASE
      ++n
   ENDDO

   rddSetDefault(RDD_NAME)

   nConnection := sr_AddConnection(CONNECT_POSTGRES, "PGS=" + s_SERVER + ";UID=" + s_UID + ";PWD=" + s_PWD + ";DTB=" + s_DTB)

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
