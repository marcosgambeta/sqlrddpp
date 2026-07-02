// SQLRDD++
// test with Firebird 5
// To compile:
// hbmk2 firebird2b -lfbclient

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"
#include "inkey.ch"

// Make a copy of this file and change the values below (if necessary).
// NOTE: the database will be created automatically.

STATIC s_SERVER := ""
STATIC s_UID    := "SYSDBA"
STATIC s_PWD    := "masterkey"
STATIC s_DTB    := "fb5dbtest2.fdb"

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "test"
#define NUM_REC 100

REQUEST SQLRDD
REQUEST SR_FIREBIRD5

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL oTB
   LOCAL nKey

   hb_RandomSeed()

   SetMode(25, maxcol() + 1)

   CLS

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

   IF !file(s_DTB)
      //SR_fbcreatedb5(s_DTB, s_UID, s_PWD, NIL, NIL, NIL) (deprecated)
      SR_FIREBIRD5():CreateDatabase(s_DTB, s_UID, s_PWD, NIL, NIL, NIL)
   ENDIF

   nConnection := sr_AddConnection(CONNECT_FIREBIRD5, "FIREBIRD=" + s_SERVER + ";UID=" + s_UID + ";PWD=" + s_PWD + ";DTB=" + s_DTB)

   IF nConnection < 0
      alert("Connection error. See sqlerror.log for details.")
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

   oTB := TBrowseDB(0, 0, maxrow(), maxcol())
   
   oTB:HeadSep := "-"
   oTB:ColSep := "|"

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
