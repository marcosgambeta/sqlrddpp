/*
* SQLRDD Server Side Constraints Sample
* Copyright (c) 2005 - Marcelo Lombardo  <marcelo@xharbour.com.br>
* All Rights Reserved
*/

// NOTE: this code is not compatible with Harbour

#include "sqlrdd.ch"

#define RECORDS_IN_TEST                   1000
#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

/*------------------------------------------------------------------------*/

FUNCTION Main(cDSN, lLog)

   LOCAL aStruct1 := { ;
                      {"DEPARTMENT_ID_PK"  , "C",  8, 0}, ;
                      {"DEPARTMENT_DESCR"  , "C", 50, 0}, ;
                      {"COST_CENTER_ID"    , "C", 10, 0};
                     }
   LOCAL aStruct2 := {;
                      {"COST_CENTER_ID_PK" , "C", 10, 0}, ;
                      {"COST_CENTER_DESCR" , "C", 50, 0} ;
                     }
   LOCAL aStruct3 := { ;
                      {"EMPLOYEE_ID_PK"    , "C",  8, 0}, ;
                      {"DEPARTMENT_ID"     , "C",  8, 0}, ;
                      {"EMPLOYEE_FIRSTNAME", "C", 50, 0}, ;
                      {"EMPLOYEE_LASTNAME" , "C", 50, 0}, ;
                      {"EMPLOYEE_EMAIL"    , "C", 80, 0} ;
                     }
   LOCAL nCnn
   LOCAL i
   LOCAL oErr

   ? ""
   ? "constraint.exe"
   ? ""
   ? "Server Side Constraints Sample"
   ? "(c) 2005 - Marcelo Lombardo"
   ? ""

   Alert("In current version, this sample works only with MySQL, MSSQL Server, Oracle and Postgres.")

   Connect(cDSN)    // see connect.prg

   SR_UseDeleteds(.F.)      // Don't keep deleted records in database

   ? "Connected to        :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)

   IF lLog != NIL
      ? "Starting LOG", SR_GetActiveConnection(), SR_StartLog()
   ENDIF

   RddSetDefault("SQLRDD")

   // Please note table creation order is VERY important.
   // If you chage it, you would not run sample twice

   ? "Creating table EMPLOYEE    :", dbCreate("EMPLOYEE", aStruct3)
   ? "Creating EMPLOYEE PRIMARY KEY..."
   USE "EMPLOYEE" NEW
   INDEX ON EMPLOYEE_ID_PK TAG EMPLOYEE_ID CONSTRAINT EMPLOYEE_PK TARGET EMPLOYEE KEY EMPLOYEE_ID_PK
   ? ""

   ? "Creating table DEPARTMENT  :", dbCreate("DEPARTMENT", aStruct1)
   ? "Creating DEPARTMENT PRIMARY KEY..."
   USE "DEPARTMENT" NEW
   INDEX ON DEPARTMENT_ID_PK TAG DEPARTMENT_ID CONSTRAINT DEPARTMENT_PK TARGET DEPARTMENT KEY DEPARTMENT_ID_PK
   ? ""

   ? "Creating table COST_CENTER :", dbCreate("COST_CENTER", aStruct2)
   ? "Creating COST_CENTER PRIMARY KEY..."
   USE "COST_CENTER" NEW
   INDEX ON COST_CENTER_ID_PK TAG COST_CENTER_ID CONSTRAINT COST_CENTER_PK TARGET COST_CENTER KEY COST_CENTER_ID_PK
   ? ""

   SELECT EMPLOYEE

   ? "Creating EMPLOYEE -> DEPARTMENT FOREIGN KEY..."
   INDEX ON DEPARTMENT_ID TAG EMPLOYEE_ID CONSTRAINT EMPLOYEE_FK1 TARGET DEPARTMENT KEY DEPARTMENT_ID_PK
   ? ""

   ? "Creating remaining EMPLOYEE indexes..."
   INDEX ON EMPLOYEE_LASTNAME  TAG EMPLOYEE_LASTNAME
   INDEX ON EMPLOYEE_FIRSTNAME TAG EMPLOYEE_FIRSTNAME
   ? ""

   SELECT COST_CENTER

   ? "Creating remaining COST_CENTER indexes..."
   INDEX ON COST_CENTER_DESCR  TAG COST_CENTER_DESCR
   ? ""

   SELECT DEPARTMENT

   ? "Creating DEPARTMENT -> COST_CENTER FOREIGN KEY..."
   INDEX ON COST_CENTER_ID TAG COST_CENTER_ID CONSTRAINT DEPARTMENT_FK1 TARGET COST_CENTER KEY COST_CENTER_ID_PK
   ? ""

   ? "Creating remaining DEPARTMENT indexes..."
   INDEX ON DEPARTMENT_DESCR TAG DEPARTMENT_DESCR
   ? ""

   ? "Add some cost centers..."
   SELECT COST_CENTER
   APPEND BLANK
   REPLACE COST_CENTER_ID_PK WITH "1.01.001"
   REPLACE COST_CENTER_DESCR WITH "Sales"
   APPEND BLANK
   REPLACE COST_CENTER_ID_PK WITH "1.01.002"
   REPLACE COST_CENTER_DESCR WITH "Manufacturing"
   APPEND BLANK
   REPLACE COST_CENTER_ID_PK WITH "1.01.003"
   REPLACE COST_CENTER_DESCR WITH "Administration"
   dbUnlock()
   dbCommit()

   ? ""
   ? "We have PRIMERY KEY defined, so it will NOT allow duplicate cost center ID"
   ? ""
   ? "   **** Run time error MUST happen ****"
   ? ""

   BEGIN SEQUENCE
      // Try to push a DUPLICATE record
      APPEND BLANK
      REPLACE COST_CENTER_ID_PK WITH "1.01.001"      // DUPLICATED ID
      REPLACE COST_CENTER_DESCR WITH "Sales"
      dbCommit()
   RECOVER USING oErr
      ? oErr:Description
   END SEQUENCE
   WAIT

   CLEAR SCREEN
   ? "Add some cost departments..."
   SELECT DEPARTMENT
   APPEND BLANK
   REPLACE DEPARTMENT_ID_PK WITH "001"
   REPLACE DEPARTMENT_DESCR WITH "Commercial"
   REPLACE COST_CENTER_ID   WITH "1.01.001"

   APPEND BLANK
   REPLACE DEPARTMENT_ID_PK WITH "003"
   REPLACE DEPARTMENT_DESCR WITH "Accounting"
   REPLACE COST_CENTER_ID   WITH "1.01.003"
   dbUnlock()
   dbCommit()

   ? ""
   ? "We have FOREIGN KEY defined, so it will NOT allow to add a department"
   ? "in a cost center that DOES NOT EXIST"
   ? ""
   ? "   **** Run time error MUST happen ****"
   ? ""

   BEGIN SEQUENCE
      APPEND BLANK
      REPLACE DEPARTMENT_ID_PK WITH "005"
      REPLACE DEPARTMENT_DESCR WITH "Advertising"
      REPLACE COST_CENTER_ID   WITH "1.01.005"
      dbCommit()
   RECOVER USING oErr
      ? oErr:Description
   END SEQUENCE
   WAIT

   CLEAR SCREEN
   ? "Add some cost employees..."
   SELECT EMPLOYEE
   APPEND BLANK
   REPLACE EMPLOYEE_ID_PK     WITH "0001"
   REPLACE DEPARTMENT_ID      WITH "001"
   REPLACE EMPLOYEE_FIRSTNAME WITH "James"
   REPLACE EMPLOYEE_LASTNAME  WITH "Labrie"

   APPEND BLANK
   REPLACE EMPLOYEE_ID_PK     WITH "0002"
   REPLACE DEPARTMENT_ID      WITH "001"
   REPLACE EMPLOYEE_FIRSTNAME WITH "John"
   REPLACE EMPLOYEE_LASTNAME  WITH "Petrucci"

   APPEND BLANK
   REPLACE EMPLOYEE_ID_PK     WITH "0003"
   REPLACE DEPARTMENT_ID      WITH "001"
   REPLACE EMPLOYEE_FIRSTNAME WITH "Mark"
   REPLACE EMPLOYEE_LASTNAME  WITH "Portnoy"

   APPEND BLANK
   REPLACE EMPLOYEE_ID_PK     WITH "0004"
   REPLACE DEPARTMENT_ID      WITH "003"
   REPLACE EMPLOYEE_FIRSTNAME WITH "Jodan"
   REPLACE EMPLOYEE_LASTNAME  WITH "Rudess"

   APPEND BLANK
   REPLACE EMPLOYEE_ID_PK     WITH "0005"
   REPLACE DEPARTMENT_ID      WITH "003"
   REPLACE EMPLOYEE_FIRSTNAME WITH "Jhon"
   REPLACE EMPLOYEE_LASTNAME  WITH "Myung"
   dbUnlock()
   dbCommit()

   CLEAR SCREEN
   ? ""
   ? "We have FOREIGN KEY defined, so it will NOT allow to DELETE a department"
   ? "where there are employees connected"
   ? ""
   ? "   **** Run time error MUST happen ****"
   ? ""

   SELECT DEPARTMENT
   SET ORDER TO "DEPARTMENT_ID"
   SEEK "001"

   IF Found()
      BEGIN SEQUENCE
         dbDelete()
         dbCommit()
      RECOVER USING oErr
         ? oErr:Description
      END SEQUENCE
   ELSE
      ? "Department NOT FOUND"
   ENDIF

   WAIT

RETURN NIL

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/