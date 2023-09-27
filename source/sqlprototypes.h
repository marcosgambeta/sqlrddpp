/*
 * SQLRDD Connection Classes C Internal header
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

HB_FUNC_EXTERN( SR_DESERIALIZE );

PHB_ITEM sr_escapeNumber( char *FromBuffer, HB_SIZE len, HB_SIZE dec, PHB_ITEM pRet );
PHB_ITEM sr_getBaseLang( PHB_ITEM );
PHB_ITEM sr_getSecondLang( PHB_ITEM );
PHB_ITEM sr_getRootLang( PHB_ITEM );
HB_BOOL HB_EXPORT sr_lSerializedAsString( void );
HB_BOOL HB_EXPORT sr_lHideRecno( void );
HB_BOOL HB_EXPORT sr_lHideHistoric( void );
HB_BOOL HB_EXPORT sr_isMultilang( void );
HB_BOOL HB_EXPORT sr_isShutdownProcess( void );
HB_BOOL HB_EXPORT sr_UseDeleteds( void );
HB_BOOL HB_EXPORT sr_lSerializeArrayAsJson( void );
HB_BOOL HB_EXPORT sr_lsql2008newTypes( void );
HB_BOOL HB_EXPORT sr_iOldPgsBehavior( void ) ;
HB_BOOL HB_EXPORT sr_fShortasNum( void );
#ifdef SQLRDD_COMPAT_PRE_1_1
   HB_BOOL hb_arraySetNL( PHB_ITEM pArray, HB_ULONG ulIndex, HB_LONG ulVal );
   HB_BOOL hb_arraySetL( PHB_ITEM pArray, HB_ULONG ulIndex, HB_BOOL lVal );
#endif
HB_BOOL iTemCompEqual( PHB_ITEM pItem1, PHB_ITEM pItem2 );
HB_BOOL hb_itemEmpty( PHB_ITEM pItem );
HB_BOOL sr_GoTopOnScope( void );

// SOme commom defines to ALL SQL RDDs

#define FIELD_LIST_LEARNING         0
#define FIELD_LIST_STABLE           1
#define FIELD_LIST_CHANGED          2
#define FIELD_LIST_NEW_VALUE_READ   3

