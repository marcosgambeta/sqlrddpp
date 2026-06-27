// SQLRDD++
// test with ODBC/MySQL
// To compile:
// hbmk2 odbcmysql2

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"
#include "inkey.ch"

// To run the test:
// odbcmysql2 --driver <drivername> --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> --options <options> --newtable --droptable
// NOTE: the database must exist before runnning the test.

#define RDD_NAME "SQLEX"
#define TABLE_NAME "test"
#define NUM_REC 100

REQUEST SQLEX
REQUEST SR_ODBC

STATIC s_DRIVER     := "MySQL ODBC 9.4 ANSI Driver"
STATIC s_SERVER     := "localhost"
STATIC s_PORT       := "3306"
STATIC s_UID        := "root"
STATIC s_PWD        := ""
STATIC s_DATABASE   := "dbtest"
STATIC s_OPTIONS    := "TCPIP=1"
STATIC s_NEW_TABLE  := .F.
STATIC s_DROP_TABLE := .F.

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL cConnectionString
   LOCAL oTB
   LOCAL nKey

   hb_RandomSeed()

   SetMode(25, maxcol() + 1)

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--driver"    ; s_DRIVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--server"    ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"      ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"       ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"       ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--database"  ; s_DATABASE := HB_PValue(++n)
      CASE HB_PValue(n) == "--options"   ; s_OPTIONS := HB_PValue(++n)
      CASE HB_PValue(n) == "--newtable"  ; s_NEW_TABLE := .T.
      CASE HB_PValue(n) == "--droptable" ; s_DROP_TABLE := .T.
      ENDCASE
      ++n
   ENDDO

   rddSetDefault(RDD_NAME)

   cConnectionString := "Driver="   + s_DRIVER   + ";" + ;
                        "Server="   + s_SERVER   + ";" + ;
                        "Port="     + s_PORT     + ";" + ;
                        "Database=" + s_DATABASE + ";" + ;
                        "Uid="      + s_UID      + ";" + ;
                        "Pwd="      + s_PWD      + ";" + ;
                        ""          + s_OPTIONS  + ";"

   Alert(cConnectionString)

   nConnection := sr_AddConnection(CONNECT_ODBC, cConnectionString)

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

   oTB:addColumn(TBColumnNew("#", {||(TABLE_NAME)->(recno())}))
   oTB:addColumn(TBColumnNew("ID", {||(TABLE_NAME)->ID}))
   oTB:addColumn(TBColumnNew("FIRST", {||(TABLE_NAME)->FIRST}))
   oTB:addColumn(TBColumnNew("LAST", {||(TABLE_NAME)->LAST}))
   oTB:addColumn(TBColumnNew("AGE", {||(TABLE_NAME)->AGE}))
   oTB:addColumn(TBColumnNew("DATE", {||(TABLE_NAME)->DATE}))
   oTB:addColumn(TBColumnNew("MARRIED", {||(TABLE_NAME)->MARRIED}))
   oTB:addColumn(TBColumnNew("VALUE", {||(TABLE_NAME)->VALUE}))

   DO WHILE nKey != K_ESC
      dispbegin()
      DO WHILE !oTB:stabilize()
      ENDDO
      dispend()
      nKey := inkey(0)
      SWITCH nKey
      CASE K_UP    ; oTB:up()     ; EXIT
      CASE K_DOWN  ; oTB:down()   ; EXIT
      CASE K_LEFT  ; oTB:left()   ; EXIT
      CASE K_RIGHT ; oTB:right()  ; EXIT
      CASE K_PGUP  ; oTB:PageUp() ; EXIT
      CASE K_PGDN  ; oTB:PageDown()
      ENDSWITCH
   ENDDO

   CLOSE DATABASE

   IF s_DROP_TABLE .AND. sr_ExistTable(TABLE_NAME)
      sr_DropTable(TABLE_NAME)
   ENDIF

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

RETURN
