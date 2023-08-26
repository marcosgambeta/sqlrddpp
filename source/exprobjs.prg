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

// #include "compat.ch"
#include "hbclass.ch"

**************************************************
CLASS Operator

   HIDDEN:
   DATA _cPattern

   EXPORTED:
   DATA cName
   DATA aSymbols

   EXPORTED:
   ACCESS cPattern

   EXPORTED:
   METHOD new(pName, pSymbols)

ENDCLASS

METHOD new(pName, pSymbols)

   ::cName := pName
   ::aSymbols := pSymbols

RETURN SELF

METHOD cPattern

   IF ::_cPattern == NIL
      ::_cPattern := cJoin(::aSymbols, "|")
      ::_cPattern := cPattern(::_cPattern)
   ENDIF

RETURN ::_cPattern

**************************************************
CLASS ComparisonOperator FROM Operator

   EXPORTED:
   METHOD new(pName, pSymbols)

ENDCLASS

METHOD new(pName, pSymbols)

   ::super:new(pName, pSymbols)

RETURN SELF

**************************************************
CLASS SerialOperator FROM Operator

   PROTECTED:
   DATA _nPriority

   EXPORTED:
   ACCESS nPriority INLINE ::_nPriority

   EXPORTED:
   METHOD new(pName, pSymbols)

ENDCLASS

METHOD new(pName, pSymbols)

   ::super:new(pName, pSymbols)

RETURN SELF

**************************************************
CLASS LogicalOperator FROM SerialOperator

   EXPORTED:
   METHOD new(pName, pSymbols)

ENDCLASS

METHOD new(pName, pSymbols)

   ::super:new(pName, pSymbols)
   IF pName == "and"
      ::_nPriority := 1
   ELSEIF pName == "or"
      ::_nPriority := 0
   ENDIF

RETURN SELF

**************************************************
CLASS ArithmeticOperator FROM SerialOperator

   EXPORTED:
   METHOD new(pName, pSymbols)

ENDCLASS

METHOD new(pName, pSymbols)

   ::super:new(pName, pSymbols)
   IF pName == "exponent"
      ::_nPriority := 2
   ELSEIF pName == "multiplied" .OR. pName == "divided"
      ::_nPriority := 1
   ELSEIF pName == "plus" .OR. pName == "minus"
      ::_nPriority := 0
   ENDIF

RETURN SELF

**************************************************
CLASS AlgebraSet

   EXPORTED:
   DATA oOperator READONLY

   EXPORTED:
   DATA cType READONLY

   EXPORTED:
   DATA cIdentityElement READONLY

   EXPORTED:
   DATA cAbsorbentElement READONLY

   EXPORTED:
   METHOD new(pOperator, pType)

ENDCLASS

METHOD new(pOperator, pType)

   ::oOperator := pOperator
   ::cType := pType

   DO CASE
   CASE ascan({"plus", "minus"}, ::oOperator:cName) > 0
      IF ::cType == "C"
         ::cIdentityElement := "''"
      ELSEIF ::cType == "N"
         ::cIdentityElement := "0"
      ELSEIF ::cType == "D"
         ::cIdentityElement := "0"
      ENDIF
   CASE ascan({"multiplied", "divided", "exponent"}, ::oOperator:cName) > 0
      ::cIdentityElement := "1"
      ::cAbsorbentElement := "0"
      ::cType := "N"
   CASE ::oOperator:cName == "and"
      ::cIdentityElement := ".T."
      ::cAbsorbentElement := ".F."
      ::cType := "L"
   CASE ::oOperator:cName == "or"
      ::cIdentityElement := ".F."
      ::cAbsorbentElement := ".T."
      ::cType := "L"
   ENDCASE

RETURN SELF

**************************************************
CLASS ISerialComposition //just a dummy class that is used as interface
ENDCLASS

**************************************************
CLASS ExpressionBase

   HIDDEN:
   DATA _oWorkArea

   EXPORTED:
   DATA lSimplified INIT .F.

   EXPORTED:
   DATA lAssessable

   EXPORTED:
   DATA lIsSimple INIT .F.

   EXPORTED:
   DATA oClipperExpression

   EXPORTED:
   DATA cContext

   EXPORTED:
   METHOD GetType() VIRTUAL

   EXPORTED:
   ACCESS oWorkArea

   EXPORTED:
   METHOD new(pContext, pClipperString)

ENDCLASS

METHOD new(pContext, pClipperString)

   ::oClipperExpression := ClipperExpression():new(pContext, pClipperString)
   ::cContext := upper(pContext)

RETURN SELF

METHOD oWorkArea() CLASS ExpressionBase

   IF ::_oWorkArea == NIL
      ::_oWorkArea := oGetWorkarea(::cContext)
   ENDIF

RETURN ::_oWorkArea

**************************************************
CLASS ConditionBase FROM ExpressionBase

   PROTECTED:
   DATA lDenied_ INIT .F. //bug with _lDenied, so I use lDenied_

   EXPORTED:
   ACCESS lDenied
   ASSIGN lDenied(value) INLINE ::lDenied(value)

   EXPORTED:
   METHOD GetType() INLINE "L"

   EXPORTED:
   METHOD new(pContext, pClipperString) INLINE ::super:new(pContext, pClipperString)

   EXPORTED:
   METHOD new2(pContext, pClipperString, pDenied)

ENDCLASS

METHOD new2(pContext, pClipperString, pDenied)

   ::lDenied_ := pDenied

RETURN ::super:new(pContext, pClipperString)

METHOD lDenied(value) CLASS ConditionBase

   IF value != NIL .AND. value != ::lDenied_
      ::lDenied_ := value
      ::oClipperExpression := ClipperExpression():new(::cContext, "!(" + ::oClipperExpression:cValue + ")")
   ENDIF

RETURN ::lDenied_

**************************************************
CLASS BooleanExpression FROM ConditionBase

   EXPORTED:
   DATA oExpression

   EXPORTED:
   ACCESS Value INLINE iif(::lDenied_, iif(upper(::oExpression:Value) == ".T.", ".F.", ".T."), ::oExpression:Value)

   EXPORTED:
   ACCESS lDenied
   ASSIGN lDenied(value) INLINE ::lDenied(value)

   EXPORTED:
   METHOD new(pContext, pClipperString, pExpr)

   EXPORTED:
   METHOD new2(pContext, pClipperString, pDenied, pExpr)

ENDCLASS

METHOD new2(pContext, pClipperString, pDenied, pExpr)

   ::lDenied_ := pDenied

RETURN ::new(pContext, pClipperString, pExpr)

METHOD new(pContext, pClipperString, pExpr)

   ::super:new(pContext, pClipperString)
   ::oExpression := pExpr
   ::lIsSimple := pExpr:lIsSimple
   ::lSimplified := pExpr:lSimplified

RETURN SELF

// not very usefull, but cleaner
METHOD lDenied(value) CLASS BooleanExpression

   IF value != NIL .AND. value != ::lDenied_ .AND. ::lIsSimple .AND. ::oExpression:ValueType = "value"
      ::lDenied_ := value
      ::oClipperExpression := ClipperExpression():new(::cContext, ::Value)
      RETURN ::lDenied_
   ENDIF

RETURN ::super:lDenied(value)

**************************************************
CLASS ComposedConditionBase FROM ConditionBase

   EXPORTED:
   DATA oOperand1
   DATA oOperand2
   DATA oOperator

   EXPORTED:
   METHOD new(pContext, pClipperString, pOperand1, pOperator, pOperand2)

   EXPORTED:
   METHOD new2(pContext, pClipperString, pDenied, pOperand1, pOperator, pOperand2)

ENDCLASS

METHOD new2(pContext, pClipperString, pDenied, pOperand1, pOperator, pOperand2) CLASS ComposedConditionBase

   ::lDenied_ = pDenied

RETURN ::new(pContext, pClipperString, /*pExpr,*/ pOperand1, pOperator, pOperand2)

METHOD new(pContext, pClipperString, pOperand1, pOperator, pOperand2) CLASS ComposedConditionBase

   ::super:new(pContext, pClipperString)
   ::oOperand1 := pOperand1
   ::oOperand2 := pOperand2
   ::oOperator := pOperator

RETURN SELF

**************************************************
CLASS Comparison FROM ComposedConditionBase
ENDCLASS

**************************************************
CLASS ComposedCondition FROM ComposedConditionBase
ENDCLASS

**************************************************
CLASS Expression FROM ExpressionBase

   EXPORTED:
   METHOD GetType()

   EXPORTED:
   METHOD new(pContext, pClipperString) inline ::super:new(pContext, pClipperString)

ENDCLASS

METHOD GetType() CLASS Expression
RETURN ::oClipperExpression:cType

**************************************************
CLASS ValueExpression FROM Expression

   EXPORTED:
   DATA Value

   EXPORTED:
   DATA ValueType

   HIDDEN:
   DATA cType

   EXPORTED:
   METHOD GetType()

   EXPORTED:
   ACCESS oExpression INLINE self //usefull to implement the same interface than ValueExpression

   EXPORTED:
   METHOD new(pContext, pValue)

ENDCLASS

METHOD new(pContext, pValue)

   ::super:new(pContext, alltrim(pValue))

   IF aScan(::oWorkArea:aNames, {|x|x == upper(pValue)}) > 0
      ::ValueType := "field"
   ELSEIF hb_regexLike("\w+", pValue) .AND. hb_regexLike("\d+", !pValue) .AND. !lower(pValue) == "nil"
      ::ValueType := "variable"
   ELSE
      ::ValueType := "value"
      ::lSimplified := .T.
   ENDIF

   ::Value := ::oClipperExpression:cValue
   ::lIsSimple := .T.

RETURN SELF

// method redefined because it's faster than evaluate the expression.
METHOD GetType() CLASS ValueExpression

   IF ::cType == NIL
      IF ::ValueType == "field"
         ::cType := ::oWorkArea:GetFieldByName(::Value):cType
      ELSEIF ::ValueType == "variable"
         ::cType := ::super:GetType()
      ELSEIF ::ValueType == "value"
         IF hb_regexLike("\d+", ::Value)
            ::cType := "N"
         ELSEIF hb_regexLike("'.*'", ::Value)
            ::cType := "C"
         ELSEIF ascan({".T.", ".F."}, upper(::Value)) > 0
            ::cType := "L"
         ENDIF
      ELSE
         ::cType = "U"
      ENDIF
   ENDIF

RETURN ::cType

**************************************************
CLASS FunctionExpression FROM Expression

   EXPORTED:
   DATA cFunctionName
   DATA aParameters

   EXPORTED:
   METHOD new(pContext, pClipperString, pFunctionName, aParameters)

ENDCLASS

METHOD new(pContext, pClipperString, pFunctionName, aParameters)

   ::super:new(pContext, pClipperString)
   ::cFunctionName := lower(pFunctionName)
   ::aParameters := aParameters

RETURN SELF

**************************************************
CLASS Parameter

   EXPORTED:
   DATA lIsByRef
   DATA oExpression

   EXPORTED:
   METHOD new(pExpression, pIsByRef)

ENDCLASS

METHOD new(pExpression, pIsByRef)

   ::oExpression := pExpression
   ::lIsByRef := pIsByRef

RETURN SELF

**************************************************
CLASS ComposedExpression FROM Expression

   EXPORTED:
   DATA oOperand1
   DATA oOperand2
   DATA oOperator

   HIDDEN:
   DATA cType

   EXPORTED:
   METHOD GetType()

   EXPORTED:
   METHOD new(pContext, pClipperString, pOperand1, pOperator, pOperand2)

ENDCLASS

METHOD new(pContext, pClipperString, pOperand1, pOperator, pOperand2)

   ::super:new(pContext, pClipperString)
   ::oOperand1 := pOperand1
   ::oOperand2 := pOperand2
   ::oOperator := pOperator

RETURN SELF

METHOD GetType()

   LOCAL cOperand1Type

   IF ::cType == NIL
      cOperand1Type := ::oOperand1:GetType()
      IF ascan({"plus", "minus"}, ::oOperator:cName) > 0 .AND. cOperand1Type == "N" //date + numeric
         ::cType := ::oOperand2:GetType()
      ELSE
         ::cType := cOperand1Type
      ENDIF
   ENDIF

RETURN ::cType

**************************************************
PROCEDURE Visualize(oExpression) // for debuging

   LOCAL i

   alert(oExpression:className() + " - workarea: " + oExpression:cContext)
   IF oExpression:isKindOf("ConditionBase")
      IF oExpression:lDenied
         alert("not")
      ENDIF
   ENDIF
   IF oExpression:isKindOf("BooleanExpression")
      Visualize(oExpression:oExpression)
   ELSEIF oExpression:isKindOf("Comparison") .OR. oExpression:isKindOf("ComposedCondition") .OR. oExpression:isKindOf("ComposedExpression")
      Visualize(oExpression:oOperand1)
      alert(oExpression:oOperator:cName)
      Visualize(oExpression:oOperand2)
   ELSEIF oExpression:isKindOf("ValueExpression")
      alert(oExpression:Value)
   ELSEIF oExpression:isKindOf("FunctionExpression")
      alert(oExpression:cFunctionName)
      alert(cstr(len(oExpression:aParameters)) + " parameter(s) :")
      FOR i := 1 TO len(oExpression:aParameters)
         Visualize(oExpression:aParameters[i]:oExpression)
      NEXT i
   ENDIF

RETURN

**************************************************
FUNCTION CollectAliases(oExpression, aAliases)

   LOCAL i

   aAddDistinct(aAliases, oExpression:cContext, {|x|lower(x)})
   IF oExpression:isKindOf("BooleanExpression")
      CollectAliases(oExpression:oExpression, aAliases)
   ELSEIF oExpression:isKindOf("Comparison") .OR. oExpression:isKindOf("ComposedCondition") .OR. oExpression:isKindOf("ComposedExpression")
      CollectAliases(oExpression:oOperand1, aAliases)
      CollectAliases(oExpression:oOperand2, aAliases)
   ELSEIF oExpression:isKindOf("FunctionExpression")
      FOR i := 1 TO len(oExpression:aParameters)
         CollectAliases(oExpression:aParameters[i]:oExpression, aAliases)
      NEXT i
   ENDIF

RETURN aAliases

**************************************************
FUNCTION ConvertToCondition(oExpression)

   IF !oExpression:isKindOf("ComposedExpression") .AND. oExpression:GetType() == "L"
      RETURN BooleanExpression():new(oExpression:cContext, oExpression:oClipperExpression:cValue, oExpression)
   ENDIF

RETURN NIL
