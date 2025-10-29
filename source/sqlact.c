// SQLPARSER
// SQL Parser Actions
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

#define WIN32_LEAN_AND_MEAN

#include "sqlrddpp.h"
#include "compat.h"
#include "hbsql.h"

#include <ctype.h>

#include "sqly.h" // Bison-generated include
#include "msg.ch"
#include "sqlrdd.h"
#include "sqlrddsetup.ch"

#define MAX_FIELD_NAME_LEN 63

// Prototypes

int SqlParse(sql_stmt *stmt, const char *query, int queryLen);
int sql_yyparse(void *stmt);

// PRG Level Functions

HB_FUNC(SR_SQLPARSE) // SqlParse(cCommand, @nError, @nErrorPos)
{
  HB_SIZE uLenPhrase = hb_parclen(1);

  if (uLenPhrase) {
    // sql_stmt * stmt = (sql_stmt *) hb_xgrab(sizeof(sql_stmt));
    sql_stmt *stmt = (sql_stmt *)hb_xgrabz(sizeof(sql_stmt));

    const char *sqlPhrase;
    const char *sqlIniPos;

    //       memset(stmt, 0, sizeof(sql_stmt));
    sqlIniPos = sqlPhrase = hb_parc(1);

    if (SqlParse(stmt, sqlPhrase, PARSE_ALL_QUERY)) {
      // printf("Parse OK. Retornado array de %i posicoes.\n", stmt->pArray->item.asArray.value->ulLen);
    } else {
      stmt->pArray = hb_itemArrayNew(0);
      // printf("Parse ERROR. Retornado array de %i posicoes.\n", stmt->pArray->item.asArray.value->ulLen);

      if (HB_ISBYREF(2)) {
        hb_itemPutNI((PHB_ITEM)hb_param(2, HB_IT_ANY), stmt->errMsg);
      }
      if (HB_ISBYREF(3)) {
        hb_itemPutNI((PHB_ITEM)hb_param(3, HB_IT_ANY), (int)(stmt->queryPtr - sqlIniPos));
      }
    }
    hb_itemRelease(hb_itemReturnForward(stmt->pArray));
    hb_xfree(stmt);
  }
}

// Parser Entry Point

int SqlParse(sql_stmt *stmt, const char *query, int queryLen)
{
  if (!query) {
    stmt->errMsg = SQL_PARSER_ERROR_PARSE;
    stmt->errPtr = "";
    return 0;
  }
  if (!queryLen) {
    queryLen = (int)strlen(query) + 1;
  }

  stmt->query = query;
  stmt->queryLen = queryLen;
  stmt->queryPtr = stmt->errPtr = query;
  stmt->errMsg = 0;

  if (sql_yyparse((void *)stmt) || stmt->errMsg || stmt->command == -1) {
    // printf("parse error in sql_yyparse\n");
    if (!stmt->errMsg) {
      stmt->errMsg = SQL_PARSER_ERROR_PARSE;
    }
    return 0;
  }

  return 1;
}

// pCode Generation and handling

PHB_ITEM SQLpCodeGenInt(int code)
{
  PHB_ITEM pArray;

  pArray = hb_itemArrayNew(1);
  hb_itemPutNILen(hb_arrayGetItemPtr(pArray, 1), code, 6);

  return pArray;
}

PHB_ITEM SQLpCodeGenIntItem(int code, PHB_ITEM value)
{
  PHB_ITEM pArray;

  pArray = hb_itemArrayNew(2);
  hb_itemPutNILen(hb_arrayGetItemPtr(pArray, 1), code, 6);
  hb_arraySetForward(pArray, 2, value);
  hb_itemRelease(value);

  return pArray;
}

PHB_ITEM SQLpCodeGenItemInt(PHB_ITEM value, int code)
{
  PHB_ITEM pArray;

  pArray = hb_itemArrayNew(2);
  hb_arraySetForward(pArray, 1, value);
  hb_itemPutNILen(hb_arrayGetItemPtr(pArray, 2), code, 6);
  // TOCHECK: hb_itemRelease(value);

  return pArray;
}

PHB_ITEM SQLpCodeGenIntItem2(int code, PHB_ITEM value, int code2, PHB_ITEM value2)
{
  PHB_ITEM pArray;

  pArray = hb_itemArrayNew(4);

  hb_itemPutNILen(hb_arrayGetItemPtr(pArray, 1), code, 6);
  hb_arraySetForward(pArray, 2, value);
  hb_itemPutNILen(hb_arrayGetItemPtr(pArray, 3), code2, 6);
  hb_arraySetForward(pArray, 4, value2);

  hb_itemRelease(value);
  hb_itemRelease(value2);

  return pArray;
}

PHB_ITEM SQLpCodeGenArrayJoin(PHB_ITEM pArray1, PHB_ITEM pArray2)
{
  HB_SIZE nLen, n;

  if (!HB_IS_ARRAY(pArray1)) {
    printf("SQLpCodeGenArrayJoin Invalid param 1\n");
  }

  if (!HB_IS_ARRAY(pArray2)) {
    printf("SQLpCodeGenArrayJoin Invalid param 2\n");
  }

  nLen = hb_arrayLen(pArray2);
  for (n = 1; n <= nLen; n++) {
    hb_arrayAddForward(pArray1, hb_arrayGetItemPtr(pArray2, n));
  }
  hb_itemRelease(pArray2);
  return pArray1;
}

PHB_ITEM SQLpCodeGenArrayItem(PHB_ITEM pArray, PHB_ITEM value)
{
  hb_arrayAddForward(pArray, value);
  hb_itemRelease(value);
  return pArray;
}

PHB_ITEM SQLpCodeGenArrayInt(PHB_ITEM pArray, int code)
{
  PHB_ITEM pItem = hb_itemPutNILen(SR_NULLPTR, code, 6);

  hb_arrayAddForward(pArray, pItem);
  hb_itemRelease(pItem);

  return pArray;
}

PHB_ITEM SQLpCodeGenArrayIntInt(PHB_ITEM pArray, int code, int code2)
{
  PHB_ITEM pItem;

  pItem = hb_itemPutNILen(SR_NULLPTR, code, 6);
  hb_arrayAddForward(pArray, pItem);
  hb_itemPutNILen(pItem, code2, 6);
  hb_arrayAddForward(pArray, pItem);
  hb_itemRelease(pItem);

  return pArray;
}

PHB_ITEM SQLpCodeGenIntArray(int code, PHB_ITEM pArray)
{
  PHB_ITEM pItem;

  pItem = hb_itemNew(SR_NULLPTR);
  hb_arrayAdd(pArray, pItem);
  hb_arrayIns(pArray, 1);
  hb_itemPutNILen(pItem, code, 6);
  hb_arraySetForward(pArray, 1, pItem);
  hb_itemRelease(pItem);

  return pArray;
}

HB_FUNC(SR_STRTOHEX)
{
  char *outbuff;
  const char *cStr;
  char *c;
  HB_USHORT iNum;
  int i, len;
  int iCipher;

  if (!HB_ISCHAR(1)) {
    hb_errRT_BASE_SubstR(EG_ARG, 3012, SR_NULLPTR, "SR_STRTOHEX", 1, hb_param(1, HB_IT_ANY));
    return;
  }

  cStr = hb_parc(1);
  len = (int)hb_parclen(1);
  outbuff = (char *)hb_xgrab((len * 2) + 1);
  c = outbuff;

  for (i = 0; i < len; i++) {

    iNum = (int)cStr[i];
    c[0] = '0';
    c[1] = '0';

    iCipher = (int)(iNum % 16);

    if (iCipher < 10) {
      c[1] = '0' + (char)iCipher;
    } else {
      c[1] = 'A' + (char)(iCipher - 10);
    }
    iNum >>= 4;

    iCipher = iNum % 16;
    if (iCipher < 10) {
      c[0] = '0' + (char)iCipher;
    } else {
      c[0] = 'A' + (char)(iCipher - 10);
    }

    c += 2;
  }

  outbuff[len * 2] = '\0';
  hb_retc(outbuff);
  hb_xfree(outbuff);
}

char *sr_Hex2Str(const char *cStr, int len, int *lenOut)
{
  char *outbuff;
  char c;
  int i, nalloc;
  int iCipher, iNum;

  nalloc = (int)(len / 2);
  outbuff = (char *)hb_xgrab(nalloc + 1);

  for (i = 0; i < nalloc; i++) {
    // First byte

    c = *cStr;
    iNum = 0;
    iNum <<= 4;
    iCipher = 0;

    if (c >= '0' && c <= '9') {
      iCipher = (HB_ULONG)(c - '0');
    } else if (c >= 'A' && c <= 'F') {
      iCipher = (HB_ULONG)(c - 'A') + 10;
    } else if (c >= 'a' && c <= 'f') {
      iCipher = (HB_ULONG)(c - 'a') + 10;
    }

    iNum += iCipher;
    cStr++;

    // Second byte

    c = *cStr;
    iNum <<= 4;
    iCipher = 0;

    if (c >= '0' && c <= '9') {
      iCipher = (HB_ULONG)(c - '0');
    } else if (c >= 'A' && c <= 'F') {
      iCipher = (HB_ULONG)(c - 'A') + 10;
    } else if (c >= 'a' && c <= 'f') {
      iCipher = (HB_ULONG)(c - 'a') + 10;
    }

    iNum += iCipher;
    cStr++;
    outbuff[i] = (char)iNum;
  }

  outbuff[nalloc] = '\0';

  *lenOut = nalloc;

  return outbuff;
}

HB_FUNC(SR_HEXTOSTR)
{
  char *outbuff;
  int nalloc;

  if (!HB_ISCHAR(1)) {
    hb_errRT_BASE_SubstR(EG_ARG, 3012, SR_NULLPTR, "SR_HEXTOSTR", 1, hb_param(1, HB_IT_ANY));
    return;
  }

  outbuff = sr_Hex2Str(hb_parc(1), (int)hb_parclen(1), &nalloc);
  hb_retclen_buffer(outbuff, nalloc);
}

//---------------------------------------------------------------------------//

static HB_SIZE escape_mysql(char *to, const char *from, HB_SIZE length)
{
  const char *to_start = to;
  const char *end;
  for (end = from + length; from != end; from++) {
    switch (*from) {
    case 0: { // Must be escaped for 'mysql'
      *to++ = '\\';
      *to++ = '0';
      break;
    }
    case '\n': { // Must be escaped for logs
      *to++ = '\\';
      *to++ = 'n';
      break;
    }
    case '\r': {
      *to++ = '\\';
      *to++ = 'r';
      break;
    }
    case '\\': {
      *to++ = '\\';
      *to++ = '\\';
      break;
    }
    case '\'': {
      *to++ = '\\';
      *to++ = '\'';
      break;
    }
    case '"': { // Better safe than sorry
      *to++ = '\\';
      *to++ = '"';
      break;
    }
    case '\032': { // This gives problems on Win32
      *to++ = '\\';
      *to++ = 'Z';
      break;
    }
    default: {
      *to++ = *from;
    }
    }
  }
  *to = 0;
  return (HB_SIZE)(to - to_start);
}

static HB_SIZE escape_single(char *to, const char *from, HB_SIZE length)
{
  const char *to_start = to;
  const char *end;
  for (end = from + length; from != end; from++) {
    switch (*from) {
    case '\'': {
      *to++ = '\'';
      *to++ = '\'';
      break;
    }
    default: {
      *to++ = *from;
    }
    }
  }
  *to = 0;
  return (HB_SIZE)(to - to_start);
}

static HB_SIZE escape_firebird(char *to, const char *from, HB_SIZE length)
{
  const char *to_start = to;
  const char *end;
  for (end = from + length; from != end; from++) {
    switch (*from) {
    case '\'': {
      *to++ = '\'';
      *to++ = '\'';
      break;
    }
    case 0: {
      *to++ = ' ';
      break;
    }
    default: {
      *to++ = *from;
    }
    }
  }
  *to = 0;
  return (HB_SIZE)(to - to_start);
}

static HB_SIZE escape_db2(char *to, const char *from, HB_SIZE length)
{
  const char *to_start = to;
  const char *end;
  for (end = from + length; from != end; from++) {
    switch (*from) {
    case '\'': {
      *to++ = '\'';
      *to++ = '\'';
      break;
    }
    case 0: {
      *to++ = ' ';
      break;
    }
    default: {
      *to++ = *from;
    }
    }
  }
  *to = 0;
  return (HB_SIZE)(to - to_start);
}

static HB_SIZE escape_pgs(char *to, const char *from, HB_SIZE length)
{
  const char *to_start = to;
  const char *end;
  for (end = from + length; from != end; from++) {
    switch (*from) {
    case '\'': {
      *to++ = '\'';
      *to++ = '\'';
      break;
    }
    case '\\': {
      *to++ = '\\';
      *to++ = '\\';
      break;
    }
    case 0: {
      break;
    }
    default: {
      *to++ = *from;
    }
    }
  }
  *to = 0;
  return (HB_SIZE)(to - to_start);
}

static HB_SIZE escape_oci(char *to, const char *from, HB_SIZE length)
{
  const char *to_start = to;
  const char *end;
  for (end = from + length; from != end; from++) {
    switch (*from) {
    case '\'': {
      *to++ = '\'';
      *to++ = '\'';
      break;
    }
    case 0: {
      break;
    }
    default: {
      *to++ = *from;
    }
    }
  }
  *to = 0;
  return (HB_SIZE)(to - to_start);
}

HB_FUNC(SR_ESCAPESTRING)
{
  const char *FromBuffer;
  HB_SIZE iSize;
  int idatabase;
  char *ToBuffer;

  iSize = hb_parclen(1);
  idatabase = hb_parni(2);

  if (!(HB_ISCHAR(1) && HB_ISNUM(2))) {
    hb_errRT_BASE_SubstR(EG_ARG, 3012, SR_NULLPTR, "SR_ESCAPESTRING", 2, hb_param(1, HB_IT_ANY),
                         hb_param(2, HB_IT_ANY));
    return;
  }

  if (iSize) {
    FromBuffer = hb_parc(1);
    ToBuffer = (char *)hb_xgrab((iSize * 2) + 1);
    if (ToBuffer) {
      switch (idatabase) {
      case SQLRDD_RDBMS_MYSQL:
      case SQLRDD_RDBMS_MARIADB: {
        iSize = escape_mysql(ToBuffer, FromBuffer, iSize);
        break;
      }
      case SQLRDD_RDBMS_FIREBR:
      case SQLRDD_RDBMS_FIREBR3:
      case SQLRDD_RDBMS_FIREBR4:
      case SQLRDD_RDBMS_FIREBR5: {
        iSize = escape_firebird(ToBuffer, FromBuffer, iSize);
        break;
      }
      case SQLRDD_RDBMS_ORACLE:
      case SQLRDD_RDBMS_CACHE: {
        iSize = escape_oci(ToBuffer, FromBuffer, iSize);
        break;
      }
      case SQLRDD_RDBMS_MSSQL7:
      case SQLRDD_RDBMS_INGRES:
      case SQLRDD_RDBMS_SYBASE:
      case SQLRDD_RDBMS_ADABAS:
      case SQLRDD_RDBMS_INFORM:
      case SQLRDD_RDBMS_OTERRO:
      case SQLRDD_RDBMS_PERVASIVE: {
        iSize = escape_single(ToBuffer, FromBuffer, iSize);
        break;
      }
      case SQLRDD_RDBMS_POSTGR: {
        iSize = escape_pgs(ToBuffer, FromBuffer, iSize);
        break;
      }
      case SQLRDD_RDBMS_IBMDB2: {
        iSize = escape_db2(ToBuffer, FromBuffer, iSize);
        break; // TODO: unnecessary break
      }
      }
    }
    hb_retclen_buffer((char *)ToBuffer, iSize);
  } else {
    hb_retc("");
  }
}

char *QuoteTrimEscapeString(const char *FromBuffer, HB_SIZE iSize, int idatabase, HB_BOOL bRTrim, HB_SIZE *iSizeOut)
{
  char *ToBuffer;

  ToBuffer = (char *)hb_xgrab((iSize * 2) + 3);

  ToBuffer[0] = '\'';
  ToBuffer++;

  switch (idatabase) {
  case SQLRDD_RDBMS_MYSQL:
  case SQLRDD_RDBMS_MARIADB: {
    iSize = escape_mysql(ToBuffer, FromBuffer, iSize);
    break;
  }
  case SQLRDD_RDBMS_FIREBR:
  case SQLRDD_RDBMS_FIREBR3:
  case SQLRDD_RDBMS_FIREBR4:
  case SQLRDD_RDBMS_FIREBR5: {
    iSize = escape_firebird(ToBuffer, FromBuffer, iSize);
    break;
  }
  case SQLRDD_RDBMS_ORACLE:
  case SQLRDD_RDBMS_CACHE: {
    iSize = escape_oci(ToBuffer, FromBuffer, iSize);
    break;
  }
  case SQLRDD_RDBMS_MSSQL7:
  case SQLRDD_RDBMS_INGRES:
  case SQLRDD_RDBMS_SYBASE:
  case SQLRDD_RDBMS_ADABAS:
  case SQLRDD_RDBMS_INFORM:
  case SQLRDD_RDBMS_OTERRO:
  case SQLRDD_RDBMS_PERVASIVE: {
    iSize = escape_single(ToBuffer, FromBuffer, iSize);
    break;
  }
  case SQLRDD_RDBMS_POSTGR: {
    iSize = escape_pgs(ToBuffer, FromBuffer, iSize);
    break;
  }
  case SQLRDD_RDBMS_IBMDB2: {
    iSize = escape_db2(ToBuffer, FromBuffer, iSize);
    break; // TODO: unnecessary break
  }
  }

  iSize++;
  ToBuffer--;

  while (bRTrim && iSize > 1 && ToBuffer[iSize - 1] == ' ') {
    iSize--;
  }

  ToBuffer[iSize] = '\'';
  iSize++;
  ToBuffer[iSize] = '\0';
  *iSizeOut = iSize;
  return ToBuffer;
}

HB_FUNC(SR_ESCAPENUM)
{
  const char *FromBuffer;
  char *ToBuffer;
  char SciNot[5] = {'\0', '\0', '\0', '\0', '\0'};
  HB_SIZE iSize, iPos;
  int iDecPos;
  HB_BOOL bInteger = HB_TRUE;
  HB_SIZE len, dec;
  double dMultpl;

  iSize = hb_parclen(1);
  FromBuffer = hb_parc(1);

  if (!(HB_ISCHAR(1) && HB_ISNUM(2) && HB_ISNUM(3))) {
    hb_errRT_BASE_SubstR(EG_ARG, 3012, SR_NULLPTR, "SR_ESCAPENUM", 3, hb_param(1, HB_IT_ANY), hb_param(2, HB_IT_ANY),
                         hb_param(3, HB_IT_ANY));
    return;
  }

  ToBuffer = (char *)hb_xgrab((iSize) + 33);
  memset(ToBuffer, 0, (iSize) + 33);

  len = hb_parnl(2);
  dec = hb_parnl(3);

  if (dec > 0) {
    len -= (dec + 1);
  }

  dMultpl = 0;
  iDecPos = 0;

  for (iPos = 0; iPos < iSize; iPos++) {
    if (FromBuffer[iPos] == ',') {
      ToBuffer[iPos] = '.';
      iDecPos = (int)iPos;
    } else {
      ToBuffer[iPos] = FromBuffer[iPos];
    }

    if (ToBuffer[iPos] == '.') {
      bInteger = HB_FALSE;
      iDecPos = (int)iPos;
    }

    if (ToBuffer[iPos] == 'E' && (iPos + 2) <= iSize) { // 1928773.3663E+003
      bInteger = HB_FALSE;
      if (FromBuffer[iPos + 1] == '-') {
        SciNot[0] = FromBuffer[iPos + 1];
      } else {
        SciNot[0] = '0';
      }
      SciNot[1] = FromBuffer[iPos + 2];

      if ((iPos + 3) <= iSize) {
        SciNot[2] = FromBuffer[iPos + 3];
        if ((iPos + 4) <= iSize) {
          SciNot[3] = FromBuffer[iPos + 4];
        }
      }

      iSize = iPos;
      dMultpl = hb_strVal(SciNot, 5);

      break;
    }
  }

  // Moves the decimal point dMultpl positions

  ToBuffer[iSize] = '\0';

  if (dMultpl > 0) {
    for (iPos = iDecPos; iPos < iSize + 32; iPos++) {
      if (ToBuffer[iPos] == '.' && dMultpl > 0 && (iPos + 1) <= iSize + 32) {
        ToBuffer[iPos] = ToBuffer[iPos + 1];
        ToBuffer[iPos + 1] = '.';
        dMultpl--;
        if (ToBuffer[iPos] == '\0' || iPos > iSize) {
          ToBuffer[iPos] = '0';
        }
        if (dMultpl == 0 && ToBuffer[iPos + 2] == '\0') {
          ToBuffer[iPos + 1] = '\0';
          break;
        }
      }
    }
    iSize = strlen(ToBuffer);
  } else if (dMultpl < 0) {
    // Not implemented
  }

  if (bInteger) {
#ifndef HB_LONG_LONG_OFF
    HB_LONGLONG lValue;
#else
    HB_LONG lValue;
#endif
    int iOverflow;
    lValue = hb_strValInt(ToBuffer, &iOverflow);

    if (!iOverflow) {
      double dValue = (double)lValue;
      hb_retnlen(dValue, (int)len, (int)dec);
    } else {
      double dValue = hb_strVal(ToBuffer, iSize);
      hb_retnlen(dValue, (int)len, (int)dec);
    }
  } else {
    double dValue = hb_strVal(ToBuffer, iSize);
    hb_retnlen(dValue, (int)len, (int)dec);
  }
  hb_xfree(ToBuffer);
}

PHB_ITEM sr_escapeNumber(char *FromBuffer, HB_SIZE len, HB_SIZE dec, PHB_ITEM pRet)
{
  char *ToBuffer;
  char SciNot[5] = {'\0', '\0', '\0', '\0', '\0'};
  HB_SIZE iSize, iPos;
  int iDecPos;
  HB_BOOL bInteger = HB_TRUE;
  double dMultpl;

  iSize = strlen(FromBuffer);
  ToBuffer = (char *)hb_xgrab((iSize) + 33);
  memset(ToBuffer, 0, (iSize) + 33);

  if (dec > 0) {
    len -= (dec + 1);
  }

  dMultpl = 0;
  iDecPos = 0;

  for (iPos = 0; iPos < iSize; iPos++) {
    if (FromBuffer[iPos] == ',') {
      ToBuffer[iPos] = '.';
      iDecPos = (int)iPos;
    } else {
      ToBuffer[iPos] = FromBuffer[iPos];
    }

    if (ToBuffer[iPos] == '.') {
      bInteger = HB_FALSE;
      iDecPos = (int)iPos;
    }

    if (ToBuffer[iPos] == 'E' && (iPos + 2) <= iSize) { // 1928773.3663E+003
      bInteger = HB_FALSE;
      if (FromBuffer[iPos + 1] == '-') {
        SciNot[0] = FromBuffer[iPos + 1];
      } else {
        SciNot[0] = '0';
      }
      SciNot[1] = FromBuffer[iPos + 2];

      if ((iPos + 3) <= iSize) {
        SciNot[2] = FromBuffer[iPos + 3];
        if ((iPos + 4) <= iSize) {
          SciNot[3] = FromBuffer[iPos + 4];
        }
      }

      iSize = iPos;
      dMultpl = hb_strVal(SciNot, 5);

      break;
    }
  }

  // Moves the decimal point dMultpl positions

  ToBuffer[iSize] = '\0';

  if (dMultpl > 0) {
    for (iPos = iDecPos; iPos < iSize + 32; iPos++) {
      if (ToBuffer[iPos] == '.' && dMultpl > 0 && (iPos + 1) <= iSize + 32) {
        ToBuffer[iPos] = ToBuffer[iPos + 1];
        ToBuffer[iPos + 1] = '.';
        dMultpl--;
        if (ToBuffer[iPos] == '\0' || iPos > iSize) {
          ToBuffer[iPos] = '0';
        }
        if (dMultpl == 0 && ToBuffer[iPos + 2] == '\0') {
          ToBuffer[iPos + 1] = '\0';
          break;
        }
      }
    }
    iSize = strlen(ToBuffer);
  } else if (dMultpl < 0) {
    // Not implemented
  }

  if (bInteger) {
#ifndef HB_LONG_LONG_OFF
    HB_LONGLONG lValue;
#else
    HB_LONG lValue;
#endif
    int iOverflow;
    lValue = hb_strValInt(ToBuffer, &iOverflow);

    if (!iOverflow) {
      double dValue = (double)lValue;
      hb_itemPutNLen(pRet, dValue, (int)len, (int)dec);
    } else {
      double dValue = hb_strVal(ToBuffer, iSize);
      hb_itemPutNLen(pRet, dValue, (int)len, (int)dec);
    }
  } else {
    double dValue = hb_strVal(ToBuffer, iSize);
    hb_itemPutNLen(pRet, dValue, (int)len, (int)dec);
  }
  hb_xfree(ToBuffer);
  return pRet;
}

HB_FUNC(SR_DBQUALIFY)
{
  PHB_ITEM pText = hb_param(1, HB_IT_STRING);
  int ulDb = hb_parni(2);

  if (pText) {
    char *szOut;
    const char *pszBuffer;
    HB_SIZE ulLen, i;

    pszBuffer = hb_itemGetCPtr(pText);
    ulLen = hb_itemGetCLen(pText);
    szOut = (char *)hb_xgrab(ulLen + 3);

    // Firebird, DB2, ADABAS and Oracle must be uppercase
    // Postgres, MySQL and Ingres must be lowercase
    // Others, doesn't matter column case

    switch (ulDb) {
    case SQLRDD_RDBMS_ORACLE:
    case SQLRDD_RDBMS_FIREBR:
    case SQLRDD_RDBMS_FIREBR3:
    case SQLRDD_RDBMS_FIREBR4:
    case SQLRDD_RDBMS_FIREBR5:
    case SQLRDD_RDBMS_IBMDB2:
    case SQLRDD_RDBMS_ADABAS: {
      szOut[0] = '"';
      for (i = 0; i < ulLen; i++) {
        szOut[i + 1] = (char)toupper((HB_BYTE)pszBuffer[i]);
      }
      szOut[i + 1] = '"';
      break;
    }
    case SQLRDD_RDBMS_INGRES:
    case SQLRDD_RDBMS_POSTGR: {
      szOut[0] = '"';
      for (i = 0; i < ulLen; i++) {
        szOut[i + 1] = (char)tolower((HB_BYTE)pszBuffer[i]);
      }
      szOut[i + 1] = '"';
      break;
    }
    case SQLRDD_RDBMS_MSSQL7: {
      szOut[0] = '[';
      for (i = 0; i < ulLen; i++) {
        szOut[i + 1] = (HB_BYTE)pszBuffer[i];
      }
      szOut[i + 1] = ']';
      break;
    }
    case SQLRDD_RDBMS_MYSQL:
    case SQLRDD_RDBMS_OTERRO:
    case SQLRDD_RDBMS_MARIADB: {
      szOut[0] = '`';
      for (i = 0; i < ulLen; i++) {
        szOut[i + 1] = (char)tolower((HB_BYTE)pszBuffer[i]);
      }
      szOut[i + 1] = '`';
      break;
    }
    case SQLRDD_RDBMS_INFORM: {
      for (i = 0; i < ulLen; i++) {
        szOut[i] = (char)tolower((HB_BYTE)pszBuffer[i]);
      }
      ulLen -= 2;
      break;
    }
    default: {
      szOut[0] = '"';
      for (i = 0; i < ulLen; i++) {
        szOut[i + 1] = (HB_BYTE)pszBuffer[i];
      }
      szOut[i + 1] = '"';
    }
    }
    hb_retclen_buffer(szOut, ulLen + 2);
  } else {
    hb_errRT_BASE_SubstR(EG_ARG, 1102, SR_NULLPTR, "SR_DBQUALIFY", 1, hb_paramError(1));
  }
}

//------------------------------------------------------------------------

#ifdef SQLRDD_COMPAT_PRE_1_1

HB_BOOL hb_arraySetNL(PHB_ITEM pArray, HB_ULONG ulIndex, HB_LONG lVal)
{
  HB_BOOL ret;
  PHB_ITEM pItem = hb_errNew();
  hb_itemPutNL(pItem, lVal);
  ret = hb_arraySetForward(pArray, ulIndex, pItem);
  hb_itemRelease(pItem);
  return ret;
}

//------------------------------------------------------------------------

HB_BOOL hb_arraySetL(PHB_ITEM pArray, HB_ULONG ulIndex, HB_BOOL lVal)
{
  HB_BOOL ret;
  PHB_ITEM pItem = hb_errNew();
  hb_itemPutL(pItem, lVal);
  ret = hb_arraySetForward(pArray, ulIndex, pItem);
  hb_itemRelease(pItem);
  return ret;
}

#endif

//-----------------------------------------------------------------------------//

HB_BOOL SR_itemEmpty(PHB_ITEM pItem)
{
  switch (hb_itemType(pItem)) {
  case HB_IT_ARRAY: {
    return hb_arrayLen(pItem) == 0;
  }
  case HB_IT_HASH: {
    return hb_hashLen(pItem) == 0;
  }
  case HB_IT_STRING:
  case HB_IT_MEMO: {
    return hb_strEmpty(hb_itemGetCPtr(pItem), hb_itemGetCLen(pItem));
  }
  case HB_IT_INTEGER: {
    return hb_itemGetNI(pItem) == 0;
  }
  case HB_IT_LONG: {
    return hb_itemGetNInt(pItem) == 0;
  }
  case HB_IT_DOUBLE: {
    return hb_itemGetND(pItem) == 0.0;
  }
  case HB_IT_DATE: {
    return hb_itemGetDL(pItem) == 0;
  }
  case HB_IT_TIMESTAMP: {
    long lDate, lTime;
    hb_itemGetTDT(pItem, &lDate, &lTime);
    return lDate == 0 && lTime == 0;
  }
  case HB_IT_LOGICAL: {
    return !hb_itemGetL(pItem);
  }
  case HB_IT_BLOCK: {
    return HB_FALSE;
  }
  case HB_IT_POINTER: {
    return hb_itemGetPtr(pItem) == SR_NULLPTR;
  }
  case HB_IT_SYMBOL: {
    PHB_SYMB pSym = hb_itemGetSymbol(pItem);
    if (pSym && (pSym->scope.value & HB_FS_DEFERRED) && pSym->pDynSym) {
      pSym = hb_dynsymSymbol(pSym->pDynSym);
    }
    return pSym == SR_NULLPTR || pSym->value.pFunPtr == SR_NULLPTR;
  }
  default: {
    return HB_TRUE;
  }
  }
}

//-----------------------------------------------------------------------------//

char *quotedNull(PHB_ITEM pFieldData, PHB_ITEM pFieldLen, PHB_ITEM pFieldDec, HB_BOOL bNullable, int nSystemID,
                 HB_BOOL bTCCompat, HB_BOOL bMemo, HB_BOOL *bNullArgument)
{
  char *sValue, sDate[9];
  HB_SIZE iSizeOut;
  int iTrim, iPos, iSize;
  sValue = SR_NULLPTR;

  *bNullArgument = HB_FALSE;

  if (SR_itemEmpty(pFieldData) && (!(HB_IS_ARRAY(pFieldData) || HB_IS_OBJECT(pFieldData) || HB_IS_HASH(pFieldData))) &&
      (((nSystemID == SQLRDD_RDBMS_POSTGR) && HB_IS_DATE(pFieldData)) ||
       ((nSystemID != SQLRDD_RDBMS_POSTGR) && (!HB_IS_LOGICAL(pFieldData))))) {
    if (bNullable || HB_IS_DATE(pFieldData)) {
      sValue = (char *)hb_xgrab(5);
      sValue[0] = 'N';
      sValue[1] = 'U';
      sValue[2] = 'L';
      sValue[3] = 'L';
      sValue[4] = '\0';
      *bNullArgument = HB_TRUE;
      return sValue;
    } else {
#if 0 // TODO: old code for reference (to be deleted)
         if( HB_IS_STRING(pFieldData) && bTCCompat ) {
            sValue = QuoteTrimEscapeString(hb_itemGetCPtr(pFieldData), hb_itemGetCLen(pFieldData), nSystemID, HB_FALSE, &iSizeOut);
            return sValue;
         } else if( HB_IS_STRING(pFieldData) ) {
            sValue = (char *) hb_xgrab(4);
            sValue[0] = '\'';
            sValue[1] = ' ';
            sValue[2] = '\'';
            sValue[3] = '\0';
            return sValue;
         } else if( HB_IS_NUMBER(pFieldData) ) {
            sValue = (char *) hb_xgrab(2);
            sValue[0] = '0';
            sValue[1] = '\0';
            return sValue;
         }
#endif
      switch (hb_itemType(pFieldData)) {
      case HB_IT_STRING:
      case HB_IT_MEMO: {
        if (bTCCompat) {
          sValue = QuoteTrimEscapeString(hb_itemGetCPtr(pFieldData), hb_itemGetCLen(pFieldData), nSystemID, HB_FALSE,
                                         &iSizeOut);
          return sValue;
        } else {
          sValue = (char *)hb_xgrab(4);
          sValue[0] = '\'';
          sValue[1] = ' ';
          sValue[2] = '\'';
          sValue[3] = '\0';
          return sValue;
        }
      }
      case HB_IT_INTEGER:
      case HB_IT_LONG:
      case HB_IT_DOUBLE: {
        sValue = (char *)hb_xgrab(2);
        sValue[0] = '0';
        sValue[1] = '\0';
        return sValue;
      }
      }
    }
  }

#if 0 // TODO: old code for reference (to be deleted)
   if( HB_IS_STRING(pFieldData) ) {
      sValue = QuoteTrimEscapeString(hb_itemGetCPtr(pFieldData), hb_itemGetCLen(pFieldData), nSystemID, !bTCCompat, &iSizeOut);
   } else if( HB_IS_NUMBER(pFieldData) ) {
      sValue = hb_itemStr(pFieldData, pFieldLen, pFieldDec);
      iTrim = 0;
      iSize = 15;
      while( sValue[iTrim] == ' ' ) {
         iTrim++;
      }
      if( iTrim > 0 ) {
         for( iPos = 0; iPos + iTrim < iSize; iPos++ ) {
            sValue[iPos] = sValue[iPos + iTrim];
         }
         sValue[iPos] = '\0';
      }
   } else if( HB_IS_DATE(pFieldData) ) {
      hb_dateDecStr(sDate, hb_itemGetDL(pFieldData));
      sValue = (char *) hb_xgrab(30);
      switch( nSystemID ) {
         case SQLRDD_RDBMS_ORACLE: {
            if( !bMemo ) {
               sprintf(sValue, "TO_DATE(\'%s\',\'YYYYMMDD\')", sDate);
               return sValue;
            }
         }
         default: {
            if( !bMemo ) {
               sprintf(sValue, "\'%s\'", sDate);
               return sValue;
            }
         }
      }
   } else if( HB_IS_LOGICAL(pFieldData) ) {
      sValue = (char *) hb_xgrab(6);
      if( hb_itemGetL(pFieldData) ) {
         if( nSystemID == SQLRDD_RDBMS_POSTGR ) {
            sValue[0] = 't';
            sValue[1] = 'r';
            sValue[2] = 'u';
            sValue[3] = 'e';
            sValue[4] = '\0';
         } else if( nSystemID == SQLRDD_RDBMS_INFORM ) {
            sValue[0] = '\'';
            sValue[1] = 't';
            sValue[2] = '\'';
            sValue[3] = '\0';
         } else {
            sValue[0] = '1';
            sValue[1] = '\0';
         }
      } else {
         if( nSystemID == SQLRDD_RDBMS_POSTGR ) {
            sValue[0] = 'f';
            sValue[1] = 'a';
            sValue[2] = 'l';
            sValue[3] = 's';
            sValue[4] = 'e';
            sValue[5] = '\0';
         } else if( nSystemID == SQLRDD_RDBMS_INFORM ) {
            sValue[0] = '\'';
            sValue[1] = 'f';
            sValue[2] = '\'';
            sValue[3] = '\0';
         } else {
            sValue[0] = '0';
            sValue[1] = '\0';
         }
      }
   }
#endif
  switch (hb_itemType(pFieldData)) {
  case HB_IT_STRING:
  case HB_IT_MEMO: {
    sValue =
        QuoteTrimEscapeString(hb_itemGetCPtr(pFieldData), hb_itemGetCLen(pFieldData), nSystemID, !bTCCompat, &iSizeOut);
    break;
  }
  case HB_IT_INTEGER:
  case HB_IT_LONG:
  case HB_IT_DOUBLE: {
    sValue = hb_itemStr(pFieldData, pFieldLen, pFieldDec);
    iTrim = 0;
    iSize = 15;
    while (sValue[iTrim] == ' ') {
      iTrim++;
    }
    if (iTrim > 0) {
      for (iPos = 0; iPos + iTrim < iSize; iPos++) {
        sValue[iPos] = sValue[iPos + iTrim];
      }
      sValue[iPos] = '\0';
    }
    break;
  }
  case HB_IT_DATE: {
    hb_dateDecStr(sDate, hb_itemGetDL(pFieldData));
    sValue = (char *)hb_xgrab(30);
    switch (nSystemID) {
    case SQLRDD_RDBMS_ORACLE: {
      if (!bMemo) {
        sprintf(sValue, "TO_DATE(\'%s\',\'YYYYMMDD\')", sDate);
        return sValue;
      }
    }
    default: {
      if (!bMemo) {
        sprintf(sValue, "\'%s\'", sDate);
        return sValue;
      }
    }
    }
    break;
  }
  case HB_IT_LOGICAL: {
    sValue = (char *)hb_xgrab(6);
    if (hb_itemGetL(pFieldData)) {
      switch (nSystemID) {
      case SQLRDD_RDBMS_POSTGR: {
        sValue[0] = 't';
        sValue[1] = 'r';
        sValue[2] = 'u';
        sValue[3] = 'e';
        sValue[4] = '\0';
        break;
      }
      case SQLRDD_RDBMS_INFORM: {
        sValue[0] = '\'';
        sValue[1] = 't';
        sValue[2] = '\'';
        sValue[3] = '\0';
        break;
      }
      default: {
        sValue[0] = '1';
        sValue[1] = '\0';
      }
      }
    } else {
      switch (nSystemID) {
      case SQLRDD_RDBMS_POSTGR: {
        sValue[0] = 'f';
        sValue[1] = 'a';
        sValue[2] = 'l';
        sValue[3] = 's';
        sValue[4] = 'e';
        sValue[5] = '\0';
        break;
      }
      case SQLRDD_RDBMS_INFORM: {
        sValue[0] = '\'';
        sValue[1] = 'f';
        sValue[2] = '\'';
        sValue[3] = '\0';
        break;
      }
      default: {
        sValue[0] = '0';
        sValue[1] = '\0';
      }
      }
    }
  }
  }

  return sValue;
}
