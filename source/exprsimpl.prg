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

#include <hbclass.ch>

///////////////////////////////////////////////////////////////////////////////

CLASS ExpressionSimplifierBase

   EXPORTED:
   DATA cContext

   EXPORTED:
   DATA lFixVariables INIT .F.

   EXPORTED:
   DATA lIgnoreRelations INIT .F.

   EXPORTED:
   METHOD Simplify(oExpression) VIRTUAL

   EXPORTED:
   METHOD Assessable(oExpression) VIRTUAL

   PROTECTED:
   METHOD NewSimpleExpression(cContext, cClipperString) VIRTUAL

   PROTECTED:
   METHOD NewComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2) VIRTUAL

   PROTECTED:
   METHOD SimplifyComposition(oExpression)

   PROTECTED:
   METHOD CompositionAssessable(oExpression)

   EXPORTED:
   METHOD new(pFixVariables, pIgnoreRelations, pContext)

ENDCLASS

METHOD new(pFixVariables, pIgnoreRelations, pContext) CLASS ExpressionSimplifierBase

   IF pFixVariables != NIL
      ::lFixVariables := pFixVariables
   ENDIF
   IF pIgnoreRelations != NIL
      ::lIgnoreRelations := pIgnoreRelations
   ENDIF
   ::cContext := Upper(pContext)

RETURN SELF

METHOD SimplifyComposition(oExpression) CLASS ExpressionSimplifierBase

   LOCAL oAlgebraSet
   LOCAL newClipperString
   LOCAL newOperands := {oExpression:oOperand1, oExpression:oOperand2}
   LOCAL oSimpleExpression
   LOCAL i

   FOR i := 1 TO 2
      newOperands[i] := ::Simplify(newOperands[i])
      IF newOperands[i]:lIsSimple
         oSimpleExpression := newOperands[i]:oExpression
         oAlgebraSet := AlgebraSet():new(oExpression:oOperator, oExpression:GetType())
         IF oAlgebraSet:cIdentityElement == Upper(newOperands[i]:Value)
            RETURN IIf(i == 1, ::Simplify(newOperands[2]), newOperands[1])
         ELSEIF oAlgebraSet:cAbsorbentElement != NIL .AND. oAlgebraSet:cAbsorbentElement == Upper(newOperands[i]:Value)
            RETURN ::NewSimpleExpression(oExpression:cContext, oAlgebraSet:cAbsorbentElement)
         ENDIF
      ENDIF
   NEXT i

   IF !newOperands[1] == oExpression:oOperand1 .OR. !newOperands[2] == oExpression:oOperand2
      newClipperString := newOperands[1]:oClipperExpression:cValue + " " + oExpression:oOperator:aSymbols[1] + " " + newOperands[2]:oClipperExpression:cValue
      RETURN ::NewComposedExpression(oExpression:cContext, newClipperString, newOperands[1], oExpression:oOperator, newOperands[2])
   ENDIF
   
   HB_SYMBOL_UNUSED(oSimpleExpression)

RETURN oExpression

METHOD CompositionAssessable(oExpression) CLASS ExpressionSimplifierBase
RETURN       (oExpression:oOperand1:lSimplified .OR. ::Assessable(oExpression:oOperand1)) ;
       .AND. (oExpression:oOperand2:lSimplified .OR. ::Assessable(oExpression:oOperand2))


///////////////////////////////////////////////////////////////////////////////

CLASS ExpressionSimplifier FROM ExpressionSimplifierBase

   HIDDEN:
   DATA _oConditionSimplifier

   HIDDEN:
   ACCESS oConditionSimplifier INLINE IIf(::_oConditionSimplifier == NIL, (::_oConditionSimplifier := ConditionSimplifier():new(::lFixVariables, ::lIgnoreRelations, ::cContext)), ::_oConditionSimplifier)

   EXPORTED:
   METHOD Simplify(oExpression)

   EXPORTED:
   METHOD Assessable(oExpression)

   HIDDEN:
   METHOD ValueAssessable(oExpression)

   HIDDEN:
   METHOD FunctionAssessable(oExpression)

   PROTECTED:
   METHOD NewSimpleExpression(cContext, cClipperString) INLINE ValueExpression():new(cContext, cClipperString)

   PROTECTED:
   METHOD NewComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2) INLINE ComposedExpression():new(cAlias, cExpression, oOperand1, oConnector, oOperand2)

   EXPORTED:
   METHOD new(pFixVariables, pIgnoreRelations, pContext, pConditionSimplifier)

ENDCLASS

METHOD new(pFixVariables, pIgnoreRelations, pContext, pConditionSimplifier) CLASS ExpressionSimplifier

   ::_oConditionSimplifier := pConditionSimplifier

RETURN ::super:new(pFixVariables, pIgnoreRelations, pContext)

METHOD Simplify(oExpression) CLASS ExpressionSimplifier

   LOCAL newValue
   LOCAL i
   LOCAL newParams
   LOCAL lAtLeastOneParamSimplified
   LOCAL oParameter
   LOCAL oSimplifiedExpression
   LOCAL result
   LOCAL simplifier
   LOCAL newClipperString
   LOCAL lEvaluated := .F.

   IF oExpression:lSimplified
      RETURN oExpression
   ELSEIF ::Assessable(oExpression)
      BEGIN SEQUENCE WITH __BreakBlock()
         newValue := oExpression:oClipperExpression:Evaluate()
         lEvaluated := .T.
      RECOVER
      END SEQUENCE
      IF lEvaluated
         SWITCH ValType(newValue)
         CASE "C"
            newValue := "'" + newValue + "'"
            result := ValueExpression():new(oExpression:cContext, newValue)
            EXIT
         CASE "N"
         CASE "L"
         CASE "U"
            newValue := cstr(newValue)
            result := ValueExpression():new(oExpression:cContext, newValue)
            EXIT
         CASE "D"
            newValue := "'" + DToC(newValue) + "'"
            result := FunctionExpression():new(oExpression:cContext, "ctod(" + newValue + ")", "ctod", {Parameter():new(ValueExpression():new(oExpression:cContext, newValue), .F.)})
         ENDSWITCH
      ENDIF
   ENDIF
   IF !lEvaluated
      IF oExpression:isKindOf("ComposedExpression")
         result := ::SimplifyComposition(oExpression)
      ELSEIF oExpression:isKindOf("FunctionExpression")
         newParams := {}
         lAtLeastOneParamSimplified := .F.
         FOR i := 1 TO Len(oExpression:aParameters)
            oParameter := oExpression:aParameters[i]
            IF oParameter:oExpression:isKindOf("ConditionBase")
               simplifier := ::oConditionSimplifier
            ELSE
               simplifier := SELF
            ENDIF
            IF oParameter:lIsByRef .OR. (oSimplifiedExpression := simplifier:Simplify(oParameter:oExpression)) == oParameter:oExpression
               AAdd(newParams, oParameter)
            ELSE
               AAdd(newParams, Parameter():new(oSimplifiedExpression, .F.))
               lAtLeastOneParamSimplified := .T.
            ENDIF
         NEXT i
         IF lAtLeastOneParamSimplified
            newClipperString := oExpression:cFunctionName + "("
            FOR i := 1 TO Len(newParams)
               newClipperString += newParams[i]:oExpression:oClipperExpression:cValue + IIf(i == Len(newParams), ")", ",")
            NEXT i
            result := FunctionExpression():new(oExpression:cContext, newClipperString, oExpression:cFunctionName, newParams)
         ENDIF
      ENDIF
   ENDIF
   IF result == NIL
      result := oExpression
   ENDIF
   result:lSimplified := .T.

RETURN result

METHOD Assessable(oExpression) CLASS ExpressionSimplifier

   LOCAL result

   IF oExpression:lAssessable != NIL
      RETURN oExpression:lAssessable
   ENDIF

   DO CASE
   CASE oExpression:isKindOf("ValueExpression")
      result := ::ValueAssessable(oExpression)
   CASE oExpression:isKindOf("FunctionExpression")
      result := ::FunctionAssessable(oExpression)
   CASE oExpression:isKindOf("ComposedExpression")
      result := ::CompositionAssessable(oExpression)
   ENDCASE
   oExpression:lAssessable := result

RETURN result

METHOD ValueAssessable(oExpression) CLASS ExpressionSimplifier

   LOCAL lRet

   SWITCH oExpression:ValueType
   CASE "value"
      lRet := .T.
      EXIT
   CASE "variable"
      lRet := ::lFixVariables
      EXIT
   CASE "field"
      lRet := (::lIgnoreRelations .OR. !::cContext == oExpression:cContext .AND. Len(RelationManager():new():GetRelations(::cContext, oExpression:cContext)) == 0) .AND. ::lFixVariables
   ENDSWITCH

RETURN lRet

METHOD FunctionAssessable(oExpression) CLASS ExpressionSimplifier

   LOCAL item
   LOCAL simplifier

   FOR EACH item IN oExpression:aParameters
      IF item:oExpression:isKindOf("ConditionBase")
         simplifier := ::oConditionSimplifier
      ELSE
         simplifier := SELF
      ENDIF
      IF !simplifier:Assessable(item:oExpression)
         RETURN .F.
      ENDIF
   NEXT

RETURN __DynsIsFun(__DynsGetIndex(oExpression:cFunctionName)) ;
   .AND. !oExpression:cFunctionName == "deleted" ;
   .AND. !oExpression:cFunctionName == "recno"

///////////////////////////////////////////////////////////////////////////////

CLASS ConditionSimplifier FROM ExpressionSimplifierBase

   HIDDEN:
   DATA _oExpressionSimplifier

   EXPORTED:
   METHOD Simplify(oCondition)

   EXPORTED:
   METHOD Assessable(oCondition)

   HIDDEN:
   METHOD BooleanExprAssessable(oCondition)

   HIDDEN:
   METHOD ComparisonAssessable(oCondition)

   PROTECTED:
   METHOD NewSimpleExpression(cContext, cClipperString) INLINE BooleanExpression():new(cContext, cClipperString, ValueExpression():new(cContext, cClipperString))

   PROTECTED:
   METHOD NewComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2) INLINE ComposedCondition():new(cAlias, cExpression, oOperand1, oConnector, oOperand2)

   EXPORTED:
   METHOD new(pFixVariables, pIgnoreRelations, pContext)

ENDCLASS

METHOD new(pFixVariables, pIgnoreRelations, pContext) CLASS ConditionSimplifier

   ::_oExpressionSimplifier := ExpressionSimplifier():new(pFixVariables, pIgnoreRelations, pContext, SELF)

RETURN ::super:new(pFixVariables, pIgnoreRelations, pContext)

METHOD Simplify(oCondition) CLASS ConditionSimplifier

   LOCAL newValue
   LOCAL newOperand1
   LOCAL newOperand2
   LOCAL newExpression
   LOCAL result
   LOCAL newClipperString

   IF oCondition:lSimplified
      RETURN oCondition
   ELSEIF oCondition:isKindOf("BooleanExpression")
      newExpression := ::_oExpressionSimplifier:Simplify(oCondition:oExpression)
      IF !newExpression == oCondition:oExpression
         result := ConvertToCondition(newExpression)
      ENDIF
   ELSEIF oCondition:isKindOf("Comparison")
      newOperand1 := ::_oExpressionSimplifier:Simplify(oCondition:oOperand1)
      newOperand2 := ::_oExpressionSimplifier:Simplify(oCondition:oOperand2)
      newClipperString := newOperand1:oClipperExpression:cValue + " " + oCondition:oOperator:aSymbols[1] + " " + newOperand2:oClipperExpression:cValue
      IF newOperand1:isKindOf("ValueExpression") .AND. newOperand1:ValueType == "value" .AND. newOperand2:isKindOf("ValueExpression") .AND. newOperand2:ValueType == "value"
         newValue := cstr(&newClipperString)
         result := BooleanExpression():new(oCondition:cContext, newValue, ValueExpression():new(oCondition:cContext, newValue))
      ELSEIF !newOperand1 == oCondition:oOperand1 .OR. !newOperand2 == oCondition:oOperand2
         result := Comparison():new(oCondition:cContext, newClipperString, newOperand1, oCondition:oOperator, newOperand2)
      ENDIF
   ELSEIF oCondition:isKindOf("ComposedCondition")
      result := ::SimplifyComposition(oCondition)
   ENDIF
   IF result == NIL
      result := oCondition
   ENDIF
   result:lDenied := oCondition:lDenied
   oCondition:lSimplified := .T.

RETURN result

METHOD Assessable(oCondition) CLASS ConditionSimplifier

   LOCAL result

   IF oCondition:lAssessable != NIL
      RETURN oCondition:lAssessable
   ENDIF
   DO CASE
   CASE oCondition:isKindOf("BooleanExpression")
      result := ::BooleanExprAssessable(oCondition)
   CASE oCondition:isKindOf("Comparison")
      result := ::ComparisonAssessable(oCondition)
   CASE oCondition:isKindOf("ComposedCondition")
      result := ::CompositionAssessable(oCondition)
   ENDCASE
   oCondition:lAssessable := result

RETURN result

METHOD BooleanExprAssessable(oCondition) CLASS ConditionSimplifier
RETURN ::_oExpressionSimplifier:Assessable(oCondition:oExpression)

METHOD ComparisonAssessable(oCondition) CLASS ConditionSimplifier
RETURN       ::_oExpressionSimplifier:Assessable(oCondition:oOperand1) ;
       .AND. ::_oExpressionSimplifier:Assessable(oCondition:oOperand2)

///////////////////////////////////////////////////////////////////////////////
