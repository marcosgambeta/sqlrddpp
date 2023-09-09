/* $CATEGORY$SQLRDD/Utils$FILES$sql.lib$
* SQLRDD Utilities
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
// #include "compat.ch"
#include "sqlodbc.ch"
#include "sqlrdd.ch"
#include "fileio.ch"
#include "msg.ch"
#include "error.ch"
#include "sqlrddsetup.ch"

#define SR_CRLF   (chr(13) + chr(10))

REQUEST HB_Deserialize
REQUEST HB_DeserialNext
#define FH_ALLOC_BLOCK     32

Static DtAtiv, lHistorico
Static _nCnt := 1
Static lCreateAsHistoric := .F.

#ifdef HB_C52_UNDOC
STATIC s_lNoAlert
#endif

/*------------------------------------------------------------------------*/

FUNCTION SR_GoPhantom()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):sqlGoPhantom()
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_WorkareaFileName()

   IF empty(alias())
      RETURN ""
   ENDIF

   IF !IS_SQLRDD
      RETURN ""
   ENDIF

RETURN dbInfo(DBI_INTERNAL_OBJECT):cFileName

/*------------------------------------------------------------------------*/

FUNCTION SR_dbStruct()

   IF empty(alias())
      RETURN {}
   ENDIF

   IF !IS_SQLRDD
      RETURN {}
   ENDIF

RETURN aclone(dbInfo(DBI_INTERNAL_OBJECT):aFields)

/*------------------------------------------------------------------------*/

FUNCTION SR_MsgLogFile(uMsg, p1, p2, p3, p4, p5, p6, p7, p8)
   SR_LogFile("sqlerror.log", {uMsg, p1, p2, p3, p4, p5, p6, p7, p8})
RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_Val2Char(a, n1, n2)

   SWITCH valtype(a)
   CASE "C"
   CASE "M"
      RETURN a
   CASE "N"
      IF n1 != NIL .AND. n2 != NIL
         RETURN Str(a, n1, n2)
      ENDIF
      RETURN Str(a)
   CASE "D"
      RETURN dtoc(a)
   CASE "L"
      RETURN iif(a, ".T.", ".F.")
   ENDSWITCH

RETURN ""

/*------------------------------------------------------------------------*/

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
   FWrite(hFile, alltrim(cLine))
   FClose(hFile)

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_FilterStatus(lEnable)

   IF IS_SQLRDD
      IF HB_ISLOGICAL(lEnable) 
         RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lDisableFlts := !lEnable
      ELSE
         RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lDisableFlts
      ENDIF
   ENDIF

RETURN .F.

/*------------------------------------------------------------------------*/

FUNCTION SR_CreateConstraint(aSourceColumns, cTargetTable, aTargetColumns, cConstraintName)

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):CreateConstraint(dbInfo(DBI_INTERNAL_OBJECT):cFileName, aSourceColumns, cTargetTable, aTargetColumns, cConstraintName)
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_DropConstraint(cConstraintName, lFKs)

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):DropConstraint(dbInfo(DBI_INTERNAL_OBJECT):cFileName, cConstraintName, lFKs)
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

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

   IF select() == 0
      SR_RuntimeErr(, "SR_ChengeStructure: Workarea not in use.")
   ENDIF

   IF len(aNewStruct) < 1 .OR. !HB_ISARRAY(aNewStruct) .OR. !HB_ISARRAY(aNewStruct[1])
      SR_RuntimeErr(, "SR_ChengeStructure: Invalid arguments [2].")
   ENDIF

   IF IS_SQLRDD

      oWA := dbInfo(DBI_INTERNAL_OBJECT)

      IF (!Empty(cTableName)) .AND. oWA:cOriginalFN != upper(alltrim(cTableName))
         SR_RuntimeErr(, "SR_ChengeStructure: Invalid arguments [1]: " + cTableName)
      ENDIF

      cAlias   := alias()
      nAlias   := select()
      cTblName := oWA:cFileName
      nOrd     := IndexOrd()
      nReg     := recno()

      dbSetOrder(0)

      SR_LogFile("changestruct.log", {oWA:cFileName, "Original Structure:", e"\r\n" + sr_showVector(oWA:aFields)})
      SR_LogFile("changestruct.log", {oWA:cFileName, "New Structure:", e"\r\n" + sr_showVector(aNewStruct)})

      FOR i := 1 TO len(aNewStruct)
         aNewStruct[i, 1] := Upper(alltrim(aNewStruct[i, 1]))
         IF (n := aScan(oWA:aFields, {|x|x[1] == aNewStruct[i, 1]})) > 0

            aSize(aNewStruct[i], max(len(aNewStruct[i]), 5))

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
               aadd(aToFix, aClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Will Change data type of field:", aNewStruct[i, 1], "from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
            ELSEIF aNewStruct[i, 2] == "C" .AND. oWA:aFields[n, 2] == "M"
               aadd(aToFix, aClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Warning: Possible data loss changing data type:", aNewStruct[i, 1], "from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
            ELSEIF aNewStruct[i, 2] != oWA:aFields[n, 2]
               IF aNewStruct[i, 2] $"CN" .AND. oWA:aFields[n, 2] $"CN" .AND. oWA:oSql:nSystemID == SYSTEMID_POSTGR

*                   IF "8.4" $ oWA:oSql:cSystemVers .OR. "9.0" $ oWA:oSql:cSystemVers
                  IF oWA:oSql:lPostgresql8 .AND. !oWA:oSql:lPostgresql83
                     aadd(aDirect, aClone(aNewStruct[i]))
                  ELSE
                     aadd(aToFix, aClone(aNewStruct[i]))
                  ENDIF
                  SR_LogFile("changestruct.log", {oWA:cFileName, "Warning: Possible data loss changing field types:", aNewStruct[i, 1], "from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
               ELSE
                  SR_LogFile("changestruct.log", {oWA:cFileName, "ERROR: Cannot convert data type of field:", aNewStruct[i, 1], " from", oWA:aFields[n, 2], "to", aNewStruct[i, 2]})
               ENDIF
            ELSEIF aNewStruct[i, 3] >= oWA:aFields[n, 3] .AND. oWA:aFields[n, 2] $ "CN"

               aadd(aDirect, aClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Will Change field size:", aNewStruct[i, 1], "from", oWA:aFields[n, 3], "to", aNewStruct[i, 3]})
            ELSEIF aNewStruct[i, 3] < oWA:aFields[n, 3] .AND. oWA:aFields[n, 2] $ "CN"
               aadd(aToFix, aClone(aNewStruct[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Warning: Possible data loss changing field size:", aNewStruct[i, 1], "from", oWA:aFields[n, 3], "to", aNewStruct[i, 3]})
            ELSE
               SR_LogFile("changestruct.log", {oWA:cFileName, "Column cannot be changed:", aNewStruct[i, 1]})
            ENDIF
         ELSE
            aadd(aToFix, aClone(aNewStruct[i]))
            SR_LogFile("changestruct.log", {oWA:cFileName, "Will add column:", aNewStruct[i, 1]})
         ENDIF
      NEXT i

      FOR i := 1 TO len(oWA:aFields)
         IF (n := aScan(aNewStruct, {|x|x[1] == oWA:aFields[i, 1]})) == 0
            IF (!oWA:aFields[i, 1] == oWA:cRecnoName) .AND. (!oWA:aFields[i, 1] == oWA:cDeletedName) .AND. oWA:oSql:nSystemID != SYSTEMID_IBMDB2
               aadd(aToDrop, aClone(oWA:aFields[i]))
               SR_LogFile("changestruct.log", {oWA:cFileName, "Will drop:", oWA:aFields[i, 1]})
            ENDIF
         ENDIF
      NEXT i
      IF Len(aDirect) > 0 .AND. ( ;
              oWA:oSql:nSystemID == SYSTEMID_FIREBR ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_FIREBR3 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MYSQL ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MARIADB ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_ORACLE ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MSSQL6 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_MSSQL7 ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_CACHE ;
         .OR. oWA:oSql:nSystemID == SYSTEMID_POSTGR)
         oWA:AlterColumnsDirect(aDirect, .T., .F., @aTofix)
      ENDIF

      IF len(aToFix) > 0
         oWA:AlterColumns(aToFix, .T.)
      ENDIF

      FOR i := 1 TO len(aToDrop)
         IF aToDrop[i, 1] == "BACKUP_"
            oWA:DropColumn(aToDrop[i, 1], .F.)
         ELSE
            oWA:DropColumn(aToDrop[i, 1], .T.)
         ENDIF
      NEXT i

      SELECT (nALias)
      dbCloseArea()

      SR_CleanTabInfoCache()

      // recover table status

      SELECT (nAlias)
      dbUseArea(.F., "SQLRDD", cTblName, cAlias)
      IF OrdCount() >= nOrd
         dbSetOrder(nOrd)
      ENDIF
      dbGoTo(nReg)

   ELSE
      SR_RuntimeErr(, "SR_ChengeStructure: Not a SQLRDD workarea.")
   ENDIF

RETURN lOk

/*------------------------------------------------------------------------*/

FUNCTION SR_SetCurrDate(d)

   IF IS_SQLRDD
      d := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetCurrDate(d)
      IF d == NIL
         d := SR_GetActiveDt()
      ENDIF
   ENDIF

RETURN d

/*------------------------------------------------------------------------*/

FUNCTION SR_QuickAppend(l)

   IF IS_SQLRDD
      l := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetQuickAppend(l)
   ENDIF

RETURN l

/*------------------------------------------------------------------------*/

FUNCTION SR_SetColPK(cColName)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetColPK(cColName)
      IF cColName == NIL
         cColName := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):cColPK
      ENDIF
   ENDIF

RETURN cColName

/*------------------------------------------------------------------------*/

FUNCTION SR_IsWAHist()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lHistoric
   ENDIF

RETURN .F.

/*------------------------------------------------------------------------*/

FUNCTION SR_SetReverseIndex(nIndex, lSet)

   LOCAL lOldSet

   IF IS_SQLRDD .AND. nIndex > 0 .AND. nIndex <= len((Select())->(dbInfo(DBI_INTERNAL_OBJECT)):aIndex)
      lOldSet := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):aIndex[nIndex, DESCEND_INDEX_ORDER]
      IF HB_ISLOGICAL(lSet)
         (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):aIndex[nIndex, DESCEND_INDEX_ORDER] := lSet
      ENDIF
   ENDIF

RETURN lOldSet

/*------------------------------------------------------------------------*/

FUNCTION SR_SetNextDt(d)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):SetNextDt(d)
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_DisableHistoric()

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):DisableHistoric()
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):Refresh()
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_EnableHistoric()

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):EnableHistoric()
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):Refresh()
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_GetActiveDt()

RETURN DtAtiv

/*------------------------------------------------------------------------*/

FUNCTION SR_SetActiveDt(d)

   DEFAULT d TO date()

RETURN DtAtiv := d

/*------------------------------------------------------------------------*/

FUNCTION SR_SetActiveDate(d)

   LOCAL dOld := DtAtiv

   IF d != NIL
      DtAtiv := d
   ENDIF

RETURN dOld

/*------------------------------------------------------------------------*/

Init Procedure SR_IniDtAtiv()

   DtAtiv := date()

Return

/*------------------------------------------------------------------------*/

FUNCTION SR_SetCreateAsHistoric(l)

   LOCAL lOld := lCreateAsHistoric

   IF HB_ISLOGICAL(l) 
      lCreateAsHistoric := l
   ENDIF

RETURN lCreateAsHistoric

/*------------------------------------------------------------------------*/

FUNCTION SR_HasHistoric()

RETURN (lHistorico := .T.)

/*------------------------------------------------------------------------*/

FUNCTION SR_cDBValue(uData, nSystemID)

   default nSystemID TO SR_GetConnection():nSystemID

RETURN SR_SubQuoted(valtype(uData), uData, nSystemID)

/*------------------------------------------------------------------------*/

STATIC FUNCTION SR_SubQuoted(cType, uData, nSystemID)

   LOCAL cRet
   LOCAL cOldSet := SET(_SET_DATEFORMAT)

#if 0 // TODO: old code for reference (to be deleted)
   Do Case
   Case cType $ "CM" .AND. nSystemID == SYSTEMID_ORACLE
      RETURN "'" + rtrim(strtran(uData, "'", "'||" + "CHR(39)" + "||'")) + "'"
   Case cType $ "CM" .AND. nSystemID == SYSTEMID_MSSQL7
      RETURN "'" + rtrim(strtran(uData, "'", "'" + "'")) + "'"
   Case cType $ "CM" .AND. nSystemID == SYSTEMID_POSTGR
      RETURN "E'" + strtran(rtrim(strtran(uData, "'", "'" + "'")), "\", "\\") + "'"
   Case cType $ "CM"
      RETURN "'" + rtrim(strtran(uData, "'", "")) + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_ORACLE
      RETURN "TO_DATE('" + rtrim(DtoS(uData)) + "','YYYYMMDD')"
   Case cType == "D" .AND. (nSystemID == SYSTEMID_IBMDB2 .OR. nSystemID == SYSTEMID_ADABAS)
        RETURN "'" + transform(DtoS(uData), "@R 9999-99-99") + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_SQLBAS
      RETURN "'" + SR_dtosDot(uData) + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_INFORM
      RETURN "'" + SR_dtoUS(uData) + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_INGRES
      RETURN "'" + SR_dtoDot(uData) + "'"
   Case cType == "D" .AND. (nSystemID == SYSTEMID_FIREBR .OR. nSystemID == SYSTEMID_FIREBR3)
      RETURN "'" + transform(DtoS(uData), "@R 9999/99/99") + "'"
   Case cType == "D" .AND. nSystemID == SYSTEMID_CACHE
      RETURN "{d '" + transform(DtoS(iif(year(uData) < 1850, stod("18500101"), uData)), "@R 9999-99-99") + "'}"
   Case cType == "D"
      RETURN "'" + dtos(uData) + "'"
   Case cType == "N"
      RETURN ltrim(str(uData))
   Case cType == "L" .AND. (nSystemID == SYSTEMID_POSTGR .OR. nSystemID == SYSTEMID_FIREBR3)
      RETURN iif(uData, "true", "false")
   Case cType == "L" .AND. nSystemID == SYSTEMID_INFORM
      RETURN iif(uData, "'t'", "'f'")
   Case cType == "L"
      RETURN iif(uData, "1", "0")
   case ctype == "T"  .AND. nSystemID == SYSTEMID_POSTGR
      IF Empty(uData)
         RETURN 'NULL'
      ENDIF

      RETURN "'" + transform(ttos(uData), '@R 9999-99-99 99:99:99') + "'"
   case ctype == "T" .AND. nSystemID == SYSTEMID_ORACLE
      IF Empty(uData)
         RETURN 'NULL'
      ENDIF
      RETURN " TIMESTAMP '" + transform(ttos(uData), "@R 9999-99-99 99:99:99") + "'"
   Case cType == 'T'
      IF Empty(uData)
         RETURN 'NULL'
      ENDIF
      Set(_SET_DATEFORMAT, "yyyy-mm-dd")
      cRet := ttoc(uData)
      Set(_SET_DATEFORMAT, cOldSet)
      RETURN "'" + cRet + "'"

   OtherWise
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN SR_SubQuoted("C", SQL_SERIALIZED_SIGNATURE + str(len(cRet), 10) + cRet, nSystemID)
   EndCase
#endif

   SWITCH cType

   CASE "C"
   CASE "M"
      SWITCH nSystemID
      CASE SYSTEMID_ORACLE
         RETURN "'" + rtrim(strtran(uData, "'", "'||" + "CHR(39)" + "||'")) + "'"
      CASE SYSTEMID_MSSQL7
         RETURN "'" + rtrim(strtran(uData, "'", "'" + "'")) + "'"
      CASE SYSTEMID_POSTGR
         RETURN "E'" + strtran(rtrim(strtran(uData, "'", "'" + "'")), "\", "\\") + "'"
      OTHERWISE
         RETURN "'" + rtrim(strtran(uData, "'", "")) + "'"
      ENDSWITCH

   CASE "D"
      SWITCH nSystemID
      CASE SYSTEMID_ORACLE
         RETURN "TO_DATE('" + rtrim(DtoS(uData)) + "','YYYYMMDD')"
      CASE SYSTEMID_IBMDB2
      CASE SYSTEMID_ADABAS
         RETURN "'" + transform(DtoS(uData), "@R 9999-99-99") + "'"
      CASE SYSTEMID_SQLBAS
         RETURN "'" + SR_dtosDot(uData) + "'"
      CASE SYSTEMID_INFORM
         RETURN "'" + SR_dtoUS(uData) + "'"
      CASE SYSTEMID_INGRES
         RETURN "'" + SR_dtoDot(uData) + "'"
      CASE SYSTEMID_FIREBR
      CASE SYSTEMID_FIREBR3
         RETURN "'" + transform(DtoS(uData), "@R 9999/99/99") + "'"
      CASE SYSTEMID_CACHE
         RETURN "{d '" + transform(DtoS(iif(year(uData) < 1850, stod("18500101"), uData)), "@R 9999-99-99") + "'}"
      OTHERWISE
         RETURN "'" + dtos(uData) + "'"
      ENDSWITCH

   CASE "N"
      RETURN ltrim(str(uData))

   CASE "L"
      SWITCH nSystemID
      CASE SYSTEMID_POSTGR
      CASE SYSTEMID_FIREBR3
         RETURN iif(uData, "true", "false")
      CASE SYSTEMID_INFORM
         RETURN iif(uData, "'t'", "'f'")
      OTHERWISE
         RETURN iif(uData, "1", "0")
      ENDSWITCH

   CASE "T"
      IF Empty(uData)
         RETURN "NULL"
      ENDIF
      SWITCH nSystemID
      CASE SYSTEMID_POSTGR
         RETURN "'" + transform(ttos(uData), "@R 9999-99-99 99:99:99") + "'"
      CASE SYSTEMID_ORACLE
         RETURN " TIMESTAMP '" + transform(ttos(uData), "@R 9999-99-99 99:99:99") + "'"
      OTHERWISE
         Set(_SET_DATEFORMAT, "yyyy-mm-dd")
         cRet := ttoc(uData)
         Set(_SET_DATEFORMAT, cOldSet)
         RETURN "'" + cRet + "'"
      ENDSWITCH

   OTHERWISE
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN SR_SubQuoted("C", SQL_SERIALIZED_SIGNATURE + str(len(cRet), 10) + cRet, nSystemID)

   ENDSWITCH

RETURN ""

/*------------------------------------------------------------------------*/

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

   BEGIN SEQUENCE

      IF !sr_PhFile("long_qry.dbf")
         dbCreate("long_qry.dbf", TRACE_STRUCT, "DBFNTX")
      ENDIF

      DO WHILE .T.
         dbUseArea(.T., "DBFNTX", "long_qry.dbf", "LONG_QRY", .T., .F.)
         IF !NetErr()
            exit
         ENDIF
         ThreadSleep(500)
      ENDDO

      LONG_QRY->(dbAppend())
      Replace LONG_QRY->DATA         with Date()
      Replace LONG_QRY->HORA         with Time()
      Replace LONG_QRY->COMANDO      with cComm
      Replace LONG_QRY->CUSTO        with nLimisencos
      LONG_QRY->(dbCloseArea())

   RECOVER

   END SEQUENCE

   dbSelectArea(nAlAtual)

RETURN NIL

/*------------------------------------------------------------------------*/

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
      RETURN ctod(cVal)
   CASE "N"
      RETURN val(cVal)
   CASE "L"
      RETURN cVal $ "1.T.SYsy.t."
   ENDSWITCH

RETURN ""

/*------------------------------------------------------------------------*/

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

   BEGIN SEQUENCE

      IF !sr_phFile("sqllog.dbf")
         dbCreate("sqllog.dbf", TRACE_STRUCT, "DBFNTX")
      ENDIF

      DO WHILE .T.
         dbUseArea(.T., "DBFNTX", "sqllog.dbf", "SQLLOG", .T., .F.)
         IF !NetErr()
            EXIT
         ENDIF
         ThreadSleep(500)
      ENDDO

      SQLLOG->(dbAppend())
      Replace SQLLOG->DATA         with Date()
      Replace SQLLOG->HORA         with Time()
      Replace SQLLOG->COMANDO      with cComm
      SQLLOG->(dbCloseArea())

   RECOVER

   END SEQUENCE

   dbSelectArea(nAlAtual)

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_ShowVector(a)

   LOCAL cRet := ""
   LOCAL i

   IF HB_ISARRAY(a) 

      cRet := "{"

      FOR i := 1 TO len(a)

         IF HB_ISARRAY(a[i])
            cRet += SR_showvector(a[i]) + iif(i == len(a), "", ",") + SR_CRLF
         ELSE
            cRet += SR_Val2CharQ(a[i]) + iif(i == len(a), "", ",")
         ENDIF

      NEXT i

      cRet += "}"

   ELSE

      cRet += SR_Val2CharQ(a)

   ENDIF

RETURN cRet

/*------------------------------------------------------------------------*/

FUNCTION SR_Val2CharQ(uData)

   LOCAL cType := valtype(uData)

   SWITCH cType
   CASE "C"
      //RETURN (["] + uData + ["])
      RETURN AllTrim(uData)
   CASE "N"
      RETURN alltrim(Str(uData))
   CASE "D"
      RETURN dtoc(uData)
   CASE "T"
      RETURN ttoc(uData)
   CASE "L"
      RETURN iif(uData, ".T.", ".F.")
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

/*------------------------------------------------------------------------*/

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
      RETURN ctod("")
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
      RETURN datetime(0, 0, 0, 0, 0, 0, 0)
   ENDSWITCH

RETURN ""

/*------------------------------------------------------------------------*/

FUNCTION SR_HistExpression(n, cTable, cPK, CurrDate, nSystem)

   LOCAL cRet
   LOCAL cAl1
   LOCAL cAl2
   LOCAL cAlias
   LOCAL oCnn

   oCnn := SR_GetConnection()

   cAlias := "W" + StrZero(++_nCnt, 3)
   cAl1   := "W" + StrZero(++_nCnt, 3)
   cAl2   := "W" + StrZero(++_nCnt, 3)

   IF _nCnt >= 995
      _nCnt := 1
   ENDIF

   DEFAULT CurrDate TO SR_GetActiveDt()
   DEFAULT n TO 0
   DEFAULT nSystem TO oCnn:nSystemID

   cRet := "SELECT " + cAlias + ".* FROM " + cTable + " " + cAlias + " WHERE " + SR_CRLF

   cRet += "(" + cAlias + ".DT__HIST = (SELECT" + iif(n = 3, " MIN(", " MAX(") + cAl1 + ".DT__HIST) FROM "
   cRet += cTable + " " + cAl1 + " WHERE " + cAlias + "." + cPK + "="
   cRet += cAl1 + "." + cPk

   IF n = 0
      cRet += " AND " + cAl1 + ".DT__HIST <= " + SR_cDBValue(CurrDate)
   ENDIF

   cRet += "))"

RETURN cRet

/*------------------------------------------------------------------------*/

FUNCTION SR_HistExpressionWhere(n, cTable, cPK, CurrDate, nSystem, cAlias)

   LOCAL cRet
   LOCAL cAl1
   LOCAL cAl2
   LOCAL oCnn

   oCnn := SR_GetConnection()

   cAl1   := "W" + StrZero(++_nCnt, 3)
   cAl2   := "W" + StrZero(++_nCnt, 3)

   IF _nCnt >= 995
      _nCnt := 1
   ENDIF

   DEFAULT CurrDate TO SR_GetActiveDt()
   DEFAULT n TO 0
   DEFAULT nSystem TO oCnn:nSystemID

   cRet := ""

   cRet += "(" + cAlias + ".DT__HIST = (SELECT" + iif(n = 3, " MIN(", " MAX(") + cAl1 + ".DT__HIST) FROM "
   cRet += cTable + " " + cAl1 + " WHERE " + cAlias + "." + cPK + "="
   cRet += cAl1 + "." + cPk

   IF n = 0
      cRet += " AND " + cAl1 + ".DT__HIST <= " + SR_cDBValue(CurrDate)
   ENDIF

   cRet += "))"

RETURN cRet

/*------------------------------------------------------------------------*/

FUNCTION SR_SetNextSvVers(lVers)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):lVers := lVers
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_GetRddName(nArea)

   DEFAULT nArea TO Select()

   DO CASE
   CASE Empty(Alias(nArea))
      RETURN "    "
   OTHERWISE
      RETURN (nArea)->(RddName())
   ENDCASE

RETURN ""

/*------------------------------------------------------------------------*/

FUNCTION IsSQLWorkarea()

RETURN "*" + SR_GetRddName() + "*" $ "*SQLRDD*ODBCRDD*SQLEX*"

/*------------------------------------------------------------------------*/

FUNCTION SR_OrdCondSet(cForSql, cForxBase)

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):OrdSetForClause(cForSql, cForxBase)
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_SetJoin(nAreaTarget, cField, nAlias, nOrderTarget)

   HB_SYMBOL_UNUSED(nAreaTarget)
   HB_SYMBOL_UNUSED(cField)
   HB_SYMBOL_UNUSED(nAlias)
   HB_SYMBOL_UNUSED(nOrderTarget)

   SR_RuntimeErr(, "SR_SetJoin() is no longer supported")

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_AddRuleNotNull(cCol)

   LOCAL lRet

   IF IS_SQLRDD
      lRet := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):AddRuleNotNull(cCol)
      SR_CleanTabInfoCache()
      RETURN lRet
   ENDIF

RETURN .F.

/*------------------------------------------------------------------------*/

FUNCTION SR_Deserialize(uData)

   //LOCAL ctemp
   //LOCAL cdes
   //LOCALchex

   // cTemp := udata
   // altd()
   // cHex := SR_HEXTOSTR(SubStr(uData, 21, val(substr(uData, 11, 10))))
   // cdes := sr_Deserialize1(cHex)
   // tracelog(udata, chex, cdes)
   // RETURN cdes

RETURN SR_Deserialize1(SR_HEXTOSTR(SubStr(uData, 21, val(substr(uData, 11, 10)))))

/*------------------------------------------------------------------------*/

FUNCTION SR_DropRuleNotNull(cCol)

   LOCAL lRet

   IF IS_SQLRDD
      lRet := (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):DropRuleNotNull(cCol)
      SR_CleanTabInfoCache()
      RETURN lRet
   ENDIF

RETURN .F.

/*------------------------------------------------------------------------*/

FUNCTION SR_LastSQLError()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):oSql:cSQLError
   ENDIF

RETURN ""

/*------------------------------------------------------------------------*/

FUNCTION SR_SetFilter(cFlt)

   LOCAL oWA
   LOCAL uRet

   IF IS_SQLRDD
      oWA := (Select())->(dbInfo(DBI_INTERNAL_OBJECT))
      uRet := oWA:cFilter
      IF !Empty(cFlt)
         oWA:cFilter := cFlt
         oWA:Refresh()
      ELSEIF HB_ISSTRING(cFlt) 
         oWA:cFilter := ""
      ENDIF
   ENDIF

RETURN uRet

/*------------------------------------------------------------------------*/

FUNCTION SR_ResetStatistics()

   IF IS_SQLRDD
      (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):ResetStatistics()
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_GetnConnection()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT):oSql:nID)
   ENDIF

RETURN 0

/*------------------------------------------------------------------------*/

FUNCTION SR_HasFilters()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):HasFilters()
   ENDIF

RETURN .F.

/*------------------------------------------------------------------------*/

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

/*------------------------------------------------------------------------*/

CLASS SqlFastHash

   DATA hHash
   DATA nPartSize

   METHOD New(nPartSize)
   METHOD Insert(uHashKey, xValue)
   METHOD Find(uHashKey, nIndex, nPart)    /* nIndex and nPart by ref */
   METHOD Delete(uHashKey)
   METHOD Update(uHashKey, uValue)
   METHOD UpdateIndex(nPos, nPart, uValue)
   METHOD Haeval(bExpr)

ENDCLASS

/*------------------------------------------------------------------------*/

METHOD Haeval(bExpr) CLASS SqlFastHash

RETURN Heval(::hHash, bExpr)

/*------------------------------------------------------------------------*/

METHOD New(nPartSize) CLASS SqlFastHash

   ::nPartSize := nPartSize
   ::hHash := {=>}
   IF nPartSize != NIL
      HSetPartition(::hHash, nPartSize)
   ENDIF

RETURN Self

/*------------------------------------------------------------------------*/

METHOD Insert(uHashKey, xValue) CLASS SqlFastHash

   IF len(::hHash) > HASH_TABLE_SIZE
      ::hHash := {=>}          /* Reset hash table */
      HB_GCALL(.T.)            /* Release memory blocks */
   ENDIF

   ::hHash[uHashKey] := xValue

RETURN .T.

/*------------------------------------------------------------------------*/

METHOD Find(uHashKey, nIndex, nPart) CLASS SqlFastHash

   LOCAL aData

   nIndex := HGetPos(::hHash, uHashKey)

   IF nIndex > 0
      aData := HGetValueAt(::hHash, nIndex)
   ENDIF

   nPart := 1     /* Compatible with old version */

RETURN aData

/*------------------------------------------------------------------------*/

METHOD Delete(uHashKey) CLASS SqlFastHash

   LOCAL nIndex := 0

   nIndex := HGetPos(::hHash, uHashKey)

   IF nIndex > 0
      HDelAt(::hHash, nIndex)
      RETURN .T.
   ENDIF

RETURN .F.

/*------------------------------------------------------------------------*/

METHOD Update(uHashKey, uValue) CLASS SqlFastHash

   LOCAL nIndex := 0

   nIndex := HGetPos(::hHash, uHashKey)

   IF nIndex > 0
      HSetValueAt(::hHash, nIndex, uValue)
      RETURN .T.
   ENDIF

RETURN .F.

/*------------------------------------------------------------------------*/

METHOD UpdateIndex(nPos, nPart, uValue) CLASS SqlFastHash

   /* nPart not used - Compatible with old version */
   HB_SYMBOL_UNUSED(nPart)
   HSetValueAt(::hHash, nPos, uValue)

RETURN .F.

/*------------------------------------------------------------------------*/

FUNCTION SR_BeginTransaction(nCnn)

   LOCAL oCnn

   IF HB_ISOBJECT(nCnn)
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
         oCnn:exec("START TRANSACTION %COMMITMODE EXPLICIT ISOLATION LEVEL READ COMMITTED")
//         oCnn:exec("START TRANSACTION %COMMITMODE EXPLICIT")
      ENDIF

   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_CommitTransaction(nCnn)

   LOCAL oCnn

   IF HB_ISOBJECT(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      IF (oCnn:nTransacCount - 1) == 0
         oCnn:Commit()
         oCnn:nTransacCount := 0
      ELSEIF (oCnn:nTransacCount - 1) > 0
         oCnn:nTransacCount --
      ENDIF
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_SetAppSite(nCnn, cSite)

   LOCAL oCnn
   LOCAL cOld

   IF HB_ISOBJECT(nCnn)
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

/*------------------------------------------------------------------------*/

FUNCTION SR_SetConnectionLogChanges(nCnn, nOpt)

   LOCAL oCnn
   LOCAL nOld

   IF HB_ISOBJECT(nCnn)
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

/*------------------------------------------------------------------------*/

FUNCTION SR_SetAppUser(nCnn, cUsername)

   LOCAL oCnn
   LOCAL cOld

   IF HB_ISOBJECT(nCnn)
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

/*------------------------------------------------------------------------*/

FUNCTION SR_SetALockWait(nCnn, nSeconds)

   LOCAL oCnn
   LOCAL nOld

   IF HB_ISOBJECT(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      nOld := oCnn:nLockWaitTime
      oCnn:nLockWaitTime := nSeconds
   ENDIF

RETURN nOld

/*------------------------------------------------------------------------*/

FUNCTION SR_RollBackTransaction(nCnn)

   LOCAL oCnn

   IF HB_ISOBJECT(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      IF oCnn:nTransacCount >  0
         oCnn:nTransacCount := 0
         // Should CLEAN UP ALL workareas BEFORE issue the ROLLBACK
         _SR_ScanExecAll({|y, x|HB_SYMBOL_UNUSED(y), aeval(x, {|z|z:Refresh(.F.)})})
         oCnn:RollBack()
      ENDIF
   ENDIF

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_TransactionCount(nCnn)

   LOCAL oCnn

   IF HB_ISOBJECT(nCnn)
      oCnn := nCnn
   ELSE
      oCnn := SR_GetConnection(nCnn)
   ENDIF

   IF oCnn != NIL
      RETURN oCnn:nTransacCount
   ENDIF

RETURN 0

/*------------------------------------------------------------------------*/

FUNCTION SR_EndTransaction(nCnn)

   LOCAL oCnn

   IF HB_ISOBJECT(nCnn)
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

/*------------------------------------------------------------------------*/

FUNCTION SR_RuntimeErr(cOperation, cErr)

   LOCAL oErr := ErrorNew()
   LOCAL cDescr

   DEFAULT cOperation TO "SQLRDD"
   DEFAULT cErr TO "RunTimeError"

   cDescr := alltrim(cErr)

   oErr:genCode       := 99
   oErr:CanDefault    := .F.
   oErr:Severity      := ES_ERROR
   oErr:CanRetry      := .T.
   oErr:CanSubstitute := .F.
   oErr:Description   := cDescr + " - RollBack executed."
   oErr:subSystem     := "SQLRDD"
   oErr:operation     := cOperation
   oErr:OsCode        := 0

   SR_LogFile("sqlerror.log", {cDescr})

   Throw(oErr)

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION dbCount()

   IF IS_SQLRDD
      RETURN (Select())->(dbInfo(DBI_INTERNAL_OBJECT)):KeyCount()
   ENDIF

RETURN 0

/*------------------------------------------------------------------------*/

FUNCTION SR_GetStack()

   LOCAL i := 1
   LOCAL cErrorLog := ""

   DO WHILE (i < 70)
      IF !Empty(ProcName(i))
         cErrorLog += SR_CRLF + Trim(ProcName(i)) + "     Linha : " + alltrim(str(ProcLine(i)))
      ENDIF
      i++
   ENDDO

RETURN cErrorLog

/*------------------------------------------------------------------------*/

/*

Alert() copied as SQLBINDBYVAL() -> DEMO banner protection

*/

//#include "hbsetup.ch"
#include "box.ch"
#include "common.ch"
#include "inkey.ch"
#include "setcurs.ch"

/* TOFIX: Clipper defines a clipped window for Alert() [vszakats] */

/* NOTE: Clipper will return NIL if the first parameter is not a string, but
         this is not documented. This implementation converts the first
         parameter to a string if another type was passed. You can switch back
         to Clipper compatible mode by defining constant
         HB_C52_STRICT. [vszakats] */

/* NOTE: Clipper handles these buttons { "Ok", "", "Cancel" } in a buggy way.
         This is fixed. [vszakats] */

/* NOTE: nDelay parameter is a Harbour extension. */

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

   /* TOFIX: Clipper decides at runtime, whether the GT is linked in,
             if it is not, the console mode is choosen here. [vszakats] */
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
         xMessage := TToC(xMessage)
         EXIT
      CASE "L"
         xMessage := iif(xMessage, ".T.", ".F.")
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
            FOR nPos := 58 TO 1 STEP -1
               IF xMessage[nPos] $ (" " + Chr(9))
                  EXIT
               ENDIF
            NEXT nPos

            IF nPos == 0
               nPos := 58
            ENDIF

            sCopy := xMessage
            aSay[HB_EnumIndex()] := RTrim(Left(xMessage, nPos))

            IF Len(aSay) == HB_EnumIndex()
               aAdd(aSay, SubStr(sCopy, nPos + 1))
            ELSE
               aIns(aSay, HB_EnumIndex() + 1, SubStr(sCopy, nPos + 1), .T.)
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

      /* NOTE: Clipper Alert does not handle second color pair properly.
               If we inform the second color pair, xHarbour alert will consider it.
               if we not inform the second color pair, then xHarbour alert will behave
               like Clipper.  2004/Sep/16 - Eduardo Fernandes <modalsist> */

      cColor11 := cColor12 := cColor21 := cColor22 := ""

      cColorStr := alltrim(StrTran(cColorNorm, " ", ""))
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

        IF !empty(cColor12)

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
      IF !empty(cColorPair2)

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

            IF !empty(cColor22)

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
         IF empty(cColor11) .OR. empty(cColor12)
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

   /* The longest line */
   nWidth := 0
   AEval(aSay, {|x|nWidth := Max(Len(x), nWidth)})

   /* Cleanup the button array */
   aOptionsOK := {}
   FOR EACH cEval IN aOptions
      IF ISCHARACTER(cEval) .AND. !Empty(cEval)
         AAdd(aOptionsOK, cEval)
      ENDIF
   NEXT

   IF Len(aOptionsOK) == 0
      aOptionsOK := {"Ok"}
#ifdef HB_C52_STRICT
   /* NOTE: Clipper allows only four options [vszakats] */
   ELSEIF Len(aOptionsOK) > 4
      aSize(aOptionsOK, 4)
#endif
   ENDIF

   /* Total width of the botton line (the one with choices) */
   nOpWidth := 0
   AEval(aOptionsOK, {|x|nOpWidth += Len(x) + 4})

   /* what's wider ? */
   nWidth := Max(nWidth + 2 + iif(Len(aSay) == 1, 4, 0), nOpWidth + 2)

   /* box coordinates */
   nInitRow := Int(((MaxRow() - (Len(aSay) + 4)) / 2) + .5)
   nInitCol := Int(((MaxCol() - (nWidth + 2)) / 2) + .5)

   /* detect prompts positions */
   aPos := {}
   aHotkey := {}
   nCurrent := nInitCol + Int((nWidth - nOpWidth) / 2) + 2
   AEval(aOptionsOK, {|x|AAdd(aPos, nCurrent), AAdd(aHotKey, Upper(Left(x, 1))), nCurrent += Len(x) + 4})

   nChoice := 1

   IF lConsole

      nCount := Len(aSay)
      FOR EACH cEval IN aSay
         OutStd(cEval)
         IF HB_EnumIndex() < nCount
            OutStd(hb_OSNewLine())
         ENDIF
      NEXT

      OutStd(" (")
      nCount := Len(aOptionsOK)
      FOR EACH cEval IN aOptionsOK
         OutStd(cEval)
         IF HB_EnumIndex() < nCount
            OutStd(", ")
         ENDIF
      NEXT
      OutStd(") ")

      /* choice loop */
      lWhile := .T.
      DO WHILE lWhile

         nKey := Inkey(nDelay, INKEY_ALL)

         SWITCH nKey
         CASE 0
            lWhile := .F.
            EXIT
         CASE K_ESC
            nChoice := 0
            lWhile  := .F.
            EXIT
         OTHERWISE
            IF Upper(Chr(nKey)) $ aHotkey
               nChoice := aScan(aHotkey, {|x|x == Upper(Chr(nKey))})
               lWhile  := .F.
            ENDIF
         ENDSWITCH

      ENDDO

      OutStd(Chr(nKey))

   ELSE

      /* PreExt */
      nCount := nOldDispCount := DispCount()

      DO WHILE nCount-- != 0
         DispEnd()
      ENDDO

      /* save status */
      nOldRow := Row()
      nOldCol := Col()
      nOldCursor := SetCursor(SC_NONE)
      cOldScreen := SaveScreen(nInitRow, nInitCol, nInitRow + Len(aSay) + 3, nInitCol + nWidth + 1)

      /* draw box */
      DispBox(nInitRow, nInitCol, nInitRow + Len(aSay) + 3, nInitCol + nWidth + 1, B_SINGLE + " ", cColorNorm)

      FOR EACH cEval IN aSay
         DispOutAt(nInitRow + HB_EnumIndex(), nInitCol + 1 + Int(((nWidth - Len(cEval)) / 2) + .5), cEval, cColorNorm)
      NEXT

      /* choice loop */
      lWhile := .T.
      DO WHILE lWhile

         nCount := Len(aSay)
         FOR EACH cEval IN aOptionsOK
            DispOutAt(nInitRow + nCount + 2, aPos[HB_EnumIndex()], " " + cEval + " ", cColorNorm)
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
            lWhile  := .F.
            EXIT
#ifdef HB_COMPAT_C53
         CASE K_LBUTTONDOWN
            nMRow  := MRow()
            nMCol  := MCol()
            nPos   := 0
            nCount := Len(aSay)
            FOR EACH cEval IN aOptionsOK
               IF nMRow == nInitRow + nCount + 2 .AND. ;
                  INRANGE(aPos[HB_EnumIndex()], nMCol, aPos[HB_EnumIndex()] + Len(cEval) + 2 - 1)
                  nPos := HB_EnumIndex()
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
               nChoice := aScan(aHotkey, {|x|x == Upper(Chr(nKey))})
               lWhile  := .F.
            ENDIF
         ENDSWITCH

      ENDDO

      /* Restore status */
      RestScreen(nInitRow, nInitCol, nInitRow + Len(aSay) + 3, nInitCol + nWidth + 1, cOldScreen)
      SetCursor(nOldCursor)
      SetPos(nOldRow, nOldCol)

      /* PostExt */
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

#include "compat.h"
#include "hbapi.h"
#include "hbapifs.h"
#include "hbapiitm.h"

#ifndef HB_PATH_MAX
#define HB_PATH_MAX   264 /* with trailing 0 byte */
#endif

/* TODO: Xbase++ has an extension where the second parameter can specify
         the required attribute. */

HB_FUNC( SR_PHFILE )
{
   PHB_ITEM pFile = hb_param(1, HB_IT_STRING);
   hb_retl((pFile && hb_itemGetCLen(pFile) < HB_PATH_MAX - 1) ? hb_spFile(hb_itemGetCPtr(pFile), NULL) : HB_FALSE);
}

#PRAGMA ENDDUMP

FUNCTION sr_AddToFilter(nRecNo)

   LOCAL oWA

   IF IS_SQLRDD
      oWA := (Select())->(dbInfo(DBI_INTERNAL_OBJECT))
      IF !Empty(oWA:cFilter)
         aadd(oWA:aRecnoFilter, nRecno)
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
   IF HB_ISNUMERIC(cDefault)
      cSql += Alltrim(str(cDefault))
   ELSEIF HB_ISSTRING(cDefault)
      IF Empty(cDefault)
         cSql += "''"
      ELSE
         cSql += "'" + cDefault + "'"
      ENDIF
   ENDIF
   IF oCnn:nSystemId == SYSTEMID_POSTGR
      oCnn:exec(cSql, , .F.)
      oCnn:Commit()
   ENDIF

RETURN NIL

FUNCTION SR_Deserialize1(cSerial, nMaxLen, lRecursive, aObj, aHash, aArray, aBlock)
RETURN HB_Deserialize(cSerial, nMaxLen, lRecursive, aObj, aHash, aArray, aBlock)
