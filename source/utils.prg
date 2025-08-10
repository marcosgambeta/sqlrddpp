//
// SQLRDD Utilities
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
#include <fileio.ch>
#include "msg.ch"
#include <error.ch>
#include "sqlrddsetup.ch"

#define SR_CRLF   (Chr(13) + Chr(10))

REQUEST HB_Deserialize
//REQUEST HB_DeserialNext
#define FH_ALLOC_BLOCK     32

Static s_DtAtiv, s_lHistorico
Static s__nCnt := 1
Static s_lCreateAsHistoric := .F.

#ifdef HB_C52_UNDOC
STATIC s_lNoAlert
#endif

//------------------------------------------------------------------------

FUNCTION SR_GoPhantom()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):sqlGoPhantom()
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_WorkareaFileName()

   IF Empty(Alias())
      RETURN ""
   ENDIF

   IF !IS_SQLRDD
      RETURN ""
   ENDIF

RETURN dbInfo(DBI_INTERNAL_OBJECT):cFileName

//------------------------------------------------------------------------

FUNCTION SR_dbStruct()

   IF Empty(Alias())
      RETURN {}
   ENDIF

   IF !IS_SQLRDD
      RETURN {}
   ENDIF

RETURN AClone(dbInfo(DBI_INTERNAL_OBJECT):aFields)

//------------------------------------------------------------------------

FUNCTION SR_MsgLogFile(uMsg, p1, p2, p3, p4, p5, p6, p7, p8)
   SR_LogFile("sqlerror.log", {uMsg, p1, p2, p3, p4, p5, p6, p7, p8})
RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_Val2Char(a, n1, n2)

   SWITCH ValType(a)
   CASE "C"
   CASE "M"
      RETURN a
   CASE "N"
      IF n1 != NIL .AND. n2 != NIL
         RETURN Str(a, n1, n2)
      ENDIF
      RETURN Str(a)
   CASE "D"
      RETURN DToC(a)
   CASE "L"
      RETURN IIf(a, ".T.", ".F.")
   ENDSWITCH

RETURN ""

//------------------------------------------------------------------------

FUNCTION SR_LogFile(cFileName, aInfo, lAddDateTime)

   LOCAL hFile
   LOCAL cLine
   LOCAL n

   Default lAddDatetime TO .T.

   IF lAddDateTime

      cLine := DToC(Date()) + " " + Time() + ": "

   ELSE

      cLine := ""

   ENDIF

   FOR n := 1 TO Len(aInfo)
      IF aInfo[n] == NIL
         Exit
      ENDIF
      cLine += SR_Val2CharQ(aInfo[n]) + Chr(9)
   NEXT n

   cLine += SR_CRLF

   IF sr_phFile(cFileName)
      hFile := FOpen(cFileName, 1)
   ELSE
      hFile := FCreate(cFileName)
   ENDIF

   FSeek(hFile, 0, 2)
   FWrite(hFile, AllTrim(cLine))
   FClose(hFile)

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_FilterStatus(lEnable)

   IF IS_SQLRDD
      IF HB_IsLogical(lEnable) 
         RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lDisableFlts := !lEnable
      ELSE
         RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lDisableFlts
      ENDIF
   ENDIF

RETURN .F.

//------------------------------------------------------------------------

FUNCTION SR_CreateConstraint(aSourceColumns, cTargetTable, aTargetColumns, cConstraintName)

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):CreateConstraint(dbInfo(DBI_INTERNAL_OBJECT):cFileName, aSourceColumns, cTargetTable, aTargetColumns, cConstraintName)
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_DropConstraint(cConstraintName, lFKs)

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):DropConstraint(dbInfo(DBI_INTERNAL_OBJECT):cFileName, cConstraintName, lFKs)
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_ChangeStruct(cTableName, aNewStruct)

   LOCAL oWA
   LOCAL lOk := .T.
   LOCAL aToDrop := {}
   LOCAL aToFix := {}
   LOCAL i
   LOCAL n
   LOCAL cAlias
   LOCAL nReg
   LOCAL cTblName
   LOCAL nAlias
   LOCAL nOrd
   LOCAL aDirect := {}

   IF Select() == 0
      SR_RuntimeErr(, "SR_ChengeStructure: Workarea not in use.")
   ENDIF

   IF Len(aNewStruct) < 1 .OR. !HB_IsArray(aNewStruct) .OR. !HB_IsArray(aNewStruct[1])
      SR_RuntimeErr(, "SR_ChengeStructure: Invalid arguments [2].")
   ENDIF

   IF IS_SQLRDD

      oWA := dbInfo(DBI_INTERNAL_OBJECT)

      IF (!Empty(cTableName)) .AND. oWA:cOriginalFN != Upper(AllTrim(cTableName))
         SR_RuntimeErr(, "SR_ChengeStructure: Invalid arguments [1]: " + cTableName)
      ENDIF

      cAlias := Alias()
      nAlias := Select()
      cTblName := oWA:cFileName
      nOrd := IndexOrd()
      nReg := RecNo()

      DBSetOrder(0)

      SR_LogFile("changestruct.log", {oWA:cFileName, "Original Structure:", e"\r\n" + sr_showVector(oWA:aFields)})
      SR_LogFile("changestruct.log", {oWA:cFileName, "New Structure:", e"\r\n" + sr_showVector(aNewStruct)})

      FOR i := 1 TO Len(aNewStruct)
         aNewStruct[i, 1] := Upper(AllTrim(aNewStruct[i, 1]))
         IF (n := AScan(oWA:aFields, {|x|x[1] == aNewStruct[i, 1]})) > 0

            ASize(aNewStruct[i], Max(Len(aNewStruct[i]), 5))

            IF aNewStruct[i, 2] == oWA:aFields[n, 2] .AND. aNewStruct[i, 3] == oWA:aFields[n, 3] .AND. aNewStruct[i, 4] == oWA:aFields[n, 4]
               // Structure is identical. Only need to check for NOT NULL flag.
               IF aNewStruct[i, FIELD_NULLABLE] != NIL .AND. aNewStruct[i, FIELD_NULLABLE] !=  oWA:aFields[n, FIELD_NULLABLE]
                  IF aNewStruct[i, FIELD_NULLABLE]
                     SR_LogFile("changestruct.log", {oWA:cFileName, "Changing to nullable:", aNewStruct[i, 1]})
                     oWA:DropRuleNotNull(aNewStruct[i, 1])
                  ELSE
                     SR_LogFile("changestruct.log", {oWA:cFileName, "Changing to not null:", aNewStruct[i, 1]})
                     oWA:AddRuleNotNull(aNewStruct[i, 1])
                  ENDIF
               ENDIF
            ELSEIF oWA:oSql:nSystemID == SYSTEMID_IBMDB2
               SR_LogFile("changestruct.log", {oWA:cFileName, "Column cannot be changed:", aNewStruct[i, 1], " - Operation not supported by back end database"})
            ELSEIF aNewStruct[i, 2] == "M" .AND. oWA:aFields[n, 2] == "C"
               AAdd(aToFix, AClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Will Change data type of field:", aNewStruct[i, 1], "from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
            ELSEIF aNewStruct[i, 2] == "C" .AND. oWA:aFields[n, 2] == "M"
               AAdd(aToFix, AClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Warning: Possible data loss changing data type:", aNewStruct[i, 1], "from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
            ELSEIF aNewStruct[i, 2] != oWA:aFields[n, 2]
               IF aNewStruct[i, 2] $"CN" .AND. oWA:aFields[n, 2] $"CN" .AND. oWA:oSql:nSystemID == SYSTEMID_POSTGR

*                   IF "8.4" $ oWA:oSql:cSystemVers .OR. "9.0" $ oWA:oSql:cSystemVers
                  IF oWA:oSql:lPostgresql8 .AND. !oWA:oSql:lPostgresql83
                     AAdd(aDirect, AClone(aNewStruct[i]))
                  ELSE
                     AAdd(aToFix, AClone(aNewStruct[i]))
                  ENDIF
                  SR_LogFile("changestruct.log", {oWA:cFileName, "Warning: Possible data loss changing field types:", aNewStruct[i, 1], "from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
               ELSE
                  SR_LogFile("changestruct.log", {oWA:cFileName, "ERROR: Cannot convert data type of field:", aNewStruct[i, 1], " from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
               ENDIF
            ELSEIF aNewStruct[i, 3] >= oWA:aFields[n, 3] .AND. oWA:aFields[n, 2] $ "CN"

               AAdd(aDirect, AClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Will Change field size:", aNewStruct[i, 1], "from", oWA:aFields[n, 3], "to", aNewStruct[i, 3]})
            ELSEIF aNewStruct[i, 3] < oWA:aFields[n, 3] .AND. oWA:aFields[n, 2] $ "CN"
               AAdd(aToFix, AClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Warning: Possible data loss changing field size:", aNewStruct[i, 1], "from", oWA:aFields[n, 3], "to", aNewStruct[i, 3]})
            ELSE
               SR_LogFile("changestruct.log", {oWA:cFileName, "Column cannot be changed:", aNewStruct[i, 1]})
            ENDIF
         ELSE
            AAdd(aToFix, AClone(aNewStruct[i]))
            SR_LogFile("changestruct.log", {oWA:cFileName, "Will add column:", aNewStruct[i, 1]})
         ENDIF
      NEXT i

      FOR i := 1 TO Len(oWA:aFields)
         IF (n := AScan(aNewStruct, {|x|x[1] == oWA:aFields[i, 1]})) == 0
            IF (!oWA:aFields[i, 1] == oWA:cRecnoName) .AND. (!oWA:aFields[i, 1] == oWA:cDeletedName) .AND. oWA:oSql:nSystemID != SYSTEMID_IBMDB2
               AAdd(aToDrop, AClone(oWA:aFields[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Will drop:", oWA:aFields[i, 1]})
            ENDIF
         ENDIF
         HB_SYMBOL_UNUSED(n)
      NEXT i
      IF Len(aDirect) > 0 .AND. ( ;
              oWA:oSql:nSystemID == SYSTEMID_FIREBR ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_FIREBR3 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_FIREBR4 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_FIREBR5 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MYSQL ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MARIADB ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_ORACLE ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MSSQL6 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MSSQL7 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_CACHE ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_POSTGR)
         oWA:AlterColumnsDirect(aDirect, .T., .F., @aTofix)
      ENDIF

      IF Len(aToFix) > 0
         oWA:AlterColumns(aToFix, .T.)
      ENDIF

      FOR i := 1 TO Len(aToDrop)
         IF aToDrop[i, 1] == "BACKUP_"
            oWA:DropColumn(aToDrop[i, 1], .F.)
         ELSE
            oWA:DropColumn(aToDrop[i, 1], .T.)
         ENDIF
      NEXT i

      SELECT (nALias)
      DBCloseArea()

      SR_CleanTabInfoCache()

      // recover table status

      SELECT (nAlias)
      DBUseArea(.F., "SQLRDD", cTblName, cAlias)
      IF OrdCount() >= nOrd
         DBSetOrder(nOrd)
      ENDIF
      DBGoTo(nReg)

   ELSE
      SR_RuntimeErr(, "SR_ChengeStructure: Not a SQLRDD workarea.")
   ENDIF

RETURN lOk

//------------------------------------------------------------------------

FUNCTION SR_SetCurrDate(d)

   IF IS_SQLRDD
      d := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetCurrDate(d)
      IF d == NIL
         d := SR_GetActiveDt()
      ENDIF
   ENDIF

RETURN d

//------------------------------------------------------------------------

FUNCTION SR_QuickAppend(l)

   IF IS_SQLRDD
      l := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetQuickAppend(l)
   ENDIF

RETURN l

//------------------------------------------------------------------------

FUNCTION SR_SetColPK(cColName)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetColPK(cColName)
      IF cColName == NIL
         cColName := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):cColPK
      ENDIF
   ENDIF

RETURN cColName

//------------------------------------------------------------------------

FUNCTION SR_IsWAHist()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lHistoric
   ENDIF

RETURN .F.

//------------------------------------------------------------------------

FUNCTION SR_SetReverseIndex(nIndex, lSet)

   LOCAL lOldSet

   IF IS_SQLRDD .AND. nIndex > 0 .AND. nIndex <= Len((Select())->(dbInfo(DBI_INTERNAL_OBJECT)):aIndex)
      lOldSet := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):aIndex[nIndex, DESCEND_INDEX_ORDER]
      IF HB_IsLogical(lSet)
         (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):aIndex[nIndex, DESCEND_INDEX_ORDER] := lSet
      ENDIF
   ENDIF

RETURN lOldSet

//------------------------------------------------------------------------

FUNCTION SR_SetNextDt(d)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetNextDt(d)
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_DisableHistoric()

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):DisableHistoric()
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):Refresh()
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_EnableHistoric()

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):EnableHistoric()
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):Refresh()
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_GetActiveDt()

RETURN s_DtAtiv

//------------------------------------------------------------------------

FUNCTION SR_SetActiveDt(d)

   DEFAULT d TO Date()

RETURN s_DtAtiv := d

//------------------------------------------------------------------------

FUNCTION SR_SetActiveDate(d)

   LOCAL dOld := s_DtAtiv

   IF d != NIL
      s_DtAtiv := d
   ENDIF

RETURN dOld

//------------------------------------------------------------------------

Init Procedure SR_IniDtAtiv()

   s_DtAtiv := Date()

Return

//------------------------------------------------------------------------

FUNCTION SR_SetCreateAsHistoric(l)

   LOCAL lOld := s_lCreateAsHistoric
   
   HB_SYMBOL_UNUSED(lOld)

   IF HB_IsLogical(l) 
      s_lCreateAsHistoric := l
   ENDIF

RETURN s_lCreateAsHistoric

//------------------------------------------------------------------------

FUNCTION SR_HasHistoric()

RETURN (s_lHistorico := .T.)

//------------------------------------------------------------------------

FUNCTION SR_cDBValue(uData, nSystemID)

   default nSystemID TO SR_GetConnection():nSystemID

RETURN SR_SubQuoted(ValType(uData), uData, nSystemID)

//------------------------------------------------------------------------

STATIC FUNCTION SR_SubQuoted(cType, uData, nSystemID)

   LOCAL cRet
   LOCAL cOldSet := SET(_SET_DATEFORMAT)

#if 0 // TODO: old code for reference (to be deleted)
   Do Case
   Case cType $ "CM" .AND. nSystemID == SYSTEMID_ORACLE
      RETURN "'" + RTrim(StrTran(uData, "'", "'||" + "CHR(39)" + "||'")) + "'"
   Case cType $ "CM" .AND. nSystemID == SYSTEMID_MSSQL7
      RETURN "'" + RTrim(StrTran(uData, "'", "'" + "'")) + "'"
   Case cType $ "CM" .AND. nSystemID == SYSTEMID_POSTGR
      RETURN "E'" + StrTran(RTrim(StrTran(uData, "'", "'" + "'")), "\", "\\") + "'"
   Case cType $ "CM"
      RETURN "'" + RTrim(StrTran(uData, "'", "")) + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_ORACLE
      RETURN "TO_DATE('" + RTrim(DToS(uData)) + "','YYYYMMDD')"
   Case cType == "D" .AND. (nSystemID == SYSTEMID_IBMDB2 .OR. nSystemID == SYSTEMID_ADABAS)
        RETURN "'" + Transform(DToS(uData), "@R 9999-99-99") + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_SQLBAS
      RETURN "'" + SR_dtosDot(uData) + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_INFORM
      RETURN "'" + SR_dtoUS(uData) + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_INGRES
      RETURN "'" + SR_dtoDot(uData) + "'"
   Case cType == "D" .AND. (nSystemID == SYSTEMID_FIREBR .OR. nSystemID == SYSTEMID_FIREBR3)
      RETURN "'" + Transform(DToS(uData), "@R 9999/99/99") + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_CACHE
      RETURN "{d '" + Transform(DToS(IIf(Year(uData) < 1850, SToD("18500101"), uData)), "@R 9999-99-99") + "'}"
   Case cType == "D"
      RETURN "'" + DToS(uData) + "'"
   Case cType == "N"
      RETURN LTrim(Str(uData))
   Case cType == "L" .AND. (nSystemID == SYSTEMID_POSTGR .OR. nSystemID == SYSTEMID_FIREBR3)
      RETURN IIf(uData, "true", "false")
   Case cType == "L" .AND. nSystemID == SYSTEMID_INFORM
      RETURN IIf(uData, "'t'", "'f'")
   Case cType == "L"
      RETURN IIf(uData, "1", "0")
   case ctype == "T"  .AND. nSystemID == SYSTEMID_POSTGR
      IF Empty(uData)
         RETURN 'NULL'
      ENDIF

      RETURN "'" + Transform(hb_ttos(uData), '@R 9999-99-99 99:99:99') + "'"
   case ctype == "T" .AND. nSystemID == SYSTEMID_ORACLE
      IF Empty(uData)
         RETURN 'NULL'
      ENDIF
      RETURN " TIMESTAMP '" + Transform(hb_ttos(uData), "@R 9999-99-99 99:99:99") + "'"
   Case cType == 'T'
      IF Empty(uData)
         RETURN 'NULL'
      ENDIF
      Set(_SET_DATEFORMAT, "yyyy-mm-dd")
      cRet := hb_ttoc(uData)
      Set(_SET_DATEFORMAT, cOldSet)
      RETURN "'" + cRet + "'"

   OtherWise
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN SR_SubQuoted("C", SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, nSystemID)
   EndCase
#endif

   SWITCH cType

   CASE "C"
   CASE "M"
      SWITCH nSystemID
      CASE SYSTEMID_ORACLE
         RETURN "'" + RTrim(StrTran(uData, "'", "'||" + "CHR(39)" + "||'")) + "'"
      CASE SYSTEMID_MSSQL7
         RETURN "'" + RTrim(StrTran(uData, "'", "'" + "'")) + "'"
      CASE SYSTEMID_POSTGR
         RETURN "E'" + StrTran(RTrim(StrTran(uData, "'", "'" + "'")), "\", "\\") + "'"
      OTHERWISE
         RETURN "'" + RTrim(StrTran(uData, "'", "")) + "'"
      ENDSWITCH

   CASE "D"
      SWITCH nSystemID
      CASE SYSTEMID_ORACLE
         RETURN "TO_DATE('" + RTrim(DToS(uData)) + "','YYYYMMDD')"
      CASE SYSTEMID_IBMDB2
      CASE SYSTEMID_ADABAS
         RETURN "'" + Transform(DToS(uData), "@R 9999-99-99") + "'"
      CASE SYSTEMID_SQLBAS
         RETURN "'" + SR_dtosDot(uData) + "'"
      CASE SYSTEMID_INFORM
         RETURN "'" + SR_dtoUS(uData) + "'"
      CASE SYSTEMID_INGRES
         RETURN "'" + SR_dtoDot(uData) + "'"
      CASE SYSTEMID_FIREBR
      CASE SYSTEMID_FIREBR3
      CASE SYSTEMID_FIREBR4
      CASE SYSTEMID_FIREBR5
         RETURN "'" + Transform(DToS(uData), "@R 9999/99/99") + "'"
      CASE SYSTEMID_CACHE
         RETURN "{d '" + Transform(DToS(IIf(Year(uData) < 1850, SToD("18500101"), uData)), "@R 9999-99-99") + "'}"
      OTHERWISE
         RETURN "'" + DToS(uData) + "'"
      ENDSWITCH

   CASE "N"
      RETURN LTrim(Str(uData))

   CASE "L"
      SWITCH nSystemID
      CASE SYSTEMID_POSTGR
      CASE SYSTEMID_FIREBR3
      CASE SYSTEMID_FIREBR4
      CASE SYSTEMID_FIREBR5
         RETURN IIf(uData, "true", "false")
      CASE SYSTEMID_INFORM
         RETURN IIf(uData, "'t'", "'f'")
      OTHERWISE
         RETURN IIf(uData, "1", "0")
      ENDSWITCH

   CASE "T"
      IF Empty(uData)
         RETURN "NULL"
      ENDIF
      SWITCH nSystemID
      CASE SYSTEMID_POSTGR
         RETURN "'" + Transform(hb_ttos(uData), "@R 9999-99-99 99:99:99") + "'"
      CASE SYSTEMID_ORACLE
         RETURN " TIMESTAMP '" + Transform(hb_ttos(uData), "@R 9999-99-99 99:99:99") + "'"
      OTHERWISE
         Set(_SET_DATEFORMAT, "yyyy-mm-dd")
         cRet := hb_ttoc(uData)
         Set(_SET_DATEFORMAT, cOldSet)
         RETURN "'" + cRet + "'"
      ENDSWITCH

   OTHERWISE
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN SR_SubQuoted("C", SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, nSystemID)

   ENDSWITCH

RETURN ""

//------------------------------------------------------------------------

FUNCTION SR_WriteTimeLog(cComm, oCnn, nLimisencos)

   LOCAL nAlAtual := Select()
   LOCAL TRACE_STRUCT := { ;
                           { "USUARIO",    "C", 10, 0 },;
                           { "DATA",       "D", 08, 0 },;
                           { "HORA",       "C", 08, 0 },;
                           { "CONTADOR",   "C", 01, 0 },;
                           { "TRANSCOUNT", "N", 10, 0 },;
                           { "COMANDO",    "M", 10, 0 },;
                           { "CUSTO",      "N", 12, 0 } ;
                         }

   HB_SYMBOL_UNUSED(oCnn)

   BEGIN SEQUENCE WITH __BreakBlock()

      IF !sr_PhFile("long_qry.dbf")
         DBCreate("long_qry.dbf", TRACE_STRUCT, "DBFNTX")
      ENDIF

      DO WHILE .T.
         DBUseArea(.T., "DBFNTX", "long_qry.dbf", "LONG_QRY", .T., .F.)
         IF !NetErr()
            exit
         ENDIF
         hb_idleSleep(500 / 1000)
      ENDDO

      LONG_QRY->(DBAppend())
      REPLACE LONG_QRY->DATA         WITH Date()
      REPLACE LONG_QRY->HORA         WITH Time()
      REPLACE LONG_QRY->COMANDO      WITH cComm
      REPLACE LONG_QRY->CUSTO        WITH nLimisencos
      LONG_QRY->(DBCloseArea())

   RECOVER

   END SEQUENCE

   DBSelectArea(nAlAtual)

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_uCharToVal(cVal, cType, nLen)

   SWITCH cType
   CASE "C"
      IF nLen == NIL
         RETURN cVal
      ELSE
         RETURN PadR(cVal, nLen)
      ENDIF
   CASE "M"
      RETURN cVal
   CASE "D"
      RETURN CToD(cVal)
   CASE "N"
      RETURN Val(cVal)
   CASE "L"
      RETURN cVal $ "1.T.SYsy.t."
   ENDSWITCH

RETURN ""

//------------------------------------------------------------------------

FUNCTION SR_WriteDbLog(cComm, oCnn)

   LOCAL nAlAtual := Select()
   LOCAL TRACE_STRUCT := { ;
                           { "USUARIO",    "C", 10, 0 },;
                           { "DATA",       "D", 08, 0 },;
                           { "HORA",       "C", 08, 0 },;
                           { "CONTADOR",   "C", 01, 0 },;
                           { "TRANSCOUNT", "N", 10, 0 },;
                           { "COMANDO",    "M", 10, 0 } ;
                         }

   HB_SYMBOL_UNUSED(oCnn)

   DEFAULT cComm TO ""

   BEGIN SEQUENCE WITH __BreakBlock()

      IF !sr_phFile("sqllog.dbf")
         DBCreate("sqllog.dbf", TRACE_STRUCT, "DBFNTX")
      ENDIF

      DO WHILE .T.
         DBUseArea(.T., "DBFNTX", "sqllog.dbf", "SQLLOG", .T., .F.)
         IF !NetErr()
            EXIT
         ENDIF
         hb_idleSleep(500 / 1000)
      ENDDO

      SQLLOG->(DBAppend())
      REPLACE SQLLOG->DATA         WITH Date()
      REPLACE SQLLOG->HORA         WITH Time()
      REPLACE SQLLOG->COMANDO      WITH cComm
      SQLLOG->(DBCloseArea())

   RECOVER

   END SEQUENCE

   DBSelectArea(nAlAtual)

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_ShowVector(a)

   LOCAL cRet := ""
   LOCAL i

   IF HB_IsArray(a) 

      cRet := "{"

      FOR i := 1 TO Len(a)

         IF HB_IsArray(a[i])
            cRet += SR_showvector(a[i]) + IIf(i == Len(a), "", ",") + SR_CRLF
         ELSE
            cRet += SR_Val2CharQ(a[i]) + IIf(i == Len(a), "", ",")
         ENDIF

      NEXT i

      cRet += "}"

   ELSE

      cRet += SR_Val2CharQ(a)

   ENDIF

RETURN cRet

//------------------------------------------------------------------------

FUNCTION SR_Val2CharQ(uData)

   LOCAL cType := ValType(uData)

   SWITCH cType
   CASE "C"
      //RETURN (["] + uData + ["])
      RETURN AllTrim(uData)
   CASE "N"
      RETURN AllTrim(Str(uData))
   CASE "D"
      RETURN DToC(uData)
   CASE "T"
      RETURN hb_ttoc(uData)
   CASE "L"
      RETURN IIf(uData, ".T.", ".F.")
   CASE "A"
      RETURN "{Array}"
   CASE "O"
      RETURN "{Object}"
   CASE "B"
      RETURN "{||Block}"
   OTHERWISE
      RETURN "NIL"
   ENDSWITCH

RETURN "NIL"

//------------------------------------------------------------------------

FUNCTION SR_BlankVar(cType, nLen, nDec)

   LOCAL nVal

   HB_SYMBOL_UNUSED(nDec) // To remove warning

   SWITCH cType
   CASE "C"
   CASE "M"
      RETURN Space(nLen)
   CASE "L"
      RETURN .F.
   CASE "D"
      RETURN CToD("")
   CASE "N"
      IF nDec > 0
         SWITCH ndec
         CASE 1
            nVal := 0.0
            EXIT
         CASE 2
            nVal := 0.00
            EXIT
         CASE 3
            nVal := 0.000
            EXIT
         CASE 4
            nVal := 0.0000
            EXIT
         CASE 5
            nVal := 0.00000
            EXIT
         CASE 6
            nVal := 0.000000
            EXIT
         OTHERWISE
            nVal := 0.00
         ENDSWITCH
         RETURN nVal
      ENDIF
      RETURN 0
   CASE "T"
      RETURN hb_datetime(0, 0, 0, 0, 0, 0, 0)
   ENDSWITCH

RETURN ""

//------------------------------------------------------------------------

FUNCTION SR_HistExpression(n, cTable, cPK, CurrDate, nSystem)

   LOCAL cRet
   LOCAL cAl1
   LOCAL cAl2
   LOCAL cAlias
   LOCAL oCnn

   oCnn := SR_GetConnection()

   cAlias := "W" + StrZero(++s__nCnt, 3)
   cAl1 := "W" + StrZero(++s__nCnt, 3)
   cAl2 := "W" + StrZero(++s__nCnt, 3)
   HB_SYMBOL_UNUSED(cAl2)

   IF s__nCnt >= 995
      s__nCnt := 1
   ENDIF

   DEFAULT CurrDate TO SR_GetActiveDt()
   DEFAULT n TO 0
   DEFAULT nSystem TO oCnn:nSystemID

   cRet := "SELECT " + cAlias + ".* FROM " + cTable + " " + cAlias + " WHERE " + SR_CRLF

   cRet += "(" + cAlias + ".DT__HIST = (SELECT" + IIf(n = 3, " MIN(", " MAX(") + cAl1 + ".DT__HIST) FROM "
   cRet += cTable + " " + cAl1 + " WHERE " + cAlias + "." + cPK + "="
   cRet += cAl1 + "." + cPk

   IF n = 0
      cRet += " AND " + cAl1 + ".DT__HIST <= " + SR_cDBValue(CurrDate)
   ENDIF

   cRet += "))"

RETURN cRet

//------------------------------------------------------------------------

FUNCTION SR_HistExpressionWhere(n, cTable, cPK, CurrDate, nSystem, cAlias)

   LOCAL cRet
   LOCAL cAl1
   LOCAL cAl2
   LOCAL oCnn

   oCnn := SR_GetConnection()

   cAl1 := "W" + StrZero(++s__nCnt, 3)
   cAl2 := "W" + StrZero(++s__nCnt, 3)
   HB_SYMBOL_UNUSED(cAl2)

   IF s__nCnt >= 995
      s__nCnt := 1
   ENDIF

   DEFAULT CurrDate TO SR_GetActiveDt()
   DEFAULT n TO 0
   DEFAULT nSystem TO oCnn:nSystemID

   cRet := ""

   cRet += "(" + cAlias + ".DT__HIST = (SELECT" + IIf(n = 3, " MIN(", " MAX(") + cAl1 + ".DT__HIST) FROM "
   cRet += cTable + " " + cAl1 + " WHERE " + cAlias + "." + cPK + "="
   cRet += cAl1 + "." + cPk

   IF n = 0
      cRet += " AND " + cAl1 + ".DT__HIST <= " + SR_cDBValue(CurrDate)
   ENDIF

   cRet += "))"

RETURN cRet

//------------------------------------------------------------------------

FUNCTION SR_SetNextSvVers(lVers)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lVers := lVers
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_GetRddName(nArea)

   DEFAULT nArea TO Select()

   DO CASE
   CASE Empty(Alias(nArea))
      RETURN "    "
   OTHERWISE
      RETURN (nArea)->(RddName())
   ENDCASE

RETURN ""

//------------------------------------------------------------------------

FUNCTION IsSQLWorkarea()

RETURN "*" + SR_GetRddName() + "*" $ "*SQLRDD*ODBCRDD*SQLEX*"

//------------------------------------------------------------------------

FUNCTION SR_OrdCondSet(cForSql, cForxBase)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):OrdSetForClause(cForSql, cForxBase)
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_SetJoin(nAreaTarget, cField, nAlias, nOrderTarget)

   HB_SYMBOL_UNUSED(nAreaTarget)
   HB_SYMBOL_UNUSED(cField)
   HB_SYMBOL_UNUSED(nAlias)
   HB_SYMBOL_UNUSED(nOrderTarget)

   SR_RuntimeErr(, "SR_SetJoin() is no longer supported")

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_AddRuleNotNull(cCol)

   LOCAL lRet

   IF IS_SQLRDD
      lRet := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):AddRuleNotNull(cCol)
      SR_CleanTabInfoCache()
      RETURN lRet
   ENDIF

RETURN .F.

//------------------------------------------------------------------------

FUNCTION SR_Deserialize(uData)

   //LOCAL ctemp
   //LOCAL cdes
   //LOCALchex

   // cTemp := udata
   // altd()
   // cHex := SR_HEXTOSTR(SubStr(uData, 21, Val(SubStr(uData, 11, 10))))
   // cdes := sr_Deserialize1(cHex)
   // tracelog(udata, chex, cdes)
   // RETURN cdes

RETURN SR_Deserialize1(SR_HEXTOSTR(SubStr(uData, 21, Val(SubStr(uData, 11, 10)))))

//------------------------------------------------------------------------

FUNCTION SR_DropRuleNotNull(cCol)

   LOCAL lRet

   IF IS_SQLRDD
      lRet := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):DropRuleNotNull(cCol)
      SR_CleanTabInfoCache()
      RETURN lRet
   ENDIF

RETURN .F.

//------------------------------------------------------------------------

FUNCTION SR_LastSQLError()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):oSql:cSQLError
   ENDIF

RETURN ""

//------------------------------------------------------------------------

FUNCTION SR_SetFilter(cFlt)

   LOCAL oWA
   LOCAL uRet

   IF IS_SQLRDD
      oWA := (Select())->(dbInfo(DBI_INTERNAL_OBJECT))
      uRet := oWA:cFilter
      IF !Empty(cFlt)
         oWA:cFilter := cFlt
         oWA:Refresh()
      ELSEIF HB_IsString(cFlt) 
         oWA:cFilter := ""
      ENDIF
   ENDIF

RETURN uRet

//------------------------------------------------------------------------

FUNCTION SR_ResetStatistics()

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):ResetStatistics()
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_GetnConnection()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT):oSql:nID)
   ENDIF

RETURN 0

//------------------------------------------------------------------------

FUNCTION SR_HasFilters()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):HasFilters()
   ENDIF

RETURN .F.

//------------------------------------------------------------------------

FUNCTION SR_dbRefresh()

   LOCAL oWA

   IF IS_SQLRDD
      oWA := (Select())->(dbInfo(DBI_INTERNAL_OBJECT))
      oWA:Refresh()
      IF !oWA:aInfo[AINFO_EOF]
         oWA:sqlGoTo(oWA:aInfo[AINFO_RECNO])
      ELSE
         oWA:sqlGoPhantom()
      ENDIF
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

CLASS SqlFastHash

   DATA hHash
   DATA nPartSize

   METHOD New(nPartSize)
   METHOD Insert(uHashKey, xValue)
   METHOD Find(uHashKey, nIndex, nPart)    // nIndex and nPart by ref
   METHOD Delete(uHashKey)
   METHOD Update(uHashKey, uValue)
   METHOD UpdateIndex(nPos, nPart, uValue)
   METHOD Haeval(bExpr)

ENDCLASS

//------------------------------------------------------------------------

METHOD Haeval(bExpr) CLASS SqlFastHash

RETURN hb_Heval(::hHash, bExpr)

//------------------------------------------------------------------------

METHOD New(nPartSize) CLASS SqlFastHash

   ::nPartSize := nPartSize
   ::hHash := {=>}
   //IF nPartSize != NIL // TODO: Harbour dont have HSetPartition
   //   HSetPartition(::hHash, nPartSize)
   //ENDIF

RETURN Self

//------------------------------------------------------------------------

METHOD Insert(uHashKey, xValue) CLASS SqlFastHash

   IF Len(::hHash) > HASH_TABLE_SIZE
      ::hHash := {=>}          // Reset hash table
      HB_GCALL(.T.)            // Release memory blocks
   ENDIF

   ::hHash[uHashKey] := xValue

RETURN .T.

//------------------------------------------------------------------------

METHOD Find(uHashKey, nIndex, nPart) CLASS SqlFastHash

   LOCAL aData

   nIndex := hb_HPos(::hHash, uHashKey)

   IF nIndex > 0
      aData := hb_HValueAt(::hHash, nIndex)
   ENDIF

   nPart := 1     // Compatible with old version

RETURN aData

//------------------------------------------------------------------------

METHOD Delete(uHashKey) CLASS SqlFastHash

   LOCAL nIndex := 0
   
   HB_SYMBOL_UNUSED(nIndex)

   nIndex := hb_HPos(::hHash, uHashKey)

   IF nIndex > 0
      hb_HDelAt(::hHash, nIndex)
      RETURN .T.
   ENDIF

RETURN .F.

//------------------------------------------------------------------------

METHOD Update(uHashKey, uValue) CLASS SqlFastHash

   LOCAL nIndex := 0
   
   HB_SYMBOL_UNUSED(nIndex)

   nIndex := hb_HPos(::hHash, uHashKey)

   IF nIndex > 0
      hb_HValueAt(::hHash, nIndex, uValue)
      RETURN .T.
   ENDIF

RETURN .F.

//------------------------------------------------------------------------

METHOD UpdateIndex(nPos, nPart, uValue) CLASS SqlFastHash

   // nPart not used - Compatible with old version
   HB_SYMBOL_UNUSED(nPart)
   hb_HValueAt(::hHash, nPos, uValue)

RETURN .F.

//------------------------------------------------------------------------

FUNCTION SR_BeginTransaction(nCnn)

   LOCAL oCnn

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      IF oCnn:nTransacCount == 0       // Commit any changes BEFORE Begin Transaction
         oCnn:Commit()
      ENDIF
      oCnn:nTransacCount ++

      IF oCnn:nSystemID == SYSTEMID_CACHE
         oCnn:Exec("START TRANSACTION %COMMITMODE EXPLICIT ISOLATION LEVEL READ COMMITTED")
//         oCnn:Exec("START TRANSACTION %COMMITMODE EXPLICIT")
      ENDIF

   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_CommitTransaction(nCnn)

   LOCAL oCnn

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      IF (oCnn:nTransacCount - 1) == 0
         oCnn:Commit()
         oCnn:nTransacCount := 0
      ELSEIF (oCnn:nTransacCount - 1) > 0
         oCnn:nTransacCount--
      ENDIF
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_SetAppSite(nCnn, cSite)

   LOCAL oCnn
   LOCAL cOld

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      cOld := oCnn:cSite
      IF cSite != NIL
         oCnn:cSite := cSite
      ENDIF
   ENDIF

RETURN cOld

//------------------------------------------------------------------------

FUNCTION SR_SetConnectionLogChanges(nCnn, nOpt)

   LOCAL oCnn
   LOCAL nOld

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      nOld := oCnn:nLogMode
      IF nOpt != NIL
         oCnn:nLogMode := nOpt
      ENDIF
   ENDIF

RETURN nOld

//------------------------------------------------------------------------

FUNCTION SR_SetAppUser(nCnn, cUsername)

   LOCAL oCnn
   LOCAL cOld

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      cOld := oCnn:cAppUser
      IF cUsername != NIL
         oCnn:cAppUser := cUsername
      ENDIF
   ENDIF

RETURN cOld

//------------------------------------------------------------------------

FUNCTION SR_SetALockWait(nCnn, nSeconds)

   LOCAL oCnn
   LOCAL nOld

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      nOld := oCnn:nLockWaitTime
      oCnn:nLockWaitTime := nSeconds
   ENDIF

RETURN nOld

//------------------------------------------------------------------------

FUNCTION SR_RollBackTransaction(nCnn)

   LOCAL oCnn

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      IF oCnn:nTransacCount >  0
         oCnn:nTransacCount := 0
         // Should CLEAN UP ALL workareas BEFORE issue the ROLLBACK
         _SR_ScanExecAll({|y, x|HB_SYMBOL_UNUSED(y), AEval(x, {|z|z:Refresh(.F.)})})
         oCnn:RollBack()
      ENDIF
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_TransactionCount(nCnn)

   LOCAL oCnn

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      RETURN oCnn:nTransacCount
   ENDIF

RETURN 0

//------------------------------------------------------------------------

FUNCTION SR_EndTransaction(nCnn)

   LOCAL oCnn

   IF HB_IsObject(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      IF oCnn:nTransacCount >  0
         oCnn:Commit()
         oCnn:nTransacCount := 0
      ENDIF
   ENDIF

RETURN NIL

//------------------------------------------------------------------------

FUNCTION SR_RuntimeErr(cOperation, cErr)

   LOCAL oErr := ErrorNew()
   LOCAL cDescr

   DEFAULT cOperation TO "SQLRDD"
   DEFAULT cErr TO "RunTimeError"

   cDescr := AllTrim(cErr)

   oErr:genCode := 99
   oErr:CanDefault := .F.
   oErr:Severity := ES_ERROR
   oErr:CanRetry := .T.
   oErr:CanSubstitute := .F.
   oErr:Description := cDescr + " - RollBack executed."
   oErr:subSystem := "SQLRDD"
   oErr:operation := cOperation
   oErr:OsCode := 0

   SR_LogFile("sqlerror.log", {cDescr})

   _SR_Throw(oErr)

RETURN NIL

//------------------------------------------------------------------------

FUNCTION dbCount()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):KeyCount()
   ENDIF

RETURN 0

//------------------------------------------------------------------------

FUNCTION SR_GetStack()

   LOCAL i := 1
   LOCAL cErrorLog := ""

   DO WHILE (i < 70)
      IF !Empty(ProcName(i))
         cErrorLog += SR_CRLF + Trim(ProcName(i)) + "     Linha : " + AllTrim(Str(ProcLine(i)))
      ENDIF
      i++
   ENDDO

RETURN cErrorLog

//------------------------------------------------------------------------

// Alert() copied as SQLBINDBYVAL() -> DEMO banner protection

//#include "hbsetup.ch"
#include "box.ch"
#include <common.ch>
#include <inkey.ch>
#include "setcurs.ch"

// TOFIX: Clipper defines a clipped window for Alert() [vszakats]

// NOTE: Clipper will return NIL if the first parameter is not a string, but
//       this is not documented. This implementation converts the first
//       parameter to a string if another type was passed. You can switch back
//       to Clipper compatible mode by defining constant
//       HB_C52_STRICT. [vszakats]

// NOTE: Clipper handles these buttons { "Ok", "", "Cancel" } in a buggy way.
//       This is fixed. [vszakats]

// NOTE: nDelay parameter is a Harbour extension.

#define INRANGE(xLo, xVal, xHi)       (xVal >= xLo .AND. xVal <= xHi)

FUNCTION SQLBINDBYVAL(xMessage, aOptions, cColorNorm, nDelay)

   LOCAL nChoice
   LOCAL aSay
   LOCAL nPos
   LOCAL nWidth
   LOCAL nOpWidth
   LOCAL nInitRow
   LOCAL nInitCol
   LOCAL nKey
   LOCAL aPos
   LOCAL nCurrent
   LOCAL aHotkey
   LOCAL aOptionsOK
   LOCAL cEval
   LOCAL cColorHigh

   LOCAL nOldRow
   LOCAL nOldCol
   LOCAL nOldCursor
   LOCAL cOldScreen

   LOCAL nOldDispCount
   LOCAL nCount
   LOCAL nLen
   LOCAL sCopy
   LOCAL lWhile

   LOCAL cColorStr
   LOCAL cColorPair1
   LOCAL cColorPair2
   LOCAL cColor11
   LOCAL cColor12
   LOCAL cColor21
   LOCAL cColor22
   LOCAL nCommaSep
   LOCAL nSlash

#ifdef HB_COMPAT_C53
   LOCAL nMRow
   LOCAL nMCol
#endif

   // TOFIX: Clipper decides at runtime, whether the GT is linked in,
   //        if it is not, the console mode is choosen here. [vszakats]
   LOCAL lConsole := .F.

#ifdef HB_C52_UNDOC

   DEFAULT s_lNoAlert TO hb_argCheck("NOALERT")

   IF s_lNoAlert
      RETURN NIL
   ENDIF

#endif

   aSay := {}

#ifdef HB_C52_STRICT

   IF !ISCHARACTER(xMessage)
      RETURN NIL
   ENDIF

   DO WHILE (nPos := At(";", xMessage)) != 0
      AAdd(aSay, Left(xMessage, nPos - 1))
      xMessage := SubStr(xMessage, nPos + 1)
   ENDDO
   AAdd(aSay, xMessage)

#else

   IF PCount() == 0
      RETURN NIL
   ENDIF

   IF ISARRAY(xMessage)

      FOR EACH cEval IN xMessage
         IF ISCHARACTER(cEval)
            AAdd(aSay, cEval)
         ENDIF
      NEXT

   ELSE

      SWITCH ValType(xMessage)
      CASE "C"
      CASE "M"
         EXIT
      CASE "N"
         xMessage := LTrim(Str(xMessage))
         EXIT
      CASE "D"
         xMessage := DToC(xMessage)
         EXIT
      CASE "T"
         xMessage := hb_TToC(xMessage)
         EXIT
      CASE "L"
         xMessage := IIf(xMessage, ".T.", ".F.")
         EXIT
      CASE "O"
         xMessage := xMessage:className + " Object"
         EXIT
      CASE "B"
         xMessage := "{||...}"
         EXIT
      OTHERWISE
         xMessage := "NIL"
      ENDSWITCH

      DO WHILE (nPos := At(";", xMessage)) != 0
         AAdd(aSay, Left(xMessage, nPos - 1))
         xMessage := SubStr(xMessage, nPos + 1)
      ENDDO
      AAdd(aSay, xMessage)

      FOR EACH xMessage IN aSay

         IF (nLen := Len(xMessage)) > 58
            HB_SYMBOL_UNUSED(nLen)
            FOR nPos := 58 TO 1 STEP -1
               IF xMessage[nPos] $ (" " + Chr(9))
                  EXIT
               ENDIF
            NEXT nPos

            IF nPos == 0
               nPos := 58
            ENDIF

            sCopy := xMessage
            aSay[xMessage:__EnumIndex()] := RTrim(Left(xMessage, nPos))

            IF Len(aSay) == xMessage:__EnumIndex()
               AAdd(aSay, SubStr(sCopy, nPos + 1))
            ELSE
               aIns(aSay, xMessage:__EnumIndex() + 1, SubStr(sCopy, nPos + 1), .T.)
            ENDIF
        ENDIF
      NEXT

   ENDIF

#endif

   IF !ISARRAY(aOptions)
      aOptions := {}
   ENDIF

   IF !ISCHARACTER(cColorNorm) .OR. EMPTY(cColorNorm)
      cColorNorm := "W+/R" // first pair color (Box line and Text)
      cColorHigh := "W+/B" // second pair color (Options buttons)
   ELSE

      // NOTE: Clipper Alert does not handle second color pair properly.
      //       If we inform the second color pair, xHarbour alert will consider it.
      //       if we not inform the second color pair, then xHarbour alert will behave
      //       like Clipper.  2004/Sep/16 - Eduardo Fernandes <modalsist>

      cColor11 := cColor12 := cColor21 := cColor22 := ""
      HB_SYMBOL_UNUSED(cColor11)
      HB_SYMBOL_UNUSED(cColor12)
      HB_SYMBOL_UNUSED(cColor21)
      HB_SYMBOL_UNUSED(cColor22)

      cColorStr := AllTrim(StrTran(cColorNorm, " ", ""))
      nCommaSep := At(",", cColorStr)

      IF nCommaSep > 0 // exist more than one color pair.
         cColorPair1 := SubStr(cColorStr, 1, nCommaSep - 1)
         cColorPair2 := SubStr(cColorStr, nCommaSep + 1)
      ELSE
         cColorPair1 := cColorStr
         cColorPair2 := ""
      ENDIF

      nSlash := At("/", cColorPair1)

      IF nSlash > 1
         cColor11 := SubStr(cColorPair1, 1, nSlash - 1)
         cColor12 := SubStr(cColorPair1, nSlash + 1)
      ELSE
         cColor11 := cColorPair1
         cColor12 := "R"
      ENDIF

      IF ColorValid(cColor11) .AND. ColorValid(cColor12)

        // if color pair is passed in numeric format, then we need to convert for
        // letter format to avoid blinking in some circumstances.
        IF IsDigit(cColor11)
           cColor11 := COLORLETTER(cColor11)
        ENDIF

        cColorNorm := cColor11

        IF !Empty(cColor12)

            IF IsDigit(cColor12)
               cColor12 := COLORLETTER(cColor12)
            ENDIF

            cColorNorm := cColor11 + "/" + cColor12

        ENDIF

      ELSE
         cColor11 := "W+"
         cColor12 := "R"
         cColorNorm := cColor11 + "/" + cColor12
      ENDIF


      // if second color pair exist, then xHarbour alert will handle properly.
      IF !Empty(cColorPair2)

         nSlash := At("/", cColorPair2)

         IF nSlash > 1
            cColor21 := SubStr(cColorPair2, 1, nSlash - 1)
            cColor22 := SubStr(cColorPair2, nSlash + 1)
         ELSE
            cColor21 := cColorPair2
            cColor22 := "B"
         ENDIF

         IF ColorValid(cColor21) .AND. ColorValid(cColor22)

            IF IsDigit(cColor21)
               cColor21 := COLORLETTER(cColor21)
            ENDIF

            cColorHigh := cColor21

            IF !Empty(cColor22)

                IF IsDigit(cColor22)
                   cColor22 := COLORLETTER(cColor22)
                ENDIF

                // extracting color attributes from background color.
                cColor22 := StrTran(cColor22, "+", "")
                cColor22 := StrTran(cColor22, "*", "")
                cColorHigh := cColor21 + "/" + cColor22

            ENDIF

         ELSE
            cColorHigh := "W+/B"
         ENDIF

      ELSE // if does not exist the second color pair, xHarbour alert will behave like Clipper
         IF Empty(cColor11) .OR. Empty(cColor12)
            cColor11 := "B"
            cColor12 := "W+"
         ELSE
            cColor11 := StrTran(cColor11, "+", "")
            cColor11 := StrTran(cColor11, "*", "")
         ENDIF
         cColorHigh := cColor12 + "/" + cColor11
      ENDIF

   ENDIF

   IF nDelay == NIL
      nDelay := 0
   ENDIF

   // The longest line
   nWidth := 0
   AEval(aSay, {|x|nWidth := Max(Len(x), nWidth)})

   // Cleanup the button array
   aOptionsOK := {}
   FOR EACH cEval IN aOptions
      IF ISCHARACTER(cEval) .AND. !Empty(cEval)
         AAdd(aOptionsOK, cEval)
      ENDIF
   NEXT

   IF Len(aOptionsOK) == 0
      aOptionsOK := {"Ok"}
#ifdef HB_C52_STRICT
   // NOTE: Clipper allows only four options [vszakats]
   ELSEIF Len(aOptionsOK) > 4
      ASize(aOptionsOK, 4)
#endif
   ENDIF

   // Total width of the botton line (the one with choices)
   nOpWidth := 0
   AEval(aOptionsOK, {|x|nOpWidth += Len(x) + 4})

   // what's wider ?
   nWidth := Max(nWidth + 2 + IIf(Len(aSay) == 1, 4, 0), nOpWidth + 2)

   // box coordinates
   nInitRow := Int(((MaxRow() - (Len(aSay) + 4)) / 2) + .5)
   nInitCol := Int(((MaxCol() - (nWidth + 2)) / 2) + .5)

   // detect prompts positions
   aPos := {}
   aHotkey := {}
   nCurrent := nInitCol + Int((nWidth - nOpWidth) / 2) + 2
   AEval(aOptionsOK, {|x|AAdd(aPos, nCurrent), AAdd(aHotKey, Upper(Left(x, 1))), nCurrent += Len(x) + 4})

   nChoice := 1

   IF lConsole

      nCount := Len(aSay)
      FOR EACH cEval IN aSay
         OutStd(cEval)
         IF cEval:__EnumIndex() < nCount
            OutStd(hb_OSNewLine())
         ENDIF
      NEXT

      OutStd(" (")
      nCount := Len(aOptionsOK)
      FOR EACH cEval IN aOptionsOK
         OutStd(cEval)
         IF cEval:__EnumIndex() < nCount
            OutStd(", ")
         ENDIF
      NEXT
      OutStd(") ")

      // choice loop
      lWhile := .T.
      DO WHILE lWhile

         nKey := Inkey(nDelay, INKEY_ALL)

         SWITCH nKey
         CASE 0
            lWhile := .F.
            EXIT
         CASE K_ESC
            nChoice := 0
            lWhile := .F.
            EXIT
         OTHERWISE
            IF Upper(Chr(nKey)) $ aHotkey
               nChoice := AScan(aHotkey, {|x|x == Upper(Chr(nKey))})
               lWhile := .F.
            ENDIF
         ENDSWITCH

      ENDDO

      OutStd(Chr(nKey))

   ELSE

      // PreExt
      nCount := nOldDispCount := DispCount()

      DO WHILE nCount-- != 0
         DispEnd()
      ENDDO

      // save status
      nOldRow := Row()
      nOldCol := Col()
      nOldCursor := SetCursor(SC_NONE)
      cOldScreen := SaveScreen(nInitRow, nInitCol, nInitRow + Len(aSay) + 3, nInitCol + nWidth + 1)

      // draw box
      DispBox(nInitRow, nInitCol, nInitRow + Len(aSay) + 3, nInitCol + nWidth + 1, B_SINGLE + " ", cColorNorm)

      FOR EACH cEval IN aSay
         DispOutAt(nInitRow + cEval:__EnumIndex(), nInitCol + 1 + Int(((nWidth - Len(cEval)) / 2) + .5), cEval, cColorNorm)
      NEXT

      // choice loop
      lWhile := .T.
      DO WHILE lWhile

         nCount := Len(aSay)
         FOR EACH cEval IN aOptionsOK
            DispOutAt(nInitRow + nCount + 2, aPos[cEval:__EnumIndex()], " " + cEval + " ", cColorNorm)
         NEXT
         DispOutAt(nInitRow + nCount + 2, aPos[nChoice], " " + aOptionsOK[nChoice] + " ", cColorHigh)

         nKey := Inkey(nDelay, INKEY_ALL)

         SWITCH nKey
         CASE K_ENTER
         CASE K_SPACE
         CASE 0
            lWhile := .F.
            EXIT
         CASE K_ESC
            nChoice := 0
            lWhile := .F.
            EXIT
#ifdef HB_COMPAT_C53
         CASE K_LBUTTONDOWN
            nMRow := MRow()
            nMCol := MCol()
            nPos := 0
            nCount := Len(aSay)
            FOR EACH cEval IN aOptionsOK
               IF nMRow == nInitRow + nCount + 2 .AND. ;
                  INRANGE(aPos[cEval:__EnumIndex()], nMCol, aPos[cEval:__EnumIndex()] + Len(cEval) + 2 - 1)
                  nPos := cEval:__EnumIndex()
                  EXIT
               ENDIF
            NEXT
            IF nPos > 0
               nChoice := nPos
               lWhile := .F.
            ENDIF
            EXIT
#endif
         CASE K_LEFT
         CASE K_SH_TAB
            IF Len(aOptionsOK) > 1
               nChoice--
               IF nChoice == 0
                  nChoice := Len(aOptionsOK)
               ENDIF
               nDelay := 0
            ENDIF
            EXIT
         CASE K_RIGHT
         CASE K_TAB
            IF Len(aOptionsOK) > 1
               nChoice++
               IF nChoice > Len(aOptionsOK)
                  nChoice := 1
               ENDIF
               nDelay := 0
            ENDIF
            EXIT
         OTHERWISE
            IF Upper(Chr(nKey)) $ aHotkey
               nChoice := AScan(aHotkey, {|x|x == Upper(Chr(nKey))})
               lWhile := .F.
            ENDIF
         ENDSWITCH

      ENDDO

      // Restore status
      RestScreen(nInitRow, nInitCol, nInitRow + Len(aSay) + 3, nInitCol + nWidth + 1, cOldScreen)
      SetCursor(nOldCursor)
      SetPos(nOldRow, nOldCol)

      // PostExt
      DO WHILE nOldDispCount-- != 0
         DispBegin()
      ENDDO

   ENDIF

RETURN nChoice

//-----------------------------------//
// 2004/Setp/15 - Eduardo Fernandes
// Convert number color format to character color format.
STATIC FUNCTION COLORLETTER(cColor)

   LOCAL nColor

  IF !IsCharacter(cColor)
     cColor := ""
  ENDIF

  cColor := StrTran(cColor, " ", "")
  cColor := StrTran(cColor, "*", "")
  cColor := StrTran(cColor, "+", "")

  nColor := Abs(Val(cColor))

  SWITCH nColor
  CASE 0  ; cColor := "N"   ; EXIT
  CASE 1  ; cColor := "B"   ; EXIT
  CASE 2  ; cColor := "G"   ; EXIT
  CASE 3  ; cColor := "BG"  ; EXIT
  CASE 4  ; cColor := "R"   ; EXIT
  CASE 5  ; cColor := "RB"  ; EXIT
  CASE 6  ; cColor := "GR"  ; EXIT
  CASE 7  ; cColor := "W"   ; EXIT
  CASE 8  ; cColor := "N+"  ; EXIT
  CASE 9  ; cColor := "B+"  ; EXIT
  CASE 10 ; cColor := "G+"  ; EXIT
  CASE 11 ; cColor := "BG+" ; EXIT
  CASE 12 ; cColor := "R+"  ; EXIT
  CASE 13 ; cColor := "RB+" ; EXIT
  CASE 14 ; cColor := "GR+" ; EXIT
  CASE 15 ; cColor := "W+"  ; EXIT
  OTHERWISE
     cColor := "W+" // 15 is the max.
  ENDSWITCH

RETURN cColor

//-----------------------------------//
// 2004/Setp/15 - Eduardo Fernandes
// Test vality of the color string
STATIC FUNCTION COLORVALID(cColor)

   IF !IsCharacter(cColor)
      RETURN .F.
   ENDIF

   cColor := StrTran(cColor, " ", "")
   cColor := StrTran(cColor, "*", "")
   cColor := StrTran(cColor, "+", "")
   cColor := Upper(cColor)

   IF cColor == "0"  .OR. ;
      cColor == "1"  .OR. ;
      cColor == "2"  .OR. ;
      cColor == "3"  .OR. ;
      cColor == "4"  .OR. ;
      cColor == "5"  .OR. ;
      cColor == "6"  .OR. ;
      cColor == "7"  .OR. ;
      cColor == "8"  .OR. ;
      cColor == "9"  .OR. ;
      cColor == "10" .OR. ;
      cColor == "11" .OR. ;
      cColor == "12" .OR. ;
      cColor == "13" .OR. ;
      cColor == "14" .OR. ;
      cColor == "15" .OR. ;
      cColor == "B"  .OR. ;
      cColor == "BG" .OR. ;
      cColor == "G"  .OR. ;
      cColor == "GR" .OR. ;
      cColor == "N"  .OR. ;
      cColor == "R"  .OR. ;
      cColor == "RB" .OR. ;
      cColor == "W"

      RETURN .T.

   ENDIF

RETURN .F.

#PRAGMA BEGINDUMP

#include "sqlrddpp.h"
#include "compat.h"
#include <hbapi.h>
#include <hbapifs.h>
#include <hbapiitm.h>

#ifndef HB_PATH_MAX
#define HB_PATH_MAX   264 // with trailing 0 byte
#endif

// TODO: Xbase++ has an extension where the second parameter can specify
//       the required attribute.

HB_FUNC(SR_PHFILE)
{
   PHB_ITEM pFile = hb_param(1, HB_IT_STRING);
   hb_retl((pFile && hb_itemGetCLen(pFile) < HB_PATH_MAX - 1) ? hb_spFile(hb_itemGetCPtr(pFile), SR_NULLPTR) : HB_FALSE);
}

#PRAGMA ENDDUMP

FUNCTION sr_AddToFilter(nRecNo)

   LOCAL oWA

   IF IS_SQLRDD
      oWA := (Select())->(dbInfo(DBI_INTERNAL_OBJECT))
      IF !Empty(oWA:cFilter)
         AAdd(oWA:aRecnoFilter, nRecno)
         oWA:Refresh()
      ENDIF
   ENDIF

RETURN NIL

FUNCTION sr_clearFilter()

   LOCAL oWa

   IF IS_SQLRDD
      oWA := (Select())->(dbInfo(DBI_INTERNAL_OBJECT))
      IF !Empty(oWA:cFilter)
         oWA:aRecnoFilter := {}
         oWA:Refresh()
      ENDIF
   ENDIF

RETURN NIL

FUNCTION SR_SetFieldDefault(cTable, cField, cDefault)

   LOCAL oCnn
   LOCAL cSql := "ALTER TABLE " + cTable + " ALTER COLUMN " + cField + " SET DEFAULT "

   oCnn := SR_GetConnection()
   IF HB_IsNumeric(cDefault)
      cSql += AllTrim(Str(cDefault))
   ELSEIF HB_IsString(cDefault)
      IF Empty(cDefault)
         cSql += "''"
      ELSE
         cSql += "'" + cDefault + "'"
      ENDIF
   ENDIF
   IF oCnn:nSystemId == SYSTEMID_POSTGR
      oCnn:Exec(cSql, , .F.)
      oCnn:Commit()
   ENDIF

RETURN NIL

FUNCTION SR_Deserialize1(cSerial, nMaxLen, lRecursive, aObj, aHash, aArray, aBlock)
RETURN HB_Deserialize(cSerial, nMaxLen, lRecursive, aObj, aHash, aArray, aBlock)
