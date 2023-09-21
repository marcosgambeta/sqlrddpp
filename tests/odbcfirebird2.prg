// SQLRDD
// test with ODBC/Firebird
// To compile:
// hbmk2 odbcfirebird2

#include "sqlrdd.ch"
#include "inkey.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.
#define ODBC_DRIVER   "Firebird/InterBase(r) driver"
#define ODBC_SERVER   "localhost"
#define ODBC_PORT     "3050"
#define ODBC_UID      "SYSDBA"
#define ODBC_PWD      "masterkey"
#define ODBC_DATABASE "C:\PATHTODATABASE\TEST.FDB"
#define ODBC_CLIENT   "fbclient.dll"
#define ODBC_CHARSET  "ISO8859_1"

//REQUEST SQLRDD
REQUEST SQLEX
REQUEST SR_ODBC
//REQUEST SR_FIREBIRD3

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL oTB
   LOCAL nKey

   setMode(25, 80)

   rddSetDefault("SQLRDD")

   nConnection := sr_AddConnection(CONNECT_ODBC, ;
      "driver="   + ODBC_DRIVER   + ";" + ;
      "server="   + ODBC_SERVER   + ";" + ;
      "port="     + ODBC_PORT     + ";" + ;
      "uid="      + ODBC_UID      + ";" + ;
      "pwd="      + ODBC_PWD      + ";" + ;
      "database=" + ODBC_DATABASE + ";" + ;
      "client="   + ODBC_CLIENT   + ";" + ;
      "charset="  + ODBC_CHARSET  + ";")

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
