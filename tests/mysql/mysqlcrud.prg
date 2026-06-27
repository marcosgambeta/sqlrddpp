// SQLRDD++
// test with MySQL simulating CRUD
// To compile:
// hbmk2 mysqlcrud -llibmysql

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"
#include "inkey.ch"

// To run the test:
// mysqlcrud --server <servername> --port <port> --uid <username> --pwd <userpassword> --dtb <databasename> --newtable --droptable
// NOTE: the database must exist before runnning the test.

STATIC s_SERVER     := "localhost"
STATIC s_PORT       := "3306"
STATIC s_UID        := "root"
STATIC s_PWD        := "password"
STATIC s_DTB        := "dbtest"
STATIC s_NEW_TABLE  := .F.
STATIC s_DROP_TABLE := .F.

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "tabcrud"
#define NUM_REC 100

REQUEST SQLRDD
REQUEST SR_MYSQL

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL oTB
   LOCAL nKey

   hb_RandomSeed()

   SetMode(25, maxcol() + 1)

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--server"    ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"      ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"       ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"       ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--dtb"       ; s_DTB := HB_PValue(++n)
      CASE HB_PValue(n) == "--newtable"  ; s_NEW_TABLE := .T.
      CASE HB_PValue(n) == "--droptable" ; s_DROP_TABLE := .T.
      ENDCASE
      ++n
   ENDDO

   SET DELETED ON

   rddSetDefault(RDD_NAME)

   CLS

   nConnection := sr_AddConnection(CONNECT_MYSQL, "MySQL=" + s_SERVER + ";PORT=" + s_PORT + ";UID=" + s_UID + ";PWD=" + s_PWD + ";DTB=" + s_DTB)

   IF nConnection < 0
      ? "Connection error. See sqlerror.log for details."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   IF s_NEW_TABLE .AND. sr_ExistTable(TABLE_NAME)
      sr_DropTable(TABLE_NAME)
   ENDIF

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

#if 0
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
#endif

   GO TOP

   oTB := TBrowseDB(0, 0, maxrow() - 1, maxcol())

   oTB:addColumn(TBColumnNew("#", {||TABCRUD->(recno())}))
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
      CASE K_UP    ; oTB:up()          ; EXIT
      CASE K_DOWN  ; oTB:down()        ; EXIT
      CASE K_LEFT  ; oTB:left()        ; EXIT
      CASE K_RIGHT ; oTB:right()       ; EXIT
      CASE K_PGUP  ; oTB:PageUp()      ; EXIT
      CASE K_PGDN  ; oTB:PageDown()    ; EXIT
      CASE K_INS   ; addrecord(oTB)    ; EXIT
      CASE K_ENTER ; updaterecord(oTB) ; EXIT
      CASE K_DEL   ; deleterecord(oTB)
      ENDSWITCH
   ENDDO

   CLOSE DATABASE

   IF s_DROP_TABLE .AND. sr_ExistTable(TABLE_NAME)
      sr_DropTable(TABLE_NAME)
   ENDIF

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

RETURN

STATIC FUNCTION AddRecord(oTB)

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

   oTB:RefreshAll()

RETURN NIL

STATIC FUNCTION UpdateRecord(oTB)

   IF reccount() == 0
      RETURN NIL
   ENDIF

   REPLACE FIRST   WITH alltrim(FIRST) + " (modified)"
   REPLACE LAST    WITH alltrim(LAST) + " (modified)"
   REPLACE AGE     WITH AGE - 1
   REPLACE DATE    WITH DATE - 1
   REPLACE MARRIED WITH iif(MARRIED, .F., .T.)
   REPLACE VALUE   WITH VALUE * 2

   oTB:RefreshAll()

RETURN NIL

STATIC FUNCTION DeleteRecord(oTB)

   IF reccount() == 0
      RETURN NIL
   ENDIF

   DELETE

   oTB:RefreshAll()

RETURN NIL
