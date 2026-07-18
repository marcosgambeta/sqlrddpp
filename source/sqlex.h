// ODBCRDD C Header
// Copyright (c) 2008 - Marcelo Lombardo  <lombardo@uol.com.br>

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

#ifndef ODBCRDD_H
#define ODBCRDD_H

// TODO: to be revised
#if _MSC_VER >= 1900
#pragma comment(lib, "legacy_stdio_definitions.lib")
#endif

#include <hbsetup.h>
#include <hbapi.h>
#include <hbapirdd.h>
#include <hbapiitm.h>
#include "sqlrdd.ch"

#define SUPERTABLE (&sqlExSuper)

#define MAX_INDEXES 51    // 50 + Natural Order
#define MAX_INDEX_COLS 10 // Seek will work on indexes with up to MAX_INDEX_COLS columns
#define PREPARED_SQL_LEN 400
#define RECORD_LIST_SIZE 250
#define COLUMN_BLOCK_SIZE 64
#define FIELD_LIST_SIZE 6000
#define FIELD_LIST_SIZE_PARAM 600
#define MAX_SQL_QUERY_LEN 32000
#define PAGE_READ_SIZE 50
#define BUFFER_POOL_SIZE 250
#define DEFAULT_INDEX_COLUMN_MAX_LEN 200
#define INITIAL_MEMO_ALLOC 256

static unsigned int openQuotes[24] =
  {
    '"', // SQLRDD_RDBMS_UNKNOW    0
    '"', // SQLRDD_RDBMS_ORACLE    1
    '"', // SQLRDD_RDBMS_MSSQL6    2
    '[', // SQLRDD_RDBMS_MSSQL7    3
    '"', // SQLRDD_RDBMS_SQLANY    4
    '"', // SQLRDD_RDBMS_SYBASE    5
    '"', // SQLRDD_RDBMS_ACCESS    6
    '"', // SQLRDD_RDBMS_INGRES    7
    '"', // SQLRDD_RDBMS_SQLBAS    8
    '"', // SQLRDD_RDBMS_ADABAS    9
    '"', // SQLRDD_RDBMS_INFORM    10
    '"', // SQLRDD_RDBMS_IBMDB2    11
    '`', // SQLRDD_RDBMS_MYSQL     12
    '"', // SQLRDD_RDBMS_POSTGR    13
    '"', // SQLRDD_RDBMS_FIREBR    14
    '"', // SQLRDD_RDBMS_CACHE     15
    '`', // SQLRDD_RDBMS_OTERRO    16
    '"', // SQLRDD_RDBMS_PERVASIVE 17
    '"', // SQLRDD_RDBMS_AZURE     18
    '`', // SQLRDD_RDBMS_MARIADB   19
    '"', // SQLRDD_RDBMS_FIREBR3   20
    '"', // SQLRDD_RDBMS_FIREBR4   21
    '"', // SQLRDD_RDBMS_FIREBR5   22
    '`'  // SQLRDD_RDBMS_CUBRID    23
  };

static unsigned int closeQuotes[24] =
  {
    '"', // SQLRDD_RDBMS_UNKNOW    0
    '"', // SQLRDD_RDBMS_ORACLE    1
    '"', // SQLRDD_RDBMS_MSSQL6    2
    ']', // SQLRDD_RDBMS_MSSQL7    3
    '"', // SQLRDD_RDBMS_SQLANY    4
    '"', // SQLRDD_RDBMS_SYBASE    5
    '"', // SQLRDD_RDBMS_ACCESS    6
    '"', // SQLRDD_RDBMS_INGRES    7
    '"', // SQLRDD_RDBMS_SQLBAS    8
    '"', // SQLRDD_RDBMS_ADABAS    9
    '"', // SQLRDD_RDBMS_INFORM    10
    '"', // SQLRDD_RDBMS_IBMDB2    11
    '`', // SQLRDD_RDBMS_MYSQL     12
    '"', // SQLRDD_RDBMS_POSTGR    13
    '"', // SQLRDD_RDBMS_FIREBR    14
    '"', // SQLRDD_RDBMS_CACHE     15
    '`', // SQLRDD_RDBMS_OTERRO    16
    '"', // SQLRDD_RDBMS_PERVASIVE 17
    '"', // SQLRDD_RDBMS_AZURE     18
    '`', // SQLRDD_RDBMS_MARIADB   19
    '"', // SQLRDD_RDBMS_FIREBR3   20
    '"', // SQLRDD_RDBMS_FIREBR4   21
    '"', // SQLRDD_RDBMS_FIREBR5   22
    '`'  // SQLRDD_RDBMS_CUBRID    23
  };

#define CHECK_SQL_N_OK(res) ((res != SQL_SUCCESS) && (res != SQL_SUCCESS_WITH_INFO))
#define OPEN_QUALIFIER(thiswa) (openQuotes[thiswa->nSystemID])
#define CLOSE_QUALIFIER(thiswa) (closeQuotes[thiswa->nSystemID])
#define RESULTSET_OK HB_SUCCESS + 10
#define RESULTSET_NOK HB_SUCCESS + 11

#undef HB_TRACE
#define HB_TRACE(x, y)

#define SQL_NVARCHAR -9
#define SQL_DB2_CLOB -99
#define SQL_FAKE_LOB -100
#define SQL_FAKE_DATE -101
#define SQL_FAKE_NUM -102

#ifdef __XHARBOUR__
#define HB_LONG LONG
#define HB_ULONG ULONG
#endif

// ODBC Column binding. I know that some information in structure below does exist in
// other parts... I mean, it's duplicated, but I prefer to waste a few bytes more and have
// things at hand, making this RDD faster

typedef struct _SQL_CHAR_STRUCT
{
  SQLCHAR *value;
  int size;
  int size_alloc;
} SQL_CHAR_STRUCT;

typedef struct _INDEXBIND
{
  HB_LONG lFieldPosDB; // Relative field position in aFields
  HB_LONG hIndexOrder; // Index order
  int iLevel;          // The current column in index
  int iIndexColumns;   // How many index columns in index
  HSTMT SkipFwdStmt;   // Index stmt handle for SQL phrase in this level for FWD movment
  HSTMT SkipBwdStmt;   // Index stmt handle for SQL phrase in this level for BWD movment
  HSTMT SeekFwdStmt;   // Index stmt handle for SQL phrase in this level for FWD movment
  HSTMT SeekBwdStmt;   // Index stmt handle for SQL phrase in this level for BWD movment
  char SkipFwdSql[PREPARED_SQL_LEN]; // Partial prepared query for debugging pourposes
  char SkipBwdSql[PREPARED_SQL_LEN]; // Partial prepared query for debugging pourposes
  char SeekFwdSql[PREPARED_SQL_LEN]; // Partial prepared query for debugging pourposes
  char SeekBwdSql[PREPARED_SQL_LEN]; // Partial prepared query for debugging pourposes
} INDEXBIND;

typedef INDEXBIND *INDEXBINDP;

typedef struct _COLUMNBIND
{
  int iParNum;            // Parameter number in binded parameters
  int iSQLType;           // SQL data type of column
  int iCType;             // C data type of the argument. It determines
                          // the as* member to be used, like xHB iTem API 'type'
  HB_LONG lFieldPosDB;    // Relative field position in aFields
  HB_LONG lFieldPosWA;    // Relative field position in aBuffer. NULL if RECNO or DELETED column
  char *colName;          // Fully qualified column name to be used in queries
  SQL_CHAR_STRUCT asChar; // Support for char data types
  SQLCHAR asLogical;      // Support for logical data type
  SQL_DATE_STRUCT asDate; // I suppose ODBC driver will suport default
                          // convertion to TIMESTAMP when needed
  SQL_TIMESTAMP_STRUCT asTimestamp; // Timestamp support, always converted to DATE
  SQLDOUBLE asNumeric;              // I suppose all ODBC drivers has build in
                                    // convertion from this type to all types
                                    // of numeric variables in SQL
  SQLUINTEGER ColumnSize;           // To make an easy bind
  SQLSMALLINT DecimalDigits;        // To make an easy bind
  HB_BOOL isNullable;               // Is this column NULLABLE ?
  HB_BOOL isArgumentNull;           // Value to be bound is NULL ?
  HB_BOOL isBoundNULL;              // Field was bound as NULL ?
  SQLLEN lIndPtr;                   // Buffer lenght pointer to be used in SQLBindParam()
  HB_BOOL isMemo;                   // Field is MEMO ?
  HB_BOOL isMultiLang;              // Fiels is multi language ?
} COLUMNBIND;

typedef COLUMNBIND *COLUMNBINDP;

// SQL WORKAREA

typedef struct _SQLEXAREA
{
  AREA area;

  // SQLRDD's additions to the workarea structure
  // Warning: The above section MUST match WORKAREA exactly! Any
  // additions to the structure MUST be added below

  PHB_CODEPAGE cdPageCnv; // Area's codepage convert pointer
  char *szDataFileName;   // file name
  HB_LONG hOrdCurrent;    // current index order

  HB_BOOL shared;
  HB_BOOL readonly;      // only SELECT allowed
  HB_BOOL creating;      // TRUE when creating table
  HB_BOOL firstinteract; // TRUE when workarea was not used yet
  HB_BOOL isam;          // ISAM Simulator ?
  HB_BOOL wasdel;
  HB_BOOL initialized; // Workarea Initialization done
  HB_BOOL sqlfilter;   // SET FILTER converted to SQL

  PHB_ITEM oWorkArea;  // SQL Workarea object
  PHB_ITEM aInfo;      // Status array
  PHB_ITEM aBuffer;    // Record buffer
  PHB_ITEM aOrders;    // Indexes
  PHB_ITEM aStruct;    // Table xBase structure
  PHB_ITEM aLocked;    // Locked lines
  PHB_ITEM aCreate;    // Structure received by dbCreate()
  PHB_ITEM aCache;     // Workarea recordset cache
  PHB_ITEM aOldBuffer; // Last workarea buffer
  PHB_ITEM aEmptyBuff; // Empty buffer to be in eof()+1
  PHB_ITEM aSelectList;

  HB_ULONG ulhRecno;   // Recno position in field list
  HB_ULONG ulhDeleted; // Deleted position in field list

  int *uiBufferIndex;    // Field offset in fields array
  int *uiFieldList;      // Keeps a field list for SELECT statements
  int iColumnListStatus; // field list status - see sqlprototypes.h

  LPDBRELINFO lpdbPendingRel; // Pointer to parent rel struct

  // SQLEX's additions to the SQLRDD workarea structure

  PHB_ITEM oSql;        // SQL connection object
  PHB_ITEM aFields;     // Table structure in DB
  PHB_ITEM hBufferPool; // Hash containing the Buffer Pool
  PHB_ITEM pIndexMgmnt; // Existing Indexes in database catalog (SR_MGMNTINDEXES) array

  HSTMT hStmt;             // Statement handle
  HSTMT hStmtBuffer;       // Statement handle with prepared statement to retrieve line
  HSTMT hStmtInsert;       // Statement handle with prepared phrase to insert a new record
  HSTMT hStmtNextval;      // Statement handle with prepared phrase to get inserted record
  HSTMT hStmtUpdate;       // Statement handle with prepared phrase to insert a new record
  HDBC hDbc;               // Database connection handle
  int nSystemID;           // Connected database ID
  HB_ULONG lCurrentRecord; // Should be filled by SR_GetCurrentRecordNum() to be used in SKIP
                           // bindings
  HB_ULONG lUpdatedRecord; // Should be filled by SR_GetCurrentRecordNum() to be used in UPDATE
                           // bindings
  HB_ULONG lBofAt;         // BOF Record optimizer
  HB_ULONG lEofAt;         // EOF Record optimizer
  HB_ULONG lLastRec;       // LastRec() + 1
  HB_ULONG *lRecordToRetrieve; // To be used with Binded Parameter
  HB_ULONG *recordList;        // record list to skip on
  char *deletedList;           // deleted list relative to record list
  int recordListPos;           // record list position
  int recordListSize;          // record list size
  int recordListDirection;     // SR_LIST_FORWARD or SR_LIST_BACKWARD
  int iTCCompat;               // Top Connect compatible

  int indexColumns; // current index column list lenght
  int indexLevel;   // index column list level in current skip sequence

  int skipDirection; // 1 - FWD, (-1) - BWD, 0 - none

  char *sFields;      // field list string
  char *sSql;         // Last SQL phrase
  char *sSqlBuffer;   // SQL Statement to get WA buffer
  char *sTable;       // Qualified table name
  char *sOwner;       // Database schema included in sTable
  char *sWhere;       // Where clause
  char *sOrderBy;     // Order By clause
  char *sRecnoName;   // Recno column name
  char *sDeletedName; // Deleted column name
  char sLimit1[50];   // String for recordset limit
  char sLimit2[50];   // String for recordset limit

  HB_BOOL bufferHot;     // Does it have to write buffer down to database ?
  HB_BOOL bIsInsert;     // HB_TRUE if appending a new record
  HB_BOOL bConnVerified; // Already checked for ODBC connection ?
  HB_BOOL bReverseIndex; // If current index is in DESCENDING order
  // INDEXBINDP IndexBindings[MAX_INDEXES]; // Index column and prepared SQL expression handles
  // for SKIP
  INDEXBINDP *IndexBindings; // Index column and prepared SQL expression handles for SKIP

  HSTMT *colStmt;             // Single column retrieving statements
  HB_BOOL bConditionChanged1; // If any of conditions like filters, scope, historic, has
                              // changed, prepared statements handles for Record List
                              // are no longer valid - USED FOR SKIP / GO TOP / BO BOTTOM
  HB_BOOL bConditionChanged2; // If any of conditions like filters, scope, historic, has
                              // changed, prepared statements handles for Record List
                              // are no longer valid - USED FOR SEEK
  HB_BOOL bOrderChanged;      // If order has changed, we should fix column bindings
                              // before use then
  HB_BOOL bRebuildSeekQuery;  // If query for Seek must be recreated due to NULL interference
  HB_BOOL bHistoric;          // TRUE if workarea has historic
  COLUMNBINDP InsertRecord;   // Column bindings to INSERT
  COLUMNBINDP CurrRecord;     // Current record bindings for SKIP / UPDATE
  char editMask[MAX_FIELDS]; // Flags if a column was updated - must be cleared on every GO_COLD
  char updatedMask[MAX_FIELDS];  // Copy of updateMask in currently prepared UPDATE stmt
  char specialMask[MAX_FIELDS];  // Same of updateMask but for special cols (INDKEY_xx and
                                 // FORKEY_xx)
  HB_BOOL bIndexTouchedInUpdate; // If any index column is affected by UPDATE
  HB_BOOL bIsSelect;             // Table open is an select statement
} SQLEXAREA;

typedef SQLEXAREA *LPSQLEXAREA;

#ifndef SQLEXAREAP
#define SQLEXAREAP LPSQLEXAREA
#endif

// prototypes

// int SR_sqlKeyCompare(AREAP thiswa, PHB_ITEM pKey, HB_BOOL fExact); NOTE: changed to static
void SR_odbcErrorDiag(HSTMT hStmt, const char *routine, const char *szSql, int line);
void SR_odbcErrorDiagRTE(HSTMT hStmt, const char *routine, const char *szSql, SQLRETURN res,
                         int line, const char *module);
// void SR_odbcFieldGet(PHB_ITEM pField, PHB_ITEM pItem, char *bBuffer, HB_ISIZ lLenBuff,
// HB_BOOL bQueryOnly,
//                   HB_ULONG ulSystemID, HB_BOOL bTranslate); NOTE: changed to static
char *SR_QuoteTrimEscapeString(char *FromBuffer, HB_ULONG iSize, int idatabase, HB_BOOL bRTrim,
                               HB_ULONG *iSizeOut);
char *SR_quotedNull(PHB_ITEM pFieldData, PHB_ITEM pFieldLen, PHB_ITEM pFieldDec,
                    HB_BOOL bNullable, int nSystemID, HB_BOOL bTCCompat, HB_BOOL bMemo,
                    HB_BOOL *bNullArgument);
HB_BOOL SR_itemEmpty(PHB_ITEM pItem);
void SR_commonError(AREAP ThisDb, HB_USHORT uiGenCode, HB_USHORT uiSubCode,
                    const char *filename);
HB_ERRCODE SR_SetBindEmptylValue(COLUMNBINDP BindStructure);
HB_ERRCODE SR_SetBindValue(PHB_ITEM pFieldData, COLUMNBINDP BindStructure, HSTMT hStmt);
char *SR_QualifyName(char *szName, SQLEXAREAP thiswa);
COLUMNBINDP SR_GetBindStruct(SQLEXAREAP thiswa, INDEXBINDP IndexBind);
HB_BOOL SR_getColumnList(SQLEXAREAP thiswa);
void SR_SolveFilters(SQLEXAREAP thiswa, HB_BOOL bWhere);
void SR_getOrderByExpression(SQLEXAREAP thiswa, HB_BOOL bUseOptimizerHints);
void SR_setResultSetLimit(SQLEXAREAP thiswa, int iRows);
void SR_SetIndexBindStructure(SQLEXAREAP thiswa);
void SR_SetInsertRecordStructure(SQLEXAREAP thiswa);
HB_ULONG SR_GetCurrentRecordNum(SQLEXAREAP thiswa);
extern void SR_odbcGetData(SQLHSTMT hStmt, PHB_ITEM pField, PHB_ITEM pItem, HB_BOOL bQueryOnly,
                           HB_ULONG ulSystemID, HB_BOOL bTranslate, HB_USHORT ui);

// INSERT and UPDATE prototypes

void SR_CreateInsertStmt(SQLEXAREAP thiswa);
void SR_SetCurrRecordStructure(SQLEXAREAP thiswa);
HB_ERRCODE SR_CreateUpdateStmt(SQLEXAREAP thiswa);
HB_ERRCODE SR_PrepareInsertStmt(SQLEXAREAP thiswa);
HB_ERRCODE SR_BindInsertColumns(SQLEXAREAP thiswa);
HB_ERRCODE SR_FeedRecordCols(SQLEXAREAP thiswa, HB_BOOL bUpdate);
HB_ERRCODE SR_ExecuteInsertStmt(SQLEXAREAP thiswa);
HB_ERRCODE SR_ExecuteUpdateStmt(SQLEXAREAP thiswa);

// SEEK Prototypes

HB_ERRCODE SR_FeedSeekKeyToBindings(SQLEXAREAP thiswa, PHB_ITEM pKey, int *queryLevel);
HB_BOOL SR_CreateSeekStmt(SQLEXAREAP thiswa, int queryLevel);
void SR_BindSeekStmt(SQLEXAREAP thiswa, int queryLevel);
HB_ERRCODE SR_getPreparedSeek(SQLEXAREAP thiswa, int queryLevel, HB_USHORT *iIndex,
                              HSTMT *hStmt);

#endif // ODBCRDD_H
