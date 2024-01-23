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

#include "dbinfo.ch"
#include "hbclass.ch"
#include "sqlrdd.ch"
#include "inkey.ch"

//#define DEBUG

///////////////////////////////////////////////////////////////////////////////

CLASS ExpressionTranslator

   HIDDEN:
   DATA _oExpressionSimplifier

   HIDDEN:
   DATA _oConditionSimplifier

   HIDDEN:
   DATA _aComparisonOperators

   HIDDEN:
   DATA _aLogicalOperators

   HIDDEN:
   DATA _aArithmeticOperators

   PROTECTED:
   DATA _oDefaultContext

   PROTECTED:
   DATA cAs INIT "as"

   PROTECTED:
   DATA cTrue INIT "true"

   PROTECTED:
   DATA cFalse INIT "false"

   PROTECTED:
   DATA cNull INIT "null"

   EXPORTED:
   DATA aUDF INIT {}

   EXPORTED:
   DATA lFixVariables INIT .F.

   EXPORTED:
   DATA lSimplifyCondition INIT .T.

   EXPORTED:
   DATA lIndexExpression INIT .T.

   EXPORTED:
   DATA lFetchJoin INIT .T.

   EXPORTED:
   DATA aRelations INIT {}

   EXPORTED:
   METHOD TranslateRelationExpression(oDirectRelation)

   EXPORTED:
   METHOD GetTranslation(oCondition)

   EXPORTED:
   METHOD Translate(oExpression, x)

   PROTECTED:
   METHOD InternalTranslate(oExpression, x)

   PROTECTED:
   METHOD TranslateCondition(oCondition)

   PROTECTED:
   METHOD TranslateComparison(oComparison)

   PROTECTED:
   METHOD TranslateBooleanExpression(oBooleanExpression)

   PROTECTED:
   METHOD TranslateExpression(oExpression)

   PROTECTED:
   METHOD TranslateFunctionExpression(oFunctionExpression)

   PROTECTED:
   METHOD TranslateValueExpression(oValueExpression)

   PROTECTED:
   METHOD TranslateComposition(oSerialComposition) //METHOD TranslateComposition(oExpression)

   PROTECTED:
   METHOD TranslateOperand(oOperand, oOperator)

   //PROTECTED:
   //METHOD new(pWorkarea, pFixVariables) (disabled/duplicated)

   PROTECTED:
   METHOD GetSQLOperator(oOperator)

   PROTECTED:
   METHOD GetComparisonOperators() VIRTUAL

   PROTECTED:
   METHOD GetLogicalOperators() VIRTUAL

   PROTECTED:
   METHOD GetArithmeticOperators() VIRTUAL

   PROTECTED:
   METHOD GetComparisonOperatorSymbol(cName) INLINE ::GetOperatorSymbol(::GetComparisonOperators(), cName)

   PROTECTED:
   METHOD GetLogicalOperatorSymbol(cName) INLINE ::GetOperatorSymbol(::GetLogicalOperators(), cName)

   PROTECTED:
   METHOD GetArithmeticOperatorSymbol(cName) INLINE ::GetOperatorSymbol(::GetArithmeticOperators(), cName)

   HIDDEN:
   METHOD GetOperatorSymbol(aOperators, cName)

   PROTECTED:
   METHOD GetFunctionName(oFunctionExpression) VIRTUAL

   PROTECTED:
   METHOD Deny(cCondition) VIRTUAL

   PROTECTED:
   METHOD GetNewTranslator(pFixVariables, pSimplifyCondition, pIndexExpression) VIRTUAL

   PROTECTED:
   METHOD GetSQLAlias(oWorkArea)

   PROTECTED:
   METHOD FormatField(oWorkArea, CFieldName)

   // PROTECTED:
   // METHOD CheckParams(oFunctionExpression)

   PROTECTED:
   METHOD AaddRelations(aRelations) INLINE aAddRangeDistinct(::aRelations, xSelectMany(aRelations, {|y|iif(y:isKindOf("DirectRelation"), {y}, y:aDirectRelations)}), {|x|x:oWorkArea2:cAlias})

   EXPORTED:
   METHOD new(pWorkarea, pFixVariables, pSimplifyCondition, pIndexExpression)

ENDCLASS

METHOD new(pWorkarea, pFixVariables, pSimplifyCondition, pIndexExpression) CLASS ExpressionTranslator

   IF HB_ISCHAR(pWorkarea)
      ::_oDefaultContext := oGetWorkarea(pWorkarea)
   ELSE
      ::_oDefaultContext := pWorkarea
   ENDIF
   ::lSimplifyCondition := pSimplifyCondition == NIL .OR. pSimplifyCondition
   ::lFixVariables := pFixVariables != NIL .AND. pFixVariables
   ::lIndexExpression := pIndexExpression == NIL .OR. pIndexExpression
   ::_oExpressionSimplifier := ExpressionSimplifier():new(::lFixVariables, .F., ::_oDefaultContext:cAlias)
   IF ::lSimplifyCondition
      ::_oConditionSimplifier := ConditionSimplifier():new(::lFixVariables, .F., ::_oDefaultContext:cAlias)
   ENDIF

RETURN SELF

METHOD GetTranslation(oCondition) CLASS ExpressionTranslator

   LOCAL item
   LOCAL translation
   LOCAL x
   LOCAL oResult := TranslationResult():new()
   LOCAL aSQLConditions := {}
   LOCAL aClipperConditions := {}
   LOCAL aConditions := SplitCondition(oCondition, {})

   FOR EACH item IN aConditions
      ::aRelations := {}
      x := NIL
      translation := ::Translate(item, @x)
      IF translation == NIL
         translation := item:oClipperExpression:cValue
         IF item:isKindOf("ComposedCondition")
            translation := "(" + translation + ")"
         ENDIF
         aadd(aClipperConditions, translation)
      ELSE
         IF x == .F. // x can be null
            aClipperConditions := {}
            aSQLConditions := {translation}
            EXIT
         ELSEIF x == .T.
            LOOP
         ENDIF
         IF item:isKindOf("ComposedCondition")
            translation := "(" + translation + ")"
         ENDIF
         aadd(aSQLConditions, translation)
      ENDIF
   NEXT
   IF len(aClipperConditions) == 0
      aClipperConditions := {".T."}
   ENDIF
   IF len(aSQLConditions) == 0
      aSQLConditions := {"1 = 1"}
   ENDIF
   oResult:cClipperCondition := cJoin(aClipperConditions, " .and. ")
   oResult:cSQLCondition := cJoin(aSQLConditions, " " + ::GetLogicalOperatorSymbol("and") + " ")

RETURN oResult

METHOD Translate(oExpression, x) CLASS ExpressionTranslator

   LOCAL result
   LOCAL i
   LOCAL oRelation
   LOCAL resultHeader
   LOCAL cOperatorAnd
   LOCAL cFilterCondition
   LOCAL oFilterCondition
   LOCAL oParser
   LOCAL oErr
   LOCAL aInitRelations
   LOCAL aSortedRelations
   LOCAL addedAliases
   LOCAL lProgress
   LOCAL resultFooter := ""
   LOCAL aFilters := {}

   BEGIN SEQUENCE WITH __BreakBlock()
      result := iif(pcount() == 2, ::InternalTranslate(oExpression, @x), ::InternalTranslate(oExpression))

      IF oExpression:isKindOf("ConditionBase")
         IF len(::aRelations) > 0
            resultHeader := "exists (select 0 from " + ::_oDefaultContext:cFileName + " " + ::cAs + " " + "A"

            // we have to look for the filter aplying on the workarea in relation. This action could eventually modify ::aRelations
            FOR i := 1 TO len(::aRelations)
               oRelation := ::aRelations[i]
               cFilterCondition := oRelation:oWorkArea2:cFilterExpression
               IF cFilterCondition != NIL .AND. !cFilterCondition == ""
                  oParser := ConditionParser():new(oRelation:oWorkArea2:cAlias)
                  oFilterCondition := oParser:Parse(cFilterCondition)
                  aadd(aFilters, ::InternalTranslate(oFilterCondition))
               ENDIF
               oRelation:cSQLJoin := ::TranslateRelationExpression(oRelation)
            NEXT i

            cOperatorAnd := " " + ::GetLogicalOperatorSymbol("and") + " "

            IF ::lFetchJoin
               addedAliases := {lower(::_oDefaultContext:cAlias)}
               aInitRelations := aclone(::aRelations)
               aSortedRelations := {}
               DO WHILE len(aInitRelations) > 0
                  lProgress := .F.
                  FOR i := 1 TO len(aInitRelations)
                     IF len(aWhere(aInitRelations[i]:aDependingContexts, {|x|!lower(x) $ addedAliases})) == 1
                        aadd(addedAliases, lower(aInitRelations[i]:oWorkArea2:cAlias))
                        aadd(aSortedRelations, aInitRelations[i])
                        adel(aInitRelations, i, .T.)
                        lProgress := .T.
                        i--
                     ENDIF
                  NEXT i
                  if !lProgress
                     Throw(ErrorNew(,,,, "Circular dependency in the relations. Pass the parameter lFetchJoin to .F. to avoid this problem."))
                  ENDIF
               ENDDO

               FOR EACH oRelation IN aSortedRelations
                  resultHeader += " inner join " + oRelation:oWorkArea2:cFileName + " " + ::cAs + " " +  upper(oRelation:oWorkArea2:cAlias) + " on " + oRelation:cSQLJoin
               NEXT
            ELSE
               FOR EACH oRelation IN ::aRelations
                  resultHeader += ", " + oRelation:oWorkArea2:cFileName + " " + ::cAs + " " + upper(oRelation:oWorkArea2:cAlias)
                  resultFooter += cOperatorAnd + oRelation:cSQLJoin
               NEXT
            ENDIF
            resultFooter += iif(len(aFilters) > 0, cOperatorAnd + cJoin(aFilters, cOperatorAnd), "") + ")"
            result := resultHeader + " where " + result + resultFooter
         ENDIF
      ENDIF
   RECOVER USING oErr
      #ifdef DEBUG
         throw(oErr)
      #endif
      result := NIL
   END SEQUENCE

   HB_SYMBOL_UNUSED(oErr)

RETURN result

METHOD InternalTranslate(oExpression, x) CLASS ExpressionTranslator

   LOCAL result

   IF oExpression:isKindOf("ConditionBase")
      IF ::lSimplifyCondition
         oExpression := ::_oConditionSimplifier:Simplify(oExpression)
      ENDIF
      IF pcount() == 2 .AND. oExpression:lIsSimple .AND. oExpression:oExpression:ValueType == "value"
         x := upper(oExpression:Value) == ".T." // Value take denied into account.
      ENDIF
      result := ::TranslateCondition(oExpression)
   ELSEIF oExpression:isKindOf("Expression")
      result := ::TranslateExpression(oExpression)
   ENDIF

RETURN result

METHOD TranslateCondition(oCondition) CLASS ExpressionTranslator

   LOCAL result

   IF oCondition:isKindOf("Comparison")
      result := ::TranslateComparison(oCondition)
   ELSEIF oCondition:isKindOf("BooleanExpression")
      result := ::TranslateBooleanExpression(oCondition)
   ELSEIF oCondition:isKindOf("ComposedCondition")
      result := ::TranslateComposition(oCondition)
   ENDIF
   IF oCondition:lDenied
      result := ::Deny(result)
   ENDIF

RETURN result

METHOD TranslateComposition(oSerialComposition) CLASS ExpressionTranslator

    LOCAL cOperand1 := ::TranslateOperand(oSerialComposition:oOperand1, oSerialComposition:oOperator)
    LOCAL cOperand2 := ::TranslateOperand(oSerialComposition:oOperand2, oSerialComposition:oOperator)
    LOCAL cOperator := ::GetSQLOperator(oSerialComposition:oOperator):aSymbols[1]

RETURN cOperand1 + " " + cOperator + " " + cOperand2

METHOD TranslateOperand(oOperand, oOperator) CLASS ExpressionTranslator

   LOCAL result := ::InternalTranslate(oOperand)

   IF       (oOperand:isKindOf("ComposedCondition") .OR. oOperand:isKindOf("ComposedExpression")) ;
      .AND. oOperand:oOperator:nPriority < oOperator:nPriority // oOperand:isKindOf("ISerialComposition") problem with multipleinheritance
      result := "(" + result + ")"
   ENDIF

RETURN result

METHOD TranslateComparison(oComparison) CLASS ExpressionTranslator
RETURN ::TranslateExpression(oComparison:oOperand1) + " " + ::GetSQLOperator(oComparison:oOperator):aSymbols[1] + " " + ::TranslateExpression(oComparison:oOperand2)

METHOD TranslateBooleanExpression(oBooleanExpression) CLASS ExpressionTranslator
RETURN ::TranslateExpression(oBooleanExpression:oExpression)

METHOD TranslateExpression(oExpression) CLASS ExpressionTranslator

   LOCAL result

   IF !oExpression:lSimplified
      oExpression := ::_oExpressionSimplifier:Simplify(oExpression)
   ENDIF
   IF oExpression:isKindOf("ComposedExpression")
      result := ::TranslateComposition(oExpression)
   ELSEIF oExpression:isKindOf("FunctionExpression")
      result := ::TranslateFunctionExpression(oExpression)
   ELSEIF oExpression:isKindOf("ValueExpression")
      result := ::TranslateValueExpression(oExpression)
   ENDIF

RETURN result

METHOD TranslateFunctionExpression(oFunctionExpression) CLASS ExpressionTranslator

   LOCAL aParameters
   LOCAL cSQLFunctionName
   LOCAL cFunctionName := oFunctionExpression:cFunctionName

   DO CASE
   CASE cFunctionName == "deleted"
      RETURN ::FormatField(oFunctionExpression:oWorkArea, "SR_DELETED")
   CASE oFunctionExpression:cFunctionName == "recno"
      RETURN "SR_RECNO"
   ENDCASE
   cSQLFunctionName := ::GetFunctionName(oFunctionExpression)
   aParameters := xSelect(oFunctionExpression:aParameters, {|x|::InternalTranslate(x:oExpression)})

RETURN cSQLFunctionName + "(" + cJoin(aParameters, ",") + ")"

/*
METHOD CheckParams(oFunctionExpression) CLASS ExpressionTranslator

   IF ascan(oFunctionExpression:aParameters, {|x|x:lIsByRef}) > 0
      Throw(ErrorNew(,,,, "The expression cannot be translated because " + oFunctionExpression:cFunctionName + " contains a parameter passed by reference"))
   ENDIF

RETURN
*/

METHOD TranslateValueExpression(oValueExpression) CLASS ExpressionTranslator

   LOCAL result
   LOCAL aRelations

   SWITCH oValueExpression:ValueType
   CASE "field"
      IF upper(::_oDefaultContext:cAlias) != oValueExpression:cContext
         aRelations := RelationManager():new():GetRelations(::_oDefaultContext:cAlias, oValueExpression:cContext)
         IF len(aRelations) > 1
            Throw(ErrorNew(, , , , "There is several relations between " + ::_oDefaultContext:cAlias + " and " + oValueExpression:cContext + ". Translation impossible."))
         ELSEIF len(aRelations) == 1
            ::AaddRelations(aRelations)
         ENDIF
      ENDIF
      result := ::FormatField(oValueExpression:oWorkArea, oValueExpression:Value)
      EXIT
   CASE "variable"
      IF !::lFixVariables
         Throw(ErrorNew(, , , , "The variable " + oValueExpression:Value + " isn't SQL valid"))
      ENDIF
      EXIT
   CASE "value"
      SWITCH upper(oValueExpression:Value)
      CASE ".T."
         result := ::cTrue
         EXIT
      CASE ".F."
         result := ::cFalse
         EXIT
      CASE "NIL"
         result := ::cNull
         EXIT
      OTHERWISE
         result := oValueExpression:Value
      ENDSWITCH
   ENDSWITCH

RETURN result

METHOD GetSQLAlias(oWorkArea) CLASS ExpressionTranslator
RETURN iif(oWorkArea == ::_oDefaultContext, "A", upper(oWorkArea:cAlias))

METHOD FormatField(oWorkArea, cFieldName) CLASS ExpressionTranslator
RETURN ::GetSQLAlias(oWorkArea) + "." + upper(alltrim(cFieldName)) // SR_DBQUALIFY

METHOD GetSQLOperator(oOperator) CLASS ExpressionTranslator

   LOCAL aSQLOperators

   DO CASE
   CASE oOperator:isKindOf("LogicalOperator")
      aSQLOperators := ::GetLogicalOperators()
   CASE oOperator:isKindOf("ArithmeticOperator")
      aSQLOperators := ::GetArithmeticOperators()
   CASE oOperator:isKindOf("ComparisonOperator")
      aSQLOperators := ::GetComparisonOperators()
   ENDCASE

RETURN aSQLOperators[ascan(aSQLOperators, {|x|x:cName == oOperator:cName})]

METHOD GetOperatorSymbol(aOperators, cName) CLASS ExpressionTranslator
RETURN xFirst(aOperators, {|x|x:cName == cName}):aSymbols[1]

METHOD TranslateRelationExpression(oDirectRelation) CLASS ExpressionTranslator

   LOCAL aFields1
   LOCAL aFields2
   LOCAL aEqualityFields
   LOCAL i
   LOCAL cRelationExpr
   LOCAL cIndexExpr
   LOCAL oTranslator := ::GetNewTranslator()

   IF !::lIndexExpression .AND. !oDirectRelation:lSameLength
      Throw(ErrorNew(, , , , "Joint between " + oDirectRelation:oWorkArea1:cAlias + " and " + oDirectRelation:oWorkArea2:cAlias + " hasn't be made because it required complex expressions that can be slow to evaluate on the server side. To force the joint, pass the property 'lIndexExpression' of the translator to .T."))
   ENDIF

   oDirectRelation:SimplifyExpression(::_oExpressionSimplifier)
   oDirectRelation:SimplifyIndexExpression(::_oExpressionSimplifier)

   IF oDirectRelation:lSameLength // we try to make the joint on equality on each field whereas on the translated expressions because is it much faster on the database side : no conversion and no concatenation
      aFields1 := {}
      aFields2 := {}
      IF GetJointsFields(oDirectRelation:oExpression, oDirectRelation:oIndexExpression, oDirectRelation:oWorkArea1, oDirectRelation:oWorkArea2, @aFields1, @aFields2)
         aEqualityFields := {}
         FOR i := 1 TO len(aFields1)
            aadd(aEqualityFields, ::FormatField(oDirectRelation:oWorkArea1, aFields1[i]) + " " + ::GetComparisonOperatorSymbol("equalEqual") + " " + ::FormatField(oDirectRelation:oWorkArea2, aFields2[i]))
         NEXT i
         RETURN cJoin(aEqualityFields, " " + ::GetLogicalOperatorSymbol("and") + " ")
      ENDIF
   ENDIF

   cRelationExpr := oTranslator:Translate(oDirectRelation:oExpression)

   IF cRelationExpr == NIL
      Throw(ErrorNew(, , , , "The translation of the relation expression on " + oDirectRelation:oWorkArea1:cAlias + " into " + oDirectRelation:oWorkArea2:cAlias + " has failed"))
   ENDIF

   ::AaddRelations(oTranslator:aRelations) // There can be a field of a workearea in relation in the relation expression ?

   cIndexExpr := oTranslator:Translate(oDirectRelation:oIndexExpression)

   IF cIndexExpr == NIL
      Throw(ErrorNew(, , , , "The translation of the index expression of " + oDirectRelation:oWorkArea2:cAlias + "   has failed"))
   ENDIF

RETURN cRelationExpr + " " + ::GetComparisonOperatorSymbol("equal") + " " + cIndexExpr

///////////////////////////////////////////////////////////////////////////////

CLASS MSSQLExpressionTranslator FROM ExpressionTranslator

   PROTECTED:
   DATA cAs INIT ""

   PROTECTED:
   DATA cTrue INIT "1"

   PROTECTED:
   DATA cFalse INIT "0"

   //EXPORTED:
   //METHOD new(pWorkarea, pFixVariables) (disabled/duplicated)

   PROTECTED:
   METHOD GetFunctionName(oFunctionExpression)

   PROTECTED:
   METHOD GetComparisonOperators()

   PROTECTED:
   METHOD GetLogicalOperators()

   PROTECTED:
   METHOD GetArithmeticOperators()

   PROTECTED:
   METHOD GetNewTranslator(pFixVariables, pSimplifyCondition, pIndexExpression)

   PROTECTED:
   METHOD TranslateComparison(oComparison)

   PROTECTED:
   METHOD TranslateFunctionExpression(oFunctionExpression)

   PROTECTED:
   METHOD TranslateBooleanExpression(oBooleanExpression)

   PROTECTED:
   METHOD Deny(cCondition) INLINE "not(" + cCondition + ")"

   EXPORTED:
   METHOD new(pWorkarea, pFixVariables, pSimplifyCondition, pIndexExpression)

ENDCLASS

METHOD new(pWorkarea, pFixVariables, pSimplifyCondition, pIndexExpression) CLASS MSSQLExpressionTranslator

   ::aUDF := {"padl", "padr", "padc", "valtype", "transform", "at", "rat", "strtran", "min", "max"}

RETURN ::super:new(pWorkarea, pFixVariables, pSimplifyCondition, pIndexExpression)

METHOD TranslateComparison(oComparison) CLASS MSSQLExpressionTranslator

   LOCAL bLike := {|x|iif(hb_regexLike("^\'.*\'$", x), " like '%" + substr(x, 2, len(x) - 2) + "%'", " like '%'+" + x + "+'")}

   IF oComparison:oOperator:cName == "included"
      RETURN ::TranslateExpression(oComparison:oOperand2) + eval(bLike, ::TranslateExpression(oComparison:oOperand1))
   ELSEIF !set(_SET_EXACT) .AND. oComparison:oOperator:cName == "equal" .AND. oComparison:oOperand2:GetType() == "C"
      RETURN ::TranslateExpression(oComparison:oOperand1) + eval(bLike, ::TranslateExpression(oComparison:oOperand2))
   ELSEIF oComparison:oOperand2:isKindOf("ValueExpression") .AND. upper(oComparison:oOperand2:Value) == "NIL"
      IF oComparison:oOperator:cName == "equal" .OR. oComparison:oOperator:cName == "equalEqual"
         RETURN ::TranslateExpression(oComparison:oOperand1) + " IS NULL"
      ELSEIF oComparison:oOperator:cName == "different"
         RETURN ::TranslateExpression(oComparison:oOperand1) + " IS NOT NULL"
      ELSE
         throw(ErrorNew(, , , , "null value cannot be compared with the operator " + oComparison:oOperator:cName))
      ENDIF
   ELSE
      RETURN ::super:TranslateComparison(oComparison)
   ENDIF

RETURN NIL

METHOD TranslateFunctionExpression(oFunctionExpression) CLASS MSSQLExpressionTranslator

   LOCAL result
   LOCAL cSavedFormat
   LOCAL dDate
   LOCAL cFunctionName := oFunctionExpression:cFunctionName
   LOCAL firstParam
   LOCAL secondParam
   LOCAL thirdParam
   LOCAL aParamExprs

   // ::CheckParams(oFunctionExpression)
   aParamExprs := xSelect(oFunctionExpression:aParameters, {|x|x:oExpression})

#if 0 // TODO: old code for reference (to be deleted)
   DO CASE
   CASE cFunctionName == "substr"
      thirdParam := iif(len(aParamExprs) == 3, ::InternalTranslate(aParamExprs[3]), "999999")
      RETURN "substring(" + ::InternalTranslate(aParamExprs[1]) + ", " + ::InternalTranslate(aParamExprs[2]) + "," + thirdParam + ")"
   CASE cFunctionName == "cstr"
      RETURN "convert(char, " + ::InternalTranslate(aParamExprs[1]) + ")"
   CASE cFunctionName == "val"
      IF set(_SET_FIXED)
         RETURN "convert(decimal(38," + alltrim(str(set(_SET_DECIMALS))) + "), " + ::InternalTranslate(aParamExprs[1]) + ")"
      ENDIF
      RETURN "convert(float, " + ::InternalTranslate(aParamExprs[1]) + ")"
   CASE cFunctionName == "int"
      RETURN "round(" + ::InternalTranslate(aParamExprs[1]) + ", 0)"
   CASE cFunctionName == "alltrim"
      RETURN "ltrim(rtrim(" + ::InternalTranslate(aParamExprs[1]) + "))"
   CASE cFunctionName == "dow" // cdow not implemented as it is used to format date values in a textual way.
      RETURN "datepart(weekday, " + ::InternalTranslate(aParamExprs[1]) + ")"
   CASE cFunctionName == "iif" .OR. cFunctionName == "if"
      IF aParamExprs[2]:isKindOf("ConditionBase")
         IF aParamExprs[2]:isKindOf("BooleanExpression") .AND. aParamExprs[3]:isKindOf("BooleanExpression")
            secondParam := ::super:TranslateBooleanExpression(aParamExprs[2])
            thirdParam := ::super:TranslateBooleanExpression(aParamExprs[3])
         ELSE
            Throw(ErrorNew(,,,, "TSQL doesn't support condition as the second or third parameter of the 'CASE WHEN ELSE END' structure"))
         ENDIF
      ELSE
         secondParam := ::InternalTranslate(aParamExprs[2])
         thirdParam := ::InternalTranslate(aParamExprs[3])
      ENDIF
      RETURN "CASE WHEN " + ::InternalTranslate(aParamExprs[1]) + " THEN " + secondParam + " ELSE " + thirdParam + " END"
   CASE cFunctionName == "at"
      IF len(aParamExprs) <= 3
         RETURN "charindex(" + ::InternalTranslate(aParamExprs[1]) + ", " + ::InternalTranslate(aParamExprs[2]) + iif(len(aParamExprs) == 3, ", " + ::InternalTranslate(aParamExprs[3]), "") + ")"
      ENDIF
   CASE cFunctionName == "islower" // http://www.simple-talk.com/sql/t-sql-programming/sql-string-user-function-workbench-part-1/
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[A-Z]%' COLLATE Latin1_General_CS_AI"
   CASE cFunctionName == "isupper"
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[a-z]%' COLLATE Latin1_General_CS_AI"
   CASE cFunctionName == "isalpha"
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[A-Z]%'"
   CASE cFunctionName == "isdigit"
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[0-9]%'"
   CASE cFunctionName == "dtos"
      RETURN "convert(char, " + ::InternalTranslate(aParamExprs[1]) + ", 112)"
   CASE cFunctionName == "ctod"
      firstParam := ::InternalTranslate(aParamExprs[1])
      IF hb_regexLike("\'.*\'", firstParam)
         IF hb_regexLike("\'\s*\'", firstParam)
            RETURN ::cNull
         ENDIF
         cSavedFormat := set(_SET_DATEFORMAT)
         dDate := oFunctionExpression:oClipperExpression:Evaluate()
         SET DATE AMERICAN
         result := "'" + dtoc(dDate) + "'"
         SET DATE FORMAT cSavedFormat
         RETURN result
      ENDIF
      RETURN firstParam
   CASE cFunctionName == "strtran"
      IF len(aParamExprs) < 3
         RETURN "replace(" + ::InternalTranslate(aParamExprs[1]) + ", " + ::InternalTranslate(aParamExprs[2]) + iif(len(aParamExprs) == 3, ", " + ::InternalTranslate(aParamExprs[3]), ", ''") + ")"
      ENDIF
   ENDCASE
#endif

   SWITCH cFunctionName
   CASE "substr"
      thirdParam := iif(len(aParamExprs) == 3, ::InternalTranslate(aParamExprs[3]), "999999")
      RETURN "substring(" + ::InternalTranslate(aParamExprs[1]) + ", " + ::InternalTranslate(aParamExprs[2]) + "," + thirdParam + ")"
   CASE "cstr"
      RETURN "convert(char, " + ::InternalTranslate(aParamExprs[1]) + ")"
   CASE "val"
      IF set(_SET_FIXED)
         RETURN "convert(decimal(38," + alltrim(str(set(_SET_DECIMALS))) + "), " + ::InternalTranslate(aParamExprs[1]) + ")"
      ENDIF
      RETURN "convert(float, " + ::InternalTranslate(aParamExprs[1]) + ")"
   CASE "int"
      RETURN "round(" + ::InternalTranslate(aParamExprs[1]) + ", 0)"
   CASE "alltrim"
      RETURN "ltrim(rtrim(" + ::InternalTranslate(aParamExprs[1]) + "))"
   CASE "dow" // cdow not implemented as it is used to format date values in a textual way.
      RETURN "datepart(weekday, " + ::InternalTranslate(aParamExprs[1]) + ")"
   CASE "iif"
   CASE "if"
      IF aParamExprs[2]:isKindOf("ConditionBase")
         IF aParamExprs[2]:isKindOf("BooleanExpression") .AND. aParamExprs[3]:isKindOf("BooleanExpression")
            secondParam := ::super:TranslateBooleanExpression(aParamExprs[2])
            thirdParam := ::super:TranslateBooleanExpression(aParamExprs[3])
         ELSE
            Throw(ErrorNew(, , , , "TSQL doesn't support condition as the second or third parameter of the 'CASE WHEN ELSE END' structure"))
         ENDIF
      ELSE
         secondParam := ::InternalTranslate(aParamExprs[2])
         thirdParam := ::InternalTranslate(aParamExprs[3])
      ENDIF
      RETURN "CASE WHEN " + ::InternalTranslate(aParamExprs[1]) + " THEN " + secondParam + " ELSE " + thirdParam + " END"
   CASE "at"
      IF len(aParamExprs) <= 3
         RETURN "charindex(" + ::InternalTranslate(aParamExprs[1]) + ", " + ::InternalTranslate(aParamExprs[2]) + iif(len(aParamExprs) == 3, ", " + ::InternalTranslate(aParamExprs[3]), "") + ")"
      ENDIF
      EXIT
   CASE "islower" // http://www.simple-talk.com/sql/t-sql-programming/sql-string-user-function-workbench-part-1/
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[A-Z]%' COLLATE Latin1_General_CS_AI"
   CASE "isupper"
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[a-z]%' COLLATE Latin1_General_CS_AI"
   CASE "isalpha"
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[A-Z]%'"
   CASE "isdigit"
      RETURN ::InternalTranslate(aParamExprs[1]) + " like '[0-9]%'"
   CASE "dtos"
      RETURN "convert(char, " + ::InternalTranslate(aParamExprs[1]) + ", 112)"
   CASE "ctod"
      firstParam := ::InternalTranslate(aParamExprs[1])
      IF hb_regexLike("\'.*\'", firstParam)
         IF hb_regexLike("\'\s*\'", firstParam)
            RETURN ::cNull
         ENDIF
         cSavedFormat := set(_SET_DATEFORMAT)
         dDate := oFunctionExpression:oClipperExpression:Evaluate()
         SET DATE AMERICAN
         result := "'" + dtoc(dDate) + "'"
         SET DATE FORMAT cSavedFormat
         RETURN result
      ENDIF
      RETURN firstParam
   CASE "strtran"
      IF len(aParamExprs) < 3
         RETURN "replace(" + ::InternalTranslate(aParamExprs[1]) + ", " + ::InternalTranslate(aParamExprs[2]) + iif(len(aParamExprs) == 3, ", " + ::InternalTranslate(aParamExprs[3]), ", ''") + ")"
      ENDIF
   ENDSWITCH

RETURN ::super:TranslateFunctionExpression(oFunctionExpression)

METHOD TranslateBooleanExpression(oBooleanExpression) CLASS MSSQLExpressionTranslator
RETURN ::super:TranslateBooleanExpression(oBooleanExpression) + " = 1"

METHOD GetFunctionName(oFunctionExpression) CLASS MSSQLExpressionTranslator

   LOCAL cFunctionName := oFunctionExpression:cFunctionName

   DO CASE
   CASE ascan({"abs", "left", "right", "replicate", "space", "str", "stuff", "upper", "lower", "ltrim", "rtrim", "year", "month", "day", "len", "exp", "log", "round", "sqrt"}, cFunctionName) > 0
      RETURN cFunctionName
   CASE ascan(::aUDF, cFunctionName) > 0
      RETURN "xhb." + cFunctionName // TODO: namespace ?
   CASE cFunctionName == "trim"
      RETURN "rtrim"
   CASE cFunctionName == "date"
      RETURN "getdate"
   OTHERWISE
      Throw(ErrorNew(, , , , "No SQL function corresponding to " + cFunctionName + " has been defined!")) // all functions translation should be specified. We could RETURN oFunctionExpression:cFunctionName, but we would have no way to check if the SQL is valid before testing it.
   ENDCASE

RETURN NIL

METHOD GetNewTranslator(pFixVariables, pSimplifyCondition, pIndexExpression)
RETURN MSSQLExpressionTranslator():new(::_oDefaultContext, pFixVariables, pSimplifyCondition, pIndexExpression)

METHOD GetComparisonOperators() CLASS MSSQLExpressionTranslator

   IF ::_aComparisonOperators == NIL
      ::_aComparisonOperators :=                             ;
         {                                                   ;
          ComparisonOperator():new("equal", {"="}),          ;
          ComparisonOperator():new("equalEqual", {"="}),     ;
          ComparisonOperator():new("different", {"!="}),     ;
          ComparisonOperator():new("lower", {"<"}),          ;
          ComparisonOperator():new("higher", {">"}),         ;
          ComparisonOperator():new("lowerOrEqual", {"<="}),  ;
          ComparisonOperator():new("higherOrEqual", {">="}), ;
         }
   ENDIF

RETURN ::_aComparisonOperators

METHOD GetLogicalOperators() CLASS MSSQLExpressionTranslator

   IF ::_aLogicalOperators == NIL
      ::_aLogicalOperators :=                    ;
         {                                       ;
          LogicalOperator():new("and", {"and"}), ;
          LogicalOperator():new("or", {"or"})    ;
         }
   ENDIF

RETURN ::_aLogicalOperators

METHOD GetArithmeticOperators() CLASS MSSQLExpressionTranslator

   IF ::_aArithmeticOperators == NIL
      ::_aArithmeticOperators :=                         ;
         {                                               ;
          ArithmeticOperator():new("plus", {"+"}),       ;
          ArithmeticOperator():new("minus", {"-"}),      ;
          ArithmeticOperator():new("multiplied", {"*"}), ;
          ArithmeticOperator():new("divided", {"/"}),    ;
          ArithmeticOperator():new("exponent", {"^"})    ;
         }
   ENDIF

RETURN ::_aArithmeticOperators

///////////////////////////////////////////////////////////////////////////////

CLASS TranslationResult

   EXPORTED:
   DATA cSQLCondition

   EXPORTED:
   DATA cClipperCondition

   EXPORTED:
   METHOD lIsFullSQL INLINE ::cClipperCondition == NIL .OR. alltrim(::cClipperCondition) == ""

ENDCLASS

///////////////////////////////////////////////////////////////////////////////

CLASS EnchancedDirectRelation FROM DirectRelation

   HIDDEN:
   DATA _oExpression

   EXPORTED:
   ACCESS oExpression

   EXPORTED:
   METHOD SimplifyExpression(oSimplifier) INLINE ::_oExpression := oSimplifier:Simplify(::oExpression)

   HIDDEN:
   DATA _oIndexExpression

   EXPORTED:
   ACCESS oIndexExpression

   EXPORTED:
   METHOD SimplifyIndexExpression(oSimplifier) INLINE ::_oIndexExpression := oSimplifier:Simplify(::oIndexExpression)

   EXPORTED:
   DATA oSeekIndex READONLY

   HIDDEN:
   DATA _aDependingContexts

   EXPORTED:
   ACCESS aDependingContexts

   EXPORTED:
   DATA nMaxLength READONLY

   EXPORTED:
   DATA lSameLength READONLY

   EXPORTED:
   DATA cSQLJoin

   EXPORTED:
   METHOD new(pWorkarea1, pWorkarea2, pExpression)

ENDCLASS

METHOD new(pWorkarea1, pWorkarea2, pExpression) CLASS EnchancedDirectRelation

   LOCAL indexLength

   ::super:new(pWorkarea1, pWorkarea2, pExpression)
   ::oSeekIndex := ::oWorkArea2:GetControllingIndex()
   indexLength := iif(::oSeekIndex == NIL, 15, ::oSeekIndex:nLength)
   ::lSameLength := ::oClipperExpression:nLength == indexLength
   ::nMaxLength := min(::oClipperExpression:nLength, indexLength)

RETURN SELF

METHOD oExpression(xValue) CLASS EnchancedDirectRelation

   LOCAL cRelationExpr

   HB_SYMBOL_UNUSED(xValue)

   IF ::_oExpression == NIL
      cRelationExpr := ::oClipperExpression:cValue
      IF ::oClipperExpression:nLength > ::nMaxLength
         cRelationExpr := "left(" + cRelationExpr + ", " + str(::nMaxLength) + ")"
      ENDIF
      ::_oExpression := ExpressionParser():new(::oWorkarea1:cAlias):Parse(cRelationExpr)
   ENDIF

RETURN ::_oExpression

METHOD oIndexExpression(xValue) CLASS EnchancedDirectRelation

   LOCAL cIndexExpr

   HB_SYMBOL_UNUSED(xValue)

   IF ::_oIndexExpression == NIL
      cIndexExpr := iif(::oSeekIndex:lIsSynthetic, ::oSeekIndex:aDbFields[1]:cName, ::oSeekIndex:oClipperExpression:cValue)
      IF ::oSeekIndex:nLength > ::nMaxLength
         cIndexExpr := "left(" + cIndexExpr + ", " + str(::nMaxLength) + ")"
      ENDIF
      ::_oIndexExpression := ExpressionParser():new(::oWorkarea2:cAlias):Parse(cIndexExpr)
   ENDIF

RETURN ::_oIndexExpression

METHOD aDependingContexts() CLASS EnchancedDirectRelation

   IF ::_aDependingContexts == NIL
      ::_aDependingContexts := CollectAliases(::oExpression, CollectAliases(::oIndexExpression, {}))
   ENDIF

RETURN ::_aDependingContexts

///////////////////////////////////////////////////////////////////////////////

CLASS EnchancedRelationFactory FROM RelationFactory

   EXPORTED:
   METHOD NewDirectRelation(pWorkarea1, pWorkarea2, pExpression) INLINE EnchancedDirectRelation():new(pWorkarea1, pWorkarea2, pExpression)

   EXPORTED:
   METHOD new()

ENDCLASS

METHOD new() CLASS EnchancedRelationFactory

   STATIC instance

   IF instance == NIL
      instance := SELF
   ENDIF

RETURN instance

///////////////////////////////////////////////////////////////////////////////

FUNCTION SplitCondition(oCondition, aConditions)

   DO WHILE oCondition:isKindOf("ComposedCondition") .AND. oCondition:oOperator:cName == "and"
      SplitCondition(oCondition:oOperand1, aConditions)
      oCondition := oCondition:oOperand2
   ENDDO
   aadd(aConditions, oCondition)

RETURN aConditions

FUNCTION GetJointsFields(oRelationExpr, oIndexExpr, oWorkArea1, oWorkArea2, aFields1, aFields2)

   LOCAL oField1
   LOCAL oField2

   IF oRelationExpr:isKindOf(oIndexExpr)
      IF oRelationExpr:isKindOf("ComposedExpression")
         RETURN       GetJointsFields(oRelationExpr:oOperand1, oIndexExpr:oOperand1, oWorkArea1, oWorkArea2, @aFields1, @aFields2) ;
                .AND. GetJointsFields(oRelationExpr:oOperand2, oIndexExpr:oOperand2, oWorkArea1, oWorkArea2, @aFields1, @aFields2)
      ELSEIF oRelationExpr:isKindOf("FunctionExpression") .AND. oRelationExpr:cFunctionName == oIndexExpr:cFunctionName
         RETURN GetJointsFields(oRelationExpr:aParameters[1]:oExpression, oIndexExpr:aParameters[1]:oExpression, oWorkArea1, oWorkArea2, @aFields1, @aFields2)
      ELSEIF oRelationExpr:isKindOf("ValueExpression")
         oField1 := oWorkArea1:GetFieldByName(oRelationExpr:Value) // TODO: we could apply the same strategy with field of other workarea but we have to look for the relations with this workarea and to do this we need to translate an expression. => I don't deal with this case, it's very rare.
         oField2 := oWorkArea2:GetFieldByName(oIndexExpr:Value)
         IF       !oField1 == NIL ;
            .AND. !oField2 == NIL ;
            .AND. oField1:cType == oField2:cType ;
            .AND. oField1:nLength == oField2:nLength
            aadd(aFields1, oField1:cName)
            aadd(aFields2, oField2:cName)
            RETURN .T.
         ENDIF
      ENDIF
   ENDIF

RETURN .F.

///////////////////////////////////////////////////////////////////////////////
