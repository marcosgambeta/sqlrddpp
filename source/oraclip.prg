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

REQUEST ADS

#include "sqlrdd.ch"
#include "sqlodbc.ch"
#include <common.ch>
#include <hbclass.ch>
#include "ads.ch"

STATIC s_aOraclipHash := hb_hash()
STATIC s_aOraClipCursors := hb_hash()
STATIC s_nIdCursor := 1
STATIC s_hplVars := {}
STATIC s_nlasterror := 0
STATIC s_lReleaseBind := .F.
STATIC s_aDestroyFiles := {} // not used

FUNCTION OraExecSql(n, c, adata)

   LOCAL cbind
   LOCAL i

   IF aData != NIL .AND. HB_IsArray(adata)
      FOR i := Len(aData) TO 1 STEP -1
         cBind := ":" + AllTrim(Str(i))
         c := StrTran(c, cBind, sr_cdbvalue(adata[i]))
      NEXT i
   ENDIF

RETURN SR_GetConnection():Exec(c, , .F.)

FUNCTION cssel1(n, aret, csql, adata)
RETURN OraSel1(n, @aret, csql, adata)

FUNCTION OraSeek(nCursor, aData, cTable, cWhere, aVarSust)

   LOCAL cSql := "select * from " + cTable
   LOCAL nRet

   IF !Empty(cWhere)
      cSql += " where " + cWhere
   ENDIF
   s_aOraClipCursors[nCursor]["oraseek"] := .T.
   nRet := OraSel1(nCursor, @aData, csql, aVarSust)

RETURN nret

FUNCTION OraSel1(n, aret, csql, adata)

   LOCAL oSql := SR_GetConnection()
   LOCAL nError
   LOCAL i
   LOCAL cBind := ""
   LOCAL aTemp := {}
   LOCAL aDataRet
   LOCAL cursor
   LOCAL lRowId := .F.
   LOCAL cTmpFile
   LOCAL nArea := SelecT()
   LOCAL aDb
   LOCAL aTmp
   LOCAL ncount := 0

   SET SERVER LOCAL
   SR_SetRDDTemp("ADT")
   closecursor(n)
   s_aOraClipCursors[n]["cursoropen"] := .F.
   IF adata == NIL

      IF "ROWID" $ csql
         s_aOraClipCursors[n]["data"] := {}
         nError := SR_GetConnection():Exec(csql, , .T., @aret)
         lRowId := .T.
      ELSE
         nError := ExecuteSql(csql, @cursor, n) // SR_GetConnection():Exec(csql, , .T., @aret)
         // s_aOraClipCursors[n]["ret"] := s_aOraClipCursors[n]["data"]
      ENDIF

      IF nError == 0
         s_aOraClipCursors[n]["cursoropen"] := .T.
         s_aOraClipCursors[n]["cursor"] := cursor
         s_aOraClipCursors[n]["start"] := 1
         s_aOraClipCursors[n]["len"] := 0
         s_aOraClipCursors[n]["curpos"] := 1
         s_aOraClipCursors[n]["error"] := 0
         s_aOraClipCursors[n]["nrowread"] := -1
         s_aOraClipCursors[n]["lastsql"] := cSql
         s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
         IF !lRowid
            s_aOraClipCursors[n]["aFields"] := SR_GetConnection():IniFields(.F.) //aFields
            s_aOraClipCursors[n]["data"] := {}
            s_aOraClipCursors[n]["completed"] := .F.
            s_aOraClipCursors[n]["eof"] := .F.

            FOR EACH atmp IN s_aOraClipCursors[n]["aFields"]
#if 0
               IF "TO_CHAR(" $ Upper(atmp[1])
                  atmp[1] := SubStr(atmp[1], At("TO_DATE(", Upper(atmp[1])) + 9)
                  atmp[1] := SubStr(atmp[1], 1, At(",", Upper(atmp[1])) - 1)
               ENDIF
               IF "DECODE(" $ Upper(atmp[1])
                  atmp[1] := SubStr(atmp[1], At("DECODE(", Upper(atmp[1])) + 8)
                  atmp[1] := SubStr(atmp[1], 1, At(",", Upper(atmp[1])) - 1)
               ENDIF
#endif
               atmp[1] := "fld" + StrZero(ncount++, 5)
            NEXT

            FClose(HB_FTEMPCREATE(".", "tmp", , @cTmpFile))
            s_aOraClipCursors[n]["aliastmp"] := StrTran(StrTran(cTmpFile, ".", ""), "\", "")
            IF File(StrTran(cTmpfile, ".\", ""))
               FErase(StrTran(cTmpfile, ".\", ""))
            ENDIF
            IF File(cTmpfile)
               FErase(cTmpfile)
            ENDIF
            s_aOraClipCursors[n]["tmpfile"] := cTmpFile
            DBCreate(cTmpFile, SR_AdjustNum(s_aOraClipCursors[n]["aFields"]), SR_SetRDDTemp())
            DBUseArea(.T., SR_SetRDDTemp(), cTmpFile, s_aOraClipCursors[n]["aliastmp"])
            cTmpFile := StrTran(cTmpfile, ".\", "")
            OraFetch(n)
            aRet := s_aOraClipCursors[n]["data"]

            s_nlasterror := 0
         ELSE
            IF Len(aRet) >= 1
               s_aOraClipCursors[n]["data"] := aret[1]
               aret := AClone(s_aOraClipCursors[n]["data"])
            ENDIF
            s_aOraClipCursors[n]["completed"] := .F.
            s_aOraClipCursors[n]["eof"] := .F.
            s_nlasterror := 0
         ENDIF
#if 0
         IF Len(aRet) >= 1
            aDataRet := aRet[1]
            aret := AClone(aDataRet)
         ENDIF
#endif
      ELSE
         s_aOraClipCursors[n]["eof"] := .T.
         s_aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
         s_aOraClipCursors[n]["lastsql"] := ""
         s_aOraClipCursors[n]["rowaffected"] := 0
         s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
         s_aOraClipCursors[n]["aFields"] := {}
      ENDIF
      IF nArea > 0
         Select(nArea)
      ENDIF
      RETURN nError

   ENDIF

   FOR i := 1 TO Len(aData)
      cBind := ":" + AllTrim(Str(i))
      cSql := StrTran(cSql, cBind, sr_cdbvalue(adata[i]))
   NEXT i
   //nError := SR_GetConnection():Exec(csql, , .T., @aret)
   IF "ROWID" $ csql
      s_aOraClipCursors[n]["data"] := {}
      nError := SR_GetConnection():Exec(csql, , .T., @aret)
      lRowId := .T.
   ELSE
      nError := ExecuteSql(csql, @cursor, n) // SR_GetConnection():Exec(csql, , .T., @aret)
   ENDIF

   //s_aOraClipCursors[n]["ret"] := AClone(aret)
   IF nError == 0
      s_aOraClipCursors[n]["cursoropen"] := .T.
      s_aOraClipCursors[n]["cursor"] := cursor
      s_aOraClipCursors[n]["start"] := 1
      s_aOraClipCursors[n]["len"] := 0
      s_aOraClipCursors[n]["curpos"] := 0
      s_aOraClipCursors[n]["error"] := 0
      s_aOraClipCursors[n]["nrowread"] := -1
      s_aOraClipCursors[n]["lastsql"] := cSql
      s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      IF !lRowid
         s_aOraClipCursors[n]["aFields"] :=  SR_GetConnection():IniFields(.F.) //aFields
         s_aOraClipCursors[n]["completed"] := .F.
         s_aOraClipCursors[n]["eof"] := .F.
         s_nlasterror := 0
         FClose(HB_FTEMPCREATE(".", "tmp", , @cTmpFile))
         s_aOraClipCursors[n]["aliastmp"] := StrTran(StrTran(cTmpFile, ".", ""), "\", "")
         IF File(StrTran(cTmpfile, ".\", ""))
            FErase(StrTran(cTmpfile, ".\", ""))
         ENDIF
         IF File(cTmpfile)
            FErase(cTmpfile)
         ENDIF
         FOR EACH atmp IN s_aOraClipCursors[n]["aFields"]
#if 0
            IF "TO_CHAR(" $ atmp[1]
               atmp[1] := SubStr(atmp[1], At("TO_DATE(", Upper(atmp[1])) + 9)
               atmp[1] := SubStr(atmp[1], 1, At(",", Upper(atmp[1])) - 1)
            ENDIF
            IF "DECODE(" $ Upper(atmp[1])
               atmp[1] := SubStr(atmp[1], At("DECODE(", Upper(atmp[1])) + 8)
               atmp[1] := SubStr(atmp[1], 1, At(",", Upper(atmp[1])) - 1)
            ENDIF
#endif
            atmp[1] := "fld" + StrZero(ncount++, 5)
         NEXT

         s_aOraClipCursors[n]["tmpfile"] := cTmpFile
         DBCreate(cTmpFile, SR_AdjustNum(s_aOraClipCursors[n]["aFields"]), SR_SetRDDTemp())
         DBUseArea(.T., SR_SetRDDTemp(), cTmpFile, s_aOraClipCursors[n]["aliastmp"])
         cTmpFile := StrTran(cTmpfile, ".\", "")
         orafetch(n)
         aret := s_aOraClipCursors[n]["data"]
      ELSE
         IF Len(aRet) >= 1
            s_aOraClipCursors[n]["data"] := aret[1]
            aret := AClone(s_aOraClipCursors[n]["data"])
         ENDIF
         s_aOraClipCursors[n]["completed"] := .F.
         s_aOraClipCursors[n]["eof"] := .F.
         s_nlasterror := 0
      ENDIF
   ELSE
      s_aOraClipCursors[n]["eof"] := .T.
      s_aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[n]["lastsql"] := ""
      s_aOraClipCursors[n]["rowaffected"] := 0
      s_aOraClipCursors[n]["aFields"] := {}
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
   ENDIF
   IF nArea > 0
      Select(nArea)
   ENDIF

RETURN nError

FUNCTION orafound(n)

   LOCAL lret := .F.

   IF s_aOraClipCursors[n]["oraseek"]
      lret := !s_aOraClipCursors[n]["eof"]
      s_aOraClipCursors[n]["eof"] := .F.
      s_aOraClipCursors[n]["oraseek"] := .F.
      RETURN lret
   ENDIF
   IF s_aOraClipCursors[n]["eof"] .AND. s_aOraClipCursors[n]["completed"]
      RETURN .F.
   ENDIF

RETURN Len(s_aOraClipCursors[n]["data"]) > 0

FUNCTION OraDelete(nCursor2, cTabOrgMat, cwhere, adata)

   LOCAL csql := "delete from " + cTabOrgMat
   LOCAL i
   LOCAL oSql := SR_GetConnection()
   LOCAL nError
   LOCAL e
   LOCAL cBind

   IF PCount() == 3
      cSql +=  " where " +  cwhere
   ELSEIF PCount() == 4
      FOR i := 1 TO Len(aData)
         cBind := ":" + AllTrim(Str(i))
         cwhere := StrTran(cwhere, cBind, sr_cdbvalue(adata[i]))
      NEXT i
      cSql += " where " +  cwhere
   ENDIF
   nError := SR_GetConnection():Exec(csql, , .F.)
   IF nError == 0
      s_aOraClipCursors[nCursor2]["error"] := 0
      s_aOraClipCursors[nCursor2]["lastsql"] := cSql
      s_aOraClipCursors[ncursor2]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_nlasterror := 0
   ELSE
      s_aOraClipCursors[nCursor2]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[nCursor2]["lastsql"] := ""
      s_aOraClipCursors[ncursor2]["rowaffected"] := 0
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
   ENDIF

RETURN nError

FUNCTION OraCommit()
   sr_committransaction()
RETURN  0

FUNCTION OraBegin()
   sr_begintransaction()
RETURN  0

FUNCTION OraRollBack()
   sr_rollbacktransaction()
RETURN  0

FUNCTION OraErrMsg()

   LOCAL c
   LOCAL e

   BEGIN SEQUENCE WITH __BreakBlock()
      c := SQLO_GETERRORDESCR(SR_GetConnection():hDBC)
   RECOVER USING e
      c := "usuario nao conectado"
   END SEQUENCE

RETURN c

FUNCTION OraUpdate(nCursor, cTabAutos, aCols, aDadosAlt, cWhere, aChave)

   LOCAL csql := "update " +  cTabAutos + " set "
   LOCAL n
   LOCAL i
   LOCAL e
   LOCAL oSql := SR_GetConnection()
   LOCAL nError
   LOCAL cbind
   LOCAL nPos

   nPos := AScan(acols,{|x|Upper(x) == "ROWID"})
   FOR n := 1 TO Len(aDadosAlt)
      IF nPos >0
         IF nPos != n
            cSql += acols[n ] + "=" + sr_cdbvalue(aDadosAlt[n]) + ","
         ENDIF
      ELSE
         cSql += acols[n ] + "=" + sr_cdbvalue(aDadosAlt[n]) + ","
      ENDIF
   NEXT n
   cSql := SubStr(csql, 1, Len(csql) - 1)

   IF PCount() == 5
      csql +=  " where " +  cwhere
   ELSEIF PCount() == 6
      FOR i := Len(aChave) TO 1 STEP -1
         cBind := ":" + AllTrim(Str(i))
         cwhere := StrTran(cwhere, cBind, sr_cdbvalue(aChave[i]))
      NEXT i
      cSql += " where " +  cwhere
   ENDIF
   BEGIN SEQUENCE WITH __BreakBlock()
      nError := SR_GetConnection():Exec(csql, , .F.)
      s_aOraClipCursors[nCursor]["error"] := 0
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_aOraClipCursors[ncursor]["cwhere"] := cwhere
      s_nlasterror := 0
   RECOVER USING e
      nerror := -1
      s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[nCursor]["lastsql"] := ""
      s_aOraClipCursors[ncursor]["rowaffected"] := 0
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
   END SEQUENCE

RETURN nError

FUNCTION OraOpen(n, ncursor)

   nCursor := s_nIdCursor
   s_aOraclipHash[n] := hb_hash()
   s_aOraclipHash[n][s_nIdCursor] := hb_hash()
   s_aOraClipCursors[s_nIdCursor] := hb_hash()
   s_aOraClipCursors[s_nIdCursor]["oraseek"] := .F.
   s_aOraClipCursors[s_nIdCursor]["cursoropen"] := .F.
   ++s_nIdCursor

RETURN 0

FUNCTION cslogon(cCnxName, cUser, cPwd, cAlias, nCnxType)
RETURN OraLogon(cCnxName, cUser, cPwd, cAlias, nCnxType)

FUNCTION ocInitialize(cConexion, cUsuario, cPassword, cAlias)
RETURN OraLogon(cConexion, cUsuario, cPassword , cAlias )

FUNCTION OraLogon(cCnxName, cUser, cPwd, cAlias, nCnxType)

   LOCAL cString
   LOCAL nRet

   cString := "UID=" + cUSer + ";PWD=" + cPwd
   IF !Empty(cAlias)
      cString += ";TNS=" + cAlias
   ENDIF
   nRet := sr_addconnection(CONNECT_ORACLE, cstring)

   IF nRet > 0
      s_aOraclipHash[cCnxName] := hb_hash()
      s_aOraclipHash[cCnxName]["nRet"] := nRet
      s_aOraclipHash[cCnxName]["alias"] := cAlias
      s_aOraclipHash[cCnxName]["time"] := DToC(Date()) + "-" + Time()
      s_aOraclipHash[cCnxName]["user"] := cUSer
      s_aOraclipHash[cCnxName]["pwd"] := cPwd
   ENDIF

RETURN IIf(nRet > 0, 0, nret)

FUNCTION cslogoff(cCnxName)
RETURN OraLogoff(cCnxName)

FUNCTION OraLogoff(cCnxName)

   LOCAL e
   LOCAL hData

   BEGIN SEQUENCE WITH __BreakBlock()
      hData := s_aOraclipHash[cCnxName]
      IF !Empty(hdata)
         sr_endconnection(hData["nRet"])
         s_aOraclipHash[cCnxName]["nRet"] := NIL
      ENDIF
   RECOVER USING e
      sr_endconnection()
   END SEQUENCE

RETURN NIL

FUNCTION oraalias(cCnxName)
RETURN s_aOraclipHash[cCnxName]["alias"]

FUNCTION oralogtime(cCnxName)
RETURN s_aOraclipHash[cCnxName]["time"]

FUNCTION orauser(ccnxname)
RETURN s_aOraclipHash[cCnxName]["user"]

FUNCTION orapwd(ccnxname)
RETURN s_aOraclipHash[cCnxName]["pwd"]

FUNCTION oraintrans(ccnxname)
RETURN SR_TransactionCount(s_aOraclipHash[cCnxName]["nRet"])

FUNCTION csskip(n, aData, nPos)
RETURN oraskip(n, @aData, nPos)

//Alteracao
FUNCTION oraskip(n, aData, nPos)

   LOCAL i
   LOCAL lPrimeiro := .T.

   DEFAULT nPos TO 1

   IF nPos > 0
      IF s_aOraClipCursors[n]["curpos"] == 0
         s_aOraClipCursors[n]["curpos"] := 1
      ENDIF
      FOR i := 1 TO nPos
         s_aOraClipCursors[n]["curpos"]++
         OraFetch(n)
      NEXT i

      //IF s_aOraClipCursors[n]["curpos"]+1 <= s_aOraClipCursors[n]["len"]
      s_aOraClipCursors[n]["curpos"]++
      //aData := s_aOraClipCursors[n]["ret"][s_aOraClipCursors[n]["curpos"]]
      aData := s_aOraClipCursors[n]["data"]
      //ENDIF
   ELSE
      FOR i := nPos TO 1 STEP -1
         s_aOraClipCursors[n]["curpos"]--
      NEXT i

      IF s_aOraClipCursors[n]["curpos"]-1 >= s_aOraClipCursors[n]["start"]
         OraFetch(n)
         //aData := s_aOraClipCursors[n]["ret"][s_aOraClipCursors[n]["curpos"]]
         aData := s_aOraClipCursors[n]["data"]
      ENDIF

   ENDIF

RETURN 0

FUNCTION cseof(n)
RETURN oraeof(n)

FUNCTION oraeof(n)

   LOCAL lreturn := .F.
   LOCAL i

   IF s_aOraClipCursors[n]["completed"]
      lreturn := .T. // (s_aOraClipCursors[n]["aliastmp"])->(Eof())
   ELSE
      IF !s_aOraClipCursors[n]["completed"] .AND. s_aOraClipCursors[n]["eof"]
         lreturn := .T.
      ELSE
         lreturn := .F.
      ENDIF
   ENDIF

   IF lReturn
      FOR i := 1 TO Len(s_aOraClipCursors[n]["data"])
         s_aOraClipCursors[n]["data"][i] := GerGhost(s_aOraClipCursors[n]["data"][i])
      NEXT i
   ENDIF

RETURN lreturn

//RETURN s_aOraClipCursors[n]["curpos"] >= s_aOraClipCursors[n]["len"]

FUNCTION csbof(n)
RETURN orabof(n)

FUNCTION orabof(n)
RETURN s_aOraClipCursors[n]["curpos"] == s_aOraClipCursors[n]["start"]

FUNCTION orazap(n)
RETURN NIL

FUNCTION orastruct(n, ctable)

   LOCAL aStru
   LOCAL csql := "select * from " + ctable + " where 1 == 1"

   USE (csql) NEW VIA "SQLRDD" ALIAS "ZZZZZZZZZZ"
   aStru := zzzzzzzzzz->(DBStruct())
   zzzzzzzzzz->(DBCloseArea())

RETURN astru

FUNCTION OraSetPwd(nCursor, cUser, cPassword)

   LOCAL cSql := "alter user " + cUser + " identified by " + cPassword
   LOCAL nRet
   LOCAL e

   nRet := SR_GetConnection():Exec(cSql, , .F.)

RETURN nRet

FUNCTION OraSingle(n, csql, adata)

   LOCAL oSql := SR_GetConnection()
   LOCAL nError
   LOCAL aRet := {}
   LOCAL i
   LOCAL e
   LOCAL cBind

   IF adata == NIL
      nError := SR_GetConnection():Exec(csql, , .T., @aret)
      IF nError == 0
         s_aOraClipCursors[n]["error"] := 0
         s_aOraClipCursors[n]["lastsql"] := cSql
         s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
         s_nlasterror := 0
         s_aOraClipCursors[n]["aFields"] := SR_GetConnection():aFields
         IF Len(aret) == 1
            IF Len(aRet[1]) == 1
               RETURN aret[1, 1]
            ELSE
               RETURN aret[1]
            ENDIF
         ENDIF

      ELSE
         s_aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
         s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
         s_aOraClipCursors[n]["lastsql"] := ""
         s_aOraClipCursors[n]["rowaffected"] := 0
         s_aOraClipCursors[n]["aFields"] := {}
      ENDIF
      RETURN aret

   ENDIF

   FOR i := 1 TO Len(aData)
      cBind := ":" + AllTrim(Str(i))
      cSql := StrTran(cSql, cBind, sr_cdbvalue(adata[i]))
   NEXT i

   BEGIN SEQUENCE WITH __BreakBlock()
      nError := SR_GetConnection():Exec(csql, , .T., @aret)
   RECOVER USING e
      nerror := -1
   END SEQUENCE

   s_aOraClipCursors[n]["ret"] := aret
   IF nError == 0
      s_aOraClipCursors[n]["start"] := 1
      s_aOraClipCursors[n]["len"] := Len(aret)
      s_aOraClipCursors[n]["curpos"] := 1
      s_aOraClipCursors[n]["error"] := 0
      s_aOraClipCursors[n]["nrowread"] := -1
      s_aOraClipCursors[n]["lastsql"] := cSql
      s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_aOraClipCursors[n]["aFields"] := SR_GetConnection():aFields
      s_nlasterror := 0
   ELSE
      s_aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[n]["lastsql"] := ""
      s_aOraClipCursors[n]["rowaffected"] := 0
      s_aOraClipCursors[n]["aFields"] := {}
   ENDIF

RETURN nError

FUNCTION OraInsert(nCursor, cTable, aCols, aData)

   LOCAL cSql := "insert into " + ctable
   LOCAL cValues := ""
   LOCAL i
   LOCAL nError
   LOCAL e
   LOCAL osql := SR_GetConnection()

   IF Len(acols) > 0
      cSql += "( "

      FOR i := 1 TO Len(acols)
         IF Upper(aCols[i]) == "SR_DELETED"
            cSql += aCols[i] + ","
            cValues += "' ',"
         ELSEIF Upper(aCols[i]) == "ROWID"
         ELSE
            cSql += aCols[i] + ","
            cValues += sr_cdbvalue(aData[i]) + ","
         ENDIF
      NEXT i

   ENDIF
   IF Len(acols ) == 0 .AND. Len(adata ) > 0
      FOR i := 1 TO Len(aData)
         cValues += sr_cdbvalue(aData[i]) + ","
      NEXT i
   ENDIF

   IF Len(acols ) > 0
      cSql := SubStr(cSql, 1, Len(cSql)-1) + ") VALUES ("
   ELSE
      csql += " values ( "
   ENDIF
   cValues := SubStr(cValues, 1, Len(cValues)-1) + ")"
   cSql += cValues

   BEGIN SEQUENCE WITH __BreakBlock()
      nError := SR_GetConnection():Exec(csql, , .F.,)
      s_aOraClipCursors[nCursor]["error"] := 0
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_aOraClipCursors[ncursor]["acols"] := acols
      s_aOraClipCursors[ncursor]["avalues"] := aData
      s_nlasterror := 0
   RECOVER USING e
      nerror := -1
      s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := 0
   END SEQUENCE

RETURN nError

FUNCTION OraCount(nCursor, cTabela, cWhere, aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL i
   LOCAL cbind

   IF PCount() < 2
      RETURN NIL
   ENDIF
   IF PCount() == 2
      cSql := "select count(*) from " +cTabela
   ELSEIF PCount() == 3
      cSql := "select count(*) from " +cTabela + " where " + cwhere
   ELSEIF PCount() == 4
      cSql := "select count(*) from " +cTabela
      FOR i := 1 TO Len(aVarSust)
         cBind := ":" + AllTrim(Str(i))
         cwhere := StrTran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
      NEXT i
      cSql += " where " +  cwhere
   ENDIF
   nErro := SR_GetConnection():Exec(cSql, , .T., @aret)
   IF nErro == 0
      s_aOraClipCursors[nCursor]["error"] := 0
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      //s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_nlasterror := 0
      RETURN aRet[1, 1]
   ELSE
      s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      //s_aOraClipCursors[ncursor]["rowaffected"] := 0
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
   ENDIF

RETURN 0

FUNCTION oraset()
RETURN NIL

FUNCTION oraerror(n)

   IF PCount() == 0
      RETURN s_nlasterror
   ENDIF

RETURN s_aOraClipCursors[n]["error"]

FUNCTION csSetVar(cVarName, cOraType, nLen, nDec, xInitValue)
RETURN OraSetVar(cVarName, cOraType, nLen, nDec, xInitValue)

FUNCTION OraSetVar(cVarName, cOraType, nLen, nDec, xInitValue)

   DEFAULT nlen TO 1
   DEFAULT ndec TO 0

   IF s_lReleaseBind
      s_lReleaseBind := .F.
      s_hplvars := {}
   ENDIF
   AAdd(s_hplVars, {Upper(cVarName), Upper(cOraType), nLen + 5, nDec, xInitValue,})

RETURN NIL

FUNCTION csplsql(nCursor, cPLSQL, aVarSust)
RETURN OraPLSQL(nCursor, cPLSQL, aVarSust)

FUNCTION OraPLSQL(nCursor, cPLSQL, aVarSust)

   LOCAL cBind
   LOCAL i
   LOCAL aItem
   LOCAL nerror
   LOCAL e
   LOCAL oSql

   s_lReleaseBind := .T.
   IF HB_IsArray(aVarSust)
      FOR i := Len(aVarSust) TO 1 STEP -1
         cBind := ":" + AllTrim(Str(i))
         cPLSQL := StrTran(cPLSQL, cBind, sr_cdbvalue(aVarSust[i]))
      NEXT i
   ENDIF
   IF Len(s_hplVars) > 0
      oSql := SR_GetConnection()
      oracleprePARE(osql:hdbc, cPLSQL)
      oraclebindalloc(oSql:hdbc, Len(s_hplVars))
      FOR i := 1 TO Len(s_hplVars)
         aItem := s_hplVars[i]
         IF aItem[2] == "VARCHAR" .OR. aItem[2] == "CHAR" .OR. aItem[2] == "VARCHAR2"
            OracleinBindParam(oSql:hdbc, i, -1, aItem[3], , aItem[5])
         ELSEIF aItem[2] == "NUMBER"
            IF aItem[4] > 0
               OracleinBindParam(oSql:hdbc, i, 4, 12, , aItem[5])
            ELSE
               OracleinBindParam(oSql:hdbc, i, 2, 12, , aItem[5])
            ENDIF
         ELSEIF aItem[2] == "DATE" .OR. aItem[2] == "DATA"
            OracleinBindParam(oSql:hdbc, i, 8, 12, , aItem[5])
         ENDIF
      NEXT i
      BEGIN SEQUENCE WITH __BreakBlock()
         nError := OracleExecDir(osql:hDbc)
         s_aOraClipCursors[nCursor]["error"] := nError
         s_aOraClipCursors[nCursor]["lastsql"] := cPlSql
         s_nlasterror := 0
      RECOVER USING e
         nerror := -1
         s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
         s_aOraClipCursors[nCursor]["lastsql"] := ""
         s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      END SEQUENCE
      IF nerror >= 0
         FOR i := 1 TO Len(s_hplVars)
            s_hplVars[i, 6] := ORACLEGETBINDDATA(osql:hdbc, i)
         NEXT i
      ENDIF
      ORACLEFREEBIND(osql:hdbc)
   ENDIF

RETURN nError

FUNCTION csgetvar(c)
RETURN oragetvar(c)

FUNCTION oragetvar(c)

   LOCAL nPos

   nPos := AScan(s_hplVars, {|x|AllTrim(Upper(x[1])) == AllTrim(Upper(c))})
   IF nPos > 0
      RETURN s_hplVars[nPos, 6]
   ENDIF
   s_lReleaseBind := .T.

RETURN ""

FUNCTION oraclose(n)
RETURN NIL

FUNCTION OraResetBind()

   s_hplVars := {}

RETURN NIL

FUNCTION OCTBROWSEDB(a, s, d, f)
RETURN tbrowsedb(a, s, d, f)

FUNCTION csxerror()
RETURN SR_GetConnection():nretcode

FUNCTION csxerrmsg()
RETURN SQLO_GETERRORCODE(SR_GetConnection():hDBC)

FUNCTION CSXCLEARFILTER()

   (Alias())->(sr_setfilter())

RETURN NIL

FUNCTION CSXsetFILTER(a)

   LOCAL cFilter

   IF Len(a) == 1
      (Alias())->(sr_setfilter(a[1]))
   ELSEIF Len(a) == 2
      cFilter := StrTran(a[1], ":1", sr_cdbvalue(a[2]))
      (Alias())->(sr_setfilter(a[1]))
   ENDIF

RETURN NIL

FUNCTION orarowid()
RETURN (Alias())->(RecNo())

FUNCTION csxrowid()
RETURN (Alias())->(RecNo())

FUNCTION csx()
RETURN NIL

FUNCTION CSOPENTMP(n, ncursor)
RETURN OraOpentmp(n, @ncursor)

FUNCTION OraOpentmp(n, ncursor)

   nCursor := s_nIdCursor
   s_aOraclipHash[n] := hb_hash()
   s_aOraclipHash[n][s_nIdCursor] := hb_hash()
   s_aOraClipCursors[s_nIdCursor] := hb_hash()
   s_aOraClipCursors[s_nIdCursor]["cursoropen"] := .F.
   ++s_nIdCursor

RETURN 0

FUNCTION CSCLOSETMP(n)
RETURN oraclosetmp(n)

FUNCTION oraclosetmp(n)

   closecursor(n)
   hdel(s_aOraClipCursors, n)
   --s_nIdCursor

RETURN NIL

// culik 8/12/2012 adicionado funcoes nao existente

FUNCTION OraMax(nCursor, cTable, cColumn, cWhere, aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL i
   LOCAL cwhere1
   LOCAL cBind

   IF PCount() < 3
      RETURN NIL
   ENDIF
   cSql := "select max( " +cColumn + " ) from " +cTable

   IF PCount() == 4
      cSql +=  " where " + cwhere
   ELSEIF PCount() == 5
      FOR i := 1 TO Len(aVarSust)
         cBind := ":" + AllTrim(Str(i))
         cwhere := StrTran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
      NEXT i
      cSql += " where " +  cwhere
   ENDIF

   nErro := SR_GetConnection():Exec(cSql, , .T., @aret)

   IF nErro == 0
      s_aOraClipCursors[nCursor]["error"] := 0
      s_aOraClipCursors[nCurSor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_nlasterror := 0
      RETURN aRet[1, 1]
   ELSE
      s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := 0
   ENDIF

RETURN NIL

FUNCTION OraSelect(n, aret, csql, adata, nRows)

   //LOCAL oSql := SR_GetConnection()
   LOCAL nError
   LOCAL i
   LOCAL e
   LOCAL cBind := ""
   LOCAL aTemp := {}
   LOCAL aDataRet := {}
   LOCAL nPosm
   LOCAL cursor

   dEFAULT nRows TO -1
   closecursor(n)
   s_aOraClipCursors[n]["cursoropen"] := .F.
   IF adata == NIL
      //IF nrows > F.
      //ELSE
      //nError := SR_GetConnection():Exec(csql, , .T., @aret)
      //ENDIF
      //comentada linha sandro, desnecessario neste ponto, existe abaixo
      //s_aOraClipCursors[n]["ret"] := aret
      //velho
      nError := ExecuteSql(csql, @cursor, n) // SR_GetConnection():Exec(csql, , .T., @aret)
      IF nError == 0
         s_aOraClipCursors[n]["cursoropen"] := .T.
         s_aOraClipCursors[n]["cursor"] := cursor
         s_aOraClipCursors[n]["start"] := 1
         s_aOraClipCursors[n]["len"] := 0
         s_aOraClipCursors[n]["curpos"] := 1
         s_aOraClipCursors[n]["error"] := 0
         s_aOraClipCursors[n]["nrowread"] := -1
         s_aOraClipCursors[n]["lastsql"] := cSql
         s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
         s_aOraClipCursors[n]["aFields"] := SR_GetConnection():IniFields(.F.) //aFields
         s_aOraClipCursors[n]["data"] := {}
         s_aOraClipCursors[n]["completed"] := .F.
         s_aOraClipCursors[n]["eof"] := .F.
         IF nRows > -1
            FOR nPos := 1 TO nRows
               OraFetchSelect(n)
               IF Len(s_aOraClipCursors[n]["data"]) > 0
                  AAdd(aRet, s_aOraClipCursors[n]["data"])
               ENDIF
            NEXT nPos
         ELSE
            DO WHILE OraFetchSelect(n) == 0
               AAdd(aRet, s_aOraClipCursors[n]["data"])
            ENDDO
         ENDIF

         //IF nError == 0
         //
         //   s_aOraClipCursors[n]["start"] := 1
         //   s_aOraClipCursors[n]["len"] := Len(aret)
         //   s_aOraClipCursors[n]["curpos"] := 0
         //   s_aOraClipCursors[n]["error"] := 0
         //   s_aOraClipCursors[n]["nrowread"] := nRows
         //
         //   s_aOraClipCursors[n]["ret"] := aret
         //   s_aOraClipCursors[n]["lastsql"] := cSql
         //   s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
         //   s_aOraClipCursors[n]["aFields"] := SR_GetConnection():aFields
         //   s_nlasterror := 0
         //   IF nRows > -1
         //      FOR EACH aTemp IN aRet
         //         AAdd(aDataRet, aTemp)
         //         IF aTemp:__enumindex() == nRows
         //            EXIT
         //         ENDIF
         //      NEXT
         //      s_aOraClipCursors[n]["curpos"] := Len(aDataRet) + 1
         //      aRet := aDataRet
         //   ENDIF
      ELSE
         s_aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
         s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
         s_aOraClipCursors[n]["lastsql"] := cSql
         s_aOraClipCursors[n]["rowaffected"] := 0
         s_aOraClipCursors[n]["aFields"] := {}
      ENDIF
      RETURN nError
   ENDIF

   FOR i := Len(aData) TO 1 STEP -1
      cBind := ":" + AllTrim(Str(i))
      cSql := StrTran(cSql, cBind, sr_cdbvalue(adata[i]))
   NEXT i
   nError := ExecuteSql(csql, @cursor, n) // SR_GetConnection():Exec(csql, , .T., @aret)
   IF nError == 0
      s_aOraClipCursors[n]["cursoropen"] := .T.
      s_aOraClipCursors[n]["cursor"] := cursor
      s_aOraClipCursors[n]["start"] := 1
      s_aOraClipCursors[n]["len"] := 0
      s_aOraClipCursors[n]["curpos"] := 1
      s_aOraClipCursors[n]["error"] := 0
      s_aOraClipCursors[n]["nrowread"] := -1
      s_aOraClipCursors[n]["lastsql"] := cSql
      s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_aOraClipCursors[n]["aFields"] := SR_GetConnection():IniFields(.F.) //aFields
      s_aOraClipCursors[n]["data"] := {}
      s_aOraClipCursors[n]["completed"] := .F.
      s_aOraClipCursors[n]["eof"] := .F.
      IF nRows > -1
         FOR nPos := 1 TO nRows
            OraFetchSelect(n)
            IF Len(s_aOraClipCursors[n]["data"]) > 0
               AAdd(aRet, s_aOraClipCursors[n]["data"])
            ENDIF
         NEXT nPos
      ELSE
         DO WHILE OraFetchSelect(n) == 0
            AAdd(aRet, s_aOraClipCursors[n]["data"])
         ENDDO
      ENDIF

//    nError := SR_GetConnection():Exec(csql, , .T., @aret)
//    s_aOraClipCursors[n]["ret"] := aret
//velho
//    IF nError == 0
//
//       s_aOraClipCursors[n]["start"] := 1
//       s_aOraClipCursors[n]["len"] := Len(aret)
//       s_aOraClipCursors[n]["curpos"] := 0
//       s_aOraClipCursors[n]["error"] := 0
//       s_aOraClipCursors[n]["nrowread"] := nRows
//       s_aOraClipCursors[n]["lastsql"] := cSql
//       s_aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
//       s_aOraClipCursors[n]["aFields"] := SR_GetConnection():aFields
//       s_nlasterror := 0
//       IF nRows > -1
//          FOR EACH aTemp IN aRet
//             AAdd(aDataRet, aTemp)
//             IF aTemp:__enumindex() == nRows
//                EXIT
//             ENDIF
//          NEXT
//          aRet := aDataRet
//          s_aOraClipCursors[n]["curpos"] := Len(aDataRet) + 1
//       ENDIF
//
   ELSE
      s_aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[n]["lastsql"] := ""
      s_aOraClipCursors[n]["rowaffected"] := 0
      s_aOraClipCursors[n]["aFields"] := {}
   ENDIF

RETURN nError

FUNCTION OraUpdIns(nCursor, cTable, aCols, aDataUpd, aDataIns, cWhere, aVarSust)

   LOCAL nRet
   LOCAL nPos
   LOCAL aret

   IF OraCount(nCursor, cTable, cWhere, aVarSust) > 0
      OraUpdate(nCursor, cTable, aCols, aDataUpd, cWhere, aVarSust)
   ELSE
      RETURN OraInsert(nCursor, cTable, aCols, aDataIns)
   ENDIF

RETURN nRet

#if 0
FUNCTION OraUpdIns(nCursor, cTable, aCols, aDataUpd, aDataIns, cWhere, aVarSust)

   LOCAL nRet
   LOCAL nPos

   nRet := OraUpdate(nCursor, cTable, aCols, aDataUpd, cWhere, aVarSust)
   IF nRet == -1
      RETURN OraInsert(nCursor, cTable, aCols, aDataIns)
   ENDIF

RETURN nRet
#endif

FUNCTION Orasum(nCursor, cTable, cColumn , cWhere , aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL cBind
   LOCAL i

   IF PCount() < 3
      RETURN NIL
   ENDIF
   cSql := "select sum( " +cColumn + " ) from " +cTable

   IF PCount() == 4
      cSql +=  " where " + cwhere
   ELSEIF PCount() == 5
      FOR i := 1 TO Len(aVarSust)
         cBind := ":" + AllTrim(Str(i))
         cwhere := StrTran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
      NEXT i
      cSql += " where " +  cwhere
   ENDIF

   nErro := SR_GetConnection():Exec(cSql, , .T., @aret)

   IF nErro == 0
      s_aOraClipCursors[nCursor]["error"] := 0
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_nlasterror := 0
      RETURN aRet[1, 1]
   ELSE
      s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := 0
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
   ENDIF

RETURN NIL

FUNCTION csxBegin()

   LOCAL oCnn

   SR_BeginTransaction()
   oCnn := SR_GetConnection()

RETURN IIf(oCnn:nTransacCount > 0, 0, -1)

FUNCTION CSXCOMMIT()

   sr_committransaction()

RETURN 0

FUNCTION CSXROLLBACK()

   sr_rollbacktransaction()

RETURN 0

FUNCTION CSINTRANS()
RETURN SR_TransactionCount() > 0

FUNCTION OraSelNext(nCursor, aTableData, nRows)

   LOCAL hData
   LOCAL e
   LOCAL nRet := 0
   LOCAL aRet
   LOCAL aDataRet := {}
   LOCAL nPos
   LOCAL nStart
   LOCAL nEnd
   LOCAL ii

   DEFAULT nRows TO -1

   BEGIN SEQUENCE WITH __BreakBlock()
      IF s_aOraClipCursors[nCursor]["completed"]
         s_aOraClipCursors[nCursor]["data"] := {}
         aTableData := {}
      ELSE
         s_aOraClipCursors[nCursor]["data"] := {}
         IF nRows > -1
            FOR nPos := 1 TO nRows
               OraFetchSelect(nCursor)
               IF Len(s_aOraClipCursors[nCursor]["data"]) > 0
                  AAdd(aDataRet, s_aOraClipCursors[nCursor]["data"])
               ENDIF
            NEXT nPos
         ELSE
            DO WHILE OraFetchSelect(nCursor) == 0
               IF Len(s_aOraClipCursors[nCursor]["data"]) > 0
                  AAdd(aDataRet, s_aOraClipCursors[nCursor]["data"])
               ENDIF
            ENDDO
         ENDIF
         aTableData := aDataRet
      ENDIF
      //
      //hData := s_aOraClipCursors[nCursor]
      //IF Len(hData["ret"]) > 0
      //   aRet := hData["ret"]
      //   nStart := hData["curpos"]
      //
      //   IF nRows == -1
      //      DO WHILE nStart <= Len(aRet)
      //         AAdd(aDataRet, aRet[nStart])
      //         nStart ++
      //      ENDDO
      //      aTableData := aDataRet
      //      s_aOraClipCursors[nCursor]["curpos"] := Len(aRet) + 1
      //
      //   ELSE
      //
      //      nEnd := hData["curpos"] + nRows
      //      ii := 0
      //      FOR nPos := nStart TO nEnd
      //         AAdd(aDataRet, aRet[nStart])
      //         ii++
      //         IF ii == nRows
      //            EXIT
      //         ENDIF
      //      NEXT nPos
      //      aTableData := aDataRet
      //      s_aOraClipCursors[nCursor]["curpos"] := nEnd + 1
      //   ENDIF
      //
      //ENDIF
   RECOVER USING e
      nRet := -1
   END SEQUENCE

RETURN nRet

FUNCTION csExecSQL(nCursor, cSQL, aVarSust)

   LOCAL nRet
   LOCAL hData
   LOCAL oSql
   LOCAL cBind
   LOCAL i
   LOCAL aItem
   LOCAL nerror

   BEGIN SEQUENCE WITH __BreakBlock()
      hData := s_aOraClipCursors[nCursor]
      osql := SR_GetConnection()
      IF Upper(SubStr(cSql, 6)) == "BEGIN "
         IF PCount() == 3
            IF HB_IsArray(aVarSust)
               FOR i := Len(aVarSust) TO 1 STEP -1
                  cBind := ":" + AllTrim(Str(i) )
                  cSQL := StrTran(cSQL, cBind, sr_cdbvalue(aVarSust[i]))
               NEXT i
            ENDIF
         ENDIF
         oracleprePARE(osql:hdbc, cSQL)
         nRet := OracleExecDir(osql:hDbc)
         s_nlasterror := 0
         s_aOraClipCursors[nCursor]["errormsg"] := ""
         IF nRet == 0
            s_aOraClipCursors[nCursor]["error"] := 0
            s_aOraClipCursors[nCursor]["lastsql"] := cSql
            s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
         ELSE
            s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
            s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
            s_aOraClipCursors[nCursor]["errormsg"] := SQLO_GETERRORDESCR(osql:hDBC)
            s_aOraClipCursors[nCursor]["lastsql"] := ""
            s_aOraClipCursors[ncursor]["rowaffected"] := 0
         ENDIF
      ELSE
         nRet := osql:Exec(cSql, , .F.)
         s_nlasterror := 0
         s_aOraClipCursors[nCursor]["errormsg"] := ""
         IF nRet == 0
            s_aOraClipCursors[nCursor]["error"] := 0
            s_aOraClipCursors[nCursor]["lastsql"] := cSql
            s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
         ELSE
            s_aOraClipCursors[nCursor]["error"] := osql:lasterror()
            s_aOraClipCursors[nCursor]["errormsg"] := SQLO_GETERRORDESCR(osql:hDBC)
            s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
            s_aOraClipCursors[nCursor]["lastsql"] := cSql
            s_aOraClipCursors[ncursor]["rowaffected"] := 0
         ENDIF
      ENDIF
   RECOVER USING e
      nret := -1
   END SEQUENCE

RETURN nRet

FUNCTION csErrMsg(nCursor)

   LOCAL nRet
   LOCAL hData
   LOCAL oSql
   LOCAL e
   LOCAL cRet := ""

   BEGIN SEQUENCE WITH __BreakBlock()
      hData := s_aOraClipCursors[nCursor]
      osql := SR_GetConnection()
      cRet :=  hData["errormsg"]
   RECOVER USING e
   END SEQUENCE

RETURN cRet

FUNCTION CSVALIDCNX(nCursor)

   LOCAL lRet := .F.
   LOCAL hData
   LOCAL oSql
   LOCAL e
   LOCAL cRet := ""

   BEGIN SEQUENCE WITH __BreakBlock()
      hData := s_aOraClipCursors[nCursor]
      osql := SR_GetConnection()
      lRet := hData["nRet"] > 0
   RECOVER USING e
      lRet := .F.
   END SEQUENCE

RETURN lRet

FUNCTION CSUSER(nCursor)

   LOCAL hData
   LOCAL oSql
   LOCAL e
   LOCAL cRet := ""

   BEGIN SEQUENCE WITH __BreakBlock()
      hData := s_aOraClipCursors[nCursor]
      osql := SR_GetConnection()
      cRet := hData["user"]
   RECOVER USING e
      cRet := ""
   END SEQUENCE

RETURN cRet

FUNCTION CSVALIDCURSOR(nCursor)

   LOCAL lRet
   LOCAL hDAta
   LOCAL e

   BEGIN SEQUENCE WITH __BreakBlock()
      hData := s_aOraClipCursors[nCursor]
      lRet := .T.
   RECOVER
      lRet := .F.
   END SEQUENCE

RETURN lRet

FUNCTION CSXSETRDD
RETURN NIL

FUNCTION OraExists(nCursor, cTable, cWhere, aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL i
   LOCAL cwhere1
   LOCAL cBind

   IF PCount() < 3
      RETURN NIL
   ENDIF
   cSql := "select * from " +cTable

   IF PCount() == 3
      cSql +=  " where " + cwhere
   ELSEIF PCount() == 4
      FOR i := 1 TO Len(aVarSust)
         cBind := ":" + AllTrim(Str(i))
         cwhere := StrTran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
      NEXT i
      cSql += " where " +  cwhere
   ENDIF
   nErro := SR_GetConnection():Exec(cSql, , .T., @aret)
   IF nErro == 0
      RETURN Len(aRet) > 0
   ENDIF

RETURN .F.

FUNCTION OraMin(nCursor, cTable, cColumn , cWhere , aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL cwhere1
   LOCAL cBind
   LOCAL i

   IF PCount() < 3
      RETURN NIL
   ENDIF
   cSql := "select mim( " +cColumn + " ) from " +cTable

   IF PCount() == 4
      cSql +=  " where " + cwhere
   ELSEIF PCount() == 5
      FOR i := Len(aVarSust) TO 1 STEP -1
         cBind := ":" + AllTrim(Str(i))
         cwhere := StrTran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
      NEXT i
      cSql += " where " +  cwhere
   ENDIF

   nErro := SR_GetConnection():Exec(cSql, , .T., @aret)

   IF nErro ==0
      s_aOraClipCursors[nCursor]["error"] := 0
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(SR_GetConnection():hdbc)
      s_nlasterror := 0
      RETURN aRet[1, 1]
   ELSE
      s_aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_nlasterror := SQLO_GETERRORCODE(SR_GetConnection():hDBC)
      s_aOraClipCursors[nCursor]["lastsql"] := cSql
      s_aOraClipCursors[ncursor]["rowaffected"] := 0
   ENDIF

RETURN NIL

#define _ORATBROWSE_EXIT             1
#define _ORATBROWSE_REFRESHALL       2
#define _ORATBROWSE_REFRESHCURRENT   3
#define _ORATBROWSE_METHOD           4
#define _ORATBROWSE_SEARCH           5
#define _ORATBROWSE_SEARCH_NEXT      6
#define _ORATBROWSE_FILTER           7
#define _ORATBROWSE_FILTER_BACK      8
#define _ORATBROWSE_FILTER_RESET     9
#define _ORATBROWSE_ORDER_BY        10
#define _ORATBROWSE_ORDER_RESET     11

FUNCTION OraTBrNew(nTop, nLeft, nBottom, nRight)
RETURN tbrowsedb(nTop, nLeft, nBottom, nRight)

#define COMPILE(cExp) &("{||"+cExp+"}")

FUNCTION OraColumnNew(cHeading, bBlock)
RETURN TBColumnNew(cHeading, COMPILE(bBlock))

FUNCTION OraTBrowse(nCursor1, cSql, c, oBrowse, bBLock)

   LOCAL cTempFile
   LOCAL aReg := {}
   LOCAL i
   LOCAL aRet := {}
   LOCAL lRet := .T.
   LOCAL nKey
   LOCAL oSql := SR_GetConnection()
   LOCAL oCol

   FClose(HB_FTEMPCREATEEX(@cTempFile, , "tmp", ".dbf"))

   osql:Exec(cSql, , .T., , cTempFile)

   DO WHILE lRet
      obrowse:forcestable()
      aReg := {}
      FOR i := 1 TO FCount()
         //AAdd(aReg, Eval(obrowse:GetColumn(i):Block))
         oCol := oBrowse:getcolumn(i)
         AAdd(aReg, FieldGet(i))
      NEXT i
      nKey := Inkey(0)
      aRet := Eval(bBLock, nkey, obrowse, aReg)
      IF Aret == NIL
         LOOP
      ENDIF
      SWITCH aRet[1]
      CASE _ORATBROWSE_METHOD
         oBrowse:applykey(nKey)
         EXIT
      CASE _ORATBROWSE_REFRESHALL
         ZAP
         osql:Exec(cSql, , .T., , cTempFile)
         GO TOP
         EXIT
      CASE  _ORATBROWSE_EXIT
        Ret := .F.
        EXIT
      ENDSWITCH
   ENDDO

RETURN 0

FUNCTION ORALASTSQL()
RETURN NIL

INIT FUNCTION OVERRIDESIZE

   OVERRIDE METHOD SQLLen IN CLASS SR_CONNECTION WITH MySQLLen

STATIC FUNCTION mySQLLen(nType, nLen, nDec)

   LOCAL cType := "U"
   LOCAL Self := QSelf()

   DEFAULT nDec TO -1

   SWITCH nType
   CASE SQL_CHAR
   CASE SQL_VARCHAR
   CASE SQL_NVARCHAR
      IF IIf(SR_SetNwgCompat(), nLen != 4000 .AND. nLen != 2000, .T.)
      ENDIF
      EXIT
   CASE SQL_SMALLINT
   CASE SQL_TINYINT
      IF ::lQueryOnly
         nLen := 10
      ELSE
         nLen := 1
      ENDIF
      EXIT
   CASE SQL_BIT
      nLen := 1
      EXIT
   CASE SQL_NUMERIC
   CASE SQL_DECIMAL
   CASE SQL_INTEGER
   CASE SQL_FLOAT
   CASE SQL_REAL
   CASE SQL_DOUBLE
      IF nLen > 19 .AND. nDec > 10 .AND. !(nLen = 38 .AND. nDec = 0)
         nLen := 20
         nDec := 6
      ENDIF
      IF nDec > 3 .AND. !(nLen = 38 .AND. nDec = 0)
         nLen := 14
      ENDIF
      IF !(nLen = 38 .AND. nDec = 0)
         nLen := Min(nLen, 20)
         nLen := Max(nLen, 1)
      ENDIF
      EXIT
   CASE SQL_DATE
   CASE SQL_TIMESTAMP
   CASE SQL_TYPE_TIMESTAMP
   CASE SQL_TYPE_DATE
   CASE SQL_DATETIME
      nLen := 8
      EXIT
   CASE SQL_TIME
      nLen := 8
      EXIT
   CASE SQL_LONGVARCHAR
   CASE SQL_LONGVARBINARY
   CASE SQL_FAKE_LOB
      nLen := 10
      EXIT
   CASE SQL_GUID
      nLen := 36
   ENDSWITCH

RETURN nLen

FUNCTION orarownum(nCursor)
RETURN s_aOraClipCursors[nCursor]["curpos"]

FUNCTION oraGoto(n, aDados, nRow)

   LOCAL nRet := 0
   LOCAL e

   DEFAULT aDados TO {}
   s_aOraClipCursors[n]["curpos"] := nRow
   BEGIN SEQUENCE WITH __BreakBlock()
      s_aOraClipCursors[n]["curpos"] := nRow
      aDados := s_aOraClipCursors[n]["ret"][s_aOraClipCursors[n]["curpos"]]
   RECOVER USING e
      nRet := -1
   END SEQUENCE

RETURN nRet

FUNCTION ORAROWCOUNT(nCursor)
RETURN s_aOraClipCursors[nCursor]["rowaffected"]

FUNCTION OraFName(n, nPos)

   LOCAL aTmp

   IF Len(s_aOraClipCursors[n]["aFields"]) == 0 .OR. nPos <= 0
      s_aOraClipCursors[n]["errormsg"] := "vetor vazio ou Posicao <= 0"
      RETURN NIL
   ENDIF
   IF Len(s_aOraClipCursors[n]["aFields"]) >1 .AND. nPos <= Len(s_aOraClipCursors[n]["aFields"])
      aTmp := s_aOraClipCursors[n]["aFields"]
      RETURN AllTrim(aTmp[nPos, 1])
   ENDIF

   s_aOraClipCursors[n]["errormsg"] := "Indice do campo invalido"

RETURN NIL

FUNCTION SR_AdjustNum(a)

   LOCAL b := AClone(a)
   LOCAL i
   LOCAL lNwgOldCompat := .F.

   FOR i := 1 TO Len(b)

      //IF lNwgOldCompat
      IF b[i, 2] = "N"
         b[i, 3] ++
      ENDIF
      //ENDIF

      IF b[i, 2] = "N" .AND. b[i, 3] > 18
         b[i, 3] := 19
      ENDIF

      IF lNwgOldCompat
         IF b[i, 2] = "N" .AND. b[i, 4] >= (b[i, 3] - 1)
            b[i, 4] := Abs(b[i, 3] - 2)
         ENDIF
      ENDIF
      IF b[i, 2] == "N" .AND. b[i, 4] >= 5
         b[i, 3] +=4
      ENDIF

      IF b[i, 2] = "M"
         b[i, 3] := 10
      ENDIF

   NEXT i

RETURN b

STATIC FUNCTION ExecuteSql(csql, cursor, n)

   // BEGIN SEQUENCE WITH __BreakBlock()
   //    nError := OraclePrepare(SR_GetConnection():hdbc, cSql, .T.)
   // RECOVER USING e
   //    nError := -1
   // END SEQUENCE
   // IF nError > 0
   nError := Sqlo_Execute(SR_GetConnection():hdbc, cSql)
   //nError := SR_GetConnection():executeraw(cSql)
   cursor := GETORAHANDLE(SR_GetConnection():hdbc)
   // ENDIF

RETURN nError

STATIC FUNCTION OraFetch(n)

   LOCAL oSql := SR_GetConnection()
   LOCAL hDBC := oSql:hdbc
   LOCAL nError
   LOCAL hDBCHandle := s_aOraClipCursors[n]["cursor"]
   LOCAL i
   LOCAL aArray
   LOCAL cCampo
   LOCAL cAlias := s_aOraClipCursors[n]["aliastmp"]
   LOCAL aDb

   SETORAHANDLE(hDBC, hDBCHandle)

   IF s_aOraClipCursors[n]["curpos"] <= (cAlias)->(RecCount()) .AND. s_aOraClipCursors[n]["curpos"] != 0
      (cAlias)->(DBGoTo(s_aOraClipCursors[n]["curpos"]))
   ELSEIF !s_aOraClipCursors[n]["completed"]

      nError := oSql:Fetch(, s_aOraClipCursors[n]["aFields"])

      s_aOraClipCursors[n]["eof"] := nError != 0
      s_aOraClipCursors[n]["data"] := {}
      IF nError == 0

         aArray := Array(Len(s_aOraClipCursors[n]["aFields"]))

         (cAlias)->(DBAppend())
         FOR i := 1 TO Len(s_aOraClipCursors[n]["aFields"])
            (cAlias)->(FieldPut(i, oSql:FieldGet(i, s_aOraClipCursors[n]["aFields"])))
         NEXT i
         (cAlias)->(DBUnlock())
      ELSE
         //FOR i := 1 TO Len(s_aOraClipCursors[n]["data"])
         aDb := s_aOraClipCursors[n]["aFields"]
         FOR i := 1 TO Len(aDb)
            SWITCH adb[i, 2]
            CASE "C"
               AAdd(s_aOraClipCursors[n]["data"], "")
               EXIT
            CASE "N"
               AAdd(s_aOraClipCursors[n]["data"], 0)
               EXIT
            CASE "D"
               AAdd(s_aOraClipCursors[n]["data"], CToD(""))
               EXIT
            CASE "L"
               AAdd(s_aOraClipCursors[n]["data"], .F.)
            ENDSWITCH
         NEXT i
         s_aOraClipCursors[n]["completed"] := .T.
         s_aOraClipCursors[n]["eof"] := .T.

         //oSql:FreeStatement()
         s_aOraClipCursors[n]["cursoropen"] := .F.
         SQLO_CLOSESTMT(hDBC)

         IF Select(s_aOraClipCursors[n]["aliastmp"]) > 0
            (s_aOraClipCursors[n]["aliastmp"])->(DBCloseArea())
            FErase(s_aOraClipCursors[n]["tmpfile"])
         ENDIF

      ENDIF

   ELSE
      (cAlias)->(DBGoTo(s_aOraClipCursors[n]["curpos"]))
   ENDIF
   IF Select(s_aOraClipCursors[n]["aliastmp"]) > 0
      FOR i := 1 TO Len(s_aOraClipCursors[n]["aFields"])
         AAdd(s_aOraClipCursors[n]["data"], (cAlias)->(FieldGet(i)))
      NEXT i
   ENDIF

RETURN nError

STATIC FUNCTION OraFetchSelect(n)

   LOCAL oSql := SR_GetConnection()
   LOCAL hDBC := oSql:hdbc
   LOCAL nError
   LOCAL hDBCHandle := s_aOraClipCursors[n]["cursor"]
   LOCAL i
   LOCAL aArray
   LOCAL cCampo
   LOCAL aret := {}

   SETORAHANDLE(hDBC, hDBCHandle)

   nError := oSql:Fetch()

   s_aOraClipCursors[n]["eof"] := nError != 0

   IF nError == 0

      s_aOraClipCursors[n]["data"] := {}

      aArray := Array(Len(s_aOraClipCursors[n]["aFields"]))

      FOR i := 1 TO Len(s_aOraClipCursors[n]["aFields"])
         AAdd(s_aOraClipCursors[n]["data"], oSql:FieldGet(i, s_aOraClipCursors[n]["aFields"]) )
      NEXT i

   ELSE

      s_aOraClipCursors[n]["completed"] := .T.
      s_aOraClipCursors[n]["cursoropen"] := .F.
      //oSql:FreeStatement()
      SQLO_CLOSESTMT(hDBC)

  ENDIF

RETURN nError

STATIC FUNCTION GerGhost(uDat)

   IF HB_IsChar(uDat)
      RETURN ""
   ELSEIF HB_IsNumeric(uDat)
      RETURN 0
   ELSEIF HB_IsLogical(uDat)
      RETURN .F.
   ELSEIF HB_IsDate(uDat)
      RETURN CToD("")
   ENDIF

RETURN ""

FUNCTION getOraclipCursor(ncursor)
RETURN s_aOraClipCursors[ncursor]

STATIC FUNCTION closecursor(n)

   LOCAL osql := SR_GetConnection()
   LOCAL hdbc := osql:hdbc

   BEGIN SEQUENCE WITH __BreakBlock()
      hDBCHandle := s_aOraClipCursors[n]["cursor"]
      IF s_aOraClipCursors[n]["cursoropen"]
         SETORAHANDLE(hDBC, hDBCHandle)
         //oSql:FreeStatement() // fecha o cursor antes da tabela
         SQLO_CLOSESTMT(hDBC)
         s_aOraClipCursors[n]["cursoropen"] := .F.
      ENDIF
      IF Select(s_aOraClipCursors[n]["aliastmp"]) > 0
         (s_aOraClipCursors[n]["aliastmp"])->(DBCloseArea())
         FErase(s_aOraClipCursors[n]["tmpfile"])
      ENDIF
   RECOVER USING e
   END SEQUENCE

RETURN NIL

#pragma BEGINDUMP

#include <hbapi.h>
#include <hbapiitm.h>

typedef int sqlo_stmt_handle_t;

typedef struct _ORA_BIND_COLS
{
  char *col_name;
  short sVal;
  double dValue;
  int iType;
  ULONG ulValue;
  char sDate[7];
  int iValue;
  char sValue[31];
  // OCIRowId *RowId;
} ORA_BIND_COLS;

typedef struct _OCI_SESSION
{
  int dbh;                      // Connection handler
  int stmt;                     // Current statement handler
  int status;                   // Execution return value
  int numcols;                  // Result set columns
  char server_version[128];
  // bellow for bind vars
  sqlo_stmt_handle_t stmtParam;
  ORA_BIND_COLS *pLink;
  unsigned int ubBindNum;
  sqlo_stmt_handle_t stmtParamRes;
  unsigned int uRows;
} OCI_SESSION;

typedef OCI_SESSION * POCI_SESSION;

HB_FUNC(GETORAHANDLE)
{
  OCI_SESSION *p = (OCI_SESSION *)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

  if (p)
  {
    hb_retni(p->stmt);
  }
}

HB_FUNC(SETORAHANDLE)
{
  OCI_SESSION *p  = (OCI_SESSION *)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

  if (p)
  {
    p->stmt = hb_parni(2);
  }
}

#pragma ENDDUMP
