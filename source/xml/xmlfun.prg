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

// XML functions used by SR_BASE_WORKAREA/SR_WORKAREA classes

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

// TODO: remove unnecessary includes

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

//----------------------------------------------------------------------------//

STATIC s_aFather := {}
STATIC s_nStartId :=0
STATIC s_aPos := {}
STATIC s_nPosData := 0

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
