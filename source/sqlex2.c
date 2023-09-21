/*
 * SQLEX Auxiliar File for INSERT and UPDATE routines
 * Copyright (c) 2009 - Marcelo Lombardo  <lombardo@uol.com.br>
 *
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

#if defined(_MSC_VER)
   #pragma warning(disable : 4201)
#endif

#include "compat.h"
#include <hbinit.h>
#include "msg.ch"
#include <rddsys.ch>
#include <hbdbferr.h>
#include "sqlrddsetup.ch"
#include "sqlprototypes.h"
#include <ctype.h>
#include <assert.h>

#if defined(HB_OS_WIN_32) || defined(HB_OS_WIN_64) || defined(HB_OS_WIN)
   #include <windows.h>
   #include <odbcinst.h>
#else
   #include <stdlib.h>
   #include <unistd.h>
   #include <errno.h>
   #include <sys/types.h>
   #include <sys/wait.h>
   #define SQL_WCHAR   (-8)
   #define SQL_WLONGVARCHAR   (-10)
   #define SQL_C_WCHAR   SQL_WCHAR
#endif

#include <sql.h>
#include <sqlext.h>
#include <sqltypes.h>
#include "sqlex.h"

/*------------------------------------------------------------------------*/

static PHB_DYNS s_pSym_Serial1 = NULL; // Pointer to serialization function

/*------------------------------------------------------------------------*/

char * QualifyName(char * szName, SQLEXAREAP thiswa)
{
   int i, len;

   len = strlen(szName);

   for( i = 0; i < len; i++ ) {
      if( szName[i] == '\0' ) {
         break;
      }
      switch( thiswa->nSystemID ) {
      case SYSTEMID_MSSQL7:
      case SYSTEMID_ORACLE:
      case SYSTEMID_FIREBR:
      case SYSTEMID_FIREBR3:
      case SYSTEMID_IBMDB2:
      case SYSTEMID_ADABAS:
         szName[i] = (char) toupper((HB_BYTE) szName[i]);
         break;
      case SYSTEMID_INGRES:
      case SYSTEMID_POSTGR:
      case SYSTEMID_MYSQL:
      case SYSTEMID_MARIADB:
      case SYSTEMID_OTERRO:
      case SYSTEMID_INFORM:
         szName[i] = (char) tolower((HB_BYTE) szName[i]);
         break;
      }
   }
   return szName;
}

/*------------------------------------------------------------------------*/

static void ResolveSpecialCols(SQLEXAREAP thiswa)
{
   // Resolve all Synthetic Index and FOR clause expressions, storing
   // results in thiswa->aBuffer
   // TO DO: Creating a new Index should reset INSERT Stmt cos it may
   //        create a new field like INDKEY_???

   int i, iIndexes;
   PHB_ITEM pIndex;
   PHB_ITEM pKeyVal;
   PHB_ITEM pIndIt;
   HB_USHORT uiPos;
   int iOldArea;

   if( !thiswa->pIndexMgmnt ) {
      hb_objSendMsg(thiswa->oWorkArea, "AINDEXMGMNT", 0);
      thiswa->pIndexMgmnt = hb_itemNew(NULL);
      hb_itemMove(thiswa->pIndexMgmnt, hb_stackReturnItem());
   }
   iOldArea = hb_rddGetCurrentWorkAreaNumber();
   if( iOldArea != thiswa->area.uiArea ) {
      hb_rddSelectWorkAreaNumber(thiswa->area.uiArea);
   }
   iIndexes = hb_arrayLen(thiswa->pIndexMgmnt);

   for( i = 1; i <= iIndexes; i++ ) {
      pIndex = hb_arrayGetItemPtr(thiswa->pIndexMgmnt, i);
      pIndIt = hb_itemArrayGet(pIndex, INDEXMAN_COLUMNS);
      // pIndIt = hb_arrayGetItemPtr(pIndex, INDEXMAN_COLUMNS);

      if( !SR_itemEmpty(pIndIt) ) {
         HB_EVALINFO info;
         hb_evalNew(&info, hb_itemArrayGet(pIndex, INDEXMAN_KEY_CODEBLOCK));
         pKeyVal = hb_evalLaunch(&info);
         hb_evalRelease(&info);

         // Get field position in ::aLocalBuffer
         // uiPos = (HB_USHORT) hb_itemGetNI(hb_arrayGetItemPtr(pIndex, INDEXMAN_SYNTH_COLPOS));
         uiPos = (HB_USHORT) hb_itemGetNI(hb_itemArrayGet(pIndex, INDEXMAN_SYNTH_COLPOS));
         thiswa->specialMask[uiPos] = '1';

         hb_arraySetForward(thiswa->aBuffer, uiPos, pKeyVal);
         hb_itemRelease(pKeyVal);
      }

      // pIndIt = hb_arrayGetItemPtr(pIndex, INDEXMAN_FOR_CODEBLOCK);
      pIndIt = hb_itemArrayGet(pIndex, INDEXMAN_FOR_CODEBLOCK);

      if( !SR_itemEmpty(pIndIt) ) {
         HB_EVALINFO info;
         hb_evalNew(&info, hb_itemArrayGet(pIndex, INDEXMAN_FOR_CODEBLOCK));
         pKeyVal = hb_evalLaunch(&info);
         hb_evalRelease(&info);

         // Get field position in ::aLocalBuffer
         // uiPos = (HB_USHORT) hb_itemGetNI(hb_arrayGetItemPtr(pIndex, INDEXMAN_FOR_COLPOS));
         uiPos = (HB_USHORT) hb_itemGetNI(hb_itemArrayGet(pIndex, INDEXMAN_FOR_COLPOS));
         thiswa->specialMask[uiPos] = '1';
         hb_arraySetForward(thiswa->aBuffer, uiPos, pKeyVal);
         hb_itemRelease(pKeyVal);
      }
   }
   if( iOldArea != thiswa->area.uiArea ) {
      hb_rddSelectWorkAreaNumber(iOldArea);
   }
}

/*------------------------------------------------------------------------*/

static void SerializeMemo(PHB_ITEM pFieldData)
{
   if( !s_pSym_Serial1 ) {
      s_pSym_Serial1 = hb_dynsymFindName("SR_SERIALIZE1");
   }
   hb_vmPushDynSym(s_pSym_Serial1);
   hb_vmPushNil();
   hb_vmPush(pFieldData);
   hb_vmDo(1);
   hb_itemMove(pFieldData, hb_stackReturnItem());
}

/*------------------------------------------------------------------------*/

void SetInsertRecordStructure(SQLEXAREAP thiswa)
{
   thiswa->InsertRecord = (COLUMNBINDP) hb_xgrab(hb_arrayLen(thiswa->aFields) * sizeof(COLUMNBIND));
   memset(thiswa->InsertRecord, 0, hb_arrayLen(thiswa->aFields) * sizeof(COLUMNBIND));
}

/*------------------------------------------------------------------------*/

void CreateInsertStmt(SQLEXAREAP thiswa)
{
   int iCols, i;
   PHB_ITEM pFieldStruct, pFieldLen, pFieldDec;
   HB_LONG lFieldPosWA, lType;
   char * colName, * sFields, * sParams, * temp;
   char ident[200] = {0};
   char tablename[100] = {0};
   char declare[200] = {0};
   char cType;
   HB_BOOL bNullable, bMultiLang, bIsMemo;
   COLUMNBINDP InsertRecord;
   HB_USHORT uiPos;

   iCols = hb_arrayLen(thiswa->aFields);

   if( !thiswa->InsertRecord ) {
      SetInsertRecordStructure(thiswa);
   }

   InsertRecord = thiswa->InsertRecord;
   sFields = (char *) hb_xgrab(FIELD_LIST_SIZE * sizeof(char));
   sParams = (char *) hb_xgrab((FIELD_LIST_SIZE_PARAM) * sizeof(char));
   uiPos = 0;
   sFields[0] = '\0';

   for( i = 1; i <= iCols; i++ ) {
      pFieldStruct = hb_arrayGetItemPtr(thiswa->aFields, i);
      bNullable = hb_arrayGetL(pFieldStruct, FIELD_NULLABLE);
      pFieldLen = hb_arrayGetItemPtr(pFieldStruct, FIELD_LEN);
      pFieldDec = hb_arrayGetItemPtr(pFieldStruct, FIELD_DEC);
      lFieldPosWA = hb_arrayGetNL(pFieldStruct, FIELD_WAOFFSET);
      lType = hb_arrayGetNL(pFieldStruct, FIELD_DOMAIN);
      cType = *hb_arrayGetCPtr(pFieldStruct, FIELD_TYPE);
      colName = hb_arrayGetC(pFieldStruct, FIELD_NAME);
      bMultiLang = hb_arrayGetL(pFieldStruct, FIELD_MULTILANG);
      if( bMultiLang ) {
         cType = 'M';
      }
      bIsMemo = cType == 'M' || bMultiLang;

      if( i != (int)(thiswa->ulhRecno) ) { // RECNO is never included in INSERT column list
         temp = hb_strdup((const char *) sFields);
         sprintf(sFields, "%s,%c%s%c", temp, OPEN_QUALIFIER(thiswa), QualifyName(colName, thiswa), CLOSE_QUALIFIER(thiswa));
         sParams[uiPos] = ',';
         sParams[++uiPos] = '?';
         sParams[++uiPos] = '\0';
         hb_xfree(temp);
      }

      hb_xfree(colName);

      InsertRecord->iSQLType = (int) lType;
      InsertRecord->isNullable = bNullable;
      InsertRecord->isBoundNULL = HB_FALSE;
      InsertRecord->lFieldPosDB = i;
      InsertRecord->lFieldPosWA = lFieldPosWA;
      InsertRecord->ColumnSize = (SQLUINTEGER) hb_itemGetNI(pFieldLen);
      InsertRecord->DecimalDigits = (SQLSMALLINT) hb_itemGetNI(pFieldDec);
      InsertRecord->isArgumentNull = HB_FALSE;
      InsertRecord->isMemo = bIsMemo;
      InsertRecord->isMultiLang = bMultiLang;

#ifdef SQLRDD_TOPCONN
      switch( lType ) {
         case SQL_FAKE_NUM: {
            lType = SQL_FLOAT;
            break;
         }
         case SQL_FAKE_DATE: {
            lType = SQL_CHAR;
            break;
         }
      }
#endif

      switch( cType ) {
         case 'M': {
            InsertRecord->iCType = SQL_C_BINARY;
            InsertRecord->asChar.value = (SQLCHAR *) hb_xgrab(INITIAL_MEMO_ALLOC);
            InsertRecord->asChar.size_alloc = INITIAL_MEMO_ALLOC;
            InsertRecord->asChar.size = 0;
            InsertRecord->asChar.value[0] = '\0';
            InsertRecord->ColumnSize = 0;
            break;
         }
         case 'C': {
            InsertRecord->asChar.value = (SQLCHAR *) hb_xgrab(InsertRecord->ColumnSize + 1);
            InsertRecord->asChar.size_alloc = InsertRecord->ColumnSize + 1;
            InsertRecord->iCType = SQL_C_CHAR;
            InsertRecord->asChar.size = 0;
            InsertRecord->asChar.value[0] = '\0';
            break;
         }
         case 'N': {
            InsertRecord->iCType = SQL_C_DOUBLE;
            break;
         }

         case 'D': {
           // Corrigido 27/12/2013 09:53 - lpereira
           // Estava atribuindo o valor de SYSTEMID_ORACLE para thiswa->nSystemID.
           // if( thiswa->nSystemID = SYSTEMID_ORACLE )
           if( thiswa->nSystemID == SYSTEMID_ORACLE ) {
              InsertRecord->iCType = SQL_C_TYPE_TIMESTAMP; // May be DATE or TIMESTAMP
           } else {
              InsertRecord->iCType = lType; // May be DATE or TIMESTAMP
            }
            break;
         }
         case 'T': {
            // DebugBreak();
            InsertRecord->iCType = SQL_C_TYPE_TIMESTAMP; // May be DATE or TIMESTAMP
            break;
         }
         case 'L': {
            InsertRecord->iCType = SQL_C_BIT;
            break;
         }
      }
      // if( InsertRecord->isMultiLang ) // culik, se e multiplang, binda como binario
      // InsertRecord->iCType = SQL_C_BINARY;
      InsertRecord++;
   }

   sParams[0] = ' ';
   sFields[0] = ' ';

   switch( thiswa->nSystemID ) {
      case SYSTEMID_MSSQL7:
      case SYSTEMID_SYBASE: {
         // sprintf(ident, " SELECT @@IDENTITY ;");
         sprintf(ident, "SELECT %s FROM @InsertedData;", thiswa->sRecnoName);
         sprintf(declare, "Declare @InsertedData table ( %s numeric(15,0) );", thiswa->sRecnoName);
         // sprintf(ident, ";SELECT SCOPE_IDENTITY() AS NewID ;");
         break;
      }
      case SYSTEMID_FIREBR:
      case SYSTEMID_FIREBR3: {
         sprintf(ident, " RETURNING %s", thiswa->sRecnoName);
         break;
      }
      case SYSTEMID_POSTGR: {
         sprintf(tablename, "%s", thiswa->szDataFileName);
         if( strlen(tablename) > (MAX_TABLE_NAME_LENGHT - 3) ) {
            tablename[MAX_TABLE_NAME_LENGHT-4] = '\0';
         }
         sprintf(ident, "; SELECT currval('%s_SQ');", tablename);
         break;
      }
      case SYSTEMID_ORACLE:
      case SYSTEMID_CACHE:
      case SYSTEMID_INFORM:
      case SYSTEMID_MYSQL: { // TODO: same as default
         ident[0] = '\0';
         break;
      }
      case SYSTEMID_IBMDB2: {
         sprintf(ident, "; VALUES IDENTITY_VAL_LOCAL();");
         break;
      }
      default: {
         ident[0] = '\0';
      }
   }
   if( thiswa->sSql ) {
      hb_xfree(thiswa->sSql);
   }
   thiswa->sSql = (char *) hb_xgrab(MAX_SQL_QUERY_LEN * sizeof(char));
   memset(thiswa->sSql, 0, MAX_SQL_QUERY_LEN * sizeof(char));
   if( thiswa->nSystemID ==  SYSTEMID_MSSQL7 ) {
      sprintf(thiswa->sSql, "%s INSERT INTO %s (%s ) OUTPUT Inserted.%s INTO @InsertedData(%s) VALUES (%s );%s",
         declare,
         thiswa->sTable,
         sFields,
         thiswa->sRecnoName,
         thiswa->sRecnoName,
         sParams,
         ident);
      // sprintf(thiswa->sSql, "%s INSERT INTO %s (%s ) VALUES (%s );%s", declare, thiswa->sTable, sFields, sParams, ident);
   } else {
      sprintf(thiswa->sSql, "INSERT INTO %s (%s ) VALUES (%s )%s", thiswa->sTable, sFields, sParams, ident);
   }

   hb_xfree(sFields);
   hb_xfree(sParams);
}

/*------------------------------------------------------------------------*/

HB_ERRCODE PrepareInsertStmt(SQLEXAREAP thiswa)
{
   SQLRETURN res;

   res = SQLAllocHandle(SQL_HANDLE_STMT, (HDBC) thiswa->hDbc, &(thiswa->hStmtInsert));

   if( CHECK_SQL_N_OK(res) ) {
      odbcErrorDiagRTE(thiswa->hStmtInsert, "PrepareInsertStmt/SQLAllocStmt", thiswa->sSql, res, __LINE__, __FILE__);
      return HB_FAILURE;
   }

   res = SQLPrepare(thiswa->hStmtInsert, (SQLCHAR *) (thiswa->sSql), SQL_NTS);

   if( CHECK_SQL_N_OK(res) ) {
      odbcErrorDiagRTE(thiswa->hStmtInsert, "PrepareInsertStmt", thiswa->sSql, res, __LINE__, __FILE__);
      return HB_FAILURE;
   }

   return HB_SUCCESS;
}

/*------------------------------------------------------------------------*/

HB_ERRCODE BindInsertColumns(SQLEXAREAP thiswa)
{
   int iCol, iCols, iBind;
   COLUMNBINDP InsertRecord;
   SQLRETURN res = SQL_ERROR;

   iCols = hb_arrayLen(thiswa->aFields);
   InsertRecord = thiswa->InsertRecord;
   iBind = 0;

   for( iCol = 1; iCol <= iCols; iCol++ ) {
      if( iCol != (int) (thiswa->ulhRecno) ) { // RECNO is never included in INSERT column list
         iBind++;
         switch( InsertRecord->iCType ) {
            case SQL_C_CHAR: {
               InsertRecord->lIndPtr = SQL_NTS;
               res = SQLBindParameter(thiswa->hStmtInsert,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      (SQLSMALLINT) InsertRecord->iCType,
                                      (SQLSMALLINT) InsertRecord->iSQLType,
                                      InsertRecord->ColumnSize,
                                      InsertRecord->DecimalDigits,
                                      InsertRecord->asChar.value,
                                      0,
                                      &(InsertRecord->lIndPtr));
               break;
            }
            case SQL_C_BINARY: {
               SQLINTEGER nInd;
               InsertRecord->lIndPtr = SQL_NTS;
               nInd = strlen((const char *) (InsertRecord->asChar.value));
               res = SQLBindParameter(thiswa->hStmtInsert,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      SQL_C_CHAR,
                                      SQL_LONGVARCHAR,
                                      InsertRecord->asChar.size_alloc,
                                      0,
                                      InsertRecord->asChar.value,
                                      nInd,
                                      &(InsertRecord->lIndPtr));
               break;
            }
            case SQL_C_DOUBLE: {
               InsertRecord->lIndPtr = 0;
               res = SQLBindParameter(thiswa->hStmtInsert,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      (SQLSMALLINT) InsertRecord->iCType,
                                      (SQLSMALLINT) InsertRecord->iSQLType,
                                      InsertRecord->ColumnSize,
                                      InsertRecord->DecimalDigits,
                                      &(InsertRecord->asNumeric),
                                      0,
                                      &(InsertRecord->lIndPtr));
               break;
            }
            case SQL_C_TYPE_TIMESTAMP: {
               // DebugBreak();
               InsertRecord->lIndPtr = 0;
               res = SQLBindParameter(thiswa->hStmtInsert,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      SQL_C_TYPE_TIMESTAMP,
                                      SQL_TYPE_TIMESTAMP,
                                      SQL_TIMESTAMP_LEN,
                                      thiswa->nSystemID == SYSTEMID_MSSQL7 || thiswa->nSystemID == SYSTEMID_AZURE ? 3 : 0,
                                      &(InsertRecord->asTimestamp),
                                      0,
                                      &(InsertRecord->lIndPtr));
               break;
            }
            case SQL_C_TYPE_DATE: {
               InsertRecord->lIndPtr = 0;
               res = SQLBindParameter(thiswa->hStmtInsert,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      SQL_C_TYPE_DATE,
                                      SQL_TYPE_DATE,
                                      SQL_DATE_LEN,
                                      0,
                                      &(InsertRecord->asDate),
                                      0,
                                      &(InsertRecord->lIndPtr));
               break;
            }
            case SQL_C_BIT: {
               res = SQLBindParameter(thiswa->hStmtInsert,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      (SQLSMALLINT) InsertRecord->iCType,
                                      (SQLSMALLINT) InsertRecord->iSQLType,
                                      InsertRecord->ColumnSize,
                                      InsertRecord->DecimalDigits,
                                      &(InsertRecord->asLogical),
                                      0,
                                      NULL);
               break;
            }
         }

         InsertRecord->iParNum = iBind;

         if( CHECK_SQL_N_OK(res) ) {
            odbcErrorDiagRTE(thiswa->hStmtInsert, "BindInsertColumns", thiswa->sSql, res, __LINE__, __FILE__);
            return HB_FAILURE;
         }
      }
      InsertRecord++;
   }

   return HB_SUCCESS;
}

/*------------------------------------------------------------------------*/

HB_ERRCODE FeedRecordCols(SQLEXAREAP thiswa, HB_BOOL bUpdate)
{
   int iCols, i;
   PHB_ITEM pFieldData, pTemp;
   COLUMNBINDP InsertRecord;

   iCols = hb_arrayLen(thiswa->aFields);

   if( bUpdate ) {
      InsertRecord = thiswa->CurrRecord;
   } else {
      InsertRecord = thiswa->InsertRecord;
   }

   if( !bUpdate ) {
      hb_arraySetNL(thiswa->aInfo, AINFO_RECNO, GetCurrentRecordNum(thiswa) - 1);
   }

   ResolveSpecialCols(thiswa); // Fix INDKEY and FOR CLAUSE columns

   for( i = 1; i <= iCols; i++ ) {
      if( (!bUpdate) || (bUpdate && (thiswa->editMask[i - 1] || thiswa->specialMask[i - 1]) ) ) {
         if( i == (int)(thiswa->ulhDeleted) ) {
            SetBindEmptylValue(InsertRecord); // Writes a ' ' to deleted flag
         } else if( i != (int)(thiswa->ulhRecno) ) { // RECNO is never included in INSERT column list
            // Get item value from Workarea
            pFieldData = hb_arrayGetItemPtr(thiswa->aBuffer, i);

            if( SR_itemEmpty(pFieldData) && (!InsertRecord->isNullable) ) {
               if( SetBindEmptylValue(InsertRecord) == HB_FAILURE ) {
                  return HB_FAILURE;
               }
            } else {
               if( InsertRecord->isMultiLang && HB_IS_STRING(pFieldData) ) {
                  // Transform multilang field in HASH
                  PHB_ITEM pLangItem = hb_itemNew(NULL);
                  pTemp = hb_hashNew(NULL);
                  hb_hashAdd(pTemp, sr_getBaseLang(pLangItem), pFieldData);
                  hb_itemRelease(pLangItem);
                  hb_itemMove(pFieldData, pTemp);
                  hb_itemRelease(pTemp);
               }
               if( InsertRecord->isMemo && (!HB_IS_STRING(pFieldData)) ) {
                  // Serialize memo
                  SerializeMemo(pFieldData);
               }

               if( SetBindValue(pFieldData, InsertRecord, bUpdate ? thiswa->hStmtUpdate : thiswa->hStmtInsert) == HB_FAILURE ) {
                  return HB_FAILURE;
               }
            }
         }
      }
      InsertRecord++;
   }

   return HB_SUCCESS;
}

/*------------------------------------------------------------------------*/

HB_ERRCODE ExecuteInsertStmt(SQLEXAREAP thiswa)
{
   SQLRETURN res;

   res = SQLExecute(thiswa->hStmtInsert);

   if( CHECK_SQL_N_OK(res) ) {
      odbcErrorDiagRTE(thiswa->hStmtInsert, "ExecuteInsertStmt/SQLExecute", thiswa->sSql, res, __LINE__, __FILE__);
      SQLCloseCursor(thiswa->hStmtInsert);
      return HB_FAILURE;
   }

   // Retrieve RECNO

   switch( thiswa->nSystemID ) {
      case SYSTEMID_MSSQL7:
      case SYSTEMID_SYBASE:
      case SYSTEMID_IBMDB2:
      case SYSTEMID_POSTGR:
      case SYSTEMID_FIREBR:
      case SYSTEMID_FIREBR3: {
         if( thiswa->nSystemID != SYSTEMID_FIREBR && thiswa->nSystemID != SYSTEMID_FIREBR3 ) {
            // #if defined(_MSC_VER)
            res = SQLMoreResults(thiswa->hStmtInsert);
            if( res != SQL_SUCCESS ) {
               res = SQLMoreResults(thiswa->hStmtInsert);
               if( CHECK_SQL_N_OK(res) ) {
                  odbcErrorDiagRTE(thiswa->hStmtInsert, "SQLMoreResults", thiswa->sSql, res, __LINE__, __FILE__);
                  SQLCloseCursor(thiswa->hStmtInsert);
                  return HB_FAILURE;
               }
            }
            // #endif
         }
         res = SQLFetch(thiswa->hStmtInsert);
         if( CHECK_SQL_N_OK(res) ) {
            odbcErrorDiagRTE(thiswa->hStmtInsert, "ExecuteInsertStmt/Fetch", thiswa->sSql, res, __LINE__, __FILE__);
            return HB_FAILURE;
         }
         res = SQLGetData(thiswa->hStmtInsert, 1, SQL_C_ULONG, &(thiswa->recordList[0]), sizeof(SQL_C_ULONG), NULL);
         if( CHECK_SQL_N_OK(res) ) {
            odbcErrorDiagRTE(thiswa->hStmtInsert, "ExecuteInsertStmt/GetData", thiswa->sSql, res, __LINE__, __FILE__);
            return HB_FAILURE;
         }
         break;
      }
      case SYSTEMID_ORACLE:
      case SYSTEMID_MYSQL: {
         SQLRETURN _res;
         char ident[200] = {0};
         char tablename[100] = {0};
   
         if( thiswa->hStmtNextval == NULL ) {
            switch( thiswa->nSystemID ) {
               case SYSTEMID_ORACLE: {
                  sprintf(tablename, "%s", thiswa->szDataFileName);
                  if( strlen(tablename) > (MAX_TABLE_NAME_LENGHT - 3) ) {
                     tablename[MAX_TABLE_NAME_LENGHT - 4] = '\0';
                  }
                  sprintf(ident, "SELECT %s%s_SQ.CURRVAL FROM DUAL", thiswa->sOwner, tablename);
                  break;
               }
               case SYSTEMID_MYSQL: {
                  sprintf(ident, "SELECT LAST_INSERT_ID()");
                  break;
               }
            }
   
            _res = SQLAllocHandle(SQL_HANDLE_STMT, (HDBC) thiswa->hDbc, &(thiswa->hStmtNextval));
            if( CHECK_SQL_N_OK(_res) ) {
               odbcErrorDiagRTE(thiswa->hStmtNextval, "SQLAllocStmt", ident, _res, __LINE__, __FILE__);
               return HB_FAILURE;
            }
   
            _res = SQLPrepare(thiswa->hStmtNextval, (SQLCHAR *) (ident), SQL_NTS);
            if( CHECK_SQL_N_OK(_res) ) {
               odbcErrorDiagRTE(thiswa->hStmtNextval, "SQLPrepare", ident, _res, __LINE__, __FILE__);
               return HB_FAILURE;
            }
         } else {
            ident[0] = '\0';
         }
   
         _res = SQLExecute(thiswa->hStmtNextval);
         if( CHECK_SQL_N_OK(_res) ) {
            odbcErrorDiagRTE(thiswa->hStmtNextval, "SQLExecute", ident, _res, __LINE__, __FILE__);
            return HB_FAILURE;
         }
         _res = SQLFetch(thiswa->hStmtNextval);
         if( CHECK_SQL_N_OK(_res) ) {
            odbcErrorDiagRTE(thiswa->hStmtNextval, "ExecuteInsertStmt/Fetch", ident, _res, __LINE__, __FILE__);
            return HB_FAILURE;
         }
         _res = SQLGetData(thiswa->hStmtNextval, 1, SQL_C_ULONG, &(thiswa->recordList[0]), sizeof(SQL_C_ULONG), NULL);
         if( CHECK_SQL_N_OK(_res) ) {
            odbcErrorDiagRTE(thiswa->hStmtNextval, "ExecuteInsertStmt/GetData", ident, _res, __LINE__, __FILE__);
            return HB_FAILURE;
         }
         SQLFreeStmt(thiswa->hStmtNextval, SQL_CLOSE);
         break;
      }
      case SYSTEMID_CACHE:
      case SYSTEMID_INFORM:
      default: {
         ;
      }
   }

   thiswa->deletedList[0] = ' ';
   thiswa->recordListPos = 0;
   thiswa->recordListSize = 1;
   hb_arraySetNL(thiswa->aInfo, AINFO_RCOUNT, thiswa->recordList[0]);
   thiswa->lLastRec = thiswa->recordList[0] + 1;

   SQLCloseCursor(thiswa->hStmtInsert);

   return HB_SUCCESS;
}

/*------------------------------------------------------------------------*/

HB_ERRCODE CreateUpdateStmt(SQLEXAREAP thiswa)
{
   SQLRETURN res;
   int iCols, i, iBind;
   COLUMNBINDP CurrRecord;
   PHB_ITEM pColumns;
   char * temp;

   if( !thiswa->CurrRecord ) {
      SetCurrRecordStructure(thiswa);
   }
   if( thiswa->hStmtUpdate ) {
      SQLFreeStmt(thiswa->hStmtUpdate, SQL_DROP);
   }

   res = SQLAllocHandle(SQL_HANDLE_STMT, (HDBC) thiswa->hDbc, &(thiswa->hStmtUpdate));
   if( CHECK_SQL_N_OK(res) ) {
      odbcErrorDiagRTE(thiswa->hStmtUpdate, "CreateUpdateStmt", thiswa->sSql, res, __LINE__, __FILE__);
   }

   iCols = (int) hb_arrayLen(thiswa->aFields);
   CurrRecord = thiswa->CurrRecord;
   iBind = 0;
   thiswa->bIndexTouchedInUpdate = HB_FALSE;
   if( thiswa->sSql ) {
      memset(thiswa->sSql, 0, MAX_SQL_QUERY_LEN * sizeof(char));
   }
   sprintf(thiswa->sSql, "UPDATE %s SET", thiswa->sTable);

   for( i = 0; i < iCols; i++ ) {
      if( thiswa->editMask[i] || thiswa->specialMask[i] ) {
         if( !thiswa->specialMask[i] ) {
            thiswa->updatedMask[i] = '1';
         } else if( thiswa->hOrdCurrent != 0 ) {
            thiswa->bIndexTouchedInUpdate = HB_TRUE; // If there is any special column, we cannot be sure
                                                     // current order is not affected by UPDATE, so it takes
                                                     // worst scenario
         }
         if( strcmp(CurrRecord->colName,thiswa->sRecnoName )== 0 ) {
            break;
         }
         // Bind the query column
         iBind++;
         switch( CurrRecord->iCType ) {
            case SQL_C_CHAR: {
               CurrRecord->lIndPtr = SQL_NTS;
               res = SQLBindParameter(thiswa->hStmtUpdate,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      (SQLSMALLINT) CurrRecord->iCType,
                                      (SQLSMALLINT) CurrRecord->iSQLType,
                                      CurrRecord->ColumnSize,
                                      CurrRecord->DecimalDigits,
                                      CurrRecord->asChar.value,
                                      0,
                                      &(CurrRecord->lIndPtr));
               break;
            }
            case SQL_C_BINARY: {
               SQLINTEGER nInd;
               CurrRecord->lIndPtr = SQL_NTS;
               nInd = strlen((const char *)(CurrRecord->asChar.value));
               res = SQLBindParameter(thiswa->hStmtUpdate,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      SQL_C_CHAR,
                                      SQL_LONGVARCHAR,
                                      CurrRecord->asChar.size_alloc,
                                      0,
                                      CurrRecord->asChar.value,
                                      nInd,
                                      &(CurrRecord->lIndPtr));
               break;
            }
            case SQL_C_DOUBLE: {
               CurrRecord->lIndPtr = 0;
               res = SQLBindParameter(thiswa->hStmtUpdate,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      (SQLSMALLINT) CurrRecord->iCType,
                                      (SQLSMALLINT) CurrRecord->iSQLType,
                                      CurrRecord->ColumnSize,
                                      CurrRecord->DecimalDigits,
                                      &(CurrRecord->asNumeric),
                                      0,
                                      &(CurrRecord->lIndPtr));
               break;
            }
            case SQL_C_TYPE_TIMESTAMP: {
              //DebugBreak();
               CurrRecord->lIndPtr = 0;
               res = SQLBindParameter(thiswa->hStmtUpdate,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      SQL_C_TYPE_TIMESTAMP,
                                      SQL_TYPE_TIMESTAMP,
                                      SQL_TIMESTAMP_LEN,
                                      thiswa->nSystemID == SYSTEMID_MSSQL7 || thiswa->nSystemID == SYSTEMID_AZURE ? 3 : 0,
                                      &(CurrRecord->asTimestamp),
                                      0,
                                      &(CurrRecord->lIndPtr));
               break;
            }
            case SQL_C_TYPE_DATE: {
               CurrRecord->lIndPtr = 0;
               res = SQLBindParameter(thiswa->hStmtUpdate,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      SQL_C_TYPE_DATE,
                                      SQL_TYPE_DATE,
                                      SQL_DATE_LEN,
                                      0,
                                      &(CurrRecord->asDate),
                                      0,
                                      &(CurrRecord->lIndPtr));
               break;
            }
            case SQL_C_BIT: {
               res = SQLBindParameter(thiswa->hStmtUpdate,
                                      (SQLUSMALLINT) iBind,
                                      SQL_PARAM_INPUT,
                                      (SQLSMALLINT) CurrRecord->iCType,
                                      (SQLSMALLINT) CurrRecord->iSQLType,
                                      CurrRecord->ColumnSize,
                                      CurrRecord->DecimalDigits,
                                      &(CurrRecord->asLogical),
                                      0,
                                      NULL);
               break;
            }
         }

         CurrRecord->iParNum = iBind;

         // Create SQL
         temp = hb_strdup((const char *) thiswa->sSql);
         sprintf(thiswa->sSql, "%s%c %c%s%c = ?",
            temp,
            iBind > 1 ? ',' : ' ',
            OPEN_QUALIFIER(thiswa),
            CurrRecord->colName,
            CLOSE_QUALIFIER(thiswa));
         hb_xfree(temp);

         if( CHECK_SQL_N_OK(res) ) {
            odbcErrorDiagRTE(thiswa->hStmtUpdate, "BindUpdateColumns", thiswa->sSql, res, __LINE__, __FILE__);
            return HB_FAILURE;
         }
      }
      CurrRecord++;
   }
   temp = hb_strdup((const char *) thiswa->sSql);
   sprintf(thiswa->sSql, "%s\n WHERE %c%s%c = ?",
      temp,
      OPEN_QUALIFIER(thiswa),
      thiswa->sRecnoName,
      CLOSE_QUALIFIER(thiswa));
   hb_xfree(temp);
   res = SQLBindParameter(thiswa->hStmtUpdate,
      (SQLUSMALLINT) ++iBind,
      SQL_PARAM_INPUT,
      SQL_C_ULONG,
      SQL_INTEGER,
      15,
      0,
      &(thiswa->lUpdatedRecord),
      0,
      NULL);
   if( CHECK_SQL_N_OK(res) ) {
      odbcErrorDiagRTE(thiswa->hStmtUpdate, "BindUpdateColumns", thiswa->sSql, res, __LINE__, __FILE__);
      return HB_FAILURE;
   }

   res = SQLPrepare(thiswa->hStmtUpdate, (SQLCHAR *) (thiswa->sSql), SQL_NTS);
   if( CHECK_SQL_N_OK(res) ) {
      odbcErrorDiagRTE(thiswa->hStmtUpdate, "CreateUpdateStmt", thiswa->sSql, res, __LINE__, __FILE__);
      return HB_FAILURE;
   }

   if( (!thiswa->bIndexTouchedInUpdate) && thiswa->hOrdCurrent ) {
      // Check if any updated column is included in current index column list
      pColumns = hb_arrayGetItemPtr(hb_arrayGetItemPtr(thiswa->aOrders, (HB_ULONG) thiswa->hOrdCurrent), INDEX_FIELDS);
      thiswa->indexColumns = hb_arrayLen(pColumns);

      for( i = 1; i <= thiswa->indexColumns; i++ ) {
         if( thiswa->editMask[hb_arrayGetNL(hb_arrayGetItemPtr(pColumns, i), 2) - 1]) {
            thiswa->bIndexTouchedInUpdate = HB_TRUE;
         }
      }
   }

   return HB_SUCCESS;
}

/*------------------------------------------------------------------------*/

HB_ERRCODE ExecuteUpdateStmt(SQLEXAREAP thiswa)
{
   PHB_ITEM pKey, aRecord;
   HB_SIZE lPos;
   SQLRETURN res;

   // Feed current record to bindings

   thiswa->lUpdatedRecord = GetCurrentRecordNum(thiswa);

   if( FeedRecordCols(thiswa, HB_TRUE) == HB_FAILURE ) { // Stmt created and prepared, only need to push data
      return HB_FAILURE;
   }

   // Execute statement

   res = SQLExecute(thiswa->hStmtUpdate);

   if( res == SQL_ERROR ) {
      odbcErrorDiagRTE(thiswa->hStmtUpdate, "ExecuteUpdateStmt", thiswa->sSql, res, __LINE__, __FILE__);
      SQLCloseCursor(thiswa->hStmtUpdate);
      thiswa->hStmtUpdate = NULL;
      return HB_FAILURE;
   }

   // If any Index column was touched, SKIP buffer is not valid anymore

   if( thiswa->bIndexTouchedInUpdate ) {
      thiswa->recordList[0] = thiswa->recordList[thiswa->recordListPos];
      thiswa->recordListPos = 0;
      thiswa->recordListSize = 1;
   }

   // Update Buffer Pool if needed

   pKey = hb_itemNew(NULL);
   hb_itemPutNL(pKey, thiswa->recordList[thiswa->recordListPos]);

   if( hb_hashScan(thiswa->hBufferPool, pKey, &lPos) ) {
      aRecord = hb_hashGetValueAt(thiswa->hBufferPool, lPos);
      hb_arrayCopy(thiswa->aBuffer, aRecord, NULL, NULL, NULL);
   }
   hb_itemRelease(pKey);

   return HB_SUCCESS;
}

/*------------------------------------------------------------------------*/
