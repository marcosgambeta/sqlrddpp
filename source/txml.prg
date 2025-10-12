//
// HBXML - XML DOM oriented routines - Classes encapsulating the document
//
// Copyright 2003 Giancarlo Niccolai <gian@niccolai.ws>
//    See also MXML library related copyright in hbxml.c
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
// along with this program; see the file LICENSE.txt.  If not, write to
// the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
// Boston, MA 02110-1301 USA (or visit https://www.gnu.org/licenses/).
//
// As a special exception, the Harbour Project gives permission for
// additional uses of the text contained in its release of Harbour.
//
// The exception is that, if you link the Harbour libraries with other
// files to produce an executable, this does not by itself cause the
// resulting executable to be covered by the GNU General Public License.
// Your use of that executable is in no way restricted on account of
// linking the Harbour library code into it.
//
// This exception does not however invalidate any other reasons why
// the executable file might be covered by the GNU General Public License.
//
// This exception applies only to the code released by the Harbour
// Project under the name Harbour.  If you copy code from other
// Harbour Project or Free Software Foundation releases into a copy of
// Harbour, as the General Public License permits, the exception does
// not apply to the code that you add in this way.  To avoid misleading
// anyone as to the status of such modified files, you must delete
// this exception notice from them.
//
// If you write modifications of your own for Harbour, it is your choice
// whether to permit this exception to apply to your modifications.
// If you do not wish that, delete this exception notice.
// $END_LICENSE$

#include <fileio.ch>
#include "srxml.ch"
#include <hbclass.ch>

//-------------------------------------------------------------------------------------------------------------------//

CREATE CLASS sr_TXMLNode

   VAR nType
   VAR cName
   VAR aAttributes
   VAR nBeginLine
   VAR cData

   VAR oNext
   VAR oPrev
   VAR oParent
   VAR oChild

   METHOD New(nType, cName, aAttributes, cData) CONSTRUCTOR
   METHOD Clone() INLINE srxml_node_clone(Self)
   METHOD CloneTree() INLINE srxml_node_clone_tree(Self)

   METHOD Unlink() INLINE srxml_node_unlink(Self)
   METHOD NextInTree()

   METHOD InsertBefore(oNode) INLINE srxml_node_insert_before(Self, oNode)
   METHOD InsertAfter(oNode) INLINE srxml_node_insert_after(Self, oNode)
   METHOD InsertBelow(oNode) INLINE srxml_node_insert_below(Self, oNode)
   METHOD AddBelow(oNode) INLINE srxml_node_add_below(Self, oNode)

   METHOD GetAttribute(cAttrib) INLINE IIf(cAttrib $ ::aAttributes, ::aAttributes[cAttrib], NIL)
   METHOD SetAttribute(cAttrib, xValue) INLINE ::aAttributes[cAttrib] := xValue

   METHOD Depth()
   METHOD Path()

   METHOD ToString(nStyle) INLINE srxml_node_to_string(Self, nStyle)
   METHOD Write(fHandle, nStyle) INLINE srxml_node_write(Self, fHandle, nStyle)

   // Useful for debugging purposes
   METHOD ToArray() INLINE {::nType, ::cName, ::aAttributes, ::cData}

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlNode:New(nType, cName, aAttributes, cData)

   IF nType == NIL
      ::nType := SRXML_TYPE_TAG
   ELSE
      ::nType := nType
   ENDIF

   IF aAttributes == NIL
      ::aAttributes := {=>}
   ELSE
      ::aAttributes := aAttributes
   ENDIF

   ::cName := cName
   ::cData := cData

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlNode:NextInTree()

   LOCAL oNext := NIL
   LOCAL oTemp

   IF ::oChild != NIL
      oNext := ::oChild
   ELSEIF ::oNext != NIL
      oNext := ::oNext
   ELSE
      oTemp := ::oParent
      DO WHILE oTemp != NIL
         IF oTemp:oNext != NIL
            oNext := oTemp:oNext
            EXIT
         ENDIF
         oTemp := oTemp:oParent
      ENDDO
   ENDIF

RETURN oNext

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlNode:Depth()

   IF ::oParent != NIL
      RETURN ::oParent:Depth() + 1
   ENDIF

RETURN 0

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlNode:Path()

   IF ::nType == SRXML_TYPE_DOCUMENT
      RETURN ""
   ENDIF

   IF ::cName != NIL
      IF ::oParent != NIL
         IF ::oParent:Path() != NIL
            RETURN ::oParent:Path() + "/" + ::cName
         ENDIF
      ELSE
         RETURN "/" + ::cName
      ENDIF
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//
// Iterator class
//-------------------------------------------------------------------------------------------------------------------//

CREATE CLASS sr_TXmlIterator

   METHOD New(oNodeTop) CONSTRUCTOR
   METHOD Next()
   METHOD Rewind() INLINE ::oNode := ::oTop
   METHOD Find(cName, cAttribute, cValue, cData)

   METHOD GetNode() INLINE ::oNode
   METHOD SetContext()
   METHOD Clone()

   PROTECTED:
   METHOD MatchCriteria(oNode)

   VAR cName
   VAR cAttribute
   VAR cValue
   VAR cData

   HIDDEN:
   VAR nTopLevel

   VAR oNode
   VAR oTop

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIterator:New(oNodeTop)

   ::oTop := oNodeTop
   ::oNode := oNodeTop
   ::nTopLevel := oNodeTop:Depth()

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIterator:Clone()

   LOCAL oRet

   oRet := sr_TXMLIterator():New(::oNodeTop)
   oRet:cName := ::cName
   oRet:cAttribute := ::cAttribute
   oRet:cValue := ::cValue
   oRet:cData := ::cData

RETURN oRet

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIterator:SetContext()

   ::oTop := ::oNode

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIterator:Find(cName, cAttribute, cValue, cData)

   ::cName := cName
   ::cAttribute := cAttribute
   ::cValue := cValue
   ::cData := cData

   IF ::oNode:nType == SRXML_TYPE_DOCUMENT
      IF ::oNode:oChild == NIL
         RETURN NIL
      ENDIF
      ::oNode := ::oNode:oChild
   ENDIF

   IF ::MatchCriteria(::oNode)
      RETURN ::oNode
   ENDIF

RETURN ::Next()

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIterator:Next()

   LOCAL oFound := ::oNode:NextInTree()

   DO WHILE oFound != NIL
      IF oFound:Depth() <= ::nTopLevel
         RETURN NIL
      ENDIF

      IF ::MatchCriteria(oFound)
         ::oNode := oFound
         RETURN oFound
      ENDIF

      oFound := oFound:NextInTree()
   ENDDO

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIterator:MatchCriteria(oNode)

   HB_SYMBOL_UNUSED(oNode)

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//
// Iterator scan class
//-------------------------------------------------------------------------------------------------------------------//

CREATE CLASS sr_TXmlIteratorScan FROM sr_TXmlIterator

   METHOD New(oNodeTop) CONSTRUCTOR
   PROTECTED:
   METHOD MatchCriteria(oFound)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIteratorScan:New(oNodeTop)

   ::Super:New(oNodeTop)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIteratorScan:MatchCriteria(oFound)

   IF ::cName != NIL .AND. (oFound:cName == NIL .OR. !(::cName == oFound:cName))
      RETURN .F.
   ENDIF

   IF ::cAttribute != NIL .AND. !::cAttribute $ oFound:aAttributes
      RETURN .F.
   ENDIF

   IF ::cValue != NIL .AND. ;
      hb_HScan(oFound:aAttributes, {|xKey, cValue|HB_SYMBOL_UNUSED(xKey), ::cValue == cValue}) == 0
      RETURN .F.
   ENDIF

   IF ::cData != NIL .AND. (oFound:cData == NIL .OR. !(::cData == oFound:cData))
      RETURN .F.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//
// Iterator regex class
//-------------------------------------------------------------------------------------------------------------------//

CREATE CLASS sr_TXmlIteratorRegex FROM sr_TXmlIterator

   METHOD New(oNodeTop) CONSTRUCTOR
   PROTECTED:
   METHOD MatchCriteria(oFound)

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIteratorRegex:New(oNodeTop)

   ::Super:New(oNodeTop)

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXmlIteratorRegex:MatchCriteria(oFound)

   IF ::cName != NIL .AND. (oFound:cName == NIL .OR. !hb_regexLike(::cName, oFound:cName, .T.))
      RETURN .F.
   ENDIF

   IF ::cAttribute != NIL .AND. hb_HScan(oFound:aAttributes, {|cKey|hb_regexLike(::cAttribute, cKey, .T.)}) == 0
      RETURN .F.
   ENDIF

   IF ::cValue != NIL .AND. ;
      hb_HScan(oFound:aAttributes, {|xKey, cValue|HB_SYMBOL_UNUSED(xKey), hb_regexLike(::cValue, cValue, .T.)}) == 0
      RETURN .F.
   ENDIF

   IF ::cData != NIL .AND. (oFound:cData == NIL .OR. !hb_regexHas(::cData, oFound:cData, .F.))
      RETURN .F.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//
// Document Class
//-------------------------------------------------------------------------------------------------------------------//

CREATE CLASS sr_TXMLDocument

   VAR oRoot
   VAR nStatus
   VAR nError
   VAR nLine
   VAR oErrorNode
   VAR nNodeCount

   METHOD New(xElem, nStyle) CONSTRUCTOR
   METHOD Read(xData, nStyle) INLINE srxml_dataread(Self, xData, nStyle)
   METHOD ToString(nStyle) INLINE ::oRoot:ToString(nStyle)
   METHOD Write(fHandle, nStyle)

   METHOD FindFirst(cName, cAttrib, cValue, cData)
   METHOD FindFirstRegex(cName, cAttrib, cValue, cData)
   METHOD FindNext() INLINE ::oIterator:Next()

   METHOD GetContext()

   HIDDEN:

   VAR oIterator
   VAR cHeader

ENDCLASS

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXMLDocument:New(xElem, nStyle)

   ::nStatus := SRXML_STATUS_OK
   ::nError := SRXML_ERROR_NONE
   ::nLine := 1
   ::nNodeCount := 0

   IF xElem == NIL
      ::oRoot := sr_TXMLNode():New(SRXML_TYPE_DOCUMENT)
   ELSE
      SWITCH ValType(xElem)
      CASE "O"
         ::oRoot := xElem
         EXIT
      CASE "N"
      CASE "C"
         ::oRoot := sr_TXMLNode():New(SRXML_TYPE_DOCUMENT)
         IF hb_FileExists(xElem)
            ::Read(hb_MemoRead(xElem), nStyle)
         ELSE
            ::Read(xElem, nStyle)
         ENDIF
         IF !Empty(::oRoot:oChild) .AND. ::oRoot:oChild:cName == "xml"
            ::cHeader := "<=xml " + ::oRoot:oChild:cData + "?>"
         ENDIF
         EXIT
      ENDSWITCH
   ENDIF

RETURN Self

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXMLDocument:Write(fHandle, nStyle)

   LOCAL nResult := SRXML_STATUS_ERROR

   IF HB_IsString(fHandle)  // It's a filename!
      fHandle := FCreate(fHandle)
      IF fHandle != F_ERROR
         IF Empty(::oRoot:oChild) .OR. !(::oRoot:oChild:cName == "xml")
            IF Empty(::cHeader)
               FWrite(fHandle, '<?xml version="1.0"?>' + hb_eol())
            ELSE
               FWrite(fHandle, ::cHeader + hb_eol())
            ENDIF
         ENDIF
         nResult := ::oRoot:Write(fHandle, nStyle)
         FClose(fHandle)
      ENDIF
      RETURN nResult
   ENDIF

RETURN ::oRoot:Write(fHandle, nStyle)

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXMLDocument:FindFirst(cName, cAttrib, cValue, cData)

   ::oIterator := sr_TXMLIteratorScan():New(::oRoot)

RETURN ::oIterator:Find(cName, cAttrib, cValue, cData)

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXMLDocument:FindFirstRegex(cName, cAttrib, cValue, cData)

   ::oIterator := sr_TXMLIteratorRegex():New(::oRoot)

RETURN ::oIterator:Find(cName, cAttrib, cValue, cData)

//-------------------------------------------------------------------------------------------------------------------//

METHOD sr_TXMLDocument:GetContext()

   LOCAL oDoc

   oDoc := sr_TXMLDocument():New()
   oDoc:oRoot := ::oIterator:GetNode()

RETURN oDoc

//-------------------------------------------------------------------------------------------------------------------//
