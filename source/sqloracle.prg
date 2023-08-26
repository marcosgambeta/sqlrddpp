/* $CATEGORY$SQLRDD/Oracle$FILES$sql.lib$HIDE$
* SQLRDD Oracle Native Connection Class
* Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
* Copyright (c) 2003 - Luiz Rafal Culik Guimarães <luiz@xharbour.com.br>
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
#include "sqlora.ch"
#include "sqlrdd.ch"
#include "error.ch"
#include "msg.ch"
#include "sqlrddsetup.ch"

#define DEBUGSESSION     .F.
#define ARRAY_BLOCK      500

/*------------------------------------------------------------------------*/

CLASS SR_ORACLE FROM SR_CONNECTION

   DATA hdbc
   DATA nParamStart  INIT 0

   Data Is_logged_on,is_Attached
   Data aBinds
   Data aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit) CONSTRUCTOR
   METHOD End()
   METHOD LastError()
   METHOD Commit()
   METHOD RollBack()
   METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName)
   METHOD ExecuteRaw(cCommand)
   METHOD AllocStatement()
   METHOD FreeStatement()
   METHOD FetchRaw(lTranslate, aFields)
   METHOD FieldGet(nField, aField, lTranslate)
   METHOD MoreResults(aArray, lTranslate)
   METHOD BINDPARAM(lStart,lIn,cRet,nLen)
   METHOD ConvertParams(c)
   METHOD WriteMemo(cFileName, nRecno, cRecnoName, aColumnsAndData)
   METHOD Getline(aFields, lTranslate, aArray)
   METHOD ExecSPRC(cComm, lMsg, lFetch, aArray, cFile, cAlias, cVar, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode)
   METHOD ExecSP(cComm, aReturn, nParam)
   METHOD GetAffectedRows()   
   
ENDCLASS

/*------------------------------------------------------------------------*/

METHOD MoreResults(aArray, lTranslate) CLASS SR_ORACLE
   (aArray)
   (lTranslate)
Return -1

/*------------------------------------------------------------------------*/

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_ORACLE

   Local i

   DEFAULT lTranslate TO .T.

   If aArray == NIL
      aArray := Array(len(aFields))
   ElseIf len(aArray) < len(aFields)
      aSize(aArray, len(aFields))
   EndIf

   If ::aCurrLine == NIL
      SQLO_LINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      Return aArray
   EndIf

   For i = 1 to len(aArray)
      aArray[i] := ::aCurrLine[i]
   Next

Return aArray

/*------------------------------------------------------------------------*/

METHOD FieldGet(nField, aFields, lTranslate) CLASS SR_ORACLE

   If ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := array(LEN(aFields))
      SQLO_LINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   EndIf

return ::aCurrLine[nField]

/*------------------------------------------------------------------------*/

METHOD FetchRaw(lTranslate, aFields) CLASS SR_ORACLE

   ::nRetCode := SQL_ERROR
   DEFAULT aFields    TO ::aFields
   DEFAULT lTranslate TO .T.

   If ::hDBC != NIL
      ::nRetCode := SQLO_FETCH(::hDBC)
      ::aCurrLine := NIL
   Else
      ::RunTimeErr("", "SQLO_FETCH - Invalid cursor state" + chr(13)+chr(10)+ chr(13)+chr(10)+"Last command sent to database : " + chr(13)+chr(10) + ::cLastComm )
   EndIf

Return ::nRetCode

/*------------------------------------------------------------------------*/

METHOD FreeStatement() CLASS SR_ORACLE

   if ::hDBC != NIL .AND. ::hstmt != NIL
      if SQLO_CLOSESTMT(::hDBC) != SQL_SUCCESS
         ::RunTimeErr("", "SQLO_CLOSESTMT error" + chr(13)+chr(10)+ chr(13)+chr(10)+"Last command sent to database : " + chr(13)+chr(10) + ::cLastComm )
      endif
      ::hstmt := NIL
   endif

Return NIL

/*------------------------------------------------------------------------*/

METHOD AllocStatement() CLASS SR_ORACLE

   local hStmtLocal := 0, nRet := 0

   ::FreeStatement()

   If ::lSetNext
      ::lSetNext  := .F.
      nRet := ::SetStmtOptions(::nSetOpt, ::nSetValue)
      If nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         SR_MsgLogFile(SR_Msg(23) + " (" + alltrim(str(nRet)) + ") : " + ::LastError())
      EndIf
   EndIf

Return nRet

/*------------------------------------------------------------------------*/

METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName) CLASS SR_ORACLE

   Local n
   Local nType := 0, nLen := 0, nNull := 0, nDec := 0, cName
   Local _nLen, _nDec
   Local cType, nLenField
   Local aFields := {}
   Local nRet, cVlr := ""

   DEFAULT lReSelect    TO .T.
   DEFAULT lLoadCache   TO .F.
   DEFAULT cWhere       TO ""
   DEFAULT cRecnoName   TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   If lReSelect
      If !Empty(cCommand)
         nRet := ::Execute(cCommand + iif(::lComments," /* Open Workarea with custom SQL command */",""), .F.)
      Else
         nRet := ::Execute("SELECT A.* FROM " + cTable + " A " + iif(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + iif(::lComments," /* Open Workarea */",""), .F.)
      EndIf

      If nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         return NIL
      EndIf
   EndIf

   ::nFields := SQLO_NUMCOLS(::hDBC)

   If ::nFields < 0
         ::RunTimeErr("", "SQLO_NUMCOLS Error" + chr(13)+chr(10)+ str(::nFields) + chr(13)+chr(10)+;
                          "Last command sent to database : " + ::cLastComm )

      Return NIL
   EndIf

   aFields   := Array(::nFields)

   For n = 1 to ::nFields

      if ( ::nRetCode := SQLO_DESCRIBECOL(::hDBC, n, @cName, @nType, @nLen, @nDec, @nNull) ) != SQL_SUCCESS
         ::RunTimeErr("", "SQLDescribeCol Error" + chr(13)+chr(10)+ ::LastError() + chr(13)+chr(10)+;
                          "Last command sent to database : " + ::cLastComm )
        return NIL
      else

         _nLen := nLen
         _nDec := nDec
         cName := Upper(alltrim(cName))

         If (nLen == 2000 .OR. nLen == 4000) .AND. SR_SetNwgCompat()
            nType := SQL_FAKE_LOB
         EndIf

         nLenField := ::SQLLen(nType, nLen, @nDec)
         cType     := ::SQLType(nType, cName, nLen)

         If (!::lQueryOnly) .AND. cType == "N" .AND. nLenField == 38 .AND. nDec == 0
            cType     := "L"
            nLenField := 1
            nType     := SQL_BIT
         EndIf

         If cType == "U"
            ::RuntimeErr("", SR_Msg(21) + cName + " : " + str(nType))
         Else
            aFields[n] := { cName, cType, nLenField, nDec, nNull, nType, , n, , , }
         EndIf

      endif
   next

   ::aFields := aFields

   If lReSelect .AND. !lLoadCache
      ::FreeStatement()
   EndIf

return aFields

/*------------------------------------------------------------------------*/

METHOD LastError() CLASS SR_ORACLE

return SQLO_GETERRORDESCR(::hDBC) + " retcode: " + sr_val2Char(::nRetCode) + " - " + AllTrim(str(SQLO_GETERRORCODE(::hDBC)))

/*------------------------------------------------------------------------*/

METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace,;
            cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit) CLASS SR_ORACLE

   local hEnv := 0, hDbc := 0
   local nret, cVersion := "", cSystemVers := "", cBuff := ""
   Local aRet := {}

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

   
   ::hStmt := NIL
   nret    :=  SQLO_CONNECT(::cUser + "/" + ::cPassWord + "@" + ::cDtb, @hDbc)
   if nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode = nRet
      ::hDbc     := hDbc
      SR_MsgLogFile("Connection Error: " + ::lastError() + " - Connection string: " + ::cUser + "/" + Replicate("*", len(::cPassWord) ) + "@" + ::cDtb)
      Return Self
   else
      ::cConnect  := cConnect
      ::hDbc      := hDbc
      cTargetDB   := "Oracle"
      cSystemVers := SQLO_DBMSNAME(hDbc)
   EndIf

   ::cSystemName  := cTargetDB
   ::cSystemVers  := cSystemVers
   ::nSystemID    := SYSTEMID_ORACLE
   ::cTargetDB    := Upper(cTargetDB)

   ::exec("select sid from " + IIf(::lCluster, "g", "" ) + "v$session where AUDSID = sys_context('USERENV','sessionid')", .T., .T., @aRet)

   If len(aRet) > 0
      ::uSid := val(str(aRet[1,1],8,0))
   EndIf

Return Self

/*------------------------------------------------------------------------*/

METHOD End() CLASS SR_ORACLE

   Local nRet

   IF !Empty(::hDbc)
     IF  ( nRet := SQLO_DISCONNECT(::hDbc)) != SQL_SUCCESS
        SR_MsgLogFile("Error disconnecting : " + str(nRet) + CRLF + ::LastError())
     EndIf
   ENDIF

   ::hEnv  = 0
   ::hDbc  = NIL

return NIL

/*------------------------------------------------------------------------*/

METHOD Commit(lNoLog) CLASS SR_ORACLE
   ::Super:Commit(lNoLog)
RETURN (::nRetcode := SQLO_COMMIT(::hdbc) )

/*------------------------------------------------------------------------*/

METHOD RollBack() CLASS SR_ORACLE
   ::Super:RollBack()
Return ( ::nRetCode := SQLO_ROLLBACK(::hDbc) )

/*------------------------------------------------------------------------*/

METHOD ExecuteRaw(cCommand) CLASS SR_ORACLE
   local nRet

   If upper(left(ltrim(cCommand), 6)) == "SELECT"
      ::hStmt := ::hDBC
      nRet := SQLO_EXECUTE(::hDBC, cCommand)
      ::lResultSet := .T.
   Else
      ::hStmt := NIL
      nRet := SQLO_EXECDIRECT(::hDBC, cCommand)
      ::lResultSet := .F.
   EndIf

Return nRet

/*------------------------------------------------------------------------*/

Static Function ProcessParams(cSql, nBound)
   Local nPos
   Local cTemp := SubStr(cSql, 1, AT("?" , cSql) - 1)
   Local lHasParen := Rat(")", cSql) > 0
   Local lHasPointComma := Rat(";", cSql) > 0
   Local aItens
   Local cOriginal := cTemp +" "
   Local xParam
   Local nParamBound := 0

   cSql := StrTran(cSql,cTemp,"")
   aItens := hb_aTokens("?",",")

   FOR EACH xParam IN aItens
      nPos := hB_enumIndex()
      cOriginal += alltrim(":P"+StrZero(nPos,3)) +" "
      nParamBound ++
   NEXT

  IF lhasParen
     cOriginal += ")"
  ENDIF

  IF lHasPointComma
     cOriginal += ";"
  ENDIF

  nBound := nParamBound

RETURN cOriginal

/*------------------------------------------------------------------------*/

METHOD BINDPARAM(lStart, lIn, nLen, cRet, nLenRet) CLASS SR_ORACLE
   DEFAULT lIn to .F.
   DEFAULT lStart to .F.
   
   (nLen)
   (cRet)
   (nLenRet)
   
   IF lStart
      ::AllocStatement()
      ::nParamStart  := 1
   ELSE
      ::nParamStart ++
   ENDIF

//   OracleinBindParam(::hdbc, ::nParamStart, SQL_LONGVARCHAR, nLen, 0,@cRet, @nLenRet, lIn)

Return self

/*------------------------------------------------------------------------*/

METHOD ConvertParams(c) CLASS SR_ORACLE
   Local nBound
   local cRet := ProcessParams(c, @nBound)
RETURN cRet

/*------------------------------------------------------------------------*/

METHOD WriteMemo(cFileName, nRecno, cRecnoName, aColumnsAndData) CLASS SR_ORACLE

Return OracleWriteMemo(::hDbc, cFileName, nRecno, cRecnoName, aColumnsAndData)

/*------------------------------------------------------------------------*/


METHOD ExecSP(cComm, aReturn, nParam, aType) CLASS SR_ORACLE
   Local i, n
   Local nError := 0
   
   DEFAULT aReturn to {}
   DEFAULT aType to   {}
   DEFAULT nParam to   1
   
   oracleprePARE(::hdbc, cComm)
   
   oraclebindalloc(::hdbc, nParam)
   
   For i:= 1 to nParam 
      n := -1
      If Len(aType) > 0
         If aType[i]=="N"
            n  := 5
         EndIf
      EndIF      
      OracleinBindParam(::hdbc, i, n, 12, 0)      
   Next
    
   BEGIN SEQUENCE
      nError := OracleExecDir(::hDbc)
   RECOVER
      nerror := - 1
   END SEQUENCE
   
   If nError < 0
      ::RunTimeErr("", str(SQLO_GETERRORCODE(::hDbc), 4) + " - " + SQLO_GETERRORDESCR(::hDbc) ) 
   Else
   //If nError >= 0
        

      For i:=1 to nParam
        AADD(aReturn, ORACLEGETBINDDATA(::hdbc, i))
      Next
   EndIf      

   ORACLEFREEBIND(::hdbc)
   CLOSECURSOR(::hDbc)
   
Return nError
   
/*------------------------------------------------------------------------*/
METHOD ExecSPRC(cComm, lMsg, lFetch, aArray, cFile, cAlias, cVar, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode) CLASS SR_ORACLE
   Local i
   Local n, nAllocated := 0
   Local nBlocks   
   Local nError
   Local aFields
   Local nCols 
   Local aDb
   Local nFieldRec
   Local aMemo
   Local cFileTemp      
   Local cEste     
   Local nLenMemo  
   Local nLinesMemo        
   Local cCampo
   Local j 
   
   DEFAULT nMaxRecords TO 999999999999
   DEFAULT cVar To ":c1"
   (nlogMode)
   (ncols)
     
   ::AllocStatement()

   DEFAULT lMsg          TO .T.
   DEFAULT lFetch        TO .F.
   DEFAULT nMaxRecords   TO 99999999999999
   DEFAULT lNoRecno      TO .F.
   DEFAULT cRecnoName    TO SR_RecnoName()
   DEFAULT cDeletedName  TO SR_DeletedName()
   
   BEGIN SEQUENCE
      nError := ORACLE_PROCCURSOR(::hDbc, cComm, cVar)
      //nError := ORACLE_BINDCURSOR(::hDbc, cComm, cVar)
      ::cLastComm := cComm
   RECOVER
      nError := - 1
   END SEQUENCE
   
   If nError < 0
      If lFetch
       //  ::RunTimeErr("", "SQLExecDirect Error Erro na STORE PROCEDURE" ) 
       ::RunTimeErr("", str(SQLO_GETERRORCODE(::hDbc), 4) + " - " + SQLO_GETERRORDESCR(::hDbc) + ::cLastComm )
      EndIf  
   EndIf      
    
   If !Empty(cFile)
      HB_FNameSplit(cFile, , @cFileTemp)
      DEFAULT cAlias        TO cFileTemp
   EndIf

   //nCols := SQLO_NUMCOLS(::hDbc)
 
   //For i := 1 to nCols
   //   ORACLEBINDALLOC(::hDbc, i)
   //Next

   aFields := ::iniFields(.F.) 

   If lFetch
      If !Empty(cFile)
       
         aFields := ::IniFields(.F.,,,,,cRecnoName, cDeletedName )

         if Select(cAlias) == 0
            aDb := {}
            If lNoRecno
               For i = 1 to len(aFields)
                  If aFields[i,1] != cRecnoName
                     AADD(aDb, aFields[i])
                  Else
                     nFieldRec := i
                  EndIf
               Next
               dbCreate(cFile, SR_AdjustNum(aDb), SR_SetRDDTemp())
            Else
               dbCreate(cFile, SR_AdjustNum(aFields), SR_SetRDDTemp())
            EndIf

            dbUseArea(.T., SR_SetRDDTemp(), cFile, cAlias, .F.)
         else
            dbSelectArea(cAlias)
         EndIf

         n := 1

         While n <= nMaxRecords .AND. ((::nRetCode := ::Fetch(, lTranslate)) == SQL_SUCCESS )

            Append Blank

            If nFieldRec == NIL
               For i = 1 to len(aFields)
                  FieldPut(i, ::FieldGet(i, aFields, lTranslate))
               Next
            Else
               For i = 1 to len(aFields)
                  Do Case
                  Case i = nFieldRec
                     ::FieldGet(i, aFields, lTranslate)
                  Case i > nFieldRec
                     FieldPut(i - 1, ::FieldGet(i, aFields, lTranslate))
                  Case i < nFieldRec
                     FieldPut(i, ::FieldGet(i, aFields, lTranslate))
                  EndCase
               Next
            EndIf

            n ++

         EndDo

         dbGoTop()

      ElseIf aArray == NIL

         ::cResult := ""
         n         := 0
         aFields   := ::IniFields(.F.,,,,,cRecnoName, cDeletedName,.T.)
 
         For i = 1 to len(aFields)
            ::cResult += PadR(aFields[i,1], IIf(aFields[i,2] == "M", Max(len(aFields[i,1]), iif(::lShowTxtMemo, 79, 30)), Max(len(aFields[i,1]), aFields[i,3])), "-") + " "
         Next

         ::cResult += chr(13) + chr(10)
         aMemo     := Array(len(aFields))

         While n <= ::nMaxTextLines .AND. ((::nRetCode := ::Fetch(, lTranslate)) == SQL_SUCCESS )

            cEste      := ""
            nLenMemo   := 0
            nLinesMemo := 0

            For i = 1 to len(aFields)
               cCampo := ::FieldGet(i, aFields, lTranslate)
               If aFields[i,2] == "M"
                  nLenMemo   := Max(len(aFields[i,1]), iif(::lShowTxtMemo, 79, 30))
                  nLinesMemo := Max(mlCount(cCampo, nLenMemo), nLinesMemo)
                  cEste += memoline(cCampo,nLenMemo,1) + " "
                  aMemo[i] := cCampo
               Else
                  cEste += PadR(SR_Val2Char(cCampo), Max(len(aFields[i,1]), aFields[i,3])) + " "
               EndIf
            Next

            ::cResult += cEste + chr(13) + chr(10)
            n ++

            If ::lShowTxtMemo .AND. nLinesMemo > 1
               For j = 2 to nLinesMemo
                  cEste    := ""
                  For i = 1 to len(aFields)
                     If aFields[i,2] == "M"
                        cEste += memoline(aMemo[i],nLenMemo,j) + " "
                     Else
                        cEste += Space(Max(len(aFields[i,1]), aFields[i,3])) + " "
                     EndIf
                  Next
                  ::cResult += cEste + chr(13) + chr(10)
                  n ++
               Next
            EndIf

         EndDo

      Else      // Retorno deve ser para Array !

         AsizeAlloc(aArray, 300)

         If HB_ISARRAY(aArray)
            If len(aArray) = 0
               aSize(aArray, ARRAY_BLOCK1)
               nAllocated := ARRAY_BLOCK1
            Else
               nAllocated := len(aArray)
            EndIf
         Else
            aArray  := Array(ARRAY_BLOCK1)
            nAllocated := ARRAY_BLOCK1
         EndIf

         nBlocks := 1
         n       := 0
         aFields := ::IniFields(.F.,,,,, cRecnoName, cDeletedName)

         While (::nRetCode := ::Fetch(, lTranslate)) = SQL_SUCCESS
            n ++
            If n > nAllocated
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
               DEFAULT
                  nAllocated += ARRAY_BLOCK5
               ENDSWITCH

               aSize(aArray, nAllocated)
            EndIf

            aArray[n] := array(len(aFields))
            For i = 1 to len(aFields)
               aArray[n,i] := ::FieldGet(i, aFields, lTranslate)
            Next
            If n > nMaxRecords
               Exit
            EndIf
         EndDo
         aSize(aArray, n)
      EndIf
   
   Endif
 
   nerror:=SQLO_CLOSESTMT(::hDbc)
   
   If nError < 0
      If lFetch
         ::RunTimeErr("", "SQLExecDirect Error in close cursor Statement" )
      EndIf      
   endif   

  ::freestatement()
 
return  0  

function  ExecuteSP(cComm, aReturn)

   Local nError := 0
   local oConn := SR_GetConnection()
   
   DEFAULT aReturn to {}
   
   oracleprePARE(oConn:hdbc, cComm)
   
   oraclebindalloc(oConn:hdbc, 1)
   
   OracleinBindParam(oConn:hdbc, 1, -1, 12, 0)      
 
   BEGIN SEQUENCE
      nError := OracleExecDir(oConn:hDbc)
   RECOVER
      nerror := - 1
   END SEQUENCE
   
   if nError >=0
      AADD(aReturn, ORACLEGETBINDDATA(oConn:hdbc, 1))
   EndIf
   
  
   ORACLEFREEBIND(oConn:hdbc)
   CLOSECURSOR(oConn:hDbc)
    
Return nError

METHOD GetAffectedRows() CLASS SR_ORACLE
return GETAFFECTROWS(::hdbc ) 