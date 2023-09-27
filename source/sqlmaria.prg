/*
 * SQLRDD MySQL Native Connection Class
 * Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
 * Copyright (c) 2003 - Luiz Rafal Culik Guimarães <luiz@xharbour.com.br>
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
#include "mysql.ch"
#include "sqlrddsetup.ch"

#define SR_CRLF   (chr(13) + chr(10))

#define  DEBUGSESSION                .F.
#define ARRAY_BLOCK                  500
#define MINIMAL_MYSQL_SUPPORTED  50100

/*------------------------------------------------------------------------*/

CLASS SR_MARIA FROM SR_CONNECTION

   DATA aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout)
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

/*------------------------------------------------------------------------*/

METHOD MoreResults(aArray, lTranslate) CLASS SR_MARIA

   LOCAL nRet

   HB_SYMBOL_UNUSED(aArray)
   HB_SYMBOL_UNUSED(lTranslate)

   nRet := -1

RETURN nRet

/*------------------------------------------------------------------------*/

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_MARIA

   LOCAL i

   DEFAULT lTranslate TO .T.

   If aArray == NIL
      aArray := Array(len(aFields))
   ElseIf len(aArray) < len(aFields)
      aSize(aArray, len(aFields))
   EndIf

   If ::aCurrLine == NIL
      MYSLINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   EndIf

   FOR i := 1 TO len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

/*------------------------------------------------------------------------*/

METHOD FieldGet(nField, aFields, lTranslate) CLASS SR_MARIA
   If ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := array(LEN(aFields))
      MYSLINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   EndIf

RETURN ::aCurrLine[nField]

/*------------------------------------------------------------------------*/

METHOD FetchRaw(lTranslate, aFields) CLASS SR_MARIA

   ::nRetCode := SQL_ERROR
   DEFAULT aFields    TO ::aFields
   DEFAULT lTranslate TO .T.

   If ::hStmt != NIL
      ::nRetCode := MYSFetch(::hDbc)
      ::aCurrLine := NIL
   Else
      ::RunTimeErr("", "MySQLFetch - Invalid cursor state" + SR_CRLF + SR_CRLF + "Last command sent to database : " + SR_CRLF + ::cLastComm)
   EndIf

RETURN ::nRetCode

/*------------------------------------------------------------------------*/

METHOD FreeStatement() CLASS SR_MARIA
   If ::hStmt != NIL
      MYSClear ( ::hDbc )
   EndIf
   ::hStmt := NIL
RETURN NIL

/*------------------------------------------------------------------------*/

METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName) CLASS SR_MARIA

   LOCAL nType := 0
   LOCAL nLen := 0
   LOCAL nNull := 0
   LOCAL aFields := {}
   LOCAL nDec := 0
   LOCAL nRet
   LOCAL cVlr := ""
   LOCAL aFld

   DEFAULT lReSelect    TO .T.
   DEFAULT lLoadCache   TO .F.
   DEFAULT cWhere       TO ""
   DEFAULT cRecnoName   TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   If lReSelect
      If !Empty(cCommand)
         nRet := ::Execute(cCommand + iif(::lComments, " /* Open Workarea with custom SQL command */", ""), .F.)
      Else
         nRet := ::Execute("SELECT A.* FROM " + cTable + " A " + iif(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + iif(::lComments, " /* Open Workarea */", ""), .F.)
      EndIf
      If nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         RETURN NIL
      EndIf
   EndIf

   If MYSResultStatus(::hDbc) != SQL_SUCCESS
      ::RunTimeErr("", "SqlNumResultCols Error" + SR_CRLF + SR_CRLF + ;
               "Last command sent to database : " + SR_CRLF + ::cLastComm)
      RETURN NIL
   endif

   ::nFields   := MYSCols(::hDbc)

//   If (!Empty(cTable)) .AND. empty(cCommand)
//      cTbl := cTable
//      aFields := MYSTableAttr(::hDbc, cTbl)
//   Else
      aFields := MYSQueryAttr(::hDbc)
//   EndIf

   ::aFields := aFields

   FOR EACH aFld IN ::aFields
      aFld[FIELD_ENUM] = hb_enumIndex()
   NEXT

   If lReSelect .AND. !lLoadCache
      ::FreeStatement()
   EndIf

RETURN aFields

/*------------------------------------------------------------------------*/

METHOD LastError() CLASS SR_MARIA

   If ::hStmt != NIL
      RETURN "(" + alltrim(str(::nRetCode)) + ") " + MYSResStatus(::hDbc) + " - " + MYSErrMsg(::hDbc)
   EndIf

RETURN "(" + alltrim(str(::nRetCode)) + ") " + MYSErrMsg(::hDbc)

/*------------------------------------------------------------------------*/

METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace,;
            cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit, nTimeout) CLASS SR_MARIA

   LOCAL hEnv := 0
   LOCAL hDbc := 0
   LOCAL nret
   LOCAL cVersion := ""
   LOCAL cSystemVers := ""
   LOCAL cBuff := ""
   LOCAL nVersionp

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

   if nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode = nRet
      ::nSystemID := 0
      SR_MsgLogFile("Connection Error")
      nVersionp := 4      
      RETURN Self
   else
      ::cConnect  = cConnect
      ::hStmt     = NIL
      ::hDbc      = hDbc
      cTargetDB   = "MARIADB Native"
      cSystemVers = alltrim(str(MYSVERS(hDbc)))
      nVersionp  := MYSVERS(hDbc)     
                              
   EndIf

   If (!::lQueryOnly) .AND. nVersionp < MINIMAL_MYSQL_SUPPORTED
      SR_MsgLogFile("Connection Error: MariaDB version not supported : " + cSystemVers + " / minimun is " + str(MINIMAL_MYSQL_SUPPORTED))
      ::End()
      ::nSystemID := 0
      ::nRetCode  := -1
      RETURN Self
   EndIf

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID   := SYSTEMID_MARIADB
   ::cTargetDB   := Upper(cTargetDB)
   ::uSid        := MYSGETCONNID(hDbc)
   ::lMariaDb    :=.T.

RETURN Self

/*------------------------------------------------------------------------*/

METHOD End() CLASS SR_MARIA

   ::Commit(.T.)
   ::FreeStatement()

   If !Empty(::hDbc)
      MYSFinish(::hDbc)
   EndIf

RETURN ::super:End()

/*------------------------------------------------------------------------*/

METHOD Commit(lNoLog) CLASS SR_MARIA
   ::super:Commit(lNoLog)
RETURN ( ::nRetCode := MYSCommit(::hDbc) )

/*------------------------------------------------------------------------*/

METHOD RollBack() CLASS SR_MARIA
   ::super:RollBack()
RETURN ( ::nRetCode := MYSRollBack(::hDbc) )

/*------------------------------------------------------------------------*/

METHOD ExecuteRaw(cCommand) CLASS SR_MARIA

   If upper(left(ltrim(cCommand), 6)) == "SELECT" .OR. upper(left(ltrim(cCommand), 5)) == "SHOW "
      ::lResultSet := .T.
   Else
      ::lResultSet := .F.
   EndIf

   ::hStmt := MYSExec(::hDbc, cCommand)
RETURN MYSResultStatus(::hDbc)

/*------------------------------------------------------------------------*/

METHOD GetAffectedRows() CLASS SR_MARIA
RETURN MYSAFFECTEDROWS(::hDbc)