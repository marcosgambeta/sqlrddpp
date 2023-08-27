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
// #include "compat.ch"
#include "sqlora.ch"
#include "sqlrdd.ch"
#include "error.ch"
#include "msg.ch"
#include "sqlrddsetup.ch"

#define CRLF      ( chr(13) + chr(10) )

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

   HB_SYMBOL_UNUSED(aArray)
   HB_SYMBOL_UNUSED(lTranslate)

RETURN -1

/*------------------------------------------------------------------------*/

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_ORACLE

   LOCAL i

   DEFAULT lTranslate TO .T.

   If aArray == NIL
      aArray := Array(len(aFields))
   ElseIf len(aArray) < len(aFields)
      aSize(aArray, len(aFields))
   EndIf

   If ::aCurrLine == NIL
      SQLO_LINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   EndIf

   FOR i := 1 TO len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

/*------------------------------------------------------------------------*/

METHOD FieldGet(nField, aFields, lTranslate) CLASS SR_ORACLE

   If ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := array(LEN(aFields))
      SQLO_LINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   EndIf

RETURN ::aCurrLine[nField]

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

RETURN ::nRetCode

/*------------------------------------------------------------------------*/

METHOD FreeStatement() CLASS SR_ORACLE

   if ::hDBC != NIL .AND. ::hstmt != NIL
      if SQLO_CLOSESTMT(::hDBC) != SQL_SUCCESS
         ::RunTimeErr("", "SQLO_CLOSESTMT error" + chr(13)+chr(10)+ chr(13)+chr(10)+"Last command sent to database : " + chr(13)+chr(10) + ::cLastComm )
      endif
      ::hstmt := NIL
   endif

RETURN NIL

/*------------------------------------------------------------------------*/

METHOD AllocStatement() CLASS SR_ORACLE

   LOCAL hStmtLocal := 0
   LOCAL nRet := 0

   ::FreeStatement()

   If ::lSetNext
      ::lSetNext  := .F.
      nRet := ::SetStmtOptions(::nSetOpt, ::nSetValue)
      If nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         SR_MsgLogFile(SR_Msg(23) + " (" + alltrim(str(nRet)) + ") : " + ::LastError())
      EndIf
   EndIf

RETURN nRet

/*------------------------------------------------------------------------*/

METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName) CLASS SR_ORACLE

   LOCAL n
   LOCAL nType := 0
   LOCAL nLen := 0
   LOCAL nNull := 0
   LOCAL nDec := 0
   LOCAL cName
   LOCAL _nLen
   LOCAL _nDec
   LOCAL cType
   LOCAL nLenField
   LOCAL aFields := {}
   LOCAL nRet
   LOCAL cVlr := ""

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
         RETURN NIL
      EndIf
   EndIf

   ::nFields := SQLO_NUMCOLS(::hDBC)

   If ::nFields < 0
         ::RunTimeErr("", "SQLO_NUMCOLS Error" + chr(13)+chr(10)+ str(::nFields) + chr(13)+chr(10)+;
                          "Last command sent to database : " + ::cLastComm )

      RETURN NIL
   EndIf

   aFields   := Array(::nFields)

   FOR n := 1 TO ::nFields

      if ( ::nRetCode := SQLO_DESCRIBECOL(::hDBC, n, @cName, @nType, @nLen, @nDec, @nNull) ) != SQL_SUCCESS
         ::RunTimeErr("", "SQLDescribeCol Error" + chr(13)+chr(10)+ ::LastError() + chr(13)+chr(10)+;
                          "Last command sent to database : " + ::cLastComm )
        RETURN NIL
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
   NEXT n

   ::aFields := aFields

   If lReSelect .AND. !lLoadCache
      ::FreeStatement()
   EndIf

RETURN aFields

/*------------------------------------------------------------------------*/

METHOD LastError() CLASS SR_ORACLE

RETURN SQLO_GETERRORDESCR(::hDBC) + " retcode: " + sr_val2Char(::nRetCode) + " - " + AllTrim(str(SQLO_GETERRORCODE(::hDBC)))

/*------------------------------------------------------------------------*/

METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace,;
            cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit) CLASS SR_ORACLE

   LOCAL hEnv := 0
   LOCAL hDbc := 0
   LOCAL nret
   LOCAL cVersion := ""
   LOCAL cSystemVers := ""
   LOCAL cBuff := ""
   LOCAL aRet := {}

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

   ::hStmt := NIL
   nret    :=  SQLO_CONNECT(::cUser + "/" + ::cPassWord + "@" + ::cDtb, @hDbc)
   if nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode = nRet
      ::hDbc     := hDbc
      SR_MsgLogFile("Connection Error: " + ::lastError() + " - Connection string: " + ::cUser + "/" + Replicate("*", len(::cPassWord) ) + "@" + ::cDtb)
      RETURN Self
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

RETURN Self

/*------------------------------------------------------------------------*/

METHOD End() CLASS SR_ORACLE

   LOCAL nRet

   IF !Empty(::hDbc)
     IF  ( nRet := SQLO_DISCONNECT(::hDbc)) != SQL_SUCCESS
        SR_MsgLogFile("Error disconnecting : " + str(nRet) + CRLF + ::LastError())
     EndIf
   ENDIF

   ::hEnv  = 0
   ::hDbc  = NIL

RETURN NIL

/*------------------------------------------------------------------------*/

METHOD Commit(lNoLog) CLASS SR_ORACLE
   ::Super:Commit(lNoLog)
RETURN (::nRetcode := SQLO_COMMIT(::hdbc) )

/*------------------------------------------------------------------------*/

METHOD RollBack() CLASS SR_ORACLE
   ::Super:RollBack()
RETURN ( ::nRetCode := SQLO_ROLLBACK(::hDbc) )

/*------------------------------------------------------------------------*/

METHOD ExecuteRaw(cCommand) CLASS SR_ORACLE

   LOCAL nRet

   If upper(left(ltrim(cCommand), 6)) == "SELECT"
      ::hStmt := ::hDBC
      nRet := SQLO_EXECUTE(::hDBC, cCommand)
      ::lResultSet := .T.
   Else
      ::hStmt := NIL
      nRet := SQLO_EXECDIRECT(::hDBC, cCommand)
      ::lResultSet := .F.
   EndIf

RETURN nRet

/*------------------------------------------------------------------------*/

Static FUNCTION ProcessParams(cSql, nBound)

   LOCAL nPos
   LOCAL cTemp := SubStr(cSql, 1, AT("?" , cSql) - 1)
   LOCAL lHasParen := Rat(")", cSql) > 0
   LOCAL lHasPointComma := Rat(";", cSql) > 0
   LOCAL aItens
   LOCAL cOriginal := cTemp + " "
   LOCAL xParam
   LOCAL nParamBound := 0

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
   
   HB_SYMBOL_UNUSED(nLen)
   HB_SYMBOL_UNUSED(cRet)
   HB_SYMBOL_UNUSED(nLenRet)
   
   IF lStart
      ::AllocStatement()
      ::nParamStart  := 1
   ELSE
      ::nParamStart ++
   ENDIF

//   OracleinBindParam(::hdbc, ::nParamStart, SQL_LONGVARCHAR, nLen, 0,@cRet, @nLenRet, lIn)

RETURN self

/*------------------------------------------------------------------------*/

METHOD ConvertParams(c) CLASS SR_ORACLE

   LOCAL nBound
   LOCAL cRet := ProcessParams(c, @nBound)

RETURN cRet

/*------------------------------------------------------------------------*/

METHOD WriteMemo(cFileName, nRecno, cRecnoName, aColumnsAndData) CLASS SR_ORACLE

RETURN OracleWriteMemo(::hDbc, cFileName, nRecno, cRecnoName, aColumnsAndData)

/*------------------------------------------------------------------------*/


METHOD ExecSP(cComm, aReturn, nParam, aType) CLASS SR_ORACLE

   LOCAL i
   LOCAL n
   LOCAL nError := 0
   
   DEFAULT aReturn to {}
   DEFAULT aType to   {}
   DEFAULT nParam to   1
   
   oracleprePARE(::hdbc, cComm)
   
   oraclebindalloc(::hdbc, nParam)
   
   FOR i := 1 TO nParam
      n := -1
      If Len(aType) > 0
         If aType[i]=="N"
            n  := 5
         EndIf
      EndIF
      OracleinBindParam(::hdbc, i, n, 12, 0)
   NEXT i

   BEGIN SEQUENCE
      nError := OracleExecDir(::hDbc)
   RECOVER
      nerror := - 1
   END SEQUENCE
   
   If nError < 0
      ::RunTimeErr("", str(SQLO_GETERRORCODE(::hDbc), 4) + " - " + SQLO_GETERRORDESCR(::hDbc) ) 
   Else
   //If nError >= 0
        

      FOR i := 1 TO nParam
         AADD(aReturn, ORACLEGETBINDDATA(::hdbc, i))
      NEXT i
   EndIf      

   ORACLEFREEBIND(::hdbc)
   CLOSECURSOR(::hDbc)
   
RETURN nError
   
/*------------------------------------------------------------------------*/
METHOD ExecSPRC(cComm, lMsg, lFetch, aArray, cFile, cAlias, cVar, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode) CLASS SR_ORACLE

   LOCAL i
   LOCAL n
   LOCAL nAllocated := 0
   LOCAL nBlocks
   LOCAL nError
   LOCAL aFields
   LOCAL nCols
   LOCAL aDb
   LOCAL nFieldRec
   LOCAL aMemo
   LOCAL cFileTemp
   LOCAL cEste
   LOCAL nLenMemo
   LOCAL nLinesMemo
   LOCAL cCampo
   LOCAL j

   DEFAULT nMaxRecords TO 999999999999
   DEFAULT cVar To ":c1"

   HB_SYMBOL_UNUSED(nlogMode)
   HB_SYMBOL_UNUSED(ncols)

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
 
   //FOR i := 1 TO nCols
   //   ORACLEBINDALLOC(::hDbc, i)
   //NEXT i

   aFields := ::iniFields(.F.) 

   If lFetch
      If !Empty(cFile)
       
         aFields := ::IniFields(.F.,,,,,cRecnoName, cDeletedName )

         if Select(cAlias) == 0
            aDb := {}
            If lNoRecno
               FOR i := 1 TO len(aFields)
                  If aFields[i,1] != cRecnoName
                     AADD(aDb, aFields[i])
                  Else
                     nFieldRec := i
                  EndIf
               NEXT i
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
               FOR i := 1 TO len(aFields)
                  FieldPut(i, ::FieldGet(i, aFields, lTranslate))
               NEXT i
            Else
               FOR i := 1 TO len(aFields)
                  Do Case
                  Case i = nFieldRec
                     ::FieldGet(i, aFields, lTranslate)
                  Case i > nFieldRec
                     FieldPut(i - 1, ::FieldGet(i, aFields, lTranslate))
                  Case i < nFieldRec
                     FieldPut(i, ::FieldGet(i, aFields, lTranslate))
                  EndCase
               NEXT i
            EndIf

            n ++

         EndDo

         dbGoTop()

      ElseIf aArray == NIL

         ::cResult := ""
         n         := 0
         aFields   := ::IniFields(.F.,,,,,cRecnoName, cDeletedName,.T.)
 
         FOR i := 1 TO len(aFields)
            ::cResult += PadR(aFields[i,1], IIf(aFields[i,2] == "M", Max(len(aFields[i,1]), iif(::lShowTxtMemo, 79, 30)), Max(len(aFields[i,1]), aFields[i,3])), "-") + " "
         NEXT i

         ::cResult += chr(13) + chr(10)
         aMemo     := Array(len(aFields))

         While n <= ::nMaxTextLines .AND. ((::nRetCode := ::Fetch(, lTranslate)) == SQL_SUCCESS )

            cEste      := ""
            nLenMemo   := 0
            nLinesMemo := 0

            FOR i := 1 TO len(aFields)
               cCampo := ::FieldGet(i, aFields, lTranslate)
               If aFields[i,2] == "M"
                  nLenMemo   := Max(len(aFields[i,1]), iif(::lShowTxtMemo, 79, 30))
                  nLinesMemo := Max(mlCount(cCampo, nLenMemo), nLinesMemo)
                  cEste += memoline(cCampo,nLenMemo,1) + " "
                  aMemo[i] := cCampo
               Else
                  cEste += PadR(SR_Val2Char(cCampo), Max(len(aFields[i,1]), aFields[i,3])) + " "
               EndIf
            NEXT i

            ::cResult += cEste + chr(13) + chr(10)
            n ++

            If ::lShowTxtMemo .AND. nLinesMemo > 1
               FOR j := 2 TO nLinesMemo
                  cEste    := ""
                  FOR i := 1 TO len(aFields)
                     If aFields[i,2] == "M"
                        cEste += memoline(aMemo[i],nLenMemo,j) + " "
                     Else
                        cEste += Space(Max(len(aFields[i,1]), aFields[i,3])) + " "
                     EndIf
                  NEXT i
                  ::cResult += cEste + chr(13) + chr(10)
                  n ++
               NEXT j
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
               OTHERWISE
                  nAllocated += ARRAY_BLOCK5
               ENDSWITCH

               aSize(aArray, nAllocated)
            EndIf

            aArray[n] := array(len(aFields))
            FOR i := 1 TO len(aFields)
               aArray[n,i] := ::FieldGet(i, aFields, lTranslate)
            NEXT i
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
 
RETURN  0  

FUNCTION ExecuteSP(cComm, aReturn)

   LOCAL nError := 0
   LOCAL oConn := SR_GetConnection()
   
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
    
RETURN nError

METHOD GetAffectedRows() CLASS SR_ORACLE
RETURN GETAFFECTROWS(::hdbc )