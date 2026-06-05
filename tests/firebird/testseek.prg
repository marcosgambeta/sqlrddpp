// SQLRDD++
// test with Firebird 5
// To compile:
// hbmk2 testseek -lfbclient

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
STATIC s_DTB    := "testseek.fdb"

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "testseek"
#define NUM_REC 1000
#define NUM_TIMES 2

REQUEST SQLRDD
REQUEST SR_FIREBIRD5

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

   SetMode(25, maxcol() + 1)

   CLS

   n := 1
   DO WHILE n <= PCount()
      IF HB_PValue(n) == "--server"
         ++n
         s_SERVER := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--uid"
         ++n
         s_UID := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--pwd"
         ++n
         s_PWD := HB_PValue(n)
         LOOP
      ENDIF
      IF HB_PValue(n) == "--dtb"
         ++n
         s_DTB := HB_PValue(n)
         LOOP
      ENDIF
      ++n
   ENDDO

   rddSetDefault(RDD_NAME)

   IF !file(s_DTB)
      SR_FIREBIRD5():CreateDatabase(s_DTB, s_UID, s_PWD, NIL, NIL, NIL)
   ENDIF

   nConnection := sr_AddConnection(CONNECT_FIREBIRD5, "FIREBIRD=" + s_SERVER + ";UID=" + s_UID + ";PWD=" + s_PWD + ";DTB=" + s_DTB)

   IF nConnection < 0
      alert("Connection error. See sqlerror.log for details.")
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
                            {"NAME      ", "C", 10, 0}, ;
                            {"DATE      ", "D",  8, 0}}, RDD_NAME)
   ENDIF

   ? "Opening table"
   USE (TABLE_NAME) EXCLUSIVE VIA (RDD_NAME)
   ? "bof()", bof()
   ? "eof()", eof()
   ? "reccount()", reccount()

   IF reccount() == 0 // < NUM_REC
      ? "Adding records"
      FOR n := 1 TO NUM_REC
         APPEND BLANK
         REPLACE ID WITH n
         REPLACE NAME WITH strzero(n, 10)
         REPLACE DATE WITH date() - n
      NEXT n
   ENDIF

   ? "Creating indexes"
   INDEX ON ID TO index1
   INDEX ON NAME TO index2
   INDEX ON DATE TO index3
   INDEX ON NAME + dtos(DATE) TO index4

   ? "Testing index 1"
   SET INDEX TO index1
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO NUM_REC * NUM_TIMES
      // create a valid id
      nID := hb_RandomInt(1, NUM_REC)
      SEEK nID
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->ID == nId
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid id
      nID := hb_RandomInt(NUM_REC + 1, NUM_REC + NUM_REC)
      SEEK nId
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be NUM_REC * NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be NUM_REC * NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   ? "Testing index 2"
   SET INDEX TO index2
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO NUM_REC * NUM_TIMES
      // create a valid name
      cName := strzero(hb_RandomInt(1, NUM_REC), 10)
      SEEK cName
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->NAME == cName
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid name
      cName := strzero(hb_RandomInt(NUM_REC + 1, NUM_REC + NUM_REC), 10)
      SEEK cName
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be NUM_REC * NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be NUM_REC * NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   ? "Testing index 3"
   SET INDEX TO index3
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO NUM_REC * NUM_TIMES
      // create a valid date
      dDate := date() - hb_RandomInt(1, NUM_REC)
      SEEK dDate
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->DATE == dDate
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid date
      dDate := date() + hb_RandomInt(1, NUM_REC)
      SEEK dDate
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be NUM_REC * NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be NUM_REC * NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   ? "Testing index 4"
   SET INDEX TO index4
   nSeekFound := 0
   nSeekNotFound := 0
   nSeekFailed := 0
   ? time()
   FOR n := 1 TO NUM_REC * NUM_TIMES
      nRand := hb_RandomInt(1, NUM_REC)
      // create a valid name
      cName := strzero(nRand, 10)
      // create a valid date
      dDate := date() - nRand
      SEEK cName + dtos(dDate)
      IF found() .AND. !bof() .AND. !eof() .AND. FIELD->NAME == cName .AND. FIELD->DATE == dDate
         ++nSeekFound
      ELSE
         ++nSeekFailed
      ENDIF
      // create a invalid name
      cName := strzero(hb_RandomInt(NUM_REC + 1, NUM_REC + NUM_REC), 10)
      // create a invalid date
      dDate := date() + hb_RandomInt(1, NUM_REC)
      SEEK cName + dtos(dDate)
      IF !found() .AND. !bof() .AND. eof()
         ++nSeekNotFound
      ELSE
         ++nSeekFailed
      ENDIF
   NEXT n
   ? time()
   // must be NUM_REC * NUM_TIMES
   ? "nSeekFound", nSeekFound, iif(nSeekFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be NUM_REC * NUM_TIMES
   ? "nSeekNotFound", nSeekNotFound, iif(nSeekNotFound == NUM_REC * NUM_TIMES, "OK", "ERROR")
   // must be 0
   ? "nSeekFailed", nSeekFailed, iif(nSeekFailed == 0, "OK", "ERROR")

   ? "Removing indexes"
   sr_DropIndex("index1")
   sr_DropIndex("index2")
   sr_DropIndex("index3")
   sr_DropIndex("index4")

   ? "Closing table"
   CLOSE DATABASE

   ? "Removing table"
   sr_DropTable(TABLE_NAME)

   sr_StopLog(nConnection)

   sr_EndConnection(nConnection)

   WAIT

RETURN
