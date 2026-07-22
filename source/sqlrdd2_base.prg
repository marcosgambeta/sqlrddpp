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

//----------------------------------------------------------------------------//

CLASS SR_BASE_WORKAREA

   // TODO: add here common properties and methods

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

ENDCLASS

//----------------------------------------------------------------------------//
// SR_BASE_WORKAREA class methods
//----------------------------------------------------------------------------//

//----------------------------------------------------------------------------//
// Functions
//----------------------------------------------------------------------------//

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

REQUEST SR_FROMXML
REQUEST SR_arraytoXml
REQUEST SR_DESERIALIZE

//----------------------------------------------------------------------------//
