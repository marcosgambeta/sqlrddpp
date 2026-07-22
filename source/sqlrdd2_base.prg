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

STATIC s_aFather := {}
STATIC s_nStartId :=0
STATIC s_aPos := {}
STATIC s_nPosData := 0

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

FUNCTION SR_SetlGoTopOnFirstInteract(l)

   LOCAL lOld := s_lGoTopOnFirstInteract

   IF l != NIL
      s_lGoTopOnFirstInteract := l
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//

FUNCTION SR_GetlGoTopOnFirstInteract()
RETURN s_lGoTopOnFirstInteract

//----------------------------------------------------------------------------//

FUNCTION SR_SetUseDTHISTAuto(l)

   LOCAL lOld := s_lUseDTHISTAuto

   IF l != NIL
      s_lUseDTHISTAuto := l
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//

FUNCTION SR_GetlUseDTHISTAuto()
RETURN s_lUseDTHISTAuto

//----------------------------------------------------------------------------//

FUNCTION SR_SetnLineCountResult(l)

   LOCAL lOld := s_nLineCountResult

   IF l != NIL
      s_nLineCountResult := l
   ENDIF

RETURN lOld

//----------------------------------------------------------------------------//

FUNCTION SR_GetnLineCountResult()
RETURN s_nLineCountResult

//----------------------------------------------------------------------------//

FUNCTION SR_GetGlobalOwner()
RETURN s_cGlobalOwner

//----------------------------------------------------------------------------//

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
// XML functions (TODO: move to a separate file ?)
//----------------------------------------------------------------------------//

REQUEST SR_FROMXML
REQUEST SR_arraytoXml
REQUEST SR_DESERIALIZE

//----------------------------------------------------------------------------//

FUNCTION SR_arraytoXml(a)

   //LOCAL cItem
   LOCAL hHash
#ifdef __XHARBOUR__
   LOCAL oXml := TXmlDocument():new() // Cria um objeto Xml
#else
   LOCAL oXml := sr_TXmlDocument():new() // Cria um objeto Xml
#endif
   LOCAL oNode
   //LOCAL oNode1
   LOCAL aItem

   s_nPosData := 0
   hhash := hb_hash()

   hHash["version"] := "1.0"

   hHash[ "encoding"] := "utf-8"
#ifdef __XHARBOUR__
   oNode := tXMLNode():New(HBXML_TYPE_PI, "xml", hHash, ;
      "version=" + Chr(34) + "1.0" + Chr(34) + " encoding=" + Chr(34) + "utf-8" + Chr(34) + "")
#else
   oNode := sr_tXMLNode():New(SR_XML_TYPE_PI, "xml", hHash, ;
      "version=" + Chr(34) + "1.0" + Chr(34) + " encoding=" + Chr(34) + "utf-8" + Chr(34) + "")
#endif
   oXml:oRoot:Addbelow(oNode)
   hhash := hb_hash()
   hhash["Type"] := ValType(a)
   hhash["Len"] := AllTrim(Str(Len(a)))
   hHash["Id"] := AllTrim(Str(s_nStartId))
   hHash["FatherId"] := AllTrim("-1")
#ifdef __XHARBOUR__
   oNode := tXMLNode():New(HBXML_TYPE_TAG, "Array", hhash)
#else
   oNode := sr_tXMLNode():New(SR_XML_TYPE_TAG, "Array", hhash)
#endif
   FOR EACH aItem IN a
      addNode(aItem, ONode)
   NEXT
   hhash := {}
   HB_SYMBOL_UNUSED(hhash)
   oXml:oRoot:addBelow(oNode)

RETURN oXml

//----------------------------------------------------------------------------//

STATIC FUNCTION AddNode(a, oNode)

   LOCAL oNode1
   LOCAL hHash := hb_Hash()
   //LOCAL oNode2
   LOCAL aItem
   //LOCAL theData

   hhash["Type"] := ValType(a)

   IF HB_IsArray(a)
      hhash["Len"] := AllTrim(Str(Len(a)))
      hhash["Type"] := ValType(a)
      AAdd(s_aFather, s_nStartId)
      ++s_nStartId
      hHash["Id"] := AllTrim(Str(s_nStartId))
      hHash["FatherId"] := AllTrim(Str(s_aFather[Len(s_aFather)]))
      hHash["Pos"] := AllTrim(Str(++s_nPosData))
      AAdd(s_aPos, s_nPosData)

      s_nPosData := 0
#ifdef __XHARBOUR__
      oNode1 := tXMLNode():New(HBXML_TYPE_TAG, "Array", hhash)
#else
      oNode1 := sr_tXMLNode():New(SR_XML_TYPE_TAG, "Array", hhash)
#endif
      FOR EACH aItem IN a
         AddNode(aItem, oNode1)
         //oNode1:addbelow(onode2)
      NEXT
      s_nStartId := s_aFather[Len(s_aFather)]
      s_nPosData := s_aPos[Len(s_aPos)]
      hb_ADel(s_aFather, Len(s_aFather), .T.)
      hb_ADel(s_aPos, Len(s_aPos), .T.)
      oNode:addbelow(oNode1)
   ELSE
      IF HB_IsNumeric(a) // TODO: switch ?
         hHash["Value"] := AllTrim(Str(a))
      ELSEIF HB_IsLogical(a)
         hHash["Value"] := IIf(a, "T", "F")
      ELSEIF HB_IsDate(a)
         hHash["Value"] := DToS(a)
      ELSE
         hHash["Value"] := a
      ENDIF
      hHash["Pos"] := AllTrim(Str(++s_nPosData))
      hHash["Id"] := AllTrim(Str(s_nStartId))
#ifdef __XHARBOUR__
      oNode1 := tXMLNode():New(HBXML_TYPE_TAG, "Data", hhash)
#else
      oNode1 := sr_tXMLNode():New(SR_XML_TYPE_TAG, "Data", hhash)
#endif
      oNode:addBelow(oNode1)
   ENDIF

RETURN NIL

//----------------------------------------------------------------------------//

FUNCTION SR_fromXml(oDoc, aRet, nLen, c)

   LOCAL oNode
   //LOCAL Curnode
   //LOCAL nId
   LOCAL CurPos
   LOCAL nStart := 0

   IF nLen == -1 .AND. !("<Array" $ c)
      aRet := {}
      RETURN {}
   ENDIF
   IF nLen == -1 .AND. !("<?xml" $ c)
      c := "<?xml version=" + Chr(34) + "1.0" + Chr(34) + " encoding=" + Chr(34) + "utf-8" + Chr(34) + "?>" + c
   ENDIF
   IF oDoc == NIL
#ifdef __XHARBOUR__
      oDoc := txmldocument():new(c)
#else
      oDoc := sr_txmldocument():new(c)
#endif
   ENDIF

   oNode := oDoc:CurNode
   HB_SYMBOL_UNUSED(oNode)
   oNode := oDoc:Next()
   DO WHILE oNode != NIL
      IF oNode:nType == 6 .OR. oNode:nType == 2
         oNode := oDoc:Next()
         LOOP
      ENDIF

      oNode := oDoc:CurNode
      IF oNode:cName == "Array"
         IF Val(oNode:AATTRIBUTES["Id"]) == 0 .AND. Val(oNode:AATTRIBUTES["FatherId"]) == -1
            aRet := Array(Val(oNode:AATTRIBUTES["Len"]))
         ELSEIF Val(oNode:AATTRIBUTES["Id"]) == 0
            CurPos := Val(oNode:AATTRIBUTES["Pos"])
            aRet[CurPos] := Array(Val(oNode:AATTRIBUTES["Len"]))
            SR_fromXml(@oDoc, @aRet[CurPos], Val(oNode:AATTRIBUTES["Len"]))
         ELSE
            CurPos := Val(oNode:AATTRIBUTES["Pos"])
            aRet[CurPos] := Array(Val(oNode:AATTRIBUTES["Len"]))
            SR_fromXml(@oDoc, @aRet[CurPos], Val(oNode:AATTRIBUTES["Len"]))
         ENDIF
      ENDIF
      IF oNode:cName == "Data"
         //IF Val(oNode:AATTRIBUTES["Id"]) == 0
         CurPos := Val(oNode:AATTRIBUTES["Pos"])
         SWITCH oNode:AATTRIBUTES["Type"]
         CASE "C"
            aRet[CurPos] := oNode:AATTRIBUTES["Value"]
            EXIT
         CASE "L"
            aRet[CurPos] := IIf(oNode:AATTRIBUTES["Value"] == "F", .F., .T.)
            EXIT
         CASE "N"
            aRet[CurPos] := Val(oNode:AATTRIBUTES["Value"])
            EXIT
         CASE "D"
            aRet[CurPos] := SToD(oNode:AATTRIBUTES["Value"])
         ENDSWITCH
         //ELSE
         //endif
      ENDIF
      nStart++
      IF nStart == nLen
         EXIT
      ENDIF
      oNode := oDoc:Next()

   ENDDO

RETURN aret

//----------------------------------------------------------------------------//

FUNCTION SR_getUseXmlField()
RETURN s_lUseXmlField

//----------------------------------------------------------------------------//

FUNCTION SR_SetUseXmlField(l)
   s_lUseXmlField := l
RETURN NIL

//----------------------------------------------------------------------------//

FUNCTION SR_getUseJSON()
RETURN s_lUseJSONField

//----------------------------------------------------------------------------//

FUNCTION SR_SetUseJSON(l)
   s_lUseJSONField := l
RETURN NIL

//----------------------------------------------------------------------------//
