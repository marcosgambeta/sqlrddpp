/*
 * C Header for SQL Parser
 * Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2, or (at your option)
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this software; see the file COPYING.  If not, write to
 * the Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA 02111-1307 USA (or visit the web site http://www.gnu.org/).
 *
 * As a special exception, the xHarbour Project gives permission for
 * additional uses of the text contained in its release of xHarbour.
 *
 * The exception is that, if you link the xHarbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the xHarbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the xHarbour
 * Project under the name xHarbour.  If you copy code from other
 * xHarbour Project or Free Software Foundation releases into a copy of
 * xHarbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for xHarbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

#ifndef SQL_PARSER_INCLUDED
#define SQL_PARSER_INCLUDED

#include <hbapi.h>
#include <hbapiitm.h>
#include <hbapierr.h>
#include <hbvm.h>
#include "hbsql.ch"

#if !defined(NULL)
#define NULL ((void*) 0)
#endif

#define PARSE_ALL_QUERY    0
#define isalnum_(c) (isalnum(c) || c == '_')

typedef struct sql_stmt_s {
   int command;
   int numParam;
   int errMsg;
   int where;
   const char* query;
   int queryLen;
   const char* queryPtr;
   const char* errPtr;
   PHB_ITEM pArray;
   PHB_ITEM pTemp;
} sql_stmt;

/* Prototypes */

PHB_ITEM SQLpCodeGenInt( int code );
PHB_ITEM SQLpCodeGenItemInt( PHB_ITEM value, int code );
PHB_ITEM SQLpCodeGenIntItem( int code, PHB_ITEM value );
PHB_ITEM SQLpCodeGenIntItem2( int code, PHB_ITEM value, int code2, PHB_ITEM value2 );
PHB_ITEM SQLpCodeGenIntArray( int code, PHB_ITEM pArray );
PHB_ITEM SQLpCodeGenArrayIntInt( PHB_ITEM pArray, int code, int code2 );
PHB_ITEM SQLpCodeGenArrayInt( PHB_ITEM pArray, int code );
PHB_ITEM SQLpCodeGenArrayJoin( PHB_ITEM pArray1, PHB_ITEM pArray2 );

#endif
