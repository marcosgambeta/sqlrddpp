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

#ifndef ORACLE_CH
#define ORACLE_CH

#define OCI_SUCCESS                0        // maps to SQL_SUCCESS of SAG CLI
#define OCI_SUCCESS_WITH_INFO      1        // maps to SQL_SUCCESS_WITH_INFO
#define OCI_RESERVED_FOR_INT_USE   200      // reserved
#define OCI_NO_DATA                100      // maps to SQL_NO_DATA
#define OCI_ERROR                  -1       // maps to SQL_ERROR
#define OCI_INVALID_HANDLE         -2       // maps to SQL_INVALID_HANDLE
#define OCI_NEED_DATA              99       // maps to SQL_NEED_DATA
#define OCI_STILL_EXECUTING        -3123    // OCI would block error
#define OCI_CONTINUE               -24200   // Continue with the body of the OCI function

#define SQL_ERROR                  OCI_ERROR
#define SQL_INVALID_HANDLE         OCI_INVALID_HANDLE
#define SQL_NEED_DATA              OCI_NEED_DATA
#define SQL_NO_DATA_FOUND          OCI_NO_DATA
#define SQL_SUCCESS                OCI_SUCCESS
#define SQL_SUCCESS_WITH_INFO      OCI_SUCCESS_WITH_INFO
#define SQL_DROP                   OCI_SUCCESS_WITH_INFO

#endif // ORACLE_CH
