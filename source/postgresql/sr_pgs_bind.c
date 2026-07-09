// SQLRDD Postgres native access routines
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

#pragma BEGINDUMP

#include "sqlrddpp.h"
#include "compat.h"

#include "libpq-fe.h"

#include "sqlrddsetup.ch"
#include "sqlprototypes.h"
#include "pgs.ch"
#include "sqlodbc.ch"

#ifdef __XHARBOUR__
#define HB_LONG LONG
#define HB_ULONG ULONG
#endif

static PHB_DYNS s_pSym_SR_DESERIALIZE = SR_NULLPTR;
static PHB_DYNS s_pSym_SR_FROMXML = SR_NULLPTR;
static PHB_DYNS s_pSym_SR_FROMJSON = SR_NULLPTR;

#define LOGFILE "pgs.log"

#define GET_PGSQL_SESSION(session, numpar)                                                     \
  PSQL_SESSION *session = (PSQL_SESSION *)hb_itemGetPtr(hb_param(numpar, HB_IT_POINTER))

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

//----------------------------------------------------------------------------//

static void myNoticeProcessor(void *arg, const char *message)
{
  HB_SYMBOL_UNUSED(arg);
  HB_SYMBOL_UNUSED(message);
  //   SR_TraceLog("sqlerror.log", "%s", message);
}

//----------------------------------------------------------------------------//

// SR_PGSConnect(ConnectionString) => ConnHandle
HB_FUNC_STATIC(SR_PGSCONNECT)
{
  // PSQL_SESSION *session = (PSQL_SESSION *)hb_xgrab(sizeof(PSQL_SESSION));
  PSQL_SESSION *session = (PSQL_SESSION *)hb_xgrabz(sizeof(PSQL_SESSION));

  // memset(session, 0, sizeof(PSQL_SESSION));
  session->iAffectedRows = 0;
  session->dbh = PQconnectdb(hb_parc(1));

  session->ifetch = -2;
  // Setup Postgres Notice Processor
  PQsetNoticeProcessor(session->dbh, myNoticeProcessor, SR_NULLPTR);
  hb_retptr((void *)session);
}

//----------------------------------------------------------------------------//

// SR_PGSFinish(ConnHandle)
HB_FUNC_STATIC(SR_PGSFINISH)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR) {
    hb_ret();
    return;
  }

  if (session->dbh != SR_NULLPTR) {
    PQfinish(session->dbh);
  }

  hb_xfree(session);
  hb_ret();
}

//----------------------------------------------------------------------------//

// SR_PGSStatus(ConnHandle) => nStatus
HB_FUNC_STATIC(SR_PGSSTATUS)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retni(SQL_ERROR);
    return;
  }

  hb_retni(PQstatus(session->dbh) == CONNECTION_OK ? SQL_SUCCESS : SQL_ERROR);
}

//----------------------------------------------------------------------------//

// SR_PGSStatus(ConnHandle) => nStatus
HB_FUNC_STATIC(SR_PGSSTATUS2)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retni(SQL_ERROR);
    return;
  }

  hb_retni((int)PQstatus(session->dbh));
}

//----------------------------------------------------------------------------//

// SR_PGSResultStatus(ResultSet) => nStatus
HB_FUNC_STATIC(SR_PGSRESULTSTATUS)
{
  int ret;
  PGresult *res = (PGresult *)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

  if (res == SR_NULLPTR) {
    hb_retni(SQL_ERROR);
    return;
  }

  ret = (int)PQresultStatus(res);

  switch (ret) {
  case PGRES_EMPTY_QUERY: {
    ret = SQL_ERROR;
    break;
  }
  case PGRES_COMMAND_OK: {
    ret = SQL_SUCCESS;
    break;
  }
  case PGRES_TUPLES_OK: {
    ret = SQL_SUCCESS;
    break;
  }
  case PGRES_BAD_RESPONSE: {
    ret = SQL_ERROR;
    break;
  }
  case PGRES_NONFATAL_ERROR: {
    ret = SQL_SUCCESS_WITH_INFO;
    break;
  }
  case PGRES_FATAL_ERROR: {
    ret = SQL_ERROR;
    break;
  }
  }

  hb_retni(ret);
}

//----------------------------------------------------------------------------//

// SR_PGSExec(ConnHandle, cCommand) => ResultSet
HB_FUNC_STATIC(SR_PGSEXEC)
{
  // SR_TraceLog(SR_NULLPTR, "PGSExec : %s\n", hb_parc(2));
  GET_PGSQL_SESSION(session, 1);
  int ret;

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retptr(SR_NULLPTR);
    return;
  }

  session->stmt = PQexec(session->dbh, hb_parc(2));

  if (session->stmt == SR_NULLPTR) {
    SR_TraceLog(LOGFILE, "PGSExec: PQexec returned NULL (connection lost?)\n");
    hb_retptr(SR_NULLPTR);
    session->numcols = 0;
    session->iAffectedRows = 0;
    return;
  }

  hb_retptr((void *)session->stmt);

  session->ifetch = -1;
  session->numcols = PQnfields(session->stmt);
  ret = (int)PQresultStatus(session->stmt);

  switch (ret) {
  case PGRES_COMMAND_OK: {
    session->iAffectedRows = (int)atoi(PQcmdTuples(session->stmt));
    break;
  }
  default: {
    session->iAffectedRows = 0;
  }
  }
}

//----------------------------------------------------------------------------//

// SR_PGSFetch(ResultSet) => nStatus
HB_FUNC_STATIC(SR_PGSFETCH)
{
  int iTpl;
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR || session->stmt == SR_NULLPTR) {
    hb_retni(SQL_INVALID_HANDLE);
    return;
  }

  iTpl = PQresultStatus(session->stmt);
  session->iAffectedRows = 0;
  if (iTpl != PGRES_TUPLES_OK) {
    hb_retni(SQL_INVALID_HANDLE);
  } else {
    if (session->ifetch >= -1) {
      session->ifetch++;
      iTpl = PQntuples(session->stmt) - 1;
      if (session->ifetch > iTpl) {
        hb_retni(SQL_NO_DATA_FOUND);
      } else {
        session->iAffectedRows = (int)iTpl;
        hb_retni(SQL_SUCCESS);
      }
    } else {
      hb_retni(SQL_INVALID_HANDLE);
    }
  }
}

//----------------------------------------------------------------------------//

// SR_PGSResStatus(ResultSet) => cErrMessage
HB_FUNC_STATIC(SR_PGSRESSTATUS)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR || session->stmt == SR_NULLPTR) {
    hb_retc("");
    return;
  }

  hb_retc(PQresStatus(PQresultStatus(session->stmt)));
}

//----------------------------------------------------------------------------//

// SR_PGSClear(ResultSet)
HB_FUNC_STATIC(SR_PGSCLEAR)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR || session->stmt == SR_NULLPTR) {
    return;
  }

  PQclear(session->stmt);
  session->stmt = SR_NULLPTR;
  session->ifetch = -2;
}

//----------------------------------------------------------------------------//

// SR_PGSGetData(ResultSet, nColumn) => cValue
/*
#if 0
HB_FUNC_STATIC(SR_PGSGETDATA)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR || session->stmt == SR_NULLPTR) {
    hb_retc("");
    return;
  }

  hb_retc(PQgetvalue(session->stmt, session->ifetch, hb_parnl(2) - 1));
}
#endif
*/

//----------------------------------------------------------------------------//

// SR_PGSCols(ResultSet) => nColsInQuery
HB_FUNC_STATIC(SR_PGSCOLS)
{
  PGresult *res = (PGresult *)hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

  if (res == SR_NULLPTR) {
    hb_retnl(0);
    return;
  }

  hb_retnl((long)PQnfields(res));
}

//----------------------------------------------------------------------------//

// SR_PGSErrMsg(ConnHandle) => cErrorMessage
HB_FUNC_STATIC(SR_PGSERRMSG)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retc("");
    return;
  }

  hb_retc(PQerrorMessage(session->dbh));
}

//----------------------------------------------------------------------------//

// SR_PGSCommit(ConnHandle) => nError
/*
#if 0
HB_FUNC_STATIC(SR_PGSCOMMIT)
{
  GET_PGSQL_SESSION(session, 1);
  PGresult *res;

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retni(SQL_ERROR);
    return;
  }

  res = PQexec(session->dbh, "COMMIT");

  hb_retni(PQresultStatus(res) == PGRES_COMMAND_OK ? SQL_SUCCESS : SQL_ERROR);
}
#endif
*/

//----------------------------------------------------------------------------//

// SR_PGSRollBack(ConnHandle) => nError
HB_FUNC_STATIC(SR_PGSROLLBACK)
{
  GET_PGSQL_SESSION(session, 1);
  PGresult *res;

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retni(SQL_ERROR);
    return;
  }

  res = PQexec(session->dbh, "ROLLBACK");

  hb_retni(PQresultStatus(res) == PGRES_COMMAND_OK ? SQL_SUCCESS : SQL_ERROR);
}

//----------------------------------------------------------------------------//

// SR_PGSTransStatus(ConnHandle) => nStatus
// Returns PQtransactionStatus() result. Available in libpq since PostgreSQL 7.3,
// so it is safe to use across the entire range of supported server versions (8.0+).
//   0 = PQTRANS_IDLE    (no transaction open)
//   1 = PQTRANS_ACTIVE  (query in progress)
//   2 = PQTRANS_INTRANS (idle, inside a transaction block)
//   3 = PQTRANS_INERROR (inside a failed transaction block)
//   4 = PQTRANS_UNKNOWN (connection is bad)
HB_FUNC_STATIC(SR_PGSTRANSSTATUS)
{
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retni(4); // PQTRANS_UNKNOWN
    return;
  }

  hb_retni((int)PQtransactionStatus(session->dbh));
}

//----------------------------------------------------------------------------//

// SR_PGSQueryAttr(ResultSet) => aStruct
HB_FUNC_STATIC(SR_PGSQUERYATTR)
{
  int row, rows, type;
  PHB_ITEM ret, atemp /*, temp*/;
  HB_ITEM temp = {0};
  HB_LONG typmod;
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR || session->stmt == SR_NULLPTR) {
    hb_retnl(-1);
    return;
  }

  if (hb_pcount() != 1) {
    hb_retnl(-2);
    return;
  }

  rows = PQnfields(session->stmt);
  ret = hb_itemNew(SR_NULLPTR);
  // temp = hb_itemNew(SR_NULLPTR); (using stack instead of heap)
  atemp = hb_itemNew(SR_NULLPTR);

  hb_arrayNew(ret, rows);

  for (row = 0; row < rows; row++) {
    // long nullable;
    // Column name
    hb_arrayNew(atemp, 11);
    hb_itemPutC(&temp, hb_strupr(PQfname(session->stmt, row)));
    hb_arraySetForward(atemp, FIELD_NAME, &temp);
    hb_arraySetNL(atemp, FIELD_ENUM, row + 1);

    // Data type, len, dec
    type = (int)PQftype(session->stmt, row);
    typmod = PQfmod(session->stmt, row);

    // nullable = PQgetisnull(session->stmt, row,PQfnumber(session->stmt, PQfname(session->stmt,
    // row)));

    if (typmod < 0L) {
      typmod = (HB_LONG)PQfsize(session->stmt, row);
    }
    /*
    #if 0
        if (typmod < 0L) {
          typmod = 20L;
        }
    #endif
    */
    switch (type) {
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
      // case TIMESTAMPOID:
      // case TIMESTAMPTZOID:
      int fieldLen;

      // moved below
      // hb_itemPutC(temp, "C");
      // hb_arraySetForward(atemp, FIELD_TYPE, temp);

      if (typmod >= 4) {
        fieldLen = typmod - 4;
      } else {
        fieldLen = (int)PQfsize(session->stmt, row);
        if (fieldLen <= 0) {
          fieldLen = 254;
        }
      }

      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "C"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, fieldLen));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_CHAR));
      break;
    }
    case UNKNOWNOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "C"));
      hb_arraySetForward(atemp, FIELD_LEN,
                         hb_itemPutNI(&temp, PQgetlength(session->stmt, 0, row)));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_CHAR));
      break;
    }
    case NUMERICOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      if (typmod > 0) {
        hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, ((typmod - 4L) >> 16L)));
        hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, ((typmod - 4L) & 0xffff)));
      } else {
        hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 18));
        hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 6));
      }
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case BOOLOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "L"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 1));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_BIT));
      break;
    }
    case TEXTOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "M"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 10));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_LONGVARCHAR));
      break;
    }
    case XMLOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "M"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_LONGVARCHARXML));
      break;
    }
    case DATEOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "D"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_DATE));
      break;
    }
    case INT2OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 6));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case INT8OID:
    case OIDOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 20));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case INT4OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 11));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case FLOAT4OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 2));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case FLOAT8OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 6));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    // teste datetime
    case TIMESTAMPOID:
    case TIMESTAMPTZOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "T"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_DATETIME));
      break;
    }
    default: {
      SR_TraceLog(LOGFILE, "Strange data type returned in query: %i\n", type);
      break;
    }
    }

    // Nullable
    hb_arraySetForward(atemp, FIELD_NULLABLE, hb_itemPutL(&temp, HB_FALSE));

    // add to main array
    hb_arraySetForward(ret, row + 1, atemp);
  }
  hb_itemRelease(atemp);
  // hb_itemRelease(temp);
  hb_itemReturnForward(ret);
  hb_itemRelease(ret);
}

//----------------------------------------------------------------------------//

// SR_PGSTableAttr(ConnHandle, cTableName) => aStruct
HB_FUNC_STATIC(SR_PGSTABLEATTR)
{
  char attcmm[512];
  int row, rows;
  PHB_ITEM ret, atemp /*, temp*/;
  HB_ITEM temp = {0};
  PGresult *stmtTemp;
  GET_PGSQL_SESSION(session, 1);

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR) {
    hb_retnl(-1);
    return;
  }

  if (hb_pcount() < 3) {
    hb_retnl(-2);
    return;
  }

  sprintf(attcmm,
          "select a.attname, a.atttypid, a.atttypmod, a.attnotnull from pg_attribute a left "
          "join pg_class b on "
          "a.attrelid = b.oid left join pg_namespace c on b.relnamespace = c.oid where "
          "a.attisdropped IS FALSE and "
          "a.attnum > 0 and b.relname = '%s' and c.nspname = '%s' order by attnum",
          hb_parc(2), hb_parc(3));

  stmtTemp = PQexec(session->dbh, attcmm);

  if (PQresultStatus(stmtTemp) != PGRES_TUPLES_OK) {
    SR_TraceLog(LOGFILE, "Query error : %i - %s\n", PQresultStatus(stmtTemp),
                PQresStatus(PQresultStatus(stmtTemp)));
    PQclear(stmtTemp);
  }

  rows = PQntuples(stmtTemp);
  ret = hb_itemNew(SR_NULLPTR);
  atemp = hb_itemNew(SR_NULLPTR);
  // temp = hb_itemNew(SR_NULLPTR); (using stack instead of heap)

  hb_arrayNew(ret, rows);

  for (row = 0; row < rows; row++) {
    long typmod;
    long nullable;
    int type;

    // Column name
    hb_arrayNew(atemp, 11);
    hb_itemPutC(&temp, hb_strupr(PQgetvalue(stmtTemp, row, 0)));
    hb_arraySetForward(atemp, 1, &temp);
    hb_arraySetNL(atemp, FIELD_ENUM, row + 1);

    // Data type, len, dec

    type = atoi(PQgetvalue(stmtTemp, row, 1));
    typmod = atol(PQgetvalue(stmtTemp, row, 2));
    if (sr_iOldPgsBehavior()) {
      nullable = 0;
    } else {
      nullable = (strcmp(PQgetvalue(stmtTemp, row, 3), "f") == 0) ? 1 : 0;
    }

    switch (type) {
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
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "C"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, typmod - 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_CHAR));
      break;
    }
    case NUMERICOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, ((typmod - 4L) >> 16L)));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, ((typmod - 4L) & 0xffff)));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case BOOLOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "L"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 1));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_BIT));
      break;
    }
    case TEXTOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "M"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 10));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_LONGVARCHAR));
      break;
    }
    case XMLOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "M"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_LONGVARCHARXML));
      break;
    }
    case DATEOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "D"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_DATE));
      break;
    }
    case INT2OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 6));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case INT8OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 20));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case INT4OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 11));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case FLOAT4OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 2));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case FLOAT8OID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "N"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 18));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 6));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_NUMERIC));
      break;
    }
    case TIMESTAMPOID:
    case TIMESTAMPTZOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "T"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 8));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_DATETIME));
      break;
    }
    case TIMEOID: {
      hb_arraySetForward(atemp, FIELD_TYPE, hb_itemPutC(&temp, "T"));
      hb_arraySetForward(atemp, FIELD_LEN, hb_itemPutNI(&temp, 4));
      hb_arraySetForward(atemp, FIELD_DEC, hb_itemPutNI(&temp, 0));
      hb_arraySetForward(atemp, FIELD_DOMAIN, hb_itemPutNI(&temp, SQL_TIME));
      break;
    }
    default: {
      SR_TraceLog(LOGFILE, "Strange data type returned: %i\n", type);
      break;
    }
    }

    // Nullable
    hb_arraySetForward(atemp, FIELD_NULLABLE, hb_itemPutL(&temp, nullable));

    // add to main array
    hb_arraySetForward(ret, row + 1, atemp);
  }
  hb_itemRelease(atemp);
  // hb_itemRelease(temp);
  hb_itemReturnForward(ret);
  hb_itemRelease(ret);
  PQclear(stmtTemp);
}

//-----------------------------------------------------------------------------//

static void sr_PGSFieldGet(PHB_ITEM pField, PHB_ITEM pItem, char *bBuffer,
                           const HB_SIZE lLenBuff, /*HB_BOOL bQueryOnly,*/
                           /*(HB_ULONG ulSystemID,*/ const HB_BOOL bTranslate)
{
  const HB_LONG lType = hb_arrayGetNL(pField, 6);
  const HB_SIZE lLen = hb_arrayGetNL(pField, 3);
  const HB_SIZE lDec = hb_arrayGetNL(pField, 4);

  // HB_SYMBOL_UNUSED(bQueryOnly);
  // HB_SYMBOL_UNUSED(ulSystemID);

  if (lLenBuff <= 0) { // database content is NULL
    switch (lType) {
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
    default: {
      SR_TraceLog(LOGFILE, "Invalid data type detected: %i\n", lType);
    }
    }
  } else {
    switch (lType) {
    case SQL_CHAR: {
      HB_SIZE lPos;
      char *szResult = (char *)hb_xgrab(lLen + 1);
      hb_xmemcpy(szResult, bBuffer, (lLen < lLenBuff ? lLen : lLenBuff));
      for (lPos = lLenBuff; lPos < lLen; lPos++) {
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
      PHB_ITEM pTemp;
      if (lLenBuff > 0 && (strncmp(bBuffer, "[", 1) == 0 || strncmp(bBuffer, "[]", 2)) &&
          (sr_lSerializeArrayAsJson())) {
        if (s_pSym_SR_FROMJSON == SR_NULLPTR) {
          s_pSym_SR_FROMJSON = hb_dynsymFindName("HB_JSONDECODE");
          if (s_pSym_SR_FROMJSON == SR_NULLPTR) {
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
      } else if (lLenBuff > 10 && strncmp(bBuffer, SQL_SERIALIZED_SIGNATURE, 10) == 0 &&
                 (!sr_lSerializedAsString())) {
        if (s_pSym_SR_DESERIALIZE == SR_NULLPTR) {
          s_pSym_SR_DESERIALIZE = hb_dynsymFindName("SR_DESERIALIZE");
          if (s_pSym_SR_DESERIALIZE == SR_NULLPTR) {
            printf("Could not find Symbol SR_DESERIALIZE\n");
          }
        }
        hb_vmPushDynSym(s_pSym_SR_DESERIALIZE);
        hb_vmPushNil();
        hb_vmPushString(bBuffer, lLenBuff);

        hb_vmDo(1);

        pTemp = hb_itemNew(SR_NULLPTR);
        hb_itemMove(pTemp, hb_stackReturnItem());

        if (HB_IS_HASH(pTemp) && sr_isMultilang() && bTranslate) {
          HB_ITEM pLangItem = {0};
          HB_SIZE ulPos;
          if (hb_hashScan(pTemp, sr_getBaseLang(&pLangItem), &ulPos) ||
              hb_hashScan(pTemp, sr_getSecondLang(&pLangItem), &ulPos) ||
              hb_hashScan(pTemp, sr_getRootLang(&pLangItem), &ulPos)) {
            hb_itemCopy(pItem, hb_hashGetValueAt(pTemp, ulPos));
          }
        } else {
          hb_itemMove(pItem, pTemp);
        }
        hb_itemRelease(pTemp);
      } else {
        hb_itemPutCL(pItem, bBuffer, lLenBuff);
      }
      break;
    }
    // xmltoarray
    case SQL_LONGVARCHARXML: {
      PHB_ITEM pTemp;
      PHB_ITEM pTemp1;
      if (s_pSym_SR_FROMXML == SR_NULLPTR) {
        s_pSym_SR_FROMXML = hb_dynsymFindName("SR_FROMXML");
        if (s_pSym_SR_FROMXML == SR_NULLPTR) {
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
#ifdef __XHARBOUR__
      hb_dateTimeStampStrGet(bBuffer, &lJulian, &lMilliSec);
#else
      hb_timeStampStrGetDT(bBuffer, &lJulian, &lMilliSec);
#endif
      hb_itemPutTDT(pItem, lJulian, lMilliSec);
      break;
    }
    case SQL_TIME: {
      long lMilliSec;
#ifdef __XHARBOUR__
      lMilliSec = hb_timeEncStr(bBuffer);
#else
      lMilliSec = hb_timeUnformat(bBuffer, SR_NULLPTR); // TOCHECK:
#endif
      hb_itemPutTDT(pItem, 0, lMilliSec);
      break;
    }
    default: {
      SR_TraceLog(LOGFILE, "Invalid data type detected: %i\n", lType);
    }
    }
  }
}

//----------------------------------------------------------------------------//

// SR_PGSLINEPROCESSED(pSession, p2, aFields, lQueryOnly, nSystemID, lTranslate, aReturn) -> NIL
// NOTES:
// . parameter 'p2' not used
// . parameter 'lQueryOnly' not used
// . parameter 'nSystemID' not used
HB_FUNC_STATIC(SR_PGSLINEPROCESSED)
{
  GET_PGSQL_SESSION(session, 1);
  // PHB_ITEM temp;
  HB_USHORT i;
  char *col;
  PHB_ITEM pFields = hb_param(3, HB_IT_ARRAY);
  // HB_BOOL bQueryOnly = hb_parl(4); (not used)
  // HB_ULONG ulSystemID = hb_parnl(5); (not used)
  HB_BOOL bTranslate = hb_parl(6);
  PHB_ITEM pRet = hb_param(7, HB_IT_ARRAY);
  HB_LONG lIndex, cols;

  if (session == SR_NULLPTR || session->dbh == SR_NULLPTR || session->stmt == SR_NULLPTR) {
    return;
  }

  cols = (HB_LONG)hb_arrayLen(pFields);

  for (i = 0; i < cols; i++) {
    // temp = hb_itemNew(SR_NULLPTR); (using stack instead of heap)
    HB_ITEM temp = {0};
    lIndex = hb_arrayGetNL(hb_arrayGetItemPtr(pFields, i + 1), FIELD_ENUM);

    if (lIndex != 0) {
      col = PQgetvalue(session->stmt, session->ifetch, lIndex - 1);
      sr_PGSFieldGet(hb_arrayGetItemPtr(pFields, i + 1), &temp, (char *)col, strlen(col),
                     /*bQueryOnly,*/ /*ulSystemID,*/
                     bTranslate);
    }
    hb_arraySetForward(pRet, i + 1, &temp);
    // hb_itemRelease(temp);
  }
}

//----------------------------------------------------------------------------//

HB_FUNC_STATIC(SR_PGSAFFECTEDROWS)
{
  GET_PGSQL_SESSION(session, 1);

  hb_retni(session != SR_NULLPTR ? session->iAffectedRows : 0);
}

//----------------------------------------------------------------------------//

#pragma ENDDUMP
