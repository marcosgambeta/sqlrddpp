/*
* RunScript
* Utility tool for pushing large script files into SQL databases
* Copyright (c) 2003 - Marcelo Lombardo  marcelo@xharbour.com.br
* All Rights Reserved
*/

#include "sqlrdd.ch"
#include "sqlodbc.ch"

#define CRLF   chr(13) + chr(10)

#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

REQUEST SQLRDD
REQUEST SR_ODBC

static cBuffer := ""
static lUnicode

/*------------------------------------------------------------------------*/

FUNCTION Main(cScriptFile, cLogFile, nToCommit)

   LOCAL oSql
   LOCAL h1
   LOCAL h2
   LOCAL cSql
   LOCAL nCnn
   LOCAL nRet
   LOCAL nIssued
   LOCAL nErrors
   LOCAL j

   ? ""
   ? Replicate("-", 79)
   ? ""
   ? "RunScript - tool for pushing large script files into SQL Databases"
   ? ""
   ? "(c) 2003 - Marcelo Lombardo - marcelo@xharbour.com.br"
   ? ""
   ? "About the scrip file:"
   ? ""
   ? "You must have at least one blank line or a semicolon (;) involving each SQL"
   ? "command as a separator. If the database rejects any SQL statement, it will"
   ? "be added to the log file, as well as the error message."
   ? ""
   ? Replicate("-", 79)
   ? ""

   Connect()

   ? "Connected to :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)

   oSql := SR_GetConnection()

   IF empty(cScriptFile)
      ? "Usage: runscript <ScriptFile> [<LogFile>] [<CommitEveryN>]"
      ? ""
      ? "where:"
      ? " CommitEveryN to issue a COMMIT after processing N commands. Default is 1000"
      ? ""
      ? "ex.: runscript demodata.sql logs.txt"
      ? ""
      ? Replicate("-", 79)
      ? ""
      RETURN
   ENDIF

   /* Check for files */
   IF !file(cScriptFile)
      ? "Script input file not found."
      RETURN
   ENDIF

   h1 = fopen(cScriptFile)

   IF h1 < 0
      ? "Error opening the script file " + cScriptFile
      RETURN
   ENDIF

   IF nToCommit == NIL
      nToCommit := 1000
   ENDIF

   IF cLogFile == NIL
      cLogFile := "runscript.log"
   ENDIF

   h2 = fcreate(cLogFile)

   IF h2 < 0
      ? "Error creating log file " + cLogFile
      RETURN
   ENDIF

   fwrite(h2, "Runscript 1.0" + CRLF + CRLF + dtoc(date()) + " " + time() + "*** Log started to run " + cScriptFile + CRLF)

   nIssued  := 0
   nErrors  := 0
   cGira    := "-\|/"
   j        := 1

   ? ""

   DO WHILE !Empty(cSql := ProxStmt(h1))

      cSql := alltrim(cSql)

      DO WHILE (!empty(cSql)) .AND. right(cSql, 1) $ chr(13) + chr(10) + ";"
         cSql := left(cSql, len(cSql) - 1)
      ENDDO

      IF upper(right(cSql, 3)) == " GO"
         cSql := left(cSql, len(cSql) - 3)
      ENDIF

      nRet := oSql:exec(cSql, .F.)

      nIssued ++

      IF nRet != SQL_SUCCESS
         nErrors ++
         fwrite(h2, dtoc(date()) + " " + time() + " SQL Statement: " + CRLF + cSql + CRLF + "Error:" + CRLF + oSql:cSQLError + CRLF)
      ENDIF

      IF (nIssued % nToCommit) = 0
         oSql:Commit()
      ENDIF

      @ row(), 1 say "Processing (ALT+C to cancel)  " + cGira[j] + "  " + alltrim(str(nIssued)) + " commands executed with " + alltrim(str(nErrors)) + " error" + iif(nErrors != 1, "s", "")
      j++

      IF j = 5
         j := 1
      ENDIF

   ENDDO

   oSql:commit()

   fwrite(h2, CRLF + CRLF + alltrim(str(nIssued)) + " command" + iif(nIssued > 1, "s", "") + " executed" + CRLF + alltrim(str(nErrors)) + " error" + iif(nErrors != 1, "s", "") + CRLF + CRLF)
   fwrite(h2, dtoc(date()) + " " + time() + "*** Log finished.")

   fclose(h1)
   fclose(h2)

   oSql:end()

   ? ""
   ? "Finished. Starting log view..."
   ? ""

   Run ("notepad " + cLogFile)

RETURN

/*------------------------------------------------------------------------*/

FUNCTION ProxStmt(h1)

   LOCAL c
   LOCAL i
   LOCAL cOut
   LOCAL lEOF
   LOCAL lOpenQuote
   LOCAL lLF

   cOut := ""
   lEOF := .F.
   lLF  := .F.

   lOpenQuote := .F.

   IF empty(cBuffer)
      cBuffer := ReadBlock(h1, @lEOF)
      IF empty(cBuffer)
         RETURN ""
      ENDIF
   ENDIF

   c := cBuffer

   DO WHILE !empty(c) .AND. SubStr(c, 1, 1) == chr(10)
      lLF := .T.
      c := subStr(c, 2)
   ENDDO

   DO WHILE .T.

      FOR i := 1 TO len(c)
         IF c[i] == "'"
            lOpenQuote := !lOpenQuote
            cOut += c[i]
         ELSEIF c[i] == chr(13) .AND. (!lOpenQuote)
            cOut += " "
         ELSEIF c[i] == chr(255) .AND. ((!lOpenQuote) .OR. lUnicode)
         ELSEIF c[i] == chr(254) .AND. ((!lOpenQuote) .OR. lUnicode)
         ELSEIF c[i] == chr(0)   .AND. ((!lOpenQuote) .OR. lUnicode)
         ELSEIF c[i] == chr(10)  .AND. (!lOpenQuote) .AND. (!lLF)
            cOut += " "
            lLF := .T.
         ELSEIF ((c[i] = chr(10) .AND. lLF) .OR. c[i] == ";") .AND. !Empty(alltrim(cOut)) .AND. (!lOpenQuote)
            cBuffer := SubStr(c, i + 1)
            RETURN cOut
         ELSE
            cOut += c[i]
            lLF := .F.
         ENDIF

      NEXT i

      IF lEOF
         cBuffer := ""
         RETURN alltrim(cOut)
      ENDIF

      c := ReadBlock(h1, @lEOF)

      IF empty(c)
         cBuffer := ""
         RETURN alltrim(cOut)
      ENDIF

   ENDDO

RETURN ""

/*------------------------------------------------------------------------*/

FUNCTION ReadBlock(h1, lEOF)

   LOCAL n
   LOCAL c := space(4096)

   lEOF := .F.
   n := fread(h1, @c, 4096)

   IF n < 4096
      lEOF := .T.
   ENDIF

   IF lUnicode == NIL
      IF left(c, 2) == chr(255) + chr(254)
         lUnicode := .T.
      ELSE
         lUnicode := .F.
      ENDIF
   ENDIF

RETURN c

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
