/* $CATEGORY$SQLRDD/Parser$FILES$sql.lib$
* SQL Code Generator
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

// #include "compat.ch"
#include "error.ch"
#include "sqlrdd.ch"
#include "msg.ch"
#include "hbsql.ch"
#include "sqlrddsetup.ch"

#define SR_CRLF   (chr(13) + chr(10))

/*
* Readble Macros
*/

#define cJoinWords(nType, nSystemID)    aJoinWords[nSystemID,nType]

#define  SKIPFWD            nIP++;uData:=apCode[nIP]
#define  PARAM_SOLV         iif(HB_ISBLOCK(aParam[uData+1]),eval(aParam[uData+1]),aParam[uData+1])
#define  RECURSIVE_CALL     nIP++;cSql+=SR_SQLCodeGen2(apCode,aParam,nSystemId,lIdent,@nIP,nContext,@nSpaces,lParseTableName);Exit
#define  GETPARAM           cSql+=iif(uData+1<=len(aParam),PARAM_SOLV,"##PARAM_"+strzero(uData+1,3)+"_NOT_SUPPLIED##");nIP++;Exit
#define  GETPARAM_QUOTED    cSql+=iif(uData+1<=len(aParam),SR_DBQUALIFY(PARAM_SOLV, nSystemID),"##PARAM_"+strzero(uData+1,3)+"_NOT_SUPPLIED##");nIP++;Exit
#define  GETPARAM_VALUE     cSql+=iif(uData+1<=len(aParam),SR_SQLQuotedString(PARAM_SOLV,nSystemID),"##PARAM_"+strzero(uData+1,3)+"_NOT_SUPPLIED##");nIP++;Exit
#define  GETPARAM_VAL_2     uData:=iif(uData+1<=len(aParam),SR_DBQUALIFY(PARAM_SOLV,nSystemID),"##PARAM_"+strzero(uData+1,3)+"_NOT_SUPPLIED##")
#define  GETPARAM_VALNN     cSql+=iif(uData+1<=len(aParam),SR_SQLQuotedString(PARAM_SOLV,nSystemID,.T.),"##PARAM_"+strzero(uData+1,3)+"_NOT_NULL_NOT_SUPPLIED##");nIP++;Exit
#define  FIX_PRE_WHERE      iif(nContext==SQL_CONTEXT_SELECT_PRE_WHERE,(nContext:=SQL_CONTEXT_SELECT_WHERE,cSql+=" WHERE "),iif(nContext==SQL_CONTEXT_SELECT_PRE_WHERE2,(nContext:=SQL_CONTEXT_SELECT_WHERE,cSql+=" AND "),))
#define  PASSTHROUGH        nIP++;EXIT
#define  IDENTSPACE         space(nSpaces)
//#define  TABLE_OPTIMIZER    iif(nSystemId==SYSTEMID_MSSQL7,iif(lLocking," WITH (UPDLOCK)", " WITH (NOLOCK)"),"")
#define  TABLE_OPTIMIZER    iif(nSystemId==SYSTEMID_MSSQL7,iif(lLocking," WITH (UPDLOCK)", ""),"")
#define  COMMAND_OPTIMIZER  iif(nSystemId==SYSTEMID_SYBASE,iif(lLocking,"", " AT ISOLATION READ UNCOMMITTED "),"")
#define  SELECT_OPTIMIZER1  ""
#define  SELECT_OPTIMIZER2  iif(nSystemId==SYSTEMID_ORACLE,iif(lLocking," FOR UPDATE", ""),"")
#define  NEWLINE            iif(lIdent,SR_CRLF,"")

#xtranslate Default(<Var>, <xVal>) => IIF(<Var> == NIL, <Var> := <xVal>, NIL)

STATIC bTableInfo
STATIC bIndexInfo

STATIC nRecordNum := 0
STATIC bNextRecord
STATIC aJoinWords

/*
* SQL Code generation
*/

FUNCTION SR_SQLCodeGen(apCode, aParam, nSystemId, lIdent, lParseTableName)
RETURN   SR_SQLCodeGen2(apCode, aParam, nSystemId, lIdent, , , , lParseTableName)

STATIC FUNCTION SR_SQLCodeGen2(apCode, aParam, nSystemId, lIdent, nIP, nContext, nSpaces, lParseTableName)

   LOCAL cSql
   LOCAL nCommand
   LOCAL uData
   LOCAL nDepht
   LOCAL nErrorId
   LOCAL aRet
   LOCAL nFlt
   LOCAL cTmp
   LOCAL cAtual
   LOCAL cAtual2
   LOCAL nPos
   LOCAL cTbl
   LOCAL outer
   LOCAL aFilters := {}
   LOCAL lLocking := .F.
   LOCAL nLen := len(apCode)
   LOCAL bError := Errorblock()
   LOCAL aLJoins := {}             /* A, B, Expression */
   LOCAL aTables := {}             /* TableName */
   LOCAL aQualifiedTables := {}             /* Owner.TableName */
   LOCAL aAlias := {}
   LOCAL aOuters := {}
   LOCAL cSqlCols := ""
   LOCAL cTrailler := ""

   Default(nSystemId, SR_GetConnection():nSystemID)
   Default(nIP, 1)
   Default(aParam, {})
   //Default(nContext, SQL_CONTEXT_RESET)
   Default(lIdent, .T.)
   Default(lParseTableName, .T.)

   nContext := SQL_CONTEXT_RESET

   IF nSpaces == NIL
      nSpaces := 0
   ELSEIF lIdent
      nSpaces += 2
   ENDIF

   cSql := ""
   nDepht := 0

   BEGIN SEQUENCE

      DO WHILE .T.

         IF nIp > nLen .OR. nDepht < 0    /* nDepht controls recursivity */
            EXIT
         ENDIF

         nCommand := apCode[nIP]

         SWITCH nCommand
         CASE SQL_PCODE_SELECT
            cSql += "SELECT" + SELECT_OPTIMIZER1 + NEWLINE + IDENTSPACE + "  "
            nContext := SQL_CONTEXT_SELECT_LIST
            PASSTHROUGH
         CASE SQL_PCODE_UPDATE
            cSql += "UPDATE " + NEWLINE + IDENTSPACE + "  "
            nContext := SQL_CONTEXT_UPDATE
            PASSTHROUGH
         CASE SQL_PCODE_LOCK
            lLocking := .T.
            PASSTHROUGH
         CASE SQL_PCODE_NOLOCK
            lLocking := .F.
            PASSTHROUGH
         CASE SQL_PCODE_INSERT
            cSql += "INSERT INTO "
            nContext := SQL_CONTEXT_INSERT
            PASSTHROUGH
         CASE SQL_PCODE_INSERT_VALUES
            cSql += NEWLINE + " VALUES" + NEWLINE + IDENTSPACE + "  "
            PASSTHROUGH
         CASE SQL_PCODE_DELETE
            cSql += "DELETE FROM "
            nContext := SQL_CONTEXT_DELETE
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_NAME
            SKIPFWD
            FIX_PRE_WHERE
            cSql += SR_DBQUALIFY(uData, nSystemID)
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_BY_VALUE
            SKIPFWD
            FIX_PRE_WHERE
            cSql += SR_SQLQuotedString(uData, nSystemID, .T.)
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_PARAM
            SKIPFWD
            FIX_PRE_WHERE
            GETPARAM_VALUE
         CASE SQL_PCODE_COLUMN_PARAM_NOTNULL
            SKIPFWD
            FIX_PRE_WHERE
            GETPARAM_VALNN
         CASE SQL_PCODE_COLUMN_NAME_PARAM
            SKIPFWD
            FIX_PRE_WHERE
            GETPARAM_QUOTED
         CASE SQL_PCODE_COLUMN_BINDVAR
            SKIPFWD
            FIX_PRE_WHERE
            cSql += SR_SQLQuotedString(&uData, nSystemID, .T.)
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_NAME_BINDVAR
            SKIPFWD
            FIX_PRE_WHERE
            cSql += SR_DBQUALIFY(&uData, nSystemID)
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_ALIAS
            SKIPFWD
            FIX_PRE_WHERE
            cSql += SR_DBQUALIFY(uData, nSystemID) + "."
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_NO_AS
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_AS
            SKIPFWD
            cSql += " AS " + SR_DBQUALIFY(uData, nSystemID)
            PASSTHROUGH
         CASE SQL_PCODE_NO_WHERE
            IF len(aFilters) > 0
               cSql += NEWLINE + IDENTSPACE + "WHERE"
               FOR nFlt := 1 TO len(aFilters)
                  cSql += NEWLINE + IDENTSPACE + iif(nFlt > 1, " AND ", "  ") + aFilters[nFlt]
               NEXT nFlt
               cSql += " "
            ENDIF
            nContext := SQL_CONTEXT_RESET
            PASSTHROUGH
         CASE SQL_PCODE_WHERE
            IF len(aFilters) > 0
               cSql += NEWLINE + IDENTSPACE + "WHERE "
               FOR nFlt := 1 TO len(aFilters)
                  cSql += NEWLINE + IDENTSPACE + iif(nFlt > 1, " AND ", "  ") + aFilters[nFlt]
               NEXT nFlt
               nContext := SQL_CONTEXT_SELECT_PRE_WHERE2
            ELSE
               nContext := SQL_CONTEXT_SELECT_PRE_WHERE
            ENDIF
            PASSTHROUGH
         CASE SQL_PCODE_TABLE_NAME
            SKIPFWD
            IF lParseTableName
               aRet := eval(bTableInfo, uData, nSystemId)
               aadd(aTables, aRet[TABLE_INFO_TABLE_NAME])
               aadd(aQualifiedTables, aRet[TABLE_INFO_QUALIFIED_NAME])
               IF nContext == SQL_CONTEXT_UPDATE
                  cSql += aRet[TABLE_INFO_QUALIFIED_NAME]
                  SR_SolveFilters(aFilters, aRet, , nSystemID)
                  cSql +=  NEWLINE + " SET" + NEWLINE + "  "
               ENDIF
               IF nContext == SQL_CONTEXT_DELETE
                  cSql += aRet[TABLE_INFO_QUALIFIED_NAME]
                  SR_SolveFilters(aFilters, aRet, , nSystemID)
               ENDIF
               IF nContext == SQL_CONTEXT_INSERT
                  cSql += aRet[TABLE_INFO_QUALIFIED_NAME]
                  cSql +=  NEWLINE + IDENTSPACE + "  "
               ENDIF
            ELSE
               aadd(aTables, uData)
               aadd(aQualifiedTables, uData)
               IF nContext == SQL_CONTEXT_UPDATE
                  cSql += uData
                  cSql +=  NEWLINE + " SET" + NEWLINE + "  "
               ENDIF
               IF nContext == SQL_CONTEXT_DELETE
                  cSql += uData
               ENDIF
               IF nContext == SQL_CONTEXT_INSERT
                  cSql += uData
                  cSql +=  NEWLINE + IDENTSPACE + "  "
               ENDIF
            ENDIF
            PASSTHROUGH
         CASE SQL_PCODE_TABLE_NO_ALIAS
            aadd(aAlias, "")
            PASSTHROUGH
         CASE SQL_PCODE_TABLE_ALIAS
            SKIPFWD
            aadd(aAlias, SR_DBQUALIFY(uData, nSystemID))
            PASSTHROUGH
         CASE SQL_PCODE_TABLE_PARAM
            SKIPFWD
            IF lParseTableName
               aRet := eval(bTableInfo, iif(uData + 1 <= len(aParam), iif(HB_ISBLOCK(aParam[uData + 1]), eval(aParam[uData + 1]), aParam[uData + 1]), "##PARAM_" + strzero(uData + 1, 3) + "_NOT_SUPPLIED##"), nSystemId)
               IF nContext != SQL_CONTEXT_SELECT_FROM
                  cSql += aRet[TABLE_INFO_QUALIFIED_NAME]
               ELSE
                  aadd(aTables, aRet[TABLE_INFO_TABLE_NAME])
                  aadd(aQualifiedTables, aRet[TABLE_INFO_QUALIFIED_NAME])
               ENDIF
               IF nContext == SQL_CONTEXT_UPDATE
                  SR_SolveFilters(aFilters, aRet, , nSystemID)
                  cSql +=  NEWLINE + " SET" + NEWLINE + "  "
               ENDIF
               IF nContext == SQL_CONTEXT_DELETE
                  SR_SolveFilters(aFilters, aRet, , nSystemID)
               ENDIF
               IF nContext == SQL_CONTEXT_INSERT
                  cSql +=  NEWLINE + IDENTSPACE + "  "
               ENDIF
            ELSE
               uData := iif(uData + 1 <= len(aParam), iif(HB_ISBLOCK(aParam[uData + 1]), eval(aParam[uData + 1]), aParam[uData + 1]), "##PARAM_" + strzero(uData + 1, 3) + "_NOT_SUPPLIED##")
               IF nContext != SQL_CONTEXT_SELECT_FROM
                  cSql += uData
               ELSE
                  aadd(aTables, uData)
                  aadd(aQualifiedTables, uData)
               ENDIF
               IF nContext == SQL_CONTEXT_UPDATE
                  cSql +=  NEWLINE + " SET" + NEWLINE + "  "
               ENDIF
               IF nContext == SQL_CONTEXT_INSERT
                  cSql +=  NEWLINE + IDENTSPACE + "  "
               ENDIF
            ENDIF
            PASSTHROUGH
         CASE SQL_PCODE_TABLE_BINDVAR
            SKIPFWD
            IF lParseTableName
               aRet := eval(bTableInfo, &uData, nSystemId)
               aadd(aTables, aRet[TABLE_INFO_TABLE_NAME])
               aadd(aQualifiedTables, aRet[TABLE_INFO_QUALIFIED_NAME])
               IF nContext == SQL_CONTEXT_UPDATE
                  SR_SolveFilters(aFilters, aRet, , nSystemID)
                  cSql +=  NEWLINE + " SET" + NEWLINE + "  "
               ENDIF
               IF nContext == SQL_CONTEXT_DELETE
                  SR_SolveFilters(aFilters, aRet, , nSystemID)
               ENDIF
               IF nContext == SQL_CONTEXT_INSERT
                  cSql +=  NEWLINE + IDENTSPACE + "  "
               ENDIF
            ELSE
               uData := &uData
               aadd(aTables, uData)
               aadd(aQualifiedTables, uData)
               IF nContext == SQL_CONTEXT_UPDATE
                  cSql +=  NEWLINE + " SET" + NEWLINE + "  "
               ENDIF
               IF nContext == SQL_CONTEXT_INSERT
                  cSql +=  NEWLINE + IDENTSPACE + "  "
               ENDIF
            ENDIF
            PASSTHROUGH
         CASE SQL_PCODE_COLUMN_LIST_SEPARATOR
            IF nContext != SQL_CONTEXT_SELECT_FROM
               cSql += "," + NEWLINE + IDENTSPACE + "  "
            ENDIF
            PASSTHROUGH
         CASE SQL_PCODE_START_EXPR
            IF nContext != SQL_CONTEXT_SELECT_FROM
               FIX_PRE_WHERE
               cSql += "("
               RECURSIVE_CALL
            ELSE
               SKIPFWD
               uData := "(" + SR_SQLCodeGen2(apCode, aParam, nSystemId, lIdent, @nIP, nContext, @nSpaces, lParseTableName)
               aadd(aTables, uData)
               aadd(aQualifiedTables, uData)
               EXIT
            ENDIF
         CASE SQL_PCODE_STOP_EXPR
            cSql += ")"
            nDepht--
            PASSTHROUGH
         CASE SQL_PCODE_NOT_EXPR
            FIX_PRE_WHERE
            cSql += " NOT "
            PASSTHROUGH
         CASE SQL_PCODE_FUNC_DATE
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
               cSql += "getdate() "
               EXIT
            CASE SYSTEMID_ORACLE
               cSql += "SYSDATE "
               EXIT
            CASE SYSTEMID_IBMDB2
            CASE SYSTEMID_FIREBR
            CASE SYSTEMID_FIREBR3
            CASE SYSTEMID_POSTGR
               cSql += "CURRENT_DATE "
               EXIT
            CASE SYSTEMID_MYSQL
            Case SYSTEMID_MARIADB
               cSql += "CURDATE() "
               EXIT
            OTHERWISE
               cSql += "CURRENT_DATE "
            ENDSWITCH
            PASSTHROUGH
         CASE SQL_PCODE_FUNC_COUNT
            cSql += "COUNT("
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_COUNT_AST
            cSql += "COUNT(*"
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_ABS
            FIX_PRE_WHERE
            cSql += "ABS("
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_AVG
            FIX_PRE_WHERE
            SWITCH nSystemId
            CASE SYSTEMID_ORACLE
            CASE SYSTEMID_MSSQL7
               cSql += "AVG("
               EXIT
            OTHERWISE
               cSql += "AVERAGE("
            ENDSWITCH
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_ISNULL
            FIX_PRE_WHERE
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
               cSql += "ISNULL("
               EXIT
            CASE SYSTEMID_ORACLE
               cSql += "NVL("
               EXIT
            CASE SYSTEMID_IBMDB2
               cSql += "VALUE("
               EXIT
            CASE SYSTEMID_POSTGR
            CASE SYSTEMID_MYSQL
            Case SYSTEMID_MARIADB
               cSql += "COALESCE("
               EXIT
            OTHERWISE
               cSql += "ISNULL("
            ENDSWITCH
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_MAX
            FIX_PRE_WHERE
            cSql += "MAX("
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_MIN
            FIX_PRE_WHERE
            cSql += "MIN("
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_POWER
            FIX_PRE_WHERE
            cSql += "POWER("
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_ROUND
            FIX_PRE_WHERE
            cSql += "ROUND("
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_SUBSTR
            FIX_PRE_WHERE
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
            CASE SYSTEMID_SYBASE
               cSql += "SUBSTRING("
               EXIT
            OTHERWISE
               cSql += "SUBSTR("
            ENDSWITCH
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_SUBSTR2
            FIX_PRE_WHERE
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
            CASE SYSTEMID_SYBASE
               cSql += "SUBSTRING("
               EXIT
            OTHERWISE
               cSql += "SUBSTR("
            ENDSWITCH
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_SUM
            FIX_PRE_WHERE
            cSql += "SUM("
            RECURSIVE_CALL
         CASE SQL_PCODE_FUNC_TRIM
            FIX_PRE_WHERE
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
               cSql += "dbo.trim("
               EXIT
            OTHERWISE
               cSql += "TRIM("
            ENDSWITCH
            RECURSIVE_CALL
         CASE SQL_PCODE_SELECT_ITEM_ASTERISK
            cSql += "*"
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_ITEM_ALIAS_ASTER
            SKIPFWD
            cSql += SR_DBQUALIFY(uData, nSystemID) + ".*"
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_ALL
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_DISTINCT
            cSql += "DISTINCT "
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_NO_LIMIT
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_LIMIT
            SKIPFWD
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
            CASE SYSTEMID_CACHE
               cSql += "TOP " + ltrim(str(uData)) + " "
               EXIT
            CASE SYSTEMID_FIREBR
            CASE SYSTEMID_FIREBR3
            CASE SYSTEMID_INFORM
               cSql += "FIRST " + ltrim(str(uData)) + " "
               EXIT
            CASE SYSTEMID_MYSQL
            CASE SYSTEMID_MARIADB
            CASE SYSTEMID_POSTGR
               cTrailler := " LIMIT " + ltrim(str(uData)) + " "
               EXIT
            CASE SYSTEMID_IBMDB2
               cTrailler := " fetch first " + ltrim(str(uData)) + " rows only"
               EXIT
            ENDSWITCH
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_ORDER_ASC
            SKIPFWD
            IF uData == SQL_PCODE_COLUMN_ALIAS
               SKIPFWD
               cSql += SR_DBQUALIFY(uData, nSystemID) + "."
               SKIPFWD
            ENDIF
            SWITCH uData
            CASE SQL_PCODE_COLUMN_NAME_BINDVAR
               SKIPFWD
               cSql += SR_DBQUALIFY(&uData, nSystemID) + " ASC"
               IF nSystemId == SYSTEMID_ORACLE
                  cSql += " NULLS FIRST"
               ENDIF
               EXIT
            CASE SQL_PCODE_COLUMN_NAME_PARAM
               SKIPFWD
               GETPARAM_VAL_2
               cSql += SR_DBQUALIFY(uData, nSystemID) + " ASC"
               IF nSystemId == SYSTEMID_ORACLE
                  cSql += " NULLS FIRST"
               ENDIF
               EXIT
            OTHERWISE
               SKIPFWD
               cSql += SR_DBQUALIFY(uData, nSystemID) + " ASC"
               IF nSystemId == SYSTEMID_ORACLE
                  cSql += " NULLS FIRST"
               ENDIF
            ENDSWITCH
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_ORDER_DESC
            SKIPFWD
            IF uData == SQL_PCODE_COLUMN_ALIAS
               SKIPFWD
               cSql += SR_DBQUALIFY(uData, nSystemID) + "."
               SKIPFWD
            ENDIF
            SWITCH uData
            CASE SQL_PCODE_COLUMN_NAME_BINDVAR
               SKIPFWD
               cSql += SR_DBQUALIFY(&uData, nSystemID) + " DESC"
               IF nSystemId == SYSTEMID_ORACLE
                  cSql += " NULLS FIRST"
               ENDIF
               EXIT
            CASE SQL_PCODE_COLUMN_NAME_PARAM
               SKIPFWD
               GETPARAM_VAL_2
               cSql += SR_DBQUALIFY(uData, nSystemID) + " DESC"
               IF nSystemId == SYSTEMID_ORACLE
                  cSql += " NULLS FIRST"
               ENDIF
               EXIT
            OTHERWISE
               SKIPFWD
               cSql += SR_DBQUALIFY(uData, nSystemID) + " DESC"
               IF nSystemId == SYSTEMID_ORACLE
                  cSql += " NULLS FIRST"
               ENDIF
            ENDSWITCH
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_ORDER
            cSql += NEWLINE + IDENTSPACE + " ORDER BY "
            nContext := SQL_CONTEXT_SELECT_ORDER
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_NO_ORDER
            nContext := SQL_CONTEXT_SELECT_ORDER
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_NO_GROUPBY
            nContext := SQL_CONTEXT_SELECT_GROUP
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_GROUPBY
            cSql += NEWLINE + IDENTSPACE + " GROUP BY "
            nContext := SQL_CONTEXT_SELECT_GROUP
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_FROM
            cSqlCols := cSql
            cSql := ""
            nContext := SQL_CONTEXT_SELECT_FROM
            PASSTHROUGH
         CASE SQL_PCODE_SELECT_UNION

            /* FROM and JOIN will be included now */

            IF !Empty(cSqlCols)

               cTmp := cSql
               cSql := cSqlCols
               cSql += NEWLINE + IDENTSPACE + "FROM" + NEWLINE + IDENTSPACE + "  "
               cAtual := "$"
               cAtual2 := "$"

               aSort(aOuters,,, {|x, y|x[1] > y[1] .AND. x[2] > y[2]})

               FOR EACH outer IN aOuters
                  IF outer[1] != cAtual .AND. hb_enumIndex() > 1
                     cSql += ", "
                     cSql += SR_CRLF
                  ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                     cSql += " AND "
                  ELSEIF  hb_enumIndex() > 1
                     cSql += SR_CRLF
                  ENDIF

                  IF outer[1] != cAtual
                     nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))
                     IF nPos == 0
                        nPos := aScan(aTables, outer[1])
                     ENDIF
                     cSql += aQualifiedTables[nPos] + " " + aAlias[nPos] + NEWLINE + IDENTSPACE
                     nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                     IF nPos == 0
                        nPos := aScan(aTables, outer[2])
                     ENDIF
                     cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos] + " " + aAlias[nPos] + " ON " + outer[3]
                  ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                     cSql += outer[3]
                  ELSE
                     nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                     IF nPos == 0
                        nPos := aScan(aTables, outer[2])
                     ENDIF
                     cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos]  + " " + aAlias[nPos] + " ON " + outer[3]
                  ENDIF
                  cAtual := outer[1]
                  cAtual2 := outer[2]
               NEXT

               FOR EACH outer IN aOuters
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))

                  IF nPos == 0
                     nPos := aScan(aTables, outer[2])
                  ENDIF

                  IF nPos > 0
                     aDel(aTables, nPos)
                     aDel(aQualifiedTables, nPos)
                     aSize(aTables, len(aTables) - 1)
                     aSize(aQualifiedTables, len(aQualifiedTables) - 1)
                     aDel(aAlias, nPos)
                     aSize(aAlias, len(aAlias) - 1)
                  ENDIF

                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))

                  IF nPos == 0
                     nPos := aScan(aTables, outer[1])
                  ENDIF

                  IF nPos > 0
                     aDel(aTables, nPos)
                     aSize(aTables, len(aTables) - 1)
                     aDel(aQualifiedTables, nPos)
                     aSize(aQualifiedTables, len(aQualifiedTables) - 1)
                     aDel(aAlias, nPos)
                     aSize(aAlias, len(aAlias) - 1)
                  ENDIF

               NEXT

               IF len(aTables) > 0 .AND. len(aOuters) > 0
                  cSql += ", " + SR_CRLF
               ENDIF

               FOR EACH cTbl IN aQualifiedTables
                  cSql += cTbl + " " + aAlias[hb_enumIndex()] + " " + iif(left(cTbl, 1) != "(", TABLE_OPTIMIZER, "") + iif(hb_enumIndex() < len(aTables), "," + NEWLINE + IDENTSPACE + "  ", "")
               NEXT

               cSql += cTmp + cTrailler
               cTrailler := ""

            ENDIF

            cSql += NEWLINE + IDENTSPACE + " UNION" + NEWLINE + IDENTSPACE + "  "

            aLJoins := {}             /* A, B, Expression */
            aTables := {}             /* TableName */
            aQualifiedTables := {}
            aAlias := {}
            aOuters := {}
            cSqlCols := ""

            nContext := SQL_CONTEXT_SELECT_UNION
            PASSTHROUGH

         CASE SQL_PCODE_SELECT_UNION_ALL

            /* FROM and JOIN will be included now */

            IF !Empty(cSqlCols)

               IF nSystemId == SYSTEMID_ORACLE

                  cTmp := cSql
                  cSql := cSqlCols
                  cSql += NEWLINE + IDENTSPACE + "FROM" + NEWLINE + IDENTSPACE + "  "
                  cAtual := "$"
                  cAtual2 := "$"
                  //aSort(aOuters, , , {|x, y|x[1] > y[1] .AND. x[2] > y[2]})

                  FOR EACH outer IN aOuters
                     //IF outer[1] != cAtual .AND. hb_enumIndex() > 1
                     //   cSql += ", "
                     //   cSql += SR_CRLF
                     //ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                     IF outer[1] = cAtual .AND. outer[2] = cAtual2
                        cSql += " AND "
                     ELSEIF  hb_enumIndex() > 1
                        cSql += SR_CRLF
                     ENDIF

                     IF hb_enumIndex() = 1
                        //IF outer[1] != cAtual
                        nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))
                        IF nPos == 0
                           nPos := aScan(aTables, outer[1])
                        ENDIF
                        cSql += aQualifiedTables[nPos] + " " + aAlias[nPos] + NEWLINE + IDENTSPACE
                        nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                        IF nPos == 0
                           nPos := aScan(aTables, outer[2])
                        ENDIF
                        cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos] + " " + aAlias[nPos] + " ON " + outer[3]
                     ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                        cSql += outer[3]
                     Else
                        nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                        IF nPos == 0
                           nPos := aScan(aTables, outer[2])
                        ENDIF
                        cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos]  + " " + aAlias[nPos] + " ON " + outer[3]
                     ENDIF
                     cAtual := outer[1]
                     cAtual2 := outer[2]
                  NEXT

               Else

                  cTmp := cSql
                  cSql := cSqlCols
                  cSql += NEWLINE + IDENTSPACE + "FROM" + NEWLINE + IDENTSPACE + "  "
                  cAtual := "$"
                  cAtual2 := "$"

                  aSort(aOuters, , , {|x, y|x[1] > y[1] .AND. x[2] > y[2]})

                  FOR EACH outer IN aOuters
                     IF outer[1] != cAtual .AND. hb_enumIndex() > 1
                        cSql += ", "
                        cSql += SR_CRLF
                     ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                        cSql += " AND "
                     ELSEIF  hb_enumIndex() > 1
                        cSql += SR_CRLF
                     ENDIF

                     IF outer[1] != cAtual
                        nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))
                        IF nPos == 0
                           nPos := aScan(aTables, outer[1])
                        ENDIF
                        cSql += aQualifiedTables[nPos] + " " + aAlias[nPos] + NEWLINE + IDENTSPACE
                        nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                        IF nPos == 0
                           nPos := aScan(aTables, outer[2])
                        ENDIF
                        cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos] + " " + aAlias[nPos] + " ON " + outer[3]
                     ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                        cSql += outer[3]
                     Else
                        nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                        IF nPos == 0
                           nPos := aScan(aTables, outer[2])
                        ENDIF
                        cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos]  + " " + aAlias[nPos] + " ON " + outer[3]
                     ENDIF
                     cAtual := outer[1]
                     cAtual2 := outer[2]
                  NEXT

               ENDIF

               FOR EACH outer IN aOuters
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))

                  IF nPos == 0
                     nPos := aScan(aTables, outer[2])
                  ENDIF

                  IF nPos > 0
                     aDel(aTables, nPos)
                     aDel(aQualifiedTables, nPos)
                     aSize(aTables, len(aTables) - 1)
                     aSize(aQualifiedTables, len(aQualifiedTables) - 1)
                     aDel(aAlias, nPos)
                     aSize(aAlias, len(aAlias) - 1)
                  ENDIF

                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))

                  IF nPos == 0
                     nPos := aScan(aTables, outer[1])
                  ENDIF

                  IF nPos > 0
                     aDel(aTables, nPos)
                     aSize(aTables, len(aTables) - 1)
                     aDel(aQualifiedTables, nPos)
                     aSize(aQualifiedTables, len(aQualifiedTables) - 1)
                     aDel(aAlias, nPos)
                     aSize(aAlias, len(aAlias) - 1)
                  ENDIF

               NEXT

               IF len(aTables) > 0 .AND. len(aOuters) > 0
                  cSql += ", " + SR_CRLF
               ENDIF

               FOR EACH cTbl IN aQualifiedTables
                  cSql += cTbl + " " + aAlias[hb_enumIndex()] + " " + iif(left(cTbl, 1) != "(", TABLE_OPTIMIZER, "") + iif(hb_enumIndex() < len(aTables), "," + NEWLINE + IDENTSPACE + "  ", "")
               NEXT

               cSql += cTmp + cTrailler
               cTrailler := ""

            ENDIF

            aLJoins := {}             /* A, B, Expression */
            aTables := {}             /* TableName */
            aQualifiedTables := {}
            aAlias := {}
            aOuters := {}
            cSqlCols := ""

            cSql += NEWLINE + IDENTSPACE + " UNION ALL" + NEWLINE + IDENTSPACE + "  "
            nContext := SQL_CONTEXT_SELECT_UNION
            PASSTHROUGH
         CASE SQL_PCODE_INSERT_NO_LIST
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_BASE
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_IN
            cSql += " IN "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_NOT_IN
            cSql += " NOT IN "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_IS_NULL
            cSql += " IS NULL "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_IS_NOT_NULL
            cSql += " IS NOT NULL "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_AND
            IF       nIP + 8 <= len(apCode) ;
               .AND. apCode[nIP + 1] == SQL_PCODE_OPERATOR_BASE ;
               .AND. apCode[nIP + 2] == SQL_PCODE_COLUMN_ALIAS ;
               .AND. apCode[nIP + 4] == SQL_PCODE_COLUMN_NAME ;
               .AND. SR_IsComparOp(apCode[nIP + 6]) ;
               .AND. iif(!SR_IsComparNullOp(apCode[nIP + 6]), apCode[nIP + 7] == SQL_PCODE_COLUMN_BY_VALUE, .T.) ;
               .AND. (nFlt := aScan(aOuters, {|x|upper(x[2]) == upper(apCode[nIP + 3])})) > 0

               aOuters[nFlt, 3] += " AND " + SR_DBQUALIFY(apCode[nIP+3], nSystemID) + "." + SR_DBQUALIFY(apCode[nIP + 5], nSystemID) + SR_ComparOpText(apCode[nIP + 6]) + iif(!SR_IsComparNullOp(apCode[nIP + 6]), SR_SQLQuotedString(apCode[nIP + 8], nSystemID), "" )
               nIP += iif(SR_IsComparNullOp(apCode[nIP + 6]), 7, 9)
               EXIT
            ELSEIF nIP + 1 <= len(apCode) .AND. apCode[nIP + 1] == SQL_PCODE_OPERATOR_LEFT_OUTER_JOIN
               PASSTHROUGH
            ELSE
               IF nContext == SQL_CONTEXT_SELECT_PRE_WHERE .OR. nContext == SQL_CONTEXT_SELECT_PRE_WHERE2
                  FIX_PRE_WHERE
               ELSE
                  IF nContext == SQL_CONTEXT_SELECT_WHERE
                     nContext := SQL_CONTEXT_SELECT_PRE_WHERE2
                  ELSE
                     cSql += " AND "
                  ENDIF
               ENDIF
               PASSTHROUGH
            ENDIF
         CASE SQL_PCODE_OPERATOR_OR
            IF nContext == SQL_CONTEXT_SELECT_PRE_WHERE .OR. nContext == SQL_CONTEXT_SELECT_PRE_WHERE2
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN_OR
            ELSE
               cSql += " OR "
            ENDIF
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_EQ
            cSql += " = "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_NE
            cSql += " != "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_GT
            cSql += " > "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_GE
            cSql += " >= "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_LT
            cSql += " < "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_LE
            cSql += " <= "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_LIKE
            cSql += " LIKE "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_NOT_LIKE
            cSql += " NOT LIKE "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_PLUS
            cSql += " + "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_MINUS
            cSql += " - "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_MULT
            cSql += " * "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_DIV
            cSql += " / "
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_CONCAT
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
               cSql += " + "
               EXIT
            CASE SYSTEMID_ORACLE
            CASE SYSTEMID_POSTGR
            CASE SYSTEMID_MYSQL
            CASE SYSTEMID_MARIADB
               cSql += " || "
               EXIT
            ENDSWITCH
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_JOIN
            SWITCH nSystemId
            CASE SYSTEMID_MSSQL7
               cSql += " = "
               EXIT
            CASE SYSTEMID_ORACLE
               cSql += " = "
               EXIT
            ENDSWITCH
            PASSTHROUGH
         CASE SQL_PCODE_OPERATOR_LEFT_OUTER_JOIN
            SKIPFWD
            IF uData == SQL_PCODE_COLUMN_ALIAS
               SKIPFWD
               aadd(aOuters, {uData, , , 1})
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            IF uData == SQL_PCODE_COLUMN_NAME
               SKIPFWD
               aOuters[len(aOuters), 3] := SR_DBQUALIFY(aOuters[len(aOuters), 1], nSystemID) + "." + SR_DBQUALIFY(uData, nSystemID)
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            aOuters[len(aOuters), 3] += " = "

            IF uData == SQL_PCODE_COLUMN_ALIAS
               SKIPFWD
               aOuters[len(aOuters), 2] := uData
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            IF uData == SQL_PCODE_COLUMN_NAME
               SKIPFWD
               aOuters[len(aOuters), 3] += SR_DBQUALIFY(aOuters[len(aOuters), 2], nSystemID) + "." + SR_DBQUALIFY(uData, nSystemID)
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            EXIT

         CASE SQL_PCODE_OPERATOR_RIGHT_OUTER_JOIN
            SKIPFWD
            IF uData == SQL_PCODE_COLUMN_ALIAS
               SKIPFWD
               aadd(aOuters, {uData, , , 2})
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            IF uData == SQL_PCODE_COLUMN_NAME
               SKIPFWD
               aOuters[len(aOuters), 3] := SR_DBQUALIFY(aOuters[len(aOuters), 1], nSystemID) + "." + SR_DBQUALIFY(uData, nSystemID)
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            aOuters[len(aOuters), 3] += " = "

            IF uData == SQL_PCODE_COLUMN_ALIAS
               SKIPFWD
               aOuters[len(aOuters), 2] := uData
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            IF uData == SQL_PCODE_COLUMN_NAME
               SKIPFWD
               aOuters[len(aOuters), 3] += SR_DBQUALIFY(aOuters[len(aOuters), 2], nSystemID) + "." + SR_DBQUALIFY(uData, nSystemID)
               SKIPFWD
            ELSE
               BREAK SQL_SINTAX_ERROR_OUTER_JOIN
            ENDIF

            EXIT

         OTHERWISE
            nIP++
         ENDSWITCH

      ENDDO

      cSql += SELECT_OPTIMIZER2

      /* FROM and JOIN will be included now */

      IF !Empty(cSqlCols)

         IF nSystemId == SYSTEMID_ORACLE

            cTmp := cSql
            cSql := cSqlCols
            cSql += NEWLINE + IDENTSPACE + "FROM" + NEWLINE + IDENTSPACE + "  "
            cAtual := "$"
            cAtual2 := "$"
            //aSort(aOuters, , , {|x, y|x[1] > y[1] .AND. x[2] > y[2]})

            FOR EACH outer IN aOuters
               //IF outer[1] != cAtual .AND. hb_enumIndex() > 1
               //   cSql += ", "
               //   cSql += SR_CRLF
               //ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
               IF outer[1] = cAtual .AND. outer[2] = cAtual2
                  cSql += " AND "
               ELSEIF  hb_enumIndex() > 1
                  cSql += SR_CRLF
               ENDIF

               IF hb_enumIndex() = 1
                  //IF outer[1] != cAtual
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))
                  IF nPos == 0
                     nPos := aScan(aTables, outer[1])
                  ENDIF
                  cSql += aQualifiedTables[nPos] + " " + aAlias[nPos] + NEWLINE + IDENTSPACE
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                  IF nPos == 0
                     nPos := aScan(aTables, outer[2])
                  ENDIF
                  cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos] + " " + aAlias[nPos] + " ON " + outer[3]
               ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                  cSql += outer[3]
               Else
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                  IF nPos == 0
                     nPos := aScan(aTables, outer[2])
                  ENDIF
                  cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos]  + " " + aAlias[nPos] + " ON " + outer[3]
               ENDIF
               cAtual := outer[1]
               cAtual2 := outer[2]
            NEXT

         Else

            cTmp := cSql
            cSql := cSqlCols
            cSql += NEWLINE + IDENTSPACE + "FROM" + NEWLINE + IDENTSPACE + "  "
            cAtual := "$"
            cAtual2 := "$"

            aSort(aOuters, , , {|x, y|x[1] > y[1] .AND. x[2] > y[2]})

            FOR EACH outer IN aOuters
               IF outer[1] != cAtual .AND. hb_enumIndex() > 1
                  cSql += ", "
                  cSql += SR_CRLF
               ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                  cSql += " AND "
               ELSEIF  hb_enumIndex() > 1
                  cSql += SR_CRLF
               ENDIF

               IF outer[1] != cAtual
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))
                  IF nPos == 0
                     nPos := aScan(aTables, outer[1])
                  ENDIF
                  cSql += aQualifiedTables[nPos] + " " + aAlias[nPos] + NEWLINE + IDENTSPACE
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                  IF nPos == 0
                     nPos := aScan(aTables, outer[2])
                  ENDIF
                  cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos] + " " + aAlias[nPos] + " ON " + outer[3]
               ELSEIF outer[1] = cAtual .AND. outer[2] = cAtual2
                  cSql += outer[3]
               ELSE
                  nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))
                  IF nPos == 0
                     nPos := aScan(aTables, outer[2])
                  ENDIF
                  cSql += cJoinWords(outer[4], nSystemID) + aQualifiedTables[nPos]  + " " + aAlias[nPos] + " ON " + outer[3]
               ENDIF
               cAtual := outer[1]
               cAtual2 := outer[2]
            NEXT

         ENDIF

         FOR EACH outer IN aOuters
            nPos := aScan(aAlias, SR_DBQUALIFY(outer[2], nSystemID))

            IF nPos == 0
               nPos := aScan(aTables, outer[2])
            ENDIF

            IF nPos > 0
               aDel(aTables, nPos)
               aSize(aTables, len(aTables) - 1)
               aDel(aQualifiedTables, nPos)
               aSize(aQualifiedTables, len(aQualifiedTables) - 1)
               aDel(aAlias, nPos)
               aSize(aAlias, len(aAlias) - 1)
            ENDIF

            nPos := aScan(aAlias, SR_DBQUALIFY(outer[1], nSystemID))

            IF nPos == 0
               nPos := aScan(aTables, outer[1])
            ENDIF

            IF nPos > 0
               aDel(aTables, nPos)
               aSize(aTables, len(aTables) - 1)
               aDel(aQualifiedTables, nPos)
               aSize(aQualifiedTables, len(aQualifiedTables) - 1)
               aDel(aAlias, nPos)
               aSize(aAlias, len(aAlias) - 1)
            ENDIF

         NEXT

         IF len(aTables) > 0 .AND. len(aOuters) > 0
            cSql += ", " + SR_CRLF
         ENDIF

         FOR EACH cTbl IN aQualifiedTables
            cSql += cTbl + " " + aAlias[hb_enumIndex()] + " " + iif(left(cTbl, 1) != "(", TABLE_OPTIMIZER, "") + iif(hb_enumIndex() < len(aTables), "," + NEWLINE + IDENTSPACE + "  ", "")
         NEXT

         cSql += cTmp + cTrailler
         cTrailler := ""

      ENDIF

   RECOVER USING nErrorId

      IF HB_ISOBJECT(nErrorId)
         Eval(bError, nErrorId)
      ELSE
         SR_SQLParseError(, , "", nErrorId, , bError)
      ENDIF

   END SEQUENCE

   IF lIdent
      nSpaces -= 2
   ENDIF

   RETURN cSQL

/*
* Quoting xBase DataTypes
*/

FUNCTION SR_SQLQuotedString(uData, nSystemID, lNotNull)

   LOCAL cType := valtype(uData)
   LOCAL uElement
   LOCAL cRet := ""

   Default(lNotNull, .F.)

   IF (!lNotNull) .AND. empty(uData)
      RETURN "NULL"
   ENDIF

   IF lNotNull .AND. empty(uData) .AND. cType $ "CM"
      RETURN "'" + " " + "'"
   ENDIF

#if 0 // TODO: old code for reference (to be deleted)
   DO CASE
   CASE cType $ "CM" .AND. nSystemID == SYSTEMID_POSTGR
      RETURN [E'] + rtrim(SR_ESCAPESTRING(uData, nSystemID)) + "'"
   CASE cType $ "CM"
      RETURN "'" + rtrim(SR_ESCAPESTRING(uData, nSystemID)) + "'"
   CASE cType == "D" .AND. nSystemID == SYSTEMID_ORACLE
      RETURN ("TO_DATE('" + rtrim(DtoS(uData)) + "','YYYYMMDD')")
   CASE cType == "D" .AND. (nSystemID == SYSTEMID_IBMDB2 .OR. nSystemID == SYSTEMID_ADABAS )
      RETURN ("'" + transform(DtoS(uData), "@R 9999-99-99") + "'")
   CASE cType == "D" .AND. nSystemID == SYSTEMID_SQLBAS
      RETURN ("'" + SR_dtosdot(uData) + "'")
   CASE cType == "D" .AND. nSystemID == SYSTEMID_INFORM
      RETURN ("'" + SR_dtoUS(uData) + "'")
   CASE cType == "D" .AND. nSystemID == SYSTEMID_INGRES
      RETURN ("'" + SR_dtoDot(uData) + "'")
   CASE cType == "D" .AND. (nSystemID == SYSTEMID_FIREBR .OR. nSystemID == SYSTEMID_FIREBR3)
      RETURN "'" + transform(DtoS(uData), "@R 9999/99/99") + "'"
   CASE cType == "D" .AND. nSystemID == SYSTEMID_CACHE
      RETURN "{d '" + transform(DtoS(iif(year(uData) < 1850, stod("18500101"), uData)), "@R 9999-99-99") + "'}"
   CASE cType == "D" .AND. (nSystemID == SYSTEMID_MYSQL .OR. nSystemID == SYSTEMID_MARIADB)
      RETURN ("str_to_date( '" + dtos(uData) + "', '%Y%m%d' )")
   CASE cType == "D"
      RETURN ("'" + dtos(uData) + "'")
   CASE cType == "N"
      RETURN ltrim(str(uData))
   CASE cType == "L" .AND. nSystemID == SYSTEMID_POSTGR
      RETURN iif(uData, "true", "false")
   CASE cType == "L" .AND. nSystemID == SYSTEMID_INFORM
      RETURN iif(uData, "'t'", "'f'")
   Case cType == "L"
      RETURN iif(uData, "1", "0")
   CASE cType == "A"
      FOR EACH uElement IN uData
         cRet += iif(empty(cRet), "", ", ") + SR_SQLQuotedString(uElement, nSystemID, lNotNull)
      NEXT
      RETURN cRet
   CASE cType == "O"
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN SR_SQLQuotedString(SQL_SERIALIZED_SIGNATURE + str(len(cRet), 10) + cRet, nSystemID, lNotNull)
   ENDCASE
#endif

   SWITCH cType

   CASE "C"
   CASE "M"
      IF nSystemID == SYSTEMID_POSTGR
         RETURN "E'" + rtrim(SR_ESCAPESTRING(uData, nSystemID)) + "'"
      ELSE
         RETURN "'" + rtrim(SR_ESCAPESTRING(uData, nSystemID)) + "'"
      ENDIF

   CASE "D"
      SWITCH nSystemID
      CASE SYSTEMID_ORACLE
         RETURN "TO_DATE('" + rtrim(DtoS(uData)) + "','YYYYMMDD')"
      CASE SYSTEMID_IBMDB2
      CASE SYSTEMID_ADABAS
         RETURN "'" + transform(DtoS(uData), "@R 9999-99-99") + "'"
      CASE SYSTEMID_SQLBAS
         RETURN "'" + SR_dtosdot(uData) + "'"
      CASE SYSTEMID_INFORM
         RETURN "'" + SR_dtoUS(uData) + "'"
      CASE SYSTEMID_INGRES
         RETURN "'" + SR_dtoDot(uData) + "'"
      CASE SYSTEMID_FIREBR
      CASE SYSTEMID_FIREBR3
         RETURN "'" + transform(DtoS(uData), "@R 9999/99/99") + "'"
      CASE SYSTEMID_CACHE
         RETURN "{d '" + transform(DtoS(iif(year(uData) < 1850, stod("18500101"), uData)), "@R 9999-99-99") + "'}"
      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
         RETURN "str_to_date( '" + dtos(uData) + "', '%Y%m%d' )"
      OTHERWISE
         RETURN "'" + dtos(uData) + "'"
      ENDSWITCH

   CASE "N"
      RETURN ltrim(str(uData))

   CASE "L"
      SWITCH nSystemID
      CASE SYSTEMID_POSTGR
         RETURN iif(uData, "true", "false")
      CASE SYSTEMID_INFORM
         RETURN iif(uData, "'t'", "'f'")
      OTHERWISE
         RETURN iif(uData, "1", "0")
      ENDSWITCH

   CASE "A"
      FOR EACH uElement IN uData
         cRet += iif(empty(cRet), "", ", ") + SR_SQLQuotedString(uElement, nSystemID, lNotNull)
      NEXT
      RETURN cRet

   CASE "O"
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN SR_SQLQuotedString(SQL_SERIALIZED_SIGNATURE + str(len(cRet), 10) + cRet, nSystemID, lNotNull)

   ENDSWITCH

RETURN "NULL"

/*
*   SQLBASE date format
*/

FUNCTION SR_dtosdot(dData)

   LOCAL cData := dtos(dData)

RETURN SubStr(cData, 1, 4) + "-" + subStr(cData, 5, 2) + "-" + subStr(cData, 7, 2)

/*
*  YYYY.MM.DD
*/

FUNCTION SR_dtoDot(dData)

   LOCAL cData := dtos(dData)

RETURN SubStr(cData, 1, 4) + "." + subStr(cData, 5, 2) + "." + subStr(cData, 7, 2)

/*
*  MMDDYYYY
*/

FUNCTION SR_dtous(dData)

   LOCAL cData := dtos(dData)

RETURN subStr(cData, 5, 2) + subStr(cData, 7, 2) + SubStr(cData, 1, 4)

/*
* Error Handler
*/

STATIC FUNCTION SR_SQLParseError(arg1, arg2, cDescr, nCode, cOper, oError)

   LOCAL uRet
   LOCAL oErr := ErrorNew()

   IF arg1 != NIL .AND. arg2 != NIL
      oErr:Args := {arg1, arg2}
   ENDIF

   Default(nCode, 0)
   Default(cDescr, "SQLPARSER Error")

   oErr:GenCode := 20000 + nCode
   oErr:CanDefault := .F.
   oErr:Severity := ES_ERROR
   oErr:CanRetry := .T.
   oErr:CanSubstitute := .F.
   oErr:Description := cDescr
   oErr:Filename := ""
   oErr:SubSystem := "SQLCodGen"
   oErr:Operation := cOper
   oErr:OsCode := 0

   uRet := Eval(oError, oErr)

RETURN uRet

/*
* SQL Filters
*
*  Expected filter format example:  "<ALIAS>.ColumnName IS NULL"
*
*/

STATIC FUNCTION SR_SolveFilters(aFilters, aRet, cAlias, nSystemID)

   LOCAL i

   IF !(HB_ISARRAY(aRet) .AND. len(aRet) >= 2 .AND. HB_ISCHAR(aRet[1]))
      RETURN .F.
   ENDIF

   Default(nSystemID, SR_GetConnection():nSystemID)
   Default(cAlias, SR_DBQUALIFY(aRet[TABLE_INFO_TABLE_NAME], nSystemID))

   FOR i := 1 TO len(aRet[TABLE_INFO_FILTERS])
      IF SR_EvalFilters()
         aadd(aFilters, &(StrTran(aRet[TABLE_INFO_FILTERS, i], "<ALIAS>", cAlias)))
      ELSE
         aadd(aFilters, StrTran(aRet[TABLE_INFO_FILTERS, i], "<ALIAS>", cAlias ))
      ENDIF
   NEXT i

RETURN .T.

/*
* Startup settings
*/

PROCEDURE __SR_StartSQL()

   bTableInfo := {|cTableName, nSystemID|SR_TableAttr(cTableName, nSystemID)}
   bIndexInfo := {|cIndexName, nSystemID|SR_IndexAttr(cIndexName, nSystemID)}
   bNextRecord := {||++nRecordNum}
   aJoinWords := Array(SUPPORTED_DATABASES)
   aFill(aJoinWords, {" LEFT OUTER JOIN ", " RIGHT OUTER JOIN ", " LEFT JOIN ", " RIGHT JOIN ", " JOIN "})

RETURN

/*------------------------------------------------------------------------*/

FUNCTION SR_SetTableInfoBlock(b)

   IF !HB_ISBLOCK(b)
      RETURN .F.
   ENDIF

   bTableInfo := b

RETURN .T.

/*------------------------------------------------------------------------*/

FUNCTION SR_SetIndexInfoBlock(b)

   IF !HB_ISBLOCK(b)
      RETURN .F.
   ENDIF

   bIndexInfo := b

RETURN .T.

/*------------------------------------------------------------------------*/

FUNCTION SR_GetTableInfoBlock()

RETURN bTableInfo

/*------------------------------------------------------------------------*/

FUNCTION SR_GetIndexInfoBlock()

RETURN bIndexInfo

/*------------------------------------------------------------------------*/

FUNCTION SR_SetNextRecordBlock(b)

   IF !HB_ISBLOCK(b)
      RETURN .F.
   ENDIF

   bNextRecord := b

RETURN .T.

/*------------------------------------------------------------------------*/

FUNCTION SR_GetNextRecordBlock()

RETURN bNextRecord

/*
* Version Report
*/

FUNCTION SR_ParserVersion()

   LOCAL nVers := 1

RETURN nVers


/*
*
*   Debug Functions
*
*/

FUNCTION SR_pCodeDescr(nCode)

   LOCAL nFound

   STATIC apCode := {{"SQL_PCODE_SELECT",                     0}, ;
                     {"SQL_PCODE_INSERT",                     1}, ;
                     {"SQL_PCODE_UPDATE",                     2}, ;
                     {"SQL_PCODE_DELETE",                     3}, ;
                     {"SQL_PCODE_COLUMN_NAME",                4}, ;
                     {"SQL_PCODE_COLUMN_BY_VALUE",            5}, ;
                     {"SQL_PCODE_COLUMN_PARAM",               6}, ;
                     {"SQL_PCODE_COLUMN_BINDVAR",             7}, ;
                     {"SQL_PCODE_COLUMN_ALIAS",               8}, ;
                     {"SQL_PCODE_COLUMN_NO_AS",               9}, ;
                     {"SQL_PCODE_COLUMN_AS",                  10}, ;
                     {"SQL_PCODE_COLUMN_NAME_BINDVAR",        11}, ;
                     {"SQL_PCODE_COLUMN_NAME_PARAM",          12}, ;
                     {"SQL_PCODE_COLUMN_PARAM_NOTNULL",       13}, ;
                     {"SQL_PCODE_LOCK",                       20}, ;
                     {"SQL_PCODE_NOLOCK",                     21}, ;
                     {"SQL_PCODE_NO_WHERE",                   22}, ;
                     {"SQL_PCODE_WHERE",                      23}, ;
                     {"SQL_PCODE_TABLE_NAME",                 25}, ;
                     {"SQL_PCODE_TABLE_NO_ALIAS",             26}, ;
                     {"SQL_PCODE_TABLE_ALIAS",                27}, ;
                     {"SQL_PCODE_TABLE_PARAM",                28}, ;
                     {"SQL_PCODE_TABLE_BINDVAR",              29}, ;
                     {"SQL_PCODE_COLUMN_LIST_SEPARATOR",      80}, ;
                     {"SQL_PCODE_START_EXPR",                 100}, ;
                     {"SQL_PCODE_STOP_EXPR",                  101}, ;
                     {"SQL_PCODE_NOT_EXPR",                   102}, ;
                     {"SQL_PCODE_FUNC_COUNT_AST",             200}, ;
                     {"SQL_PCODE_FUNC_COUNT",                 201}, ;
                     {"SQL_PCODE_FUNC_ABS",                   202}, ;
                     {"SQL_PCODE_FUNC_AVG",                   203}, ;
                     {"SQL_PCODE_FUNC_ISNULL",                204}, ;
                     {"SQL_PCODE_FUNC_MAX",                   205}, ;
                     {"SQL_PCODE_FUNC_MIN",                   206}, ;
                     {"SQL_PCODE_FUNC_POWER              ",   207}, ;
                     {"SQL_PCODE_FUNC_ROUND              ",   208}, ;
                     {"SQL_PCODE_FUNC_SUBSTR             ",   209}, ;
                     {"SQL_PCODE_FUNC_SUBSTR2            ",   210}, ;
                     {"SQL_PCODE_FUNC_SUM                ",   211}, ;
                     {"SQL_PCODE_FUNC_TRIM               ",   212}, ;
                     {"SQL_PCODE_FUNC_DATE               ",   213}, ;
                     {"SQL_PCODE_SELECT_ITEM_ASTERISK    ",   300}, ;
                     {"SQL_PCODE_SELECT_ITEM_ALIAS_ASTER ",   301}, ;
                     {"SQL_PCODE_SELECT_ALL              ",   302}, ;
                     {"SQL_PCODE_SELECT_DISTINCT         ",   303}, ;
                     {"SQL_PCODE_SELECT_NO_LIMIT         ",   304}, ;
                     {"SQL_PCODE_SELECT_LIMIT            ",   305}, ;
                     {"SQL_PCODE_SELECT_ORDER_ASC        ",   306}, ;
                     {"SQL_PCODE_SELECT_ORDER_DESC       ",   307}, ;
                     {"SQL_PCODE_SELECT_ORDER            ",   308}, ;
                     {"SQL_PCODE_SELECT_NO_ORDER         ",   309}, ;
                     {"SQL_PCODE_SELECT_NO_GROUPBY       ",   310}, ;
                     {"SQL_PCODE_SELECT_GROUPBY          ",   311}, ;
                     {"SQL_PCODE_SELECT_FROM             ",   312}, ;
                     {"SQL_PCODE_SELECT_UNION            ",   313}, ;
                     {"SQL_PCODE_SELECT_UNION_ALL        ",   314}, ;
                     {"SQL_PCODE_INSERT_NO_LIST          ",   400}, ;
                     {"SQL_PCODE_INSERT_VALUES           ",   401}, ;
                     {"SQL_PCODE_OPERATOR_BASE           ",   1000}, ;
                     {"SQL_PCODE_OPERATOR_IN             ",   1002}, ;
                     {"SQL_PCODE_OPERATOR_NOT_IN         ",   1003}, ;
                     {"SQL_PCODE_OPERATOR_IS_NULL        ",   1004}, ;
                     {"SQL_PCODE_OPERATOR_IS_NOT_NULL    ",   1005}, ;
                     {"SQL_PCODE_OPERATOR_AND            ",   1006}, ;
                     {"SQL_PCODE_OPERATOR_OR             ",   1007}, ;
                     {"SQL_PCODE_OPERATOR_EQ             ",   1008}, ;
                     {"SQL_PCODE_OPERATOR_NE             ",   1009}, ;
                     {"SQL_PCODE_OPERATOR_GT             ",   1010}, ;
                     {"SQL_PCODE_OPERATOR_GE             ",   1011}, ;
                     {"SQL_PCODE_OPERATOR_LT             ",   1012}, ;
                     {"SQL_PCODE_OPERATOR_LE             ",   1013}, ;
                     {"SQL_PCODE_OPERATOR_LIKE           ",   1014}, ;
                     {"SQL_PCODE_OPERATOR_NOT_LIKE       ",   1020}, ;
                     {"SQL_PCODE_OPERATOR_PLUS           ",   1015}, ;
                     {"SQL_PCODE_OPERATOR_MINUS          ",   1016}, ;
                     {"SQL_PCODE_OPERATOR_MULT           ",   1017}, ;
                     {"SQL_PCODE_OPERATOR_DIV            ",   1018}, ;
                     {"SQL_PCODE_OPERATOR_CONCAT         ",   1019}, ;
                     {"SQL_PCODE_OPERATOR_JOIN           ",   1100}, ;
                     {"SQL_PCODE_OPERATOR_LEFT_OUTER_JOIN",   1101}, ;
                     {"SQL_PCODE_OPERATOR_RIGHT_OUTER_JOIN",  1102}}

   IF !HB_ISNUMERIC(nCode)
      RETURN nCode
   ENDIF

   nFound := aScan(apCode, {|x|x[2] == nCode})

   IF nFound > 0
      RETURN apCode[nFound, 1]
   ENDIF

RETURN nCode

/*------------------------------------------------------------------------*/

FUNCTION SR_TableAttr(cTableName, nSystemID)

   /* Translates "c:\data\accounts\chart.dbf" to "DATA_ACCONTS_CHART" */

   LOCAL aRet
   LOCAL cOwner := ""
   LOCAL cSlash

   IF substr(cTableName, 2, 1) == ":"
      /* Remove drive letter */
      cTableName := SubStr(cTableName, 3)
   ENDIF

   IF "\" $ cTableName .OR. "/" $ cTableName    // This may keep compatible with xHB 1.2
      IF "/" $ cTableName
        cSlash := "/"
      ELSE
        cSlash := "\"
      ENDIF
      IF SubStr(cTableName, 2, rat(cSlash, cTableName) - 2) == CurDir()
         cTableName := SubStr(cTableName, Rat(cSlash, cTableName) + 1)
      ENDIF
   ENDIF

   cTableName := strtran(alltrim(lower(cTableName)), ".dbf", "_dbf")
   cTableName := strtran(cTableName, ".ntx", "")
   cTableName := strtran(cTableName, ".cdx", "")
   cTableName := strtran(cTableName, "\", "_")
   IF substr(cTableName, 1, 1) == "/"
      cTableName := SubStr(cTableName, 2)
   ENDIF
   cTableName := strtran(cTableName, "/", "_")
   cTableName := strtran(cTableName, ".", "_")
   cTableName := alltrim(cTableName)

   IF len(cTableName) > 30
      cTableName := SubStr(cTableName, len(cTableName) - 30 + 1)
   ENDIF

   cOwner := SR_SetGlobalOwner()
   IF (!Empty(cOwner)) .AND. right(cOwner, 1) != "."
      cOwner += "."
   ENDIF

   aRet := {upper(cTableName),;
            {},;
            "",;
            TABLE_INFO_RELATION_TYPE_OUTER_JOIN,;
            SR_SetGlobalOwner(),;
            NIL,;
            "",;
            .T.,;
            .T.,;
            .T.,;
            .F.,;
            ,;
            ,;
            ,;
            cOwner + SR_DBQUALIFY(cTableName, nSystemID) }

RETURN aRet

/*------------------------------------------------------------------------*/

FUNCTION SR_IndexAttr(cTableName, nSystemID)

   /* Translates "c:\data\accounts\chart.dbf" to "DATA_ACCONTS_CHART" */

   LOCAL aRet
   LOCAL cSlash

   HB_SYMBOL_UNUSED(nSystemID)

   IF substr(cTableName, 2, 1) == ":"
      /* Remove drive letter */
      cTableName := SubStr(cTableName, 3)
   ENDIF

   IF "\" $ cTableName .OR. "/" $ cTableName    // This may keep compatible with xHB 1.2
      IF "/" $ cTableName
        cSlash := "/"
      ELSE
        cSlash := "\"
      ENDIF
      IF SubStr(cTableName, 2, rat(cSlash, cTableName) - 2) == CurDir()
         cTableName := SubStr(cTableName, Rat(cSlash, cTableName) + 1)
      ENDIF
   ENDIF

   cTableName := strtran(alltrim(lower(cTableName)), ".dbf", "_dbf")
   cTableName := strtran(cTableName, ".ntx", "")
   cTableName := strtran(cTableName, ".cdx", "")
   cTableName := strtran(cTableName, "\", "_")
   IF substr(cTableName, 1, 1) == "/"
      cTableName := SubStr(cTableName, 2)
   ENDIF
   cTableName := strtran(cTableName, "/", "_")
   cTableName := strtran(cTableName, ".", "_")
   cTableName := alltrim(cTableName)

   IF len(cTableName) > 30
      cTableName := SubStr(cTableName, len(cTableName) - 30 + 1)
   ENDIF

   aRet := {upper(cTableName), {}, "", TABLE_INFO_RELATION_TYPE_OUTER_JOIN, SR_SetGlobalOwner(), .F., "", .T., .T., .T., .F., ,}

RETURN aRet

/*------------------------------------------------------------------------*/

STATIC FUNCTION SR_IsComparOp(nOp)

   SWITCH nOp
   CASE SQL_PCODE_OPERATOR_EQ
   CASE SQL_PCODE_OPERATOR_NE
   CASE SQL_PCODE_OPERATOR_GT
   CASE SQL_PCODE_OPERATOR_GE
   CASE SQL_PCODE_OPERATOR_LT
   CASE SQL_PCODE_OPERATOR_LE
   CASE SQL_PCODE_OPERATOR_LIKE
   CASE SQL_PCODE_OPERATOR_NOT_LIKE
   CASE SQL_PCODE_OPERATOR_IS_NULL
   CASE SQL_PCODE_OPERATOR_IS_NOT_NULL
      RETURN .T.
   ENDSWITCH

RETURN .F.

/*------------------------------------------------------------------------*/

STATIC FUNCTION SR_IsComparNullOp(nOp)

   SWITCH nOp
   CASE SQL_PCODE_OPERATOR_IS_NULL
   CASE SQL_PCODE_OPERATOR_IS_NOT_NULL
      RETURN .T.
   ENDSWITCH

RETURN .F.

/*------------------------------------------------------------------------*/

STATIC FUNCTION SR_ComparOpText(nOp)

   LOCAL cSql := ""

   SWITCH nOp
   CASE SQL_PCODE_OPERATOR_EQ
      cSql += " = "
      EXIT
   CASE SQL_PCODE_OPERATOR_NE
      cSql += " != "
      EXIT
   CASE SQL_PCODE_OPERATOR_GT
      cSql += " > "
      EXIT
   CASE SQL_PCODE_OPERATOR_GE
      cSql += " >= "
      EXIT
   CASE SQL_PCODE_OPERATOR_LT
      cSql += " < "
      EXIT
   CASE SQL_PCODE_OPERATOR_LE
      cSql += " <= "
      EXIT
   CASE SQL_PCODE_OPERATOR_LIKE
      cSql += " LIKE "
      EXIT
   CASE SQL_PCODE_OPERATOR_NOT_LIKE
      cSql += " NOT LIKE "
      EXIT
   CASE SQL_PCODE_OPERATOR_IS_NULL
      cSql += " IS NULL "
      EXIT
   CASE SQL_PCODE_OPERATOR_IS_NOT_NULL
      cSql += " IS NOT NULL "
      EXIT
   ENDSWITCH

RETURN cSql

/*------------------------------------------------------------------------*/
