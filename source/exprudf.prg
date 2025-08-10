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

FUNCTION cJoin(aArray, cString)

   LOCAL result := ""
   LOCAL i

   IF Len(aArray) > 0
      FOR i := 1 TO Len(aArray) - 1
         result += aArray[i] + cString
      NEXT i
      result += aArray[Len(aArray)]
   ENDIF

RETURN result

FUNCTION xSelect(aArray, bSelector)

   LOCAL newArray := Array(Len(aArray))

   AEval(aArray, {|x, n|newArray[n] := Eval(bSelector, x)})

RETURN newArray

FUNCTION xSelectMany(aArray, bSelector)

   LOCAL newArray := {}

   AEval(aArray, {|x|aAddRange(newArray, Eval(bSelector, x))})

RETURN newArray

FUNCTION aWhere(aArray, bPredicate)

   LOCAL item
   LOCAL newArray := {}

   FOR EACH item IN aArray
      IF Eval(bPredicate, item)
         AAdd(newArray, item)
      ENDIF
   NEXT

RETURN newArray

FUNCTION xFirst(aArray, bPredicate)

   LOCAL i := AScan(aArray, bPredicate)

   IF i == 0
      RETURN NIL
   ENDIF

RETURN aArray[i]

FUNCTION xFirstOrDefault(aArray)

   IF Len(aArray) == 0
      RETURN NIL
   ENDIF

RETURN aArray[1]

FUNCTION aDistinct(aArray, bSelector)

   LOCAL item
   LOCAL newArray := {}
   LOCAL ids := {}
   LOCAL id

   FOR EACH item IN aArray
      id := Eval(bSelector, item)
      IF !(AScan(ids, id) > 0)
         AAdd(ids, id)
         AAdd(newArray, item)
      ENDIF
   NEXT

RETURN newArray

PROCEDURE aAddRange(aArray1, aArray2)

   LOCAL item

   FOR EACH item IN aArray2
      AAdd(aArray1, item)
   NEXT

RETURN

PROCEDURE aAddDistinct(aArray1, xValue, bSelector)

   LOCAL id

   IF bSelector == NIL
      bSelector := {|x|x}
   ENDIF
   id := Eval(bSelector, xValue)
   IF AScan(aArray1, {|x|id == Eval(bSelector, x)}) == 0
      AAdd(aArray1, xValue)
   ENDIF

RETURN

PROCEDURE aAddRangeDistinct(aArray1, aArray2, bSelector)

   LOCAL item

   FOR EACH item IN aArray2
      aAddDistinct(aArray1, item, bSelector)
   NEXT

RETURN

PROCEDURE RemoveAll(aArray, bPredicate)

   LOCAL i

   FOR i := 1 TO Len(aArray)
      IF Eval(bPredicate, aArray[i])
          hb_ADel(aArray, i, .T.)
          i--
      ENDIF
   NEXT i

RETURN

FUNCTION aReplaceNilBy(aArray, xValue)
RETURN AEval(aArray, {|x, n|IIf(x == NIL, aArray[n] := xValue, NIL)})

///////////////////////////////////////////////////////////////////////////////

CLASS Dictionary

   HIDDEN:
   DATA aInternArray INIT {}

   EXPORTED:
   METHOD aAdd(xKey, xValue, nMode)

   EXPORTED:
   METHOD xValue(xKey)

   EXPORTED:
   METHOD Remove(xKey)

   EXPORTED:
   METHOD GetKeyValuePair(xKey)

   EXPORTED:
   METHOD At(nIndex)

   EXPORTED:
   ACCESS nLength INLINE Len(::aInternArray)

   EXPORTED:
   METHOD SetValue(xKey, xValue)

   EXPORTED:
   METHOD nIndexOfKey(xKey)

   EXPORTED:
   METHOD Clear()

   EXPORTED:
   METHOD lContainsKey(xKey)

ENDCLASS

// nMode = 1 : If the key exist, an exception is thrown
// nMode = 2 : If the key exist, the method does nothing
// nMode = 3 : If the key exist, the value is replaced
METHOD aAdd(xKey, xValue, nMode) CLASS Dictionary

   LOCAL lContainsKey := ::lContainsKey(xKey)

   IF !(AScan({1, 2, 3}, nMode) > 0)
      nMode := 1
   ENDIF
   DO CASE
   CASE !lContainsKey
      AAdd(::aInternArray, KeyValuePair():new(xKey, xValue))
   CASE nMode == 1 .AND. lContainsKey
      _SR_Throw(ErrorNew(, , , , "The given key already exists in the dictionary"))
   CASE nMode == 3 .AND. lContainsKey
      ::SetValue(xKey, xValue)
   ENDCASE

RETURN NIL

METHOD GetKeyValuePair(xKey) CLASS Dictionary

   LOCAL result := xFirst(::aInternArray, {|y|y:xKey == xKey})

   IF result == NIL
      _SR_Throw(ErrorNew(, , , , "The key " + cstr(xKey) + " was not found."))
   ENDIF

RETURN result

METHOD At(nIndex) CLASS Dictionary
RETURN ::aInternArray[nIndex]

METHOD xValue(xKey) CLASS Dictionary
RETURN ::GetKeyValuePair(xKey):xValue

METHOD SetValue(xKey, xValue) CLASS Dictionary

   ::GetKeyValuePair(xKey):xValue := xValue

RETURN NIL

METHOD nIndexOfKey(xKey) CLASS Dictionary
RETURN AScan(::aInternArray, {|x|x:xKey == xKey})

METHOD Remove(xKey) CLASS Dictionary

   LOCAL nIndex := ::nIndexOfKey(xKey)

   IF nIndex == 0
      _SR_Throw(ErrorNew(, , , , "The key " + cstr(xKey) + " was not found."))
   ENDIF

RETURN hb_ADel(::aInternArray, nIndex, .T.)

METHOD Clear() CLASS Dictionary

   ::aInternArray := {}

RETURN NIL

METHOD lContainsKey(xKey) CLASS Dictionary
RETURN ::nIndexOfKey(xKey) > 0

///////////////////////////////////////////////////////////////////////////////

CLASS KeyValuePair

   EXPORTED:
   DATA xKey readonly

   DATA xValue

   METHOD new(pKey, pValue)

ENDCLASS

METHOD new(pKey, pValue) CLASS KeyValuePair

   ::xKey := pKey
   ::xValue := pValue

RETURN SELF

///////////////////////////////////////////////////////////////////////////////

FUNCTION ToDictionary(aArray, bKeySelector)

   LOCAL item
   LOCAL result := Dictionary():new()

   FOR EACH item IN aArray
      result:aadd(Eval(bKeySelector, item), item)
   NEXT

RETURN result

FUNCTION GetFileName(cPath)

   LOCAL aGroups
   LOCAL cRegEx := "^(?:(\w:(?:\\|/)?)((?:.+?(?:\\|/))*))?(\w+?)(\.\w+)?$"

   IF HB_RegExMatch(cRegEx, cPath, .F.)
      aGroups := HB_RegExAtX(cRegEx, cPath)
      RETURN aGroups[4, 1]
   ELSE
      _SR_Throw(ErrorNew(, , , , cPath + " is not a valid path"))
   ENDIF

RETURN NIL

///////////////////////////////////////////////////////////////////////////////
