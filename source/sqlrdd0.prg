//
// SQLRDD Startup
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

#include <common.ch>
#include <error.ch>
#include <rddsys.ch>
#include <hbclass.ch>
// #include "compat.ch"
#include "sqlrdd.ch"
#include "sqlodbc.ch"
#include "msg.ch"
#define HB_FALSE 0
#define HB_TRUE 1
//REQUEST XHB_LIB
REQUEST HB_Deserialize
REQUEST HB_Serialize

// Need this modules linked
REQUEST SR_WORKAREA

STATIC s_aConnections
STATIC s_nActiveConnection

STATIC s_lTblMgmnt := .F.
STATIC s_EvalFilters := .F.
STATIC s_RecnoName := "SR_RECNO"
STATIC s_DeletedName := "SR_DELETED"
STATIC s_cCollation := ""
STATIC s_cToolsOwner := ""
STATIC s_cIntenalID := NIL
STATIC s_lFastOpenWA := .T.
STATIC s_nMaxRowCache := 1000
STATIC s_nFetchSize := 10
STATIC s_lSyntheticInd := .F.
STATIC s_cSynthetiVInd := ""
STATIC s_lCheckMgmntInd := .T.
STATIC s_cRDDTemp := "DBFCDX"

STATIC s_cTblSpaceData := ""
STATIC s_cTblSpaceIndx := ""
STATIC s_cTblSpaceLob := ""

STATIC s_hMultilangColumns
STATIC s_nSyntheticIndexMinimun := 3

STATIC s_lErrorOnGotoToInvalidRecord := .F.

STATIC s_lUseNullsFirst := .T.

//-------------------------------------------------------------------------------------------------------------------//

PROCEDURE SR_Init()
RETURN

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetCnn(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection

   IF SR_CheckCnn(nConnection)
      DEFAULT s_aConnections TO {}
      RETURN s_aConnections[nConnection]
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_CheckCnn(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}

   IF nConnection > Len(s_aConnections) .OR. nConnection == 0
      RETURN .F.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetConnection(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}

   SR_CheckConnection(nConnection)

RETURN s_aConnections[nConnection]

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_CheckConnection(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}

   IF nConnection > Len(s_aConnections) .OR. nConnection == 0 .OR. nConnection < 0
      RETURN SR_RuntimeErr("SR_CheckConnection()", SR_Msg(7))
   ENDIF

RETURN s_aConnections[nConnection]

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetNextQuery(cSql)

   LOCAL cOld

   DEFAULT s_aConnections TO {}
   DEFAULT s_nActiveConnection TO 0

   SR_CheckConnection(s_nActiveConnection)
   cOld := s_aConnections[s_nActiveConnection]:cNextQuery

   IF cSql != NIL
      s_aConnections[s_nActiveConnection]:cNextQuery := cSql
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetSyntheticIndexMinimun()

   LOCAL nRet := s_nSyntheticIndexMinimun

   DEFAULT s_aConnections TO {}
   DEFAULT s_nActiveConnection TO 0

   SWITCH s_aConnections[s_nActiveConnection]:nSystemID
   CASE SYSTEMID_POSTGR
   CASE SYSTEMID_ORACLE
      EXIT
   OTHERWISE
      nRet := 10
   ENDSWITCH

RETURN nRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetSyntheticIndexMinimun(nSet)

   LOCAL nOld := s_nSyntheticIndexMinimun

   IF HB_IsNumeric(nSet)
      s_nSyntheticIndexMinimun := Min(nSet, 10)
   ENDIF

RETURN nOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_CheckMgmntInd(nSet)

   LOCAL nOld := s_lCheckMgmntInd

   IF HB_IsLogical(nSet)
      s_lCheckMgmntInd := nSet
   ENDIF

RETURN nOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetSyntheticIndex(lSet)

   LOCAL lOld := s_lSyntheticInd

   IF HB_IsLogical(lSet)
      s_lSyntheticInd := lSet
   ENDIF

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetSyntheticIndex()

RETURN s_lSyntheticInd

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetSVIndex(cSet)

   LOCAL cOld := s_cSynthetiVInd

   IF HB_IsChar(cSet)
      IF Len(cSet) != 3 .OR. " " $ cSet .OR. "." $ cSet
         SR_RuntimeErr("SR_SetSVIndex()", "Invalid parameter: " + cSet)
      ENDIF
      s_cSynthetiVInd := cSet
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetSVIndex()

   LOCAL cRet := s_cSynthetiVInd

   s_cSynthetiVInd := ""

RETURN cRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetFastOpen(lSet)

   LOCAL lOld := s_lFastOpenWA

   IF HB_IsLogical(lSet)
      s_lFastOpenWA := lSet
   ENDIF

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetExclusiveManagement(lSet)

   LOCAL lOld := !s_lFastOpenWA

   IF HB_IsLogical(lSet)
      s_lFastOpenWA := !lSet
   ENDIF

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetTblSpaceData(cSet)

   LOCAL cOld := s_cTblSpaceData
   LOCAL oSql

   IF HB_IsChar(cSet)
      s_cTblSpaceData := cSet
   ELSEIF Empty(s_cTblSpaceData)
      oSql := SR_GetConnection()
      IF !Empty(oSql:cDsnTblData)
         RETURN oSql:cDsnTblData
      ENDIF
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetTblSpaceIndx(cSet)

   LOCAL cOld := s_cTblSpaceIndx
   LOCAL oSql

   IF HB_IsChar(cSet)
      s_cTblSpaceIndx := cSet
   ELSEIF Empty(s_cTblSpaceIndx)
      oSql := SR_GetConnection()
      If !Empty(oSql:cDsnTblIndx)
         RETURN oSql:cDsnTblIndx
      ENDIF
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetTblSpaceLob(cSet)

   LOCAL cOld := s_cTblSpaceLob
   LOCAL oSql

   IF HB_IsChar(cSet)
      s_cTblSpaceLob := cSet
   ELSEIF Empty(s_cTblSpaceLob)
      oSql := SR_GetConnection()
      IF !Empty(oSql:cDsnTblLob)
         RETURN oSql:cDsnTblLob
      ENDIF
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetRDDTemp(cSet)

   LOCAL cOld := s_cRDDTemp

   IF HB_IsChar(cSet)
      s_cRDDTemp := cSet
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetFastOpen()

RETURN s_lFastOpenWA

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetActiveConnection()

   DEFAULT s_nActiveConnection TO 0

RETURN s_nActiveConnection

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetActiveConnection(nCnn)

   LOCAL nOld

   DEFAULT s_nActiveConnection TO 0
   nOld := s_nActiveConnection
   DEFAULT nCnn TO 1
   DEFAULT s_aConnections TO {}

   IF nCnn != 0 .AND. nCnn <= Len(s_aConnections)
      s_nActiveConnection := nCnn
   ELSE
      RETURN -1
   ENDIF

RETURN nOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_AddConnection(nType, cDSN, cUser, cPassword, cOwner, lCounter, lAutoCommit, lNoSetEnv, nTimeout)

   LOCAL nRet := -1
   LOCAL oConnect
   LOCAL oConnect2

   DEFAULT nType TO CONNECT_ODBC
   DEFAULT lAutoCommit TO .F.
   DEFAULT lCounter TO .F.
   DEFAULT cOwner TO ""
   DEFAULT lNoSetEnv TO .F.
   DEFAULT s_aConnections TO {}
   DEFAULT s_nActiveConnection TO 0

   // The macro execution is used to NOT link the connection class if we don't need it
   // The programmer MUST declare the needed connection class using REQUEST in PRG source

   SWITCH nType
   CASE CONNECT_ODBC
   CASE CONNECT_ODBC_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_ODBC()")
      oConnect2 := &("SR_ODBC()")
#endif
      EXIT
   CASE CONNECT_MYSQL
   CASE CONNECT_MYSQL_NOEXLOCK
      oConnect := &("SR_MYSQL()")
      oConnect2 := &("SR_MYSQL()")
      EXIT
   CASE CONNECT_POSTGRES
   CASE CONNECT_POSTGRES_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_PGS()")
      oConnect2 := &("SR_PGS()")
#endif
      EXIT
   CASE CONNECT_ORACLE
   CASE CONNECT_ORACLE_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_ORACLE()")
      oConnect2 := &("SR_ORACLE()")
#endif
      EXIT
   CASE CONNECT_ORACLE2
   CASE CONNECT_ORACLE2_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_ORACLE2()")
      oConnect2 := &("SR_ORACLE2()")
#endif
      EXIT
   CASE CONNECT_FIREBIRD
   CASE CONNECT_FIREBIRD_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_FIREBIRD()")
      oConnect2 := &("SR_FIREBIRD()")
#endif
      EXIT
   CASE CONNECT_FIREBIRD3
   CASE CONNECT_FIREBIRD3_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_FIREBIRD3()")
      oConnect2 := &("SR_FIREBIRD3()")
#endif
      EXIT
   CASE CONNECT_FIREBIRD4
   CASE CONNECT_FIREBIRD4_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_FIREBIRD4()")
      oConnect2 := &("SR_FIREBIRD4()")
#endif
      EXIT
   CASE CONNECT_FIREBIRD5
   CASE CONNECT_FIREBIRD5_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_FIREBIRD5()")
      oConnect2 := &("SR_FIREBIRD5()")
#endif
      EXIT
   CASE CONNECT_MARIA
   CASE CONNECT_MARIA_NOEXLOCK
#ifndef MYSQLRDD
      oConnect := &("SR_MARIA()")
      oConnect2 := &("SR_MARIA()")
#endif
      EXIT
   CASE CONNECT_ODBC_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect := &("SR_ODBC()")
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_ORACLE_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect := &("SR_ORACLE()")
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_ORACLE2_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect := &("SR_ORACLE2()")
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_MYSQL_QUERY_ONLY
      oConnect := &("SR_MYSQL()")
      oConnect:lQueryOnly := .T.
      EXIT
   CASE CONNECT_POSTGRES_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect := &("SR_PGS()")
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_FIREBIRD_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect := &("SR_FIREBIRD()")
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   CASE CONNECT_MARIA_QUERY_ONLY
#ifndef MYSQLRDD
      oConnect := &("SR_MARIA()")
      oConnect:lQueryOnly := .T.
#endif
      EXIT
   OTHERWISE
      SR_MsgLogFile("Invalid connection type in SR_AddConnection() :" + Str(nType))
      RETURN -1
   ENDSWITCH

   IF HB_IsObject(oConnect)
      oConnect:Connect("", cUser, cPassword, 1, cOwner, 4000, .F., cDSN, 50, "ANSI", 0, 0, 0, lCounter, lAutoCommit, ;
         nTimeout)
   ELSE
      SR_MsgLogFile("Invalid connection type in SR_AddConnection() :" + Str(nType))
      RETURN -1
   ENDIF

   IF oConnect:nSystemID != 0 .AND. oConnect:nSystemID != NIL

      oConnect:nConnectionType := nType

      // Create other connections to the database

      IF nType < CONNECT_NOEXLOCK
         oConnect:oSqlTransact := oConnect2:Connect("", cUser, cPassword, 1, cOwner, 4000, .F., cDSN, 50, "ANSI", ;
            0, 0, 0, .T., lAutoCommit, nTimeout)
         oConnect2:nConnectionType := nType
      ELSEIF nType < CONNECT_QUERY_ONLY
         lNoSetEnv := .F.
      ELSE
         lNoSetEnv := .T.
      ENDIF

      // ToDo: Add MUTEX here
      AAdd(s_aConnections, oConnect)
      nRet := Len(s_aConnections)

      IF s_nActiveConnection == NIL .OR. s_nActiveConnection == 0
         s_nActiveConnection := nRet
      ENDIF

      oConnect:nID := nRet

      IF !lNoSetEnv
         IF Empty(SR_SetEnvSQLRDD(oConnect))
            RETURN -1
         ENDIF
      ELSE
         IF Empty(SR_SetEnvMinimal(oConnect))
            RETURN -1
         ENDIF
      ENDIF

      SR_ReloadFieldModifiers(oConnect)

      IF !("DB2/400" $ oConnect:cSystemName)
         IF !lAutoCommit
            oConnect:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF)
            IF nType < CONNECT_QUERY_ONLY
               oConnect2:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_OFF)
            ENDIF
         ENDIF
      ELSE
         oConnect:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON)
         IF nType < CONNECT_QUERY_ONLY
            oConnect2:SetOptions(SQL_AUTOCOMMIT, SQL_AUTOCOMMIT_ON)
         ENDIF
      ENDIF

   ENDIF

RETURN nRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ReloadFieldModifiers(oConnect)

#ifdef SQLRDD_TOPCONN

   LOCAL aRet := {}
   LOCAL aFlds := {}
   LOCAL aField
   LOCAL cLast

   IF oConnect:Exec("SELECT FIELD_TABLE, FIELD_NAME, FIELD_TYPE, FIELD_PREC, FIELD_DEC FROM TOP_FIELD WHERE FIELD_TYPE != 'X' ORDER BY FIELD_TABLE, FIELD_NAME", .F., .T., @aRet) == SQL_SUCCESS
      oConnect:aFieldModifier := {=>}
      hb_HAllocate(oConnect:aFieldModifier, 10000)
      oConnect:nTCCompat := 2
      IF Len(aRet) > 0
         cLast := aRet[1, 1]
         FOR EACH aField IN aRet
            IF aField[1] != cLast
               IF "." $ cLast
                  cLast := Upper(SubSTr(cLast, At(".", cLast) + 1))
               ENDIF
               oConnect:aFieldModifier[AllTrim(cLast)] := aFlds
               aFlds := {}
               cLast := aField[1]
            ENDIF
            AAdd(aFlds, {aField[2], aField[3], aField[4], aField[5]})
         NEXT
         IF "." $ cLast
            cLast := Upper(SubStr(cLast, At(".", cLast) + 1))
         ENDIF
         oConnect:aFieldModifier[AllTrim(cLast)] := aFlds
      ENDIF
   ELSE
      oConnect:Commit()
   ENDIF
#else
   HB_SYMBOL_UNUSED(oConnect)
#endif

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION SR_SetEnvSQLRDD(oConnect)

   LOCAL aRet := {}
   LOCAL cRet := ""
   LOCAL i
   LOCAL oCnn
   LOCAL cStartingVersion
   LOCAL cSql
   LOCAL lOld

   HB_SYMBOL_UNUSED(cRet)

   FOR i := 1 TO 2

      IF i == 1
         oCnn := oConnect
      ELSEIF i == 2
         IF oConnect:oSqlTransact == NIL
            EXIT
         ENDIF
         oCnn := oConnect:oSqlTransact
      ENDIF

      SWITCH oCnn:nSystemID

      CASE SYSTEMID_ORACLE
         IF SR_UseSequences() .AND. i == 1
            aRet := {}
            oCnn:Exec("SELECT SEQUENCE_NAME FROM USER_SEQUENCES WHERE SEQUENCE_NAME='SQ_NRECNO'", .F., .T., @aRet)
         ENDIF
         oCnn:Exec("ALTER SESSION SET NLS_LANGUAGE=AMERICAN", .F.)
         oCnn:Exec("ALTER SESSION SET NLS_SORT=BINARY", .F.)
         oCnn:Exec("ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,'", .F.)
         oCnn:Exec("alter session set SESSION_CACHED_CURSORS=10000", .F.)
         IF oCnn:cCharSet != NIL
            oCnn:Exec("ALTER SESSION SET NLS_CHARACTERSET=" + oCnn:cCharSet, .F.)
         ENDIF
         IF oCnn:lNative
            oCnn:Exec("ALTER SESSION SET NLS_DATE_FORMAT='yyyymmdd'", .F.)
            oCnn:Exec("ALTER SESSION SET NLS_TIMESTAMP_FORMAT='yyyymmdd HH.MI.SSXFF AM'", .F.)
         ENDIF
         // Locking system housekeeping

         aRet := {}
         oCnn:Exec("select sid from " + IIf(oCnn:lCluster, "g", "") + ;
            "v$session where AUDSID = sys_context('USERENV','sessionid')", .T., .T., @aRet)

         IF Len(aRet) > 0
            oCnn:uSid := Val(Str(aRet[1, 1], 8, 0))
         ENDIF

         oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLOCKS WHERE SPID_ = " + Str(oCnn:uSid) + ;
            " OR SPID_ NOT IN (select " + Chr(34) + "AUDSID" + Chr(34) + " from " + ;
            IIf(oCnn:lCluster, "g", "") + "v$session)", .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_INGRES
         oCnn:Commit()
         oCnn:Exec("set lockmode session where readlock=nolock,level=row")
         EXIT

      CASE SYSTEMID_IBMDB2
#if 0
         IF SR_UseSequences() .AND. i == 1
            aRet := {}
            oCnn:Exec("VALUES NEXTVAL FOR N_RECNO", .F., .T., @aRet)
            IF Len(aRet) == 0
               oCnn:Exec("CREATE SEQUENCE N_RECNO START WITH 1 INCREMENT BY 1 NOMAXVALUE NOCYCLE")
            ENDIF
         ENDIF
#endif
         EXIT

      CASE SYSTEMID_SYBASE
         //oCnn:Commit()
         //oCnn:Exec("SET CHAINED ON")
         oCnn:Commit()
         oCnn:Exec("SET QUOTED_IDENTIFIER ON")
         oCnn:Exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
         EXIT

      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_MSSQL6
      CASE SYSTEMID_AZURE
         oCnn:Commit()
         oCnn:Exec("SET QUOTED_IDENTIFIER ON")
         oCnn:Exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
         // Locking system housekeeping
         aRet := {}
         oCnn:Exec("SELECT convert( char(30), login_time, 21 ) FROM MASTER.DBO.SYSPROCESSES where SPID = @@SPID", ;
            .F., .T., @aRet)

         IF Len(aRet) > 0
            oCnn:cLoginTime := AllTrim(aRet[1, 1])
         ENDIF

         oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS WHERE SPID_ = @@SPID OR convert( CHAR(10), SPID_ ) + convert( CHAR(23), LOGIN_TIME_, 21 ) NOT IN (SELECT convert( CHAR(10), SPID) + CONVERT( CHAR(23), LOGIN_TIME, 21 ) FROM MASTER.DBO.SYSPROCESSES)", .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
         oCnn:Exec("set session autocommit=0;")
         oCnn:Exec("set session sql_mode = 'PIPES_AS_CONCAT'")
         oCnn:Exec("SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
         EXIT

      CASE SYSTEMID_POSTGR
         IF SR_UseSequences() .AND. i == 1
            aRet := {}
            oCnn:Exec("SELECT * FROM SQ_NRECNO", .F., .T., @aRet)
            oCnn:Commit()
         ENDIF
         oCnn:Exec("SET CLIENT_ENCODING to 'LATIN1'", .F., .T., @aRet)
         oCnn:Exec("SET xmloption to 'DOCUMENT'", .F., .T., @aRet)
         // Locking system housekeeping
         oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS WHERE SPID_ = (select pg_backend_pid()) OR SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))", .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_FIREBR
      CASE SYSTEMID_FIREBR3
      CASE SYSTEMID_FIREBR4
      CASE SYSTEMID_FIREBR5
         //oCnn:Exec("SET TERM !@¨§;", .F.)
         oCnn:Commit()
         EXIT

      CASE SYSTEMID_CACHE
         oCnn:Exec("SET OPTION SUPPORT_DELIMITED_IDENTIFIERS=TRUE")

         aRet := {}
         oCnn:Exec("select * from " + SR_GetToolsOwner() + "dual", .F., .T., @aRet)
         IF Len(aRet) == 0
            oConnect:Exec("create table " + SR_GetToolsOwner() + "dual (dummy char(1))", .F.)
            oConnect:Exec("insert into " + SR_GetToolsOwner() + "dual (dummy) values (0)", .F.)
            oConnect:Commit()

            cSql := "create function " + SR_GetToolsOwner() + e"NEXTVAL(sequenceName VARCHAR(50))\r\n for " + ;
               SR_GetToolsOwner() + e"SequenceControler \r\n"
            cSql += e"returns INT \r\n LANGUAGE OBJECTSCRIPT \r\n {\r\n New nextVal \r\n Set nextVal = $Increment(^" + ;
               SR_GetToolsOwner() + 'SequenceControler("Sequences",sequenceName))' + e"\r\n"
            cSql += e"Set ^CacheTemp.SequenceControler($Job,sequenceName)=nextVal \r\n Quit nextVal \r\n }"

            oConnect:Exec(cSql, .T.)
            oConnect:Commit()

            cSql := "create function " + SR_GetToolsOwner() + e"CURRVAL(sequenceName VARCHAR(50))\r\n for " + ;
               SR_GetToolsOwner() + e"SequenceControler \r\n  returns INT \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n  Quit $Get(^CacheTemp.SequenceControler($Job,sequenceName)) \r\n  }"

            oConnect:Exec(cSql, .T.)
            oConnect:Commit()

            cSql := "create procedure " + SR_GetToolsOwner() + e"RESET(sequenceName VARCHAR(50))\r\n for " + ;
               SR_GetToolsOwner() + e"SequenceControler \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n  Kill ^" + ;
               SR_GetToolsOwner() + 'SequenceControler("Sequences",sequenceName)' + e" \r\n  }"

            oConnect:Exec(cSql, .T.)
            oConnect:Commit()

            cSql := "create function " + SR_GetToolsOwner() + e"JOB()\r\n for " + SR_GetToolsOwner() + ;
               e"JOB \r\n  returns INT \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n  Quit $Job \r\n  }"
            oConnect:Exec(cSql, .T.)
            oConnect:Commit()

            cSql := "create function " + SR_GetToolsOwner() + e"JOBLIST()\r\n for " + SR_GetToolsOwner() + ;
               e"JOB \r\n  returns %String \r\n LANGUAGE OBJECTSCRIPT \r\n  { \r\n"
            cSql += [Set lista=""] + e"\r\n Do \r\n { \r\n" + [Set rs=##class(%ResultSet).%New("%SYSTEM.Process:CONTROLPANEL")] + e"\r\n" + [Set ok=rs.Execute("")] + e"\r\n"
            cSql += e"If 'ok Quit\r\n \r\n Set i=1\r\n  While rs.Next() \r\n{\r\n Set pid=rs.GetData(2) \r\n"
            cSql += [If pid>0 Set $Piece(lista,",",i)=pid] + e"\r\n Set i=i+1 \r\n } \r\n Do rs.Close() \r\n } While 0 \r\n"
            cSql += e"\r\n  Quit lista\r\n}\r\n"

            oConnect:Exec(cSql, .T.)
            oConnect:Commit()

         ENDIF

         oCnn:Commit()
         EXIT

      ENDSWITCH
   NEXT i

   // check for the control tables
   aRet := {}
   oConnect:Exec("SELECT VERSION_, SIGNATURE_ FROM " + SR_GetToolsOwner() + "SR_MGMNTVERSION", .F., .T., @aRet)

   IF Len(aRet) > 0
      cStartingVersion := AllTrim(aRet[1, 1])
   ELSE
      cStartingVersion := ""
   ENDIF

   IF cStartingVersion < "MGMNT 1.02"
      // Only use BASIC types and commands to be 100% darabase independent
      oConnect:Commit()
      oConnect:Exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTVERSION", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + ;
         "SR_MGMNTVERSION (VERSION_ CHAR(20), SIGNATURE_ CHAR(20))", .F.)
      oConnect:Commit()

      IF oConnect:nSystemID == SYSTEMID_AZURE
         oConnect:Exec("CREATE CLUSTERED INDEX " + ;
            IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
            "SR_MGMNTVERSION01 ON " + SR_GetToolsOwner() + "SR_MGMNTVERSION ( VERSION_ )", .F.)
         oConnect:Commit()
      ENDIF

      oConnect:Exec("INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTVERSION (VERSION_, SIGNATURE_) VALUES ('" + ;
         HB_SR__MGMNT_VERSION + "', '" + DToS(Date()) + " " + Time() + "')", .T.)
      oConnect:Commit()
      oConnect:Exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTINDEXES", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTINDEXES (TABLE_ CHAR(50), SIGNATURE_ CHAR(20), IDXNAME_ CHAR(64), PHIS_NAME_ CHAR(64), IDXKEY_ VARCHAR(254), IDXFOR_ VARCHAR(254), IDXCOL_ CHAR(3), TAG_ CHAR(30), TAGNUM_ CHAR(6) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED ", " ") + " INDEX " + ;
         IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTINDEX01 ON " + ;
         SR_GetToolsOwner() + "SR_MGMNTINDEXES ( TABLE_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
         "SR_MGMNTINDEX02 ON " + SR_GetToolsOwner() + "SR_MGMNTINDEXES ( IDXNAME_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES (TABLE_ CHAR(50), SIGNATURE_ CHAR(20), CREATED_ CHAR(20), TYPE_ CHAR(30), REGINFO_ CHAR(15))", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED ", " ") + " INDEX " + ;
         IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTTABLES01 ON " + SR_GetToolsOwner() + "SR_MGMNTTABLES ( TABLE_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_ CHAR(50), TARGETTABLE_ CHAR(50), CONSTRNAME_ CHAR(50), CONSTRTYPE_ CHAR(2) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + ;
         IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRAINTS01 ON " + ;
         SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_, CONSTRNAME_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), SOURCECOLUMN_ CHAR(50) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + ;
         IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRSRCCOLS01 ON " + ;
         SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), TARGETCOLUMN_ CHAR(50) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + ;
         IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTCONSTRTGTCOLS01 ON " + ;
         SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)

      // Caché - should add dual table ,like Oracle

      cRet := HB_SR__MGMNT_VERSION

   ELSEIF cStartingVersion < "MGMNT 1.03"

      oConnect:Commit()
      oConnect:Exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTTABLES (TABLE_ CHAR(50), SIGNATURE_ CHAR(20), CREATED_ CHAR(20), TYPE_ CHAR(30), REGINFO_ CHAR(15))", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
         "SR_MGMNTTABLES01 ON " + SR_GetToolsOwner() + "SR_MGMNTTABLES ( TABLE_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:Commit()

      cRet := HB_SR__MGMNT_VERSION
   ELSE
      cRet := aRet[1, 1]
   ENDIF

   IF cStartingVersion < "MGMNT 1.65"

      oConnect:Commit()
      oConnect:Exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOCKS", .F.)
      oConnect:Commit()
      oConnect:Exec("DROP TABLE " + SR_GetToolsOwner() + "SR_MGMNTLTABLES", .F.) // Table REMOVED from SQLRDD catalogs
      oConnect:Commit()

      SWITCH oConnect:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_AZURE
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ NUMERIC(6), LOGIN_TIME_ DATETIME )", .F.)
         EXIT
      CASE SYSTEMID_POSTGR
      CASE SYSTEMID_SYBASE
      CASE SYSTEMID_CACHE
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ NUMERIC(6), LOGIN_TIME_ TIMESTAMP )", .F.)
         EXIT
      CASE SYSTEMID_ORACLE
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ NUMBER(8), LOGIN_TIME_ TIMESTAMP )", .F.)
         EXIT
      CASE SYSTEMID_IBMDB2
      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
      CASE SYSTEMID_ADABAS
      CASE SYSTEMID_INGRES
      CASE SYSTEMID_INFORM
      CASE SYSTEMID_FIREBR
      CASE SYSTEMID_FIREBR3
      CASE SYSTEMID_FIREBR4
      CASE SYSTEMID_FIREBR5
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ DECIMAL(8), LOGIN_TIME_ TIMESTAMP )", .F.)
         EXIT
      OTHERWISE
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS (LOCK_ CHAR(250) NOT NULL UNIQUE, WSID_ CHAR(250) NOT NULL, SPID_ CHAR(10), LOGIN_TIME_ CHAR(50))", .F.)
      ENDSWITCH

      oConnect:Commit()
      oConnect:Exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE," CLUSTERED " ," ") + " INDEX " + ;
         IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOCKS01 ON " + ;
         SR_GetToolsOwner() + "SR_MGMNTLOCKS ( LOCK_, WSID_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
         "SR_MGMNTLOCKS02 ON " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( WSID_, LOCK_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
         "SR_MGMNTLOCKS03 ON " + SR_GetToolsOwner() + "SR_MGMNTLOCKS ( SPID_ )", .F.)
      oConnect:Commit()

      oConnect:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:Commit()

      cRet := HB_SR__MGMNT_VERSION
   ENDIF

   IF cStartingVersion < "MGMNT 1.50"

      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLANG ( TABLE_ CHAR(50), COLUMN_ CHAR(50), TYPE_ CHAR(1), LEN_ CHAR(8), DEC_ CHAR(8) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE " + IIf(oConnect:nSystemID == SYSTEMID_AZURE, " CLUSTERED " , " ") + " INDEX " + ;
         IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLANG01 ON " + ;
         SR_GetToolsOwner() + "SR_MGMNTLANG ( TABLE_, COLUMN_ )", .F.)
      oConnect:Commit()

      oConnect:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:Commit()

      cRet := HB_SR__MGMNT_VERSION
   ENDIF

   IF cStartingVersion < "MGMNT 1.60"

      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_ CHAR(50), TARGETTABLE_ CHAR(50), CONSTRNAME_ CHAR(50), CONSTRTYPE_ CHAR(2) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
         "SR_MGMNTCONSTRAINTS01 ON " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS ( SOURCETABLE_, CONSTRNAME_ )", .F.)

      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), SOURCECOLUMN_ CHAR(50) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
         "SR_MGMNTCONSTRSRCCOLS01 ON " + SR_GetToolsOwner() + ;
         "SR_MGMNTCONSTRSRCCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)

      oConnect:Commit()
      oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_ CHAR(50), CONSTRNAME_ CHAR(50), ORDER_ CHAR(02), TARGETCOLUMN_ CHAR(50) )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + ;
         "SR_MGMNTCONSTRTGTCOLS01 ON " + SR_GetToolsOwner() + ;
         "SR_MGMNTCONSTRTGTCOLS ( SOURCETABLE_, CONSTRNAME_, ORDER_ )", .F.)

      oConnect:Commit()
      oConnect:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:Commit()

      cRet := HB_SR__MGMNT_VERSION

   ENDIF

   IF cStartingVersion < "MGMNT 1.67"
      IF oConnect:nSystemID == SYSTEMID_MSSQL7 .OR. oConnect:nSystemID == SYSTEMID_AZURE
         oConnect:Exec("DROP FUNCTION dbo.trim", .F.)
         oConnect:Commit()
         oConnect:Exec("CREATE FUNCTION dbo.trim( @p1 AS CHAR  ) RETURNS CHAR BEGIN RETURN ltrim(rtrim( @p1 )) END", .F.)
         oConnect:Commit()
         oConnect:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
         oConnect:Commit()
      ENDIF
      cRet := HB_SR__MGMNT_VERSION
   ENDIF

   // MISSING: Add columns to SR_MGMNTINDEXES ( ordfor(), ordkey() )

   IF cStartingVersion < "MGMNT 1.72"

      lOld := SR_UseDeleteds(.F.)

      DBCreate("SR_MGMNTLOGCHG", { { "SPID_",        "N", 12, 0 }, ;
                                   { "WPID_",        "N", 12, 0 }, ;
                                   { "TYPE_",        "C",  2, 0 }, ;
                                   { "APPUSER_",     "C", 50, 0 }, ;
                                   { "TIME_",        "C", 25, 0 }, ;
                                   { "QUERY_",       "M", 10, 0 }, ;
                                   { "CALLSTACK_",   "C", 1000, 0}, ;
                                   { "SITE_",        "C", 20, 0 }, ;
                                   { "CONTROL_",     "C", 50, 0 }, ;
                                   { "COST_",        "N", 12, 0 } }, "SQLRDD")

      USE SR_MGMNTLOGCHG EXCLUSIVE VIA "SQLRDD" NEW
      //ordCreate("SR_MGMNTLOGCHG", "001", "SPID_ + WPID_")
      //ordCreate("SR_MGMNTLOGCHG", "002", "APPUSER_ + WPID_")
      //ordCreate("SR_MGMNTLOGCHG", "003", "TIME_ + SITE_")
      //ordCreate("SR_MGMNTLOGCHG", "004", "TYPE_ + SPID_")
      USE

      SR_UseDeleteds(lOld)

#if 0
      SWITCH oConnect:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_SYBASE
      CASE SYSTEMID_CACHE
      CASE SYSTEMID_POSTGR
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ NUMERIC(12) NOT NULL, WPID_ NUMERIC(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ TEXT, CALLSTACK_ TEXT, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_ORACLE
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ NUMERIC(12) NOT NULL, WPID_ NUMERIC(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ TEXT, CALLSTACK_ TEXT, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_IBMDB2
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ DECIMAL(12) NOT NULL, WPID_ DECIMAL(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ CLOB (64000) " + IIf("DB2/400" $ oCOnnect:cSystemName, "",  " NOT LOGGED COMPACT") + ", CALLSTACK_ CLOB (4000) " + IIf( "DB2/400" $ oCOnnect:cSystemName, "",  " NOT LOGGED COMPACT") + ", SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ BIGINT(12) NOT NULL, WPID_ BIGINT(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ MEDIUMBLOB, CALLSTACK_ MEDIUMBLOB, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_ADABAS
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ BIGINT(12) NOT NULL, WPID_ BIGINT(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ LONG, CALLSTACK_ LONG, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_INGRES
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ BIGINT(12) NOT NULL, WPID_ BIGINT(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ long varchar, CALLSTACK_ long varchar, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_INFORM
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ DECIMAL(12) NOT NULL, WPID_ DECIMAL(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ TEXT, CALLSTACK_ TEXT, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      CASE SYSTEMID_FIREBR
         oConnect:Exec("CREATE TABLE " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG (SPID_ DECIMAL(12) NOT NULL, WPID_ DECIMAL(12), TYPE_ CHAR(2), APPUSER_ CHAR(50), TIME_ CHAR(16), QUERY_ BLOB SUB_TYPE 1, CALLSTACK_ BLOB SUB_TYPE 1, SITE_ CHAR(10), FREE1_ CHAR(50) )", .F.)
         EXIT
      ENDSWITCH

      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG01 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( SPID_, WPID_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG02 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( APPUSER_, SPID_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG03 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( TIME_, SITE_ )", .F.)
      oConnect:Commit()
      oConnect:Exec("CREATE INDEX " + IIf(oConnect:nSystemID != SYSTEMID_ORACLE, "", SR_GetToolsOwner()) + "SR_MGMNTLOGCHG04 ON " + SR_GetToolsOwner() + "SR_MGMNTLOGCHG ( TYPE_, TIME_ )", .F.)
      oConnect:Commit()
#endif

      oConnect:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTVERSION SET VERSION_ = '" + HB_SR__MGMNT_VERSION + "'")
      oConnect:Commit()

      cRet := HB_SR__MGMNT_VERSION

   ENDIF

   oConnect:cMgmntVers := cRet

   // Setup multilang hash

   SR_ReloadMLHash(oConnect)

RETURN cRet

//-------------------------------------------------------------------------------------------------------------------//

STATIC FUNCTION SR_SetEnvMinimal(oConnect)

   LOCAL aRet := {}
   LOCAL cRet := "0"
   LOCAL oCnn

   oCnn := oConnect

   SWITCH oCnn:nSystemID

   CASE SYSTEMID_ORACLE
      oCnn:Exec("ALTER SESSION SET NLS_LANGUAGE=AMERICAN", .F.)
      oCnn:Exec("ALTER SESSION SET NLS_SORT=BINARY", .F.)
      oCnn:Exec("ALTER SESSION SET NLS_NUMERIC_CHARACTERS='.,'", .F.)
      IF oCnn:cCharSet != NIL
         oCnn:Exec("ALTER SESSION SET NLS_CHARACTERSET=" + oCnn:cCharSet, .F.)
      ENDIF
      IF oCnn:lNative
         oCnn:Exec("ALTER SESSION SET NLS_DATE_FORMAT='yyyymmdd'", .F.)
         oCnn:Exec("ALTER SESSION SET NLS_TIMESTAMP_FORMAT='yyymmdd HH.MI.SSXFF AM'", .F.)
      ENDIF
      EXIT

   CASE SYSTEMID_INGRES
      oCnn:Commit()
      oCnn:Exec("set lockmode session where readlock=nolock,level=row")
      EXIT

   CASE SYSTEMID_SYBASE
      //oCnn:Commit()
      //oCnn:Exec("SET CHAINED ON")
      oCnn:Commit()
      oCnn:Exec("SET QUOTED_IDENTIFIER ON")
      oCnn:Exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
      EXIT

   CASE SYSTEMID_MSSQL7
   CASE SYSTEMID_MSSQL6
   CASE SYSTEMID_AZURE
      oCnn:Commit()
      oCnn:Exec("SET QUOTED_IDENTIFIER ON")
      oCnn:Exec("SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED")
      oCnn:Commit()
      EXIT

   CASE SYSTEMID_MYSQL
   CASE SYSTEMID_MARIADB
      oCnn:Exec("set session autocommit=0;", .F.)
      oCnn:Exec("SET SESSION TRANSACTION ISOLATION LEVEL READ UNCOMMITTED", .F.)
      EXIT

   CASE SYSTEMID_CACHE
      oCnn:Exec("SET OPTION SUPPORT_DELIMITED_IDENTIFIERS=TRUE")
      oCnn:Commit()
      EXIT

   CASE SYSTEMID_POSTGR
      oCnn:Exec("SET CLIENT_ENCODING to 'SQL_ASCII'", .F., .T., @aRet)
      oCnn:Commit()
      EXIT

   ENDSWITCH

RETURN cRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ReloadMLHash(oConnect)

   LOCAL aRet := {}
   LOCAL aCol

   oConnect:Exec("SELECT TABLE_ , COLUMN_, TYPE_, LEN_, DEC_ FROM " + SR_GetToolsOwner() + ;
      "SR_MGMNTLANG", .F., .T., @aRet)
   oConnect:Commit()

   s_hMultilangColumns := hb_Hash()
   hb_HAllocate(s_hMultilangColumns, Max(10, Len(aRet)))

   FOR EACH aCol IN aRet
      s_hMultilangColumns[aCol[1] + aCol[2]] := aCol
   NEXT

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION AddToMLHash(aField)

   s_hMultilangColumns[PadR(aField[1], 50) + PadR(aField[2], 50)] := aField

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION GetMLHash(cTab, cCol)

   LOCAL cKey := PadR(Upper(cTab), 50) + PadR(Upper(cCol), 50)
   LOCAL nPos := hb_HPos(s_hMultilangColumns, cKey)

   IF nPos > 0
      RETURN hb_HValueAt(s_hMultilangColumns, nPos)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ErrorOnGotoToInvalidRecord(l)

   LOCAL lOld := s_lErrorOnGotoToInvalidRecord

   IF l != NIL
      s_lErrorOnGotoToInvalidRecord := l
   ENDIF

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_UseNullsFirst(l)

   LOCAL lOld := s_lUseNullsFirst

   IF l != NIL
      s_lUseNullsFirst := l
   ENDIF

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_TblMgmnt()
RETURN s_lTblMgmnt

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetTblMgmnt(lOpt)

   LOCAL lOld := s_lTblMgmnt

   s_lTblMgmnt := lOpt

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_EvalFilters(lEval)

   LOCAL lOld := s_EvalFilters

   If lEval != NIL
      s_EvalFilters := lEval
   EndIf

RETURN lOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_RecnoName(cName)

   LOCAL cOld := s_RecnoName

   IF cName != NIL
      s_RecnoName := Upper(AllTrim(cName))
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_MaxRowCache(n)

   LOCAL cOld := s_nMaxRowCache

   IF n != NIL
      s_nMaxRowCache := n
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_FetchSize(n)

   LOCAL cOld := s_nFetchSize

   IF n != NIL
      s_nFetchSize := n
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_DeletedName(cName)

   LOCAL cOld := s_DeletedName

   IF cName != NIL
      s_DeletedName := Upper(AllTrim(cName))
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ExistTable(cTableName, cOwner, oCnn)

   LOCAL cFileName
   LOCAL nRet
   LOCAL aRet

   DEFAULT oCnn TO SR_GetConnection()
   aRet := Eval(SR_GetTableInfoBlock(), cTableName)

   IF cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      IF !Empty(SR_GetGlobalOwner())
         cOwner := AllTrim(SR_GetGlobalOwner())
      ELSEIF !Empty(oCnn:cOwner)
         cOwner := AllTrim(oCnn:cOwner)
      ELSEIF cOwner == NIL
         cOwner := ""
      ENDIF
   ENDIF

   IF (!Empty(cOwner)) .AND. Right(cOwner, 1) != "."
      cOwner += "."
   ENDIF

   cFileName := SR_ParseFileName(AllTrim(aRet[TABLE_INFO_TABLE_NAME]))

   IF oCnn:oSqlTransact == NIL
      nRet := oCnn:Exec("SELECT * FROM " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + " WHERE 0 = 2", .F.)
      oCnn:Commit()
   ELSE
      nRet := oCnn:oSqlTransact:Exec("SELECT * FROM " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + " WHERE 0 = 2", .F.)
      oCnn:oSqlTransact:Commit()
   ENDIF

   IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO .OR. nRet == SQL_NO_DATA_FOUND
      RETURN .T.
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ExistIndex(cIndexName, cOwner)

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}

   HB_SYMBOL_UNUSED(cOwner)

   oCnn := SR_GetConnection()

   aRet := Eval(SR_GetIndexInfoBlock(), cIndexName)
   ASize(aRet, TABLE_INFO_SIZE)

   cIndexName := SR_ParseFileName(aRet[TABLE_INFO_TABLE_NAME])

   aRet := {}
   nRet := oCnn:Exec("SELECT * FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE IDXNAME_ = '" + ;
      Upper(AllTrim(cIndexName)) + "'", .F., .T., @aRet)

   IF (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. Len(aRet) > 0
      RETURN .T.
   ENDIF

RETURN .F.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_File(cTableName)

   LOCAL cTbl := Lower(cTableName)

   DO CASE
   CASE ".dbf" $ cTbl .OR. ".dbt" $ cTbl
      RETURN SR_ExistTable(cTableName)
   CASE ".ntx" $ cTbl .OR. ".cdx" $ cTbl
      RETURN SR_ExistIndex(cTableName)
   ENDCASE

RETURN SR_ExistTable(cTableName) .OR. SR_ExistIndex(cTableName)

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_EndConnection(nConnection)

   LOCAL oCnn
   LOCAL uRet

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}

   SR_CheckConnection(nConnection)

   IF nConnection > Len(s_aConnections) .OR. nConnection == 0 .OR. nConnection < 0
      RETURN NIL
   ENDIF

   oCnn := s_aConnections[nConnection]

   IF nConnection == Len(s_aConnections)
      ASize(s_aConnections, Len(s_aConnections) - 1)
   ELSE
      s_aConnections[nConnection] := NIL
   ENDIF

   IF oCnn != NIL
      IF oCnn:oSqlTransact != NIL
         oCnn:oSqlTransact:RollBack()
         oCnn:oSqlTransact:end()
      ENDIF
      uRet := oCnn:end()
   ENDIF

   s_nActiveConnection := Len(s_aConnections)

RETURN uRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetConnectionInfo(nConnection, nInfo)

   LOCAL oCnn

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
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

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_StartLog(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}
   SR_CheckConnection(nConnection)
   s_aConnections[nConnection]:lTraceToDBF := .T.
   IF s_aConnections[nConnection]:oSqlTransact != NIL
      s_aConnections[nConnection]:oSqlTransact:lTraceToDBF := .T.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_StartTrace(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}
   SR_CheckConnection(nConnection)
   s_aConnections[nConnection]:lTraceToScreen := .T.
   IF s_aConnections[nConnection]:oSqlTransact != NIL
      s_aConnections[nConnection]:oSqlTransact:lTraceToScreen := .T.
   ENDIF

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_StopLog(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}
   SR_CheckConnection(nConnection)
   s_aConnections[nConnection]:lTraceToDBF := .F.
   IF s_aConnections[nConnection]:oSqlTransact != NIL
      s_aConnections[nConnection]:oSqlTransact:lTraceToDBF := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_StopTrace(nConnection)

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}
   SR_CheckConnection(nConnection)
   s_aConnections[nConnection]:lTraceToScreen := .F.
   IF s_aConnections[nConnection]:oSqlTransact != NIL
      s_aConnections[nConnection]:oSqlTransact:lTraceToScreen := .F.
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetTimeTrace(nConnection, nMilisseconds)

   LOCAL nOld

   DEFAULT s_nActiveConnection TO 0
   DEFAULT nConnection TO s_nActiveConnection
   DEFAULT s_aConnections TO {}
   SR_CheckConnection(nConnection)
   DEFAULT nMilisseconds TO s_aConnections[nConnection]:nTimeTraceMin
   nOld := s_aConnections[nConnection]:nTimeTraceMin
   s_aConnections[nConnection]:nTimeTraceMin := nMilisseconds

   HB_SYMBOL_UNUSED(nOld)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

Procedure SR_End()

   DEFAULT s_aConnections TO {}
   DO WHILE Len(s_aConnections) > 0
      SR_EndConnection(Len(s_aConnections))
   ENDDO

Return

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION _SR_UnRegister(oWA)

   LOCAL aActiveWAs
   LOCAL n

   aActiveWAs := oWa:oSql:oHashActiveWAs:Find(oWA:cFileName)

   IF HB_IsArray(aActiveWAs)
      DO WHILE (n := AScan(aActiveWAs, {|x|x:nThisArea == oWA:nThisArea})) > 0
         ADel(aActiveWAs, n)
         ASize(aActiveWAs, Len(aActiveWAs) - 1)
      ENDDO
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION _SR_Register(oWA)

   LOCAL aActiveWAs

   aActiveWAs := oWa:oSql:oHashActiveWAs:Find(oWA:cFileName)

   IF HB_IsArray(aActiveWAs)
      AAdd(aActiveWAs, oWA)
   ELSE
      oWa:oSql:oHashActiveWAs:Insert(oWA:cFileName, {oWA})
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION _SR_ScanExec(oWA, bExpr)

   LOCAL aActiveWAs := oWa:oSql:oHashActiveWAs:Find(oWA:cFileName)

   IF HB_IsArray(aActiveWAs)
      AEval(aActiveWAs, bExpr)
   ENDIF

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION _SR_ScanExecAll(bExpr)

   SR_GetConnection():oHashActiveWAs:Haeval(bExpr)

RETURN NIL

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetUniqueSystemID()

   LOCAL i1
   LOCAL i2

   i1 := HB_RANDOMINT(1, 99999999 )
   i2 := HB_RANDOMINT(1, 99999999 )

RETURN AllTrim(SR_Val2Char(SR_GetCurrInstanceID())) + "__" + StrZero(i1, 8) + "__" + StrZero(i2, 8)

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetInternalID()

   LOCAL i1
   LOCAL i2

   IF s_cIntenalID != NIL
      RETURN s_cIntenalID
   ENDIF

   i1 := HB_RANDOMINT(1, 99999999 )
   i2 := HB_RANDOMINT(1, 99999999 )

   s_cIntenalID := AllTrim(SR_Val2Char(SR_GetCurrInstanceID())) + "__" + StrZero(i1, 8) + "__" + StrZero(i2, 8)

RETURN s_cIntenalID

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetCollation(cName)

   LOCAL cOld := s_cCollation

   IF HB_IsChar(cName)
      s_cCollation := cName
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

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

   HB_SYMBOL_UNUSED(ctempIndex)

   oCnn := SR_GetConnection()

   aRet := Eval(SR_GetIndexInfoBlock(), cIndexName)
   ctempIndex := cIndexName
   cIndexName := SR_ParseFileName(AllTrim(aRet[TABLE_INFO_TABLE_NAME]))

   IF cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      IF !Empty(SR_GetGlobalOwner())
         cOwner := AllTrim(SR_GetGlobalOwner())
      ELSEIF !Empty(oCnn:cOwner)
         cOwner := AllTrim(oCnn:cOwner)
      ELSEIF cOwner == NIL
         cOwner := ""
      ENDIF
   ENDIF

   IF (!Empty(cOwner)) .AND. Right(cOwner, 1) != "."
      cOwner += "."
   ENDIF

   aRet := {}
   nRet := oCnn:Exec("SELECT TABLE_, PHIS_NAME_, IDXNAME_, IDXCOL_, IDXFOR_, IDXKEY_ FROM " + SR_GetToolsOwner() + ;
      "SR_MGMNTINDEXES WHERE IDXNAME_ = '" + Upper(AllTrim(cIndexName)) + "'", .F., .T., @aRet)
   IF (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. Len(aRet) == 0
      // Index does not exist
      aRet := {}
      nRet := oCnn:Exec("SELECT TABLE_, PHIS_NAME_, IDXNAME_, IDXCOL_, IDXFOR_, IDXKEY_ FROM " + SR_GetToolsOwner() + ;
         "SR_MGMNTINDEXES WHERE PHIS_NAME_ = '" + Upper(AllTrim(cIndexName)) + "'", .F., .T., @aRet)
      IF (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. Len(aRet) == 0
         aRet := {}
         nRet := oCnn:Exec("SELECT TABLE_, PHIS_NAME_, IDXNAME_, IDXCOL_, IDXFOR_, IDXKEY_ FROM " + ;
            SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TAG_ = '" + AllTrim(ctempIndex) + "'", .F., .T., @aRet)
         IF (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. Len(aRet) == 0
            RETURN .F.
         ELSE
            lTag := .T.
         ENDIF
      ENDIF
   ENDIF

   cFileName := RTrim(aRet[1, 1])
   cIndex := RTrim(aRet[1, 2])
   cIdxName := RTrim(aRet[1, 3])
   IF lTag
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + cFileName + ;
         "' AND PHIS_NAME_ = '" + cIndex + "'" + IIf(oCnn:lComments, " /* Wipe index info */", ""), .F.)
   ELSE
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + cFileName + ;
         "' AND IDXNAME_ = '" + cIdxName + "'" + IIf(oCnn:lComments, " /* Wipe index info */", ""), .F.)
   ENDIF
   oCnn:Commit()

   FOR EACH aIndex IN aRet
      cPhisicalName := RTrim(aIndex[2])

      SWITCH oCnn:nSystemID
      CASE SYSTEMID_MSSQL6
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_SYBASE
      CASE SYSTEMID_AZURE
         oCnn:Exec("DROP INDEX " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + "." + cPhisicalName, .F.)
         EXIT
      CASE SYSTEMID_MYSQL
      CASE SYSTEMID_MARIADB
         oCnn:Exec("DROP INDEX " + cPhisicalName + " ON " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + ;
            IIf(oCnn:lComments, " /* DROP Index */", ""), .F.)
         EXIT
      CASE SYSTEMID_ORACLE
         IF Len(aIndex[6]) > 4 .AND. SubStr(aIndex[6], 4, 1) == "@"
            oCnn:Exec("DROP INDEX " + cOwner + "A$" + SubStr(aIndex[6], 1, 3) + SubStr(cFileName, 1, 25) + ;
               IIf(oCnn:lComments, " /* Drop VIndex */", ""), .F.)
            oCnn:Commit()
            oCnn:Exec("DROP INDEX " + cOwner + "D$" + SubStr(aIndex[6], 1, 3) + SubStr(cFileName, 1, 25) + ;
               IIf(oCnn:lComments, " /* Drop VIndex */", ""), .F.)
            oCnn:Commit()
         ENDIF
         oCnn:Exec("DROP INDEX " + cPhisicalName + IIf(oCnn:lComments, " /* DROP Index */", ""), .F.)
         EXIT
      OTHERWISE
         oCnn:Exec("DROP INDEX " + cPhisicalName + IIf(oCnn:lComments, " /* DROP Index */", ""), .F.)
      ENDSWITCH

      IF (!Empty(aIndex[4])) .OR. SubStr(aIndex[5], 1, 1) == "#"
         USE (cFileName) NEW VIA "SQLRDD" ALIAS "TEMPDROPCO" exclusive
         oWA := TEMPDROPCO->(dbInfo(DBI_INTERNAL_OBJECT))

         IF !Empty(aIndex[4])
            oWA:DropColumn("INDKEY_" + AllTrim(aIndex[4]), .F.)
         ENDIF
         IF SubStr(aIndex[5], 1, 1) == "#"
            oWA:DropColumn("INDFOR_" + SubStr(aIndex[5], 2, 3), .F.)
         ENDIF

         TEMPDROPCO->(DBCloseArea())
      ENDIF
   NEXT

   oCnn:Commit()
   SR_CleanTabInfoCache()

RETURN .T.

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_DropTable(cFileName, cOwner)

   LOCAL oCnn
   LOCAL lRet
   LOCAL aRet := {}

   HB_SYMBOL_UNUSED(aRet)

   oCnn := SR_GetConnection()

   aRet := Eval(SR_GetTableInfoBlock(), cFileName)
   cFileName := SR_ParseFileName(AllTrim(aRet[TABLE_INFO_TABLE_NAME]))

   IF cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      IF !Empty(SR_GetGlobalOwner())
         cOwner := AllTrim(SR_GetGlobalOwner())
      ELSEIF !Empty(oCnn:cOwner)
         cOwner := AllTrim(oCnn:cOwner)
      ELSEIF cOwner == NIL
         cOwner := ""
      ENDIF
   ENDIF

   IF (!Empty(cOwner)) .AND. Right(cOwner, 1) != "."
      cOwner += "."
   ENDIF

   // Drop the table

   lRet := oCnn:Exec("DROP TABLE " + cOwner + SR_DBQUALIFY(cFileName, oCnn:nSystemID) + ;
      IIf(oCnn:nSystemID == SYSTEMID_ORACLE, " CASCADE CONSTRAINTS", "") + ;
      IIf(oCnn:lComments, " /* drop table */", ""), .T.) == SQL_SUCCESS
   oCnn:Commit()

   IF lRet
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + ;
         Upper(cFileName) + "'" + IIf(oCnn:lComments, " /* Wipe index info */", ""), .F.)
      oCnn:Commit()
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES WHERE TABLE_ = '" + ;
         Upper(cFileName) + "'" + IIf(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTLANG WHERE TABLE_ = '" + ;
         Upper(cFileName) + "'" + IIf(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS WHERE TABLE_ = '" + ;
         Upper(cFileName) + "'" + IIf(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRAINTS WHERE SOURCETABLE_ = '" + ;
         Upper(cFileName) + "'" + IIf(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRTGTCOLS WHERE SOURCETABLE_ = '" + ;
         Upper(cFileName) + "'" + IIf(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
      oCnn:Exec("DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTCONSTRSRCCOLS WHERE SOURCETABLE_ = '" + ;
         Upper(cFileName) + "'" + IIf(oCnn:lComments, " /* Wipe table info */", ""), .F.)
      oCnn:Commit()
   ENDIF

RETURN lRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ListIndex(cFilename)

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}
   LOCAL i

   oCnn := SR_GetConnection()

   aRet := Eval(SR_GetIndexInfoBlock(), cFilename)
   cFilename := SR_ParseFileName(AllTrim(aRet[TABLE_INFO_TABLE_NAME]))

   aRet := {}
   nRet := oCnn:Exec("SELECT IDXNAME_,PHIS_NAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_ FROM " + SR_GetToolsOwner() + ;
      "SR_MGMNTINDEXES WHERE TABLE_ = '" + AllTrim(Upper(cFilename)) + "'", .F., .T., @aRet)

   FOR i := 1 TO Len(aRet)
      aRet[i, 1] := AllTrim(aRet[i, 1])
   NEXT i

   HB_SYMBOL_UNUSED(nRet)

RETURN aRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_RenameTable(cTable, cNewName, cOwner)

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}
   LOCAL lOk := .F.

   oCnn := SR_GetConnection()

   aRet := Eval(SR_GetTableInfoBlock(), cTable)
   cTable := SR_ParseFileName(AllTrim(aRet[TABLE_INFO_TABLE_NAME]))

   IF cOwner == NIL
      cOwner := aRet[TABLE_INFO_OWNER_NAME]
      IF !Empty(SR_GetGlobalOwner())
         cOwner := AllTrim(SR_GetGlobalOwner())
      ELSEIF !Empty(oCnn:cOwner)
         cOwner := AllTrim(oCnn:cOwner)
      ELSEIF cOwner == NIL
         cOwner := ""
      ENDIF
   ENDIF

   IF (!Empty(cOwner)) .AND. Right(cOwner, 1) != "."
      cOwner += "."
   ENDIF

   aRet := Eval(SR_GetTableInfoBlock(), cNewName)
   cNewName := SR_ParseFileName(AllTrim(aRet[TABLE_INFO_TABLE_NAME]))

   aRet := {}
   nRet := oCnn:Exec("SELECT * FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES WHERE TABLE_ = '" + ;
      Upper(cTable) + "'", .F., .T., @aRet)
   IF (nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO) .AND. Len(aRet) == 0
      // Table does not exist
      RETURN .F.
   ENDIF

   aRet := {}
   nRet := oCnn:Exec("SELECT * FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES WHERE TABLE_ = '" + ;
      Upper(cNewName) + "'", .F., .T., @aRet)
   HB_SYMBOL_UNUSED(nRet)
   IF Len(aRet) > 0
      // Destination EXISTS !!
      RETURN .F.
   ENDIF

   SWITCH oCnn:nSystemID
   CASE SYSTEMID_MSSQL7
   CASE SYSTEMID_AZURE
      nRet := oCnn:Exec("exec sp_rename " + cOwner + cTable + ", " + cOwner + cNewName, .F.)
      IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
         lOk := .T.
      ENDIF
      EXIT
   CASE SYSTEMID_POSTGR
   CASE SYSTEMID_ORACLE
   CASE SYSTEMID_MYSQL
   CASE SYSTEMID_MARIADB
      IF oCnn:nSystemID == SYSTEMID_POSTGR
         nRet := oCnn:Exec("ALTER TABLE " + cOwner + SR_DBQUALIFY(cTable + "_sq", oCnn:nSystemID) + ;
            " RENAME TO " + cOwner + SR_DBQUALIFY(cNewName+"_sq", oCnn:nSystemID), .F.)
         HB_SYMBOL_UNUSED(nRet)
      ENDIF

      nRet := oCnn:Exec("ALTER TABLE " + cOwner + SR_DBQUALIFY(cTable, oCnn:nSystemID) + ;
         " RENAME TO " + cOwner + SR_DBQUALIFY(cNewName, oCnn:nSystemID), .F.)
      IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
         lOk := .T.
      ENDIF

      IF oCnn:nSystemID == SYSTEMID_POSTGR
         nRet := oCnn:Exec("ALTER TABLE " + cOwner + SR_DBQUALIFY(cNewName, oCnn:nSystemID) + ;
            " ALTER COLUMN " + SR_RecnoName() + " SET DEFAULT nextval('" + Lower(cNewName) + "_sq'::regclass)")
         HB_SYMBOL_UNUSED(nRet)
      ENDIF
      IF oCnn:nSystemID == SYSTEMID_ORACLE
         nRet := oCnn:Exec("RENAME " + cOwner + cTable + "_sq" + " TO " + cOwner + cNewName + "_sq", .F.)
         HB_SYMBOL_UNUSED(nRet)
      ENDIF
      EXIT

   ENDSWITCH

   IF lOk
      oCnn:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTINDEXES SET TABLE_ = '" + cNewName + ;
         "' WHERE TABLE_ = '" + cTable + "'", .F.)
      oCnn:Exec("UPDATE " + SR_GetToolsOwner() + "SR_MGMNTTABLES SET TABLE_ = '" + cNewName + ;
         "' WHERE TABLE_ = '" + cTable + "'", .F.)
      oCnn:Commit()
   ENDIF

RETURN lOk

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ListTables(cOwner)

RETURN (SR_GetConnection()):ListCatTables(cOwner)

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ListCreatedTables()

   LOCAL oCnn
   LOCAL nRet
   LOCAL aRet := {}
   LOCAL aRet2 := {}

   oCnn := SR_GetConnection()
   nRet := oCnn:Exec("SELECT TABLE_ FROM " + SR_GetToolsOwner() + "SR_MGMNTTABLES", .F., .T., @aRet)

   AEval(aRet, {|x|AAdd(aRet2, AllTrim(x[1])) })

   HB_SYMBOL_UNUSED(nRet)

RETURN aRet2

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetToolsOwner(cOwner)

   LOCAL cOld := s_cToolsOwner
   LOCAL oSql

   IF cOwner != NIL
      s_cToolsOwner := cOwner
      IF (!Empty(cOwner)) .AND. Right(s_cToolsOwner, 1) != "."
         s_cToolsOwner += "."
      ENDIF
   ELSE
      IF Empty(s_cToolsOwner)
         oSql := SR_GetConnection()
         IF !Empty(oSql:cOwner)
            RETURN oSql:cOwner
         ENDIF
      ENDIF
   ENDIF

RETURN cOld

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_GetToolsOwner()

   LOCAL oSql

   IF Empty(s_cToolsOwner)
      oSql := SR_GetConnection()
      IF !Empty(oSql:cOwner)
         RETURN oSql:cOwner
      ENDIF
   ENDIF

RETURN s_cToolsOwner

//-------------------------------------------------------------------------------------------------------------------//

// SQLRDD Exclusive Lock management and Lock behavior
// --------------------------------------------------
//
// We use internally 2 different connections to manage locks.
// Connection information:
//
// 1 - Transactional connection (regular queries)
// 2 - Autocommit connection (used for counters and "one query" transactions)
//
// SetLocks function steps, using SQLRDD system table SR_MGMNTLOCKS:
//
// * For Microsoft SQL Server:
// ---------------------------
//
// At application startup, perform the following housekeeping routine:
//
// "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ = @@SPID OR SPID_ + LOGIN_TIME_ NOT IN (SELECT SPID + LOGIN_TIME FROM MASTER.DBO.SYSPROCESSES)"
//
// 1 - Try to INSERT the string to be locked using connection 2; Commit;
// 2 - If success, LOCK is acquired
// 3 - If it fails, run housekeeping "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (SELECT SPID FROM MASTER.DBO.SYSPROCESSES)"; Commit;
// 4 - Try INSERT again;
// 5 - If succefull, lock is acquired;
// 6 - If not succefull, lock is denied;
//
// * For Oracle:
// -------------
//
// Housekeeping expression is:
// "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ = sys_context('USERENV','sessionid') OR SPID_ NOT IN (select "AUDSID" from v$session)"
//
// Step 3 query is:
// "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (select "AUDSID" from v$session)"; Commit;
//
// * For Postgres:
// ---------------
//
// Housekeeping expression is:
// "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ = (select pg_backend_pid()) OR SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))"
//
// Step 3 query is:
// "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))"; Commit;
//
//
// ReleaseLocks function steps:
//
// 1 - Delete the line using connection 2; Commit;

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_SetLocks(uLocks, oCnn, nRetries)

   LOCAL lRet := .T.
   LOCAL aLocks
   LOCAL cSql
   LOCAL cValue
   LOCAL aAdded := {}
   LOCAL nRet
   LOCAL cIns
   LOCAL cDel

   DEFAULT oCnn TO SR_GetConnection()
   DEFAULT nRetries TO 0

   IF oCnn:oSqlTransact == NIL
      RETURN .T.
   ENDIF

   DO CASE
   CASE HB_IsChar(uLocks)
      aLocks := {uLocks}
   CASE HB_IsArray(uLocks)
      aLocks := uLocks
   OTHERWISE
      aLocks := {SR_Val2Char(uLocks)}
   ENDCASE

   FOR EACH cValue IN aLocks

      cValue := SR_Val2Char(cValue)

      SWITCH oCnn:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_AZURE
         cIns := "INSERT INTO " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS ( LOCK_, WSID_, SPID_, LOGIN_TIME_ ) VALUES ( '" + cValue + "', '" + SR_GetInternalID() + ;
            "', @@SPID, '" + oCnn:oSqlTransact:cLoginTime + "' )"
         cDel := "DELETE FROM SR_MGMNTLOCKS WHERE convert( CHAR(10), SPID_ ) + convert( CHAR(23), LOGIN_TIME_, 21 ) NOT IN (SELECT convert( CHAR(10), SPID) + CONVERT( CHAR(23), LOGIN_TIME, 21 ) FROM MASTER.DBO.SYSPROCESSES)"
         EXIT
      CASE SYSTEMID_ORACLE
         cIns := "INSERT INTO " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS ( LOCK_, WSID_, SPID_ ) VALUES ( '" + cValue + "', '" + SR_GetInternalID() + ;
            "', " + Str(oCnn:uSid) + " )"
         cDel := "DELETE FROM SR_MGMNTLOCKS WHERE SPID_ NOT IN (select " + Chr(34) + "AUDSID" + Chr(34) + " from " + ;
            IIf(oCnn:lCluster, "g", "") + "v$session)"
         EXIT
      CASE SYSTEMID_POSTGR
         cIns := "INSERT INTO " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS ( LOCK_, WSID_, SPID_ ) VALUES ( '" + cValue + "', '" + SR_GetInternalID() + ;
            "', (select pg_backend_pid()) )"
         cDel := "DELETE FROM " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS WHERE SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))"
         EXIT
      CASE SYSTEMID_IBMDB2
         EXIT
      ENDSWITCH

      nRet := oCnn:oSqlTransact:Exec(cIns, .F.)
      oCnn:oSqlTransact:Commit()

      IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
         oCnn:oSqlTransact:Exec(cDel, .F.)
         oCnn:oSqlTransact:Commit()
         nRet := oCnn:oSqlTransact:Exec(cIns, .F.)
         oCnn:oSqlTransact:Commit()

         IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
            DO WHILE nRetries > 0
               oCnn:oSqlTransact:Exec(cDel, .F.)
               oCnn:oSqlTransact:Commit()
               nRet := oCnn:oSqlTransact:Exec(cIns, .F.)
               oCnn:oSqlTransact:Commit()

               IF nRet != SQL_SUCCESS .AND. nRet != SQL_SUCCESS_WITH_INFO
                  Inkey(.5)
                  nRetries--
               ELSE
                  EXIT
               ENDIF
            ENDDO
         ENDIF
      ENDIF

      IF nRet == SQL_SUCCESS .OR. nRet == SQL_SUCCESS_WITH_INFO
         AAdd(aAdded, cValue)
      ELSE
         lRet := .F.
         EXIT
      ENDIF
   NEXT

   IF !lRet
      FOR EACH cValue IN aAdded
         SWITCH oCnn:nSystemID
         CASE SYSTEMID_MSSQL7
         CASE SYSTEMID_ORACLE
         CASE SYSTEMID_POSTGR
         CASE SYSTEMID_IBMDB2
         CASE SYSTEMID_AZURE
            cSql := "DELETE FROM " + SR_GetToolsOwner() + ;
               "SR_MGMNTLOCKS WHERE LOCK_ = '" + cValue + "' AND WSID_ = '" + SR_GetInternalID() + "'"
            EXIT
         ENDSWITCH
         oCnn:oSqlTransact:Exec(cSql, .F.)
         oCnn:oSqlTransact:Commit()
      NEXT
   ENDIF

RETURN lRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ReleaseLocks(uLocks, oCnn)

   LOCAL lRet := .T.
   LOCAL aLocks
   LOCAL cValue
   LOCAL cSql

   DEFAULT oCnn TO SR_GetConnection()

   IF oCnn:oSqlTransact == NIL
      RETURN .F.
   ENDIF

   DO CASE
   CASE HB_IsChar(uLocks)
      aLocks := {uLocks}
   CASE HB_IsArray(uLocks)
      aLocks := uLocks
   OTHERWISE
      aLocks := {SR_Val2Char(uLocks)}
   ENDCASE

   FOR EACH cValue IN aLocks
      cValue := SR_Val2Char(cValue)
      SWITCH oCnn:nSystemID
      CASE SYSTEMID_MSSQL7
      CASE SYSTEMID_ORACLE
      CASE SYSTEMID_POSTGR
      CASE SYSTEMID_IBMDB2
      CASE SYSTEMID_AZURE
         cSql := "DELETE FROM " + SR_GetToolsOwner() + ;
            "SR_MGMNTLOCKS WHERE LOCK_ = '" + cValue + "' AND WSID_ = '" + SR_GetInternalID() + "'"
         EXIT
      ENDSWITCH

      oCnn:oSqlTransact:Exec(cSql, .T.)
      oCnn:oSqlTransact:Commit()
   NEXT

RETURN lRet

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_ListLocks(oCnn, lAll)

   LOCAL aLocks := {}

   DEFAULT oCnn TO SR_GetConnection()
   DEFAULT lAll TO .F.

   IF oCnn:oSqlTransact == NIL
      RETURN {}
   ENDIF

   // Housekeeping to avoid wrong info

   SWITCH oCnn:oSqlTransact:nSystemID
   CASE SYSTEMID_ORACLE
      oCnn:oSqlTransact:Exec("DELETE FROM " + SR_GetToolsOwner() + ;
         "SR_MGMNTLOCKS WHERE SPID_ NOT IN (select " + Chr(34) + "SID" + Chr(34) + " from " + ;
         IIf(oCnn:lCluster, "g", "") + "v$session)", .F.)
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
      oCnn:oSqlTransact:Exec("DELETE FROM " + SR_GetToolsOwner() + ;
         "SR_MGMNTLOCKS WHERE convert( CHAR(10), SPID_ ) + convert( CHAR(23), LOGIN_TIME_, 21 ) NOT IN (SELECT convert( CHAR(10), SPID) + CONVERT( CHAR(23), LOGIN_TIME, 21 ) FROM MASTER.DBO.SYSPROCESSES)", .F.)
      EXIT
   CASE SYSTEMID_MYSQL
   CASE SYSTEMID_MARIADB
      EXIT
   CASE SYSTEMID_POSTGR
      oCnn:oSqlTransact:Exec("DELETE FROM  " + SR_GetToolsOwner() + ;
         "SR_MGMNTLOCKS WHERE SPID_ NOT IN (select pg_stat_get_backend_pid(pg_stat_get_backend_idset()))", .F.)
      EXIT
   ENDSWITCH

   oCnn:oSqlTransact:Commit()
   oCnn:oSqlTransact:Exec("SELECT LOCK_, WSID_, SPID_ FROM " + SR_GetToolsOwner() + ;
      "SR_MGMNTLOCKS" + IIf(lAll, " WHERE WSID_ = '" + SR_GetInternalID() + "'", ""), .F., .T., @aLocks)

RETURN aLocks

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION DetectDBFromDSN(cConnect)

RETURN SR_DetectDBFromDSN(cConnect)

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_DetectDBFromDSN(cConnect)

   LOCAL aItem
   LOCAL cBuff
   LOCAL aToken
   LOCAL aCon := hb_atokens(cConnect,";")

   FOR EACH aItem IN aCon
      aToken := hb_atokens(aItem,"=")
      cBuff := Upper(aToken[1])
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
      CASE "FB4"
      CASE "FIREBIRD4"
         RETURN CONNECT_FIREBIRD4
      CASE "FB5"
      CASE "FIREBIRD5"
         RETURN CONNECT_FIREBIRD5
      CASE "DSN"
      CASE "DRIVER"
         RETURN CONNECT_ODBC
      ENDSWITCH
   NEXT

RETURN SYSTEMID_UNKNOW

//-------------------------------------------------------------------------------------------------------------------//

#pragma BEGINDUMP

#include "compat.h"

static HB_BOOL s_fMultiLang = HB_FALSE;
static HB_BOOL s_fShutDown = HB_FALSE;
static HB_BOOL s_fGoTopOnScope = HB_TRUE;
static HB_BOOL s_fSerializedAsString = HB_FALSE;
static HB_BOOL s_fHideRecno = HB_TRUE;
static HB_BOOL s_fHideHistoric = HB_FALSE;
static HB_BOOL s_fUseDeleteds = HB_TRUE;
// Culik added new global to tell if we will serialize arrays as json or xml
static HB_BOOL s_fSerializeArrayAsJson = HB_FALSE;
// Culik added new global to tell if we are using sqlverser 2008 or newer
static HB_BOOL s_fSql2008newTypes = HB_FALSE;

static HB_BOOL s_iOldPgsBehavior = HB_FALSE;
static HB_BOOL s_fShortasNum = HB_FALSE;

HB_BOOL HB_EXPORT sr_isMultilang(void)
{
  return s_fMultiLang;
}

HB_FUNC(SR_SETMULTILANG)
{
  hb_retl(s_fMultiLang);
  if (HB_ISLOG(1))
  {
    s_fMultiLang = hb_parl(1);
  }
}

HB_BOOL HB_EXPORT sr_isShutdownProcess(void)
{
  return s_fShutDown;
}

HB_FUNC(SR_SETSHUTDOWN)
{
  hb_retl(s_fShutDown);
  if (HB_ISLOG(1))
  {
    s_fShutDown = hb_parl(1);
  }
}

HB_BOOL HB_EXPORT sr_GoTopOnScope(void)
{
  return s_fGoTopOnScope;
}

HB_FUNC(SR_SETGOTOPONSCOPE)
{
  hb_retl(s_fGoTopOnScope);
  if (HB_ISLOG(1))
  {
    s_fGoTopOnScope = hb_parl(1);
  }
}

HB_BOOL HB_EXPORT sr_lSerializedAsString(void)
{
  return s_fSerializedAsString;
}

HB_FUNC(SR_SETSERIALIZEDSTRING)
{
  hb_retl(s_fSerializedAsString);
  if (HB_ISLOG(1))
  {
    s_fSerializedAsString = hb_parl(1);
  }
}

HB_BOOL HB_EXPORT sr_lHideRecno(void)
{
  return s_fHideRecno;
}

HB_FUNC(SR_SETHIDERECNO)
{
  hb_retl(s_fHideRecno);
  if (HB_ISLOG(1))
  {
    s_fHideRecno = hb_parl(1);
  }
}

HB_BOOL HB_EXPORT sr_lHideHistoric(void)
{
  return s_fHideHistoric;
}

HB_FUNC(SR_SETHIDEHISTORIC)
{
  hb_retl(s_fHideHistoric);
  if (HB_ISLOG(1))
  {
    s_fHideHistoric = hb_parl(1);
  }
}

HB_BOOL HB_EXPORT sr_UseDeleteds(void)
{
  return s_fUseDeleteds;
}

HB_FUNC(SR_USEDELETEDS)
{
  hb_retl(s_fUseDeleteds);
  if (HB_ISLOG(1))
  {
    s_fUseDeleteds = hb_parl(1);
  }
}

HB_BOOL HB_EXPORT sr_lSerializeArrayAsJson(void)
{
  return s_fSerializeArrayAsJson;
}

HB_FUNC(SR_SETSERIALIZEARRAYASJSON)
{
  hb_retl(s_fSerializeArrayAsJson);
  if (HB_ISLOG(1))
  {
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

HB_FUNC(SR_GETSQL2008NEWTYPES)
{
  hb_retl(s_fSql2008newTypes);
}

HB_FUNC(SR_SETSQL2008NEWTYPES)
{
  hb_retl(s_fSql2008newTypes);
  if (HB_ISLOG(1))
  {
    s_fSql2008newTypes = hb_parl(1);
  }
}

HB_FUNC(SETPGSOLDBEHAVIOR)
{
  int iOld = s_iOldPgsBehavior;
  if (HB_ISLOG(1))
  {
    s_iOldPgsBehavior = hb_parl(1);
  }
  hb_retl(iOld);
}


HB_BOOL HB_EXPORT sr_fShortasNum(void)
{
  return s_fShortasNum;
}

HB_FUNC(SETFIREBIRDUSESHORTASNUM)
{
  int iOld = s_fShortasNum;
  if (HB_ISLOG(1))
  {
    s_fShortasNum = hb_parl(1);
  }
  hb_retl(iOld);
}

#pragma ENDDUMP

//-------------------------------------------------------------------------------------------------------------------//

FUNCTION SR_Version()

RETURN HB_SR__VERSION_STRING + ", Build " + AllTrim(StrZero(HB_SQLRDD_BUILD, 4)) + ", " + HB_SR__MGMNT_VERSION

//-------------------------------------------------------------------------------------------------------------------//

EXIT PROCEDURE SQLRDD_ShutDown()

   sr_setShutDown(.T.)

RETURN

//-------------------------------------------------------------------------------------------------------------------//
