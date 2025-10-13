//
// SQLRDD Language Utilities
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

// #include "compat.ch"
#include <hbclass.ch>
#include <common.ch>
#include "msg.ch"

STATIC s_nMessages := 32

STATIC s_aMsg1 := ;
{ ;
   "Attempt to write to an empty table without a previous Append Blank",;
   "Undefined SQL datatype: ",;
   "Insert not allowed in table : ",;
   "Update not allowed without a WHERE clause.",;
   "Update not allowed in table : ",;
   "Invalid record number : ",;
   "Not connected to the SQL dabase server",;
   "Error Locking line or table (record# + table + error code):",;
   "Unsupported data type in : ",;
   "Syntax Error in filter expression : ",;
   "Error selecting IDENTITY after INSERT in table : ",;
   "Delete not allowed in table : ",;
   "Delete Failure ",;
   "Last command sent to database : ",;
   "Insert Failure ",;
   "Update Failure ",;
   "Error creating index : ",;
   "Index Column not Found - ",;
   "Invalid Index number or tag in OrdListFocus() : ",;
   "Seek without active index",;
   "Unsupported data type at column ",;
   "Unsupported database : ",;
   "Could not setup stmt option",;
   "RECNO column not found (column / table): ",;
   "DELETED column not found (column / table): ",;
   "Invalid dbSeek or SetScope Key Argument",;
   "Error Opening table in SQL database",;
   "Data type mismatch in dbSeek()",;
   "Invalid columns lists in constraints creating",;
   "Error altering NOT NULL column",;
   "Invalid column in index expression",;
   "Table or View does not exist";
}

STATIC s_aMsg2 := ;
{ ;
   "Tentativa de gravar um registro em tabela vazia sem antes adicionar uma linha",;
   "Tipo de dado SQL indefinido : ",;
   "Inclus�o n�o permitida na tabela : ",;
   "Update n�o permitido SEM cl�usula WHERE.",;
   "Altera��o n�o permitida na tabela : ",;
   "N�mero de Registro inexistente :",;
   "N�o conectado ao servidor de banco de dados",;
   "Erro travando registro ou tabela (num.registro + tabela + cod.erro):",;
   "Tipo de dado n�o suportado em : ",;
   "Erro de sitaxe em express�o de filtro : ",;
   "Erro ao selecionar IDENTITY ap�s INSERT na tabela : ",;
   "Exclus�o n�o permitida na tabela : ",;
   "Erro na exclus�o ",;
   "�ltimo comando enviado ao banco de dados : ",;
   "Erro na inclus�o ",;
   "Erro na altera��o ",;
   "Erro criando �ndice : ",;
   "Coluna de �ndice n�o existente - ",;
   "Indice ou tag inv�lido em OrdListFocus() : ",;
   "Seek sem �ndice ativo.",;
   "Tipo de dado inv�lido na coluna ",;
   "Banco de dados n�o suportado : ",;
   "Erro configurando stmt",;
   "Coluna de RECNO n�o encontrada (coluna / tabela): ",;
   "Coluna de DELETED n�o encontrada (coluna / tabela): ",;
   "Argumento chave inv�lido em dbSeek ou SetScope",;
   "Erro abrindo tabela no banco SQL",;
   "Tipo de dado inv�lido em dbSeek()",;
   "Listas de colunas inv�lidas em cria��o de constraints",;
   "Erro alterando coluna para NOT NULL",;
   "Coluna inv�lida na chave de �ndice",;
   "Tabela ou View n�o existente";
}

STATIC s_aMsg3 := ;
{ ;
   "Attempt to write to an empty table without a previous Append Blank",;
   "Undefined SQL datatype: ",;
   "Insert not allowed in table : ",;
   "Update not allowed without a WHERE clause.",;
   "Update not allowed in table : ",;
   "Invalid record number : ",;
   "Not connected to the SQL dabase server",;
   "Error Locking line or table (record# + table + error code):",;
   "Unsupported data type in : ",;
   "Syntax Error in filter expression : ",;
   "Error selecting IDENTITY after INSERT in table : ",;
   "Delete not allowed in table : ",;
   "Delete Failure ",;
   "Last command sent to database : ",;
   "Insert Failure ",;
   "Update Failure ",;
   "Error creating index : ",;
   "Index Column not Found - ",;
   "Invalid Index numner or tag in OrdListFocus() : ",;
   "Seek without active index",;
   "Unsupported data type at column ",;
   "Unsupported database : ",;
   "Could not setup stmt option",;
   "RECNO column not found (column / table): ",;
   "DELETED column not found (column / table): ",;
   "Invalid dbSeek or SetScope Key Argument",;
   "Error Opening table in SQL database",;
   "Data type mismatch in dbSeek()",;
   "Invalid columns lists in constraints creating",;
   "Error altering NOT NULL column",;
   "Invalid column in index expression",;
   "Table or View does not exist";
}

STATIC s_aMsg4 := ;
{ ;
   "Attempt to write to an empty table without a previous Append Blank",;
   "Undefined SQL datatype: ",;
   "Insert not allowed in table : ",;
   "Update not allowed without a WHERE clause.",;
   "Update not allowed in table : ",;
   "Invalid record number : ",;
   "Not connected to the SQL dabase server",;
   "Error Locking line or table (record# + table + error code):",;
   "Unsupported data type in : ",;
   "Syntax Error in filter expression : ",;
   "Error selecting IDENTITY after INSERT in table : ",;
   "Delete not allowed in table : ",;
   "Delete Failure ",;
   "Last command sent to database : ",;
   "Insert Failure ",;
   "Update Failure ",;
   "Error creating index : ",;
   "Index Column not Found - ",;
   "Invalid Index number or tag in OrdListFocus() : ",;
   "Seek without active index",;
   "Unsupported data type at column ",;
   "Unsupported database : ",;
   "Could not setup stmt option",;
   "RECNO column not found (column / table): ",;
   "DELETED column not found (column / table): ",;
   "Invalid dbSeek or SetScope Key Argument",;
   "Error Opening table in SQL database",;
   "Data type mismatch in dbSeek()",;
   "Invalid columns lists in constraints creating",;
   "Error altering NOT NULL column",;
   "Invalid column in index expression",;
   "Table or View does not exist";
}

STATIC s_aMsg5 := ;
{ ;
   "Attempt to write to an empty table without a previous Append Blank",;
   "Undefined SQL datatype: ",;
   "Insert not allowed in table : ",;
   "Update not allowed without a WHERE clause.",;
   "Update not allowed in table : ",;
   "Invalid record number : ",;
   "Not connected to the SQL dabase server",;
   "Error Locking line or table (record# + table + error code):",;
   "Unsupported data type in : ",;
   "Syntax Error in filter expression : ",;
   "Error selecting IDENTITY after INSERT in table : ",;
   "Delete not allowed in table : ",;
   "Delete Failure ",;
   "Last command sent to database : ",;
   "Insert Failure ",;
   "Update Failure ",;
   "Error creating index : ",;
   "Index Column not Found - ",;
   "Invalid Index number or tag in OrdListFocus() : ",;
   "Seek without active index",;
   "Unsupported data type at column ",;
   "Unsupported database : ",;
   "Could not setup stmt option",;
   "RECNO column not found (column / table): ",;
   "DELETED column not found (column / table): ",;
   "Invalid dbSeek or SetScope Key Argument",;
   "Error Opening table in SQL database",;
   "Data type mismatch in dbSeek()",;
   "Invalid columns lists in constraints creating",;
   "Error altering NOT NULL column",;
   "Invalid column in index expression",;
   "Table or View does not exist";
}

STATIC s_aMsg6 := ;
{ ;
   "Attempt to write to an empty table without a previous Append Blank",;
   "Undefined SQL datatype: ",;
   "Insert not allowed in table : ",;
   "Update not allowed without a WHERE clause.",;
   "Update not allowed in table : ",;
   "Invalid record number : ",;
   "Not connected to the SQL dabase server",;
   "Error Locking line or table (record# + table + error code):",;
   "Unsupported data type in : ",;
   "Syntax Error in filter expression : ",;
   "Error selecting IDENTITY after INSERT in table : ",;
   "Delete not allowed in table : ",;
   "Delete Failure ",;
   "Last command sent to database : ",;
   "Insert Failure ",;
   "Update Failure ",;
   "Error creating index : ",;
   "Index Column not Found - ",;
   "Invalid Index number or tag in OrdListFocus() : ",;
   "Seek without active index",;
   "Unsupported data type at column ",;
   "Unsupported database : ",;
   "Could not setup stmt option",;
   "RECNO column not found (column / table): ",;
   "DELETED column not found (column / table): ",;
   "Invalid dbSeek or SetScope Key Argument",;
   "Error Opening table in SQL database",;
   "Data type mismatch in dbSeek()",;
   "Invalid columns lists in constraints creating",;
   "Error altering NOT NULL column",;
   "Invalid column in index expression",;
   "Table or View does not exist";
}

STATIC s_aMsg7 := ;
{ ;
   "Attempt to write to an empty table without a previous Append Blank",;
   "Undefined SQL datatype: ",;
   "Insert not allowed in table : ",;
   "Update not allowed without a WHERE clause.",;
   "Update not allowed in table : ",;
   "Invalid record number : ",;
   "Not connected to the SQL dabase server",;
   "Error Locking line or table (record# + table + error code):",;
   "Unsupported data type in : ",;
   "Syntax Error in filter expression : ",;
   "Error selecting IDENTITY after INSERT in table : ",;
   "Delete not allowed in table : ",;
   "Delete Failure ",;
   "Last command sent to database : ",;
   "Insert Failure ",;
   "Update Failure ",;
   "Error creating index : ",;
   "Index Column not Found - ",;
   "Invalid Index number or tag in OrdListFocus() : ",;
   "Seek without active index",;
   "Unsupported data type at column ",;
   "Unsupported database : ",;
   "Could not setup stmt option",;
   "RECNO column not found (column / table): ",;
   "DELETED column not found (column / table): ",;
   "Invalid dbSeek or SetScope Key Argument",;
   "Error Opening table in SQL database",;
   "Data type mismatch in dbSeek()",;
   "Invalid columns lists in constraints creating",;
   "Error altering NOT NULL column",;
   "Invalid column in index expression",;
   "Table or View does not exist";
};

STATIC s_aMsg

//------------------------------------------------------------------------
INIT PROCEDURE SR_Init2

  s_aMsg := { s_aMsg1, s_aMsg2, s_aMsg3, s_aMsg4, s_aMsg5, s_aMsg6, s_aMsg7 }

  SR_SetMsgCount(Len(s_aMsg))

  SR_SetBaseLang(1)
  SR_SetSecondLang(LANG_EN_US)
  SR_SetRootLang(LANG_PT_BR)      // Root since I do it on Brazil

RETURN

//------------------------------------------------------------------------

FUNCTION SR_Msg(nMsg)
   Local nBaseLang := SR_SetBaseLang()

   If nMsg > 0 .AND. nMsg <= Len(s_aMsg[nBaseLang])
      RETURN s_aMsg[nBaseLang, nMsg]
   EndIf

RETURN ""

//------------------------------------------------------------------------

FUNCTION SR_GetErrMessageMax()

RETURN s_nMessages

//------------------------------------------------------------------------

#pragma BEGINDUMP

#include "compat.h"

static int s_iMsgCount = 0;
static int s_iBaseLang = 0;
static int s_iSecondLang = 0;
static int s_iRootLang = 0;

PHB_ITEM HB_EXPORT sr_getBaseLang(PHB_ITEM pLangItm)
{
  return hb_itemPutNI(pLangItm, s_iBaseLang);
}

PHB_ITEM HB_EXPORT sr_getSecondLang(PHB_ITEM pLangItm)
{
  return hb_itemPutNI(pLangItm, s_iSecondLang);
}

PHB_ITEM HB_EXPORT sr_getRootLang(PHB_ITEM pLangItm)
{
  return hb_itemPutNI(pLangItm, s_iRootLang);
}

HB_FUNC_STATIC(SR_SETMSGCOUNT)
{
  hb_retni(s_iMsgCount);
  if (HB_ISNUM(1)) {
    s_iMsgCount = hb_parni(1);
  }
}

HB_FUNC(SR_SETBASELANG)
{
  int iLang = hb_parni(1);

  hb_retni(s_iBaseLang);

  if (iLang > 0 && iLang <= s_iMsgCount) {
    s_iBaseLang = iLang;
  }
}

HB_FUNC(SR_SETSECONDLANG)
{
  int iLang = hb_parni(1);

  hb_retni(s_iSecondLang);

  if (iLang > 0 && iLang <= s_iMsgCount) {
    s_iSecondLang = iLang;
  }
}

HB_FUNC(SR_SETROOTLANG)
{
  int iLang = hb_parni(1);

  hb_retni(s_iRootLang);

  if (iLang > 0 && iLang <= s_iMsgCount) {
    s_iRootLang = iLang;
  }
}

#pragma ENDDUMP

//------------------------------------------------------------------------
