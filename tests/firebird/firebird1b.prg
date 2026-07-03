// SQLRDD++
// test with Firebird 5
// To compile:
// hbmk2 firebird1b -lfbclient

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"

// Make a copy of this file and change the values below (if necessary) or pass the parameters via command line:
// firebird1b --server <servername> --port <port> --uid <username> --pwd <userpassword> --database <databasename> --tablename <tablename> --newtable --droptable
// NOTE: the database will be created automatically.

STATIC s_SERVER     := ""
STATIC s_PORT       := "3050"
STATIC s_UID        := "SYSDBA"
STATIC s_PWD        := "masterkey"
STATIC s_DTB        := "fb5dbtest1.fdb"
STATIC s_TABLE_NAME := "test"
STATIC s_NEW_TABLE  := .F.
STATIC s_DROP_TABLE := .F.

#define RDD_NAME "SQLRDD"
#define NUM_REC 100

REQUEST SQLRDD
REQUEST SR_FIREBIRD5

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n

   hb_RandomSeed()

   SetMode(25, maxcol() + 1)

   CLS

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--server"    ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"      ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"       ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"       ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--dtb"       ; s_DTB := HB_PValue(++n)
      CASE HB_PValue(n) == "--tablename" ; s_TABLE_NAME := HB_PValue(++n)
      CASE HB_PValue(n) == "--newtable"  ; s_NEW_TABLE := .T.
      CASE HB_PValue(n) == "--droptable" ; s_DROP_TABLE := .T.
      ENDCASE
      ++n
   ENDDO

   rddSetDefault(RDD_NAME)

   IF !file(s_DTB)
      //SR_fbcreatedb5(s_DTB, s_UID, s_PWD, NIL, NIL, NIL) (deprecated)
      SR_FIREBIRD5():CreateDatabase(s_DTB, s_UID, s_PWD, NIL, NIL, NIL)
   ENDIF

   nConnection := sr_AddConnection(CONNECT_FIREBIRD5, "FIREBIRD=" + s_SERVER + ";PORT=" + s_PORT + ";UID=" + s_UID + ";PWD=" + s_PWD + ";DTB=" + s_DTB)

   IF nConnection < 0
      ? "Connection error. See sqlerror.log for details."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   IF s_NEW_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   IF !sr_ExistTable(s_TABLE_NAME)
      dbCreate(s_TABLE_NAME, {{"ID",      "N", 10, 0}, ;
                              {"FIRST",   "C", 30, 0}, ;
                              {"LAST",    "C", 30, 0}, ;
                              {"AGE",     "N",  3, 0}, ;
                              {"DATE",    "D",  8, 0}, ;
                              {"MARRIED", "L",  1, 0}, ;
                              {"VALUE",   "N", 12, 2}}, RDD_NAME)
   ENDIF

   USE (s_TABLE_NAME) EXCLUSIVE VIA (RDD_NAME)

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

   IF s_DROP_TABLE .AND. sr_ExistTable(s_TABLE_NAME)
      sr_DropTable(s_TABLE_NAME)
   ENDIF

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

RETURN
