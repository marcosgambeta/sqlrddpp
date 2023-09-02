/*
* SQLRDD Test
* Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"

#define SQL_DBMS_NAME           17
#define SQL_DBMS_VER            18

/*------------------------------------------------------------------------*/

FUNCTION Main(cRDD, cDSN)

   /* CODE_IS is the primary key 1st key. See SQLRDD.CH for details about structure array */

   LOCAL aStruct := { ;
                     {"CODE_ID", "C",  8, 0, .F., , , , , 1}, ;
                     {"CARDID" , "C",  1, 0}, ;
                     {"D1"     , "M", 10, 0}, ;
                     {"D2"     , "M", 10, 0}, ;
                     {"D3"     , "M", 10, 0}, ;
                     {"D4"     , "M", 10, 0} ;
                    }
   LOCAL nCnn
   LOCAL i
   LOCAL s

   ? ""
   ? "tstmemo.exe"
   ? ""
   ? "Small SQLRDD MEMO test"
   ? "(c) 2003 - Marcelo Lombardo"
   ? ""

   Connect(@cRDD, cDSN)    // see connect.prg

   ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "RDD in use          :", cRDD
   ? "Creating table      :", dbCreate("TEST_TABLE_MEMO", aStruct, cRDD)

   USE "TEST_TABLE_MEMO" SHARED VIA cRDD

   ? "Appending "

   APPEND BLANK
   REPLACE CODE_ID WITH "aaaaa"
   REPLACE D1      WITH date()
   REPLACE D2      WITH 1000
   REPLACE D3      WITH "aaaa"
   REPLACE D4      WITH {9999999, 2, 3, 4, 5, 6, date(), "a"}

   COMMIT
   dbclosearea()

   ? "Done"

   USE "TEST_TABLE_MEMO" SHARED VIA cRDD

   ? "D1", valtype(d1), d1
   ? "D2", valtype(d2), d2
   ? "D3", valtype(d3), d3
   ? "D4", valtype(d4), d4
   ? "D4", valtype(d4), sr_showvector(d4)

RETURN NIL

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
