// SQLRDD
// test with MySQL
// To compile:
// hbmk2 mysql1 ../sqlrddpp.hbc -llibmysql

#include "sqlrdd.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.
#define SERVER "localhost"
#define UID    "root"
#define PWD    "password"
#define DTB    "dbtest"

REQUEST SQLRDD
REQUEST SQLEX
REQUEST SR_MYSQL

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n

   setMode(25, 80)

   rddSetDefault("SQLRDD")

   nConnection := sr_AddConnection(CONNECT_MYSQL, "MySQL=" + SERVER + ";UID=" + UID + ";PWD=" + PWD + ";DTB=" + DTB)

   IF !sr_ExistTable("test")
      dbCreate("test", {{"ID", "N", 10, 0}, {"FIRST", "C", 30, 0}, {"LAST", "C", 30, 0}, {"AGE", "N", 3, 0}}, "SQLRDD")
   ENDIF

   USE test EXCLUSIVE VIA "SQLRDD"

   IF recno() < 100
      FOR n := 1 TO 100
         APPEND BLANK
         REPLACE ID    WITH n
         REPLACE FIRST WITH "FIRST" + hb_ntos(n)
         REPLACE LAST  WITH "LAST" + hb_ntos(n)
         REPLACE AGE   WITH n + 18
      NEXT n
   ENDIF

   GO TOP

   browse()

   CLOSE DATABASE

RETURN
