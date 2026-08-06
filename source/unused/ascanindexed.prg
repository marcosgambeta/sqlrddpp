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

// NOTE: The aScanIndexed static function is not used in the SQLRDD source code. So,
// I am preserving the code here. If really necessary, the function can be reintroduced
// in the library. [MAG]

// static variables used only in STATIC FUNCTION aScanIndexed(...) (static function not used)
#ifdef __XHARBOUR__
// NOTE: to avoid warning about variable declared but not used in function.
STATIC s_ItP11 := NIL
STATIC s_ItP14 := NIL
STATIC s_ItP2 := NIL
STATIC s_ItP3 := NIL
#else
STATIC s_ItP11
STATIC s_ItP14
STATIC s_ItP2
STATIC s_ItP3
#endif

STATIC FUNCTION aScanIndexed(aVet, nPos, uKey, lSoft, nLen, lFound) // static function not used

   LOCAL nRet := 0
   LOCAL first
   LOCAL last
   LOCAL mid
   LOCAL closest
   LOCAL icomp
   LOCAL exec
   LOCAL nRegress

   exec := HB_IsBlock(nPos)
   first := 1
   last := Len(aVet)
   mid := Int((first + last) / 2)
   lFound := .T.

   closest := mid

   DO WHILE last > 0

      s_ItP11 := nPos
      s_ItP14 := nPos
      s_ItP2 := uKey
      s_ItP3 := nLen

      icomp := sr_ItemCmp(IIf(exec, Eval(s_ItP11, mid, aVet), aVet[mid, s_ItP14]), s_ItP2, s_ItP3)

      IF icomp == 0
         nRegress := mid
         DO WHILE --nRegress > 0
            IF sr_ItemCmp(IIf(exec, Eval(s_ItP11, nRegress, aVet), aVet[nRegress, s_ItP14]), s_ItP2, s_ItP3) != 0
               EXIT
            ENDIF
         ENDDO
         RETURN (++nRegress)
      ELSE
         IF first == last
            EXIT
         ELSEIF first == (last - 1)

            s_ItP11 := nPos
            s_ItP14 := nPos
            s_ItP2 := uKey
            s_ItP3 := nLen

            IF sr_ItemCmp(IIf(exec, Eval(s_ItP11, last, aVet), aVet[last, s_ItP14]), s_ItP2, s_ItP3) == 0
               nRegress := last
               DO WHILE --nRegress > 0
                  IF sr_ItemCmp(IIf(exec, Eval(s_ItP11, nRegress, aVet), aVet[nRegress, s_ItP14]), s_ItP2, s_ItP3) != 0
                     EXIT
                  ENDIF
               ENDDO
               RETURN (++nRegress)
            ENDIF
            EXIT
         ENDIF

         IF icomp > 0
            last := mid
            closest := mid
         ELSE
            first := mid
            closest := first
         ENDIF

         mid := Int((last + first) / 2)

      ENDIF

   ENDDO

   IF lSoft .AND. Len(aVet) > 0
      lFound := .F.
      IF Len(aVet) > mid
         nRet := mid + 1    // Soft seek should stop at immediatelly superior item
      ELSE
         nRet := mid
      ENDIF
   ENDIF

RETURN nRet
