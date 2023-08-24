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

#include "compat.ch"
#include "sqlrdd.ch"
#include "hbclass.ch"
#ifndef __XHARBOUR__
   #include "xhbcls.ch"
#endif

**************************************************
FUNCTION NewDbSetRelation(cAlias, bRelation, cRelation, lScoped)

   DbSetRelation(cAlias, bRelation, cRelation, lScoped)
   RelationManager():new():AddRelation(EnchancedRelationFactory():new(), alias(), cAlias, cRelation)

RETURN NIL

**************************************************
FUNCTION NewdbClearRelation()

   dbClearRelation()
   RelationManager():new():Clear(alias())

RETURN NIL

**************************************************
FUNCTION Newdbclearfilter()

   dbclearfilter()
   oGetWorkarea(alias()):cFilterExpression := ""

RETURN NIL

**************************************************
FUNCTION oGetWorkarea(cAlias)

   LOCAL result
   LOCAL oerr

   TRY
      result := &cAlias->(dbInfo(DBI_INTERNAL_OBJECT))
   CATCH oErr
      oErr:Description += " (cAlias: " + cstr(cAlias) + ")"
      throw(oErr)
   END

RETURN result

**************************************************
PROCEDURE SelectFirstAreaNotInUse()

   LOCAL nArea

   FOR nArea := 1 TO 65534
      IF Empty(alias(nArea))
         SELECT &nArea
         EXIT
      ENDIF
   NEXT

RETURN

**************************************************
CLASS RelationBase

   EXPORTED:
   DATA oWorkarea1

   EXPORTED:
   DATA oWorkarea2

ENDCLASS

**************************************************
CLASS IndirectRelation FROM RelationBase

   EXPORTED:
   DATA aDirectRelations INIT {}

   EXPORTED:
   ACCESS oWorkarea1 INLINE ::aDirectRelations[1]:oWorkarea1

   EXPORTED:
   ACCESS oWorkarea2 INLINE atail(::aDirectRelations):oWorkarea2

ENDCLASS

**************************************************
CLASS DirectRelation FROM RelationBase

   EXPORTED:
   DATA oClipperExpression READONLY

   EXPORTED:
   METHOD new(pWorkarea1, pWorkarea2, pExpression)

ENDCLASS

METHOD new(pWorkarea1, pWorkarea2, pExpression)

   IF HB_ISCHAR(pWorkarea1)
      ::oWorkarea1 := oGetWorkarea(pWorkarea1)
   ELSE
      ::oWorkarea1 := pWorkarea1
   ENDIF
   IF HB_ISCHAR(pWorkarea2)
      ::oWorkarea2 := oGetWorkarea(pWorkarea2)
   ELSE
      ::oWorkarea2 := pWorkarea2
   ENDIF

   ::oClipperExpression := ClipperExpression():new(::oWorkarea1:cAlias, pExpression, .T.)

RETURN SELF

**************************************************
CLASS RelationFactory

   EXPORTED:
   METHOD NewDirectRelation(pWorkarea1, pWorkarea2, pExpression) INLINE DirectRelation():new(pWorkarea1, pWorkarea2, pExpression)

   EXPORTED:
   METHOD new()

ENDCLASS

METHOD new()

   STATIC instance

   IF instance == NIL
      instance := SELF
   ENDIF

RETURN instance

**************************************************
CLASS RelationManager

   HIDDEN:
   DATA oInternDictionary INIT Dictionary():new()

   HIDDEN:
   DATA aDirectRelations INIT {}

   EXPORTED:
   METHOD AddRelation(oFactory, pAlias1, pAlias2, pExpression)

   EXPORTED:
   METHOD GetRelations(cAlias1, cAlias2)

   EXPORTED:
   METHOD Clear(cAlias)

   HIDDEN:
   METHOD BuildRelations(oIndirectRelation, cAlias1, cAlias2)

   EXPORTED:
   METHOD new()

ENDCLASS

METHOD new()

   STATIC instance

   IF instance == NIL
      instance := SELF
   ENDIF

RETURN instance

METHOD Clear(cAlias) CLASS RelationManager

   ::oInternDictionary:Clear()
   RemoveAll(::aDirectRelations, {|y|lower(y:oWorkarea1:cAlias) == lower(cAlias)})

RETURN NIL

METHOD AddRelation(oFactory, pAlias1, pAlias2, pExpression) CLASS RelationManager

   LOCAL cAlias1 := upper(pAlias1)
   LOCAL cAlias2 := upper(pAlias2)
   LOCAL n := ascan(::aDirectRelations, {|x|upper(x:oWorkarea1:cAlias) == cAlias1 .AND. upper(x:oWorkarea2:cAlias) == cAlias2})
   LOCAL oNewRelation := oFactory:NewDirectRelation(cAlias1, cAlias2, pExpression)

   IF n > 0
      ::aDirectRelations[n] := oNewRelation
   ELSE
      aadd(::aDirectRelations, oNewRelation)
   ENDIF
   ::oInternDictionary:Clear()

RETURN NIL

METHOD GetRelations(cAlias1, cAlias2) CLASS RelationManager

   LOCAL result := {}
   LOCAL r
   LOCAL i
   LOCAL oDirectRelation
   LOCAL dico2

   cAlias1 := upper(cAlias1)
   cAlias2 := upper(cAlias2)

   IF ::oInternDictionary:lContainsKey(cAlias1) .AND. (dico2 := ::oInternDictionary:xValue(cAlias1)):lContainsKey(cAlias2)
      result := ::oInternDictionary:xValue(cAlias1):xValue(cAlias2)
   ELSE
      FOR i := 1 TO len(::aDirectRelations)
         oDirectRelation := ::aDirectRelations[i]
         IF cAlias1 == upper(oDirectRelation:oWorkarea1:cAlias)
            IF cAlias2 == upper(oDirectRelation:oWorkarea2:cAlias)
               aadd(result, oDirectRelation)
            ELSE
               r := IndirectRelation():new()
               aadd(r:aDirectRelations, oDirectRelation)
               aAddRange(result, ::BuildRelations(r, oDirectRelation:oWorkarea2:cAlias, cAlias2))
            ENDIF
         ENDIF
      NEXT i
      IF dico2 == NIL
         dico2 := Dictionary():new()
         dico2:aadd(cAlias2, result)
         ::oInternDictionary:aadd(cAlias1, dico2 , 3)
      ELSE
         dico2:aadd(cAlias2, result)
      ENDIF
   ENDIF

RETURN result

METHOD BuildRelations(oIndirectRelation, cAlias1, cAlias2) CLASS RelationManager

   LOCAL result := {}
   LOCAL r
   LOCAL i
   LOCAL j
   LOCAL oDirectRelation

   cAlias1 := upper(cAlias1)
   cAlias2 := upper(cAlias2)

   FOR i := 1 TO len(::aDirectRelations)
      oDirectRelation := ::aDirectRelations[i]
      IF cAlias1 == upper(oDirectRelation:oWorkarea1:cAlias)
         oDirectRelation := ::aDirectRelations[i]
         r := IndirectRelation():new()
         FOR j := 1 TO len(oIndirectRelation:aDirectRelations)
             aadd(r:aDirectRelations, oIndirectRelation:aDirectRelations[j])
         NEXT j

         aadd(r:aDirectRelations, oDirectRelation)

         IF oDirectRelation:oWorkarea2:cAlias == cAlias2
            aadd(result, r)
         ELSE
            aAddRange(result, ::BuildRelations(r, oDirectRelation:oWorkarea2:cAlias, cAlias2))
         ENDIF
      ENDIF
   NEXT i

RETURN result

**************************************************
CLASS DbIndex

   HIDDEN:
   DATA _aInfos

   HIDDEN:
   DATA _cName

   EXPORTED:
   ACCESS cName INLINE ::_cName

   HIDDEN:
   DATA _lIsSynthetic

   EXPORTED:
   ACCESS lIsSynthetic

   HIDDEN:
   DATA _aDbFields

   EXPORTED:
   ACCESS aDbFields

   EXPORTED:
   DATA oClipperExpression READONLY

   HIDDEN:
   DATA _nLength

   EXPORTED:
   ACCESS nLength

   EXPORTED:
   DATA oWorkarea

   EXPORTED:
   METHOD new(pWorkarea, pName)

ENDCLASS

METHOD new(pWorkarea, pName)

   IF HB_ISCHAR(pWorkarea)
      ::oWorkarea := oGetWorkarea(pWorkarea)
   ELSE
      ::oWorkarea := pWorkarea
   ENDIF
   ::_cName := upper(pName)
   ::_aInfos := aWhere(pWorkarea:aIndex, {|x|x[10] == ::_cName})[1]
   ::oClipperExpression := ClipperExpression():new(::oWorkarea:cAlias, ::_aInfos[4], ::lIsSynthetic)

RETURN SELF

METHOD lIsSynthetic() CLASS DbIndex

   IF ::_lIsSynthetic == NIL
      ::_lIsSynthetic := (::_aInfos[9] == "")
   ENDIF

RETURN ::_lIsSynthetic

METHOD aDbFields() CLASS DbIndex

   LOCAL i

   IF ::_aDbFields == NIL
      ::_aDbFields := {}
      IF ::lIsSynthetic()
         // ::oClipperExpression:nLength will evaluate the index expression which is a bit slow. It would be nice to have access to the legnth of a synthetic index.
         aadd(::_aDbFields, DbField():new(HB_RegExAtX(".*\[(.*?)\]", ::_aInfos[1], .F.)[2,1], "C", ::oClipperExpression:nLength)) //the way to get the name of the field that contains the synthetic index isn't very clean... We also suppose that the synthtic index has a fix length
      ELSE
         FOR i := 1 TO len(::_aInfos[3]) - 1 // not SR_RECNO
            aadd(::_aDbFields, ::oWorkarea:GetFieldByName(::_aInfos[3][i][1]))
         NEXT i
      ENDIF
   ENDIF

RETURN ::_aDbFields

METHOD nLength() CLASS DbIndex

   LOCAL i

   IF ::_nLength == NIL
      ::_nLength := 0
      FOR i := 1 TO len(::aDbFields)
         ::_nLength += ::aDbFields[i]:nLength
      NEXT i
   ENDIF

RETURN ::_nLength

**************************************************
CLASS DbField

   EXPORTED:
   DATA cName READONLY

   EXPORTED:
   DATA cType READONLY

   EXPORTED:
   DATA nLength READONLY

   EXPORTED:
   METHOD new(pName, pType, pLength)

ENDCLASS

METHOD new(pName, pType, pLength)

   ::cName := pName
   ::cType := pType
   ::nLength := pLength

RETURN SELF

**************************************************
CLASS ClipperExpression

   EXPORTED:
   DATA lIgnoreRelations

   EXPORTED:
   DATA cContext READONLY

   EXPORTED:
   DATA cValue READONLY

   HIDDEN:
   DATA _cEvaluation

   HIDDEN:
   METHOD cEvaluation

   HIDDEN:
   DATA _cType

   EXPORTED:
   ACCESS cType

   HIDDEN:
   DATA _nLength

   EXPORTED:
   ACCESS nLength

   EXPORTED:
   METHOD Evaluate()

   EXPORTED:
   METHOD new(pContext, pValue)

ENDCLASS

METHOD new(pContext, pValue, pIgnoreRelations) CLASS ClipperExpression

   ::cContext := pContext
   ::cValue := pValue
   ::lIgnoreRelations := pcount() == 3 .AND. pIgnoreRelations

RETURN SELF

METHOD cEvaluation() CLASS ClipperExpression

   IF ::_cEvaluation == NIL
      ::_cEvaluation := cstr(::Evaluate(::lIgnoreRelations))
   ENDIF

RETURN NIL

METHOD Evaluate(lIgnoreRelations) CLASS ClipperExpression

   LOCAL nSeconds
   LOCAL save_slct
   LOCAL Result
   LOCAL oErr

   // can be very slow with relations...
   nseconds := seconds()

   TRY
      if pcount() == 1 .AND. lIgnoreRelations
         save_slct := select()
         SelectFirstAreaNotInUse()
         USE &(oGetWorkarea(::cContext):cFileName) VIA "SQLRDD" ALIAS "AliasWithoutRelation"
         result := &(::cValue)
         CLOSE ("AliasWithoutRelation")
         select(save_slct)
      ELSE
         result := &(::cContext)->(&(::cValue))
      ENDIF
   CATCH oErr
      oErr:description += ";The value unseccessfully evaluated was : " + ::cValue   + ";"
      throw(oErr)
   END

RETURN result

METHOD cType() CLASS ClipperExpression

   IF ::_cType == NIL
      ::_cType := valtype(::cEvaluation())
   ENDIF

RETURN ::_cType

METHOD nLength() CLASS ClipperExpression

   IF ::_nLength == NIL
      ::_nLength := len(::cEvaluation())
   ENDIF

RETURN ::_nLength

**************************************************

FUNCTION ExtendWorkarea()

   EXTEND CLASS SR_WORKAREA WITH DATA aIndexes
   EXTEND CLASS SR_WORKAREA WITH METHOD GetIndexes
   EXTEND CLASS SR_WORKAREA WITH METHOD GetControllingIndex

   EXTEND CLASS SR_WORKAREA WITH DATA aDbFields
   EXTEND CLASS SR_WORKAREA WITH METHOD GetFields
   EXTEND CLASS SR_WORKAREA WITH METHOD GetFieldByName

   EXTEND CLASS SR_WORKAREA WITH DATA cFilterExpression

   OVERRIDE METHOD ParseForClause IN CLASS SR_WORKAREA WITH NewParseForClause

RETURN NIL

FUNCTION GetIndexes(lOrdered)

   LOCAL self := HB_QSelf()
   LOCAL i

   lOrdered := lOrdered == NIL .OR. lOrdered
   IF ::aIndexes == NIL
      ::aIndexes := {}
      FOR i := 1 TO len(::aIndex)
         IF hb_regexLike("^\w+$", ::aIndex[i,10])
            aadd(::aIndexes, DbIndex():new(self, ::aIndex[i, 10]))
         ENDIF
      NEXT i
   ENDIF
   IF lOrdered // order can change with set order to => we could also redefine DbSetOrder() to sort aIndexes each time the order change.
      asort(::aIndexes, {|x, y|&(::cAlias)->(OrdNumber(x:cName)) < &(::cAlias)->(OrdNumber(y:cName))})
   ENDIF

RETURN ::aIndexes

FUNCTION GetControllingIndex()

   LOCAL self := HB_QSelf()
   LOCAL aIndexes := ::GetIndexes(.F.)
   LOCAL nIndex := &(::cAlias)->(OrdNumber())

   IF nIndex == 0
      RETURN NIL
   ENDIF

RETURN aIndexes[nIndex]

FUNCTION GetFields()

   LOCAL self := HB_QSelf()
   LOCAL i
   LOCAL save_slct
   LOCAL nCount
   LOCAL _aTypes
   LOCAL _aNames
   LOCAL _aLengths

   IF ::aDbFields == NIL
      save_slct := select()
      select(::cAlias)
      nCount := fcount()
      _aTypes := Array(nCount)
      _aNames := Array(nCount)
      _aLengths := Array(nCount)
      ::aDbFields := Array(nCount)
      AFields(_aNames, _aTypes, _aLengths)
      FOR i := 1 TO nCount
         ::aDbFields[i] := DbField():new(_aNames[i], _aTypes[i], _aLengths[i])
      NEXT i
      select(save_slct)
   ENDIF

RETURN ::aDbFields

FUNCTION GetFieldByName(cName)

   LOCAL self := HB_QSelf()

RETURN xFirst(::GetFields(), {|x|lower(x:cName) == lower(cName)})

// should be implemented : GetTranslations() and lFixVariables
FUNCTION NewParseForClause(cFor, lFixVariables)

   LOCAL self := HB_QSelf()
   LOCAL oParser
   LOCAL otranslator
   LOCAL oCondition

   ::cFilterExpression := cFor

   oParser := ConditionParser():new(::cAlias)
   otranslator := MSSQLExpressionTranslator():new(::cAlias, lFixVariables, .T.)

   oCondition := oParser:Parse(cFor)

RETURN otranslator:Translate(oCondition)
