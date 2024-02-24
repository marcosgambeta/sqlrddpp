// SQLRDD++
// test with Firebird, MySQL and PostgreSQL
// To compile:
// hbmk2 multisgbd1 -lfbclient -llibmysql -llibpq

#include "sqlrdd.ch"

// Make a copy of this file and change the values below.
// NOTE: the database must exist before runnning the test.

#define FIREBIRD3_SERVER "inet://"
#define FIREBIRD3_UID    "SYSDBA"
#define FIREBIRD3_PWD    "masterkey"
#define FIREBIRD3_DTB    "C:\PATHTODATABASE\TEST.FDB"

#define MYSQL_SERVER     "localhost"
#define MYSQL_UID        "root"
#define MYSQL_PWD        "password"
#define MYSQL_DTB        "dbtest"

#define POSTGRES_SERVER  "localhost"
#define POSTGRES_UID     "postgres"
#define POSTGRES_PWD     "password"
#define POSTGRES_DTB     "dbtest"

REQUEST SQLRDD
REQUEST SR_FIREBIRD3
REQUEST SR_MYSQL
REQUEST SR_PGS

PROCEDURE Main()

   LOCAL nSGBD
   LOCAL nConnection
   LOCAL n

   setMode(25, 80)

   rddSetDefault("SQLRDD")

   DO WHILE .T.
   
      CLS

      nSGBD := alert("Choose the SGBD", {"Firebird", "MySQL", "PostgreSQL"})

      IF nSGBD == 0
         EXIT
      ENDIF

      SWITCH nSGBD
      CASE 1
         // Firebird
         nConnection := sr_AddConnection(CONNECT_FIREBIRD3, "FIREBIRD=" + FIREBIRD3_SERVER + ";UID=" + FIREBIRD3_UID + ";PWD=" + FIREBIRD3_PWD + ";DTB=" + FIREBIRD3_DTB)
         EXIT
      CASE 2
         // MySQL
         nConnection := sr_AddConnection(CONNECT_MYSQL, "MySQL=" + MYSQL_SERVER + ";UID=" + MYSQL_UID + ";PWD=" + MYSQL_PWD + ";DTB=" + MYSQL_DTB)
         EXIT
      CASE 3
         // PostgreSQL
         nConnection := sr_AddConnection(CONNECT_POSTGRES, "PGS=" + POSTGRES_SERVER + ";UID=" + POSTGRES_UID + ";PWD=" + POSTGRES_PWD + ";DTB=" + POSTGRES_DTB)
      ENDSWITCH

      IF nConnection < 0
         alert("Connection error. See sqlerror.log for details.")
         LOOP
      ENDIF

      sr_StartLog(nConnection)

      IF !sr_ExistTable("test")
         dbCreate("test", {{"ID",      "N", 10, 0}, ;
                           {"FIRST",   "C", 30, 0}, ;
                           {"LAST",    "C", 30, 0}, ;
                           {"AGE",     "N",  3, 0}, ;
                           {"DATE",    "D",  8, 0}, ;
                           {"MARRIED", "L",  1, 0}, ;
                           {"VALUE",   "N", 12, 2}}, "SQLRDD")
      ENDIF
   
      USE test EXCLUSIVE VIA "SQLRDD"
   
      IF reccount() < 100
         FOR n := 1 TO 100
            APPEND BLANK
            REPLACE ID      WITH n
            REPLACE FIRST   WITH "FIRST" + hb_ntos(n)
            REPLACE LAST    WITH "LAST" + hb_ntos(n)
            REPLACE AGE     WITH n + 18
            REPLACE DATE    WITH date() - n
            REPLACE MARRIED WITH iif(n / 2 == int(n / 2), .T., .F.)
            REPLACE VALUE   WITH n * 1000 / 100
         NEXT n
      ENDIF
   
      GO TOP
   
      browse()

      CLOSE DATABASE
      
      sr_StopLog(nConnection)

      sr_EndConnection(nConnection)

   ENDDO

RETURN
