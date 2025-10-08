//
// SQLRDD Main File
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

#include "sqlrddpp.h"
#include "compat.h"
#include <hbapilng.h>

#include "sqlrdd.h"
#include "msg.ch"
#include <rddsys.ch>
#include "sqlrddsetup.ch"
#include "sqlprototypes.h"

// #undef HB_IS_OBJECT
// #define HB_IS_OBJECT(p)  ( ( p ) && HB_IS_OF_TYPE(p, HB_IT_OBJECT) && ( p )->item.asArray.value->uiClass != 0 )

#include <ctype.h>
#include <assert.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <sys/types.h>
#include <sys/wait.h>
#endif

#undef HB_TRACE
#define HB_TRACE(x, y)

static RDDFUNCS sqlrddSuper;

void startSQLRDDSymbols(void);

static HB_BOOL ProcessFields(SQLAREAP ThisDb);
static HB_BOOL SetFields(SQLAREAP ThisDb);

// static PHB_ITEM loadTag(SQLAREAP thiswa, LPDBORDERINFO pInfo, HB_LONG * lorder);
HB_EXTERN_BEGIN
PHB_ITEM loadTagDefault(SQLAREAP thiswa, LPDBORDERINFO pInfo, HB_LONG *lorder);
HB_EXTERN_END

HB_FUNC_EXTERN(SR_END);
HB_FUNC_EXTERN(SR_INIT);
HB_FUNC_EXTERN(__SR_STARTSQL);

//------------------------------------------------------------------------

static PHB_DYNS s_pSym_SQLGOBOTTOM;
static PHB_DYNS s_pSym_SQLGOTO;
static PHB_DYNS s_pSym_SQLGOTOP;
static PHB_DYNS s_pSym_SQLSEEK;
static PHB_DYNS s_pSym_SETBOF;
static PHB_DYNS s_pSym_SQLDELETEREC;
static PHB_DYNS s_pSym_SQLFLUSH;
static PHB_DYNS s_pSym_SQLRECALL;
static PHB_DYNS s_pSym_SQLCLOSE;
static PHB_DYNS s_pSym_SQLCREATE;
static PHB_DYNS s_pSym_SQLOPEN;
static PHB_DYNS s_pSym_SQLOPENALLINDEXES;
static PHB_DYNS s_pSym_SQLPACK;
static PHB_DYNS s_pSym_SQLZAP;
static PHB_DYNS s_pSym_SQLORDERLISTADD;
static PHB_DYNS s_pSym_SQLORDERLISTCLEAR;
static PHB_DYNS s_pSym_SQLORDERLISTFOCUS;
static PHB_DYNS s_pSym_SQLORDERCREATE;
static PHB_DYNS s_pSym_SQLORDERDESTROY;
static PHB_DYNS s_pSym_SQLORDERCONDITION;
static PHB_DYNS s_pSym_SQLORDERLISTNUM;
static PHB_DYNS s_pSym_SQLSETSCOPE;
static PHB_DYNS s_pSym_SQLLOCK;
static PHB_DYNS s_pSym_SQLUNLOCK;
static PHB_DYNS s_pSym_SQLDROP;
static PHB_DYNS s_pSym_SQLEXISTS;
static PHB_DYNS s_pSym_SQLKEYCOUNT;
static PHB_DYNS s_pSym_SQLRECSIZE;
static PHB_DYNS s_pSym_WRITEBUFFER;
static PHB_DYNS s_pSym_READPAGE;
static PHB_DYNS s_pSym_STABILIZE;
static PHB_DYNS s_pSym_NORMALIZE;
static PHB_DYNS s_pSym_SQLGETVALUE;
static PHB_DYNS s_pSym_SQLSETFILTER;
static PHB_DYNS s_pSym_SQLCLEARFILTER;
static PHB_DYNS s_pSym_SQLFILTERTEXT;

static PHB_DYNS s_pSym_SQLINIT = SR_NULLPTR;
static PHB_DYNS s_pSym_SQLEXIT = SR_NULLPTR;
static PHB_DYNS s_pSym_WORKAREA = SR_NULLPTR;

//------------------------------------------------------------------------

void fixCachePointer(HB_LONG *lPosCache)
{
  if (*lPosCache < 1) {
    *lPosCache += (CAHCE_PAGE_SIZE * 3);
  } else if (*lPosCache > (CAHCE_PAGE_SIZE * 3)) {
    *lPosCache -= (CAHCE_PAGE_SIZE * 3);
  }
}

//------------------------------------------------------------------------

HB_FUNC(SR_FIXCACHEPOINTER)
{
  HB_LONG lPos = hb_parnl(1);
  fixCachePointer(&lPos);
  hb_retnl(lPos);
}

//------------------------------------------------------------------------

HB_BOOL isCachePointerInRange(HB_LONG lPosCache, HB_LONG lBegin, HB_LONG lEnd)
{
  if (lBegin == lEnd) {
    return lPosCache == lBegin;
  }
  if (lBegin < lEnd) {
    return (lPosCache >= lBegin && lPosCache <= lEnd);
  }
  return (lPosCache >= lBegin || lPosCache <= lEnd);
}

//------------------------------------------------------------------------

HB_LONG searchCacheFWD(SQLAREAP thiswa, HB_LONG lPreviousCacheStatus)
{
  HB_LONG lBegin, lEnd;
  HB_LONG lPosCache = hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE);

  if (!lPosCache) {
    return 0;
  }

  lBegin = hb_arrayGetNL(thiswa->aInfo, AINFO_NCACHEBEGIN);
  lEnd = hb_arrayGetNL(thiswa->aInfo, AINFO_NCACHEEND);

  if (lPreviousCacheStatus) {
    lPosCache++;
  }
  fixCachePointer(&lPosCache);

  while (isCachePointerInRange(lPosCache, lBegin, lEnd)) {
    if (!HB_IS_NIL(hb_arrayGetItemPtr(thiswa->aCache, lPosCache))) {
      return lPosCache;
    }
    lPosCache++;
    fixCachePointer(&lPosCache);
  }
  return 0;
}

//------------------------------------------------------------------------

HB_LONG searchCacheBWD(SQLAREAP thiswa, HB_LONG lPreviousCacheStatus)
{
  HB_LONG lBegin, lEnd;
  HB_LONG lPosCache = hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE);

  if (!lPosCache) {
    return 0;
  }

  lBegin = hb_arrayGetNL(thiswa->aInfo, AINFO_NCACHEBEGIN);
  lEnd = hb_arrayGetNL(thiswa->aInfo, AINFO_NCACHEEND);

  if (lPreviousCacheStatus) {
    lPosCache--;
  }
  fixCachePointer(&lPosCache);

  while (isCachePointerInRange(lPosCache, lBegin, lEnd)) {
    if (!HB_IS_NIL(hb_arrayGetItemPtr(thiswa->aCache, lPosCache))) {
      return lPosCache;
    }
    lPosCache--;
    fixCachePointer(&lPosCache);
  }
  return 0;
}

//------------------------------------------------------------------------

void readCachePageFWD(SQLAREAP thiswa)
{
  PHB_ITEM pOrd = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pDel = hb_itemNew(SR_NULLPTR);
  hb_itemPutNL(pOrd, ORD_DIR_FWD);
  hb_itemPutL(pDel, thiswa->wasdel);
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_READPAGE, 2, pOrd, pDel);
  hb_itemRelease(pOrd);
  hb_itemRelease(pDel);
}

//------------------------------------------------------------------------

void readCachePageBWD(SQLAREAP thiswa)
{
  PHB_ITEM pOrd = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pDel = hb_itemNew(SR_NULLPTR);
  hb_itemPutNL(pOrd, ORD_DIR_BWD);
  hb_itemPutL(pDel, thiswa->wasdel);
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_READPAGE, 2, pOrd, pDel);
  hb_itemRelease(pOrd);
  hb_itemRelease(pDel);
}

//------------------------------------------------------------------------

void setCurrentFromCache(SQLAREAP thiswa, HB_LONG lPos)
{
  HB_SIZE nPos, nLen;
  PHB_ITEM pCacheRecord, pCol;

  hb_arraySetNL(thiswa->aInfo, AINFO_NPOSCACHE, lPos);

  pCacheRecord = (PHB_ITEM)hb_arrayGetItemPtr(thiswa->aCache, lPos);

  pCol = hb_itemNew(SR_NULLPTR);

  for (nPos = 1, nLen = hb_arrayLen(pCacheRecord); nPos <= nLen; nPos++) {

    hb_arrayGet(pCacheRecord, nPos, pCol);
    hb_arraySet(thiswa->aOldBuffer, nPos, pCol);

    if (nPos == thiswa->ulhRecno) {
      hb_arraySet(thiswa->aInfo, AINFO_RECNO, pCol);
    }

    if (nPos == thiswa->ulhDeleted) {
      const char *deleted = hb_itemGetCPtr(pCol);
      if (*deleted == 'T' || *deleted == '*') {
        hb_arraySetL(thiswa->aInfo, AINFO_DELETED, HB_TRUE);
      } else {
        hb_arraySetL(thiswa->aInfo, AINFO_DELETED, HB_FALSE);
      }
    }
    hb_arraySetForward(thiswa->aBuffer, nPos, pCol);
  }

  if (thiswa->ulhDeleted == 0) {
    hb_arraySetL(thiswa->aInfo, AINFO_DELETED, HB_FALSE);
  }

  hb_itemRelease(pCol);
}

//------------------------------------------------------------------------

void sqlGetBufferFromCache2(SQLAREAP thiswa, HB_LONG lPos)
{
  HB_SIZE nPos, nLen;
  PHB_ITEM pCacheRecord, pCol;

  pCacheRecord = (PHB_ITEM)hb_arrayGetItemPtr(thiswa->aCache, lPos);

  pCol = hb_itemNew(SR_NULLPTR);

  for (nPos = 1, nLen = hb_arrayLen(pCacheRecord); nPos <= nLen; nPos++) {
    hb_arrayGet(pCacheRecord, nPos, pCol);
    hb_arraySet(thiswa->aOldBuffer, nPos, pCol);
    if (nPos == thiswa->ulhRecno) {
      hb_arraySet(thiswa->aInfo, AINFO_RECNO, pCol);
    }
    if (nPos == thiswa->ulhDeleted) {
      const char *deleted = hb_itemGetCPtr(pCol);
      if (*deleted == 'T' || *deleted == '*') {
        hb_arraySetL(thiswa->aInfo, AINFO_DELETED, HB_TRUE);
      } else {
        hb_arraySetL(thiswa->aInfo, AINFO_DELETED, HB_FALSE);
      }
    }
    hb_arraySetForward(thiswa->aBuffer, nPos, pCol);
  }

  if (thiswa->ulhDeleted == 0) {
    hb_arraySetL(thiswa->aInfo, AINFO_DELETED, HB_FALSE);
  }

  hb_itemRelease(pCol);
  hb_arraySetNL(thiswa->aInfo, AINFO_NPOSCACHE, lPos);
}

//------------------------------------------------------------------------

static void sqlGetCleanBuffer(SQLAREAP thiswa)
{
  HB_SIZE nPos, nLen;
  PHB_ITEM pCol;

  pCol = hb_itemNew(SR_NULLPTR);
  for (nPos = 1, nLen = hb_arrayLen(thiswa->aEmptyBuff); nPos <= nLen; nPos++) {
    hb_arrayGet(thiswa->aEmptyBuff, nPos, pCol);
    hb_arraySet(thiswa->aOldBuffer, nPos, pCol);
    hb_arraySetForward(thiswa->aBuffer, nPos, pCol);
  }
  hb_arraySetL(thiswa->aInfo, AINFO_DELETED, HB_FALSE);
  hb_arraySetL(thiswa->aInfo, AINFO_EOF, HB_TRUE);
  hb_arrayGet(thiswa->aInfo, AINFO_RCOUNT, pCol);
  hb_itemPutNL(pCol, hb_itemGetNL(pCol) + 1);
  hb_arraySetForward(thiswa->aInfo, AINFO_RECNO, pCol);
  hb_itemRelease(pCol);
  if (!thiswa->isam) {
    hb_arraySetNL(thiswa->aInfo, AINFO_NPOSCACHE, hb_arrayLen(thiswa->aCache) + 1);
  }
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlBof(SQLAREAP thiswa, HB_BOOL *bof)
{
  if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  }
  thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);
  *bof = thiswa->area.fBof;

  // sr_TraceLog(SR_NULLPTR, "sqlBof, returning %i\n", thiswa->area.fBof);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlEof(SQLAREAP thiswa, HB_BOOL *eof)
{
  if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  }

  if (hb_arrayGetL(thiswa->aInfo, AINFO_ISINSERT) && hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
    *eof = HB_FALSE;
  } else {
    thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
    *eof = thiswa->area.fEof;
  }

  // sr_TraceLog(SR_NULLPTR, "sqlEof, returning %i\n", thiswa->area.fEof);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlFound(SQLAREAP thiswa, HB_BOOL *found)
{
  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  }

  thiswa->area.fFound = hb_arrayGetL(thiswa->aInfo, AINFO_FOUND);
  *found = thiswa->area.fFound;

  // sr_TraceLog(SR_NULLPTR, "sqlFound, returning %i\n", thiswa->area.fFound);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlGoBottom(SQLAREAP thiswa)
{
  HB_LONG leof;
  PHB_ITEM eofat;

  eofat = hb_itemNew(SR_NULLPTR);

  // sr_TraceLog(SR_NULLPTR, "sqlGoBottom\n");

  thiswa->lpdbPendingRel = SR_NULLPTR;
  thiswa->firstinteract = HB_FALSE;
  thiswa->wasdel = HB_FALSE;

  if (hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_WRITEBUFFER, 0);
  }

  leof = hb_arrayGetNL(thiswa->aInfo, AINFO_EOF_AT);

  if (hb_arrayGetNL(thiswa->aInfo, AINFO_EOF_AT)) {
    hb_itemPutNL(eofat, leof);
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGOTO, 1, eofat);
  } else {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGOBOTTOM, 0);
  }

  thiswa->area.fTop = HB_FALSE;
  thiswa->area.fBottom = HB_TRUE;
  thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);
  hb_itemRelease(eofat);

  SELF_SKIPFILTER(&thiswa->area, -1);

  if (thiswa->area.lpdbRelations) {
    return SELF_SYNCCHILDREN(&thiswa->area);
  } else {
    return HB_SUCCESS;
  }
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlGoTo(SQLAREAP thiswa, HB_LONG recno)
{
  PHB_ITEM pParam1;

  // sr_TraceLog(SR_NULLPTR, "sqlGoTo %i\n", recno);

  // Reset parent rel struct
  thiswa->lpdbPendingRel = SR_NULLPTR;
  thiswa->firstinteract = HB_FALSE;
  thiswa->wasdel = HB_FALSE;

  pParam1 = hb_itemPutNL(SR_NULLPTR, recno);
  if (hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_WRITEBUFFER, 0);
  }
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGOTO, 1, pParam1);
  hb_itemRelease(pParam1);

  thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlGoToId(SQLAREAP thiswa, PHB_ITEM pItem)
{

  HB_TRACE(HB_TR_DEBUG, ("sqlGoToId1(%p, %p)", thiswa, pItem));

  // sr_TraceLog(SR_NULLPTR, "sqlGoToId\n");

  thiswa->firstinteract = HB_FALSE;
  thiswa->wasdel = HB_FALSE;

  if (HB_IS_NUMERIC(pItem)) {
    return SELF_GOTO(&thiswa->area, hb_itemGetNL(pItem));
  } else {
    if (hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_WRITEBUFFER, 0);
    }

    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGOTO, 1, pItem);

    thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
    thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);

    return HB_SUCCESS;
  }
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlGoTop(SQLAREAP thiswa)
{
  HB_LONG lbof;

  // sr_TraceLog(SR_NULLPTR, "sqlGoTop\n");

  thiswa->lpdbPendingRel = SR_NULLPTR;
  thiswa->firstinteract = HB_FALSE;
  thiswa->wasdel = HB_FALSE;

  if (hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_WRITEBUFFER, 0);
  }

  lbof = hb_arrayGetNL(thiswa->aInfo, AINFO_BOF_AT);

  if (lbof) {
    PHB_ITEM pBOF = hb_itemPutNL(SR_NULLPTR, lbof);
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGOTO, 1, pBOF);
    hb_itemRelease(pBOF);
  } else {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGOTOP, 0);
  }

  thiswa->area.fTop = HB_TRUE;
  thiswa->area.fBottom = HB_FALSE;
  thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);

  SELF_SKIPFILTER(&thiswa->area, 1);

  if (thiswa->area.lpdbRelations) {
    return SELF_SYNCCHILDREN(&thiswa->area);
  } else {
    return HB_SUCCESS;
  }
}

//------------------------------------------------------------------------

int sqlKeyCompare(AREAP thiswa, PHB_ITEM pKey, HB_BOOL fExact)
{
  HB_LONG lorder = 0;
  PHB_ITEM pTag, pKeyVal, itemTemp;
  int iLimit, iResult = 0;
  HB_BYTE len1, len2;
  char *valbuf = SR_NULLPTR;
  const char *val1, *val2;

  // sr_TraceLog(SR_NULLPTR, "sqlKeyCompare\n");

  pTag = loadTagDefault((SQLAREAP)thiswa, SR_NULLPTR, &lorder);
  if (pTag) {
    if (((SQLAREAP)thiswa)->firstinteract) {
      SELF_GOTOP((AREAP)thiswa);
      ((SQLAREAP)thiswa)->firstinteract = HB_FALSE;
    }
    itemTemp = hb_itemArrayGet(pTag, INDEX_KEY_CODEBLOCK);
    if (HB_IS_NUMBER(itemTemp)) {
      pKeyVal = hb_itemArrayGet(((SQLAREAP)thiswa)->aBuffer, hb_arrayGetNL(pTag, INDEX_KEY_CODEBLOCK));
      len1 = (HB_BYTE)hb_strRTrimLen(hb_itemGetCPtr(pKeyVal), hb_itemGetCLen(pKeyVal), HB_FALSE) - 15;
      val1 = hb_itemGetCPtr(pKeyVal);
    } else {
      HB_EVALINFO info;
      hb_evalNew(&info, hb_itemArrayGet(pTag, INDEX_KEY_CODEBLOCK));
      pKeyVal = hb_evalLaunch(&info);
      hb_evalRelease(&info);
      len1 = (HB_BYTE)hb_itemGetCLen(pKeyVal);
      val1 = hb_itemGetCPtr(pKeyVal);
    }
    hb_itemRelease(itemTemp);
    hb_itemRelease(pTag);
  } else {
    return 0;
  }

  if (HB_IS_DATE(pKey)) {
    len2 = 8;
    valbuf = (char *)hb_xgrab(9);
    val2 = hb_itemGetDS(pKey, valbuf);
  } else if (HB_IS_NUMBER(pKey)) {
    PHB_ITEM pLen = hb_itemPutNL(SR_NULLPTR, (HB_LONG)len1);
    val2 = valbuf = hb_itemStr(pKey, pLen, SR_NULLPTR);
    len2 = (HB_BYTE)strlen(val2);
    hb_itemRelease(pLen);
  } else if (HB_IS_LOGICAL(pKey)) {
    len2 = 1;
    val2 = hb_itemGetL(pKey) ? "T" : "F";
  } else {
    len2 = (HB_BYTE)hb_itemGetCLen(pKey);
    val2 = hb_itemGetCPtr(pKey);
  }

  iLimit = (len1 > len2) ? len2 : len1;

  if (HB_IS_STRING(pKeyVal)) {
    if (iLimit > 0) {
      iResult = memcmp(val1, val2, iLimit);
    }

    if (iResult == 0) {
      if (len1 >= len2) {
        iResult = 1;
      } else if (len1 < len2 && fExact) {
        iResult = -1;
      }
    } else {
      iResult = 0;
    }
  } else {
    if (iLimit == 0 || (iResult = memcmp(val1, val2, iLimit)) == 0) {
      if (len1 >= len2) {
        iResult = 1;
      } else if (len1 < len2) {
        iResult = -1;
      }
    }
  }

  if (valbuf) {
    hb_xfree(valbuf);
  }

  hb_itemRelease(pKeyVal);

  return iResult;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlSeek(SQLAREAP thiswa, HB_BOOL bSoftSeek, PHB_ITEM pKey, HB_BOOL bFindLast)
{
  PHB_ITEM pNewKey = SR_NULLPTR, pItem, pItem2;
  HB_ERRCODE retvalue = HB_SUCCESS;

  // sr_TraceLog(SR_NULLPTR, "sqlSeek(%p, %d, %p, %d)", thiswa, bSoftSeek, pKey, bFindLast);

  thiswa->lpdbPendingRel = SR_NULLPTR;
  thiswa->firstinteract = HB_FALSE;
  thiswa->wasdel = HB_FALSE;

  pItem = hb_itemPutL(SR_NULLPTR, bSoftSeek);
  pItem2 = hb_itemPutL(SR_NULLPTR, bFindLast);

#ifndef HB_CDP_SUPPORT_OFF
  if (HB_IS_STRING(pKey)) {
    PHB_CODEPAGE cdpSrc = thiswa->cdPageCnv ? thiswa->cdPageCnv : hb_vmCDP();
    if (thiswa->area.cdPage && thiswa->area.cdPage != cdpSrc) {
      HB_SIZE nLen = hb_itemGetCLen(pKey);
      char *pszVal = hb_cdpnDup(hb_itemGetCPtr(pKey), &nLen, cdpSrc, thiswa->area.cdPage);
      pKey = pNewKey = hb_itemPutCLPtr(SR_NULLPTR, pszVal, nLen);
    }
  }
#endif

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLSEEK, 3, pKey, pItem, pItem2);

  thiswa->area.fFound = hb_arrayGetL(thiswa->aInfo, AINFO_FOUND);
  thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);
  thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);

  if ((hb_setGetDeleted() || thiswa->area.dbfi.itmCobExpr != SR_NULLPTR) && !thiswa->area.fEof) {
    retvalue = SELF_SKIPFILTER(&thiswa->area, (bFindLast ? -1 : 1));

    if (thiswa->area.fEof) {
      thiswa->area.fFound = HB_FALSE;
      hb_itemPutL(pItem, thiswa->area.fFound);
      hb_arraySetForward(thiswa->aInfo, AINFO_FOUND, pItem);
    } else {
      if (sqlKeyCompare(&thiswa->area, pKey, HB_FALSE) != 0) {
        thiswa->area.fFound = HB_TRUE;
        hb_itemPutL(pItem, thiswa->area.fFound);
        hb_arraySetForward(thiswa->aInfo, AINFO_FOUND, pItem);
      } else {
        thiswa->area.fFound = HB_FALSE;
        hb_itemPutL(pItem, thiswa->area.fFound);
        hb_arraySetForward(thiswa->aInfo, AINFO_FOUND, pItem);

        if (!bSoftSeek) {
          sqlGetCleanBuffer(thiswa);
        }
      }
    }
  }

  hb_itemRelease(pItem);
  hb_itemRelease(pItem2);
  if (pNewKey) {
    hb_itemRelease(pNewKey);
  }

  if (thiswa->area.lpdbRelations && retvalue == HB_SUCCESS) {
    return SELF_SYNCCHILDREN(&thiswa->area);
  } else {
    return retvalue;
  }
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlSkip(SQLAREAP thiswa, HB_LONG lToSkip)
{
  HB_ERRCODE ret;

  // sr_TraceLog(SR_NULLPTR, "sqlSkip %i\n", lToSkip);

  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  } else if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (SELF_GOCOLD(&thiswa->area) == HB_FAILURE) {
    return HB_FAILURE;
  }

  thiswa->area.fTop = thiswa->area.fBottom = HB_FALSE;

  ret = SUPER_SKIP(&thiswa->area, lToSkip); // This will call SKIPRAW

  hb_arraySetL(thiswa->aInfo, AINFO_BOF, thiswa->area.fBof);
  hb_arraySetL(thiswa->aInfo, AINFO_EOF, thiswa->area.fEof);
  thiswa->wasdel = HB_FALSE;

  return ret;
}

//------------------------------------------------------------------------

HB_ERRCODE sqlSkipFilter(SQLAREAP thiswa, HB_LONG lUpDown)
{
  HB_BOOL bOutOfRange, bDeleted;
  PHB_ITEM pResult;
  HB_ERRCODE uiError;

  // sr_TraceLog(SR_NULLPTR, "sqlSkipFilter %i\n", lUpDown);

  if (!hb_setGetDeleted() && thiswa->area.dbfi.itmCobExpr == SR_NULLPTR) {
    return HB_SUCCESS;
  }

  lUpDown = (lUpDown > 0 ? 1 : -1);
  bOutOfRange = HB_FALSE;

  while (HB_TRUE) {
    if (thiswa->area.fBof || thiswa->area.fEof) {
      bOutOfRange = HB_TRUE;
      break;
    }

    // SET FILTER TO
    if (thiswa->area.dbfi.itmCobExpr) {
      pResult = hb_vmEvalBlock(thiswa->area.dbfi.itmCobExpr);
      if (HB_IS_LOGICAL(pResult) && !hb_itemGetL(pResult)) {
        SELF_SKIPRAW(&thiswa->area, lUpDown);
        continue;
      }
    }

    // SET DELETED
    if (hb_setGetDeleted()) {
      SELF_DELETED(&thiswa->area, &bDeleted);
      if (bDeleted) {
        SELF_SKIPRAW(&thiswa->area, lUpDown);
        continue;
      }
    }
    break;
  }

  if (bOutOfRange) {
    if (lUpDown < 0) {
      thiswa->area.fEof = HB_FALSE;
      uiError = SELF_GOTOP(&thiswa->area);
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SETBOF, 0);
      thiswa->area.fBof = HB_TRUE;
    } else {
      thiswa->area.fBof = HB_FALSE;
      uiError = HB_SUCCESS;
    }
  } else {
    uiError = HB_SUCCESS;
  }

  return uiError;
}

//------------------------------------------------------------------------

static HB_ERRCODE ConcludeSkipraw(SQLAREAP thiswa, HB_LONG lToSkip)
{
#if 0
  if (lToSkip != 0) {
    thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);
    thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  }
#endif
  HB_SYMBOL_UNUSED(lToSkip);

  // Force relational movement in child WorkAreas

  if (thiswa->area.lpdbRelations) {
    return SELF_SYNCCHILDREN(&thiswa->area);
  } else {
    return HB_SUCCESS;
  }
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlSkipRaw(SQLAREAP thiswa, HB_LONG lToSkip)
{
  HB_BOOL bEof, bBof;
  PHB_ITEM pToSkip;

  // sr_TraceLog(SR_NULLPTR, "sqlSkipRaw %i\n", lToSkip);

  bEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  bBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);

  thiswa->area.fFound = HB_FALSE;

  if ((bEof && bBof) && lToSkip == -1) {
    return SELF_GOBOTTOM(&thiswa->area); // <===========| RETURNING
  }

  if ((bEof && bBof) || lToSkip == 0) {
    // Table is empty
    thiswa->area.fEof = bEof;
    thiswa->area.fBof = bBof;
    return HB_SUCCESS; // <===========| RETURNING
  }

  hb_arraySetNL(thiswa->aInfo, AINFO_SKIPCOUNT, hb_arrayGetNL(thiswa->aInfo, AINFO_SKIPCOUNT) + lToSkip);

  if (thiswa->isam) {
    HB_LONG lPosCache, lFound, lPreviousCacheStatus;
    HB_BOOL bCurrentDeleted;

    lPosCache = hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE);
    bCurrentDeleted = lPosCache && HB_IS_NIL(hb_arrayGetItemPtr(thiswa->aCache, lPosCache));

    if (lToSkip > 0) {
      if (bEof) {
        return HB_SUCCESS; // <===========| RETURNING
      }
      if (iTemCompEqual(hb_arrayGetItemPtr(thiswa->aInfo, AINFO_EOF_AT),
                        hb_arrayGetItemPtr(thiswa->aInfo, AINFO_RECNO))) {
        hb_arraySetL(thiswa->aInfo, AINFO_EOF, HB_TRUE);
        thiswa->area.fEof = HB_TRUE;
        sqlGetCleanBuffer(thiswa);
        return ConcludeSkipraw(thiswa, lToSkip);
      }

      lFound = searchCacheFWD(thiswa, 1);

      if (lFound) {
        setCurrentFromCache(thiswa, lFound);
        thiswa->area.fBof = HB_FALSE;
        return ConcludeSkipraw(thiswa, lToSkip);
      }
      lPreviousCacheStatus = lPosCache;
      readCachePageFWD(thiswa);
      lFound = searchCacheFWD(thiswa, lPreviousCacheStatus);
      if (lFound) {
        setCurrentFromCache(thiswa, lFound);
        thiswa->area.fBof = HB_FALSE;
        return ConcludeSkipraw(thiswa, lToSkip);
      }
      hb_arraySetL(thiswa->aInfo, AINFO_EOF, HB_TRUE);
      thiswa->area.fEof = HB_TRUE;
      sqlGetCleanBuffer(thiswa);
      return ConcludeSkipraw(thiswa, lToSkip);
    } else {
      // lToSkip < 0
      if (bCurrentDeleted) {
        if (!bBof) {
          if (bEof) {
            SELF_GOBOTTOM(&thiswa->area);
            return ConcludeSkipraw(thiswa, lToSkip);
          }
          lFound = searchCacheBWD(thiswa, 1);
          if (lFound) {
            setCurrentFromCache(thiswa, lFound);
            return ConcludeSkipraw(thiswa, lToSkip);
          }
          lPreviousCacheStatus = lPosCache;
          readCachePageBWD(thiswa);
          lFound = searchCacheBWD(thiswa, lPreviousCacheStatus);
          if (lFound) {
            setCurrentFromCache(thiswa, lFound);
            return ConcludeSkipraw(thiswa, lToSkip);
          }
        }
        lFound = searchCacheFWD(thiswa, 1);
        if (lFound) {
          setCurrentFromCache(thiswa, lFound);
          hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_TRUE);
          thiswa->area.fBof = HB_TRUE;
          return ConcludeSkipraw(thiswa, lToSkip);
        }
        readCachePageFWD(thiswa);
        lFound = searchCacheFWD(thiswa, 1);
        if (lFound) {
          setCurrentFromCache(thiswa, lFound);
          hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_TRUE);
          thiswa->area.fBof = HB_TRUE;
          return ConcludeSkipraw(thiswa, lToSkip);
        }
        hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_TRUE);
        thiswa->area.fBof = HB_TRUE;
        hb_arraySetL(thiswa->aInfo, AINFO_EOF, HB_TRUE);
        thiswa->area.fEof = HB_TRUE;
        sqlGetCleanBuffer(thiswa);
      } else {
        if (bBof) {
          return ConcludeSkipraw(thiswa, lToSkip);
        }
        if (iTemCompEqual(hb_arrayGetItemPtr(thiswa->aInfo, AINFO_BOF_AT),
                          hb_arrayGetItemPtr(thiswa->aInfo, AINFO_RECNO))) {
          // Checking optimizer
          hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_TRUE);
          thiswa->area.fBof = HB_TRUE;
          return ConcludeSkipraw(thiswa, lToSkip);
        }
        if (bEof) {
          if (iTemCompEqual(hb_arrayGetItemPtr(thiswa->aInfo, AINFO_EOF_AT),
                            hb_arrayGetItemPtr(thiswa->aInfo, AINFO_RECNO))) {
            SELF_GOTOID(&thiswa->area, hb_arrayGetItemPtr(thiswa->aInfo, AINFO_EOF_AT));
          } else {
            SELF_GOBOTTOM(&thiswa->area);
          }
          return ConcludeSkipraw(thiswa, lToSkip);
        }
        lFound = searchCacheBWD(thiswa, 1);
        if (lFound) {
          setCurrentFromCache(thiswa, lFound);
          return ConcludeSkipraw(thiswa, lToSkip);
        }
        lPreviousCacheStatus = lPosCache;
        readCachePageBWD(thiswa);
        lFound = searchCacheBWD(thiswa, lPreviousCacheStatus);
        if (lFound) {
          setCurrentFromCache(thiswa, lFound);
          return ConcludeSkipraw(thiswa, lToSkip);
        }
        hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_TRUE);
        thiswa->area.fBof = HB_TRUE;
        return ConcludeSkipraw(thiswa, lToSkip);
      }
    }
  } else {
    // !ISAM
    if (hb_arrayLen(thiswa->aCache) == 0) {
      sqlGetCleanBuffer(thiswa);
      if (lToSkip != 0) {
        thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);
        thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
      }
      return ConcludeSkipraw(thiswa, lToSkip);
    }

    hb_objSendMessage(thiswa->oWorkArea, s_pSym_STABILIZE, 0);

    if (lToSkip == 0) {
      hb_arraySetL(thiswa->aInfo, AINFO_BOF, bBof);
      hb_arraySetL(thiswa->aInfo, AINFO_EOF, bEof);
      return ConcludeSkipraw(thiswa, lToSkip);
    } else if (hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE) + lToSkip > 0 &&
             hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE) + lToSkip <= (HB_LONG)hb_arrayLen(thiswa->aCache)) {
      sqlGetBufferFromCache2(thiswa, hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE) + lToSkip);
      hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_FALSE);
      hb_arraySetL(thiswa->aInfo, AINFO_EOF, HB_FALSE);
      hb_arraySetL(thiswa->aInfo, AINFO_FOUND, HB_FALSE);
      pToSkip = hb_itemNew(SR_NULLPTR);
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_NORMALIZE, 1, pToSkip);
      hb_itemRelease(pToSkip);
      thiswa->area.fBof = HB_FALSE;
      thiswa->area.fEof = HB_FALSE;
      return ConcludeSkipraw(thiswa, lToSkip);
    } else if (hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE) + lToSkip < 1) {
      hb_arraySetNL(thiswa->aInfo, AINFO_NPOSCACHE, 1);
      sqlGetBufferFromCache2(thiswa, 1);
      hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_TRUE);
      hb_arraySetL(thiswa->aInfo, AINFO_EOF, HB_FALSE);
      hb_arraySetL(thiswa->aInfo, AINFO_FOUND, HB_FALSE);
      thiswa->area.fBof = HB_TRUE;
      thiswa->area.fEof = HB_FALSE;
      return ConcludeSkipraw(thiswa, lToSkip);
    } else if (hb_arrayGetNL(thiswa->aInfo, AINFO_NPOSCACHE) + lToSkip > (HB_LONG)hb_arrayLen(thiswa->aCache)) {
      hb_arraySetL(thiswa->aInfo, AINFO_BOF, HB_FALSE);
      sqlGetCleanBuffer(thiswa);
    }
  }
  if (lToSkip == 0) {
    thiswa->area.fBof = bBof;
    thiswa->area.fEof = bEof;
    return HB_SUCCESS;
  }
  if (lToSkip != 0) {
    thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);
    thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  }
  return ConcludeSkipraw(thiswa, lToSkip);
}

//------------------------------------------------------------------------

#define sqlAddField SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlAppend(SQLAREAP thiswa)
{
  PHB_ITEM pItem;

  // sr_TraceLog(SR_NULLPTR, "sqlAppend\n");

  // Reset parent rel struct
  thiswa->lpdbPendingRel = SR_NULLPTR;
  thiswa->firstinteract = HB_FALSE;
  thiswa->wasdel = HB_FALSE;

  hb_arraySize(thiswa->aLocked, 0);

  if (hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_WRITEBUFFER, 0);
  }

  thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);

  pItem = hb_itemPutL(SR_NULLPTR, HB_TRUE);
  hb_arraySet(thiswa->aInfo, AINFO_HOT, pItem);
  hb_arraySet(thiswa->aInfo, AINFO_ISINSERT, pItem);
  hb_itemPutNI(pItem, 0);
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGOTO, 1, pItem);
  hb_itemRelease(pItem);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlCreateFields(SQLAREAP thiswa, PHB_ITEM pStruct)
{
  thiswa->aCreate = pStruct;
  return SUPER_CREATEFIELDS(&thiswa->area, pStruct);
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlDeleteRec(SQLAREAP thiswa)
{
  if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  }

  if (hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_WRITEBUFFER, 0);
  }
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLDELETEREC, 0);
  thiswa->wasdel = HB_TRUE;

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlDeleted(SQLAREAP thiswa, HB_BOOL *isDeleted)
{
  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  } else if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  *isDeleted = hb_arrayGetL(thiswa->aInfo, AINFO_DELETED);

  // sr_TraceLog(SR_NULLPTR, "sqlDeleted, returning %i\n", *isDeleted);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlFieldCount(SQLAREAP thiswa, HB_USHORT *fieldCount)
{
  *fieldCount = thiswa->area.uiFieldCount;
  // sr_TraceLog(SR_NULLPTR, "sqlFieldCount, returning %i\n", thiswa->area.uiFieldCount);
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlFieldDisplay SR_NULLPTR
#define sqlFieldInfo SR_NULLPTR
#define sqlFieldName SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlFlush(SQLAREAP thiswa)
{
  // sr_TraceLog(SR_NULLPTR, "sqlFlush\n");
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLFLUSH, 0);
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlGetRec SR_NULLPTR // leave it unUsed

//------------------------------------------------------------------------

static HB_ERRCODE sqlGetValue(SQLAREAP thiswa, HB_USHORT fieldNum, PHB_ITEM value)
{
  PHB_ITEM itemTemp, itemTemp3;
  PHB_ITEM pFieldNum;
  HB_SIZE nPos;
  LPFIELD pField;

  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  } else if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }
  pField = thiswa->area.lpFields + fieldNum - 1;
  itemTemp = hb_itemArrayGet(thiswa->aBuffer, thiswa->uiBufferIndex[fieldNum - 1]);

  if (HB_IS_NIL(itemTemp)) {
    hb_itemRelease(itemTemp);
    pFieldNum = hb_itemNew(SR_NULLPTR);
    hb_itemPutNI(pFieldNum, thiswa->uiBufferIndex[fieldNum - 1]);
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGETVALUE, 1, pFieldNum);
    hb_itemRelease(pFieldNum);
    itemTemp = hb_itemArrayGet(thiswa->aBuffer, thiswa->uiBufferIndex[fieldNum - 1]);
  }

  if (!thiswa->uiFieldList[fieldNum - 1]) {
    hb_arraySetNL(thiswa->aSelectList, thiswa->uiBufferIndex[fieldNum - 1], 1);
    thiswa->uiFieldList[fieldNum - 1] = 1;
    thiswa->iFieldListStatus = FIELD_LIST_NEW_VALUE_READ;
  }

  if (HB_IS_ARRAY(itemTemp)) {
    hb_arrayCloneTo(value, itemTemp);
  } else if (HB_IS_HASH(itemTemp) && sr_isMultilang()) {
    pField = thiswa->area.lpFields + fieldNum - 1;

    if (pField->uiType == HB_FT_MEMO) {
      PHB_ITEM pLangItem = hb_itemNew(SR_NULLPTR);
      if (hb_hashScan(itemTemp, sr_getBaseLang(pLangItem), &nPos) ||
          hb_hashScan(itemTemp, sr_getSecondLang(pLangItem), &nPos) ||
          hb_hashScan(itemTemp, sr_getRootLang(pLangItem), &nPos)) {
        hb_itemCopy(value, hb_hashGetValueAt(itemTemp, nPos));
      } else {
        hb_itemPutC(value, SR_NULLPTR);
      }
      hb_itemRelease(pLangItem);
    } else {
      PHB_ITEM pLangItem = hb_itemNew(SR_NULLPTR);
      HB_SIZE nLen = pField->uiLen, nSrcLen;
      char *empty = (char *)hb_xgrab(nLen + 1);

      if (hb_hashScan(itemTemp, sr_getBaseLang(pLangItem), &nPos) ||
          hb_hashScan(itemTemp, sr_getSecondLang(pLangItem), &nPos) ||
          hb_hashScan(itemTemp, sr_getRootLang(pLangItem), &nPos)) {
        itemTemp3 = hb_hashGetValueAt(itemTemp, nPos);
        nSrcLen = hb_itemGetCLen(itemTemp3);
        hb_xmemcpy(empty, hb_itemGetCPtr(itemTemp3), HB_MIN(nLen, nSrcLen));
        if (nLen > nSrcLen) {
          memset(empty + nSrcLen, ' ', nLen - nSrcLen);
        }
#ifndef HB_CDP_SUPPORT_OFF
        if (pField->uiType == HB_FT_STRING) {
          PHB_CODEPAGE cdpDest = thiswa->cdPageCnv ? thiswa->cdPageCnv : hb_vmCDP();
          if (thiswa->area.cdPage && thiswa->area.cdPage != cdpDest) {
            char *pszVal = hb_cdpnDup(empty, &nLen, thiswa->area.cdPage, cdpDest);
            hb_xfree(empty);
            empty = pszVal;
          }
        }
#endif
      } else {
        memset(empty, ' ', nLen);
      }
      empty[nLen] = '\0';
      hb_itemPutCLPtr(value, empty, nLen);
      hb_itemRelease(pLangItem);
    }
  } else {
#if 0
    if (HB_IS_NIL(itemTemp)) {
      sr_TraceLog(SR_NULLPTR, "Empty buffer found at position %i, fieldpos %i\n", (int)thiswa->uiBufferIndex[fieldNum - 1],
        (int) fieldNum);
    }
#endif
#ifndef HB_CDP_SUPPORT_OFF
    LPFIELD pField_ = thiswa->area.lpFields + fieldNum - 1;
    if (pField_->uiType == HB_FT_STRING) {
      PHB_CODEPAGE cdpDest = thiswa->cdPageCnv ? thiswa->cdPageCnv : hb_vmCDP();
      if (thiswa->area.cdPage && thiswa->area.cdPage != cdpDest) {
        HB_SIZE nLen = hb_itemGetCLen(itemTemp);
        char *pszVal = hb_cdpnDup(hb_itemGetCPtr(itemTemp), &nLen, thiswa->area.cdPage, cdpDest);
        hb_itemPutCLPtr(itemTemp, pszVal, nLen);
      }
    }
#endif
    hb_itemMove(value, itemTemp);
  }
  hb_itemRelease(itemTemp);
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlGetVarLen SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlGoCold(SQLAREAP thiswa)
{
  if (hb_arrayGetL(thiswa->aInfo, AINFO_HOT) && (!hb_arrayGetL(thiswa->aInfo, AINFO_DELETED))) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_WRITEBUFFER, 0); // GoCold
  }
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlGoHot SR_NULLPTR
#define sqlPutRec SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlPutValue(SQLAREAP thiswa, HB_USHORT fieldNum, PHB_ITEM value)
{
  PHB_ITEM pDest;
  LPFIELD pField;
  char *cfield;
  double dNum;
  HB_USHORT len, dec, fieldindex;
  PHB_ITEM pFieldNum;
  // HB_BOOL bOk = HB_TRUE;
  // PHB_DYNS s_pSym_SR_FROMXML = NULL;
  // sr_TraceLog(SR_NULLPTR, "sqlPutValue, writing column %i\n", fieldNum);

  if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  }

  fieldindex = (HB_USHORT)thiswa->uiBufferIndex[fieldNum - 1];
  pDest = hb_itemArrayGet(thiswa->aBuffer, fieldindex);
  //                if( s_pSym_SR_FROMXML == NULL ) {
  //                   s_pSym_SR_FROMXML = hb_dynsymFindName("ESCREVE");
  //                   if( s_pSym_SR_FROMXML  == NULL ) {
  //                      printf("Could not find Symbol SR_DESERIALIZE\n");
  //                   }
  //                }
  //
  //                hb_vmPushDynSym(s_pSym_SR_FROMXML);
  //                hb_vmPushNil();
  //                hb_vmPush(thiswa->aBuffer);
  //                hb_vmDo(1);
  //
  if (HB_IS_NIL(pDest)) {
    hb_itemRelease(pDest);
    pFieldNum = hb_itemNew(SR_NULLPTR);
    hb_itemPutNI(pFieldNum, thiswa->uiBufferIndex[fieldNum - 1]);
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLGETVALUE, 1, pFieldNum);
    hb_itemRelease(pFieldNum);
    pDest = hb_itemArrayGet(thiswa->aBuffer, fieldindex);
  }

  if (!thiswa->uiFieldList[fieldNum - 1]) {
    hb_arraySetNL(thiswa->aSelectList, thiswa->uiBufferIndex[fieldNum - 1], 1);
    thiswa->uiFieldList[fieldNum - 1] = 1;
  }

  pField = thiswa->area.lpFields + fieldNum - 1;

  // test compatible datatypes
  // if (HB_IS_TIMESTAMP(value)) { //|| HB_IS_DATE(pDest))
  //   bOk = HB_FALSE;
  //   hb_arraySet(thiswa->aBuffer, fieldindex, value);
  // }
  if ((HB_IS_NUMBER(pDest) && HB_IS_NUMBER(value)) || (HB_IS_STRING(pDest) && HB_IS_STRING(value)) ||
      (HB_IS_LOGICAL(pDest) && HB_IS_LOGICAL(value)) || (HB_IS_DATE(pDest) && HB_IS_DATE(value)) ||
      (HB_IS_TIMESTAMP(pDest) && HB_IS_DATETIME(value)) || (HB_IS_DATETIME(pDest) && HB_IS_DATETIME(value))) {

    if (pField->uiType == HB_FT_STRING) {
      HB_SIZE nSize = hb_itemGetCLen(value), nLen = pField->uiLen;

      cfield = (char *)hb_xgrab(nLen + 1);
#ifndef HB_CDP_SUPPORT_OFF
      hb_cdpnDup2(hb_itemGetCPtr(value), nSize, cfield, &nLen, thiswa->cdPageCnv ? thiswa->cdPageCnv : hb_vmCDP(),
                  thiswa->area.cdPage);
      nSize = nLen;
      nLen = pField->uiLen;
#else
      memcpy(cfield, hb_itemGetCPtr(value), HB_MIN(nLen, nSize));
#endif
      if (nLen > nSize) {
        memset(cfield + nSize, ' ', nLen - nSize);
      }
      cfield[nLen] = '\0';
      hb_itemPutCLPtr(value, cfield, nLen);
    } else if (pField->uiType == HB_FT_LONG) {
      len = pField->uiLen;
      dec = pField->uiDec;
      if (dec > 0) {
        len -= (dec + 1);
      }
      dNum = hb_itemGetND(value);
      hb_itemPutNLen(value, dNum, len, dec);
    }

    hb_arraySet(thiswa->aBuffer, fieldindex, value);
  } else if (HB_IS_STRING(value) && HB_IS_HASH(pDest) && sr_isMultilang()) {
    PHB_ITEM pLangItem = hb_itemNew(SR_NULLPTR);
    hb_hashAdd(pDest, sr_getBaseLang(pLangItem), value);
    hb_itemRelease(pLangItem);
  } else if (pField->uiType == HB_FT_MEMO) {
    // Memo fields can hold ANY datatype
    hb_arraySet(thiswa->aBuffer, fieldindex, value);
  } else {
#ifdef SQLRDD_NWG_SPECIFIC
    hb_itemPutL(pDest, HB_TRUE);
    hb_arraySetForward(thiswa->aInfo, AINFO_HOT, pDest);
    hb_itemRelease(pDest);
    return HB_SUCCESS;
#else
    char type_err[128];
    sprintf(type_err, "data type origin: %i - data type target %i", hb_itemType(value), hb_itemType(pDest));
    hb_itemRelease(pDest);
    commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, type_err);
    return HB_FAILURE;
#endif
  }

  hb_itemPutL(pDest, HB_TRUE);
  hb_arraySetForward(thiswa->aInfo, AINFO_HOT, pDest);
  hb_itemRelease(pDest);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlRecall(SQLAREAP thiswa)
{
  // sr_TraceLog(SR_NULLPTR, "sqlRecall\n");

  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  } else if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLRECALL, 0);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlRecCount(SQLAREAP thiswa, HB_ULONG *recCount)
{
  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  }

  if (hb_arrayGetL(thiswa->aInfo, AINFO_ISINSERT) && hb_arrayGetL(thiswa->aInfo, AINFO_HOT)) {
    *recCount = (HB_ULONG)(hb_arrayGetNL(thiswa->aInfo, AINFO_RCOUNT) + 1);
  } else {
    *recCount = (HB_ULONG)(hb_arrayGetNL(thiswa->aInfo, AINFO_RCOUNT));
  }

  // sr_TraceLog(SR_NULLPTR, "sqlRecCount, returning %i\n", *recCount);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlRecInfo SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlRecNo(SQLAREAP thiswa, HB_ULONG *recno)
{
#ifdef SQLRDD_NWG_SPECIFIC
  if (hb_arrayGetNL(thiswa->aInfo, hb_arrayGetL(thiswa->aInfo, AINFO_ISINSERT))) {
    commonError(&thiswa->area, EG_ARG, ESQLRDD_NOT_COMMITED_YET, SR_NULLPTR);
    return HB_FAILURE;
  }
#endif
  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  } else if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  *recno = (HB_ULONG)hb_arrayGetNL(thiswa->aInfo, AINFO_RECNO);

  // sr_TraceLog(SR_NULLPTR, "sqlRecNo %i\n", hb_arrayGetNI(thiswa->aInfo, AINFO_RECNO));

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlRecId(SQLAREAP thiswa, PHB_ITEM recno)
{
  if (thiswa->lpdbPendingRel) {
    SELF_FORCEREL(&thiswa->area);
  } else if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (thiswa->initialized) {
    hb_arrayGet(thiswa->aInfo, AINFO_RECNO, recno);
  } else {
    hb_itemPutNL(recno, 0);
  }

  // sr_TraceLog(SR_NULLPTR, "sqlRecID %i\n", hb_arrayGetNI(thiswa->aInfo, AINFO_RECNO));

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlSetFieldExtent(SQLAREAP thiswa, HB_USHORT uiFieldExtent)
{
  HB_TRACE(HB_TR_DEBUG, ("sqlSetFieldExtent(%p, %hu)", thiswa, uiFieldExtent));

  if (SUPER_SETFIELDEXTENT(&thiswa->area, uiFieldExtent) == HB_FAILURE) {
    return HB_FAILURE;
  }

  if (!sr_lHideRecno()) {
    uiFieldExtent++;
  }

  if (!sr_lHideHistoric()) {
    uiFieldExtent++;
  }

  // thiswa->uiBufferIndex = (int *) hb_xgrab(uiFieldExtent * sizeof(int));
  // thiswa->uiFieldList = (int *) hb_xgrab(uiFieldExtent * sizeof(int));
  // memset(thiswa->uiBufferIndex, 0, uiFieldExtent * sizeof(int));
  // memset(thiswa->uiFieldList,  0, uiFieldExtent * sizeof(int));
  thiswa->uiBufferIndex = (int *)hb_xgrabz(uiFieldExtent * sizeof(int));
  thiswa->uiFieldList = (int *)hb_xgrabz(uiFieldExtent * sizeof(int));
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlAlias SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlClose(SQLAREAP thiswa)
{
  HB_ERRCODE uiError;

  // sr_TraceLog(SR_NULLPTR, "sqlClose\n");

  // Reset parent rel struct
  thiswa->lpdbPendingRel = SR_NULLPTR;

  if (thiswa->oWorkArea && HB_IS_OBJECT(thiswa->oWorkArea)) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLCLOSE, 0);
  } else {
    return SUPER_CLOSE(&thiswa->area);
  }

  uiError = SUPER_CLOSE(&thiswa->area);

#if 0
  else {
    commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
    return HB_FAILURE;
  }
#endif
  // Release the used objects

  hb_itemRelease(thiswa->aStruct);
  hb_itemRelease(thiswa->aInfo);
  hb_itemRelease(thiswa->aBuffer);
  hb_itemRelease(thiswa->aOrders);
  hb_itemRelease(thiswa->aSelectList);
  hb_itemRelease(thiswa->aLocked);
  hb_itemRelease(thiswa->aOldBuffer);
  hb_itemRelease(thiswa->aCache);
  hb_itemRelease(thiswa->aEmptyBuff);

  if (thiswa->szDataFileName) {
    hb_xfree(thiswa->szDataFileName);
    thiswa->szDataFileName = SR_NULLPTR;
  }

  if (thiswa->uiBufferIndex) {
    hb_xfree(thiswa->uiBufferIndex);
    thiswa->uiBufferIndex = SR_NULLPTR;
  }

  if (thiswa->uiFieldList) {
    hb_xfree(thiswa->uiFieldList);
    thiswa->uiFieldList = SR_NULLPTR;
  }

  if (thiswa->oWorkArea && HB_IS_OBJECT(thiswa->oWorkArea)) {
    hb_itemRelease(thiswa->oWorkArea);
    thiswa->oWorkArea = SR_NULLPTR;
  }
  return uiError;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlCreate(SQLAREAP thiswa, LPDBOPENINFO pCreateInfo)
{
  PHB_ITEM pTable = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pAlias = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pArea = hb_itemNew(SR_NULLPTR);
  HB_ERRCODE errCode;

  // sr_TraceLog(SR_NULLPTR, "sqlCreate(%p, %p)", thiswa, pCreateInfo);

  thiswa->creating = HB_TRUE;

  thiswa->szDataFileName = (char *)hb_xgrab(strlen((char *)pCreateInfo->abName) + 1);
  strcpy(thiswa->szDataFileName, (char *)pCreateInfo->abName);

  pTable = hb_itemPutC(pTable, thiswa->szDataFileName);
  if (pCreateInfo->atomAlias) {
    hb_itemPutC(pAlias, (char *)pCreateInfo->atomAlias);
  }
  hb_itemPutNL(pArea, pCreateInfo->uiArea);

  thiswa->area.fTop = 0;
  thiswa->area.fBottom = 1;
  thiswa->area.fBof = 0;
  thiswa->area.fEof = 1;

  //   thiswa->valResult = NULL;

  // Create and run class object
  hb_vmPushDynSym(s_pSym_WORKAREA);
  hb_vmPushNil();
  hb_vmDo(0);

  thiswa->oWorkArea = hb_itemNew(SR_NULLPTR);
  hb_itemCopy(thiswa->oWorkArea, hb_stackReturnItem());
  if (s_pSym_SQLCREATE) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLCREATE, 4, thiswa->aCreate, pTable, pAlias, pArea);
  }

  hb_objSendMsg(thiswa->oWorkArea, "AINFO", 0);
  thiswa->aInfo = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ACACHE", 0);
  thiswa->aCache = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AOLDBUFFER", 0);
  thiswa->aOldBuffer = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ALOCALBUFFER", 0);
  thiswa->aBuffer = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AEMPTYBUFFER", 0);
  thiswa->aEmptyBuff = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AINDEX", 0);
  thiswa->aOrders = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ASELECTLIST", 0);
  thiswa->aSelectList = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AINIFIELDS", 0);
  thiswa->aStruct = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ALOCKED", 0);
  thiswa->aLocked = hb_itemNew(hb_stackReturnItem());

  hb_itemRelease(pTable);
  hb_itemRelease(pAlias);
  hb_itemRelease(pArea);

  hb_objSendMsg(thiswa->oWorkArea, "LOPENED", 0);

  if (!hb_itemGetL(hb_stackReturnItem())) {
    return HB_FAILURE;
  }

  if (!SetFields(thiswa)) {
    return HB_FAILURE;
  }

  // If successful call SUPER_CREATE to finish system jobs
  errCode = SUPER_CREATE(&thiswa->area, pCreateInfo);

  hb_objSendMsg(thiswa->oWorkArea, "LISAM", 0);
  thiswa->isam = hb_itemGetL(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "HNRECNO", 0);
  thiswa->ulhRecno = (HB_ULONG)hb_itemGetNL(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "HNDELETED", 0);
  thiswa->ulhDeleted = (HB_ULONG)hb_itemGetNL(hb_stackReturnItem());

  if (errCode != HB_SUCCESS) {
    SELF_CLOSE(&thiswa->area);
    return errCode;
  } else {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  thiswa->wasdel = HB_FALSE;

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlInfo(SQLAREAP thiswa, HB_USHORT uiIndex, PHB_ITEM pItem)
{
  HB_BOOL flag = HB_TRUE;

  // sr_TraceLog(SR_NULLPTR, "sqlInfo(%p, %hu, %p)", thiswa, uiIndex, pItem);

  switch (uiIndex) {
  case DBI_ISDBF:
  case DBI_CANPUTREC: {
    hb_itemPutL(pItem, HB_FALSE);
    break;
  }
  case DBI_GETHEADERSIZE: {
    hb_itemPutNL(pItem, 0);
    break;
  }
  case DBI_LASTUPDATE: {
    hb_itemPutD(pItem, 2003, 12, 31);
    break;
  }
  case DBI_GETDELIMITER:
  case DBI_SETDELIMITER: {
    break;
  }
  case DBI_GETRECSIZE: {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLRECSIZE, 0);
    hb_itemPutNI(pItem, hb_itemGetNI(hb_stackReturnItem()));
    break;
  }
  case DBI_GETLOCKARRAY: {
    hb_itemCopy(pItem, thiswa->aLocked);
    break;
  }
  case DBI_TABLEEXT: {
    hb_itemPutC(pItem, "");
    break;
  }
  case DBI_MEMOEXT: {
    hb_itemPutC(pItem, "");
    break;
  }
  case DBI_MEMOBLOCKSIZE: {
    hb_itemPutNI(pItem, 0);
    break;
  }
  case DBI_FULLPATH: {
    hb_itemPutC(pItem, thiswa->szDataFileName);
    break;
  }
  case DBI_FILEHANDLE: {
    hb_itemPutNL(pItem, 0);
    break;
  }
  case DBI_BOF: {
    SELF_BOF(&thiswa->area, &flag);
    hb_itemPutL(pItem, flag);
    break;
  }
  case DBI_EOF: {
    SELF_EOF(&thiswa->area, &flag);
    hb_itemPutL(pItem, flag);
    break;
  }
  case DBI_ISFLOCK: {
    if (HB_IS_OBJECT(thiswa->oWorkArea)) {
      hb_objSendMsg(thiswa->oWorkArea, "LTABLELOCKED", 0);
    } else {
      commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
      return HB_FAILURE;
    }
    hb_itemMove(pItem, hb_stackReturnItem());
    break;
  }
  case DBI_MEMOHANDLE: {
    hb_itemPutNL(pItem, 0);
    break;
  }
  case DBI_RDD_BUILD: {
    hb_itemPutNL(pItem, HB_SQLRDD_BUILD);
    break;
  }
  case DBI_RDD_VERSION: {
    if (HB_IS_OBJECT(thiswa->oWorkArea)) {
      hb_objSendMsg(thiswa->oWorkArea, "OSQL", 0);
      hb_objSendMsg(hb_stackReturnItem(), "CMGMNTVERS", 0);
    } else {
      commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
      return HB_FAILURE;
    }
    hb_itemMove(pItem, hb_stackReturnItem());
    break;
  }
  case DBI_DB_VERSION: {
    if (HB_IS_OBJECT(thiswa->oWorkArea)) {
      hb_objSendMsg(thiswa->oWorkArea, "OSQL", 0);
      hb_objSendMsg(hb_stackReturnItem(), "NSYSTEMID", 0);
    } else {
      commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
      return HB_FAILURE;
    }
    hb_itemMove(pItem, hb_stackReturnItem());
    break;
  }
  case DBI_INTERNAL_OBJECT: {
    hb_itemCopy(pItem, thiswa->oWorkArea);
    break;
  }
  case DBI_ISREADONLY: {
    hb_itemPutL(pItem, thiswa->readonly);
    break;
  }
  case DBI_SHARED: {
    hb_itemPutL(pItem, thiswa->shared);
    break;
  }
  case DBI_CPCONVERTTO: {
    if (HB_IS_STRING(pItem)) {
      PHB_CODEPAGE cdpage = hb_cdpFind(hb_itemGetCPtr(pItem));
      if (cdpage) {
        thiswa->cdPageCnv = cdpage;
      }
    }
    if (thiswa->cdPageCnv) {
      hb_itemPutC(pItem, (char *)thiswa->cdPageCnv->id);
    } else {
      hb_itemPutC(pItem, "");
    }
    break; // TODO: unnecessary break
  }
  }
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

void startSQLRDDSymbols()
{
  if (s_pSym_WORKAREA == SR_NULLPTR) {
    s_pSym_WORKAREA = hb_dynsymFindName(WORKAREA_CLASS);
    s_pSym_SQLGOBOTTOM = hb_dynsymFindName("SQLGOBOTTOM");
    s_pSym_SQLGOTO = hb_dynsymFindName("SQLGOTO");
    s_pSym_SQLGOTOP = hb_dynsymFindName("SQLGOTOP");
    s_pSym_SQLSEEK = hb_dynsymFindName("SQLSEEK");
    s_pSym_SETBOF = hb_dynsymFindName("SETBOF");
    s_pSym_SQLDELETEREC = hb_dynsymFindName("SQLDELETEREC");
    s_pSym_SQLFLUSH = hb_dynsymFindName("SQLFLUSH");
    s_pSym_SQLRECALL = hb_dynsymFindName("SQLRECALL");
    s_pSym_SQLCLOSE = hb_dynsymFindName("SQLCLOSE");
    s_pSym_SQLCREATE = hb_dynsymFindName("SQLCREATE");
    s_pSym_SQLOPEN = hb_dynsymFindName("SQLOPENAREA");
    s_pSym_SQLOPENALLINDEXES = hb_dynsymFindName("SQLOPENALLINDEXES");
    s_pSym_SQLPACK = hb_dynsymFindName("SQLPACK");
    s_pSym_SQLZAP = hb_dynsymFindName("SQLZAP");
    s_pSym_SQLORDERLISTADD = hb_dynsymFindName("SQLORDERLISTADD");
    s_pSym_SQLORDERLISTCLEAR = hb_dynsymFindName("SQLORDERLISTCLEAR");
    s_pSym_SQLORDERLISTFOCUS = hb_dynsymFindName("SQLORDERLISTFOCUS");
    s_pSym_SQLORDERCREATE = hb_dynsymFindName("SQLORDERCREATE");
    s_pSym_SQLORDERDESTROY = hb_dynsymFindName("SQLORDERDESTROY");
    s_pSym_SQLORDERCONDITION = hb_dynsymFindName("SQLORDERCONDITION");
    s_pSym_SQLORDERLISTNUM = hb_dynsymFindName("SQLORDERLISTNUM");
    s_pSym_SQLSETSCOPE = hb_dynsymFindName("SQLSETSCOPE");
    s_pSym_SQLLOCK = hb_dynsymFindName("SQLLOCK");
    s_pSym_SQLUNLOCK = hb_dynsymFindName("SQLUNLOCK");
    s_pSym_SQLDROP = hb_dynsymFindName("SQLDROP");
    s_pSym_SQLEXISTS = hb_dynsymFindName("SQLEXISTS");
    s_pSym_WRITEBUFFER = hb_dynsymFindName("WRITEBUFFER");
    s_pSym_READPAGE = hb_dynsymFindName("READPAGE");
    s_pSym_STABILIZE = hb_dynsymFindName("STABILIZE");
    s_pSym_NORMALIZE = hb_dynsymFindName("NORMALIZE");
    s_pSym_SQLKEYCOUNT = hb_dynsymFindName("SQLKEYCOUNT");
    s_pSym_SQLRECSIZE = hb_dynsymFindName("SQLRECSIZE");
    s_pSym_SQLGETVALUE = hb_dynsymFindName("SQLGETVALUE");
    s_pSym_SQLSETFILTER = hb_dynsymFindName("SQLSETFILTER");
    s_pSym_SQLCLEARFILTER = hb_dynsymFindName("SQLCLEARFILTER");
    s_pSym_SQLFILTERTEXT = hb_dynsymFindName("SQLFILTERTEXT");

    if (s_pSym_WORKAREA == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", WORKAREA_CLASS);
    }
    if (s_pSym_SQLGOBOTTOM == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLGOBOTTOM");
    }
    if (s_pSym_SQLGOTO == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLGOTO");
    }
    if (s_pSym_SQLGOTOP == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLGOTOP");
    }
    if (s_pSym_SQLSEEK == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLSEEK");
    }
    if (s_pSym_SETBOF == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SETBOF");
    }
    if (s_pSym_SQLDELETEREC == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLDELETEREC");
    }
    if (s_pSym_SQLFLUSH == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLFLUSH");
    }
    if (s_pSym_SQLRECALL == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLRECALL");
    }
    if (s_pSym_SQLCLOSE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLCLOSE");
    }
    if (s_pSym_SQLCREATE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLCREATE");
    }
    if (s_pSym_SQLOPEN == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLOPENAREA");
    }
    if (s_pSym_SQLOPENALLINDEXES == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLOPENALLINDEXES");
    }
    if (s_pSym_SQLPACK == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLPACK");
    }
    if (s_pSym_SQLZAP == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLZAP");
    }
    if (s_pSym_SQLORDERLISTADD == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLORDERLISTADD");
    }
    if (s_pSym_SQLORDERLISTCLEAR == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLORDERLISTCLEAR");
    }
    if (s_pSym_SQLORDERLISTFOCUS == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLORDERLISTFOCUS");
    }
    if (s_pSym_SQLORDERCREATE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLORDERCREATE");
    }
    if (s_pSym_SQLORDERDESTROY == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLORDERDESTROY");
    }
    if (s_pSym_SQLORDERCONDITION == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLORDERCONDITION");
    }
    if (s_pSym_SQLORDERLISTNUM == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLORDERLISTNUM");
    }
    if (s_pSym_SQLSETSCOPE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLSETSCOPE");
    }
    if (s_pSym_SQLLOCK == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLLOCK");
    }
    if (s_pSym_SQLUNLOCK == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLUNLOCK");
    }
    if (s_pSym_SQLDROP == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLDROP");
    }
    if (s_pSym_SQLEXISTS == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLEXISTS");
    }
    if (s_pSym_SQLKEYCOUNT == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLKEYCOUNT");
    }
    if (s_pSym_WRITEBUFFER == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "WRITEBUFFER");
    }
    if (s_pSym_READPAGE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "READPAGE");
    }
    if (s_pSym_STABILIZE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "STABILIZE");
    }
    if (s_pSym_NORMALIZE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "NORMALIZE");
    }
    if (s_pSym_SQLGETVALUE == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLGETVALUE");
    }
    if (s_pSym_SQLSETFILTER == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLSETFILTER");
    }
    if (s_pSym_SQLCLEARFILTER == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLCLEARFILTER");
    }
    if (s_pSym_SQLFILTERTEXT == SR_NULLPTR) {
      printf("Could not find Symbol %s\n", "SQLFILTERTEXT");
    }
  }
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlNewArea(SQLAREAP thiswa)
{
  if (SUPER_NEW(&thiswa->area) == HB_FAILURE) {
    return HB_FAILURE;
  }

  thiswa->uiBufferIndex = SR_NULLPTR;
  thiswa->uiFieldList = SR_NULLPTR;
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlOpen(SQLAREAP thiswa, LPDBOPENINFO pOpenInfo)
{
  PHB_ITEM pConnection = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pTable = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pArea = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pAlias = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pShared = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pReadOnly = hb_itemNew(SR_NULLPTR);
  HB_ERRCODE errCode;

  char szAlias[HB_RDD_MAX_ALIAS_LEN + 1];

  // sr_TraceLog(SR_NULLPTR, "sqlOpen\n");

  thiswa->szDataFileName = (char *)hb_xgrab(strlen((char *)pOpenInfo->abName) + 1);
  strcpy(thiswa->szDataFileName, (char *)pOpenInfo->abName);

  // Create default alias if necessary
  if (!pOpenInfo->atomAlias) {
    PHB_FNAME pFileName;
    pFileName = hb_fsFNameSplit((char *)pOpenInfo->abName);
    hb_strncpyUpperTrim(szAlias, pFileName->szName, HB_RDD_MAX_ALIAS_LEN);
    pOpenInfo->atomAlias = szAlias;
    hb_xfree(pFileName);
  }

  errCode = SUPER_OPEN(&thiswa->area, pOpenInfo);

  if (errCode != HB_SUCCESS) {
    SELF_CLOSE(&thiswa->area);
    return errCode;
  }

  thiswa->shared = pOpenInfo->fShared;
  thiswa->readonly = pOpenInfo->fReadonly;
  thiswa->hOrdCurrent = 0;
  thiswa->creating = HB_FALSE;
  thiswa->initialized = HB_FALSE;
  thiswa->sqlfilter = HB_FALSE;

  thiswa->area.uiMaxFieldNameLength = 64;

  hb_itemPutNL(pConnection, pOpenInfo->ulConnection);
  hb_itemPutC(pTable, thiswa->szDataFileName);
  hb_itemPutNL(pArea, pOpenInfo->uiArea);
  hb_itemPutL(pShared, thiswa->shared);
  hb_itemPutL(pReadOnly, thiswa->readonly);
  hb_itemPutC(pAlias, (char *)pOpenInfo->atomAlias);

#ifndef HB_CDP_SUPPORT_OFF
  if (pOpenInfo->cdpId) {
    thiswa->area.cdPage = hb_cdpFind((char *)pOpenInfo->cdpId);
    if (!thiswa->area.cdPage) {
      thiswa->area.cdPage = hb_vmCDP();
    }
  } else {
    thiswa->area.cdPage = hb_vmCDP();
  }
#endif

  hb_vmPushDynSym(s_pSym_WORKAREA);
  hb_vmPushNil();
  hb_vmDo(0);
  thiswa->oWorkArea = hb_itemNew(hb_stackReturnItem());

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLOPEN, 6, pTable, pArea, pShared, pReadOnly, pAlias, pConnection);

  hb_objSendMsg(thiswa->oWorkArea, "AINFO", 0);
  thiswa->aInfo = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ACACHE", 0);
  thiswa->aCache = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AOLDBUFFER", 0);
  thiswa->aOldBuffer = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ALOCALBUFFER", 0);
  thiswa->aBuffer = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AEMPTYBUFFER", 0);
  thiswa->aEmptyBuff = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AINDEX", 0);
  thiswa->aOrders = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ASELECTLIST", 0);
  thiswa->aSelectList = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "AINIFIELDS", 0);
  thiswa->aStruct = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "ALOCKED", 0);
  thiswa->aLocked = hb_itemNew(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "LGOTOPONFIRSTINTERACT", 0);
  thiswa->firstinteract = hb_itemGetL(hb_stackReturnItem());

  thiswa->initialized = HB_TRUE;
  thiswa->wasdel = HB_FALSE;

  hb_itemRelease(pTable);
  hb_itemRelease(pArea);
  hb_itemRelease(pAlias);
  hb_itemRelease(pShared);
  hb_itemRelease(pReadOnly);
  hb_itemRelease(pConnection);

  hb_objSendMsg(thiswa->oWorkArea, "LOPENED", 0);

  if (!hb_itemGetL(hb_stackReturnItem())) {
    return HB_FAILURE;
  }

  hb_objSendMsg(thiswa->oWorkArea, "LISAM", 0);
  thiswa->isam = hb_itemGetL(hb_stackReturnItem());

  if (!ProcessFields(thiswa)) {
    return HB_FAILURE;
  }

  hb_objSendMsg(thiswa->oWorkArea, "HNRECNO", 0);
  thiswa->ulhRecno = (HB_ULONG)hb_itemGetNL(hb_stackReturnItem());

  hb_objSendMsg(thiswa->oWorkArea, "HNDELETED", 0);
  thiswa->ulhDeleted = (HB_ULONG)hb_itemGetNL(hb_stackReturnItem());

  if (hb_setGetAutOpen()) {
    if (HB_IS_OBJECT(thiswa->oWorkArea)) {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLOPENALLINDEXES, 0);
    } else {
      commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
      return HB_FAILURE;
    }

    if (hb_itemGetNL(hb_stackReturnItem())) {
      thiswa->hOrdCurrent = hb_itemGetNL(hb_stackReturnItem());
    }
  }
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlRelease SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlStructSize(SQLAREAP thiswa, HB_USHORT *StructSize)
{
  HB_SYMBOL_UNUSED(thiswa); // Avoid compiler warning
  *StructSize = sizeof(SQLAREA);
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlSysName SR_NULLPTR
#define sqlEval SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlPack(SQLAREAP thiswa)
{
  // sr_TraceLog(SR_NULLPTR, "sqlPack\n");
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLPACK, 0);
  SELF_GOTOP(&thiswa->area);
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlPackRec SR_NULLPTR
#define sqlSort SR_NULLPTR
#define sqlTrans SR_NULLPTR
#define sqlTransRec SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlZap(SQLAREAP thiswa)
{
  // sr_TraceLog(SR_NULLPTR, "sqlZap\n");

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLZAP, 0);

  thiswa->area.fEof = hb_arrayGetL(thiswa->aInfo, AINFO_EOF);
  thiswa->area.fBof = hb_arrayGetL(thiswa->aInfo, AINFO_BOF);
  thiswa->firstinteract = HB_FALSE;
  thiswa->wasdel = HB_FALSE;

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

HB_ERRCODE sqlChildEnd(SQLAREAP thiswa, LPDBRELINFO pRelInfo)
{
  HB_ERRCODE uiError;

  // sr_TraceLog(SR_NULLPTR, "sqlChildEnd\n");

  HB_TRACE(HB_TR_DEBUG, ("sqlChildEnd(%p, %p)", thiswa, pRelInfo));

  if (thiswa->lpdbPendingRel == pRelInfo) {
    uiError = SELF_FORCEREL(&thiswa->area);
  } else {
    uiError = HB_SUCCESS;
  }
  SUPER_CHILDEND(&thiswa->area, pRelInfo);
  return uiError;
}

//------------------------------------------------------------------------

HB_ERRCODE sqlChildStart(SQLAREAP thiswa, LPDBRELINFO pRelInfo)
{
  HB_TRACE(HB_TR_DEBUG, ("sqlChildStart(%p, %p)", thiswa, pRelInfo));

  // sr_TraceLog(SR_NULLPTR, "sqlChildStart\n");

  if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  SELF_CHILDSYNC(&thiswa->area, pRelInfo);
  return SUPER_CHILDSTART(&thiswa->area, pRelInfo);
}

//------------------------------------------------------------------------

HB_ERRCODE sqlChildSync(SQLAREAP thiswa, LPDBRELINFO pRelInfo)
{
  HB_TRACE(HB_TR_DEBUG, ("sqlChildSync(%p, %p)", thiswa, pRelInfo));

  // sr_TraceLog(SR_NULLPTR, "sqlChildSync\n");

  thiswa->lpdbPendingRel = pRelInfo;
  SELF_SYNCCHILDREN(&thiswa->area);

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlSyncChildren SR_NULLPTR

//------------------------------------------------------------------------

#define sqlClearRel SR_NULLPTR

//------------------------------------------------------------------------

HB_ERRCODE sqlForceRel(SQLAREAP thiswa)
{
  LPDBRELINFO lpdbPendingRel;
  HB_ERRCODE uiError;

  HB_TRACE(HB_TR_DEBUG, ("sqlForceRel(%p)", thiswa));

  if (thiswa->lpdbPendingRel) {
    lpdbPendingRel = thiswa->lpdbPendingRel;
    thiswa->lpdbPendingRel = SR_NULLPTR;
    uiError = SELF_RELEVAL(&thiswa->area, lpdbPendingRel);
    thiswa->firstinteract = HB_FALSE;
    thiswa->wasdel = HB_FALSE;
    return uiError;
  }
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlRelArea SR_NULLPTR
#define sqlRelEval SR_NULLPTR
#define sqlRelText SR_NULLPTR
#define sqlSetRel SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlOrderListAdd(SQLAREAP thiswa, LPDBORDERINFO pOrderInfo)
{
  PHB_ITEM pNIL = SR_NULLPTR, pIndex, pTag;

  // sr_TraceLog(SR_NULLPTR, "sqlOrderListAdd\n");

  pIndex = pOrderInfo->atomBagName;
  pTag = pOrderInfo->itmOrder;
  if (!pIndex || !pTag) {
    pNIL = hb_itemNew(SR_NULLPTR);
    if (!pIndex) {
      pIndex = pNIL;
    }
    if (!pTag) {
      pTag = pNIL;
    }
  }

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTADD, 2, pIndex, pTag);

  if (pNIL) {
    hb_itemRelease(pNIL);
  }

  if (hb_itemGetNL(hb_stackReturnItem())) {
    thiswa->hOrdCurrent = hb_itemGetNL(hb_stackReturnItem());
    return HB_SUCCESS;
  }

  return HB_FAILURE;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlOrderListClear(SQLAREAP thiswa)
{
  // sr_TraceLog(SR_NULLPTR, "sqlOrderListClear\n");

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTCLEAR, 0);

  if (hb_itemGetL(hb_stackReturnItem())) {
    thiswa->hOrdCurrent = 0;
    return HB_SUCCESS;
  }

  return HB_FAILURE;
}

//------------------------------------------------------------------------

#define sqlOrderListDelete SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlOrderListFocus(SQLAREAP thiswa, LPDBORDERINFO pOrderInfo)
{
  PHB_ITEM pTag;
  HB_LONG lorder = 0;

  // sr_TraceLog(SR_NULLPTR, "sqlOrderListFocus\n");

  // BagName.type = HB_IT_NIL;
  pTag = loadTagDefault(thiswa, SR_NULLPTR, &lorder);

  if (pTag) {
    hb_arrayGet(pTag, ORDER_TAG, pOrderInfo->itmResult);
    hb_itemRelease(pTag);
  } else {
    hb_itemPutC(pOrderInfo->itmResult, "");
  }

  if (pOrderInfo->itmOrder) {
    PHB_ITEM pBagName = hb_itemNew(pOrderInfo->atomBagName);
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTFOCUS, 2, pOrderInfo->itmOrder, pBagName);
    hb_itemRelease(pBagName);
    thiswa->hOrdCurrent = hb_itemGetNL(hb_stackReturnItem());
    return HB_SUCCESS;
  } else {
    return HB_SUCCESS;
  }
}

//------------------------------------------------------------------------

#define sqlOrderListRebuild SR_NULLPTR

//------------------------------------------------------------------------

HB_ERRCODE sqlOrderCondition(SQLAREAP thiswa, LPDBORDERCONDINFO lpdbOrdCondInfo)
{
  PHB_ITEM pItemFor, pItemWhile, pItemStart, pItemNext, pItemRecno, pItemRest, pItemDesc;

  pItemFor = hb_itemNew(SR_NULLPTR);
  pItemWhile = hb_itemNew(SR_NULLPTR);
  pItemStart = hb_itemNew(SR_NULLPTR);
  pItemNext = hb_itemNew(SR_NULLPTR);
  pItemRecno = hb_itemNew(SR_NULLPTR);
  pItemRest = hb_itemNew(SR_NULLPTR);
  pItemDesc = hb_itemNew(SR_NULLPTR);

  if (lpdbOrdCondInfo) {
    if (lpdbOrdCondInfo->abFor) {
      hb_itemPutC(pItemFor, lpdbOrdCondInfo->abFor);
    }
    if (lpdbOrdCondInfo->abWhile) {
      hb_itemPutC(pItemWhile, lpdbOrdCondInfo->abWhile);
    }
    if (lpdbOrdCondInfo->itmStartRecID) {
      hb_itemCopy(pItemStart, lpdbOrdCondInfo->itmStartRecID);
    }
    hb_itemPutNL(pItemNext, lpdbOrdCondInfo->lNextCount);
    if (lpdbOrdCondInfo->itmRecID) {
      hb_itemCopy(pItemRecno, lpdbOrdCondInfo->itmRecID);
    }
    hb_itemPutL(pItemRest, lpdbOrdCondInfo->fRest);
    hb_itemPutL(pItemDesc, lpdbOrdCondInfo->fDescending);
  }

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERCONDITION, 7, pItemFor, pItemWhile, pItemStart, pItemNext,
                    pItemRecno, pItemRest, pItemDesc);

  hb_itemRelease(pItemFor);
  hb_itemRelease(pItemWhile);
  hb_itemRelease(pItemStart);
  hb_itemRelease(pItemNext);
  hb_itemRelease(pItemRecno);
  hb_itemRelease(pItemRest);
  hb_itemRelease(pItemDesc);

  SUPER_ORDSETCOND(&thiswa->area, lpdbOrdCondInfo);
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlOrderCreate(SQLAREAP thiswa, LPDBORDERCREATEINFO pOrderInfo)
{
  PHB_ITEM pBagName, pAtomBagName;

  // sr_TraceLog(SR_NULLPTR, "sqlOrderCreate\n");

  if (SELF_GOCOLD(&thiswa->area) == HB_FAILURE) {
    return HB_FAILURE;
  }

  pBagName = hb_itemPutC(SR_NULLPTR, pOrderInfo->abBagName);
  pAtomBagName = hb_itemPutC(SR_NULLPTR, pOrderInfo->atomBagName);

  if (pOrderInfo->lpdbConstraintInfo) {
    PHB_ITEM pConstrName, pTarget, pEnable;

    pConstrName = hb_itemPutC(SR_NULLPTR, pOrderInfo->lpdbConstraintInfo->abConstrName);
    pTarget = hb_itemPutC(SR_NULLPTR, pOrderInfo->lpdbConstraintInfo->abTargetName);
    pEnable = hb_itemPutL(SR_NULLPTR, pOrderInfo->lpdbConstraintInfo->fEnabled);

    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERCREATE, 7, pBagName, pOrderInfo->abExpr, pAtomBagName,
                      pConstrName, pTarget, pOrderInfo->lpdbConstraintInfo->itmRelationKey, pEnable);

    hb_itemRelease(pConstrName);
    hb_itemRelease(pTarget);
    hb_itemRelease(pEnable);
  } else {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERCREATE, 3, pBagName, pOrderInfo->abExpr, pAtomBagName);
  }

  hb_itemRelease(pBagName);
  hb_itemRelease(pAtomBagName);

  if (hb_itemGetNL(hb_stackReturnItem())) {
    thiswa->hOrdCurrent = hb_itemGetNL(hb_stackReturnItem());
    return HB_SUCCESS;
  }
  return HB_FAILURE;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlOrderDestroy(SQLAREAP thiswa, LPDBORDERINFO pOrderInfo)
{
  PHB_ITEM pTag;
  HB_LONG lorder = 0;

  // sr_TraceLog(SR_NULLPTR, "sqlOrderDestroy\n");

  if (SELF_GOCOLD(&thiswa->area) == HB_FAILURE) {
    return HB_FAILURE;
  }

  pTag = loadTagDefault(thiswa, SR_NULLPTR, &lorder);

  if (!pTag) {
    return HB_FAILURE;
  }

  if (pOrderInfo->itmOrder) {
    PHB_ITEM pBagName = hb_itemNew(pOrderInfo->atomBagName);

    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERDESTROY, 2, pOrderInfo->itmOrder, pBagName);
    hb_itemRelease(pBagName);

    if (hb_itemGetNL(hb_stackReturnItem())) {
      thiswa->hOrdCurrent = hb_itemGetNL(hb_stackReturnItem());
      return HB_SUCCESS;
    }
  } else {
    return HB_SUCCESS;
  }

  return HB_FAILURE;
}

//------------------------------------------------------------------------

#if 0
static PHB_ITEM loadTag(SQLAREAP thiswa, LPDBORDERINFO pInfo, HB_LONG * lorder)
{
  PHB_ITEM pTag = SR_NULLPTR;

  if (pInfo && pInfo->itmOrder) {
    if (HB_IS_OBJECT(thiswa->oWorkArea)) {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTNUM, 1, pInfo->itmOrder);
    } else {
      commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
      return SR_NULLPTR;
    }

    if (hb_itemGetNL(hb_stackReturnItem())) {
      *lorder = hb_itemGetNL(hb_stackReturnItem());
      pTag = hb_itemArrayGet(thiswa->aOrders, (HB_ULONG) * lorder);
    }
  }
  return pTag;
}
#endif

//------------------------------------------------------------------------

PHB_ITEM loadTagDefault(SQLAREAP thiswa, LPDBORDERINFO pInfo, HB_LONG *lorder)
{
  PHB_ITEM pOrder = hb_itemNew(SR_NULLPTR);
  PHB_ITEM pTag = SR_NULLPTR;

  //   Order.type = HB_IT_NIL;

  if (pInfo) {
    if (pInfo->itmOrder) {
      if (HB_IS_OBJECT(thiswa->oWorkArea)) {
        hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTNUM, 1, pInfo->itmOrder);
      } else {
        commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
        return SR_NULLPTR;
      }
    } else {
      if (HB_IS_OBJECT(thiswa->oWorkArea)) {
        hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTNUM, 1, pOrder);
      } else {
        hb_itemRelease(pOrder);
        commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
        return SR_NULLPTR;
      }
    }
  } else {
    if (HB_IS_OBJECT(thiswa->oWorkArea)) {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTNUM, 1, pOrder);
    } else {
      hb_itemRelease(pOrder);
      commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
      return SR_NULLPTR;
    }
  }

  *lorder = hb_itemGetNL(hb_stackReturnItem());

  if (*lorder) {
    pTag = hb_itemArrayGet(thiswa->aOrders, (HB_ULONG)*lorder);
  }

  hb_itemRelease(pOrder);

  return pTag;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlSetServerSideIndexScope(SQLAREAP thiswa, int nScope, PHB_ITEM scopeValue)
{
  PHB_ITEM scopetype;
  PHB_ITEM scopeval;
  int res;

  scopeval = hb_itemNew(scopeValue);
  scopetype = hb_itemPutNI(SR_NULLPTR, nScope);
  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLSETSCOPE, 2, scopetype, scopeval);
  res = hb_itemGetNI(hb_stackReturnItem());
  hb_itemRelease(scopetype);
  hb_itemRelease(scopeval);

  if ((!res) && sr_GoTopOnScope()) {
    thiswa->firstinteract = HB_TRUE;
  }

  return (res == 0) ? HB_SUCCESS : HB_FAILURE;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlOrderInfo(SQLAREAP thiswa, HB_USHORT uiIndex, LPDBORDERINFO pInfo)
{
  HB_LONG lIndexes, lorder = 0;
  PHB_ITEM pTag, pTemp;
  PHB_MACRO pMacro;

  // sr_TraceLog(SR_NULLPTR, "sqlOrderInfo, order: %i\n", uiIndex);

  HB_TRACE(HB_TR_DEBUG, ("sqlOrderInfo(%p, %hu, %p)", thiswa, uiIndex, pInfo));

  switch (uiIndex) {
  case DBOI_BAGEXT: {
    hb_itemPutC(pInfo->itmResult, "");
    return HB_SUCCESS;
  }
  }

  lIndexes = hb_itemSize(thiswa->aOrders);

  if (lIndexes) {
    // Exists opened orders ?
    switch (uiIndex) {
    case DBOI_KEYCOUNTRAW: {
      HB_ULONG ulRecCount = 0;
      SELF_RECCOUNT(&thiswa->area, &ulRecCount);
      hb_itemPutNL(pInfo->itmResult, ulRecCount);
      break;
    }
    case DBOI_KEYCOUNT: {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLKEYCOUNT, 0);
      hb_itemPutNL(pInfo->itmResult, hb_itemGetNL(hb_stackReturnItem()));
      break;
    }
    case DBOI_CONDITION: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        pTemp = hb_itemArrayGet(pTag, FOR_CLAUSE);
        hb_itemCopy(pInfo->itmResult, pTemp);
        hb_itemRelease(pTemp);
        hb_itemRelease(pTag);
      } else {
        hb_itemPutC(pInfo->itmResult, "");
      }
      break;
    }
    case DBOI_EXPRESSION: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);

      if (pTag) {
        pTemp = hb_itemArrayGet(pTag, INDEX_KEY);
        hb_itemCopy(pInfo->itmResult, pTemp);
        hb_itemRelease(pTemp);
        hb_itemRelease(pTag);
      } else {
        hb_itemPutC(pInfo->itmResult, "");
      }
      break;
    }
    case DBOI_NUMBER: {
      hb_itemPutNILen(pInfo->itmResult, hb_arrayGetNI(thiswa->aInfo, AINFO_INDEXORD), 3);
      break;
    }
    case DBOI_BAGNAME: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        pTemp = hb_itemArrayGet(pTag, ORDER_NAME);
        hb_itemCopy(pInfo->itmResult, pTemp);
        hb_itemRelease(pTemp);
        hb_itemRelease(pTag);
      } else {
        hb_itemPutC(pInfo->itmResult, "");
      }
      break;
    }
    case DBOI_NAME: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        pTemp = hb_itemArrayGet(pTag, ORDER_TAG);
        hb_itemCopy(pInfo->itmResult, pTemp);
        hb_itemRelease(pTemp);
        hb_itemRelease(pTag);
      } else {
        hb_itemPutC(pInfo->itmResult, "");
      }
      break;
    }
    case DBOI_POSITION:
    case DBOI_KEYNORAW: {
      hb_itemPutND(pInfo->itmResult, 0);
      break;
    }
    case DBOI_ISCOND: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        pTemp = hb_itemArrayGet(pTag, FOR_CLAUSE);
        hb_itemPutL(pInfo->itmResult, !HB_IS_NIL(pTemp));
        hb_itemRelease(pTemp);
        hb_itemRelease(pTag);
      } else {
        hb_itemPutL(pInfo->itmResult, 0);
      }
      break;
    }
    case DBOI_ISDESC: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        hb_itemPutL(pInfo->itmResult, hb_arrayGetL(pTag, DESCEND_INDEX_ORDER));

        if (pInfo->itmNewVal && HB_IS_LOGICAL(pInfo->itmNewVal)) {
          hb_itemPutL(pInfo->itmResult, hb_arrayGetL(thiswa->aInfo, AINFO_REVERSE_INDEX));
          hb_itemPutL(hb_arrayGetItemPtr(pTag, DESCEND_INDEX_ORDER), hb_itemGetL(pInfo->itmNewVal));
          hb_itemPutL(hb_arrayGetItemPtr(thiswa->aInfo, AINFO_REVERSE_INDEX), hb_itemGetL(pInfo->itmNewVal));
          hb_arraySetForward(pTag, ORDER_SKIP_UP, hb_itemNew(SR_NULLPTR));
          hb_arraySetForward(pTag, ORDER_SKIP_DOWN, hb_itemNew(SR_NULLPTR));
          hb_itemPutNL(hb_arrayGetItemPtr(thiswa->aInfo, AINFO_BOF_AT), 0);
          hb_itemPutNL(hb_arrayGetItemPtr(thiswa->aInfo, AINFO_EOF_AT), 0);
        }
        hb_itemRelease(pTag);
      } else {
        hb_itemPutL(pInfo->itmResult, HB_FALSE);
      }
      break;
    }
    case DBOI_UNIQUE: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        hb_itemPutL(pInfo->itmResult, hb_arrayGetL(pTag, AORDER_UNIQUE));
        hb_itemRelease(pTag);
      } else {
        hb_itemPutL(pInfo->itmResult, HB_FALSE);
      }
      break;
    }
    case DBOI_CUSTOM: {
      hb_itemPutL(pInfo->itmResult, HB_FALSE);
      break;
    }
    case DBOI_SCOPETOP: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        if (pInfo->itmResult) {
          pTemp = hb_itemArrayGet(pTag, TOP_SCOPE);
          hb_itemCopy(pInfo->itmResult, pTemp);
          hb_itemRelease(pTemp);
        }
        if (pInfo->itmNewVal) {
          sqlSetServerSideIndexScope((SQLAREAP)thiswa, 0, pInfo->itmNewVal);
        }
        hb_itemRelease(pTag);
      } else {
        hb_itemClear(pInfo->itmResult);
      }
      break;
    }
    case DBOI_SCOPEBOTTOM: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        if (pInfo->itmResult) {
          pTemp = hb_itemArrayGet(pTag, BOTTOM_SCOPE);
          hb_itemCopy(pInfo->itmResult, pTemp);
          hb_itemRelease(pTemp);
        }
        if (pInfo->itmNewVal) {
          sqlSetServerSideIndexScope((SQLAREAP)thiswa, 1, pInfo->itmNewVal);
        }
        hb_itemRelease(pTag);
      } else {
        hb_itemClear(pInfo->itmResult);
      }
      break;
    }
    case DBOI_SCOPETOPCLEAR: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        sqlSetServerSideIndexScope((SQLAREAP)thiswa, 0, SR_NULLPTR);
      }
      break;
    }
    case DBOI_SCOPEBOTTOMCLEAR: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        sqlSetServerSideIndexScope((SQLAREAP)thiswa, 1, SR_NULLPTR);
      }
      break;
    }
    case DBOI_SCOPESET: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        if (pInfo->itmResult) {
          pTemp = hb_itemArrayGet(pTag, TOP_SCOPE);
          hb_itemCopy(pInfo->itmResult, pTemp);
          hb_itemRelease(pTemp);
        }
        if (pInfo->itmNewVal) {
          sqlSetServerSideIndexScope((SQLAREAP)thiswa, TOP_BOTTOM_SCOPE, pInfo->itmNewVal);
        }
        hb_itemRelease(pTag);
      } else {
        hb_itemClear(pInfo->itmResult);
      }
      break;
    }
    case DBOI_KEYADD: {
      hb_itemPutL(pInfo->itmResult, HB_FALSE);
      break;
    }
    case DBOI_KEYDELETE: {
      hb_itemPutL(pInfo->itmResult, HB_FALSE);
      break;
    }
    case DBOI_KEYVAL: {
      pTag = loadTagDefault(thiswa, pInfo, &lorder);
      if (pTag) {
        if (thiswa->firstinteract) {
          SELF_GOTOP(&thiswa->area);
          thiswa->firstinteract = HB_FALSE;
        }

        pTemp = hb_itemArrayGet(pTag, INDEX_KEY);
        pMacro = hb_macroCompile(hb_itemGetCPtr(pTemp));
        hb_macroRun(pMacro);
        hb_macroDelete(pMacro);
        hb_itemMove(pInfo->itmResult, hb_stackItemFromTop(-1));
        hb_itemRelease(pTemp);
        hb_itemRelease(pTag);
      } else {
        hb_itemClear(pInfo->itmResult);
      }
      break;
    }
    case DBOI_ORDERCOUNT: {
      hb_itemPutNI(pInfo->itmResult, lIndexes);
      break; // TODO: unnecessary break
    }
    }
  } else {
    switch (uiIndex) {
    case DBOI_KEYCOUNTRAW: {
      HB_ULONG ulRecCount = 0;
      SELF_RECCOUNT(&thiswa->area, &ulRecCount);
      hb_itemPutND(pInfo->itmResult, ulRecCount);
      break;
    }
    case DBOI_KEYCOUNT: {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLKEYCOUNT, 0);
      hb_itemPutND(pInfo->itmResult, hb_itemGetND(hb_stackReturnItem()));
      break;
    }
    case DBOI_POSITION:
    case DBOI_KEYNORAW: {
      hb_itemPutND(pInfo->itmResult, 0);
      SELF_RECID(&thiswa->area, pInfo->itmResult);
      break;
    }
    case DBOI_ISCOND:
    case DBOI_ISDESC:
    case DBOI_UNIQUE:
    case DBOI_CUSTOM:
    case DBOI_KEYADD:
    case DBOI_KEYDELETE: {
      hb_itemPutL(pInfo->itmResult, HB_FALSE);
      break;
    }
    case DBOI_KEYVAL:
    case DBOI_SCOPETOP:
    case DBOI_SCOPEBOTTOM:
    case DBOI_SCOPETOPCLEAR:
    case DBOI_SCOPEBOTTOMCLEAR: {
      hb_itemClear(pInfo->itmResult);
      break;
    }
    case DBOI_ORDERCOUNT:
    case DBOI_NUMBER: {
      hb_itemPutNI(pInfo->itmResult, 0);
      break;
    }
    default: {
      hb_itemPutC(pInfo->itmResult, "");
    }
    }
  }

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlClearFilter(SQLAREAP thiswa)
{
  if (thiswa->sqlfilter) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLCLEARFILTER, 0);
    thiswa->sqlfilter = HB_FALSE;
  }
  return SUPER_CLEARFILTER(&thiswa->area);
}

//------------------------------------------------------------------------

#define sqlClearLocate SR_NULLPTR

//------------------------------------------------------------------------

#define sqlClearScope SR_NULLPTR

//------------------------------------------------------------------------

#define sqlCountScope SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlFilterText(SQLAREAP thiswa, PHB_ITEM pFilter)
{
  if (thiswa->sqlfilter) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLFILTERTEXT, 0);
    hb_itemCopy(pFilter, hb_stackReturnItem());
    return HB_SUCCESS;
  } else {
    return SUPER_FILTERTEXT(&thiswa->area, pFilter);
  }
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlScopeInfo(SQLAREAP thiswa, HB_USHORT nScope, PHB_ITEM pItem)
{
  HB_LONG lIndexes, lorder;
  PHB_ITEM pTag, pTemp;

  // sr_TraceLog(SR_NULLPTR, "sqlScopeInfo, nScope: %i\n", nScope);

  hb_itemClear(pItem);
  lIndexes = hb_itemSize(thiswa->aOrders);

  if (lIndexes) {
    // Exists opened orders ?
    if (HB_IS_OBJECT(thiswa->oWorkArea)) {
      PHB_ITEM pOrder = hb_itemNew(SR_NULLPTR);
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLORDERLISTNUM, 1, pOrder);
      hb_itemRelease(pOrder);
    } else {
      commonError(&thiswa->area, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
      return HB_FAILURE;
    }
    lorder = hb_itemGetNL(hb_stackReturnItem());
    if (lorder) {
      pTag = hb_itemArrayGet(thiswa->aOrders, (HB_ULONG)lorder);
      pTemp = hb_itemArrayGet(pTag, nScope ? BOTTOM_SCOPE : TOP_SCOPE);
      hb_itemCopy(pItem, pTemp);
      hb_itemRelease(pTag);
      hb_itemRelease(pTemp);
    }
  }
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlSetFilter(SQLAREAP thiswa, LPDBFILTERINFO pFilterInfo)
{
  PHB_ITEM filtertext;
  HB_ERRCODE res;

  if (thiswa->lpdbPendingRel) {
    if (SELF_FORCEREL(&thiswa->area) != HB_SUCCESS) {
      return HB_FAILURE;
    }
  }

  // Try to translate the filter expression into a valid SQL statement

  SUPER_CLEARFILTER(&thiswa->area);

  filtertext = hb_itemNew(pFilterInfo->abFilterText);

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLSETFILTER, 1, filtertext);
  hb_itemRelease(filtertext);
  res = hb_itemGetNI(hb_stackReturnItem());

  if (res == HB_SUCCESS) {
    thiswa->sqlfilter = HB_TRUE;
    return HB_SUCCESS;
  } else {
    return SUPER_SETFILTER(&thiswa->area, pFilterInfo);
  }
}

//------------------------------------------------------------------------

#define sqlSetLocate SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlSetScope(SQLAREAP thiswa, LPDBORDSCOPEINFO sInfo)
{
  PHB_ITEM scopetype;
  PHB_ITEM scopeval;
  int res;

  // sr_TraceLog(SR_NULLPTR, "sqlSetScope\n");

  scopetype = hb_itemPutNI(SR_NULLPTR, sInfo->nScope);
  scopeval = hb_itemNew(sInfo->scopeValue);

#ifndef HB_CDP_SUPPORT_OFF
  if (HB_IS_STRING(scopeval)) {
    PHB_CODEPAGE cdpSrc = thiswa->cdPageCnv ? thiswa->cdPageCnv : hb_vmCDP();
    if (thiswa->area.cdPage && thiswa->area.cdPage != cdpSrc) {
      HB_SIZE nLen = hb_itemGetCLen(scopeval);
      char *pszVal = hb_cdpnDup(hb_itemGetCPtr(scopeval), &nLen, cdpSrc, thiswa->area.cdPage);
      hb_itemPutCLPtr(scopeval, pszVal, nLen);
    }
  }
#endif

  hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLSETSCOPE, 2, scopetype, scopeval);
  res = hb_itemGetNI(hb_stackReturnItem());
  hb_itemRelease(scopetype);
  hb_itemRelease(scopeval);

  if ((!res) && sr_GoTopOnScope()) {
    thiswa->firstinteract = HB_TRUE;
  }

  return (res == 0) ? HB_SUCCESS : HB_FAILURE;
}

//------------------------------------------------------------------------

#define sqlSkipScope SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlLocate(SQLAREAP thiswa, HB_BOOL fContinue)
{
  HB_ERRCODE err;

  err = SUPER_LOCATE(&thiswa->area, fContinue);
  hb_arraySetL(thiswa->aInfo, AINFO_FOUND, thiswa->area.fFound);

  return err;
}

//------------------------------------------------------------------------

#define sqlCompile SR_NULLPTR
#define sqlError SR_NULLPTR
#define sqlEvalBlock SR_NULLPTR
#define sqlRawLock SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlLock(SQLAREAP thiswa, LPDBLOCKINFO pLockInfo)
{
  PHB_ITEM pRecord;

  // sr_TraceLog(SR_NULLPTR, "sqlLock\n");

  if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (hb_arrayGetL(thiswa->aInfo, AINFO_ISINSERT) || hb_arrayGetL(thiswa->aInfo, AINFO_EOF)) {
    pLockInfo->fResult = HB_TRUE;
    return HB_SUCCESS;
  }

  if (thiswa->shared) {
    PHB_ITEM pMethod = hb_itemPutNI(SR_NULLPTR, pLockInfo->uiMethod);

    switch (pLockInfo->uiMethod) {
    case DBLM_EXCLUSIVE: {
      pRecord = hb_itemNew(SR_NULLPTR);
      hb_arrayGet(thiswa->aInfo, AINFO_RECNO, pRecord);
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLLOCK, 2, pMethod, pRecord);
      hb_itemRelease(pRecord);
      pLockInfo->fResult = (HB_USHORT)hb_itemGetL(hb_stackReturnItem());
      break;
    }
    case DBLM_MULTIPLE: {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLLOCK, 2, pMethod, pLockInfo->itmRecID);
      pLockInfo->fResult = (HB_USHORT)hb_itemGetL(hb_stackReturnItem());
      break;
    }
    case DBLM_FILE: {
      hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLLOCK, 1, pMethod);
      pLockInfo->fResult = (HB_USHORT)hb_itemGetL(hb_stackReturnItem());
      break;
    }
    default: {
      pLockInfo->fResult = HB_FALSE;
    }
    }
    hb_itemRelease(pMethod);
  } else {
    pLockInfo->fResult = HB_TRUE;
  }

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlUnLock(SQLAREAP thiswa, PHB_ITEM pRecNo)
{
  if (thiswa->firstinteract) {
    SELF_GOTOP(&thiswa->area);
    thiswa->firstinteract = HB_FALSE;
  }

  if (pRecNo) {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLUNLOCK, 1, pRecNo);
  } else {
    hb_objSendMessage(thiswa->oWorkArea, s_pSym_SQLUNLOCK, 0);
  }

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlCloseMemFile SR_NULLPTR
#define sqlCreateMemFile SR_NULLPTR
#define sqlGetValueFile SR_NULLPTR
#define sqlOpenMemFile SR_NULLPTR
#define sqlPutValueFile SR_NULLPTR
#define sqlReadDBHeader SR_NULLPTR
#define sqlWriteDBHeader SR_NULLPTR
#define sqlInit SR_NULLPTR

//------------------------------------------------------------------------

static HB_ERRCODE sqlExit(LPRDDNODE pRDD)
{
  HB_SYMBOL_UNUSED(pRDD);
  HB_TRACE(HB_TR_DEBUG, ("sqlExit(%p)", pRDD));

  if (!s_pSym_SQLEXIT) {
    s_pSym_SQLEXIT = hb_dynsymFindName("SR_END");
  }
  hb_vmPushDynSym(s_pSym_SQLEXIT);
  hb_vmPushNil();
  hb_vmDo(0);
  return HB_SUCCESS;
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlDrop(PHB_ITEM pItemTable)
{
  // sr_TraceLog(SR_NULLPTR, "sqlDrop\n");

  hb_vmPushDynSym(s_pSym_WORKAREA);
  hb_vmPushNil();
  hb_vmDo(0);

  if (hb_stackReturnItem()) {
    hb_objSendMessage(hb_stackReturnItem(), s_pSym_SQLDROP, 1, pItemTable);
  } else {
    commonError(SR_NULLPTR, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
    return HB_FAILURE;
  }

  return HB_SUCCESS;
}

// returns 1 if exists, 0 else
//------------------------------------------------------------------------

HB_BOOL sqlExists(PHB_ITEM pItemTable, PHB_ITEM pItemIndex)
{
  // sr_TraceLog(SR_NULLPTR, "sqlExists\n");

  hb_vmPushDynSym(s_pSym_WORKAREA);
  hb_vmPushNil();
  hb_vmDo(0);

  if (HB_IS_OBJECT(hb_stackReturnItem())) {
    if (pItemTable) {
      hb_objSendMessage(hb_stackReturnItem(), s_pSym_SQLEXISTS, 1, pItemTable);
    } else if (pItemIndex) {
      hb_objSendMessage(hb_stackReturnItem(), s_pSym_SQLEXISTS, 1, pItemIndex);
    } else {
      return HB_FAILURE;
    }
  } else {
    commonError(SR_NULLPTR, EG_DATATYPE, ESQLRDD_DATATYPE, SR_NULLPTR);
    return HB_FAILURE;
  }

  return hb_itemGetL(hb_stackReturnItem());
}

//------------------------------------------------------------------------

static HB_ERRCODE sqlRddInfo(LPRDDNODE pRDD, HB_USHORT uiIndex, HB_ULONG ulConnect, PHB_ITEM pItem)
{
  HB_TRACE(HB_TR_DEBUG, ("sqlRddInfo(%p, %hu, %lu, %p)", pRDD, uiIndex, ulConnect, pItem));

  switch (uiIndex) {
  case RDDI_ORDBAGEXT:
  case RDDI_ORDEREXT:
  case RDDI_ORDSTRUCTEXT: {
    hb_itemPutC(pItem, SR_NULLPTR);
    break;
  }
  case RDDI_MULTITAG:
  case RDDI_SORTRECNO:
  case RDDI_STRUCTORD:
  case RDDI_MULTIKEY: {
    hb_itemPutL(pItem, HB_TRUE);
    break;
  }
  default: {
    return SUPER_RDDINFO(pRDD, uiIndex, ulConnect, pItem);
  }
  }

  return HB_SUCCESS;
}

//------------------------------------------------------------------------

#define sqlWhoCares SR_NULLPTR

//------------------------------------------------------------------------

static HB_BOOL ProcessFields(SQLAREAP thiswa)
{
  DBFIELDINFO field;
  HB_LONG numFields;
  HB_BYTE *fieldType;
  HB_USHORT i;
  PHB_ITEM thisfield;

  if (hb_itemType(thiswa->aStruct) != HB_IT_ARRAY) {
    HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Invalid structure array"));
    return HB_FALSE;
  }

  numFields = hb_itemSize(thiswa->aStruct);

  if (!numFields) {
    HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Empty structure array"));
    return HB_FALSE;
  }

  SELF_SETFIELDEXTENT(&thiswa->area, (HB_USHORT)numFields);

  for (i = 1; i <= (HB_USHORT)numFields; i++) {
    thisfield = hb_itemArrayGet(thiswa->aStruct, i);

    if (hb_itemType(thisfield) != HB_IT_ARRAY) {
      HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Empty structure field array: %i", i));
      return HB_FALSE;
    }

    // Clear out the field
    memset(&field, 0, sizeof(field));

    field.uiTypeExtended = 0;
    field.atomName = hb_arrayGetC(thisfield, (HB_USHORT)1);
    field.uiDec = (HB_USHORT)0;
    field.uiLen = (HB_USHORT)hb_arrayGetNI(thisfield, (HB_USHORT)3);

    thiswa->uiBufferIndex[i - 1] = (int)hb_arrayGetNI(thisfield, (HB_USHORT)5);

    fieldType = (unsigned char *)hb_arrayGetCPtr(thisfield, (HB_USHORT)2);

    switch (*fieldType) {
    case 'c':
    case 'C': {
      field.uiType = HB_FT_STRING;
      break;
    }
    case 'm':
    case 'M': {
      field.uiType = HB_FT_MEMO;
      break;
    }
    case 'n':
    case 'N': {
      field.uiType = HB_FT_LONG;
      field.uiDec = (HB_USHORT)hb_arrayGetNI(thisfield, (HB_USHORT)4);
      break;
    }
    case 'l':
    case 'L': {
      field.uiType = HB_FT_LOGICAL;
      break;
    }
    case 'd':
    case 'D': {
      field.uiType = HB_FT_DATE;
      break;
    }
    case 'v':
    case 'V': {
      field.uiType = HB_FT_ANY;
      break;
    }
    // new field type
    case 't':
    case 'T': {
      if (field.uiLen == 4) {
        field.uiType = HB_FT_TIME;
      } else {
        field.uiType = HB_FT_TIMESTAMP;
      }
      break;
    }
    default: {
      field.uiType = HB_IT_NIL;
      break; // TODO: unnecessary break
    }
    }

    if (field.uiType == HB_IT_NIL) {
      HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Unsuported datatype on field: %i", i));
      return HB_FALSE;
    }

    // Add the field

    if (SELF_ADDFIELD(&thiswa->area, (LPDBFIELDINFO)&field) != HB_SUCCESS) {
      HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Could not add field: %i", i));
    }
    hb_itemRelease(thisfield);
    hb_xfree((void *)field.atomName);
  }
  return HB_TRUE;
}

//------------------------------------------------------------------------

static HB_BOOL SetFields(SQLAREAP thiswa)
{
  HB_LONG numFields;
  HB_USHORT i;
  PHB_ITEM thisfield;

  if (hb_itemType(thiswa->aStruct) != HB_IT_ARRAY) {
    HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Invalid structure array"));
    return HB_FALSE;
  }

  numFields = hb_itemSize(thiswa->aStruct);

  if (!numFields) {
    HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Empty structure array"));
    return HB_FALSE;
  }

  for (i = 1; i <= (HB_USHORT)numFields; i++) {
    thisfield = hb_itemArrayGet(thiswa->aStruct, i);

    if (hb_itemType(thisfield) != HB_IT_ARRAY) {
      HB_TRACE(HB_TR_ALWAYS, ("SQLRDD: Empty structure field array: %i", i));
      return HB_FALSE;
    }

    thiswa->uiBufferIndex[i - 1] = (int)hb_arrayGetNI(thisfield, (HB_USHORT)5);
    hb_itemRelease(thisfield);
  }
  return HB_TRUE;
}

//------------------------------------------------------------------------

void commonError(AREAP thiswa, HB_USHORT uiGenCode, HB_USHORT uiSubCode, char *filename)
{
  PHB_ITEM pError = hb_errNew();

  hb_errPutGenCode(pError, uiGenCode);
  hb_errPutSubCode(pError, uiSubCode);
  hb_errPutSeverity(pError, ES_ERROR);
  hb_errPutTries(pError, EF_NONE);
  hb_errPutSubSystem(pError, "SQLRDD");
#ifdef __XHARBOUR__
  hb_errPutModuleName(pError, "SQLRDD");
#endif

  hb_errPutDescription(pError, hb_langDGetErrorDesc(uiGenCode));

  if (filename) {
    hb_errPutFileName(pError, filename);
  }

  SUPER_ERROR(thiswa, pError);

  hb_itemRelease(pError);

  return;
}

//------------------------------------------------------------------------

// ITEMCMP(cItem1, cItem2, nLenToCompare) ==> 0 == identical, < 0 if cItem1 < cIten2, > 0 == cItem1 > cIten2
HB_FUNC(ITEMCMP)
{
  int ret;
  const char *val1;
  const char *val2;

  val1 = hb_itemGetCPtr(hb_param(1, HB_IT_ANY));
  val2 = hb_itemGetCPtr(hb_param(2, HB_IT_ANY));
  ret = strncmp(val1, val2, hb_parnl(3));

  hb_retni(ret);
}

//------------------------------------------------------------------------

HB_BOOL iTemCompEqual(PHB_ITEM pItem1, PHB_ITEM pItem2)
{
  if (HB_IS_NIL(pItem1) || HB_IS_NIL(pItem2)) {
    return HB_FALSE;
  }

  if (HB_IS_STRING(pItem1) && HB_IS_STRING(pItem2)) {
    return hb_itemStrCmp(pItem1, pItem2, HB_FALSE) == 0;
  } else if (HB_IS_NUMINT(pItem1) && HB_IS_NUMINT(pItem2)) {
    return hb_itemGetNInt(pItem1) == hb_itemGetNInt(pItem2);
  } else if (HB_IS_NUMERIC(pItem1) && HB_IS_NUMERIC(pItem2)) {
    return hb_itemGetND(pItem1) == hb_itemGetND(pItem2);
  } else if (HB_IS_DATE(pItem1) && HB_IS_DATE(pItem2)) {
    return hb_itemGetDL(pItem1) == hb_itemGetDL(pItem2);
  } else {
    return HB_FALSE;
  }
}

//------------------------------------------------------------------------

#ifdef _WIN32

HB_FUNC(SR_GETCURRINSTANCEID)
{
  hb_retni(GetCurrentProcessId());
}

#else

HB_FUNC(SR_GETCURRINSTANCEID)
{
  pid_t Thispid = getpid();
  hb_retni(Thispid);
}

#endif

//------------------------------------------------------------------------

// clang-format off
static const RDDFUNCS sqlTable =
{
  // Movement and positioning methods

  (DBENTRYP_BP)sqlBof,
  (DBENTRYP_BP)sqlEof,
  (DBENTRYP_BP)sqlFound,
  (DBENTRYP_V)sqlGoBottom,
  (DBENTRYP_UL)sqlGoTo,
  (DBENTRYP_I)sqlGoToId,
  (DBENTRYP_V)sqlGoTop,
  (DBENTRYP_BIB)sqlSeek,
  (DBENTRYP_L)sqlSkip,
  (DBENTRYP_L)sqlSkipFilter,
  (DBENTRYP_L)sqlSkipRaw,

  // Data management

  (DBENTRYP_VF)sqlAddField,
  (DBENTRYP_B)sqlAppend,
  (DBENTRYP_I)sqlCreateFields,
  (DBENTRYP_V)sqlDeleteRec,
  (DBENTRYP_BP)sqlDeleted,
  (DBENTRYP_SP)sqlFieldCount,
  (DBENTRYP_VF)sqlFieldDisplay,
  (DBENTRYP_SSI)sqlFieldInfo,
  (DBENTRYP_SCP)sqlFieldName,
  (DBENTRYP_V)sqlFlush,
  (DBENTRYP_PP)sqlGetRec,
  (DBENTRYP_SI)sqlGetValue,
  (DBENTRYP_SVL)sqlGetVarLen,
  (DBENTRYP_V)sqlGoCold,
  (DBENTRYP_V)sqlGoHot,
  (DBENTRYP_P)sqlPutRec,
  (DBENTRYP_SI)sqlPutValue,
  (DBENTRYP_V)sqlRecall,
  (DBENTRYP_ULP)sqlRecCount,
  (DBENTRYP_ISI)sqlRecInfo,
  (DBENTRYP_ULP)sqlRecNo,
  (DBENTRYP_I)sqlRecId,
  (DBENTRYP_S)sqlSetFieldExtent,

  // WorkArea/Database management

  (DBENTRYP_CP)sqlAlias,
  (DBENTRYP_V)sqlClose,
  (DBENTRYP_VO)sqlCreate,
  (DBENTRYP_SI)sqlInfo,
  (DBENTRYP_V)sqlNewArea,
  (DBENTRYP_VO)sqlOpen,
  (DBENTRYP_V)sqlRelease,
  (DBENTRYP_SP)sqlStructSize,
  (DBENTRYP_CP)sqlSysName,
  (DBENTRYP_VEI)sqlEval,
  (DBENTRYP_V)sqlPack,
  (DBENTRYP_LSP)sqlPackRec,
  (DBENTRYP_VS)sqlSort,
  (DBENTRYP_VT)sqlTrans,
  (DBENTRYP_VT)sqlTransRec,
  (DBENTRYP_V)sqlZap,

  // Relational Methods

  (DBENTRYP_VR)sqlChildEnd,
  (DBENTRYP_VR)sqlChildStart,
  (DBENTRYP_VR)sqlChildSync,
  (DBENTRYP_V)sqlSyncChildren,
  (DBENTRYP_V)sqlClearRel,
  (DBENTRYP_V)sqlForceRel,
  (DBENTRYP_SSP)sqlRelArea,
  (DBENTRYP_VR)sqlRelEval,
  (DBENTRYP_SI)sqlRelText,
  (DBENTRYP_VR)sqlSetRel,

   // Order Management

  (DBENTRYP_VOI)sqlOrderListAdd,
  (DBENTRYP_V)sqlOrderListClear,
  (DBENTRYP_VOI)sqlOrderListDelete,
  (DBENTRYP_VOI)sqlOrderListFocus,
  (DBENTRYP_V)sqlOrderListRebuild,
  (DBENTRYP_VOO)sqlOrderCondition,
  (DBENTRYP_VOC)sqlOrderCreate,
  (DBENTRYP_VOI)sqlOrderDestroy,
  (DBENTRYP_SVOI)sqlOrderInfo,

  // Filters and Scope Settings

  (DBENTRYP_V)sqlClearFilter,
  (DBENTRYP_V)sqlClearLocate,
  (DBENTRYP_V)sqlClearScope,
  (DBENTRYP_VPLP)sqlCountScope,
  (DBENTRYP_I)sqlFilterText,
  (DBENTRYP_SI)sqlScopeInfo,
  (DBENTRYP_VFI)sqlSetFilter,
  (DBENTRYP_VLO)sqlSetLocate,
  (DBENTRYP_VOS)sqlSetScope,
  (DBENTRYP_VPL)sqlSkipScope,
  (DBENTRYP_B)sqlLocate,

  // Miscellaneous

  (DBENTRYP_CC)sqlCompile,
  (DBENTRYP_I)sqlError,
  (DBENTRYP_I)sqlEvalBlock,

  // Network operations

  (DBENTRYP_VSP)sqlRawLock,
  (DBENTRYP_VL)sqlLock,
  (DBENTRYP_I)sqlUnLock,

  // Memofile functions

  (DBENTRYP_V)sqlCloseMemFile,
  (DBENTRYP_VO)sqlCreateMemFile,
  (DBENTRYP_SCCS)sqlGetValueFile,
  (DBENTRYP_VO)sqlOpenMemFile,
  (DBENTRYP_SCCS)sqlPutValueFile,

  // Database file header handling

  (DBENTRYP_V)sqlReadDBHeader,
  (DBENTRYP_V)sqlWriteDBHeader,

  // non WorkArea functions

  (DBENTRYP_R)sqlInit,
  (DBENTRYP_R)sqlExit,
  (DBENTRYP_RVVL)sqlDrop,
  (DBENTRYP_RVVL)sqlExists,
  (DBENTRYP_RVVVL)SR_NULLPTR, // sqlRename
  (DBENTRYP_RSLV)sqlRddInfo,

  // Special and reserved methods

  (DBENTRYP_SVP)sqlWhoCares
};
// clang-format on

HB_FUNC(SQLRDD)
{
}

HB_FUNC(SQLRDD_GETFUNCTABLE)
{
  RDDFUNCS *pTable;
  HB_USHORT *uiCount;

  startSQLRDDSymbols();

  uiCount = (HB_USHORT *)hb_parptr(1);
  pTable = (RDDFUNCS *)hb_parptr(2);

  HB_TRACE(HB_TR_DEBUG, ("SQLRDD_GETFUNCTABLE(%p, %p)", uiCount, pTable));

  if (pTable) {
    HB_ERRCODE errCode;

    if (uiCount) {
      *uiCount = RDDFUNCSCOUNT;
    }
    errCode = hb_rddInherit(pTable, &sqlTable, &sqlrddSuper, SR_NULLPTR);
    hb_retni(errCode);
  } else {
    hb_retni(HB_FAILURE);
  }
}

#define __PRG_SOURCE__ __FILE__

#ifdef HB_PCODE_VER
#undef HB_PRG_PCODE_VER
#define HB_PRG_PCODE_VER HB_PCODE_VER
#endif

static void hb_sqlrddRddInit(void *cargo)
{
  int usResult;
  HB_SYMBOL_UNUSED(cargo);

  usResult = hb_rddRegister("SQLRDD", RDT_FULL);
  if (usResult <= 1) {
    if (usResult == 0) {
      PHB_DYNS pDynSym;
      if (!s_pSym_SQLINIT) {
        s_pSym_SQLINIT = hb_dynsymFindName("SR_INIT");
      }
      hb_vmPushDynSym(s_pSym_SQLINIT);
      hb_vmPushNil();
      hb_vmDo(0);

      pDynSym = hb_dynsymFind("__SR_STARTSQL");

      if (pDynSym && hb_dynsymIsFunction(pDynSym)) {
        hb_vmPushDynSym(pDynSym);
        hb_vmPushNil();
        hb_vmDo(0);
      }
    }
    return;
  }

  hb_errInternal(HB_EI_RDDINVALID, SR_NULLPTR, SR_NULLPTR, SR_NULLPTR);
}

// clang-format off
HB_INIT_SYMBOLS_BEGIN(sqlrdd1__InitSymbols)
  {"SQLRDD", {HB_FS_PUBLIC | HB_FS_LOCAL}, {HB_FUNCNAME(SQLRDD)}, SR_NULLPTR},
  {"SQLRDD_GETFUNCTABLE", {HB_FS_PUBLIC | HB_FS_LOCAL}, {HB_FUNCNAME(SQLRDD_GETFUNCTABLE)}, SR_NULLPTR}
HB_INIT_SYMBOLS_END(sqlrdd1__InitSymbols)
// clang-format on

// clang-format off
HB_CALL_ON_STARTUP_BEGIN(_hb_sqlrdd_rdd_init_)
  hb_vmAtInit(hb_sqlrddRddInit, SR_NULLPTR);
HB_CALL_ON_STARTUP_END(_hb_sqlrdd_rdd_init_)
// clang-format on

#if defined(HB_PRAGMA_STARTUP)
#pragma startup sqlrdd1__InitSymbols
#pragma startup _hb_sqlrdd_rdd_init_
#elif defined(HB_DATASEG_STARTUP)
#define HB_DATASEG_BODY                                                                                                \
  HB_DATASEG_FUNC(sqlrdd1__InitSymbols)                                                                                \
  HB_DATASEG_FUNC(_hb_sqlrdd_rdd_init_)
#include "hbiniseg.h"
#endif

HB_FUNC(SR_SETFOUND)
{
  SQLAREAP pArea = (SQLAREAP)hb_rddGetCurrentWorkAreaPointer();

  if (pArea) {
    PHB_ITEM pFound = hb_param(1, HB_IT_LOGICAL);
    if (pFound) {
      pArea->area.fFound = hb_itemGetL(pFound);
      hb_arraySetForward(pArea->aInfo, AINFO_FOUND, pFound);
    }
  } else {
    hb_errRT_DBCMD(EG_NOTABLE, EDBCMD_NOTABLE, SR_NULLPTR, HB_ERR_FUNCNAME);
  }
}
