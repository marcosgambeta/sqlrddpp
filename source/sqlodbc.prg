/*
 * SQLRDD ODBC Connection Class
 * Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
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

#define SR_CRLF   (chr(13) + chr(10))

#define DEBUGSESSION     .F.
#define ARRAY_BLOCK      500

#define SQL_LONGDATA_COMPAT          1253
#define SQL_ATTR_LONGDATA_COMPAT    SQL_LONGDATA_COMPAT
#define SQL_LD_COMPAT_YES            1

CLASS SR_ODBC FROM SR_CONNECTION

   Data aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit)
   METHOD End()
   METHOD GetInfo(nType)
   METHOD SetOptions(nType, uBuffer)
   METHOD GetOptions(nType)
   METHOD LastError()
   METHOD Commit()
   METHOD RollBack()
   METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)
   METHOD ExecuteRaw(cCommand)
   METHOD AllocStatement()
   METHOD SetStmtOptions(nType, uBuffer)
   METHOD FreeStatement()
   METHOD FetchRaw(lTranslate, aFields)
   METHOD FieldGet(nField, aFields, lTranslate)
   METHOD MoreResults(aArray)
   METHOD WriteMemo(cFileName, nRecno, cRecnoName, aColumnsAndData)
   METHOD DriverCatTables()
   METHOD Getline(aFields, lTranslate, aArray)
   METHOD FetchMultiple(lTranslate, aFields, aCache, nCurrentFetch, aInfo, nDirection, nBlockPos, hnRecno, lFetchAll, aFetch, uRecord, nPos)

ENDCLASS

METHOD FetchMultiple(lTranslate, aFields, aCache, nCurrentFetch, aInfo, nDirection, hnRecno, lFetchAll, aFetch, uRecord, nPos) CLASS SR_ODBC

   DEFAULT lTranslate TO .T.

RETURN SR_ODBCGETLINES(::hStmt, 4096, aFields, aCache, ::nSystemID, lTranslate, nCurrentFetch, aInfo, nDirection, hnRecno, lFetchAll, aFetch, uRecord, nPos)

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_ODBC

   LOCAL i

   DEFAULT lTranslate TO .T.

   IF aArray == NIL
      aArray := Array(len(aFields))
   ELSEIF len(aArray) < len(aFields)
      aSize(aArray, len(aFields))
   ENDIF

   IF ::aCurrLine == NIL
      SR_ODBCLINEPROCESSED(::hStmt, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   ENDIF

   FOR i := 1 TO len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

METHOD DriverCatTables() CLASS SR_ODBC

   LOCAL nRet
   LOCAL aArray := Array(ARRAY_BLOCK1)
   LOCAL nAllocated
   LOCAL nBlocks
   LOCAL aFields
   LOCAL n := 0

   ::AllocStatement()
   nRet := SR_Tables(::hStmt)

   IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO

      nAllocated := ARRAY_BLOCK1
      nBlocks    := 1
      n          := 0
      aFields    := ::IniFields(.F.,,,,,,)

      DO WHILE (::nRetCode := ::Fetch()) = SQL_SUCCESS

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

         aArray[n] := {::FieldGet(3, aFields, .F.)}
      ENDDO
   ENDIF

   ::FreeStatement()
   aSize(aArray, n)

RETURN aArray

METHOD MoreResults(aArray, lTranslate) CLASS SR_ODBC

   LOCAL nRet
   LOCAL i
   LOCAL n

   STATIC aFieldsMore

   DEFAULT lTranslate TO .T.

   nRet := SR_MoreResults(::hStmt)

   IF nRet == SQL_SUCCESS

      DEFAULT aArray TO {}
      n := 1
      IF aFieldsMore == NIL
         aFieldsMore := ::IniFields(.F., , , , , SR_RecnoName(), SR_DeletedName())
      ENDIF

      DO WHILE (::nRetCode := ::FetchRaw(lTranslate, aFieldsMore)) = SQL_SUCCESS
         AADD(aArray, Array(len(aFieldsMore)))
         FOR i := 1 TO len(aFieldsMore)
            aArray[n, i] := ::FieldGet(i, aFieldsMore, lTranslate)
         NEXT i
         n++
      ENDDO

   ENDIF

RETURN nRet

METHOD FieldGet(nField, aFields, lTranslate) CLASS SR_ODBC

   IF ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := array(LEN(aFields))
      SR_ODBCLINEPROCESSED(::hStmt, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   ENDIF

RETURN ::aCurrLine[nField]

METHOD FetchRaw(lTranslate, aFields) CLASS SR_ODBC

   ::nRetCode := SQL_ERROR
   DEFAULT aFields    TO ::aFields
   DEFAULT lTranslate TO .T.

   IF ::hStmt != NIL
      ::nRetCode := SR_Fetch(::hStmt)
      ::aCurrLine := NIL
   ELSE
      ::RunTimeErr("", "SQLFetch - Invalid cursor state" + SR_CRLF + SR_CRLF + "Last command sent to database : " + SR_CRLF + ::cLastComm)
   ENDIF

RETURN ::nRetCode

METHOD FreeStatement() CLASS SR_ODBC

   IF !empty(::hStmt) // != NIL // != 0
      IF SR_FreeStm(::hStmt, SQL_DROP) != SQL_SUCCESS
         ::RunTimeErr("", "SQLFreeStmt [DROP] error" + SR_CRLF + SR_CRLF + "Last command sent to database : " + SR_CRLF + ::cLastComm)
      ENDIF
      ::hStmt := NIL
   ENDIF

RETURN NIL

METHOD AllocStatement() CLASS SR_ODBC

   LOCAL hStmtLocal := NIL
   LOCAL nRet := 0

   ::FreeStatement()

   IF (nRet := SR_AllocSt(::hDbc, @hStmtLocal)) == SQL_SUCCESS
      ::hStmt = hStmtLocal
   ELSE
      ::nRetCode := nRet
      ::RunTimeErr("", "SQLAllocStmt [NEW] Error" + SR_CRLF + SR_CRLF + ::LastError() + SR_CRLF + SR_CRLF + "Last command sent to database : " + SR_CRLF + ::cLastComm)
      RETURN NIL
   ENDIF

   IF ::lSetNext .AND. nRet == SQL_SUCCESS
      ::lSetNext := .F.
      nRet := ::SetStmtOptions(::nSetOpt, ::nSetValue)
      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         SR_MsgLogFile(SR_Msg(23) + " (" + alltrim(str(nRet)) + ") : " + ::LastError())
      ENDIF
   ENDIF

RETURN nRet

METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName) CLASS SR_ODBC

   LOCAL n
   LOCAL nFields := 0
   LOCAL nType := 0
   LOCAL nLen := 0
   LOCAL nNull := 0
   LOCAL cName
   LOCAL _nLen
   LOCAL _nDec
   LOCAL cType
   LOCAL nLenField
   LOCAL nNameLen
   LOCAL aFields := {}
   LOCAL nDec := 0
   LOCAL nSoma
   LOCAL nRet
   LOCAL cVlr := ""
   //LOCAL nBfLn
   //LOCAL nOut

   DEFAULT lReSelect    TO .T.
   DEFAULT lLoadCache   TO .F.
   DEFAULT cWhere       TO ""
   DEFAULT cRecnoName   TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   IF lReSelect
      IF !Empty(cCommand)
         nRet := ::Execute(cCommand + iif(::lComments, " /* Open Workarea with custom SQL command */", ""), .F.)
      ELSE
         nRet := ::Execute("SELECT A.* FROM " + cTable + " A " + iif(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + iif(::lComments, " /* Open Workarea */", ""), .F.)
      ENDIF

      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         RETURN NIL
      ENDIF
   ENDIF

   IF (::nRetCode := SR_NumRes(::hStmt, @nFields)) != SQL_SUCCESS
      ::RunTimeErr("", "SqlNumResultCols Error" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
      RETURN NIL
   ENDIF

   aFields := Array(nFields)
   ::nFields := nFields

   FOR n := 1 TO nFields

      nDec := 0
      nSoma := 0

      IF (::nRetCode := SR_Describ(::hStmt, n, @cName, 255, @nNameLen, @nType, @nLen, @nDec, @nNull, ::nSystemID)) != SQL_SUCCESS
         ::RunTimeErr("", "SQLDescribeCol Error" + SR_CRLF + ::LastError() + SR_CRLF + ;
            "Last command sent to database : " + ::cLastComm)
         RETURN NIL
      ELSE
         _nLen := nLen
         _nDec := nDec
         IF (nType == SQL_DOUBLE .OR. nType == SQL_FLOAT) .AND. nDec == 0
            nDec := 6
            nSoma := 6
         ENDIF

         IF (nLen == 2000 .OR. nLen == 4000) .AND. SR_SetNwgCompat()
            nType := SQL_FAKE_LOB
         ENDIF

         IF ::nSystemID == SYSTEMID_ORACLE .AND. nLen == 19 .AND. (nType == SQL_TIMESTAMP .OR. nType == SQL_TYPE_TIMESTAMP .OR. nType == SQL_DATETIME)
             nType := SQL_DATE
         ENDIF
         IF ::nsystemId ==  SYSTEMID_MSSQL7
            IF (ntype == SQL_TYPE_DATE) .AND. SR_GETSQL2008NEWTYPES() .AND. ::lSqlServer2008
               nType := SQL_DATE
            ELSEIF (nType == SQL_TIMESTAMP .OR. nType == SQL_TYPE_TIMESTAMP .OR. nType == SQL_DATETIME) .AND. SR_GETSQL2008NEWTYPES() .AND. ::lSqlServer2008
            ELSEIF (nType == SQL_TIMESTAMP .OR. nType == SQL_TYPE_TIMESTAMP .OR. nType == SQL_DATETIME) .AND. !SR_GETSQL2008NEWTYPES() //.AND. !::lSqlServer2008
               nType := SQL_DATE
            ENDIF
         ENDIF

         cName := upper(alltrim(cName))
         cType := ::SQLType(nType, cName, nLen)
         nLenField := ::SQLLen(nType, nLen, @nDec) + nSoma
         IF ::nSystemID == SYSTEMID_ORACLE .AND. (!::lQueryOnly) .AND. cType == "N" .AND. nLenField == 38 .AND. nDec == 0
            cType := "L"
            nLenField := 1
         ENDIF
/*
         IF ::nSystemID == SYSTEMID_POSTGR
            nRet := SR_ColAttribute(::hStmt, n, SQL_DESC_NULLABLE, @cVlr, 64, @nBfLn, @nOut)
            nNull := nOut
         ENDIF
*/
         IF cType == "U"
            ::RuntimeErr("", SR_Msg(21) + cName + " : " + str(nType))
         ELSE
            aFields[n] := {cName, cType, nLenField, iif(cType == "D", 0, nDec), nNull >= 1, nType, nLen, n, _nDec}
         ENDIF
      ENDIF

   NEXT n

   ::aFields := aFields

   IF lReSelect .AND. !lLoadCache
      ::FreeStatement()
   ENDIF

RETURN aFields

METHOD LastError() CLASS SR_ODBC

   LOCAL cClassError := space(200)
   LOCAL nType := 0
   LOCAL cMsgError := space(200)
   LOCAL nRealLen := 0

   SR_Error(::hEnv, ::hDbc, ::hStmt, @cClassError, @nType, @cMsgError, 256, nRealLen)

RETURN SR_Val2Char(cClassError) + " - " + AllTrim(SR_Val2Char(nType)) + " - " + SR_Val2Char(cMsgError)

METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit) CLASS SR_ODBC

   LOCAL hEnv := NIL
   LOCAL hDbc := NIL
   LOCAL nret
   LOCAL cVersion := ""
   LOCAL cSystemVers := ""
   LOCAL cBuff := ""
   LOCAL aRet := {}

   HB_SYMBOL_UNUSED( cDSN)
   HB_SYMBOL_UNUSED(cUser)
   HB_SYMBOL_UNUSED(cPassword)
   HB_SYMBOL_UNUSED(nVersion)
   HB_SYMBOL_UNUSED(cOwner)
   HB_SYMBOL_UNUSED(nSizeMaxBuff)
   HB_SYMBOL_UNUSED(lTrace)
   HB_SYMBOL_UNUSED(nPrefetch)
   HB_SYMBOL_UNUSED(nselMeth)
   HB_SYMBOL_UNUSED(nEmptyMode)
   HB_SYMBOL_UNUSED(nDateMode)
   HB_SYMBOL_UNUSED(lCounter)
   HB_SYMBOL_UNUSED(lAutoCommit)

   ::lNative := .F.

   IF (nRet := SR_AllocEn(@hEnv)) == SQL_SUCCESS
      ::hEnv := hEnv
   ELSE
      ::nRetCode := nRet
      SR_MsgLogFile("SQLALLOCENV Error" + str(nRet))
      RETURN SELF
   ENDIF

   IF (nret := SR_ALLOCCO(hEnv, @hDbc)) == SQL_SUCCESS
      ::hDbc := hDbc
   ELSE
      ::nRetCode := nRet
      SR_MsgLogFile("SQLALLOCCONNECT Error" + str(nRet))
      RETURN SELF
   ENDIF

   IF !Empty(::cDTB)
      SR_SetCOnnectAttr(hDbc, SQL_ATTR_CURRENT_CATALOG, ::cDTB, len(::cDTB))
   ENDIF

   cConnect := alltrim(cConnect)
   nRet := SR_DriverC(hDbc, @cConnect)

   IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode := nRet
      SR_MsgLogFile("SQLDriverConnect Error: No ODBC connection established " + ::LastError())
      RETURN SELF
   ELSE
      ::cConnect := cConnect
      SR_GetInfo(hDbc, SQL_DBMS_NAME, @cTargetDB)
      SR_GetInfo(hDbc, SQL_DBMS_VER, @cSystemVers)
   ENDIF

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers

   ::DetectTargetDb()

   SWITCH ::nSystemID
   CASE SYSTEMID_IBMDB2
      SR_SetConnectAttr(hDbc, SQL_ATTR_LONGDATA_COMPAT, SQL_LD_COMPAT_YES)
      EXIT
   CASE SYSTEMID_MSSQL7
   CASE SYSTEMID_AZURE
      ::exec("select cast( @@spid as numeric )", .T., .T., @aRet)
      IF len(aRet) > 0
         ::uSid := val(str(aRet[1, 1], 8, 0))
      ENDIF
      EXIT
   ENDSWITCH

RETURN SELF

METHOD End() CLASS SR_ODBC

   LOCAL nRet

   ::Commit(.T.)

   IF (nRet := SR_Disconn(::hDbc)) != SQL_SUCCESS
      SR_MsgLogFile("Error disconnecting : " + str(nRet) + SR_CRLF + ::LastError())
   ELSE
      IF (nRet := SR_FreeCon(::hDbc)) != SQL_SUCCESS
         SR_MsgLogFile("Error in SR_FreeCon() : " + str(nRet) + SR_CRLF + ::LastError())
      ELSE
         If (nRet := SR_FreeEnv(::hEnv)) != SQL_SUCCESS
            SR_MsgLogFile("Error in SR_FreeEnv() : " + str(nRet) + SR_CRLF + ::LastError())
         EndIf
      ENDIF
   ENDIF

RETURN ::Super:End()

METHOD GetInfo(nType) CLASS SR_ODBC

   LOCAL cBuffer := Space(256)

   ::nRetCode := SR_GetInfo(::hDbc, nType, @cBuffer)

RETURN cBuffer

METHOD GetOptions(nType) CLASS SR_ODBC

  LOCAL cBuffer := space(256)

   ::nRetCode := SR_GETCONNECTOPTION(::hDbc, nType, @cBuffer)

RETURN cBuffer

METHOD SetOptions(nType, uBuffer) CLASS SR_ODBC

RETURN (::nRetCode := SR_SetConnectOption(::hDbc, nType, uBuffer))

METHOD SetStmtOptions(nType, uBuffer) CLASS SR_ODBC

RETURN (::nRetCode := SR_SetStmtOption(::hStmt, nType, uBuffer))

METHOD Commit(lNoLog) CLASS SR_ODBC

   ::Super:Commit(lNoLog)

RETURN (::nRetCode := SR_Commit(::hEnv, ::hDbc))

METHOD RollBack() CLASS SR_ODBC

   ::Super:RollBack()

RETURN (::nRetCode := SR_RollBack(::hEnv, ::hDbc))

METHOD ExecuteRaw(cCommand) CLASS SR_ODBC

RETURN SR_ExecDir(::hStmt, cCommand)

METHOD WriteMemo(cFileName, nRecno, cRecnoName, aColumnsAndData) CLASS SR_ODBC

   ::FreeStatement()

RETURN SR_ODBCWriteMemo(::hDbc, cFileName, nRecno, cRecnoName, aColumnsAndData)
