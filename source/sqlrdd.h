//
// SQLRDD C Header
// Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
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

#ifndef SQLRDD_H
#define SQLRDD_H

// TODO: to be revised
#if _MSC_VER >= 1900
#pragma comment(lib, "legacy_stdio_definitions.lib")
#endif

#include "compat.h"
#include <hbsetup.h>
#include <hbapi.h>
#include <hbapirdd.h>
#include <hbapiitm.h>
#include "sqlrdd.ch"

#define SUPERTABLE (&sqlrddSuper)

// SQL WORKAREA

typedef struct _SQLAREA
{
  AREA area;

  //  SQLRDD's additions to the workarea structure
  //
  //  Warning: The above section MUST match WORKAREA exactly!  Any
  //  additions to the structure MUST be added below
  PHB_CODEPAGE cdPageCnv; // Area's codepage convert pointer
  char *szDataFileName;   // file name
  HB_LONG hOrdCurrent;    // current index order
  HB_BOOL shared;
  HB_BOOL readonly;      // only SELECT allowed
  HB_BOOL creating;      // HB_TRUE when creating table
  HB_BOOL firstinteract; // HB_TRUE when workarea was not used yet
  HB_BOOL isam;          // ISAM Simulator ?
  HB_BOOL wasdel;
  HB_BOOL initialized; // Workarea Initialization done
  HB_BOOL sqlfilter;   // SET FILTER converted to SQL

  PHB_ITEM oWorkArea;  // SQL Workarea object
  PHB_ITEM aInfo;      // Status array
  PHB_ITEM aBuffer;    // Record buffer
  PHB_ITEM aOrders;    // Indexes
  PHB_ITEM aStruct;    // Table xBase structure
  PHB_ITEM aLocked;    // Locked lines
  PHB_ITEM aCreate;    // Structure received by dbCreate()
  PHB_ITEM aCache;     // Workarea recordset cache
  PHB_ITEM aOldBuffer; // Last workarea buffer
  PHB_ITEM aEmptyBuff; // Empty buffer to be in eof()+1
  PHB_ITEM aSelectList;

  HB_ULONG ulhRecno;   // Recno position in field list
  HB_ULONG ulhDeleted; // Deleted position in field list

  int *uiBufferIndex;   // Field offset in fields array
  int *uiFieldList;     // Keeps a field list for SELECT statements
  int iFieldListStatus; // field list status - see sqlprototypes.h

  LPDBRELINFO lpdbPendingRel; // Pointer to parent rel struct
  char editMask[MAX_FIELDS];  // Flags if a column was updated - must be cleared on every GO_COLD - USED BY ODBCRDD

} SQLAREA;

typedef SQLAREA *LPSQLAREA;

#ifndef SQLAREAP
#define SQLAREAP LPSQLAREA
#endif

// prototypes

void commonError(AREAP ThisDb, HB_USHORT uiGenCode, HB_USHORT uiSubCode, char *filename);

#endif // SQLRDD_H
