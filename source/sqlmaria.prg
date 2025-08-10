//
// SQLRDD MySQL Native Connection Class
// Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
// Copyright (c) 2003 - Luiz Rafal Culik Guimarães <luiz@xharbour.com.br>
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

#include <hbclass.ch>
#include <common.ch>
// #include "compat.ch"
#include "sqlodbc.ch"
#include "sqlrdd.ch"
#include <error.ch>
#include "msg.ch"
#include "mysql.ch"
#include "sqlrddsetup.ch"

#define SR_CRLF                   (Chr(13) + Chr(10))
#define DEBUGSESSION              .F.
#define ARRAY_BLOCK               500
#define MINIMAL_MYSQL_SUPPORTED   50100

//-------------------------------------------------------------------------------------------------------------------//

CLASS SR_MARIA FROM SR_CONNECTION

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

METHOD MoreResults(aArray, lTranslate) CLASS SR_MARIA

   HB_SYMBOL_UNUSED(aArray)
   HB_SYMBOL_UNUSED(lTranslate)

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_MARIA

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

METHOD FieldGet(nField, aFields, lTranslate) CLASS SR_MARIA

   IF ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := Array(Len(aFields))
      MYSLINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   ENDIF

RETURN ::aCurrLine[nField]

//-------------------------------------------------------------------------------------------------------------------//

METHOD FetchRaw(lTranslate, aFields) CLASS SR_MARIA

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

METHOD FreeStatement() CLASS SR_MARIA

   IF ::hStmt != NIL
      MYSClear(::hDbc)
   ENDIF
   ::hStmt := NIL

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName) CLASS SR_MARIA

   //LOCAL nType := 0 (variable not used)
   //LOCAL nLen := 0 (variable not used)
   //LOCAL nNull := 0 (variable not used)
   LOCAL aFields //:= {} (value not used)
   //LOCAL nDec := 0 (variable not used)
   LOCAL nRet
   //LOCAL cVlr := "" (variable not used)
   LOCAL aFld

   //HB_SYMBOL_UNUSED(nType)
   //HB_SYMBOL_UNUSED(nLen)
   //HB_SYMBOL_UNUSED(nNull)
   //HB_SYMBOL_UNUSED(aFields)
   //HB_SYMBOL_UNUSED(nDec)
   //HB_SYMBOL_UNUSED(cVlr)

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

METHOD LastError() CLASS SR_MARIA

   IF ::hStmt != NIL
      RETURN "(" + AllTrim(Str(::nRetCode)) + ") " + MYSResStatus(::hDbc) + " - " + MYSErrMsg(::hDbc)
   ENDIF

RETURN "(" + AllTrim(Str(::nRetCode)) + ") " + MYSErrMsg(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//

METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, ;
   nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout) CLASS SR_MARIA

   //LOCAL hEnv := 0 (variable not used)
   LOCAL hDbc //:= 0 (value not used)
   LOCAL nret
   //LOCAL cVersion := "" (variable not used)
   LOCAL cSystemVers //:= "" (value not used)
   //LOCAL cBuff := "" (variable not used)
   LOCAL nVersionp

   //HB_SYMBOL_UNUSED(hEnv)
   //HB_SYMBOL_UNUSED(hDbc)
   //HB_SYMBOL_UNUSED(cVersion)
   //HB_SYMBOL_UNUSED(cSystemVers)
   //HB_SYMBOL_UNUSED(cBuff)

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
      //nVersionp := 4 (value not used)
      RETURN Self
   ENDIF

   ::cConnect := cConnect
   ::hStmt := NIL
   ::hDbc := hDbc
   cTargetDB := "MARIADB Native"
   cSystemVers := AllTrim(Str(MYSVERS(hDbc)))
   nVersionp := MYSVERS(hDbc)

   IF (!::lQueryOnly) .AND. nVersionp < MINIMAL_MYSQL_SUPPORTED
      SR_MsgLogFile("Connection Error: MariaDB version not supported : " + cSystemVers + " / minimun is " + ;
         Str(MINIMAL_MYSQL_SUPPORTED))
      ::End()
      ::nSystemID := 0
      ::nRetCode := -1
      RETURN Self
   ENDIF

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID := SYSTEMID_MARIADB
   ::cTargetDB := Upper(cTargetDB)
   ::uSid := MYSGETCONNID(hDbc)
   ::lMariaDb := .T.

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD End() CLASS SR_MARIA

   ::Commit(.T.)
   ::FreeStatement()

   IF !Empty(::hDbc)
      MYSFinish(::hDbc)
   ENDIF

RETURN ::super:End()

//-------------------------------------------------------------------------------------------------------------------//

METHOD Commit(lNoLog) CLASS SR_MARIA

   ::super:Commit(lNoLog)

RETURN (::nRetCode := MYSCommit(::hDbc))

//-------------------------------------------------------------------------------------------------------------------//

METHOD RollBack() CLASS SR_MARIA

   ::super:RollBack()

RETURN (::nRetCode := MYSRollBack(::hDbc))

//-------------------------------------------------------------------------------------------------------------------//

METHOD ExecuteRaw(cCommand) CLASS SR_MARIA

   IF Upper(Left(LTrim(cCommand), 6)) == "SELECT" .OR. Upper(Left(LTrim(cCommand), 5)) == "SHOW "
      ::lResultSet := .T.
   ELSE
      ::lResultSet := .F.
   ENDIF

   ::hStmt := MYSExec(::hDbc, cCommand)

RETURN MYSResultStatus(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//

METHOD GetAffectedRows() CLASS SR_MARIA
RETURN MYSAFFECTEDROWS(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//
