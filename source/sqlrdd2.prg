// SQLRDD Support Classes
// WorkArea abstract class
// Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>

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

// xHarbour compatibility
#ifdef __XHARBOUR__
#xtranslate HB_HASH([<x,...>]) => HASH(<x>)
#xtranslate HB_HALLOCATE([<x,...>]) => HALLOCATE(<x>)
#xtranslate HB_HPOS([<x,...>]) => HGETPOS(<x>)
//#xtranslate HB_HVALUEAT([<x,...>]) => HGETVALUEAT(<x>)
//#xtranslate HB_HVALUEAT([<x,...>]) => HSETVALUEAT(<x>)
#xtranslate HB_HDELAT([<x,...>]) => HDELAT(<x>)
#xtranslate HB_HEVAL([<x,...>]) => HEVAL(<x>)
#xtranslate HB_TTOS([<x>]) => TTOS(<x>)
#xtranslate HB_TTOC([<x,...>]) => TTOC(<x>)
#xtranslate HB_STRTOHEX([<c,...>]) => STRTOHEX(<c>)
#xtranslate HB_STOT([<x>]) => STOT(<x>)
#xtranslate HB_ADEL([<x,...>]) => ADEL(<x>)
#endif

// set of macros to check the RDBMS
#define ISACCESS() (::oSql:nSystemID == SQLRDD_RDBMS_ACCESS)
#define ISADABAS() (::oSql:nSystemID == SQLRDD_RDBMS_ADABAS)
#define ISAZURE() (::oSql:nSystemID == SQLRDD_RDBMS_AZURE)
#define ISCACHE() (::oSql:nSystemID == SQLRDD_RDBMS_CACHE)
#define ISCUBRID() (::osql:nsystemID == SQLRDD_RDBMS_CUBRID)
#define ISFIREBIRD() (::oSql:nSystemID == SQLRDD_RDBMS_FIREBR)
#define ISFIREBIRD3() (::oSql:nSystemID == SQLRDD_RDBMS_FIREBR3)
#define ISFIREBIRD4() (::oSql:nSystemID == SQLRDD_RDBMS_FIREBR4)
#define ISFIREBIRD5() (::oSql:nSystemID == SQLRDD_RDBMS_FIREBR5)
#define ISIBMDB2() (::oSql:nSystemID == SQLRDD_RDBMS_IBMDB2)
#define ISINFORM() (::oSql:nSystemID == SQLRDD_RDBMS_INFORM)
#define ISINGRES() (::oSql:nSystemID == SQLRDD_RDBMS_INGRES)
#define ISMARIADB() (::oSql:nSystemID == SQLRDD_RDBMS_MARIADB)
#define ISMSSQL6() (::oSql:nSystemID == SQLRDD_RDBMS_MSSQL6)
#define ISMSSQL7() (::oSql:nSystemID == SQLRDD_RDBMS_MSSQL7)
#define ISMYSQL() (::oSql:nSystemID == SQLRDD_RDBMS_MYSQL)
#define ISORACLE() (::oSql:nSystemID == SQLRDD_RDBMS_ORACLE)
#define ISPOSTGRESQL() (::osql:nsystemID == SQLRDD_RDBMS_POSTGR)
#define ISSQLANY() (::oSql:nSystemID == SQLRDD_RDBMS_SQLANY)
#define ISSQLBAS() (::oSql:nSystemID == SQLRDD_RDBMS_SQLBAS)
#define ISSYBASE() (::oSql:nSystemID == SQLRDD_RDBMS_SYBASE)

#include <common.ch>
#include <hbclass.ch>
#include <error.ch>
#include <dbinfo.ch>

#include "sqlrdd.ch"
#include "sqlrddpp.ch"
#include "sqlodbc.ch"
#include "ord.ch"
#include "msg.ch"
#include "set.ch"
#include "sqlrddsetup.ch"
#ifdef __XHARBOUR__
#include "hbxml.ch" // Culik added to support arrays as xml
#else
#include "srxml.ch" // Culik added to support arrays as xml
#endif

#define DUPL_IND_DETECT                .F.
#define SQLRDD_LEARNING_REPETITIONS     5

STATIC s_lUseXmlField := .F.
STATIC s_lUseJSONField := .F.

/*
// static variables used only in STATIC FUNCTION aScanIndexed(...) (static function not used)
#ifdef __XHARBOUR__
// NOTE: to avoid warning about variable declared but not used in function.
STATIC s_ItP11 := NIL
STATIC s_ItP14 := NIL
STATIC s_ItP2 := NIL
STATIC s_ItP3 := NIL
#else
STATIC s_ItP11
STATIC s_ItP14
STATIC s_ItP2
STATIC s_ItP3
#endif
*/

STATIC s_lGoTopOnFirstInteract := .T.
STATIC s_lUseDTHISTAuto := .F.
STATIC s_nLineCountResult := 0
STATIC s_cGlobalOwner := ""
STATIC s_nOperat := 0
STATIC s_cMySqlMemoDataType := "MEDIUMBLOB"
STATIC s_cMySqlNumericDataType := "REAL"
STATIC s_lUseDBCatalogs := .F.
STATIC s_lAllowRelationsInIndx := .F.
STATIC s_____lOld
STATIC s_nMininumVarchar2Size := 31
STATIC s_lOracleSyntheticVirtual := .T.

//----------------------------------------------------------------------------//

CLASS SR_WORKAREA

   CLASSDATA nCnt
   CLASSDATA cWSID
   CLASSDATA aExclusive       AS ARRAY    INIT {}

   DATA aInfo         AS ARRAY INIT {.T., .T., .F., 0, 0, 0, .F., .F., 0, 0, .F., .F., 0, 0, .T., 0, .F., 0, .F., 0, 0, 0, 0, 0}  // See sqlrdd.ch, SR_AINFO_*
   DATA aLocked       AS ARRAY INIT {}
   DATA aIndex        AS ARRAY INIT {}
   DATA aIndexMgmnt   AS ARRAY INIT {}
   DATA aConstrMgmnt  AS ARRAY INIT {}
   DATA aCache        AS ARRAY INIT Array(SR_CACHE_PAGE_SIZE * 3)
   DATA aLocalBuffer  AS ARRAY INIT {}
   DATA aOldBuffer    AS ARRAY INIT {}
   DATA aEmptyBuffer  AS ARRAY INIT {}
   DATA aSelectList   AS ARRAY INIT {}

   DATA nThisArea     AS NUMERIC INIT 0
   DATA nFetchSize    AS NUMERIC INIT SR_FetchSize()

   DATA cOwner        AS CHARACTER INIT ""
   DATA cColPK        AS CHARACTER INIT ""
   DATA cFor          AS CHARACTER INIT ""
   DATA cScope        AS CHARACTER INIT ""
   DATA cOriginalFN   AS CHARACTER INIT ""
   DATA cRights       AS CHARACTER INIT ""
   DATA cRecnoName    AS CHARACTER INIT ""
   DATA cDeletedName  AS CHARACTER INIT ""

   DATA cQualifiedTableName  AS CHARACTER
   DATA lTableIsSelect       INIT .F.

   DATA Optmizer_1s
   DATA Optmizer_1e
   DATA Optmizer_ns
   DATA Optmizer_ne

   DATA nCurrentFetch   AS NUMERIC INIT SR_FetchSize()
   DATA nSkipCount      AS NUMERIC INIT 0
   DATA nLastRecordAded AS NUMERIC INIT -1
   DATA nLastRefresh    AS NUMERIC INIT 0
   DATA hnRecno         AS NUMERIC INIT 0
   DATA hnDeleted       AS NUMERIC INIT 0

   DATA cLastMove       AS CHARACTER INIT ""
   DATA cLastComm       AS CHARACTER INIT ""

   DATA lStable        AS LOGICAL INIT .T.
   DATA lOrderValid    AS LOGICAL INIT .F.
   DATA lTableLocked   AS LOGICAL INIT .F.
   DATA lHistoric      AS LOGICAL INIT .F.
   DATA lHistEnable    AS LOGICAL INIT .T.
   DATA lNoData        AS LOGICAL INIT .F.
   DATA lEmptyTable    AS LOGICAL INIT .F.
   DATA lVers          AS LOGICAL INIT .T.
   DATA lDisableFlts   AS LOGICAL INIT .F.
   DATA lSharedLock    AS LOGICAL INIT .F.
   DATA lOpened        AS LOGICAL INIT .T.
   DATA lCreating      AS LOGICAL INIT .F.
   DATA lQuickAppend   AS LOGICAL INIT .F.
   DATA lUseSequences  AS LOGICAL INIT .T.

   DATA lCollectingBehavior  AS LOGICAL INIT .T.
   DATA lAllColumnsSelected  AS LOGICAL INIT .F.

   DATA nTCCompat      AS NUMERIC INIT 0      // TopConnect compatibility mode

   DATA nSequencePerTable  AS NUMERIC INIT SEQ_NOTDEFINED

   DATA bScope    AS CODEBLOCK INIT {||.T.}
   DATA bFilter   AS CODEBLOCK INIT {||.T.}

   DATA oSql      AS OBJECT

   DATA cFileName
   DATA aFields
   DATA aIniFields
   DATA aNames
   DATA aNamesLower
   DATA nPosColPK
   DATA cAlias
   DATA aFilters
   DATA nFields
   DATA CurrDate
   DATA cFltUsr
   DATA cFilter
   DATA nLogMode
   DATA lCanSel
   DATA lCanUpd
   DATA lCanIns
   DATA lCanDel
   DATA nRelacType
   DATA lISAM
   DATA cCustomSQL
   DATA nLastRec
   DATA lGoTopOnFirstInteract
   DATA aLastOrdCond

   DATA lFetchAll AS LOGICAL INIT .F.
   DATA aFetch    AS ARRAY   INIT {}

   DATA cDel
   DATA cUpd
   DATA cIns
   DATA nPosDtHist
   DATA dNextDt                              // Date value for next INSERT with Historic

   DATA aPosition
   DATA aQuoted
   DATA aDat
   DATA aSeekXF   AS ARRAY INIT {}          // client side transforms for seek found() check (expression indexes)
   DATA nPartialDateSeek

   // For Self recno filter
   Data aRecnoFilter AS ARRAY INIT {}

   // SQL Methods

   METHOD ResetStatistics() INLINE (::nCurrentFetch := SR_FetchSize(), ::aInfo[SR_AINFO_SKIPCOUNT] := 0, ::cLastMove := "OPEN")
   METHOD GetNextRecordNumber()

   METHOD IniFields(lReSelect, lLoadCache, aInfo)
   METHOD Refresh(lGoCold)
   METHOD GetBuffer(lClean, nCache)
   METHOD SolveSQLFilters(cAliasSQL)
   METHOD SolveRestrictors()
   METHOD Default()
   METHOD UpdateCache(aResultSet)
   METHOD lCanICommitNow()
   METHOD WriteBuffer(lInsert, aBuffer)
   METHOD QuotedNull(uData, trim, nLen, nDec, nTargetDB, lNull, lMemo)
   METHOD Quoted(uData, trim, nLen, nDec, nTargetDB, lSynthetic)
   METHOD CheckCache(oWorkArea)
   METHOD WhereEqual()
   METHOD RuntimeErr(cOperation, cErr, nOSCode, nGenCode, SubCode)
   METHOD Normalize(nDirection)
   METHOD SkipRawCache(nToSkip)
   METHOD Stabilize()
   METHOD FirstFetch(nDirection)
   METHOD OrderBy(nOrder, lAscend, lRec)
   METHOD ReadPage(nDirection, lWasDel)
   METHOD WhereMajor()       // Retrieves an SQL/WHERE Major or equal the currente record
   METHOD WhereMinor()       // Retrieves an SQL/WHERE Minor or equal the currente record
   //METHOD WhereVMajor()       // Retrieves an SQL/WHERE Major or equal the currente record (Synthetic Virtual Index)
   METHOD WhereVMajor(cQot)
   //METHOD WhereVMinor()       // Retrieves an SQL/WHERE Minor or equal the currente record (Synthetic Virtual Index)
   METHOD WhereVMinor(cQot)
   //METHOD WherePgsMajor(aQuotedCols)    // Retrieves an SQL/WHERE Major or equal the currente record
   METHOD WherePgsMajor(aQuotedCols, lPartialSeek)
   METHOD WherePgsMinor(aQuotedCols)    // Retrieves an SQL/WHERE Minor or equal the currente record
   // METHOD sqlKeyCompare(uKey)                       C level implemented - reads from ::aInfo
   METHOD ParseIndexColInfo(cSQL)

   // Expression index support (PostgreSQL native expression indexes)

   METHOD ParseIndexComponents(cExpr)   // xBase index key => array of components or NIL
   METHOD BuildIndexComponent(cItem)    // one component => column name, component array or NIL
   METHOD IndexFieldSQL(aFld)           // SQL expression (or qualified column) of a component
   METHOD IndexFieldVal(aFld)           // current buffer value of a component (client side transform)
   METHOD IndexFieldType(aFld)          // component type ("C" for expressions)
   METHOD IndexFieldLen(aFld)           // component length
   METHOD IndexFieldDec(aFld)           // component decimals
   METHOD IndexFieldNul(aFld)           // component nullability (.F. for expressions)
   METHOD HasExpressionOrder()          // .T. when the active order has expression components
   METHOD CanOpenExpressionIndex()      // .T. when this workarea can OPEN expression indexes
   METHOD CanUseExpressionIndex()       // .T. when this workarea can CREATE expression indexes

   METHOD HasFilters()
   METHOD ParseForClause(cFor)
   METHOD OrdSetForClause(cFor, cForxBase)
   METHOD SetColPK(cColName)
   METHOD ConvType(cData, cType, lPartialSeek, nThis, lLike)

   METHOD LoadRegisteredTags()

   METHOD LockTable(lCheck4ExcLock, lFLock) //METHOD LockTable(lCheck)
   METHOD UnlockTable(lClosing) //METHOD UnlockTable()

   METHOD FCount() INLINE ::nFields
   METHOD SetNextDt(d) INLINE ::dNextDt := d
   METHOD SetQuickAppend(l) INLINE (s_____lOld := ::lQuickAppend, ::lQuickAppend := l, s_____lOld)

   // Table maintanance stuff

   METHOD AlterColumns(aCreate, lDisplayErrorMessage, lBakcup)
   //This is an new method for direct alter column
   METHOD AlterColumnsDirect(aCreate, lDisplayErrorMessage, lBakcup, aRemove)
   METHOD DropColumn(cColumn, lDisplayErrorMessage, lRemoveFromWA)
   METHOD DropColRules(cColumn, lDisplayErrorMessage, aDeletedIndexes)
   METHOD AddRuleNotNull(cColumn)
   METHOD DropRuleNotNull(cColumn)

   METHOD DropConstraint(cTable, cConstraintName, lFKs, cConstrType)
   METHOD CreateConstraint(cSourceTable, aSourceColumns, cTargetTable, aTargetColumns, cConstraintName)

   // Historic functionality specific methods

   //METHOD HistExpression(cAlias, cAlias)
   METHOD HistExpression(n, cAlias)
   METHOD DisableHistoric()
   METHOD EnableHistoric()
   METHOD SetCurrDate(d) INLINE IIf(d == NIL, ::CurrDate, ::CurrDate := d)

   METHOD LineCount(lMsg) //METHOD LineCount()
   METHOD CreateOrclFunctions(cOwner, cFileName)

   METHOD sqlOpenAllIndexes()
   METHOD IncludeAllMethods()

   // Workarea methods reflexion

   // METHOD sqlBof                       C level implemented - reads from ::aInfo
   // METHOD sqlEof                       C level implemented - reads from ::aInfo
   // METHOD qlFound                      C level implemented - reads from ::aInfo
   METHOD sqlGoBottom()
   METHOD sqlGoPhantom()
   METHOD sqlGoTo(uRecord, lNoOptimize)
   // METHOD sqlGoToId                    C level implemented - maps to sqlGoTo()
   METHOD sqlGoTop()
   METHOD sqlSeek(uKey, lSoft, lLast)
   // METHOD sqlSkip                      C level implemented
   // METHOD sqlSkipFilter                Superclass does the job
   // METHOD sqlSkipRaw                   C level implemented
   // METHOD sqlAddField                  Superclass does the job
   // METHOD sqlAppend()                  C level implemented
   // METHOD sqlCreateFields              Superclass does the job
   METHOD sqlDeleteRec()
   // METHOD sqlDeleted                   C level implemented - reads from ::aInfo
   // METHOD sqlFieldCount                C level implemented - reads from ::aInfo
   // METHOD sqlFieldDisplay              Superclass does the job
   // METHOD sqlFieldInfo                 Superclass does the job
   // METHOD sqlFieldName                 Superclass does the job
   METHOD sqlFlush()
   // METHOD sqlGetRec                    Superclass does the job
   METHOD sqlGetValue(nField)
   // METHOD sqlGetVarLen                 C level implemented - reads from aLocalBuffer
   METHOD sqlGoCold()                     // NOT called from SQLRDD1.C
   // METHOD sqlGoHot                     C level implemented - writes to ::aInfo
   // METHOD sqlPutRec                    Superclass does the job
   // METHOD sqlPutValue                  C level implemented - writes to aLocalBuffer
   METHOD sqlRecall()
   // METHOD sqlRecCount                  C level implemented - reads from ::aInfo
   // METHOD sqlRecInfo                   Superclass does the job
   // METHOD sqlRecNo                     C level implemented - reads from ::aInfo
   // METHOD sqlSetFieldExtent            Superclass does the job
   // METHOD sqlAlias                     Superclass does the job
   METHOD sqlClose()
   METHOD sqlCreate(aStruct, cFileName, cAlias, nArea)
   // METHOD sqlInfo                      C level implemented - reads from ::aInfo
   // METHOD sqlNewArea                   Superclass does the job
   //METHOD sqlOpenArea(cFileName, nArea, lShared, lReadOnly, cAlias) // the constructor
   METHOD sqlOpenArea(cFileName, nArea, lShared, lReadOnly, cAlias, nDBConnection)
   // METHOD sqlRelease                   Superclass does the job
   // METHOD sqlStructSize                C level implemented
   // METHOD sqlSysName                   C level implemented
   // METHOD sqlEval                      Superclass does the job
   METHOD sqlPack()
   // METHOD sqlPackRec                   Superclass does the job
   // METHOD sqlSort                      Superclass does the job - UNSUPPORTED
   // METHOD sqlTrans                     Superclass does the job
   // METHOD sqlTransRec                  Superclass does the job
   METHOD sqlZap()
   // METHOD sqlChildEnd                  C level implemented
   // METHOD sqlChildStart                C level implemented
   // METHOD sqlChildSync                 C level implemented
   // METHOD sqlSyncChildren              C level implemented
   // METHOD sqlClearRel                  C level implemented
   // METHOD sqlForceRel                  C level implemented
   // METHOD sqlRelArea                   Superclass does the job
   // METHOD sqlRelEval                   Superclass does the job
   // METHOD sqlRelText                   Superclass does the job
   // METHOD sqlSetRel                    C level implemented
   METHOD sqlOrderListAdd(cBagName, cTag)
   METHOD sqlOrderListClear()
   // METHOD sqlOrderListDelete           Superclass does the job
   METHOD sqlOrderListFocus(uOrder, cBag)
   METHOD sqlOrderListNum(uOrder)       // Used by sqlOrderInfo
   // METHOD sqlOrderListRebuild          Superclass does the job - UNSUPPORTED
   METHOD sqlOrderCondition(cFor, cWhile, nStart, nNext, uRecord, lRest, lDesc)
   METHOD sqlOrderCreate(cIndexName, cColumns, cTag, cConstraintName, cTargetTable, aTargetColumns, lEnable)
   METHOD sqlOrderDestroy(uOrder, cBag)
   // METHOD sqlOrderInfo                 C level implemented - reads from ::aInfo and ::aIndex
   METHOD sqlClearFilter()
   // METHOD sqlClearLocate               Superclass does the job
   METHOD sqlClearScope()
   // METHOD sqlCountScope                Superclass does the job
   METHOD sqlFilterText()
   // METHOD sqlScopeInfo                 C level implemented
   METHOD sqlSetFilter(cFilter)
   // METHOD sqlSetLocate                 Superclass does the job
   METHOD sqlSetScope(nType, uValue)
   // METHOD sqlSkipScope                 Superclass does the job
   // METHOD sqlCompile                   Superclass does the job
   // METHOD sqlError                     Superclass does the job
   // METHOD sqlEvalBlock                 Superclass does the job
   // METHOD sqlRawLock                   Superclass does the job
   METHOD sqlLock(nType, uRecord)
   METHOD sqlUnLock(uRecord)
   // METHOD sqlCloseMemFile              Superclass does the job - UNSUPPORTED
   // METHOD sqlCreateMemFile             Superclass does the job - UNSUPPORTED
   // METHOD sqlGetValueFile              Superclass does the job - UNSUPPORTED
   // METHOD sqlOpenMemFile               Superclass does the job - UNSUPPORTED
   // METHOD sqlPutValueFile              Superclass does the job - UNSUPPORTED
   // METHOD sqlReadDBHeader              Superclass does the job - UNSUPPORTED
   // METHOD sqlWriteDBHeader             Superclass does the job - UNSUPPORTED
   // METHOD sqlExit                      Superclass does the job
   METHOD sqlDrop(cFileName)
   METHOD sqlExists(cFileName)
   // METHOD sqlWhoCares                  Superclass does the job

   METHOD SetBOF()
   METHOD sqlKeyCount(lFilters)
   METHOD sqlRecSize()
   METHOD GetSyntheticVirtualExpr(aExpr, cAlias)
   METHOD GetSelectList()
   METHOD RecnoExpr()   // add recno filters
   // DESTRUCTOR WA_ENDED

ENDCLASS

//----------------------------------------------------------------------------//

// PROCEDURE SR_WORKAREA:WA_ENDED
//
//    ? "Cleanup:", "WORKAREA", ::cFileName
//
// RETURN

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlSetFilter(cFilter)

   LOCAL cExpr
#ifdef NG_DEVELOPMENT
   LOCAL oParser
   LOCAL oTranslator
#endif

   cExpr := ::ParseForClause(cFilter)

   // Try it

   IF ::oSql:oSqlTransact:Exec("SELECT A.* FROM " + ::cQualifiedTableName + " A WHERE 0 = 1 AND (" + cExpr + ")", .F.) == SQL_SUCCESS
      ::cFilter := cExpr
      ::Refresh()
      ::oSql:oSqlTransact:Commit()
      RETURN SQL_SUCCESS
   ENDIF

#ifdef NG_DEVELOPMENT
   // Try with Maxime parser
   oParser := SR_ConditionParser():New(::cAlias)
   oTranslator := SR_MSSQLExpressionTranslator():New(::cAlias, .F., .T.)
   cExpr := oTranslator:GetTranslation(oParser:Parse(cFilter)):cSQLCondition

   IF ::oSql:oSqlTransact:Exec("SELECT A.* FROM " + ::cQualifiedTableName + " A WHERE 0 = 1 AND (" + cExpr + ")", .F.) == SQL_SUCCESS
      ::cFilter := cExpr
      ::Refresh()
      ::oSql:oSqlTransact:Commit()
      RETURN SQL_SUCCESS
   ENDIF
#endif

   ::oSql:oSqlTransact:Commit()

RETURN SQL_ERROR

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlClearFilter()

   ::cFilter := ""
   ::Refresh()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlFilterText()

   IF ::cFilter == NIL
      RETURN ""
   ENDIF

RETURN ::cFilter

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:GetSelectList()

   LOCAL i
   LOCAL nLen := Len(::aFields)
   LOCAL cSelectList := " "
   LOCAL nFeitos := 0
   LOCAL aInd

   IF ::lCollectingBehavior .OR. ::lAllColumnsSelected
      IF ISPOSTGRESQL() .AND. SR_getUseXmlField()
      ELSE
         AEval(::aFields, {|x, i|HB_SYMBOL_UNUSED(x), ::aFields[i, SR_FIELD_ENUM] := i})
         RETURN " A.* "
      ENDIF
   ENDIF

   IF ::hnDeleted > 0
      ::aSelectList[::hnDeleted] := 1
   ENDIF
   ::aSelectList[::hnRecno] := 1

   // Current order fields should be added to select list

   IF ::aInfo[SR_AINFO_INDEXORD] > 0
      aInd := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]
      FOR i := 1 TO Len(aInd)
         ::aSelectList[aInd[i, 2]] := 1
      NEXT i
   ENDIF

   FOR i := 1 TO nLen
      IF ::aSelectList[i] == 1
         nFeitos++
         cSelectList += IIf(nFeitos > 1, ", A.", "A.") + SR_DBQUALIFY(::aNames[i], ::oSql:nSystemID)
         IF ISPOSTGRESQL() .AND. ::aFields[i, SR_FIELD_DOMAIN] == SQL_LONGVARCHARXML
            cSelectList += "::varchar"
         ENDIF

         ::aFields[i, SR_FIELD_ENUM] := nFeitos
      ELSE
         ::aFields[i, SR_FIELD_ENUM] := 0
      ENDIF
   NEXT i

   IF nFeitos == nLen
      IF ISPOSTGRESQL() .AND. SR_getUseXmlField()
      ELSE
         cSelectList := " A.* "
         ::lAllColumnsSelected := .T.
      ENDIF
   ENDIF

RETURN cSelectList + " "

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlGetValue(nField)

   LOCAL aRet := {NIL}
   LOCAL lOldIndex

   IF ::aInfo[SR_AINFO_DETECT1_COUNT] > SQLRDD_LEARNING_REPETITIONS
      ::lAllColumnsSelected := .T.
      ::sqlGoTo(::aInfo[SR_AINFO_RECNO], .T.)
      RETURN ::aLocalBuffer[nField]
   ENDIF

   IF ::oSql:Execute("SELECT " + SR_DBQUALIFY(::aNames[nField], ::oSql:nSystemID) + ;
      " FROM " + ::cQualifiedTableName + ::WhereEqual()) == SQL_SUCCESS

      lOldIndex := ::aFields[nField, SR_FIELD_ENUM]
      ::aFields[nField, SR_FIELD_ENUM] := 1

      IF ::oSql:Fetch(NIL, .F., {::aFields[nField]}) == SQL_SUCCESS
         ::oSql:GetLine({::aFields[nField]}, .F., @aRet)
         IF aRet[1] != NIL
            ::aLocalBuffer[nField] := aRet[1]
            IF ::aInfo[SR_AINFO_NPOSCACHE] > 0 .AND. ::aCache[::aInfo[SR_AINFO_NPOSCACHE]] != NIL .AND. Len(::aCache[::aInfo[SR_AINFO_NPOSCACHE]]) > 0
               ::aCache[::aInfo[SR_AINFO_NPOSCACHE], nField] := aRet[1]
               IF ::aInfo[SR_AINFO_DETECT1_LASTRECNO] != ::aInfo[SR_AINFO_RECNO]
                  ::aInfo[SR_AINFO_DETECT1_COUNT] ++
                  ::aInfo[SR_AINFO_DETECT1_LASTRECNO] := ::aInfo[SR_AINFO_RECNO]
               ENDIF
            ENDIF
         ENDIF
      ENDIF

      ::aFields[nField, SR_FIELD_ENUM] := lOldIndex

   ENDIF

RETURN aRet[1]

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlRecSize()

   LOCAL i := 0
   LOCAL aCol

   FOR EACH aCol IN ::aFields
      i += aCol[3]
   NEXT

RETURN i

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:SolveRestrictors()

   lOCAL cRet := ""

   IF !Empty(::cFor)
      cRet += "(" + ::cFor + ")"
   ENDIF

   IF !::lDisableFlts
      IF !Empty(::cFilter)
         cRet := "(" + ::cFilter + ")"
      ENDIF
      IF !Empty(::cScope)
         IF !Empty(cRet)
            cRet += " AND "
         ENDIF
         cRet += "(" + ::cScope + ")"
      ENDIF
      IF !Empty(::cFltUsr)
         IF !Empty(cRet)
            cRet += " AND "
         ENDIF
         cRet += "(" + ::cFltUsr + ")"
      ENDIF
      IF ::aInfo[SR_AINFO_INDEXORD] > 0 .AND. (!Empty(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_SCOPE_SQLEXPR]))
         IF !Empty(cRet)
            cRet += " AND "
         ENDIF
         cRet += "(" + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_SCOPE_SQLEXPR] + ") "
      ENDIF
      IF ::lHistoric .AND. ::lHistEnable
         IF !Empty(cRet)
            cRet += " AND "
         ENDIF
         cRet += ::HistExpression()
      ENDIF
     IF Len(::aRecnoFilter) > 0
         IF !Empty(cRet)
            cRet += " OR  "
         ENDIF
         cRet += ::RecnoExpr()
     ENDIF
   ENDIF
#if 0
   IF SR_UseDeleteds() .AND. set(_SET_DELETED)
      IF !Empty(cRet)
         cRet += " AND "
      ENDIF
      cRet += " (" + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " IS NULL  OR "  + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID)  + " != " + IIf(::nTCCompat > 0, "'*'", "'T'") + " ) "
   ENDIF
#endif

RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:GetSyntheticVirtualExpr(aExpr, cAlias)

   LOCAL cRet := ""
   LOCAL cColName
   LOCAL nPos

   DEFAULT cAlias TO ""

   IF !Empty(cAlias)
      cAlias += "."
   ENDIF

   FOR EACH cColName IN aExpr
      nPos := AScan(::aNames, {|x|x == Upper(cColName)})
      IF nPos <= 0
         ::RunTimeErr("31", SR_Msg(31) + cColName + " Table : " + ::cFileName)
         EXIT
      ELSE
         IF !Empty(cRet)
            cRet += "||"
         ENDIF
         SWITCH ::aFields[nPos, SR_FIELD_TYPE]
         CASE "C"
            cRet += "RPAD(NVL(" + cAlias + ::aFields[nPos, SR_FIELD_NAME] + ",' ')," + AllTrim(Str(::aFields[nPos, SR_FIELD_LEN], 5)) + ")"
            EXIT
         CASE "D"
            cRet += "TO_CHAR(" + cAlias + ::aFields[nPos, SR_FIELD_NAME] + ",'YYYYMMDD')"
            EXIT
         CASE "N"
            cRet += "SUBSTR(TO_CHAR(NVL(" + cAlias + ::aFields[nPos, SR_FIELD_NAME] + ",0),'" + ;
               replicate("9", ::aFields[nPos, SR_FIELD_LEN] - ::aFields[nPos, SR_FIELD_DEC] - 1 - IIf(::aFields[nPos, SR_FIELD_DEC] > 0, 1, 0)) + ;
               "0" + IIf(::aFields[nPos, SR_FIELD_DEC] > 0, "." + replicate("9", ::aFields[nPos, SR_FIELD_DEC]), "") + "'),2," + ;
               Str(::aFields[nPos, SR_FIELD_LEN]) + ")"
            EXIT
         SR_OTHERWISE
            ::RunTimeErr("31", SR_Msg(31) + cColName + "(2) Table : " + ::cFileName)
         ENDSWITCH
      ENDIF
   NEXT

RETURN cRet

//----------------------------------------------------------------------------//
//
// Expression index support (PostgreSQL and MySQL)
//
// Index keys built with translatable Harbour functions (UPPER, SUBSTR, LEFT,
// STRZERO) are mapped to native expression indexes (PostgreSQL) or functional
// indexes (MySQL 8.0.13+) instead of the classic synthetic INDKEY_ column.
// Only keys using non translatable (user defined) functions still create the
// extra column.
//
// A translated component is stored in INDEX_FIELDS as:
//    {cXBaseExpr, nFieldPos, cSqlExpr, cType, nLen, bClientTransform}
// while plain column components keep the original {cName, nFieldPos} format.
//
// All SQL expressions produce TRIMMED text ("rtrim(...)") to stay consistent
// with the trimmed character values produced by ::Quoted().
//
// The SQLEX RDD consumes expression components at C level: the SKIP/SEEK
// engine (sqlex1/2/3.c) uses the component SQL expression in the generated
// statements and binds the value transformed by the client side codeblock.
//
// MariaDB has no functional indexes (it uses indexed generated columns), so
// it keeps the classic synthetic index.
//
//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:CanOpenExpressionIndex()   // opening never depends on SR_GetExpressionIndex()

   LOCAL cVers
   LOCAL aVers
   LOCAL nVers

   IF ISPOSTGRESQL()
      RETURN .T.
   ENDIF

   IF ISMYSQL()

      cVers := Upper(AllTrim(SR_Val2Char(::oSql:cSystemVers)))

      IF "MARIA" $ cVers .OR. "MARIA" $ Upper(SR_Val2Char(::oSql:cTargetDB))
         RETURN .F.     // MariaDB server behind a MySQL driver
      ENDIF

      // The native driver reports mysql_get_server_version() (80013 for
      // 8.0.13) while ODBC reports a dotted string ("8.0.36")

      IF "." $ cVers
         aVers := HB_ATokens(cVers, ".")
         nVers := Val(aVers[1]) * 10000 + ;
                  IIf(Len(aVers) > 1, Val(aVers[2]) * 100, 0) + ;
                  IIf(Len(aVers) > 2, Val(aVers[3]), 0)
      ELSE
         nVers := Val(cVers)
      ENDIF

      RETURN nVers >= 80013      // MySQL functional indexes

   ENDIF

RETURN .F.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:CanUseExpressionIndex()    // creating new expression indexes

RETURN ::CanOpenExpressionIndex() .AND. SR_GetExpressionIndex()

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:ParseIndexComponents(cExpr)

   LOCAL aParts := {}
   LOCAL aComps := {}
   LOCAL nDepth := 0
   LOCAL cPart := ""
   LOCAL c
   LOCAL i
   LOCAL uComp

   IF Empty(cExpr)
      RETURN NIL
   ENDIF

   // Split the key expression on "+" at parenthesis level zero

   FOR i := 1 TO Len(cExpr)
      c := SubStr(cExpr, i, 1)
      DO CASE
      CASE c == "("
         nDepth++
         cPart += c
      CASE c == ")"
         nDepth--
         cPart += c
      CASE c == "+" .AND. nDepth == 0
         AAdd(aParts, cPart)
         cPart := ""
      OTHERWISE
         cPart += c
      ENDCASE
   NEXT i

   IF !Empty(AllTrim(cPart))
      AAdd(aParts, cPart)
   ENDIF

   IF nDepth != 0 .OR. Len(aParts) == 0
      RETURN NIL
   ENDIF

   FOR i := 1 TO Len(aParts)

      IF "->" $ aParts[i]   // relations are not supported in expression indexes
         RETURN NIL
      ENDIF

      uComp := ::BuildIndexComponent(aParts[i])

      IF uComp == NIL
         RETURN NIL
      ENDIF

      IF HB_IsChar(uComp) .AND. AScan(::aNames, {|x|x == uComp}) == 0
         RETURN NIL     // unknown identifier, let the synthetic index handle it
      ENDIF

      AAdd(aComps, uComp)

   NEXT i

   // At least one component must be a real expression, otherwise the
   // regular column index path already handles the key

   IF AScan(aComps, {|x|HB_IsArray(x)}) == 0
      RETURN NIL
   ENDIF

RETURN aComps

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:BuildIndexComponent(cItem)

   LOCAL cFunc
   LOCAL cArgs
   LOCAL aArgs
   LOCAL cCol
   LOCAL nPos
   LOCAL nFldLen
   LOCAL nStart
   LOCAL nCount
   LOCAL nZLen
   LOCAL nZDec
   LOCAL nParen
   LOCAL cSql
   LOCAL i

   cItem := Upper(AllTrim(cItem))
   nParen := At("(", cItem)

   IF nParen == 0
      RETURN cItem      // plain column name
   ENDIF

   IF Right(cItem, 1) != ")"
      RETURN NIL
   ENDIF

   cFunc := AllTrim(Left(cItem, nParen - 1))
   cArgs := SubStr(cItem, nParen + 1, Len(cItem) - nParen - 1)

   IF "(" $ cArgs        // nested functions not supported
      RETURN NIL
   ENDIF

   aArgs := HB_ATokens(cArgs, ",")
   FOR i := 1 TO Len(aArgs)
      aArgs[i] := AllTrim(aArgs[i])
   NEXT i

   // Functions that sort exactly like their column argument map to the
   // plain column, keeping the regular multi column index behavior

   DO CASE
   CASE cFunc == "STR" .OR. cFunc == "DTOS" .OR. cFunc == "TTOS"
      IF Len(aArgs) >= 1 .AND. !Empty(aArgs[1])
         RETURN aArgs[1]
      ENDIF
      RETURN NIL
   CASE cFunc == "RECNO"
      RETURN ::cRecnoName
   CASE cFunc == "DELETED"
      IF ::hnDeleted > 0
         RETURN ::cDeletedName
      ENDIF
      RETURN NIL
   ENDCASE

   IF Len(aArgs) < 1 .OR. Empty(aArgs[1])
      RETURN NIL
   ENDIF

   cCol := aArgs[1]
   nPos := AScan(::aNames, {|x|x == cCol})

   IF nPos == 0
      RETURN NIL
   ENDIF

   nFldLen := ::aFields[nPos, SR_FIELD_LEN]

   DO CASE
   CASE cFunc == "UPPER"

      IF ::aFields[nPos, SR_FIELD_TYPE] != "C" .OR. Len(aArgs) != 1
         RETURN NIL
      ENDIF

      cSql := "rtrim(upper(coalesce(A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ",'')))"

      RETURN {cItem, nPos, cSql, "C", nFldLen, IdxBlkUpper()}

   CASE cFunc == "SUBSTR" .OR. cFunc == "LEFT"

      IF ::aFields[nPos, SR_FIELD_TYPE] != "C"
         RETURN NIL
      ENDIF

      IF cFunc == "LEFT"
         IF Len(aArgs) != 2
            RETURN NIL
         ENDIF
         nStart := 1
         nCount := Val(aArgs[2])
      ELSE
         IF Len(aArgs) < 2 .OR. Len(aArgs) > 3
            RETURN NIL
         ENDIF
         nStart := Val(aArgs[2])
         nCount := IIf(Len(aArgs) == 3, Val(aArgs[3]), nFldLen - Val(aArgs[2]) + 1)
      ENDIF

      IF nStart < 1 .OR. nCount < 1
         RETURN NIL
      ENDIF

      // MySQL rpad() requires the pad string

      cSql := "rtrim(substr(rpad(coalesce(A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ",'')," + ;
              LTrim(Str(nFldLen)) + IIf(ISMYSQL(), ",' '", "") + ")," + ;
              LTrim(Str(nStart)) + "," + LTrim(Str(nCount)) + "))"

      RETURN {cItem, nPos, cSql, "C", nCount, IdxBlkSubStr(nStart, nCount, nFldLen)}

   CASE cFunc == "STRZERO"

      IF ::aFields[nPos, SR_FIELD_TYPE] != "N" .OR. Len(aArgs) < 2 .OR. Len(aArgs) > 3
         RETURN NIL
      ENDIF

      nZLen := Val(aArgs[2])
      nZDec := IIf(Len(aArgs) == 3, Val(aArgs[3]), 0)

      IF nZLen < 1 .OR. nZDec < 0 .OR. nZDec > 30 .OR. (nZDec > 0 .AND. nZLen < nZDec + 2)
         RETURN NIL
      ENDIF

      // Fixing the scale (round()::text on PostgreSQL, cast() to decimal on
      // MySQL, where round() keeps the column scale) makes lpad() zero fill
      // exactly like StrZero() (negative values are not supported)

      IF ISMYSQL()
         cSql := "lpad(cast(coalesce(A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ",0) as decimal(65," + ;
                 LTrim(Str(nZDec)) + "))," + LTrim(Str(nZLen)) + ",'0')"
      ELSE
         cSql := "lpad(round(coalesce(A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ",0)," + ;
                 LTrim(Str(nZDec)) + ")::text," + LTrim(Str(nZLen)) + ",'0')"
      ENDIF

      RETURN {cItem, nPos, cSql, "C", nZLen, IdxBlkStrZero(nZLen, nZDec)}

   ENDCASE

RETURN NIL

//----------------------------------------------------------------------------//

STATIC FUNCTION IdxBlkUpper()

RETURN {|u|RTrim(Upper(IIf(u == NIL, "", u)))}

//----------------------------------------------------------------------------//

STATIC FUNCTION IdxBlkSubStr(nStart, nCount, nFldLen)

RETURN {|u|RTrim(SubStr(PadR(IIf(u == NIL, "", u), nFldLen), nStart, nCount))}

//----------------------------------------------------------------------------//

STATIC FUNCTION IdxBlkStrZero(nZLen, nZDec)

RETURN {|u|StrZero(Round(IIf(u == NIL, 0, u), nZDec), nZLen, nZDec)}

//----------------------------------------------------------------------------//

STATIC FUNCTION IdxBlkPad(bXForm, nLen)   // pads the transformed value back to the component width (seek found check)

RETURN {|u|PadR(Eval(bXForm, u), nLen)}

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IndexFieldSQL(aFld)

   IF Len(aFld) >= SR_IDXFLD_SQL .AND. aFld[SR_IDXFLD_SQL] != NIL
      RETURN aFld[SR_IDXFLD_SQL]
   ENDIF

RETURN "A." + SR_DBQUALIFY(::aNames[aFld[SR_IDXFLD_POS]], ::oSql:nSystemID)

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IndexFieldVal(aFld)

   IF Len(aFld) >= SR_IDXFLD_XFORM .AND. aFld[SR_IDXFLD_XFORM] != NIL
      RETURN Eval(aFld[SR_IDXFLD_XFORM], ::aLocalBuffer[aFld[SR_IDXFLD_POS]])
   ENDIF

RETURN ::aLocalBuffer[aFld[SR_IDXFLD_POS]]

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IndexFieldType(aFld)

   IF Len(aFld) >= SR_IDXFLD_TYPE .AND. aFld[SR_IDXFLD_TYPE] != NIL
      RETURN aFld[SR_IDXFLD_TYPE]
   ENDIF

RETURN ::aFields[aFld[SR_IDXFLD_POS], SR_FIELD_TYPE]

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IndexFieldLen(aFld)

   IF Len(aFld) >= SR_IDXFLD_LEN .AND. aFld[SR_IDXFLD_LEN] != NIL
      RETURN aFld[SR_IDXFLD_LEN]
   ENDIF

RETURN ::aFields[aFld[SR_IDXFLD_POS], SR_FIELD_LEN]

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IndexFieldDec(aFld)

   IF Len(aFld) >= SR_IDXFLD_SQL .AND. aFld[SR_IDXFLD_SQL] != NIL
      RETURN 0
   ENDIF

RETURN ::aFields[aFld[SR_IDXFLD_POS], SR_FIELD_DEC]

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IndexFieldNul(aFld)

   IF Len(aFld) >= SR_IDXFLD_SQL .AND. aFld[SR_IDXFLD_SQL] != NIL
      RETURN .F.
   ENDIF

RETURN ::aFields[aFld[SR_IDXFLD_POS], SR_FIELD_NULLABLE]

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:HasExpressionOrder()

   LOCAL aFld

   IF ::aInfo[SR_AINFO_INDEXORD] > 0 .AND. ::aInfo[SR_AINFO_INDEXORD] <= Len(::aIndex)
      FOR EACH aFld IN ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]
         IF Len(aFld) >= SR_IDXFLD_SQL .AND. aFld[SR_IDXFLD_SQL] != NIL
            RETURN .T.
         ENDIF
      NEXT
   ENDIF

RETURN .F.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:LoadRegisteredTags()

   LOCAL aInd
   LOCAL cLast := "##"
   LOCAL lCDXCompat := .F.
   LOCAL aRet
   LOCAL aThisIndex
   LOCAL aCols
   LOCAL i
   LOCAL cind
   LOCAL nPos
   LOCAL cItem

   ASize(::aIndexMgmnt, 0)
   ::oSql:Exec("SELECT TABLE_,SIGNATURE_,IDXNAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(::cFileName) + "' ORDER BY IDXNAME_, TAGNUM_", .F., .T., @::aIndexMgmnt)

   FOR EACH aInd IN ::aIndexMgmnt
      ASize(aInd, SR_INDEXMAN_SIZE)
      IF SubStr(aInd[SR_INDEXMAN_IDXKEY], 4, 1) == "@"
         IF ISORACLE()
            aInd[SR_INDEXMAN_VIRTUAL_SYNTH] := SubStr(aInd[SR_INDEXMAN_IDXKEY], 1, 3) + SubStr(::cFileName, 1, 25)
         ENDIF
         aInd[SR_INDEXMAN_IDXKEY] := SubStr(aInd[SR_INDEXMAN_IDXKEY], 5)
      ENDIF
      IF !Empty(aInd[SR_INDEXMAN_COLUMNS])
         aInd[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| SR_Val2Char(" + AllTrim(aInd[SR_INDEXMAN_IDXKEY]) + ") + Str(RecNo(),15) }")
         aInd[SR_INDEXMAN_SYNTH_COLPOS] := AScan(::aNames, "INDKEY_" + aInd[SR_INDEXMAN_COLUMNS])     // Make life easier in odbcrdd2.c
      ELSE
         aInd[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| " + AllTrim(aInd[SR_INDEXMAN_IDXKEY]) + " }")
      ENDIF
      aInd[SR_INDEXMAN_IDXNAME] := AllTrim(aInd[SR_INDEXMAN_IDXNAME])
      aInd[SR_INDEXMAN_TAG] := AllTrim(aInd[SR_INDEXMAN_TAG])
      IF SubStr(aInd[SR_INDEXMAN_FOR_EXPRESS], 1, 1) == "#"
         aInd[SR_INDEXMAN_FOR_CODEBLOCK] := &("{|| if(" + AllTrim(SubStr(aInd[SR_INDEXMAN_FOR_EXPRESS], 5)) + ",'T','F') }")     // FOR clause codeblock
         aInd[SR_INDEXMAN_FOR_COLPOS] := AScan(::aNames, "INDFOR_" + SubStr(aInd[SR_INDEXMAN_FOR_EXPRESS], 2, 3))   // Make life easier in odbcrdd2.c
      ENDIF
      // If there is no more than one occourrence of same index bag name,
      // for sure we are dealing with CDX compatible application
      IF cLast == aInd[SR_INDEXMAN_IDXNAME]
         lCDXCompat := .T.
      ENDIF
      cLast := aInd[SR_INDEXMAN_IDXNAME]
   NEXT

   IF s_lUseDBCatalogs
      aRet := {}
      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_IBMDB2
         ::oSql:Exec("SELECT NAME, COLNAMES FROM SYSIBM.SYSINDEXES WHERE CREATOR != 'SYSIBM' AND TBNAME = '" + ::cFileName + "' ORDER BY 1", .F., .T., @aRet)
         FOR EACH aInd IN aRet
            aInd[1] := Upper(RTrim(aInd[1]))
            IF Right(aInd[1], 4) == "_UNQ"
               LOOP
            ENDIF
            aCols := hb_atokens(AllTrim(aInd[2]), "+")
            ADel(aCols, 1)
            ASize(aCols, Len(aCols) - 1)    // Remove first "+"
            aThisIndex := Array(SR_INDEXMAN_SIZE)
            aThisIndex[SR_INDEXMAN_TABLE] := ::cFileName
            aThisIndex[SR_INDEXMAN_SIGNATURE] := "DBCATALOG"
            aThisIndex[SR_INDEXMAN_IDXNAME] := aInd[1]
            aThisIndex[SR_INDEXMAN_IDXKEY] := ""
            FOR i := 1 TO Len(aCols)
               IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_" .AND. Len(aCols) == 1
                  EXIT
               ENDIF
               aThisIndex[SR_INDEXMAN_IDXKEY] += IIf(i > 1, ',"', Chr(34)) + AllTrim(aCols[i]) + Chr(34)
               IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_"
                  EXIT
               ENDIF
            NEXT i
            IF Empty(aThisIndex[SR_INDEXMAN_IDXKEY])
               EXIT
            ENDIF
            aThisIndex[SR_INDEXMAN_FOR_EXPRESS] := ""
            aThisIndex[SR_INDEXMAN_COLUMNS] := ""
            aThisIndex[SR_INDEXMAN_TAG] := aInd[1]
            aThisIndex[SR_INDEXMAN_TAGNUM] := StrZero(SR_ENUMINDEX(aInd), 6)
            aThisIndex[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| " + aThisIndex[SR_INDEXMAN_IDXKEY] + " }")
            aThisIndex[SR_INDEXMAN_SYNTH_COLPOS] := 0
            aThisIndex[SR_INDEXMAN_FOR_COLPOS] := 0

            AAdd(::aIndexMgmnt, aThisIndex)
         NEXT
         EXIT
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
         aRet := {}
         ::oSql:Exec("show index from " + ::cFileName, .F., .T., @aRet)

         aCols := {}
         FOR EACH aInd IN aRet
            IF (npos := AScan(aCols, {|x|x[1] == aInd[3]})) == 0
               AAdd(aCols, {aInd[3], ""})
            ENDIF
            HB_SYMBOL_UNUSED(npos)
         NEXT

         FOR EACH aInd IN aCols

           clast := aInd[1]
           cind := ""

           FOR EACH citem IN aret
              IF citem[3] == clast
                 cind += AllTrim(citem[5]) + ","
              ENDIF
           NEXT

           cind := SubStr(cind, 1, Len(cind) - 1) // remove ","
           aInd[2] := Upper(cind)

         NEXT

         FOR EACH aInd IN aCols

            IF Asc(Right(AllTrim(aInd[2]), 1)) == 0
               aInd[2] := SubStr(aInd[2], 1, Len(AllTrim(aInd[2])) - 1)
            ENDIF

            aCols := hb_atokens(AllTrim(aInd[2]), ",")

            aThisIndex := Array(SR_INDEXMAN_SIZE)
            aThisIndex[SR_INDEXMAN_TABLE] := ::cFileName
            aThisIndex[SR_INDEXMAN_SIGNATURE] := "DBCATALOG"
            aThisIndex[SR_INDEXMAN_IDXNAME] := RTrim(aInd[1])
            aThisIndex[SR_INDEXMAN_IDXKEY] := ""
            FOR i := 1 TO Len(aCols)
               IF ( AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_") .AND. Len(aCols) == 1
                  EXIT
               ENDIF
               aThisIndex[SR_INDEXMAN_IDXKEY] += IIf(i > 1, "," + Chr(34), Chr(34)) + AllTrim(aCols[i]) + Chr(34)
               IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_"
                  EXIT
               ENDIF
            NEXT i
            IF Empty(aThisIndex[SR_INDEXMAN_IDXKEY]) .AND. Len(::aIndexMgmnt) > 0
               EXIT
            ENDIF
            IF !Empty(aThisIndex[SR_INDEXMAN_IDXKEY])
               aThisIndex[SR_INDEXMAN_FOR_EXPRESS] := ""
               aThisIndex[SR_INDEXMAN_COLUMNS] := ""
               aThisIndex[SR_INDEXMAN_TAG] := RTrim(aInd[1])
               aThisIndex[SR_INDEXMAN_TAGNUM] := StrZero(SR_ENUMINDEX(aInd), 6)
               aThisIndex[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| " + aThisIndex[SR_INDEXMAN_IDXKEY] + " }")
               aThisIndex[SR_INDEXMAN_SYNTH_COLPOS] := 0
               aThisIndex[SR_INDEXMAN_FOR_COLPOS] := 0
               AAdd(::aIndexMgmnt, aThisIndex)
            ENDIF
         NEXT

         EXIT

      CASE SQLRDD_RDBMS_SYBASE
         EXIT

      CASE SQLRDD_RDBMS_POSTGR
         ::oSql:oSqlTransact:Exec("SELECT DISTINCT cls.oid, cls.relname as idxname FROM pg_index idx JOIN pg_class cls ON cls.oid=indexrelid JOIN pg_class tab ON tab.oid=indrelid WHERE tab.relname = '" + Lower(::cFileName) + "' order by idxname", .F., .T., @aRet)
         ::oSql:oSqlTransact:Commit()
         FOR EACH aInd IN aRet
            aThisIndex := Array(SR_INDEXMAN_SIZE)
            aThisIndex[SR_INDEXMAN_TABLE] := ::cFileName
            aThisIndex[SR_INDEXMAN_SIGNATURE] := "DBCATALOG"
            aThisIndex[SR_INDEXMAN_IDXNAME] := Upper(RTrim(aInd[2]))

            IF Right(aThisIndex[SR_INDEXMAN_IDXNAME], 4) == "_UNQ"
               LOOP
            ENDIF

            aThisIndex[SR_INDEXMAN_IDXKEY] := ""
            aCols := {}
            FOR i := 1 TO 20
               ::oSql:oSqlTransact:Exec("SELECT pg_get_indexdef(" + Str(aInd[1]) + "," + Str(i, 2) + ",true)", .F., .T., @aCols)
               ::oSql:oSqlTransact:Commit()
               IF Len(aCols) > 0 .AND. !Empty(aCols[1, 1])
                  aCols[1, 1] := Upper(AllTrim(aCols[1, 1]))
                  IF aCols[1, 1] == ::cRecnoName .OR. aCols[1, 1] == "R_E_C_N_O_" .AND. i == 1
                     EXIT
                  ENDIF
                  aThisIndex[SR_INDEXMAN_IDXKEY] += IIf(i > 1, ',"', Chr(34)) + aCols[1, 1] + Chr(34)
                  IF aCols[1, 1] == ::cRecnoName .OR. aCols[1, 1] == "R_E_C_N_O_"
                     EXIT
                  ENDIF
               ELSE
                  EXIT
               ENDIF
            NEXT i
            IF !Empty(aThisIndex[SR_INDEXMAN_IDXKEY])
               aThisIndex[SR_INDEXMAN_FOR_EXPRESS] := ""
               aThisIndex[SR_INDEXMAN_COLUMNS] := ""
               aThisIndex[SR_INDEXMAN_TAG] := Upper(RTrim(aInd[2]))
               aThisIndex[SR_INDEXMAN_TAGNUM] := StrZero(SR_ENUMINDEX(aInd), 6)
               aThisIndex[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| " + aThisIndex[SR_INDEXMAN_IDXKEY] + " }")
               aThisIndex[SR_INDEXMAN_SYNTH_COLPOS] := 0
               aThisIndex[SR_INDEXMAN_FOR_COLPOS] := 0
               AAdd(::aIndexMgmnt, aThisIndex)
            ENDIF
         NEXT
         EXIT

      CASE SQLRDD_RDBMS_ORACLE
         ::oSql:Exec("select index_name, column_name, column_position from user_ind_columns where table_name = '" + ::cFileName + "' and index_name not like 'X_WA_Sys%' order by 1, 3", .F., .T., @aRet)
         IF Len(aRet) > 0
            cLast := aRet[1, 1]
            aCols := {}
            FOR EACH aInd IN aRet
               IF aInd[1] == cLast
                  AAdd(aCols, aInd[2])
                  LOOP
               ENDIF
               aThisIndex := Array(SR_INDEXMAN_SIZE)
               aThisIndex[SR_INDEXMAN_TABLE] := ::cFileName
               aThisIndex[SR_INDEXMAN_SIGNATURE] := "DBCATALOG"
               aThisIndex[SR_INDEXMAN_IDXNAME] := RTrim(cLast)
               aThisIndex[SR_INDEXMAN_IDXKEY] := ""
               FOR i := 1 TO Len(aCols)
                  IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_" .AND. Len(aCols) == 1
                     EXIT
                  ENDIF
                  aThisIndex[SR_INDEXMAN_IDXKEY] += IIf(i > 1, ',"', Chr(34)) + AllTrim(aCols[i]) + Chr(34)
                  IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_"
                     EXIT
                  ENDIF
               NEXT i
               IF !Empty(aThisIndex[SR_INDEXMAN_IDXKEY]) .AND. Right(RTrim(cLast), 4) != "_UNQ"
                  aThisIndex[SR_INDEXMAN_FOR_EXPRESS] := ""
                  aThisIndex[SR_INDEXMAN_COLUMNS] := ""
                  aThisIndex[SR_INDEXMAN_TAG] := RTrim(cLast)
                  aThisIndex[SR_INDEXMAN_TAGNUM] := StrZero(SR_ENUMINDEX(aInd), 6)
                  aThisIndex[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| " + aThisIndex[SR_INDEXMAN_IDXKEY] + " }")
                  aThisIndex[SR_INDEXMAN_SYNTH_COLPOS] := 0
                  aThisIndex[SR_INDEXMAN_FOR_COLPOS] := 0
                  AAdd(::aIndexMgmnt, aThisIndex)
               ENDIF
               cLast := aInd[1]
               aCols := {aInd[2]}
            NEXT

            aThisIndex := Array(SR_INDEXMAN_SIZE)
            aThisIndex[SR_INDEXMAN_TABLE] := ::cFileName
            aThisIndex[SR_INDEXMAN_SIGNATURE] := "DBCATALOG"
            aThisIndex[SR_INDEXMAN_IDXNAME] := RTrim(cLast)
            aThisIndex[SR_INDEXMAN_IDXKEY] := ""
            FOR i := 1 TO Len(aCols)
               IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_" .AND. Len(aCols) == 1
                  EXIT
               ENDIF
               aThisIndex[SR_INDEXMAN_IDXKEY] += IIf(i > 1, ',"', Chr(34)) + AllTrim(aCols[i]) + Chr(34)
               IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_"
                  EXIT
               ENDIF
            NEXT i
            IF !Empty(aThisIndex[SR_INDEXMAN_IDXKEY]) .AND. Right(RTrim(cLast), 4) != "_UNQ"
               aThisIndex[SR_INDEXMAN_FOR_EXPRESS] := ""
               aThisIndex[SR_INDEXMAN_COLUMNS] := ""
               aThisIndex[SR_INDEXMAN_TAG] := RTrim(cLast)
#ifdef __XHARBOUR__
               aThisIndex[SR_INDEXMAN_TAGNUM] := StrZero(hb_EnumIndex(), 6) // TODO: HB_ENUMINDEX outside of a FOR EACH
#else
               aThisIndex[SR_INDEXMAN_TAGNUM] := StrZero(_sr_EnumIndex(), 6) // TODO: _sr_ENUMINDEX outside of a FOR EACH
#endif
               aThisIndex[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| " + aThisIndex[SR_INDEXMAN_IDXKEY] + " }")
               aThisIndex[SR_INDEXMAN_SYNTH_COLPOS] := 0
               aThisIndex[SR_INDEXMAN_FOR_COLPOS] := 0
               AAdd(::aIndexMgmnt, aThisIndex)
            ENDIF

         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_AZURE
         ::oSql:Exec("sp_helpindex " + ::cFileName, .F., .T., @aRet)

         FOR EACH aInd IN aRet
            IF Asc(Right(AllTrim(aInd[3]), 1)) == 0
               aInd[3] := SubStr(aInd[3], 1, Len(AllTrim(aInd[3])) - 1)
            ENDIF
            aCols := hb_atokens(AllTrim(aInd[3]), ",")

            aThisIndex := Array(SR_INDEXMAN_SIZE)
            aThisIndex[SR_INDEXMAN_TABLE] := ::cFileName
            aThisIndex[SR_INDEXMAN_SIGNATURE] := "DBCATALOG"
            aThisIndex[SR_INDEXMAN_IDXNAME] := RTrim(aInd[1])
            aThisIndex[SR_INDEXMAN_IDXKEY] := ""
            FOR i := 1 TO Len(aCols)
               IF (AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_") .AND. Len(aCols) == 1
                  EXIT
               ENDIF
               aThisIndex[SR_INDEXMAN_IDXKEY] += IIf(i > 1, ',"', Chr(34)) + AllTrim(aCols[i]) + Chr(34)
               IF AllTrim(aCols[i]) == ::cRecnoName .OR. AllTrim(aCols[i]) == "R_E_C_N_O_"
                  EXIT
               ENDIF
            NEXT i
            IF Empty(aThisIndex[SR_INDEXMAN_IDXKEY]) .AND. Len(::aIndexMgmnt) > 0
               EXIT
            ENDIF
            IF       !Empty(aThisIndex[SR_INDEXMAN_IDXKEY]) ;
               .AND. Right(aThisIndex[SR_INDEXMAN_IDXNAME], 4) != "_UNQ" ;
               .AND. Right(aThisIndex[SR_INDEXMAN_IDXNAME], 3) != "_PK"
               aThisIndex[SR_INDEXMAN_FOR_EXPRESS] := ""
               aThisIndex[SR_INDEXMAN_COLUMNS] := ""
               aThisIndex[SR_INDEXMAN_TAG] := RTrim(aInd[1])
               aThisIndex[SR_INDEXMAN_TAGNUM] := StrZero(SR_ENUMINDEX(aInd), 6)
               aThisIndex[SR_INDEXMAN_KEY_CODEBLOCK] := &("{|| " + aThisIndex[SR_INDEXMAN_IDXKEY] + " }")
               aThisIndex[SR_INDEXMAN_SYNTH_COLPOS] := 0
               aThisIndex[SR_INDEXMAN_FOR_COLPOS] := 0
               AAdd(::aIndexMgmnt, aThisIndex)
            ENDIF
         NEXT
      ENDSWITCH
   ENDIF

   IF !lCDXCompat
      // If not CDX, orders should be added by creation order
      ASort(::aIndexMgmnt, , , {|x, y|x[SR_INDEXMAN_TAGNUM] < y[SR_INDEXMAN_TAGNUM]})
   ENDIF

//   ::aConstrMgmnt := {}
//   ::oSql:Exec("SELECT SOURCETABLE_ , SOURCECOLUMNS_, CONSTRTYPE_, TARGETTABLE_, TARGETCOLUMNS_, CONSTRNAME_ FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS WHERE SOURCETABLE_ = '" + Upper(::cFileName) + "' ORDER BY CONSTRNAME_", .F., .T., @::aConstrMgmnt)

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:SetColPK(cColName)

   LOCAL nPos := AScan(::aNames, {|x|x == Upper(cColName)})

   IF nPos > 0
      ::nPosCOlPK := nPos
      ::cColPK := Upper(cColName)
   ENDIF

RETURN ::cColPK

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:DisableHistoric()

   LOCAL i

   ::lHistEnable := .F.
   FOR i := 1 TO Len(::aIndex)
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_UP] := NIL
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_DOWN] := NIL
   NEXT i

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:EnableHistoric()

   LOCAL i

   ::lHistEnable := .T.
   FOR i := 1 TO Len(::aIndex)
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_UP] := NIL
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_DOWN] := NIL
   NEXT i

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:GetNextRecordNumber()

   LOCAL nRet
   LOCAL aRet

   IF ::lQuickAppend
      RETURN ::aInfo[SR_AINFO_RCOUNT] + 1
   ENDIF

   IF !::oSql:lUseSequences .OR. !::lUseSequences
      nRet := Eval(SR_GetNextRecordBlock(), Self)
   ELSE
      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_INGRES
         aRet := {}
         ::oSql:Exec("SELECT SQ_" + ::cFileName + ".nextval", .F., .T., @aRet)
         IF Len(aRet) > 0
            nRet := aRet[1, 1]
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_FIREBR
         aRet := {}
         ::oSql:Exec("SELECT gen_id(" + ::cFileName + ",1) FROM RDB$DATABASE", .F., .T., @aRet)
         IF Len(aRet) > 0
            nRet := aRet[1, 1]
         ENDIF
         EXIT
      SR_OTHERWISE
         nRet := ::aInfo[SR_AINFO_RCOUNT] + 1
      ENDSWITCH
   ENDIF

RETURN nRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:ParseIndexColInfo(cSQL)

   LOCAL i
   LOCAL nLen
   LOCAL aQuot
   LOCAL cOut := ""
   LOCAL nIndexCol
   LOCAL cFieldName
   LOCAL cType
   LOCAL lNull

   IF ::aInfo[SR_AINFO_INDEXORD] == 0
      RETURN cSQL
   ENDIF

   nLen := Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS])
   aQuot := Array(nLen)

   FOR i := 1 TO nLen
      aQuot[i] := ::QuotedNull(::aLocalBuffer[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]], .T., , , , ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_NULLABLE])
   NEXT i

   nLen := Len(cSql)
   cOut := Left(cSql, 11)

   FOR i := 12 TO nLen
      IF SubStr(cSql, i, 1) == "@"

         nIndexCol := Val(SubStr(cSql, i + 2, 1)) + 1  // This is ZERO-base

         IF aQuot[nIndexCol] == "NULL"  // This 90% of the problem from 1% of the cases

            cType := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, nIndexCol, 2], SR_FIELD_TYPE]

            IF cType == "N"

               cFieldName := "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, nIndexCol, 2]], ::oSql:nSystemID)

               SWITCH SubStr(cSql, i + 1, 1)
               CASE "1"  // >
                  cOut := ShiftLeftAddParentesis(cOut) + " IS NOT NULL AND " + cFieldName + " > 0 )"
                  EXIT
               CASE "2"  // =
                  cOut := ShiftLeftAddParentesis(cOut) + " IS NULL OR " + cFieldName + " = 0 )"
                  EXIT
               CASE "3"  // >=
                  cOut := ShiftLeftAddParentesis(cOut) + " IS NULL OR " + cFieldName + " >= 0 )"
                  EXIT
               CASE "4"  // <
                  cOut := ShiftLeftAddParentesis(cOut) + " IS NOT NULL AND " + cFieldName + " < 0 )"
                  EXIT
               CASE "6"  // <=
                  cOut := ShiftLeftAddParentesis(cOut) + " IS NULL OR " + cFieldName + " < 0 )"
               ENDSWITCH
            ELSE
               SWITCH SubStr(cSql, i + 1, 1)
               CASE "1"  // >
                  cOut += "IS NOT NULL"
                  EXIT
               CASE "2"  // =
                  cOut += "IS NULL"
                  EXIT
               CASE "3"  // >=
                  cOut := ShiftLeft(cOut) + " 1 = 1 "
                  EXIT
               CASE "4"  // <
                  cOut := ShiftLeft(cOut) + " 1 = 0 "
                  EXIT
               CASE "6"  // <=
                  cOut += " IS NULL"
               ENDSWITCH
            ENDIF
         ELSE
            lNull := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, nIndexCol, 2], SR_FIELD_NULLABLE]

            SWITCH SubStr(cSql, i + 1, 1)
            CASE "1"  // >
               cOut += " > " + aQuot[nIndexCol]
               EXIT
            CASE "2"  // =
               cOut += " = " + aQuot[nIndexCol]
               EXIT
            CASE "3"  // >=
               cOut += " >= " + aQuot[nIndexCol]
               EXIT
            CASE "4"  // <
               IF lNull
                  cFieldName := "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, nIndexCol, 2]], ::oSql:nSystemID)
                  cOut := ShiftLeftAddParentesis(cOut) + " < " + aQuot[nIndexCol] + " OR " + cFieldName + " IS NULL )"
               ELSE
                  cOut += " < " + aQuot[nIndexCol]
               ENDIF
               EXIT
            CASE "6"  // <=
               IF lNull
                  cFieldName := "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, nIndexCol, 2]], ::oSql:nSystemID)
                  cOut := ShiftLeftAddParentesis(cOut) + " <= " + aQuot[nIndexCol] + " OR " + cFieldName + " IS NULL )"
               ELSE
                  cOut += " <= " + aQuot[nIndexCol]
               ENDIF
            ENDSWITCH
         ENDIF
         i += 2
      ELSE
         cOut += SubStr(cSql, i, 1)
      ENDIF
   NEXT i

RETURN cOut

//----------------------------------------------------------------------------//

STATIC FUNCTION ShiftLeft(cSql)

   LOCAL i := Len(cSql)

   DO WHILE SubStr(cSql, i, 1) == " "
      i--
   ENDDO
   DO WHILE SubStr(cSql, i, 1) != " "
      i--
   ENDDO
   cSql := SubStr(cSql, 1, i)

RETURN cSql

//----------------------------------------------------------------------------//

STATIC FUNCTION ShiftLeftAddParentesis(cSql)

   LOCAL i := Len(cSql)

   DO WHILE SubStr(cSql, i, 1) == " "
      i--
   ENDDO
   DO WHILE SubStr(cSql, i, 1) != " "
      i--
   ENDDO
   cSql := SubStr(cSql, 1, i) + "(" + SubStr(cSql, i)
   i := Len(cSql)
   DO WHILE SubStr(cSql, i, 1) == " "
      i--
   ENDDO

RETURN cSql

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlKeyCount(lFilters)

   LOCAL nRet := 0
   LOCAL aRet := {}
   LOCAL lDeleteds
   LOCAL cSql
   LOCAL cRet := ""

   HB_SYMBOL_UNUSED(cRet)

   DEFAULT lFilters TO .T.

   IF ::lISAM

      lDeleteds := (!Empty(::hnDeleted)) .AND. set(_SET_DELETED)

      cSql := "SELECT COUNT(" + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + ") FROM " + ::cQualifiedTableName + " A " +;
               IIf(lDeleteds, " WHERE " + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " != " + IIf(::nTCCompat > 0, "'*'", "'T'"), "")

      IF lFilters
         cRet := ::SolveRestrictors()
         IF Len(cRet) > 0
            IF !lDeleteds
               cRet := " WHERE" + cRet
            ELSE
               cRet := " AND " + cRet
            ENDIF
            cSql += cRet
         ENDIF
      ENDIF

      cSql += IIf(::oSql:lComments, " /* dbCount() */", "")
      ::oSql:Exec(cSql, , .T., @aRet)

      IF Len(aRet) > 0
         nRet := aRet[1, 1]
      ENDIF
   ELSE
      nRet := Len(::aCache)
   ENDIF

RETURN nRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IncludeAllMethods()

   // Any methods referenced by startSQLRDDSymbols() should be added here

   ::sqlGetValue()
   ::READPAGE()
   ::SQLGOBOTTOM()
   ::SQLGOTO()
   ::SQLGOTOP()
   ::SQLSEEK()
   ::SETBOF()
   ::SQLDELETEREC()
   ::SQLFLUSH()
   ::SQLRECALL()
   ::SQLCLOSE()
   ::SQLCREATE()
   ::SQLOPENAREA()
   ::SQLOPENALLINDEXES()
   ::SQLPACK()
   ::SQLZAP()
   ::SQLORDERLISTADD()
   ::SQLORDERLISTCLEAR()
   ::SQLORDERLISTFOCUS()
   ::SQLORDERDESTROY()
   ::SQLORDERCREATE()
   ::SQLORDERCONDITION()
   ::SQLORDERLISTNUM()
   ::SQLSETSCOPE()
   ::SQLLOCK()
   ::SQLUNLOCK()
   ::SQLDROP()
   ::SQLEXISTS()
   ::WRITEBUFFER()
   ::SQLKEYCOUNT()
   ::SQLRECSIZE()
   ::DROPCONSTRAINT()
   ::CREATECONSTRAINT()
   ::GETSYNTHETICVIRTUALEXPR()
   ::SQLSETFILTER()
   ::SQLCLEARFILTER()
   ::SQLFILTERTEXT()

   SR_Serialize1()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:LockTable(lCheck4ExcLock, lFLock)

   LOCAL lRet := .T.
   LOCAL aVet := {}
   LOCAL aResultSet := {}
   LOCAL i

   HB_SYMBOL_UNUSED(aVet)
   HB_SYMBOL_UNUSED(aResultSet)

   IF AScan(::aExclusive, {|x|x[2] == ::cFileName}) > 0    // Table already exclusive by this application instance
      RETURN .T.
   ENDIF

   DEFAULT lCheck4ExcLock TO .T.
   DEFAULT lFLock TO .F.

   SWITCH ::oSql:nSystemID

   CASE SQLRDD_RDBMS_IBMDB2
   CASE SQLRDD_RDBMS_MYSQL
   CASE SQLRDD_RDBMS_MARIADB
   CASE SQLRDD_RDBMS_SYBASE
      EXIT

   CASE SQLRDD_RDBMS_MSSQL7
   CASE SQLRDD_RDBMS_ORACLE
   CASE SQLRDD_RDBMS_POSTGR
   CASE SQLRDD_RDBMS_AZURE

      FOR i := 1 TO SR_LOCKTABLE_TRIES

         IF lCheck4ExcLock

            // Step 1: Try to create a LOCK to check If someone have this table EXCLUSIVE
            // Lock format is: SR_EXCLUSIVE_TABLE_LOCK_SIGN + TableName

            lRet := SR_SetLocks(SR_EXCLUSIVE_TABLE_LOCK_SIGN + Upper(::cFileName), ::oSql, 4)

            // Step 2: If LOCK acquired, RELEASE IT and return TRUE, else LOOP

            IF lRet
               // Ok, nobody have it EXCLUSIVE !
               SR_ReleaseLocks(SR_EXCLUSIVE_TABLE_LOCK_SIGN + Upper(::cFileName), ::oSql)
            ENDIF

         ELSE

            // Try to create a LOCK to this table
            // Lock format is: SR_EXCLUSIVE_TABLE_LOCK_SIGN + TableName
            // IF LOCK acquired, return TRUE. Lock MUST be removed at workarea close

            IF lFLock
               lRet := SR_SetLocks(SR_FLOCK_TABLE_LOCK_SIGN + Upper(::cFileName), ::oSql, 4)
            ELSE
               lRet := SR_SetLocks({SR_FLOCK_TABLE_LOCK_SIGN + Upper(::cFileName), ;
                  SR_EXCLUSIVE_TABLE_LOCK_SIGN + Upper(::cFileName), ;
                  SR_SHARED_TABLE_LOCK_SIGN + Upper(::cFileName)}, ::oSql, 4)
            ENDIF

         ENDIF

         IF lRet
            EXIT
         ENDIF

         Inkey(0.5)         // wait .5 seconds before trying again
      NEXT i

   ENDSWITCH

   IF !lCheck4ExcLock .AND. lRet
      ::lTableLocked := .T.
      AAdd(::aExclusive, {::nThisArea, ::cFileName})
   ENDIF

RETURN lRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:UnlockTable(lClosing)

   LOCAL lRet := .T.
   LOCAL aVet := {}
   LOCAL aResultSet := {}
   LOCAL nPos

   HB_SYMBOL_UNUSED(aVet)
   HB_SYMBOL_UNUSED(aResultSet)

   IF AScan(::aExclusive, {|x|x[1] == ::nThisArea}) == 0
      RETURN .T.
   ENDIF

   DEFAULT lClosing TO .F.

   IF !lClosing .AND. !::aInfo[SR_AINFO_SHARED]
      RETURN .F. // USE EXCLUSIVE cannot be released until file is closed
   ENDIF

   SWITCH ::oSql:nSystemID
   CASE SQLRDD_RDBMS_IBMDB2
   CASE SQLRDD_RDBMS_MYSQL
   CASE SQLRDD_RDBMS_MARIADB
   CASE SQLRDD_RDBMS_SYBASE
      EXIT
   CASE SQLRDD_RDBMS_MSSQL7
   CASE SQLRDD_RDBMS_ORACLE
   CASE SQLRDD_RDBMS_POSTGR
   CASE SQLRDD_RDBMS_AZURE
      SR_ReleaseLocks({SR_EXCLUSIVE_TABLE_LOCK_SIGN + Upper(::cFileName), SR_FLOCK_TABLE_LOCK_SIGN + Upper(::cFileName)}, ::oSql)
   ENDSWITCH

   ::lTableLocked := .F.
   nPos := AScan(::aExclusive, {|x|x[1] == ::nThisArea})

   IF nPos > 0
      ADel(::aExclusive, nPos)
      ASize(::aExclusive, Len(::aExclusive) - 1)
   ENDIF

RETURN lRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:LineCount(lMsg)

   LOCAL nRet := 0
   LOCAL aRet := {}

   DEFAULT lMsg TO .T.

   IF ::lISAM

      IF SR_GetnLineCountResult() == 0
         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_POSTGR
            ::oSql:Exec("SELECT " + SR_DBQUALIFY(::cRecnoName, SQLRDD_RDBMS_POSTGR) + " FROM " + ::cQualifiedTableName + " ORDER BY " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " DESC LIMIT 1" + IIf(::oSql:lComments, " /* Counting Records */", ""), lMsg, .T., @aRet)
            EXIT
         CASE SQLRDD_RDBMS_FIREBR
            ::oSql:Exec("SELECT gen_id(" + ::cFileName + ",0) FROM RDB$DATABASE", .F., .T., @aRet)
            EXIT
         CASE SQLRDD_RDBMS_CACHE
            ::oSql:Exec("SELECT TOP 1 " + SR_DBQUALIFY(::cRecnoName, SQLRDD_RDBMS_CACHE) + " FROM " + ::cOwner + ::cFileName + " ORDER BY " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " DESC", lMsg, .T., @aRet)
            EXIT
         SR_OTHERWISE
           ::oSql:Exec("SELECT MAX( " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " ) FROM " + ::cQualifiedTableName + IIf(::oSql:lComments, " /* Counting Records */", ""), lMsg, .T., @aRet)
         ENDSWITCH

         IF Len(aRet) > 0 .AND. !HB_IsNumeric(aRet[1, 1])
            ::oSql:Exec("SELECT COUNT( " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " ) FROM " + ::cQualifiedTableName + IIf(::oSql:lComments, " /* Counting Records */", ""), lMsg, .T., @aRet)
         ENDIF

         IF Len(aRet) > 0
            ::aInfo[SR_AINFO_RCOUNT] := aRet[1, 1]
            nRet := aRet[1, 1]
         ELSEIF ::oSql:nRetCode != SQL_SUCCESS .AND. ::oSql:nRetCode != SQL_NO_DATA_FOUND
            nRet := -1     // Error
         ENDIF
      ELSE
         nRet := SR_GetnLineCountResult()
         ::aInfo[SR_AINFO_RCOUNT] := nRet
      ENDIF
   ELSE
      nRet := Len(::aCache)
   ENDIF

   IF Empty(nRet)
      ::lEmptyTable := .T.
      ::aInfo[SR_AINFO_RECNO] := 1
      ::aInfo[SR_AINFO_RCOUNT] := 0
      ::aInfo[SR_AINFO_BOF] := .T.
      ::aInfo[SR_AINFO_EOF] := .T.
   ENDIF

RETURN nRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOpenAllIndexes()

   LOCAL i
   LOCAL aCols
   LOCAL cOrdName
   LOCAL nPos
   LOCAL nInd
   LOCAL cXBase
   LOCAL cCol
   LOCAL nPosAt
   LOCAL cSqlA
   LOCAL cSqlD
   LOCAL cColumns
   LOCAL lSyntheticVirtual := .F.
   LOCAL cPhysicalVIndexName
   LOCAL uComp

   ASize(::aIndex, Len(::aIndexMgmnt))

   FOR nInd := 1 TO Len(::aIndexMgmnt)

      IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])
         aCols := {"INDKEY_" + ::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS]}
      ELSE
         aCols := &("{" + ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY] + "}")
         // aCols := HB_ATokens(StrTran(::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY], Chr(34), ""), ",")
      ENDIF

      cOrdName := ::aIndexMgmnt[nInd, SR_INDEXMAN_TAG]
      cColumns := ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY]
      cSqlA := " ORDER BY "
      cSqlD := " ORDER BY "
      cXBase := ""

      IF Empty(cOrdName)
         cOrdName := ""
      ENDIF

      IF ::aIndexMgmnt[nInd, SR_INDEXMAN_VIRTUAL_SYNTH] != NIL
         lSyntheticVirtual := .T.
         cPhysicalVIndexName := ::aIndexMgmnt[nInd, SR_INDEXMAN_VIRTUAL_SYNTH]
      ELSE
         cPhysicalVIndexName := NIL
      ENDIF

      ::aIndex[nInd] := {"", "", {}, "", "", "", NIL, NIL, cOrdName, cColumns, , , , , , 0, SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_SIGNATURE], 19, 1) == "D", cPhysicalVIndexName, , , ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXNAME]}
      ::aIndex[nInd, SR_AINDEX_INDEX_FIELDS] := Array(Len(aCols))

      FOR i := 1 TO Len(aCols)

         IF HB_IsChar(aCols[i]) .AND. "(" $ aCols[i]

            // Expression index component (UPPER/SUBSTR/LEFT/STRZERO/...)

            IF !::CanOpenExpressionIndex()
               ::RunTimeErr("18", SR_Msg(18) + aCols[i] + " Table : " + ::cFileName + ;
                  " (index uses a PostgreSQL expression key;" + ;
                  " it can only be opened on a PostgreSQL connection)")
               RETURN 0    // error exit
            ENDIF

            uComp := ::BuildIndexComponent(aCols[i])

            IF HB_IsArray(uComp)
               IF ::osql:lPostgresql8
                  cSqlA += " " + uComp[SR_IDXFLD_SQL] + " NULLS FIRST,"
                  cSqlD += " " + uComp[SR_IDXFLD_SQL] + " DESC NULLS LAST,"
               ELSE
                  cSqlA += " " + uComp[SR_IDXFLD_SQL] + ","
                  cSqlD += " " + uComp[SR_IDXFLD_SQL] + " DESC,"
               ENDIF
               cXBase += uComp[SR_IDXFLD_NAME] + " + "
               ::aIndex[nInd, SR_AINDEX_INDEX_FIELDS, i] := uComp
               LOOP
            ELSEIF HB_IsChar(uComp)
               aCols[i] := uComp       // STR()/DTOS() map to the plain column
            ELSE
               ::RunTimeErr("18", SR_Msg(18) + aCols[i] + " Table : " + ::cFileName)
               RETURN 0    // error exit
            ENDIF

         ENDIF

         nPosAt := At(aCols[i], " ")

         IF nPosAt == 0
            cCol := aCols[i]
         ELSE
            cCol := SubStr(aCols[i], 1, nPosAt)
         ENDIF

         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_ORACLE
         CASE SQLRDD_RDBMS_FIREBR
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " NULLS FIRST,"
            cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC NULLS LAST,"
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
            IF "08.0" $ ::oSql:cSystemVers .AND. (!"08.00" $ ::oSql:cSystemVers)
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " NULLS FIRST,"
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC NULLS LAST,"
            ELSE
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ","
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC,"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_POSTGR
            IF ::osql:lPostgresql8
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " NULLS FIRST,"
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC NULLS LAST,"
            ELSE
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ","
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC,"
            ENDIF
            EXIT
         SR_OTHERWISE
            cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ","
            cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC,"
         ENDSWITCH

         IF (nPos := AScan(::aNames, {|x|x == cCol})) != 0
            IF ::aNames[nPos] != ::cRecnoName
               ::aIndex[nInd, SR_AINDEX_SYNTH_INDEX_COL_POS] := nPos
               SWITCH ::aFields[nPos, SR_FIELD_TYPE]
               CASE "C"
                  IF ::aNames[nPos] == ::cDeletedName
                     cXBase += "Deleted() + "
                  ELSE
                     cXBase += ::aNames[nPos] + " + "
                  ENDIF
                  EXIT
               CASE "D"
                  cXBase += "DTOS(" + ::aNames[nPos] + ") + "
                  EXIT
               CASE "T"
                  cXBase += "TTOS(" + ::aNames[nPos] + ") + " // TODO: TTOS -> HB_TTOS
                  EXIT
               CASE "N"
                  cXBase += "STR(" + ::aNames[nPos] + ", " + AllTrim(Str(::aFields[nPos, SR_FIELD_LEN])) + ", " + AllTrim(Str(::aFields[nPos, SR_FIELD_DEC])) + ") + "
                  EXIT
               CASE "L"
                  cXBase += "Sr_cdbvalue("+ ::aNames[nPos] + ")" + " + "
               ENDSWITCH
            ENDIF
         ELSE
            ::RunTimeErr("18", SR_Msg(18) + cCol + " Table : " + ::cFileName)
            RETURN 0       // error exit
         ENDIF

         ::aIndex[nInd, SR_AINDEX_INDEX_FIELDS, i] := {aCols[i], nPos}

      NEXT i

      cXBase := Left(cXBase, Len(cXBase) - 2)
      cSqlA := Left(cSqlA, Len(cSqlA) - 1) + " "
      cSqlD := Left(cSqlD, Len(cSqlD) - 1) + " "

      ::aIndex[nInd, SR_AINDEX_ORDER_ASCEND] := cSqlA
      ::aIndex[nInd, SR_AINDEX_ORDER_DESEND] := cSqlD
      ::aIndex[nInd, SR_AINDEX_INDEX_KEY] := RTrim(IIf(nInd > 0 .AND. (!Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])), ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY], cXBase))
      IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])
         IF RDDNAME() == "SQLEX"
            // SQLEX does not expose the INDKEY_ column as a field, so the key
            // codeblock must evaluate the original xBase expression client
            // side (same value stored in INDKEY_, without the recno suffix)
            ::aIndex[nInd, SR_AINDEX_INDEX_KEY_CODEBLOCK] := &("{|| SR_Val2Char(" + AllTrim(::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY]) + ") }")
         ELSE
            ::aIndex[nInd, SR_AINDEX_INDEX_KEY_CODEBLOCK] := AScan(::aNames, "INDKEY_" + ::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])
         ENDIF
      ELSE
         ::aIndex[nInd, SR_AINDEX_INDEX_KEY_CODEBLOCK] := &("{|| " + cXBase + " }")
      ENDIF
      IF SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS], 1, 1) != "#"
         ::aIndex[nInd, SR_AINDEX_FOR_CLAUSE] := RTrim(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS])
      ELSE
         ::aIndex[nInd, SR_AINDEX_FOR_CLAUSE] := "INDFOR_" + SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS], 2, 3) + " = 'T'"
      ENDIF
      ::aIndex[nInd, SR_AINDEX_STR_DESCENDS] := ""
      ::aIndex[nInd, SR_AINDEX_SYNTH_INDEX_COL_POS] := IIf(nInd > 0 .AND. (!Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])), ::aIndex[nInd, SR_AINDEX_SYNTH_INDEX_COL_POS], 0)

      IF lSyntheticVirtual
         ::aIndex[nInd, SR_AINDEX_VIRTUAL_INDEX_EXPR] := ::GetSyntheticVirtualExpr(aCols, "A")
      ENDIF

   NEXT nInd

   ::lStable := .F.

   IF Len(::aIndexMgmnt) > 0
      RETURN ::sqlOrderListFocus(1)
   ENDIF

RETURN 0

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:OrderBy(nOrder, lAscend, lRec)

   DEFAULT nOrder TO ::aInfo[SR_AINFO_INDEXORD]
   DEFAULT lRec TO .T.

   lAscend := IIf(::aInfo[SR_AINFO_REVERSE_INDEX], !lAscend, lAscend)

   IF lRec
      IF nOrder == 0 .OR. nOrder > Len(::aIndex)
         RETURN " ORDER BY A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + IIf(lAscend, " ", " DESC ")
      ENDIF
      RETURN ::aIndex[nOrder, IIf(lAscend, SR_AINDEX_ORDER_ASCEND, SR_AINDEX_ORDER_DESEND)]
   ELSE
      IF nOrder == 0 .OR. nOrder > Len(::aIndex)
         RETURN " "
      ENDIF
      RETURN StrTran(::aIndex[nOrder, IIf(lAscend, SR_AINDEX_ORDER_ASCEND, SR_AINDEX_ORDER_DESEND)], ", A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID), "")
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:FirstFetch(nDirection)

   LOCAL uRecord
   LOCAL nFecth
   LOCAL nBlockPos := 0
   LOCAL nPos
   LOCAL nOldBg
   LOCAL nOldEnd
   LOCAL lCacheIsEmpty

   HB_SYMBOL_UNUSED(nBlockPos)

   DEFAULT nDirection TO SR_ORD_INVALID

   ::oSql:nRetCode := ::oSql:Fetch(, .F., ::aFields)

   IF ::lFetchAll
      nDirection := SR_ORD_DIR_FWD
      ::nCurrentFetch := Max(::nCurrentFetch, 50)
   ENDIF

   SWITCH ::oSql:nRetCode

   CASE SQL_SUCCESS
      ::lNoData := .F.
      ::aInfo[SR_AINFO_EOF] := .F.
      ::aInfo[SR_AINFO_BOF] := .F.
      ::lEmptyTable := .F.
      nOldBg := ::aInfo[SR_AINFO_NCACHEBEGIN]
      nOldEnd := ::aInfo[SR_AINFO_NCACHEEND]
      lCacheIsEmpty := (nOldBg == nOldEnd) .AND. nOldEnd == 0

      IF nDirection == SR_ORD_DIR_FWD
         IF (::aInfo[SR_AINFO_NPOSCACHE] + 1) > (SR_CACHE_PAGE_SIZE * 3)
            nBlockPos := 1
         ELSE
            nBlockPos := ::aInfo[SR_AINFO_NPOSCACHE] + 1
         ENDIF
         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NPOSCACHE] + ::nCurrentFetch
         IF nOldBg == nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEEND] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEEND] -= (SR_CACHE_PAGE_SIZE * 3)
            ENDIF
            ::aInfo[SR_AINFO_EOF_AT] := 0
         ELSEIF nOldBg < nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEEND] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEEND] -= (SR_CACHE_PAGE_SIZE * 3)
               IF ::aInfo[SR_AINFO_NCACHEEND] >= (::aInfo[SR_AINFO_NCACHEBEGIN] - 2)
                  ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NCACHEEND] + 2
               ENDIF
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
         ELSE
            IF ::aInfo[SR_AINFO_NCACHEEND] >= (::aInfo[SR_AINFO_NCACHEBEGIN] - 2)
               ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NCACHEEND] + 2
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEEND] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEEND] -= (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEBEGIN] -= (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF

         ENDIF
         IF ::aInfo[SR_AINFO_NCACHEBEGIN] == 0
            ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
         ENDIF
         IF ::aInfo[SR_AINFO_NPOSCACHE] == 0
            ::aInfo[SR_AINFO_NPOSCACHE] := 1
         ENDIF
         IF ::aCache[nBlockPos] == NIL
            ::aCache[nBlockPos] := Array(Len(::aLocalBuffer))
         ENDIF
         ::oSql:GetLine(::aFields, .F., @::aCache[nBlockPos])
         uRecord := ::aCache[nBlockPos, ::hnRecno]
         IF ::aInfo[SR_AINFO_NPOSCACHE] == 0
            ::aInfo[SR_AINFO_NPOSCACHE] := 1
         ENDIF
         nPos := ::aInfo[SR_AINFO_NPOSCACHE] + IIf(lCacheIsEmpty, 0, 1)
         IF nPos > (SR_CACHE_PAGE_SIZE * 3)
            nPos := 1
         ENDIF

         IF ::lFetchAll
            AAdd(::aFetch, uRecord)
         ENDIF

      ELSEIF nDirection == SR_ORD_DIR_BWD

         IF (::aInfo[SR_AINFO_NPOSCACHE] - 1) < 1
            nBlockPos := SR_CACHE_PAGE_SIZE * 3
         ELSE
            nBlockPos := ::aInfo[SR_AINFO_NPOSCACHE] - 1
         ENDIF
         ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NPOSCACHE] - ::nCurrentFetch
         IF nOldBg == nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] < 1
               ::aInfo[SR_AINFO_NCACHEBEGIN] += (SR_CACHE_PAGE_SIZE * 3)
            ENDIF
            ::aInfo[SR_AINFO_EOF_AT] := 0

         ELSEIF nOldBg < nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] < 1
               ::aInfo[SR_AINFO_NCACHEBEGIN] += (SR_CACHE_PAGE_SIZE * 3)
               IF (::aInfo[SR_AINFO_NCACHEEND] + 2) >= ::aInfo[SR_AINFO_NCACHEBEGIN]
                  ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] - 2
               ENDIF
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
         ELSE
            IF (::aInfo[SR_AINFO_NCACHEEND] + 2) >= ::aInfo[SR_AINFO_NCACHEBEGIN]
               ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] - 2
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] < 1
               ::aInfo[SR_AINFO_NCACHEBEGIN] += (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEEND] < 1
               ::aInfo[SR_AINFO_NCACHEEND] += (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
         ENDIF

         IF ::aInfo[SR_AINFO_NCACHEEND] == 0
            ::aInfo[SR_AINFO_NCACHEEND] := (SR_CACHE_PAGE_SIZE * 3)
         ENDIF
         IF ::aInfo[SR_AINFO_NPOSCACHE] == 0
            ::aInfo[SR_AINFO_NPOSCACHE] := (SR_CACHE_PAGE_SIZE * 3)
         ENDIF
         IF ::aCache[nBlockPos] == NIL
            ::aCache[nBlockPos] := Array(Len(::aLocalBuffer))
         ENDIF
         ::oSql:GetLine(::aFields, .F., @::aCache[nBlockPos])
         uRecord := ::aCache[nBlockPos, ::hnRecno]
         nPos := ::aInfo[SR_AINFO_NPOSCACHE] - IIf(lCacheIsEmpty, 0, 1)
         IF nPos < 1
            nPos := (SR_CACHE_PAGE_SIZE * 3)
         ENDIF

      ELSE
         ::aInfo[SR_AINFO_NPOSCACHE] := ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NCACHEEND] := nBlockPos := 1
         ::oSql:GetLine(::aFields, .F., @::aCache[1])
         uRecord := ::aCache[nBlockPos, ::hnRecno]
      ENDIF

      IF nDirection == SR_ORD_DIR_FWD .OR. nDirection == SR_ORD_DIR_BWD
         FOR nFecth := 1 to ::nCurrentFetch // TODO: nFecth -> nFetch
            ::oSql:nRetCode := ::oSql:Fetch(NIL, .F., ::aFields)
            IF ::oSql:nRetCode != SQL_SUCCESS
               IF ::oSql:nRetCode == SQL_ERROR
                  DEFAULT ::cLastComm TO ::oSql:cLastComm
                  ::RunTimeErr("999", "[FetchLine Failure][" + AllTrim(Str(::oSql:nRetCode)) + "] " + ::oSql:LastError() + SR_CRLF + SR_CRLF + ;
                     "Last command sent to database : " + SR_CRLF + ::cLastComm)
               ENDIF
               IF nDirection == SR_ORD_DIR_FWD
                  ::aInfo[SR_AINFO_EOF_AT] := uRecord
                  ::aInfo[SR_AINFO_NCACHEEND] := nPos
               ELSE
                  ::aInfo[SR_AINFO_BOF_AT] := uRecord
                  ::aInfo[SR_AINFO_NCACHEBEGIN] := nPos
               ENDIF

               EXIT
            ENDIF
            IF nDirection == SR_ORD_DIR_FWD
               nPos ++
               IF nPos > (SR_CACHE_PAGE_SIZE * 3)
                  nPos -= (SR_CACHE_PAGE_SIZE * 3)
               ENDIF
            ELSE
               nPos--
               IF nPos < 1
                  nPos += (SR_CACHE_PAGE_SIZE * 3)
               ENDIF
            ENDIF

            ::oSql:GetLine(::aFields, .F., @::aCache[nPos])
            uRecord := ::aCache[nPos, ::hnRecno]
            IF ::lFetchAll
               AAdd(::aFetch, uRecord)
            ENDIF
         NEXT nFecth
      ENDIF
      IF ::aCache[::aInfo[SR_AINFO_NPOSCACHE]] != NIL
         ::GetBuffer()     // Loads current cache position to record buffer
      ENDIF
      EXIT

   CASE SQL_NO_DATA_FOUND
      ::lNoData := .T.
      IF nDirection == SR_ORD_DIR_BWD
         ::aInfo[SR_AINFO_BOF] := .T.
         ::aInfo[SR_AINFO_BOF_AT] := ::aInfo[SR_AINFO_RECNO]
      ELSEIF nDirection == SR_ORD_DIR_FWD
         ::aInfo[SR_AINFO_EOF_AT] := ::aInfo[SR_AINFO_RECNO]
         ::GetBuffer(.T.)         // Clean Buffer
      ELSE
         ::GetBuffer(.T.)         // Clean Buffer
      ENDIF
      EXIT

   SR_OTHERWISE
      ::lNoData := .T.
      DEFAULT ::cLastComm TO ::oSql:cLastComm
      ::RunTimeErr("999", "[Fetch Failure/First][" + AllTrim(Str(::oSql:nRetCode)) + "] " + ::oSql:LastError() + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)

   ENDSWITCH

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:Stabilize()

   LOCAL nLen
   LOCAL nPos
   LOCAL nRec
   LOCAL aPos
   LOCAL i
   LOCAL aXF
   LOCAL aFld
   LOCAL lXF
   LOCAL nLast := 0

   HB_SYMBOL_UNUSED(nLast)

   IF ::lStable .OR. ::aInfo[SR_AINFO_INDEXORD] == 0 .OR. Len(::aIndex) == 0 .AND. Len(::aCache) > 0
      RETURN NIL
   ENDIF

   // Stabilize means re-order the workarea cache

   nLen := Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]) // - 1      // This "-1" is to removes the NRECNO column
   nRec := ::aLocalBuffer[::hnRecno]

   aXF := Array(nLen)
   lXF := .F.
   FOR i := 1 TO nLen
      aFld := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]
      IF Len(aFld) >= SR_IDXFLD_XFORM .AND. aFld[SR_IDXFLD_XFORM] != NIL
         aXF[i] := aFld[SR_IDXFLD_XFORM]
         lXF := .T.
      ENDIF
   NEXT i

   IF lXF              // Expression index: sort cache in the transformed domain
      aPos := Array(nLen)
      FOR i := 1 TO nLen
         aPos[i] := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]
      NEXT i
      ASort(::aCache, , , {|x, y|aOrdX(x, y, aPos, aXF)})
   ELSEIF nLen == 1      // One field index is easy and fast !
      nPos := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2]
      ASort(::aCache, , , {|x, y|x[nPos] < y[nPos]})
   ELSE
      aPos := Array(nLen)
      FOR i := 1 TO nLen
         aPos[i] := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]
      NEXT i
      ASort(::aCache, , , {|x, y|aOrd(x, y, aPos)})
   ENDIF

   ::aInfo[SR_AINFO_NPOSCACHE] := AScan(::aCache, {|x|x[::hnRecno] == nRec})

   IF ::aInfo[SR_AINFO_NPOSCACHE] == 0
      ::aInfo[SR_AINFO_NPOSCACHE] := Len(::aCache)
   ENDIF

   ::GetBuffer(.F., ::aInfo[SR_AINFO_NPOSCACHE])
   ::lStable := .T.
   ::aInfo[SR_AINFO_FOUND] := .F.

   ::aInfo[SR_AINFO_BOF] := Len(::aCache) == 0
   ::aInfo[SR_AINFO_EOF] := Len(::aCache) == 0

   ::lNoData := .F.

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:Normalize(nDirection)

   LOCAL nRet := 1

   // Returns : 0 - Nothing, 1 Ok, 2 GoOut()

   DEFAULT nDirection TO 1

   // Can the actual record pass the filters ?_

   DO WHILE !(Eval(::bScope, ::aLocalBuffer) .AND. Eval(::bFilter, ::aLocalBuffer))
      nRet := ::SkipRawCache(nDirection)
      IF nRet != 1
         // EOF or BOF
         EXIT
      ENDIF
   ENDDO

   DO CASE
   CASE nDirection < 0 .AND. nRet == 0      // BOF
      nDirection := 1
      DO WHILE !(Eval(::bScope, ::aLocalBuffer) .AND. Eval(::bFilter, ::aLocalBuffer))
         nRet := ::SkipRawCache(nDirection)
         IF nRet != 1
            ::GetBuffer(.T.)
            EXIT
         ENDIF
      ENDDO
      ::aInfo[SR_AINFO_BOF] := .T.
   ENDCASE

RETURN nRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:SkipRawCache(nToSkip)

   LOCAL nRet := 0

   HB_SYMBOL_UNUSED(nRet)

   DEFAULT nToSkip TO 1

   DO CASE
   CASE ::aInfo[SR_AINFO_NPOSCACHE] + nToSkip > 0 .AND. ::aInfo[SR_AINFO_NPOSCACHE] + nToSkip <= Len(::aCache) .AND. nToSkip != 0
      ::GetBuffer(.F., ::aInfo[SR_AINFO_NPOSCACHE] + nToSkip)
      RETURN 1
   CASE ::aInfo[SR_AINFO_NPOSCACHE] + nToSkip < 1
      ::GetBuffer(.F., 1)
      RETURN 0
   CASE ::aInfo[SR_AINFO_NPOSCACHE] + nToSkip > Len(::aCache)
      ::aInfo[SR_AINFO_BOF] := .F.
      ::GetBuffer(.T.)
   ENDCASE

RETURN 0

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:RuntimeErr(cOperation, cErr, nOSCode, nGenCode, SubCode)

   LOCAL oErr := ErrorNew()
   LOCAL cDescr

   DEFAULT cOperation TO RddName()  // ::ClassName()
   DEFAULT nOSCode TO 0
   DEFAULT nGenCode TO 99
   DEFAULT SubCode TO Val(cOperation)

   IF SubCode > 0 .AND. SubCode <= SR_GetErrMessageMax()
      DEFAULT cErr TO SR_Msg(SubCode)
   ELSE
      DEFAULT cErr TO "RunTime Error"
   ENDIF

   cDescr := AllTrim(cErr)

   ::oSql:RollBack()

   oErr:genCode := nGenCode
   oErr:subCode := SubCode
   oErr:CanDefault := .F.
   oErr:Severity := ES_ERROR
   oErr:CanRetry := .T.
   oErr:CanSubstitute := .F.
   oErr:Description := cDescr + " - RollBack executed."
   oErr:subSystem := RddName()  // ::ClassName()
   oErr:operation := cOperation
   oErr:OsCode := nOSCode
   oErr:FileName := ::cFileName

   SR_LogFile("sqlerror.log", {cDescr})

   _SR_Throw(oErr)

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:CheckCache(oWorkArea)

   LOCAL nRecno := ::aLocalBuffer[::hnRecno]

   HB_SYMBOL_UNUSED(nRecno)

   IF oWorkArea:aInfo[SR_AINFO_EOF]
      oWorkArea:aInfo[SR_AINFO_NCACHEEND] := oWorkArea:aInfo[SR_AINFO_NCACHEBEGIN] := 0
      oWorkArea:aInfo[SR_AINFO_NPOSCACHE] := 0
   ELSE
      IF oWorkArea:aLocalBuffer[::hnRecno] == ::aLocalBuffer[::hnRecno]
         ACopy(::aLocalBuffer, oWorkArea:aLocalBuffer)
      ENDIF
      oWorkArea:aInfo[SR_AINFO_NCACHEEND] := oWorkArea:aInfo[SR_AINFO_NCACHEBEGIN] := 0
      oWorkArea:aInfo[SR_AINFO_NPOSCACHE] := 0
   ENDIF
   oWorkArea:aInfo[SR_AINFO_EOF_AT] := 0
   oWorkArea:aInfo[SR_AINFO_BOF_AT] := 0

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WhereEqual()

RETURN " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(::aInfo[SR_AINFO_RECNO])

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:Quoted(uData, trim, nLen, nDec, nTargetDB, lSynthetic)

   LOCAL cType := ValType(uData)
   LOCAL cRet

   DEFAULT trim TO .F.
   DEFAULT nTargetDB TO ::oSql:cTargetDB
   DEFAULT lSynthetic TO .F.

   IF cType $ "CM" .AND. nLen != NIL
      uData := Left(uData, nLen)
   ENDIF

   IF ::nTCCompat > 0
      trim := .F.
   ENDIF

   IF Empty(uData) .AND. ISPOSTGRESQL() .AND. cType == "D"
      IF lSynthetic
         RETURN "        "
      ELSE
         // uData := SToD("17550101") // Lowest date allowed by MSSQL Server
         RETURN "NULL"
      ENDIF
   ENDIF

   SWITCH cType

   CASE "C"
   CASE "M"
      IF ISPOSTGRESQL() .AND. !trim
         RETURN "E'" + RTrim(SR_ESCAPESTRING(uData, ::oSql:nSystemID)) + "'"
      ELSEIF !trim
         RETURN "'" + SR_ESCAPESTRING(uData, ::oSql:nSystemID) + "'"
      ELSEIF ISPOSTGRESQL() .AND. trim
         RETURN "E'" + RTrim(SR_ESCAPESTRING(uData, ::oSql:nSystemID)) + "'"
      ELSEIF trim
         RETURN "'" + RTrim(SR_ESCAPESTRING(uData, ::oSql:nSystemID)) + "'"
      ENDIF
      EXIT

   CASE "D"
      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_ORACLE
         RETURN "TO_DATE('" + RTrim(DToS(uData)) + "','YYYYMMDD')"
      CASE SQLRDD_RDBMS_INFORM
         RETURN "'" + SR_dtoUS(uData) + "'"
      CASE SQLRDD_RDBMS_SQLBAS
         RETURN "'" + SR_dtosdot(uData) + "'"
      CASE SQLRDD_RDBMS_IBMDB2
      CASE SQLRDD_RDBMS_ADABAS
         RETURN "'" + Transform(DToS(uData), "@R 9999-99-99") + "'"
      CASE SQLRDD_RDBMS_FIREBR
      CASE SQLRDD_RDBMS_FIREBR3
      CASE SQLRDD_RDBMS_FIREBR4
      CASE SQLRDD_RDBMS_FIREBR5
         RETURN "'" + Transform(DToS(uData), "@R 9999/99/99") + "'"
      CASE SQLRDD_RDBMS_INGRES
         RETURN "'" + SR_dtoDot(uData) + "'"
      CASE SQLRDD_RDBMS_CACHE
         RETURN "{d '" + Transform(DToS(IIf(Year(uData) < 1850, SToD("18500101"), uData)), "@R 9999-99-99") + "'}"
      SR_OTHERWISE
         RETURN "'" + DToS(uData) + "'"
      ENDSWITCH

   CASE "T"
      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_POSTGR
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
         IF nLen == 4
            RETURN "'" + HB_TSTOSTR(udata, .T.) + "'"
         ENDIF
         //RETURN "'" + Transform(hb_ttos(uData), '@R 9999-99-99 99:99:99') + "'"
         RETURN "'" + HB_TSTOSTR(uData) + "'"
      CASE SQLRDD_RDBMS_ORACLE
         RETURN " TIMESTAMP '" + Transform(hb_ttos(uData), "@R 9999-99-99 99:99:99") + "'"
      SR_OTHERWISE
         cRet := SR_STRTOHEX(HB_Serialize(uData))
         RETURN ::Quoted(SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, trim, nLen, nDec, nTargetDB)
      ENDSWITCH

   CASE "N"
      IF nLen == NIL
         RETURN LTrim(Str(uData))
      ELSEIF nLen != NIL
         RETURN LTrim(Str(uData, nLen, nDec))
      ENDIF

   CASE "L"
      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_POSTGR
      CASE SQLRDD_RDBMS_FIREBR3
      CASE SQLRDD_RDBMS_FIREBR4
      CASE SQLRDD_RDBMS_FIREBR5
         RETURN IIf(uData, "true", "false")
      CASE SQLRDD_RDBMS_INFORM
         RETURN IIf(uData, "'t'", "'f'")
      //CASE SQLRDD_RDBMS_CUBRID
      //   RETURN IIf(uData, "B'1'", "B'0'")
      SR_OTHERWISE
         RETURN IIf(uData, "1", "0")
      ENDSWITCH

   SR_OTHERWISE

      IF HB_IsArray(uData) .AND. SR_SetSerializeArrayAsJson()
         cRet := hb_jsonencode(uData,.F.)
         RETURN ::Quoted(cRet, trim, nLen, nDec, nTargetDB)
      ENDIF
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN ::Quoted(SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, trim, nLen, nDec, nTargetDB)

   ENDSWITCH

RETURN ""

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:QuotedNull(uData, trim, nLen, nDec, nTargetDB, lNull, lMemo)

   LOCAL cType := ValType(uData)
   LOCAL cRet
   LOCAL cOldSet := SET(_SET_DATEFORMAT)

   DEFAULT trim TO .F.
   DEFAULT nTargetDB TO ::oSql:nSystemID
   DEFAULT lNull TO .T.
   DEFAULT lMemo TO .F.

   IF Empty(uData) .AND. (!cType $ "AOH") .AND. ((nTargetDB == SQLRDD_RDBMS_POSTGR .AND. cType $ "DCMNT" .AND. cType != "L") .OR. (nTargetDB != SQLRDD_RDBMS_POSTGR .AND. cType != "L"))
      IF lNull
         RETURN "NULL"
      ELSE
         SWITCH cType
         CASE "D"
         CASE "T"
            RETURN "NULL"
         CASE "C"
         CASE "M"
            IF ::nTCCompat > 0
               RETURN "'" + uData + "'"
            ENDIF
            IF nTargetDB == SQLRDD_RDBMS_POSTGR
               IF SR_SETPGSOLDBEHAVIOR()
                  RETURN "''"
               ELSE
                  RETURN "' '"
               ENDIF
            ENDIF
            RETURN "' '"
         CASE "N"
            RETURN "0"
         ENDSWITCH
      ENDIF
   ENDIF

   IF cType $ "CM" .AND. nLen != NIL
      IF ::nTCCompat > 0
         trim := .F.
         uData := PadR(uData, nLen)
      ELSE
         uData := Left(uData, nLen)
      ENDIF
   ENDIF

   SWITCH cType

   CASE "C"
   CASE "M"
      IF nTargetDB == SQLRDD_RDBMS_POSTGR .AND. !trim
         RETURN "E'" + SR_ESCAPESTRING(uData, nTargetDB) + "'"
      ELSEIF !trim
         RETURN "'" + SR_ESCAPESTRING(uData, nTargetDB) + "'"
      ELSEIF nTargetDB == SQLRDD_RDBMS_POSTGR .AND. trim
         RETURN "E'" + RTrim(SR_ESCAPESTRING(uData, nTargetDB)) + "'"
      ELSEIF trim
         RETURN "'" + RTrim(SR_ESCAPESTRING(uData, nTargetDB)) + "'"
      ENDIF

   CASE "D"
      IF !lMemo
         SWITCH nTargetDB
         CASE SQLRDD_RDBMS_ORACLE
            RETURN "TO_DATE('" + RTrim(DToS(uData)) + "','YYYYMMDD')"
         CASE SQLRDD_RDBMS_INFORM
            RETURN "'" + SR_dtoUS(uData) + "'"
         CASE SQLRDD_RDBMS_SQLBAS
            RETURN "'" + SR_dtosDot(uData) + "'"
         CASE SQLRDD_RDBMS_IBMDB2
         CASE SQLRDD_RDBMS_ADABAS
            RETURN "'" + Transform(DToS(uData), "@R 9999-99-99") + "'"
         CASE SQLRDD_RDBMS_FIREBR
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            RETURN "'" + Transform(DToS(uData), "@R 9999-99-99") + "'"
         CASE SQLRDD_RDBMS_INGRES
            RETURN "'" + SR_dtoDot(uData) + "'"
         CASE SQLRDD_RDBMS_CACHE
            RETURN "{d '" + Transform(DToS(IIf(Year(uData) < 1850, SToD("18500101"), uData)), "@R 9999-99-99") + "'}"
         SR_OTHERWISE
            RETURN "'" + DToS(uData) + "'"
         ENDSWITCH
      ENDIF
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN ::Quoted(SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, .F., , , nTargetDB)

   CASE "T"
      IF Empty(uData)
         RETURN "NULL"
      ENDIF
      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_POSTGR
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
         IF nLen == 4
            RETURN "'" + HB_TSTOSTR(udata, .T.) + "'"
         ENDIF
         //RETURN "'" + Transform(hb_ttos(uData), '@R 9999-99-99 99:99:99') + "'"
         RETURN "'" + HB_TSTOSTR(uData) + "'"
      CASE SQLRDD_RDBMS_ORACLE
         RETURN " TIMESTAMP '" + Transform(hb_ttos(uData), "@R 9999-99-99 99:99:99") + "'"
      SR_OTHERWISE
         Set(_SET_DATEFORMAT, "yyyy-mm-dd")
         cRet := hb_ttoc(uData)
         Set(_SET_DATEFORMAT, cOldSet)
         RETURN "'" + cRet + "'"
      ENDSWITCH

   CASE "N"
      IF nLen != NIL .AND. !lMemo
         RETURN LTrim(Str(uData, nLen + 1, nDec))
      ELSEIF !lMemo
         RETURN LTrim(Str(uData))
      ENDIF
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN ::Quoted(SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, .F., , , nTargetDB)

   CASE "L"
      IF (nTargetDB == SQLRDD_RDBMS_POSTGR .OR. nTargetDB == SQLRDD_RDBMS_FIREBR3 .OR. nTargetDB == SQLRDD_RDBMS_FIREBR4 .OR. nTargetDB == SQLRDD_RDBMS_FIREBR5) .AND. !lMemo
         RETURN IIf(uData, "true", "false")
      ELSEIF nTargetDB == SQLRDD_RDBMS_INFORM
         RETURN IIf(uData, "'t'", "'f'")
      //ELSEIF nTargetDB == SQLRDD_RDBMS_CUBRID
      //   RETURN IIf(uData, "B'1'", "B'0'")
      ELSEIF !lMemo
         RETURN IIf(uData, "1", "0")
      ENDIF
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN ::Quoted(SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, .F., , , nTargetDB)

   SR_OTHERWISE
      IF HB_IsArray(uData) .AND. SR_SetSerializeArrayAsJson()
         cRet := hb_jsonencode(uData, .F.)
         RETURN ::Quoted(cRet, .F., , , nTargetDB)
      ENDIF
      cRet := SR_STRTOHEX(HB_Serialize(uData))
      RETURN ::Quoted(SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cRet), 10) + cRet, .F., , , nTargetDB)

   ENDSWITCH

RETURN ""

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:HistExpression(n, cAlias)

   // parameter n +- 0 -> (default) active record at current date
   //             |- 1 -> record last version
   //             +- 2 -> record first version

   LOCAL cRet := ""
   LOCAL cAl1
   LOCAL cAl2

   IF !::lHistoric .OR. !::lHistEnable
      RETURN ""
   ENDIF

   IF ::nCnt == NIL
      ::nCnt := 1
   ENDIF

   cAl1 := "W" + StrZero(++::nCnt, 3)
   cAl2 := "W" + StrZero(++::nCnt, 3)
   HB_SYMBOL_UNUSED(cAl2)

   IF ::nCnt >= 997
      ::nCnt := 1
   ENDIF

   DEFAULT cAlias TO "A"

   IF SR_GetlUseDTHISTAuto()
      DEFAULT ::CurrDate TO SR_GetActiveDt()
   ELSE
      ::CurrDate := SR_GetActiveDt()
   ENDIF

   DEFAULT n TO 0

   cRet += "(" + cAlias + ".DT__HIST = (SELECT" + IIf(n == 3, " MIN(", " MAX(") + cAl1 + ".DT__HIST) FROM "
   cRet += ::cQualifiedTableName + " " + cAl1 + " WHERE " + cAlias + "." + ::cColPK + "="
   cRet += cAl1 + "." + ::cColPK

   IF n == 0
      cRet += " AND " + cAl1 + ".DT__HIST <= " + SR_cDBValue(::CurrDate)
   ENDIF

   cRet += "))"

RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WriteBuffer(lInsert, aBuffer)

   LOCAL cRet := ""
   LOCAL cVal := ""
   LOCAL lFirst := .T.
   LOCAL cWh
   LOCAL aRet
   LOCAL nLen
   LOCAL nDec
   LOCAL lNull
   LOCAL lMemo
   LOCAL i
   LOCAL nInd
   LOCAL cKey
   LOCAL nRet
   LOCAL nThisField
   LOCAL cIdent := ""
   LOCAL lML
   LOCAL lMustUPD := .F.
   LOCAL aMemos := {}
   LOCAL cMemo
   LOCAL oXml

   DEFAULT lInsert TO ::aInfo[SR_AINFO_ISINSERT]
   DEFAULT aBuffer TO ::aLocalBuffer

   ASize(::aLocalBuffer, ::nFields)

   IF !lInsert .AND. ::aInfo[SR_AINFO_EOF] .AND. ::aInfo[SR_AINFO_BOF]
      ::RunTimeErr("1")
      RETURN .F.
   ENDIF

   IF !lInsert .AND. Empty(aBuffer[::hnRecno])
      RETURN .F.
   ENDIF

   ::aInfo[SR_AINFO_ISINSERT] := .F.
   ::aInfo[SR_AINFO_HOT] := .F.
   ::aInfo[SR_AINFO_EOF_AT] := 0
   ::aInfo[SR_AINFO_BOF_AT] := 0

   IF ::lHistoric .AND. (!Empty(aBuffer[::nPosDtHist])) .AND. (!Empty(aBuffer[::hnRecno]))
      aRet := {}

      IF SR_GetlUseDTHISTAuto()
         ::oSql:Exec("SELECT " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " FROM " + ::cQualifiedTableName + " WHERE " + ;
            ::cColPK + " = " + SR_cDbValue(aBuffer[::nPosColPK]) + " AND DT__HIST = " + SR_cDbValue(aBuffer[::nPosDtHist]), ;
            .F., .T., @aRet)
      ELSE
         ::oSql:Exec("SELECT " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " FROM " + ::cQualifiedTableName + " WHERE " + ;
            ::cColPK + " = " + SR_cDbValue(aBuffer[::nPosColPK]) + " AND DT__HIST = " + SR_cDbValue(SR_GetActiveDt()), ;
            .F., .T., @aRet)
      ENDIF

      IF Len(aRet) > 0
         lInsert := .F.
         lMustUPD := .T.
      ENDIF
   ENDIF

   IF ::lHistoric .AND. !lMustUPD

      IF Empty(aBuffer[::nPosDtHist])
         aBuffer[::nPosDtHist] := SR_GetActiveDt()
      ENDIF
      IF !lInsert
         IF ::lVers
            lInsert := .T.
            IF (!::oSql:lUseSequences .OR. !::lUseSequences) .OR. (ISFIREBIRD() .OR. ISINGRES())
               ::aInfo[SR_AINFO_RECNO] := 0
               aBuffer[::hnRecno] := 0               // This forces NEW recno number
            ENDIF
            IF ::dNextDt == NIL
               aBuffer[::nPosDtHist] := SR_GetActiveDt()
            ELSE
               aBuffer[::nPosDtHist] := ::dNextDt
            ENDIF
         ENDIF
      ENDIF
   ENDIF

   DO CASE
   CASE !lInsert
      IF ::lCanUpd
         FOR nThisField := 1 TO ::nFields
            IF      SubStr(::aNames[nThisField], 1, 7) == "INDKEY_" ;
               .OR. SubStr(::aNames[nThisField], 1, 7) == "INDFOR_" ;
               .OR. aBuffer[nThisField] == NIL
               LOOP
            ENDIF

            nLen := ::aFields[nThisField, SR_FIELD_LEN]
            nDec := ::aFields[nThisField, SR_FIELD_DEC]
            lNull := ::aFields[nThisField, SR_FIELD_NULLABLE]
            lMemo := ::aFields[nThisField, SR_FIELD_TYPE] == "M"
            lML := ::aFields[nThisField, SR_FIELD_MULTILANG]
            IF lMemo .AND. ::aFields[nThisField, SR_FIELD_DOMAIN] == SQL_LONGVARCHARXML
               lMemo := .F.
            ENDIF
            IF lML .OR. ;
               (::aOldBuffer[nThisField] == NIL) .OR.;
               (lMemo .AND. (!HB_IsChar(::aOldBuffer[nThisField]) .OR. !HB_IsChar(aBuffer[nThisField]))) .OR.;
               ((!::aOldBuffer[nThisField] == aBuffer[nThisField]) .AND. (nThisField != ::hnRecno))

               IF lML .AND. HB_IsString(aBuffer[nThisField])
                  aBuffer[nThisField] := hb_Hash(SR_SetBaseLang(), aBuffer[nThisField])
               ENDIF
               IF (lMemo .OR. lML) .AND. (ISORACLE() .OR. ISADABAS() .OR. ISIBMDB2()) .AND. ::aFields[nThisField, SR_FIELD_DOMAIN] != SQL_FAKE_LOB  // .OR. ISCACHE()
                  IF !HB_IsString(aBuffer[nThisField])
                     cMemo := SR_STRTOHEX(HB_Serialize(aBuffer[nThisField]))
                     cMemo := SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cMemo), 10) + cMemo
                  ELSE
                     cMemo := aBuffer[nThisField]
                  ENDIF
                  AAdd(aMemos, {::aNames[nThisField], cMemo})
                  LOOP
#ifdef SQLRDD_TOPCONN
               ELSEIF ::aFields[nThisField, SR_FIELD_DOMAIN] == SQL_FAKE_DATE
                  cRet += IIf(!lFirst, ", ", "") + SR_DBQUALIFY(::aNames[nThisField], ::oSql:nSystemID) + " = '" + DToS(aBuffer[nThisField]) + "' "
               ELSEIF ::aFields[nThisField, SR_FIELD_DOMAIN] == SQL_FAKE_NUM
                  cRet += IIf(!lFirst, ", ", "") + SR_DBQUALIFY(::aNames[nThisField], ::oSql:nSystemID) + " = " + Str(aBuffer[nThisField], nLen, nDec) + " "
#endif
               ELSEIF ::aFields[nThisField, SR_FIELD_DOMAIN] != SQL_GUID
                  cRet += IIf(!lFirst, ", ", "") + SR_DBQUALIFY(::aNames[nThisField], ::oSql:nSystemID) + " = " + ::QuotedNull(aBuffer[nThisField], .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo) + " "
               ELSEIF ::aFields[nThisField, SR_FIELD_DOMAIN] == SQL_LONGVARCHARXML
                  oXml := sr_arraytoXml(aBuffer[nThisField])
#ifdef __XHARBOUR__
                  nlen := Len(oxml:tostring(HBXML_STYLE_NONEWLINE))
                  cVal := IIf(!lFirst, ", ", "") + SR_DBQUALIFY(::aNames[nThisField], ::oSql:nSystemID) + " = " + ::QuotedNull(oxml:tostring(HBXML_STYLE_NONEWLINE), .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo)
#else
                  nlen := Len(oxml:tostring(SR_XML_STYLE_NONEWLINE))
                  cVal := IIf(!lFirst, ", ", "") + SR_DBQUALIFY(::aNames[nThisField], ::oSql:nSystemID) + " = " + ::QuotedNull(oxml:tostring(SR_XML_STYLE_NONEWLINE), .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo)
#endif
               ELSEIF ::aFields[nthisField, SR_FIELD_DOMAIN] == SQL_VARBINARY .AND. ISMSSQL7()
                  cVal := '0x'+hb_StrtoHex(aBuffer[nThisField])
               //ELSEIF ::aFields[nthisField, SR_FIELD_DOMAIN] == SQL_BINARY .AND. ISCUBRID()
               //   cVal := iif(aBuffer[nThisField], "B'1'", "B'0'")
               ELSE
                  LOOP
               ENDIF
               lFirst := .F.
               ::aOldBuffer[nThisField] := aBuffer[nThisField]
            ENDIF
         NEXT nThisField

         IF !lFirst            // Smth has been updated

            // Write the index columns

            IF !lFirst
               FOR nInd := 1 TO Len(::aIndexMgmnt)
                  IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])
                     cKey := (::cAlias)->(SR_ESCAPESTRING(Eval(::aIndexMgmnt[nInd, SR_INDEXMAN_KEY_CODEBLOCK]), ::oSql:nSystemID))
                     IF ISPOSTGRESQL()
                        cRet += ", " + SR_DBQUALIFY("INDKEY_" + ::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS], ::oSql:nSystemID) + " = E'" + cKey + "' "
                     ELSE
                        cRet += ", " + SR_DBQUALIFY("INDKEY_" + ::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS], ::oSql:nSystemID) + " = '" + cKey + "' "
                     ENDIF
                     ::aLocalBuffer[::aIndexMgmnt[nInd, SR_INDEXMAN_SYNTH_COLPOS]] := cKey
                  ENDIF
                  IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_CODEBLOCK])
                     cKey := (::cAlias)->(Eval(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_CODEBLOCK]))
                     IF ISPOSTGRESQL()
                        cRet += ", " + SR_DBQUALIFY("INDFOR_" + SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS], 2, 3), ::oSql:nSystemID) + " = E'" + cKey + "' "
                     ELSE
                        cRet += ", " + SR_DBQUALIFY("INDFOR_" + SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS], 2, 3), ::oSql:nSystemID) + " = '" + cKey + "' "
                     ENDIF
                     ::aLocalBuffer[::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_COLPOS]] := cKey
                  ENDIF
               NEXT nInd
            ENDIF

            cWh := ::WhereEqual()

            IF Empty(cWh)
               ::dNextDt := NIL
               ::RuntimeErr("4")
               RETURN .F.
            ENDIF

            IF ::oSql:Execute(::cUpd + cRet + cWh, , ::nLogMode) != SQL_SUCCESS
               ::RuntimeErr("16", SR_Msg(16) + ::oSql:LastError() + SR_CRLF + SR_CRLF + ;
                  SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
               ::dNextDt := NIL
               RETURN .F.
            ENDIF

            ::oSql:FreeStatement()

         ENDIF

         // Write memo fields

         IF Len(aMemos) > 0
            ::oSql:WriteMemo(::cQualifiedTableName, aBuffer[::hnRecno], SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID), aMemos)
         ENDIF

         IF ::aInfo[SR_AINFO_NCACHEBEGIN] == 0 .AND. ::aInfo[SR_AINFO_NCACHEEND] == 0
            ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
            ::aInfo[SR_AINFO_NPOSCACHE] := 1
         ENDIF

         ASize(::aCache[::aInfo[SR_AINFO_NPOSCACHE]], ::nFields)
         ACopy(::aLocalBuffer, ::aCache[::aInfo[SR_AINFO_NPOSCACHE]])

         // Sync with other workareas opening the same table

         _SR_ScanExec(Self, {|x|IIf(x:nThisArea != ::nThisArea, ::CheckCache(x), NIL)})

      ELSE
         ::RunTimeErr("5", SR_Msg(5) + ::cFileName)
      ENDIF

   CASE lInsert

      IF ::lCanIns

         FOR i := 1 TO ::nFields
            IF SubStr(::aNames[i], 1, 7) == "INDKEY_" .OR. SubStr(::aNames[i], 1, 7) == "INDFOR_"
               LOOP
            ENDIF

            nLen := ::aFields[i, SR_FIELD_LEN]
            nDec := ::aFields[i, SR_FIELD_DEC]
            lNull := ::aFields[i, SR_FIELD_NULLABLE]
            lMemo := ::aFields[i, SR_FIELD_TYPE] == "M"
            lML := ::aFields[i, SR_FIELD_MULTILANG]
            IF lMemo .AND. ::aFields[i, SR_FIELD_DOMAIN] == SQL_LONGVARCHARXML
               lMemo := .F.
            ENDIF

            IF lML .AND. HB_IsString(aBuffer[i])
               aBuffer[i] := {SR_SetBaseLang() => aBuffer[i]}
            ENDIF

            IF aBuffer[i] == NIL
               aBuffer[i] := ::aEmptyBuffer[i]
            ENDIF

            IF i == ::hnRecno
               IF !::oSql:lUseSequences .OR. !::lUseSequences
                  IF Empty(::aInfo[SR_AINFO_RECNO])
                     aBuffer[::hnRecno] := ::GetNextRecordNumber()
                     ::aInfo[SR_AINFO_RECNO] := aBuffer[::hnRecno]
                  ELSE
                     aBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
                  ENDIF
                  IF ::cIns == NIL
                     cRet += IIf(!lFirst, ", ", "( ") + SR_DBQUALIFY(::aNames[i], ::oSql:nSystemID)
                  ENDIF
                  cVal += IIf(!lFirst, ", ", "( ") + ::QuotedNull(aBuffer[i], .T., NIL, nDec, , lNull, lMemo)
                  lFirst := .F.
               ELSEIF !::lQuickAppend .OR. ISINGRES()
                  SWITCH ::oSql:nSystemID
                  CASE SQLRDD_RDBMS_INGRES
                  CASE SQLRDD_RDBMS_FIREBR
                     IF Empty(::aInfo[SR_AINFO_RECNO])
                        aBuffer[::hnRecno] := ::GetNextRecordNumber()
                        ::aInfo[SR_AINFO_RECNO] := aBuffer[::hnRecno]
                     ELSE
                        aBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
                     ENDIF
                     IF ::cIns == NIL
                        cRet += IIf(!lFirst, ", ", "( ") + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID)
                     ENDIF
                     cVal += IIf(!lFirst, ", ", "( ") + LTrim(Str(aBuffer[::hnRecno], 15))
                     lFirst := .F.
                     EXIT
                  CASE SQLRDD_RDBMS_INFORM // TODO: unnecessary
                  CASE SQLRDD_RDBMS_ORACLE // TODO: unnecessary
                  CASE SQLRDD_RDBMS_MSSQL7 // TODO: unnecessary
                  CASE SQLRDD_RDBMS_POSTGR // TODO: unnecessary
                  CASE SQLRDD_RDBMS_MSSQL6 // TODO: unnecessary
                  CASE SQLRDD_RDBMS_SYBASE // TODO: unnecessary
                  CASE SQLRDD_RDBMS_IBMDB2 // Use IDENTITY column (or similar) // TODO: unnecessary
                  CASE SQLRDD_RDBMS_AZURE // TODO: unnecessary
                  ENDSWITCH
               ENDIF
            ELSE
               IF lMemo .OR. lML
                  IF !HB_IsString(aBuffer[i])
                     cMemo := SR_STRTOHEX(HB_Serialize(aBuffer[i]))
                     cMemo := SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cMemo), 10) + cMemo
                  ELSE
                     cMemo := aBuffer[i]
                  ENDIF

                  IF ISORACLE() .AND. Len(cMemo) > 2000  // .OR. ISCACHE()
                     AAdd(aMemos, {::aNames[i], cMemo})
                     cMemo := NIL
                  ELSEIF ISIBMDB2() .AND. Len(cMemo) > 32000
                     AAdd(aMemos, {::aNames[i], cMemo})
                     cMemo := NIL
                  ELSEIF ISADABAS() // .OR. ISMSSQL7() // ADABAS always need binding
                     AAdd(aMemos, {::aNames[i], cMemo})
                     LOOP
                  ELSE
                     cMemo := aBuffer[i]
                  ENDIF
               ELSE
                  cMemo := aBuffer[i]
               ENDIF

               IF ::cIns == NIL
                  cRet += IIf(!lFirst, ", ", "( ") + SR_DBQUALIFY(::aNames[i], ::oSql:nSystemID)
               ENDIF

               SWITCH ::aFields[i, SR_FIELD_DOMAIN]
               CASE SQL_GUID
                  cVal += IIf(!lFirst, ", ", "( ") + " NEWID() "
                  EXIT
#ifdef SQLRDD_TOPCONN
               CASE SQL_FAKE_DATE
                  cVal += IIf(!lFirst, ", ", "( ") + "'" + DToS(cMemo) + "' "
                  EXIT
               CASE SQL_FAKE_NUM
                  cVal += IIf(!lFirst, ", ", "( ") + Str(cMemo, nLen, nDec) + " "
                  EXIT
#endif
               CASE SQL_LONGVARCHARXML
                  oXml := sr_arraytoXml(cMemo)
#ifdef __XHARBOUR__
                  nlen := Len(oxml:tostring(HBXML_STYLE_NONEWLINE))
                  cVal += IIf(!lFirst, ", ", "( ") + ::QuotedNull(oXml:tostring(HBXML_STYLE_NONEWLINE), .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo)
#else
                  nlen := Len(oxml:tostring(SR_XML_STYLE_NONEWLINE))
                  cVal += IIf(!lFirst, ", ", "( ") + ::QuotedNull(oXml:tostring(SR_XML_STYLE_NONEWLINE), .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo)
#endif
                  EXIT
               CASE SQL_VARBINARY
                  IF ISMSSQL7()
                     cVal += IIf(!lFirst, ", ", "( ") + "0x" + hb_StrtoHex(cmemo)
                  ELSE
                     cVal += IIf(!lFirst, ", ", "( ") + ::QuotedNull(cMemo, .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo)
                  ENDIF
                  EXIT
               //CASE SQL_BINARY
               //   IF ISCUBRID()
               //      cVal += IIf(!lFirst, ", ", "( ") + iif(cmemo, "B'1'", "B'0'")
               //   ELSE
               //      cVal += IIf(!lFirst, ", ", "( ") + ::QuotedNull(cMemo, .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo)
               //   ENDIF
               //   EXIT
               SR_OTHERWISE
                  cVal += IIf(!lFirst, ", ", "( ") + ::QuotedNull(cMemo, .T., IIf(lMemo, NIL, nLen), nDec, , lNull, lMemo)
               ENDSWITCH
               lFirst := .F.
            ENDIF
         NEXT i

         // Write the index columns

         FOR nInd := 1 TO Len(::aIndexMgmnt)
            IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])
               IF ::cIns == NIL
                  cRet += IIf(!lFirst, ", ", "( ") + SR_DBQUALIFY("INDKEY_" + ::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS], ::oSql:nSystemID)
               ENDIF
               cKey := (::cAlias)->(SR_ESCAPESTRING(Eval(::aIndexMgmnt[nInd, SR_INDEXMAN_KEY_CODEBLOCK]), ::oSql:nSystemID))
               IF ISPOSTGRESQL()
                  cVal += IIf(!lFirst, ", E'", "( E'") + cKey + "'"
               ELSE
                  cVal += IIf(!lFirst, ", '", "( '") + cKey + "'"
               ENDIF
               ::aLocalBuffer[::aIndexMgmnt[nInd, SR_INDEXMAN_SYNTH_COLPOS]] := cKey
            ENDIF
            IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_CODEBLOCK])
               IF ::cIns == NIL
                  cRet += IIf(!lFirst, ", ", "( ") + SR_DBQUALIFY("INDFOR_" + SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS], 2, 3), ::oSql:nSystemID)
               ENDIF
               cKey := (::cAlias)->(Eval(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_CODEBLOCK]))
               IF ISPOSTGRESQL()
                  cVal += IIf(!lFirst, ", E'", "( E'") + cKey + "'"
               ELSE
                  cVal += IIf(!lFirst, ", '", "( '") + cKey + "'"
               ENDIF
               ::aLocalBuffer[::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_COLPOS]] := cKey
            ENDIF
         NEXT nInd

         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_AZURE
            IF ::oSql:lUseSequences .AND. ::lUseSequences
               //cIdent := "; SELECT IDENT_CURRENT('" + ::cfilename + "');"
               cIdent := "; SELECT " + ::cRecnoName + " FROM @InsertedData;"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
            IF ::oSql:lUseSequences .AND. ::lUseSequences .AND. !("DB2/400" $ ::oSql:cSystemName)
               cIdent := "; VALUES IDENTITY_VAL_LOCAL();"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            IF ::oSql:lUseSequences .AND. ::lUseSequences
               cIdent := "  RETURNING  " + ::cRecnoName
            ENDIF
         ENDSWITCH

         aRet := {}

         IF Len(::aOldBuffer) == 0
            ASize(::aOldBuffer, Len(::aLocalBuffer))
         ENDIF
         ACopy(aBuffer, ::aOldBuffer)

         IF ::cIns == NIL
            IF ISMSSQL7()
               ::cIns := "Declare @InsertedData table (" + ::cRecnoName + " numeric(15,0) );INSERT INTO " + ::cQualifiedTableName + " " + cRet + " ) OUTPUT Inserted." + ::cRecnoName + " INTO @InsertedData VALUES "
            ELSE
               ::cIns := "INSERT INTO " + ::cQualifiedTableName + " " + cRet + " ) VALUES "
            ENDIF
         ENDIF

         IF ::oSql:Execute(::cIns + cVal + " ) " + cIdent, , ::nLogMode) != SQL_SUCCESS
            ::dNextDt := NIL
            RETURN .F.
         ENDIF

         // If using sequences, try to find the record number

         IF ::oSql:lUseSequences .AND. ::lUseSequences .AND. !::lQuickAppend

            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_FIREBR3
            CASE SQLRDD_RDBMS_FIREBR4
            CASE SQLRDD_RDBMS_FIREBR5
               ::oSql:MoreResults(@aRet)
               IF Len(aRet) > 0
                  aBuffer[::hnRecno] := aRet[1, 1]
               ELSE
                  ::RunTimeErr("11", SR_Msg(11) + ::cFileName + " SQL Statement: " + ::cIns + cVal + " ) " + cIdent  + " " + ::oSql:LastError())
                  ::dNextDt := NIL
                  RETURN .F.
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_MSSQL7
            CASE SQLRDD_RDBMS_AZURE
               ::oSql:MoreResults(@aRet)
               ::oSql:MoreResults(@aRet)
               IF Len(aRet) > 0
                  aBuffer[::hnRecno] := aRet[1, 1]
               ELSE
                  ::RunTimeErr("11", SR_Msg(11) + ::cFileName + " SQL Statement: " + ::cIns + cVal + " ) " + cIdent  + " " + ::oSql:LastError())
                  ::dNextDt := NIL
                  RETURN .F.
               ENDIF
               ::oSql:FreeStatement()
               EXIT
            CASE SQLRDD_RDBMS_IBMDB2
               IF "DB2/400" $ ::oSql:cSystemName
                  ::oSql:FreeStatement()
                  aRet := {}
                  ::oSql:Exec("SELECT IDENTITY_VAL_LOCAL() AS RECORD FROM " + ::cOwner + ::cFileName + " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = IDENTITY_VAL_LOCAL()" , .F., .T., @aRet)
                  IF Len(aRet) > 0
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ELSE
                     ::RunTimeErr("11", SR_Msg(11) + ::cFileName)
                     ::dNextDt := NIL
                     RETURN .F.
                  ENDIF
               ELSE
                  ::oSql:MoreResults(@aRet)
                  ::oSql:MoreResults(@aRet)
                  IF Len(aRet) > 0
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ELSE
                     ::RunTimeErr("11", SR_Msg(11) + ::cFileName)
                     ::dNextDt := NIL
                     RETURN .F.
                  ENDIF
                  ::oSql:FreeStatement()
                  EXIT
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_ORACLE
               ::oSql:FreeStatement()
               aRet := {}
               SWITCH ::nSequencePerTable
               CASE SEQ_PER_TABLE
                  ::oSql:Exec("SELECT " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ.CURRVAL FROM DUAL", .T., .T., @aRet)
                  IF Len(aRet) > 0
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ENDIF
                  EXIT
               CASE SEQ_NOTDEFINED
                  ::oSql:Exec("SELECT " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ.CURRVAL FROM DUAL", .F., .T., @aRet)
                  IF Len(aRet) > 0
                     ::nSequencePerTable := SEQ_PER_TABLE
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ELSE
                     ::nSequencePerTable := SEQ_PER_DATABASE
                     aRet := {}
                     ::oSql:Exec("SELECT " + ::cOwner + "SQ_NRECNO.CURRVAL FROM DUAL", .F., .T., @aRet)
                     IF Len(aRet) > 0
                        aBuffer[::hnRecno] := aRet[1, 1]
                     ENDIF
                  ENDIF
                  EXIT
               CASE SEQ_PER_DATABASE
                  ::oSql:Exec("SELECT SQ_NRECNO.CURRVAL FROM DUAL", .F., .T., @aRet)
                  IF Len(aRet) > 0
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ENDIF
               ENDSWITCH
               EXIT
            CASE SQLRDD_RDBMS_POSTGR
               ::oSql:FreeStatement()
               aRet := {}
               SWITCH ::nSequencePerTable
               CASE SEQ_PER_TABLE
                  ::oSql:Exec("SELECT currval('" + ::cOwner + LimitLen(::cFileName, 3) + "_SQ')", .F., .T., @aRet)
                  IF Len(aRet) > 0
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ENDIF
                  EXIT
               CASE SEQ_NOTDEFINED
                  ::oSql:Exec("SELECT currval('" + ::cOwner + LimitLen(::cFileName, 3) + "_SQ')", .F., .T., @aRet)
                  IF Len(aRet) > 0
                     ::nSequencePerTable := SEQ_PER_TABLE
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ELSE
                     ::oSql:Commit()
                     ::nSequencePerTable := SEQ_PER_DATABASE
                     aRet := {}
                     ::oSql:Exec("SELECT currval('SQ_NRECNO')", .F., .T., @aRet)
                     IF Len(aRet) > 0
                        aBuffer[::hnRecno] := aRet[1, 1]
                     ENDIF
                  ENDIF
                  EXIT
               CASE SEQ_PER_DATABASE
                  ::oSql:Exec("SELECT currval('SQ_NRECNO')", .F., .T., @aRet)
                  IF Len(aRet) > 0
                     aBuffer[::hnRecno] := aRet[1, 1]
                  ENDIF
               ENDSWITCH
               EXIT
            CASE SQLRDD_RDBMS_MYSQL
            CASE SQLRDD_RDBMS_MARIADB
               ::oSql:FreeStatement()
               aRet := {}
               ::oSql:Exec("SELECT LAST_INSERT_ID()", .F., .T., @aRet)
               IF Len(aRet) > 0
                  aBuffer[::hnRecno] := aRet[1, 1]
               ELSE
                  ::RunTimeErr("11", SR_Msg(11) + ::cFileName)
                  ::dNextDt := NIL
                  RETURN .F.
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_INFORM
               ::oSql:FreeStatement()
               aRet := {}
               ::oSql:Exec("select first 1 dbinfo('sqlca.sqlerrd1') from systables", .F., .T., @aRet)
               IF Len(aRet) > 0
                  aBuffer[::hnRecno] := aRet[1, 1]
               ELSE
                  ::RunTimeErr("11", SR_Msg(11) + ::cFileName)
                  ::dNextDt := NIL
                  RETURN .F.
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_CUBRID
               ::oSql:FreeStatement()
               aRet := {}
               ::oSql:Exec("SELECT LAST_INSERT_ID()", .F., .T., @aRet)
               IF Len(aRet) > 0
                  aBuffer[::hnRecno] := aRet[1, 1]
               ELSE
                  ::RunTimeErr("11", SR_Msg(11) + ::cFileName)
                  ::dNextDt := NIL
                  RETURN .F.
               ENDIF
            ENDSWITCH
         ENDIF

         // Write memo fields
         IF Len(aMemos) > 0
            IF (nRet := ::oSql:WriteMemo(::cQualifiedTableName, aBuffer[::hnRecno], SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID), aMemos)) != 0
               ::RunTimeErr("10", "Error writing LOB info in table " + ::cFileName + ":" + LTrim(Str(nRet)) + " " + ::oSql:LastError())
            ENDIF
         ENDIF

         // Record should remain Locked

         IF ::aInfo[SR_AINFO_SHARED] .AND. Len(::aLocked) < SR_MAXIMUN_LOCKS
            AAdd(::aLocked, aBuffer[::hnRecno])
         ENDIF

         // Sets info array

         ::lEmptyTable := .F.
         ::aInfo[SR_AINFO_RCOUNT] := aBuffer[::hnRecno]
         ::nLastRecordAded := aBuffer[::hnRecno]

         // Cache insertion is disabled because INSERTED lines usually
         // are discarded by cache engine

         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_EOF] := .F.
         ::aInfo[SR_AINFO_BOF_AT] := 0
         ::aInfo[SR_AINFO_EOF_AT] := 0

         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
         ::aInfo[SR_AINFO_NPOSCACHE] := 1
         IF ::aCache[1] == NIL
            ::aCache[1] := Array(Len(::aLocalBuffer))
         ENDIF

         ASize(::aCache[1], ::nFields)
         ACopy(::aLocalBuffer, ::aCache[1])

         _SR_ScanExec(Self, {|x|IIf(x:nThisArea != ::nThisArea, ::CheckCache(x), NIL)})

      ELSE
         SR_MsgLogFile(SR_Msg(3) + ::cFileName)
      ENDIF

   ENDCASE

   ::aInfo[SR_AINFO_RECNO] := aBuffer[::hnRecno]
   ::aInfo[SR_AINFO_BOF] := .F.
   ::aInfo[SR_AINFO_EOF] := .F.
   ::lNoData := .F.
   ::dNextDt := NIL

   IF ::lCollectingBehavior
      FOR EACH i IN ::aSelectList
         IF i == 1
            ::lCollectingBehavior := .F.
            EXIT
         ENDIF
      NEXT
   ENDIF

RETURN .T.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:lCanICommitNow()

RETURN ::oSql:nTransacCount == 0 .AND. ::aInfo[SR_AINFO_SHARED] .AND. Empty(::aLocked)

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:UpdateCache(aResultSet)

   LOCAL uRecord
   LOCAL uVal

   IF ::hnRecno == NIL .OR. ::hnRecno <= 0 .AND. Len(aResultSet) > 0
      RETURN NIL
   ENDIF

   uRecord := aResultSet[1, ::hnRecno]

   IF SR_SetMultiLang()
      IF ::aInfo[SR_AINFO_RECNO] == uRecord
         FOR EACH uVal IN aResultSet[1]
            IF HB_IsHash(::aLocalBuffer[SR_ENUMINDEX(uVal)])
               IF ::aFields[SR_ENUMINDEX(uVal), SR_FIELD_TYPE] $ "CM"
                  (::aLocalBuffer[SR_ENUMINDEX(uVal)])[SR_SetBaseLang()] := PadR(uVal, ::aFields[SR_ENUMINDEX(uVal), SR_FIELD_LEN])
               ELSE
                  (::aLocalBuffer[SR_ENUMINDEX(uVal)])[SR_SetBaseLang()] := uVal
               ENDIF
               ::aOldBuffer[SR_ENUMINDEX(uVal)] := ::aLocalBuffer[SR_ENUMINDEX(uVal)]
            ELSE
               ::aLocalBuffer[SR_ENUMINDEX(uVal)] := uVal
               ::aOldBuffer[SR_ENUMINDEX(uVal)] := uVal
            ENDIF
         NEXT
      ENDIF
   ELSE
      IF ::aInfo[SR_AINFO_RECNO] == uRecord
         FOR EACH uVal IN aResultSet[1]
            ::aLocalBuffer[SR_ENUMINDEX(uVal)] := uVal
            ::aOldBuffer[SR_ENUMINDEX(uVal)] := uVal
         NEXT
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:Default()

   IF Len(::aCache) == 0
      ::aInfo[SR_AINFO_BOF] := .T.
      ::aInfo[SR_AINFO_RCOUNT] := 0
      ::aInfo[SR_AINFO_RECNO] := 1
      ::lNoData := .T.
      ::GetBuffer(.T.)
      ::aInfo[SR_AINFO_NPOSCACHE] := 1
   ELSE
      ::aInfo[SR_AINFO_BOF] := .F.
      ::aInfo[SR_AINFO_EOF] := .F.
      ::aInfo[SR_AINFO_RCOUNT] := ::nLastRec
      ::lNoData := .F.
      ::GetBuffer(.F.)                        // Use the first record
      IF ::hnRecno != NIL .AND. ::hnRecno != 0
         ::aInfo[SR_AINFO_RECNO] := ::aLocalBuffer[::hnRecno]
      ELSE
         ::aInfo[SR_AINFO_RECNO] :=  ::aInfo[SR_AINFO_NPOSCACHE]
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:SolveSQLFilters(cAliasSQL)

   LOCAL cRet := ""
   LOCAL cFlt

   DEFAULT cAliasSQL TO ""

   IF !Empty(cAliasSQL) .AND. Right(cAliasSQL, 1) != "."
      cAliasSQL += "."
   ENDIF
   FOR EACH cFlt IN ::aFilters
      cFlt := StrTran(cFlt, "<ALIAS>.", cAliasSQL)
      BEGIN SEQUENCE
         IF Empty(cRet)
            IF SR_EvalFilters()
               cRet := &cFlt
            ELSE
               cRet := cFlt
            ENDIF
         ELSE
            IF SR_EvalFilters()
               cRet += " AND " + &cFlt
            ELSE
               cRet += " AND " + cFlt
            ENDIF
         ENDIF
      RECOVER
         ::RunTimeErr("10", SR_Msg(10) + ::cFileName + " - " + cFlt)
      END SEQUENCE
   NEXT
RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:Refresh(lGoCold)

   LOCAL i
   LOCAL nMax := 0
   LOCAL nAllocated
   LOCAL n
   LOCAL lRecnoAdded := .F.

   DEFAULT lGoCold TO .T.

   IF lGoCold
      ::sqlGoCold()     // writes any change in the buffer to the database
   ELSE
      ::aInfo[SR_AINFO_HOT] := .F.
      ::GetBuffer(.T.)         // Clean Buffer
   ENDIF

   IF ::lISAM

      ::aInfo[SR_AINFO_BOF_AT] := 0
      ::aInfo[SR_AINFO_EOF_AT] := 0

      IF !( ::aInfo[SR_AINFO_EOF] .AND. ::aInfo[SR_AINFO_BOF])
         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
         ::aInfo[SR_AINFO_NPOSCACHE] := 1
         ACopy(::aLocalBuffer, ::aCache[1])
      ELSE
         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
         ::aInfo[SR_AINFO_NPOSCACHE] := 0
      ENDIF

      FOR i := 1 TO Len(::aIndex)
         ::aIndex[i, SR_AINDEX_ORDER_SKIP_UP] := NIL
         ::aIndex[i, SR_AINDEX_ORDER_SKIP_DOWN] := NIL
      NEXT i

   ELSE

      ::IniFields(.T., .T.)

      // Load the cache to ::aCache

      ASize(::aCache, SR_ARRAY_BLOCK2)
      nAllocated := SR_ARRAY_BLOCK2
      n := 0

      IF ::hnRecno == NIL
         ::hnRecno := ::nFields + 1
         ::nFields ++
         ::lCanUpd := .F.
         ::lCanIns := .F.
         ::lCanDel := .F.
         lRecnoAdded := .T.
         AAdd(::aNames, ::cRecnoName)
         AAdd(::aFields, {::cRecnoName, "N", 15, 0})
         AAdd(::aEmptyBuffer, 0)
      ENDIF

      DO WHILE (::oSql:Fetch(, .F., ::aFields)) == SQL_SUCCESS
         n ++
         IF n > nAllocated
            SWITCH nAllocated
            CASE SR_ARRAY_BLOCK2
               nAllocated := SR_ARRAY_BLOCK3
               EXIT
            CASE SR_ARRAY_BLOCK3
               nAllocated := SR_ARRAY_BLOCK4
               EXIT
            CASE SR_ARRAY_BLOCK4
               nAllocated := SR_ARRAY_BLOCK5
               EXIT
            SR_OTHERWISE
               nAllocated += SR_ARRAY_BLOCK5
            ENDSWITCH

            ASize(::aCache, nAllocated)
         ENDIF

         ::aCache[n] := Array(::nFields)

         FOR i := 1 TO ::nFields
            IF lRecnoAdded .AND. i == ::nFields
               ::aCache[n, i] := n
               nMax := n
            ELSE
               ::aCache[n, i] := ::oSql:FieldGet(i, ::aFields, .F.)
            ENDIF
            IF !lRecnoAdded .AND. i == ::hnRecno
               nMax := Max(nMax, ::aCache[n, i])
            ENDIF
         NEXT i
      ENDDO

      ASize(::aCache, n)
      ::nLastRec := nMax
      ::aInfo[SR_AINFO_NPOSCACHE] := Min(::aInfo[SR_AINFO_NPOSCACHE], Len(::aCache))
      ::aInfo[SR_AINFO_FCOUNT] := ::nFields
      ::aInfo[SR_AINFO_FOUND] := .F.
      ::aInfo[SR_AINFO_RCOUNT] := nMax

      ::Default()

   ENDIF

   ::LineCount()
   ::nLastRefresh := Seconds()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:GetBuffer(lClean, nCache)

   DEFAULT lClean TO .F.
   DEFAULT nCache TO ::aInfo[SR_AINFO_NPOSCACHE]

   IF Len(::aLocalBuffer) < ::nFields
      ASize(::aLocalBuffer, ::nFields)
   ENDIF

   IF !lClean .AND. (nCache == 0 .OR. Len(::aCache) == 0 .OR. nCache > Len(::aCache) .OR. Len(::aCache[nCache]) < ::nFields)
      lClean := .T.
   ENDIF

   IF !lClean
      IF ::lISAM
         ACopy(::aCache[nCache], ::aLocalBuffer)
         ::aInfo[SR_AINFO_RECNO] := ::aCache[nCache, ::hnRecno]
      ELSE
         ACopy(::aCache[nCache], ::aLocalBuffer)
         IF ::hnRecno != NIL .AND. ::hnRecno != 0
            ::aInfo[SR_AINFO_RECNO] := ::aCache[nCache, ::hnRecno]
         ELSE
            ::aInfo[SR_AINFO_RECNO] := nCache
         ENDIF
         ::aInfo[SR_AINFO_NPOSCACHE] := nCache
      ENDIF
      IF ::hnDeleted > 0 .AND. ::aLocalBuffer[::hnDeleted] != NIL
         ::aInfo[SR_AINFO_DELETED] := ::aLocalBuffer[::hnDeleted] $ "T*"
      ELSE
         ::aInfo[SR_AINFO_DELETED] := .F.
      ENDIF
   ELSE
      AEval(::aLocalBuffer, {|x, i|HB_SYMBOL_UNUSED(x), ::aLocalBuffer[i] := ::aEmptyBuffer[i]})
      IF !::lISAM
         ::aInfo[SR_AINFO_NPOSCACHE] := Len(::aCache) + 1
      ENDIF
      ::aInfo[SR_AINFO_DELETED] := .F.
      ::aInfo[SR_AINFO_RECNO] := ::aInfo[SR_AINFO_RCOUNT] + 1
      ::aInfo[SR_AINFO_EOF] := .T.
   ENDIF

   // Take a picture of the buffer

   IF Len(::aOldBuffer) == 0
      ASize(::aOldBuffer, Len(::aLocalBuffer))
   ENDIF

   ACopy(::aLocalBuffer, ::aOldBuffer)

RETURN ::aLocalBuffer

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:IniFields(lReSelect, lLoadCache, aInfo)

   LOCAL cName
   LOCAL n
   LOCAL cWhere
   LOCAL lHaveInfoCache
   LOCAL aML
   LOCAL aFlds := {}
#ifdef SQLRDD_TOPCONN
   LOCAL nPos
#endif

   DEFAULT lLoadCache TO .F.

   lHaveInfoCache := aInfo != NIL .AND. aInfo[SR_CACHEINFO_AFIELDS] != NIL

   IF !::lISAM
      IF Empty(::cCustomSQL)
         ::cFltUsr := ::SolveSQLFilters("A")
         cWhere := ::SolveRestrictors()
         IF !Empty(cWhere)
            cWhere := " WHERE " + cWhere
         ENDIF
      ENDIF
   ENDIF

   ::hnRecno := 0
   ::hnDeleted := 0
   ::aIniFields := {}

   IF ::oSql:oSqlTransact == NIL .OR. (!::lISAM)
      ::aFields := ::oSql:IniFields(lReSelect, ::cQualifiedTableName, ::cCustomSQL, lLoadCache, cWhere, ::cRecnoName, ::cDeletedName)
   ELSE
      ::aFields := ::oSql:oSqlTransact:IniFields(lReSelect, ::cQualifiedTableName, ::cCustomSQL, lLoadCache, cWhere, ::cRecnoName, ::cDeletedName)
      ::oSql:oSqlTransact:Commit()
   ENDIF

   IF ::aFields == NIL
      RETURN NIL
   ENDIF

   ::nFields := Len(::aFields)
   ::aInfo[SR_AINFO_FCOUNT] := ::nFields
   ::aNames := Array(::nFields)
   ::aNamesLower := Array(::nFields)

   ASize(::aEmptyBuffer, ::nFields)
   ASize(::aSelectList, ::nFields)
   aFill(::aSelectList, 0)

   IF !::lISAM
      ASize(::aLocalBuffer, ::nFields)
   ENDIF

#ifdef SQLRDD_TOPCONN

   IF ::oSQL:nTCCompat > 0

      nPos := hb_HPos(::oSql:aFieldModifier, ::cFileName)

      IF nPos > 0
#ifdef __XHARBOUR__
         aFlds := HGETVALUEAT(::oSql:aFieldModifier, nPos)
#else
         aFlds := hb_HValueAt(::oSql:aFieldModifier, nPos)
#endif
      ENDIF

      FOR n := 1 TO ::nFields
         cName := Upper(AllTrim(::aFields[n, SR_FIELD_NAME]))
         ASize(::aFields[n], SR_FIELD_INFO_SIZE)
         ::aFields[n, SR_FIELD_MULTILANG] := .F.
         ::aFields[n, SR_FIELD_ENUM] := n
         ::aFields[n, SR_FIELD_WAOFFSET] := 0

         IF ::aFields[n, SR_FIELD_TYPE] == "M" .AND. SR_SetMultiLang()
            aML := SR_GetMLHash(::cFileName, ::aFields[n, SR_FIELD_NAME])
            IF aML != NIL
               ::aFields[n, SR_FIELD_TYPE] := aML[3]
               ::aFields[n, SR_FIELD_LEN] := Val(aML[4])
               ::aFields[n, SR_FIELD_MULTILANG] := .T.
            ENDIF
         ENDIF

         IF cName == ::cRecnoName .OR. cName == "SR_RECNO"
            ::hnRecno := n
            IF ::cRecnoName != SR_RecnoName() .OR. !SR_SetHideRecno()
               AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
               ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
            ENDIF
         ELSEIF cName == ::cDeletedName
            ::hnDeleted := n
            ::aFields[n, SR_FIELD_NULLABLE] := .F. // NOT NULL
         ELSEIF cName == "DT__HIST" .AND. ::lISAM
            ::nPosDtHist := n
            ::lHistoric := .T.

            IF !SR_SetHideHistoric()
               AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
               ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
            ENDIF
         ELSEIF cName == ::cColPK
            ::nPosColPK := n
            AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
            ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
         ELSEIF SubStr(cName, 1, 7) == "INDKEY_" .OR. SubStr(cName, 1, 7) == "INDFOR_"
            // Ignore these columns
         ELSEIF cName == "R_E_C_N_O_"
            ::cRecnoName := "R_E_C_N_O_"
            ::hnRecno := n
            ::nTCCompat := 2
            IF ::cRecnoName != SR_RecnoName() .OR. !SR_SetHideRecno()
               AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
               ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
            ENDIF
            // Fix record numbering to work like TopConnect
            SR_SetNextRecordBlock({|oWA|SR_TCNextRecord(oWA)})
            ::lUseSequences := .F.
         ELSEIF cName == "D_E_L_E_T_"
            ::cDeletedName := "D_E_L_E_T_"
            ::hnDeleted := n
         ELSEIF cName == "R_E_C_D_E_L_"
            ::nTCCompat := 4
            // Ignore this column
         ELSE
            nPos := AScan(aFlds, {|x|Upper(AllTrim(x[1])) == cName})
            IF nPos > 0
               IF aFlds[nPos, 2] == "P"
                  ::aFields[n, SR_FIELD_TYPE] := "N"
                  ::aFields[n, SR_FIELD_LEN] := Val(aFlds[nPos, 3])
                  ::aFields[n, SR_FIELD_DEC] := Val(aFlds[nPos, 4])
                  ::aFields[n, SR_FIELD_DOMAIN] := SQL_FAKE_NUM
               ELSEIF aFlds[nPos, 2] == "D"
                  IF ::aFields[n, SR_FIELD_TYPE] != "D"
                     ::aFields[n, SR_FIELD_TYPE] := "D"
                     ::aFields[n, SR_FIELD_LEN] := 8
                     ::aFields[n, SR_FIELD_DOMAIN] := SQL_FAKE_DATE
                  ENDIF
               ENDIF
            ENDIF
            AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
            ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
         ENDIF

         ::aNames[n] := cName

         IF ::aFields[n, SR_FIELD_MULTILANG] .AND. SR_SetMultiLang()
            ::aEmptyBuffer[n] := hb_Hash()
         ELSE
            ::aEmptyBuffer[n] := SR_BlankVar(::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC])
         ENDIF

      NEXT n

      IF ::nTCCompat > 0
         FOR n := 1 TO ::nFields
            ::aFields[n, SR_FIELD_NULLABLE] := .F.
         NEXT n
      ENDIF

   ELSE

#endif

      FOR n := 1 TO ::nFields
         cName := ::aFields[n, SR_FIELD_NAME]
         ASize(::aFields[n], SR_FIELD_INFO_SIZE)
         ::aFields[n, SR_FIELD_MULTILANG] := .F.
         ::aFields[n, SR_FIELD_ENUM] := n
         ::aFields[n, SR_FIELD_WAOFFSET] := 0

         IF ::aFields[n, SR_FIELD_TYPE] == "M" .AND. SR_SetMultiLang()
            aML := SR_GetMLHash(::cFileName, ::aFields[n, SR_FIELD_NAME])
            IF aML != NIL
               ::aFields[n, SR_FIELD_TYPE] := aML[3]
               ::aFields[n, SR_FIELD_LEN] := Val(aML[4])
               ::aFields[n, SR_FIELD_MULTILANG] := .T.
            ENDIF
         ENDIF

         IF cName == ::cRecnoName .OR. cName == "SR_RECNO"
            ::cRecnoName := cName
            ::hnRecno := n
            IF ::cRecnoName != SR_RecnoName() .OR. !SR_SetHideRecno()
               AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
               ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
            ENDIF
         ELSEIF cName == ::cDeletedName
            ::hnDeleted := n
            ::aFields[n, SR_FIELD_NULLABLE] := .F. // NOT NULL
         ELSEIF cName == "DT__HIST" .AND. ::lISAM
            ::nPosDtHist := n
            ::lHistoric := .T.

            IF !SR_SetHideHistoric()
               AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
               ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
            ENDIF
         ELSEIF cName == ::cColPK
            ::nPosColPK := n
            AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
            ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
         ELSEIF SubStr(cName, 1, 7) == "INDKEY_" .OR. SubStr(cName, 1, 7) == "INDFOR_"
            // Ignore these columns
            // Culik are we in sqlex? if yes, we need to return this fields to query also
            IF RDDNAME() == "SQLEX"
               AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
               ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
            ENDIF

         ELSE
            AAdd(::aIniFields, {::aFields[n, SR_FIELD_NAME], ::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC], n})
            ::aFields[n, SR_FIELD_WAOFFSET] := Len(::aIniFields)
         ENDIF

         ::aNames[n] := cName

         IF ::aFields[n, SR_FIELD_MULTILANG] .AND. SR_SetMultiLang()
            ::aEmptyBuffer[n] := hb_Hash()
         ELSE
            ::aEmptyBuffer[n] := SR_BlankVar(::aFields[n, SR_FIELD_TYPE], ::aFields[n, SR_FIELD_LEN], ::aFields[n, SR_FIELD_DEC])
         ENDIF

      NEXT n

#ifdef SQLRDD_TOPCONN

   ENDIF

#endif

   IF ::lHistoric .AND. ::nPosColPK == NIL
      ::nPosColPK := ::hnRecno
      ::cColPK := ::cRecnoName
   ENDIF

   IF ::hnRecno == NIL .AND. ::lISAM
      // Let's try some *magic*

      aFlds := {}

      SWITCH ::oSQL:nSystemID
      CASE SQLRDD_RDBMS_IBMDB2
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
      CASE SQLRDD_RDBMS_SYBASE
         EXIT
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_AZURE
         ::oSql:Exec("sp_pkeys " + ::cFileName, .T., .T., @aFlds)
         IF Len(aFlds) == 1
            ::hnRecno := AScan(::aFields, {|x|x[1] == AllTrim(Upper(aflds[1, 4]))})
            ::cRecnoName := aflds[1, 4]
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_ORACLE // TODO: unnecessary
      CASE SQLRDD_RDBMS_POSTGR // TODO: unnecessary
      ENDSWITCH

      IF Empty(::hnRecno)
         ::RuntimeErr("24", SR_Msg(24) + ::cRecnoName  + " / " + ::cFileName)
      ENDIF
   ENDIF

   IF !lHaveInfoCache .AND. aInfo != NIL
      aInfo[SR_CACHEINFO_AFIELDS] := AClone(::aFields)
      aInfo[SR_CACHEINFO_ANAMES] := AClone(::aNames)
      aInfo[SR_CACHEINFO_ABLANK] := AClone(::aEmptyBuffer)
      aInfo[SR_CACHEINFO_HNRECNO] := ::hnRecno
      aInfo[SR_CACHEINFO_HNDELETED] := ::hnDeleted
      aInfo[SR_CACHEINFO_INIFIELDS] := AClone(::aIniFields)
      aInfo[SR_CACHEINFO_HNPOSDTHIST] := ::nPosDtHist
      aInfo[SR_CACHEINFO_HNCOLPK] := ::nPosColPK
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlGoBottom()

   LOCAL cJoin1
   LOCAL cJoin3
   LOCAL cTemp := ""
   LOCAL i

   IF ::lCollectingBehavior
      FOR EACH i IN ::aSelectList
         IF i == 1
            ::lCollectingBehavior := .F.
            EXIT
         ENDIF
      NEXT
   ENDIF

   ::aInfo[SR_AINFO_DETECT1_COUNT] := 0

   IF ::lISAM

      cJoin1 := " " + ::cQualifiedTableName + " A "
      cJoin3 := ::GetSelectList()
      ::aInfo[SR_AINFO_SKIPCOUNT] := 0

      IF !Empty(cTemp := ::SolveRestrictors())
         cTemp := " WHERE " + cTemp
      ENDIF

      ::ResetStatistics()

      IF ::aInfo[SR_AINFO_INDEXORD] > 0 .AND. ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] != NIL
         cTemp += IIf(" WHERE " $ cTemp, " AND ", " WHERE ") + "(" + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_EXPR] + " <= 'zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzz' AND ROWNUM <= " + Str(::nCurrentFetch+1) + ") "
         ::oSql:Execute('SELECT /*+ INDEX( A D$' + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] + ") */ " + cJoin3 + "FROM" + cJoin1 + cTemp + IIf(::oSql:lComments, " /* GoBottom */", ""))
      ELSE
         ::oSql:Execute("SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1 + cTemp + ::OrderBy(NIL, .F.) + Eval(::Optmizer_ne, ::nCurrentFetch) + IIf(::oSql:lComments, " /* GoBottom */", ""))
      ENDIF

      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0

      ::FirstFetch(SR_ORD_DIR_BWD)
      ::oSql:FreeStatement()

      IF !::lNoData
         ::aInfo[SR_AINFO_EOF_AT] := ::aLocalBuffer[::hnRecno]
      ENDIF

      IF ::lEmptyTable .OR. ::lNoData
         ::aInfo[SR_AINFO_BOF] := .T.
         ::aInfo[SR_AINFO_EOF] := .T.
      ELSE
         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_EOF] := .F.
         ::aInfo[SR_AINFO_NPOSCACHE] := (SR_CACHE_PAGE_SIZE * 3)
      ENDIF

   ELSE

      IF ::lNoData
         RETURN NIL
      ELSE
         ::Stabilize()
         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_EOF] := .F.
      ENDIF

      IF !::aInfo[SR_AINFO_REVERSE_INDEX]
         ::GetBuffer(.F., Len(::aCache))
         ::Normalize(-1)
      ELSE
         ::GetBuffer(.F., 1)
         ::Normalize(1)
      ENDIF

   ENDIF

   IF ::hnDeleted > 0 .AND. ::aLocalBuffer[::hnDeleted] != NIL
     ::aInfo[SR_AINFO_DELETED] := ::aLocalBuffer[::hnDeleted] $ "T*"
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlGoCold()

   IF ::aInfo[SR_AINFO_HOT] .AND. IIf(::hnDeleted > 0, .T.,  !::aInfo[SR_AINFO_DELETED])
      ::WriteBuffer(::aInfo[SR_AINFO_ISINSERT], ::aLocalBuffer)
   ENDIF

RETURN .F.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlGoTo(uRecord, lNoOptimize)

   LOCAL nCache
   LOCAL cGoTo
   LOCAL i
   LOCAL cJoin1
   LOCAL cJoin3

   DEFAULT lNoOptimize TO .F.

   ::aInfo[SR_AINFO_FOUND] := .F.

   IF ::lCollectingBehavior
      FOR EACH i IN ::aSelectList
         IF i == 1
            ::lCollectingBehavior := .F.
            EXIT
         ENDIF
      NEXT
   ENDIF

   // Optimizing DBGoTo(RecNo())

   IF !lNoOptimize .AND. (uRecord == ::aInfo[SR_AINFO_RECNO] .AND. !::aInfo[SR_AINFO_ISINSERT] .AND. !( ::aInfo[SR_AINFO_BOF] .AND. ::aInfo[SR_AINFO_EOF]))
      // ::aInfo[SR_AINFO_EOF] := .F.
      ::aInfo[SR_AINFO_BOF] := .F.
      RETURN NIL
   ENDIF

   ::aInfo[SR_AINFO_SKIPCOUNT] := 0
   ::aInfo[SR_AINFO_DETECT1_COUNT] := 0

   IF Empty(uRecord) .OR. ( HB_IsNumeric(uRecord) .AND. uRecord == LASTREC_POS + 1)
      ::GetBuffer(.T.)
      IF ::aInfo[SR_AINFO_ISINSERT]
         ::aInfo[SR_AINFO_RECNO] := ::GetNextRecordNumber()
         ::aLocalBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
      ENDIF
      ::aInfo[SR_AINFO_BOF] := .T. // Bug fixed in feb 2009, BOF should be TRUE as well as EOF
                                // if DBGoTo(invalidRecord)
      RETURN NIL
   ELSE
      IF ::lISAM

         IF ::aInfo[SR_AINFO_NCACHEBEGIN] > 0 .AND. ::aInfo[SR_AINFO_BOF_AT] > 0 .AND. ::aCache[::aInfo[SR_AINFO_NCACHEBEGIN]] != NIL .AND. Len(::aCache[::aInfo[SR_AINFO_NCACHEBEGIN]]) > 0
            IF ::aCache[::aInfo[SR_AINFO_NCACHEBEGIN], ::hnRecno] == uRecord
               ::aInfo[SR_AINFO_NPOSCACHE] := ::aInfo[SR_AINFO_NCACHEBEGIN]
               ::GetBuffer()
               ::aInfo[SR_AINFO_EOF] := .F.
               ::aInfo[SR_AINFO_BOF] := .F.
               RETURN NIL
            ENDIF
         ENDIF

         cJoin1 := " " + ::cQualifiedTableName + " A "
         cJoin3 := ::GetSelectList()
         cGoTo := "SELECT" + ::Optmizer_1s + cJoin3 + "FROM" + cJoin1 + " WHERE A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = "

         ::oSql:Execute(cGoTo + ::Quoted(uRecord, , 18, 0) + " " + IIf(::oSql:lComments, " /* GoTo */", ""))
         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
         ::aInfo[SR_AINFO_NPOSCACHE] := 0

         ::FirstFetch()
         ::oSql:FreeStatement()

         IF ::lNoData
            IF SR_ErrorOnGotoToInvalidRecord()
               ::RuntimeErr("6", SR_Msg(6) + ::Quoted(uRecord, , 15, 0))
            ELSE
               ::GetBuffer(.T.)
               ::aInfo[SR_AINFO_BOF] := .T. // Bug fixed in feb 2009, BOF should be TRUE as well as EOF
                                         // if DBGoTo(invalidRecord)
            ENDIF
         ELSE
            ::aInfo[SR_AINFO_EOF] := .F.
            ::aInfo[SR_AINFO_BOF] := .F.
         ENDIF
      ELSE
         nCache := AScan(::aCache, {|x|x[::hnRecno] == uRecord})
         IF nCache == 0 .AND. SR_ErrorOnGotoToInvalidRecord()
            ::RuntimeErr("6", SR_Msg(6) + ::Quoted(uRecord, , 15, 0))
         ELSE
            ::GetBuffer(.F., nCache)
            ::aInfo[SR_AINFO_EOF] := .F.
            ::aInfo[SR_AINFO_BOF] := .F.
         ENDIF
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlGoTop()

   LOCAL cJoin1
   LOCAL cJoin3
   LOCAL cTemp
   LOCAL i

   IF ::lCollectingBehavior
      FOR EACH i IN ::aSelectList
         IF i == 1
            ::lCollectingBehavior := .F.
            EXIT
         ENDIF
      NEXT
   ENDIF

   ::aInfo[SR_AINFO_DETECT1_COUNT] := 0

   IF ::lISAM
      cJoin1 := " " + ::cQualifiedTableName + " A "
      cJoin3 := ::GetSelectList()
      ::aInfo[SR_AINFO_SKIPCOUNT] := 0

      IF !Empty(cTemp := ::SolveRestrictors())
         cTemp := " WHERE " + cTemp
      ENDIF

      ::ResetStatistics()

      IF ::aInfo[SR_AINFO_INDEXORD] > 0 .AND. ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] != NIL
         cTemp += IIf(" WHERE " $ cTemp, " AND ", " WHERE ") + "(" + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_EXPR] + " >= ' ' AND ROWNUM <= " + Str(::nCurrentFetch+1) + ") "
         ::oSql:Execute('SELECT /*+ INDEX( A A$' + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] + ") */ " + cJoin3 + "FROM" + cJoin1 + cTemp + IIf(::oSql:lComments, " /* GoTop */", ""))
      ELSE
         ::oSql:Execute("SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1 + cTemp + ::OrderBy(NIL, .T.) + Eval(::Optmizer_ne, ::nCurrentFetch) + IIf(::oSql:lComments, " /* GoTop */", ""))
      ENDIF

      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0
      ::FirstFetch(SR_ORD_DIR_FWD)

      ::oSql:FreeStatement()

      IF !::lNoData
         ::aInfo[SR_AINFO_BOF_AT] := ::aLocalBuffer[::hnRecno]
      ENDIF

     IF ::lEmptyTable .OR. ::lNoData
         ::aInfo[SR_AINFO_BOF] := .T.
         ::aInfo[SR_AINFO_EOF] := .T.
      ELSE
         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_EOF] := .F.
         ::aInfo[SR_AINFO_NPOSCACHE] := 1
      ENDIF

   ELSE

      // ALL_IN_CACHE

      IF ::lNoData
         RETURN NIL
      ELSE
         ::Stabilize()
         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_EOF] := .F.
      ENDIF

      IF !::aInfo[SR_AINFO_REVERSE_INDEX]
         ::GetBuffer(.F., 1)
         ::Normalize(1)
      ELSE
         ::GetBuffer(.F., Len(::aCache))
         ::Normalize(-1)
      ENDIF

   ENDIF

   IF ::hnDeleted > 0 .AND. ::aLocalBuffer[::hnDeleted] != NIL
      ::aInfo[SR_AINFO_DELETED] := ::aLocalBuffer[::hnDeleted] $ "T*"
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlGoPhantom()

   ::sqlGoCold()
   ::GetBuffer(.T.)
   ::aInfo[SR_AINFO_FOUND] := .F.

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlSeek(uKey, lSoft, lLast)

   LOCAL nLenKey
   LOCAL cPart
   LOCAL nCons
   LOCAL nLen
   LOCAL i
   LOCAL j
   LOCAL cType
   LOCAL lPartialSeek := .F.
   LOCAL cRet := ""
   LOCAL nFDec
   LOCAL nFLen
   LOCAL nThis
   LOCAL cSep
   LOCAL cSql
   LOCAL cQot
   LOCAL cNam
   LOCAL nSimpl
   LOCAL nFeitos
   LOCAL aTemp
   LOCAL cTemp
   LOCAL cJoin1
   LOCAL cJoin3
   LOCAL lNull
   LOCAL uSet
   LOCAL cField
   LOCAL nfieldPos
   LOCAL lLikeSep := .F.
   LOCAL cKeyValue
   LOCAL aFld

   IF ::lCollectingBehavior
      FOR EACH i IN ::aSelectList
         IF i == 1
            ::lCollectingBehavior := .F.
            EXIT
         ENDIF
      NEXT
   ENDIF

   ::nPartialDateSeek := 0
   ::sqlGoCold()

   DEFAULT lSoft TO .F.

   ::aInfo[SR_AINFO_FOUND] := .F.
   ::aInfo[SR_AINFO_DETECT1_COUNT] := 0

   // reset static data

   ::aQuoted := {}
   ::aDat := {}
   ::aPosition := {}
   ::aSeekXF := {}

   IF ::lNoData .AND. (!::lISAM)
      RETURN NIL
   ENDIF

   IF ::aInfo[SR_AINFO_INDEXORD] == 0
      ::RuntimeErr("20")
      RETURN NIL
   ENDIF

   ::aInfo[SR_AINFO_SKIPCOUNT] := 0
   uSet := Set(_SET_EXACT, .F.)

   IF lSoft .AND. ::lISAM .AND. ISORACLE() .AND. ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] != NIL .AND. HB_IsChar(uKey)

      nLen := Max(Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]) - 1, 1)      // Esse -1 � para remover o NRECNO que SEMPRE faz parte do indice !
      nCons := 0
      nLenKey := Len(uKey)
      //cPart := "" (unnecessary, cPart is used only inside the loop FOR/NEXT)

      FOR i := 1 TO nLen

         nThis := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_LEN]
         cPart := SubStr(uKey, nCons + 1, nThis)

         AAdd(::aPosition, ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2])

         cType := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_TYPE]
         lNull := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_NULLABLE]
         // unnecessary, the value is not used
         //nFDec := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_DEC]
         // unnecessary, the value is not used
         //nFLen := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_LEN]

         IF i == 1 .AND. nThis >= Len(uKey)
            IF uKey == ""
               EXIT
            ENDIF
         ELSE
            IF Len(cPart) == 0
               EXIT
            ENDIF
         ENDIF

         AAdd(::aQuoted, ::QuotedNull(::ConvType(cPart, cType, @lPartialSeek, nThis, ::aInfo[SR_AINFO_REVERSE_INDEX]), !lSoft, , , , lNull)) // Reverse Index should add % to end of string or seek will never find current record if partial
         AAdd(::aDat,    ::ConvType(IIf(lSoft, cPart, RTrim(cPart)), cType, , nThis))

         nCons += nThis

         IF nLenKey < nCons
            EXIT
         ENDIF

      NEXT i

      cJoin1 := " " + ::cQualifiedTableName + " A "
      cJoin3 := ::GetSelectList()

      IF ::aInfo[SR_AINFO_REVERSE_INDEX] .OR. lLast
         cSql := 'SELECT /*+ INDEX( A ' + 'D$' + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] + ") */ " + cJoin3 + "FROM" + cJoin1 + ::WhereVMinor( uKey ) + " AND ROWNUM <= 1"
      ELSE
         cSql := 'SELECT /*+ INDEX( A ' + 'A$' + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] + ") */ " + cJoin3 + "FROM" + cJoin1 + ::WhereVMajor( uKey ) + " AND ROWNUM <= 1"
      ENDIF

      ::oSql:Execute(cSql + IIf(::oSql:lComments, " /* SoftSeek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */", ""))

      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0
      ::FirstFetch()

      IF ::lNoData .OR. ::aInfo[SR_AINFO_EOF]
         ::aInfo[SR_AINFO_EOF] := .T.
         ::aInfo[SR_AINFO_FOUND] := .F.
      ELSE

         IF HB_IsChar(uKey) .AND. uKey == ""
            ::aInfo[SR_AINFO_FOUND] := .T.
         ELSE
            FOR i := 1 TO Len(::aQuoted)
               DO CASE
               CASE HB_IsChar(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i]) .AND. (ISMSSQL7() .OR. ( ISMYSQL() .OR. ISMARIADB()) .OR. ISAZURE())
                  ::aInfo[SR_AINFO_FOUND] := (Upper(::aLocalBuffer[::aPosition[i]]) = Upper(::aDat[i]))
               CASE HB_IsNumeric(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = Val(::aDat[i]))
               CASE HB_IsChar(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsNumeric(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = Str(::aDat[i]))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = SToD(::aDat[i]))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDate(::aDat[i]) .AND. ::nPartialDateSeek > 0 .AND. i == Len(::aQuoted)
                  ::aInfo[SR_AINFO_FOUND] := (Left(DToS(::aLocalBuffer[::aPosition[i]]), ::nPartialDateSeek) == Left(DToS(::aDat[i]), ::nPartialDateSeek))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDate(::aDat[i]) .AND. ::nPartialDateSeek == 0 .AND. i == Len(::aQuoted) .AND. lsoft
                  ::aInfo[SR_AINFO_FOUND] := (DToS(::aLocalBuffer[::aPosition[i]]) >= DToS(::aDat[i]))
               CASE HB_IsDateTime(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDateTime(::aDat[i]) .AND. ::nPartialDateSeek > 0 .AND. i == Len(::aQuoted)
                  ::aInfo[SR_AINFO_FOUND] := (Left(hb_ttos(::aLocalBuffer[::aPosition[i]]), ::nPartialDateSeek) == Left(hb_ttos(::aDat[i]), ::nPartialDateSeek))
               CASE HB_IsDateTime(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDateTime(::aDat[i]) .AND. ::nPartialDateSeek == 0 .AND. i == Len(::aQuoted) .AND. lsoft
                  ::aInfo[SR_AINFO_FOUND] := (hb_ttos(::aLocalBuffer[::aPosition[i]]) >=  hb_ttos(::aDat[i]))
               CASE ValType(::aLocalBuffer[::aPosition[i]]) != ValType(::aDat[i])
                  ::RuntimeErr("28")
                  Set(_SET_EXACT, uSet)
                  RETURN NIL
               OTHERWISE
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = ::aDat[i])
               ENDCASE

               IF !::aInfo[SR_AINFO_FOUND]
                  EXIT
               ENDIF
            NEXT i
         ENDIF
      ENDIF

      IF ::aInfo[SR_AINFO_FOUND]
         ::aInfo[SR_AINFO_EOF] := .F.
         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_RECNO] := ::aLocalBuffer[::hnRecno]
      ELSE
         ::aInfo[SR_AINFO_FOUND] := .F.
         IF lSoft .AND. ::lNoData
            ::GetBuffer(.T.)
            ::aInfo[SR_AINFO_RECNO] := ::aInfo[SR_AINFO_RCOUNT] + 1
            ::aLocalBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
         ELSEIF lSoft
            ::aInfo[SR_AINFO_EOF] := .F.
            ::aInfo[SR_AINFO_RECNO] := ::aLocalBuffer[::hnRecno]
         ELSE
            ::GetBuffer(.T.)
            ::aInfo[SR_AINFO_RECNO] := ::aInfo[SR_AINFO_RCOUNT] + 1
            ::aLocalBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
         ENDIF
      ENDIF

      ::oSql:FreeStatement()

   ELSEIF ::lISAM .AND. ::oSql:nSystemID != SQLRDD_RDBMS_POSTGR

      SWITCH ValType(uKey)

      CASE "N"
      CASE "D"
      CASE "L"
      CASE "T"

         lNull := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2], SR_FIELD_NULLABLE]
         nFDec := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2], SR_FIELD_DEC]
         nFLen := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2], SR_FIELD_LEN]

         cRet := " WHERE (( "

         IF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2] == ::hnDeleted .AND. HB_IsLogical(uKey)
            IF ::nTCCompat > 0
               cQot := IIf(uKey, "'*'", "' '")
               AAdd(::aDat, IIf(uKey, "*", " "))
            ELSE
               cQot := IIf(uKey, "'T'", "' '")
               AAdd(::aDat, IIf(uKey, "T", " "))
            ENDIF
         ELSE
            IF "INDKEY_" $ ::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2]] .AND. HB_IsNumeric(uKey)
               cField :=  Upper(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_KEY])
               IF "VAL(" $ CFIELD
                  CfIELD := StrTran(CfIELD, "VAL(", "")
                  CfIELD := StrTran(CfIELD, ")", "")
                  nfieldPos := AScan(::aFields, {|x|x[1] == cField})
                  IF nFieldPos >0
                     cKeyValue := Str(uKey, ::aFields[nFieldPos, SR_FIELD_LEN]) + "%"
                     lLikeSep := .T.
                  ENDIF
               ENDIF
            ENDIF
            IF !Empty(cKeyValue)
               cQot := ::QuotedNull(cKeyValue, , nFLen, nFDec, , lNull)
            ELSE
               cQot := ::QuotedNull(uKey, , nFLen, nFDec, , lNull)
            ENDIF
            IF lLikeSep
               AAdd(::aDat, Str(uKey, ::aFields[nFieldPos, SR_FIELD_LEN]))
            ELSE
               AAdd(::aDat, uKey)
            ENDIF
         ENDIF

         IF ::aInfo[SR_AINFO_REVERSE_INDEX] .OR. lLast
            cSep := IIf(cQot == "NULL", " IS ", IIf(lSoft, " <= ", IIf(lLikeSep, " Like ", " = ")))
         ELSE
            cSep := IIf(cQot == "NULL", " IS ", IIf(lSoft, " >= ", IIf(lLikeSep, " Like ", " = ")))
         ENDIF
         cNam := "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2]], ::oSql:nSystemID)

         AAdd(::aPosition, ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2])
         AAdd(::aQuoted, ::Quoted(uKey))

         // If Null, we don't need WHERE clause on Soft Seeks
         IF !IsNull(cQot) .OR. !lSoft
            cRet += cNam + cSep + cQot + " "
         ENDIF

         EXIT

      CASE "C"

         nLen := Max(Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]) - 1, 1)      // Esse -1 � para remover o NRECNO que SEMPRE faz parte do indice !
         nCons := 0
         nLenKey := Len(uKey)
         //cPart := "" (unnecessary, cPart is used only inside the loop FOR/NEXT)

         FOR i := 1 TO nLen

            nThis := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_LEN]
            cPart := SubStr(uKey, nCons + 1, nThis)

            AAdd(::aPosition, ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2])

            cType := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_TYPE]
            lNull := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_NULLABLE]
            // unnecessary, the value is not used
            //nFDec := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_DEC]
            // unnecessary, the value is not used
            //nFLen := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_LEN]

            IF i == 1 .AND. nThis >= Len(uKey)
               IF uKey == ""
                  EXIT
               ENDIF
            ELSE
               IF Len(cPart) == 0
                  EXIT
               ENDIF
            ENDIF

            AAdd(::aQuoted, ::QuotedNull(::ConvType(cPart, cType, @lPartialSeek, nThis, ::aInfo[SR_AINFO_REVERSE_INDEX]), !lSoft, , , , lNull)) // Reverse Index should add % to end of string or seek will never find current record if partial
            AAdd(::aDat,    ::ConvType(IIf(lSoft, cPart, RTrim(cPart)), cType, , nThis))

            nCons += nThis

            IF nLenKey < nCons
               EXIT
            ENDIF

         NEXT i

         cRet := " WHERE (( "
         nLen := Min(nLen, Len(::aQuoted))

         IF lSoft
            nSimpl := nLen
         ELSE
            nSimpl := 1
         ENDIF

         FOR j := 1 TO nSimpl

            IF j >= 2
               cRet += e" ) OR \r\n ( "
            ENDIF

            nFeitos := 0

            FOR i := 1 TO (nLen - j + 1)

               cQot := ::aQuoted[i]
               cNam := "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]], ::oSql:nSystemID)

               IF lPartialSeek .AND. i == nLen
                  IF ::aInfo[SR_AINFO_REVERSE_INDEX]
                     cSep := IIf(lSoft, IIf(j == 1, " <= ", " < "), IIf(cQot == "NULL", " IS ", " LIKE "))
                  ELSEIF ::nPartialDateSeek > 0  // Partial date seek
                     cSep := IIf(j == 1, " >= ", " > ")
                  ELSE
                     cSep := IIf(lSoft, IIf(j == 1, " >= ", " > "), IIf(cQot == "NULL", " IS ", " LIKE "))
                     IF cQot != "NULL" .AND. !lSoft .AND. !("TO_DATE(" $ cQot)
                        cTemp := SubStr(cQot, 1, Len(cQot) - 1)
                        SWITCH ::oSql:nSystemID
                        CASE SQLRDD_RDBMS_MSSQL7
                        CASE SQLRDD_RDBMS_AZURE
                           cTemp := StrTran(cTemp, "%", "!%")
                           EXIT
                        CASE SQLRDD_RDBMS_MYSQL
                        CASE SQLRDD_RDBMS_MARIADB
                           cTemp := StrTran(cTemp, "%", "\%")
                           cTemp := StrTran(cTemp, "_", "\_")
                        ENDSWITCH
                        cQot := cTemp + "%'"
                     ENDIF
                  ENDIF
               ELSE
                  IF ::aInfo[SR_AINFO_REVERSE_INDEX] .OR. lLast
                     cSep := IIf(lSoft, IIf(i != nLen - j + 1 .OR. j == 1, " <= ", " < "), IIf(cQot == "NULL", " IS ", " = "))
                  ELSE
                     cSep := IIf(lSoft, IIf(i != nLen - j + 1 .OR. j == 1, " >= ", " > "), IIf(cQot == "NULL", " IS ", " = "))
                  ENDIF
               ENDIF

               // When using >=, If the quoted value is NULL, this column does't mind to this query.

               IF (cSep == " >= " .OR. cSep == " <= " ) .AND. IsNull(::aQuoted[i])
                  LOOP
               ENDIF

               IF cSep == " > " .AND. ::aQuoted[i] == "NULL"
                  cSep := " IS NOT "
               ELSEIF cSep == " < " .AND. ::aQuoted[i] == "NULL"
                  LOOP        // ToDo: less than NULL does not exist (or negative if numeric field)
               ENDIF

               nFeitos ++

               cRet += IIf(nFeitos > 1, " AND ", "") + cNam + cSep + cQot + IIf(cSep == " LIKE " .AND. (ISMSSQL7() .OR. ISAZURE()), " ESCAPE '!' ", " ")

            NEXT i

            IF j == 1 .AND. nFeitos == 0
               cRet := " WHERE (( 1 = 1 "
               EXIT
            ENDIF

         NEXT j

         EXIT

      SR_OTHERWISE

         ::RuntimeErr("26")
         Set(_SET_EXACT, uSet)
         RETURN NIL

      ENDSWITCH

      cTemp := ::SolveRestrictors()

      IF cRet == " WHERE (( "
         IF Empty(cTemp)
            cRet := ""
         ELSE
            cRet := " WHERE " + cTemp
         ENDIF
      ELSE
         cRet += ")) "
         IF !Empty(cTemp)
            cRet += " AND " + cTemp
         ENDIF
      ENDIF

      cJoin1 := " " + ::cQualifiedTableName + " A "
      cJoin3 := ::GetSelectList()

      IF ::lFetchAll
         //::oSql:Execute("SELECT" + Eval(::Optmizer_ns, Max(::nCurrentFetch, 50)) + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL,.T.) + Eval(::Optmizer_ne, Max(::nCurrentFetch, 50)) + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */",""))
         ::oSql:Execute("SELECT" + Eval(::Optmizer_ns, Max(::nCurrentFetch, 50)) + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL, IIf(lLast, .F., .T.)) + Eval(::Optmizer_ne, Max(::nCurrentFetch, 50)) + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */",""))
      ELSE
         //::oSql:Execute("SELECT" + ::Optmizer_1s + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL,.T.) + ::Optmizer_1e + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */",""))
         ::oSql:Execute("SELECT" + ::Optmizer_1s + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL, IIf(lLast, .F., .T.)) + ::Optmizer_1e + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */",""))
      ENDIF

      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0
      ::FirstFetch()

      IF ::lNoData .OR. ::aInfo[SR_AINFO_EOF]
         ::aInfo[SR_AINFO_EOF] := .T.
         ::aInfo[SR_AINFO_FOUND] := .F.
      ELSE

         IF HB_IsChar(uKey) .AND. uKey == ""
            ::aInfo[SR_AINFO_FOUND] := .T.
         ELSE
            FOR i := 1 TO Len(::aQuoted)
               DO CASE
               CASE HB_IsChar(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i]) .AND. (ISMSSQL7() .OR. (ISMYSQL() .OR. ISMARIADB()) .OR. ISAZURE())
                  ::aInfo[SR_AINFO_FOUND] := (Upper(::aLocalBuffer[::aPosition[i]]) = Upper(::aDat[i]))
               CASE HB_IsNumeric(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = Val(::aDat[i]))
               CASE HB_IsChar(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsNumeric(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = Str(::aDat[i]))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = SToD(::aDat[i]))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDate(::aDat[i]) .AND. ::nPartialDateSeek > 0 .AND. i == Len(::aQuoted)
                  ::aInfo[SR_AINFO_FOUND] := (Left(DToS(::aLocalBuffer[::aPosition[i]]), ::nPartialDateSeek) == Left(DToS(::aDat[i]), ::nPartialDateSeek))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDate(::aDat[i]) .AND. ::nPartialDateSeek == 0 .AND. i == Len(::aQuoted) .AND. lsoft
                  ::aInfo[SR_AINFO_FOUND] := (DToS(::aLocalBuffer[::aPosition[i]]) >= DToS(::aDat[i]))
               CASE HB_IsDateTime(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDateTime(::aDat[i]) .AND. ::nPartialDateSeek > 0 .AND. i == Len(::aQuoted)
                  ::aInfo[SR_AINFO_FOUND] := (Left(hb_ttos(::aLocalBuffer[::aPosition[i]]), ::nPartialDateSeek) == Left(hb_ttos(::aDat[i]), ::nPartialDateSeek))
               CASE HB_IsDateTime(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDateTime(::aDat[i]) .AND. ::nPartialDateSeek == 0 .AND. i == Len(::aQuoted) .AND. lsoft
                  ::aInfo[SR_AINFO_FOUND] := (hb_ttos(::aLocalBuffer[::aPosition[i]]) >= hb_ttos(::aDat[i]))
               CASE ValType(::aLocalBuffer[::aPosition[i]]) != ValType(::aDat[i])
                  ::RuntimeErr("28")
                  Set(_SET_EXACT, uSet)
                  RETURN NIL
               OTHERWISE
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = ::aDat[i])
               ENDCASE

               IF !::aInfo[SR_AINFO_FOUND]
                  EXIT
               ENDIF
            NEXT i
         ENDIF
      ENDIF

      IF ::aInfo[SR_AINFO_FOUND]
         ::aInfo[SR_AINFO_EOF] := .F. // 06/01/2004 - fixing skip after dbseek
         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_RECNO] := ::aLocalBuffer[::hnRecno]
      ELSE
         ::aInfo[SR_AINFO_FOUND] := .F.
         IF lSoft .AND. ::lNoData
            ::GetBuffer(.T.)
            ::aInfo[SR_AINFO_RECNO] := ::aInfo[SR_AINFO_RCOUNT] + 1
            ::aLocalBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
         ELSEIF lSoft
            ::aInfo[SR_AINFO_EOF] := .F.
            ::aInfo[SR_AINFO_RECNO] := ::aLocalBuffer[::hnRecno]
         ELSE
            ::GetBuffer(.T.)
            ::aInfo[SR_AINFO_RECNO] := ::aInfo[SR_AINFO_RCOUNT] + 1
            ::aLocalBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
         ENDIF
      ENDIF

      ::oSql:FreeStatement()

   ELSEIF ::lISAM .AND. ISPOSTGRESQL()

      SWITCH ValType(uKey)

      CASE "N"
      CASE "D"
      CASE "L"
      CASE "T"

         lNull := ::IndexFieldNul(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])
         nFDec := ::IndexFieldDec(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])
         nFLen := ::IndexFieldLen(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])

         cRet := " WHERE (( "

         IF "INDKEY_" $ ::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2]] .AND. HB_IsNumeric(uKey)
            cField :=  Upper(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_KEY])
            IF "VAL(" $ CFIELD
               CfIELD := StrTran(CfIELD, "VAL(", "")
               CfIELD := StrTran(CfIELD, ")", "")
               nfieldPos := AScan(::aFields, {|x|x[1] == cField})
               IF nFieldPos >0
                  cKeyValue := Str(uKey, ::aFields[nFieldPos, SR_FIELD_LEN]) + "%"
                  lLikeSep := .T.
               ENDIF
            ENDIF
         ENDIF
         IF !Empty(cKeyValue)
            cQot := ::QuotedNull(cKeyValue, , nFLen, nFDec, , lNull)
         ELSE
            cQot := ::QuotedNull(uKey, , nFLen, nFDec, , lNull)
         ENDIF

         IF ::aInfo[SR_AINFO_REVERSE_INDEX] .OR. lLast
            cSep := IIf(cQot == "NULL", " IS ", IIf(lSoft, " <= ", IIf(lLikeSep, " Like ", " = ")))
         ELSE
            cSep := IIf(cQot == "NULL", " IS ", IIf(lSoft, " >= ", IIf(lLikeSep, " Like ", " = ")))
         ENDIF

         cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])

         AAdd(::aPosition, ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1, 2])
         AAdd(::aQuoted, ::QuotedNull(uKey))
         AAdd(::aSeekXF, NIL)
         IF lLikeSep
            AAdd(::aDat, Str(uKey, ::aFields[nFieldPos, SR_FIELD_LEN]))
         ELSE
            AAdd(::aDat, uKey)
         ENDIF

         // If Null, we don't need WHERE clause on Soft Seeks
         // culik, we have an indkey_xxxx and seek value is number, we convert to string
         IF !IsNull(cQot) .OR. !lSoft
            cRet += cNam + cSep + cQot +  " "
         ENDIF

         cTemp := ::SolveRestrictors()

         IF cRet == " WHERE (( "
            IF Empty(cTemp)
               cRet := ""
            ELSE
               cRet := " WHERE " + cTemp
            ENDIF
         ELSE
            cRet += ")) "
            IF !Empty(cTemp)
               cRet += " AND " + cTemp
            ENDIF
         ENDIF

         cJoin1 := " " + ::cQualifiedTableName + " A "
         cJoin3 := ::GetSelectList()

         IF ::lFetchAll
            //::oSql:Execute("SELECT" + Eval(::Optmizer_ns, Max(::nCurrentFetch, 50)) + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL, .T.) + Eval(::Optmizer_ne, Max(::nCurrentFetch, 50)) + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */", ""))
            ::oSql:Execute("SELECT" + Eval(::Optmizer_ns, Max(::nCurrentFetch, 50)) + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL, IIf(lLast, .F., .T.)) + Eval(::Optmizer_ne, Max(::nCurrentFetch, 50)) + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */", ""))
         ELSE
            //::oSql:Execute("SELECT" + ::Optmizer_1s + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL, .T.) + ::Optmizer_1e + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */", ""))
            ::oSql:Execute("SELECT" + ::Optmizer_1s + cJoin3 + "FROM" + cJoin1 + cRet + ::OrderBy(NIL, IIf(lLast, .F., .T.)) + ::Optmizer_1e + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */",""))
         ENDIF

         EXIT

      CASE "C"

         nLen := Max(Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]) - 1, 1)      // Esse -1 � para remover o NRECNO que SEMPRE faz parte do indice !
         nCons := 0
         nLenKey := Len(uKey)
         //cPart := "" (unnecessary, cPart is used only inside the loop FOR/NEXT)

         FOR i := 1 TO nLen

            aFld := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]

            nThis := ::IndexFieldLen(aFld)
            cPart := SubStr(uKey, nCons + 1, nThis)

            AAdd(::aPosition, aFld[SR_IDXFLD_POS])

            IF Len(aFld) >= SR_IDXFLD_XFORM .AND. aFld[SR_IDXFLD_XFORM] != NIL
               AAdd(::aSeekXF, IdxBlkPad(aFld[SR_IDXFLD_XFORM], nThis))
            ELSE
               AAdd(::aSeekXF, NIL)
            ENDIF

            cType := ::IndexFieldType(aFld)
            // unnecessary, the value is not used
            //lNull := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_NULLABLE]
            // unnecessary, the value is not used
            //nFDec := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_DEC]
            // unnecessary, the value is not used
            //nFLen := ::aFields[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2], SR_FIELD_LEN]

            IF i == 1 .AND. nThis >= Len(uKey)
               IF uKey == ""
                  EXIT
               ENDIF
            ELSE
               IF Len(cPart) == 0
                  EXIT
               ENDIF
            ENDIF

            // Ajuste abaixo - pgs � tudo NOT NULL, nao deve dar trim se for indice sintetico

            IF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_SYNTH_INDEX_COL_POS] > 0
               AAdd(::aQuoted, ::Quoted(::ConvType(cPart, cType, @lPartialSeek, nThis), .F., , , , .T.))
            ELSE

               AAdd(::aQuoted, ::Quoted(::ConvType(cPart, cType, @lPartialSeek, nThis), !lSoft, , , , .F.))
            ENDIF
            AAdd(::aDat, ::ConvType(cPart, cType, , nThis))

            nCons += nThis

            IF nLenKey < nCons
               EXIT
            ENDIF

         NEXT i

         cJoin1 := " " + ::cQualifiedTableName + " A "
         cJoin3 := ::GetSelectList()

         IF ::aInfo[SR_AINFO_REVERSE_INDEX] .OR. lLast
            aTemp := ::WherePgsMinor(::aQuoted, lPartialSeek .OR. lSoft)
         ELSE
            aTemp := ::WherePgsMajor(::aQuoted, lPartialSeek .OR. lSoft)
         ENDIF

         cTemp := "SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1
         cSql := ""

         IF Len(aTemp) > 0
            FOR i := 1 TO Len(aTemp)
               //cSql += "SELECT * FROM (" + cTemp + " WHERE " + aTemp[i] + ::OrderBy(NIL,.T.) + Eval(::Optmizer_ne, ::nCurrentFetch) + " ) TMP" + AllTrim(Str(i))
               //test fix for seek last
               cSql += "SELECT * FROM (" + cTemp + " WHERE " + aTemp[i] + ::OrderBy(NIL, IIf(lLast, .F., .T.)) + Eval(::Optmizer_ne, ::nCurrentFetch) + " ) TMP" + AllTrim(Str(i))
               IF i != Len(aTemp)
                  cSql += SR_CRLF + "UNION" + SR_CRLF
               ENDIF
            NEXT i
            //cSql += StrTran(::OrderBy(NIL, .T. ), "A.", "" ) + Eval(::Optmizer_ne, ::nCurrentFetch)
            //test fix for seek last
            IF Len(aTemp) > 1 .AND. ::HasExpressionOrder()
               // PostgreSQL only accepts result column names (not expressions) in
               // the ORDER BY of a UNION, so wrap the UNION in a subselect
               cSql := "SELECT * FROM (" + SR_CRLF + cSql + SR_CRLF + ") TMPALL " + StrTran(::OrderBy(NIL, IIf(lLast, .F., .T.)), "A.", "") + Eval(::Optmizer_ne, ::nCurrentFetch)
            ELSE
               cSql += StrTran(::OrderBy(NIL, IIf(lLast, .F., .T.)), "A.", "") + Eval(::Optmizer_ne, ::nCurrentFetch)
            ENDIF
         ELSE
            //test fix for seek last
            //cSql := "SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1 + ::OrderBy(NIL, .T. ) + Eval(::Optmizer_ne, ::nCurrentFetch)
            cSql := "SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1 + ::OrderBy(NIL, IIf(lLast, .F., .T.)) + Eval(::Optmizer_ne, ::nCurrentFetch)
         ENDIF

         ::oSql:Execute(cSql + IIf(::oSql:lComments, " /* " + IIf(lSoft, "Soft", "") + "Seek " + Str(::aInfo[SR_AINFO_INDEXORD]) + " */",""))

         EXIT

      SR_OTHERWISE

         ::RuntimeErr("26")
         Set(_SET_EXACT, uSet)
         RETURN NIL

      ENDSWITCH

      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0
      ::FirstFetch()

      IF ::lNoData .OR. ::aInfo[SR_AINFO_EOF]
         ::aInfo[SR_AINFO_EOF] := .T.
         ::aInfo[SR_AINFO_FOUND] := .F.
      ELSE

         IF HB_IsChar(uKey) .AND. uKey == ""
            ::aInfo[SR_AINFO_FOUND] := .T.
         ELSE
            FOR i := 1 TO Len(::aQuoted)
               DO CASE
               CASE Len(::aSeekXF) >= i .AND. ::aSeekXF[i] != NIL .AND. HB_IsChar(::aDat[i])
                  // Expression index component: compare in the transformed domain
                  ::aInfo[SR_AINFO_FOUND] := (Left(Eval(::aSeekXF[i], ::aLocalBuffer[::aPosition[i]]), Len(::aDat[i])) == ::aDat[i])
               CASE HB_IsNumeric(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = Val(::aDat[i]))
               CASE HB_IsChar(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsNumeric(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = Str(::aDat[i]))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = SToD(::aDat[i]))
               CASE HB_IsDateTime(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsChar(::aDat[i])
                  ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = hb_stot(::aDat[i]))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDate(::aDat[i]) .AND. ::nPartialDateSeek > 0 .AND. i == Len(::aQuoted)
                  ::aInfo[SR_AINFO_FOUND] := (Left(DToS(::aLocalBuffer[::aPosition[i]]), ::nPartialDateSeek) == Left(DToS(::aDat[i]), ::nPartialDateSeek))
               CASE HB_IsDate(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDate(::aDat[i]) .AND. ::nPartialDateSeek == 0 .AND. i == Len(::aQuoted) .AND. lsoft
                  ::aInfo[SR_AINFO_FOUND] := (DToS(::aLocalBuffer[::aPosition[i]]) >= DToS(::aDat[i]))
               CASE HB_IsDateTime(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDateTime(::aDat[i]) .AND. ::nPartialDateSeek > 0 .AND. i == Len(::aQuoted)
                  ::aInfo[SR_AINFO_FOUND] := (Left(hb_ttos(::aLocalBuffer[::aPosition[i]]), ::nPartialDateSeek) == Left(hb_ttos(::aDat[i]), ::nPartialDateSeek))
               CASE HB_IsDateTime(::aLocalBuffer[::aPosition[i]]) .AND. HB_IsDateTime(::aDat[i]) .AND. ::nPartialDateSeek == 0 .AND. i == Len(::aQuoted) .AND. lsoft
                  ::aInfo[SR_AINFO_FOUND] := (hb_ttos(::aLocalBuffer[::aPosition[i]]) >= hb_ttos(::aDat[i]))
               CASE ValType(::aLocalBuffer[::aPosition[i]]) != ValType(::aDat[i])
                  ::RuntimeErr("28")
                  Set(_SET_EXACT, uSet)
                  RETURN NIL
               OTHERWISE
                  IF HB_IsChar(::aLocalBuffer[::aPosition[i]])
                     ::aInfo[SR_AINFO_FOUND] := (Left(::aLocalBuffer[::aPosition[i]], Len(::aDat[i])) == ::aDat[i])
                  ELSE
                     ::aInfo[SR_AINFO_FOUND] := (::aLocalBuffer[::aPosition[i]] = ::aDat[i])
                  ENDIF
               ENDCASE

               IF !::aInfo[SR_AINFO_FOUND]
                  EXIT
               ENDIF
            NEXT i
         ENDIF
      ENDIF

      IF ::aInfo[SR_AINFO_FOUND]
         ::aInfo[SR_AINFO_EOF] := .F.
         ::aInfo[SR_AINFO_BOF] := .F.
         ::aInfo[SR_AINFO_RECNO] := ::aLocalBuffer[::hnRecno]
      ELSE
         ::aInfo[SR_AINFO_FOUND] := .F.
         IF lSoft .AND. ::lNoData
            ::GetBuffer(.T.)
            ::aInfo[SR_AINFO_RECNO] := ::aInfo[SR_AINFO_RCOUNT] + 1
            ::aLocalBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
         ELSEIF lSoft
            ::aInfo[SR_AINFO_EOF] := .F.
            ::aInfo[SR_AINFO_RECNO] := ::aLocalBuffer[::hnRecno]
         ELSE
            ::GetBuffer(.T.)
            ::aInfo[SR_AINFO_RECNO] := ::aInfo[SR_AINFO_RCOUNT] + 1
            ::aLocalBuffer[::hnRecno] := ::aInfo[SR_AINFO_RECNO]
         ENDIF
      ENDIF

      ::oSql:FreeStatement()

   ENDIF

   Set(_SET_EXACT, uSet)

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:ConvType(cData, cType, lPartialSeek, nThis, lLike)

   LOCAL dRet
   LOCAL cD := "19600101"
   LOCAL cD1 := "19600101 000000"

   DEFAULT lLike TO .F.

   SWITCH cType
   CASE "C"
      IF Len(cData) < nThis // .AND. Right(cData, 1) != " "
         lPartialSeek := .T.
      ENDIF
      EXIT
   CASE "N"
      RETURN Val(cData)
   CASE "D"
      IF Len(cData) < 8 .AND. !Empty(cData)
         ::nPartialDateSeek := Len(cData)
         cData += SubStr(cD, Len(cData) + 1, 8 - Len(cData))
         lPartialSeek := .T.
         lLike := .F.
      ELSE
         lPartialSeek := .F.
         lLike := .F.
      ENDIF
      dRet := SToD(cData)
      RETURN dRet
   CASE "T"
      IF Len(cData) < 15 .AND. !Empty(cData)
         ::nPartialDateSeek := Len(cData)
         cData += SubStr(cD1, Len(cData) + 1, 15 - Len(cData))
         lPartialSeek := .T.
         lLike := .F.
      ELSE
         lPartialSeek := .F.
         lLike := .F.
      ENDIF
      dRet := hb_stot(cData)
      RETURN dRet
   CASE "L"
      RETURN cData $ "SY.T."
   ENDSWITCH

RETURN IIf(lLike .AND. lPartialSeek, RTrim(cData + "%"), cData)

//----------------------------------------------------------------------------//

STATIC FUNCTION IsNull(cPar)

   IF cPar == "NULL" .OR. cPar == "0" .OR. cPar == " "
      RETURN .T.
   ENDIF

RETURN .F.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:SetBOF()

   ::aInfo[SR_AINFO_BOF] := .T.

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:ReadPage(nDirection, lWasDel)

   LOCAL i
   LOCAL cJoin1
   LOCAL cJoin3
   LOCAL cTemp
   LOCAL aTemp
   LOCAL cSql := ""
   LOCAL uRecord
   LOCAL nFecth
   LOCAL nBlockPos := 0
   LOCAL nPos
   LOCAL nOldBg
   LOCAL nOldEnd
   LOCAL lCacheIsEmpty

   HB_SYMBOL_UNUSED(nBlockPos)

   //-------- Paging cache

   IF ::lCollectingBehavior
      FOR EACH i IN ::aSelectList
         IF i == 1
            ::lCollectingBehavior := .F.
            EXIT
         ENDIF
      NEXT
   ENDIF

   IF Abs(::aInfo[SR_AINFO_SKIPCOUNT]) >= (::nCurrentFetch)
      IF ::nCurrentFetch <= 16
         ::nCurrentFetch := Max(60, ::nCurrentFetch * ::nCurrentFetch)
      ELSE
         ::nCurrentFetch += Abs(::aInfo[SR_AINFO_SKIPCOUNT]) * 3
      ENDIF
      ::nCurrentFetch := Min(::nCurrentFetch, 500)
   ELSE
      ::lCollectingBehavior := .F.
      ::nCurrentFetch := Max(Abs(::aInfo[SR_AINFO_SKIPCOUNT]), 30)
   ENDIF

   //-------- Paging cache

   cJoin1 := " " + ::cQualifiedTableName + " A "
   cJoin3 := ::GetSelectList()

   SWITCH ::oSql:nSystemID
   CASE SQLRDD_RDBMS_INGRES
   CASE SQLRDD_RDBMS_INFORM
   CASE SQLRDD_RDBMS_IBMDB2
      IF ::aInfo[SR_AINFO_REVERSE_INDEX]
         cTemp := IIf(nDirection != SR_ORD_DIR_FWD, ::WhereMajor(), ::WhereMinor())
      ELSE
         cTemp := IIf(nDirection == SR_ORD_DIR_FWD, ::WhereMajor(), ::WhereMinor())
      ENDIF
      cSql := "SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1 + cTemp + ::OrderBy(NIL, nDirection == SR_ORD_DIR_FWD) + Eval(::Optmizer_ne, ::nCurrentFetch) +;
               IIf(::oSql:lComments, " /* Skip " + IIf(nDirection == SR_ORD_DIR_FWD, "FWD", "BWD") + " */","")
      cSql := ::ParseIndexColInfo(cSQL)
      EXIT

   CASE SQLRDD_RDBMS_POSTGR
      IF ::aInfo[SR_AINFO_REVERSE_INDEX]
         aTemp := IIf(nDirection != SR_ORD_DIR_FWD, ::WherePgsMajor(), ::WherePgsMinor())
      ELSE
         aTemp := IIf(nDirection == SR_ORD_DIR_FWD, ::WherePgsMajor(), ::WherePgsMinor())
      ENDIF

      cTemp := "SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1

      FOR i := 1 TO Len(aTemp)
         cSql += "SELECT * FROM (" + cTemp + " WHERE " + aTemp[i] + ::OrderBy(NIL, nDirection == SR_ORD_DIR_FWD) + Eval(::Optmizer_ne, ::nCurrentFetch) + " ) TMP" + AllTrim(Str(i))
         IF i != Len(aTemp)
            cSql += SR_CRLF + "UNION" + SR_CRLF
         ENDIF
      NEXT i

      IF Len(aTemp) > 1 .AND. ::HasExpressionOrder()
         // PostgreSQL only accepts result column names (not expressions) in
         // the ORDER BY of a UNION, so wrap the UNION in a subselect
         cSql := "SELECT * FROM (" + SR_CRLF + cSql + SR_CRLF + ") TMPALL " + StrTran(::OrderBy(NIL, nDirection == SR_ORD_DIR_FWD), "A.", "") + Eval(::Optmizer_ne, ::nCurrentFetch) +;
                 IIf(::oSql:lComments, " /* Skip " + IIf(nDirection == SR_ORD_DIR_FWD, "FWD", "BWD") + " */","")
      ELSE
         cSql += StrTran(::OrderBy(NIL, nDirection == SR_ORD_DIR_FWD), "A.", "") + Eval(::Optmizer_ne, ::nCurrentFetch) +;
                 IIf(::oSql:lComments, " /* Skip " + IIf(nDirection == SR_ORD_DIR_FWD, "FWD", "BWD") + " */","")
      ENDIF
      EXIT

   CASE SQLRDD_RDBMS_ORACLE
      IF Len(::aIndex) > 0 .AND. ::aInfo[SR_AINFO_INDEXORD] > 0 .AND. ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] != NIL
         IF ::aInfo[SR_AINFO_REVERSE_INDEX]
            cTemp := IIf(nDirection != SR_ORD_DIR_FWD, ::WhereVMajor(), ::WhereVMinor())
            cSql := "SELECT /*+ INDEX( A " + IIf(nDirection != SR_ORD_DIR_FWD, "A$", "D$") + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] + ") */ " + cJoin3 + "FROM" + cJoin1 + cTemp + " AND ROWNUM <= " + Str(::nCurrentFetch+2) + " " + ;
               ::OrderBy(NIL, nDirection == SR_ORD_DIR_FWD) + IIf(::oSql:lComments, " /* Skip " + IIf(nDirection == SR_ORD_DIR_FWD, "FWD", "BWD") + " */", "")
         ELSE
            cTemp := IIf(nDirection == SR_ORD_DIR_FWD, ::WhereVMajor(), ::WhereVMinor())
            cSql := "SELECT /*+ INDEX( A " + IIf(nDirection == SR_ORD_DIR_FWD, "A$", "D$") + ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_NAME] + ") */ " + cJoin3 + "FROM" + cJoin1 + cTemp + " AND ROWNUM <= " + Str(::nCurrentFetch+2)+ " " + ;
               ::OrderBy(NIL, nDirection == SR_ORD_DIR_FWD) + IIf(::oSql:lComments, " /* Skip " + IIf(nDirection == SR_ORD_DIR_FWD, "FWD", "BWD") + " */", "")
         ENDIF
         EXIT  // Leave this exist HERE !!!!
      ENDIF

   SR_OTHERWISE
      IF ::aInfo[SR_AINFO_REVERSE_INDEX]
         cTemp := IIf(nDirection != SR_ORD_DIR_FWD, ::WhereMajor(), ::WhereMinor())
      ELSE
         cTemp := IIf(nDirection == SR_ORD_DIR_FWD, ::WhereMajor(), ::WhereMinor())
      ENDIF
      cSql := "SELECT" + Eval(::Optmizer_ns, ::nCurrentFetch) + cJoin3 + "FROM" + cJoin1 + cTemp + ::OrderBy(NIL, nDirection == SR_ORD_DIR_FWD) + Eval(::Optmizer_ne, ::nCurrentFetch) +;
               IIf(::oSql:lComments, " /* Skip " + IIf(nDirection == SR_ORD_DIR_FWD, "FWD", "BWD") + " */", "")
      cSql := ::ParseIndexColInfo(cSQL)

   ENDSWITCH

  ::oSql:Execute(cSql)

   IF !(lWasDel .AND. (!SR_UseDeleteds()))
      IF (::oSql:nRetCode := ::oSql:Fetch(NIL, .F., ::aFields)) != SQL_SUCCESS
         RETURN NIL
      ENDIF
   ELSE
   ENDIF

   ::oSql:nRetCode := ::oSql:Fetch(, .F., ::aFields)

   SWITCH ::oSql:nRetCode
   CASE SQL_SUCCESS

      nOldBg := ::aInfo[SR_AINFO_NCACHEBEGIN]
      nOldEnd := ::aInfo[SR_AINFO_NCACHEEND]
      lCacheIsEmpty := (nOldBg == nOldEnd) .AND. nOldEnd == 0

      IF nDirection == SR_ORD_DIR_FWD

         nBlockPos := SR_FIXCACHEPOINTER(::aInfo[SR_AINFO_NPOSCACHE] + 1)

         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NPOSCACHE] + ::nCurrentFetch

         IF nOldBg == nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEEND] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEEND] -= (SR_CACHE_PAGE_SIZE * 3)
            ENDIF
            ::aInfo[SR_AINFO_EOF_AT] := 0
         ELSEIF nOldBg < nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEEND] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEEND] -= (SR_CACHE_PAGE_SIZE * 3)
               IF ::aInfo[SR_AINFO_NCACHEEND] >= (::aInfo[SR_AINFO_NCACHEBEGIN] - 2)
                  ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NCACHEEND] + 2
               ENDIF
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
         ELSE
            IF ::aInfo[SR_AINFO_NCACHEEND] >= (::aInfo[SR_AINFO_NCACHEBEGIN] - 2)
               ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NCACHEEND] + 2
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEEND] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEEND] -= (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] > SR_CACHE_PAGE_SIZE * 3   // 3 pages...
               ::aInfo[SR_AINFO_NCACHEBEGIN] -= (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF

         ENDIF
         IF ::aInfo[SR_AINFO_NCACHEBEGIN] == 0
            ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
         ENDIF
         IF ::aInfo[SR_AINFO_NPOSCACHE] == 0
            ::aInfo[SR_AINFO_NPOSCACHE] := 1
         ENDIF
         IF ::aCache[nBlockPos] == NIL
            ::aCache[nBlockPos] := Array(Len(::aLocalBuffer))
         ENDIF
         ::oSql:GetLine(::aFields, .F., @::aCache[nBlockPos])
         uRecord := ::aCache[nBlockPos, ::hnRecno]
         IF ::aInfo[SR_AINFO_NPOSCACHE] == 0
            ::aInfo[SR_AINFO_NPOSCACHE] := 1
         ENDIF
         nPos := ::aInfo[SR_AINFO_NPOSCACHE] + IIf(lCacheIsEmpty, 0, 1)
         IF nPos > (SR_CACHE_PAGE_SIZE * 3)
            nPos := 1
         ENDIF

      ELSEIF nDirection == SR_ORD_DIR_BWD

         nBlockPos := SR_FIXCACHEPOINTER(::aInfo[SR_AINFO_NPOSCACHE] - 1)

         ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NPOSCACHE] - ::nCurrentFetch
         IF nOldBg == nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] < 1
               ::aInfo[SR_AINFO_NCACHEBEGIN] += (SR_CACHE_PAGE_SIZE * 3)
            ENDIF
            ::aInfo[SR_AINFO_EOF_AT] := 0

         ELSEIF nOldBg < nOldEnd
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] < 1
               ::aInfo[SR_AINFO_NCACHEBEGIN] += (SR_CACHE_PAGE_SIZE * 3)
               IF ::aInfo[SR_AINFO_NCACHEEND] + 2 >= ::aInfo[SR_AINFO_NCACHEBEGIN]
                  ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] - 2
               ENDIF
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
         ELSE
            IF ::aInfo[SR_AINFO_NCACHEEND] + 2 >= ::aInfo[SR_AINFO_NCACHEBEGIN]
               ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] - 2
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEBEGIN] < 1
               ::aInfo[SR_AINFO_NCACHEBEGIN] += (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
            IF ::aInfo[SR_AINFO_NCACHEEND] < 1
               ::aInfo[SR_AINFO_NCACHEEND] += (SR_CACHE_PAGE_SIZE * 3)
               ::aInfo[SR_AINFO_EOF_AT] := 0
               ::aInfo[SR_AINFO_BOF_AT] := 0
            ENDIF
         ENDIF

         IF ::aInfo[SR_AINFO_NCACHEEND] == 0
            ::aInfo[SR_AINFO_NCACHEEND] := (SR_CACHE_PAGE_SIZE * 3)
         ENDIF
         IF ::aInfo[SR_AINFO_NPOSCACHE] == 0
            ::aInfo[SR_AINFO_NPOSCACHE] := (SR_CACHE_PAGE_SIZE * 3)
         ENDIF
         IF ::aCache[nBlockPos] == NIL
            ::aCache[nBlockPos] := Array(Len(::aLocalBuffer))
         ENDIF
         ::oSql:GetLine(::aFields, .F., @::aCache[nBlockPos])
         uRecord := ::aCache[nBlockPos, ::hnRecno]
         nPos := ::aInfo[SR_AINFO_NPOSCACHE] - IIf(lCacheIsEmpty, 0, 1)
         IF nPos < 1
            nPos := (SR_CACHE_PAGE_SIZE * 3)
         ENDIF

      ELSE
         ::aInfo[SR_AINFO_NPOSCACHE] := ::aInfo[SR_AINFO_NCACHEBEGIN] := ::aInfo[SR_AINFO_NCACHEEND] := nBlockPos := 1
         ::oSql:GetLine(::aFields, .F., @::aCache[1])
         uRecord := ::aCache[nBlockPos, ::hnRecno]
      ENDIF

      IF nDirection == SR_ORD_DIR_FWD .OR. nDirection == SR_ORD_DIR_BWD
         FOR nFecth := 1 TO ::nCurrentFetch // TODO: nFecth -> nFetch
            ::oSql:nRetCode := ::oSql:Fetch(NIL, .F., ::aFields)
            IF ::oSql:nRetCode != SQL_SUCCESS
               IF ::oSql:nRetCode == SQL_ERROR
                  DEFAULT ::cLastComm TO ::oSql:cLastComm
                  ::RunTimeErr("999", "[FetchLine Failure][" + AllTrim(Str(::oSql:nRetCode)) + "] " + ::oSql:LastError() + SR_CRLF + SR_CRLF + ;
                     "Last command sent to database : " + SR_CRLF + ::cLastComm)
               ENDIF
               IF nDirection == SR_ORD_DIR_FWD
                  ::aInfo[SR_AINFO_EOF_AT] := uRecord
                  ::aInfo[SR_AINFO_NCACHEEND] := nPos
               ELSE
                  ::aInfo[SR_AINFO_BOF_AT] := uRecord
                  ::aInfo[SR_AINFO_NCACHEBEGIN] := nPos
               ENDIF

               EXIT
            ENDIF
            IF nDirection == SR_ORD_DIR_FWD
               nPos ++
               IF nPos > (SR_CACHE_PAGE_SIZE * 3)
                  nPos -= (SR_CACHE_PAGE_SIZE * 3)
               ENDIF
            ELSE
               nPos--
               IF nPos < 1
                  nPos += (SR_CACHE_PAGE_SIZE * 3)
               ENDIF
            ENDIF

            ::oSql:GetLine(::aFields, .F., @::aCache[nPos])
            uRecord := ::aCache[nPos, ::hnRecno]
            IF ::lFetchAll
               AAdd(::aFetch, uRecord)
            ENDIF
         NEXT nFecth
      ENDIF
      IF ::aCache[::aInfo[SR_AINFO_NPOSCACHE]] != NIL
         ::GetBuffer()     // Loads current cache position to record buffer
      ENDIF
      EXIT

   CASE SQL_NO_DATA_FOUND

      ::lNoData := .T.

      IF nDirection == SR_ORD_DIR_BWD
         ::aInfo[SR_AINFO_BOF_AT] := ::aInfo[SR_AINFO_RECNO]
      ELSEIF nDirection == SR_ORD_DIR_FWD
         ::aInfo[SR_AINFO_EOF_AT] := ::aInfo[SR_AINFO_RECNO]
         ::GetBuffer(.T.)         // Clean Buffer
      ELSE
         ::GetBuffer(.T.)         // Clean Buffer
      ENDIF

      EXIT
   SR_OTHERWISE
      ::lNoData := .T.
      DEFAULT ::cLastComm TO ::oSql:cLastComm
      ::RunTimeErr("999", "[Fetch Failure/First][" + AllTrim(Str(::oSql:nRetCode)) + "] " + ::oSql:LastError() + SR_CRLF + SR_CRLF + ;
         "Last command sent to database : " + SR_CRLF + ::cLastComm)
   ENDSWITCH

   ::oSql:FreeStatement()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlRecall()

   LOCAL nRecno := ::aInfo[SR_AINFO_RECNO]

   HB_SYMBOL_UNUSED(nRecno)

   ::sqlGoCold()

   IF ::lCanDel .AND. SR_UseDeleteds()
      IF ::hnDeleted > 0
         IF ::nTCCompat >= 4
            IF (::oSql:Execute(::cUpd + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = ' ', R_E_C_D_E_L_ = 0 " + ::WhereEqual(), , ::nLogMode)) != SQL_SUCCESS
               ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                  SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
               RETURN .F.
            ENDIF
         ELSE
            IF (::oSql:Execute(::cUpd + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = ' ' " + ::WhereEqual(), , ::nLogMode)) != SQL_SUCCESS
               ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                  SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
               RETURN .F.
            ENDIF
         ENDIF

         ::oSql:FreeStatement()
         ::aInfo[SR_AINFO_DELETED] := .F.
         ::aLocalBuffer[::hnDeleted] := " "

         ::aCache[::aInfo[SR_AINFO_NPOSCACHE], ::hnDeleted] := " "
         _SR_ScanExec(Self, {|x|IIf(x:nThisArea != ::nThisArea, ::CheckCache(x), NIL)})
      ENDIF
   ELSE
      SR_MsgLogFile(SR_Msg(12) + ::cFileName)
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlPack()

   LOCAL nRet

   ::sqlGoCold()

   IF ::lCanDel
      IF ::hnDeleted > 0
         IF ::nTCCompat >= 2
            nRet := ::oSql:Execute(::cDel + " WHERE " + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = '*'", , ::nLogMode)
            IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO .AND. nRet != SQL_NO_DATA_FOUND
               ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                  SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
               RETURN .F.
            ENDIF
         ELSE
            nRet := ::oSql:Execute(::cDel + " WHERE " + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = 'T'", , ::nLogMode)
            IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO .AND. nRet != SQL_NO_DATA_FOUND
               ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                  SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
               RETURN .F.
            ENDIF
         ENDIF

         ::oSql:FreeStatement()
         ::Refresh()

      ENDIF
   ELSE
      SR_MsgLogFile(SR_Msg(12) + ::cFileName)
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlDeleteRec()

   LOCAL nRecno := ::aInfo[SR_AINFO_RECNO]

   ::sqlGoCold()

   IF ::lCanDel
      IF !::aInfo[SR_AINFO_DELETED]
         IF ::hnDeleted > 0 .AND. SR_UseDeleteds()
            IF ::nTCCompat >= 2
               IF ::nTCCompat >= 4
                  IF (::oSql:Execute(::cUpd + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = '*', R_E_C_D_E_L_ = R_E_C_N_O_ " + ::WhereEqual(), , ::nLogMode)) != SQL_SUCCESS
                     ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                        SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
                     RETURN .F.
                  ENDIF
               ELSE
                  IF (::oSql:Execute(::cUpd + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = '*' " + ::WhereEqual(), , ::nLogMode)) != SQL_SUCCESS
                     ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                        SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
                     RETURN .F.
                  ENDIF
               ENDIF
            ELSE
               IF (::oSql:Execute(::cUpd + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = 'T' " + ::WhereEqual(), , ::nLogMode)) != SQL_SUCCESS
                  ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                     SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
                  RETURN .F.
               ENDIF
            ENDIF

            ::oSql:FreeStatement()
            ::aInfo[SR_AINFO_DELETED] := .T.
            ::aLocalBuffer[::hnDeleted] := IIf(::nTCCompat > 0, "*", "T")

            IF ::aInfo[SR_AINFO_NPOSCACHE] > 0
               ::aCache[::aInfo[SR_AINFO_NPOSCACHE], ::hnDeleted] :=  ::aLocalBuffer[::hnDeleted]
               _SR_ScanExec(Self, {|x|IIf(x:nThisArea != ::nThisArea, ::CheckCache(x), NIL)})
            ENDIF

         ELSE
            IF (::oSql:Execute(::cDel + ::WhereEqual(), , ::nLogMode)) != SQL_SUCCESS
               ::RuntimeErr("13", SR_Msg(13) + ::oSql:LastError() + SR_CRLF + ;
                  SR_Msg(14) + SR_CRLF + ::oSql:cLastComm)
               RETURN .F.
            ENDIF

            ::oSql:FreeStatement()

            IF nRecno == ::aInfo[SR_AINFO_EOF_AT]
#if 0
               nPos := ::aInfo[SR_AINFO_NPOSCACHE] - 1
               IF nPos > SR_CACHE_PAGE_SIZE
                  nPos := 1
               ENDIF
               IF (::aInfo[SR_AINFO_NCACHEBEGIN] < ::aInfo[SR_AINFO_NCACHEEND] .AND. (nPos < ::aInfo[SR_AINFO_NCACHEEND] .AND. nPos >= ::aInfo[SR_AINFO_NCACHEBEGIN])) .OR.;
                  (::aInfo[SR_AINFO_NCACHEBEGIN] > ::aInfo[SR_AINFO_NCACHEEND] .AND. (nPos >= ::aInfo[SR_AINFO_NCACHEBEGIN] .OR. nPos < ::aInfo[SR_AINFO_NCACHEEND]))
                  ::aInfo[SR_AINFO_EOF_AT] := ::aCache[nPos, ::hnRecno]
               ENDIF
#endif
               ::aInfo[SR_AINFO_EOF_AT] := 0
            ENDIF

            IF nRecno == ::aInfo[SR_AINFO_BOF_AT]
#if 0
               nPos := ::aInfo[SR_AINFO_NPOSCACHE] + 1
               IF nPos > SR_CACHE_PAGE_SIZE
                  nPos := 1
               ENDIF
               IF (::aInfo[SR_AINFO_NCACHEBEGIN] < ::aInfo[SR_AINFO_NCACHEEND] .AND. (nPos <= ::aInfo[SR_AINFO_NCACHEEND] .AND. nPos > ::aInfo[SR_AINFO_NCACHEBEGIN])) .OR.;
                  (::aInfo[SR_AINFO_NCACHEBEGIN] > ::aInfo[SR_AINFO_NCACHEEND] .AND. (nPos > ::aInfo[SR_AINFO_NCACHEBEGIN] .OR. nPos <= ::aInfo[SR_AINFO_NCACHEEND]))
                  ::aInfo[SR_AINFO_BOF_AT] := ::aCache[nPos, ::hnRecno]
               ENDIF
#endif
               ::aInfo[SR_AINFO_EOF_AT] := 0

            ENDIF

            IF ::hnDeleted > 0
               ::aLocalBuffer[::hnDeleted] := IIf(::nTCCompat > 0, "*", "T")
            ENDIF

            IF ::aInfo[SR_AINFO_NPOSCACHE] != 0
               ::aCache[::aInfo[SR_AINFO_NPOSCACHE]] := NIL
            ENDIF

            ::aInfo[SR_AINFO_DELETED] := .T.

         ENDIF
      ENDIF
   ELSE
      SR_MsgLogFile(SR_Msg(12) + ::cFileName)
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlFlush()
   ::sqlGoCold()
   IF ::lCanICommitNow()
      ::oSql:Commit()
   ENDIF
RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlClose()

   IF ::oSql != NIL
      ::sqlFlush()      // commit when close WA
      IF ::nThisArea > 0
         IF !::lCreating //
            _SR_UnRegister(Self)
         ENDIF
         IF ::lTableLocked
            ::UnlockTable(.T.)
         ENDIF
         IF ::lSharedLock .AND. ::lOpened
            SR_ReleaseLocks(SR_SHARED_TABLE_LOCK_SIGN + Upper(::cFileName), ::oSql)
         ENDIF
      ENDIF
   ENDIF

   IF ++s_nOperat > 100
      hb_gcAll(.T.)
      s_nOperat := 0
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlCreate(aStruct, cFileName, cAlias, nArea)

   LOCAL i
   LOCAL nConnection
   LOCAL aRet
   LOCAL aRec
   LOCAL aPK
   LOCAL aCreate
   LOCAL cSql
   LOCAL cField
   LOCAL lNotNull
   LOCAL lPrimary
   LOCAL lRet
   LOCAL cTblName
   LOCAL nRet
   LOCAL nRowSize := 0
   LOCAL cRowSize
   LOCAL aMultilang := {}
   LOCAL aField
   LOCAL cLobs := ""
   LOCAL aCacheInfo := Array(SR_CACHEINFO_LEN)
   LOCAL nPos
   LOCAL cTemp1
   LOCAL cTemp2
   LOCAL cTemp3

   ::cRecnoName := SR_RecnoName()
   ::cDeletedName := SR_DeletedName()

   //AsizeAlloc(::aFetch, 50) // TODO: ASIZEALLOC does nothing in Harbour

   IF ::cWSID == NIL
      ::cWSID := SR_GetUniqueSystemID()
   ENDIF

   aRet := Eval(SR_GetTableInfoBlock(), cFileName)

   ASize(aRet, SR_TABLE_INFO_SIZE)

   IF aRet[SR_TABLE_INFO_CONNECTION] != NIL
      nConnection := aRet[SR_TABLE_INFO_CONNECTION]
   ENDIF

   IF ::nCnt == NIL
      ::nCnt := 1
   ENDIF

   DEFAULT cAlias TO "SQLRDD_SYS_WA_" + StrZero(++::nCnt, 3)

   IF ::nCnt >= 998
      ::nCnt := 1
   ENDIF

   ::nThisArea := nArea
   ::cAlias := cAlias
   ::aInfo[SR_AINFO_SHARED] := .F.
   ::cOriginalFN := Upper(AllTrim(cFileName))
   ::lGoTopOnFirstInteract := SR_GetlGoTopOnFirstInteract()

   IF !::aInfo[SR_AINFO_SHARED]
      ::lQuickAppend := .T.
   ENDIF

   IF SR_GetFastOpen()
      ::aInfo[SR_AINFO_SHARED] := .T.
   ENDIF

   ::cFileName := SR_ParseFileName(aRet[SR_TABLE_INFO_TABLE_NAME])
   ::aFilters := aRet[SR_TABLE_INFO_FILTERS]
   ::cColPK := AllTrim(Upper(aRet[SR_TABLE_INFO_PRIMARY_KEY]))
   ::nRelacType := aRet[SR_TABLE_INFO_RELATION_TYPE]
   ::cOwner := aRet[SR_TABLE_INFO_OWNER_NAME]
   ::cCustomSQL := aRet[SR_TABLE_INFO_CUSTOM_SQL]

   ::lHistoric := aRet[SR_TABLE_INFO_HISTORIC] .OR. SR_SetCreateAsHistoric()

   ::lCanUpd := aRet[SR_TABLE_INFO_CAN_UPDATE]
   ::lCanIns := aRet[SR_TABLE_INFO_CAN_INSERT]
   ::lCanDel := aRet[SR_TABLE_INFO_CAN_DELETE]

   ::lOpened := .T.
   ::lCreating := .T.

   IF aRet[SR_TABLE_INFO_RECNO_NAME] != NIL
      ::cRecnoName := Upper(AllTrim(aRet[SR_TABLE_INFO_RECNO_NAME]))
   ENDIF

   IF aRet[SR_TABLE_INFO_DELETED_NAME] != NIL
      ::cDeletedName := Upper(AllTrim(aRet[SR_TABLE_INFO_DELETED_NAME]))
   ENDIF

   ::oSql := SR_GetConnection(nConnection)

   IF aRet[SR_TABLE_INFO_ALL_IN_CACHE] == NIL
      aRet[SR_TABLE_INFO_ALL_IN_CACHE] := ::oSql:lAllInCache
   ENDIF

   ::lISAM := .T. // !aRet[SR_TABLE_INFO_ALL_IN_CACHE]

   // NewAge compatible rights string...

   ::cRights := "S" + IIf(::lCanUpd, "U", "") + IIf(::lCanIns, "I", "") + IIf(::lCanDel, "D", "") + LTrim(StrZero(::nRelacType, 1))

   IF !Empty(SR_GetGlobalOwner())
      ::cOwner := AllTrim(SR_GetGlobalOwner())
   ELSEIF !Empty(::oSql:cOwner)
      ::cOwner := AllTrim(::oSql:cOwner)
   ENDIF

   IF !Empty(::cOwner) .AND. Right(::cOwner, 1) != "."
      ::cOwner += "."
   ENDIF

   ::cQualifiedTableName := ::cOwner + SR_DBQUALIFY(::cFileName, ::oSql:nSystemID)

   nPos := hb_HPos(::oSql:aTableInfo, ::cOriginalFN)
   IF nPos > 0
      // REMOVE from cache
      hb_HDelAt(::oSql:aTableInfo, nPos)
   ENDIF

   IF Len(::cFileName) > SR_MAX_TABLE_NAME_LENGHT
      cTblName := subStr(::cFileName, 1, SR_MAX_TABLE_NAME_LENGHT)
      ::cFileName := cTblName
   ELSE
      cTblName := ::cFileName
   ENDIF

   ::lCanSel := .T.

   ::cDel := "DELETE FROM " + ::cQualifiedTableName + " "
   ::cUpd := "UPDATE " + ::cQualifiedTableName + " SET "

   // Release any pending transaction before a DML command

   ::oSql:Commit()
   ::oSql:nTransacCount := 0

   IF ISSYBASE()
      ::oSql:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON)
   ENDIF

   // Drop the table

   IF ISPOSTGRESQL()
      ::oSql:Exec("DROP TABLE " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + " CASCADE" + IIf(::oSql:lComments, " /* create table */", ""), .F.)
   ELSE
      ::oSql:Exec("DROP TABLE " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + IIf(ISORACLE(), " CASCADE CONSTRAINTS", "") + IIf(::oSql:lComments, " /* create table */", ""), .F.)
   ENDIF
   ::oSql:Commit()

   // Catalogs cleanup
   cTemp1 := SR_GetToolsOwner() // calls SR_GetToolsOwner only once
   cTemp2 := "'" + Upper(::cFileName) + "'" // calls Upper only once
   cTemp3 := IIf(::oSql:lComments, " /* Wipe table info */", "") // create the string only once
   ::oSql:Exec("DELETE FROM " + cTemp1 + "SR_MGMNTINDEXES WHERE TABLE_ = " + cTemp2 + IIf(::oSql:lComments, " /* Wipe index info */", ""), .F.)
   ::oSql:Commit()
   ::oSql:Exec("DELETE FROM " + cTemp1 + "SR_MGMNTTABLES WHERE TABLE_ = " + cTemp2 + cTemp3, .F.)
   ::oSql:Commit()
   ::oSql:Exec("DELETE FROM " + cTemp1 + "SR_MGMNTLANG WHERE TABLE_ = " + cTemp2 + cTemp3, .F.)
   ::oSql:Commit()
   ::oSql:Exec("DELETE FROM " + cTemp1 + "SR_MGMNTCONSTRAINTS WHERE TABLE_ = " + cTemp2 + cTemp3, .F.)
   ::oSql:Commit()
   ::oSql:Exec("DELETE FROM " + cTemp1 + "SR_MGMNTCONSTRAINTS WHERE SOURCETABLE_ = " + cTemp2 + cTemp3, .F.)
   ::oSql:Commit()
   ::oSql:Exec("DELETE FROM " + cTemp1 + "SR_MGMNTCONSTRTGTCOLS WHERE SOURCETABLE_ = " + cTemp2 + cTemp3, .F.)
   ::oSql:Commit()
   ::oSql:Exec("DELETE FROM " + cTemp1 + "SR_MGMNTCONSTRSRCCOLS WHERE SOURCETABLE_ = " + cTemp2 + cTemp3, .F.)
   ::oSql:Commit()

   cTemp1 := ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) // call SR_DBQUALIFY only once
   IF ::oSql:Exec("SELECT * FROM " + cTemp1 + IIf(::oSql:lComments, " /* check dropped table */", ""), .F.) == SQL_SUCCESS
      ::oSql:Commit()
      ::oSql:Exec("DROP TABLE " + cTemp1 + IIf(ISORACLE(), " CASCADE CONSTRAINTS", "") + IIf(::oSql:lComments, " /* create table */", ""), .T.)
      ::oSql:Commit()
      IF ::oSql:Exec("SELECT * FROM " + cTemp1 + IIf(::oSql:lComments, " /* check dropped table */", ""), .F.) == SQL_SUCCESS
         SR_MsgLogFile("Could not drop existing table " + cTblName + " in dbCreate()")
         ::lOpened := .F.
         IF ISSYBASE()
            ::oSql:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF)
         ENDIF
         RETURN Self
      ENDIF
   ENDIF
   ::oSql:Commit()

   // If Postgres, create SEQUENCE per table

   IF ISPOSTGRESQL()
      ::oSql:Commit()
      ::oSql:Exec("DROP SEQUENCE " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ", .F.)
      ::oSql:Commit()
      ::oSql:Exec("CREATE SEQUENCE " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ START 1")
      ::oSql:Commit()
   ENDIF

   // Create the new table

   aPK := {}
   aCreate := {}

   FOR EACH aRec IN aStruct

      ASize(aRec, SR_FIELD_INFO_SIZE)

      aRec[SR_FIELD_NAME] := AllTrim(Upper(aRec[SR_FIELD_NAME]))
      aRec[SR_FIELD_TYPE] := AllTrim(Upper(aRec[SR_FIELD_TYPE]))

      IF aRec[SR_FIELD_NULLABLE] == NIL .OR. !HB_IsLogical(aRec[SR_FIELD_NULLABLE])
         aRec[SR_FIELD_NULLABLE] := .T.
      ENDIF
      IF aRec[SR_FIELD_UNIQUE] == NIL
         aRec[SR_FIELD_UNIQUE] := .F.
      ENDIF
      IF aRec[SR_FIELD_PRIMARY_KEY] == NIL
         aRec[SR_FIELD_PRIMARY_KEY] := 0
      ENDIF
      IF aRec[SR_FIELD_MULTILANG] == NIL
         aRec[SR_FIELD_MULTILANG] := MULTILANG_FIELD_OFF
      ENDIF

      IF !("*" + aRec[SR_FIELD_NAME] + "*") $ "*" + ::cRecnoName + "*" //DT__HIST*"
         IF aRec[SR_FIELD_PRIMARY_KEY] != 0
            AAdd(aPk, {aRec[SR_FIELD_PRIMARY_KEY], aRec[SR_FIELD_NAME]})
         ENDIF
         AAdd(aCreate, aRec)
      ENDIF

   NEXT

   AAdd(aCreate, {::cRecnoName, "N", 15, 0, .F., , MULTILANG_FIELD_OFF, , , 0, .F.})

   IF SR_UseDeleteds()
      AAdd(aCreate, {::cDeletedName, "C", 1, 0, IIf(ISORACLE(), .T., .F.), , MULTILANG_FIELD_OFF, , , 0, .F.})
   ENDIF



   IF ::lHistoric
      AAdd(aCreate, {"DT__HIST", "D", 8, 0, .T., , MULTILANG_FIELD_OFF, , , 0, .F.})
   ENDIF

   cSql := "CREATE TABLE " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + " ( "

   FOR i := 1 TO Len(aCreate)

      cField := Upper(AllTrim(aCreate[i, SR_FIELD_NAME]))
      lPrimary := aCreate[i, SR_FIELD_PRIMARY_KEY] > 0
      nRowSize += aCreate[i, SR_FIELD_LEN]

      IF aCreate[i, SR_FIELD_MULTILANG] .AND. aCreate[i, SR_FIELD_TYPE] $ "MC" .AND. SR_SetMultiLang()
         AAdd(aMultilang, AClone(aCreate[i]))
         aCreate[i, SR_FIELD_TYPE] := "M"
      ENDIF

      cSql += "   " + SR_DBQUALIFY(cField, ::oSql:nSystemID)
      cSql += " "

      lNotNull := (!aCreate[i, SR_FIELD_NULLABLE]) .OR. lPrimary

      SWITCH aCreate[i, SR_FIELD_TYPE]

#define SR_FIELD_SIZE LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0))

      CASE "C"
         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_ORACLE
            IF aCreate[i, SR_FIELD_LEN] > 30
               cSql += "VARCHAR2(" + LTrim(Str(Min(aCreate[i, SR_FIELD_LEN], 4000), 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            ELSE
               IF aCreate[i, SR_FIELD_LEN] > s_nMininumVarchar2Size .AND. s_nMininumVarchar2Size < 30
                  cSql += "VARCHAR(" + SR_FIELD_SIZE + ")" + IIf(lNotNull, " NOT NULL", "")
               ELSE
                  cSql += "CHAR(" + SR_FIELD_SIZE + ")" + IIf(lNotNull, " NOT NULL", "")
               ENDIF
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_SQLBAS
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "LONG VARCHAR"
            ELSE
               cSql += "VARCHAR(" + SR_FIELD_SIZE + ")" + IIf(lPrimary, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_MSSQL6
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_AZURE
         CASE SQLRDD_RDBMS_POSTGR
         CASE SQLRDD_RDBMS_CACHE
         CASE SQLRDD_RDBMS_ADABAS
            IF ISMSSQL7() .OR. ISAZURE()
               IF ::OSQL:lSqlServer2008 .AND. SR_Getsql2008newTypes()
                  IF aCreate[i, SR_FIELD_LEN] > 10
                     cSql += "VARCHAR (" + SR_FIELD_SIZE + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
                  ELSE
                     cSql += "CHAR (" + SR_FIELD_SIZE + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IF(lNotNull, " NOT NULL", "")
                  ENDIF
               ELSE
                  cSql += "CHAR (" + SR_FIELD_SIZE + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
               ENDIF
            ELSEIF ISPOSTGRESQL() .AND. aCreate[i, SR_FIELD_LEN] > s_nMininumVarchar2Size - 1 // 10
               cSql += "VARCHAR (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            IF ISPOSTGRESQL() .AND. cField == ::cDeletedName
               cSql += " default ' '"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_MYSQL
         CASE SQLRDD_RDBMS_MARIADB
            IF aCreate[i, SR_FIELD_LEN] > 255
               cSql += "VARCHAR (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
            IF aCreate[i, SR_FIELD_LEN] > 128
               cSql += "VARCHAR (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHARACTER (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_INGRES
            cSql += "varchar(" + SR_FIELD_SIZE + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IIf(lNotNull, " NOT NULL", ""))
            EXIT
         CASE SQLRDD_RDBMS_INFORM
            cSql += "CHARACTER (" + SR_FIELD_SIZE + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IIf(lNotNull, " NOT NULL", ""))
            EXIT
         CASE SQLRDD_RDBMS_ACCESS
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "TEXT"
            ELSE
               cSql += "CHAR (" + SR_FIELD_SIZE + ")"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_SQLANY
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "LONG VARCHAR "
            ELSE
               cSql += "CHAR (" + SR_FIELD_SIZE + ")" + "  " + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_FIREBR
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "VARCHAR (" + SR_FIELD_SIZE + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "") + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + SR_FIELD_SIZE + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")  + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_SYBASE
            IF aCreate[i, SR_FIELD_LEN] > 30
               cSql += "VARCHAR (" + SR_FIELD_SIZE + ")" + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + SR_FIELD_SIZE + ")" + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_CUBRID
            IF aCreate[i, SR_FIELD_LEN] > 255
               cSql += "VARCHAR(" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR(" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         SR_OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")
         ENDSWITCH
         EXIT

#undef SR_FIELD_SIZE

      CASE "D"
         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_ORACLE
         CASE SQLRDD_RDBMS_SQLBAS
         CASE SQLRDD_RDBMS_INFORM
         CASE SQLRDD_RDBMS_INGRES
         CASE SQLRDD_RDBMS_MYSQL
         CASE SQLRDD_RDBMS_MARIADB
         CASE SQLRDD_RDBMS_FIREBR
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
         CASE SQLRDD_RDBMS_CACHE
            cSql += "DATE"
            EXIT
         CASE SQLRDD_RDBMS_SYBASE
            cSql += "DATETIME"
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
         CASE SQLRDD_RDBMS_POSTGR
         CASE SQLRDD_RDBMS_ADABAS
            cSql += "DATE"
            EXIT
         CASE SQLRDD_RDBMS_ACCESS
         CASE SQLRDD_RDBMS_MSSQL6
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_AZURE
            IF ISMSSQL7() .AND. ::OSQL:lSqlServer2008 .AND. SR_Getsql2008newTypes()
               cSql += "DATE NULL "
            ELSE
               cSql += "DATETIME NULL"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_SQLANY
            cSql += "TIMESTAMP"
            EXIT
         CASE SQLRDD_RDBMS_CUBRID
            cSql += "DATE"
            EXIT
         SR_OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")
         ENDSWITCH
         EXIT

      CASE "L"
         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_MSSQL6
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_AZURE
         CASE SQLRDD_RDBMS_CACHE
            cSql += "BIT"
            EXIT
         CASE SQLRDD_RDBMS_POSTGR
         CASE SQLRDD_RDBMS_ADABAS
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            cSql += "BOOLEAN"
            EXIT
         CASE SQLRDD_RDBMS_MYSQL
         CASE SQLRDD_RDBMS_MARIADB
            cSql += "TINYINT"
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
         CASE SQLRDD_RDBMS_FIREBR
            cSql += "SMALLINT"
            EXIT
         CASE SQLRDD_RDBMS_SYBASE
            cSql += "BIT NOT NULL"
            EXIT
         CASE SQLRDD_RDBMS_SQLANY
            cSql += "NUMERIC (1) NULL"
            EXIT
         CASE SQLRDD_RDBMS_ORACLE
            cSql += "SMALLINT"
            EXIT
         CASE SQLRDD_RDBMS_INFORM
            cSql += "BOOLEAN"
            EXIT
         CASE SQLRDD_RDBMS_INGRES
            cSql += "tinyint"
            EXIT
         CASE SQLRDD_RDBMS_CUBRID
            cSql += "SMALLINT"
            EXIT
         SR_OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")
         ENDSWITCH
         EXIT

      CASE "M"
         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_SQLBAS
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "LONG VARCHAR"
            ELSE
               cSql += "VARCHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_ORACLE
            cSql += "CLOB"
            cLobs += IIf(Empty(cLobs), "", ",") + SR_DBQUALIFY(cField, ::oSql:nSystemID)
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
            cSql += "CLOB (256000) " + IIf("DB2/400" $ ::oSql:cSystemName, "",  " NOT LOGGED COMPACT")
            EXIT
         CASE SQLRDD_RDBMS_POSTGR
            IF aCreate[i, SR_FIELD_LEN] == 4
               cSql += "XML"
            ELSE
               cSql += "TEXT"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_MSSQL6
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_AZURE
         //CASE SQLRDD_RDBMS_POSTGR
         CASE SQLRDD_RDBMS_INFORM
         CASE SQLRDD_RDBMS_CACHE
            cSql += "TEXT"
            EXIT
         CASE SQLRDD_RDBMS_MYSQL
         CASE SQLRDD_RDBMS_MARIADB
            cSql += s_cMySqlMemoDataType
            EXIT
         CASE SQLRDD_RDBMS_ADABAS
            cSql += "LONG"
            EXIT
         CASE SQLRDD_RDBMS_INGRES
            cSql += "long varchar"
            EXIT
         CASE SQLRDD_RDBMS_ACCESS
            cSql += "TEXT NULL"
            EXIT
         CASE SQLRDD_RDBMS_SYBASE
            cSql += "TEXT"
            EXIT
         CASE SQLRDD_RDBMS_SQLANY
            cSql += "LONG VARCHAR"
            EXIT
         CASE SQLRDD_RDBMS_FIREBR
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            cSql += "BLOB SUB_TYPE 1" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")
            EXIT
         CASE SQLRDD_RDBMS_CUBRID
            cSql += "CLOB"
            cLobs += IIf(Empty(cLobs), "", ",") + SR_DBQUALIFY(cField, ::oSql:nSystemID)
            EXIT
         SR_OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")
         ENDSWITCH
         EXIT

#define SR_FIELD_SIZE LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0))

      CASE "N"
         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_MSSQL6
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_SYBASE
         CASE SQLRDD_RDBMS_AZURE
            IF cField == ::cRecnoName
               IF ::oSql:lUseSequences
                  cSql += "NUMERIC (" + SR_FIELD_SIZE + ") IDENTITY"
               ELSE
                  cSql += "NUMERIC (" + SR_FIELD_SIZE + ") NOT NULL UNIQUE"
               ENDIF
            ELSE
               cSql += "NUMERIC (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL ", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_CACHE
            IF cField == ::cRecnoName
               cSql += "NUMERIC (" + SR_FIELD_SIZE + ") UNIQUE " + [default objectscript '##class(] + SR_GetToolsOwner() + [SequenceControler).NEXTVAL("] + ::cFileName + [")']
            ELSE
               cSql += "NUMERIC (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL ", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_POSTGR
            IF cField == ::cRecnoName
               cSql += "NUMERIC (" + SR_FIELD_SIZE + ") default (nextval('" + ::cOwner + LimitLen(::cFileName, 3) + "_SQ')) NOT NULL UNIQUE"
            ELSE
               cSql += "NUMERIC (" + SR_FIELD_SIZE + ")  default 0 " + IIf(lNotNull, " NOT NULL ", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_MYSQL
            IF cField == ::cRecnoName
               cSql += "BIGINT (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") NOT NULL UNIQUE AUTO_INCREMENT "
            ELSE
               // use type DECIMAL instead of REAL when using MySQL 8 or upper,
               // except if the flag 'SQLRDD_MYSQL_REAL_DATA_TYPE' is set
               #ifdef SQLRDD_MYSQL_REAL_DATA_TYPE
               cSql += s_cMySqlNumericDataType + " (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL ", "")
               #else
               IF SubStr(::oSql:cSystemVers, 1, 1) == "5"
                  // maintain the original behavior when using MySQL 5
                  cSql += s_cMySqlNumericDataType + " (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL ", "")
               ELSE
                  cSql += "DECIMAL (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL ", "")
               ENDIF
               #endif
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_MARIADB
            IF cField == ::cRecnoName
               cSql += "BIGINT (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") NOT NULL UNIQUE AUTO_INCREMENT "
            ELSE
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL ", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_ORACLE
            IF cField == ::cRecnoName
               cSql += "NUMBER (" + SR_FIELD_SIZE + ")" +;
                       IIf(lNotNull, " NOT NULL UNIQUE USING INDEX ( CREATE INDEX " + ::cOwner + LimitLen(::cFileName, 3) + "_UK ON " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + "( " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + ")" +;
                       IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx()) , "") + ")"
            ELSE
               cSql += "NUMBER (" + SR_FIELD_SIZE + ")" + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
            IF cField == ::cRecnoName
               IF ::oSql:lUseSequences
                  cSql += "DECIMAL (" + SR_FIELD_SIZE + ") NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE)"
               ELSE
                  cSql += "DECIMAL (" + SR_FIELD_SIZE + ") NOT NULL"
               ENDIF
            ELSE
               cSql += "DECIMAL(" + SR_FIELD_SIZE + ")" + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_ADABAS
            IF cField == ::cRecnoName
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ") NOT NULL DEFAULT SERIAL"
            ELSE
               cSql += "DECIMAL(" + SR_FIELD_SIZE + ")" + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_INGRES
            IF cField == ::cRecnoName
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ") NOT NULL UNIQUE"
            ELSE
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY ", IIf(lNotNull, " NOT NULL", ""))
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_INFORM
            IF cField == ::cRecnoName
               cSql += "SERIAL NOT NULL UNIQUE"
            ELSE
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY ", IIf(lNotNull, " NOT NULL", ""))
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_FIREBR
            IF cField == ::cRecnoName
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ") NOT NULL UNIQUE "
            ELSE
               IF aCreate[i, SR_FIELD_LEN] > 18
                  cSql += "DOUBLE PRECISION" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
               ELSE
                  cSql += "DECIMAL (" + SR_FIELD_SIZE +  ")" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
               ENDIF
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            IF cField == ::cRecnoName
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ") GENERATED BY DEFAULT AS IDENTITY  NOT NULL UNIQUE "
            ELSE
               IF aCreate[i, SR_FIELD_LEN] > 18
                  cSql += "DOUBLE PRECISION" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
               ELSE
                  cSql += "DECIMAL (" + SR_FIELD_SIZE +  ")" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
               ENDIF
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_SQLBAS
            IF aCreate[i, SR_FIELD_LEN] > 15
               cSql += "NUMBER" + IIf(lPrimary, " NOT NULL", " ")
            ELSE
               cSql += "DECIMAL (" + SR_FIELD_SIZE + ")" + IIf(lPrimary, " NOT NULL", " ")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_SQLANY
            cSql += "NUMERIC (" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL", "")
            EXIT
         CASE SQLRDD_RDBMS_ACCESS
            cSql += "NUMERIC"
            EXIT
         CASE SQLRDD_RDBMS_CUBRID
            IF cField == ::cRecnoName
               cSql += "BIGINT NOT NULL UNIQUE AUTO_INCREMENT "
            ELSE
               cSql += "NUMERIC(" + SR_FIELD_SIZE + ") " + IIf(lNotNull, " NOT NULL ", "")
            ENDIF
            EXIT
         SR_OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")
         ENDSWITCH
         EXIT

#undef SR_FIELD_SIZE

      // including xml data type
      // postgresql datetime
      CASE "T"
         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_POSTGR
            IF aCreate[i, SR_FIELD_LEN] == 4
                cSql += "time  without time zone "
            ELSE
                cSql += "timestamp  without time zone "
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_MYSQL
         CASE SQLRDD_RDBMS_MARIADB
            IF aCreate[i, SR_FIELD_LEN] == 4
                cSql += "time "
            ELSE
                cSql += "DATETIME "
            ENDIF
            EXIT
         // oracle datetime
         CASE SQLRDD_RDBMS_ORACLE
         CASE SQLRDD_RDBMS_FIREBR
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            cSql += "TIMESTAMP "
            EXIT
         CASE SQLRDD_RDBMS_MSSQL7 // .AND. ::OSQL:lSqlServer2008 .AND. SR_Getsql2008newTypes()
            cSql += "DATETIME NULL "
            EXIT
         CASE SQLRDD_RDBMS_CUBRID
            cSql += "DATETIME "
            EXIT
         SR_OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")
         ENDSWITCH
         EXIT

      CASE "V"
         IF ISMSSQL7()
            cSql += " VARBINARY(MAX) "
         ELSE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")
         ENDIF
         EXIT

      SR_OTHERWISE
         SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")

      ENDSWITCH

      IF i != Len(aCreate)
         cSql += ", " + SR_CRLF
      ELSE
         cSql += SR_CRLF
      ENDIF

   NEXT i

   cSql += " )"

   // TODO: switch

   //If ISMYSQL()
        //cSql += " Type=InnoDb "
   //ENDIF

   IF ISMARIADB()
      cSql += " Engine=InnoDb "
   ENDIF

   IF ISMYSQL()

#if 0
      IF Val(SubStr(::oSql:cSystemVers, 1, 3)) < 505 // NOTE: not working with MySQL 8 [MAG]
         cSql += " Type=InnoDb "
      ELSE
         cSql += " Engine=InnoDb "
      ENDIF
#endif
      IF SubStr(::oSql:cSystemVers, 1, 1) == "5" // NOTE: trying another method [MAG]
         cSql += " Type=InnoDb "
      ELSE
         cSql += " Engine=InnoDb "
      ENDIF

   ENDIF

   IF ISORACLE() .AND. !Empty(SR_SetTblSpaceData())
      cSql += " TABLESPACE " + SR_SetTblSpaceData()
   ENDIF

   IF ISORACLE() .AND. (!Empty(SR_SetTblSpaceLob())) .AND. (!Empty(cLobs))
      cSql += " LOB (" + cLobs + ") STORE AS (TABLESPACE " + SR_SetTblSpaceLob() + ")"
   ENDIF

   IF ISINGRES()
      nRowSize += 1000     // prevent INDKEY_...
      DO CASE
//      CASE nRowSize < 3988
//         cRowSize := "4096"
      CASE nRowSize < 8084
         cRowSize := "8192"
//      CASE nRowSize < 16276
//         cRowSize := "16384"
      CASE nRowSize < 32660
         cRowSize := "32768"
      OTHERWISE
         cRowSize := "65536"
      ENDCASE
//      cSql += " structure=btree"
//      cSql += " with page_size= " + cRowSize + " structure=btree"
   ENDIF

// TODO: end switch

   ::oSql:Commit()
   nRet := ::oSql:Exec(cSql, .T.)
   lRet := nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
   ::oSql:Commit()

   IF lRet .AND. ISMSSQL7() .OR. ISPOSTGRESQL() .OR. ISADABAS() .OR. ISAZURE() // .OR. ISCACHE() // Create SR_RECNO INDEX
   // Culik 18/10/2010 se o server suporta clustered index, adicionamos o mesmo na criacao
      cSql := "CREATE " + IIf(::oSql:lClustered, " CLUSTERED " , " ") + "INDEX " + LimitLen(::cFileName, 3) + "_SR ON " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + "(" + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + ") " + IIf(::oSql:lComments, " /* Unique Index */", "")
      lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS
      ::oSql:Commit()
   ENDIF

   IF lRet .AND. ISORACLE() .AND. ::oSql:lUseSequences  // Create RECNO Trigger
      ::oSql:Exec("DROP SEQUENCE " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ", .F.)
      ::oSql:Commit()
      ::oSql:Exec("CREATE SEQUENCE " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ START WITH 1")
      ::CreateOrclFunctions(::cOwner, ::cFileName)
   ENDIF

   IF lRet .AND. ISCACHE()
      ::oSql:Commit()
      ::oSql:Exec("call " +  SR_GetToolsOwner() + [RESET("] + ::cFileName + [")], .F.)
      ::oSql:Commit()
   ENDIF

   IF lRet .AND. ISINGRES() .AND. ::oSql:lUseSequences  // Create RECNO Trigger
      ::oSql:Commit()
      ::oSql:Exec("modify " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + " to btree with page_size = " + cRowSize, .T.) // + "unique on " + ::cRecnoName
      ::oSql:Commit()
      ::oSql:Exec("DROP SEQUENCE "  + ::cOwner + "SQ_" + cTblName, .F.)
      ::oSql:Commit()
      ::oSql:Exec("CREATE SEQUENCE " + ::cOwner + "SQ_" + cTblName + " AS BIGINT START WITH 1")
      ::oSql:Commit()
   ENDIF

   IF lRet .AND. ISFIREBIRD() .AND. ::oSql:lUseSequences  // Create RECNO Trigger
      ::oSql:Commit()

      IF ::oSql:Exec("SELECT gen_id( " + ::cOwner+cTblName + ", 1) FROM RDB$DATABASE", .F.) != SQL_SUCCESS
         ::oSql:Exec("CREATE GENERATOR " + ::cOwner + cTblName)
         ::oSql:Commit()
      ENDIF

      ::oSql:Exec("SET GENERATOR " + ::cOwner + cTblName + " TO 0")
      ::oSql:Commit()

      cSql := "CREATE TRIGGER " + ::cOwner + cTblName + "_SR  FOR " + ::cOwner + cTblName +;
              " ACTIVE BEFORE INSERT POSITION 0 " +;
              " as " +;
              "begin " +;
              "If (new." + ::cRecnoName + " is null) then " + ;
              "new." + ::cRecnoName + " = gen_id( " + ::cOwner+cTblName + ", 1); " + ;
              "end"
      lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS
      ::oSql:Commit()

   ENDIF

   IF lRet .AND. Len(aPk) > 0     // Creates the primary key

      ASort(aPk, , , {|x, y|x[1] < y[1]})
      cSql := ""

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_MSSQL6
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_FIREBR
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
      CASE SQLRDD_RDBMS_POSTGR
      CASE SQLRDD_RDBMS_AZURE
         cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + " ADD CONSTRAINT " + cTblName + "_PK PRIMARY KEY ("
         FOR i := 1 TO Len(aPk)
            cSql += IIf(i == 1, "", ", ")
            cSql += aPk[i, 2]
         NEXT i
         cSql += ")"
         EXIT
      CASE SQLRDD_RDBMS_ORACLE
         cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + " ADD CONSTRAINT " + cTblName + "_PK PRIMARY KEY ("
         FOR i := 1 TO Len(aPk)
            cSql += IIf(i == 1, "", ", ")
            cSql += aPk[i, 2]
         NEXT i
         cSql += ") USING INDEX ( CREATE INDEX " + ::cOwner + LimitLen(::cFileName, 3) + "_PK ON " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + "( "
         FOR i := 1 TO Len(aPk)
            cSql += IIf(i == 1, "", ", ")
            cSql += aPk[i, 2]
         NEXT i
         cSql += ")" + IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx()) + ")"
      ENDSWITCH

      IF Len(cSql) > 0
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS
         HB_SYMBOL_UNUSED(lRet)
         ::oSql:Commit()
      ENDIF
   ENDIF

   // Add multilang columns in catalog

   FOR EACH aField IN aMultilang
      ::oSql:Exec("INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTLANG ( TABLE_ , COLUMN_, TYPE_, LEN_, DEC_ ) VALUES ( '" + Upper(::cFileName) + "','" + aField[SR_FIELD_NAME] + "', '" + aField[SR_FIELD_TYPE] + "','" + AllTrim(Str(aField[SR_FIELD_LEN], 8)) + "','" + AllTrim(Str(aField[SR_FIELD_DEC], 8)) + "' )")
      ::oSql:Commit()
   NEXT

   // Update SQLRDD catalogs

   ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES WHERE TABLE_ = '" + Upper(::cFileName) + "'" , .F.)
   ::oSql:Commit()

   ::oSql:Exec("INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTTABLES ( TABLE_ , SIGNATURE_, CREATED_, TYPE_, REGINFO_ ) VALUES ( '" + Upper(::cFileName) + "','" + HB_SR__MGMNT_VERSION + "', '" + DToS(Date()) + Time() + "','TABLE',' ' )")
   ::oSql:Commit()

   IF Len(aMultilang) > 0
      SR_ReloadMLHash(::oSql)
   ENDIF

   IF ISSYBASE()
      ::oSql:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF)
   ENDIF

   IF ::LineCount(.F.) == -1
      ::lOpened := .F.
      ::RuntimeErr("27", SR_Msg(27) , 2, EG_OPEN, ESQLRDD_OPEN)
      RETURN Self
   ENDIF

   ::IniFields(.T., , @aCacheInfo)

//   aFill(::aCache, Array(Len(::aLocalBuffer)))
   AEval(::aCache, {|x, i|HB_SYMBOL_UNUSED(x), ::aCache[i] := array(Len(::aLocalBuffer))})

   ::GetBuffer(.T.)         // Clean Buffer
   ::aInfo[SR_AINFO_BOF] := .T.

   ::nCurrentFetch := ::nFetchSize
   ::aInfo[SR_AINFO_SKIPCOUNT] := 0
   ::cLastMove := "OPEN"
   ::Optmizer_1e := ""
   ::Optmizer_1s := ""
   ::Optmizer_ne := {||""}
   ::Optmizer_ns := {||""}

   SWITCH ::oSql:nSystemID
   CASE SQLRDD_RDBMS_MSSQL7
   CASE SQLRDD_RDBMS_AZURE
   CASE SQLRDD_RDBMS_CACHE
      ::Optmizer_1s := " TOP 1"
      ::Optmizer_ns := {|x|" TOP " + Str(x + 2, 5)}
      EXIT
   CASE SQLRDD_RDBMS_FIREBR
      IF ::oSql:cSystemVers >= "2.0"
         ::Optmizer_1e := " ROWS 1"
         ::Optmizer_ne := {|x|" ROWS " + Str(x + 2, 5)}
      ELSE
         ::Optmizer_1s := " FIRST 1"
         ::Optmizer_ns := {|x|" FIRST " + Str(x + 2, 5)}
      ENDIF
      EXIT
   CASE SQLRDD_RDBMS_INFORM
      ::Optmizer_1s := " FIRST 1"
      ::Optmizer_ns := {|x|" FIRST " + Str(x + 2, 5)}
      EXIT
   CASE SQLRDD_RDBMS_ORACLE
      //::Optmizer_1s := " /*+ FIRST_ROWS(1) */ "
      //::Optmizer_ns := {|x|" /*+ FIRST_ROWS(" + Str(x + 2, 5) + ") */ "}
      IF OracleMinVersion(::oSql:cSystemVers) < 9
         ::Optmizer_1s := " /* + FIRST_ROWS(1) */ "
         ::Optmizer_ns := {|x|" /* + FIRST_ROWS(" + Str(x + 2, 5) + ") */"}
      ELSE
         ::Optmizer_1s := " /* + FIRST_ROWS_1 */ "
         ::Optmizer_ns := {|x|" /* + FIRST_ROWS_" + ALLTRIM(Str(x + 2, 5)) + " */ "}
      ENDIF
      EXIT
   CASE SQLRDD_RDBMS_POSTGR
   CASE SQLRDD_RDBMS_MYSQL
   CASE SQLRDD_RDBMS_MARIADB
      ::Optmizer_1e := " LIMIT 1"
      ::Optmizer_ne := {|x|" LIMIT " + Str(x + 2, 5)}
      EXIT
   CASE SQLRDD_RDBMS_IBMDB2
      IF !("DB2/400" $ ::oSql:cSystemName .OR. "SQLDS/VM" $ ::oSql:cSystemName)
         ::Optmizer_1e := " fetch first 1 row only"
         ::Optmizer_ne := {|x|" fetch first " + Str(x + 2, 5) + " rows only"}
      ENDIF
      EXIT
   CASE SQLRDD_RDBMS_SYBASE
      IF "12.53" $ ::oSql:cSystemVers
         ::Optmizer_1s := " TOP 1"
         ::Optmizer_ns := {|x|" TOP " + Str(x + 2, 5)}
      ENDIF
   ENDSWITCH

   ::aInfo[SR_AINFO_HNRECNO] := ::hnRecno
   ::aInfo[SR_AINFO_HNDELETED] := ::hnDeleted

   ASize(::aIndexMgmnt, 0)
   IF SR_CheckMgmntInd()
      ::LoadRegisteredTags()
   ENDIF

   IF !SR_GetFastOpen()

      IF !::LockTable(.F.)
         ::lOpened := .F.
      ENDIF

      ::lSharedLock := .T. // EXCLUSIVE open have EXC and SHARED locks.

      IF ::lOpened
         _SR_Register(Self)
      ENDIF
   ELSE
      _SR_Register(Self)
   ENDIF

   aRet[SR_TABLE_INFO_HISTORIC] := ::lHistoric

   aCacheInfo[SR_CACHEINFO_TABINFO] := aRet
   aCacheInfo[SR_CACHEINFO_TABNAME] := ::cFileName
   aCacheInfo[SR_CACHEINFO_CONNECT] := ::oSql
   aCacheInfo[SR_CACHEINFO_INDEX] := ::aIndexMgmnt
   ::oSql:aTableInfo[::cOriginalFN] := aCacheInfo

RETURN Self

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOpenArea(cFileName, nArea, lShared, lReadOnly, cAlias, nDBConnection)

   LOCAL i
   LOCAL nConnection
   LOCAL aRet
   LOCAL nMax := 0
   LOCAL nPos := 0
   LOCAL aCacheInfo
   LOCAL nAllocated
   LOCAL n
   LOCAL lRecnoAdded := .F.

   IF ::cWSID == NIL
      ::cWSID := SR_GetUniqueSystemID()
   ENDIF

   //AsizeAlloc(::aFetch, 50) // TODO: ASIZEALLOC does nothing in Harbour

   ::nThisArea := nArea
   ::cAlias := cAlias
   ::aInfo[SR_AINFO_SHARED] := lShared
   ::cOriginalFN := Upper(AllTrim(cFileName))
   ::lGoTopOnFirstInteract := SR_GetlGoTopOnFirstInteract()

   ::cRecnoName := SR_RecnoName()
   ::cDeletedName := SR_DeletedName()
   ::nFetchSize := SR_FetchSize()

   IF !::aInfo[SR_AINFO_SHARED]
      ::lQuickAppend := .T.
   ENDIF

   IF SR_GetFastOpen()
      ::aInfo[SR_AINFO_SHARED] := .T.
   ENDIF

   IF nDBConnection == 0
      nDBConnection := NIL
   ENDIF

   ::oSql := SR_GetConnection(nDBConnection)

   IF ::oSql:cNextQuery != NIL .OR. (Upper(Left(cFileName, 6)) == "SELECT" .AND. SubStr(cFileName, 7, 1) $ " " + Chr(9) + SR_CRLF)
      IF ::oSql:cNextQuery != NIL
         ::cFileName := ::oSql:cNextQuery
      ELSE
         ::cFileName := cFileName
      ENDIF
      aRet := Array(SR_TABLE_INFO_SIZE)
      aRet[SR_TABLE_INFO_RELATION_TYPE] := SR_TABLE_INFO_RELATION_TYPE_SELECT
      aRet[SR_TABLE_INFO_ALL_IN_CACHE] := .T.
      aRet[SR_TABLE_INFO_CUSTOM_SQL] := ::cFileName
      aRet[SR_TABLE_INFO_HISTORIC] := .F.
      aRet[SR_TABLE_INFO_OWNER_NAME] := ""
      aRet[SR_TABLE_INFO_CAN_UPDATE] := .F.
      aRet[SR_TABLE_INFO_CAN_INSERT] := .F.
      aRet[SR_TABLE_INFO_CAN_DELETE] := .F.
      aRet[SR_TABLE_INFO_PRIMARY_KEY] := ""
      ::oSql:cNextQuery := NIL                     // Reset Next query
   ELSE
      nPos := hb_HPos(::oSql:aTableInfo, ::cOriginalFN)
      IF nPos > 0
#ifdef __XHARBOUR__
         aCacheInfo := AClone(HGETVALUEAT(::oSql:aTableInfo, nPos))
#else
         aCacheInfo := AClone(hb_HValueAt(::oSql:aTableInfo, nPos))
#endif
         aRet := aCacheInfo[SR_CACHEINFO_TABINFO]
         ::cFileName := aCacheInfo[SR_CACHEINFO_TABNAME]
         ::oSql := aCacheInfo[SR_CACHEINFO_CONNECT]
      ELSE
         aCacheInfo := Array(SR_CACHEINFO_LEN)
         aRet := Eval(SR_GetTableInfoBlock(), cFileName)
         ::cFileName := SR_ParseFileName(aRet[SR_TABLE_INFO_TABLE_NAME])
      ENDIF

      IF Len(::cFileName) > SR_MAX_TABLE_NAME_LENGHT
         ::cFileName := subStr(::cFileName, 1, SR_MAX_TABLE_NAME_LENGHT)
      ENDIF

   ENDIF

   ASize(aRet, SR_TABLE_INFO_SIZE)
   IF aRet[SR_TABLE_INFO_CONNECTION] != NIL
      nConnection := aRet[SR_TABLE_INFO_CONNECTION]
      ::oSql := SR_GetConnection(nConnection)
   ENDIF

   IF aRet[SR_TABLE_INFO_NO_TRANSAC] != NIL .AND. aRet[SR_TABLE_INFO_NO_TRANSAC]
      ::oSql := ::oSql:oSqlTransact
   ENDIF

   IF aRet[SR_TABLE_INFO_ALL_IN_CACHE] == NIL
      aRet[SR_TABLE_INFO_ALL_IN_CACHE] := ::oSql:lAllInCache
   ENDIF

   ::aFilters := aRet[SR_TABLE_INFO_FILTERS]

   ::cColPK := AllTrim(Upper(aRet[SR_TABLE_INFO_PRIMARY_KEY]))
   ::nRelacType := aRet[SR_TABLE_INFO_RELATION_TYPE]
   ::cOwner := aRet[SR_TABLE_INFO_OWNER_NAME]
   ::lISAM := .T. // !aRet[SR_TABLE_INFO_ALL_IN_CACHE]
   ::cCustomSQL := aRet[SR_TABLE_INFO_CUSTOM_SQL]

   ::lHistoric := aRet[SR_TABLE_INFO_HISTORIC]

   IF lReadOnly .OR. (!Empty(::cCustomSQL))
      ::lCanUpd := .F.
      ::lCanIns := .F.
      ::lCanDel := .F.
   ELSE
      ::lCanUpd := aRet[SR_TABLE_INFO_CAN_UPDATE]
      ::lCanIns := aRet[SR_TABLE_INFO_CAN_INSERT]
      ::lCanDel := aRet[SR_TABLE_INFO_CAN_DELETE]
   ENDIF

   // NewAge compatible rights string...

   ::cRights := "S" + IIf(::lCanUpd, "U", "") + IIf(::lCanIns, "I", "") + IIf(::lCanDel, "D", "") + LTrim(StrZero(::nRelacType, 1))

   IF aRet[SR_TABLE_INFO_RECNO_NAME] != NIL
     ::cRecnoName := aRet[SR_TABLE_INFO_RECNO_NAME]
   ENDIF

   IF aRet[SR_TABLE_INFO_DELETED_NAME] != NIL
      ::cDeletedName := aRet[SR_TABLE_INFO_DELETED_NAME]
   ENDIF

   IF !Empty(::cCustomSQL)      // Custom SQL Commands requires ALL_DATA_IN_CACHE workarea
      ::lISAM := .F.
   ENDIF

   IF !Empty(sr_GetGlobalOwner())
      ::cOwner := AllTrim(SR_GetGlobalOwner())
   ELSEIF !Empty(::oSql:cOwner)
      ::cOwner := AllTrim(::oSql:cOwner)
   ENDIF

   IF !Empty(::cOwner) .AND. Right(::cOwner, 1) != "."
      ::cOwner := AllTrim(::cOwner) + "."
   ENDIF

   ::lCanSel := .T.
   IF Upper(SubStr(::cFileName, 1, 6)) == "SELECT"
      ::lTableIsSelect := .T.
   ENDIF
   ::cQualifiedTableName := ::cOwner + SR_DBQUALIFY(::cFileName, ::oSql:nSystemID)

   ::cDel := "DELETE FROM " + ::cQualifiedTableName + " "
   ::cUpd := "UPDATE " + ::cQualifiedTableName + " SET "

   // Search the registered indexes and creates KEY codeblock

   IF Empty(::cCustomSQL)
      IF nPos > 0
         ::aIndexMgmnt := aCacheInfo[SR_CACHEINFO_INDEX]
         ::aFields := aCacheInfo[SR_CACHEINFO_AFIELDS]
         ::aNames := aCacheInfo[SR_CACHEINFO_ANAMES]
         ::aNamesLower := aCacheInfo[SR_CACHEINFO_ANAMES_LOWER]
         ::hnRecno := aCacheInfo[SR_CACHEINFO_HNRECNO]
         ::hnDeleted := aCacheInfo[SR_CACHEINFO_HNDELETED]
         ::aIniFields := aCacheInfo[SR_CACHEINFO_INIFIELDS]
         ::nPosDtHist := aCacheInfo[SR_CACHEINFO_HNPOSDTHIST]
         ::nPosColPK := aCacheInfo[SR_CACHEINFO_HNCOLPK]
         ::nFields := Len(::aFields)
         ::aInfo[SR_AINFO_FCOUNT] := ::nFields
         IF ::hnRecno != NIL
            ::cRecnoName := ::aFields[::hnRecno, SR_FIELD_NAME]
         ENDIF
         IF ::hnDeleted > 0
            ::cDeletedName := ::aFields[::hnDeleted, SR_FIELD_NAME]
         ENDIF
         ASize(::aEmptyBuffer, ::nFields)
         AEval(::aEmptyBuffer, {|x, i|HB_SYMBOL_UNUSED(x), ::aEmptyBuffer[i] := aCacheInfo[SR_CACHEINFO_ABLANK][i]})
         ASize(::aSelectList, ::nFields)
//         aFill(::aCache, Array(Len(::aLocalBuffer)))
         AEval(::aCache, {|x, i|HB_SYMBOL_UNUSED(x), ::aCache[i] := Array(Len(::aLocalBuffer))})
      ELSE
         ASize(::aIndexMgmnt, 0)
      ENDIF
      ::cFltUsr := ::SolveSQLFilters("A")
   ELSE
      ::cFltUsr := ""
      ASize(::aIndexMgmnt, 0)
   ENDIF

   IF !::lISAM    // load the result set to memory
      ::lGoTopOnFirstInteract := .T.
      ::IniFields(.T., .T., @aCacheInfo)

      IF ::aFields == NIL
         ::lOpened := .F.
         ::RuntimeErr("32", SR_Msg(32) , 2, EG_OPEN, ESQLRDD_OPEN)
         RETURN Self
      ENDIF

      // Load the cache to ::aCache

      ASize(::aCache, SR_ARRAY_BLOCK2)
      nAllocated := SR_ARRAY_BLOCK2
      n := 0

      IF ::hnRecno == NIL .OR. ::hnRecno == 0
         ::hnRecno := ::nFields + 1
         ::nFields ++
         ::lCanUpd := .F.
         ::lCanIns := .F.
         ::lCanDel := .F.
         lRecnoAdded := .T.
         AAdd(::aNames, ::cRecnoName)
         AAdd(::aFields, {::cRecnoName, "N", 15, 0})
         AAdd(::aEmptyBuffer, 0)
      ENDIF

      DO WHILE (::oSql:Fetch(, .F., ::aFields)) == SQL_SUCCESS
         n ++
         IF n > nAllocated
            SWITCH nAllocated
            CASE SR_ARRAY_BLOCK2
               nAllocated := SR_ARRAY_BLOCK3
               EXIT
            CASE SR_ARRAY_BLOCK3
               nAllocated := SR_ARRAY_BLOCK4
               EXIT
            CASE SR_ARRAY_BLOCK4
               nAllocated := SR_ARRAY_BLOCK5
               EXIT
            SR_OTHERWISE
               nAllocated += SR_ARRAY_BLOCK5
            ENDSWITCH

            ASize(::aCache, nAllocated)
         ENDIF

         ::aCache[n] := Array(::nFields)

         FOR i := 1 TO ::nFields
            IF lRecnoAdded .AND. i == ::nFields
               ::aCache[n, i] := n
               nMax := n
            ELSE
               ::aCache[n, i] := ::oSql:FieldGet(i, ::aFields, .F.)
            ENDIF
            IF !lRecnoAdded .AND. i == ::hnRecno
               nMax := Max(nMax, ::aCache[n, i])
            ENDIF
         NEXT i
      ENDDO

      ASize(::aCache, n)
      ::nLastRec := nMax
      ::aInfo[SR_AINFO_RCOUNT] := nMax
      ::aInfo[SR_AINFO_FCOUNT] := ::nFields
      ::aInfo[SR_AINFO_FOUND] := .F.
      ::aInfo[SR_AINFO_NPOSCACHE] := 1

      ::Default()

      ::oSql:FreeStatement()

   ELSE

      IF nPos < 1
         ::IniFields(.T., , @aCacheInfo)
      ENDIF

      IF ::aFields == NIL
         ::lOpened := .F.
         ::RuntimeErr("32", SR_Msg(32) + ": " + ::cFileName , 2, EG_OPEN, ESQLRDD_OPEN)
         RETURN Self
      ENDIF

      IF ::LineCount(.F.) == -1
         ::lOpened := .F.
         ::RuntimeErr("27", SR_Msg(27) , 2, EG_OPEN, ESQLRDD_OPEN)
         RETURN Self
      ENDIF

      IF Empty(::cCustomSQL) .AND. nPos <= 0
         IF SR_CheckMgmntInd()
            ::LoadRegisteredTags()
         ENDIF
      ENDIF

      AEval(::aCache, {|x, i|HB_SYMBOL_UNUSED(x), ::aCache[i] := Array(Len(::aLocalBuffer))})

      ::GetBuffer(.T.)         // Clean Buffer
      ::aInfo[SR_AINFO_BOF] := .T.

      ::nCurrentFetch := ::nFetchSize
      ::aInfo[SR_AINFO_SKIPCOUNT] := 0
      ::cLastMove := "OPEN"
      ::Optmizer_1e := ""
      ::Optmizer_1s := ""
      ::Optmizer_ne := {||""}
      ::Optmizer_ns := {||""}

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_AZURE
      CASE SQLRDD_RDBMS_CACHE
         ::Optmizer_1s := " TOP 1"
         ::Optmizer_ns := {|x|" TOP " + Str(x +2 , 5)}
         EXIT
      CASE SQLRDD_RDBMS_FIREBR
         IF ::oSql:cSystemVers >= "2.0"
            ::Optmizer_1e := " ROWS 1"
            ::Optmizer_ne := {|x|" ROWS " + Str(x + 2, 5)}
         ELSE
            ::Optmizer_1s := " FIRST 1"
            ::Optmizer_ns := {|x|" FIRST " + Str(x + 2, 5)}
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_INFORM
         ::Optmizer_1s := " FIRST 1"
         ::Optmizer_ns := {|x|" FIRST " + Str(x + 2, 5)}
         EXIT
      CASE SQLRDD_RDBMS_ORACLE
         //::Optmizer_1s := " /*+ FIRST_ROWS(1) */ "
         //::Optmizer_ns := {|x|" /*+ FIRST_ROWS(" + Str(x + 2, 5) + ") */ "}
         IF OracleMinVersion(::oSql:cSystemVers) < 9
            ::Optmizer_1s := " /* + FIRST_ROWS(1) */ "
            ::Optmizer_ns := {|x|" /* + FIRST_ROWS(" + Str(x + 2, 5) + ") */"}
         ELSE
            ::Optmizer_1s := " /* + FIRST_ROWS_1 */ "
            ::Optmizer_ns := {|x|" /* + FIRST_ROWS_" + ALLTRIM(Str(x+  2, 5)) + " */ "}
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_POSTGR
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
      CASE SQLRDD_RDBMS_CUBRID
         ::Optmizer_1e := " LIMIT 1"
         ::Optmizer_ne := {|x|" LIMIT " + Str(x + 2, 5)}
         EXIT
      CASE SQLRDD_RDBMS_IBMDB2
         IF !("DB2/400" $ ::oSql:cSystemName .OR. "SQLDS/VM" $ ::oSql:cSystemName)
            ::Optmizer_1e := " fetch first 1 row only"
            ::Optmizer_ne := {|x|" fetch first " + Str(x + 2, 5) + " rows only"}
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_SYBASE
         IF "12.53" $ ::oSql:cSystemVers
            ::Optmizer_1s := " TOP 1"
            ::Optmizer_ns := {|x|" TOP " + Str(x + 2, 5)}
         ENDIF
      ENDSWITCH
   ENDIF

   ::aInfo[SR_AINFO_HNRECNO] := ::hnRecno
   ::aInfo[SR_AINFO_HNDELETED] := ::hnDeleted

   ::nLogMode := ::oSql:nLogMode

   IF !SR_GetFastOpen()

      IF !lShared
         IF !::LockTable(.F.)
            ::lOpened := .F.
         ENDIF
         ::lSharedLock := .T. // EXCLUSIVE open have EXC and SHARED locks.
      ELSE
        IF !::LockTable(.T.)   // Test If can Lock the file for a moment in current ID
            ::lOpened := .F.
         ELSE
            ::lSharedLock := SR_SetLocks(SR_SHARED_TABLE_LOCK_SIGN + Upper(::cFileName), ::oSql)
         ENDIF
      ENDIF

      IF ::lOpened
         _SR_Register(Self)
      ENDIF
   ELSE
      _SR_Register(Self)
   ENDIF

   IF nPos <= 0 .AND. Empty(::cCustomSQL)
      aCacheInfo[SR_CACHEINFO_TABINFO] := aRet
      aCacheInfo[SR_CACHEINFO_TABNAME] := ::cFileName
      aCacheInfo[SR_CACHEINFO_CONNECT] := ::oSql
      aCacheInfo[SR_CACHEINFO_INDEX] := ::aIndexMgmnt
      ::oSql:aTableInfo[::cOriginalFN] := aCacheInfo
   ENDIF

   IF aRet[SR_TABLE_INFO_ALL_IN_CACHE]
      ::lGoTopOnFirstInteract := .T.
   ENDIF

RETURN Self

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:CreateOrclFunctions(cOwner, cFileName)

   LOCAL lRet
   LOCAL cTblName
   LOCAL cSql

   IF Len(cFileName) > SR_MAX_TABLE_NAME_LENGHT
      cTblName := subStr(cFileName, 1, SR_MAX_TABLE_NAME_LENGHT)
      cFileName := cTblName
   ELSE
      cTblName := cFileName
   ENDIF

   ::oSql:Exec("CREATE OR REPLACE FUNCTION " + cOwner + LimitLen(cFileName, 3) + "_SP RETURN NUMBER AS ID_R NUMBER; BEGIN SELECT " + cOwner + LimitLen(cFileName, 3) + "_SQ.NEXTVAL INTO ID_R FROM DUAL; RETURN ID_R; END;")

   cSql := "CREATE OR REPLACE TRIGGER " + cOwner + LimitLen(cFileName, 3) + "_SR BEFORE INSERT ON " +;
           cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + " FOR EACH ROW DECLARE v_seq " +;
           SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + "." + ::cRecnoName + "%TYPE; BEGIN If :OLD." +;
           ::cRecnoName + " IS NULL THEN SELECT " + cOwner + LimitLen(cFileName, 3) + "_SQ.NEXTVAL INTO v_seq FROM DUAL; :NEW." +;
           ::cRecnoName + " := v_seq; END IF; END;"
   lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS
   ::oSql:Commit()

RETURN lRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlZap()

   LOCAL nRet

   ::sqlGoCold()

   IF ::lCanDel

      nRet := ::oSql:execute(::cDel  + IIf(::oSql:lComments, " /* Zap */", ""), .F., ::nLogMode)

      ::oSql:FreeStatement()

      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO .AND. nRet != SQL_NO_DATA_FOUND
         RETURN .F.
      ENDIF

      IF ISFIREBIRD() .AND. ::oSql:lUseSequences .AND. ::lUseSequences
         ::oSql:Commit()
         ::oSql:Exec("SET GENERATOR " + ::cFileName + " TO 0")
         ::oSql:Commit()
      ENDIF
      IF ISPOSTGRESQL() .AND. ::oSql:lUseSequences .AND. ::lUseSequences
         ::oSql:Commit()
         ::oSql:Exec("select setval('" +::cOwner + LimitLen(::cFileName, 3) + "_SQ'  , 1)")
         ::oSql:Commit()
      ENDIF

#if 0
      IF ISORACLE() .AND. .AND. ::lUseSequences
         ::oSql:Commit()
         ::oSql:Exec("DROP SEQUENCE " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ", .F.)
         ::oSql:Commit()
         ::oSql:Exec("CREATE SEQUENCE " + ::cOwner + LimitLen(::cFileName, 3) + "_SQ START WITH 1")
         ::oSql:Commit()
      ENDIF
#endif
      ::sqlFlush()

      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0
      ::aInfo[SR_AINFO_EOF_AT] := 0
      ::aInfo[SR_AINFO_BOF_AT] := 0
      ::aInfo[SR_AINFO_EOF] := .T.
      ::aInfo[SR_AINFO_BOF] := .T.
   ELSE
      SR_MsgLogFile(SR_Msg(12) + ::cFileName)
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOrderListAdd(cBagName, cTag)

   LOCAL i
   LOCAL c
   LOCAL cWord := ""
   LOCAL aCols := {}
   LOCAL cList := ""
   LOCAL cOrdName
   LOCAL nPos
   LOCAL nInd
   LOCAL aInd := {}
   LOCAL nLen
   LOCAL cXBase := ""
   LOCAL cCol
   LOCAL nPosAt
   LOCAL cSqlA
   LOCAL cSqlD
   LOCAL aRet
   LOCAL lSyntheticVirtual := .F.
   LOCAL cPhysicalVIndexName
   LOCAL cVInd
   LOCAL uComp

   HB_SYMBOL_UNUSED(cList)

   IF !Empty(cVInd := SR_GetSVIndex())
      lSyntheticVirtual := ISORACLE()
      cPhysicalVIndexName := SubStr(cVInd, 1, 3) + SubStr(::cFileName, 1, 25)
   ELSEIF Len(cBagName) > 0 .AND. SubStr(cBagName, 4, 1) == "@"
      lSyntheticVirtual := ISORACLE()
      cPhysicalVIndexName := SubStr(cBagName, 1, 3) + SubStr(::cFileName, 1, 25)
      cBagName := SubStr(cBagName, 5)
   ELSE
      aRet := Eval(SR_GetIndexInfoBlock(), cBagName)
      ASize(aRet, SR_TABLE_INFO_SIZE)
      cBagName := SR_ParseFileName(aRet[SR_TABLE_INFO_TABLE_NAME])

      IF cTag == NIL .OR. Empty(AllTrim(cTag))

         // Check If the index is already open

         nInd := AScan(::aIndex, {|x|AllTrim(Upper(x[10])) == AllTrim(Upper(cBagName))})

         IF nInd > 0 .AND. DUPL_IND_DETECT
            // Index already opened
            RETURN nInd
         ENDIF

         // Not opened, than try find it in the orders management

         nInd := AScan(::aIndexMgmnt, {|x|AllTrim(Upper(x[SR_INDEXMAN_IDXNAME])) == AllTrim(Upper(cBagName))})
         IF nInd > 0
            AAdd(aInd, nInd)
            nInd ++
            DO WHILE nInd <= Len(::aIndexMgmnt)
               IF AllTrim(Upper(::aIndexMgmnt[nInd, SR_INDEXMAN_IDXNAME])) == AllTrim(Upper(cBagName))
                  AAdd(aInd, nInd)
               ELSE
                  EXIT
               ENDIF
               nInd ++
            ENDDO
         ENDIF
         cTag := NIL
      ELSE
         nInd := AScan(::aIndexMgmnt, {|x|AllTrim(Upper(x[SR_INDEXMAN_IDXNAME])) == AllTrim(Upper(cBagName)) .AND. AllTrim(Upper(x[SR_INDEXMAN_TAG])) == AllTrim(Upper(cTag))})
         IF nInd > 0
            // Index already opened
            AAdd(aInd, nInd)
         ENDIF
      ENDIF
   ENDIF

   // Check if BagName is a list of fields or a real index name

   cCol := ""

   IF Len(aInd) == 0
      FOR i := 1 TO Len(cBagName)
         c := SubStr(cBagName, i, 1)
         IF IsDigit(c) .OR. IsAlpha(c) .OR. c == "_" .OR. c == " "
            cWord += c
         ENDIF
         IF c $ "|-;+-/*" .AND. !Empty(cWord)
            AAdd(aCols, Upper(cWord))
            cCol += IIf(Len(cCol) != 0, ",", "") + Upper(cWord)
            cWord := ""
         ENDIF
      NEXT i
      IF Len(cWord) > 0
         AAdd(aCols, Upper(cWord))
         cCol += IIf(Len(cCol) != 0, ",", "") + Upper(cWord)
      ENDIF

      IF ::lHistoric
         AAdd(aCols, "DT__HIST")
         cCol += IIf(Len(cCol) != 0, ",", "") + "DT__HIST"
      ENDIF

      AAdd(aCols, ::cRecnoName)
      cCol += IIf(Len(cCol) != 0, ",", "") + ::cRecnoName

      AAdd(::aIndexMgmnt, {"", "", "Direct", aCols, "", "", "", "", &("{|| " + AllTrim(cBagName) + " }"), , IIf(lSyntheticVirtual, cPhysicalVIndexName, NIL)})

//      IF Empty(::cCustomSQL)
//         aInf := ::oSql:aTableInfo[::cOriginalFN]
//         aInf[SR_CACHEINFO_INDEX] := ::aIndexMgmnt
//      ENDIF

      AAdd(aInd, Len(::aIndexMgmnt))

   ENDIF

   FOR EACH nInd IN aInd

      IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])
         aCols := {"INDKEY_" + ::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS]}
      ELSE
         IF HB_IsChar(::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY])
            aCols := &("{" + ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY] + "}")
         ELSE
            aCols := ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY]
         ENDIF
      ENDIF
      cOrdName := ::aIndexMgmnt[nInd, SR_INDEXMAN_TAG]

      IF Empty(cOrdName)
         cOrdName := ""
      ENDIF

      IF ::aIndexMgmnt[nInd, SR_INDEXMAN_VIRTUAL_SYNTH] != NIL
         lSyntheticVirtual := .T.
         cPhysicalVIndexName := ::aIndexMgmnt[nInd, SR_INDEXMAN_VIRTUAL_SYNTH]
      ELSE
         cPhysicalVIndexName := NIL
      ENDIF

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_IBMDB2
         IF "08.0" $ ::oSql:cSystemVers .AND. (!"08.00" $ ::oSql:cSystemVers)
            cSqlA := " ORDER BY row_number() over( ORDER BY "
            cSqlD := " ORDER BY row_number() over( ORDER BY "
         ELSE
            cSqlA := " ORDER BY "
            cSqlD := " ORDER BY "
         ENDIF
         EXIT
      SR_OTHERWISE
         cSqlA := " ORDER BY "
         cSqlD := " ORDER BY "
      ENDSWITCH

      cXBase := ""

      AAdd(::aIndex, {"", "", {}, "", "", "", NIL, NIL, cOrdName, cBagName, , , , , , 0, SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_SIGNATURE], 19, 1) == "D", cPhysicalVIndexName, , , ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXNAME]})
      nLen := Len(::aIndex)

      FOR i := 1 TO Len(aCols)

         IF HB_IsChar(aCols[i]) .AND. "(" $ aCols[i]

            // Expression index component (UPPER/SUBSTR/LEFT/STRZERO/...)

            IF !::CanOpenExpressionIndex()
               ::RunTimeErr("18", SR_Msg(18) + aCols[i] + " Table : " + ::cFileName + ;
                  " (index uses a PostgreSQL expression key;" + ;
                  " it can only be opened on a PostgreSQL connection)")
               RETURN 0    // error exit
            ENDIF

            uComp := ::BuildIndexComponent(aCols[i])

            IF HB_IsArray(uComp)
               IF ::osql:lPostgresql8
                  cSqlA += " " + uComp[SR_IDXFLD_SQL] + " NULLS FIRST,"
                  cSqlD += " " + uComp[SR_IDXFLD_SQL] + " DESC NULLS LAST,"
               ELSE
                  cSqlA += " " + uComp[SR_IDXFLD_SQL] + ","
                  cSqlD += " " + uComp[SR_IDXFLD_SQL] + " DESC,"
               ENDIF
               cXBase += uComp[SR_IDXFLD_NAME] + " + "
               AAdd(::aIndex[nLen, SR_AINDEX_INDEX_FIELDS], uComp)
               LOOP
            ELSEIF HB_IsChar(uComp)
               aCols[i] := uComp       // STR()/DTOS() map to the plain column
            ELSE
               ::RunTimeErr("18", SR_Msg(18) + aCols[i] + " Table : " + ::cFileName)
               RETURN 0    // error exit
            ENDIF

         ENDIF

         nPosAt := At(aCols[i], " ")

         IF nPosAt == 0
            cCol := aCols[i]
         ELSE
            cCol := SubStr(aCols[i], 1, nPosAt)
         ENDIF

         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_ORACLE
         CASE SQLRDD_RDBMS_FIREBR
            cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " NULLS FIRST,"
            cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC NULLS LAST,"
            EXIT
         CASE SQLRDD_RDBMS_POSTGR
            IF ::osql:lPostgresql8
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " NULLS FIRST,"
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC NULLS LAST,"
            ELSE
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ","
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC,"
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_IBMDB2
            IF "08.0" $ ::oSql:cSystemVers .AND. (!"08.00" $ ::oSql:cSystemVers)
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " NULLS FIRST,"
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC NULLS LAST,"
            ELSE
               cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ","
               cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC,"
            ENDIF
            EXIT
         SR_OTHERWISE
            cSqlA += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + ","
            cSqlD += " A." + SR_DBQUALIFY(cCol, ::oSql:nSystemID) + " DESC,"
         ENDSWITCH

         IF (nPos := AScan(::aNames, {|x|x == cCol})) != 0
            IF ::aNames[nPos] != ::cRecnoName
               ::aIndex[nLen, SR_AINDEX_SYNTH_INDEX_COL_POS] := nPos
               SWITCH ::aFields[nPos, SR_FIELD_TYPE]
               CASE "C"
                  IF ::aNames[nPos] == ::cDeletedName
                     cXBase += "Deleted() + "
                  ELSE
                     cXBase += ::aNames[nPos] + " + "
                  ENDIF
                  EXIT
               CASE "D"
                  cXBase += "DTOS(" + ::aNames[nPos] + ") + "
                  EXIT
               CASE "T"
                  cXBase += "TTOS(" + ::aNames[nPos] + ") + " // TODO: TTOS -> HB_TTOS
                  EXIT
               CASE "N"
                  cXBase += "STR(" + ::aNames[nPos] + ", " + AllTrim(Str(::aFields[nPos, SR_FIELD_LEN])) + ", " + AllTrim(Str(::aFields[nPos, SR_FIELD_DEC])) + ") + "
                  EXIT
               CASE "L"
                  cXBase += "Sr_cdbvalue(" + ::aNames[nPos] + ")" + " + "
               ENDSWITCH
            ENDIF
         ELSE
            ::RunTimeErr("18", SR_Msg(18) + cCol + " Table : " + ::cFileName)
            RETURN 0       // error exit
         ENDIF

         AAdd(::aIndex[nLen, SR_AINDEX_INDEX_FIELDS], {aCols[i], nPos})

      NEXT i

      cXBase := Left(cXBase, Len(cXBase) - 2)

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_IBMDB2
         IF "08.0" $ ::oSql:cSystemVers .AND. (!"08.00" $ ::oSql:cSystemVers)
            cSqlA := Left(cSqlA, Len(cSqlA) - 1) + " ) "
            cSqlD := Left(cSqlD, Len(cSqlD) - 1) + " ) "
         ELSE
            cSqlA := Left(cSqlA, Len(cSqlA) - 1) + " "
            cSqlD := Left(cSqlD, Len(cSqlD) - 1) + " "
         ENDIF
         EXIT
      SR_OTHERWISE
         cSqlA := Left(cSqlA, Len(cSqlA) - 1) + " "
         cSqlD := Left(cSqlD, Len(cSqlD) - 1) + " "
      ENDSWITCH

      ::aIndex[nLen, SR_AINDEX_ORDER_ASCEND] := cSqlA
      ::aIndex[nLen, SR_AINDEX_ORDER_DESEND] := cSqlD
      ::aIndex[nLen, SR_AINDEX_INDEX_KEY] := RTrim(IIf(nInd > 0 .AND. (!Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])), ::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY], cXBase))
      IF !Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])

         IF RDDNAME() == "SQLEX"
            // SQLEX does not expose the INDKEY_ column as a field, so the key
            // codeblock must evaluate the original xBase expression client
            // side (same value stored in INDKEY_, without the recno suffix)
            ::aIndex[nLen, SR_AINDEX_INDEX_KEY_CODEBLOCK] := &("{|| SR_Val2Char(" + AllTrim(::aIndexMgmnt[nInd, SR_INDEXMAN_IDXKEY]) + ") }")
         ELSE
            ::aIndex[nLen, SR_AINDEX_INDEX_KEY_CODEBLOCK] := AScan(::aNames, "INDKEY_" + ::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])
         ENDIF
      ELSE
         ::aIndex[nLen, SR_AINDEX_INDEX_KEY_CODEBLOCK] := &("{|| " + cXBase + " }")
      ENDIF

      IF SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS], 1, 1) != "#"
         ::aIndex[nLen, SR_AINDEX_FOR_CLAUSE] := RTrim(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS])
      ELSE
         ::aIndex[nLen, SR_AINDEX_FOR_CLAUSE] := "INDFOR_" + SubStr(::aIndexMgmnt[nInd, SR_INDEXMAN_FOR_EXPRESS], 2, 3) + " = 'T'"
      ENDIF

      ::aIndex[nLen, SR_AINDEX_STR_DESCENDS] := ""
      ::aIndex[nLen, SR_AINDEX_SYNTH_INDEX_COL_POS] := IIf(nInd > 0 .AND. (!Empty(::aIndexMgmnt[nInd, SR_INDEXMAN_COLUMNS])), ::aIndex[nLen, SR_AINDEX_SYNTH_INDEX_COL_POS], 0)

      IF lSyntheticVirtual
         ::aIndex[nLen, SR_AINDEX_VIRTUAL_INDEX_EXPR] := ::GetSyntheticVirtualExpr(aCols, "A")
      ENDIF

   NEXT

   ::lStable := .F.
   ::lOrderValid := .T.

   IF ::aInfo[SR_AINFO_INDEXORD] == 0
      IF cTag == NIL
         ::aInfo[SR_AINFO_INDEXORD] := 1
         ::aInfo[SR_AINFO_REVERSE_INDEX] := ::aIndex[1, SR_AINDEX_DESCEND_INDEX_ORDER]
      ELSE
         ::aInfo[SR_AINFO_INDEXORD] := Len(::aIndex)
         ::aInfo[SR_AINFO_REVERSE_INDEX] := ::aIndex[Len(::aIndex), SR_AINDEX_DESCEND_INDEX_ORDER]
      ENDIF
   ENDIF

RETURN ::aInfo[SR_AINFO_INDEXORD] // Len(::aIndex) Controlling order should not be changed.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOrderListClear()

   ::aInfo[SR_AINFO_FOUND] := .F.
   ASize(::aIndex, 0)
   ::cFor := ""
   ::aInfo[SR_AINFO_INDEXORD] := 0
   ::lStable := .T.
   ::lOrderValid := .F.

RETURN .T.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOrderListFocus(uOrder, cBag)

   LOCAL nOrder := 0
   LOCAL i
   LOCAL aInd

   HB_SYMBOL_UNUSED(cBag)

   IF HB_IsChar(uOrder)      // TAG order
      nOrder := AScan(::aIndex, {|x|Upper(AllTrim(x[SR_AINDEX_ORDER_TAG])) == Upper(AllTrim(uOrder))})
      IF nOrder == 0 .OR. nOrder > Len(::aIndex)
         ::cFor := ""
         ::aInfo[SR_AINFO_INDEXORD] := 0
         ::RuntimeErr("19", SR_Msg(19) + SR_Val2Char(uOrder))
         RETURN 0 // error exit
      ENDIF
   ELSEIF HB_IsNumeric(uOrder)
      nOrder := uOrder
   ENDIF

   IF nOrder == ::aInfo[SR_AINFO_INDEXORD]
      RETURN nOrder
   ENDIF

   IF nOrder == 0 .OR. nOrder > Len(::aIndex)

      ::cFor := ""
      ::aInfo[SR_AINFO_INDEXORD] := 0

      IF nOrder > Len(::aIndex)
         ::RuntimeErr("19", SR_Msg(19) + AllTrim(SR_Val2Char(uOrder)) + ", " + ::cAlias)
      ENDIF

      ::aInfo[SR_AINFO_EOF_AT] := 0
      ::aInfo[SR_AINFO_BOF_AT] := 0

//      IF (!(::aInfo[SR_AINFO_EOF] .AND. ::aInfo[SR_AINFO_BOF])) .AND. !::aInfo[SR_AINFO_DELETED]
//         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
//         ::aInfo[SR_AINFO_NPOSCACHE] := 1
//         ACopy(::aLocalBuffer, ::aCache[1])
//      ELSE
         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
         ::aInfo[SR_AINFO_NPOSCACHE] := 0
//      ENDIF

      RETURN 0

   ENDIF

   ::cFor := ::aIndex[nOrder, SR_AINDEX_FOR_CLAUSE]

   IF !(nOrder == ::aInfo[SR_AINFO_INDEXORD] .AND. ::lStable)
      ::lStable := .F.
   ENDIF

   ::aInfo[SR_AINFO_INDEXORD] := nOrder
   ::aInfo[SR_AINFO_REVERSE_INDEX] := ::aIndex[nOrder, SR_AINDEX_DESCEND_INDEX_ORDER]
   ::lOrderValid := .T.
   ::aInfo[SR_AINFO_EOF_AT] := 0
   ::aInfo[SR_AINFO_BOF_AT] := 0

   IF (!(::aInfo[SR_AINFO_EOF] .AND. ::aInfo[SR_AINFO_BOF])) .AND. (!::aInfo[SR_AINFO_DELETED]) .AND. ::aInfo[SR_AINFO_NPOSCACHE] > 0
      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
      ::aInfo[SR_AINFO_NPOSCACHE] := 1
      ACopy(::aLocalBuffer, ::aCache[1])
   ELSE
      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0
   ENDIF

   aInd := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]
   FOR i := 1 TO Len(aInd)
      ::aSelectList[aInd[i, 2]] := 1
   NEXT i

RETURN nOrder

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOrderDestroy(uOrder, cBag)

   LOCAL nOrder := 0
   //LOCAL i
   //LOCAL aInd

   HB_SYMBOL_UNUSED(cBag)

   IF HB_IsChar(uOrder)      // TAG order
      nOrder := AScan(::aIndex, {|x|Upper(AllTrim(x[SR_AINDEX_ORDER_TAG])) == Upper(AllTrim(uOrder))})
      IF nOrder == 0 .OR. nOrder > Len(::aIndex)
         ::cFor := ""
         ::aInfo[SR_AINFO_INDEXORD] := 0
         ::RuntimeErr("19", SR_Msg(19) + SR_Val2Char(uOrder))
         RETURN 0
      ELSE
         SR_DropIndex(::aIndex[nOrder, SR_AINDEX_ORDER_TAG])
         hb_ADel(::aIndex, 12, .T.)
         RETURN 0
      ENDIF
   ELSEIF HB_IsNumeric(uOrder)
      nOrder := uOrder
      IF nOrder == 0 .OR. nOrder > Len(::aIndex)
         ::cFor := ""
         ::aInfo[SR_AINFO_INDEXORD] := 0
         ::RuntimeErr("19", SR_Msg(19) + SR_Val2Char(uOrder))
         RETURN 0
      ELSE
         SR_DropIndex(::aIndex[nOrder, SR_AINDEX_ORDER_TAG])
         hb_ADel(::aIndex, 12, .T.)
         RETURN 0
      ENDIF

   ENDIF

#if 0
   IF nOrder == 0 .OR. nOrder > Len(::aIndex)

      ::cFor := ""
      ::aInfo[SR_AINFO_INDEXORD] := 0

      IF nOrder > Len(::aIndex)
         ::RuntimeErr("19", SR_Msg(19) + AllTrim(SR_Val2Char(uOrder)) + ", " + ::cAlias)
      ENDIF

      ::aInfo[SR_AINFO_EOF_AT] := 0
      ::aInfo[SR_AINFO_BOF_AT] := 0

      // IF (!(::aInfo[SR_AINFO_EOF] .AND. ::aInfo[SR_AINFO_BOF])) .AND. !::aInfo[SR_AINFO_DELETED]
      //    ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
      //    ::aInfo[SR_AINFO_NPOSCACHE] := 1
      //    ACopy(::aLocalBuffer, ::aCache[1])
      // ELSE
         ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
         ::aInfo[SR_AINFO_NPOSCACHE] := 0
      // ENDIF

      RETURN 0

   ENDIF

   ::cFor := ::aIndex[nOrder, SR_AINDEX_FOR_CLAUSE]

   IF !(nOrder == ::aInfo[SR_AINFO_INDEXORD] .AND. ::lStable)
      ::lStable := .F.
   ENDIF

   ::aInfo[SR_AINFO_INDEXORD] := nOrder
   ::aInfo[SR_AINFO_REVERSE_INDEX] := ::aIndex[nOrder, SR_AINDEX_DESCEND_INDEX_ORDER]
   ::lOrderValid := .T.
   ::aInfo[SR_AINFO_EOF_AT] := 0
   ::aInfo[SR_AINFO_BOF_AT] := 0

   IF (!(::aInfo[SR_AINFO_EOF] .AND. ::aInfo[SR_AINFO_BOF])) .AND. (!::aInfo[SR_AINFO_DELETED]) .AND. ::aInfo[SR_AINFO_NPOSCACHE] > 0
      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 1
      ::aInfo[SR_AINFO_NPOSCACHE] := 1
      ACopy(::aLocalBuffer, ::aCache[1])
   ELSE
      ::aInfo[SR_AINFO_NCACHEEND] := ::aInfo[SR_AINFO_NCACHEBEGIN] := 0
      ::aInfo[SR_AINFO_NPOSCACHE] := 0
   ENDIF

   aInd := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]
   FOR i := 1 TO Len(aInd)
      ::aSelectList[aInd[i, 2]] := 1
   NEXT i
#endif

RETURN nOrder

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOrderListNum(uOrder)

   LOCAL nOrder := 0

   HB_SYMBOL_UNUSED(nOrder)

   IF HB_IsChar(uOrder)      // TAG order
      nOrder := AScan(::aIndex, {|x|Upper(AllTrim(x[SR_AINDEX_ORDER_TAG])) == Upper(AllTrim(uOrder))})
      IF nOrder == 0 .OR. nOrder > Len(::aIndex)
         RETURN 0 // error exit
      ENDIF
   ELSEIF HB_IsNumeric(uOrder)
      nOrder := uOrder
   ELSE
      nOrder := ::aInfo[SR_AINFO_INDEXORD]
   ENDIF

   IF nOrder == 0 .OR. nOrder > Len(::aIndex)
      RETURN 0 // error exit
   ENDIF

RETURN nOrder

//----------------------------------------------------------------------------//

METHOD sqlOrderCondition(cFor, cWhile, nStart, nNext, uRecord, lRest, lDesc)

   ::aLastOrdCond := {cFor, cWhile, nStart, nNext, uRecord, lRest, lDesc}

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlOrderCreate(cIndexName, cColumns, cTag, cConstraintName, cTargetTable, aTargetColumns, lEnable)

   LOCAL i
   LOCAL c
   LOCAL cWord := ""
   LOCAL aCols := {}
   LOCAL cNextTagNum
   LOCAL cFor
   LOCAL cForDb := ""
   LOCAL cColFor
   LOCAL aConstraintCols := {}
   LOCAL cList := ""
   LOCAL cList2 := ""
   LOCAL cListConstraint := ""
   LOCAL cListConstraint_Source := ""
   LOCAL lHaveTag
   LOCAL nNewTag
   LOCAL lTagFound
   LOCAL cPhisicalName
   LOCAL cSql
   LOCAL lRet
   LOCAL lSyntheticIndex := .F.
   LOCAL lInFunction := .F.
   LOCAL cColIndx
   LOCAL bIndexKey
   LOCAL bIndexFor
   LOCAL lInParams := .F.
   LOCAL aInf
   LOCAL nLenTag
   LOCAL nOldOrd
   LOCAL aRet
   LOCAL lDesc := .F.
   LOCAL lSyntheticVirtual := .F.
   LOCAL cPhysicalVIndexName
   LOCAL cPrevPhysicalVIndexName
   LOCAL nVI
   LOCAL lOK
   LOCAL cVInd
   LOCAL aOldPhisNames := {}
   LOCAL cName
   LOCAL aExprCols
   LOCAL nKeySize := 0

   HB_SYMBOL_UNUSED(nKeySize)

   HB_SYMBOL_UNUSED(lEnable)

   IF HB_IsArray(aTargetColumns) .AND. Len(aTargetColumns) > 0 .AND. HB_IsArray(aTargetColumns[1])
      aTargetColumns := aTargetColumns[1]
   ENDIF

   lHaveTag := !Empty(cTag)

   // Release any pending transaction before a DDL command

   ::sqlGoCold()

   IF ::oSql:nTransacCount >  0
      ::oSql:Commit()
      ::oSql:nTransacCount := 0
   ENDIF

   IF cConstraintName == NIL
      cConstraintName := ""
   ENDIF

   IF !Empty(cVInd := SR_GetSVIndex())
      lSyntheticVirtual := ISORACLE()
      cPhysicalVIndexName := SubStr(cVInd, 1, 3) + SubStr(::cFileName, 1, 25)
   ELSEIF Len(cColumns) > 4 .AND. SubStr(cColumns, 4, 1) == "@"
      lSyntheticVirtual := ISORACLE()
      cPhysicalVIndexName := SubStr(cColumns, 1, 3) + SubStr(::cFileName, 1, 25)
      cColumns := SubStr(cColumns, 5)
   ENDIF

   IF !SR_GetSyntheticIndex()
      FOR i := 1 TO Len(cColumns)
         c := SubStr(cColumns, i, 1)
         IF lInFunction .OR. lInParams
            IF c == ")"
               lInFunction := .F.
               lInParams := .F.
               IF !Empty(cWord)
                  AAdd(aCols, Upper(cWord))
                  cWord := ""
               ENDIF
            ELSEIF c $ "," .AND. !Empty(cWord)
               AAdd(aCols, Upper(cWord))
               cWord := ""
               lInParams := .T.
            ELSEIF c $ ","
               lInParams := .T.
            ELSEIF c $ "("       // dtos(otherfunc()) not allowed
               lSyntheticIndex := .T.
               EXIT
            ELSEIF c == "-" .AND. SubStr(cColumns, i + 1, 1) == ">"
               IF s_lAllowRelationsInIndx
                  lSyntheticIndex := .T.
                  EXIT
               ENDIF
               i ++
               cWord := ""
            ELSEIF IsAlpha(c) .OR. c == "_" .OR. (IsDigit(c) .AND. (IsAlpha(Left(cWord, 1)) .OR. Left(cWord, 1) == "_"))
               cWord += c
            ENDIF
         ELSE
            IF IsDigit(c) .OR. IsAlpha(c) .OR. c == "_"
               cWord += c
            ENDIF
            IF c == "("
               IF Upper(cWord) == "STR"
                  cWord := ""
                  lInFunction := .T.
               ELSEIF Upper(cWord) == "DTOS"
                  cWord := ""
                  lInFunction := .T.
               ELSEIF Upper(cWord) == "DELETED" .AND. ::hnDeleted > 0
                  AAdd(aCols, ::cDeletedName)
                  cWord := ""
               ELSEIF Upper(cWord) == "RECNO"
                  cWord := ""
                  lInFunction := .T.
               ELSE
                  lSyntheticIndex := .T.
                  lSyntheticVirtual := .F.
                  EXIT
               ENDIF
            ELSE
               IF c $ "|-;+-/*" .AND. !Empty(cWord)
                  IF c == "-" .AND. SubStr(cColumns, i + 1, 1) == ">"
                     IF s_lAllowRelationsInIndx
                        lSyntheticIndex := .T.
                        EXIT
                     ENDIF
                     i ++
                  ELSE
                     AAdd(aCols, Upper(cWord))
                  ENDIF
                  cWord := ""
               ENDIF
            ENDIF
         ENDIF
      NEXT i
   ELSE
      lSyntheticIndex := .T.
      lSyntheticVirtual := .F.
   ENDIF

   IF !lSyntheticIndex
      IF Len(cWord) > 0
         AAdd(aCols, Upper(cWord))
      ENDIF
   ENDIF

   // Second chance (PostgreSQL): keys using translatable Harbour functions
   // (UPPER, SUBSTR, LEFT, STRZERO, ...) become native expression indexes
   // instead of a synthetic INDKEY_ column. Only untranslatable (user
   // defined) functions still fall back to the synthetic column.

   IF lSyntheticIndex .AND. !SR_GetSyntheticIndex() .AND. ::CanUseExpressionIndex()
      aExprCols := ::ParseIndexComponents(cColumns)
      IF aExprCols != NIL
         lSyntheticIndex := .F.
         aCols := aExprCols
      ENDIF
   ENDIF

   IF !Empty(AllTrim(cConstraintName))
      aConstraintCols := {}
      AEval(aCols, {|x|AAdd(aConstraintCols, IIf(HB_IsArray(x), ::aNames[x[SR_IDXFLD_POS]], x))})
   ENDIF

   IF !lSyntheticIndex

      IF ::lHistoric
         AAdd(aCols, "DT__HIST")
      ENDIF

      IF ((!::lHistoric .AND. Len(aCols) == 1) .OR. (::lHistoric .AND. Len(aCols) == 2))
         IF HB_IsArray(aCols[1]) .OR. AllTrim(aCols[1]) != ::cRecnoName   //minor hack for indexes with only recno (or history) column....
            AAdd(aCols, ::cRecnoName)
         ENDIF
      ELSE
         AAdd(aCols, ::cRecnoName)
      ENDIF
   ENDIF

   IF !lSyntheticIndex .AND. Len(aCols) > SR_GetSyntheticIndexMinimun()
      IF ::CanUseExpressionIndex()
         // Legacy rule: keys with many columns used to become synthetic. When
         // expression indexes are enabled PostgreSQL handles multi column and
         // expression indexes natively, so keep the regular index instead of
         // creating an INDKEY_ column.
      ELSEIF ::oSql:nSystemID != SQLRDD_RDBMS_ORACLE
         lSyntheticIndex := .T.
         lSyntheticVirtual := .F.
      ELSE     // Oracle can workaround with SinthetycVirtualIndex

         IF !SR_GetOracleSyntheticVirtual() // if set to false, use normal index, dont created the function based indexes
            lSyntheticIndex := .T.
            lSyntheticVirtual := .F.
         ELSE
            lSyntheticVirtual := .T.
            ::LoadRegisteredTags()

            nVI := 1

            DO WHILE nVI <= 999     // Determine an automatic name for SVI (SyntheticVirtualIndex)
               lOk := .T.
               FOR i := 1 TO Len(::aIndexMgmnt)
                  IF ::aIndexMgmnt[i, SR_INDEXMAN_VIRTUAL_SYNTH] != NIL .AND. subStr(::aIndexMgmnt[i, SR_INDEXMAN_VIRTUAL_SYNTH], 1, 3) == StrZero(nVI, 3)
                     nVI++
                     lOk := .F.
                     EXIT
                  ENDIF
               NEXT i
               IF lOK
                  cPhysicalVIndexName := StrZero(nVI, 3) + SubStr(::cFileName, 1, 25)
                  EXIT
               ENDIF
            ENDDO
         ENDIF
      ENDIF
   ENDIF

   aRet := Eval(SR_GetIndexInfoBlock(), cIndexName)
   ASize(aRet, SR_TABLE_INFO_SIZE)

   cIndexName := SR_ParseFileName(aRet[SR_TABLE_INFO_TABLE_NAME])

   IF Empty(cIndexName)
      cIndexName := ::cFileName
   ENDIF

   IF Empty(cTag) .AND. (!Empty(cIndexName)) .AND. (!lSyntheticIndex)
      cTag := cIndexName
   ENDIF

   IF ISSYBASE()
      ::oSql:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON)
   ENDIF

   // Removes from the control structures

   ASize(::aIndexMgmnt, 0)
   ::oSql:Exec("SELECT TABLE_,SIGNATURE_,IDXNAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_,PHIS_NAME_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES  WHERE TABLE_ = '" + Upper(::cFileName) + "' AND IDXNAME_ = '" + Upper(AllTrim(cIndexName)) + "'" + IIf(lHaveTag, " AND TAG_ = '" + cTag + "'", "") + " ORDER BY IDXNAME_, TAGNUM_", .T., .T., @::aIndexMgmnt)

   FOR i := 1 TO Len(::aIndexMgmnt)
      AAdd(aOldPhisNames, AllTrim(::aIndexMgmnt[i, 9]))
      IF !Empty(::aIndexMgmnt[i, SR_INDEXMAN_COLUMNS])
         ::DropColumn("INDKEY_" + AllTrim(::aIndexMgmnt[i, SR_INDEXMAN_COLUMNS]), .F.)
      ENDIF
      IF SubStr(::aIndexMgmnt[i, SR_INDEXMAN_FOR_EXPRESS], 1, 1) == "#"
         ::DropColumn("INDFOR_" + SubStr(::aIndexMgmnt[i, SR_INDEXMAN_FOR_EXPRESS], 2, 3), .F., .T.)
      ENDIF
      IF Len(::aIndexMgmnt[i, SR_INDEXMAN_IDXKEY]) > 4 .AND. SubStr(::aIndexMgmnt[i, SR_INDEXMAN_IDXKEY], 4, 1) == "@"
         cPrevPhysicalVIndexName := SubStr(::aIndexMgmnt[i, SR_INDEXMAN_IDXKEY], 1, 3) + SubStr(::cFileName, 1, 25)
      ENDIF
   NEXT i

   IF HB_IsArray(::aLastOrdCond) .AND. Len(::aLastOrdCond) > 1
      IF ::aLastOrdCond[1] != NIL
         // Try to create an easy xBase => SQL translation
         cFor := ::ParseForClause(::aLastOrdCond[1])

         // Try FOR clause in SQL
         IF ::oSql:Exec("SELECT A.* FROM " + ::cQualifiedTableName + " A WHERE 0 = 1 AND (" + cFor + ")", .F.) == SQL_SUCCESS
            cForDb := cFor
         ELSE
            i := 1
            DO WHILE AScan(::aNames, {|x|Upper(x) == "INDFOR_" + StrZero(i, 3)}) > 0
               i++
            ENDDO
            cForDB := "#" + StrZero(i, 3) + ::aLastOrdCond[1]
            cColFor := "INDFOR_" + StrZero(i, 3)
            bIndexFor := &("{|| " + AllTrim(::aLastOrdCond[1]) + " }")
            ::AlterColumns({{cColFor, "C", 1, 0, , SQL_CHAR}}, .F.)
            ::Refresh()
         ENDIF
      ENDIF

      IF ::aLastOrdCond[7] != NIL
         lDesc := ::aLastOrdCond[7]
      ENDIF
   ENDIF

   ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(::cFileName) + "' AND IDXNAME_ = '" + Upper(AllTrim(cIndexName)) + "'" + IIf(lHaveTag, " AND TAG_ = '" + cTag + "'", "") + IIf(::oSql:lComments, " /* Wipe index info 01 */", ""), .F.)
   ::oSql:Commit()

   ASize(::aIndexMgmnt, 0)
   ::oSql:Exec("SELECT TABLE_,SIGNATURE_,IDXNAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(::cFileName) + "' ORDER BY IDXNAME_, TAGNUM_", .F., .T., @::aIndexMgmnt)
   ::oSql:Commit()

   cNextTagNum := StrZero(Val(IIf(Len(::aIndexMgmnt) == 0, "0", ::aIndexMgmnt[Len(::aIndexMgmnt), SR_INDEXMAN_TAGNUM])) + 1, 6)

   // Create the index

   ::oSql:Commit()      // All Locks should be released to INDEX a table

   nLenTag := Len(IIf(lHaveTag, "_" + cTag, "_" + cNextTagNum))
   cPhisicalName := cIndexName + IIf(lHaveTag, "_" + cTag, "_" + cNextTagNum)

   IF Len(cIndexName) + nLenTag > 30
      cPhisicalName := Left(cIndexName, 30 - nLenTag) + IIf(lHaveTag, "_" + cTag, "_" + cNextTagNum)
   ENDIF
   IF ISORACLE() .AND. Len(cPhisicalName) > 30     // Oracle sucks!
      cPhisicalName := Right(cPhisicalName, 30)
   ENDIF
   IF ISIBMDB2() .AND. Len(cPhisicalName) > 18     // DB2 sucks!
      cPhisicalName := Right(cPhisicalName, 18)
   ENDIF
   IF SubStr(cPhisicalName, 1, 1) == "_"
      cPhisicalName := "I" + SubStr(cPhisicalName, 2) // cPhisicalName[1] := "I"
   ENDIF

   IF lSyntheticIndex

      lTagFound := .F.
      HB_SYMBOL_UNUSED(lTagFound)

      IF Len(cColumns) > 4 .AND. SubStr(cColumns, 4, 1) == "@"
         cColumns := SubStr(cColumns, 5)
      ENDIF

      // look for an empty tag column

      FOR nNewTag := 1 TO 120
         lTagFound := .T.
         FOR i := 1 TO Len(::aIndexMgmnt)
            IF SubStr(::aIndexMgmnt[i, SR_INDEXMAN_COLUMNS], 1, 3) == StrZero(nNewTag, 3)
               lTagFound := .F.
               EXIT
            ENDIF
         NEXT i
         IF lTagFound .OR. Len(::aIndexMgmnt) == 0
            EXIT
         ENDIF
      NEXT nNewTag

      cColIndx := "INDKEY_" + StrZero(nNewTag, 3)

      aCols := {cColIndx}

      bIndexKey := &("{|| " + AllTrim(cColumns) + " }")

      // Update all records with the index key

      nOldOrd := (::cAlias)->(IndexOrd())

      (::cAlias)->(DBSetOrder(0))
      (::cAlias)->(DBGoTop())

      nKeySize := Len(SR_Val2Char(Eval(bIndexKey))) +15

      // Create the index column in the table and add it to aCols
      IF ISFIREBIRD()
         ::AlterColumns({{cColIndx, "C", Min(nKeySize, 180), 0, , SQL_CHAR}}, .F., .F.)
      ELSE
         ::AlterColumns({{cColIndx, "C", Min(nKeysize, 254), 0, , SQL_CHAR}}, .F., .F.)
      ENDIF

      ::Refresh()
//       bIndexKey := &("{|| " + AllTrim(cColumns) + " }")
//
//       // Update all records with the index key
//
//       nOldOrd := (::cAlias)->(IndexOrd())
//
//       (::cAlias)->(DBSetOrder(0))
//       (::cAlias)->(DBGoTop())

      IF cColFor == NIL
         DO WHILE !(::cAlias)->(Eof())
            IF ISPOSTGRESQL()
               ::oSql:Exec(::cUpd + cColIndx + " = E'" + SR_ESCAPESTRING(SR_Val2Char(Eval(bIndexKey)) + Str(RecNo(), 15), ::oSql:nSystemID) + "' WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + Str((::cAlias)->(RecNo())))
            ELSE
               ::oSql:Exec(::cUpd + cColIndx + " = '" + SR_ESCAPESTRING(SR_Val2Char(Eval(bIndexKey)) + Str(RecNo(), 15), ::oSql:nSystemID) + "' WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + Str((::cAlias)->(RecNo())))
            ENDIF
            (::cAlias)->(dbSkip())
         ENDDO
      ELSE
         DO WHILE !(::cAlias)->(Eof())
            IF ISPOSTGRESQL()
               ::oSql:Exec(::cUpd + cColIndx + " = E'" + SR_ESCAPESTRING(SR_Val2Char(Eval(bIndexKey)) + Str(RecNo(), 15), ::oSql:nSystemID) + "' WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + Str((::cAlias)->(RecNo())))
            ELSE
               ::oSql:Exec(::cUpd + cColIndx + " = '" + SR_ESCAPESTRING(SR_Val2Char(Eval(bIndexKey)) + Str(RecNo(), 15), ::oSql:nSystemID) + "' WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + Str((::cAlias)->(RecNo())))
            ENDIF
            ::oSql:Exec(::cUpd + cColFor  + " = '" + IIf(Eval(bIndexFor), "T", "F") + "' WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + Str((::cAlias)->(RecNo())))
            (::cAlias)->(dbSkip())
         ENDDO
         IF Len(aCols) < 9    // If index has 9 or more columns... no sense to optimize!
            AAdd(aCols, cColFor)
         ENDIF
      ENDIF

      ::oSql:Commit()
      (::cAlias)->(DBSetOrder(nOldOrd))

      IF ::lHistoric
         IF Len(aCols) < 9    // If index has 9 or more columns... no sense to optimize!
            AAdd(aCols, "DT__HIST")
         ENDIF
      ENDIF

      IF ISPOSTGRESQL() .AND. ::osql:lPostgresql8
               // PGS 8.3 will use it once released
         FOR i := 1 TO Len(aCols)
            cList += SR_DBQUALIFY(aCols[i], ::oSql:nSystemID) + " NULLS FIRST"
            cList += IIf(i == Len(aCols), "", ",")
            cList2 += Chr(34) + aCols[i] + Chr(34)
            cList2 += IIf(i == Len(aCols), "", ",")
         NEXT i
      ELSE
         FOR i := 1 TO Len(aCols)
            cList += SR_DBQUALIFY(aCols[i], ::oSql:nSystemID)
            cList += IIf(i == Len(aCols), "", ",")
            cList2 += Chr(34) + aCols[i] + Chr(34)
            cList2 += IIf(i == Len(aCols), "", ",")
         NEXT i
      ENDIF

      // Drop the index

      IF !Empty(AllTrim(cConstraintName))
         IF ISORACLE() .OR. (ISMYSQL() .OR. ISMARIADB())
            ::DropConstraint(::cFileName, AllTrim(cConstraintName), .T.)
         ENDIF
      ENDIF

      IF AScan(aOldPhisNames, cPhisicalName) == 0
         AAdd(aOldPhisNames, cPhisicalName)
      ENDIF

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_MSSQL6
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_AZURE
      CASE SQLRDD_RDBMS_SYBASE
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + ::cQualifiedTableName + "." + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create synthetic Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + cName + " ON " + ::cQualifiedTableName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create synthetic Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_ORACLE
         IF cPhysicalVIndexName != NIL
            ::oSql:Exec("DROP INDEX " + ::cOwner + "A$" + cPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
            ::oSql:Exec("DROP INDEX " + ::cOwner + "D$" + cPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
         ENDIF
         IF cPrevPhysicalVIndexName != NIL
            ::oSql:Exec("DROP INDEX " + ::cOwner + "A$" + cPrevPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
            ::oSql:Exec("DROP INDEX " + ::cOwner + "D$" + cPrevPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
         ENDIF
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + ::cOwner + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + ::cOwner + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql += IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx())
         cSql +=  + IIf(::oSql:lComments, " /* Create synthetic Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_IBMDB2
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + ::cOwner + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + ::cOwner + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create synthetic Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_FIREBR
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
            ::oSql:Exec("DROP INDEX " + cName + "R" + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         HB_SYMBOL_UNUSED(lRet)
         cSql := "CREATE DESCENDING INDEX " + cPhisicalName + "R ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      SR_OTHERWISE
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create synthetic Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
      ENDSWITCH

      IF lRet
         ::oSql:Commit()
         cSql := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTINDEXES (TABLE_,SIGNATURE_,IDXNAME_,PHIS_NAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_) VALUES ( '" + Upper(::cFileName) + "','" + DToS(Date()) + " " + Time() + IIf(lDesc, " D", " A") + "','"
         cSql += Upper(AllTrim(cIndexName)) + "','" + cPhisicalName + "','" + SR_ESCAPESTRING(cColumns, ::oSql:nSystemID) + "','" + SR_ESCAPESTRING(cForDB, ::oSql:nSystemID) + "','" + StrZero(nNewTag, 3) + "','" + cTag + "','" + cNextTagNum + "' )"
         ::oSql:Exec(cSql, .T.)
      ENDIF

   ELSE     // Not a Synthetic Index

      IF cColFor != NIL
         nOldOrd := (::cAlias)->(IndexOrd())
         (::cAlias)->(DBSetOrder(0))
         (::cAlias)->(DBGoTop())
         DO WHILE !(::cAlias)->(Eof())
            ::oSql:Exec(::cUpd + cColFor + " = '" + IIf(Eval(bIndexFor), "T", "F") + "' WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + Str((::cAlias)->(RecNo())))
            (::cAlias)->(DBSkip())
         ENDDO
         ::oSql:Commit()
         (::cAlias)->(DBSetOrder(nOldOrd))
      ENDIF

      IF ISPOSTGRESQL() .AND. ::osql:lPostgresql8
               // PGS 8.3 will use it once released
         FOR i := 1 TO Len(aCols)
            IF HB_IsArray(aCols[i])
               // Expression index component: index the SQL expression itself
               cList += "(" + StrTran(aCols[i][SR_IDXFLD_SQL], "A.", "") + ") NULLS FIRST"
               cList2 += Chr(34) + aCols[i][SR_IDXFLD_NAME] + Chr(34)
            ELSE
               cList += SR_DBQUALIFY(aCols[i], ::oSql:nSystemID) + " NULLS FIRST"
               cList2 += Chr(34) + aCols[i] + Chr(34)
            ENDIF
            cList += IIf(i == Len(aCols), "", ",")
            cList2 += IIf(i == Len(aCols), "", ",")
         NEXT i
      ELSE
         FOR i := 1 TO Len(aCols)
            IF HB_IsArray(aCols[i])
               cList += "(" + StrTran(aCols[i][SR_IDXFLD_SQL], "A.", "") + ")"
               cList2 += Chr(34) + aCols[i][SR_IDXFLD_NAME] + Chr(34)
            ELSE
               cList += SR_DBQUALIFY(aCols[i], ::oSql:nSystemID)
               cList2 += Chr(34) + aCols[i] + Chr(34)
            ENDIF
            cList += IIf(i == Len(aCols), "", ",")
            cList2 += IIf(i == Len(aCols), "", ",")
         NEXT i
      ENDIF

      // Drop the index

      IF !Empty(AllTrim(cConstraintName))
         IF ISORACLE() .OR. (ISMYSQL() .OR. ISMARIADB())
            ::DropConstraint(::cFileName, AllTrim(cConstraintName), .T.)
         ENDIF
      ENDIF

      IF AScan(aOldPhisNames, cPhisicalName) == 0
         AAdd(aOldPhisNames, cPhisicalName)
      ENDIF

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_MSSQL6
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_AZURE
      CASE SQLRDD_RDBMS_SYBASE
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + ::cQualifiedTableName + "." + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + cName + " ON " + ::cQualifiedTableName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_ORACLE
         IF cPhysicalVIndexName != NIL
            ::oSql:Exec("DROP INDEX " + ::cOwner + "A$" + cPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
            ::oSql:Exec("DROP INDEX " + ::cOwner + "D$" + cPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
         ENDIF
         IF cPrevPhysicalVIndexName != NIL
            ::oSql:Exec("DROP INDEX " + ::cOwner + "A$" + cPrevPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
            ::oSql:Exec("DROP INDEX " + ::cOwner + "D$" + cPrevPhysicalVIndexName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
         ENDIF
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + ::cOwner + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + ::cOwner + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql += IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx())
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_IBMDB2
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + ::cOwner + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + ::cOwner + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      CASE SQLRDD_RDBMS_FIREBR
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
            ::oSql:Exec("DROP INDEX " + cName + "R" + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
            ::oSql:Commit()
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         HB_SYMBOL_UNUSED(lRet)
         cSql := "CREATE DESCENDING INDEX " + cPhisicalName + "R ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         EXIT
      SR_OTHERWISE
         FOR EACH cName IN aOldPhisNames
            ::oSql:Exec("DROP INDEX " + cName + IIf(::oSql:lComments, " /* Create Index */", ""), .F.)
         NEXT
         cSql := "CREATE INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + " (" + cList + ")"
         ::oSql:Commit()
         cSql +=  + IIf(::oSql:lComments, " /* Create regular Index */", "")
         lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
      ENDSWITCH

      IF lRet
         ::oSql:Commit()

         IF lSyntheticVirtual    // Should we create the Virtual Index too ?
            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_ORACLE
               cSql := "CREATE INDEX " + ::cOwner + "A$" + cPhysicalVIndexName + " ON " + ::cQualifiedTableName + " (" + ::GetSyntheticVirtualExpr(aCols) + ")" +IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx())
               lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
               ::oSql:Commit()
               IF lRet
                  cSql := "CREATE INDEX " + ::cOwner + "D$" + cPhysicalVIndexName + " ON " + ::cQualifiedTableName + " (" + ::GetSyntheticVirtualExpr(aCols) + " DESC )" +IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx())
                  lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
                  ::oSql:Commit()
               ENDIF
            ENDSWITCH
         ENDIF

         IF lRet
            cSql := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTINDEXES (TABLE_,SIGNATURE_,IDXNAME_,PHIS_NAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_) VALUES ( '" + Upper(::cFileName) + "','" + DToS(Date()) + " " + Time() + IIf(lDesc, " D", " A") + "','"
            cSql += Upper(AllTrim(cIndexName)) + "','" + cPhisicalName + "','" + IIf(lSyntheticVirtual, SubStr(cPhysicalVIndexName, 1, 3) + "@", "") + SR_ESCAPESTRING(cList2, ::oSql:nSystemID) + "','" + SR_ESCAPESTRING(cForDB, ::oSql:nSystemID) + "',NULL,'" + cTag + "','" + cNextTagNum  + "' )"
            ::oSql:Exec(cSql, .T.)
            ::oSql:Commit()
         ENDIF
      ENDIF
   ENDIF

   IF !Empty(AllTrim(cConstraintName))

      cConstraintName := Upper(AllTrim(cConstraintName))
      cTargetTable := Upper(AllTrim(cTargetTable))

      FOR i := 1 TO Len(aTargetColumns)

         cListConstraint += aTargetColumns[i]
         cListConstraint += IIf(i == Len(aTargetColumns), "", ",")

         cListConstraint_Source += aConstraintCols[i]
         cListConstraint_Source += IIf(i == Len(aTargetColumns), "", ",")

      NEXT i

      IF Len(aTargetColumns) > Len(aConstraintCols)

         ::RunTimeErr("29", SR_Msg(29) + " Table: " + ::cFileName + " Index columns list: " + Upper(AllTrim(cListConstraint_Source)) + " Constraint columns list: " + Upper(AllTrim(cListConstraint)))

      ENDIF

      ASize(aConstraintCols, Len(aTargetColumns))

      ::CreateConstraint(::cFileName, aConstraintCols, cTargetTable, aTargetColumns, cConstraintName)

   ENDIF

   ::oSql:Commit()
   ::LoadRegisteredTags()

   aInf := ::oSql:aTableInfo[::cOriginalFN]
   aInf[SR_CACHEINFO_INDEX] := ::aIndexMgmnt

   IF ISSYBASE()
      ::oSql:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF)
   ENDIF

   ::aLastOrdCond := NIL

RETURN ::sqlOrderListAdd(cIndexName, cTag)

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlClearScope()

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlSetScope(nType, uValue)

   LOCAL uKey
   LOCAL nLenKey
   LOCAL cPart
   LOCAL nCons
   LOCAL nLen
   LOCAL cSep2
   LOCAL cExpr
   LOCAL aNulls
   LOCAL aNotNulls
   LOCAL i
   LOCAL j
   LOCAL cType := ""
   LOCAL lPartialSeek := .F.
   LOCAL cRet
   LOCAL cRet2
   LOCAL nFDec
   LOCAL nFLen
   LOCAL nScoping
   LOCAL nSimpl
   LOCAL nThis
   LOCAL cSep
   LOCAL cQot
   LOCAL cNam
   LOCAL nFeitos
   LOCAL lNull
   LOCAL aFld

   HB_SYMBOL_UNUSED(cType)

   IF Len(::aIndex) > 0 .AND. ::aInfo[SR_AINFO_INDEXORD] > 0

      IF HB_IsBlock(uValue)
         uKey := Eval(uValue)
      ELSE
         uKey := uValue
         IF HB_IsChar(uKey)
            IF Len(uKey) == 0
               uKey := NIL
            ENDIF
         ENDIF
      ENDIF

      SWITCH nType
      CASE TOPSCOPE
         ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE] := uKey
         EXIT
      CASE BOTTOMSCOPE
         ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE] := uKey

         IF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE] == ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE]
            IF HB_IsChar(uKey)
               ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE] := uKey + "|"
            ENDIF
         ENDIF
         EXIT
      CASE TOP_BOTTOM_SCOPE
         ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE] := uKey
         ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE] := uKey
         EXIT
      SR_OTHERWISE
         RETURN -1         // Error
      ENDSWITCH

      // Create the SQL expression based on the scope data

      ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_SCOPE_SQLEXPR] := NIL
      ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_UP] := NIL
      ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_DOWN] := NIL

      IF nType == TOP_BOTTOM_SCOPE .OR. (::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE] != NIL .AND. ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE] != NIL .AND.;
         ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE] == ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE])

         nLen := Max(Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]) - 1, 1)      // -1 to remove RECNO from index key

         SWITCH ValType(uKey)

         CASE "N"
         CASE "D"
         CASE "L"

            lNull := ::IndexFieldNul(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])
            nFDec := ::IndexFieldDec(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])
            nFLen := ::IndexFieldLen(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])

            cQot := ::QuotedNull(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE], , nFLen, nFDec, , lNull)
            cSep := IIf(cQot == "NULL", " IS ", " = ")
            cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])

            cRet := " " + cNam + cSep + cQot + " "

            IF cQot == "NULL"
               IF HB_IsNumeric(uKey)
                  cRet := "( " + cRet + " OR " + cNam + " = 0 )"
               ELSEIF HB_IsDate(uKey) //ValType(uKey) == "D"
                  cRet := "( " + cRet + " OR " + cNam + " <= " + ::QuotedNull(SToD("19000101"), , nFLen, nFDec, , lNull) + " )"
               ENDIF
            ENDIF

            IF !Empty(cRet)
               ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_SCOPE_SQLEXPR] := " ( " + cRet + " ) "
            ENDIF

            EXIT

         CASE "C"

            ::aQuoted := {}
            ::aDat := {}
            ::aPosition := {}
            ::aSeekXF := {}
            nCons := 0
            nLenKey := Len(uKey)
            cPart := ""
            HB_SYMBOL_UNUSED(cPart)

            // First, split uKey in fields and values according to current index

            FOR i := 1 TO nLen

               aFld := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]

               nThis := ::IndexFieldLen(aFld)
               cPart := SubStr(uKey, nCons + 1, nThis)

               IF AllTrim(cPart) == "%"
                  EXIT
               ENDIF

               AAdd(::aPosition, aFld[SR_IDXFLD_POS])

               IF Len(aFld) >= SR_IDXFLD_XFORM .AND. aFld[SR_IDXFLD_XFORM] != NIL
                  AAdd(::aSeekXF, IdxBlkPad(aFld[SR_IDXFLD_XFORM], nThis))
               ELSE
                  AAdd(::aSeekXF, NIL)
               ENDIF

               cType := ::IndexFieldType(aFld)
               lNull := ::IndexFieldNul(aFld)
               nFDec := ::IndexFieldDec(aFld)
               HB_SYMBOL_UNUSED(nFDec)
               nFLen := ::IndexFieldLen(aFld)
               HB_SYMBOL_UNUSED(nFLen)

               IF i == 1 .AND. nThis >= Len(uKey)
                  IF uKey == ""
                     EXIT
                  ENDIF
               ELSE
                  IF Len(cPart) == 0
                     EXIT
                  ENDIF
               ENDIF

               AAdd(::aQuoted, ::QuotedNull(::ConvType(cPart, cType, @lPartialSeek, nThis, SR_SetGoTopOnScope()), .T., , , , lNull))  // This SR_SetGoTopOnScope() here is a NewAge issue.
               AAdd(::aDat,    ::ConvType(RTrim(cPart), cType, , nThis))

               nCons += nThis

               IF nLenKey < nCons
                  EXIT
               ENDIF

            NEXT i

            cRet := ""
            nLen := Min(nLen, Len(::aQuoted))
            nFeitos := 0

            FOR i := 1 TO nLen
               cQot := ::aQuoted[i]
               cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i])

               IF lPartialSeek .AND. i == nLen
                  cSep := " >= "
               ELSE
                  cSep := " = "
               ENDIF

               IF ::aQuoted[i] == "NULL"
                  cSep := IIf(cSep == " = ", " IS ", " IS NOT ")
               ENDIF

               IF i == nLen .AND. "%" $ cQot
                  cSep := " LIKE "
               ENDIF

               nFeitos ++
               cRet += IIf(nFeitos > 1, " AND ", "") + cNam + cSep + cQot + " "
            NEXT i

            IF !Empty(cRet)
               ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_SCOPE_SQLEXPR] := " ( " + cRet + " ) "
            ENDIF

            EXIT

         CASE "U"
            // Clear scope
            EXIT

         SR_OTHERWISE

            ::RuntimeErr("26")
            RETURN -1

         ENDSWITCH

      ELSEIF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE] != NIL .OR. ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE] != NIL

         nLen := Max(Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS]) - 1, 1)      // -1 to remove RECNO from index key
         aNulls := {}
         aNotNulls := {}

         FOR nScoping := TOPSCOPE TO BOTTOMSCOPE

            uKey := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE + nScoping]
            IF HB_IsString(uKey) //ValType(uKey) == "C"
               IF Right(uKey, 1) == "|" // TODO:
                  uKey := Left(uKey, Len(uKey) - 1)
               ENDIF
            ENDIF

            SWITCH ValType(uKey)

            CASE "N"
            CASE "D"
            CASE "L"

               lNull := ::IndexFieldNul(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])
               nFDec := ::IndexFieldDec(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])
               nFLen := ::IndexFieldLen(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])

               IF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE] != NIL
                  cQot := ::QuotedNull(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_TOP_SCOPE], , nFLen, nFDec, , lNull)
                  cSep := IIf(cQot == "NULL", " IS ", " >= ")
                  cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])

                  cRet := " " + cNam + cSep + cQot + " "

                  IF cQot == "NULL"
                     IF HB_IsNumeric(uKey)
                        cRet := "( " + cRet + " OR " + cNam + " >= 0 )"
                     ELSEIF HB_IsDate(uKey) //ValType(uKey) == "D"
                        cRet := "( " + cRet + " OR " + cNam + " >= " + ::QuotedNull(SToD("19000101"), , nFLen, nFDec, , lNull) + " )"
                     ENDIF
                  ENDIF
               ENDIF

               IF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE] != NIL
                  cQot := ::QuotedNull(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_BOTTOM_SCOPE], , nFLen, nFDec, , lNull)
                  cSep := IIf(cQot == "NULL", " IS ", " <= ")
                  cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, 1])

                  cRet2 := " " + cNam + cSep + cQot + " "

                  IF cQot == "NULL"
                     IF HB_IsNumeric(uKey)
                        cRet2 := "( " + cRet2 + " OR " + cNam + " <= 0 )"
                     ELSEIF HB_IsDate(uKey) //ValType(uKey) == "D"
                        cRet2 := "( " + cRet2 + " OR " + cNam + " <= " + ::QuotedNull(SToD("19000101"), , nFLen, nFDec, , lNull) + " )"
                     ENDIF
                  ENDIF

                  IF Empty(cRet)
                     cRet := cRet2
                  ELSE
                     cRet := cRet + " and " + cRet2
                  ENDIF
               ENDIF

               EXIT

            CASE "C"
            CASE "M"

               ::aQuoted := {}
               ::aDat := {}
               ::aPosition := {}
               ::aSeekXF := {}
               nCons := 0
               nLenKey := Len(uKey)
               cPart := ""
               HB_SYMBOL_UNUSED(cPart)
               cSep2 := IIf(nScoping == TOPSCOPE, ">", "<")

               // First, split uKey in fields and values according to current index

               FOR i := 1 TO nLen

                  aFld := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]

                  nThis := ::IndexFieldLen(aFld)
                  cPart := SubStr(uKey, nCons + 1, nThis)

                  IF Len(AllTrim(cPart)) < nThis .AND. nScoping == BOTTOMSCOPE
                     IF Empty(AllTrim(cPart))
                        cPart := " " + SR_LAST_CHAR
                     ELSE
                        cPart := AllTrim(cPart) + SR_LAST_CHAR
                     ENDIF
                  ENDIF

                  AAdd(::aPosition, aFld[SR_IDXFLD_POS])

                  IF Len(aFld) >= SR_IDXFLD_XFORM .AND. aFld[SR_IDXFLD_XFORM] != NIL
                     AAdd(::aSeekXF, IdxBlkPad(aFld[SR_IDXFLD_XFORM], nThis))
                  ELSE
                     AAdd(::aSeekXF, NIL)
                  ENDIF

                  cType := ::IndexFieldType(aFld)
                  lNull := ::IndexFieldNul(aFld)
                  nFDec := ::IndexFieldDec(aFld)
                  HB_SYMBOL_UNUSED(nFDec)
                  nFLen := ::IndexFieldLen(aFld)
                  HB_SYMBOL_UNUSED(nFLen)

                  IF i == 1 .AND. nThis >= Len(uKey)
                     IF uKey == ""
                        EXIT
                     ENDIF
                  ELSE
                     IF Len(cPart) == 0
                        EXIT
                     ENDIF
                  ENDIF

                  AAdd(::aQuoted, ::QuotedNull(::ConvType(cPart, cType, @lPartialSeek, nThis), .T., , , , lNull))
                  AAdd(::aDat,    ::ConvType(RTrim(cPart), cType, , nThis))

                  nCons += nThis

                  IF nLenKey < nCons
                     EXIT
                  ENDIF

               NEXT i

               cRet := IIf(Empty(cRet), " (   ( ", cRet + " AND (   ( ")
               nLen := Min(nLen, Len(::aQuoted))

               nSimpl := nLen
               nSimpl := Min(nSimpl, 2)      // 3-key SET SCOPE not allowed.

               FOR j := 1 TO nSimpl

                  nFeitos := 0
                  cExpr := ""

                  FOR i := 1 TO (nLen - j + 1)

                     cQot := ::aQuoted[i]
                     cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i])

                     IF lPartialSeek .AND. i == nLen
                        cSep := IIf(j == 1, " " + cSep2 + "= ", " " + cSep2 + " ")
                     ELSE
                        cSep := IIf(j == 1, " " + cSep2 + "= ", " " + cSep2 + " ")
                     ENDIF

                     nFeitos ++

                     IF IsNull(::aQuoted[i])
                        IF cSep == " >= " .OR. cSep == " <= "
                           cExpr += IIf(nFeitos > 1," AND ", "") + cNam + cSep + " ' " + IIf(cSep == " <= ", SR_LAST_CHAR, "") + "' "
                           AAdd(aNulls, cNam)
                        ELSEIF cSep == " = "
                           AAdd(aNulls, cNam)
                        ELSE
                           cExpr += IIf(nFeitos > 1, " AND ", "") + cNam + cSep + " ' " + SR_LAST_CHAR + "' "
                           AAdd(aNotNulls, cNam)
                        ENDIF
                     ELSE

//                         IF ISPOSTGRESQL()
//                            IF 'INDKEY_' $ Upper(cNam)
//                            altd()
//                               cnam := "substr( " + cNam + ",1," + Str(Len(cQot) - 3) + ")"
//                           ENDIF
//                         ENDIF

                        cExpr += IIf(nFeitos > 1, " AND ", "") + cNam + cSep + cQot + " "
                     ENDIF

                  NEXT i

                  IF j < nSimpl
                     cRet += cExpr + e" ) OR \r\n ( "
                  ELSE
                     cRet += cExpr
                  ENDIF

               NEXT j

               cRet += " )   )"

               EXIT

            CASE "U"
               // Clear scope
               EXIT

            SR_OTHERWISE

               ::RuntimeErr("26")
               RETURN -1

            ENDSWITCH

         NEXT nScoping

         IF Len(aNulls) > 0 .OR. Len(aNotNulls) > 0
            cRet := "(" + cRet + ") ) "
            FOR i := 1 TO Len(aNulls)
               cRet := " " + aNulls[i] + " IS NULL OR " + cRet
            NEXT i
            FOR i := 1 TO Len(aNotNulls)
               cRet := " " + aNotNulls[i] + " IS NOT NULL OR " + cRet
            NEXT i
            cRet := " (" + cRet
         ENDIF

         IF !Empty(cRet)
            ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_SCOPE_SQLEXPR] := cRet
         ENDIF

      ENDIF

      ::Refresh()

      RETURN 0    // Success

   ENDIF

RETURN -1         // Failure

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlLock(nType, uRecord)

   LOCAL lRet := .T.
   LOCAL aVet := {}
   LOCAL aResultSet := {}

   HB_SYMBOL_UNUSED(aVet)

   ::sqlGoCold()

   IF nType < 3 .AND. ::aInfo[SR_AINFO_SHARED]
      IF uRecord == NIL .OR. Empty(uRecord) .OR. AScan(::aLocked, uRecord) > 0 .OR. ::aInfo[SR_AINFO_ISINSERT]
         RETURN .T.
      ENDIF
      IF nType != 2 .AND. Len(::aLocked) > 0
         ::sqlUnlock()
      ENDIF
   ELSE
      ASize(::aLocked, 0)
   ENDIF

   // Sets the timeout to SR_LOCK_TIMEOUT seconds

   ::oSql:SetNextOpt(SQL_ATTR_QUERY_TIMEOUT, SR_LOCK_TIMEOUT)

   SWITCH ::oSql:nSystemID

   CASE SQLRDD_RDBMS_ORACLE
   CASE SQLRDD_RDBMS_POSTGR
      IF nType < 3
         IF ::oSql:Exec("SELECT * FROM " + ::cQualifiedTableName + ;
            IIf(nType < 3, " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0), "") + " FOR UPDATE" + ::oSql:cLockWait + ;
            IIf(::oSql:lComments, " /* Line Lock */", ""), .F., .T., @aResultSet, , , , , ::cRecnoName, ::cDeletedName, , ::nLogMode, SQLLOGCHANGES_TYPE_LOCK) != SQL_SUCCESS
            lRet := .F.
         ENDIF
         IF Len(aResultSet) > 0 .AND. lret
            ::UpdateCache(aResultSet)
         ELSE
            lRet := .F.
         ENDIF
      ELSE
         IF !::LockTable(.F., .T.)
            lRet := .F.
         ENDIF
      ENDIF
      EXIT

#if 0
      // Commented 2005/02/04 - It's better to wait forever on a lock than have a corrupt transaction

      IF ISPOSTGRESQL() .AND. !lRet
         // This will BREAK transaction control, but it's the only way to have Postgres responding again
         IF ::oSql:nTransacCount >  0
            ::oSql:Commit()
            ::oSql:nTransacCount := 0
         ENDIF
         ::oSql:Commit()
      ENDIF
#endif

   CASE SQLRDD_RDBMS_FIREBR
      IF nType < 3
         IF ::oSql:Exec("SELECT * FROM " + ::cQualifiedTableName + ;
            IIf(nType < 3, " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0), "") + " FOR UPDATE WITH LOCK" + ;
            IIf(::oSql:lComments, " /* Line Lock */", ""), .F., .T., @aResultSet, , , , , ::cRecnoName, ::cDeletedName, , ::nLogMode, SQLLOGCHANGES_TYPE_LOCK) != SQL_SUCCESS
            lRet := .F.
         ENDIF
         IF Len(aResultSet) > 0 .AND. lret
            ::UpdateCache(aResultSet)
         ELSE
            lRet := .F.
         ENDIF
      ELSE
         IF !::LockTable(.F., .T.)
            lRet := .F.
         ENDIF
      ENDIF
      EXIT

   CASE SQLRDD_RDBMS_IBMDB2
   CASE SQLRDD_RDBMS_MYSQL
   CASE SQLRDD_RDBMS_MARIADB
      IF nType < 3
         IF ::oSql:Exec("SELECT * FROM " + ::cQualifiedTableName + ;
            IIf(nType < 3, " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0), "") + " FOR UPDATE" + ::oSql:cLockWait + ;
            IIf(::oSql:lComments, " /* Line Lock */", ""), .F., .T., @aResultSet, , , , , ::cRecnoName, ::cDeletedName, , ::nLogMode, SQLLOGCHANGES_TYPE_LOCK) != SQL_SUCCESS
            lRet := .F.
         ENDIF
         IF Len(aResultSet) > 0 .AND. lret
            ::UpdateCache(aResultSet)
         ELSE
            lRet := .F.
         ENDIF
      ELSE
         IF !::LockTable(.F., .T.)
            lRet := .F.
         ENDIF
      ENDIF
      EXIT

   CASE SQLRDD_RDBMS_INGRES
      IF ::oSql:Exec("SELECT * FROM " + ::cQualifiedTableName + ;
         IIf(nType < 3, " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0), "") + ;
         IIf(::oSql:lComments, " /* Lock */", ""), .F., .T., @aResultSet, , , , , ::cRecnoName, ::cDeletedName, , ::nLogMode, SQLLOGCHANGES_TYPE_LOCK) != SQL_SUCCESS
         lRet := .F.
      ENDIF
      IF nType < 3
         IF Len(aResultSet) > 0 .AND. lRet
            ::UpdateCache(aResultSet)
         ELSE
            lRet := .F.
         ENDIF
      ENDIF
      EXIT

   CASE SQLRDD_RDBMS_MSSQL7
   CASE SQLRDD_RDBMS_AZURE
      IF nType < 3
         IF ::oSql:Exec("SELECT * FROM " + ::cQualifiedTableName  + " WITH (UPDLOCK) WHERE " + ;
            SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0) + ;
            IIf(::oSql:lComments, " /* Lock row */", ""), .F., .T., @aResultSet, , , , , ::cRecnoName, ::cDeletedName, , ::nLogMode, SQLLOGCHANGES_TYPE_LOCK) != SQL_SUCCESS
            lRet := .F.
         ENDIF
         IF Len(aResultSet) > 0 .AND. lRet
            ::UpdateCache(aResultSet)
         ELSE
            lRet := .F.
         ENDIF
      ELSE
         IF !::LockTable(.F., .T.)
            lRet := .F.
         ENDIF
      ENDIF
      EXIT

   CASE SQLRDD_RDBMS_SYBASE
      IF ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0) + IIf(nType < 3, " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0), "") + ;
         + IIf(::oSql:lComments, " /* Lock */", ""), .F., .T., @aResultSet, , , , , ::cRecnoName, ::cDeletedName, , ::nLogMode, SQLLOGCHANGES_TYPE_LOCK) != SQL_SUCCESS
         lRet := .F.
      ENDIF
      IF nType < 3
         IF ::oSql:Exec("SELECT * FROM " + ::cQualifiedTableName + " WHERE " + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " = " + ::Quoted(uRecord, , 15, 0) + ;
            IIf(::oSql:lComments, " /* Lock */", ""), .F., .T., @aResultSet, , , , , ::cRecnoName, ::cDeletedName, , ::nLogMode, SQLLOGCHANGES_TYPE_LOCK) != SQL_SUCCESS
            lRet := .F.
         ENDIF
         IF Len(aResultSet) > 0 .AND. lRet
            ::UpdateCache(aResultSet)
         ELSE
            // SR_MsgLogFile(SR_Msg(8) + AllTrim(Str(uRecord, 15)) + " + " + ::cOwner + AllTrim(::cFileName) + " + " + SR_Val2Char(::oSql:nRetCode))
            lRet := .F.
         ENDIF
      ENDIF
      EXIT

   CASE SQLRDD_RDBMS_CACHE // TODO: unnecessary
/*
drop function newage.LOCK
drop function newage.UNLOCK

create function newage.LOCK(lockName VARCHAR(50) default 'noname',
timeout int default 4)
for newage.LockControler
returns INT
LANGUAGE OBJECTSCRIPT
{
Set lockName="^"_lockName
Lock +@lockName:timeout
Else Quit 0
Quit 1
}
*/

   ENDSWITCH

   IF ::aInfo[SR_AINFO_SHARED] .AND. lRet .AND. nType < 3
      AAdd(::aLocked, uRecord)
   ENDIF

   IF lRet .AND. nType == 3
      ::lTableLocked := .T.
   ENDIF

   // Reset stmt timeout
   ::oSql:SetNextOpt(SQL_ATTR_QUERY_TIMEOUT, 0)

RETURN lRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlUnLock(uRecord)

   HB_SYMBOL_UNUSED(uRecord)

   ::sqlGoCold()

   IF ::aInfo[SR_AINFO_SHARED]
      IF Len(::aLocked) > 0 .OR. ::lTableLocked
         ASize(::aLocked, 0)
         IF ::lCanICommitNow()
            ::oSql:Commit()      // This will release all Locks in SQL database
         ENDIF
      ENDIF
      IF ::lTableLocked
         ::UnlockTable()
         ::lTableLocked := .F.
      ENDIF
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlDrop(cFileName)

   IF SR_ExistTable(cFileName)
      SR_DropTable(cFileName)
   ELSEIF SR_ExistIndex(cFileName)
      SR_DropIndex(cFileName)
   ELSE
      RETURN .F.
   ENDIF

RETURN .T.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:sqlExists(cFileName)

RETURN SR_File(cFileName)

//----------------------------------------------------------------------------//

STATIC FUNCTION aOrd(x, y, aPos)

   LOCAL i
   LOCAL cStr1 := ""
   LOCAL cStr2 := ""

   FOR i := 1 TO Len(aPos)
      IF HB_IsDate(x[aPos[i]])
         cStr1 += DToS(x[aPos[i]])
         cStr2 += DToS(y[aPos[i]])
      ELSE
         cStr1 += HB_VALTOSTR(x[aPos[i]])
         cStr2 += HB_VALTOSTR(y[aPos[i]])
      ENDIF
   NEXT i

RETURN cStr1 < cStr2

//----------------------------------------------------------------------------//

STATIC FUNCTION aOrdX(x, y, aPos, aXF)    // cache sort honoring expression index transforms

   LOCAL i
   LOCAL u1
   LOCAL u2
   LOCAL cStr1 := ""
   LOCAL cStr2 := ""

   FOR i := 1 TO Len(aPos)
      u1 := IIf(aXF[i] == NIL, x[aPos[i]], Eval(aXF[i], x[aPos[i]]))
      u2 := IIf(aXF[i] == NIL, y[aPos[i]], Eval(aXF[i], y[aPos[i]]))
      IF HB_IsDate(u1)
         cStr1 += DToS(u1)
         cStr2 += DToS(u2)
      ELSE
         cStr1 += HB_VALTOSTR(u1)
         cStr2 += HB_VALTOSTR(u2)
      ENDIF
   NEXT i

RETURN cStr1 < cStr2

//----------------------------------------------------------------------------//

/*
STATIC FUNCTION aScanIndexed(aVet, nPos, uKey, lSoft, nLen, lFound) // static function not used

   LOCAL nRet := 0
   LOCAL first
   LOCAL last
   LOCAL mid
   LOCAL closest
   LOCAL icomp
   LOCAL exec
   LOCAL nRegress

   exec := HB_IsBlock(nPos)
   first := 1
   last := Len(aVet)
   mid := Int((first + last) / 2)
   lFound := .T.

   closest := mid

   DO WHILE last > 0

      s_ItP11 := nPos
      s_ItP14 := nPos
      s_ItP2 := uKey
      s_ItP3 := nLen

      icomp := sr_ItemCmp(IIf(exec, Eval(s_ItP11, mid, aVet), aVet[mid, s_ItP14]), s_ItP2, s_ItP3)

      IF icomp == 0
         nRegress := mid
         DO WHILE --nRegress > 0
            IF sr_ItemCmp(IIf(exec, Eval(s_ItP11, nRegress, aVet), aVet[nRegress, s_ItP14]), s_ItP2, s_ItP3) != 0
               EXIT
            ENDIF
         ENDDO
         RETURN (++nRegress)
      ELSE
         IF first == last
            EXIT
         ELSEIF first == (last - 1)

            s_ItP11 := nPos
            s_ItP14 := nPos
            s_ItP2 := uKey
            s_ItP3 := nLen

            IF sr_ItemCmp(IIf(exec, Eval(s_ItP11, last, aVet), aVet[last, s_ItP14]), s_ItP2, s_ItP3) == 0
               nRegress := last
               DO WHILE --nRegress > 0
                  IF sr_ItemCmp(IIf(exec, Eval(s_ItP11, nRegress, aVet), aVet[nRegress, s_ItP14]), s_ItP2, s_ItP3) != 0
                     EXIT
                  ENDIF
               ENDDO
               RETURN (++nRegress)
            ENDIF
            EXIT
         ENDIF

         IF icomp > 0
            last := mid
            closest := mid
         ELSE
            first := mid
            closest := first
         ENDIF

         mid := Int((last + first) / 2)

      ENDIF

   ENDDO

   IF lSoft .AND. Len(aVet) > 0
      lFound := .F.
      IF Len(aVet) > mid
         nRet := mid + 1    // Soft seek should stop at immediatelly superior item
      ELSE
         nRet := mid
      ENDIF
   ENDIF

RETURN nRet
*/

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WhereMajor()

   LOCAL i
   LOCAL cRet := ""
   LOCAL nLen
   LOCAL cSep
   LOCAL cNam
   LOCAL c1 := ""
   LOCAL c2 := ""
   LOCAL cRet2
   LOCAL j

   IF ::aInfo[SR_AINFO_INDEXORD] == 0
      cRet2 := ::SolveRestrictors()
      IF !Empty(cRet2)
         cRet2 := " AND " + cRet2
      ENDIF
      RETURN " WHERE A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " >= " + ::QuotedNull(::aLocalBuffer[::hnRecno], .T., , , , .F.) + cRet2
   ENDIF

   IF !::lOrderValid
      RETURN ""
   ENDIF

   IF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_UP] != NIL
      RETURN ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_UP]
   ENDIF

   nLen := Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS])

   FOR i := 1 TO nLen
      c1 += IIf(!Empty(c1), " AND ", "") + "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]], ::oSql:nSystemID) + " @3" + Str(i - 1, 1)
   NEXT i

   cRet := "( " + c1 + ") "

   FOR j := (nLen-1) TO 1 STEP -1
      c2 := ""
      FOR i := 1 TO j
         cNam := "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]], ::oSql:nSystemID)
         DO CASE
         CASE i == j
            cSep := " @1"  // " > "
         CASE i + 1 == j
            cSep := " @2"  // " = "
         OTHERWISE
            cSep := " @3"  // " >= "
         ENDCASE
         c2 += IIf(!Empty(c2), " AND ", "") + cNam + cSep + Str(i - 1, 1) + " "
      NEXT i

      IF !Empty(c2)
         cRet += "OR ( " + c2 + ") "
      ENDIF
   NEXT j

   cRet2 := ::SolveRestrictors()

   IF !Empty(cRet2)
      cRet2 := " AND " + cRet2
   ENDIF

   cRet := " WHERE ( " + cRet + " )" + cRet2
   ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_UP] := cRet

RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WhereVMajor(cQot)

   LOCAL cRet
   LOCAL cRet2

   IF ::aInfo[SR_AINFO_INDEXORD] == 0
      cRet2 := ::SolveRestrictors()
      IF !Empty(cRet2)
         cRet2 := " AND " + cRet2
      ENDIF
      RETURN " WHERE A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " >= " + ::QuotedNull(::aLocalBuffer[::hnRecno], .T., , , , .F.) + cRet2
   ENDIF

   IF !::lOrderValid
      RETURN ""
   ENDIF

   DEFAULT cQot TO (::cAlias)->(&(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_KEY])) + Str(::aInfo[SR_AINFO_RECNO], 15)

   cRet := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_EXPR] + " >= '" + SR_ESCAPESTRING(cQot, ::oSql:nSystemID) + "'"
   cRet2 := ::SolveRestrictors()

   IF !Empty(cRet2)
      cRet2 := " AND " + cRet2
   ENDIF

   cRet := " WHERE ( " + cRet + " )" + cRet2

RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WherePgsMajor(aQuotedCols, lPartialSeek)

   LOCAL i
   LOCAL aRet := {}
   LOCAL nLen
   LOCAL cSep
   LOCAL cQot
   LOCAL cNam
   LOCAL lNull := NIL
   LOCAL c2
   LOCAL cRet := ""
   LOCAL cRet2
   LOCAL j
   LOCAL aQuot := {}

   DEFAULT lPartialSeek TO .T.

   IF ::aInfo[SR_AINFO_INDEXORD] == 0
      cRet2 := ::SolveRestrictors()
      IF !Empty(cRet2)
         cRet2 := " AND " + cRet2
      ENDIF
      aRet := {"A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " >= " + ::Quoted(::aLocalBuffer[::hnRecno], .T., , , , .F.) + cRet2}
   ELSE

      IF Empty(::aInfo[SR_AINFO_INDEXORD])
         RETURN {}
      ENDIF

      IF !::lOrderValid
         RETURN {}
      ENDIF

      IF aQuotedCols == NIL
         nLen := Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS])
         FOR i := 1 TO nLen
            AAdd(aQuot, ::Quoted(::IndexFieldVal(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]), .T., , , , lNull))
         NEXT i
      ELSE
         nLen := Len(aQuotedCols)
         aQuot := aQuotedCols
      ENDIF

      FOR j := nLen TO 1 STEP -1

         c2 := ""

         FOR i := 1 TO j
            //lNull := ::IndexFieldNul(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]) (variable and value not used)
            cQot := aQuot[i]
            cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i])

            DO CASE
            CASE !lPartialSeek
               cSep := " = "
            CASE j == nLen .AND. cQot == "NULL"
               LOOP
            CASE j == nLen
               cSep := " >= "
            CASE i == j .AND. cQot == "NULL"
               cSep := " IS NOT "
            CASE i == j
               cSep := " > "
            CASE i + 1 == j
               cSep := " = "
            OTHERWISE
               IF cQot == "NULL"
                  LOOP
               ELSE
                  cSep := " >= "
               ENDIF
            ENDCASE

            c2 += IIf(!Empty(c2), " AND ", "") + cNam + cSep + cQot + " "

         NEXT i

         IF !Empty(c2)
            AAdd(aRet, "( " + c2 + ") ")
         ENDIF

         IF !lPartialSeek
            EXIT
         ENDIF

      NEXT j

   ENDIF

   cRet := ::SolveRestrictors()

   IF !Empty(cRet)
      cRet := " AND ( " + cRet + " ) "
   ENDIF

   AEval(aRet, {|x, i|HB_SYMBOL_UNUSED(x), aRet[i] += cRet})

RETURN aRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WhereMinor()

   LOCAL i
   LOCAL cRet := ""
   LOCAL nLen
   LOCAL cSep
   LOCAL cNam
   LOCAL c1 := ""
   LOCAL c2 := ""
   LOCAL cRet2
   LOCAL j

   IF ::aInfo[SR_AINFO_INDEXORD] == 0 .AND. ::aLocalBuffer[::hnRecno] != 0
      cRet2 := ::SolveRestrictors()
      IF !Empty(cRet2)
         cRet2 := " AND " + cRet2
      ENDIF
      RETURN " WHERE A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " <= " + ::QuotedNull(::aLocalBuffer[::hnRecno], .T., , , , .F.) + cRet2
   ENDIF

   IF !::lOrderValid
      RETURN ""
   ENDIF

   IF ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_DOWN] != NIL
      RETURN ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_DOWN]
   ENDIF

   nLen := Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS])

   FOR i := 1 TO nLen
      c1 += IIf(!Empty(c1), " AND ", "") + "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]], ::oSql:nSystemID) + " @6" + Str(i - 1, 1)
   NEXT i

   cRet += "( " + c1 + ") "

   FOR j := (nLen-1) TO 1 STEP -1
      c2 := ""
      FOR i := 1 TO j
         cNam := "A." + SR_DBQUALIFY(::aNames[::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i, 2]], ::oSql:nSystemID)
         DO CASE
         CASE i == j
            cSep := " @4"  // " < "
         CASE i + 1 == j
            cSep := " @2"  // " = "
         OTHERWISE
            cSep := " @6"  // " <= "
         ENDCASE
         c2 += IIf(!Empty(c2), " AND ", "") + cNam + cSep + Str(i - 1, 1) + " "
      NEXT i

      IF !Empty(c2)
         cRet += IIf(Empty(cRet), "( ", "OR ( ") + c2 + ") "
      ENDIF
   NEXT j

   cRet2 := ::SolveRestrictors()

   IF !Empty(cRet2)
      cRet2 := " AND " + cRet2
   ENDIF

   cRet := " WHERE ( " + cRet + " )" + cRet2
   ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_DOWN] := cRet

RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WhereVMinor(cQot)

   LOCAL cRet
   LOCAL cRet2

   IF ::aInfo[SR_AINFO_INDEXORD] == 0 .AND. ::aLocalBuffer[::hnRecno] != 0
      cRet2 := ::SolveRestrictors()
      IF !Empty(cRet2)
         cRet2 := " AND " + cRet2
      ENDIF
      RETURN " WHERE A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " <= " + ::QuotedNull(::aLocalBuffer[::hnRecno], .T., , , , .F.) + cRet2
   ENDIF

   IF !::lOrderValid
      RETURN ""
   ENDIF

   DEFAULT cQot TO (::cAlias)->(&(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_KEY])) + Str(::aInfo[SR_AINFO_RECNO], 15)

   cRet := ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_VIRTUAL_INDEX_EXPR] + " <= '" + SR_ESCAPESTRING(cQot, ::oSql:nSystemID) + "'"

   cRet2 := ::SolveRestrictors()

   IF !Empty(cRet2)
      cRet2 := " AND " + cRet2
   ENDIF

   cRet := " WHERE ( " + cRet + " )" + cRet2

   ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_ORDER_SKIP_DOWN] := cRet

RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:WherePgsMinor(aQuotedCols)

   LOCAL i
   LOCAL aRet := {}
   LOCAL nLen
   LOCAL cSep
   LOCAL cQot
   LOCAL cNam
   LOCAL lNull := NIL
   LOCAL c2 := ""
   LOCAL cRet := ""
   LOCAL cRet2
   LOCAL j
   LOCAL aQuot := {}

   IF ::aInfo[SR_AINFO_INDEXORD] == 0
      cRet2 := ::SolveRestrictors()
      IF !Empty(cRet2)
         cRet2 := " AND " + cRet2
      ENDIF
      aRet := {"A." + SR_DBQUALIFY(::cRecnoName, ::oSql:nSystemID) + " <= " + ::QuotedNull(::aLocalBuffer[::hnRecno], .T., , , , .F.) + cRet2}
   ELSE

      IF Empty(::aInfo[SR_AINFO_INDEXORD])
         RETURN {}
      ENDIF

      IF !::lOrderValid
         RETURN {}
      ENDIF

      IF aQuotedCols == NIL
         nLen := Len(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS])
         FOR i := 1 TO nLen
            cQot := ::Quoted(::IndexFieldVal(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]), .T., , , , lNull)
            AAdd(aQuot, cQot)
         NEXT i
      ELSE
         nLen := Len(aQuotedCols)
         aQuot := aQuotedCols
      ENDIF

      FOR j := nLen TO 1 STEP -1

         c2 := ""

         FOR i := 1 TO j

            //lNull := ::IndexFieldNul(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i]) (variable and value not used)
            cQot := aQuot[i]
            cNam := ::IndexFieldSQL(::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_INDEX_FIELDS, i])

            DO CASE
            CASE j == nLen .AND. cQot == "NULL"
               cSep := " IS "
            CASE j == nLen
               cSep := " <= "
//                IF 'INDKEY_' $ Upper(CNAM)
//                altd()
//                   cnam := "substr( " + cnam + ",1," + Str(Len(cQot) - 3) + ")"
//                ENDIF

            CASE i == j
               cSep := " < "
            CASE i + 1 == j
               cSep := " = "
            OTHERWISE
               IF cQot == "NULL"
                  cSep := " IS "
               ELSE
                  cSep := " <= "
//                   IF "INDKEY_" $ Upper(CNAM)
//                   altd()
//                   cnam := "substr( " + cnam + ",1," + Str(Len(cQot) - 3) + ")"
//                   ENDIF
               ENDIF
            ENDCASE

            c2 += CatSep(IIf(!Empty(c2), " AND ", ""), cNam, cSep, cQot) + " "

         NEXT i

         IF !Empty(c2)
            AAdd(aRet, "( " + c2 + ") ")
         ENDIF
      NEXT j

   ENDIF

   cRet := ::SolveRestrictors()

   IF !Empty(cRet)
      cRet := " AND ( " + cRet + " ) "
   ENDIF

   AEval(aRet, {|x, i|HB_SYMBOL_UNUSED(x), aRet[i] += cRet})

RETURN aRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:DropColRules(cColumn, lDisplayErrorMessage, aDeletedIndexes)

   LOCAL aInd := NIL
   LOCAL i
   LOCAL cPhisicalName
   LOCAL aIndexes
   LOCAL nRet := SQL_SUCCESS
   LOCAL cPhysicalVIndexName

   cColumn := Upper(AllTrim(cColumn))

   aIndexes := {}
   ::oSql:Commit()
   ::oSql:Exec("SELECT PHIS_NAME_, IDXCOL_, IDXKEY_, IDXNAME_ ,TAGNUM_, TAG_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(::cFileName) + "' ORDER BY IDXNAME_, TAGNUM_", .T., .T., @aIndexes)

   // Check if column is used by any index and drop the index, if necessary.

   FOR i := 1 TO Len(aIndexes)

      IF At(Chr(34) + cColumn + Chr(34), aIndexes[i, 3]) > 0 .OR. At("+" + cColumn + "+", "+" + AllTrim(aIndexes[i, 3]) + "+") > 0 .OR. ;
         (Left(cColumn, 7) == "INDKEY_" .AND. SubStr(cColumn, 8, 3) == SubStr(aIndexes[i, 2], 1, 3))

         // Drop the index

         IF Len(aIndexes) >= i

            cPhisicalName := AllTrim(aIndexes[i, 1])

            IF SubStr(aIndexes[i, 4], 4, 1) == "@"
               cPhysicalVIndexName := SubStr(aInd[4], 1, 3) + SubStr(::cFileName, 1, 25)
            ELSE
               cPhysicalVIndexName := NIL
            ENDIF

            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_MSSQL6
            CASE SQLRDD_RDBMS_MSSQL7
            CASE SQLRDD_RDBMS_AZURE
            CASE SQLRDD_RDBMS_SYBASE
               nRet := ::oSql:Exec("DROP INDEX " + ::cQualifiedTableName + "." + cPhisicalName + IIf(::oSql:lComments, " /* Drop index before drop column */", ""), lDisplayErrorMessage)
               EXIT
            CASE SQLRDD_RDBMS_MYSQL
            CASE SQLRDD_RDBMS_MARIADB
               nRet := ::oSql:Exec("DROP INDEX " + cPhisicalName + " ON " + ::cQualifiedTableName + IIf(::oSql:lComments, " /* Drop index before drop column */", ""), lDisplayErrorMessage)
               EXIT
            CASE SQLRDD_RDBMS_ORACLE
               IF cPhysicalVIndexName != NIL
                  ::oSql:Exec("DROP INDEX " + ::cOwner + "A$" + cPhysicalVIndexName + IIf(::oSql:lComments, " /* Drop VIndex before drop column */", ""), .F.)
                  ::oSql:Commit()
                  ::oSql:Exec("DROP INDEX " + ::cOwner + "D$" + cPhysicalVIndexName + IIf(::oSql:lComments, " /* Drop VIndex before drop column */", ""), .F.)
                  ::oSql:Commit()
               ENDIF
               nRet := ::oSql:Exec("DROP INDEX " + ::cOwner + cPhisicalName + IIf(::oSql:lComments, " /* Drop index before drop column */", ""), lDisplayErrorMessage)
               EXIT
            CASE SQLRDD_RDBMS_FIREBR
               nRet := ::oSql:Exec("DROP INDEX " + cPhisicalName + IIf(::oSql:lComments, " /* Drop index before drop column */", ""), lDisplayErrorMessage)
               HB_SYMBOL_UNUSED(nRet)
               ::oSql:Commit()
               // DELETED THE DESCENDING INDEX
               nRet := ::oSql:Exec("DROP INDEX " + cPhisicalName + "R" + IIf(::oSql:lComments, " /* Drop index before drop column */", ""), lDisplayErrorMessage)
               ::oSql:Commit()
               EXIT
            SR_OTHERWISE
               nRet := ::oSql:Exec("DROP INDEX " + cPhisicalName + IIf(::oSql:lComments, " /* Drop index before drop column */", ""), lDisplayErrorMessage)
            ENDSWITCH

            ::oSql:Commit()

            // Remove from catalogs

            IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO

               nRet := ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(::cFileName) + "' AND IDXNAME_ = '" + Upper(AllTrim(aIndexes[i, 4])) + "' AND TAG_ = '" + Upper(AllTrim(aIndexes[i, 6])) + "'" + IIf(::oSql:lComments, " /* Wipe index info */", ""), .F.)

               ::oSql:Commit()

               IF (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND) .AND. aDeletedIndexes != NIL
                  AAdd(aDeletedIndexes, AClone(aIndexes[i]))
               ENDIF

            ENDIF

            IF !lDisplayErrorMessage .AND. nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO .AND. nRet != SQL_NO_DATA_FOUND
               SR_LogFile("changestruct.log", {::cFileName, "Warning: DROP INDEX:", cPhisicalName, ::oSql:cSQLError})
            ENDIF

         ENDIF

         ::oSql:Commit()

      ENDIF
   NEXT i

RETURN nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:DropColumn(cColumn, lDisplayErrorMessage, lRemoveFromWA)

   LOCAL i
   LOCAL nRet := SQL_SUCCESS

   DEFAULT lRemoveFromWA TO .F.

   cColumn := Upper(AllTrim(cColumn))

   ::DropColRules(cColumn, .F.)

   SWITCH ::oSql:nSystemID
   CASE SQLRDD_RDBMS_ORACLE
   CASE SQLRDD_RDBMS_MSSQL6
   CASE SQLRDD_RDBMS_MSSQL7
   CASE SQLRDD_RDBMS_SQLANY
   CASE SQLRDD_RDBMS_SYBASE
   CASE SQLRDD_RDBMS_ACCESS
   CASE SQLRDD_RDBMS_INGRES
   CASE SQLRDD_RDBMS_SQLBAS
   CASE SQLRDD_RDBMS_ADABAS
   CASE SQLRDD_RDBMS_INFORM
   CASE SQLRDD_RDBMS_IBMDB2
   CASE SQLRDD_RDBMS_MYSQL
   CASE SQLRDD_RDBMS_MARIADB
   CASE SQLRDD_RDBMS_POSTGR
   CASE SQLRDD_RDBMS_CACHE
   CASE SQLRDD_RDBMS_AZURE
      nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " DROP COLUMN " + SR_DBQUALIFY(cColumn, ::oSql:nSystemID), lDisplayErrorMessage)
      ::oSql:Commit()
      EXIT
   CASE SQLRDD_RDBMS_FIREBR
      nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " DROP " + SR_DBQUALIFY(cColumn, ::oSql:nSystemID), lDisplayErrorMessage)
      ::oSql:Commit()
   ENDSWITCH

   IF !lDisplayErrorMessage .AND. nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
      SR_LogFile("changestruct.log", {::cFileName, "Warning: DROP COLUMN:", cColumn, ::oSql:cSQLError})
   ENDIF

   IF lRemoveFromWA
      IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
         IF (i := AScan(::aNames, cColumn)) > 0
            ADel(::aNames, i)
            ASize(::aNames, Len(::aNames) - 1)
            ADel(::aFields, i)
            ASize(::aFields, Len(::aFields) - 1)
            ::nFields := Len(::aFields)
         ENDIF
      ENDIF
   ENDIF

RETURN nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:AlterColumns(aCreate, lDisplayErrorMessage, lBakcup)

   LOCAL lRet := .T.
   LOCAL i
   LOCAL cSql
   LOCAL cField
   LOCAL lPrimary
   LOCAL lNotNull
   LOCAL lRet2
   LOCAL aInfo
   LOCAL aMultilang := {}
   LOCAL aField
   LOCAL nPos_
   LOCAL aBack
   LOCAL lDataInBackup := .F.
   LOCAL cLobs := ""
   LOCAL cTblName := NIL
   LOCAL lCurrentIsMultLang := .F.

   HB_SYMBOL_UNUSED(lCurrentIsMultLang)

   DEFAULT lBakcup TO .T.

   // Release any pending transaction before a DML command

   ::sqlGoCold()

   ::oSql:Commit()
   ::oSql:nTransacCount := 0

   DEFAULT lDisplayErrorMessage TO .T.

   // Check existing column

   FOR i := 1 TO Len(aCreate)

      ASize(aCreate[i], SR_FIELD_INFO_SIZE)
      cLobs := ""

      DEFAULT aCreate[i, SR_FIELD_PRIMARY_KEY] TO 0
      DEFAULT aCreate[i, SR_FIELD_NULLABLE] TO .T.
      DEFAULT aCreate[i, SR_FIELD_MULTILANG] TO MULTILANG_FIELD_OFF

      aCreate[i, SR_FIELD_NAME] := Upper(AllTrim(aCreate[i, SR_FIELD_NAME]))
      cField := aCreate[i, SR_FIELD_NAME]
      lPrimary := aCreate[i, SR_FIELD_PRIMARY_KEY] > 0

      IF (nPos_ := AScan(::aNames, {|x|AllTrim(Upper(x)) == cField})) > 0
         // Column exists

         lCurrentIsMultLang := ::aFields[nPos_, SR_FIELD_MULTILANG]

         IF lBakcup .AND. (!lCurrentIsMultLang)
            // Create backup column
            aBack := {AClone(::aFields[nPos_])}
            aBack[1, 1] := "BACKUP_"
            ::AlterColumns(aBack, lDisplayErrorMessage, .F.)
            ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET BACKUP_ = " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID), lDisplayErrorMessage)
            ::oSql:Commit()
            lDataInBackup := .T.
         ENDIF
      ELSE
         lCurrentIsMultLang := .F.
      ENDIF

      // DROP the column

      IF !(lCurrentIsMultLang .AND. aCreate[i, SR_FIELD_TYPE] $ "MC")

         ::DropColumn(cField, .F.)   // It may be a new column or not - don't care.

         cSql := "ALTER TABLE " + ::cQualifiedTableName
         cSql += " ADD " + IIf(ISPOSTGRESQL(), "COLUMN ", "") + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID)
         cSql += " "

         // lNotNull := (!aCreate[i, SR_FIELD_NULLABLE]) .OR. lPrimary
         lNotNull := .F.

      ENDIF

      IF lCurrentIsMultLang .AND. aCreate[i, SR_FIELD_TYPE] $ "MC" .AND. SR_SetMultiLang()

         aField := AClone(aCreate[i])
         AAdd(aMultilang, AClone(aCreate[i]))
         ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLANG WHERE TABLE_ = '" + Upper(::cFileName) + "' AND COLUMN_ = '" + aField[SR_FIELD_NAME] + "'")
         ::oSql:Commit()
         SR_LogFile("changestruct.log", {::cFileName, "Removing MLANG column:", aField[SR_FIELD_NAME]})
         lRet2 := .F.

      ELSE

         IF aCreate[i, SR_FIELD_MULTILANG] .AND. aCreate[i, SR_FIELD_TYPE] $ "MC" .AND. SR_SetMultiLang()
            AAdd(aMultilang, AClone(aCreate[i]))
            aCreate[i, SR_FIELD_TYPE] := "M"
         ENDIF

#if 0 // original code for reference (to be deleted)
         DO CASE // TODO: switch ?

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISORACLE()
            IF aCreate[i, SR_FIELD_LEN] > 30
               cSql += "VARCHAR2(" + LTrim(Str(Min(aCreate[i, SR_FIELD_LEN], 4000), 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            ELSE
               IF aCreate[i, SR_FIELD_LEN] > s_nMininumVarchar2Size .AND. s_nMininumVarchar2Size < 30
                  cSql += "VARCHAR2(" + LTrim(Str(Min(aCreate[i, SR_FIELD_LEN], 4000), 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
               ELSE
               cSql += "CHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            ENDIF
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C" .OR. aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISSQLBAS()
            IF aCreate[i, SR_FIELD_LEN] > 254 .OR. aCreate[i, SR_FIELD_TYPE] == "M"
               cSql += "LONG VARCHAR"
            ELSE
               cSql += "VARCHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISPOSTGRESQL() .OR. ISCACHE() .OR. ISADABAS() .OR. ISAZURE())
            IF ISMSSQL7() .OR. ISAZURE()
               IF ::OSQL:lSqlServer2008 .AND. SR_Getsql2008newTypes()
                  IF aCreate[i, SR_FIELD_LEN] > 10
                     cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
                  ELSE
                     cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
                  ENDIF
               ELSE
                  cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
               ENDIF
            ELSEIF ISPOSTGRESQL() .AND. aCreate[i, SR_FIELD_LEN] > s_nMininumVarchar2Size -1 //10
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE aCreate[i, SR_FIELD_TYPE] == "C" .AND. (ISMYSQL() .OR. ISMARIADB())
            IF aCreate[i, SR_FIELD_LEN] > 255
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. (ISIBMDB2())
            IF aCreate[i, SR_FIELD_LEN] > 255
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHARACTER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISINGRES()
            cSql += "varchar(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IIf(lNotNull, " NOT NULL", ""))

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISINFORM()
            cSql += "CHARACTER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IIf(lNotNull, " NOT NULL", ""))

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISACCESS()
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "TEXT"
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")"
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISSQLANY()
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "LONG VARCHAR "
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + "  " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISFIREBIRD()
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "") + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")  + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISSYBASE()
            IF aCreate[i, SR_FIELD_LEN] > 30
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "D") .AND. (ISORACLE() .OR. ISSQLBAS() .OR. ISINFORM() .OR. ISINGRES() .OR. (ISMYSQL() .OR. ISMARIADB()) .OR. ISFIREBIRD() .OR. ISCACHE())
            cSql += "DATE"

         CASE (aCreate[i, SR_FIELD_TYPE] == "D") .AND. ISSYBASE()
            cSql += "DATETIME"

         CASE (aCreate[i, SR_FIELD_TYPE] == "D") .AND. (ISIBMDB2() .OR. ISPOSTGRESQL() .OR. ISADABAS())
            cSql += "DATE"

         CASE (aCreate[i, SR_FIELD_TYPE] == "D") .AND. (ISACCESS() .OR. ISMSSQL6() .OR. ISMSSQL7() .OR. ISAZURE())
            cSql += "DATETIME NULL"

         CASE (aCreate[i, SR_FIELD_TYPE] == "D") .AND. ISSQLANY()
            cSql += "TIMESTAMP"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISCACHE() .OR. ISAZURE())
            cSql += "BIT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. (ISPOSTGRESQL() .OR. ISADABAS())
            cSql += "BOOLEAN"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. ((ISMYSQL() .OR. ISMARIADB()))
            cSql += "TINYINT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. (ISIBMDB2() .OR. ISFIREBIRD())
            cSql += "SMALLINT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. ISSYBASE()
            cSql += "BIT NOT NULL"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. ISSQLANY()
            cSql += "NUMERIC (1) NULL"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. ISORACLE()
            cSql += "SMALLINT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. ISINFORM()
            cSql += "BOOLEAN"

         CASE (aCreate[i, SR_FIELD_TYPE] == "L") .AND. ISINGRES()
            cSql += "tinyint"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISORACLE()
            cSql += "CLOB"
            cLobs += IIf(Empty(cLobs), "", ",") + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID)

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISIBMDB2()
            cSql += "CLOB (256000) " + IIf("DB2/400" $ ::oSql:cSystemName, "",  " NOT LOGGED COMPACT")

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISPOSTGRESQL() .OR. ISINFORM() .OR. ISCACHE() .OR. ISAZURE())
            cSql += "TEXT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. (ISMYSQL() .OR. ISMARIADB())
            cSql += s_cMySqlMemoDataType

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISADABAS()
            cSql += "LONG"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISINGRES()
            cSql += "long varchar"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISACCESS()
            cSql += "TEXT NULL"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISSYBASE()
            cSql += "TEXT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISSQLANY()
            cSql += "LONG VARCHAR"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISFIREBIRD()
            cSql += "BLOB SUB_TYPE 1" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISSYBASE() .OR. ISAZURE()) .AND. cField == ::cRecnoName
            IF ::oSql:lUseSequences
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") IDENTITY"
            ELSE
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE"
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISCACHE() .AND. cField == ::cRecnoName
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") UNIQUE " + [default objectscript '##class(] + SR_GetToolsOwner() + [SequenceControler).NEXTVAL("] + ::cFileName + [")']

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISSYBASE() .OR. ISCACHE() .OR. ISAZURE())
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ") " + IIf(lNotNull, " NOT NULL ", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISPOSTGRESQL() .AND. cField == ::cRecnoName
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") default (nextval('" + ::cOwner + LimitLen(::cFileName, 3) + "_SQ')) NOT NULL UNIQUE"
         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISPOSTGRESQL()
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ")  default 0 " + IIf(lNotNull, " NOT NULL ", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMYSQL() .OR. ISMARIADB()) .AND. cField == ::cRecnoName
            cSql += "BIGINT (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") NOT NULL UNIQUE AUTO_INCREMENT "
         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMYSQL() .OR. ISMARIADB())
            cSql += s_cMySqlNumericDataType + " (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ") " + IIf(lNotNull, " NOT NULL ", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISORACLE() .AND. cField == ::cRecnoName
            cSql += "NUMBER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" +;
                 IIf(lNotNull, " NOT NULL UNIQUE USING INDEX ( CREATE INDEX " + ::cOwner + LimitLen(::cFileName, 3) + "_UK ON " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + "( " + ::cRecnoName + ")" +;
                 IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx()) , "") + ")"
         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISORACLE()
            cSql += "NUMBER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISIBMDB2() .AND. cField == ::cRecnoName
            IF ::oSql:lUseSequences
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE)"
            ELSE
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL"
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISADABAS() .AND. cField == ::cRecnoName
            cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL DEFAULT SERIAL"

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISIBMDB2() .OR. ISADABAS())
            cSql += "DECIMAL(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISINGRES() .AND. cField == ::cRecnoName
            cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE "

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISINFORM() .AND. cField == ::cRecnoName
            cSql += "SERIAL NOT NULL UNIQUE"

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISINFORM() .OR. ISINGRES())
            cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY ", IIf(lNotNull, " NOT NULL", ""))

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISSQLBAS()
            IF aCreate[i, SR_FIELD_LEN] > 15
               cSql += "NUMBER" + IIf(lPrimary, " NOT NULL", " ")
            ELSE
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", " ")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISSQLANY()
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISACCESS()
            cSql += "NUMERIC"

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISFIREBIRD() .AND. cField == ::cRecnoName
           cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE "

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5()) .AND. cField == ::cRecnoName
           cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") GENERATED BY DEFAULT AS IDENTITY  NOT NULL UNIQUE "

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISFIREBIRD() .OR. ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5())
            IF aCreate[i, SR_FIELD_LEN] > 18
               cSql += "DOUBLE PRECISION" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
            ELSE
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) +  ")" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
            ENDIF
         // including xml data type
         // postgresql datetime
         CASE (aCreate[i, SR_FIELD_TYPE] == "T") .AND. (ISPOSTGRESQL())
            IF aCreate[i, SR_FIELD_LEN] == 4
               cSql += "time  without time zone "
            ELSE
               cSql += "timestamp  without time zone "
            ENDIF
         CASE (aCreate[i, SR_FIELD_TYPE] == "T") .AND. (ISMYSQL() .OR. ISMARIADB())
         IF aCreate[i, SR_FIELD_LEN] == 4
             cSql += "time "
         ELSE
             cSql += "DATETIME "
         ENDIF

         // oracle datetime
         CASE (aCreate[i, SR_FIELD_TYPE] == "T") .AND. (ISORACLE() .OR. ISFIREBIRD() .OR. ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5())
            cSql += "TIMESTAMP "
         CASE (aCreate[i, SR_FIELD_TYPE] == "T") .AND. (ISMSSQL7()) // .AND. ::OSQL:lSqlServer2008 .AND. SR_Getsql2008newTypes()
            cSql += "DATETIME NULL "
         CASE (aCreate[i, SR_FIELD_TYPE] == "T") .AND. (ISMYSQL() .OR. ISMARIADB())
            cSql += "DATETIME "
         CASE (aCreate[i, SR_FIELD_TYPE] == "V") .AND. (ISMSSQL7())
             cSql += " VARBINARY(MAX) "

         OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")

         ENDCASE
#else
         SWITCH aCreate[i, SR_FIELD_TYPE]

         CASE "C"
            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_ORACLE
               IF aCreate[i, SR_FIELD_LEN] > 30
                  cSql += "VARCHAR2(" + LTrim(Str(Min(aCreate[i, SR_FIELD_LEN], 4000), 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
               ELSE
                  IF aCreate[i, SR_FIELD_LEN] > s_nMininumVarchar2Size .AND. s_nMininumVarchar2Size < 30
                    cSql += "VARCHAR2(" + LTrim(Str(Min(aCreate[i, SR_FIELD_LEN], 4000), 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
                  ELSE
                     cSql += "CHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
                  ENDIF
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_SQLBAS
               IF aCreate[i, SR_FIELD_LEN] > 254
                  cSql += "LONG VARCHAR"
               ELSE
                  cSql += "VARCHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", "")
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_MSSQL6
            CASE SQLRDD_RDBMS_MSSQL7
            CASE SQLRDD_RDBMS_POSTGR
            CASE SQLRDD_RDBMS_CACHE
            CASE SQLRDD_RDBMS_ADABAS
            CASE SQLRDD_RDBMS_AZURE
               IF ISMSSQL7() .OR. ISAZURE()
                  IF ::OSQL:lSqlServer2008 .AND. SR_Getsql2008newTypes()
                     IF aCreate[i, SR_FIELD_LEN] > 10
                        cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
                     ELSE
                        cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
                     ENDIF
                  ELSE
                     cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
                  ENDIF
               ELSEIF ISPOSTGRESQL() .AND. aCreate[i, SR_FIELD_LEN] > s_nMininumVarchar2Size -1 //10
                  cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
               ELSE
                  cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_MYSQL
            CASE SQLRDD_RDBMS_MARIADB
               IF aCreate[i, SR_FIELD_LEN] > 255
                  cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
               ELSE
                  cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_IBMDB2
               IF aCreate[i, SR_FIELD_LEN] > 255
                  cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
               ELSE
                  cSql += "CHARACTER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_INGRES
               cSql += "varchar(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IIf(lNotNull, " NOT NULL", ""))
               EXIT
            CASE SQLRDD_RDBMS_INFORM
               cSql += "CHARACTER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IIf(lNotNull, " NOT NULL", ""))
               EXIT
            CASE SQLRDD_RDBMS_ACCESS
               IF aCreate[i, SR_FIELD_LEN] > 254
                  cSql += "TEXT"
               ELSE
                  cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")"
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_SQLANY
               IF aCreate[i, SR_FIELD_LEN] > 254
                  cSql += "LONG VARCHAR "
               ELSE
                  cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + "  " + IIf(lNotNull, " NOT NULL", "")
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_FIREBR
               IF aCreate[i, SR_FIELD_LEN] > 254
                  cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "") + IIf(lNotNull, " NOT NULL", "")
               ELSE
                  cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")  + IIf(lNotNull, " NOT NULL", "")
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_SYBASE
               IF aCreate[i, SR_FIELD_LEN] > 30
                  cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
               ELSE
                 cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
               ENDIF
               EXIT
            SR_OTHERWISE
               SR_MsgLogFile(SR_Msg(9) + cField + " (C)")
            ENDSWITCH
            EXIT

         CASE "D"
            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_ORACLE
            CASE SQLRDD_RDBMS_SQLBAS
            CASE SQLRDD_RDBMS_INFORM
            CASE SQLRDD_RDBMS_INGRES
            CASE SQLRDD_RDBMS_MYSQL
            CASE SQLRDD_RDBMS_MARIADB
            CASE SQLRDD_RDBMS_FIREBR
            CASE SQLRDD_RDBMS_CACHE
               cSql += "DATE"
               EXIT
            CASE SQLRDD_RDBMS_SYBASE
               cSql += "DATETIME"
               EXIT
            CASE SQLRDD_RDBMS_IBMDB2
            CASE SQLRDD_RDBMS_POSTGR
            CASE SQLRDD_RDBMS_ADABAS
               cSql += "DATE"
               EXIT
            CASE SQLRDD_RDBMS_ACCESS
            CASE SQLRDD_RDBMS_MSSQL6
            CASE SQLRDD_RDBMS_MSSQL7
            CASE SQLRDD_RDBMS_AZURE
               cSql += "DATETIME NULL"
               EXIT
            CASE SQLRDD_RDBMS_SQLANY
               cSql += "TIMESTAMP"
               EXIT
            SR_OTHERWISE
               SR_MsgLogFile(SR_Msg(9) + cField + " (D)")
            ENDSWITCH
            EXIT

         CASE "L"
            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_MSSQL6
            CASE SQLRDD_RDBMS_MSSQL7
            CASE SQLRDD_RDBMS_CACHE
            CASE SQLRDD_RDBMS_AZURE
               cSql += "BIT"
               EXIT
            CASE SQLRDD_RDBMS_POSTGR
            CASE SQLRDD_RDBMS_ADABAS
               cSql += "BOOLEAN"
               EXIT
            CASE SQLRDD_RDBMS_MYSQL
            CASE SQLRDD_RDBMS_MARIADB
               cSql += "TINYINT"
               EXIT
            CASE SQLRDD_RDBMS_IBMDB2
            CASE SQLRDD_RDBMS_FIREBR
               cSql += "SMALLINT"
               EXIT
            CASE SQLRDD_RDBMS_SYBASE
               cSql += "BIT NOT NULL"
               EXIT
            CASE SQLRDD_RDBMS_SQLANY
               cSql += "NUMERIC (1) NULL"
               EXIT
            CASE SQLRDD_RDBMS_ORACLE
               cSql += "SMALLINT"
               EXIT
            CASE SQLRDD_RDBMS_INFORM
               cSql += "BOOLEAN"
               EXIT
            CASE SQLRDD_RDBMS_INGRES
               cSql += "tinyint"
               EXIT
            SR_OTHERWISE
               SR_MsgLogFile(SR_Msg(9) + cField + " (L)")
            ENDSWITCH
            EXIT

         CASE "M"
            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_SQLBAS
               IF aCreate[i, SR_FIELD_LEN] > 254
                  cSql += "LONG VARCHAR"
               ELSE
                  cSql += "VARCHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", "")
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_ORACLE
               cSql += "CLOB"
               cLobs += IIf(Empty(cLobs), "", ",") + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID)
               EXIT
            CASE SQLRDD_RDBMS_IBMDB2
               cSql += "CLOB (256000) " + IIf("DB2/400" $ ::oSql:cSystemName, "",  " NOT LOGGED COMPACT")
               EXIT
            CASE SQLRDD_RDBMS_MSSQL6
            CASE SQLRDD_RDBMS_MSSQL7
            CASE SQLRDD_RDBMS_POSTGR
            CASE SQLRDD_RDBMS_INFORM
            CASE SQLRDD_RDBMS_CACHE
            CASE SQLRDD_RDBMS_AZURE
               cSql += "TEXT"
               EXIT
            CASE SQLRDD_RDBMS_MYSQL
            CASE SQLRDD_RDBMS_MARIADB
               cSql += s_cMySqlMemoDataType
               EXIT
            CASE SQLRDD_RDBMS_ADABAS
               cSql += "LONG"
               EXIT
            CASE SQLRDD_RDBMS_INGRES
               cSql += "long varchar"
               EXIT
            CASE SQLRDD_RDBMS_ACCESS
               cSql += "TEXT NULL"
               EXIT
            CASE SQLRDD_RDBMS_SYBASE
               cSql += "TEXT"
               EXIT
            CASE SQLRDD_RDBMS_SQLANY
               cSql += "LONG VARCHAR"
               EXIT
            CASE SQLRDD_RDBMS_FIREBR
               cSql += "BLOB SUB_TYPE 1" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")
               EXIT
            SR_OTHERWISE
               SR_MsgLogFile(SR_Msg(9) + cField + " (M)")
            ENDSWITCH
            EXIT

         CASE "N"
            DO CASE // TODO: change to SWITCH
            CASE (ISMSSQL6() .OR. ISMSSQL7() .OR. ISSYBASE() .OR. ISAZURE()) .AND. cField == ::cRecnoName
               IF ::oSql:lUseSequences
                  cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") IDENTITY"
               ELSE
                  cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE"
               ENDIF
            CASE ISCACHE() .AND. cField == ::cRecnoName
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") UNIQUE " + [default objectscript '##class(] + SR_GetToolsOwner() + [SequenceControler).NEXTVAL("] + ::cFileName + [")']
            CASE (ISMSSQL6() .OR. ISMSSQL7() .OR. ISSYBASE() .OR. ISCACHE() .OR. ISAZURE())
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ") " + IIf(lNotNull, " NOT NULL ", "")
            CASE ISPOSTGRESQL() .AND. cField == ::cRecnoName
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") default (nextval('" + ::cOwner + LimitLen(::cFileName, 3) + "_SQ')) NOT NULL UNIQUE"
            CASE ISPOSTGRESQL()
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ")  default 0 " + IIf(lNotNull, " NOT NULL ", "")
            CASE (ISMYSQL() .OR. ISMARIADB()) .AND. cField == ::cRecnoName
               cSql += "BIGINT (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") NOT NULL UNIQUE AUTO_INCREMENT "
            CASE (ISMYSQL() .OR. ISMARIADB())
              cSql += s_cMySqlNumericDataType + " (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ") " + IIf(lNotNull, " NOT NULL ", "")
            CASE ISORACLE() .AND. cField == ::cRecnoName
               cSql += "NUMBER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" +;
                    IIf(lNotNull, " NOT NULL UNIQUE USING INDEX ( CREATE INDEX " + ::cOwner + LimitLen(::cFileName, 3) + "_UK ON " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + "( " + ::cRecnoName + ")" +;
                    IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx()) , "") + ")"
            CASE ISORACLE()
               cSql += "NUMBER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            CASE ISIBMDB2() .AND. cField == ::cRecnoName
               IF ::oSql:lUseSequences
                  cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE)"
               ELSE
                  cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL"
               ENDIF
            CASE ISADABAS() .AND. cField == ::cRecnoName
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL DEFAULT SERIAL"
            CASE (ISIBMDB2() .OR. ISADABAS())
               cSql += "DECIMAL(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            CASE ISINGRES() .AND. cField == ::cRecnoName
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE "
            CASE ISINFORM() .AND. cField == ::cRecnoName
               cSql += "SERIAL NOT NULL UNIQUE"
            CASE (ISINFORM() .OR. ISINGRES())
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY ", IIf(lNotNull, " NOT NULL", ""))
            CASE ISSQLBAS()
               IF aCreate[i, SR_FIELD_LEN] > 15
                  cSql += "NUMBER" + IIf(lPrimary, " NOT NULL", " ")
               ELSE
                  cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", " ")
               ENDIF
            CASE ISSQLANY()
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            CASE ISACCESS()
               cSql += "NUMERIC"
            CASE ISFIREBIRD() .AND. cField == ::cRecnoName
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE "
            CASE (ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5()) .AND. cField == ::cRecnoName
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") GENERATED BY DEFAULT AS IDENTITY  NOT NULL UNIQUE "
            CASE (ISFIREBIRD() .OR. ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5())
               IF aCreate[i, SR_FIELD_LEN] > 18
                  cSql += "DOUBLE PRECISION" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
               ELSE
                  cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) +  ")" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
               ENDIF
            OTHERWISE
               SR_MsgLogFile(SR_Msg(9) + cField + " (N)")
            ENDCASE
            EXIT

         CASE "T"
            // including xml data type
            // postgresql datetime
            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_POSTGR
               IF aCreate[i, SR_FIELD_LEN] == 4
                  cSql += "time  without time zone "
               ELSE
                  cSql += "timestamp  without time zone "
               ENDIF
               EXIT
            CASE SQLRDD_RDBMS_MYSQL
            CASE SQLRDD_RDBMS_MARIADB
               IF aCreate[i, SR_FIELD_LEN] == 4
                  cSql += "time "
               ELSE
                  cSql += "DATETIME "
               ENDIF
               EXIT
            // oracle datetime
            CASE SQLRDD_RDBMS_ORACLE
            CASE SQLRDD_RDBMS_FIREBR
            CASE SQLRDD_RDBMS_FIREBR3
            CASE SQLRDD_RDBMS_FIREBR4
            CASE SQLRDD_RDBMS_FIREBR5
               cSql += "TIMESTAMP "
               EXIT
            CASE SQLRDD_RDBMS_MSSQL7 // .AND. ::OSQL:lSqlServer2008 .AND. SR_Getsql2008newTypes()
               cSql += "DATETIME NULL "
               EXIT
            //CASE SQLRDD_RDBMS_MYSQL
            //CASE SQLRDD_RDBMS_MARIADB // TODO: why duplicated ?
            //   cSql += "DATETIME "
            //   EXIT
            SR_OTHERWISE
               SR_MsgLogFile(SR_Msg(9) + cField + " (T)")
            ENDSWITCH
            EXIT

         CASE "V"
            SWITCH ::oSql:nSystemID
            CASE SQLRDD_RDBMS_MSSQL7
               cSql += " VARBINARY(MAX) "
               EXIT
            SR_OTHERWISE
               SR_MsgLogFile(SR_Msg(9) + cField + " (V)")
            ENDSWITCH
            EXIT

         SR_OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")

         ENDSWITCH
#endif

         IF ISORACLE() .AND. (!Empty(SR_SetTblSpaceLob())) .AND. (!Empty(cLobs))
            cSql += " LOB (" + cLobs + ") STORE AS (TABLESPACE " + SR_SetTblSpaceLob() + ")"
         ENDIF

         lRet2 := ::oSql:Exec(cSql, lDisplayErrorMessage) == SQL_SUCCESS
         ::oSql:Commit()

         lRet := lRet .AND. lRet2

      ENDIF

      IF nPos_ > 0
         ::aFields[nPos_] := AClone(aCreate[i])
         ::aNames[nPos_] := aCreate[i, 1]
         ::aEmptyBuffer[nPos_] := SR_BlankVar(::aFields[Len(::aFields), SR_FIELD_TYPE], ::aFields[Len(::aFields), SR_FIELD_LEN], ::aFields[Len(::aFields), SR_FIELD_DEC])
      ELSE
         AAdd(::aFields, AClone(aCreate[i]))
         AAdd(::aNames, aCreate[i, 1])
         AAdd(::aEmptyBuffer, SR_BlankVar(::aFields[Len(::aFields), SR_FIELD_TYPE], ::aFields[Len(::aFields), SR_FIELD_LEN], ::aFields[Len(::aFields), SR_FIELD_DEC]))
         nPos_ := Len(::aFields)
      ENDIF

      ::nFields := Len(::aFields)
      ASize(::aLocalBuffer, ::nFields)
      ASize(::aSelectList, ::nFields)
      aFill(::aSelectList, 1)           // Next SELECT should include ALL columns

      aInfo := ::oSql:aTableInfo[::cOriginalFN]
      aInfo[SR_CACHEINFO_AFIELDS] := ::aFields
      aInfo[SR_CACHEINFO_ANAMES] := ::aNames
      aInfo[SR_CACHEINFO_ABLANK] := ::aEmptyBuffer

      // Add multilang columns in catalog

      FOR EACH aField IN aMultilang
         ::oSql:Exec("INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTLANG ( TABLE_ , COLUMN_, TYPE_, LEN_, DEC_ ) VALUES ( '" + Upper(::cFileName) + "','" + aField[SR_FIELD_NAME] + "', '" + aField[SR_FIELD_TYPE] + "','" + AllTrim(Str(aField[SR_FIELD_LEN], 8)) + "','" + AllTrim(Str(aField[SR_FIELD_DEC], 8)) + "' )")
         ::oSql:Commit()
         SR_LogFile("changestruct.log", {::cFileName, "Adding MLANG column:", "'" + aField[SR_FIELD_NAME] + "', '" + aField[SR_FIELD_TYPE] + "','" + AllTrim(Str(aField[SR_FIELD_LEN], 8)) + "'"})
         SR_ReloadMLHash(::oSql)
      NEXT

      aMultilang := {}

      IF lDataInBackup
         // Put data back in column
         IF ISORACLE() .AND. ::aFields[nPos_, SR_FIELD_TYPE] $ "CM"
            ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID) + " = RTRIM( BACKUP_ )", lDisplayErrorMessage)
         ELSE
            IF ISPOSTGRESQL() .AND. ::aFields[nPos_, SR_FIELD_TYPE] != aBack[1, 2]
               IF ::aFields[nPos_, SR_FIELD_TYPE] == "N" .AND. aBack[1, 2] == "C"
                  ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID) + " = BACKUP_::text::numeric::integer", lDisplayErrorMessage)
               //ELSEIF ::aFields[nPos_, SR_FIELD_TYPE] == "C" .AND. aBack[1, 2] == "N"
                  //::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID) + " = BACKUP_::numeric::integer::text", lDisplayErrorMessage)
               ELSE
                  ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID) + " = BACKUP_", lDisplayErrorMessage)
               ENDIF
            ELSE
            ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID) + " = BACKUP_", lDisplayErrorMessage)
            ENDIF
         ENDIF
         ::oSql:Commit()
         // Drop backup
         ::DropColumn("BACKUP_", lDisplayErrorMessage)
         lDataInBackup := .F.
      ENDIF

      IF lRet2 .AND. (!aCreate[i, SR_FIELD_NULLABLE])  // Column should be NOT NULL
         ::AddRuleNotNull(aCreate[i, SR_FIELD_NAME])
      ENDIF

   NEXT i

RETURN lRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:AlterColumnsDirect(aCreate, lDisplayErrorMessage, lBakcup, aRemove)

   LOCAL lRet := .T.
   LOCAL i
   LOCAL cSql
   LOCAL cField
   LOCAL lPrimary
   LOCAL lNotNull
   LOCAL lRet2
   LOCAL aInfo
   LOCAL aMultilang := {}
   LOCAL aField
   LOCAL nPos_
   LOCAL aBack
   LOCAL lDataInBackup := .F.
   LOCAL cLobs := ""
   LOCAL cTblName := NIL
   LOCAL lCurrentIsMultLang := .F.
   LOCAL nPos
   LOCAL cSql2 := ""
   LOCAL cSql3 := ""

   HB_SYMBOL_UNUSED(lCurrentIsMultLang)

   DEFAULT lBakcup TO .T.

   // Release any pending transaction before a DML command

   ::sqlGoCold()

   ::oSql:Commit()
   ::oSql:nTransacCount := 0

   DEFAULT lDisplayErrorMessage TO .T.

   // Check existing column

   FOR i := 1 TO Len(aCreate)

      ASize(aCreate[i], SR_FIELD_INFO_SIZE)
      cLobs := ""

      DEFAULT aCreate[i, SR_FIELD_PRIMARY_KEY] TO 0
      DEFAULT aCreate[i, SR_FIELD_NULLABLE] TO .T.
      DEFAULT aCreate[i, SR_FIELD_MULTILANG] TO MULTILANG_FIELD_OFF

      aCreate[i, SR_FIELD_NAME] := Upper(AllTrim(aCreate[i, SR_FIELD_NAME]))
      cField := aCreate[i, SR_FIELD_NAME]
      lPrimary := aCreate[i, SR_FIELD_PRIMARY_KEY] > 0

      IF (nPos_ := AScan(::aNames, {|x| AllTrim(Upper(x)) == cField})) > 0
         // Column exists

         lCurrentIsMultLang := ::aFields[nPos_, SR_FIELD_MULTILANG]

         IF lBakcup .AND. (!lCurrentIsMultLang)
            // Create backup column
            aBack := {AClone(::aFields[nPos_])}
            aBack[1, 1] := "BACKUP_"
            ::AlterColumns(aBack, lDisplayErrorMessage, .F.)
            ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET BACKUP_ = " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID), lDisplayErrorMessage)
            ::oSql:Commit()
            lDataInBackup := .T.
         ENDIF
      ELSE
         lCurrentIsMultLang := .F.
      ENDIF

      // DROP the column

      IF !(lCurrentIsMultLang .AND. aCreate[i, SR_FIELD_TYPE] $ "MC")

         cSql := "ALTER TABLE " + ::cQualifiedTableName
         IF ISPOSTGRESQL() .OR. ISFIREBIRD() .OR. ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5()
            cSql += " ALTER " + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID) + " TYPE "
         ELSEIF ISMYSQL() .OR. ISMARIADB()
            cSql += " MODIFY COLUMN " + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID)
         ELSEIF ISORACLE()
            cSql += " MODIFY (" + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID)
         ELSEIF ISMSSQL6() .OR. ISMSSQL7() .OR. ISCACHE() .OR. ISAZURE()
            cSql += " ALTER COLUMN " + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID)
         ENDIF
         cSql += " "

         // lNotNull := (!aCreate[i, SR_FIELD_NULLABLE]) .OR. lPrimary
         lNotNull := .F.

      ENDIF

      IF lCurrentIsMultLang .AND. aCreate[i, SR_FIELD_TYPE] $ "MC" .AND. SR_SetMultiLang()

         aField := AClone(aCreate[i])
         AAdd(aMultilang, AClone(aCreate[i]))
         ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLANG WHERE TABLE_ = '" + Upper(::cFileName) + "' AND COLUMN_ = '" + aField[SR_FIELD_NAME] + "'")
         ::oSql:Commit()
         SR_LogFile("changestruct.log", {::cFileName, "Removing MLANG column:", aField[SR_FIELD_NAME]})
         lRet2 := .F.

      ELSE

         IF aCreate[i, SR_FIELD_MULTILANG] .AND. aCreate[i, SR_FIELD_TYPE] $ "MC" .AND. SR_SetMultiLang()
            AAdd(aMultilang, AClone(aCreate[i]))
            aCreate[i, SR_FIELD_TYPE] := "M"
         ENDIF

         DO CASE // TODO: switch ?
         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISORACLE()
            IF aCreate[i, SR_FIELD_LEN] > 30
               cSql += "VARCHAR2(" + LTrim(Str(Min(aCreate[i, SR_FIELD_LEN], 4000), 9, 0)) + ")" + IIf(lNotNull, " NOT NULL )", ") ")
            ELSE
               IF aCreate[i, SR_FIELD_LEN] > s_nMininumVarchar2Size .AND. s_nMininumVarchar2Size < 30
                  cSql += "VARCHAR2(" + LTrim(Str(Min(aCreate[i, SR_FIELD_LEN], 4000), 9, 0)) + ")" + IIf(lNotNull, " NOT NULL )", ") ")
               ELSE
               cSql += "CHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL )", ")")
            ENDIF
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C" .OR. aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISSQLBAS()
            IF aCreate[i, SR_FIELD_LEN] > 254 .OR. aCreate[i, SR_FIELD_TYPE] == "M"
               cSql += "LONG VARCHAR"
            ELSE
               cSql += "VARCHAR(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISPOSTGRESQL() .OR. ISCACHE() .OR. ISADABAS() .OR. ISAZURE())
            IF ISMSSQL7() .OR. ISAZURE()
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(!Empty(SR_SetCollation()), "COLLATE " + SR_SetCollation() + " " , "")  + IIf(lNotNull, " NOT NULL", "")
            ELSEIF ISPOSTGRESQL() .AND. aCreate[i, SR_FIELD_LEN] > 10
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE aCreate[i, SR_FIELD_TYPE] == "C" .AND. (ISMYSQL() .OR. ISMARIADB())
            IF aCreate[i, SR_FIELD_LEN] > 255
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. (ISIBMDB2())
            IF aCreate[i, SR_FIELD_LEN] > 255
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHARACTER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISINGRES()
            cSql += "varchar(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IF(lNotNull, " NOT NULL", ""))

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISINFORM()
            cSql += "CHARACTER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY", IF(lNotNull, " NOT NULL", ""))

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISACCESS()
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "TEXT"
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")"
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISSQLANY()
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "LONG VARCHAR "
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + "  " + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ( ISFIREBIRD() .OR. ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5())
            IF aCreate[i, SR_FIELD_LEN] > 254
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "") + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")  + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "C") .AND. ISSYBASE()
            IF aCreate[i, SR_FIELD_LEN] > 30
               cSql += "VARCHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            ELSE
               cSql += "CHAR (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISORACLE()
            cSql += "CLOB"
            cLobs += IIf(Empty(cLobs), "", ",") + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID)

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISIBMDB2()
            cSql += "CLOB (256000) " + IIf("DB2/400" $ ::oSql:cSystemName, "",  " NOT LOGGED COMPACT")

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISPOSTGRESQL() .OR. ISINFORM() .OR. ISCACHE() .OR. ISAZURE())
            cSql += "TEXT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. (ISMYSQL() .OR. ISMARIADB())
            cSql += s_cMySqlMemoDataType

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISADABAS()
            cSql += "LONG"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISINGRES()
            cSql += "long varchar"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISACCESS()
            cSql += "TEXT NULL"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISSYBASE()
            cSql += "TEXT"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. ISSQLANY()
            cSql += "LONG VARCHAR"

         CASE (aCreate[i, SR_FIELD_TYPE] == "M") .AND. (ISFIREBIRD() .OR. ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5())
            cSql += "BLOB SUB_TYPE 1" + IIf(!Empty(::oSql:cCharSet), " CHARACTER SET " + ::oSql:cCharSet, "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISSYBASE() .OR. ISAZURE()) .AND. cField == ::cRecnoName
            IF ::oSql:lUseSequences
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") IDENTITY"
            ELSE
               cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE"
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISCACHE() .AND. cField == ::cRecnoName
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") UNIQUE " + [default objectscript '##class(] + SR_GetToolsOwner() + [SequenceControler).NEXTVAL("] + ::cFileName + [")']

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMSSQL6() .OR. ISMSSQL7() .OR. ISSYBASE() .OR. ISCACHE() .OR. ISAZURE())
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str (aCreate[i, SR_FIELD_DEC])) + ") " + IIf(lNotNull, " NOT NULL ", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISPOSTGRESQL() .AND. cField == ::cRecnoName
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") default (nextval('" + ::cOwner + LimitLen(::cFileName, 3) + "_SQ')) NOT NULL UNIQUE"
         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISPOSTGRESQL()

            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ")" //
            nPos := AScan(::aFields, {|x|AllTrim(Upper(x[1])) == AllTrim(Upper(cField))})
            IF nPos >0
               IF ::aFields[nPos, SR_FIELD_TYPE] == "C"
                  cSql += " using " + cField + "::numeric "
               ENDIF
            ENDIF
            cSql2 := "ALTER TABLE " + ::cQualifiedTableName
            cSql2 := cSql2 + " ALTER " + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID) + " SET DEFAULT 0"

            IF lNotNull
               cSql3 := "ALTER TABLE " + ::cQualifiedTableName
               cSql3 := cSql3 + " ALTER " + SR_DBQUALIFY(AllTrim(cField), ::oSql:nSystemID) + " SET "
               cSql3 := cSql3 + " NOT NULL "
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMYSQL() .OR. ISMARIADB()) .AND. cField == ::cRecnoName
            cSql += "BIGINT (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + ") NOT NULL UNIQUE AUTO_INCREMENT "
         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISMYSQL() .OR. ISMARIADB())
            cSql += s_cMySqlNumericDataType + " (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC])) + ") " + IIf(lNotNull, " NOT NULL ", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISORACLE() .AND. cField == ::cRecnoName
            cSql += "NUMBER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" +;
                 IIf(lNotNull, " NOT NULL UNIQUE USING INDEX ( CREATE INDEX " + ::cOwner + LimitLen(::cFileName, 3) + "_UK ON " + ::cOwner + SR_DBQUALIFY(cTblName, ::oSql:nSystemID) + "( " + ::cRecnoName + ")" +;
                 IIf(Empty(SR_SetTblSpaceIndx()), "", " TABLESPACE " + SR_SetTblSpaceIndx()) , "") + ")"
         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISORACLE()
            cSql += "NUMBER (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISIBMDB2() .AND. cField == ::cRecnoName
            IF ::oSql:lUseSequences
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1, NO CACHE)"
            ELSE
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL"
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISADABAS() .AND. cField == ::cRecnoName
            cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL DEFAULT SERIAL"

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISIBMDB2() .OR. ISADABAS())
            cSql += "DECIMAL(" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lNotNull, " NOT NULL", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISINGRES() .AND. cField == ::cRecnoName
            cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE "

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISINFORM() .AND. cField == ::cRecnoName
            cSql += "SERIAL NOT NULL UNIQUE"

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISINFORM() .OR. ISINGRES())
            cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") " + IIf(lPrimary, "NOT NULL PRIMARY KEY ", IIf(lNotNull, " NOT NULL", ""))

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISSQLBAS()
            IF aCreate[i, SR_FIELD_LEN] > 15
               cSql += "NUMBER" + IIf(lPrimary, " NOT NULL", " ")
            ELSE
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ")" + IIf(lPrimary, " NOT NULL", " ")
            ENDIF

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISSQLANY()
            cSql += "NUMERIC (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") " + IIf(lNotNull, " NOT NULL", "")

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISACCESS()
            cSql += "NUMERIC"

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. (ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5()) .AND. cField == ::cRecnoName
           cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") GENERATED BY DEFAULT AS IDENTITY  NOT NULL UNIQUE "

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ISFIREBIRD() .AND. cField == ::cRecnoName
           cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN])) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) + ") NOT NULL UNIQUE "

         CASE (aCreate[i, SR_FIELD_TYPE] == "N") .AND. ( ISFIREBIRD() .OR. ISFIREBIRD3() .OR. ISFIREBIRD4() .OR. ISFIREBIRD5())
            IF aCreate[i, SR_FIELD_LEN] > 18
               cSql += "DOUBLE PRECISION" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
            ELSE
               cSql += "DECIMAL (" + LTrim(Str(aCreate[i, SR_FIELD_LEN], 9, 0)) + "," + LTrim(Str(aCreate[i, SR_FIELD_DEC], 9, 0)) +  ")" + IIf(lPrimary .OR. lNotNull, " NOT NULL", " ")
            ENDIF

         OTHERWISE
            SR_MsgLogFile(SR_Msg(9) + cField + " (" + aCreate[i, SR_FIELD_TYPE] + ")")

         ENDCASE

         IF ISORACLE() .AND. (!Empty(SR_SetTblSpaceLob())) .AND. (!Empty(cLobs))
            cSql += " LOB (" + cLobs + ") STORE AS (TABLESPACE " + SR_SetTblSpaceLob() + ")"
         ENDIF

         lRet2 := ::oSql:Exec(cSql, lDisplayErrorMessage) == SQL_SUCCESS
         ::oSql:Commit()
         IF !Empty(cSql2) .AND. ISPOSTGRESQL()
             ::osql:Exec(cSql2, lDisplayErrorMessage)
             ::osql:Commit()
         ENDIF
         IF !Empty(cSql3) .AND. ISPOSTGRESQL()
             ::osql:Exec(cSql3, lDisplayErrorMessage)
             ::osql:Commit()
         ENDIF

         lRet := lRet .AND. lRet2

      ENDIF

      IF nPos_ > 0
         ::aFields[nPos_] := AClone(aCreate[i])
         ::aNames[nPos_] := aCreate[i, 1]
         ::aEmptyBuffer[nPos_] := SR_BlankVar(::aFields[Len(::aFields), SR_FIELD_TYPE], ::aFields[Len(::aFields), SR_FIELD_LEN], ::aFields[Len(::aFields), SR_FIELD_DEC])
      ELSE
         AAdd(::aFields, AClone(aCreate[i]))
         AAdd(::aNames, aCreate[i, 1])
         AAdd(::aEmptyBuffer, SR_BlankVar(::aFields[Len(::aFields), SR_FIELD_TYPE], ::aFields[Len(::aFields), SR_FIELD_LEN], ::aFields[Len(::aFields), SR_FIELD_DEC]))
         nPos_ := Len(::aFields)
      ENDIF

      ::nFields := Len(::aFields)
      ASize(::aLocalBuffer, ::nFields)
      ASize(::aSelectList, ::nFields)
      aFill(::aSelectList, 1)           // Next SELECT should include ALL columns

      aInfo := ::oSql:aTableInfo[::cOriginalFN]
      aInfo[SR_CACHEINFO_AFIELDS] := ::aFields
      aInfo[SR_CACHEINFO_ANAMES] := ::aNames
      aInfo[SR_CACHEINFO_ABLANK] := ::aEmptyBuffer

      // Add multilang columns in catalog

      FOR EACH aField IN aMultilang
         ::oSql:Exec("INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTLANG ( TABLE_ , COLUMN_, TYPE_, LEN_, DEC_ ) VALUES ( '" + Upper(::cFileName) + "','" + aField[SR_FIELD_NAME] + "', '" + aField[SR_FIELD_TYPE] + "','" + AllTrim(Str(aField[SR_FIELD_LEN], 8)) + "','" + AllTrim(Str(aField[SR_FIELD_DEC], 8)) + "' )")
         ::oSql:Commit()
         SR_LogFile("changestruct.log", {::cFileName, "Adding MLANG column:", "'" + aField[SR_FIELD_NAME] + "', '" + aField[SR_FIELD_TYPE] + "','" + AllTrim(Str(aField[SR_FIELD_LEN], 8)) + "'"})
         SR_ReloadMLHash(::oSql)
      NEXT

      aMultilang := {}

      IF lDataInBackup
         // Put data back in column
         IF ISORACLE() .AND. ::aFields[nPos_, SR_FIELD_TYPE] $ "CM"
            ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID) + " = RTRIM( BACKUP_ )", lDisplayErrorMessage)
         ELSE
            ::oSql:Exec("UPDATE " + ::cQualifiedTableName + " SET " + SR_DBQUALIFY(::aFields[nPos_, SR_FIELD_NAME], ::oSql:nSystemID) + " = BACKUP_", lDisplayErrorMessage)
         ENDIF
         ::oSql:Commit()
         // Drop backup
         ::DropColumn("BACKUP_", lDisplayErrorMessage)
         lDataInBackup := .F.
      ENDIF

      IF lRet2 .AND. (!aCreate[i, SR_FIELD_NULLABLE])  // Column should be NOT NULL
         ::AddRuleNotNull(aCreate[i, SR_FIELD_NAME])
      ENDIF

      IF lRet2
         nPos := AScan(aRemove, {|x|AllTrim(Upper(x[1])) == AllTrim(Upper(cField))})
         IF nPos >0
            hb_ADel(aRemove, nPos, .T.)
         ENDIF
      ENDIF

   NEXT i

RETURN lRet

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:OrdSetForClause(cFor, cForxBase)

   LOCAL i
   LOCAL cOut := ""
   LOCAL cWord := ""
   LOCAL cWordUpper

   HB_SYMBOL_UNUSED(cForxBase)

   cFor := AllTrim(cFor)

   IF ::aInfo[SR_AINFO_INDEXORD] > 0

      FOR i := 1 TO Len(cFor)
         IF !IsDigit(SubStr(cFor, i, 1)) .AND. !IsAlpha(SubStr(cFor, i, 1)) .AND. SubStr(cFor, i, 1) != "_"
            cWordUpper := Upper(cWord)
            IF Len(cWord) > 0 .AND. AScan(::aNames, {|x|x == cWordUpper}) > 0
               cOut += "A." + SR_DBQUALIFY(cWordUpper, ::oSql:nSystemID) + SubStr(cFor, i, 1)
            ELSE
               cOut += cWord + SubStr(cFor, i, 1)
            ENDIF
            cWord := ""
         ELSEIF IsDigit(SubStr(cFor, i, 1)) .OR. IsAlpha(SubStr(cFor, i, 1)) .OR. SubStr(cFor, i, 1) = "_"
            cWord += SubStr(cFor, i, 1)
         ELSE
           cOut += SubStr(cFor, i, 1)
         ENDIF
      NEXT i

      IF Len(cWord) > 0
         cWordUpper := Upper(cWord)
         IF AScan(::aNames, {|x|x == cWordUpper}) > 0
            cOut += "A." + SR_DBQUALIFY(cWordUpper, ::oSql:nSystemID) + SubStr(cFor, i, 1)
         ELSE
            cOut += cWord + SubStr(cFor, i, 1)
         ENDIF
      ENDIF

      ::cFor := cOut
      ::aIndex[::aInfo[SR_AINFO_INDEXORD], SR_AINDEX_FOR_CLAUSE] := cOut
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:ParseForClause(cFor)

   LOCAL i
   LOCAL cOut := ""
   LOCAL cWord := ""
   LOCAL cWordUpper

   cFor := AllTrim(cFor)

   FOR i := 1 TO Len(cFor)

      IF SubStr(cFor, i, 1) == Chr(34)
         cFor := stuff(cFor, i, 1, "'")
      ENDIF

      IF !IsDigit(SubStr(cFor, i, 1)) .AND. !IsAlpha(SubStr(cFor, i, 1)) .AND. SubStr(cFor, i, 1) != "_"

         IF SubStr(cFor, i, 1) == "-" .AND. SubStr(cFor, i + 1, 1) == ">"        // Remove ALIAS
            cWord := ""
            i ++
            LOOP
         ENDIF

         cWordUpper := Upper(cWord)
         IF Len(cWord) > 0 .AND. AScan(::aNames, {|x|x == cWordUpper}) > 0
            cOut += "A." + SR_DBQUALIFY(cWordUpper, ::oSql:nSystemID)
         ELSE
            cOut += cWord
         ENDIF

         IF SubStr(cFor, i, 1) == "." .AND. Lower(SubStr(cFor, i + 1, 1)) $ "aon"       // .AND. .OR.
            IF Lower(SubStr(cFor, i, 5)) == ".and."
               cOut += " AND "
               i += 4
               LOOP
            ENDIF
            IF Lower(SubStr(cFor, i, 5)) == ".not."
               cOut += " ! "
               i += 4
               LOOP
            ENDIF
            IF Lower(SubStr(cFor, i, 4)) == ".or."
               cOut += " OR "
               i += 3
               LOOP
            ENDIF
         ENDIF

         cOut += SubStr(cFor, i, 1)
         cWord := ""
      ELSEIF IsDigit(SubStr(cFor, i, 1)) .OR. IsAlpha(SubStr(cFor, i, 1)) .OR. SubStr(cFor, i, 1) = "_"
         cWord += SubStr(cFor, i, 1)
      ELSE
         cOut += SubStr(cFor, i, 1)
      ENDIF

   NEXT i

   IF Len(cWord) > 0
      cWordUpper := Upper(cWord)
      IF AScan(::aNames, {|x|x == cWordUpper}) > 0
         cOut += "A." + SR_DBQUALIFY(cWordUpper, ::oSql:nSystemID) + SubStr(cFor, i, 1)
      ELSE
         cOut += cWord + SubStr(cFor, i, 1)
      ENDIF
   ENDIF

   IF Upper(StrTran(cOut, " ", "")) == "!DELETED()"
      cOut := "A." + SR_DBQUALIFY(::cDeletedName, ::oSql:nSystemID) + " = ' '"
   ENDIF

RETURN cOut

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:HasFilters()

   IF !Empty(::cFilter) .OR. !Empty(::cFltUsr) .OR. !Empty(::cFor) .OR. !Empty(::cScope) .OR. (::lHistoric .AND. ::lHistEnable)
      RETURN .T.
   ENDIF

RETURN .F.

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:AddRuleNotNull(cColumn)

   LOCAL lOk := .T.
   LOCAL nCol
   LOCAL nRet := SQL_ERROR
   LOCAL uVal
   LOCAL cType

   nCol := AScan(::aNames, {|x|AllTrim(Upper(x)) == AllTrim(Upper(cColumn))})

   IF nCol > 0
      SWITCH ::aFields[nCol, SR_FIELD_TYPE]
      CASE "C"
         uVal := "' '"
         EXIT
      CASE "D"
         uVal := SR_cDBValue(SToD("17550101"))
         EXIT
      CASE "N"
         uVal := "0"
         EXIT
      SR_OTHERWISE
         lOk := .F.
//         ::RunTimeErr("", "Cannot change NULL constraint to datatype: " + ::aFields[nCol, SR_FIELD_TYPE])
      ENDSWITCH

      ::oSql:Commit()

      IF !lOk
         RETURN .F.
      ENDIF

      lOk := .F.

      nRet := ::oSql:Exec("UPDATE " +  ::cQualifiedTableName + " SET " + cColumn + " = " + uVal + " WHERE " + cColumn + " IS NULL", .F.)

      IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND

         ::oSql:Commit()

         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_IBMDB2
            IF ::AlterColumns({{::aFields[nCol, SR_FIELD_NAME], ::aFields[nCol, SR_FIELD_TYPE], ::aFields[nCol, SR_FIELD_LEN], ::aFields[nCol, SR_FIELD_DEC], .F.}}, .T.)
               nRet := SQL_SUCCESS
            ELSE
               nRet := SQL_ERROR
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_MYSQL
         CASE SQLRDD_RDBMS_MARIADB
            SWITCH ::aFields[nCol, SR_FIELD_TYPE]
            CASE "C"
               IF ::aFields[nCol, SR_FIELD_LEN] > 255
                  cType := "VARCHAR (" + Str(::aFields[nCol, SR_FIELD_LEN], 3) + ")"
               ELSE
                  cType := "CHAR (" + Str(::aFields[nCol, SR_FIELD_LEN], 3) + ")"
               ENDIF
               EXIT
            CASE "N"
               IF ISMYSQL()
                  // use type DECIMAL instead of REAL when using MySQL 8 or upper,
                  // except if the flag 'SQLRDD_MYSQL_REAL_DATA_TYPE' is set
                  #ifdef SQLRDD_MYSQL_REAL_DATA_TYPE
                  cType := s_cMySqlNumericDataType + " (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
                  #else
                  IF SubStr(::oSql:cSystemVers, 1, 1) == "5"
                     // maintain the original behavior when using MySQL 5
                     cType := s_cMySqlNumericDataType + " (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
                  ELSE
                     cType := "DECIMAL (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
                  ENDIF
                  #endif
               ELSE
                  // MariaDB
                  cType := "DECIMAL (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
               ENDIF
               EXIT
            CASE "D"
               cType := "DATE"
            ENDSWITCH
            nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " MODIFY " + cColumn + " " + cType + " NOT NULL", .F.)
            EXIT
         CASE SQLRDD_RDBMS_SYBASE
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_AZURE
            SWITCH ::aFields[nCol, SR_FIELD_TYPE]
            CASE "C"
               cType := "CHAR (" + Str(::aFields[nCol, SR_FIELD_LEN], 3) + ")"
               EXIT
            CASE "N"
               cType := "NUMERIC (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
               EXIT
            CASE "D"
               cType := "DATETIME"
            ENDSWITCH
            nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " ALTER COLUMN " + cColumn + " " + cType + " NOT NULL", .F.)
            EXIT
         CASE SQLRDD_RDBMS_ORACLE
            nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " MODIFY " + cColumn + " NOT NULL", .F.)
            EXIT
         CASE SQLRDD_RDBMS_POSTGR
            nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " ALTER COLUMN " + cColumn + " SET NOT NULL", .F.)
            EXIT
         CASE SQLRDD_RDBMS_FIREBR
            nRet := ::oSql:Exec("update RDB$RELATION_FIELDS set RDB$NULL_FLAG = 1 where (RDB$FIELD_NAME = '" + cColumn + "') and (RDB$RELATION_NAME = '" + ::cFileName + "')", .T.)
            EXIT
         CASE SQLRDD_RDBMS_FIREBR3
         CASE SQLRDD_RDBMS_FIREBR4
         CASE SQLRDD_RDBMS_FIREBR5
            nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " ALTER " + cColumn + " NOT NULL", .F.)
         ENDSWITCH
      ENDIF
   ENDIF

   IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND
      lOk := .T.
      ::aFields[nCol, SR_FIELD_NULLABLE] := .F.
   ENDIF

RETURN lOk

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:DropRuleNotNull(cColumn)

   LOCAL lOk := .T.
   LOCAL nCol
   LOCAL nRet := SQL_ERROR
   LOCAL cType

   nCol := AScan(::aNames, {|x|AllTrim(Upper(x)) == AllTrim(Upper(cColumn))})

   IF nCol > 0

      ::oSql:Commit()

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_IBMDB2
         EXIT
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
         SWITCH ::aFields[nCol, SR_FIELD_TYPE]
         CASE "C"
            cType := "CHAR (" + Str(::aFields[nCol, SR_FIELD_LEN], 3) + ")"
            EXIT
         CASE "N"
            IF ISMYSQL()
               // use type DECIMAL instead of REAL when using MySQL 8 or upper,
               // except if the flag 'SQLRDD_MYSQL_REAL_DATA_TYPE' is set
               #ifdef SQLRDD_MYSQL_REAL_DATA_TYPE
               cType := s_cMySqlNumericDataType + " (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
               #else
               IF SubStr(::oSql:cSystemVers, 1, 1) == "5"
                  // maintain the original behavior when using MySQL 5
                  cType := s_cMySqlNumericDataType + " (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
               ELSE
                  cType := "DECIMAL (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
               ENDIF
               #endif
            ELSE
               // MariaDB
               cType := "DECIMAL (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
            ENDIF
            EXIT
         CASE "D"
            cType := "DATE"
         ENDSWITCH
         nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " MODIFY " + cColumn + " " + cType + " NULL", .F.)
         EXIT
      CASE SQLRDD_RDBMS_SYBASE
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_AZURE
         SWITCH ::aFields[nCol, SR_FIELD_TYPE]
         CASE "C"
            cType := "CHAR (" + Str(::aFields[nCol, SR_FIELD_LEN], 3) + ")"
            EXIT
         CASE "N"
            cType := "NUMERIC (" + Str(::aFields[nCol, SR_FIELD_LEN], 4) + "," + Str(::aFields[nCol, SR_FIELD_DEC], 3) + ")"
            EXIT
         CASE "D"
            cType := "DATETIME"
         ENDSWITCH
         nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " ALTER COLUMN " + cColumn + " " + cType + " NULL", .F.)
         EXIT
      CASE SQLRDD_RDBMS_ORACLE
         nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " MODIFY " + cColumn + " NULL", .F.)
         EXIT
      CASE SQLRDD_RDBMS_POSTGR
         nRet := ::oSql:Exec("ALTER TABLE " + ::cQualifiedTableName + " ALTER COLUMN " + cColumn + " SET NULL", .F.)
      ENDSWITCH
   ENDIF

   IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND
      lOk := .T.
      ::aFields[nCol, SR_FIELD_NULLABLE] := .F.
   ENDIF

RETURN lOk

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:DropConstraint(cTable, cConstraintName, lFKs, cConstrType)

   LOCAL lOk := .T.
   LOCAL cSql
   LOCAL aLine := {}
   LOCAL aRet := {}
   LOCAL aRet2 := {}

   cTable := Upper(AllTrim(cTable))
   cConstraintName := Upper(AllTrim(cConstraintName))

   DEFAULT lFKs TO .T.

   IF cConstrType == NIL
      cConstrType := ""
   ENDIF

   cSql := "SELECT "
   cSql += "   A.SOURCETABLE_ , A.TARGETTABLE_, A.CONSTRNAME_, A.CONSTRTYPE_ "
   cSql += "FROM "
   cSql +=     SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS A "
   cSql += "WHERE "
   cSql += "       A.SOURCETABLE_ = '" + cTable          + "' "
   cSql += "   AND A.CONSTRNAME_  = '" + cConstraintName + "' "

   aRet := {}
   ::oSql:Exec(cSql, .T., .T., @aRet)

   IF Len(aRet) == 1

      IF lFKs .AND. AllTrim(aRet[1, 4]) == "PK"

         cSql := "SELECT "
         cSql += "   A.SOURCETABLE_ , A.TARGETTABLE_, A.CONSTRNAME_, A.CONSTRTYPE_ "
         cSql += "FROM "
         cSql +=    SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS A "
         cSql += "WHERE "
         cSql += "       A.TARGETTABLE_   = '" + cTable + "' "
         cSql += "   AND A.CONSTRTYPE_    = 'FK' "
         cSql += "ORDER BY "
         cSql += "   A.SOURCETABLE_ , A.CONSTRNAME_ "

         aRet2 := {}
         ::oSql:Exec(cSql, .T., .T., @aRet2)

         FOR EACH aLine IN aRet2

            ::DropConstraint(AllTrim(aLine[1]), AllTrim(aLine[3]), .F., AllTrim(aLine[4]))

         NEXT

         ::DropConstraint(cTable, cConstraintName, .F., "PK")

      ELSE

         SWITCH ::oSql:nSystemID
         CASE SQLRDD_RDBMS_MSSQL6
         CASE SQLRDD_RDBMS_MSSQL7
         CASE SQLRDD_RDBMS_SYBASE
         CASE SQLRDD_RDBMS_AZURE
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cTable, ::oSql:nSystemID) + " DROP CONSTRAINT " + cConstraintName + IIf(::oSql:lComments, " /* Create Constraint */", "")
            EXIT
         CASE SQLRDD_RDBMS_MYSQL
         CASE SQLRDD_RDBMS_MARIADB
            IF AllTrim(cConstrType) == "PK"
               cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cTable, ::oSql:nSystemID) + " DROP PRIMARY KEY " + IIf(::oSql:lComments, " /* Create Constraint */", "")
            ELSE
               cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cTable, ::oSql:nSystemID) + " DROP FOREIGN KEY " + cConstraintName + IIf(::oSql:lComments, " /* Create Constraint */", "")
            ENDIF
            EXIT
         CASE SQLRDD_RDBMS_ORACLE
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cTable, ::oSql:nSystemID) + " DROP CONSTRAINT " + cConstraintName + IIf(::oSql:lComments, " /* Create Constraint */", "")
            EXIT
         SR_OTHERWISE
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cTable, ::oSql:nSystemID) + " DROP CONSTRAINT " + cConstraintName + IIf(::oSql:lComments, " /* Create Constraint */", "")
         ENDSWITCH

         lOk := ::oSql:Exec(cSql,.T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO
         ::oSql:Commit()

         IF lOk
            ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS   WHERE SOURCETABLE_ = '" + cTable + "' AND CONSTRNAME_ = '" + cConstraintName + "'" + IIf(::oSql:lComments, " /* Wipe constraint info 01 */", ""), .T.)
            ::oSql:Commit()
             ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS WHERE SOURCETABLE_ = '" + cTable + "' AND CONSTRNAME_ = '" + cConstraintName + "'" + IIf(::oSql:lComments, " /* Wipe constraint info 01 */", ""),.T.)
              ::oSql:Commit()
             ::oSql:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS WHERE SOURCETABLE_ = '" + cTable + "' AND CONSTRNAME_ = '" + cConstraintName + "'" + IIf(::oSql:lComments, " /* Wipe constraint info 01 */", ""),.T.)
            ::oSql:Commit()
         ENDIF

      ENDIF

   ENDIF

RETURN lOk

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:CreateConstraint(cSourceTable, aSourceColumns, cTargetTable, aTargetColumns, cConstraintName)

   LOCAL i
   LOCAL cSql
   LOCAL lRet
   LOCAL aRet := {}
   LOCAL nCol
   LOCAL lPk := .F.
   LOCAL aRecreateIndex := {}
   LOCAL cSourceColumns := ""
   LOCAL cTargetColumns := ""
   LOCAL cCols

   HB_SYMBOL_UNUSED(lPk)

   cSourceTable := Upper(AllTrim(cSourceTable))
   cTargetTable := Upper(AllTrim(cTargetTable))
   cConstraintName := Upper(AllTrim(cConstraintName))

   // You can pass constraint KEY as a list or as array
   IF HB_IsArray(aTargetColumns) .AND. Len(aTargetColumns) > 0 .AND. HB_IsArray(aTargetColumns[1])
      aTargetColumns := aTargetColumns[1]
   ENDIF

   // check if the constraint already exists....
   ::oSql:Exec("SELECT A.CONSTRNAME_ FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS A WHERE A.SOURCETABLE_ = '" + cSourceTable + "' AND A.CONSTRNAME_ = '" + cConstraintName + "'", .F., .T., @aRet)

   IF Len(aRet) == 0
      FOR i := 1 TO Len(aSourceColumns)
         cSourceColumns += SR_DBQUALIFY(aSourceColumns[i], ::oSql:nSystemID)
         cSourceColumns += IIf(i == Len(aSourceColumns), "", ",")
      NEXT i

      FOR i := 1 TO Len(aTargetColumns)
         cTargetColumns += SR_DBQUALIFY(aTargetColumns[i], ::oSql:nSystemID)
         cTargetColumns += IIf(i == Len(aTargetColumns), "", ",")
      NEXT i

      IF ISORACLE() .AND. Len(cConstraintName) > 30     // Oracle sucks!
         cConstraintName := Right(cConstraintName, 30)
      ENDIF

      IF ISIBMDB2() .AND. Len(cConstraintName) > 18     // DB2 sucks!
         cConstraintName := Right(cConstraintName, 18)
      ENDIF
      // ? "OK", AllTrim(::cFileName) , AllTrim(cTargetTable) , Upper(AllTrim(cSourceColumns)) , Upper(AllTrim(cTargetColumns))
      lPk := (AllTrim(::cFileName) == AllTrim(cTargetTable) .AND. Upper(AllTrim(cSourceColumns)) == Upper(AllTrim(cTargetColumns)))

      IF lPk   // primary key, so lets perform an alter column setting not null property first...

         FOR i := 1 TO Len(aTargetColumns)

            nCol := AScan(::aNames, {|x|Upper(AllTrim(x)) == Upper(AllTrim(aTargetColumns[i]))})

            IF nCol > 0 .AND. ::aFields[nCol, SR_FIELD_NULLABLE]
               IF ISMSSQL6() .OR. ISMSSQL7() .OR. ISSYBASE() .OR. ISAZURE()
                  IF !::DropColRules(aTargetColumns[i], .F., @aRecreateIndex)
                     ::RunTimeErr("30", SR_Msg(30) + " Table: " + ::cFileName + " Column: " + aTargetColumns[i])
                  ENDIF
               ENDIF
               IF !::AddRuleNotNull(aTargetColumns[i])
                  ::RunTimeErr("30", SR_Msg(30) + " Table: " + ::cFileName + " Column: " + aTargetColumns[i])
               ENDIF
            ENDIF

         NEXT i

         FOR i := 1 TO Len(aRecreateIndex)
            cCols := StrTran(StrTran(StrTran(AllTrim(aRecreateIndex[i, 3]), ::cRecnoName, ""), ["], ""), ",", "+") // this comment fixes my stupid text editor's colorizer"
            IF cCols[Len(cCols)] == "+"
               cCols := Left(cCols,(Len(cCols) - 1))
            ENDIF
            ::sqlOrderCreate(AllTrim(aRecreateIndex[i, 4]), cCols , AllTrim(aRecreateIndex[i, 6]))
         NEXT i

      ENDIF

      SWITCH ::oSql:nSystemID
      CASE SQLRDD_RDBMS_MSSQL6
      CASE SQLRDD_RDBMS_MSSQL7
      CASE SQLRDD_RDBMS_SYBASE
      CASE SQLRDD_RDBMS_MYSQL
      CASE SQLRDD_RDBMS_MARIADB
      CASE SQLRDD_RDBMS_AZURE
         IF lPk
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " PRIMARY KEY (" + cTargetColumns + ")"
         ELSE
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " FOREIGN KEY (" + cSourceColumns + ") REFERENCES " + ::cOwner + SR_DBQUALIFY(cTargetTable, ::oSql:nSystemID) + " (" + cTargetColumns + ")"
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_ORACLE
         IF lPk
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " PRIMARY KEY (" + cTargetColumns + ")"
         ELSE
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " FOREIGN KEY (" + cSourceColumns + ") REFERENCES " + ::cOwner + SR_DBQUALIFY(cTargetTable, ::oSql:nSystemID) + " (" + cTargetColumns + ") "
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_FIREBR
      CASE SQLRDD_RDBMS_FIREBR3
      CASE SQLRDD_RDBMS_FIREBR4
      CASE SQLRDD_RDBMS_FIREBR5
         IF lPk
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " PRIMARY KEY (" + cTargetColumns + ")"
         ELSE
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " FOREIGN KEY (" + cSourceColumns + ") REFERENCES " + ::cOwner + SR_DBQUALIFY(cTargetTable, ::oSql:nSystemID) + " (" + cTargetColumns + ")"
         ENDIF
         EXIT
      CASE SQLRDD_RDBMS_POSTGR
         cSourceColumns := StrTran(cSourceColumns, Chr(34), "")
         cTargetColumns := StrTran(cTargetColumns, Chr(34), "")
         IF lPk
            cSql := "ALTER TABLE " + ::cOwner + StrTran(SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID), Chr(34), "") + " ADD CONSTRAINT " + cConstraintName + " PRIMARY KEY (" + cTargetColumns + ")"
         ELSE
            cSql := "ALTER TABLE " + ::cOwner + StrTran(SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID), Chr(34), "") + " ADD CONSTRAINT " + cConstraintName + " FOREIGN KEY (" + cSourceColumns + ") REFERENCES " + ::cOwner + StrTran(SR_DBQUALIFY(cTargetTable, ::oSql:nSystemID), Chr(34), "") + " (" + cTargetColumns + ")"
         ENDIF
         EXIT
      SR_OTHERWISE
         IF lPk
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " PRIMARY KEY (" + cTargetColumns + ")"
         ELSE
            cSql := "ALTER TABLE " + ::cOwner + SR_DBQUALIFY(cSourceTable, ::oSql:nSystemID) + " ADD CONSTRAINT " + cConstraintName + " FOREIGN KEY (" + cSourceColumns + ") REFERENCES " + ::cOwner + SR_DBQUALIFY(cTargetTable, ::oSql:nSystemID) + " (" + cTargetColumns + ")"
         ENDIF
      ENDSWITCH

      IF ISORACLE() .AND. lPK
         cSql += IIf(Empty(SR_SetTblSpaceIndx()), "", " USING INDEX TABLESPACE " + SR_SetTblSpaceIndx())
      ENDIF

      cSql +=  + IIf(::oSql:lComments, " /* Create constraint */", "")

      ::oSql:Commit()
      lRet := ::oSql:Exec(cSql, .T.) == SQL_SUCCESS .OR. ::oSql:nRetCode == SQL_SUCCESS_WITH_INFO

      IF lRet

         ::oSql:Commit()

         cSql := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS "
         cSql += "   (SOURCETABLE_ , TARGETTABLE_, CONSTRNAME_, CONSTRTYPE_) "
         cSql += "VALUES "
         cSql += "   ('" + cSourceTable + "','" + cTargetTable + "', '" + cConstraintName + "','"
         cSql +=     IIf(lPk, "PK", "FK") + "')"
         ::oSql:Exec(cSql, .T.)

         // aSourceColumns and aTargetColumns arrays has the same size (does it? sure???), so we can use just one loop...
         FOR i := 1 TO Len(aSourceColumns)

            cSql := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS "
            cSql += "   (SOURCETABLE_, CONSTRNAME_, ORDER_, SOURCECOLUMN_) "
            cSql += "VALUES "
            cSql += " ('" + cSourceTable + "','" + cConstraintName + "','" + StrZero(i, 2) + "','" + aSourceColumns[i] + "')"
            ::oSql:Exec(cSql, .T.)

            cSql := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS "
            cSql += "   (SOURCETABLE_, CONSTRNAME_, ORDER_, TARGETCOLUMN_) "
            cSql += "VALUES "
            cSql += " ('" + cSourceTable + "','" + cConstraintName + "','" + StrZero(i, 2) + "','" + aTargetColumns[i] + "')"
            ::oSql:Exec(cSql, .T.)

         NEXT i

         ::oSql:Commit()

      ENDIF

   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

FUNCTION SR_ParseFileName(cInd)

   LOCAL i
   LOCAL cRet := ""

   FOR i := Len(cInd) TO 1 STEP -1
      IF SubStr(cInd, i, 1) == "."
         cRet := ""
         LOOP
      ENDIF
      IF SubStr(cInd, i, 1) $ "\/:"
         EXIT
      ENDIF
      cRet := SubStr(cInd, i, 1) + cRet
   NEXT i

RETURN AllTrim(cRet)

//----------------------------------------------------------------------------//

STATIC FUNCTION CatSep(cP, cNam, cSep, cQot)

   LOCAL cRet := ""

   IF cQot == "NULL"
      DO CASE
      CASE cSep == " >= "
         cRet := ""
      CASE cSep == " = " .OR. cSep == " <= "
         cRet := cP + cNam + " IS NULL"
      CASE cSep == " > "
         cRet := cP + cNam + " IS NOT NULL"
      CASE cSep == " < "      // Query is dead (Killed)
         cRet := cP + " 0 = 1"
      ENDCASE
   ELSE
      cRet := cP + cNam + cSep + cQot
   ENDIF

RETURN cRet

//----------------------------------------------------------------------------//

FUNCTION SR_CleanTabInfoCache()

   LOCAL oCnn := SR_GetConnection()

   IF HB_IsObject(oCnn)
      oCnn:aTableInfo := {=>}
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//
// Get/Set s_lGoTopOnFirstInteract
//----------------------------------------------------------------------------//

FUNCTION SR_GetlGoTopOnFirstInteract()
RETURN s_lGoTopOnFirstInteract

FUNCTION SR_SetlGoTopOnFirstInteract(l)

   LOCAL lOld := s_lGoTopOnFirstInteract

   IF l != NIL
      s_lGoTopOnFirstInteract := l
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//
// Get/Set s_nLineCountResult
//----------------------------------------------------------------------------//

FUNCTION SR_GetnLineCountResult()
RETURN s_nLineCountResult

FUNCTION SR_SetnLineCountResult(l)

   LOCAL lOld := s_nLineCountResult

   IF l != NIL
      s_nLineCountResult := l
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//
// Get/Set s_lUseDTHISTAuto
//----------------------------------------------------------------------------//

FUNCTION SR_GetlUseDTHISTAuto()
RETURN s_lUseDTHISTAuto

FUNCTION SR_SetUseDTHISTAuto(l)

   LOCAL lOld := s_lUseDTHISTAuto

   IF l != NIL
      s_lUseDTHISTAuto := l
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//

STATIC FUNCTION LimitLen(cStr, nLen)

   IF Len(cStr) > (SR_MAX_TABLE_NAME_LENGHT - nLen)
      RETURN SubStr(cStr, 1, SR_MAX_TABLE_NAME_LENGHT - nLen)
   ENDIF

RETURN cStr

//----------------------------------------------------------------------------//
// Get/Set s_cGlobalOwner
//----------------------------------------------------------------------------//

FUNCTION SR_GetGlobalOwner()
RETURN s_cGlobalOwner

FUNCTION SR_SetGlobalOwner(cOwner)

   LOCAL cOld := s_cGlobalOwner
   LOCAL oSql

   IF cOwner != NIL
      s_cGlobalOwner := cOwner
   ELSE
      IF Empty(s_cGlobalOwner)
         oSql := SR_GetCnn()
         IF HB_IsObject(oSql) .AND. (!Empty(oSql:cOwner))
            RETURN oSql:cOwner
         ENDIF
      ENDIF
   ENDIF

RETURN cOld

//----------------------------------------------------------------------------//

FUNCTION SR_UseSequences(oCnn)

   DEFAULT oCnn TO SR_GetConnection()

   IF HB_IsObject(oCnn)
      RETURN oCnn:lUseSequences
   ENDIF

RETURN .T.

//----------------------------------------------------------------------------//

FUNCTION SR_SetUseSequences(lOpt, oCnn)

   LOCAL lOld := .T.

   DEFAULT oCnn TO SR_GetConnection()

   IF HB_IsObject(oCnn)
      lOld := oCnn:lUseSequences
      oCnn:lUseSequences := lOpt
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//

FUNCTION SR_SetMySQLMemoDataType(cOpt)

   LOCAL cOld := s_cMySqlMemoDataType

   IF cOpt != NIL
      s_cMySqlMemoDataType := cOpt
   ENDIF

RETURN cOld

//----------------------------------------------------------------------------//

FUNCTION SR_SetMySQLNumericDataType(cOpt)

   LOCAL cOld := s_cMySqlNumericDataType

   IF cOpt != NIL
      s_cMySqlNumericDataType := cOpt
   ENDIF

RETURN cOld

//----------------------------------------------------------------------------//

FUNCTION SR_TCNextRecord(oWA)

   LOCAL aRet := {}

   SWITCH oWA:oSQL:nSystemID
   CASE SQLRDD_RDBMS_SYBASE
   CASE SQLRDD_RDBMS_MSSQL7
   CASE SQLRDD_RDBMS_AZURE
      oWA:Exec("SELECT isnull(max(R_E_C_N_O_),0) + 1 AS R_E_C_N_O_ FROM " + SR_DBQUALIFY(oWA:cFileName, oWA:oSql:nSystemID), .F., .T., @aRet)
      EXIT
   CASE SQLRDD_RDBMS_ORACLE
      oWA:Exec("SELECT nvl(max(R_E_C_N_O_),0) + 1 AS R_E_C_N_O_ FROM " + SR_DBQUALIFY(oWA:cFileName, oWA:oSql:nSystemID), .F., .T., @aRet)
      EXIT
   CASE SQLRDD_RDBMS_IBMDB2
      oWA:Exec("SELECT value(max(R_E_C_N_O_),0) + 1 AS R_E_C_N_O_ FROM " + SR_DBQUALIFY(oWA:cFileName, oWA:oSql:nSystemID), .F., .T., @aRet)
      EXIT
   CASE SQLRDD_RDBMS_POSTGR
   CASE SQLRDD_RDBMS_MYSQL
   CASE SQLRDD_RDBMS_MARIADB
      oWA:Exec("SELECT coalesce(max(R_E_C_N_O_),0) + 1 AS R_E_C_N_O_ FROM " + SR_DBQUALIFY(oWA:cFileName, oWA:oSql:nSystemID), .F., .T., @aRet)
   ENDSWITCH

RETURN IIf(Len(aRet) > 0, aRet[1, 1], 0)

//----------------------------------------------------------------------------//

FUNCTION SR_SetlUseDBCatalogs(lSet)

   LOCAL lOld := s_lUseDBCatalogs

   IF lSet != NIL
      s_lUseDBCatalogs := lSet
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//

FUNCTION SR_SetAllowRelationsInIndx(lSet)

   LOCAL lOld := s_lAllowRelationsInIndx

   IF lSet != NIL
      s_lAllowRelationsInIndx := lSet
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//

FUNCTION SR_Serialize1(uVal)

   LOCAL cMemo := SR_STRTOHEX(HB_Serialize(uVal))

RETURN SR_SQL_SERIALIZED_SIGNATURE + Str(Len(cMemo), 10) + cMemo

//----------------------------------------------------------------------------//

STATIC FUNCTION OracleMinVersion(cString)

   STATIC s_reEnvVar

   LOCAL cMatch
   LOCAL nStart
   LOCAL nLen
   LOCAL cTemp := cString

   HB_SYMBOL_UNUSED(cTemp)

   IF s_reEnvVar == NIL
      s_reEnvVar := HB_RegexComp("(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9])[.]){3}(([2]([0-4][0-9]|[5][0-5])|[0-1]?[0-9]?[0-9]))")
   ENDIF

   cMatch := HB_AtX(s_reEnvVar, cString, @nStart, @nLen)

RETURN IIf(Empty(cMatch), 0, Val(hb_atokens(cMatch, '.')[1]))

//----------------------------------------------------------------------------//

METHOD SR_WORKAREA:RecnoExpr()

   LOCAL cRet := ""
   LOCAL aItem

   cRet +=  "( " +::cRecnoname  + " IN ( "
   FOR EACH aItem IN ::aRecnoFilter
      cRet += AllTrim(Str(aItem)) + ","
   NEXT
   cRet := SubStr(cRet, 1, Len(cRet) - 1) + " ) ) "

RETURN cRet

//----------------------------------------------------------------------------//

REQUEST SR_FROMXML
REQUEST SR_arraytoXml
REQUEST SR_DESERIALIZE

//----------------------------------------------------------------------------//
// Get/Set s_lUseXmlField
//----------------------------------------------------------------------------//

FUNCTION SR_getUseXmlField()
RETURN s_lUseXmlField

FUNCTION SR_SetUseXmlField(l)
   s_lUseXmlField := l
RETURN NIL

//----------------------------------------------------------------------------//
// Get/Set s_lUseJSONField
//----------------------------------------------------------------------------//

FUNCTION SR_getUseJSON()
RETURN s_lUseJSONField

FUNCTION SR_SetUseJSON(l)
   s_lUseJSONField := l
RETURN NIL

//----------------------------------------------------------------------------//

FUNCTION SR_SetMininumVarchar2Size(n)

   s_nMininumVarchar2Size := n

RETURN NIL

//----------------------------------------------------------------------------//

FUNCTION SR_SetOracleSyntheticVirtual(l)

   s_lOracleSyntheticVirtual := l

RETURN NIL

//----------------------------------------------------------------------------//

FUNCTION SR_GetOracleSyntheticVirtual()
RETURN s_lOracleSyntheticVirtual

//----------------------------------------------------------------------------//
