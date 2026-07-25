// SQLRDD++
// test with PostgreSQL
// To compile:
// hbmk2 testdesc1 -llibpq

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"

// To run the test:
// testdesc1 --server <servername> --uid <username> --pwd <userpassword> --dtb <databasename>
// NOTE: the database must exist before runnning the test.

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "testdesc1"
#define NUM_REC 15
#define NUM_TIMES 1

REQUEST SQLRDD
REQUEST SR_PGS

STATIC s_SERVER := "localhost"
STATIC s_UID    := "postgres"
STATIC s_PWD    := "password"
STATIC s_DTB    := "dbtest"

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL nSeekFound
   LOCAL nSeekNotFound
   LOCAL nSeekFailed
   LOCAL nId
   LOCAL cName
   LOCAL dDate
   LOCAL nRand

   hb_RandomSeed()

   //SetMode(25, maxcol() + 1)

   //CLS

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--server" ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"    ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"    ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--dtb"    ; s_DTB := HB_PValue(++n)
      OTHERWISE
         ? "Unknow parameter:", HB_PValue(n)
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

   IF sr_ExistTable(TABLE_NAME)
      sr_DropTable(TABLE_NAME)
   ENDIF

   // TODO: add more data types
   IF !sr_ExistTable(TABLE_NAME)
      ? "Creating table"
      dbCreate(TABLE_NAME, {{"ID        ", "N", 10, 0}, ;
                            {"NAME      ", "C", 30, 0}, ;
                            {"DATE      ", "D",  8, 0}}, RDD_NAME)
      ? "Opening table"
      USE (TABLE_NAME) EXCLUSIVE VIA (RDD_NAME)
      ? "bof()", bof()
      ? "eof()", eof()
      ? "reccount()", reccount()
      ? "Creating indexes"
      INDEX ON ID TO index1
      INDEX ON NAME TO index2
      INDEX ON DATE TO index3
      INDEX ON descend(ID) TO index4
      INDEX ON descend(NAME) TO index5
      INDEX ON descend(DATE) TO index6
      IF reccount() == 0 // < NUM_REC
         ? "Adding records"
         FOR n := 1 TO NUM_REC
            APPEND BLANK
            REPLACE ID WITH n
            REPLACE NAME WITH "NAME_" + strzero(n, 10)
            REPLACE DATE WITH date() + n
         NEXT n
      ENDIF
      ? "Closing table"
      USE
   ENDIF

   ? "Opening table"
   USE (TABLE_NAME) INDEX index1,index2,index3,index4,index5,index6 EXCLUSIVE VIA (RDD_NAME)
   ? "bof()", bof()
   ? "eof()", eof()
   ? "reccount()", reccount()
   WAIT

   ? "Testing descend function"
   dbsetorder(0)
   dbgotop()
   ? "descend(ID)", descend(FIELD->ID)
   ? "descend(NAME)", descend(FIELD->NAME)
   ? "descend(DATE)", descend(FIELD->DATE)
   WAIT

   ? "natural order"
   dbsetorder(0)
   dbgotop()
   DO WHILE !eof()
      ? FIELD->ID, FIELD->NAME, FIELD->DATE
      dbskip()
   ENDDO
   WAIT

   ? "ID order"
   dbsetorder(1)
   dbgotop()
   DO WHILE !eof()
      ? FIELD->ID, FIELD->NAME, FIELD->DATE
      dbskip()
   ENDDO
   WAIT

   ? "NAME order"
   dbsetorder(2)
   dbgotop()
   DO WHILE !eof()
      ? FIELD->ID, FIELD->NAME, FIELD->DATE
      dbskip()
   ENDDO
   WAIT

   ? "DATE order"
   dbsetorder(3)
   dbgotop()
   DO WHILE !eof()
      ? FIELD->ID, FIELD->NAME, FIELD->DATE
      dbskip()
   ENDDO
   WAIT

   ? "DESCEND(ID) order"
   dbsetorder(4)
   dbgotop()
   DO WHILE !eof()
      ? FIELD->ID, FIELD->NAME, FIELD->DATE
      dbskip()
   ENDDO
   WAIT

   ? "DESCEND(NAME) order"
   dbsetorder(5)
   dbgotop()
   DO WHILE !eof()
      ? FIELD->ID, FIELD->NAME, FIELD->DATE
      dbskip()
   ENDDO
   WAIT

   ? "DESCEND(DATE) order"
   dbsetorder(6)
   dbgotop()
   DO WHILE !eof()
      ? FIELD->ID, FIELD->NAME, FIELD->DATE
      dbskip()
   ENDDO
   WAIT

   ? "Closing table"
   CLOSE DATABASE

   ? "Removing table"
   sr_DropTable(TABLE_NAME)

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

   WAIT

RETURN
