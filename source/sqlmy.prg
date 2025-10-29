// SQLRDD MySQL Native Connection Class
// Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
// Copyright (c) 2003 - Luiz Rafal Culik Guimarães <luiz@xharbour.com.br>

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

#include <hbclass.ch>
#include <common.ch>
#include "sqlodbc.ch"
#include "sqlrdd.ch"
#include "sqlrddpp.ch"
#include <error.ch>
#include "msg.ch"
#include "mysql.ch"
#include "sqlrddsetup.ch"

#define DEBUGSESSION              .F.
#define ARRAY_BLOCK               500
#define MINIMAL_MYSQL_SUPPORTED   40105

//-------------------------------------------------------------------------------------------------------------------//

CLASS SR_MYSQL FROM SR_CONNECTION

   DATA aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, ;
      nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout)
   METHOD End()
   METHOD LastError()
   METHOD Commit(lNoLog)
   METHOD RollBack()
   METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)
   METHOD ExecuteRaw(cCommand)
   METHOD FreeStatement()
   METHOD FetchRaw(lTranslate, aFields)
   METHOD FieldGet(nField, aFields, lTranslate)
   METHOD MoreResults(aArray, lTranslate)
   METHOD Getline(aFields, lTranslate, aArray)
   METHOD KillConnectionID(nID) INLINE MYSKILLCONNID(::hDbc, nID)
   METHOD GetAffectedRows()

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:MoreResults(aArray, lTranslate)

   HB_SYMBOL_UNUSED(aArray)
   HB_SYMBOL_UNUSED(lTranslate)

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:Getline(aFields, lTranslate, aArray)

   LOCAL i

   DEFAULT lTranslate TO .T.

   IF aArray == NIL
      aArray := Array(Len(aFields))
   ELSEIF Len(aArray) < Len(aFields)
      ASize(aArray, Len(aFields))
   ENDIF

   IF ::aCurrLine == NIL
      MYSLINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   ENDIF

   FOR i := 1 TO Len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:FieldGet(nField, aFields, lTranslate)

   IF ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := Array(Len(aFields))
      MYSLINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   ENDIF

RETURN ::aCurrLine[nField]

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:FetchRaw(lTranslate, aFields)

   ::nRetCode := SQL_ERROR

   DEFAULT aFields TO ::aFields
   DEFAULT lTranslate TO .T.

   IF ::hStmt != NIL
      ::nRetCode := MYSFetch(::hDbc)
      ::aCurrLine := NIL
   ELSE
      ::RunTimeErr("", "MySQLFetch - Invalid cursor state" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
   ENDIF

RETURN ::nRetCode

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:FreeStatement()

   IF ::hStmt != NIL
      MYSClear(::hDbc)
   ENDIF
   ::hStmt := NIL

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)

   LOCAL aFields
   LOCAL nRet
   LOCAL aFld

   DEFAULT lReSelect TO .T.
   DEFAULT lLoadCache TO .F.
   DEFAULT cWhere TO ""
   DEFAULT cRecnoName TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   IF lReSelect
      IF !Empty(cCommand)
         nRet := ::Execute(cCommand + IIf(::lComments, " /* Open Workarea with custom SQL command */", ""), .F.)
      ELSE
         nRet := ::Execute("SELECT A.* FROM " + cTable + " A " + ;
            IIf(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + ;
            IIf(::lComments, " /* Open Workarea */", ""), .F.)
      ENDIF
      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         RETURN NIL
      ENDIF
   ENDIF

   IF MYSResultStatus(::hDbc) != SQL_SUCCESS
      ::RunTimeErr("", "SqlNumResultCols Error" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
      RETURN NIL
   ENDIF

   ::nFields := MYSCols(::hDbc)

   // IF (!Empty(cTable)) .AND. Empty(cCommand)
   //    cTbl := cTable
   //    aFields := MYSTableAttr(::hDbc, cTbl)
   // ELSE
   aFields := MYSQueryAttr(::hDbc)
   // ENDIF

   ::aFields := aFields

   FOR EACH aFld IN ::aFields
      aFld[FIELD_ENUM] := aFld:__enumIndex()
   NEXT

   IF lReSelect .AND. !lLoadCache
      ::FreeStatement()
   ENDIF

RETURN aFields

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:LastError()

   IF ::hStmt != NIL
      RETURN "(" + AllTrim(Str(::nRetCode)) + ") " + MYSResStatus(::hDbc) + " - " + MYSErrMsg(::hDbc)
   ENDIF

RETURN "(" + AllTrim(Str(::nRetCode)) + ") " + MYSErrMsg(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, ;
   nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout)

   LOCAL hDbc
   LOCAL nret
   LOCAL cSystemVers
   LOCAL nVersionp

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

   hDbc := MYSConnect(::cHost, ::cUser, ::cPassWord, ::cDtb, ::cPort, ::cDtb, nTimeout, ::lCompress)
   nRet := MYSStatus(hDbc)

   IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode := nRet
      ::nSystemID := 0
      SR_MsgLogFile("Connection Error")
      RETURN SELF
   ENDIF

   ::cConnect := cConnect
   ::hStmt := NIL
   ::hDbc := hDbc
   cTargetDB := "MySql Native"
   cSystemVers := AllTrim(Str(MYSVERS(hDbc)))
   nVersionp := MYSVERS(hDbc)

   IF !::lQueryOnly .AND. nVersionp < MINIMAL_MYSQL_SUPPORTED
      SR_MsgLogFile("Connection Error: MySQL version not supported : " + cSystemVers + " / minimun is " + ;
         Str(MINIMAL_MYSQL_SUPPORTED))
      ::End()
      ::nSystemID := 0
      ::nRetCode := -1
      RETURN SELF
   ENDIF

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID := SQLRDD_RDBMS_MYSQL
   ::cTargetDB := Upper(cTargetDB)
   ::uSid := MYSGETCONNID(hDbc)

RETURN SELF

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:End()

   ::Commit(.T.)
   ::FreeStatement()

   IF !Empty(::hDbc)
      MYSFinish(::hDbc)
   ENDIF

RETURN ::Super:End()

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:Commit(lNoLog)

   ::Super:Commit(lNoLog)

RETURN (::nRetCode := MYSCommit(::hDbc))

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:RollBack()

   ::Super:RollBack()

RETURN (::nRetCode := MYSRollBack(::hDbc))

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:ExecuteRaw(cCommand)

   IF Upper(Left(LTrim(cCommand), 6)) == "SELECT" .OR. Upper(Left(LTrim(cCommand), 5)) == "SHOW "
      ::lResultSet := .T.
   ELSE
      ::lResultSet := .F.
   ENDIF

   ::hStmt := MYSExec(::hDbc, cCommand)

RETURN MYSResultStatus(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_MYSQL:GetAffectedRows()
RETURN MYSAFFECTEDROWS(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//
