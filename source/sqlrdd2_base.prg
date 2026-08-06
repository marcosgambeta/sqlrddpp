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

STATIC s_lUseXmlField := .F.
STATIC s_lUseJSONField := .F.

STATIC s_lGoTopOnFirstInteract := .T.
STATIC s_lUseDTHISTAuto := .F.
STATIC s_nLineCountResult := 0
STATIC s_cGlobalOwner := ""
STATIC s_cMySqlMemoDataType := "MEDIUMBLOB" // TODO: used only by MySQL/MariaDB
STATIC s_cMySqlNumericDataType := "REAL" // TODO: used only by MySQL/MariaDB
STATIC s_lUseDBCatalogs := .F.
STATIC s_lAllowRelationsInIndx := .F.
STATIC s_lOracleSyntheticVirtual := .T. // TODO: used only by Oracle

//----------------------------------------------------------------------------//

CLASS SR_BASE_WORKAREA

   // TODO: add here common properties and methods

   CLASSDATA nCnt
   CLASSDATA cWSID
   CLASSDATA aExclusive       AS ARRAY    INIT {}
   CLASSDATA nOperat          AS NUMERIC  INIT 0

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
//    METHOD GetNextRecordNumber()

//    METHOD IniFields(lReSelect, lLoadCache, aInfo)
//    METHOD Refresh(lGoCold)
//    METHOD GetBuffer(lClean, nCache)
//    METHOD SolveSQLFilters(cAliasSQL)
//    METHOD SolveRestrictors()
//    METHOD Default()
//    METHOD UpdateCache(aResultSet)
//    METHOD lCanICommitNow()
//    METHOD WriteBuffer(lInsert, aBuffer)
//    METHOD QuotedNull(uData, trim, nLen, nDec, nTargetDB, lNull, lMemo)
//    METHOD Quoted(uData, trim, nLen, nDec, nTargetDB, lSynthetic)
//    METHOD CheckCache(oWorkArea)
//    METHOD WhereEqual()
//    METHOD RuntimeErr(cOperation, cErr, nOSCode, nGenCode, SubCode)
//    METHOD Normalize(nDirection)
//    METHOD SkipRawCache(nToSkip)
//    METHOD Stabilize()
//    METHOD FirstFetch(nDirection)
//    METHOD OrderBy(nOrder, lAscend, lRec)
//    METHOD ReadPage(nDirection, lWasDel)
//    METHOD WhereMajor()       // Retrieves an SQL/WHERE Major or equal the currente record
//    METHOD WhereMinor()       // Retrieves an SQL/WHERE Minor or equal the currente record
//    //METHOD WhereVMajor()       // Retrieves an SQL/WHERE Major or equal the currente record (Synthetic Virtual Index)
//    METHOD WhereVMajor(cQot)
//    //METHOD WhereVMinor()       // Retrieves an SQL/WHERE Minor or equal the currente record (Synthetic Virtual Index)
//    METHOD WhereVMinor(cQot)
//    //METHOD WherePgsMajor(aQuotedCols)    // Retrieves an SQL/WHERE Major or equal the currente record
//    METHOD WherePgsMajor(aQuotedCols, lPartialSeek)
//    METHOD WherePgsMinor(aQuotedCols)    // Retrieves an SQL/WHERE Minor or equal the currente record
//    // METHOD sqlKeyCompare(uKey)                       C level implemented - reads from ::aInfo
//    METHOD ParseIndexColInfo(cSQL)
   METHOD HasFilters()
//    METHOD ParseForClause(cFor)
//    METHOD OrdSetForClause(cFor, cForxBase)
   METHOD SetColPK(cColName)
//    METHOD ConvType(cData, cType, lPartialSeek, nThis, lLike)

//    METHOD LoadRegisteredTags()

//    METHOD LockTable(lCheck4ExcLock, lFLock) //METHOD LockTable(lCheck)
//    METHOD UnlockTable(lClosing) //METHOD UnlockTable()

   METHOD FCount() INLINE ::nFields
   METHOD SetNextDt(d) INLINE ::dNextDt := d
   METHOD SetQuickAppend(l)

   // Table maintanance stuff

//    METHOD AlterColumns(aCreate, lDisplayErrorMessage, lBakcup)
//    //This is an new method for direct alter column
//    METHOD AlterColumnsDirect(aCreate, lDisplayErrorMessage, lBakcup, aRemove)
//    METHOD DropColumn(cColumn, lDisplayErrorMessage, lRemoveFromWA)
//    METHOD DropColRules(cColumn, lDisplayErrorMessage, aDeletedIndexes)
//    METHOD AddRuleNotNull(cColumn)
//    METHOD DropRuleNotNull(cColumn)

//    METHOD DropConstraint(cTable, cConstraintName, lFKs, cConstrType)
//    METHOD CreateConstraint(cSourceTable, aSourceColumns, cTargetTable, aTargetColumns, cConstraintName)

   // Historic functionality specific methods

//    //METHOD HistExpression(cAlias, cAlias)
//    METHOD HistExpression(n, cAlias)
   METHOD DisableHistoric()
   METHOD EnableHistoric()
   METHOD SetCurrDate(d) INLINE IIf(d == NIL, ::CurrDate, ::CurrDate := d)
//
//    METHOD LineCount(lMsg) //METHOD LineCount()
//    METHOD CreateOrclFunctions(cOwner, cFileName)
//
//    METHOD sqlOpenAllIndexes()
//    METHOD IncludeAllMethods()

   // Workarea methods reflexion

   // METHOD sqlBof                       C level implemented - reads from ::aInfo
   // METHOD sqlEof                       C level implemented - reads from ::aInfo
   // METHOD qlFound                      C level implemented - reads from ::aInfo
//    METHOD sqlGoBottom()
//    METHOD sqlGoPhantom()
//    METHOD sqlGoTo(uRecord, lNoOptimize)
   // METHOD sqlGoToId                    C level implemented - maps to sqlGoTo()
//    METHOD sqlGoTop()
//    METHOD sqlSeek(uKey, lSoft, lLast)
   // METHOD sqlSkip                      C level implemented
   // METHOD sqlSkipFilter                Superclass does the job
   // METHOD sqlSkipRaw                   C level implemented
   // METHOD sqlAddField                  Superclass does the job
   // METHOD sqlAppend()                  C level implemented
   // METHOD sqlCreateFields              Superclass does the job
//    METHOD sqlDeleteRec()
   // METHOD sqlDeleted                   C level implemented - reads from ::aInfo
   // METHOD sqlFieldCount                C level implemented - reads from ::aInfo
   // METHOD sqlFieldDisplay              Superclass does the job
   // METHOD sqlFieldInfo                 Superclass does the job
   // METHOD sqlFieldName                 Superclass does the job
//    METHOD sqlFlush()
   // METHOD sqlGetRec                    Superclass does the job
//    METHOD sqlGetValue(nField)
   // METHOD sqlGetVarLen                 C level implemented - reads from aLocalBuffer
//    METHOD sqlGoCold()                     // NOT called from SQLRDD1.C
   // METHOD sqlGoHot                     C level implemented - writes to ::aInfo
   // METHOD sqlPutRec                    Superclass does the job
   // METHOD sqlPutValue                  C level implemented - writes to aLocalBuffer
//    METHOD sqlRecall()
   // METHOD sqlRecCount                  C level implemented - reads from ::aInfo
   // METHOD sqlRecInfo                   Superclass does the job
   // METHOD sqlRecNo                     C level implemented - reads from ::aInfo
   // METHOD sqlSetFieldExtent            Superclass does the job
   // METHOD sqlAlias                     Superclass does the job
//    METHOD sqlClose()
//    METHOD sqlCreate(aStruct, cFileName, cAlias, nArea)
   // METHOD sqlInfo                      C level implemented - reads from ::aInfo
   // METHOD sqlNewArea                   Superclass does the job
   // METHOD sqlOpenArea(cFileName, nArea, lShared, lReadOnly, cAlias) // the constructor
//    METHOD sqlOpenArea(cFileName, nArea, lShared, lReadOnly, cAlias, nDBConnection)
   // METHOD sqlRelease                   Superclass does the job
   // METHOD sqlStructSize                C level implemented
   // METHOD sqlSysName                   C level implemented
   // METHOD sqlEval                      Superclass does the job
//    METHOD sqlPack()
   // METHOD sqlPackRec                   Superclass does the job
   // METHOD sqlSort                      Superclass does the job - UNSUPPORTED
   // METHOD sqlTrans                     Superclass does the job
   // METHOD sqlTransRec                  Superclass does the job
//    METHOD sqlZap()
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
//    METHOD sqlOrderListAdd(cBagName, cTag)
   METHOD sqlOrderListClear()
   // METHOD sqlOrderListDelete           Superclass does the job
//    METHOD sqlOrderListFocus(uOrder, cBag)
//    METHOD sqlOrderListNum(uOrder)       // Used by sqlOrderInfo
   // METHOD sqlOrderListRebuild          Superclass does the job - UNSUPPORTED
//    METHOD sqlOrderCondition(cFor, cWhile, nStart, nNext, uRecord, lRest, lDesc)
//    METHOD sqlOrderCreate(cIndexName, cColumns, cTag, cConstraintName, cTargetTable, aTargetColumns, lEnable)
//    METHOD sqlOrderDestroy(uOrder, cBag)
   // METHOD sqlOrderInfo                 C level implemented - reads from ::aInfo and ::aIndex
//    METHOD sqlClearFilter()
   // METHOD sqlClearLocate               Superclass does the job
//    METHOD sqlClearScope()
   // METHOD sqlCountScope                Superclass does the job
   METHOD sqlFilterText()
   // METHOD sqlScopeInfo                 C level implemented
//    METHOD sqlSetFilter(cFilter)
   // METHOD sqlSetLocate                 Superclass does the job
//    METHOD sqlSetScope(nType, uValue)
   // METHOD sqlSkipScope                 Superclass does the job
   // METHOD sqlCompile                   Superclass does the job
   // METHOD sqlError                     Superclass does the job
   // METHOD sqlEvalBlock                 Superclass does the job
   // METHOD sqlRawLock                   Superclass does the job
//    METHOD sqlLock(nType, uRecord)
//    METHOD sqlUnLock(uRecord)
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

//    METHOD SetBOF()
//    METHOD sqlKeyCount(lFilters)
   METHOD sqlRecSize()
//    METHOD GetSyntheticVirtualExpr(aExpr, cAlias)
//    METHOD GetSelectList()
   METHOD RecnoExpr()   // add recno filters
   // DESTRUCTOR WA_ENDED

ENDCLASS

//----------------------------------------------------------------------------//
// SR_BASE_WORKAREA class methods
//----------------------------------------------------------------------------//

// PROCEDURE SR_WORKAREA:WA_ENDED
//
//    ? "Cleanup:", "WORKAREA", ::cFileName
//
// RETURN

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:SetColPK(cColName)

   LOCAL nPos := AScan(::aNames, {|x|x == Upper(cColName)})

   IF nPos > 0
      ::nPosCOlPK := nPos
      ::cColPK := Upper(cColName)
   ENDIF

RETURN ::cColPK

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:DisableHistoric()

   LOCAL i

   ::lHistEnable := .F.
   FOR i := 1 TO Len(::aIndex)
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_UP] := NIL
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_DOWN] := NIL
   NEXT i

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:EnableHistoric()

   LOCAL i

   ::lHistEnable := .T.
   FOR i := 1 TO Len(::aIndex)
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_UP] := NIL
      ::aIndex[i, SR_AINDEX_ORDER_SKIP_DOWN] := NIL
   NEXT i

RETURN NIL

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:SetQuickAppend(l)

   LOCAL lOld := ::lQuickAppend

   ::lQuickAppend := l

RETURN lOld

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:sqlOrderListClear()

   ::aInfo[SR_AINFO_FOUND] := .F.
   ASize(::aIndex, 0)
   ::cFor := ""
   ::aInfo[SR_AINFO_INDEXORD] := 0
   ::lStable := .T.
   ::lOrderValid := .F.

RETURN .T.

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:sqlFilterText()

   IF ::cFilter == NIL
      RETURN ""
   ENDIF

RETURN ::cFilter

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:sqlRecSize()

   LOCAL i := 0
   LOCAL aCol

   FOR EACH aCol IN ::aFields
      i += aCol[3]
   NEXT

RETURN i

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:RecnoExpr()

   LOCAL cRet := ""
   LOCAL aItem

   cRet +=  "( " +::cRecnoname  + " IN ( "
   FOR EACH aItem IN ::aRecnoFilter
      cRet += AllTrim(Str(aItem)) + ","
   NEXT
   cRet := SubStr(cRet, 1, Len(cRet) - 1) + " ) ) "

RETURN cRet

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:HasFilters()

   IF !Empty(::cFilter) .OR. !Empty(::cFltUsr) .OR. !Empty(::cFor) .OR. !Empty(::cScope) .OR. (::lHistoric .AND. ::lHistEnable)
      RETURN .T.
   ENDIF

RETURN .F.

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:sqlDrop(cFileName)

   IF SR_ExistTable(cFileName)
      SR_DropTable(cFileName)
   ELSEIF SR_ExistIndex(cFileName)
      SR_DropIndex(cFileName)
   ELSE
      RETURN .F.
   ENDIF

RETURN .T.

//----------------------------------------------------------------------------//

METHOD SR_BASE_WORKAREA:sqlExists(cFileName)
RETURN SR_File(cFileName)

//----------------------------------------------------------------------------//
// Functions
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

FUNCTION SR_CleanTabInfoCache()

   LOCAL oCnn := SR_GetConnection()

   IF HB_IsObject(oCnn)
      oCnn:aTableInfo := {=>}
   ENDIF

RETURN NIL

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
// Get/Set s_cMySqlMemoDataType (TODO: used only by MySQL/MariaDB)
//----------------------------------------------------------------------------//

FUNCTION SR_GetMySQLMemoDataType()
RETURN s_cMySqlMemoDataType

FUNCTION SR_SetMySQLMemoDataType(cOpt)

   LOCAL cOld := s_cMySqlMemoDataType

   IF cOpt != NIL
      s_cMySqlMemoDataType := cOpt
   ENDIF

RETURN cOld

//----------------------------------------------------------------------------//
// Get/Set s_cMySqlNumericDataType (TODO: used only by MySQL/MariaDB)
//----------------------------------------------------------------------------//

FUNCTION SR_GetMySQLNumericDataType()
RETURN s_cMySqlNumericDataType

FUNCTION SR_SetMySQLNumericDataType(cOpt)

   LOCAL cOld := s_cMySqlNumericDataType

   IF cOpt != NIL
      s_cMySqlNumericDataType := cOpt
   ENDIF

RETURN cOld

//----------------------------------------------------------------------------//
// Get/Set s_lUseDBCatalogs
//----------------------------------------------------------------------------//

FUNCTION SR_GetlUseDBCatalogs()
RETURN s_lUseDBCatalogs

FUNCTION SR_SetlUseDBCatalogs(lSet)

   LOCAL lOld := s_lUseDBCatalogs

   IF lSet != NIL
      s_lUseDBCatalogs := lSet
   ENDIF

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//
// Get/Set s_lAllowRelationsInIndx
//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetlAllowRelationsInIndx()
RETURN s_lAllowRelationsInIndx

FUNCTION SR_SetAllowRelationsInIndx(lSet)

   LOCAL lOld := s_lAllowRelationsInIndx

   IF lSet != NIL
      s_lAllowRelationsInIndx := lSet
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//
// Get/Set s_lOracleSyntheticVirtual (TODO: used only by Oracle)
//----------------------------------------------------------------------------//

FUNCTION SR_GetOracleSyntheticVirtual()
RETURN s_lOracleSyntheticVirtual

FUNCTION SR_SetOracleSyntheticVirtual(l)

   s_lOracleSyntheticVirtual := l

RETURN NIL

//----------------------------------------------------------------------------//

REQUEST SR_FROMXML
REQUEST SR_arraytoXml
REQUEST SR_DESERIALIZE

//----------------------------------------------------------------------------//
