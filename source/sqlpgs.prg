/* $CATEGORY$SQLRDD/Postgres$FILES$sql.lib$HIDE$
* SQLRDD Postgres Native Connection Class
* Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
* All Rights Reserved
*/

/*
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
#include "compat.ch"
#include "sqlodbc.ch"
#include "sqlrdd.ch"
#include "error.ch"
#include "msg.ch"
#include "pgs.ch"
#include "sqlrddsetup.ch"

/*------------------------------------------------------------------------*/

CLASS SR_PGS FROM SR_CONNECTION

   Data aCurrLine

   METHOD ConnectRaw( cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit )
   METHOD End()
   METHOD LastError()
   METHOD Commit()
   METHOD RollBack()
   METHOD IniFields( lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName )
   METHOD ExecuteRaw( cCommand )
   METHOD AllocStatement()
   METHOD FreeStatement()
   METHOD FetchRaw( lTranslate, aFields )
   METHOD FieldGet( nField, aFields, lTranslate )
   METHOD MoreResults( aArray, lTranslate )
   METHOD Getline( aFields, lTranslate, aArray )
   METHOD GetAffectedRows()

ENDCLASS

/*------------------------------------------------------------------------*/

METHOD MoreResults( aArray, lTranslate )  CLASS SR_PGS
   (aArray)
   (lTranslate)
Return -1

/*------------------------------------------------------------------------*/

METHOD Getline( aFields, lTranslate, aArray )  CLASS SR_PGS

   Local i

   DEFAULT lTranslate := .T.

   If aArray == NIL
      aArray := Array(len( aFields ))
   ElseIf len( aArray ) != len( aFields )
      aSize( aArray, len( aFields ) )
   EndIf

   If ::aCurrLine == NIL
      PGSLINEPROCESSED( ::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray )
      ::aCurrLine := aArray
      Return aArray
   EndIf

   For i = 1 to len( aArray )
      aArray[i] := ::aCurrLine[ i ]
   Next

Return aArray

/*------------------------------------------------------------------------*/

METHOD FieldGet( nField, aFields, lTranslate ) CLASS SR_PGS

   If ::aCurrLine == NIL
      DEFAULT lTranslate := .T.
      ::aCurrLine := array( LEN( aFields ) )
      PGSLINEPROCESSED( ::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine )
   EndIf

return ::aCurrLine[nField]

/*------------------------------------------------------------------------*/

METHOD FetchRaw( lTranslate, aFields ) CLASS SR_PGS

   ::nRetCode := SQL_ERROR
   DEFAULT aFields    := ::aFields
   DEFAULT lTranslate := .T.

   If ::hDBC != NIL
      ::nRetCode := PGSFetch( ::hDbc )
      ::aCurrLine := NIL
   Else
      ::RunTimeErr("", "PGSFetch - Invalid cursor state" + chr(13)+chr(10)+ chr(13)+chr(10)+"Last command sent to database : " + chr(13)+chr(10) + ::cLastComm )
   EndIf

Return ::nRetCode

/*------------------------------------------------------------------------*/

METHOD FreeStatement() CLASS SR_PGS
   If ::hStmt != NIL
      PGSClear ( ::hDbc )
   EndIf
   ::hStmt := NIL
Return NIL

/*------------------------------------------------------------------------*/

METHOD IniFields( lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName ) CLASS SR_PGS

   local nFields := 0
   local nType := 0, nLen := 0, nNull := 0
   local aFields := {}
   local nDec := 0, nRet, cVlr := "", cTbl, cOwner := "public"

   DEFAULT lReSelect    := .T.
   DEFAULT lLoadCache   := .F.
   DEFAULT cWhere       := ""
   DEFAULT cRecnoName   := SR_RecnoName()
   DEFAULT cDeletedName := SR_DeletedName()

   If lReSelect
      If !Empty( cCommand )
         nRet := ::Execute( cCommand + if(::lComments," /* Open Workarea with custom SQL command */",""), .F. )
      Else
         nRet := ::Execute( "SELECT A.* FROM " + cTable + " A " + if(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + if(::lComments," /* Open Workarea */",""), .F. )
      EndIf
      If nRet != SQL_SUCCESS .and. nRet != SQL_SUCCESS_WITH_INFO
         return nil
      EndIf
   EndIf

   If PGSResultStatus( ::hStmt ) != SQL_SUCCESS
      ::RunTimeErr("", "SqlNumResultCols Error" + chr(13)+chr(10)+ chr(13)+chr(10)+;
               "Last command sent to database : " + chr(13)+chr(10) + ::cLastComm )
      return nil
   endif

   nFields   := PGSCols( ::hStmt )
   ::nFields := nFields

   If (!Empty( cTable )) .and. empty( cCommand )
      cTbl := lower( cTable )
      If "." $ cTbl
         cOwner := SubStr( cTbl, 1, at(".",cTbl)-1 )
         cTbl   := SubStr( cTbl, at(".",cTbl)+1 )
      EndIf
      If left( cTbl, 1 ) == ["]     // "
         cTbl := SubStr( cTbl, 2, len(cTbl)-2 )
      EndIf
      aFields := PGSTableAttr( ::hDbc, cTbl, cOwner )
   Else
      aFields := PGSQueryAttr( ::hDbc )
   EndIf

   ::aFields := aFields

   If lReSelect .and. !lLoadCache
      ::FreeStatement()
   EndIf

return aFields

/*------------------------------------------------------------------------*/

METHOD LastError() CLASS SR_PGS

   If ::hStmt != NIL
      Return "(" + alltrim(str( ::nRetCode ) ) + ") " + PGSResStatus( ::hDbc ) + " - " + PGSErrMsg( ::hDbc )
   EndIf

Return "(" + alltrim(str( ::nRetCode ) ) + ") " + PGSErrMsg( ::hDbc )

/*------------------------------------------------------------------------*/

METHOD ConnectRaw( cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace,;
            cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit ) CLASS SR_PGS

   local hEnv := 0, hDbc := 0
   local nret, cVersion := "", cSystemVers := "", cBuff := ""
   Local aRet := {}
   Local aVersion
   Local cmatch,nstart,nlen,s_reEnvVar := HB_RegexComp( "(\d+\.\d+\.\d+)" )
   Local cString
   
   
   (cDSN)
   (cUser)
   (cPassword)
   (nVersion)
   (cOwner)
   (nSizeMaxBuff)
   (lTrace)
   (nPrefetch)
   (nSelMeth)
   (nEmptyMode)
   (nDateMode)
   (lCounter)
   (lAutoCommit)

   DEFAULT ::cPort := 5432

   cConnect := "host=" + ::cHost + " user=" + ::cUser + " password=" + ::cPassword + " dbname=" + ::cDTB + " port=" + str(::cPort,6)
   
   IF !Empty( ::sslcert )
      cConnect += " sslmode=prefer sslcert="+::sslcert +" sslkey="+::sslkey +" sslrootcert="+ ::sslrootcert +" sslcrl="+ ::sslcrl
   ENDIF   
   
   hDbc := PGSConnect( cConnect )
   nRet := PGSStatus( hDbc )

   if nRet != SQL_SUCCESS .and. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode = nRet
      SR_MsgLogFile( "Connection Error: " + alltrim(str(PGSStatus2( hDbc ))) + " (see pgs.ch)" )
      Return Self
   else
      ::cConnect = cConnect
      ::hStmt    = NIL
      ::hDbc     = hDbc
      cTargetDB  = "PostgreSQL Native"
      ::exec( "select version()", .t., .t., @aRet )
      If len (aRet) > 0
         cSystemVers := aRet[1,1]
         cString := aRet[1,1]          
         cMatch := HB_AtX( s_reEnvVar, cString, , @nStart, @nLen )         
         if !empty(cMatch )
            aVersion      := hb_atokens( cMatch, "." )
         else
            aVersion      := hb_atokens( strtran(Upper(aRet[1,1]),"POSTGRESQL ",""), "." )
         endif
      Else
         cSystemVers= "??"
         aVersion      := {"6","0"}
      EndIf
   EndIf

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID   := SYSTEMID_POSTGR
   ::cTargetDB   := Upper( cTargetDB )
   

*    If ! ("7.3" $ cSystemVers .or. "7.4" $ cSystemVers .or. "8.0" $ cSystemVers .or. "8.1" $ cSystemVers .or. "8.2" $ cSystemVers .or. "8.3" $ cSystemVers .or. "8.4" $ cSystemVers .or. "9.0" $ cSystemVers or. "9.1" $ cSystemVers)

     if !(( Val( aversion[ 1 ] ) == 7 .and. Val( aversion[ 2 ] ) >= 3) .or. ( Val( aversion[ 1 ] ) >= 8 ))
      ::End()
      ::nRetCode  := SQL_ERROR
      ::nSystemID := NIL
      SR_MsgLogFile( "Unsupported Postgres version: " + cSystemVers )
   else
      ::lPostgresql8 := (( Val( aversion[ 1 ] ) == 8 .and. Val( aversion[ 2 ] ) >= 3) .or. ( Val( aversion[ 1 ] ) >= 9 ))
      ::lPostgresql83 := ( Val( aversion[ 1 ] ) == 8 .and. Val( aversion[ 2 ] ) == 3) 
   EndIf
   
   
   
   ::exec( "select pg_backend_pid()", .T., .T., @aRet )

   If len( aRet ) > 0
      ::uSid := val(str(aRet[1,1],8,0))
   EndIf

return Self

/*------------------------------------------------------------------------*/

METHOD End() CLASS SR_PGS

   ::Commit( .T. )

   ::FreeStatement()

   If !Empty( ::hDbc )
      PGSFinish( ::hDbc )
   EndIf

   ::hEnv  = 0
   ::hDbc  = NIL

return nil

/*------------------------------------------------------------------------*/

METHOD Commit( lNoLog ) CLASS SR_PGS
   ::Super:Commit( lNoLog )
Return ( ::nRetCode := ::exec( "COMMIT;BEGIN",.f. ) )

/*------------------------------------------------------------------------*/

METHOD RollBack() CLASS SR_PGS
   ::Super:RollBack()
   ::nRetCode := PGSRollBack( ::hDbc )
   ::exec( "BEGIN",.f. )
Return ::nRetCode

/*------------------------------------------------------------------------*/

METHOD ExecuteRaw( cCommand ) CLASS SR_PGS

   If upper(left(ltrim(cCommand), 6)) == "SELECT"
      ::lResultSet := .T.
   Else
      ::lResultSet := .F.
   EndIf

   ::hStmt := PGSExec( ::hDbc, cCommand )
Return PGSResultStatus( ::hStmt )

/*------------------------------------------------------------------------*/

METHOD AllocStatement() CLASS SR_PGS

   If ::lSetNext
      If ::nSetOpt == SQL_ATTR_QUERY_TIMEOUT
/*
         Commented 2005/02/04 - It's better to wait forever on a lock than have a corruct transaction
         PGSExec( ::hDbc, "set statement_timeout=" + str(::nSetValue*1000) )
*/
      EndIf
      ::lSetNext  := .F.
   EndIf

return SQL_SUCCESS

METHOD GetAffectedRows()
return PGSAFFECTEDROWS( ::hDbc )

/*------------------------------------------------------------------------*/



