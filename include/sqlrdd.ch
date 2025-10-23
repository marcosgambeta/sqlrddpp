//
// SQLRDD PRG Header (used by C code also)
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

#ifndef SQLRDD_CH
#define SQLRDD_CH

#define HB_SR__VERSION_STRING       "SQLRDD(EX) 9.0"
#define HB_SR__MGMNT_VERSION        "MGMNT 1.72"

#define MAX_FIELDS                  512

#define HB_SQLRDD_BUILD             15
#define DBI_RDD_BUILD               1030
#define DBI_INTERNAL_OBJECT         1001
#define DBI_CPCONVERTTO             1002
#define TOP_BOTTOM_SCOPE            2

#define WORKAREA_CLASS              "SR_WORKAREA"
#define HASH_TABLE_SIZE             1000

#define CONNECT_ODBC                   1
#define CONNECT_RPC                    2
#define CONNECT_MYSQL                  3
#define CONNECT_POSTGRES               4
#define CONNECT_ORACLE                 5
#define CONNECT_FIREBIRD               6
#define CONNECT_MARIA                  7
#define CONNECT_ORACLE2                8
#define CONNECT_FIREBIRD3              9
#define CONNECT_FIREBIRD4              10
#define CONNECT_FIREBIRD5              11

#define CONNECT_QUERY_ONLY           100
#define CONNECT_NOEXLOCK              50

#define CONNECT_ODBC_QUERY_ONLY        1 + CONNECT_QUERY_ONLY
#define CONNECT_RPC_QUERY_ONLY         2 + CONNECT_QUERY_ONLY
#define CONNECT_MYSQL_QUERY_ONLY       3 + CONNECT_QUERY_ONLY
#define CONNECT_POSTGRES_QUERY_ONLY    4 + CONNECT_QUERY_ONLY
#define CONNECT_ORACLE_QUERY_ONLY      5 + CONNECT_QUERY_ONLY
#define CONNECT_FIREBIRD_QUERY_ONLY    6 + CONNECT_QUERY_ONLY
#define CONNECT_MARIA_QUERY_ONLY       7 + CONNECT_QUERY_ONLY
#define CONNECT_ORACLE2_QUERY_ONLY     8 + CONNECT_QUERY_ONLY
#define CONNECT_FIREBIRD3_QUERY_ONLY   9 + CONNECT_QUERY_ONLY
#define CONNECT_FIREBIRD4_QUERY_ONLY   10 + CONNECT_QUERY_ONLY
#define CONNECT_FIREBIRD5_QUERY_ONLY   11 + CONNECT_QUERY_ONLY

#define CONNECT_ODBC_NOEXLOCK          1 + CONNECT_NOEXLOCK
#define CONNECT_RPC_NOEXLOCK           2 + CONNECT_NOEXLOCK
#define CONNECT_MYSQL_NOEXLOCK         3 + CONNECT_NOEXLOCK
#define CONNECT_POSTGRES_NOEXLOCK      4 + CONNECT_NOEXLOCK
#define CONNECT_ORACLE_NOEXLOCK        5 + CONNECT_NOEXLOCK
#define CONNECT_FIREBIRD_NOEXLOCK      6 + CONNECT_NOEXLOCK
#define CONNECT_MARIA_NOEXLOCK         7 + CONNECT_NOEXLOCK
#define CONNECT_ORACLE2_NOEXLOCK       8 + CONNECT_NOEXLOCK
#define CONNECT_FIREBIRD3_NOEXLOCK     9 + CONNECT_NOEXLOCK
#define CONNECT_FIREBIRD4_NOEXLOCK     10 + CONNECT_NOEXLOCK
#define CONNECT_FIREBIRD5_NOEXLOCK     11 + CONNECT_NOEXLOCK

#define CONNECT_CUSTOM               999

// some errors
#define ESQLRDD_OPEN                1001
#define ESQLRDD_CLOSE               1002
#define ESQLRDD_CREATE              1004
#define ESQLRDD_READ                1010
#define ESQLRDD_WRITE               1011
#define ESQLRDD_CORRUPT             1012
#define ESQLRDD_DATATYPE            1020
#define ESQLRDD_DATAWIDTH           1021
#define ESQLRDD_SHARED              1023
#define ESQLRDD_READONLY            1025
#define ESQLRDD_NOT_COMMITED_YET    1026

// supported RDBMS

#define SUPPORTED_DATABASES           23

#define LASTREC_POS             99999998

// Log changes to SR_MGMNTLOGCHG - modes

#define SQLLOGCHANGES_NOLOG                           0     // Does not log
#define SQLLOGCHANGES_BEFORE_COMMAND                  1     // May log wrong statements
#define SQLLOGCHANGES_AFTER_COMMAND                  10     // Logs only if command was succefull
#define SQLLOGCHANGES_IN_TRANSACTION                100     // Otherwise log goes by second connection, outside transaction control
#define SQLLOGCHANGES_LOCKS                        1000     // Log Line LOCKS
#define SQLLOGCHANGES_DELETE_AFTER_TRANSACTION    10000     // Delete all previous ocourrences from current database connection when transaction is finished
#define SQLLOGCHANGES_LOG_CALLSTACK              100000     // Log Call Stack - good when looking for locked peers

#define SQLLOGCHANGES_SIZE                            6

// SR_MGMNTLOGCHG type column

#define SQLLOGCHANGES_TYPE_DML                "01"
#define SQLLOGCHANGES_TYPE_DDL                "02"
#define SQLLOGCHANGES_TYPE_LOCK               "03"

// Sequence per table

#define SEQ_NOTDEFINED                         0
#define SEQ_PER_TABLE                          1
#define SEQ_PER_DATABASE                       2

// Workarea Type

#define WATYPE_UNDEF                   0
#define WATYPE_ISAM                    1
// #define WATYPE_CACHE                   2     --  Deprecated

// eval( SQLGetTableInfoBlock(), cTableName ) return array constants

#define TABLE_INFO_SIZE               16

#define TABLE_INFO_TABLE_NAME          1
#define TABLE_INFO_FILTERS             2
#define TABLE_INFO_PRIMARY_KEY         3
#define TABLE_INFO_RELATION_TYPE       4
#define TABLE_INFO_OWNER_NAME          5
#define TABLE_INFO_ALL_IN_CACHE        6
#define TABLE_INFO_CUSTOM_SQL          7
#define TABLE_INFO_CAN_INSERT          8
#define TABLE_INFO_CAN_UPDATE          9
#define TABLE_INFO_CAN_DELETE         10
#define TABLE_INFO_HISTORIC           11
#define TABLE_INFO_RECNO_NAME         12
#define TABLE_INFO_DELETED_NAME       13
#define TABLE_INFO_CONNECTION         14
#define TABLE_INFO_QUALIFIED_NAME     15
#define TABLE_INFO_NO_TRANSAC         16

// Table Relation Methods

#define TABLE_INFO_RELATION_TYPE_SELECT     0
#define TABLE_INFO_RELATION_TYPE_JOIN       1
#define TABLE_INFO_RELATION_TYPE_OUTER_JOIN 2

// Historic management

#define HISTORIC_ACTIVE_RECORD              0
#define HISTORIC_LAST_RECORD                1
#define HISTORIC_FIRST_RECORD               2

// dbCreate Record Array Structure

#define FIELD_INFO_SIZE                11

#define FIELD_NAME                      1
#define FIELD_TYPE                      2
#define FIELD_LEN                       3
#define FIELD_DEC                       4
#define FIELD_NULLABLE                  5
#define FIELD_DOMAIN                    6  // Not used by dbCreate
#define FIELD_MULTILANG                 7
#define FIELD_ENUM                      8  // Not used by dbCreate
#define FIELD_WAOFFSET                  9  // Not used by dbCreate
#define FIELD_PRIMARY_KEY              10
#define FIELD_UNIQUE                   11

#define MULTILANG_FIELD_ON             .T.
#define MULTILANG_FIELD_OFF            .F.

#ifndef SQL_ERRCODES
#include "sqlodbc.ch"
#endif

#ifndef SQLRDD_H
#define IS_SQLRDD   (Select() > 0 .AND. (RddName()=="SQLRDD" .OR. RddName()=="SQLEX"))
#endif

#endif // SQLRDD_CH
