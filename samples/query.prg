/*
* SQL Parser test routine II
* Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"
#include "sqlodbc.ch"

#define RECORDS_IN_TEST       1000
#define SQL_DBMS_NAME           17
#define SQL_DBMS_VER            18

FUNCTION MAIN(cRDD, cDsn)

   LOCAL aStruct := { ;
                     {"CODE_ID" , "C",  8, 0}, ;
                     {"CARDID"  , "C",  1, 0}, ;
                     {"DESCR"   , "C", 50, 0}, ;
                     {"PERCENT" , "N",  8, 2}, ;
                     {"DAYS"    , "N",  6, 0}, ;
                     {"DATE_LIM", "D",  8, 0}, ;
                     {"ENABLE"  , "L",  1, 0}, ;
                     {"OBS"     , "M", 10, 0}, ;
                     {"VALUE"   , "N", 18, 6} ;
                    }
   LOCAL aReturn := {}
   LOCAL cComm
   LOCAL apCode
   LOCAL cOut
   LOCAL nErr
   LOCAL nPos
   LOCAL vEmp := {}
   LOCAL nCnn
   LOCAL s
   LOCAL i
   LOCAL oSql

   Connect(cRDD, cDSN)    // see connect.prg

   ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "Creating table      :", dbCreate("TEST_TABLE1", aStruct, cRDD)

   ? "Appending " + alltrim(str(RECORDS_IN_TEST)) + " records in TEST_TABLE1"

   s := seconds()

   oSql   := SR_GetConnection()

   /* IMPORTANT: The "?" will be used as a parameter in SR_SQLCodeGen(). "??" means a NOT NULL column */

	cComm  := "INSERT INTO TEST_TABLE1 ( CODE_ID, DESCR, DAYS, DATE_LIM, ENABLE, VALUE, SR_DELETED ) VALUES ( ?, ?, ?, ?, ?, ?, ?? )"
	apCode := SR_SQLParse(cComm, @nErr, @nPos)

   FOR i := 1 TO RECORDS_IN_TEST

      nErr := oSql:exec(SR_SQLCodeGen(apCode, {strzero(i, 7), "DESCRIPTION", i, date(), .T., i, " "}, oSql:nSystemID))

      IF nErr != 0
         EXIT
      ENDIF

   NEXT i

   oSql:Commit()

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? ""
   ? "Creating table      :", dbCreate("TEST_TABLE2", aStruct, cRDD)

   ? "Appending " + alltrim(str(RECORDS_IN_TEST/10)) + " records in TEST_TABLE2"

   s := seconds()

   cComm  := "INSERT INTO TEST_TABLE2 ( CODE_ID, DESCR, DAYS, DATE_LIM, ENABLE, VALUE, SR_DELETED ) VALUES ( ?, ?, ?, ?, ?, ?, ?? )"
   apCode := SR_SQLParse(cComm, @nErr, @nPos)

   FOR i := 1 TO RECORDS_IN_TEST

      nErr := oSql:exec(SR_SQLCodeGen(apCode, {strzero(i, 7), "DESCRIPTION", i, date(), .T., i, " "}, oSql:nSystemID))

      IF nErr != 0
         EXIT
      ENDIF

   NEXT i

   oSql:Commit()

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? ""
   WAIT
   ? "Select records from both tables and obtain result set in an array"

   s := seconds()

   /* IMPORTANT: The "?" will be used as a parameter in SR_SQLCodeGen() */

   cComm  := "SELECT A.CODE_ID AS CODE_ID_A, B.CODE_ID AS CODE_ID_B, B.DESCR FROM TEST_TABLE1 A, TEST_TABLE2 B WHERE A.CODE_ID LEFT OUTER JOIN B.CODE_ID AND A.DAYS < ?"

   ? ""
   ? cComm
   ? ""

   apCode := SR_SQLParse(cComm, @nErr, @nPos)
   cComm  := SR_SQLCodeGen(apCode, {RECORDS_IN_TEST}, oSql:nSystemID)

   ? ""
   ? cComm
   ? ""

   nErr := oSql:exec(cComm, , .T., @aReturn)

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? "len(aReturn)        :", len(aReturn)
   ? ""
   ? "Select records from both tables and retrieve rows one by one"

   nErr := oSql:execute(cComm)
   oSql:iniFields(.F.)

   ? "Query structure from iniFields() method:"
   ? sr_showVector(oSql:aFields)
   ? " "

   aReturn := {}
   i := 0

   DO WHILE (oSql:Fetch(@aReturn) == SQL_SUCCESS)
      // Use aReturn with the line
      i++
   ENDDO

   ? "Retrieved lines     :", i
   ? " "
   ? "Select records from both tables and obtain result set in an dbf table"

   s := seconds()

   /* IMPORTANT: The "?" will be used as a parameter in SR_SQLCodeGen() */

   cComm  := "SELECT A.CODE_ID AS CODE_ID_A, B.CODE_ID AS CODE_ID_B, B.DESCR FROM TEST_TABLE1 A, TEST_TABLE2 B WHERE A.CODE_ID LEFT OUTER JOIN B.CODE_ID AND A.DAYS < ?"

   ? ""
   ? cComm
   ? ""

   apCode := SR_SQLParse(cComm, @nErr, @nPos)
   cComm  := SR_SQLCodeGen(apCode, {RECORDS_IN_TEST}, oSql:nSystemID)

   ? ""
   ? cComm
   ? ""

   nErr := oSql:exec(cComm, , .T., , "test.dbf")

   ? "Done, Elapsed time  :", seconds() - s, "seconds"
   ? "len(aReturn)        :", len(aReturn)

   ? ""

   WAIT "Select records from both tables and obtain result set in a workarea"

   // Now a query returning as a workarea

   dbUseArea(.F., "SQLRDD", cComm, "QUERY_ALIAS")
   browse()

RETURN NIL

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
