/*
 * SQLRDD Firebird Connection Class
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
#include "firebird.ch"
#include "sqlrddsetup.ch"

#define SR_CRLF   (chr(13) + chr(10))

#define DEBUGSESSION     .F.
#define ARRAY_BLOCK      500

/*------------------------------------------------------------------------*/

CLASS SR_FIREBIRD3 FROM SR_CONNECTION

   Data aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit)
   METHOD End()
   METHOD LastError()
   METHOD Commit()
   METHOD RollBack()
   METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)
   METHOD ExecuteRaw(cCommand)
   METHOD AllocStatement()
   METHOD FetchRaw(lTranslate, aFields)
   METHOD FieldGet(nField, aFields, lTranslate)
   METHOD Getline(aFields, lTranslate, aArray)
   METHOD MoreResults(aArray, lTranslate)

ENDCLASS

/*------------------------------------------------------------------------*/

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_FIREBIRD3

   LOCAL i

   DEFAULT lTranslate TO .T.

   IF aArray == NIL
      aArray := Array(len(aFields))
   ELSEIF len(aArray) != len(aFields)
      aSize(aArray, len(aFields))
   ENDIF

   IF ::aCurrLine == NIL
      FBLINEPROCESSED3(::hEnv, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   ENDIF

   FOR i := 1 TO len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

/*------------------------------------------------------------------------*/

METHOD FieldGet(nField, aFields, lTranslate) CLASS SR_FIREBIRD3

   IF ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := array(LEN(aFields))
      FBLINEPROCESSED3(::hEnv, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   ENDIF

RETURN ::aCurrLine[nField]

/*------------------------------------------------------------------------*/

METHOD FetchRaw(lTranslate, aFields) CLASS SR_FIREBIRD3

   ::nRetCode := SQL_ERROR
   DEFAULT aFields TO ::aFields
   DEFAULT lTranslate TO .T.

   IF ::hEnv != NIL
      ::nRetCode := FBFetch3(::hEnv)
      ::aCurrLine := NIL
   ELSE
      ::RunTimeErr("", "FBFetch - Invalid cursor state" + SR_CRLF + SR_CRLF + "Last command sent to database : " + SR_CRLF + ::cLastComm)
   ENDIF

RETURN ::nRetCode

/*------------------------------------------------------------------------*/

METHOD AllocStatement() CLASS SR_FIREBIRD3

   IF ::lSetNext
      IF ::nSetOpt == SQL_ATTR_QUERY_TIMEOUT
         // To do.
      ENDIF
      ::lSetNext := .F.
   ENDIF

RETURN SQL_SUCCESS

/*------------------------------------------------------------------------*/

METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName) CLASS SR_FIREBIRD3

   LOCAL n
   LOCAL nFields := 0
   LOCAL nType := 0
   LOCAL nLen := 0
   LOCAL nNull := 0
   LOCAL cName
   LOCAL _nLen
   LOCAL _nDec
   LOCAL nPos
   LOCAL cType
   LOCAL nLenField
   LOCAL aFields := {}
   LOCAL nDec := 0
   LOCAL nRet
   LOCAL cVlr := ""
   LOCAL aLocalPrecision := {}

   DEFAULT lReSelect TO .T.
   DEFAULT lLoadCache TO .F.
   DEFAULT cWhere TO ""
   DEFAULT cRecnoName TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   IF lReSelect
      IF !Empty(cCommand)
         nRet := ::Execute(cCommand + iif(::lComments, " /* Open Workarea with custom SQL command */", ""), .F.)
      ELSE
         // DOON'T remove "+0"
         ::Exec("select a.rdb$field_name, b.rdb$field_precision + 0 from rdb$relation_fields a, rdb$fields b where a.rdb$relation_name = '" + StrTran(cTable, chr(34), "") + "' and a.rdb$field_source = b.rdb$field_name", .F., .T., @aLocalPrecision)
         nRet := ::Execute("SELECT A.* FROM " + cTable + " A " + iif(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + iif(::lComments, " /* Open Workarea */", ""), .F.)
      ENDIF
      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         RETURN NIL
      ENDIF
   ENDIF

   IF (::nRetCode := FBNumResultCols3(::hEnv, @nFields)) != SQL_SUCCESS
      ::RunTimeErr("", "FBNumResultCols Error" + SR_CRLF + SR_CRLF + "Last command sent to database : " + SR_CRLF + ::cLastComm)
      RETURN NIL
   ENDIF

   aFields := Array(nFields)
   ::nFields := nFields

   FOR n := 1 TO nFields

      nDec := 0

      IF (::nRetCode := FBDescribeCol3(::hEnv, n, @cName, @nType, @nLen, @nDec, @nNull)) != SQL_SUCCESS
         ::RunTimeErr("", "FBDescribeCol Error" + SR_CRLF + ::LastError() + SR_CRLF + "Last command sent to database : " + ::cLastComm)
         RETURN NIL
      ELSE
         _nLen := nLen
         _nDec := nDec

         cName := upper(alltrim(cName))
         nPos := aScan(aLocalPrecision, {|x|rtrim(x[1]) == cName})
         cType := ::SQLType(nType, cName, nLen)
         nLenField := ::SQLLen(nType, nLen, @nDec)
         IF nPos > 0 .AND. aLocalPrecision[nPos, 2] > 0
            nLenField := aLocalPrecision[nPos, 2]
         ELSEIF (nType == SQL_DOUBLE .OR. nType == SQL_FLOAT .OR. nType == SQL_NUMERIC)
            nLenField := 19
         ENDIF

         IF cType == "U"
            ::RuntimeErr("", SR_Msg(21) + cName + " : " + str(nType))
         ELSE
            aFields[n] := {cName, cType, nLenField, nDec, nNull >= 1, nType, , n, _nDec, ,}
         ENDIF

      ENDIF
   NEXT n

   ::aFields := aFields

   IF lReSelect .AND. !lLoadCache
      ::FreeStatement()
   ENDIF

RETURN aFields

/*------------------------------------------------------------------------*/

METHOD LastError() CLASS SR_FIREBIRD3

   LOCAL cMsgError
   LOCAL nType := 0

   cMsgError := FBError3(::hEnv, @nType)

RETURN alltrim(cMsgError) + " - Native error code " + AllTrim(str(nType))

/*------------------------------------------------------------------------*/

METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, ;
   cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit) CLASS SR_FIREBIRD3

   LOCAL nRet
   LOCAL hEnv
   LOCAL cSystemVers

   HB_SYMBOL_UNUSED(cDSN)
   HB_SYMBOL_UNUSED(cUser)
   HB_SYMBOL_UNUSED(cPassword)
   HB_SYMBOL_UNUSED(nVersion)
   HB_SYMBOL_UNUSED(cOwner)
   HB_SYMBOL_UNUSED(nSizeMaxBuff)
   HB_SYMBOL_UNUSED(lTrace)
   HB_SYMBOL_UNUSED(nPrefetch)
   HB_SYMBOL_UNUSED(nSelMeth)
   HB_SYMBOL_UNUSED(nEmptyMode)
   HB_SYMBOL_UNUSED(nDateMode)
   HB_SYMBOL_UNUSED(lCounter)
   HB_SYMBOL_UNUSED(lAutoCommit)

   nRet := FBConnect3(::cDtb, ::cUser, ::cPassword, ::cCharSet, @hEnv)

   IF nRet != SQL_SUCCESS
      ::nRetCode := nRet
      SR_MsgLogFile("Connection Error: " + alltrim(str(nRet)) + " (check fb.log) - Database: " + ::cDtb + " - Username : " + ::cUser + " (Password not shown for security)")
      RETURN SELF
   ELSE
      ::cConnect := cConnect
      cTargetDB := StrTran(FBVERSION3(hEnv), "(access method)", "")
      cSystemVers := SubStr(cTargetDB, at("Firebird ", cTargetDB) + 9, 3)
      //tracelog("cTargetDB", cTargetDB, "cSystemVers", cSystemVers)
   ENDIF

   nRet := FBBeginTransaction3(hEnv)

   IF nRet != SQL_SUCCESS
      ::nRetCode := nRet
      SR_MsgLogFile("Transaction Start error : " + alltrim(str(nRet)))
      RETURN SELF
   ENDIF

   ::hEnv := hEnv
   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers

   ::DetectTargetDb()

RETURN SELF

/*------------------------------------------------------------------------*/

METHOD End() CLASS SR_FIREBIRD3

   ::Commit()
   FBClose(::hEnv)

RETURN ::Super:End()

/*------------------------------------------------------------------------*/

METHOD Commit() CLASS SR_FIREBIRD3

   ::Super:Commit()
   ::nRetCode := FBCOMMITTRANSACTION3(::hEnv)

RETURN (::nRetCode := FBBeginTransaction3(::hEnv))

/*------------------------------------------------------------------------*/

METHOD RollBack() CLASS SR_FIREBIRD3

   ::super:RollBack()

RETURN (::nRetCode := FBRollBackTransaction3(::hEnv))

/*------------------------------------------------------------------------*/

METHOD ExecuteRaw(cCommand) CLASS SR_FIREBIRD3

   LOCAL nRet

   IF upper(left(ltrim(cCommand), 6)) == "SELECT" .OR. "RETURNING" $ upper(alltrim(cCommand))
      nRet := FBExecute3(::hEnv, cCommand, IB_DIALECT_CURRENT)
      ::lResultSet := .T.
   ELSE
      nRet := FBExecuteImmediate3(::hEnv, cCommand, IB_DIALECT_CURRENT)
      ::lResultSet := .F.
   ENDIF

RETURN nRet

/*------------------------------------------------------------------------*/

METHOD MoreResults(aArray, lTranslate) CLASS SR_FIREBIRD3

   LOCAL nRet
   LOCAL i
   LOCAL n
   LOCAL nvalue := -1

   STATIC aFieldsMore

   DEFAULT lTranslate TO .T.

   nRet := FB_MoreResults(::hEnv, @nValue)

   IF nRet == SQL_SUCCESS

      DEFAULT aArray TO {}
      n := 1

      AADD(aArray, Array(1))

      aArray[n, 1] := nvalue

   ENDIF

RETURN nRet
