/*
* SQL Parser test routine
* Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"

FUNCTION Main()

   LOCAL cComm
   LOCAL apCode
   LOCAL cOut
   LOCAL nErr
   LOCAL nPos
   LOCAL i

   cComm := "SELECT TAB1.NAME, 200 AS " + chr(34) + "COL2" + chr(34) + ", 'ABC' AS " + chr(34) + "COL3" + chr(34) + ;
      ", B." + chr(34) + "ID" + chr(34) + " AS " + chr(34) + "VAL1" + chr(34) + ;
      " FROM TAB1, TAB2 B WHERE TAB1.NAME LIKE 'X%' AND TAB1.ID LEFT OUTER JOIN B.ID AND B.ID IS NOT NULL AND B.DUE_DATE > " + "[20021231]"

   ? "-------------------------------------------"
   ? cComm
   ? "-------------------------------------------"

   apCode := SR_SQLParse(cComm, @nErr, @nPos)

   IF len(apCode) > 0

      ? "SYSTEMID_ORACLE"
      ? "-------------------------------------------"
      ? SR_SQLCodeGen(apCode, {}, SYSTEMID_ORACLE)
      ? "-------------------------------------------"
      wait
      ? "SYSTEMID_MSSQL7"
      ? "-------------------------------------------"
      ? SR_SQLCodeGen(apCode, {}, SYSTEMID_MSSQL7)
      ? "-------------------------------------------"
      wait
      ? "SYSTEMID_IBMDB2"
      ? "-------------------------------------------"
      ? SR_SQLCodeGen(apCode, {}, SYSTEMID_IBMDB2)
      ? "-------------------------------------------"
      wait
      ? "SYSTEMID_POSTGR"
      ? "-------------------------------------------"
      ? SR_SQLCodeGen(apCode, {}, SYSTEMID_POSTGR)
      ? "-------------------------------------------"
      wait
      ? "SYSTEMID_MYSQL"
      ? "-------------------------------------------"
      ? SR_SQLCodeGen(apCode, {}, SYSTEMID_MYSQL)
      ? "-------------------------------------------"
      wait

   ELSE

      ? "Parse error", nErr, " at position ", nPos
      ? "-------------------------------------------"
      ? substr(cComm, nPos)
      ? "-------------------------------------------"

   ENDIF

   ? ""
   ? "Press any key to quit"

   inkey(0)

RETURN

/*------------------------------------------------------------------------*/
