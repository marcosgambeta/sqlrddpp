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
#include "hbclass.ch"

**************************************************
function cJoin(aArray, cString)
	local result := "", i
	if (len(aArray)>0)
		for i:=1 to len(aArray) - 1 
			result += aArray[i]	+ cString
		next i
		result += aArray[len(aArray)]	
	endif
return result

**************************************************
function xSelect(aArray, bSelector)
	local newArray := array(len(aArray))
	aeval(aArray, {|x,n| newArray[n] := eval(bSelector, x)})
return newArray
	
**************************************************
function xSelectMany(aArray, bSelector)
	local newArray := {}
	aeval(aArray, {|x| aAddRange(newArray, eval(bSelector, x))})
return newArray	
	
**************************************************
function aWhere(aArray, bPredicate)	
	local newArray := {}, i
	for i:=1 to len(aArray)
		if(eval(bPredicate, aArray[i]))
			aadd(newArray, aArray[i])
		endif
	next i
return newArray	
	
**************************************************
function xFirst(aArray, bPredicate)
	local i := ascan(aArray, bPredicate)
	if(i==0)
		return nil
	endif
return aArray[i]
	
**************************************************
function xFirstOrDefault(aArray)
	if(len(aArray) == 0)
		return nil
	endif
return aArray[1]	
		
**************************************************
function aDistinct(aArray, bSelector)	
	local newArray := {}, ids := {}, i, id
	for i:=1 to len(aArray)
		if (!(id := eval(bSelector, aArray[i])) in ids)
			aadd(ids, id)
			aadd(newArray, aArray[i])
		endif
	next i
return newArray	
	
**************************************************
PROCEDURE aAddRange(aArray1, aArray2)
   LOCAL i
	for i:=1 to len(aArray2)
		aadd(aArray1, aArray2[i]) 
	next i
RETURN

**************************************************
PROCEDURE aAddDistinct(aArray1, xValue, bSelector)
	local id
	if(bSelector == nil)
		bSelector = {|x| x}
	endif
	id := eval(bSelector, xValue)
	if(ascan(aArray1, {|x| id == eval(bSelector, x)})==0)
		aadd(aArray1, xValue)
	endif
return
	
**************************************************
PROCEDURE aAddRangeDistinct(aArray1, aArray2, bSelector)
   LOCAL i
	for i:=1 to len(aArray2)
		aAddDistinct(aArray1, aArray2[i], bSelector) 
	next i
return	

**************************************************
PROCEDURE RemoveAll(aArray, bPredicate)
	local i
	for i:=1 to len(aArray)
		if(eval(bPredicate, aArray[i]))
			 adel(aArray, i, .T.)
			 i--
		endif
	next i		
return

**************************************************
function aReplaceNilBy(aArray, xValue)
return aeval(aArray, {|x,n| if(x == nil, aArray[n] := xValue, )})	

**************************************************
class Dictionary
	HIDDEN:
	data aInternArray init {}
	
	EXPORTED:
	method aAdd(xKey, xValue, nMode)

	EXPORTED:
	method xValue(xKey)

	EXPORTED:
	method Remove(xKey)
		
	EXPORTED:
	method GetKeyValuePair(xKey)
			
	EXPORTED:
	method At(nIndex)
		
	EXPORTED:
	access nLength inline len(::aInternArray)  
	
	EXPORTED:
	method SetValue(xKey, xValue)

	EXPORTED:
	method nIndexOfKey(xKey)
	
	EXPORTED:
	method Clear()
	
	EXPORTED:
	method lContainsKey()	
endclass

//nMode = 1 : If the key exist, an exception is thrown
//nMode = 2 : If the key exist, the method does nothing
//nMode = 3 : If the key exist, the value is replaced
method aAdd(xKey, xValue, nMode) class Dictionary
	local lContainsKey := ::lContainsKey(xKey)
	if (!nMode in {1,2,3})
		nMode = 1
	endif
	do case
		case (!lContainsKey)
			aadd(::aInternArray, KeyValuePair():new(xKey, xValue))
		case (nMode == 1 .and. lContainsKey)
			Throw(ErrorNew(,,,,"The given key already exists in the dictionary"))
		case (nMode == 3 .and. lContainsKey)
			::SetValue(xKey, xValue)
	endcase
return Nil

method GetKeyValuePair(xKey)
	local result := xFirst(::aInternArray, {|y| y:xKey == xKey})
	if(result == nil)
		Throw(ErrorNew(,,,,"The key " + cstr(xKey) + " was not found."))
	endif		
return result

method At(nIndex)		
return ::aInternArray[nIndex]

method xValue(xKey) class Dictionary
return ::GetKeyValuePair(xKey):xValue

method SetValue(xKey, xValue)
	::GetKeyValuePair(xKey):xValue = xValue
return Nil	
	
method nIndexOfKey(xKey)
return ascan(::aInternArray, {|x| x:xKey == xKey})

method Remove(xKey) class Dictionary
	local nIndex := ::nIndexOfKey(xKey)
	if(nIndex == 0)
		Throw(ErrorNew(,,,,"The key " + cstr(xKey) + " was not found."))
	endif
return adel(::aInternArray, nIndex, .T.)

method Clear() class Dictionary
	::aInternArray = {}
return Nil

method lContainsKey(xKey) class Dictionary
return ::nIndexOfKey(xKey) > 0

**************************************************
class KeyValuePair
	EXPORTED:
	data xKey readonly
	
	data xValue
	
	method new(pKey, pValue)
endclass

method new(pKey, pValue)
	::xKey = pKey
	::xValue = pValue
return self

**************************************************
function ToDictionary(aArray, bKeySelector)
	local result := Dictionary():new(), i
	for i:=1 to len(aArray)
		result:aadd(eval(bKeySelector, aArray[i]), aArray[i])
	next i
return result

**************************************************
function GetFileName(cPath)
   LOCAL aGroups
	local cRegEx := "^(?:(\w:(?:\\|/)?)((?:.+?(?:\\|/))*))?(\w+?)(\.\w+)?$"
    if (HB_RegExMatch(cRegEx, cPath, .F.)) 
    	aGroups = HB_RegExAtX(cRegEx, cPath)
		return aGroups[4,1]
	else
		Throw(ErrorNew(,,,, cPath + " is not a valid path"))		
    endif	
RETURN Nil    
