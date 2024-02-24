// SQLRDD++
// test with MySQL simulating CRUD
// To compile:
// hbmk2 mysqlcrud -llibmysql

#include "sqlrdd.ch"
#include "inkey.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.

#define MYSQL_SERVER     "localhost"
#define MYSQL_UID        "root"
#define MYSQL_PWD        "password"
#define MYSQL_DTB        "dbtest"

REQUEST SQLRDD
REQUEST SR_MYSQL

PROCEDURE Main()

   LOCAL nConnection
#if 0
   LOCAL n
#endif
   LOCAL oTB
   LOCAL nKey

   setMode(25, 80)

   SET DELETED ON

   rddSetDefault("SQLRDD")

   CLS

   nConnection := sr_AddConnection(CONNECT_MYSQL, "MySQL=" + MYSQL_SERVER + ";UID=" + MYSQL_UID + ";PWD=" + MYSQL_PWD + ";DTB=" + MYSQL_DTB)

   IF nConnection < 0
      alert("Connection error. See sqlerror.log for details.")
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   IF !sr_ExistTable("tabcrud")
      dbCreate("tabcrud", {{"ID",      "N", 10, 0}, ;
                           {"FIRST",   "C", 30, 0}, ;
                           {"LAST",    "C", 30, 0}, ;
                           {"AGE",     "N",  3, 0}, ;
                           {"DATE",    "D",  8, 0}, ;
                           {"MARRIED", "L",  1, 0}, ;
                           {"VALUE",   "N", 12, 2}}, "SQLRDD")
   ENDIF

   USE tabcrud EXCLUSIVE VIA "SQLRDD"

#if 0
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
#endif

   GO TOP

   oTB := TBrowseDB(0, 0, maxrow() - 1, maxcol())

   oTB:addColumn(TBColumnNew("ID", {||TABCRUD->ID}))
   oTB:addColumn(TBColumnNew("FIRST", {||TABCRUD->FIRST}))
   oTB:addColumn(TBColumnNew("LAST", {||TABCRUD->LAST}))
   oTB:addColumn(TBColumnNew("AGE", {||TABCRUD->AGE}))
   oTB:addColumn(TBColumnNew("DATE", {||TABCRUD->DATE}))
   oTB:addColumn(TBColumnNew("MARRIED", {||TABCRUD->MARRIED}))
   oTB:addColumn(TBColumnNew("VALUE", {||TABCRUD->VALUE}))

   oTB:HeadSep := "-"
   oTB:ColSep := "|"
   oTB:FootSep := "-"

   @ maxrow(), 0 SAY "INSERT=add record  ENTER=update record  DELETE=delete record  ESC=exit"

   nKey := 0

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
      CASE K_INS
         addrecord()
         oTB:RefreshAll()
         EXIT
      CASE K_ENTER
         updaterecord()
         oTB:RefreshAll()
         EXIT
      CASE K_DEL
         deleterecord()
         oTB:RefreshAll()
      ENDSWITCH
   ENDDO

   CLOSE DATABASE

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

RETURN

STATIC FUNCTION AddRecord()

   LOCAL n := reccount()

   ++n

   APPEND BLANK
   REPLACE ID      WITH n
   REPLACE FIRST   WITH "FIRST" + hb_ntos(n)
   REPLACE LAST    WITH "LAST" + hb_ntos(n)
   REPLACE AGE     WITH n + 18
   REPLACE DATE    WITH date() - n
   REPLACE MARRIED WITH iif(n / 2 == int(n / 2), .T., .F.)
   REPLACE VALUE   WITH n * 1000 / 100

RETURN NIL

STATIC FUNCTION UpdateRecord()

   REPLACE FIRST   WITH alltrim(FIRST) + " (modified)"
   REPLACE LAST    WITH alltrim(LAST) + " (modified)"
   REPLACE AGE     WITH AGE - 1
   REPLACE DATE    WITH DATE - 1
   REPLACE MARRIED WITH iif(MARRIED, .F., .T.)
   REPLACE VALUE   WITH VALUE * 2

RETURN NIL

STATIC FUNCTION DeleteRecord()

   DELETE

RETURN NIL
