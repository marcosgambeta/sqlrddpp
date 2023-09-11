/* $CATEGORY$SQLRDD/Utils$FILES$sql.lib$
* SQLRDD Startup
* Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
* All Rights Reserved
*/

/*
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

#include "common.ch"
#include "error.ch"
#include "rddsys.ch"
#include "hbclass.ch"
// #include "compat.ch"
#include "sqlrdd.ch"
#include "sqlodbc.ch"
#include "msg.ch"
#define HB_FALSE 0
#define HB_TRUE 1
REQUEST XHB_LIB
REQUEST HB_Deserialize
REQUEST HB_Serialize
#define DEMO_NOTICE    "54686973206170706C69636174696F6E20776173206275696C64207769746820612064656D6F206F662053514C5244442C2064697374726962757465642062792078486172626F75722E636F6D2E0D0A0D0A457374612061706C69636163616F20E920666569746120636F6D20756D612076657273616F2044454D4F4E5354524143414F20646F2053514C5244442C2065207365752075736F20E9207065726D697469646F204150454E415320504152412046494E53204445204156414C4941C7C34F2E204120646973747269627569E7E36F20656D2070726F6475E7E36F2064657374612061706C696361E7E36F20E92070726F696269646120652073756A6569746120E0732070656E616C6964616465732070726576697374617320656D206C65692E204D61697320696E666F726D61E7F5657320656D207777772E78686172626F75722E636F6D2E62722E0D0A"

/* Need this modules linked */
REQUEST SR_WORKAREA

Static aConnections, nActiveConnection

Static lTblMgmnt        := .F.
Static EvalFilters      := .F.
Static RecnoName        := "SR_RECNO"
Static DeletedName      := "SR_DELETED"
Static cCollation       := ""
Static cToolsOwner      := ""
Static cIntenalID       := NIL
Static lFastOpenWA      := .T.
Static nMaxRowCache     := 1000
Static nFetchSize       := 10
Static lSyntheticInd    := .F.
Static cSynthetiVInd    := ""
Static lCheckMgmntInd   := .T.
Static cRDDTemp         := "DBFCDX"

Static cTblSpaceData    := ""
Static cTblSpaceIndx    := ""
Static cTblSpaceLob     := ""

Static hMultilangColumns
Static nSyntheticIndexMinimun      := 3

Static lErrorOnGotoToInvalidRecord := .F.

Static lUseNullsFirst              := .T.



/*------------------------------------------------------------------------*/

Procedure SR_Init

   #pragma TEXTHIDDEN(1)

   #ifdef SQLRDD_DEMO
      #ifdef __PLATFORM__Windows
         SR_BINDBYVALUE(hextostr(DEMO_NOTICE))
      #else
         SQLBINDBYVAL(hextostr(DEMO_NOTICE))
      #endif

   #endif

   #ifdef SQLRDD_TIMEBOMBED
      if date() > stod("20090801")
      #ifdef __PLATFORM__Windows
         SR_BINDBYVALUE("SQLRDD Demo expired. Please contact your local resseler.")
         Quit
      #else
         SQLBINDBYVAL("SQLRDD Demo expired. Please contact your local resseler.")
         Quit
      #endif
         quit
      endif
   #endif

   #pragma TEXTHIDDEN(0)

Return

/*------------------------------------------------------------------------*/

FUNCTION SR_GetCnn(nConnection)
   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   If SR_CheckCnn(nConnection)
      DEFAULT aConnections TO {}
      RETURN aConnections[nConnection]
   EndIf
RETURN  NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_CheckCnn(nConnection)
   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   If nConnection > len(aConnections) .OR. nConnection == 0
      RETURN .F.
   EndIf
RETURN .T.

/*------------------------------------------------------------------------*/

FUNCTION SR_GetConnection(nConnection)
   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   SR_CheckConnection(nConnection)
RETURN aConnections[nConnection]

/*------------------------------------------------------------------------*/

FUNCTION SR_CheckConnection(nConnection)
   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   If nConnection > len(aConnections) .OR. nConnection == 0 .OR. nConnection < 0
      RETURN SR_RuntimeErr("SR_CheckConnection()", SR_Msg(7))
   EndIf
RETURN aConnections[nConnection]

/*------------------------------------------------------------------------*/

FUNCTION SR_SetNextQuery(cSql)

   LOCAL cOld

   DEFAULT aConnections TO {}
   DEFAULT nActiveConnection TO 0

   SR_CheckConnection(nActiveConnection)
   cOld := aConnections[nActiveConnection]:cNextQuery

   If cSql != NIL
      aConnections[nActiveConnection]:cNextQuery := cSql
   EndIf

RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_GetSyntheticIndexMinimun()

   LOCAL nRet :=  nSyntheticIndexMinimun

   DEFAULT aConnections TO {}
   DEFAULT nActiveConnection TO 0

   SWITCH aConnections[nActiveConnection]:nSystemID
   CASE SYSTEMID_POSTGR
   CASE SYSTEMID_ORACLE
      EXIT
   OTHERWISE
      nRet := 10
   ENDSWITCH

RETURN nRet

/*------------------------------------------------------------------------*/

FUNCTION SR_SetSyntheticIndexMinimun(nSet)

   LOCAL nOld := nSyntheticIndexMinimun

   If HB_ISNUMERIC(nSet)
      nSyntheticIndexMinimun := Min(nSet, 10)
   EndIf
RETURN nOld

/*------------------------------------------------------------------------*/

FUNCTION SR_CheckMgmntInd(nSet)

   LOCAL nOld := lCheckMgmntInd

   If HB_ISLOGICAL(nSet)
      lCheckMgmntInd := nSet
   EndIf
RETURN nOld

/*------------------------------------------------------------------------*/

FUNCTION SR_SetSyntheticIndex(lSet)

   LOCAL lOld := lSyntheticInd

   If HB_ISLOGICAL(lSet)
      lSyntheticInd := lSet
   EndIf
RETURN lOld

/*------------------------------------------------------------------------*/

FUNCTION SR_GetSyntheticIndex()

RETURN lSyntheticInd

/*------------------------------------------------------------------------*/

FUNCTION SR_SetSVIndex(cSet)

   LOCAL cOld := cSynthetiVInd

   If HB_ISCHAR(cSet)
      If len(cSet) != 3 .OR. " " $ cSet .OR. "." $ cSet
         SR_RuntimeErr("SR_SetSVIndex()", "Invalid parameter: " + cSet)
      EndIf
      cSynthetiVInd := cSet
   EndIf
RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_GetSVIndex()

   LOCAL cRet := cSynthetiVInd

   cSynthetiVInd := ""

RETURN cRet

/*------------------------------------------------------------------------*/

FUNCTION SR_SetFastOpen(lSet)

   LOCAL lOld := lFastOpenWA

   If HB_ISLOGICAL(lSet)
      lFastOpenWA := lSet
   EndIf

RETURN lOld

/*------------------------------------------------------------------------*/

FUNCTION SR_SetExclusiveManagement(lSet)

   LOCAL lOld := !lFastOpenWA

   If HB_ISLOGICAL(lSet)
      lFastOpenWA := !lSet
   EndIf

RETURN lOld

/*------------------------------------------------------------------------*/

FUNCTION SR_SetTblSpaceData(cSet)

   LOCAL cOld := cTblSpaceData
   LOCAL oSql

   If HB_ISCHAR(cSet)
      cTblSpaceData := cSet
   ElseIf Empty(cTblSpaceData)
      oSql := SR_GetConnection()
      If !Empty(oSql:cDsnTblData)
         RETURN oSql:cDsnTblData
      EndIf
   EndIf

RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_SetTblSpaceIndx(cSet)

   LOCAL cOld := cTblSpaceIndx
   LOCAL oSql

   If HB_ISCHAR(cSet)
      cTblSpaceIndx := cSet
   ElseIf Empty(cTblSpaceIndx)
      oSql := SR_GetConnection()
      If !Empty(oSql:cDsnTblIndx)
         RETURN oSql:cDsnTblIndx
      EndIf
   EndIf

RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_SetTblSpaceLob(cSet)

   LOCAL cOld := cTblSpaceLob
   LOCAL oSql

   If HB_ISCHAR(cSet)
      cTblSpaceLob := cSet
   ElseIf Empty(cTblSpaceLob)
      oSql := SR_GetConnection()
      If !Empty(oSql:cDsnTblLob)
         RETURN oSql:cDsnTblLob
      EndIf
   EndIf

RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_SetRDDTemp(cSet)

   LOCAL cOld := cRDDTemp

   If HB_ISCHAR(cSet)
      cRDDTemp := cSet
   EndIf

RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_GetFastOpen()

RETURN lFastOpenWA

/*------------------------------------------------------------------------*/

FUNCTION SR_GetActiveConnection()
   DEFAULT nActiveConnection TO 0
RETURN nActiveConnection

/*------------------------------------------------------------------------*/

FUNCTION SR_SetActiveConnection(nCnn)

   LOCAL nOld

   DEFAULT nActiveConnection TO 0
   nOld := nActiveConnection
   DEFAULT nCnn TO 1
   DEFAULT aConnections TO {}

   If nCnn != 0 .AND. nCnn <= len(aConnections)
      nActiveConnection := nCnn
   Else
      RETURN -1
   EndIf

RETURN nOld

/*------------------------------------------------------------------------*/

FUNCTION SR_AddConnection(nType, cDSN, cUser, cPassword, cOwner, lCounter, lAutoCommit, lNoSetEnv, nTimeout)

   LOCAL nRet := -1
   LOCAL oConnect
   LOCAL oConnect2

   DEFAULT nType             TO CONNECT_ODBC
   DEFAULT lAutoCommit       TO .F.
   DEFAULT lCounter          TO .F.
   DEFAULT cOwner            TO ""
   DEFAULT lNoSetEnv         TO .F.
   DEFAULT aConnections      TO {}
   DEFAULT nActiveConnection TO 0

   #pragma TEXTHIDDEN(1)

   #ifdef SQLRDD_DEMO
      #ifdef __PLATFORM__Windows
         SR_BINDBYVALUE(hextostr(DEMO_NOTICE))
      #else
         SQLBINDBYVAL(hextostr(DEMO_NOTICE))
      #endif

   #endif

   #pragma TEXTHIDDEN(0)

   /* The macro execution is used to NOT link the connection class if we don't need it
      The programmer MUST declare the needed connection class using REQUEST in PRG source */

   SWITCH nType
   CASE CONNECT_ODBC
   CASE CONNECT_ODBC_NOEXLOCK
#ifndef MYSQLRDD
      oConnect  := &( "SR_ODBC()" )
      oConnect2 := &( "SR_ODBC()" )
#endif
      EXIT
   CASE CONNECT_MYSQL
   CASE CONNECT_MYSQL_NOEXLOCK
      oConnect  := &( "SR_MYSQL()" )
      oConnect2 := &( "SR_MYSQL()" )
      EXIT
   CASE CONNECT_POSTGRES
   CASE CONNECT_POSTGRES_NOEXLOCK
#ifndef MYSQLRDD
      oConnect  := &( "SR_PGS()" )
      oConnect2 := &( "SR_PGS()" )
#endif
      EXIT
   CASE CONNECT_ORACLE
   CASE CONNECT_ORACLE_NOEXLOCK
#ifndef MYSQLRDD
      oConnect  := &( "SR_ORACLE()" )
      oConnect2 := &( "SR_ORACLE()" )
#endif
      EXIT
   CASE CONNECT_ORACLE2
   CASE CONNECT_ORACLE2_NOEXLOCK
#ifndef MYSQLRDD
      oConnect  := &( "SR_ORACLE2()" )
      oConnect2 := &( "SR_ORACLE2()" )
#endif
      EXIT
   CASE CONNECT_FIREBIRD
   CASE CONNECT_FIREBIRD_NOEXLOCK
#ifndef MYSQLRDD
      oConnect  := &( "SR_FIREBIRD()" )
      oConnect2 := &( "SR_FIREBIRD()" )
#endif
      EXIT
   CASE CONNECT_FIREBIRD3
   CASE CONNECT_FIREBIRD3_NOEXLOCK
#ifndef MYSQLRDD
      oConnect  := &( "SR_FIREBIRD3()" )
      oConnect2 := &( "SR_FIREBIRD3()" )
#endif
      EXIT
   CASE CONNECT_MARIA
   CASE CONNECT_MARIA_NOEXLOCK
#ifndef MYSQLRDD
      oConnect  := &( "SR_MARIA()" )
      oConnect2 := &( "SR_MARIA()" )
#endif
      EXIT
   CASE CONNECT_ODBC_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect  := &( "SR_ODBC()" )
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_ORACLE_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect  := &( "SR_ORACLE()" )
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_ORACLE2_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect  := &( "SR_ORACLE2()" )
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_MYSQL_QUERY_ONLY
      oConnect  := &( "SR_MYSQL()" )
      oConnect:lQueryOnly := .T.
      EXIT
   CASE CONNECT_POSTGRES_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect  := &( "SR_PGS()" )
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_FIREBIRD_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect  := &( "SR_FIREBIRD()" )
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_MARIA_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect  := &( "SR_MARIA()" )
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   OTHERWISE
      SR_MsgLogFile("Invalid connection type in SR_AddConnection() :" + str(nType))
      RETURN -1
   ENDSWITCH

   If HB_ISOBJECT(oConnect)

      oConnect:Connect("", cUser, cPassword, 1, cOwner, 4000, .F.,;
                     cDSN, 50, "ANSI", 0, 0, 0,;
                     lCounter, lAutoCommit, nTimeout)
   Else
      SR_MsgLogFile("Invalid connection type in SR_AddConnection() :" + str(nType))
      RETURN -1
   EndIf

   If oConnect:nSystemID != 0 .AND. oConnect:nSystemID != NIL

      oConnect:nConnectionType := nType


      /* Create other connections to the database */

      If nType < CONNECT_NOEXLOCK
         oConnect:oSqlTransact := oConnect2:Connect("", cUser, cPassword, 1, cOwner, 4000, .F.,;
                                  cDSN, 50, "ANSI", 0, 0, 0, .T., lAutoCommit, nTimeout)
         oConnect2:nConnectionType := nType
      ElseIf nType < CONNECT_QUERY_ONLY
         lNoSetEnv := .F.
      Else
         lNoSetEnv := .T.
      EndIf

      // ToDo: Add MUTEX here
      aadd(aConnections, oConnect)
      nRet := len(aConnections)

      If nActiveConnection == NIL .OR. nActiveConnection == 0
         nActiveConnection := nRet
      EndIf

      oConnect:nID := nRet

      If !lNoSetEnv
         If empty(SR_SetEnvSQLRDD(oConnect))
            RETURN -1
         EndIf
      Else
         If empty(SR_SetEnvMinimal(oConnect))
            RETURN -1
         EndIf
      EndIf

      SR_ReloadFieldModifiers(oConnect)

      If !( "DB2/400" $ oConnect:cSystemName )
         If !lAutoCommit
            oConnect:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF)
            If nType < CONNECT_QUERY_ONLY
               oConnect2:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF)
            EndIf
         EndIf
      Else
         oConnect:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON)
         If nType < CONNECT_QUERY_ONLY
            oConnect2:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON)
         EndIf
      EndIf

   EndIf

RETURN nRet

/*------------------------------------------------------------------------*/

FUNCTION SR_ReloadFieldModifiers(oConnect)

#ifdef SQLRDD_TOPCONN

   LOCAL aRet := {}
   LOCAL aFlds := {}
   LOCAL aField
   LOCAL cLast

   If oConnect:exec("SELECT FIELD_TABLE, FIELD_NAME, FIELD_TYPE, FIELD_PREC, FIELD_DEC FROM TOP_FIELD WHERE FIELD_TYPE != 'X' ORDER BY FIELD_TABLE, FIELD_NAME", .F., .T., @aRet) == SQL_SUCCESS
      oConnect:aFieldModifier := { => }
      HAllocate(oConnect:aFieldModifier, 10000)
      oConnect:nTCCompat := 2
      If len(aRet) > 0
         cLast := aRet[1, 1]
         FOR EACH aField IN aRet
            If aField[1] != cLast
               If "." $ cLast
                  cLast := Upper(SubSTr(cLast, At(".", cLast) + 1))
               EndIf
               oConnect:aFieldModifier[alltrim(cLast)] := aFlds
               aFlds := {}
               cLast := aField[1]
            EndIf
            aadd(aFlds, { aField[2], aField[3], aField[4], aField[5] })
         NEXT
         If "." $ cLast
            cLast := Upper(SubSTr(cLast, At(".", cLast) + 1))
         EndIf
         oConnect:aFieldModifier[alltrim(cLast)] := aFlds
      EndIf
   Else
      oConnect:Commit()
   EndIf
#else
   HB_SYMBOL_UNUSED(oConnect)
#endif

RETURN NIL

/*------------------------------------------------------------------------*/

Static FUNCTION SR_SetEnvSQLRDD(oConnect)

   LOCAL aRet := {}
   LOCAL cRet := ""
   LOCAL i
   LOCAL oCnn
   LOCAL cStartingVersion
   LOCAL cSql
   LOCAL lOld

   FOR i := 1 TO 2

      If i == 1
         oCnn := oConnect
      ElseIf i == 2
         If oConnect:oSqlTransact == NIL
            Exit
         EndIf
         oCnn := oConnect:oSqlTransact
      EndIf

      SWITCH oCnn:nSystemID

      CASE SYSTEMID_ORACLE
         If SR_UseSequences() .AND. i == 1
            aRet := {}
            oCnn:exec("SELECT SEQUENCE_NAME FROM USER_SEQUENCES WHERE SEQUENCE_NAME='SQ_NRECNO'", .F., .T., @aRet)
         EndIf
         oCnn:exec("ALTER SESSION SET NLS_LANGUAGE=AMERICAN", .F.)
         oCnn:exec("ALTER SESSION SET NLS_SORT=BINARY", .F.)
         oCnn:exec("ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,'", .F.)
         oCnn:exec("alter session set SESSION_CACHED_CURSORS=10000", .F.)
         If oCnn:cCharSet != NIL
            oCnn:exec("ALTER SESSION SET NLS_CHARACTERSET=" + oCnn:cCharSet, .F.)
         EndIf
         If oCnn:lNative
            oCnn:exec("ALTER SESSION SET NLS_DATE_FORMAT='yyyymmdd'", .F.)
            oCnn:exec("ALTER SESSION SET NLS_TIMESTAMP_FORMAT='yyyymmdd HH.MI.SSXFF AM'", .F.)
         EndIf
         /* Locking system housekeeping */

         aRet := {}
         oCnn:exec("select sid from " + IIf(oCnn:lCluster, "g", "") + "v$session where AUDSID = sys_context('USERENV','sessionid')", .T., .T., @aRet)

         If len(aRet) > 0
            oCnn:uSid := val(str(aRet[1, 1], 8, 0))
         EndIf

         oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + [SR_MGMNTLOCKS WHERE SPID_ = ] + str(oCnn:uSid) + [ OR SPID_ NOT IN (select "AUDSID" from ] + IIf(oCnn:lCluster, "g", "") + [v$session)], .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_INGRES
         oCnn:Commit()
         oCnn:exec("set lockmode session where readlock=nolock,level=row")
         EXIT

      CASE SYSTEMID_IBMDB2
         /*
         If SR_UseSequences() .AND. i == 1
            aRet := {}
            oCnn:exec("VALUES NEXTVAL FOR N_RECNO", .F., .T., @aRet)
            If len(aRet) == 0
               oCnn:exec("CREATE SEQUENCE N_RECNO START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE")
            EndIf
         EndIf
         */
         EXIT

      CASE SYSTEMID_SYBASE
//         oCnn:commit()
//         oCnn:exec("SET CHAINED ON")
         oCnn:commit()
         oCnn:exec("SET QUOTED_IDENTIFIER ON")
         oCnn:exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
         EXIT

      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_MSSQL6
      CASE SYSTEMID_AZURE
         oCnn:Commit()
         oCnn:exec("SET QUOTED_IDENTIFIER ON")
         oCnn:exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
         /* Locking system housekeeping */
         aRet := {}
         oCnn:exec("SELECT convert( char(30), login_time, 21 ) FROM MASTER.DBO.SYSPROCESSES where SPID = @@SPID", .F., .T., @aRet)

         If len(aRet) > 0
            oCnn:cLoginTime   := alltrim(aRet[1, 1])
         EndIf

         oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE SPID_ = @@SPID OR convert( CHAR(10), SPID_ ) + convert( CHAR(23), LOGIN_TIME_, 21 ) NOT IN (SELECT convert( CHAR(10), SPID) + CONVERT( CHAR(23), LOGIN_TIME, 21 ) FROM MASTER.DBO.SYSPROCESSES)", .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
         oCnn:exec("set session autocommit=0;")
         oCnn:exec("set session sql_mode = 'PIPES_AS_CONCAT'")
         oCnn:exec("SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
         EXIT

      CASE SYSTEMID_POSTGR
         If SR_UseSequences() .AND. i == 1
            aRet := {}
            oCnn:exec("SELECT * FROM SQ_NRECNO", .F., .T., @aRet)
            oCnn:Commit()
         EndIf
         oCnn:exec("SET CLIENT_ENCODING to 'LATIN1'", .F., .T., @aRet)
         oCnn:exec("SET xmloption to 'DOCUMENT'", .F., .T., @aRet)
         /* Locking system housekeeping */
         oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE SPID_ = (select pg_backend_pid()) OR SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))", .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_FIREBR
      CASE SYSTEMID_FIREBR3
//         oCnn:exec("SET TERM !@¨§;", .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_CACHE
         oCnn:exec("SET OPTION SUPPORT_DELIMITED_IDENTIFIERS=TRUE")

         aRet := {}
         oCnn:exec("select * from " + SR_GetToolsOwner() + "dual", .F., .T., @aRet)
         if len(aRet) == 0
            oConnect:exec("create table " + SR_GetToolsOwner() + "dual (dummy char(1))", .F.)
            oConnect:exec("insert into " + SR_GetToolsOwner() + "dual (dummy) values (0)", .F.)
            oConnect:commit()

            cSql := "create function " + SR_GetToolsOwner() + e"NEXTVAL(sequenceName VARCHAR(50))\r\n for " + SR_GetToolsOwner() + e"SequenceControler \r\n"
            cSql += e"returns INT \r\n LANGUAGE OBJECTSCRIPT \r\n {\r\n New nextVal \r\n Set nextVal = $Increment(^" + SR_GetToolsOwner() + 'SequenceControler("Sequences",sequenceName))' + e"\r\n"
            cSql += e"Set ^CacheTemp.SequenceControler($Job,sequenceName)=nextVal \r\n Quit nextVal \r\n }"

            oConnect:exec(cSql, .T.)
            oConnect:commit()

            cSql := "create function " + SR_GetToolsOwner() + e"CURRVAL(sequenceName VARCHAR(50))\r\n for " + SR_GetToolsOwner() + e"SequenceControler \r\n  returns INT \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n  Quit $Get(^CacheTemp.SequenceControler($Job,sequenceName)) \r\n  }"

            oConnect:exec(cSql, .T.)
            oConnect:commit()

            cSql := "create procedure " + SR_GetToolsOwner() + e"RESET(sequenceName VARCHAR(50))\r\n for " + SR_GetToolsOwner() + e"SequenceControler \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n  Kill ^" + SR_GetToolsOwner() + 'SequenceControler("Sequences",sequenceName)' + e" \r\n  }"

            oConnect:exec(cSql, .T.)
            oConnect:commit()

            cSql := "create function " + SR_GetToolsOwner() + e"JOB()\r\n for " + SR_GetToolsOwner() + e"JOB \r\n  returns INT \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n  Quit $Job \r\n  }"
            oConnect:exec(cSql, .T.)
            oConnect:commit()

            cSql := "create function " + SR_GetToolsOwner() + e"JOBLIST()\r\n for " + SR_GetToolsOwner() + e"JOB \r\n  returns %String \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n"
            cSql += [Set lista=""] + e"\r\n Do \r\n { \r\n" + [Set rs=##class(%ResultSet).%New("%SYSTEM.Process:CONTROLPANEL")] + e"\r\n" + [Set ok=rs.Execute("")] + e"\r\n"
            cSql += e"If 'ok Quit\r\n \r\n Set i=1\r\n  While rs.Next() \r\n{\r\n Set pid=rs.GetData(2) \r\n"
            cSql += [If pid>0 Set $Piece(lista,",",i)=pid] + e"\r\n Set i=i+1 \r\n } \r\n Do rs.Close() \r\n } While 0 \r\n"
            cSql += e"\r\n  Quit lista\r\n}\r\n"

            oConnect:exec(cSql, .T.)
            oConnect:commit()

         EndIf

         oCnn:Commit()
         EXIT

      ENDSWITCH
   NEXT i

   /* check for the control tables */
   aRet := {}
   oConnect:exec("SELECT VERSION_, SIGNATURE_ FROM " + SR_GetToolsOwner() + "SR_MGMNTVERSION", .F., .T., @aRet)

   If len(aRet) > 0
      cStartingVersion := alltrim(aRet[1, 1])
   Else
      cStartingVersion := ""
   EndIf

   If cStartingVersion < "MGMNT 1.02"
      /* Only use BASIC types and commands to be 100% darabase independent */
      oConnect:commit()
      oConnect:exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTVERSION", .F.)
      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTVERSION (VERSION_ CHAR(20), SIGNATURE_ CHAR(20))", .F.)
      oConnect:commit()

      If oConnect:nSystemID == SYSTEMID_AZURE

         oConnect:exec("CREATE CLUSTERED INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTVERSION01 ON " + SR_GetToolsOwner() + "SR_MGMNTVERSION ( VERSION_ )", .F.)
         oConnect:commit()

      Endif

      oConnect:exec("INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTVERSION (VERSION_, SIGNATURE_) VALUES ('" + HB_SR__MGMNT_VERSION + "', '" + DTOS(DATE()) + " " + TIME() + "')", .T.)
      oConnect:commit()
      oConnect:exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTINDEXES", .F.)
      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTINDEXES (TABLE_ CHAR(50), SIGNATURE_ CHAR(20), IDXNAME_ CHAR(64), PHIS_NAME_ CHAR(64), IDXKEY_ VARCHAR(254), IDXFOR_ VARCHAR(254), IDXCOL_ CHAR(3), TAG_ CHAR(30), TAGNUM_ CHAR(6) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED ", " ") + " INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTINDEX01 ON " + SR_GetToolsOwner() + "SR_MGMNTINDEXES ( TABLE_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTINDEX02 ON " + SR_GetToolsOwner() + "SR_MGMNTINDEXES ( IDXNAME_ )", .F.)
      oConnect:commit()
      oConnect:exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES", .F.)
      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES (TABLE_ CHAR(50), SIGNATURE_ CHAR(20), CREATED_ CHAR(20), TYPE_ CHAR(30), REGINFO_ CHAR(15))", .F.)
      oConnect:commit()
      oConnect:exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED ", " ") + " INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTTABLES01 ON " + SR_GetToolsOwner() + "SR_MGMNTTABLES ( TABLE_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_ CHAR(50), TARGETTABLE_ CHAR(50), CONSTRNAME_ CHAR(50), CONSTRTYPE_ CHAR(2) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRAINTS01 ON " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_, CONSTRNAME_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), SOURCECOLUMN_ CHAR(50) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRSRCCOLS01 ON " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), TARGETCOLUMN_ CHAR(50) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRTGTCOLS01 ON " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)

      // Caché - should add dual table ,like Oracle

      cRet := HB_SR__MGMNT_VERSION

   ElseIf cStartingVersion < "MGMNT 1.03"

      oConnect:commit()
      oConnect:exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES", .F.)
      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES (TABLE_ CHAR(50), SIGNATURE_ CHAR(20), CREATED_ CHAR(20), TYPE_ CHAR(30), REGINFO_ CHAR(15))", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTTABLES01 ON " + SR_GetToolsOwner() + "SR_MGMNTTABLES ( TABLE_ )", .F.)
      oConnect:commit()
      oConnect:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:commit()

      cRet := HB_SR__MGMNT_VERSION
   Else
      cRet := aRet[1, 1]
   EndIf

   If cStartingVersion < "MGMNT 1.65"

      oConnect:commit()
      oConnect:exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOCKS", .F.)
      oConnect:commit()
      oConnect:exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTLTABLES", .F.) // Table REMOVED from SQLRDD catalogs
      oConnect:commit()

      SWITCH oConnect:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_AZURE
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ NUMERIC(6), LOGIN_TIME_ DATETIME )", .F.)
         EXIT
      CASE SYSTEMID_POSTGR
      CASE SYSTEMID_SYBASE
      CASE SYSTEMID_CACHE
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ NUMERIC(6), LOGIN_TIME_ TIMESTAMP )", .F.)
         EXIT
      CASE SYSTEMID_ORACLE
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ NUMBER(8), LOGIN_TIME_ TIMESTAMP )", .F.)
         EXIT
      CASE SYSTEMID_IBMDB2
      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
      CASE SYSTEMID_ADABAS
      CASE SYSTEMID_INGRES
      CASE SYSTEMID_INFORM
      CASE SYSTEMID_FIREBR
      CASE SYSTEMID_FIREBR3
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ DECIMAL(8), LOGIN_TIME_ TIMESTAMP )", .F.)
         EXIT
      OTHERWISE
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ CHAR(10), LOGIN_TIME_ CHAR(50))", .F.)
      ENDSWITCH

      oConnect:commit()
      oConnect:exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE," CLUSTERED " ," ") + " INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOCKS01 ON " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( LOCK_, WSID_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOCKS02 ON " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( WSID_, LOCK_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOCKS03 ON " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( SPID_ )", .F.)
      oConnect:commit()

      oConnect:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:commit()

      cRet := HB_SR__MGMNT_VERSION
   EndIf

   If cStartingVersion < "MGMNT 1.50"

      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLANG ( TABLE_ CHAR(50), COLUMN_ CHAR(50), TYPE_ CHAR(1), LEN_ CHAR(8), DEC_ CHAR(8) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLANG01 ON " + SR_GetToolsOwner() + "SR_MGMNTLANG ( TABLE_, COLUMN_ )", .F.)
      oConnect:commit()

      oConnect:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:commit()

      cRet := HB_SR__MGMNT_VERSION
   EndIf

   If cStartingVersion < "MGMNT 1.60"

      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_ CHAR(50), TARGETTABLE_ CHAR(50), CONSTRNAME_ CHAR(50), CONSTRTYPE_ CHAR(2) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRAINTS01 ON " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_, CONSTRNAME_ )", .F.)

      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), SOURCECOLUMN_ CHAR(50) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRSRCCOLS01 ON " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)

      oConnect:commit()
      oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), TARGETCOLUMN_ CHAR(50) )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRTGTCOLS01 ON " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)

      oConnect:commit()
      oConnect:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:commit()

      cRet := HB_SR__MGMNT_VERSION

   EndIf

   If cStartingVersion < "MGMNT 1.67"
      If oConnect:nSystemID == SYSTEMID_MSSQL7 .OR. oConnect:nSystemID == SYSTEMID_AZURE
         oConnect:exec("DROP FUNCTION dbo.trim", .F.)
         oConnect:commit()
         oConnect:exec("CREATE FUNCTION dbo.trim( @p1 AS CHAR  ) RETURNS CHAR BEGIN RETURN ltrim(rtrim( @p1 )) END", .F.)
         oConnect:commit()
         oConnect:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
         oConnect:commit()
      EndIf
      cRet := HB_SR__MGMNT_VERSION
   EndIf

   // MISSING: Add columns to SR_MGMNTINDEXES ( ordfor(), ordkey() )

   If cStartingVersion < "MGMNT 1.72"

      lOld := SR_UseDeleteds(.F.)

      dbCreate("SR_MGMNTLOGCHG", { { "SPID_",        "N", 12, 0 },;
                                   { "WPID_",        "N", 12, 0 },;
                                   { "TYPE_",        "C",  2, 0 },;
                                   { "APPUSER_",     "C", 50, 0 },;
                                   { "TIME_",        "C", 25, 0 },;
                                   { "QUERY_",       "M", 10, 0 },;
                                   { "CALLSTACK_",   "C", 1000, 0 },;
                                   { "SITE_",        "C", 20, 0 },;
                                   { "CONTROL_",     "C", 50, 0 },;
                                   { "COST_",        "N", 12, 0 } }, "SQLRDD")

      USE SR_MGMNTLOGCHG EXCLUSIVE VIA "SQLRDD" NEW
//      ordCreate("SR_MGMNTLOGCHG", "001", "SPID_ + WPID_")
//      ordCreate("SR_MGMNTLOGCHG", "002", "APPUSER_ + WPID_")
//      ordCreate("SR_MGMNTLOGCHG", "003", "TIME_ + SITE_")
//      ordCreate("SR_MGMNTLOGCHG", "004", "TYPE_ + SPID_")
      USE

      SR_UseDeleteds(lOld)

/*

      SWITCH oConnect:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_SYBASE
      CASE SYSTEMID_CACHE
      CASE SYSTEMID_POSTGR
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ NUMERIC(12) NOT NULL, WPID_ NUMERIC(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ TEXT, CALLSTACK_ TEXT, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_ORACLE
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ NUMERIC(12) NOT NULL, WPID_ NUMERIC(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ TEXT, CALLSTACK_ TEXT, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_IBMDB2
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ DECIMAL(12) NOT NULL, WPID_ DECIMAL(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ CLOB (64000) " + IIf("DB2/400" $ oCOnnect:cSystemName, "",  " NOT LOGGED COMPACT") + ", CALLSTACK_ CLOB (4000) " + IIf( "DB2/400" $ oCOnnect:cSystemName, "",  " NOT LOGGED COMPACT") + ", SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ BIGINT(12) NOT NULL, WPID_ BIGINT(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ MEDIUMBLOB, CALLSTACK_ MEDIUMBLOB, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_ADABAS
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ BIGINT(12) NOT NULL, WPID_ BIGINT(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ LONG, CALLSTACK_ LONG, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_INGRES
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ BIGINT(12) NOT NULL, WPID_ BIGINT(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ long varchar, CALLSTACK_ long varchar, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_INFORM
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ DECIMAL(12) NOT NULL, WPID_ DECIMAL(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ TEXT, CALLSTACK_ TEXT, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_FIREBR
         oConnect:exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ DECIMAL(12) NOT NULL, WPID_ DECIMAL(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ BLOB SUB_TYPE 1, CALLSTACK_ BLOB SUB_TYPE 1, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      ENDSWITCH

      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG01 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( SPID_, WPID_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG02 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( APPUSER_, SPID_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG03 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( TIME_, SITE_ )", .F.)
      oConnect:commit()
      oConnect:exec("CREATE INDEX " + iif(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG04 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( TYPE_, TIME_ )", .F.)
      oConnect:commit()

*/

      oConnect:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:commit()

      cRet := HB_SR__MGMNT_VERSION

   EndIf

   oConnect:cMgmntVers := cRet

   // Setup multilang hash

   SR_ReloadMLHash(oConnect)

RETURN cRet

/*------------------------------------------------------------------------*/

Static FUNCTION SR_SetEnvMinimal(oConnect)

   LOCAL aRet := {}
   LOCAL cRet := "0"
   LOCAL oCnn

   oCnn := oConnect

   SWITCH oCnn:nSystemID

   CASE SYSTEMID_ORACLE
      oCnn:exec("ALTER SESSION SET NLS_LANGUAGE=AMERICAN", .F.)
      oCnn:exec("ALTER SESSION SET NLS_SORT=BINARY", .F.)
      oCnn:exec("ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,'", .F.)
      If oCnn:cCharSet != NIL
         oCnn:exec("ALTER SESSION SET NLS_CHARACTERSET=" + oCnn:cCharSet, .F.)
      EndIf
      If oCnn:lNative
         oCnn:exec("ALTER SESSION SET NLS_DATE_FORMAT='yyyymmdd'", .F.)
         oCnn:exec("ALTER SESSION SET NLS_TIMESTAMP_FORMAT='yyymmdd HH.MI.SSXFF AM'", .F.)
      EndIf
      EXIT

   CASE SYSTEMID_INGRES
      oCnn:Commit()
      oCnn:exec("set lockmode session where readlock=nolock,level=row")
      EXIT

   CASE SYSTEMID_SYBASE
//      oCnn:commit()
//      oCnn:exec("SET CHAINED ON")
      oCnn:commit()
      oCnn:exec("SET QUOTED_IDENTIFIER ON")
      oCnn:exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
      EXIT

   CASE SYSTEMID_MSSQL7
   CASE SYSTEMID_MSSQL6
   CASE SYSTEMID_AZURE
      oCnn:Commit()
      oCnn:exec("SET QUOTED_IDENTIFIER ON")
      oCnn:exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
      oCnn:Commit()
      EXIT

   CASE SYSTEMID_MYSQL
   CASE SYSTEMID_MARIADB
      oCnn:exec("set session autocommit=0;", .F.)
      oCnn:exec("SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED", .F.)
      EXIT

   CASE SYSTEMID_CACHE
      oCnn:exec("SET OPTION SUPPORT_DELIMITED_IDENTIFIERS=TRUE")
      oCnn:Commit()
      EXIT

   CASE SYSTEMID_POSTGR
      oCnn:exec("SET CLIENT_ENCODING to 'SQL_ASCII'", .F., .T., @aRet)
      oCnn:Commit()
      EXIT

   ENDSWITCH

RETURN cRet

/*------------------------------------------------------------------------*/

FUNCTION SR_ReloadMLHash(oConnect)

   LOCAL aRet := {}
   LOCAL aCol

   oConnect:exec("SELECT TABLE_ , COLUMN_, TYPE_, LEN_, DEC_ FROM " + SR_GetToolsOwner() + "SR_MGMNTLANG", .F., .T., @aRet)
   oConnect:commit()

   hMultilangColumns := Hash()
   HAllocate(hMultilangColumns, max(10, len(aRet)))

   FOR EACH aCol IN aRet
      hMultilangColumns[aCol[1] + aCol[2]] := aCol
   NEXT

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION AddToMLHash(aField)

   hMultilangColumns[PadR(aField[1], 50) + PadR(aField[2], 50)] := aField

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION GetMLHash(cTab, cCol)

   LOCAL cKey := PadR(upper(cTab), 50) + PadR(upper(cCol), 50)
   LOCAL nPos := HGetPos(hMultilangColumns, cKey)

   If nPos > 0
      RETURN HGetValueAt(hMultilangColumns, nPos)
   EndIf

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_ErrorOnGotoToInvalidRecord(l)

   LOCAL lOld  := lErrorOnGotoToInvalidRecord

   If l != NIL
      lErrorOnGotoToInvalidRecord := l
   EndIf
RETURN lOld

FUNCTION SR_UseNullsFirst(l) 

   LOCAL lOld  := lUseNullsFirst

   If l != NIL
      lUseNullsFirst := l
   EndIf
RETURN lOld
      
   

/*------------------------------------------------------------------------*/

FUNCTION SR_TblMgmnt()
RETURN lTblMgmnt

/*------------------------------------------------------------------------*/

FUNCTION SR_SetTblMgmnt(lOpt)

   LOCAL lOld := lTblMgmnt

   lTblMgmnt := lOpt
RETURN lOld

/*------------------------------------------------------------------------*/

FUNCTION SR_EvalFilters(lEval)

   LOCAL lOld  := EvalFilters

   If lEval != NIL
      EvalFilters := lEval
   EndIf
RETURN lOld

/*------------------------------------------------------------------------*/

FUNCTION SR_RecnoName(cName)

   LOCAL cOld  := RecnoName

   If cName != NIL
      RecnoName := Upper(Alltrim(cName))
   EndIf
RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_MaxRowCache(n)

   LOCAL cOld  := nMaxRowCache

   If n != NIL
      nMaxRowCache := n
   EndIf
RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_FetchSize(n)

   LOCAL cOld  := nFetchSize

   If n != NIL
      nFetchSize := n
   EndIf
RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_DeletedName(cName)

   LOCAL cOld  := DeletedName

   If cName != NIL
      DeletedName := Upper(Alltrim(cName))
   EndIf
RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_ExistTable(cTableName, cOwner, oCnn)

   LOCAL cFileName
   LOCAL nRet
   LOCAL aRet

   DEFAULT oCnn TO SR_GetConnection()
   aRet := eval(SR_GetTableInfoBlock(), cTableName)

   If cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      If !Empty(SR_GetGlobalOwner())
         cOwner := alltrim(SR_GetGlobalOwner())
      ElseIf !Empty(oCnn:cOwner)
         cOwner := alltrim(oCnn:cOwner)
      ElseIf cOwner == NIL
         cOwner := ""
      EndIf
   EndIf

   If (!Empty(cOwner)) .AND. right(cOwner, 1) != "."
      cOwner += "."
   EndIf

   cFileName := SR_ParseFileName(alltrim(aRet[TABLE_INFO_TABLE_NAME]))

   If oCnn:oSqlTransact == NIL
      nRet := oCnn:exec("SELECT * FROM " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + " WHERE 0 = 2", .F.)
      oCnn:Commit()
   Else
      nRet := oCnn:oSqlTransact:exec("SELECT * FROM " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + " WHERE 0 = 2", .F.)
      oCnn:oSqlTransact:Commit()
   EndIf

   If nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND
      RETURN .T.
   EndIf

RETURN .F.

/*------------------------------------------------------------------------*/

FUNCTION SR_ExistIndex(cIndexName, cOwner)

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}

   HB_SYMBOL_UNUSED(cOwner)

   oCnn := SR_GetConnection()

   aRet := eval(SR_GetIndexInfoBlock(), cIndexName)
   aSize(aRet, TABLE_INFO_SIZE)

   cIndexName  := SR_ParseFileName(aRet[TABLE_INFO_TABLE_NAME])

   aRet := {}
   nRet := oCnn:exec("SELECT * FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE IDXNAME_ = '" + Upper(Alltrim(cIndexName)) + "'", .F., .T., @aRet)

   If (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. len(aRet) > 0
      RETURN .T.
   EndIf

RETURN .F.

/*------------------------------------------------------------------------*/

FUNCTION SR_File(cTableName)

   LOCAL cTbl := lower(cTableName)

   Do Case
   Case ".dbf" $ cTbl .OR. ".dbt" $ cTbl
      RETURN SR_ExistTable(cTableName)
   Case ".ntx" $ cTbl .OR. ".cdx" $ cTbl
      RETURN SR_ExistIndex(cTableName)
   EndCase

RETURN SR_ExistTable(cTableName) .OR. SR_ExistIndex(cTableName)

/*------------------------------------------------------------------------*/

FUNCTION SR_EndConnection(nConnection)

   LOCAL oCnn
   LOCAL uRet

   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}

   #pragma TEXTHIDDEN(1)

   #ifdef SQLRDD_DEMO
      #ifdef __PLATFORM__Windows
         SR_BINDBYVALUE(hextostr(DEMO_NOTICE))
      #else
         SQLBINDBYVAL(hextostr(DEMO_NOTICE))
      #endif

   #endif

   #pragma TEXTHIDDEN(0)

   SR_CheckConnection(nConnection)

   If nConnection > len(aConnections) .OR. nConnection == 0 .OR. nConnection < 0
      RETURN NIL
   EndIf

   oCnn := aConnections[nConnection]

   If nConnection == len(aConnections)
      aSize(aConnections, len(aConnections) - 1)
   Else
      aConnections[nConnection] := NIL
   EndIf

   If oCnn != NIL
      If oCnn:oSqlTransact != NIL
         oCnn:oSqlTransact:RollBack()
         oCnn:oSqlTransact:end()
      EndIf
      uRet := oCnn:end()
   EndIf

   nActiveConnection := len(aConnections)

RETURN uRet

/*------------------------------------------------------------------------*/

FUNCTION SR_GetConnectionInfo(nConnection, nInfo)

   LOCAL oCnn

   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   SR_CheckConnection(nConnection)
   oCnn := SR_GetConnection()

   SWITCH nInfo
   CASE SQL_DBMS_NAME
      RETURN oCnn:cTargetDB
      //EXIT
   CASE SQL_DBMS_VER
      RETURN oCnn:cSystemVers
      //EXIT
   ENDSWITCH

RETURN ""

/*------------------------------------------------------------------------*/

FUNCTION SR_StartLog(nConnection)

   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   SR_CheckConnection(nConnection)
   aConnections[nConnection]:lTraceToDBF := .T.
   If aConnections[nConnection]:oSqlTransact != NIL
      aConnections[nConnection]:oSqlTransact:lTraceToDBF := .T.
   EndIf

RETURN .T.

/*------------------------------------------------------------------------*/

FUNCTION SR_StartTrace(nConnection)

   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   SR_CheckConnection(nConnection)
   aConnections[nConnection]:lTraceToScreen := .T.
   If aConnections[nConnection]:oSqlTransact != NIL
      aConnections[nConnection]:oSqlTransact:lTraceToScreen := .T.
   EndIf

RETURN .T.

/*------------------------------------------------------------------------*/

FUNCTION SR_StopLog(nConnection)

   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   SR_CheckConnection(nConnection)
   aConnections[nConnection]:lTraceToDBF := .F.
   If aConnections[nConnection]:oSqlTransact != NIL
      aConnections[nConnection]:oSqlTransact:lTraceToDBF := .F.
   EndIf

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_StopTrace(nConnection)

   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   SR_CheckConnection(nConnection)
   aConnections[nConnection]:lTraceToScreen := .F.
   If aConnections[nConnection]:oSqlTransact != NIL
      aConnections[nConnection]:oSqlTransact:lTraceToScreen := .F.
   EndIf

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_SetTimeTrace(nConnection, nMilisseconds)

   LOCAL nOld

   DEFAULT nActiveConnection TO 0
   DEFAULT nConnection TO nActiveConnection
   DEFAULT aConnections TO {}
   SR_CheckConnection(nConnection)
   DEFAULT nMilisseconds TO aConnections[nConnection]:nTimeTraceMin
   nOld := aConnections[nConnection]:nTimeTraceMin
   aConnections[nConnection]:nTimeTraceMin := nMilisseconds

RETURN NIL

/*------------------------------------------------------------------------*/

Procedure SR_End()

   DEFAULT aConnections TO {}
   DO WHILE len(aConnections) > 0
      SR_EndConnection(len(aConnections))
   ENDDO

Return

/*------------------------------------------------------------------------*/

FUNCTION _SR_UnRegister(oWA)

   LOCAL aActiveWAs
   LOCAL n

   aActiveWAs := oWa:oSql:oHashActiveWAs:Find(oWA:cFileName)

   If HB_ISARRAY(aActiveWAs)
      DO WHILE (n := aScan(aActiveWAs, { |x| x:nThisArea == oWA:nThisArea }) ) > 0
         aDel(aActiveWAs, n)
         aSize(aActiveWAs, len(aActiveWAs) - 1)
      ENDDO
   EndIf

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION _SR_Register(oWA)

   LOCAL aActiveWAs

   aActiveWAs := oWa:oSql:oHashActiveWAs:Find(oWA:cFileName)

   If HB_ISARRAY(aActiveWAs)
      aadd(aActiveWAs, oWA)
   Else
      oWa:oSql:oHashActiveWAs:Insert(oWA:cFileName, { oWA })
   EndIf

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION _SR_ScanExec(oWA, bExpr)

   LOCAL aActiveWAs := oWa:oSql:oHashActiveWAs:Find(oWA:cFileName)

   If HB_ISARRAY(aActiveWAs)
      aEval(aActiveWAs, bExpr)
   EndIf

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION _SR_ScanExecAll(bExpr)

   SR_GetConnection():oHashActiveWAs:Haeval(bExpr)

RETURN NIL

/*------------------------------------------------------------------------*/

FUNCTION SR_GetUniqueSystemID()

   LOCAL i1
   LOCAL i2

   i1 := HB_RANDOMINT(1, 99999999 )
   i2 := HB_RANDOMINT(1, 99999999 )

RETURN alltrim(SR_Val2Char(SR_GetCurrInstanceID())) + "__" + strZero(i1, 8) + "__" + strZero(i2, 8)

/*------------------------------------------------------------------------*/

FUNCTION SR_GetInternalID()

   LOCAL i1
   LOCAL i2

   If cIntenalID != NIL
      RETURN cIntenalID
   EndIf

   i1 := HB_RANDOMINT(1, 99999999 )
   i2 := HB_RANDOMINT(1, 99999999 )

   cIntenalID := alltrim(SR_Val2Char(SR_GetCurrInstanceID())) + "__" + strZero(i1, 8) + "__" + strZero(i2, 8)

RETURN cIntenalID

/*------------------------------------------------------------------------*/

FUNCTION SR_SetCollation(cName)

   LOCAL cOld := cCollation

   If HB_ISCHAR(cName)
      cCollation := cName
   EndIf

RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_DropIndex(cIndexName, cOwner)

   LOCAL oCnn
   LOCAL cFileName
   LOCAL nRet
   LOCAL aRet := {}
   LOCAL cPhisicalName
   LOCAL aIndex
   LOCAL cIdxName
   LOCAL oWA
   LOCAL lTag := .F.
   LOCAL cIndex
   LOCAL ctempIndex := ""

   oCnn := SR_GetConnection()

   aRet := eval(SR_GetIndexInfoBlock(), cIndexName)
   ctempIndex    := cIndexName
   cIndexName := SR_ParseFileName(alltrim(aRet[TABLE_INFO_TABLE_NAME]))

   If cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      If !Empty(SR_GetGlobalOwner())
         cOwner := alltrim(SR_GetGlobalOwner())
      ElseIf !Empty(oCnn:cOwner)
         cOwner := alltrim(oCnn:cOwner)
      ElseIf cOwner == NIL
         cOwner := ""
      EndIf
   EndIf

   If (!Empty(cOwner)) .AND. right(cOwner, 1) != "."
      cOwner += "."
   EndIf

   aRet := {}
   nRet := oCnn:exec("SELECT TABLE_, PHIS_NAME_, IDXNAME_, IDXCOL_, IDXFOR_, IDXKEY_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE IDXNAME_ = '" + Upper(Alltrim(cIndexName)) + "'", .F., .T., @aRet)
   If (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. len(aRet) == 0
      // Index does not exist
      aRet := {}
      nRet := oCnn:exec("SELECT TABLE_, PHIS_NAME_, IDXNAME_, IDXCOL_, IDXFOR_, IDXKEY_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE PHIS_NAME_ = '" + Upper(Alltrim(cIndexName)) + "'", .F., .T., @aRet)
      If (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. len(aRet) == 0
          aRet := {}
          nRet := oCnn:exec("SELECT TABLE_, PHIS_NAME_, IDXNAME_, IDXCOL_, IDXFOR_, IDXKEY_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TAG_ = '" + Alltrim(ctempIndex) + "'", .F., .T., @aRet)
         If (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. len(aRet) == 0
            RETURN .F.
         ELSE
            lTag := .T.
         ENDIF
      endif
   EndIf

   cFileName   := rtrim(aRet[1, 1])
   cIndex      := rtrim(aRet[1, 2])
   cIdxName    := rtrim(aRet[1, 3])
   If lTag
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + cFileName + "' AND PHIS_NAME_ = '" + cIndex + "'" + iif(oCnn:lComments," /* Wipe index info */",""), .F.)
   ELSE
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + cFileName + "' AND IDXNAME_ = '" + cIdxName + "'" + iif(oCnn:lComments," /* Wipe index info */",""), .F.)
   ENDIF
   oCnn:Commit()

   FOR EACH aIndex IN aRet
      cPhisicalName := rtrim(aIndex[2])

      SWITCH oCnn:nSystemID
      CASE SYSTEMID_MSSQL6
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_SYBASE
      CASE SYSTEMID_AZURE
         oCnn:exec("DROP INDEX " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + "." + cPhisicalName, .F.)
         EXIT
      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
         oCnn:exec("DROP INDEX " + cPhisicalName + " ON " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + iif(oCnn:lComments, " /* DROP Index */", ""), .F.)
         EXIT
      CASE SYSTEMID_ORACLE
         If len(aIndex[6]) > 4 .AND. aIndex[6][4] == "@"
            oCnn:exec("DROP INDEX " + cOwner + "A$" + SubStr(aIndex[6], 1, 3) + SubStr(cFileName, 1, 25) + iif(oCnn:lComments, " /* Drop VIndex */", ""), .F.)
            oCnn:Commit()
            oCnn:exec("DROP INDEX " + cOwner + "D$" + SubStr(aIndex[6], 1, 3) + SubStr(cFileName, 1, 25) + iif(oCnn:lComments, " /* Drop VIndex */", ""), .F.)
            oCnn:Commit()
         EndIf
         oCnn:exec("DROP INDEX " + cPhisicalName + iif(oCnn:lComments, " /* DROP Index */", ""), .F.)
         EXIT
      OTHERWISE
         oCnn:exec("DROP INDEX " + cPhisicalName + iif(oCnn:lComments, " /* DROP Index */", ""), .F.)
      ENDSWITCH

      If (!Empty(aIndex[4])) .OR. aIndex[5][1] == "#"
         USE (cFileName) NEW VIA "SQLRDD" ALIAS "TEMPDROPCO" exclusive
         oWA := TEMPDROPCO->(dbInfo(DBI_INTERNAL_OBJECT))

         If !Empty(aIndex[4])
            oWA:DropColumn("INDKEY_" + alltrim(aIndex[4]), .F.)
         EndIf
         If aIndex[5][1] == "#"
            oWA:DropColumn("INDFOR_" + substr(aIndex[5], 2, 3), .F.)
         EndIf

         TEMPDROPCO->(dbCLoseArea())
      EndIf
   NEXT

   oCnn:Commit()
   SR_CleanTabInfoCache()

RETURN .T.

/*------------------------------------------------------------------------*/

FUNCTION SR_DropTable(cFileName, cOwner)

   LOCAL oCnn
   LOCAL lRet
   LOCAL aRet := {}

   oCnn := SR_GetConnection()

   aRet := eval(SR_GetTableInfoBlock(), cFileName)
   cFileName := SR_ParseFileName(alltrim(aRet[TABLE_INFO_TABLE_NAME]))

   If cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      If !Empty(SR_GetGlobalOwner())
         cOwner := alltrim(SR_GetGlobalOwner())
      ElseIf !Empty(oCnn:cOwner)
         cOwner := alltrim(oCnn:cOwner)
      ElseIf cOwner == NIL
         cOwner := ""
      EndIf
   EndIf

   If (!Empty(cOwner)) .AND. right(cOwner, 1) != "."
      cOwner += "."
   EndIf

   /* Drop the table */

   lRet := oCnn:exec("DROP TABLE " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + iif(oCnn:nSystemID == SYSTEMID_ORACLE, " CASCADE CONSTRAINTS", "") + iif(oCnn:lComments, " /* drop table */", ""), .T.) == SQL_SUCCESS
   oCnn:Commit()

   If lRet
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + UPPER(cFileName) + "'" + iif(oCnn:lComments, " /* Wipe index info */", ""), .F.)
      oCnn:Commit()
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES WHERE TABLE_ = '" + UPPER(cFileName) + "'" + iif(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLANG WHERE TABLE_ = '" + UPPER(cFileName) + "'" + iif(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS WHERE TABLE_ = '" + UPPER(cFileName) + "'" + iif(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS WHERE SOURCETABLE_ = '" + UPPER(cFileName) + "'" + iif(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS WHERE SOURCETABLE_ = '" + UPPER(cFileName) + "'" + iif(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS WHERE SOURCETABLE_ = '" + UPPER(cFileName) + "'" + iif(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
   EndIf

RETURN lRet

/*------------------------------------------------------------------------*/

FUNCTION SR_ListIndex(cFilename)

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}
   LOCAL i

   oCnn := SR_GetConnection()

   aRet := eval(SR_GetIndexInfoBlock(), cFilename)
   cFilename := SR_ParseFileName(alltrim(aRet[TABLE_INFO_TABLE_NAME]))

   aRet := {}
   nRet := oCnn:exec("SELECT IDXNAME_,PHIS_NAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_ FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + alltrim(upper(cFilename)) + "'", .F., .T., @aRet)

   FOR i := 1 TO len(aRet)
      aRet[i, 1] := alltrim(aRet[i, 1])
   NEXT i

RETURN aRet

/*------------------------------------------------------------------------*/

FUNCTION SR_RenameTable(cTable, cNewName, cOwner)

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}
   LOCAL lOk := .F.

   oCnn := SR_GetConnection()

   aRet   := eval(SR_GetTableInfoBlock(), cTable)
   cTable := SR_ParseFileName(alltrim(aRet[TABLE_INFO_TABLE_NAME]))

   If cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      If !Empty(SR_GetGlobalOwner())
         cOwner := alltrim(SR_GetGlobalOwner())
      ElseIf !Empty(oCnn:cOwner)
         cOwner := alltrim(oCnn:cOwner)
      ElseIf cOwner == NIL
         cOwner := ""
      EndIf
   EndIf

   If (!Empty(cOwner)) .AND. right(cOwner, 1) != "."
      cOwner += "."
   EndIf

   aRet     := eval(SR_GetTableInfoBlock(), cNewName)
   cNewName := SR_ParseFileName(alltrim(aRet[TABLE_INFO_TABLE_NAME]))

   aRet := {}
   nRet := oCnn:exec("SELECT * FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES WHERE TABLE_ = '" + upper(cTable) + "'", .F., .T., @aRet)
   If (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. len(aRet) == 0
      // Table does not exist
      RETURN .F.
   EndIf

   aRet := {}
   nRet := oCnn:exec("SELECT * FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES WHERE TABLE_ = '" + upper(cNewName) + "'", .F., .T., @aRet)
   If len(aRet) > 0
      // Destination EXISTS !!
      RETURN .F.
   EndIf

   SWITCH oCnn:nSystemID
   CASE SYSTEMID_MSSQL7
   CASE SYSTEMID_AZURE
      nRet := oCnn:exec("exec sp_rename " + cOwner + cTable + ", " + cOwner + cNewName, .F.)
      If nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
         lOk := .T.
      EndIf
      EXIT
   CASE SYSTEMID_POSTGR
   CASE SYSTEMID_ORACLE
   CASE SYSTEMID_MYSQL
   CASE SYSTEMID_MARIADB
      IF oCnn:nSystemID == SYSTEMID_POSTGR
         nRet := oCnn:exec("ALTER TABLE " + cOwner + SR_DBQUALIFY(cTable + "_sq", oCnn:nSystemID) + " RENAME TO " + cOwner + SR_DBQUALIFY(cNewName+"_sq", oCnn:nSystemID), .F.)
      ENDIF

      nRet := oCnn:exec("ALTER TABLE " + cOwner + SR_DBQUALIFY(cTable, oCnn:nSystemID) + " RENAME TO " + cOwner + SR_DBQUALIFY(cNewName, oCnn:nSystemID), .F.)
      If nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
         lOk := .T.
      EndIf

      IF oCnn:nSystemID == SYSTEMID_POSTGR
         nRet := oCnn:exec("ALTER TABLE " + cOwner + SR_DBQUALIFY(cNewName, oCnn:nSystemID) + " ALTER COLUMN " + SR_RecnoName() + " SET DEFAULT nextval('" + lower(cNewName) + "_sq'::regclass)")
      ENDIF
      IF oCnn:nSystemID == SYSTEMID_ORACLE
         nRet := oCnn:exec("RENAME " + cOwner + cTable + "_sq" + " TO " + cOwner + cNewName+"_sq", .F.)
      ENDIF
      EXIT

   ENDSWITCH

   If lOk
      oCnn:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTINDEXES SET TABLE_ = '" + cNewName + "' WHERE TABLE_ = '" + cTable + "'", .F.)
      oCnn:exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTTABLES SET TABLE_ = '" + cNewName + "' WHERE TABLE_ = '" + cTable + "'", .F.)
      oCnn:Commit()
   EndIf

RETURN lOk

/*------------------------------------------------------------------------*/

FUNCTION SR_ListTables(cOwner)

RETURN (SR_GetConnection()):ListCatTables(cOwner)

/*------------------------------------------------------------------------*/

FUNCTION SR_ListCreatedTables()

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}
   LOCAL aRet2 := {}

   oCnn := SR_GetConnection()
   nRet := oCnn:exec("SELECT TABLE_ FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES", .F., .T., @aRet)

   aEval(aRet, {|x| aadd(aRet2, alltrim(x[1])) })

RETURN aRet2

/*------------------------------------------------------------------------*/

FUNCTION SR_SetToolsOwner(cOwner)

   LOCAL cOld := cToolsOwner
   LOCAL oSql

   If cOwner != NIL
      cToolsOwner := cOwner
      If (!Empty(cOwner)) .AND. right(cToolsOwner, 1) != "."
         cToolsOwner += "."
      EndIf
   Else
      If Empty(cToolsOwner)
         oSql := SR_GetConnection()
         If !Empty(oSql:cOwner)
            RETURN oSql:cOwner
         EndIf
      EndIf
   EndIf

RETURN cOld

/*------------------------------------------------------------------------*/

FUNCTION SR_GetToolsOwner()

   LOCAL oSql

   If Empty(cToolsOwner)
      oSql := SR_GetConnection()
      If !Empty(oSql:cOwner)
         RETURN oSql:cOwner
      EndIf
   EndIf

RETURN cToolsOwner

/*------------------------------------------------------------------------

SQLRDD Exclusive Lock management and Lock behavior
--------------------------------------------------

We use internally 2 different connections to manage locks.
Connection information:

1 - Transactional connection (regular queries)
2 - Autocommit connection (used for counters and "one query" transactions)

SetLocks function steps, using SQLRDD system table SR_MGMNTLOCKS:

* For Microsoft SQL Server:
---------------------------

At application startup, perform the following housekeeping routine:

"DELETE FROM SR_MGMNTLOCKS WHERE SPID_ = @@SPID OR SPID_ + LOGIN_TIME_ NOT IN (SELECT SPID + LOGIN_TIME FROM MASTER.DBO.SYSPROCESSES)"

1 - Try to INSERT the string to be locked using connection 2; Commit;
2 - If success, LOCK is acquired
3 - If it fails, run housekeeping "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (SELECT SPID FROM MASTER.DBO.SYSPROCESSES)"; Commit;
4 - Try INSERT again;
5 - If succefull, lock is acquired;
6 - If not succefull, lock is denied;

* For Oracle:
-------------

Housekeeping expression is:
"DELETE FROM SR_MGMNTLOCKS WHERE SPID_ = sys_context('USERENV','sessionid') OR SPID_ NOT IN (select "AUDSID" from v$session)"

Step 3 query is:
"DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (select "AUDSID" from v$session)"; Commit;

* For Postgres:
---------------

Housekeeping expression is:
"DELETE FROM SR_MGMNTLOCKS WHERE SPID_ = (select pg_backend_pid()) OR SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))"

Step 3 query is:
"DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))"; Commit;


ReleaseLocks function steps:

1 - Delete the line using connection 2; Commit;

------------------------------------------------------------------------*/

FUNCTION SR_SetLocks(uLocks, oCnn, nRetries)

   LOCAL lRet := .T.
   LOCAL aLocks
   LOCAL cSql
   LOCAL cValue
   LOCAL aAdded := {}
   LOCAL nRet
   LOCAL cIns
   LOCAL cDel

   DEFAULT oCnn     TO SR_GetConnection()
   DEFAULT nRetries TO 0

   If oCnn:oSqlTransact == NIL
      RETURN .T.
   EndIf

   Do Case
   Case HB_ISCHAR(uLocks)
      aLocks := { uLocks }
   Case HB_ISARRAY(uLocks)
      aLocks := uLocks
   OtherWise
      aLocks := { SR_Val2Char(uLocks) }
   EndCase

   FOR EACH cValue IN aLocks

      cValue := SR_Val2Char(cValue)

      SWITCH oCnn:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_AZURE
         cIns := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( LOCK_, WSID_, SPID_, LOGIN_TIME_ ) VALUES ( '" + cValue + "', '" + SR_GetInternalID() + "', @@SPID, '" + oCnn:oSqlTransact:cLoginTime + "' )"
         cDel := "DELETE FROM SR_MGMNTLOCKS WHERE convert( CHAR(10), SPID_ ) + convert( CHAR(23), LOGIN_TIME_, 21 ) NOT IN (SELECT convert( CHAR(10), SPID) + CONVERT( CHAR(23), LOGIN_TIME, 21 ) FROM MASTER.DBO.SYSPROCESSES)"
         EXIT
      CASE SYSTEMID_ORACLE
         cIns := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( LOCK_, WSID_, SPID_ ) VALUES ( '" + cValue + "', '" + SR_GetInternalID() + "', " + str(oCnn:uSid) + " )"
         cDel := [DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (select "AUDSID" from ] + IIf(oCnn:lCluster, "g", "") + [v$session)]
         EXIT
      CASE SYSTEMID_POSTGR
         cIns := "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( LOCK_, WSID_, SPID_ ) VALUES ( '" + cValue + "', '" + SR_GetInternalID() + "', (select pg_backend_pid()) )"
         cDel := "DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))"
         EXIT
      CASE SYSTEMID_IBMDB2
         EXIT
      ENDSWITCH

      nRet := oCnn:oSqlTransact:exec(cIns, .F.)
      oCnn:oSqlTransact:Commit()

      If nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         oCnn:oSqlTransact:exec(cDel, .F.)
         oCnn:oSqlTransact:Commit()
         nRet := oCnn:oSqlTransact:exec(cIns, .F.)
         oCnn:oSqlTransact:Commit()

         If nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
            DO WHILE nRetries > 0
               oCnn:oSqlTransact:exec(cDel, .F.)
               oCnn:oSqlTransact:Commit()
               nRet := oCnn:oSqlTransact:exec(cIns, .F.)
               oCnn:oSqlTransact:Commit()

               If nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
                  Inkey(.5)
                  nRetries--
               Else
                  Exit
               EndIf
            ENDDO
         EndIf
      EndIf

      If nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
         aadd(aAdded, cValue)
      Else
         lRet := .F.
         Exit
      EndIf
   NEXT

   If !lRet
      FOR EACH cValue IN aAdded
         SWITCH oCnn:nSystemID
         CASE SYSTEMID_MSSQL7
         CASE SYSTEMID_ORACLE
         CASE SYSTEMID_POSTGR
         CASE SYSTEMID_IBMDB2
         CASE SYSTEMID_AZURE
            cSql := "DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE LOCK_ = '" + cValue + "' AND WSID_ = '" + SR_GetInternalID() + "'"
            EXIT
         ENDSWITCH
         oCnn:oSqlTransact:exec(cSql, .F.)
         oCnn:oSqlTransact:Commit()
      NEXT
   EndIf

RETURN lRet

/*------------------------------------------------------------------------*/

FUNCTION SR_ReleaseLocks(uLocks, oCnn)

   LOCAL lRet := .T.
   LOCAL aLocks
   LOCAL cValue
   LOCAL cSql

   DEFAULT oCnn TO SR_GetConnection()

   If oCnn:oSqlTransact == NIL
      RETURN .F.
   EndIf

   Do Case
   Case HB_ISCHAR(uLocks)
      aLocks := { uLocks }
   Case HB_ISARRAY(uLocks)
      aLocks := uLocks
   OtherWise
      aLocks := { SR_Val2Char(uLocks) }
   EndCase

   FOR EACH cValue IN aLocks
      cValue := SR_Val2Char(cValue)
      SWITCH oCnn:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_ORACLE
      CASE SYSTEMID_POSTGR
      CASE SYSTEMID_IBMDB2
      CASE SYSTEMID_AZURE
         cSql := "DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE LOCK_ = '" + cValue + "' AND WSID_ = '" + SR_GetInternalID() + "'"
         EXIT
      ENDSWITCH

      oCnn:oSqlTransact:exec(cSql, .T.)
      oCnn:oSqlTransact:Commit()
   NEXT

RETURN lRet

/*------------------------------------------------------------------------*/

FUNCTION SR_ListLocks(oCnn, lAll)

   LOCAL aLocks := {}

   DEFAULT oCnn TO SR_GetConnection()
   DEFAULT lAll TO .F.

   If oCnn:oSqlTransact == NIL
      RETURN {}
   EndIf

   // Housekeeping to avoid wrong info

   SWITCH oCnn:oSqlTransact:nSystemID
   CASE SYSTEMID_ORACLE
      oCnn:oSqlTransact:exec("DELETE FROM " + SR_GetToolsOwner() + [SR_MGMNTLOCKS WHERE SPID_ NOT IN (select "SID" from ] + IIf(oCnn:lCluster, "g", "") + [v$session)], .F.)
      EXIT
   CASE SYSTEMID_INGRES
      EXIT
   CASE SYSTEMID_IBMDB2
      EXIT
   CASE SYSTEMID_SYBASE
      EXIT
   CASE SYSTEMID_MSSQL7
   CASE SYSTEMID_MSSQL6
   CASE SYSTEMID_AZURE
      oCnn:oSqlTransact:exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE convert( CHAR(10), SPID_ ) + convert( CHAR(23), LOGIN_TIME_, 21 ) NOT IN (SELECT convert( CHAR(10), SPID) + CONVERT( CHAR(23), LOGIN_TIME, 21 ) FROM MASTER.DBO.SYSPROCESSES)", .F.)
      EXIT
   CASE SYSTEMID_MYSQL
   CASE SYSTEMID_MARIADB
      EXIT
   CASE SYSTEMID_POSTGR
      oCnn:oSqlTransact:exec("DELETE FROM  " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))", .F.)
      EXIT
   ENDSWITCH

   oCnn:oSqlTransact:Commit()
   oCnn:oSqlTransact:exec("SELECT LOCK_, WSID_, SPID_ FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS" + IIf(lAll, " WHERE WSID_ = '" + SR_GetInternalID() + "'", ""), .F., .T., @aLocks)

RETURN aLocks

/*------------------------------------------------------------------------*/

FUNCTION DetectDBFromDSN(cConnect)

RETURN SR_DetectDBFromDSN(cConnect)

/*------------------------------------------------------------------------*/

FUNCTION SR_DetectDBFromDSN(cConnect)

   LOCAL aItem
   LOCAL cBuff
   LOCAL aToken
   LOCAL aCon := hb_atokens(cConnect,";")

   FOR EACH aItem IN aCon
      aToken := hb_atokens(aItem,"=")
      cBuff = Upper(aToken[1])
      SWITCH cBuff
      CASE "OCI"
         RETURN CONNECT_ORACLE
      CASE "OCI2"
         RETURN CONNECT_ORACLE2
      CASE "PGS"
         RETURN CONNECT_POSTGRES
      CASE "MYSQL"
         RETURN CONNECT_MYSQL
      CASE "MARIA"
         RETURN CONNECT_MARIA
      CASE "FB"
      CASE "FIREBIRD"
      CASE "IB"
         RETURN CONNECT_FIREBIRD
      CASE "FB3"
      CASE "FIREBIRD3"
         RETURN CONNECT_FIREBIRD3
      CASE "DSN"
      CASE "DRIVER"
         RETURN CONNECT_ODBC
      ENDSWITCH
   NEXT

RETURN SYSTEMID_UNKNOW

/*------------------------------------------------------------------------*/

#pragma BEGINDUMP

#include "compat.h"

static HB_BOOL s_fMultiLang               = HB_FALSE;
static HB_BOOL s_fShutDown                = HB_FALSE;
static HB_BOOL s_fGoTopOnScope            = HB_TRUE;
static HB_BOOL s_fSerializedAsString      = HB_FALSE;
static HB_BOOL s_fHideRecno               = HB_TRUE;
static HB_BOOL s_fHideHistoric            = HB_FALSE;
static HB_BOOL s_fUseDeleteds             = HB_TRUE;
/* Culik added new global to tell if we will serialize arrays as json or xml */
static HB_BOOL s_fSerializeArrayAsJson    = HB_FALSE;
/* Culik added new global to tell if we are using sqlverser 2008 or newer */
static HB_BOOL s_fSql2008newTypes         = HB_FALSE;

static HB_BOOL s_iOldPgsBehavior          = HB_FALSE;
static HB_BOOL s_fShortasNum              = HB_FALSE;

HB_BOOL HB_EXPORT sr_isMultilang(void)
{
   return s_fMultiLang;
}

HB_FUNC( SR_SETMULTILANG )
{
   hb_retl(s_fMultiLang);
   if( HB_ISLOG(1) ) {
      s_fMultiLang = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_isShutdownProcess(void)
{
   return s_fShutDown;
}

HB_FUNC( SR_SETSHUTDOWN )
{
   hb_retl(s_fShutDown);
   if( HB_ISLOG(1) ) {
      s_fShutDown = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_GoTopOnScope(void)
{
   return s_fGoTopOnScope;
}

HB_FUNC( SR_SETGOTOPONSCOPE )
{
   hb_retl(s_fGoTopOnScope);
   if( HB_ISLOG(1) ) {
      s_fGoTopOnScope = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_lSerializedAsString(void)
{
   return s_fSerializedAsString;
}

HB_FUNC( SR_SETSERIALIZEDSTRING )
{
   hb_retl(s_fSerializedAsString);
   if( HB_ISLOG(1) ) {
      s_fSerializedAsString = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_lHideRecno(void)
{
   return s_fHideRecno;
}

HB_FUNC( SR_SETHIDERECNO )
{
   hb_retl(s_fHideRecno);
   if( HB_ISLOG(1) ) {
      s_fHideRecno = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_lHideHistoric(void)
{
   return s_fHideHistoric;
}

HB_FUNC( SR_SETHIDEHISTORIC )
{
   hb_retl(s_fHideHistoric);
   if( HB_ISLOG(1) ) {
      s_fHideHistoric = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_UseDeleteds(void)
{
   return s_fUseDeleteds;
}

HB_FUNC( SR_USEDELETEDS )
{
   hb_retl(s_fUseDeleteds);
   if( HB_ISLOG(1) ) {
      s_fUseDeleteds = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_lSerializeArrayAsJson(void)
{
   return s_fSerializeArrayAsJson;
}

HB_FUNC( SR_SETSERIALIZEARRAYASJSON )
{
   hb_retl(s_fSerializeArrayAsJson);
   if( HB_ISLOG(1) ) {
      s_fSerializeArrayAsJson = hb_parl(1);
   }
}

HB_BOOL HB_EXPORT sr_lsql2008newTypes(void)
{
   return s_fSql2008newTypes;
}

HB_BOOL HB_EXPORT sr_iOldPgsBehavior(void)
{
   return s_iOldPgsBehavior;
}

HB_FUNC( SR_GETSQL2008NEWTYPES )
{
   hb_retl(s_fSql2008newTypes);
}

HB_FUNC( SR_SETSQL2008NEWTYPES )
{
   hb_retl(s_fSql2008newTypes);
   if( HB_ISLOG(1) ) {
      s_fSql2008newTypes = hb_parl(1);
   }
}

HB_FUNC( SETPGSOLDBEHAVIOR )
{
   int iOld = s_iOldPgsBehavior;
   if( HB_ISLOG(1) ) {
      s_iOldPgsBehavior = hb_parl(1);
   }
   hb_retl(iOld);
}


HB_BOOL HB_EXPORT sr_fShortasNum(void)
{
   return s_fShortasNum;
}

HB_FUNC( SETFIREBIRDUSESHORTASNUM )
{
   int iOld = s_fShortasNum;
   if( HB_ISLOG(1) ) {
      s_fShortasNum = hb_parl(1);
   }
   hb_retl(iOld);
}

#pragma ENDDUMP

/*------------------------------------------------------------------------*/

FUNCTION SR_Version()

Return HB_SR__VERSION_STRING + ", Build " + alltrim(strzero(HB_SQLRDD_BUILD, 4)) + ", " + HB_SR__MGMNT_VERSION

/*------------------------------------------------------------------------*/

Exit Proc SQLRDD_ShutDown()
   sr_setShutDown(.T.)
Return

/*------------------------------------------------------------------------*/
