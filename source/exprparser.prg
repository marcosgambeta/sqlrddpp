// TODO: add copyright here

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

CLASS SR_ParserBase

   HIDDEN:
   DATA _SortedOperators

   PROTECTED:
   DATA _Operators

   PROTECTED:
   DATA _cDefaultContext

   EXPORTED:
   METHOD Parse(cExpression)

   PROTECTED:
   METHOD InternParse(cExpression, cAlias)

   PROTECTED:
   METHOD GetComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2) VIRTUAL

   PROTECTED:
   METHOD GetOperators() VIRTUAL

   PROTECTED:
   ACCESS SortedOperators

   PROTECTED:
   METHOD GetOperands(cExpression, cAlias, oOperand1, oConnector, oOperand2)

   PROTECTED:
   METHOD RestoreParenthesis(cExpression)

   PROTECTED:
   METHOD ResolveParenthesis(cExpression)

   PROTECTED:
   METHOD ExtractAlias1(cExpression)

   PROTECTED:
   METHOD ExtractAlias2(cExpression)

   PROTECTED:
   METHOD ExtractAlias3(cExpression)

   HIDDEN:
   METHOD ExtractAlias(cExpression, cRegex)

   EXPORTED:
   METHOD new(pWorkarea)

ENDCLASS

METHOD SR_ParserBase:new(pWorkarea)

   ::_cDefaultContext := pWorkarea

RETURN SELF

METHOD SR_ParserBase:SortedOperators

   IF ::_SortedOperators == NIL
      ::_SortedOperators := ASort(::GetOperators(), , , {|x, y|x:nPriority < y:nPriority})
   ENDIF

RETURN ::_SortedOperators

METHOD SR_ParserBase:Parse(cExpression)
RETURN ::InternParse("?" + AtRepl(Chr(34), cExpression, "'") + "?", ::_cDefaultContext)

METHOD SR_ParserBase:InternParse(cExpression, cAlias)

   LOCAL oOperand1
   LOCAL oOperand2
   LOCAL oConnector

   ::GetOperands(@cExpression, @cAlias, @oOperand1, @oConnector, @oOperand2)

   IF oOperand2 != NIL
       RETURN ::GetComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2)
   ENDIF

RETURN oOperand1

METHOD SR_ParserBase:GetOperands(cExpression, cAlias, oOperand1, oConnector, oOperand2)

   LOCAL o
   LOCAL aGroups
   LOCAL i
   LOCAL cNewAlias
   LOCAL cRegO

   cExpression := AllTrim(cExpression)

   cAlias := IIf((cNewAlias := ::ExtractAlias1(@cExpression)) != NIL, cNewAlias, cAlias)

   DO WHILE hb_regexLike("^\?(?:[^\'\?]*?(?:\'[^\']*\'))*[^\'\?]*\?$", cExpression)
      cExpression := AllTrim(SubStr(cExpression, 2, Len(cExpression) - 2))
      cAlias := IIf((cNewAlias := ::ExtractAlias2(@cExpression)) != NIL, cNewAlias, cAlias)
      ::ResolveParenthesis(@cExpression)
   ENDDO

   FOR i := 1 TO Len(::SortedOperators)
      o := ::SortedOperators[i]
      cRegO := "^((?:[^\'\?]*(?:\'[^\']*\'|\?(?:[^\'\?]*(?:\'[^\']*\'))*[^\'\?]*\?))*?[^\'\?]*?)(" + o:cPattern + ")(\s*[^>].*)$"
      IF HB_RegExMatch(cRegO, cExpression, .F.)
         aGroups := HB_RegExAtX(cRegO, cExpression)
         oOperand1 := ::InternParse(aGroups[2, 1], cAlias)
         oConnector := o
         oOperand2 := ::InternParse(aGroups[4, 1], cAlias)
         EXIT
      ENDIF
   NEXT i

   cAlias := IIf((cNewAlias := ::ExtractAlias3(@cExpression)) != NIL, cNewAlias, cAlias)

RETURN NIL

METHOD SR_ParserBase:ResolveParenthesis(cExpression)

   LOCAL i
   LOCAL nParenthesisDeep := 0

   FOR i := 1 TO Len(cExpression)
      SWITCH cExpression[i]
      CASE "'"
         DO WHILE cExpression[++i] != "'"
         ENDDO
         EXIT
      CASE "("
         IF nParenthesisDeep == 0
            cExpression[i] := "?"
         ENDIF
         nParenthesisDeep++
         EXIT
      CASE ")"
         nParenthesisDeep--
         IF nParenthesisDeep == 0
            cExpression[i] := "?"
         ENDIF
      ENDSWITCH
   NEXT i

RETURN NIL

METHOD SR_ParserBase:RestoreParenthesis(cExpression)

   LOCAL cParenthesis := "("
   LOCAL i

   FOR i := 1 TO Len(cExpression)
      IF substr(cExpression, i, 1) == "'"
         DO WHILE substr(cExpression, ++i, 1) != "'"
         ENDDO
      ELSEIF substr(cExpression, i, 1) == "?"
         cExpression := Stuff(cExpression, i, 1, cParenthesis)
         cParenthesis := IIf(cParenthesis == "(", ")", "(")
      ENDIF
   NEXT i

RETURN cExpression

METHOD SR_ParserBase:ExtractAlias1(cExpression)

   STATIC regex := "^(\w+)\s*->\s*(\?.+\?)$"

RETURN ::ExtractAlias(@cExpression, regex)

METHOD SR_ParserBase:ExtractAlias2(cExpression)

   STATIC regex := "^(\w+)\s*->\s*(\(.+\))$"

RETURN ::ExtractAlias(@cExpression, regex)

METHOD SR_ParserBase:ExtractAlias3(cExpression)

   STATIC regex := "^(\w+)\s*->\s*(\w+)$"

RETURN ::ExtractAlias(@cExpression, regex)

METHOD SR_ParserBase:ExtractAlias(cExpression, cRegex)

   LOCAL aGroups

   IF HB_RegExMatch(cRegex, cExpression, .F.)
      aGroups := HB_RegExAtX(cRegex, cExpression)
      cExpression := aGroups[3, 1]
      RETURN aGroups[2, 1]
   ENDIF

RETURN NIL

///////////////////////////////////////////////////////////////////////////////

CLASS SR_ExpressionParser FROM SR_ParserBase

   PROTECTED:
   METHOD GetOperators()

   PROTECTED:
   METHOD GetComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2)

   PROTECTED:
   METHOD GetOperands(cExpression, cAlias, oOperand1, oConnector, oOperand2)

   PROTECTED:
   METHOD GetParameter(cExpression, cAlias)

   EXPORTED:
   METHOD new(pWorkarea) INLINE ::super:new(pWorkarea)

ENDCLASS

METHOD SR_ExpressionParser:GetOperators()

   IF ::_Operators == NIL
      ::_Operators := {                                               ;
                       SR_ArithmeticOperator():new("plus", {"+"}),       ;
                       SR_ArithmeticOperator():new("minus", {"-"}),      ;
                       SR_ArithmeticOperator():new("multiplied", {"*"}), ;
                       SR_ArithmeticOperator():new("divided", {"/"}),    ;
                       SR_ArithmeticOperator():new("exponent", {"^"})    ;
                      }
   ENDIF

RETURN ::_Operators

METHOD SR_ExpressionParser:GetComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2)
RETURN SR_ComposedExpression():new(cAlias, ::RestoreParenthesis(cExpression), oOperand1, oConnector, oOperand2)

METHOD SR_ExpressionParser:GetOperands(cExpression, cAlias, oOperand1, oConnector, oOperand2)

   LOCAL aGroups
   LOCAL aParamGroups
   LOCAL cFunctionName
   LOCAL cParameters
   LOCAL aParameters := {}

   STATIC cRegFunction := "^(\w+)\s*\?\s*(.*?)\s*\?$"
   STATIC cRegParams := "^((?:[^\'\?,]*?(?:\'[^\']*\'|\?(?:[^\'\?]*?(?:\'[^\']*\'))*[^\'\?]*?\?))*[^\'\?,]*?),(.*)$"
   STATIC cRegMacro := "^&\s*(\w+)$"

   ::super:GetOperands(@cExpression, @cAlias, @oOperand1, @oConnector, @oOperand2)

   IF oOperand1 == NIL
      IF HB_RegExMatch(cRegFunction, cExpression, .F.)
         aGroups := HB_RegExAtX(cRegFunction, cExpression)
         cFunctionName := aGroups[2, 1]
         cParameters := aGroups[3, 1]
         ::ResolveParenthesis(@cParameters)
         DO WHILE HB_RegExMatch(cRegParams, cParameters, .F.)
            aParamGroups := HB_RegExAtX(cRegParams, cParameters)
            AAdd(aParameters, ::GetParameter(aParamGroups[2, 1], cAlias))
            cParameters := aParamGroups[3, 1]
         ENDDO
         IF !cParameters == ""
            AAdd(aParameters, ::GetParameter(cParameters, cAlias))
         ENDIF
         oOperand1 := SR_FunctionExpression():new(cAlias, ::RestoreParenthesis(cExpression), cFunctionName, aParameters)
      ELSEIF HB_RegExMatch(cRegMacro, cExpression, .F.)
         oOperand1 := ::InternParse(&(HB_RegExAtX(cRegMacro, cExpression)[2, 1]))
      ELSE
         oOperand1 := SR_ValueExpression():new(cAlias, ::RestoreParenthesis(cExpression), ::RestoreParenthesis(cExpression))
      ENDIF
   ENDIF

RETURN NIL

METHOD SR_ExpressionParser:GetParameter(cExpression, cAlias)

   STATIC cRegParam := "^(@?)(.*)$"

   LOCAL aGroups
   LOCAL lByRef
   LOCAL oExpression

   IF hb_regexLike("^\s*$", cExpression)
      lByRef := .F.
      oExpression := SR_ValueExpression():new(cAlias, "nil")
   ELSE
      aGroups := HB_RegExAtX(cRegParam, cExpression)
      lByRef := aGroups[2, 1] != ""
      oExpression := GetConditionOrExpression(::RestoreParenthesis(aGroups[3, 1]), cAlias)
   ENDIF

RETURN SR_Parameter():new(oExpression, lByRef)

///////////////////////////////////////////////////////////////////////////////

CLASS SR_ConditionParser FROM SR_ParserBase

   HIDDEN:
   DATA _cRegOperator
   DATA _cRegNegative1
   DATA _cRegNegative2
   DATA _cNegativesPattern INIT "!|\.not\."

   EXPORTED:
   DATA aClipperComparisonOperators

   PROTECTED:
   METHOD GetOperators()

   PROTECTED:
   METHOD GetComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2)

   PROTECTED:
   METHOD GetOperands(cExpression, cAlias, oOperand1, oConnector, oOperand2)

   EXPORTED:
   METHOD new(pWorkarea)

ENDCLASS

METHOD SR_ConditionParser:new(pWorkarea)

   LOCAL cOperatorsChoice
   LOCAL cOperatorsChars

   ::super:new(pWorkarea)
   ::aClipperComparisonOperators :=                              ;
      {                                                          ;
       SR_ComparisonOperator():new("equal", {"="}),                 ;
       SR_ComparisonOperator():new("equalEqual", {"=="}),           ;
       SR_ComparisonOperator():new("different", {"!=", "<>", "#"}), ;
       SR_ComparisonOperator():new("lower", {"<"}),                 ;
       SR_ComparisonOperator():new("higher", {">"}),                ;
       SR_ComparisonOperator():new("lowerOrEqual", {"<="}),         ;
       SR_ComparisonOperator():new("higherOrEqual", {">="}),        ;
       SR_ComparisonOperator():new("included", {"$"})               ;
      }

   cOperatorsChoice := SR_cJoin(SR_xSelect(::aClipperComparisonOperators, {|x|x:cPattern}), "|")
   cOperatorsChars := SR_cPattern(CharList(SR_cJoin(SR_xSelectMany(::aClipperComparisonOperators, {|x|x:aSymbols}), "")))

   ::_cRegOperator := ;
      HB_RegExComp("^((?:[^\'\?]*?(?:\'[^\']*\'|\?(?:[^\'\?]*?(?:\'[^\']*\'))*[^\'\?]*?\?))*(?:[^\'\?]*?[^-" + ;
      cOperatorsChars + "\s])?\s*)(" + cOperatorsChoice + ")([^" + cOperatorsChars + "].*)$", .F.)
   ::_cRegNegative1 := HB_RegExComp("^(" + ::_cNegativesPattern + ")\s*(\?.*\?)$", .F.)
   ::_cRegNegative2 := HB_RegExComp("^(" + ::_cNegativesPattern + ")\s*(.+)$", .F.)

RETURN SELF

METHOD SR_ConditionParser:GetOperators()

   IF ::_Operators == NIL
      ::_Operators := {                                           ;
                       SR_LogicalOperator():new("and", {".and."}),   ;
                       SR_LogicalOperator():new("or", {".or."})      ;
                      }
   ENDIF

RETURN ::_Operators

METHOD SR_ConditionParser:GetComposedExpression(cAlias, cExpression, oOperand1, oConnector, oOperand2)
RETURN SR_ComposedCondition():new(cAlias, ::RestoreParenthesis(cExpression), oOperand1, oConnector, oOperand2)

METHOD SR_ConditionParser:GetOperands(cExpression, cAlias, oOperand1, oConnector, oOperand2)

   LOCAL aGroups
   LOCAL oComparisonOperator
   LOCAL oExpressionParser
   LOCAL lDenied
   LOCAL cNewAlias
   LOCAL cExpression2

   ::super:GetOperands(@cExpression, @cAlias, @oOperand1, @oConnector, @oOperand2)

   IF oOperand1 == NIL
      IF HB_RegExMatch(::_cRegNegative1, cExpression, .F.)
         aGroups := HB_RegExAtX(::_cRegNegative1, cExpression)
         oOperand1 := ::InternParse(aGroups[3, 1], cAlias)
         oOperand1:lDenied := .T.
      ELSE
         cAlias := IIf((cNewAlias := ::ExtractAlias3(@cExpression)) != NIL, cNewAlias, cAlias)

         oExpressionParser := SR_ExpressionParser():new(cAlias)

         IF HB_RegExMatch(::_cRegOperator, cExpression, .F.)
            aGroups := HB_RegExAtX(::_cRegOperator, cExpression)

            oComparisonOperator := SR_xFirst(::aClipperComparisonOperators, {|y|aGroups[3, 1] $ y:aSymbols})

            oOperand1 := SR_Comparison():new(cAlias, ;
                                          ::RestoreParenthesis(cExpression), ;
                                          oExpressionParser:Parse(::RestoreParenthesis(aGroups[2, 1])), ;
                                          oComparisonOperator, ;
                                          oExpressionParser:Parse(::RestoreParenthesis(aGroups[4, 1])))
            ELSE
               lDenied := HB_RegExMatch(::_cRegNegative2, cExpression, .F.)
               cExpression2 := cExpression
               IF lDenied
                  aGroups := HB_RegExAtX(::_cRegNegative2, cExpression)
                  cExpression2 := aGroups[3, 1]
               ENDIF
               oOperand1 := SR_BooleanExpression():new2(cAlias, ::RestoreParenthesis(cExpression), lDenied, oExpressionParser:Parse(::RestoreParenthesis(cExpression2)))
         ENDIF
      ENDIF
   ENDIF

RETURN NIL

///////////////////////////////////////////////////////////////////////////////

STATIC FUNCTION GetConditionOrExpression(cExpression, cAlias)

   LOCAL cContext
   LOCAL oParser := SR_ConditionParser():new(cAlias)
   LOCAL oResult := oParser:Parse(cExpression)

   IF oResult:isKindOf("SR_BooleanExpression") .AND. oResult:oExpression:GetType() != "L"
      cContext := oResult:cContext
      oResult := oResult:oExpression
      oResult:cContext := cContext
   ENDIF

RETURN oResult

FUNCTION SR_cPattern(cString)

   LOCAL item
   LOCAL aSpecialChars := ".+-*/^$()#"

   FOR EACH item IN aSpecialChars
       cString := StrTran(cString, item, "\" + item)
   NEXT

RETURN cString

///////////////////////////////////////////////////////////////////////////////
