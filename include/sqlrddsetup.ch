//
// SQLRDD PRG/C Internal header
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

#ifndef SQLRDDSETUP_CH
#define SQLRDDSETUP_CH

#define LOCK_TIMEOUT             3
#define LOCKTABLE_TRIES          2
#define MAXIMUN_LOCKS          100
#define MAX_TABLE_NAME_LENGHT   30
#define CAHCE_PAGE_SIZE        200
#define SQL_SERIALIZED_SIGNATURE     "!#SERIAL#!"
#define HB_RETRY                       HB_FAILURE + 100

#define AINFO_BOF                      1
#define AINFO_EOF                      2
#define AINFO_FOUND                    3
#define AINFO_RECNO                    4
#define AINFO_FCOUNT                   5
#define AINFO_RCOUNT                   6
#define AINFO_HOT                      7
#define AINFO_DELETED                  8
#define AINFO_HNRECNO                  9
#define AINFO_HNDELETED               10
#define AINFO_SHARED                  11
#define AINFO_ISINSERT                12
#define AINFO_BOF_AT                  13
#define AINFO_EOF_AT                  14
#define AINFO_BUFFER_VALID            15
#define AINFO_INDEXORD                16
#define AINFO_REVERSE_INDEX           17
#define AINFO_SKIPCOUNT               18
#define AINFO_WASDEL                  19
#define AINFO_NPOSCACHE               20
#define AINFO_NCACHEBEGIN             21
#define AINFO_NCACHEEND               22
#define AINFO_DETECT1_LASTRECNO       23
#define AINFO_DETECT1_COUNT           24

// cache flags

#define ORD_INVALID                    0
#define ORD_DIR_FWD                    1
#define ORD_DIR_BWD                    2
#define ORD_NATURAL                    3

#define SQL_NULL_HSTMT                 0

// aIndexMgmnt array structure

#define INDEXMAN_SIZE                 14

#define INDEXMAN_TABLE                 1
#define INDEXMAN_SIGNATURE             2
#define INDEXMAN_IDXNAME               3
#define INDEXMAN_IDXKEY                4
#define INDEXMAN_FOR_EXPRESS           5
#define INDEXMAN_COLUMNS               6
#define INDEXMAN_TAG                   7
#define INDEXMAN_TAGNUM                8
#define INDEXMAN_KEY_CODEBLOCK         9
#define INDEXMAN_FOR_CODEBLOCK         10
#define INDEXMAN_VIRTUAL_SYNTH         11
#define INDEXMAN_UNUSED                12
#define INDEXMAN_SYNTH_COLPOS          13
#define INDEXMAN_FOR_COLPOS            14

// aIndex array structure

#define ORDER_ASCEND                   1
#define ORDER_DESEND                   2
#define INDEX_FIELDS                   3
#define INDEX_KEY                      4
#define FOR_CLAUSE                     5
#define STR_DESCENDS                   6
#define SEEK_CODEBLOCK                 7
#define FOR_CODEBLOCK                  8
#define ORDER_TAG                      9
#define ORDER_NAME                    10
#define TOP_SCOPE                     11
#define BOTTOM_SCOPE                  12
#define SCOPE_SQLEXPR                 13
#define ORDER_SKIP_UP                 14
#define ORDER_SKIP_DOWN               15
#define SYNTH_INDEX_COL_POS           16
#define DESCEND_INDEX_ORDER           17
#define VIRTUAL_INDEX_NAME            18
#define VIRTUAL_INDEX_EXPR            19
#define INDEX_KEY_CODEBLOCK           20
#define INDEX_PHISICAL_NAME           21

#define AORDER_NAME                    1
#define AORDER_FOR                     2
#define AORDER_TYPE                    3
#define AORDER_UNIQUE                  4

#define CACHEINFO_LEN                 13
#define CACHEINFO_TABINFO              1
#define CACHEINFO_TABNAME              2
#define CACHEINFO_CONNECT              3
#define CACHEINFO_INDEX                4
#define CACHEINFO_AFIELDS              5
#define CACHEINFO_ANAMES               6
#define CACHEINFO_ABLANK               7
#define CACHEINFO_HNRECNO              8
#define CACHEINFO_HNDELETED            9
#define CACHEINFO_INIFIELDS           10
#define CACHEINFO_HNPOSDTHIST         11
#define CACHEINFO_HNCOLPK             12
#define CACHEINFO_ANAMES_LOWER        13


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
