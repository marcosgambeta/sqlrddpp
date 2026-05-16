// HBXML - XML DOM oriented routines
// Copyright 2003 Giancarlo Niccolai <gian@niccolai.ws>

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
// along with this program; see the file LICENSE.txt.  If not, write to
// the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
// Boston, MA 02110-1301 USA (or visit https://www.gnu.org/licenses/).
//
// As a special exception, the Harbour Project gives permission for
// additional uses of the text contained in its release of Harbour.
//
// The exception is that, if you link the Harbour libraries with other
// files to produce an executable, this does not by itself cause the
// resulting executable to be covered by the GNU General Public License.
// Your use of that executable is in no way restricted on account of
// linking the Harbour library code into it.
//
// This exception does not however invalidate any other reasons why
// the executable file might be covered by the GNU General Public License.
//
// This exception applies only to the code released by the Harbour
// Project under the name Harbour.  If you copy code from other
// Harbour Project or Free Software Foundation releases into a copy of
// Harbour, as the General Public License permits, the exception does
// not apply to the code that you add in this way.  To avoid misleading
// anyone as to the status of such modified files, you must delete
// this exception notice from them.
//
// If you write modifications of your own for Harbour, it is your choice
// whether to permit this exception to apply to your modifications.
// If you do not wish that, delete this exception notice.
// $END_LICENSE$

#ifndef SR_XML_CH
#define SR_XML_CH

// Styles
#define SR_XML_STYLE_NOINDENT         0  // no indent nodes and insert new line after each node
#define SR_XML_STYLE_INDENT           1  // indent nodes with 1 space and insert new line after each node (default)
#define SR_XML_STYLE_TAB              2  // indent nodes with tab spaces and insert new line after each node
#define SR_XML_STYLE_THREESPACES      4  // indent nodes with 3 spaces and insert new line after each node
#define SR_XML_STYLE_NOESCAPE         8
#define SR_XML_STYLE_NONEWLINE        16 // no indent and no insert newline

// Status values
#define SR_XML_STATUS_ERROR           0
#define SR_XML_STATUS_OK              1
#define SR_XML_STATUS_MORE            2
#define SR_XML_STATUS_DONE            3
#define SR_XML_STATUS_UNDEFINED       4
#define SR_XML_STATUS_MALFORMED       5

// Error codes
#define SR_XML_ERROR_NONE             0
#define SR_XML_ERROR_IO               1
#define SR_XML_ERROR_NOMEM            2
#define SR_XML_ERROR_OUTCHAR          3
#define SR_XML_ERROR_INVNODE          4
#define SR_XML_ERROR_INVATT           5
#define SR_XML_ERROR_MALFATT          6
#define SR_XML_ERROR_INVCHAR          7
#define SR_XML_ERROR_NAMETOOLONG      8
#define SR_XML_ERROR_ATTRIBTOOLONG    9
#define SR_XML_ERROR_VALATTOOLONG     10
#define SR_XML_ERROR_UNCLOSED         11
#define SR_XML_ERROR_UNCLOSEDENTITY   12
#define SR_XML_ERROR_WRONGENTITY      13

// Node types
#define SR_XML_TYPE_TAG               0
#define SR_XML_TYPE_COMMENT           1
#define SR_XML_TYPE_PI                2
#define SR_XML_TYPE_DIRECTIVE         3
#define SR_XML_TYPE_DATA              4
#define SR_XML_TYPE_CDATA             5
#define SR_XML_TYPE_DOCUMENT          6

#endif // SR_XML_CH
