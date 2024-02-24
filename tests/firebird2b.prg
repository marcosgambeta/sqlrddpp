// SQLRDD++
// test with Firebird 3
// To compile:
// hbmk2 firebird2b -lfbclient

#include "sqlrdd.ch"
#include "inkey.ch"

// Make a copy of this file and change the values below (if necessary).
// NOTE: the database will be created automatically.
#define SERVER ""
#define UID    "SYSDBA"
#define PWD    "masterkey"
#define DTB    "fb3dbtest2.fdb"

REQUEST SQLRDD
REQUEST SR_FIREBIRD3

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL oTB
   LOCAL nKey

   setMode(25, 80)

   rddSetDefault("SQLRDD")

   IF !file(DTB)
      fbcreatedb3(DTB, UID, PWD, NIL, NIL, NIL)
   ENDIF

   nConnection := sr_AddConnection(CONNECT_FIREBIRD3, "FIREBIRD=" + SERVER + ";UID=" + UID + ";PWD=" + PWD + ";DTB=" + DTB)

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

   oTB := TBrowseDB(0, 0, maxrow(), maxcol())

   oTB:addColumn(TBColumnNew("ID", {||TEST->ID}))
   oTB:addColumn(TBColumnNew("FIRST", {||TEST->FIRST}))
   oTB:addColumn(TBColumnNew("LAST", {||TEST->LAST}))
   oTB:addColumn(TBColumnNew("AGE", {||TEST->AGE}))
   oTB:addColumn(TBColumnNew("DATE", {||TEST->DATE}))
   oTB:addColumn(TBColumnNew("MARRIED", {||TEST->MARRIED}))
   oTB:addColumn(TBColumnNew("VALUE", {||TEST->VALUE}))

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
   
   sr_StopLog(nConnection)
   
   sr_EndConnection(nConnection)

RETURN
