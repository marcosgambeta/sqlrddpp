//
// SQLRDD Firebird Connection Class
// Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
//

// $BEGIN_LICENSE$
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2, or (at your option)
// any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this software; see the file COPYING.  If not, write to
// the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
// Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
//
// As a special exception, the xHarbour Project gives permission for
// additional uses of the text contained in its release of xHarbour.
//
// The exception is that, if you link the xHarbour libraries with other
// files to produce an executable, this does not by itself cause the
// resulting executable to be covered by the GNU General Public License.
// Your use of that executable is in no way restricted on account of
// linking the xHarbour library code into it.
//
// This exception does not however invalidate any other reasons why
// the executable file might be covered by the GNU General Public License.
//
// This exception applies only to the code released by the xHarbour
// Project under the name xHarbour.  If you copy code from other
// xHarbour Project or Free Software Foundation releases into a copy of
// xHarbour, as the General Public License permits, the exception does
// not apply to the code that you add in this way.  To avoid misleading
// anyone as to the status of such modified files, you must delete
// this exception notice from them.
//
// If you write modifications of your own for xHarbour, it is your choice
// whether to permit this exception to apply to your modifications.
// If you do not wish that, delete this exception notice.
// $END_LICENSE$

// TODO: inherit from SR_FIREBIRD3
//       remove duplicated code

#include <hbclass.ch>
#include <common.ch>
// #include "compat.ch"
#include "sqlodbc.ch"
#include "sqlrdd.ch"
#include "sqlrddpp.ch"
#include <error.ch>
#include "msg.ch"
#include "firebird.ch"
#include "sqlrddsetup.ch"

#define DEBUGSESSION     .F.
#define ARRAY_BLOCK      500

//-------------------------------------------------------------------------------------------------------------------//

CLASS SR_FIREBIRD4 FROM SR_CONNECTION

   Data aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, ;
      nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit)
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

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:Getline(aFields, lTranslate, aArray)

   LOCAL i

   DEFAULT lTranslate TO .T.

   IF aArray == NIL
      aArray := Array(Len(aFields))
   ELSEIF Len(aArray) != Len(aFields)
      ASize(aArray, Len(aFields))
   ENDIF

   IF ::aCurrLine == NIL
      FBLINEPROCESSED4(::hEnv, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   ENDIF

   FOR i := 1 TO Len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:FieldGet(nField, aFields, lTranslate)

   IF ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := Array(Len(aFields))
      FBLINEPROCESSED4(::hEnv, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   ENDIF

RETURN ::aCurrLine[nField]

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:FetchRaw(lTranslate, aFields)

   ::nRetCode := SQL_ERROR
   DEFAULT aFields TO ::aFields
   DEFAULT lTranslate TO .T.

   IF ::hEnv != NIL
      ::nRetCode := FBFetch4(::hEnv)
      ::aCurrLine := NIL
   ELSE
      ::RunTimeErr("", "FBFetch - Invalid cursor state" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
   ENDIF

RETURN ::nRetCode

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:AllocStatement()

   IF ::lSetNext
      IF ::nSetOpt == SQL_ATTR_QUERY_TIMEOUT
         // To do.
      ENDIF
      ::lSetNext := .F.
   ENDIF

RETURN SQL_SUCCESS

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)

   LOCAL n
   LOCAL nFields := 0
   LOCAL nType := 0
   LOCAL nLen := 0
   LOCAL nNull := 0
   LOCAL cName
   //LOCAL _nLen (variable disabled)
   LOCAL _nDec
   LOCAL nPos
   LOCAL cType
   LOCAL nLenField
   LOCAL aFields
   LOCAL nDec := 0
   LOCAL nRet
   LOCAL aLocalPrecision := {}

   DEFAULT lReSelect TO .T.
   DEFAULT lLoadCache TO .F.
   DEFAULT cWhere TO ""
   DEFAULT cRecnoName TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   IF lReSelect
      IF !Empty(cCommand)
         nRet := ::Execute(cCommand + IIf(::lComments, " /* Open Workarea with custom SQL command */", ""), .F.)
      ELSE
         // DOON'T remove "+0"
         ::Exec("select a.rdb$field_name, b.rdb$field_precision + 0 from rdb$relation_fields a, " + ;
            "rdb$fields b where a.rdb$relation_name = '" + StrTran(cTable, Chr(34), "") + ;
            "' and a.rdb$field_source = b.rdb$field_name", .F., .T., @aLocalPrecision)
         nRet := ::Execute("SELECT A.* FROM " + cTable + " A " + ;
            IIf(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + ;
            IIf(::lComments, " /* Open Workarea */", ""), .F.)
      ENDIF
      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         RETURN NIL
      ENDIF
   ENDIF

   IF (::nRetCode := FBNumResultCols4(::hEnv, @nFields)) != SQL_SUCCESS
      ::RunTimeErr("", "FBNumResultCols Error" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
      RETURN NIL
   ENDIF

   aFields := Array(nFields)
   ::nFields := nFields

   FOR n := 1 TO nFields

      nDec := 0

      IF (::nRetCode := FBDescribeCol4(::hEnv, n, @cName, @nType, @nLen, @nDec, @nNull)) != SQL_SUCCESS
         ::RunTimeErr("", "FBDescribeCol Error" + SR_CRLF + ::LastError() + SR_CRLF + ;
            "Last command sent to database : " + ::cLastComm)
         RETURN NIL
      ENDIF

      _nDec := nDec

      cName := Upper(AllTrim(cName))
      nPos := AScan(aLocalPrecision, {|x|RTrim(x[1]) == cName})
      cType := ::SQLType(nType, cName, nLen)
      nLenField := ::SQLLen(nType, nLen, @nDec)
      IF nPos > 0 .AND. aLocalPrecision[nPos, 2] > 0
         nLenField := aLocalPrecision[nPos, 2]
      ELSEIF nType == SQL_DOUBLE .OR. nType == SQL_FLOAT .OR. nType == SQL_NUMERIC
         nLenField := 19
      ENDIF

      IF cType == "U"
         ::RuntimeErr("", SR_Msg(21) + cName + " : " + Str(nType))
      ELSE
         aFields[n] := {cName, cType, nLenField, nDec, nNull >= 1, nType, , n, _nDec, ,}
      ENDIF

   NEXT n

   ::aFields := aFields

   IF lReSelect .AND. !lLoadCache
      ::FreeStatement()
   ENDIF

RETURN aFields

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:LastError()

   LOCAL cMsgError
   LOCAL nType := 0

   cMsgError := FBError4(::hEnv, @nType)

RETURN AllTrim(cMsgError) + " - Native error code " + AllTrim(Str(nType))

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, ;
   nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit)

   LOCAL nRet
   LOCAL hEnv
   LOCAL cSystemVers

   // parameters not used
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

   nRet := FBConnect4(::cDtb, ::cUser, ::cPassword, ::cCharSet, @hEnv)

   IF nRet != SQL_SUCCESS
      ::nRetCode := nRet
      SR_MsgLogFile("Connection Error: " + AllTrim(Str(nRet)) + " (check fb.log) - Database: " + ::cDtb + ;
         " - Username : " + ::cUser + " (Password not shown for security)")
      RETURN SELF
   ENDIF

   ::cConnect := cConnect
   cTargetDB := StrTran(FBVERSION4(hEnv), "(access method)", "")
   cSystemVers := SubStr(cTargetDB, At("Firebird ", cTargetDB) + 9, 3)
   //tracelog("cTargetDB", cTargetDB, "cSystemVers", cSystemVers)

   nRet := FBBeginTransaction4(hEnv)

   IF nRet != SQL_SUCCESS
      ::nRetCode := nRet
      SR_MsgLogFile("Transaction Start error : " + AllTrim(Str(nRet)))
      RETURN SELF
   ENDIF

   ::hEnv := hEnv
   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers

   ::DetectTargetDb()

RETURN SELF

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:End()

   ::Commit()
   FBClose4(::hEnv)

RETURN ::Super:End()

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:Commit()

   ::Super:Commit()
   ::nRetCode := FBCOMMITTRANSACTION4(::hEnv)

RETURN (::nRetCode := FBBeginTransaction4(::hEnv))

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:RollBack()

   ::super:RollBack()

RETURN (::nRetCode := FBRollBackTransaction4(::hEnv))

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:ExecuteRaw(cCommand)

   LOCAL nRet

   IF Upper(Left(LTrim(cCommand), 6)) == "SELECT" .OR. "RETURNING" $ Upper(AllTrim(cCommand))
      nRet := FBExecute4(::hEnv, cCommand, IB_DIALECT_CURRENT)
      ::lResultSet := .T.
   ELSE
      nRet := FBExecuteImmediate4(::hEnv, cCommand, IB_DIALECT_CURRENT)
      ::lResultSet := .F.
   ENDIF

RETURN nRet

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_FIREBIRD4:MoreResults(aArray, lTranslate)

   LOCAL nRet
   LOCAL n
   LOCAL nvalue := -1

   DEFAULT lTranslate TO .T.

   nRet := FB_MoreResults4(::hEnv, @nValue)

   IF nRet == SQL_SUCCESS

      DEFAULT aArray TO {}
      n := 1

      AAdd(aArray, Array(1))

      aArray[n, 1] := nvalue

   ENDIF

RETURN nRet

//-------------------------------------------------------------------------------------------------------------------//
