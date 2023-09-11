// SQLRDD
// test with MySQL
// To compile:
// hbmk2 mysql2 ../sqlrddpp.hbc -llibmysql

#include "sqlrdd.ch"
#include "inkey.ch"

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
   LOCAL oTB
   LOCAL nKey

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

   oTB := TBrowseDB(0, 0, maxrow(), maxcol())

   oTB:addColumn(TBColumnNew("ID", {||TEST->ID}))
   oTB:addColumn(TBColumnNew("FIRST", {||TEST->FIRST}))
   oTB:addColumn(TBColumnNew("LAST", {||TEST->LAST}))
   oTB:addColumn(TBColumnNew("AGE", {||TEST->AGE}))

   DO WHILE nKey != K_ESC
      dispbegin()
      DO WHILE !oTB:stabilize()
      ENDDO
      dispend()
      nKey := inkey(0)
      SWITCH nKey
      CASE K_UP
         oTB:up()
         EXIT
      CASE K_DOWN
         oTB:down()
         EXIT
      CASE K_LEFT
         oTB:left()
         EXIT
      CASE K_RIGHT
         oTB:right()
         EXIT
      CASE K_PGUP
         oTB:PageUp()
         EXIT
      CASE K_PGDN
         oTB:PageDown()
      ENDSWITCH
   ENDDO

   CLOSE DATABASE

RETURN
