//
// SQLRDD Firebird native constants
// Copyright (c) 2004 - Marcelo Lombardo  <lombardo@uol.com.br>
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

#ifndef FIREBIRD5_CH
#define FIREBIRD5_CH

#define IB_SQL_TEXT                           452
#define IB_SQL_VARYING                        448
#define IB_SQL_SHORT                          500
#define IB_SQL_LONG                           496
#define IB_SQL_FLOAT                          482
#define IB_SQL_DOUBLE                         480
#define IB_SQL_D_FLOAT                        530
#define IB_SQL_TIMESTAMP                      510
#define IB_SQL_BLOB                           520
#define IB_SQL_ARRAY                          540
#define IB_SQL_QUAD                           550
#define IB_SQL_TYPE_TIME                      560
#define IB_SQL_TYPE_DATE                      570
#define IB_SQL_INT64                          580
#define IB_SQL_DATE                           IB_SQL_TIMESTAMP
#define IB_SQL_BOOLEAN                        32764

#define IB_DIALECT_V5                         1
#define IB_DIALECT_V6_TRANSITION              2
#define IB_DIALECT_V6                         3
#define IB_DIALECT_CURRENT                    IB_DIALECT_V6

#endif // FIREBIRD5_CH
