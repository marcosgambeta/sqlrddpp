//
// SQLRDD Postgres native access routines
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

#include "libpq-fe.h"

#include "sqlrddsetup.ch"
#include "sqlprototypes.h"
#include "pgs.ch"
#include "sqlodbc.ch"

#include <assert.h>

static PHB_DYNS s_pSym_SR_DESERIALIZE = SR_NULLPTR;
static PHB_DYNS s_pSym_SR_FROMXML = SR_NULLPTR;
static PHB_DYNS s_pSym_SR_FROMJSON = SR_NULLPTR;
#define LOGFILE "pgs.log"
typedef struct _PSQL_SESSION
{
  int status;        // Execution return value
  int numcols;       // Result set columns
  int ifetch;        // Fetch position in result set
  PGconn *dbh;       // Connection handler
  PGresult *stmt;    // Current statement handler
  int iAffectedRows; // Number of affected rows by command
} PSQL_SESSION;

// culik 11/9/2010 variavel para setar o comportamento do postgresql

typedef PSQL_SESSION *PPSQL_SESSION;

static void myNoticeProcessor(void *arg, const char *message)
{
  HB_SYMBOL_UNUSED(arg);
  HB_SYMBOL_UNUSED(message);
  //   sr_TraceLog("sqlerror.log", "%s", message);
}

// PGSConnect(ConnectionString) => ConnHandle
HB_FUNC(PGSCONNECT)
{
  // PPSQL_SESSION session = (PPSQL_SESSION) hb_xgrab(sizeof(PSQL_SESSION));
  PPSQL_SESSION session = (PPSQL_SESSION)hb_xgrabz(sizeof(PSQL_SESSION));
  const char *szConn = hb_parc(1);

  //    memset(session, 0, sizeof(PSQL_SESSION));
  session->iAffectedRows = 0;
  session->dbh = PQconnectdb(szConn);

  session->ifetch = -2;
  // Setup Postgres Notice Processor
  PQsetNoticeProcessor(session->dbh, myNoticeProcessor, SR_NULLPTR);
  hb_retptr((void *)session);
}

// PGSFinish(ConnHandle)
HB_FUNC(PGSFINISH)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);
  PQfinish(session->dbh);
  hb_xfree(session);
  hb_ret();
}

// PGSStatus(ConnHandle) => nStatus
HB_FUNC(PGSSTATUS)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);

  if (PQstatus(session->dbh) == CONNECTION_OK)
  {
    hb_retni(SQL_SUCCESS);
  }
  else
  {
    hb_retni(SQL_ERROR);
  }
}

// PGSStatus(ConnHandle) => nStatus
HB_FUNC(PGSSTATUS2)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);
  hb_retni((int)PQstatus(session->dbh));
}

// PGSResultStatus(ResultSet) => nStatus
HB_FUNC(PGSRESULTSTATUS)
{
  int ret;
  PGresult *res = (PGresult *)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(res != SR_NULLPTR);
  ret = (int)PQresultStatus(res);

  switch (ret)
  {
  case PGRES_EMPTY_QUERY:
    ret = SQL_ERROR;
    break;
  case PGRES_COMMAND_OK:
    ret = SQL_SUCCESS;
    break;
  case PGRES_TUPLES_OK:
    ret = SQL_SUCCESS;
    break;
  case PGRES_BAD_RESPONSE:
    ret = SQL_ERROR;
    break;
  case PGRES_NONFATAL_ERROR:
    ret = SQL_SUCCESS_WITH_INFO;
    break;
  case PGRES_FATAL_ERROR:
    ret = SQL_ERROR;
    break;
  }

  hb_retni(ret);
}

// PGSExec(ConnHandle, cCommand) => ResultSet
HB_FUNC(PGSEXEC)
{
  // sr_TraceLog(SR_NULLPTR, "PGSExec : %s\n", hb_parc(2));
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  int ret;
  assert(session->dbh != SR_NULLPTR);

  session->stmt = PQexec(session->dbh, hb_parc(2));
  hb_retptr((void *)session->stmt);

  session->ifetch = -1;
  session->numcols = PQnfields(session->stmt);
  ret = (int)PQresultStatus(session->stmt);

  switch (ret)
  {
  case PGRES_COMMAND_OK:
    session->iAffectedRows = (int)atoi(PQcmdTuples(session->stmt));
    break;
  default:
    session->iAffectedRows = 0;
  }
}

// PGSFetch(ResultSet) => nStatus
HB_FUNC(PGSFETCH)
{
  int iTpl;
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);
  assert(session->stmt != SR_NULLPTR);

  iTpl = PQresultStatus(session->stmt);
  session->iAffectedRows = 0;
  if (iTpl != PGRES_TUPLES_OK)
  {
    hb_retni(SQL_INVALID_HANDLE);
  }
  else
  {
    if (session->ifetch >= -1)
    {
      session->ifetch++;
      iTpl = PQntuples(session->stmt) - 1;
      if (session->ifetch > iTpl)
      {
        hb_retni(SQL_NO_DATA_FOUND);
      }
      else
      {
        session->iAffectedRows = (int)iTpl;
        hb_retni(SQL_SUCCESS);
      }
    }
    else
    {
      hb_retni(SQL_INVALID_HANDLE);
    }
  }
}

// PGSResStatus(ResultSet) => cErrMessage
HB_FUNC(PGSRESSTATUS)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);
  assert(session->stmt != SR_NULLPTR);
  hb_retc(PQresStatus(PQresultStatus(session->stmt)));
}

// PGSClear(ResultSet)
HB_FUNC(PGSCLEAR)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);
  if (session->stmt)
  {
    PQclear(session->stmt);
    session->stmt = SR_NULLPTR;
    session->ifetch = -2;
  }
}

// PGSGetData(ResultSet, nColumn) => cValue
HB_FUNC(PGSGETDATA)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);
  assert(session->stmt != SR_NULLPTR);
  hb_retc(PQgetvalue(session->stmt, session->ifetch, hb_parnl(2) - 1));
}

// PGSCols(ResultSet) => nColsInQuery
HB_FUNC(PGSCOLS)
{
  PGresult *res = (PGresult *)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(res != SR_NULLPTR);
  hb_retnl((long)PQnfields(res));
}

// PGSErrMsg(ConnHandle) => cErrorMessage
HB_FUNC(PGSERRMSG)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  assert(session->dbh != SR_NULLPTR);
  hb_retc(PQerrorMessage(session->dbh));
}

// PGSCommit(ConnHandle) => nError
HB_FUNC(PGSCOMMIT)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  PGresult *res;
  assert(session->dbh != SR_NULLPTR);
  res = PQexec(session->dbh, "COMMIT");
  if (PQresultStatus(res) == PGRES_COMMAND_OK)
  {
    hb_retni(SQL_SUCCESS);
  }
  else
  {
    hb_retni(SQL_ERROR);
  }
}

// PGSRollBack(ConnHandle) => nError
HB_FUNC(PGSROLLBACK)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  PGresult *res;
  assert(session->dbh != SR_NULLPTR);
  res = PQexec(session->dbh, "ROLLBACK");
  if (PQresultStatus(res) == PGRES_COMMAND_OK)
  {
    hb_retni(SQL_SUCCESS);
  }
  else
  {
    hb_retni(SQL_ERROR);
  }
}

// PGSQueryAttr(ResultSet) => aStruct
HB_FUNC(PGSQUERYATTR)
{
  int row, rows, type;

  PHB_ITEM ret, atemp, temp;
  HB_LONG typmod;
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

  assert(session->dbh != SR_NULLPTR);
  assert(session->stmt != SR_NULLPTR);

  if (hb_pcount() != 1)
  {
    hb_retnl(-2);
    return;
  }

  rows = PQnfields(session->stmt);
  ret = hb_itemNew(SR_NULLPTR);
  temp = hb_itemNew(SR_NULLPTR);
  atemp = hb_itemNew(SR_NULLPTR);

  hb_arrayNew(ret, rows);

  for (row = 0; row < rows; row++)
  {
    //      long nullable;
    // Column name
    hb_arrayNew(atemp, 11);
    hb_itemPutC(temp, hb_strupr(PQfname(session->stmt, row)));
    hb_arraySetForward(atemp, FIELD_NAME, temp);
    hb_arraySetNL(atemp, FIELD_ENUM, row + 1);

    // Data type, len, dec
    type = (int)PQftype(session->stmt, row);
    typmod = PQfmod(session->stmt, row);

    // nullable = PQgetisnull(session->stmt, row,PQfnumber(session->stmt, PQfname(session->stmt, row)));

    if (typmod < 0L)
    {
      typmod = (HB_LONG)PQfsize(session->stmt, row);
    }
#if 0
    if (typmod < 0L)
    {
      typmod = 20L;
    }
#endif
    switch (type)
    {
    case CHAROID:
    case NAMEOID:
    case BPCHAROID:
    case VARCHAROID:
    case BYTEAOID:
    case ABSTIMEOID:
    case RELTIMEOID:
    case TINTERVALOID:
    case CASHOID:
    case MACADDROID:
    case INETOID:
    case CIDROID:
    case TIMETZOID: {
      //         case TIMESTAMPOID:
      // case TIMESTAMPTZOID:
      int fieldLen = 0;

      hb_itemPutC(temp, "C");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);

      if (typmod >= 4)
      {
        fieldLen = typmod - 4;
      }
      else
      {
        fieldLen = (int)PQfsize(session->stmt, row);
        if (fieldLen <= 0)
        {
          fieldLen = 254;
        }
      }

      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, fieldLen));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_CHAR));
      break;
    }
    case UNKNOWNOID:
      hb_itemPutC(temp, "C");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, PQgetlength(session->stmt, 0, row)));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_CHAR));
      break;
    case NUMERICOID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      if (typmod > 0)
      {
        hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, ((typmod - 4L) >> 16L)));
        hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, ((typmod - 4L) & 0xffff)));
      }
      else
      {
        hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 18));
        hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 6));
      }
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case BOOLOID:
      hb_itemPutC(temp, "L");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 1));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_BIT));
      break;
    case TEXTOID:
      hb_itemPutC(temp, "M");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 10));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_LONGVARCHAR));
      break;
    case XMLOID:
      hb_itemPutC(temp, "M");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_LONGVARCHARXML));
      break;

    case DATEOID:
      hb_itemPutC(temp, "D");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_DATE));
      break;
    case INT2OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 6));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case INT8OID:
    case OIDOID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 20));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case INT4OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 11));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case FLOAT4OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 2));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case FLOAT8OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 6));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
      // teste datetime
    case TIMESTAMPOID:
    case TIMESTAMPTZOID:
      hb_itemPutC(temp, "T");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_DATETIME));
      break;

    default:
      sr_TraceLog(LOGFILE, "Strange data type returned in query: %i\n", type);
      break;
    }

    // Nullable
    hb_arraySetForward(atemp, FIELD_NULLABLE, hb_itemPutL(temp, HB_FALSE));
    // add to main array
    hb_arraySetForward(ret, row + 1, atemp);
  }
  hb_itemRelease(atemp);
  hb_itemRelease(temp);
  hb_itemReturnForward(ret);
  hb_itemRelease(ret);
}

// PGSTableAttr(ConnHandle, cTableName) => aStruct
HB_FUNC(PGSTABLEATTR)
{
  char attcmm[512];
  int row, rows;
  PHB_ITEM ret, atemp, temp;
  PGresult *stmtTemp;
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

  assert(session->dbh != SR_NULLPTR);

  if (hb_pcount() < 3)
  {
    hb_retnl(-2);
    return;
  }

  sprintf(attcmm,
          "select a.attname, a.atttypid, a.atttypmod, a.attnotnull from pg_attribute a left join pg_class b on "
          "a.attrelid = b.oid left join pg_namespace c on b.relnamespace = c.oid where a.attisdropped IS FALSE and "
          "a.attnum > 0 and b.relname = '%s' and c.nspname = '%s' order by attnum",
          hb_parc(2), hb_parc(3));

  stmtTemp = PQexec(session->dbh, attcmm);

  if (PQresultStatus(stmtTemp) != PGRES_TUPLES_OK)
  {
    sr_TraceLog(LOGFILE, "Query error : %i - %s\n", PQresultStatus(stmtTemp), PQresStatus(PQresultStatus(stmtTemp)));
    PQclear(stmtTemp);
  }

  rows = PQntuples(stmtTemp);
  ret = hb_itemNew(SR_NULLPTR);
  atemp = hb_itemNew(SR_NULLPTR);
  temp = hb_itemNew(SR_NULLPTR);

  hb_arrayNew(ret, rows);

  for (row = 0; row < rows; row++)
  {
    long typmod;
    long nullable;
    int type;

    // Column name
    hb_arrayNew(atemp, 11);
    hb_itemPutC(temp, hb_strupr(PQgetvalue(stmtTemp, row, 0)));
    hb_arraySetForward(atemp, 1, temp);
    hb_arraySetNL(atemp, FIELD_ENUM, row + 1);

    // Data type, len, dec

    type = atoi(PQgetvalue(stmtTemp, row, 1));
    typmod = atol(PQgetvalue(stmtTemp, row, 2));
    if (sr_iOldPgsBehavior())
    {
      nullable = 0;
    }
    else
    {
      if (strcmp(PQgetvalue(stmtTemp, row, 3), "f") == 0)
      {
        nullable = 1;
      }
      else
      {
        nullable = 0;
      }
    }

    switch (type)
    {
    case CHAROID:
    case NAMEOID:
    case BPCHAROID:
    case VARCHAROID:
    case BYTEAOID:
    case ABSTIMEOID:
    case RELTIMEOID:
    case TINTERVALOID:
    case CASHOID:
    case MACADDROID:
    case INETOID:
    case CIDROID:
    case TIMETZOID:
      hb_itemPutC(temp, "C");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, typmod - 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_CHAR));
      break;
    case NUMERICOID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, ((typmod - 4L) >> 16L)));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, ((typmod - 4L) & 0xffff)));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case BOOLOID:
      hb_itemPutC(temp, "L");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 1));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_BIT));
      break;
    case TEXTOID:
      hb_itemPutC(temp, "M");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 10));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_LONGVARCHAR));
      break;
    case XMLOID:
      hb_itemPutC(temp, "M");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_LONGVARCHARXML));
      break;

    case DATEOID:
      hb_itemPutC(temp, "D");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_DATE));
      break;
    case INT2OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 6));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case INT8OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 20));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case INT4OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 11));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case FLOAT4OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 2));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case FLOAT8OID:
      hb_itemPutC(temp, "N");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 6));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_NUMERIC));
      break;
    case TIMESTAMPOID:
    case TIMESTAMPTZOID:
      hb_itemPutC(temp, "T");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_DATETIME));
      break;
    case TIMEOID:
      hb_itemPutC(temp, "T");
      hb_arraySetForward(atemp, FIELD_TYPE, temp);
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(temp, 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(temp, SQL_TIME));
      break;

    default:
      sr_TraceLog(LOGFILE, "Strange data type returned: %i\n", type);
      break;
    }

    // Nullable

    hb_arraySetForward(atemp, FIELD_NULLABLE, hb_itemPutL(temp, nullable));

    // add to main array
    hb_arraySetForward(ret, row + 1, atemp);
  }
  hb_itemRelease(atemp);
  hb_itemRelease(temp);
  hb_itemReturnForward(ret);
  hb_itemRelease(ret);
  PQclear(stmtTemp);
}

//-----------------------------------------------------------------------------//

void PGSFieldGet(PHB_ITEM pField, PHB_ITEM pItem, char *bBuffer, HB_SIZE lLenBuff, HB_BOOL bQueryOnly,
                 HB_ULONG ulSystemID, HB_BOOL bTranslate)
{
  HB_LONG lType;
  HB_SIZE lLen, lDec;
  PHB_ITEM pTemp;
  PHB_ITEM pTemp1;

  HB_SYMBOL_UNUSED(bQueryOnly);
  HB_SYMBOL_UNUSED(ulSystemID);

  lType = hb_arrayGetNL(pField, 6);
  lLen = hb_arrayGetNL(pField, 3);
  lDec = hb_arrayGetNL(pField, 4);

  if (lLenBuff <= 0)
  { // database content is NULL
    switch (lType)
    {
    case SQL_CHAR: {
      char *szResult = (char *)hb_xgrab(lLen + 1);
      hb_xmemset(szResult, ' ', lLen);
      szResult[lLen] = '\0';
      hb_itemPutCLPtr(pItem, szResult, lLen);
      break;
    }
    case SQL_NUMERIC:
    case SQL_FAKE_NUM: {
      char szResult[2] = {' ', '\0'};
      sr_escapeNumber(szResult, lLen, lDec, pItem);
      break;
    }
    case SQL_DATE: {
      char dt[9] = {' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', '\0'};
      hb_itemPutDS(pItem, dt);
      break;
    }
    case SQL_LONGVARCHAR: {
      hb_itemPutCL(pItem, bBuffer, 0);
      break;
    }
    case SQL_BIT: {
      hb_itemPutL(pItem, HB_FALSE);
      break;
    }

#ifdef SQLRDD_TOPCONN
    case SQL_FAKE_DATE: {
      hb_itemPutDS(pItem, bBuffer);
      break;
    }
#endif
    case SQL_DATETIME: {
      hb_itemPutTDT(pItem, 0, 0);
      break;
    }
    case SQL_TIME: {
      hb_itemPutTDT(pItem, 0, 0);
      break;
    }

    default:
      sr_TraceLog(LOGFILE, "Invalid data type detected: %i\n", lType);
    }
  }
  else
  {
    switch (lType)
    {
    case SQL_CHAR: {
      HB_SIZE lPos;
      char *szResult = (char *)hb_xgrab(lLen + 1);
      hb_xmemcpy(szResult, bBuffer, (lLen < lLenBuff ? lLen : lLenBuff));

      for (lPos = lLenBuff; lPos < lLen; lPos++)
      {
        szResult[lPos] = ' ';
      }
      szResult[lLen] = '\0';
      hb_itemPutCLPtr(pItem, szResult, lLen);
      break;
    }
    case SQL_NUMERIC: {
      sr_escapeNumber(bBuffer, lLen, lDec, pItem);
      break;
    }
    case SQL_DATE: {
      char dt[9];
      dt[0] = bBuffer[0];
      dt[1] = bBuffer[1];
      dt[2] = bBuffer[2];
      dt[3] = bBuffer[3];
      dt[4] = bBuffer[5];
      dt[5] = bBuffer[6];
      dt[6] = bBuffer[8];
      dt[7] = bBuffer[9];
      dt[8] = '\0';
      hb_itemPutDS(pItem, dt);
      break;
    }

    case SQL_LONGVARCHAR: {

      if (lLenBuff > 0 && (strncmp(bBuffer, "[", 1) == 0 || strncmp(bBuffer, "[]", 2)) && (sr_lSerializeArrayAsJson()))
      {
        if (s_pSym_SR_FROMJSON == SR_NULLPTR)
        {
          s_pSym_SR_FROMJSON = hb_dynsymFindName("HB_JSONDECODE");
          if (s_pSym_SR_FROMJSON == SR_NULLPTR)
          {
            printf("Could not find Symbol HB_JSONDECODE\n");
          }
        }
        hb_vmPushDynSym(s_pSym_SR_FROMJSON);
        hb_vmPushNil();
        hb_vmPushString(bBuffer, lLenBuff);
        pTemp = hb_itemNew(SR_NULLPTR);
        hb_vmPush(pTemp);
        hb_vmDo(2);
        // TOFIX:
        hb_itemMove(pItem, pTemp);
        hb_itemRelease(pTemp);
      }
      else if (lLenBuff > 10 && strncmp(bBuffer, SQL_SERIALIZED_SIGNATURE, 10) == 0 && (!sr_lSerializedAsString()))
      {
        if (s_pSym_SR_DESERIALIZE == SR_NULLPTR)
        {
          s_pSym_SR_DESERIALIZE = hb_dynsymFindName("SR_DESERIALIZE");
          if (s_pSym_SR_DESERIALIZE == SR_NULLPTR)
          {
            printf("Could not find Symbol SR_DESERIALIZE\n");
          }
        }
        hb_vmPushDynSym(s_pSym_SR_DESERIALIZE);
        hb_vmPushNil();
        hb_vmPushString(bBuffer, lLenBuff);

        hb_vmDo(1);

        pTemp = hb_itemNew(SR_NULLPTR);
        hb_itemMove(pTemp, hb_stackReturnItem());

        if (HB_IS_HASH(pTemp) && sr_isMultilang() && bTranslate)
        {
          PHB_ITEM pLangItem = hb_itemNew(SR_NULLPTR);
          HB_SIZE ulPos;
          if (hb_hashScan(pTemp, sr_getBaseLang(pLangItem), &ulPos) ||
              hb_hashScan(pTemp, sr_getSecondLang(pLangItem), &ulPos) ||
              hb_hashScan(pTemp, sr_getRootLang(pLangItem), &ulPos))
          {
            hb_itemCopy(pItem, hb_hashGetValueAt(pTemp, ulPos));
          }
          hb_itemRelease(pLangItem);
        }
        else
        {
          hb_itemMove(pItem, pTemp);
        }
        hb_itemRelease(pTemp);
      }
      else
      {
        hb_itemPutCL(pItem, bBuffer, lLenBuff);
      }
      break;
    }
    // xmltoarray
    case SQL_LONGVARCHARXML: {

      if (s_pSym_SR_FROMXML == SR_NULLPTR)
      {
        s_pSym_SR_FROMXML = hb_dynsymFindName("SR_FROMXML");
        if (s_pSym_SR_FROMXML == SR_NULLPTR)
        {
          printf("Could not find Symbol SR_DESERIALIZE\n");
        }
      }
      pTemp1 = hb_itemArrayNew(0);
      hb_vmPushDynSym(s_pSym_SR_FROMXML);
      hb_vmPushNil();
      hb_vmPushNil();
      hb_vmPush(pTemp1);
      hb_vmPushLong(-1);
      hb_vmPushString(bBuffer, lLenBuff);
      hb_vmDo(4);

      pTemp = hb_itemNew(SR_NULLPTR);
      hb_itemMove(pTemp, hb_stackReturnItem());

      hb_itemMove(pItem, pTemp);

      hb_itemRelease(pTemp);
      break;
    }

    case SQL_BIT: {
      hb_itemPutL(pItem, bBuffer[0] == 't' ? HB_TRUE : HB_FALSE);
      break;
    }

#ifdef SQLRDD_TOPCONN
    case SQL_FAKE_DATE: {
      hb_itemPutDS(pItem, bBuffer);
      break;
    }
#endif
    case SQL_DATETIME: {
      long lJulian, lMilliSec;
      hb_timeStampStrGetDT(bBuffer, &lJulian, &lMilliSec);
      hb_itemPutTDT(pItem, lJulian, lMilliSec);
      break;
    }
    case SQL_TIME: {
      long lMilliSec;
      lMilliSec = hb_timeUnformat(bBuffer, SR_NULLPTR); // TOCHECK:
      hb_itemPutTDT(pItem, 0, lMilliSec);
      break;
    }

    default:
      sr_TraceLog(LOGFILE, "Invalid data type detected: %i\n", lType);
    }
  }
}

//-----------------------------------------------------------------------------//

HB_FUNC(PGSLINEPROCESSED)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  PHB_ITEM temp;
  HB_USHORT i;
  char *col;
  PHB_ITEM pFields = hb_param(3, HB_IT_ARRAY);
  HB_BOOL bQueryOnly = hb_parl(4);
  HB_ULONG ulSystemID = hb_parnl(5);
  HB_BOOL bTranslate = hb_parl(6);
  PHB_ITEM pRet = hb_param(7, HB_IT_ARRAY);
  HB_LONG lIndex, cols;

  assert(session->dbh != SR_NULLPTR);
  assert(session->stmt != SR_NULLPTR);

  if (session)
  {
    cols = hb_arrayLen(pFields);

    for (i = 0; i < cols; i++)
    {
      temp = hb_itemNew(SR_NULLPTR);
      lIndex = hb_arrayGetNL(hb_arrayGetItemPtr(pFields, i + 1), FIELD_ENUM);

      if (lIndex != 0)
      {
        col = PQgetvalue(session->stmt, session->ifetch, lIndex - 1);
        PGSFieldGet(hb_arrayGetItemPtr(pFields, i + 1), temp, (char *)col, strlen(col), bQueryOnly, ulSystemID,
                    bTranslate);
      }
      hb_arraySetForward(pRet, i + 1, temp);
      hb_itemRelease(temp);
    }
  }
}

HB_FUNC(PGSAFFECTEDROWS)
{
  PPSQL_SESSION session = (PPSQL_SESSION)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));
  if (session)
  {
    hb_retni(session->iAffectedRows);
    return;
  }
  hb_retni(0);
}
//-----------------------------------------------------------------------------//
