//
// SQLRDD Externals
// Copyright (c) 2003 - Marcelo Lombardo  <marcelo@xharbour.com.br>
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

#ifndef SQLEXTERN_CH
#define SQLEXTERN_CH

// Classes

EXTERNAL SR_WORKAREA
EXTERNAL SqlFastHash
EXTERNAL SR_CONNECTION
EXTERNAL SR_FIREBIRD
EXTERNAL SR_MYSQL
//EXTERNAL SR_MARIADB
EXTERNAL SR_PGS
EXTERNAL SR_ORACLE
EXTERNAL SR_ODBC

// Functions

EXTERNAL SR_AllInCache
EXTERNAL SR_AutoCommit
EXTERNAL SR_GetCnn
EXTERNAL SR_CheckCnn
EXTERNAL SR_GetConnection
EXTERNAL SR_CheckConnection
EXTERNAL SR_SetNextQuery
EXTERNAL SR_GetSyntheticIndexMinimun
EXTERNAL SR_SetSyntheticIndexMinimun
EXTERNAL SR_CheckMgmntInd
EXTERNAL SR_SetSyntheticIndex
EXTERNAL SR_GetSyntheticIndex
EXTERNAL SR_SetSVIndex
EXTERNAL SR_GetSVIndex
EXTERNAL SR_SetFastOpen
EXTERNAL SR_SetTblSpaceData
EXTERNAL SR_SetTblSpaceIndx
EXTERNAL SR_SetTblSpaceLob
EXTERNAL SR_SetRDDTemp
EXTERNAL SR_GetFastOpen
EXTERNAL SR_GetActiveConnection
EXTERNAL SR_SetActiveConnection
EXTERNAL SR_AddConnection
EXTERNAL SR_ReloadMLHash
EXTERNAL AddToMLHash
EXTERNAL GetMLHash
EXTERNAL SR_ErrorOnGotoToInvalidRecord
EXTERNAL SR_SetGoTopOnScope
EXTERNAL SR_SetMultiLang
EXTERNAL SR_SetSerializedString
EXTERNAL SR_TblMgmnt
EXTERNAL SR_SetTblMgmnt
EXTERNAL SR_EvalFilters
EXTERNAL SR_UseDeleteds
EXTERNAL SR_RecnoName
EXTERNAL SR_MaxRowCache
EXTERNAL SR_FetchSize
EXTERNAL SR_DeletedName
EXTERNAL SR_ExistTable
EXTERNAL SR_ExistIndex
EXTERNAL SR_File
EXTERNAL SR_EndConnection
EXTERNAL SR_GetConnectionInfo
EXTERNAL SR_StartLog
EXTERNAL SR_StartTrace
EXTERNAL SR_StopLog
EXTERNAL SR_StopTrace
EXTERNAL SR_SetTimeTrace
EXTERNAL _SR_UnRegister
EXTERNAL _SR_Register
EXTERNAL _SR_ScanExec
EXTERNAL _SR_ScanExecAll
EXTERNAL SR_GetUniqueSystemID
EXTERNAL SR_GetInternalID
EXTERNAL SR_SetCollation
EXTERNAL SR_SetHideRecno
EXTERNAL SR_SetHideHistoric
EXTERNAL SR_DropIndex
EXTERNAL SR_DropTable
EXTERNAL SR_ListIndex
EXTERNAL SR_RenameTable
EXTERNAL SR_ListTables
EXTERNAL SR_ListCreatedTables
EXTERNAL SR_SetToolsOwner
EXTERNAL SR_GetToolsOwner
EXTERNAL SR_SetLocks
EXTERNAL SR_ReleaseLocks
EXTERNAL SR_ListLocks
EXTERNAL DetectDBFromDSN
EXTERNAL SR_DetectDBFromDSN
EXTERNAL SR_Version

EXTERNAL SR_ParseFileName
EXTERNAL SR_CleanTabInfoCache
EXTERNAL SR_SetlGoTopOnFirstInteract
EXTERNAL SR_SetnLineCountResult
EXTERNAL SR_SetUseDTHISTAuto
EXTERNAL SR_GetGlobalOwner
EXTERNAL SR_SetGlobalOwner
EXTERNAL SR_UseSequences
EXTERNAL SR_SetUseSequences


EXTERNAL SR_MsgLogFile
EXTERNAL SR_Val2Char
EXTERNAL SR_LogFile
EXTERNAL SR_FilterStatus
EXTERNAL SR_ChangeStruct
EXTERNAL SR_SetCurrDate
EXTERNAL SR_QuickAppend
EXTERNAL SR_SetColPK
EXTERNAL SR_IsWAHist
EXTERNAL SR_SetNextDt
EXTERNAL SR_DisableHistoric
EXTERNAL SR_EnableHistoric
EXTERNAL SR_GetActiveDt
EXTERNAL SR_SetActiveDt
EXTERNAL SR_SetActiveDate
EXTERNAL SR_SetCreateAsHistoric
EXTERNAL SR_HasHistoric
EXTERNAL SR_cDBValue
EXTERNAL SR_WriteTimeLog
EXTERNAL SR_uCharToVal
EXTERNAL SR_WriteDbLog
EXTERNAL SR_ShowVector
EXTERNAL SR_Val2CharQ
EXTERNAL SR_BlankVar
EXTERNAL SR_HistExpression
EXTERNAL SR_HistExpressionWhere
EXTERNAL SR_SetNextSvVers
EXTERNAL SR_GetRddName
EXTERNAL IsSQLWorkarea
EXTERNAL SR_OrdCondSet
EXTERNAL SR_SetJoin
EXTERNAL SR_AddRuleNotNull
EXTERNAL SR_LastSQLError
EXTERNAL SR_SetFilter
EXTERNAL SR_HasFilters
EXTERNAL SR_dbRefresh

EXTERNAL SR_BeginTransaction
EXTERNAL SR_CommitTransaction
EXTERNAL SR_RollBackTransaction
EXTERNAL SR_TransactionCount
EXTERNAL SR_EndTransaction
EXTERNAL SR_RuntimeErr
EXTERNAL dbCount
EXTERNAL SR_GetStack
//EXTERNAL SR_BINDBYVAL
EXTERNAL __NONOALERT
EXTERNAL SR_SetNwgCompat

EXTERNAL SR_SQLCodeGen
EXTERNAL SR_SQLQuotedString
EXTERNAL SR_dtosdot
EXTERNAL SR_dtoDot
EXTERNAL SR_dtous
EXTERNAL SR_SetTableInfoBlock
EXTERNAL SR_SetIndexInfoBlock
EXTERNAL SR_GetTableInfoBlock
EXTERNAL SR_GetIndexInfoBlock
EXTERNAL SR_SetNextRecordBlock
EXTERNAL SR_GetNextRecordBlock
EXTERNAL SR_ParserVersion
EXTERNAL SR_pCodeDescr
EXTERNAL SR_TableAttr
EXTERNAL SR_IndexAttr

EXTERNAL SR_Msg
EXTERNAL SR_SetBaseLang
EXTERNAL SR_SetSecondLang
EXTERNAL SR_SetRootLang
EXTERNAL SR_GetErrMessageMax

EXTERNAL ITEMCMP
EXTERNAL SR_GETCURRINSTANCEID
EXTERNAL ORACLEINBINDPARAM
EXTERNAL ORACLEGETBINDDATA
EXTERNAL ORACLEFREEBIND
EXTERNAL ORACLEPREPARE
EXTERNAL ORACLEEXECDIR
EXTERNAL ORACLEBINDALLOC

EXTERNAL SR_INSTALLDSN
EXTERNAL SR_INSTALLERROR
EXTERNAL SR_ALLOCEN
EXTERNAL SR_ALLOCCO
EXTERNAL SR_DRIVERC
//EXTERNAL SR_CONNECT
EXTERNAL SR_DISCONN
EXTERNAL SR_FREECON
EXTERNAL SR_FREEENV
EXTERNAL SR_ALLOCST
EXTERNAL SR_FREESTM
EXTERNAL SR_EXECDIR
EXTERNAL SR_FETCH
//EXTERNAL SR_GETDATA
EXTERNAL SR_NUMRES
EXTERNAL SR_DESCRIB
EXTERNAL SR_COLATTRIBUTE
//EXTERNAL SR_EXTENDE
//EXTERNAL SR_FETCHSC
EXTERNAL SR_ERROR
//EXTERNAL SR_ROWCOUN
EXTERNAL SR_GETINFO
EXTERNAL SR_SETCONNECTOPTION
EXTERNAL SR_GETCONNECTOPTION
//EXTERNAL SR_GETSTMTOPTION
EXTERNAL SR_COMMIT
EXTERNAL SR_ROLLBACK
//EXTERNAL SETNUMLEN
//EXTERNAL SR_PREPARE
//EXTERNAL SR_EXECUTE
//EXTERNAL SR_EXECUTESCALAR
//EXTERNAL SR_STOD
EXTERNAL SR_MORERESULTS
//EXTERNAL SR_BINDOUTPARAM
//EXTERNAL SR_BINDOUTPARAMX
EXTERNAL SR_TABLES
EXTERNAL SR_ODBCWRITEMEMO
EXTERNAL SR_ODBCLINEPROCESSED

#endif // SQLEXTERN_CH
