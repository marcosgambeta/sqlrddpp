/*
 * Main Connection Class
 * Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
 *
 * This class does not work alone. It should be superclass of
 * database-specific connection class
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the xHarbour Project gives permission for
 * additional uses of the text contained in its release of xHarbour.
 *
 * The exception is that, if you link the xHarbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the xHarbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the xHarbour
 * Project under the name xHarbour.  If you copy code from other
 * xHarbour Project or Free Software Foundation releases into a copy of
 * xHarbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for xHarbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#include "hbclass.ch"
#include "common.ch"
// #include "compat.ch"
#include "sqlodbc.ch"
#include "sqlrdd.ch"
#include "error.ch"
#include "msg.ch"
#include "sqlrddsetup.ch"

#define DEBUGSESSION     .F.

#define SR_CRLF   (chr(13) + chr(10))

STATIC lNwgOldCompat := .F.

CLASS SR_CONNECTION

   CLASSDATA lFreezed AS LOGICAL INIT .F.
   DATA cLowLevLogFile AS CHARACTER INIT "sqltrace.log"

   DATA nConnectionType
   DATA nSizeMaxBuff
   DATA nPreFetch
   DATA cOwner
   DATA cQueryOwner
   DATA lTrace
   DATA oSqlTransact
   DATA oCache
   DATA nSelMeth
   DATA nEmptyMode
   DATA nDateMode
   DATA oSql
   DATA cNextQuery
   DATA sSiteName
   DATA cSQLError
   DATA cResult
   DATA uSid
   DATA cLockWait

   DATA cTargetDB, cSystemName, nSystemID, cSystemVers READONLY
   DATA nFields, aFields, hEnv, hDbc, /*nRetCode,*/ nVersion READONLY
   DATA nRetCode
   // CULIK 18/10/2010 Adicionado para indicar se o indice contem cluster
   DATA lClustered AS LOGICAL INIT .F. READONLY
   //culik 30/12/2011 adicionado para indicar se e  sqlserver versao 2008 ou superior
   DATA lSqlServer2008 AS LOGICAL INIT .F.
   DATA lPostgresql8   AS LOGICAL INIT .F. // do we have postgressql >= 8.3
   DATA lPostgresql83  AS LOGICAL INIT .F. // do we have postgressql >= 8.3
   DATA lMariaDb       AS LOGICAL INIT .F. // do we have mariadb
   DATA oHashActiveWAs

   DATA aTableInfo INIT {=>}
   DATA aFieldModifier

   DATA cDsnTblData
   DATA cDsnTblIndx
   DATA cDsnTblLob

   DATA lNative         AS LOGICAL INIT .T.
   DATA lComments       AS LOGICAL INIT .T.
   DATA lQueryOnly      AS LOGICAL INIT .F.
   DATA lLowLevSqlDbg   AS LOGICAL INIT .F.
   DATA lAutoCommit     AS LOGICAL INIT .F.
   DATA lUseRepl        AS LOGICAL INIT .F.
   DATA lCounter        AS LOGICAL INIT .F.
   DATA lLogDateTime    AS LOGICAL INIT .F.
   DATA lCluster        AS LOGICAL INIT .F.
   DATA lCompress       AS LOGICAL INIT .F. // to enable mysql compression

//   DATA nParallel
//   DATA cLastLine
//   DATA lWantCommit AS LOGICAL INIT .F.
//   DATA lLocks      AS LOGICAL INIT .F.
//   DATA SimulateLL  AS LOGICAL INIT .F.
//   DATA cTempDir         AS CHARACTER   INIT ""

   DATA lSetNext         AS LOGICAL    INIT .F.
   DATA lResultSet       AS LOGICAL    INIT .T.
   DATA lAllInCache      AS LOGICAL    INIT .F. // Handles whether derived workareas are ALL_IN_CACHE or not
   DATA cLastComm        AS CHARACTER  INIT ""
   DATA cMgmntVers       AS CHARACTER  INIT ""
   DATA cLoginTime       AS CHARACTER  INIT ""
   DATA cAppUser         AS CHARACTER  INIT ""
   DATA cSite            AS CHARACTER  INIT ""
   DATA lHistEnable      AS LOGICAL    INIT .T.
   DATA lTraceToDBF      AS LOGICAL    INIT .F.
   DATA lTraceToScreen   AS LOGICAL    INIT .F.
   DATA nTimeTraceMin    AS NUMERIC    INIT 1000
   DATA nLogMode         AS NUMERIC    INIT SQLLOGCHANGES_NOLOG
   DATA hStmt            //AS NUMERIC    INIT 0
   DATA nConnID          AS NUMERIC    INIT 0
   DATA nID              AS NUMERIC    INIT 0
   DATA nTransacCount    AS NUMERIC    INIT 0
   DATA nMaxTextLines    AS NUMERIC    INIT 100
   DATA nLockWaitTime    AS NUMERIC    INIT 1
   DATA lShowTxtMemo     AS LOGICAL    INIT .F.
   DATA nIteractions     AS NUMERIC    INIT 0
   DATA nAutoCommit      AS NUMERIC    INIT 0
   DATA lUseSequences    AS LOGICAL    INIT .T.
   DATA nTCCompat        AS NUMERIC    INIT 0      // TopConnect compatibility mode

   DATA cTempFile
   DATA oODBCTemp
   DATA oOdbc
   DATA nSetOpt
   DATA nSetValue
   DATA nMiliseconds
   DATA cPort, cHost, oSock, cDBS, cDrv, cDTB, cHandle       /* RPC stuff */
   DATA cCharSet
   DATA cNetLibrary
   DATA cApp
   // Culik Added to tell to postgresql use ssl
   DATA sslcert
   DATA sslkey
   DATA sslrootcert
   DATA sslcrl
   // CULIK 21/3/2011 Adicionado para indicar se o indice contem cluster
   DATA lClustered AS LOGICAL INIT .F. READONLY
   //culik 30/12/2011 adicionado para indicar se e  sqlserver versao 2008 ou superior
   DATA lSqlServer2008 AS LOGICAL INIT .F.
   DATA lOracle12      AS LOGICAL INIT .F. // do we have Oracle >= 12.0

   DATA lBind INIT .F.
   DATA cSqlPrepare INIT ""
   DATA aBindParameters INIT {}

   PROTECTED:

   DATA cConnect
   DATA cDSN
   DATA cUser
   DATA cPassword

   EXPORTED:

   METHOD Connect(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout) CONSTRUCTOR
   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout) VIRTUAL
   METHOD DetectTargetDb()
   METHOD RPCTalk(cSend)
   METHOD End()
   METHOD GetInfo(nType)
   METHOD SetOptions(nType, uBuffer)
   METHOD GetOptions(nType)
   METHOD LastError()
   METHOD Commit()
   METHOD RollBack()
   METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName, lRefCursor) VIRTUAL
   METHOD ExecuteRaw() VIRTUAL
   METHOD Execute(cCommand, lErrMsg, nLogMode, cType)
   METHOD Exec(cCommand, lMsg, lFetch, aArray, cFile, cAlias, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode, cType)
   METHOD AllocStatement()
   METHOD SetStmtOptions(nType, uBuffer)
   METHOD RuntimeErr(cOperation, cErr)
   METHOD FreeStatement() VIRTUAL
   METHOD Fetch(aLine, lTranslate, aFields)
   METHOD FetchRaw(lTranslate, aFields) VIRTUAL
   METHOD FieldGet(nField, aField, lTranslate) VIRTUAL
   METHOD SetNextOpt(nSet, nOpt)
   METHOD MoreResults() VIRTUAL
   METHOD Getline(aFields, lTranslate, aArray)
   METHOD GetStruct(cTable)
   METHOD WriteMemo(hDbc, cFileName, nRecno, cRecnoName, aColumnsAndData) VIRTUAL
   METHOD ListCatTables(cOwner)
   METHOD DriverCatTables() VIRTUAL
   METHOD FetchMultiple(lTranslate, aFields, aCache, nCurrentFetch, aInfo, nDirection, hnRecno, lFetchAll, aFetch, uRecord, nPos) VIRTUAL
   METHOD LogQuery(cSql, cType)

   METHOD SQLType(nType, cName, nLen)
   METHOD SQLLen(nType, nLen, nDec)

   METHOD GetConnectionID() INLINE (::uSid)
   METHOD KillConnectionID(nID) VIRTUAL
   METHOD ExecSPRC(cComm, lMsg, lFetch, aArray, cFile, cAlias, cVar, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode) VIRTUAL
   METHOD ExecSP(cComm, aReturn, nParam) VIRTUAL
   METHOD GetAffectedRows() Virtual

ENDCLASS

METHOD LogQuery(cCommand, cType, nLogMode, nCost) CLASS SR_CONNECTION

   LOCAL cSql
   LOCAL cMode
   LOCAL oSql
   LOCAL cStack

   DEFAULT cType    TO SQLLOGCHANGES_TYPE_DML
   DEFAULT nLogMode TO ::nLogMode
   DEFAULT nCost    TO 0

   cMode := StrZero(nLogMode, SQLLOGCHANGES_SIZE)

   IF ::cQueryOwner == NIL
      IF !Empty(SR_GetGlobalOwner())
         ::cQueryOwner := alltrim(SR_GetGlobalOwner())
      ELSEIF !Empty(::oSql:cOwner)
         ::cQueryOwner := alltrim(::cOwner)
      ENDIF

      IF (!Empty(::cQueryOwner)) .AND. right(::cQueryOwner, 1) != "."
         ::cQueryOwner += "."
      ENDIF

      IF Empty(::cQueryOwner)
         ::cQueryOwner := ""
      ENDIF

   ENDIF

   IF substr(cMode, 4, 1) == "1" .OR. ::oSqlTransact == NIL
      oSql := SELF
   ELSE
      oSql := ::oSqlTransact
   ENDIF

   IF substr(cMode, 1, 1) == "1"
      cStack := sr_cDbValue(SR_GetStack(), ::nSystemID)
   ELSE
      cStack := " NULL"
   ENDIF

   cSql := "INSERT INTO " + ::cQueryOwner + "SR_MGMNTLOGCHG (SPID_, WPID_, TYPE_, APPUSER_, TIME_, QUERY_, CALLSTACK_, SITE_, CONTROL_, COST_ ) VALUES ( " + ;
           str(::uSid) + "," + str(SR_GetCurrInstanceID()) + ", '" + cType + "','" + ::cAppUser + "','" + dtos(date()) + time() + strzero(seconds() * 1000, 8) + "'," + sr_cDbValue(cCommand, ::nSystemID) + "," + cStack + ",'" + ::cSite + "', NULL, " + str(nCost) + " )"
   oSql:execute(cSql, , , .T.)
   oSql:FreeStatement()

   IF substr(cMode, 4, 1) != "1"
      oSql:Commit()
   ENDIF

RETURN NIL

METHOD ListCatTables(cOwner) CLASS SR_CONNECTION

   LOCAL aRet := {}
   LOCAL aRet2 := {}
   LOCAL i

   DEFAULT cOwner TO SR_SetGlobalOwner()

   IF right(cOwner, 1) == "."
      cOwner := SubStr(cOwner, 1, len(cOwner) - 1)
   ENDIF

   SWITCH ::nSystemID
   CASE SYSTEMID_MSSQL7
   CASE SYSTEMID_SYBASE
      IF empty(cOwner)
         ::exec("select name from sysobjects where type = N'U' order by name", .T., .T., @aRet)
      ELSE
         ::exec("select name from sysobjects where type = N'U' and user_name(uid) = '" + cOwner + "' order by name", .T., .T., @aRet)
      ENDIF
      EXIT
   CASE SYSTEMID_POSTGR
      IF empty(cOwner)
         ::exec("select tablename from pg_tables where schemaname = 'public' order by tablename", .T., .T., @aRet)
      ELSE
         ::exec("select tablename from pg_tables where schemaname = '" + cOwner + "' order by tablename", .T., .T., @aRet)
      ENDIF
      EXIT
   CASE SYSTEMID_ORACLE
      IF empty(cOwner)
         ::exec("select table_name from user_tables order by TABLE_NAME", .T., .T., @aRet)
      ELSE
         ::exec("select TABLE_NAME from all_tables where owner = '" + cOwner + "' order by TABLE_NAME", .T., .T., @aRet)
      ENDIF
      EXIT
   CASE SYSTEMID_MYSQL
   CASE SYSTEMID_MARIADB
      ::exec("show tables", .T., .T., @aRet)
      EXIT
   CASE SYSTEMID_ADABAS
   CASE SYSTEMID_IBMDB2
   CASE SYSTEMID_CACHE
   CASE SYSTEMID_INGRES
      aRet := ::DriverCatTables()
      EXIT
   CASE SYSTEMID_FIREBR
   CASE SYSTEMID_FIREBR3
      IF empty(cOwner)
         ::exec("select RDB$RELATION_NAME from RDB$RELATIONS where RDB$FLAGS = 1 order by RDB$RELATION_NAME", .T., .T., @aRet)
      ELSE
         ::exec("select RDB$RELATION_NAME from RDB$RELATIONS where RDB$FLAGS = 1 AND RDB$OWNER_NAME = '" + cOwner + "' order by RDB$RELATION_NAME", .T., .T., @aRet)
      ENDIF
      EXIT
   ENDSWITCH

   aRet2 := array(len(aRet))
   FOR i := 1 TO len(aRet)
      aRet2[i] := upper(rtrim(aRet[i, 1]))
   NEXT i

RETURN aRet2

METHOD Fetch(aLine, lTranslate, aFields) CLASS SR_CONNECTION

   LOCAL lResults := HB_ISARRAY(aLine)
   LOCAL i
   LOCAL nRet := ::FetchRaw(lTranslate, aFields)

   IF nRet == SQL_SUCCESS .AND. lResults
      aSize(aLine, ::nFields)
      FOR i := 1 TO ::nFields
         aLine[i] := ::FieldGet(i, ::aFields, lTranslate)
      NEXT i
   ENDIF

RETURN nRet

METHOD GetStruct(cTable) CLASS SR_CONNECTION
RETURN ::oSql:IniFields(.T., cTable, , .F.)

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_CONNECTION

   LOCAL i

   IF aArray == NIL
      aArray := Array(len(aFields))
   ELSEIF len(aArray) < len(aFields)
      aSize(aArray, len(aFields))
   ENDIF

   FOR i := 1 TO len(aFields)
      aArray[i] := ::FieldGet(i, aFields, lTranslate)
   NEXT i

RETURN aArray

METHOD SetNextOpt(nSet, nOpt) CLASS SR_CONNECTION

   ::lSetNext  := .T.
   ::nSetOpt   := nSet
   ::nSetValue := nOpt

RETURN NIL

METHOD Exec(cCommand, lMsg, lFetch, aArray, cFile, cAlias, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode, cType) CLASS SR_CONNECTION

   LOCAL nRet := 0
   LOCAL i
   LOCAL j
   LOCAL n
   LOCAL cEste
   LOCAL cCampo
   LOCAL aDb
   LOCAL nFieldRec
   LOCAL aFields
   LOCAL nBlocks
   LOCAL nAllocated := 0
   LOCAL nLenMemo
   LOCAL nLinesMemo
   LOCAL aMemo
   LOCAL cFileTemp

   DEFAULT nLogMode TO ::nLogMode
   DEFAULT cType    TO SQLLOGCHANGES_TYPE_DML

   IF ::lTraceToDBF
      SR_WriteDbLog(cCommand, SELF)
   ENDIF
   IF ::lTraceToScreen
      Alert(cCommand)
   ENDIF
   IF ::lLowLevSqlDbg
      SR_LogFile(::cLowLevLogFile, {cCommand}, ::lLogDateTime)
   ENDIF

   IF ::lFreezed
      RETURN SQL_SUCCESS
   ENDIF

   DEFAULT lMsg         TO .T.
   DEFAULT lFetch       TO .F.
   DEFAULT nMaxRecords  TO 99999999999999
   DEFAULT lNoRecno     TO .F.
   DEFAULT cRecnoName   TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   IF !Empty(cFile)
      HB_FNameSplit(cFile, , @cFileTemp)
      DEFAULT cAlias TO cFileTemp
   ENDIF

   IF cCommand == NIL
      RETURN SQL_ERROR
   ELSE
      ::cLastComm := cCommand

      IF nLogMode > 0 .AND. StrZero(nLogMode, SQLLOGCHANGES_SIZE)[6] == "1" .AND. ((!Upper(SubStr(ltrim(cCommand), 1, 6)) $ "SELECT,") .OR. cType == SQLLOGCHANGES_TYPE_LOCK)
         ::LogQuery(cCommand, cType, nLogMode)
      ENDIF

      ::AllocStatement()
      ::nMiliseconds := Seconds() * 100
      nRet := ::ExecuteRaw(cCommand)

      IF nLogMode > 0 .AND. StrZero(nLogMode, SQLLOGCHANGES_SIZE)[5] == "1" .AND. ((!Upper(SubStr(ltrim(cCommand), 1, 6)) $ "SELECT,") .OR. cType == SQLLOGCHANGES_TYPE_LOCK)
         ::LogQuery(cCommand, cType, nLogMode)
      ENDIF

      lFetch := lFetch .AND. ::lResultSet

      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO .AND. (!(("DELETE FROM " $ upper(cCommand) .OR. "UPDATE " $ upper(left(cCommand, 7))) .AND. nRet == SQL_NO_DATA_FOUND))

         ::nRetCode  := nRet
         ::cSQLError := ""
         IF lMsg
            IF len(cCommand) > 10000
               ::RunTimeErr("", "SQLExecDirect Error" + ;
                        SR_CRLF + ::LastError() + SR_CRLF + "Command sent to database : " + SR_CRLF + SubStr(cCommand, 1, 2000) + " ... (command too long to display here)")
            ELSE
               ::RunTimeErr("", "SQLExecDirect Error" + ;
                        SR_CRLF + ::LastError() + SR_CRLF + "Command sent to database : " + SR_CRLF + cCommand)
            ENDIF
         ELSE
            ::cSQLError := ::LastError()
         ENDIF
      ELSE

         ::nRetCode     := nRet
         ::nMiliseconds := (Seconds()*100) - ::nMiliseconds

         IF ::nMiliseconds > ::nTimeTraceMin
            SR_WriteTimeLog(cCommand, SELF, ::nMiliseconds)
         ENDIF

         IF lFetch
            IF !Empty(cFile)

               aFields := ::IniFields(.F.,,,,, cRecnoName, cDeletedName)

               IF Select(cAlias) == 0
                  aDb := {}
                  IF lNoRecno
                     FOR i := 1 TO len(aFields)
                        IF aFields[i, 1] != cRecnoName
                           AADD(aDb, aFields[i])
                        ELSE
                           nFieldRec := i
                        ENDIF
                     NEXT i
                     dbCreate(cFile, SR_AdjustNum(aDb), SR_SetRDDTemp())
                  ELSE
                     dbCreate(cFile, SR_AdjustNum(aFields), SR_SetRDDTemp())
                  ENDIF

                  dbUseArea(.T., SR_SetRDDTemp(), cFile, cAlias, .F.)
               ELSE
                  dbSelectArea(cAlias)
               ENDIF

               n := 1

               DO WHILE n <= nMaxRecords .AND. ((::nRetCode := ::Fetch(, lTranslate)) == SQL_SUCCESS)

                  APPEND BLANK

                  IF nFieldRec == NIL
                     FOR i := 1 TO len(aFields)
                        FieldPut(i, ::FieldGet(i, aFields, lTranslate))
                     NEXT i
                  ELSE
                     FOR i := 1 TO len(aFields)
                        DO CASE
                        CASE i = nFieldRec
                           ::FieldGet(i, aFields, lTranslate)
                        CASE i > nFieldRec
                           FieldPut(i - 1, ::FieldGet(i, aFields, lTranslate))
                        CASE i < nFieldRec
                           FieldPut(i, ::FieldGet(i, aFields, lTranslate))
                        ENDCASE
                     NEXT i
                  ENDIF

                  n++

               EndDo

               dbGoTop()

            ELSEIF aArray == NIL

               ::cResult := ""
               n         := 0
               aFields   := ::IniFields(.F.,,,,, cRecnoName, cDeletedName)

               FOR i := 1 TO len(aFields)
                  ::cResult += PadR(aFields[i, 1], IIf(aFields[i, 2] == "M", Max(len(aFields[i, 1]), iif(::lShowTxtMemo, 79, 30)) , Max(len(aFields[i, 1]), aFields[i, 3])), "-") + " "
               NEXT i

               ::cResult += SR_CRLF
               aMemo     := Array(len(aFields))

               DO WHILE n <= ::nMaxTextLines .AND. ((::nRetCode := ::Fetch(, lTranslate)) == SQL_SUCCESS)

                  cEste      := ""
                  nLenMemo   := 0
                  nLinesMemo := 0

                  FOR i := 1 TO len(aFields)
                     cCampo := ::FieldGet(i, aFields, lTranslate)
                     IF aFields[i, 2] == "M"
                        nLenMemo   := Max(len(aFields[i, 1]), iif(::lShowTxtMemo, 79, 30))
                        nLinesMemo := Max(mlCount(cCampo, nLenMemo), nLinesMemo)
                        cEste += memoline(cCampo, nLenMemo, 1) + " "
                        aMemo[i] := cCampo
                     ELSE
                        cEste += PadR(SR_Val2Char(cCampo), Max(len(aFields[i, 1]), aFields[i, 3])) + " "
                     ENDIF
                  NEXT i

                  ::cResult += cEste + SR_CRLF
                  n++

                  IF ::lShowTxtMemo .AND. nLinesMemo > 1
                     FOR j := 2 TO nLinesMemo
                        cEste := ""
                        FOR i := 1 TO len(aFields)
                           IF aFields[i, 2] == "M"
                              cEste += memoline(aMemo[i], nLenMemo, j) + " "
                           ELSE
                              cEste += Space(Max(len(aFields[i, 1]), aFields[i, 3])) + " "
                           ENDIF
                        NEXT i
                        ::cResult += cEste + SR_CRLF
                        n++
                     NEXT j
                  ENDIF

               EndDo

            ELSE      // Retorno deve ser para Array !

               AsizeAlloc(aArray, 300)

               IF HB_ISARRAY(aArray)
                  IF len(aArray) = 0
                     aSize(aArray, ARRAY_BLOCK1)
                     nAllocated := ARRAY_BLOCK1
                  ELSE
                     nAllocated := len(aArray)
                  ENDIF
               ELSE
                  aArray := Array(ARRAY_BLOCK1)
                  nAllocated := ARRAY_BLOCK1
               ENDIF

               nBlocks := 1
               n       := 0
               aFields := ::IniFields(.F.,,,,, cRecnoName, cDeletedName)

               DO WHILE (::nRetCode := ::Fetch(, lTranslate)) = SQL_SUCCESS
                  n++
                  IF n > nAllocated
                     SWITCH nAllocated
                     CASE ARRAY_BLOCK1
                        nAllocated := ARRAY_BLOCK2
                        EXIT
                     CASE ARRAY_BLOCK2
                        nAllocated := ARRAY_BLOCK3
                        EXIT
                     CASE ARRAY_BLOCK3
                        nAllocated := ARRAY_BLOCK4
                        EXIT
                     CASE ARRAY_BLOCK4
                        nAllocated := ARRAY_BLOCK5
                        EXIT
                     OTHERWISE
                        nAllocated += ARRAY_BLOCK5
                     ENDSWITCH

                     aSize(aArray, nAllocated)
                  ENDIF

                  aArray[n] := array(len(aFields))
                  FOR i := 1 TO len(aFields)
                     aArray[n, i] := ::FieldGet(i, aFields, lTranslate)
                  NEXT i
                  IF n > nMaxRecords
                     EXIT
                  ENDIF
               EndDo
               aSize(aArray, n)
            ENDIF
         ENDIF

         IF ::nAutoCommit > 0 .AND. Upper(SubStr(ltrim(cCommand), 1, 6)) $ "UPDATE,INSERT,DELETE"
            IF (++::nIteractions) >= ::nAutoCommit .AND. ::nTransacCount == 0
               ::Commit()
            ENDIF
         ENDIF

      ENDIF

      ::FreeStatement()

   ENDIF

RETURN nRet

METHOD AllocStatement() CLASS SR_CONNECTION
RETURN SQL_SUCCESS

METHOD Execute(cCommand, lErrMsg, nLogMode, cType, lNeverLog) CLASS SR_CONNECTION

   LOCAL nRet := 0

   DEFAULT lErrMsg   TO .T.
   DEFAULT lNeverLog TO .F.
   DEFAULT nLogMode  TO ::nLogMode
   DEFAULT cType     TO SQLLOGCHANGES_TYPE_DML

   IF ::lTraceToDBF
      SR_WriteDbLog(cCommand, SELF)
   ENDIF
   IF ::lTraceToScreen
      Alert(cCommand)
   ENDIF
   IF ::lLowLevSqlDbg
      SR_LogFile(::cLowLevLogFile, {cCommand}, ::lLogDateTime)
   ENDIF

   IF ::lFreezed
      RETURN 0
   ENDIF

   IF cCommand == NIL
      nRet := SQL_ERROR
   ELSE
      IF Len(cCommand) < 1
         ::nRetCode := nRet := 2
      ELSE
         ::cLastComm := cCommand

         IF nLogMode > 0 .AND. StrZero(nLogMode, SQLLOGCHANGES_SIZE)[6] == "1" .AND. ((!Upper(SubStr(ltrim(cCommand), 1, 6)) $ "SELECT,") .OR. cType == SQLLOGCHANGES_TYPE_LOCK) .AND. (!lNeverLog)
            ::LogQuery(cCommand, cType, nLogMode)
         ENDIF

         ::AllocStatement()
         ::nMiliseconds := Seconds() * 100

         nRet := ::ExecuteRaw(cCommand)
         ::nRetCode := nRet
         ::nMiliseconds := (Seconds()*100) - ::nMiliseconds

         IF nLogMode > 0 .AND. StrZero(nLogMode, SQLLOGCHANGES_SIZE)[5] == "1" .AND. ((!Upper(SubStr(ltrim(cCommand), 1, 6)) $ "SELECT,") .OR. cType == SQLLOGCHANGES_TYPE_LOCK) .AND. (!lNeverLog)
            ::LogQuery(cCommand, cType, nLogMode, ::nMiliseconds)
         ENDIF

         IF ::nMiliseconds > ::nTimeTraceMin
            SR_WriteTimeLog(cCommand, SELF, ::nMiliseconds)
         ENDIF

         IF lErrMsg .AND. nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO .AND. (!(("DELETE FROM " $ upper(cCommand) .OR. "UPDATE " $ upper(left(cCommand, 7))) .AND. nRet == SQL_NO_DATA_FOUND))

            ::RunTimeErr("", "SQLExecDirect Error" + ;
                     SR_CRLF + ::LastError() + SR_CRLF + ;
                     "Command : " + cCommand + SR_CRLF + ;
                     "hStmt   : " + SR_Val2Char(::hStmt))
         ENDIF

         IF ::nAutoCommit > 0 .AND. Upper(SubStr(ltrim(cCommand), 1, 6)) $ "UPDATE,INSERT,DELETE"
            IF (++::nIteractions) >= ::nAutoCommit .AND. ::nTransacCount == 0
               ::Commit()
            ENDIF
         ENDIF

      ENDIF
   ENDIF

RETURN nRet

METHOD LastError() CLASS SR_CONNECTION
RETURN ""

METHOD RPCTalk(cSend) CLASS SR_CONNECTION

   HB_SYMBOL_UNUSED(cSend)

RETURN ""

METHOD DetectTargetDb() CLASS SR_CONNECTION

   LOCAL cTargetDB := Upper(::cSystemName)
   LOCAL aVers

   ::nSystemID := SYSTEMID_UNKNOW

   DO CASE
   CASE "ORACLE" $ cTargetDB
      ::nSystemID := SYSTEMID_ORACLE
   CASE ("MICROSOFT" $ cTargetDB .AND. "SQL" $ cTargetDB .AND. "SERVER" $ cTargetDB .AND.("10.25" $ ::cSystemVers))
      ::nSystemID := SYSTEMID_AZURE
   CASE "MICROSOFT" $ cTargetDB .AND. "SQL" $ cTargetDB .AND. "SERVER" $ cTargetDB .AND. "6.5" $ ::cSystemVers
      ::nSystemID := SYSTEMID_MSSQL6
   CASE ("SQL Server" $ cTargetDB .AND. "00.53.0000" $ ::cSystemVers) .OR. ("MICROSOFT SQL SERVER" $ cTargetDB)
      ::nSystemID := SYSTEMID_MSSQL7
      aVers := hb_atokens(::cSystemVers, '.')
      IF val(aVers[1]) >= 8
         ::lClustered := .T.
      ENDIF
         //culik 30/12/2011 adicionado para indicar se e  sqlserver versao 2008 ou superior
      IF val(aVers[1]) >= 10
         ::lSqlServer2008 := .T.
      ENDIF

   CASE ("MICROSOFT" $ cTargetDB .AND. "SQL" $ cTargetDB .AND. "SERVER" $ cTargetDB .AND.("7.0" $ ::cSystemVers .OR. "8.0" $ ::cSystemVers .OR. "9.0" $ ::cSystemVers .OR. "10.00" $ ::cSystemVers .OR. "10.50" $ ::cSystemVers .OR. "11.00" $ ::cSystemVers)) //.OR. ( "SQL SERVER" $ cTargetDB .AND. !("SYBASE" $ cTargetDB))
      ::nSystemID := SYSTEMID_MSSQL7
      aVers := hb_atokens(::cSystemVers, '.')
      IF val(aVers[1]) >= 8
         ::lClustered := .T.
      ENDIF
   CASE "ANYWHERE" $ cTargetDB
      ::nSystemID := SYSTEMID_SQLANY
   CASE "SYBASE" $ cTargetDB .OR. "SQL SERVER" $ cTargetDB
      ::nSystemID := SYSTEMID_SYBASE
   CASE "ACCESS" $ cTargetDB
      ::nSystemID := SYSTEMID_ACCESS
   CASE "INGRES" $ cTargetDB
      ::nSystemID := SYSTEMID_INGRES
   CASE "SQLBASE" $ cTargetDB
      ::nSystemID := SYSTEMID_SQLBAS
   CASE "INFORMIX" $ cTargetDB
      ::nSystemID := SYSTEMID_INFORM
   CASE "ADABAS" $ cTargetDB
      ::nSystemID := SYSTEMID_ADABAS
      ::lComments := .F.
   CASE "POSTGRESQL" $ cTargetDB
      ::nSystemID := SYSTEMID_POSTGR
   CASE "DB2" $ cTargetDB .OR. "SQLDS/VM" $ cTargetDB
      ::nSystemID := SYSTEMID_IBMDB2
      ::lComments := .F.
      IF "05.03" $ ::cSystemVers       // Detects AS/400 from Win98 ODBC
         ::cSystemName := "DB2/400"
         cTargetDB     := "DB2/400"
      ENDIF
   CASE "MYSQL" $ cTargetDB .AND. SubStr(alltrim(::cSystemVers), 1, 3) >= "4.1"
      ::nSystemID := SYSTEMID_MYSQL
   CASE "MARIADB" $ cTargetDB
      ::nSystemID := SYSTEMID_MARIADB
   CASE "FIREBIRD" $ cTargetDb .OR. "INTERBASE" $ cTargetdb
      ::nSystemID := SYSTEMID_FIREBR
      aVers := hb_atokens(::cSystemVers, '.')
      IF val(aVers[1]) >= 3
         ::nSystemID := SYSTEMID_FIREBR3
      ENDIF
   CASE "INTERSYSTEMS CACHE" $ cTargetDb
      ::nSystemID := SYSTEMID_CACHE
      ::lComments := .F.
   CASE "OTERRO" $ cTargetDb
      ::nSystemID := SYSTEMID_OTERRO
      ::lComments := .F.
   CASE "PERVASIVE.SQL" $ cTargetDb
      ::nSystemID := SYSTEMID_PERVASIVE
      ::lComments := .F.
   OTHERWISE
      IF !::lQueryOnly
         ::RuntimeErr(, SR_Msg(22) + cTargetDB + " " + ::cSystemVers)
      ENDIF
      ::lComments := .F.
   ENDCASE

   ::cTargetDB := cTargetDB

RETURN NIL

METHOD End() CLASS SR_CONNECTION

   ::hEnv := NIL
   ::hDbc := NIL

RETURN NIL

METHOD GetInfo(nType) CLASS SR_CONNECTION

   HB_SYMBOL_UNUSED(nType)

RETURN ""

METHOD GetOptions(nType) CLASS SR_CONNECTION

   HB_SYMBOL_UNUSED(nType)

RETURN ""

METHOD SetOptions(nType, uBuffer) CLASS SR_CONNECTION

   HB_SYMBOL_UNUSED(nType)
   HB_SYMBOL_UNUSED(uBuffer)

RETURN SQL_SUCCESS

METHOD SetStmtOptions(nType, uBuffer) CLASS SR_CONNECTION

   HB_SYMBOL_UNUSED(nType)
   HB_SYMBOL_UNUSED(uBuffer)

RETURN SQL_SUCCESS

METHOD Commit(lNoLog) CLASS SR_CONNECTION

   DEFAULT lNoLog TO .F.

   IF ::lTraceToDBF
      SR_WriteDbLog("COMMIT", SELF)
   ENDIF
   IF ::lTraceToScreen
      Alert("COMMIT")
   ENDIF
   IF ::lLowLevSqlDbg
      SR_LogFile(::cLowLevLogFile, {"COMMIT"}, ::lLogDateTime)
   ENDIF

   ::nIteractions := 0

   IF ::nLogMode > 0 .AND. StrZero(::nLogMode, SQLLOGCHANGES_SIZE)[2] == "1" .AND. (!lNoLog)
      IF ::cQueryOwner == NIL
         IF !Empty(SR_GetGlobalOwner())
            ::cQueryOwner := alltrim(SR_GetGlobalOwner())
         ELSEIF !Empty(::oSql:cOwner)
            ::cQueryOwner := alltrim(::cOwner)
         ENDIF
         IF (!Empty(::cQueryOwner)) .AND. right(::cQueryOwner, 1) != "."
            ::cQueryOwner += "."
         ENDIF
         IF Empty(::cQueryOwner)
            ::cQueryOwner := ""
         ENDIF
      ENDIF

      IF StrZero(::nLogMode, SQLLOGCHANGES_SIZE)[4] == "1" .OR. ::oSqlTransact == NIL
         SELF:execute("DELETE FROM " + ::cQueryOwner + "SR_MGMNTLOGCHG WHERE SPID_ = " + str(::uSid),,,, .T.)
      ELSE
         ::oSqlTransact:execute("DELETE FROM " + ::cQueryOwner + "SR_MGMNTLOGCHG WHERE SPID_ = " + str(::uSid),,,, .T.)
         ::oSqlTransact:FreeStatement()
         ::oSqlTransact:commit(.T.)
      ENDIF
   ENDIF

RETURN SQL_SUCCESS

METHOD RollBack() CLASS SR_CONNECTION

   IF ::lTraceToDBF
      SR_WriteDbLog("ROLLBACK", SELF)
   ENDIF
   IF ::lTraceToScreen
      Alert("ROLLBACK")
   ENDIF
   IF ::lLowLevSqlDbg
      SR_LogFile(::cLowLevLogFile, {"ROLLBACK"}, ::lLogDateTime)
   ENDIF

   ::nIteractions := 0

   IF ::nLogMode > 0 .AND. StrZero(::nLogMode, SQLLOGCHANGES_SIZE)[2] == "1"
      IF ::cQueryOwner == NIL
         IF !Empty(SR_GetGlobalOwner())
            ::cQueryOwner := alltrim(SR_GetGlobalOwner())
         ELSEIF !Empty(::oSql:cOwner)
            ::cQueryOwner := alltrim(::cOwner)
         ENDIF
         IF (!Empty(::cQueryOwner)) .AND. right(::cQueryOwner, 1) != "."
            ::cQueryOwner += "."
         ENDIF
         IF Empty(::cQueryOwner)
            ::cQueryOwner := ""
         ENDIF
      ENDIF

      IF StrZero(::nLogMode, SQLLOGCHANGES_SIZE)[4] == "1" .OR. ::oSqlTransact == NIL
         SELF:execute("DELETE FROM " + ::cQueryOwner + "SR_MGMNTLOGCHG WHERE SPID_ = " + str(::uSid),,,, .T.)
      ELSE
         ::oSqlTransact:execute("DELETE FROM " + ::cQueryOwner + "SR_MGMNTLOGCHG WHERE SPID_ = " + str(::uSid),,,, .T.)
         ::oSqlTransact:FreeStatement()
         ::oSqlTransact:commit(.T.)
      ENDIF
   ENDIF

RETURN SQL_SUCCESS

METHOD RuntimeErr(cOperation, cErr) CLASS SR_CONNECTION

   LOCAL oErr := ErrorNew()
   LOCAL cDescr

   DEFAULT cOperation TO ::ClassName()
   DEFAULT cErr       TO "RunTimeError"

   cDescr := alltrim(cErr) + SR_CRLF + ;
             "Steatment handle  : " + SR_Val2Char(::hStmt) + SR_CRLF + ;
             "Connection handle : " + SR_Val2Char(::hDbc) + SR_CRLF + ;
             "RetCode           : " + SR_Val2Char(::nRetCode) + SR_CRLF

   ::RollBack()

   oErr:genCode       := 99
   oErr:CanDefault    := .F.
   oErr:Severity      := ES_ERROR
   oErr:CanRetry      := .T.
   oErr:CanSubstitute := .F.
   oErr:Description   := cDescr + " - RollBack executed."
   oErr:subSystem     := ::ClassName()
   oErr:operation     := cOperation
   oErr:OsCode        := 0

   SR_LogFile("sqlerror.log", {cDescr, SR_GetStack()})

   Throw(oErr)

RETURN NIL

FUNCTION SR_AdjustNum(a)

   LOCAL b := aClone(a)
   LOCAL i

   FOR i := 1 TO len(b)

      IF lNwgOldCompat
         IF b[i, 2] = "N"
            b[i, 3]++
         ENDIF
      ENDIF

      IF b[i, 2] = "N" .AND. b[i, 3] > 18
         b[i, 3] := 19
      ENDIF

      IF lNwgOldCompat
         IF b[i, 2] = "N" .AND. b[i, 4] >= (b[i, 3] - 1)
            b[i, 4] := abs(b[i, 3] - 2)
         ENDIF
      ENDIF

      IF b[i, 2] = "M"
         b[i, 3] := 10
      ENDIF

   NEXT i

RETURN b

METHOD Connect(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout) CLASS SR_CONNECTION

   LOCAL hEnv := NIL
   LOCAL hDbc := NIL
   LOCAL cVersion := ""
   LOCAL cSystemVers := ""
   LOCAL cBuff := ""
   LOCAL aCon
   LOCAL aItem
   LOCAL aToken

   DEFAULT nVersion    TO 1
   DEFAULT lTrace      TO .F.
   DEFAULT nPreFetch   TO 0
   DEFAULT cDSN        TO ""
   DEFAULT lCounter    TO .F.
   DEFAULT lAutoCommit TO .F. /* by default support transactions */

   ::lAutoCommit  := lAutoCommit
   ::nVersion     := nVersion
   ::cOwner       := cOwner
   ::lCounter     := lCounter
   ::nRetCode     := 0
   ::nSizeMaxBuff := nSizeMaxBuff
   ::nPreFetch    := nPrefetch
   ::lTrace       := lTrace
   ::nSelMeth     := nSelMeth
   ::nEmptyMode   := nEmptyMode      // ( 0 = Grava NULLS, 1 = Grava o campo no próprio tamanho )
   ::nDateMode    := nDateMode       // ( 0 = Utiliza o padrão do banco, como DATETIME ou TIMESTAMP, 1 = grava em Char(8) )
   ::cDsn         := ""
   ::cUser        := ""
   ::cPassword    := ""
   ::cPort        := NIL
   ::cHost        := ""
   ::cDBS         := ""
   ::cHost        := ""
   ::cDrv         := ""
   ::cDTB         := ""
   ::cNetLibrary  := ""
   ::oOdbc        := SELF            // NewAge backwards compatible...
   ::oSql         := SELF            // NewAge backwards compatible...
   ::cCharSet     := NIL             // should be NIL or FB does not work
   ::lCluster     := .F.
   ::lClustered   := .F.

   IF ::lCounter
      ::lLowLevSqlDbg := (!Empty(GetEnv("QUERYDEBUGCOUNTER"))) .AND. upper(GetEnv("QUERYDEBUGCOUNTER")) $ "Y,S,TRUE"
   ELSE
      ::lLowLevSqlDbg := (!Empty(GetEnv("QUERYDEBUG"))) .AND. upper(GetEnv("QUERYDEBUG")) $ "Y,S,TRUE"
   ENDIF

   ::oHashActiveWAs := SqlFastHash():new()

   IF cConnect == NIL .OR. empty(cConnect)
      SR_MsgLogFile("Invalid connection string : " + SR_Val2Char(cConnect))
      ::nRetCode := SQL_ERROR
      RETURN SELF
   ELSE
      aCon := hb_atokens(cConnect, ";")

      FOR EACH aItem IN aCon

         IF Empty(aItem)
            LOOP
         ENDIF

         aToken := hb_atokens(aItem, "=")
         cBuff := alltrim(Upper(aToken[1]))
         IF len(aToken) = 1
            aadd(aToken, "")
         ENDIF
         SWITCH cBuff
         CASE "UID"
         CASE "UIID"
         CASE "USR"
            ::cUser += aToken[2]
            EXIT
         CASE "PWD"
            ::cPassword += aToken[2]
            EXIT
         CASE "DSN"
            ::cDSN += aToken[2]
            EXIT
         CASE "DBS"
            ::cDBS += aToken[2]
            EXIT
         CASE "HST"
         CASE "OCI"
         CASE "MYSQL"
         CASE "PGS"
         CASE "SERVER"
         CASE "MARIA"
            ::cHost += aToken[2]
            EXIT
         CASE "PRT"
            ::cPort := Val(sr_val2char(aToken[2]))
            EXIT
         CASE "DRV"
         CASE "DRIVER"
            ::cDRV += aToken[2]
            EXIT
         CASE "CHARSET"
            ::cCharSet := aToken[2]
            EXIT
         CASE "AUTOCOMMIT"
            ::nAutoCommit := Val(aToken[2])
            EXIT
         CASE "DTB"
         CASE "FB"
         CASE "FIREBIRD"
         CASE "FB3"
         CASE "FIREBIRD3"
         CASE "IB"
         CASE "TNS"
         CASE "DATABASE"
            ::cDTB += aToken[2]
            EXIT
         CASE "TABLESPACE_DATA"
            ::cDsnTblData := aToken[2]
            EXIT
         CASE "TABLESPACE_INDEX"
            ::cDsnTblIndx := aToken[2]
            EXIT
         CASE "TABLESPACE_LOB"
            ::cDsnTblLob := aToken[2]
            EXIT
         CASE "CLUSTER"
            ::lCluster := Upper(aToken[2]) $ "Y,S,TRUE"
            EXIT
         CASE "OWNER" //.AND. empty(::cOwner)
            ::cOwner := aToken[2]
            IF !Empty(::cOwner) .AND. right(::cOwner, 1) != "."
               ::cOwner += "."
            ENDIF
            EXIT
         CASE "NETWORK"
         CASE "LIBRARY"
         CASE "NETLIBRARY"
            ::cNetLibrary := aToken[2]
            EXIT
         CASE "APP"
            ::cApp := aToken[2]
            EXIT
         CASE "SSLCERT"
            ::sslcert := aToken[2]
            EXIT
         CASE "SSLKEY"
            ::sslkey := aToken[2]
            EXIT
         CASE "SSLROOTCERT"
            ::sslrootcert := aToken[2]
            EXIT
         CASE "SSLCRL"
            ::sslcrl := aToken[2]
            EXIT
         CASE "COMPRESS"
            ::lCompress := Upper(aToken[2]) $ "Y,S,TRUE"
//         OtherWise
//            SR_MsgLogFile("Invalid connection string entry : " + cBuff + " = " + SR_Val2Char(aToken[2]))
         ENDSWITCH
      NEXT
   ENDIF

   ::nSystemID := SYSTEMID_UNKNOW

   ::ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, alltrim(cConnect), nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout)

   SWITCH ::nSystemID
   CASE SYSTEMID_ORACLE
      ::cLockWait := " WAIT " + str(int(::nLockWaitTime))
      EXIT
   OTHERWISE
      ::cLockWait := ""
   ENDSWITCH

RETURN SELF

METHOD SQLType(nType, cName, nLen) CLASS SR_CONNECTION

   LOCAL cType := "U"

   HB_SYMBOL_UNUSED(cName)

   DEFAULT nLen TO 0

   SWITCH nType
   CASE SQL_CHAR
   CASE SQL_VARCHAR
   CASE SQL_NVARCHAR
   CASE SQL_GUID
      IF IIf(lNwgOldCompat, nLen != 4000 .AND. nLen != 2000, .T.)
         cType := "C"
      ENDIF
      EXIT
   CASE SQL_SMALLINT
   CASE SQL_TINYINT
      IF ::lQueryOnly
         cType := "N"
      ELSE
         cType := "L"
      ENDIF
      EXIT
   CASE SQL_BIT
      cType := "L"
      EXIT
   CASE SQL_NUMERIC
   CASE SQL_DECIMAL
   CASE SQL_INTEGER
   CASE SQL_BIGINT
   CASE SQL_FLOAT
   CASE SQL_REAL
   CASE SQL_DOUBLE
      cType := "N"
      EXIT
   //CASE SQL_DATE
   //CASE SQL_TIMESTAMP
   //CASE SQL_TYPE_TIMESTAMP
   //CASE SQL_TYPE_DATE
   CASE SQL_DATE
   CASE SQL_TYPE_DATE
      cType := "D"
      EXIT
   CASE SQL_TIME
      IF      ::nSystemID == SYSTEMID_POSTGR ;
         .OR. ::nSystemID == SYSTEMID_MYSQL ;
         .OR. ::nSystemID == SYSTEMID_MARIADB ;
         .OR. ::nSystemID == SYSTEMID_FIREBR ;
         .OR. ::nSystemID == SYSTEMID_FIREBR3
         cType := "T"
      ELSE
         cType := "C"
      ENDIF
      EXIT
   CASE SQL_LONGVARCHAR
   CASE SQL_DB2_CLOB
   CASE SQL_FAKE_LOB
   CASE SQL_LONGVARBINARY
      cType := "M"
      EXIT
   CASE SQL_VARBINARY
      IF ::nSystemID != SYSTEMID_MSSQL7
         cType := "M"
      ENDIF
      IF ::nSystemID == SYSTEMID_MSSQL7
         cType := "V"
      ENDIF
      EXIT
   CASE SQL_TIMESTAMP
   CASE SQL_TYPE_TIMESTAMP
   CASE SQL_DATETIME
      cType := "T"
   ENDSWITCH

   IF cType == "U"
      SR_MsgLogFile(SR_Msg(2) + SR_Val2CharQ(nType))
   ENDIF

RETURN cType

METHOD SQLLen(nType, nLen, nDec) CLASS SR_CONNECTION

   LOCAL cType := "U"

   DEFAULT nDec TO -1

   SWITCH nType
   CASE SQL_CHAR
   CASE SQL_VARCHAR
   CASE SQL_NVARCHAR
      IF IIf(lNwgOldCompat, nLen != 4000 .AND. nLen != 2000, .T.)
      ENDIF
      EXIT
   CASE SQL_SMALLINT
   CASE SQL_TINYINT
      IF ::lQueryOnly
         nLen := 10
      ELSE
         nLen := 1
      ENDIF
      EXIT
   CASE SQL_BIT
      nLen := 1
      EXIT
   CASE SQL_NUMERIC
   CASE SQL_DECIMAL
   CASE SQL_INTEGER
   CASE SQL_FLOAT
   CASE SQL_REAL
   CASE SQL_DOUBLE
      IF nLen > 19 .AND. nDec > 10 .AND. !(nLen = 38 .AND. nDec = 0)
         nLen := 20
         nDec := 6
      ENDIF
      IF !(nLen = 38 .AND. nDec = 0)
         nLen := min(nLen, 20)
         nLen := max(nLen, 1)
      ENDIF
      EXIT
   CASE SQL_DATE
   CASE SQL_TIMESTAMP
   CASE SQL_TYPE_TIMESTAMP
   CASE SQL_TYPE_DATE
   CASE SQL_DATETIME
      nLen := 8
      EXIT
   CASE SQL_TIME
      nLen := 8
      EXIT
   CASE SQL_LONGVARCHAR
   CASE SQL_LONGVARBINARY
   CASE SQL_FAKE_LOB
   CASE SQL_VARBINARY
      nLen := 10
      EXIT
   CASE SQL_GUID
      nLen := 36
   ENDSWITCH

RETURN nLen

FUNCTION SR_SetNwgCompat(l)

   LOCAL lOld := lNwgOldCompat

   IF l != NIL
      lNwgOldCompat := l
   ENDIF

RETURN lOld

FUNCTION SR_AutoCommit(nSet)

   LOCAL nOld
   LOCAL oSql

   oSql := SR_GetConnection()

   nOld := oSql:nAutoCommit

   IF HB_ISNUMERIC(nSet)
      oSql:nAutoCommit := nSet
   ENDIF

RETURN nOld

FUNCTION SR_AllInCache(lSet)

   LOCAL lOld
   LOCAL oSql

   oSql := SR_GetConnection()

   lOld := oSql:lAllInCache

   IF HB_ISLOGICAL(lSet)
      oSql:lAllInCache := lSet
   ENDIF

RETURN lOld

FUNCTION SR_SetTraceLog(cLog)

   LOCAL cOld
   LOCAL oSql

   oSql := SR_GetConnection()

   cOld := oSql:cLowLevLogFile

   IF HB_ISCHAR(cLog)
      oSql:cLowLevLogFile := cLog
   ENDIF

RETURN cOld
