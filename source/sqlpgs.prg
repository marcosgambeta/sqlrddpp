//
// SQLRDD Postgres Native Connection Class
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

#include <hbclass.ch>
#include <common.ch>
// #include "compat.ch"
#include "sqlodbc.ch"
#include "sqlrdd.ch"
#include <error.ch>
#include "msg.ch"
#include "pgs.ch"
#include "sqlrddsetup.ch"

#define SR_CRLF   (Chr(13) + Chr(10))

//-------------------------------------------------------------------------------------------------------------------//

CLASS SR_PGS FROM SR_CONNECTION

   Data aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, ;
      nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit)
   METHOD End()
   METHOD LastError()
   METHOD Commit(lNoLog)
   METHOD RollBack()
   METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)
   METHOD ExecuteRaw(cCommand)
   METHOD AllocStatement()
   METHOD FreeStatement()
   METHOD FetchRaw(lTranslate, aFields)
   METHOD FieldGet(nField, aFields, lTranslate)
   METHOD MoreResults(aArray, lTranslate)
   METHOD Getline(aFields, lTranslate, aArray)
   METHOD GetAffectedRows()

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:MoreResults(aArray, lTranslate)

   HB_SYMBOL_UNUSED(aArray)
   HB_SYMBOL_UNUSED(lTranslate)

RETURN -1

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:Getline(aFields, lTranslate, aArray)

   LOCAL i

   DEFAULT lTranslate TO .T.

   IF aArray == NIL
      aArray := Array(Len(aFields))
   ELSEIF Len(aArray) != Len(aFields)
      ASize(aArray, Len(aFields))
   ENDIF

   IF ::aCurrLine == NIL
      PGSLINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   ENDIF

   FOR i := 1 TO Len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:FieldGet(nField, aFields, lTranslate)

   IF ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := Array(Len(aFields))
      PGSLINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   ENDIF

RETURN ::aCurrLine[nField]

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:FetchRaw(lTranslate, aFields)

   ::nRetCode := SQL_ERROR
   DEFAULT aFields TO ::aFields
   DEFAULT lTranslate TO .T.

   IF ::hDBC != NIL
      ::nRetCode := PGSFetch(::hDbc)
      ::aCurrLine := NIL
   ELSE
      ::RunTimeErr("", "PGSFetch - Invalid cursor state" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
   ENDIF

RETURN ::nRetCode

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:FreeStatement()

   IF ::hStmt != NIL
      PGSClear(::hDbc)
   ENDIF
   ::hStmt := NIL

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)

   LOCAL nFields //:= 0 (value not used)
   //LOCAL nType := 0 (variable not used)
   //LOCAL nLen := 0 (variable not used)
   //LOCAL nNull := 0 (variable not used)
   LOCAL aFields //:= {} (value not used)
   //LOCAL nDec := 0 (variable not used)
   LOCAL nRet
   //LOCAL cVlr := "" (variable not used)
   LOCAL cTbl
   LOCAL cOwner := "public"

   //HB_SYMBOL_UNUSED(nFields)
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

   IF PGSResultStatus(::hStmt) != SQL_SUCCESS
      ::RunTimeErr("", "SqlNumResultCols Error" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
      RETURN NIL
   ENDIF

   nFields := PGSCols(::hStmt)
   ::nFields := nFields

   IF !Empty(cTable) .AND. Empty(cCommand)
      cTbl := Lower(cTable)
      IF "." $ cTbl
         cOwner := SubStr(cTbl, 1, At(".", cTbl) - 1)
         cTbl := SubStr(cTbl, At(".", cTbl) + 1)
      ENDIF
      IF Left(cTbl, 1) == Chr(34) // "
         cTbl := SubStr(cTbl, 2, Len(cTbl) - 2)
      ENDIF
      aFields := PGSTableAttr(::hDbc, cTbl, cOwner)
   ELSE
      aFields := PGSQueryAttr(::hDbc)
   ENDIF

   ::aFields := aFields

   IF lReSelect .AND. !lLoadCache
      ::FreeStatement()
   ENDIF

RETURN aFields

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:LastError()

   IF ::hStmt != NIL
      RETURN "(" + AllTrim(Str(::nRetCode)) + ") " + PGSResStatus(::hDbc) + " - " + PGSErrMsg(::hDbc)
   ENDIF

RETURN "(" + AllTrim(Str(::nRetCode)) + ") " + PGSErrMsg(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, ;
   nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit)

   //LOCAL hEnv := 0 (variable not used)
   LOCAL hDbc //:= 0 (value not used)
   LOCAL nret
   //LOCAL cVersion := "" (variable not used)
   LOCAL cSystemVers //:= "" (value not used)
   //LOCAL cBuff := "" (variable not used)
   LOCAL aRet := {}
   LOCAL aVersion
   LOCAL cmatch
   LOCAL nstart
   LOCAL nlen
   LOCAL s_reEnvVar := HB_RegexComp("(\d+\.\d+\.\d+)")
   LOCAL cString

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

   DEFAULT ::cPort TO 5432

   cConnect := "host=" + ::cHost + " user=" + ::cUser + " password=" + ::cPassword + " dbname=" + ::cDTB + ;
      " port=" + Str(::cPort, 6)

   IF !Empty(::sslcert)
      cConnect += " sslmode=prefer sslcert=" + ::sslcert + " sslkey=" + ::sslkey + " sslrootcert=" + ::sslrootcert + ;
         " sslcrl=" + ::sslcrl
   ENDIF

   hDbc := PGSConnect(cConnect)
   nRet := PGSStatus(hDbc)

   IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode := nRet
      SR_MsgLogFile("Connection Error: " + AllTrim(Str(PGSStatus2(hDbc))) + " (see pgs.ch)")
      RETURN Self
   ENDIF

   ::cConnect := cConnect
   ::hStmt := NIL
   ::hDbc := hDbc
   cTargetDB := "PostgreSQL Native"
   ::Exec("select version()", .T., .T., @aRet)
   IF Len(aRet) > 0
      cSystemVers := aRet[1, 1]
      cString := aRet[1, 1]
      cMatch := HB_AtX(s_reEnvVar, cString, , @nStart, @nLen)
      IF !Empty(cMatch)
         aVersion := hb_atokens(cMatch, ".")
      ELSE
         aVersion := hb_atokens(StrTran(Upper(aRet[1, 1]), "POSTGRESQL ", ""), ".")
      ENDIF
   ELSE
      cSystemVers := "??"
      aVersion := {"6", "0"}
   ENDIF

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID := SYSTEMID_POSTGR
   ::cTargetDB := Upper(cTargetDB)

   // IF !("7.3" $ cSystemVers .OR. "7.4" $ cSystemVers .OR. "8.0" $ cSystemVers .OR. "8.1" $ cSystemVers .OR. ;
   //    "8.2" $ cSystemVers .OR. "8.3" $ cSystemVers .OR. "8.4" $ cSystemVers .OR. "9.0" $ cSystemVers .OR. ;
   //    "9.1" $ cSystemVers)

   IF !((Val(aversion[1]) == 7 .AND. Val(aversion[2]) >= 3) .OR. (Val(aversion[1]) >= 8))
      ::End()
      ::nRetCode := SQL_ERROR
      ::nSystemID := NIL
      SR_MsgLogFile("Unsupported Postgres version: " + cSystemVers)
   ELSE
      ::lPostgresql8 := ((Val(aversion[1]) == 8 .AND. Val(aversion[2]) >= 3) .OR. (Val(aversion[1]) >= 9))
      ::lPostgresql83 := (Val(aversion[1]) == 8 .AND. Val(aversion[2]) == 3)
   ENDIF

   ::Exec("select pg_backend_pid()", .T., .T., @aRet)

   IF Len(aRet) > 0
      ::uSid := Val(Str(aRet[1, 1], 8, 0))
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:End()

   ::Commit(.T.)

   ::FreeStatement()

   IF !Empty(::hDbc)
      PGSFinish(::hDbc)
   ENDIF

   ::hEnv := 0
   ::hDbc := NIL

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:Commit(lNoLog)

   ::Super:Commit(lNoLog)

RETURN (::nRetCode := ::Exec("COMMIT;BEGIN", .F.))

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:RollBack()

   ::Super:RollBack()
   ::nRetCode := PGSRollBack(::hDbc)
   ::Exec("BEGIN", .F.)

RETURN ::nRetCode

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:ExecuteRaw(cCommand)

   IF Upper(Left(LTrim(cCommand), 6)) == "SELECT"
      ::lResultSet := .T.
   ELSE
      ::lResultSet := .F.
   ENDIF

   ::hStmt := PGSExec(::hDbc, cCommand)

RETURN PGSResultStatus(::hStmt)

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:AllocStatement()

   IF ::lSetNext
      IF ::nSetOpt == SQL_ATTR_QUERY_TIMEOUT
         // Commented 2005/02/04 - It's better to wait forever on a lock than have a corruct transaction
         // PGSExec(::hDbc, "set statement_timeout=" + Str(::nSetValue * 1000))
      ENDIF
      ::lSetNext := .F.
   ENDIF

RETURN SQL_SUCCESS

//-------------------------------------------------------------------------------------------------------------------//

METHOD SR_PGS:GetAffectedRows()
RETURN PGSAFFECTEDROWS(::hDbc)

//-------------------------------------------------------------------------------------------------------------------//
