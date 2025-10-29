// SQLPARSER
// PRG level pCode Header for SQL Parser (used from C also)
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

#ifndef HBSQL_CH
#define HBSQL_CH

// pCode Instruction Set

#define SQL_PCODE_VERSION                    1

#define SQL_PCODE_SELECT                     0
#define SQL_PCODE_INSERT                     1
#define SQL_PCODE_UPDATE                     2
#define SQL_PCODE_DELETE                     3

#define SQL_PCODE_COLUMN_NAME                4
#define SQL_PCODE_COLUMN_BY_VALUE            5
#define SQL_PCODE_COLUMN_PARAM               6
#define SQL_PCODE_COLUMN_BINDVAR             7
#define SQL_PCODE_COLUMN_ALIAS               8
#define SQL_PCODE_COLUMN_NO_AS               9
#define SQL_PCODE_COLUMN_AS                  10
#define SQL_PCODE_COLUMN_NAME_BINDVAR        11
#define SQL_PCODE_COLUMN_NAME_PARAM          12
#define SQL_PCODE_COLUMN_PARAM_NOTNULL       13


#define SQL_PCODE_LOCK                       20
#define SQL_PCODE_NOLOCK                     21

#define SQL_PCODE_NO_WHERE                   22
#define SQL_PCODE_WHERE                      23

#define SQL_PCODE_TABLE_NAME                 25
#define SQL_PCODE_TABLE_NO_ALIAS             26
#define SQL_PCODE_TABLE_ALIAS                27
#define SQL_PCODE_TABLE_PARAM                28
#define SQL_PCODE_TABLE_BINDVAR              29

#define SQL_PCODE_COLUMN_LIST_SEPARATOR      80

#define SQL_PCODE_START_EXPR                 100
#define SQL_PCODE_STOP_EXPR                  101
#define SQL_PCODE_NOT_EXPR                   102

#define SQL_PCODE_FUNC_COUNT_AST             200
#define SQL_PCODE_FUNC_COUNT                 201
#define SQL_PCODE_FUNC_ABS                   202
#define SQL_PCODE_FUNC_AVG                   203
#define SQL_PCODE_FUNC_ISNULL                204
#define SQL_PCODE_FUNC_MAX                   205
#define SQL_PCODE_FUNC_MIN                   206
#define SQL_PCODE_FUNC_POWER                 207
#define SQL_PCODE_FUNC_ROUND                 208
#define SQL_PCODE_FUNC_SUBSTR                209
#define SQL_PCODE_FUNC_SUBSTR2               210
#define SQL_PCODE_FUNC_SUM                   211
#define SQL_PCODE_FUNC_TRIM                  212
#define SQL_PCODE_FUNC_DATE                  213

#define SQL_PCODE_SELECT_ITEM_ASTERISK       300
#define SQL_PCODE_SELECT_ITEM_ALIAS_ASTER    301
#define SQL_PCODE_SELECT_ALL                 302
#define SQL_PCODE_SELECT_DISTINCT            303
#define SQL_PCODE_SELECT_NO_LIMIT            304
#define SQL_PCODE_SELECT_LIMIT               305
#define SQL_PCODE_SELECT_ORDER_ASC           306
#define SQL_PCODE_SELECT_ORDER_DESC          307
#define SQL_PCODE_SELECT_ORDER               308
#define SQL_PCODE_SELECT_NO_ORDER            309
#define SQL_PCODE_SELECT_NO_GROUPBY          310
#define SQL_PCODE_SELECT_GROUPBY             311
#define SQL_PCODE_SELECT_FROM                312
#define SQL_PCODE_SELECT_UNION               313
#define SQL_PCODE_SELECT_UNION_ALL           314

#define SQL_PCODE_INSERT_NO_LIST             400
#define SQL_PCODE_INSERT_VALUES              401

#define SQL_PCODE_OPERATOR_BASE              1000

#define SQL_PCODE_OPERATOR_IN                1002
#define SQL_PCODE_OPERATOR_NOT_IN            1003
#define SQL_PCODE_OPERATOR_IS_NULL           1004
#define SQL_PCODE_OPERATOR_IS_NOT_NULL       1005
#define SQL_PCODE_OPERATOR_AND               1006
#define SQL_PCODE_OPERATOR_OR                1007
#define SQL_PCODE_OPERATOR_EQ                1008
#define SQL_PCODE_OPERATOR_NE                1009
#define SQL_PCODE_OPERATOR_GT                1010
#define SQL_PCODE_OPERATOR_GE                1011
#define SQL_PCODE_OPERATOR_LT                1012
#define SQL_PCODE_OPERATOR_LE                1013
#define SQL_PCODE_OPERATOR_LIKE              1014
#define SQL_PCODE_OPERATOR_PLUS              1015
#define SQL_PCODE_OPERATOR_MINUS             1016
#define SQL_PCODE_OPERATOR_MULT              1017
#define SQL_PCODE_OPERATOR_DIV               1018
#define SQL_PCODE_OPERATOR_CONCAT            1019
#define SQL_PCODE_OPERATOR_NOT_LIKE          1020

#define SQL_PCODE_OPERATOR_JOIN              1100
#define SQL_PCODE_OPERATOR_LEFT_OUTER_JOIN   1101
#define SQL_PCODE_OPERATOR_RIGHT_OUTER_JOIN  1102

// Error Messages

#define SQL_PARSER_ERROR_PARSE               1

#define SQL_PARSER_ERROR_NUMBER              2
#define SQL_PARSER_ERROR_NUMBER_NEGATIVE     3
#define SQL_PARSER_ERROR_NUMBER_EOF          4
#define SQL_PARSER_ERROR_NUMBER_INTEGER      5
#define SQL_PARSER_ERROR_NUMBER_FLOAT        6

#define SQL_PARSER_ERROR_STRING              10
#define SQL_PARSER_ERROR_STRING_QUOTED       11
#define SQL_PARSER_ERROR_STRING_DATE         12

#define SQL_PARSER_ERROR_MEM                 110
#define SQL_PARSER_ERROR_OUT_OF_BOUNDS       111
#define SQL_PARSER_ERROR_INTERNAL            112
#define SQL_PARSER_ERROR_LIMIT               113

#define SQL_SINTAX_ERROR_OUTER_JOIN          400
#define SQL_SINTAX_ERROR_OUTER_JOIN_OR       401

// Context Analisys Constants

#define SQL_CONTEXT_RESET                 0

#define SQL_CONTEXT_SELECT_LIST           1
#define SQL_CONTEXT_SELECT_FROM           2
#define SQL_CONTEXT_SELECT_PRE_WHERE      3
#define SQL_CONTEXT_SELECT_PRE_WHERE2     4
#define SQL_CONTEXT_SELECT_WHERE          5
#define SQL_CONTEXT_SELECT_GROUP          6
#define SQL_CONTEXT_SELECT_ORDER          7
#define SQL_CONTEXT_SELECT_UNION          8

#define SQL_CONTEXT_INSERT                11
#define SQL_CONTEXT_UPDATE                21
#define SQL_CONTEXT_DELETE                31


#endif // HBSQL_CH
