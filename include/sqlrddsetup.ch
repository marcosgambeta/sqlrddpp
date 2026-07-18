// SQLRDD PRG/C Internal header
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

#ifndef SQLRDDSETUP_CH
#define SQLRDDSETUP_CH

#define SR_LOCK_TIMEOUT             3
#define SR_LOCKTABLE_TRIES          2
#define SR_MAXIMUN_LOCKS          100
#define SR_MAX_TABLE_NAME_LENGHT   30
#define SR_CACHE_PAGE_SIZE        200
#define SR_SQL_SERIALIZED_SIGNATURE     "!#SERIAL#!"
#define SR_HB_RETRY                       HB_FAILURE + 100

#define SR_AINFO_BOF                      1
#define SR_AINFO_EOF                      2
#define SR_AINFO_FOUND                    3
#define SR_AINFO_RECNO                    4
#define SR_AINFO_FCOUNT                   5
#define SR_AINFO_RCOUNT                   6
#define SR_AINFO_HOT                      7
#define SR_AINFO_DELETED                  8
#define SR_AINFO_HNRECNO                  9
#define SR_AINFO_HNDELETED               10
#define SR_AINFO_SHARED                  11
#define SR_AINFO_ISINSERT                12
#define SR_AINFO_BOF_AT                  13
#define SR_AINFO_EOF_AT                  14
#define SR_AINFO_BUFFER_VALID            15
#define SR_AINFO_INDEXORD                16
#define SR_AINFO_REVERSE_INDEX           17
#define SR_AINFO_SKIPCOUNT               18
#define SR_AINFO_WASDEL                  19
#define SR_AINFO_NPOSCACHE               20
#define SR_AINFO_NCACHEBEGIN             21
#define SR_AINFO_NCACHEEND               22
#define SR_AINFO_DETECT1_LASTRECNO       23
#define SR_AINFO_DETECT1_COUNT           24

// cache flags

#define SR_ORD_INVALID                    0
#define SR_ORD_DIR_FWD                    1
#define SR_ORD_DIR_BWD                    2
#define SR_ORD_NATURAL                    3 // not used in sqlrdd code

#define SR_SQL_NULL_HSTMT                 0 // not used in sqlrdd code

// aIndexMgmnt array structure

#define SR_INDEXMAN_SIZE                 14

#define SR_INDEXMAN_TABLE                 1
#define SR_INDEXMAN_SIGNATURE             2
#define SR_INDEXMAN_IDXNAME               3
#define SR_INDEXMAN_IDXKEY                4
#define SR_INDEXMAN_FOR_EXPRESS           5
#define SR_INDEXMAN_COLUMNS               6
#define SR_INDEXMAN_TAG                   7
#define SR_INDEXMAN_TAGNUM                8
#define SR_INDEXMAN_KEY_CODEBLOCK         9
#define SR_INDEXMAN_FOR_CODEBLOCK         10
#define SR_INDEXMAN_VIRTUAL_SYNTH         11
#define SR_INDEXMAN_UNUSED                12
#define SR_INDEXMAN_SYNTH_COLPOS          13
#define SR_INDEXMAN_FOR_COLPOS            14

// aIndex array structure

#define SR_AINDEX_ORDER_ASCEND                   1
#define SR_AINDEX_ORDER_DESEND                   2
#define SR_AINDEX_INDEX_FIELDS                   3
#define SR_AINDEX_INDEX_KEY                      4
#define SR_AINDEX_FOR_CLAUSE                     5
#define SR_AINDEX_STR_DESCENDS                   6
#define SR_AINDEX_SEEK_CODEBLOCK                 7
#define SR_AINDEX_FOR_CODEBLOCK                  8
#define SR_AINDEX_ORDER_TAG                      9
#define SR_AINDEX_ORDER_NAME                    10
#define SR_AINDEX_TOP_SCOPE                     11
#define SR_AINDEX_BOTTOM_SCOPE                  12
#define SR_AINDEX_SCOPE_SQLEXPR                 13
#define SR_AINDEX_ORDER_SKIP_UP                 14
#define SR_AINDEX_ORDER_SKIP_DOWN               15
#define SR_AINDEX_SYNTH_INDEX_COL_POS           16
#define SR_AINDEX_DESCEND_INDEX_ORDER           17
#define SR_AINDEX_VIRTUAL_INDEX_NAME            18
#define SR_AINDEX_VIRTUAL_INDEX_EXPR            19
#define SR_AINDEX_INDEX_KEY_CODEBLOCK           20
#define SR_AINDEX_INDEX_PHISICAL_NAME           21

// INDEX_FIELDS component structure
// Plain column components have only NAME and POS.
// Expression index components (PostgreSQL) carry the SQL expression,
// the component type/len and a client-side transform codeblock.

#define IDXFLD_NAME                    1
#define IDXFLD_POS                     2
#define IDXFLD_SQL                     3
#define IDXFLD_TYPE                    4
#define IDXFLD_LEN                     5
#define IDXFLD_XFORM                   6

#define SR_AORDER_NAME                    1
#define SR_AORDER_FOR                     2
#define SR_AORDER_TYPE                    3
#define SR_AORDER_UNIQUE                  4

#define SR_CACHEINFO_LEN                 13
#define SR_CACHEINFO_TABINFO              1
#define SR_CACHEINFO_TABNAME              2
#define SR_CACHEINFO_CONNECT              3
#define SR_CACHEINFO_INDEX                4
#define SR_CACHEINFO_AFIELDS              5
#define SR_CACHEINFO_ANAMES               6
#define SR_CACHEINFO_ABLANK               7
#define SR_CACHEINFO_HNRECNO              8
#define SR_CACHEINFO_HNDELETED            9
#define SR_CACHEINFO_INIFIELDS           10
#define SR_CACHEINFO_HNPOSDTHIST         11
#define SR_CACHEINFO_HNCOLPK             12
#define SR_CACHEINFO_ANAMES_LOWER        13


#define ORDER_TYPE_ASCEND              1
#define ORDER_TYPE_DESASCEND           0

#define LIST_FROM_TOP                  0
#define LIST_FROM_BOTTOM               1
#define LIST_SKIP_FWD                  2
#define LIST_SKIP_BWD                  3

#define LIST_FORWARD                   0
#define LIST_BACKWARD                  1

#define LONG_LIST                      0
#define SHORT_LIST                     1

#define EXCLUSIVE_TABLE_LOCK_SIGN   "SQL_EXCLUSIVE_TABLE_$_"
#define FLOCK_TABLE_LOCK_SIGN       "SQL_FLOCK_TABLE_$_"
#define SHARED_TABLE_LOCK_SIGN      "SQL_SHARED_TABLE_$_"
#define LAST_CHAR                   "z"

#define ARRAY_BLOCK1      1
#define ARRAY_BLOCK2      10
#define ARRAY_BLOCK3      50
#define ARRAY_BLOCK4      100
#define ARRAY_BLOCK5      500

// dbCreate Record Array Structure
#ifndef FIELD_INFO_SIZE
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

#define SUPPORTED_DATABASES           23

#endif

#endif // SQLRDDSETUP_CH
