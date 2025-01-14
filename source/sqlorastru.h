//
// This program is free software; you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation; either version 2, or (at your option)
// any later version.
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

#ifndef _SQL_ORASTRU_H
#define _SQL_ORASTRU_H

#include "compat.h"

#include "sqlrddsetup.ch"
#include "sqlprototypes.h"
#include "sqlodbc.ch"
#include "ocilib.h"

#if !defined(__GNUC__) && defined(WIN32)
#define inline __inline

#endif

#ifdef SQLORA2
typedef struct _ORA_BIND_COLS2
{
  char *col_name;
  char *bindname;
  int iType;
  short sVal;
  double dValue;
  unsigned int ulValue;
  char sDate[7];
  HB_LONGLONG iValue;
  HB_LONGLONG lValue;
  OCI_Date *date;
  int iFieldSize;
} ORA_BIND_COLS2;

#else
typedef struct _ORA_BIND_COLS
{
  char *col_name;
  char *bindname;
  int iType;
  short sVal;
  double dValue;
  unsigned int ulValue;
  char sDate[7];
  HB_LONGLONG iValue;
  HB_LONGLONG lValue;
  OCI_Date *date;
  int iFieldSize;
} ORA_BIND_COLS;
#endif

typedef struct _OCI_ORASESSION
{
  OCI_Connection *cn;
  OCI_Statement *stmt;
  OCI_Statement *stmtParamRes;
  OCI_Resultset *rs;
  int iStatus; // Execution return value
  int numcols; // Result set columns
  char server_version[1024];
#ifdef SQLORA2
  ORA_BIND_COLS2 *pLink;
#else
  ORA_BIND_COLS *pLink;
#endif
  unsigned int ubBindNum;
} OCI_ORASESSION;
typedef OCI_ORASESSION *POCI_ORASESSION;

#endif