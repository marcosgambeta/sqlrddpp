//
// SQLRDD - Harbour/xHarbour compatibility definitions
// (c) copyright xHarbour.com Inc. http://www.xHarbour.com
// Author: Przemyslaw Czerpak (druzus/at/poczta.onet.pl)
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

#ifndef _SQL_RDD_COMPAT_H
#define _SQL_RDD_COMPAT_H

#include <hbapi.h>
#include <hbapiitm.h>
#include <hbapirdd.h>
#include <hbapierr.h>
#include <hbset.h>
#include <hbvm.h>
#include <hbstack.h>
#include <hbdate.h>
#include <hbapicls.h>

HB_EXTERN_BEGIN

extern void sr_TraceLog(const char *sFile, const char *sTraceMsg, ...);

HB_EXTERN_END

// typedef HB_BYTE            BYTE;
// typedef HB_SCHAR           SCHAR;
// typedef HB_SHORT           SHORT;
// typedef HB_USHORT          USHORT;
// typedef HB_UINT            UINT;
// typedef HB_LONG            LONG;
// typedef HB_ULONG           ULONG;
// typedef HB_BOOL            BOOL;
// typedef HB_LONGLONG        LONGLONG;

// #define EVALINFO           HB_EVALINFO

// #ifndef FALSE
//    #define FALSE           0
// #endif
// #ifndef TRUE
//    #define TRUE               (!0)
// #endif

// #define ISBYREF(x)         HB_ISBYREF(x)
// #define ISCHAR(x)          HB_ISCHAR(x)
// #define ISNUM(x)           HB_ISNUM(x)
// #define ISLOG(x)           HB_ISLOG(x)

// #define hb_retcAdopt( szText )               hb_retc_buffer( (szText) )
// #define hb_retclenAdopt( szText, ulLen )     hb_retclen_buffer( (szText), (ulLen) )
// #define hb_retcStatic( szText )              hb_retc_const( (szText) )
// #define hb_storclenAdopt                     hb_storclen_buffer
// #define hb_itemPutCRawStatic                 hb_itemPutCLConst
// #define hb_itemForwardValue( dst, src )      hb_itemMove( dst, src )
// #define hb_cdppage()                         hb_vmCDP()

// #define hb_dynsymLock()
// #define hb_dynsymUnlock()

#endif // _SQL_RDD_COMPAT_H
