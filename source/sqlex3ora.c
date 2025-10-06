//
// SQLEX Auxiliar File for SEEK routines
// Copyright (c) 2009 - Marcelo Lombardo  <lombardo@uol.com.br>
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

#include "compat.h"
#include <hbinit.h>
#include "msg.ch"
#include <rddsys.ch>
#include <hbdbferr.h>
#include "sqlrddsetup.ch"
#include "sqlprototypes.h"
#include <ctype.h>
#include <assert.h>
#include "ocilib.h"
#include "sqlexora.h"

#define LOGFILE "oci2.log"

//------------------------------------------------------------------------

extern HB_ERRCODE FeedSeekStmtOra(SQLEXORAAREAP thiswa, int queryLevel);

//------------------------------------------------------------------------

static void createSeekQueryOra(SQLEXORAAREAP thiswa, HB_BOOL bUseOptimizerHints)
{
  if (getColumnListOra(thiswa)) {
    thiswa->bConditionChanged1 = HB_TRUE; // SEKIP statements are no longer valid - column list has changed!
  }
  if (thiswa->sSql) {
    memset(thiswa->sSql, 0, MAX_SQL_QUERY_LEN * sizeof(char));
  }
  if (bUseOptimizerHints) {
    if (thiswa->bOracle12) {
      sprintf(thiswa->sSql, "SELECT %s \nFROM %s A %s FETCH FIRST 1 ROWS ONLY", thiswa->sFields, thiswa->sTable,
              thiswa->sWhere);
    } else {
      sprintf(thiswa->sSql, "SELECT /*+ INDEX_ASC( A %s ) */ %s %s \nFROM %s A %s AND ROWNUM <= 1",
              thiswa->sOrderBy, // thiswa->sOrderBy has the index name, not the index column list
              thiswa->sLimit1, thiswa->sFields, thiswa->sTable, thiswa->sWhere);
    }
  } else {
    sprintf(thiswa->sSql, "SELECT %s %s \nFROM %s A %s %s %s", thiswa->sLimit1, thiswa->sFields, thiswa->sTable,
            thiswa->sWhere,
            thiswa->sOrderBy, // thiswa->sOrderBy has the index column list
            thiswa->sLimit2);
  }
  // sr_TraceLog("aaa.log", "query %s\n", thiswa->sSql);
}

//------------------------------------------------------------------------

static HB_ERRCODE getSeekWhereExpressionOra(SQLEXORAAREAP thiswa, int iListType, int queryLevel,
                                            HB_BOOL *bUseOptimizerHints)
{
  HB_BOOL bWhere = HB_FALSE;
  int iCol;
  INDEXBINDORAP SeekBind;
  COLUMNBINDORAP BindStructure;
  HB_BOOL bDirectionFWD;
  char *temp;

  thiswa->sWhere[0] = '\0';

  SeekBind = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];
  // Nao necessario esta aqui, fazia com que fosse para o ultimo item da chave
  // SeekBind += (queryLevel - 1); // place offset

  thiswa->recordListDirection = (iListType == LIST_SKIP_FWD ? LIST_FORWARD : LIST_BACKWARD);
  bDirectionFWD = iListType == LIST_SKIP_FWD;

  if (thiswa->bReverseIndex) {
    bDirectionFWD = !bDirectionFWD;
  }

  for (iCol = 1; iCol <= queryLevel; iCol++) {
    BindStructure = GetBindStructOra(thiswa, SeekBind);

    if (BindStructure->isArgumentNull) {
      *bUseOptimizerHints = HB_FALSE; // We cannot use this high speed solution
                                      // because Oracle does not store NULLs in indexes

      if (BindStructure->iCType == SQL_C_DOUBLE) {
        temp = hb_strdup((const char *)thiswa->sWhere);
        sprintf(thiswa->sWhere, "%s %s ( A.%c%s%c %s %s OR A.%c%s%c IS NULL )", bWhere ? temp : "\nWHERE",
                bWhere ? "AND" : "", OPEN_QUALIFIER(thiswa), BindStructure->colName, CLOSE_QUALIFIER(thiswa),
                iCol == queryLevel ? (bDirectionFWD ? ">=" : "<=") : "IS", iCol == queryLevel ? "0" : "NULL",
                OPEN_QUALIFIER(thiswa), BindStructure->colName, CLOSE_QUALIFIER(thiswa));
        hb_xfree(temp);
      } else {
        if (iCol == queryLevel && iListType == LIST_SKIP_FWD) {
          // This condition should create a WHERE clause like "COLUMN >= NULL".
          // Since this is not numeric, EVERYTHING is greater
          // or equal to NULL, so we do not add any restriction to WHERE clause.
        } else {
          temp = hb_strdup((const char *)thiswa->sWhere);
          sprintf(thiswa->sWhere, "%s %s A.%c%s%c IS NULL", bWhere ? temp : "\nWHERE", bWhere ? "AND" : "",
                  OPEN_QUALIFIER(thiswa), BindStructure->colName, CLOSE_QUALIFIER(thiswa));
          hb_xfree(temp);
        }
      }
    } else {
      temp = hb_strdup((const char *)thiswa->sWhere);
      sprintf(thiswa->sWhere, "%s %s A.%c%s%c %s :%s", bWhere ? temp : "\nWHERE", bWhere ? "AND" : "",
              OPEN_QUALIFIER(thiswa), BindStructure->colName, CLOSE_QUALIFIER(thiswa),
              iCol == queryLevel ? (bDirectionFWD ? ">=" : "<=") : "=", BindStructure->colName);
      hb_xfree(temp);
    }
    bWhere = HB_TRUE;
    // Culik Movido a posicao do seekbind para essa posicao, onde estava assumuia que o inicio era o ultimo item da
    // chave
    SeekBind++; // place offset
  }

  SolveFiltersOra(thiswa, bWhere);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

HB_ERRCODE prepareSeekQueryOra(SQLEXORAAREAP thiswa, INDEXBINDORAP SeekBind)
{
  // res = SQLAllocStmt((HDBC) thiswa->hDbc, &hPrep);
  // hPrep = OCI_StatementCreate(GetConnection(thiswa->hDbc));

  if (thiswa->recordListDirection == LIST_FORWARD) {
    SeekBind->SeekFwdStmt = OCI_StatementCreate(GetConnection(thiswa->hDbc));
  } else {
    SeekBind->SeekBwdStmt = OCI_StatementCreate(GetConnection(thiswa->hDbc));
  }

  if (thiswa->recordListDirection == LIST_FORWARD) {
    if (SeekBind->SeekFwdStmt == SR_NULLPTR) {
      return HB_FAILURE;
    }
  } else {
    if (SeekBind->SeekBwdStmt == SR_NULLPTR) {
      return HB_FAILURE;
    }
  }

  // if (hPrep == NULL) {
  //   return HB_FAILURE;
  // }
  OCI_AllowRebinding(thiswa->recordListDirection == LIST_FORWARD ? SeekBind->SeekFwdStmt : SeekBind->SeekBwdStmt, 1);

  if (!OCI_Prepare(thiswa->recordListDirection == LIST_FORWARD ? SeekBind->SeekFwdStmt : SeekBind->SeekBwdStmt,
                   thiswa->sSql)) {
    return HB_FAILURE;
  }

  if (thiswa->recordListDirection == LIST_FORWARD) {
    memset(&SeekBind->SeekFwdSql, 0, PREPARED_SQL_LEN);
    hb_xmemcpy(SeekBind->SeekFwdSql, thiswa->sSql, PREPARED_SQL_LEN - 1);
    SeekBind->SeekFwdSql[PREPARED_SQL_LEN - 1] = '\0';
  } else {
    memset(&SeekBind->SeekBwdSql, 0, PREPARED_SQL_LEN);
    hb_xmemcpy(SeekBind->SeekBwdSql, thiswa->sSql, PREPARED_SQL_LEN - 1);
    SeekBind->SeekBwdSql[PREPARED_SQL_LEN - 1] = '\0';
  }

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

HB_BOOL CreateSeekStmtora(SQLEXORAAREAP thiswa, int queryLevel)
{
  PHB_ITEM pColumns, pIndexRef;
  INDEXBINDORAP SeekBind;
  HB_BOOL bUseOptimizerHints;

  bUseOptimizerHints = thiswa->nSystemID == SYSTEMID_ORACLE;
  thiswa->bConditionChanged1 = HB_TRUE; // SKIP statements are no longer valid

  // Alloc memory for binding structures, if first time

  if (!thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent]) {
    SetIndexBindStructureOra(thiswa);
  }

  SeekBind = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];
  // SeekBind += (queryLevel - 1); // place offset

  // Check if stmt must be created or recreated

  if (thiswa->bConditionChanged2 || thiswa->bRebuildSeekQuery ||
      (thiswa->recordListDirection == LIST_FORWARD && (!SeekBind->SeekFwdStmt)) ||
      (thiswa->recordListDirection == LIST_BACKWARD && (!SeekBind->SeekBwdStmt))) {

    pIndexRef = hb_arrayGetItemPtr(thiswa->sqlarea.aOrders, (HB_ULONG)thiswa->sqlarea.hOrdCurrent);
    pColumns = hb_arrayGetItemPtr(pIndexRef, INDEX_FIELDS);
    thiswa->indexColumns = hb_arrayLen(pColumns);

    // Free the statements we are about to recreate

    if (SeekBind->SeekFwdStmt) {
      OCI_StatementFree(SeekBind->SeekFwdStmt);
      SeekBind->SeekFwdStmt = SR_NULLPTR;
    }

    if (SeekBind->SeekBwdStmt) {
      OCI_StatementFree(SeekBind->SeekBwdStmt);
      SeekBind->SeekBwdStmt = SR_NULLPTR;
    }

    getSeekWhereExpressionOra(thiswa, thiswa->recordListDirection == LIST_FORWARD ? LIST_SKIP_FWD : LIST_SKIP_BWD,
                              queryLevel, &bUseOptimizerHints);
    getOrderByExpressionOra(thiswa, bUseOptimizerHints);
    setResultSetLimitOra(thiswa, 1);
    createSeekQueryOra(thiswa, bUseOptimizerHints);

    prepareSeekQueryOra(thiswa, SeekBind);
    thiswa->bOrderChanged = HB_FALSE; // we set to use the new key after enter here, so we disable for next seek
    return HB_TRUE;
  } else {
    return HB_FALSE;
  }
}

//------------------------------------------------------------------------

HB_ERRCODE FeedSeekKeyToBindingsOra(SQLEXORAAREAP thiswa, PHB_ITEM pKey, int *queryLevel)
{
  INDEXBINDORAP SeekBind;
  COLUMNBINDORAP BindStructure;
  int i, lenKey, size, iCol;
  const char *szKey;

  SeekBind = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];

  if (thiswa->sqlarea.hOrdCurrent != SeekBind->hIndexOrder) { // || thiswa->bOrderChanged )
    // SeekBindings is not constructed based on same index order as
    // previous SEEK, so we must reconstruct thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent]
    // based on current index

    thiswa->bConditionChanged2 = HB_TRUE;                // Force SEEK query to be rebuilt
    SeekBind->hIndexOrder = thiswa->sqlarea.hOrdCurrent; // Store latest prepared index order query

    for (iCol = 1; iCol <= thiswa->indexColumns; iCol++) {
      BindStructure = GetBindStructOra(thiswa, SeekBind);

      if (!thiswa->sqlarea.uiFieldList[(BindStructure->lFieldPosDB) - 1]) {
        thiswa->sqlarea.uiFieldList[(BindStructure->lFieldPosDB) - 1] = HB_TRUE; // Force index columns to be present in
                                                                                 // query cos sqlKeyCompare will need it
        thiswa->sqlarea.iFieldListStatus = FIELD_LIST_CHANGED;
      }

      SeekBind->iLevel = iCol;
      SeekBind->iIndexColumns = thiswa->indexColumns;
      BindStructure->isArgumentNull = HB_FALSE;

      // Free previous statements

      if (SeekBind->SeekFwdStmt) {
        OCI_StatementFree(SeekBind->SeekFwdStmt);
        SeekBind->SeekFwdStmt = SR_NULLPTR;
      }
      if (SeekBind->SeekBwdStmt) {
        OCI_StatementFree(SeekBind->SeekBwdStmt);
        SeekBind->SeekBwdStmt = SR_NULLPTR;
      }

      SeekBind++;
    }
    SeekBind = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent]; // Reset position to 1st index column
  }

  // Push pKey value splitted into SeekBindings structures

  if (HB_IS_STRING(pKey)) {
    // parse Key string and split it in index fields

    lenKey = hb_itemGetCLen(pKey);
    szKey = hb_itemGetCPtr(pKey);
    *queryLevel = thiswa->indexColumns;

    for (i = 1; i <= thiswa->indexColumns; i++) {
      BindStructure = GetBindStructOra(thiswa, SeekBind);
      size = 0;

      switch (BindStructure->iCType) {
      case SQL_C_CHAR: {
        int nTrim, i;
        size = lenKey > (int)(BindStructure->ColumnSize) ? ((int)(BindStructure->ColumnSize)) : lenKey;
        nTrim = size;

        // RTrim() the string value

        for (i = (size - 1); i >= 0; i--) {
          if (szKey[i] == '\0' || szKey[i] != ' ') {
            nTrim = i + 1;
            break;
          }
        }
        if (i < 0) {
          nTrim = 0;
        }

        if (nTrim == 0) {
          // We have a NULL argument to SEEK for

          if (!(BindStructure->isNullable)) {
            // Column cannot be NULL by definition, so
            // SQLRDD uses 1 blank space in it
            // This is an SQLRDD rule.

            BindStructure->asChar.value[0] = ' ';
            BindStructure->asChar.value[1] = '\0';
          } else {
            BindStructure->asChar.value[0] = '\0';
            if (BindStructure->isArgumentNull == HB_FALSE) { // Check if NULL status has changed
              thiswa->bRebuildSeekQuery = HB_TRUE;
            }
            BindStructure->isArgumentNull = HB_TRUE;
          }
        } else {
          hb_xmemcpy(BindStructure->asChar.value, szKey, nTrim);
          BindStructure->asChar.value[nTrim] = '\0';
          if (BindStructure->isArgumentNull) { // Check if NULL status has changed
            thiswa->bRebuildSeekQuery = HB_TRUE;
            BindStructure->isArgumentNull = HB_FALSE;
          }
        }
        break;
      }
      case SQL_C_NUMERIC: {
        size = BindStructure->ColumnSize;
        BindStructure->asNumeric = (HB_LONG)hb_strVal(szKey, BindStructure->ColumnSize);
        break;
      }
      case SQL_C_DOUBLE: {
        size = BindStructure->ColumnSize;
        BindStructure->asDouble = (double)hb_strVal(szKey, BindStructure->ColumnSize);
        break;
      }
      case SQL_C_TYPE_TIMESTAMP: {
        int iPos;
        HB_LONG lVal;
        double dVal;

        char datemask[9] = "10000101";
        char *mask = datemask;

        size = lenKey > (int)(BindStructure->ColumnSize) ? ((int)(BindStructure->ColumnSize)) : lenKey;

        // Must fix partial date seek
        for (iPos = 0; iPos < size; iPos++) {
          datemask[iPos] = szKey[iPos];
        }

        hb_compStrToNum(datemask, 4, &lVal, &dVal, SR_NULLPTR, SR_NULLPTR);
        BindStructure->asTimestamp.year = (unsigned int)lVal;
        mask += 4;
        hb_compStrToNum(mask, 2, &lVal, &dVal, SR_NULLPTR, SR_NULLPTR);
        BindStructure->asTimestamp.month = (unsigned int)lVal;
        mask += 2;
        hb_compStrToNum(mask, 2, &lVal, &dVal, SR_NULLPTR, SR_NULLPTR);
        BindStructure->asTimestamp.day = (unsigned int)lVal;
        BindStructure->asTimestamp.hour = 0;
        BindStructure->asTimestamp.minute = 0;
        BindStructure->asTimestamp.second = 0;
        BindStructure->asTimestamp.fraction = 0;
        break;
      }
      case SQL_C_TYPE_DATE: {
        int iPos;
        HB_MAXINT lVal;
        double dVal;

        char datemask[9] = "10000101";
        char *mask = datemask;

        size = lenKey > (int)(BindStructure->ColumnSize) ? ((int)(BindStructure->ColumnSize)) : lenKey;

        // Must fix partial date seek
        for (iPos = 0; iPos < size; iPos++) {
          datemask[iPos] = szKey[iPos];
        }

        hb_compStrToNum(datemask, 4, &lVal, &dVal, SR_NULLPTR, SR_NULLPTR);
        BindStructure->asDate.year = (unsigned int)lVal;
        mask += 4;
        hb_compStrToNum(mask, 2, &lVal, &dVal, SR_NULLPTR, SR_NULLPTR);
        BindStructure->asDate.month = (unsigned int)lVal;
        mask += 2;
        hb_compStrToNum(mask, 2, &lVal, &dVal, SR_NULLPTR, SR_NULLPTR);
        BindStructure->asDate.day = (unsigned int)lVal;

        break; // TODO: unnecessary break
      }
      }

      lenKey -= size;
      szKey += size;

      if (lenKey <= 0) {
        *queryLevel = i;
        break;
      }

      SeekBind++; // Advance to next index column in bind structure
    }
  } else {
    *queryLevel = 1;
    BindStructure = GetBindStructOra(thiswa, SeekBind);

    if (HB_IS_DATE(pKey) || HB_IS_DATETIME(pKey)) {
      int iYear, iMonth, iDay;
      int iHour, iMinute;

      hb_dateDecode(hb_itemGetDL(pKey), &iYear, &iMonth, &iDay);

      if (BindStructure->iCType == SQL_C_TYPE_DATE) {
        BindStructure->asDate.year = (unsigned int)iYear;
        BindStructure->asDate.month = (unsigned int)iMonth;
        BindStructure->asDate.day = (unsigned int)iDay;
      } else if (BindStructure->iCType == SQL_C_TYPE_TIMESTAMP) {
        long lJulian, lMilliSec;
        int seconds, millisec;
        hb_itemGetTDT(pKey, &lJulian, &lMilliSec);
        hb_timeDecode(lMilliSec, &iHour, &iMinute, &seconds, &millisec);
        BindStructure->asTimestamp.year = (unsigned int)iYear;
        BindStructure->asTimestamp.month = (unsigned int)iMonth;
        BindStructure->asTimestamp.day = (unsigned int)iDay;
        BindStructure->asTimestamp.hour = (unsigned int)iHour;
        BindStructure->asTimestamp.minute = (unsigned int)iMinute;
        BindStructure->asTimestamp.second = (unsigned int)seconds;
        BindStructure->asTimestamp.fraction = 0;
      } else {
        // To Do: Raise RT error
        return HB_FAILURE;
      }
    } else if (HB_IS_NUMERIC(pKey)) {
      if (BindStructure->iCType != SQL_C_DOUBLE || BindStructure->iCType != SQL_C_NUMERIC) { // Check column data type
        // To Do: Raise RT error
        return HB_FAILURE;
      }
      if (BindStructure->iCType == SQL_C_NUMERIC) {
        BindStructure->asNumeric = (HB_LONG)hb_itemGetNInt(pKey);
      } else {
        BindStructure->asDouble = (double)hb_itemGetND(pKey);
      }
    } else if (HB_IS_LOGICAL(pKey)) {
      if (BindStructure->iCType != SQL_C_BIT) { // Check column data type
        // To Do: Raise RT error
        return HB_FAILURE;
      }
      BindStructure->asLogical = hb_itemGetNInt(pKey);
    }
  }
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

void BindSeekStmtora(SQLEXORAAREAP thiswa, int queryLevel)
{
  OCI_Statement *hStmt;
  INDEXBINDORAP SeekBind, SeekBindParam;
  COLUMNBINDORAP BindStructure;
  int iBind, iLoop;
  int res = 0;
  char *sSql;

  SeekBind = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];
  // Culik
  // removed, this line bellow make the data be the last field name
  // SeekBind += (queryLevel - 1); // place offset

  hStmt = thiswa->recordListDirection == LIST_FORWARD ? SeekBind->SeekFwdStmt : SeekBind->SeekBwdStmt;
  sSql = thiswa->recordListDirection == LIST_FORWARD ? SeekBind->SeekFwdSql : SeekBind->SeekBwdSql;
  SeekBindParam = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];
  iBind = 1;

  for (iLoop = 1; iLoop <= queryLevel; iLoop++) {
    BindStructure = GetBindStructOra(thiswa, SeekBindParam);
    if (!BindStructure->isArgumentNull) {

      // if (thiswa->nSystemID = SYSTEMID_ORACLE)
      //    if (BindStructure->iCType == SQL_C_TYPE_DATE)
      //      BindStructure->iCType = SQL_C_TYPE_TIMESTAMP; // May be DATE or TIMESTAMP

      switch (BindStructure->iCType) {
      case SQL_C_CHAR: {
        // res = SQLBindParameter(hStmt, iBind, SQL_PARAM_INPUT,
        //                        BindStructure->iCType,
        //                        BindStructure->iSQLType,
        //                        BindStructure->ColumnSize,
        //                        BindStructure->DecimalDigits,
        //                        BindStructure->asChar.value, 0, NULL);
        res = OCI_BindString(hStmt, BindStructure->szBindName, BindStructure->asChar.value, BindStructure->ColumnSize);
        break;
      }
      case SQL_C_NUMERIC: {
        res = OCI_BindUnsignedBigInt(hStmt, BindStructure->szBindName, &BindStructure->asNumeric);
        break;
      }
      case SQL_C_DOUBLE: {
        // res = SQLBindParameter(hStmt, iBind, SQL_PARAM_INPUT,
        //                        BindStructure->iCType,
        //                        BindStructure->iSQLType,
        //                        BindStructure->ColumnSize,
        //                        BindStructure->DecimalDigits,
        //                        &(BindStructure->asNumeric), 0, NULL);
        res = OCI_BindDouble(hStmt, BindStructure->szBindName, &BindStructure->asDouble);
        break;
      }
      case SQL_C_TYPE_TIMESTAMP: {
        // res = SQLBindParameter(hStmt, iBind, SQL_PARAM_INPUT,
        //                        SQL_C_TYPE_DATE,
        //                        SQL_TYPE_DATE,
        //                        SQL_TIMESTAMP_LEN,
        //                        0,
        //                        &(BindStructure->asTimestamp), 0, 0);
        BindStructure->asDate2 = OCI_DateCreate(GetConnection(thiswa->hDbc));
        OCI_DateSetDateTime(BindStructure->asDate2, BindStructure->asTimestamp.year, BindStructure->asTimestamp.month,
                            BindStructure->asTimestamp.day, BindStructure->asTimestamp.hour,
                            BindStructure->asTimestamp.minute, BindStructure->asTimestamp.second);
        res = OCI_BindDate(hStmt, BindStructure->szBindName, BindStructure->asDate2);
        break;
      }
      case SQL_C_TYPE_DATE: {
        // res = SQLBindParameter(hStmt, iBind, SQL_PARAM_INPUT,
        //                        SQL_C_TYPE_DATE,
        //                        SQL_TYPE_DATE,
        //                        SQL_DATE_LEN,
        //                        0,
        //                        &(BindStructure->asDate), 0, NULL);
        // sr_TraceLog("sqltrace.log", " %s  %i %i %i \n", sSql, BindStructure->asDate.year,
        // BindStructure->asDate.month, BindStructure->asDate.day);
        BindStructure->asDate1 = OCI_DateCreate(GetConnection(thiswa->hDbc));
        OCI_DateSetDate(BindStructure->asDate1, BindStructure->asDate.year, BindStructure->asDate.month,
                        BindStructure->asDate.day);
        res = OCI_BindDate(hStmt, BindStructure->szBindName, BindStructure->asDate1);
        break;
      }
      case SQL_C_BIT: {
        res = OCI_BindUnsignedBigInt(hStmt, BindStructure->szBindName, &BindStructure->asLogical);
        // res = SQLBindParameter(hStmt, iBind, SQL_PARAM_INPUT,
        //                        BindStructure->iCType,
        //                        BindStructure->iSQLType,
        //                        BindStructure->ColumnSize,
        //                        BindStructure->DecimalDigits,
        //                        &(BindStructure->asLogical), 0, NULL);
        break; // TODO: unnecessary break
      }
      }
      if (res == 0) {
        OraErrorDiagRTE(hStmt, "BindSeekStmtora", sSql, res, __LINE__, __FILE__);
      }
      iBind++;
      BindStructure->iParNum = iBind;
    }
    SeekBindParam++;
    // Culik Correct place so we can get the data from next field
    SeekBind++; // = (queryLevel - 1); // place offset
  }
}

//------------------------------------------------------------------------

HB_ERRCODE getPreparedSeekora(SQLEXORAAREAP thiswa, int queryLevel, HB_USHORT *iIndex, OCI_Statement **hStmt,
                              OCI_Resultset **rs) // Returns HB_TRUE if any result found
{
  int res;
  INDEXBINDORAP SeekBind;
  // OCI_Resultset * rs;

  SeekBind = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];
  // this line bellow make the last field current
  // SeekBind += (queryLevel - 1); // place offset
  HB_SYMBOL_UNUSED(queryLevel);

  *hStmt = thiswa->recordListDirection == LIST_FORWARD ? SeekBind->SeekFwdStmt : SeekBind->SeekBwdStmt;

  // res = SQLExecute(*hStmt);
  res = OCI_Execute(*hStmt);
  if (!res) {
    OraErrorDiagRTE(*hStmt, "getPreparedSeekora", "", res, __LINE__, __FILE__);
    OCI_StatementFree(*hStmt);
    return HB_FAILURE;
  }

  *rs = OCI_GetResultset(*hStmt);
  if (*rs == SR_NULLPTR) {
    return HB_FAILURE;
  }

  OCI_FetchNext(*rs);
  thiswa->recordList[0] = OCI_GetUnsignedBigInt(*rs, 1);
  if (thiswa->recordList[0] == 0) {
    // OCI_StatementFree(*hStmt);
    return HB_FAILURE;
  }

  if (thiswa->sqlarea.ulhDeleted > 0) {
    char szValue[2];
    unsigned int uiLen;

    if (OCI_GetString(*rs, 2) == SR_NULLPTR) {
      // OCI_StatementFree(*hStmt);
      return HB_FAILURE;
    }
    uiLen = OCI_GetDataLength(*rs, 2);

    hb_xmemcpy(szValue, (char *)OCI_GetString(*rs, 2), uiLen);
    if (szValue[0] == 0) {
      thiswa->deletedList[0] = ' '; // MySQL driver climps spaces from right side
    } else {
      thiswa->deletedList[0] = szValue[0];
    }

    *iIndex = 2;
  } else {
    *iIndex = 1;
    thiswa->deletedList[0] = ' ';
  }

  thiswa->recordListSize = 1L;
  thiswa->recordListPos = 0;

  return HB_SUCCESS;
}

HB_ERRCODE FeedSeekStmtOra(SQLEXORAAREAP thiswa, int queryLevel)
{
  int i;

  COLUMNBINDORAP InsertRecord;
  INDEXBINDORAP SeekBind, SeekBindParam;
  int iLoop;
  char *sSql;

  SeekBind = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];

  sSql = thiswa->recordListDirection == LIST_FORWARD ? SeekBind->SeekFwdSql : SeekBind->SeekBwdSql;

  SeekBindParam = thiswa->IndexBindings[thiswa->sqlarea.hOrdCurrent];

  for (iLoop = 1; iLoop <= queryLevel; iLoop++) {
    InsertRecord = GetBindStructOra(thiswa, SeekBindParam);
    if (InsertRecord->iCType == SQL_C_TYPE_TIMESTAMP) {
      OCI_DateSetDateTime(InsertRecord->asDate2, InsertRecord->asTimestamp.year, InsertRecord->asTimestamp.month,
                          InsertRecord->asTimestamp.day, InsertRecord->asTimestamp.hour,
                          InsertRecord->asTimestamp.minute, InsertRecord->asTimestamp.second);
    }
    if (InsertRecord->iCType == SQL_C_TYPE_DATE) {
      OCI_DateSetDate(InsertRecord->asDate1, InsertRecord->asDate.year, InsertRecord->asDate.month,
                      InsertRecord->asDate.day);
    }
    InsertRecord++;
  }

  return HB_SUCCESS;
}
