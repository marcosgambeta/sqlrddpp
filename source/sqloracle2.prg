//
// SQLRDD Oracle Native Connection Class
// Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
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
#include "sqlora.ch"
#include "sqlrdd.ch"
#include <error.ch>
#include "msg.ch"
#include "sqlrddsetup.ch"

#define SR_CRLF   (Chr(13) + Chr(10))

#define DEBUGSESSION     .F.
#define ARRAY_BLOCK      500

//------------------------------------------------------------------------

CLASS SR_ORACLE2 FROM SR_CONNECTION

   DATA hdbc
   DATA nParamStart INIT 0

   DATA Is_logged_on
   DATA is_Attached
   DATA aBinds
   DATA aCurrLine

   METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit) CONSTRUCTOR
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
   METHOD BINDPARAM(lStart, lIn, nLen, cRet, nLenRet) //METHOD BINDPARAM(lStart, lIn, cRet, nLen)
   METHOD ConvertParams(c)
   METHOD WriteMemo(cFileName, nRecno, cRecnoName, aColumnsAndData)
   METHOD Getline(aFields, lTranslate, aArray)
   METHOD ExecSPRC(cComm, lMsg, lFetch, aArray, cFile, cAlias, cVar, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode)
   METHOD ExecSP(cComm, aReturn, nParam, aType)
   METHOD GetAffectedRows()

ENDCLASS

//------------------------------------------------------------------------

METHOD MoreResults(aArray, lTranslate) CLASS SR_ORACLE2

   HB_SYMBOL_UNUSED(aArray)
   HB_SYMBOL_UNUSED(lTranslate)

RETURN -1

//------------------------------------------------------------------------

METHOD Getline(aFields, lTranslate, aArray) CLASS SR_ORACLE2

   LOCAL i

   DEFAULT lTranslate TO .T.

   IF aArray == NIL
      aArray := Array(Len(aFields))
   ELSEIF Len(aArray) < Len(aFields)
      ASize(aArray, Len(aFields))
   ENDIF

   IF ::aCurrLine == NIL
      SQLO2_LINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, aArray)
      ::aCurrLine := aArray
      RETURN aArray
   ENDIF

   FOR i := 1 TO Len(aArray)
      aArray[i] := ::aCurrLine[i]
   NEXT i

RETURN aArray

//------------------------------------------------------------------------

METHOD FieldGet(nField, aFields, lTranslate) CLASS SR_ORACLE2

   IF ::aCurrLine == NIL
      DEFAULT lTranslate TO .T.
      ::aCurrLine := Array(Len(aFields))
      SQLO2_LINEPROCESSED(::hDbc, 4096, aFields, ::lQueryOnly, ::nSystemID, lTranslate, ::aCurrLine)
   ENDIF

RETURN ::aCurrLine[nField]

//------------------------------------------------------------------------

METHOD FetchRaw(lTranslate, aFields) CLASS SR_ORACLE2

   ::nRetCode := SQL_ERROR
   DEFAULT aFields TO ::aFields
   DEFAULT lTranslate TO .T.

   IF ::hDBC != NIL
      ::nRetCode := SQLO2_FETCH(::hDBC)
      ::aCurrLine := NIL
   ELSE
      ::RunTimeErr("", "SQLO2_FETCH - Invalid cursor state" + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
   ENDIF

RETURN ::nRetCode

//------------------------------------------------------------------------

METHOD FreeStatement() CLASS SR_ORACLE2

   IF ::hDBC != NIL .AND. ::hstmt != NIL
      IF SQLO2_CLOSESTMT(::hDBC) != SQL_SUCCESS
         ::RunTimeErr("", "SQLO2_CLOSESTMT error" + SR_CRLF + SR_CRLF + ;
            "Last command sent to database : " + SR_CRLF + ::cLastComm)
      ENDIF
      ::hstmt := NIL
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

METHOD AllocStatement() CLASS SR_ORACLE2

   LOCAL hStmtLocal := 0
   LOCAL nRet := 0
   
   HB_SYMBOL_UNUSED(hStmtLocal)

   ::FreeStatement()

   IF ::lSetNext
      ::lSetNext := .F.
      nRet := ::SetStmtOptions(::nSetOpt, ::nSetValue)
      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         SR_MsgLogFile(SR_Msg(23) + " (" + AllTrim(Str(nRet)) + ") : " + ::LastError())
      ENDIF
   ENDIF

RETURN nRet

//------------------------------------------------------------------------

METHOD IniFields(lReSelect, cTable, cCommand, lLoadCache, cWhere, cRecnoName, cDeletedName) CLASS SR_ORACLE2

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

   HB_SYMBOL_UNUSED(aFields)
   HB_SYMBOL_UNUSED(cVlr)

   DEFAULT lReSelect TO .T.
   DEFAULT lLoadCache TO .F.
   DEFAULT cWhere TO ""
   DEFAULT cRecnoName TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   IF lReSelect
      IF !Empty(cCommand)
         nRet := ::Execute(cCommand + IIf(::lComments, " /* Open Workarea with custom SQL command */", ""), .F.)
      ELSE
         nRet := ::Execute("SELECT A.* FROM " + cTable + " A " + IIf(lLoadCache, cWhere + " ORDER BY A." + cRecnoName, " WHERE 1 = 0") + IIf(::lComments, " /* Open Workarea */", ""), .F.)
      ENDIF
      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         RETURN NIL
      ENDIF
   ENDIF

   ::nFields := SQLO2_NUMCOLS(::hDBC)

   IF ::nFields < 0
      ::RunTimeErr("", "SQLO2_NUMCOLS Error" + SR_CRLF + Str(::nFields) + SR_CRLF + ;
         "Last command sent to database : " + ::cLastComm)
      RETURN NIL
   ENDIF

   aFields := Array(::nFields)

   FOR n := 1 TO ::nFields

      IF (::nRetCode := SQLO2_DESCRIBECOL(::hDBC, n, @cName, @nType, @nLen, @nDec, @nNull)) != SQL_SUCCESS
         ::RunTimeErr("", "SQLDescribeCol Error" + SR_CRLF + ::LastError() + SR_CRLF + ;
            "Last command sent to database : " + ::cLastComm)
         RETURN NIL
      ELSE
         _nLen := nLen
         _nDec := nDec
         cName := Upper(AllTrim(cName))

         IF (nLen == 2000 .OR. nLen == 4000) .AND. SR_SetNwgCompat()
            nType := SQL_FAKE_LOB
         ENDIF

         nLenField := ::SQLLen(nType, nLen, @nDec)
         cType := ::SQLType(nType, cName, nLen)

         IF !::lQueryOnly .AND. cType == "N" .AND. nLenField == 38 .AND. nDec == 0
            cType := "L"
            nLenField := 1
            nType := SQL_BIT
         ENDIF

         IF cType == "U"
            ::RuntimeErr("", SR_Msg(21) + cName + " : " + Str(nType))
         ELSE
            aFields[n] := {cName, cType, nLenField, nDec, nNull, nType, , n, , ,}
         ENDIF
      ENDIF

   NEXT n

   ::aFields := aFields

   IF lReSelect .AND. !lLoadCache
      ::FreeStatement()
   ENDIF

   HB_SYMBOL_UNUSED(_nLen)
   HB_SYMBOL_UNUSED(_nDec)

RETURN aFields

//------------------------------------------------------------------------

METHOD LastError() CLASS SR_ORACLE2

RETURN SQLO2_GETERRORDESCR(::hDBC) + " retcode: " + sr_val2Char(::nRetCode) + " - " + AllTrim(Str(SQLO2_GETERRORCODE(::hDBC)))

//------------------------------------------------------------------------

METHOD ConnectRaw(cDSN, cUser, cPassword, nVersion, cOwner, nSizeMaxBuff, lTrace, cConnect, nPrefetch, cTargetDB, nSelMeth, nEmptyMode, nDateMode, lCounter, lAutoCommit) CLASS SR_ORACLE2

   LOCAL hEnv := 0
   LOCAL hDbc := 0
   LOCAL nret
   LOCAL cVersion := ""
   LOCAL cSystemVers := ""
   LOCAL cBuff := ""
   LOCAL aRet := {}
   LOCAL aVersion
   LOCAL cmatch
   LOCAL nstart
   LOCAL nlen
   LOCAL s_reEnvVar := HB_RegexComp("(\d+\.\d+\.\d+)")
   //LOCAL cString
   
   HB_SYMBOL_UNUSED(hEnv)
   HB_SYMBOL_UNUSED(cVersion)
   HB_SYMBOL_UNUSED(cSystemVers)
   HB_SYMBOL_UNUSED(cBuff)

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
   // nret := SQLO2_CONNECT(::cUser + "/" + ::cPassWord + "@" + ::cDtb, @hDbc)
   IF ::cApp != NIL
      nret := SQLO2_CONNECT(::cDtb, ::cUser, ::cPassWord, @hDbc, .T.)
   ELSE
      nret := SQLO2_CONNECT(::cDtb, ::cUser, ::cPassWord, @hDbc, .F.)
   ENDIF
   IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      ::nRetCode := nRet
      ::hDbc := hDbc
      SR_MsgLogFile("Connection Error: " + ::lastError() + " - Connection string: " + ::cUser + "/" + Replicate("*", Len(::cPassWord)) + "@" + ::cDtb)
      RETURN SELF
   ELSE
      ::cConnect := cConnect
      ::hDbc := hDbc
      cTargetDB := "Oracle"
      cSystemVers := SQLO2_DBMSNAME(hDbc)
   ENDIF

   ::cSystemName := cTargetDB
   ::cSystemVers := cSystemVers
   ::nSystemID := SYSTEMID_ORACLE
   ::cTargetDB := Upper(cTargetDB)

   aRet := {{cSystemVers}}
   cMatch := HB_AtX(s_reEnvVar, cSystemVers, , @nStart, @nLen)
   IF !Empty(cMatch)
      aVersion := hb_atokens(cMatch, ".")
   ELSE
      aVersion := hb_atokens(StrTran(Upper(aRet[1, 1]), "ORACLE ", ""), ".")
   ENDIF

   ::Exec("select sid from " + IIf(::lCluster, "g", "") + "v$session where AUDSID = sys_context('USERENV','sessionid')", .T., .T., @aRet)

   IF Len(aRet) > 0
      ::uSid := Val(Str(aRet[1, 1], 8, 0))
   ENDIF
   SQLO2_SETSTATEMENTCACHESIZE(hdbc, 50)
   ::lOracle12 := (Val(aversion[1]) == 12)

RETURN SELF

//------------------------------------------------------------------------

METHOD End() CLASS SR_ORACLE2

   LOCAL nRet

   IF !Empty(::hDbc)
     IF (nRet := SQLO2_DISCONNECT(::hDbc)) != SQL_SUCCESS
        SR_MsgLogFile("Error disconnecting : " + Str(nRet) + SR_CRLF + ::LastError())
     ENDIF
   ENDIF

   ::hEnv := 0
   ::hDbc := NIL

RETURN NIL

//------------------------------------------------------------------------

METHOD Commit(lNoLog) CLASS SR_ORACLE2

   ::super:Commit(lNoLog)

RETURN (::nRetcode := SQLO2_COMMIT(::hdbc))

//------------------------------------------------------------------------

METHOD RollBack() CLASS SR_ORACLE2

   ::super:RollBack()

RETURN (::nRetCode := SQLO2_ROLLBACK(::hDbc))

//------------------------------------------------------------------------

METHOD ExecuteRaw(cCommand) CLASS SR_ORACLE2

   LOCAL nRet
   LOCAL i

   IF Upper(Left(LTrim(cCommand), 6)) == "SELECT"
      ::hStmt := ::hDBC

      IF !Empty(::cSqlPrepare) .AND. Len(::aBindParameters) > 0 .AND. ":1" $ ::cSqlPrepare

         ::lBind := .F.

         ORACLEPREPARE2(::hDBC, ::cSqlPrepare, .T.)
         ORACLEBINDALLOC2(::hDBC, Len(::aBindParameters))
         FOR i := 1 TO Len(::aBindParameters )
            IF HB_IsArray(::aBindParameters[i])
               IF HB_IsChar(::aBindParameters[i, 2])
                  ORACLEINBINDPARAM2(::hDBC, i, -1, ::aBindParameters[i, 3], 0, ::aBindParameters[i, 2], .T.)
               ELSEIF HB_IsDate(::aBindParameters[i, 2])
                  ORACLEINBINDPARAM2(::hDBC, i, 8, ::aBindParameters[i, 3], 0, ::aBindParameters[i, 2], .T.)
               ELSEIF HB_IsLogical(::aBindParameters[i])
                  ORACLEINBINDPARAM2(::hDBC, i, 3, ::aBindParameters[i, 3], 0, ::aBindParameters[i, 2], .T.)
               ELSE
                  ORACLEINBINDPARAM2(::hDBC, i, 2, 15, 0, ::aBindParameters[i, 2], .T.)
               ENDIF
            ELSE
               IF HB_IsChar(::aBindParameters[i])
                  ORACLEINBINDPARAM2(::hDBC, i, -1, Len(::aBindParameters[i]), 0, ::aBindParameters[i], .T.)
               ELSEIF HB_IsDate(::aBindParameters[i])
                  ORACLEINBINDPARAM2(::hDBC, i, 8, ::aBindParameters[i], 0, ::aBindParameters[i], .T.)
               ELSEIF HB_IsLogical(::aBindParameters[i])
                  ORACLEINBINDPARAM2(::hDBC, i, 3, ::aBindParameters[i], 0, ::aBindParameters[i], .T.)
               ELSE
                  ORACLEINBINDPARAM2(::hDBC, i, 2, 15, 0, ::aBindParameters[i], .T.)
               ENDIF
            ENDIF
         NEXT i
         nRet := SQLO2_EXECUTE(::hDBC, ::cSqlPrepare, .T.)

         ORACLEFREEBIND2(::hDbc)
         ::aBindParameters := {}
         ::cSqlPrepare := ""
      ELSE
         nRet := SQLO2_EXECUTE(::hDBC, cCommand)
      ENDIF
      ::lResultSet := .T.
   ELSE
      ::hStmt := NIL
      nRet := SQLO2_EXECDIRECT(::hDBC, cCommand)
      ::lResultSet := .F.
   ENDIF

RETURN nRet

//------------------------------------------------------------------------

STATIC FUNCTION ProcessParams(cSql, nBound)

   LOCAL nPos
   LOCAL cTemp := SubStr(cSql, 1, At("?", cSql) - 1)
   LOCAL lHasParen := RAt(")", cSql) > 0
   LOCAL lHasPointComma := RAt(";", cSql) > 0
   LOCAL aItens
   LOCAL cOriginal := cTemp + " "
   LOCAL xParam
   LOCAL nParamBound := 0

   cSql := StrTran(cSql, cTemp, "")
   aItens := hb_aTokens("?", ",")

   FOR EACH xParam IN aItens
      nPos := xParam:__enumIndex()
      cOriginal += AllTrim(":P" + StrZero(nPos, 3)) + " "
      nParamBound++
   NEXT

  IF lhasParen
     cOriginal += ")"
  ENDIF

  IF lHasPointComma
     cOriginal += ";"
  ENDIF

  nBound := nParamBound

RETURN cOriginal

//------------------------------------------------------------------------

METHOD BINDPARAM(lStart, lIn, nLen, cRet, nLenRet) CLASS SR_ORACLE2

   DEFAULT lIn TO .F.
   DEFAULT lStart TO .F.

   HB_SYMBOL_UNUSED(nLen)
   HB_SYMBOL_UNUSED(cRet)
   HB_SYMBOL_UNUSED(nLenRet)

   IF lStart
      ::AllocStatement()
      ::nParamStart := 1
   ELSE
      ::nParamStart++
   ENDIF

   // OracleinBindParam(::hdbc, ::nParamStart, SQL_LONGVARCHAR, nLen, 0, @cRet, @nLenRet, lIn)

RETURN SELF

//------------------------------------------------------------------------

METHOD ConvertParams(c) CLASS SR_ORACLE2

   LOCAL nBound
   LOCAL cRet := ProcessParams(c, @nBound)

RETURN cRet

//------------------------------------------------------------------------

METHOD WriteMemo(cFileName, nRecno, cRecnoName, aColumnsAndData) CLASS SR_ORACLE2

RETURN OracleWriteMemo2(::hDbc, cFileName, nRecno, cRecnoName, aColumnsAndData)

//------------------------------------------------------------------------

METHOD ExecSP(cComm, aReturn, nParam, aType) CLASS SR_ORACLE2

   LOCAL i
   LOCAL n
   LOCAL nError := 0
   
   HB_SYMBOL_UNUSED(nError)

   DEFAULT aReturn TO {}
   DEFAULT aType TO {}
   DEFAULT nParam TO 1

   oracleprePARE(::hdbc, cComm)

   oraclebindalloc(::hdbc, nParam)

   FOR i := 1 TO nParam
      n := -1
      IF Len(aType) > 0
         IF aType[i] == "N"
            n := 5
         ENDIF
      ENDIF
      OracleinBindParam(::hdbc, i, n, 12, 0)
   NEXT i

   BEGIN SEQUENCE WITH __BreakBlock()
      nError := OracleExecDir(::hDbc)
   RECOVER
      nerror := -1
   END SEQUENCE

   IF nError < 0
      ::RunTimeErr("", Str(SQLO2_GETERRORCODE(::hDbc), 4) + " - " + SQLO2_GETERRORDESCR(::hDbc))
   ELSE
   //IF nError >= 0
      FOR i := 1 TO nParam
         AAdd(aReturn, ORACLEGETBINDDATA(::hdbc, i))
      NEXT i
   ENDIF

   ORACLEFREEBIND(::hdbc)
   CLOSECURSOR(::hDbc)

RETURN nError

//------------------------------------------------------------------------

METHOD ExecSPRC(cComm, lMsg, lFetch, aArray, cFile, cAlias, cVar, nMaxRecords, lNoRecno, cRecnoName, cDeletedName, lTranslate, nLogMode) CLASS SR_ORACLE2

   LOCAL i
   LOCAL n
   LOCAL nAllocated := 0
   LOCAL nBlocks
   LOCAL nError
   LOCAL aFields
   LOCAL nCols := 0
   LOCAL aDb
   LOCAL nFieldRec
   LOCAL aMemo
   LOCAL cFileTemp
   LOCAL cEste
   LOCAL nLenMemo
   LOCAL nLinesMemo
   LOCAL cCampo
   LOCAL j
   
   HB_SYMBOL_UNUSED(nAllocated)

   DEFAULT nMaxRecords TO 999999999999 // TODO:
   DEFAULT cVar TO ":c1"

   HB_SYMBOL_UNUSED(ncols)
   HB_SYMBOL_UNUSED(nlogmode)

   ::AllocStatement()

   DEFAULT lMsg TO .T.
   DEFAULT lFetch TO .F.
   DEFAULT nMaxRecords TO 99999999999999
   DEFAULT lNoRecno TO .F.
   DEFAULT cRecnoName TO SR_RecnoName()
   DEFAULT cDeletedName TO SR_DeletedName()

   BEGIN SEQUENCE WITH __BreakBlock()
      nError := ORACLE_PROCCURSOR2(::hDbc, cComm, cVar)
      //nError := ORACLE_BINDCURSOR(::hDbc, cComm, cVar)
      ::cLastComm := cComm
   RECOVER
      nError := - 1
   END SEQUENCE

   IF nError < 0
      IF lFetch
         // ::RunTimeErr("", "SQLExecDirect Error Erro na STORE PROCEDURE")
         ::RunTimeErr("", Str(SQLO2_GETERRORCODE(::hDbc), 4) + " - " + SQLO2_GETERRORDESCR(::hDbc) + ::cLastComm)
      ENDIF
   ENDIF

   IF !Empty(cFile)
      HB_FNameSplit(cFile, , @cFileTemp)
      DEFAULT cAlias TO cFileTemp
   ENDIF

   //nCols := SQLO2_NUMCOLS(::hDbc)

   //FOR i := 1 TO nCols
   //   ORACLEBINDALLOC(::hDbc, i)
   //NEXT i

   aFields := ::iniFields(.F.)

   IF lFetch
      IF !Empty(cFile)

         aFields := ::IniFields(.F., , , , , cRecnoName, cDeletedName)

         IF Select(cAlias) == 0
            aDb := {}
            IF lNoRecno
               FOR i := 1 TO Len(aFields)
                  IF aFields[i, 1] != cRecnoName
                     AAdd(aDb, aFields[i])
                  ELSE
                     nFieldRec := i
                  ENDIF
               NEXT i
               DBCreate(cFile, SR_AdjustNum(aDb), SR_SetRDDTemp())
            ELSE
               DBCreate(cFile, SR_AdjustNum(aFields), SR_SetRDDTemp())
            ENDIF

            DBUseArea(.T., SR_SetRDDTemp(), cFile, cAlias, .F.)
         ELSE
            DBSelectArea(cAlias)
         ENDIF

         n := 1

         DO WHILE n <= nMaxRecords .AND. ((::nRetCode := ::Fetch(, lTranslate)) == SQL_SUCCESS)

            APPEND BLANK

            IF nFieldRec == NIL
               FOR i := 1 TO Len(aFields)
                  FieldPut(i, ::FieldGet(i, aFields, lTranslate))
               NEXT i
            ELSE
               FOR i := 1 TO Len(aFields)
                  DO CASE
                  CASE i = nFieldRec
                     ::FieldGet(i, aFields, lTranslate)
                  CASE i > nFieldRec
                     FieldPut(i - 1, ::FieldGet(i, aFields, lTranslate))
                  CASE i < nFieldRec
                     FieldPut(i, ::FieldGet(i, aFields, lTranslate))
                  ENDCASE
               NEXT i
            ENDIF

            n++

         ENDDO

         DBGoTop()

      ELSEIF aArray == NIL

         ::cResult := ""
         n := 0
         aFields := ::IniFields(.F., , , , , cRecnoName, cDeletedName, .T.)

         FOR i := 1 TO Len(aFields)
            ::cResult += PadR(aFields[i, 1], IIf(aFields[i, 2] == "M", Max(Len(aFields[i, 1]), IIf(::lShowTxtMemo, 79, 30)), Max(Len(aFields[i, 1]), aFields[i, 3])), "-") + " "
         NEXT i

         ::cResult += SR_CRLF
         aMemo := Array(Len(aFields))

         DO WHILE n <= ::nMaxTextLines .AND. ((::nRetCode := ::Fetch(, lTranslate)) == SQL_SUCCESS)

            cEste := ""
            nLenMemo := 0
            nLinesMemo := 0

            FOR i := 1 TO Len(aFields)
               cCampo := ::FieldGet(i, aFields, lTranslate)
               IF aFields[i, 2] == "M"
                  nLenMemo := Max(Len(aFields[i, 1]), IIf(::lShowTxtMemo, 79, 30))
                  nLinesMemo := Max(mlCount(cCampo, nLenMemo), nLinesMemo)
                  cEste += memoline(cCampo, nLenMemo, 1) + " "
                  aMemo[i] := cCampo
               ELSE
                  cEste += PadR(SR_Val2Char(cCampo), Max(Len(aFields[i, 1]), aFields[i, 3])) + " "
               ENDIF
            NEXT i

            ::cResult += cEste + SR_CRLF
            n++

            IF ::lShowTxtMemo .AND. nLinesMemo > 1
               FOR j := 2 TO nLinesMemo
                  cEste := ""
                  FOR i := 1 TO Len(aFields)
                     IF aFields[i, 2] == "M"
                        cEste += memoline(aMemo[i], nLenMemo, j) + " "
                     ELSE
                        cEste += Space(Max(Len(aFields[i, 1]), aFields[i, 3])) + " "
                     ENDIF
                  NEXT i
                  ::cResult += cEste + SR_CRLF
                  n++
               NEXT j
            ENDIF

         ENDDO

      ELSE      // Retorno deve ser para Array !

         //AsizeAlloc(aArray, 300) // TODO: ASIZEALLOC does nothing in Harbour

         IF HB_IsArray(aArray)
            IF Len(aArray) == 0
               ASize(aArray, ARRAY_BLOCK1)
               nAllocated := ARRAY_BLOCK1
            ELSE
               nAllocated := Len(aArray)
            ENDIF
         ELSE
            aArray := Array(ARRAY_BLOCK1)
            nAllocated := ARRAY_BLOCK1
         ENDIF

         nBlocks := 1
         n := 0
         aFields := ::IniFields(.F., , , ,, cRecnoName, cDeletedName)

         DO WHILE (::nRetCode := ::Fetch(, lTranslate)) = SQL_SUCCESS
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
               ASize(aArray, nAllocated)
            ENDIF
            aArray[n] := Array(Len(aFields))
            FOR i := 1 TO Len(aFields)
               aArray[n, i] := ::FieldGet(i, aFields, lTranslate)
            NEXT i
            IF n > nMaxRecords
               EXIT
            ENDIF
         ENDDO
         ASize(aArray, n)
      ENDIF

   ENDIF

   nerror := SQLO2_CLOSESTMT(::hDbc)

   IF nError < 0
      IF lFetch
         ::RunTimeErr("", "SQLExecDirect Error in close cursor Statement")
      ENDIF
   ENDIF

   ::freestatement()

   HB_SYMBOL_UNUSED(aFields)
   HB_SYMBOL_UNUSED(nBlocks)

RETURN 0

FUNCTION ExecuteSP2(cComm, aReturn)

   //LOCAL i
   //LOCAL n
   LOCAL nError := 0
   LOCAL oConn := SR_GetConnection()
   
   HB_SYMBOL_UNUSED(nError)

   DEFAULT aReturn TO {}

   oracleprePARE(oConn:hdbc, cComm)

   oraclebindalloc(oConn:hdbc, 1)

   OracleinBindParam(oConn:hdbc, 1, -1, 12, 0)

   BEGIN SEQUENCE WITH __BreakBlock()
      nError := OracleExecDir(oConn:hDbc)
   RECOVER
      nerror := -1
   END SEQUENCE

   IF nError >=0
      AAdd(aReturn, ORACLEGETBINDDATA(oConn:hdbc, 1))
   ENDIF

   ORACLEFREEBIND(oConn:hdbc)
   CLOSECURSOR(oConn:hDbc)

RETURN nError

#if 0
FUNCTION SR_AdjustNum(a)

   LOCAL b := AClone(a)
   LOCAL i

   FOR i := 1 TO Len(b)

      IF lNwgOldCompat
         IF b[i, 2] = "N"
            b[i, 3]++
         ENDIF
      ENDIF

      IF b[i, 2] = "N" .AND. b[i, 3] > 18
         b[i, 3] := 19
      ENDIF

      IF lNwgOldCompat
         IF b[i, 2] = "N" .AND. b[i, 4] >= (b[i, 3] - 1)
            b[i, 4] := Abs(b[i, 3] - 2)
         ENDIF
      ENDIF

      IF b[i, 2] = "M"
         b[i, 3] := 10
      ENDIF

   NEXT i

RETURN b
#endif
