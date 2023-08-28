REQUEST ADS

#include "sqlrdd.ch"
#include "sqlodbc.ch"
#include "common.ch"
#include "hbclass.ch"
#include "ads.ch"

STATIC aOraclipHash := hash()
STATIC aOraClipCursors := hash()
STATIC nIdCursor := 1
STATIC hplVars := {}
STATIC nlasterror := 0
STATIC lReleaseBind := .F.
STATIC aDestroyFiles := {}

FUNCTION OraExecSql(n, c, adata)

   LOCAL cbind
   LOCAL i

if aData != NIL .AND. HB_ISARRAY(adata)
FOR i := len(aData) TO 1 step -1
   cBind := ":"+alltrim(str(i))
   c := strtran(c, cBind, sr_cdbvalue(adata[i]))
NEXT i
endif


RETURN sr_getconnection():exec(c,,.F.)


FUNCTION cssel1(n, aret, csql, adata)
RETURN OraSel1(n, @aret, csql, adata)

FUNCTION OraSeek(nCursor, aData, cTable, cWhere, aVarSust)

   LOCAL cSql := "select * from " + cTable
   LOCAL nRet

if !empty(cWhere )
cSql += " where " + cWhere
endif
aOraClipCursors[nCursor]["oraseek"] := .T.
nRet := OraSel1(nCursor, @aData, csql, aVarSust)
RETURN nret


FUNCTION OraSel1(n, aret, csql, adata)

   LOCAL oSql := sr_getconnection()
   LOCAL nError
   LOCAL i
   LOCAL cBind := ""
   LOCAL aTemp := {}
   LOCAL aDataRet
   LOCAL cursor
   LOCAL lRowId := .F.
   LOCAL cTmpFile
   LOCAL nArea := SelecT()
   LOCAL aDb
   LOCAL aTmp
   LOCAL ncount := 0

set server local
SR_SetRDDTemp("ADT")
closecursor(n)
aOraClipCursors[n]["cursoropen"] := .F.
if adata == NIL

   if "ROWID" $ csql
      aOraClipCursors[n]["data"] := {}
      nError := sr_getconnection():exec(csql, , .T., @aret)
      lRowId := .T.
   else
      nError := ExecuteSql(csql, @cursor, n) // sr_getconnection():exec(csql, , .T., @aret)
      // aOraClipCursors[n]["ret"] := aOraClipCursors[n]["data"]
   endif

   if nError == 0
      aOraClipCursors[n]["cursoropen"] := .T.   
      aOraClipCursors[n]["cursor"] := cursor
      aOraClipCursors[n]["start"] := 1
      aOraClipCursors[n]["len"] := 0
      aOraClipCursors[n]["curpos"] := 1
      aOraClipCursors[n]["error"] := 0   
      aOraClipCursors[n]["nrowread"] := -1  
      aOraClipCursors[n]["lastsql"] := cSql
      aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      if !lRowid
         aOraClipCursors[n]["aFields"] := sr_getconnection():IniFields(.F.) //aFields
         aOraClipCursors[n]["data"] := {}
         aOraClipCursors[n]["completed"] := .F.
         aOraClipCursors[n]["eof"] := .F.
           
         FOR EACH atmp IN aOraClipCursors[n]["aFields"]
            /*
            if "TO_CHAR(" $ UPPER(atmp[1])
               atmp[1] := substr(atmp[1], at("TO_DATE(", upper(atmp[1])) + 9)
               atmp[1] := substr(atmp[1], 1, at(",", upper(atmp[1])) - 1)
            endif
            if "DECODE(" $ UPPER(atmp[1])
               atmp[1] := substr(atmp[1], at("DECODE(", upper(atmp[1])) + 8)
               atmp[1] := substr(atmp[1], 1, at(",", upper(atmp[1])) - 1)
               ENDIF
            */
            atmp[1] := "fld" + strzero(ncount++, 5)
         NEXT

         fclose(HB_FTEMPCREATE(".", "tmp", , @cTmpFile))
         aOraClipCursors[n]["aliastmp"] := StrTran(StrTran(cTmpFile, ".", ""), "\", "") 
         if file(strtran(cTmpfile, ".\", ""))                 
            ferase(strtran(cTmpfile, ".\", ""))
         endif
         if file(cTmpfile)                 
            ferase(cTmpfile)
         endif
         aOraClipCursors[n]["tmpfile"] := cTmpFile
         dbCreate(cTmpFile, SR_AdjustNum(aOraClipCursors[n]["aFields"]), SR_SetRDDTemp())
         dbuseArea(.T., SR_SetRDDTemp(), cTmpFile, aOraClipCursors[n]["aliastmp"])
         cTmpFile := strtran(cTmpfile, ".\", "")
         OraFetch(n) 
         aRet := aOraClipCursors[n]["data"]
      
      nlasterror := 0
      else
      if len(aRet) >= 1
            aOraClipCursors[n]["data"] := aret[1]
            aret := aclone(aOraClipCursors[n]["data"])
         endif
         aOraClipCursors[n]["completed"] := .F.
         aOraClipCursors[n]["eof"]  := .F.
         nlasterror := 0
      endif
     /* if len(aRet) >= 1
         aDataRet := aRet[1]
         aret := aclone(aDataRet)
      endif*/   
   else 
      aOraClipCursors[n]["eof"] := .T.
      aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[n]["lastsql"] := ""
      aOraClipCursors[n]["rowaffected"] := 0
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[n]["aFields"] := {} 
   endif
   if ( nArea>0 ) 
      select(nArea)
   endif
   RETURN nError
   
endif

FOR i := 1 TO len(aData)
   cBind := ":"+alltrim(str(i))
   cSql := strtran(cSql, cBind, sr_cdbvalue(adata[i]))
NEXT i
//    nError := sr_getconnection():exec(csql, , .T., @aret)
   if "ROWID" $ csql
      aOraClipCursors[n]["data"] := {}
   nError := sr_getconnection():exec(csql, , .T., @aret)
      lRowId := .T.

   else
      nError := ExecuteSql(csql, @cursor, n) // sr_getconnection():exec(csql, , .T., @aret)
   endif
   
   //aOraClipCursors[n]["ret"] := aclone(aret)
   if nError == 0 
      aOraClipCursors[n]["cursoropen"] := .T.   
      aOraClipCursors[n]["cursor"] := cursor     
      aOraClipCursors[n]["start"] := 1
      aOraClipCursors[n]["len"] := 0
      aOraClipCursors[n]["curpos"] := 0
      aOraClipCursors[n]["error"] := 0   
      aOraClipCursors[n]["nrowread"] := -1  
      aOraClipCursors[n]["lastsql"] := cSql
      aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      if !lRowid  
         aOraClipCursors[n]["aFields"] :=  sr_getconnection():IniFields(.F.) //aFields
         aOraClipCursors[n]["completed"] := .F.
         aOraClipCursors[n]["eof"] := .F.
nlasterror := 0
         fclose(HB_FTEMPCREATE(".", "tmp", , @cTmpFile))
         aOraClipCursors[n]["aliastmp"] := StrTran(StrTran(cTmpFile, ".", ""), "\", "")
         if file(strtran(cTmpfile, ".\", ""))                 
            ferase(strtran(cTmpfile, ".\", ""))
         endif
         if file(cTmpfile)                 
            ferase(cTmpfile)
         endif
         FOR EACH atmp IN aOraClipCursors[n]["aFields"]
            /*
            if "TO_CHAR(" $ atmp[1]
               atmp[1] := substr(atmp[1], at("TO_DATE(", upper(atmp[1])) + 9)
               atmp[1] := substr(atmp[1], 1, at(",", upper(atmp[1])) - 1)
            endif
            if "DECODE(" $ UPPER(atmp[1])
               atmp[1] := substr(atmp[1], at("DECODE(", upper(atmp[1])) + 8)
               atmp[1] := substr(atmp[1], 1, at(",", upper(atmp[1])) - 1)
            ENDIF
            */
            atmp[1] := "fld" + strzero(ncount++, 5)
         NEXT

         aOraClipCursors[n]["tmpfile"] := cTmpFile
         dbCreate(cTmpFile, SR_AdjustNum(aOraClipCursors[n]["aFields"]), SR_SetRDDTemp())
         dbuseArea(.T., SR_SetRDDTemp(), cTmpFile, aOraClipCursors[n]["aliastmp"])
         cTmpFile := strtran(cTmpfile, ".\", "")   
         orafetch(n)
         aret := aOraClipCursors[n]["data"]
      else
      if len(aRet) >= 1
            aOraClipCursors[n]["data"] := aret[1]
            aret := aclone(aOraClipCursors[n]["data"])
         endif
         aOraClipCursors[n]["completed"] := .F.
         aOraClipCursors[n]["eof"] := .F.
         nlasterror := 0
      endif

   else 
      aOraClipCursors[n]["eof"] := .T.
      aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[n]["lastsql"] := ""
      aOraClipCursors[n]["rowaffected"] := 0
      aOraClipCursors[n]["aFields"] := {}
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
   endif
   if ( nArea>0 ) 
      select(nArea)
   endif
RETURN nError

FUNCTION orafound(n)

   LOCAL lret := .F.

if aOraClipCursors[n]["oraseek"]
   lret := !aOraClipCursors[n]["eof"] 
   aOraClipCursors[n]["eof"] := .F.
   aOraClipCursors[n]["oraseek"] := .F.
   RETURN lret  

endif
if aOraClipCursors[n]["eof"] .AND. aOraClipCursors[n]["completed"] 
RETURN .F.
endif
RETURN len(aOraClipCursors[n]["data"]) >0


FUNCTION OraDelete(nCursor2, cTabOrgMat, cwhere, adata)

   LOCAL csql := "delete from " + cTabOrgMat
   LOCAL i
   LOCAL oSql := sr_getconnection()
   LOCAL nError
   LOCAL e
   LOCAL cBind

if pCount() == 3
   cSql +=  " where " +  cwhere
elseif pCount() == 4

   FOR i := 1 TO len(aData)
      cBind := ":"+alltrim(str(i))
      cwhere := strtran(cwhere, cBind, sr_cdbvalue(adata[i]))
   NEXT i
   cSql += " where " +  cwhere 
endif
   nError := sr_getconnection():exec(csql,,.F.)
   if nError == 0
      aOraClipCursors[nCursor2]["error"] := 0
      aOraClipCursors[nCursor2]["lastsql"] := cSql
      aOraClipCursors[ncursor2]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      nlasterror := 0
   else 
      aOraClipCursors[nCursor2]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[nCursor2]["lastsql"] := ""
      aOraClipCursors[ncursor2]["rowaffected"] := 0
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
   endif

RETURN nError

FUNCTION OraCommit()
 sr_committransaction()
RETURN  0
FUNCTION OraBegin()
sr_begintransaction()
RETURN  0
FUNCTION OraRollBack()
 sr_rollbacktransaction()
RETURN  0
FUNCTION OraErrMsg()

   LOCAL c
   LOCAL e

BEGIN SEQUENCE
   c := SQLO_GETERRORDESCR(sr_getconnection():hDBC)
RECOVER USING e
   c := "usuario nao conectado"
END SEQUENCE
RETURN c

FUNCTION OraUpdate(nCursor, cTabAutos, aCols, aDadosAlt, cWhere, aChave)

   LOCAL csql := "update " +  cTabAutos + " set "
   LOCAL n
   LOCAL i
   LOCAL e
   LOCAL oSql := sr_getconnection()
   LOCAL nError
   LOCAL cbind
   LOCAL nPos

nPos := ascan(acols,{|x| upper(x) == "ROWID"})
FOR n := 1 TO len(aDadosAlt)
   if nPos >0
      if nPos != n
   cSql += acols[n ] + "=" + sr_cdbvalue(aDadosAlt[n]) + ","
      endif
   else
   cSql += acols[n ] + "=" + sr_cdbvalue(aDadosAlt[n]) + ","
   endif
NEXT n
cSql := substr(csql, 1, len(csql) - 1)

if pcount() == 5
    csql +=  " where " +  cwhere 
elseif pcount() == 6


   FOR i := len(aChave) TO 1 STEP -1
      cBind := ":" + alltrim(str(i))
      cwhere := strtran(cwhere, cBind, sr_cdbvalue(aChave[i]))
   NEXT i
   cSql += " where " +  cwhere 

endif   
   BEGIN SEQUENCE
      nError := sr_getconnection():exec(csql, , .F.)
      aOraClipCursors[nCursor]["error"] := 0
      aOraClipCursors[nCursor]["lastsql"] := cSql
      aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      aOraClipCursors[ncursor]["cwhere"] := cwhere
      nlasterror := 0
   RECOVER USING e
      nerror := -1
      aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[nCursor]["lastsql"] := ""
      aOraClipCursors[ncursor]["rowaffected"] := 0
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
   END SEQUENCE
RETURN nError

FUNCTION OraOpen(n, ncursor)
nCursor := nIdCursor
aOraclipHash[n] := hash()
aOraclipHash[n][nIdCursor] := hash()
aOraClipCursors[nIdCursor] := hash() 
aOraClipCursors[nIdCursor]["oraseek"] := .F.
aOraClipCursors[nIdCursor]["cursoropen"] := .F.
++nIdCursor
RETURN 0

FUNCTION cslogon(cCnxName, cUser, cPwd, cAlias, nCnxType) 
RETURN OraLogon(cCnxName, cUser, cPwd, cAlias, nCnxType) 

FUNCTION ocInitialize(cConexion, cUsuario, cPassword, cAlias)
RETURN OraLogon(cConexion, cUsuario, cPassword , cAlias )
 
FUNCTION OraLogon(cCnxName, cUser, cPwd, cAlias, nCnxType)

   LOCAL cString
   LOCAL nRet

cString := "UID="+cUSer+";PWD="+cPwd
if !empty(cAlias ) 
cString += ";TNS="+cAlias
endif
nRet := sr_addconnection(CONNECT_ORACLE, cstring)

if nRet >0
   aOraclipHash[cCnxName] := hash()
   aOraclipHash[cCnxName]["nRet"] := nRet
   aOraclipHash[cCnxName]["alias"] := cAlias
   aOraclipHash[cCnxName]["time"] := dtoc(date()) + "-" + time()
   aOraclipHash[cCnxName]["user"] := cUSer
   aOraclipHash[cCnxName]["pwd"] := cPwd
endif
RETURN iif(nRet > 0, 0, nret)

FUNCTION cslogoff(cCnxName) 
RETURN  OraLogoff(cCnxName) 
FUNCTION OraLogoff(cCnxName)

   LOCAL e
   LOCAL hData

BEGIN SEQUENCE
   hData := aOraclipHash[cCnxName]
   if !empty(hdata)
       sr_endconnection(hData["nRet"])
       aOraclipHash[cCnxName]["nRet"] := NIL
   endif
RECOVER USING e
   sr_endconnection()
END SEQUENCE
RETURN NIL

FUNCTION oraalias(cCnxName)
RETURN  aOraclipHash[cCnxName]["alias"]

FUNCTION oralogtime(cCnxName)
RETURN  aOraclipHash[cCnxName]["time"]

FUNCTION orauser(ccnxname)
RETURN aOraclipHash[cCnxName]["user"] 

FUNCTION orapwd(ccnxname)
RETURN aOraclipHash[cCnxName]["pwd"] 

FUNCTION oraintrans(ccnxname)
RETURN SR_TransactionCount(aOraclipHash[cCnxName]["nRet"] )


FUNCTION csskip(n, aData, nPos)
RETURN oraskip(n, @aData, nPos)

//Alteracao
FUNCTION oraskip(n, aData, nPos)

   LOCAL i
   LOCAL lPrimeiro := .T.

default nPos to 1
if nPos>0
    if aOraClipCursors[n]["curpos"] == 0
       aOraClipCursors[n]["curpos"] := 1
    endif
    FOR i := 1 TO nPos
       aOraClipCursors[n]["curpos"]++
       OraFetch(n)
    NEXT i

    //if aOraClipCursors[n]["curpos"]+1 <= aOraClipCursors[n]["len"] 
      aOraClipCursors[n]["curpos"]++
      //aData := aOraClipCursors[n]["ret"][aOraClipCursors[n]["curpos"]]
      aData := aOraClipCursors[n]["data"]
    //endif
else
    FOR i := nPos TO 1 STEP -1
       aOraClipCursors[n]["curpos"]--
    NEXT i
       
   if aOraClipCursors[n]["curpos"]-1 >= aOraClipCursors[n]["start"] 
      OraFetch(n)
      //aData := aOraClipCursors[n]["ret"][aOraClipCursors[n]["curpos"]]
      aData := aOraClipCursors[n]["data"]
   endif
    
endif   
      
RETURN  0
FUNCTION cseof(n)
RETURN oraeof(n)
FUNCTION oraeof(n)

   LOCAL lreturn := .F.
   LOCAL i

If aOraClipCursors[n]["completed"]
   lreturn := .T. // (aOraClipCursors[n]["aliastmp"])->(eof())
Else
   If !aOraClipCursors[n]["completed"] .AND. aOraClipCursors[n]["eof"]   
      lreturn := .T.
   Else
      lreturn := .F.
   EndIf      
EndIf
if lReturn
   FOR i := 1 TO len(aOraClipCursors[n]["data"])
       aOraClipCursors[n]["data"][i] := GerGhost(aOraClipCursors[n]["data"][i])
   NEXT i
endif       
RETURN lreturn

//RETURN aOraClipCursors[n]["curpos"] >= aOraClipCursors[n]["len"]

FUNCTION csbof(n)
RETURN  orabof(n)
FUNCTION orabof(n)
RETURN aOraClipCursors[n]["curpos"] == aOraClipCursors[n]["start"]

FUNCTION orazap(n)
RETURN NIL
FUNCTION orastruct(n, ctable)

   LOCAL aStru
   LOCAL csql := "select * from " + ctable + " where 1 == 1"

use (csql) new via "SQLRDD" alias "ZZZZZZZZZZ"
aStru := zzzzzzzzzz->(dbstruct())
zzzzzzzzzz->(dbclosearea())
RETURN astru

FUNCTION OraSetPwd(nCursor, cUser, cPassword)

   LOCAL cSql := "alter user " + cUser + " identified by " + cPassword
   LOCAL nRet
   LOCAL e

   nRet := sr_getconnection():exec(cSql, , .F.)

RETURN  nRet

FUNCTION OraSingle(n, csql, adata)

   LOCAL oSql := sr_getconnection()
   LOCAL nError
   LOCAL aRet := {}
   LOCAL i
   LOCAL e
   LOCAL cBind

if adata == NIL
   nError := sr_getconnection():exec(csql, , .T., @aret)
   if nError == 0
      aOraClipCursors[n]["error"]  := 0   
      aOraClipCursors[n]["lastsql"] := cSql
      aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      nlasterror := 0
      aOraClipCursors[n]["aFields"] := sr_Getconnection():aFields
      if len(aret) == 1 
         if len(aRet[1]) == 1
            RETURN aret[1, 1]
         else
            RETURN aret[1]   
         endif   
      endif

   else
      aOraClipCursors[n]["error"]  := SQLO_GETERRORCODE(sr_getconnection():hDBC)
nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
aOraClipCursors[n]["lastsql"] := ""
      aOraClipCursors[n]["rowaffected"] := 0
      aOraClipCursors[n]["aFields"] := {} 
   endif   
   RETURN aret   
   
endif

   FOR i := 1 TO len(aData)
      cBind := ":" + alltrim(str(i))
      cSql := strtran(cSql, cBind, sr_cdbvalue(adata[i]))
   NEXT i
   
   BEGIN SEQUENCE
      nError := sr_getconnection():exec(csql, , .T., @aret)
   RECOVER USING e
      nerror := -1
   END SEQUENCE

   aOraClipCursors[n]["ret"] := aret
   if nError == 0
      aOraClipCursors[n]["start"] := 1
      aOraClipCursors[n]["len"] := len(aret)
      aOraClipCursors[n]["curpos"] := 1
      aOraClipCursors[n]["error"]  := 0
      aOraClipCursors[n]["nrowread"] := -1
      aOraClipCursors[n]["lastsql"] := cSql
      aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      aOraClipCursors[n]["aFields"] := sr_getconnection():aFields
      nlasterror := 0
   else
      aOraClipCursors[n]["error"]  := SQLO_GETERRORCODE(sr_getconnection():hDBC)
nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[n]["lastsql"] := ""
      aOraClipCursors[n]["rowaffected"] := 0
      aOraClipCursors[n]["aFields"] := {}
   endif

RETURN nError



FUNCTION OraInsert(nCursor, cTable, aCols, aData)

   LOCAL cSql := "insert into " + ctable
   LOCAL cValues := ""
   LOCAL i
   LOCAL nError
   LOCAL e
   LOCAL osql := sr_getconnection()

if len(acols) > 0
cSql += "( "

FOR i := 1 TO len(acols)
   if upper(aCols[i]) == "SR_DELETED"
      cSql += aCols[i] + ","
      cValues += "' ',"
   elseif upper(aCols[i]) == "ROWID"
   else
      cSql += aCols[i] + ","
      cValues += sr_cdbvalue(aData[i]) + ","
   endif
NEXT i

endif
if len(acols ) == 0 .AND. len(adata ) > 0
FOR i := 1 TO len(aData)
   cValues += sr_cdbvalue(aData[i]) + ","
NEXT i

endif

if len(acols ) > 0
cSql := substr(cSql, 1, len(cSql)-1) + ") VALUES ("
else
csql += " values ( "
endif
cValues := substr(cValues, 1, len(cValues)-1) + ")"
cSql += cValues

   BEGIN SEQUENCE
      nError := sr_getconnection():exec(csql, , .F. ,)
      aOraClipCursors[nCursor]["error"] := 0
      aOraClipCursors[nCursor]["lastsql"] := cSql
      aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      aOraClipCursors[ncursor]["acols"] := acols
      aOraClipCursors[ncursor]["avalues"] := aData
      nlasterror := 0
   RECOVER USING e
      nerror := -1
      aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[nCursor]["lastsql"] := cSql
      aOraClipCursors[ncursor]["rowaffected"] := 0
   END SEQUENCE

RETURN nError


FUNCTION OraCount(nCursor, cTabela, cWhere, aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL i
   LOCAL cbind

if pcount() < 2
   RETURN NIL
endif
if pcount() == 2
cSql := "select count(*) from " +cTabela
elseif pCount() == 3
cSql := "select count(*) from " +cTabela + " where " + cwhere
elseif pCount() == 4
   cSql := "select count(*) from " +cTabela 
   FOR i := 1 TO len(aVarSust)
      cBind := ":" + alltrim(str(i))
      cwhere := strtran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
   NEXT i
   cSql += " where " +  cwhere 

endif
nErro := sr_Getconnection():exec(cSql, , .T., @aret)
if nErro ==0 
   aOraClipCursors[nCursor]["error"]  := 0
   aOraClipCursors[nCursor]["lastsql"] := cSql
//    aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
nlasterror := 0
   RETURN aRet[1, 1]
else
   aOraClipCursors[nCursor]["error"]  := SQLO_GETERRORCODE(sr_getconnection():hDBC)      
   aOraClipCursors[nCursor]["lastsql"] := cSql
//    aOraClipCursors[ncursor]["rowaffected"] := 0
nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
endif
RETURN 0   
FUNCTION oraset()
RETURN NIL


FUNCTION oraerror(n)
if pcount()==0
RETURN nlasterror
endif
RETURN aOraClipCursors[n]["error"]
FUNCTION csSetVar(cVarName, cOraType, nLen, nDec, xInitValue)
RETURN OraSetVar(cVarName, cOraType, nLen, nDec, xInitValue)

FUNCTION OraSetVar(cVarName, cOraType, nLen, nDec, xInitValue)
default nlen to 1
default ndec to 0

if lReleaseBind
lReleaseBind := .F.
hplvars := {}
endif
aadd(hplVars,  {UPPER(cVarName), UPPER(cOraType), nLen+5, nDec, xInitValue,})
RETURN NIL

FUNCTION csplsql(nCursor, cPLSQL, aVarSust)
RETURN OraPLSQL(nCursor, cPLSQL, aVarSust)
FUNCTION OraPLSQL(nCursor, cPLSQL, aVarSust)

   LOCAL cBind
   LOCAL i
   LOCAL aItem
   LOCAL nerror
   LOCAL e
   LOCAL oSql

lReleaseBind := .T.
if HB_ISARRAY(aVarSust)
   FOR i := len(aVarSust) TO 1 STEP -1
      cBind := ":" + alltrim(str(i))
      cPLSQL := strtran(cPLSQL, cBind, sr_cdbvalue(aVarSust[i]))
   NEXT i
endif
if len(hplVars ) >0
   oSql := sr_getconnection()
   oracleprePARE(osql:hdbc, cPLSQL)
   oraclebindalloc(oSql:hdbc, len(hplVars))
   FOR i := 1 TO len(hplVars)
      aItem := hplVars[i]
      if aItem[2] == "VARCHAR" .OR. aItem[2] == "CHAR" .OR. aItem[2] == "VARCHAR2"
         OracleinBindParam(oSql:hdbc, i, -1, aItem[3], , aItem[5])
      elseif aItem[2] == "NUMBER"
         if aItem[4] >0
            OracleinBindParam(oSql:hdbc, i, 4, 12, , aItem[5])
         else
            OracleinBindParam(oSql:hdbc, i, 2, 12, , aItem[5])
         endif
      elseif aItem[2] == "DATE" .OR. aItem[2] == "DATA"
        OracleinBindParam(oSql:hdbc, i, 8, 12, , aItem[5])
      endif
   NEXT i
   BEGIN SEQUENCE
      nError := OracleExecDir(osql:hDbc)
      aOraClipCursors[nCursor]["error"] := nError
      aOraClipCursors[nCursor]["lastsql"] := cPlSql
      nlasterror := 0
   RECOVER USING e
      nerror := -1
      aOraClipCursors[nCursor]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[nCursor]["lastsql"] := ""
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
   END SEQUENCE
   If nerror >= 0
      FOR i := 1 TO len(hplVars)
         hplVars[i, 6] := ORACLEGETBINDDATA(osql:hdbc, i)
      NEXT i
   Endif
   ORACLEFREEBIND(osql:hdbc)
endif
RETURN nError

FUNCTION csgetvar(c)
RETURN oragetvar(c)
FUNCTION oragetvar(c)

   LOCAL nPos

nPos := ascan(hplVars,{|x| alltrim(upper(x[1])) == Alltrim(upper(c ))})
if nPos >0
   RETURN hplVars[nPos, 6]
endif
   lReleaseBind := .T.
RETURN ""
      
FUNCTION oraclose(n)
RETURN NIL
   
FUNCTION OraResetBind()
hplVars := {}
RETURN NIL   
FUNCTION OCTBROWSEDB(a, s, d, f)
RETURN tbrowsedb(a, s, d, f)

FUNCTION csxerror()
RETURN sr_Getconnection():nretcode
FUNCTION csxerrmsg()
RETURN SQLO_GETERRORCODE(sr_getconnection():hDBC)

FUNCTION CSXCLEARFILTER()
(alias())->(sr_setfilter())
RETURN NIL

FUNCTION CSXsetFILTER(a)

   LOCAL cFilter

if len(a) == 1
(alias())->(sr_setfilter(a[1]))
elseif len(a) ==2
cFilter := strtran(a[1], ":1", sr_cdbvalue(a[2]))
(alias())->(sr_setfilter(a[1]))
endif
RETURN NIL


FUNCTION orarowid()
RETURN (alias())->(recno())
FUNCTION csxrowid()
RETURN (alias())->(recno())

FUNCTION csx
RETURN NIL

FUNCTION CSOPENTMP(n, ncursor)
RETURN OraOpentmp(n, @ncursor)

FUNCTION OraOpentmp(n, ncursor)
nCursor := nIdCursor
aOraclipHash[n] := hash()
aOraclipHash[n][nIdCursor] := hash()
aOraClipCursors[nIdCursor] := hash() 
aOraClipCursors[nIdCursor]["cursoropen"] := .F.
++nIdCursor
RETURN 0

FUNCTION CSCLOSETMP(n)
RETURN oraclosetmp(n)
FUNCTION oraclosetmp(n)
   closecursor(n)
   hdel(aOraClipCursors, n)
   --nIdCursor
   RETURN NIL

// culik 8/12/2012 adicionado funcoes nao existente   
   
FUNCTION OraMax(nCursor, cTable, cColumn , cWhere , aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL i
   LOCAL cwhere1
   LOCAL cBind

if pcount() < 3
   RETURN NIL
endif
cSql := "select max( " +cColumn + " ) from " +cTable

   
if pCount() == 4
   cSql +=  " where " + cwhere
elseif pCount() == 5
   FOR i := 1 TO len(aVarSust)
      cBind := ":" + alltrim(str(i))
      cwhere := strtran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
   NEXT i
   cSql += " where " +  cwhere 

endif
nErro := sr_Getconnection():exec(cSql, , .T., @aret)
if nErro ==0 
   aOraClipCursors[nCursor]["error"]  := 0
   aOraClipCursors[nCurSor]["lastsql"] := cSql
   aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
   nlasterror := 0
   RETURN aRet[1, 1]
else
   aOraClipCursors[nCursor]["error"]  := SQLO_GETERRORCODE(sr_getconnection():hDBC)      
   nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)      
   aOraClipCursors[nCursor]["lastsql"] := cSql
   aOraClipCursors[ncursor]["rowaffected"] := 0
endif
RETURN NIL   

FUNCTION OraSelect(n, aret, csql, adata, nRows)

   //LOCAL oSql := sr_getconnection()
   LOCAL nError
   LOCAL i
   LOCAL e
   LOCAL cBind := ""
   LOCAL aTemp := {}
   LOCAL aDataRet := {}
   LOCAL nPosm
   LOCAL cursor

Default nRows to -1
   closecursor(n)
aOraClipCursors[n]["cursoropen"] := .F.
if adata == NIL
   //if nrows >F.
   //else
//    nError := sr_getconnection():exec(csql, , .T., @aret)
   //endif
   //comentada linha sandro, desnecessario neste ponto, existe abaixo
   //aOraClipCursors[n]["ret"] := aret   
   // velho
   nError := ExecuteSql(csql, @cursor, n) // sr_getconnection():exec(csql, , .T., @aret)
   if nError == 0 
aOraClipCursors[n]["cursoropen"] := .T.      
      aOraClipCursors[n]["cursor"] := cursor
      aOraClipCursors[n]["start"] := 1
      aOraClipCursors[n]["len"] := 0
      aOraClipCursors[n]["curpos"] := 1
      aOraClipCursors[n]["error"] := 0 
      aOraClipCursors[n]["nrowread"] := -1  
      aOraClipCursors[n]["lastsql"] := cSql
      aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      aOraClipCursors[n]["aFields"] := sr_getconnection():IniFields(.F.) //aFields
      aOraClipCursors[n]["data"] := {}
      aOraClipCursors[n]["completed"] := .F.
      aOraClipCursors[n]["eof"] := .F.
      if nRows > -1
         FOR nPos := 1 TO nRows
            OraFetchSelect(n)
            IF LEN(aOraClipCursors[n]["data"]) > 0
               aadd(aRet, aOraClipCursors[n]["data"])
            endif
         NEXT nPos
      else
          DO WHILE OraFetchSelect(n) == 0
             aadd(aRet, aOraClipCursors[n]["data"])
          ENDDO
          
      endif



//    if nError == 0
//
//       aOraClipCursors[n]["start"] := 1
//       aOraClipCursors[n]["len"] := len(aret)
//       aOraClipCursors[n]["curpos"] := 0
//       aOraClipCursors[n]["error"] := 0
//       aOraClipCursors[n]["nrowread"] := nRows
//
//       aOraClipCursors[n]["ret"] := aret
//       aOraClipCursors[n]["lastsql"] := cSql
//       aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
//       aOraClipCursors[n]["aFields"] := sr_getconnection():aFields
//       nlasterror := 0
//       if nRows > -1
//          FOR EACH aTemp IN aRet
//             aadd(aDataRet, aTemp)
//             if hb_enumindex() == nRows
//                exit
//             endif
//          NEXT
//          aOraClipCursors[n]["curpos"] := len(aDataRet )+1
//          aRet := aDataRet
//       endif
   else
      aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[n]["lastsql"] := cSql
      aOraClipCursors[n]["rowaffected"] := 0
      aOraClipCursors[n]["aFields"] := {}
   endif
   RETURN nError
endif

   FOR i := len(aData) TO 1 STEP -1
      cBind := ":" + alltrim(str(i))
      cSql := strtran(cSql, cBind, sr_cdbvalue(adata[i]))
   NEXT i
   nError := ExecuteSql(csql, @cursor, n) // sr_getconnection():exec(csql, , .T., @aret)
   if nError == 0 
      aOraClipCursors[n]["cursoropen"] := .T.      
      aOraClipCursors[n]["cursor"] := cursor
      aOraClipCursors[n]["start"] := 1
      aOraClipCursors[n]["len"] := 0
      aOraClipCursors[n]["curpos"] := 1
      aOraClipCursors[n]["error"] := 0   
      aOraClipCursors[n]["nrowread"] := -1  
      aOraClipCursors[n]["lastsql"] := cSql
      aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
      aOraClipCursors[n]["aFields"] := sr_getconnection():IniFields(.F.) //aFields
      aOraClipCursors[n]["data"] := {}
      aOraClipCursors[n]["completed"] := .F.
      aOraClipCursors[n]["eof"] := .F.
      if nRows > -1
          FOR nPos := 1 TO nRows
             OraFetchSelect(n)
             IF LEN(aOraClipCursors[n]["data"]) > 0
                aadd(aRet, aOraClipCursors[n]["data"])
             ENDIF
          NEXT nPos
      else
          DO WHILE OraFetchSelect(n) == 0
             aadd(aRet, aOraClipCursors[n]["data"])
          ENDDO
      endif


//    nError := sr_getconnection():exec(csql, , .T., @aret)
//    aOraClipCursors[n]["ret"] := aret
//velho
//    if nError == 0
//
//       aOraClipCursors[n]["start"] := 1
//       aOraClipCursors[n]["len"] := len(aret)
//       aOraClipCursors[n]["curpos"] := 0
//       aOraClipCursors[n]["error"] := 0
//       aOraClipCursors[n]["nrowread"] := nRows
//       aOraClipCursors[n]["lastsql"] := cSql
//       aOraClipCursors[n]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
//       aOraClipCursors[n]["aFields"] := sr_getconnection():aFields
//       nlasterror := 0
//       if nRows > -1
//          FOR EACH aTemp IN aRet
//             aadd(aDataRet, aTemp)
//             if hb_enumindex() == nRows
//                exit
//             endif
//          NEXT
//          aRet := aDataRet
//          aOraClipCursors[n]["curpos"] := len(aDataRet )+1
//       endif
//
   else
      aOraClipCursors[n]["error"] := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[n]["lastsql"] := ""
      aOraClipCursors[n]["rowaffected"] := 0
      aOraClipCursors[n]["aFields"] := {}
   endif
  
RETURN nError

FUNCTION OraUpdIns(nCursor, cTable, aCols, aDataUpd, aDataIns, cWhere, aVarSust)

   LOCAL nRet
   LOCAL nPos
   LOCAL aret

   if OraCount(nCursor, cTable, cWhere, aVarSust) > 0
      OraUpdate(nCursor, cTable, aCols, aDataUpd, cWhere, aVarSust)
   else
      RETURN OraInsert(nCursor, cTable, aCols, aDataIns) 
   endif
RETURN nRet  

/*
FUNCTION OraUpdIns(nCursor, cTable, aCols, aDataUpd, aDataIns, cWhere, aVarSust)

   LOCAL nRet
   LOCAL nPos

   nRet := OraUpdate(nCursor, cTable, aCols, aDataUpd, cWhere, aVarSust)
   if nRet == -1
      RETURN OraInsert(nCursor, cTable, aCols, aDataIns)
   endif
RETURN nRet      
*/

FUNCTION Orasum(nCursor, cTable, cColumn , cWhere , aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL cBind
   LOCAL i

if pcount() < 3
   RETURN NIL
endif
cSql := "select sum( " +cColumn + " ) from " +cTable

   
if pCount() == 4
   cSql +=  " where " + cwhere
elseif pCount() == 5
   FOR i := 1 TO len(aVarSust)
      cBind := ":" + alltrim(str(i))
      cwhere := strtran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
   NEXT i
   cSql += " where " +  cwhere 

endif
nErro := sr_Getconnection():exec(cSql, , .T., @aret)
if nErro ==0 
   aOraClipCursors[nCursor]["error"]  := 0
   aOraClipCursors[nCursor]["lastsql"] := cSql
   aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
   nlasterror := 0
   RETURN aRet[1, 1]
else
   aOraClipCursors[nCursor]["error"]  := SQLO_GETERRORCODE(sr_getconnection():hDBC)      
   aOraClipCursors[nCursor]["lastsql"] := cSql
   aOraClipCursors[ncursor]["rowaffected"] := 0
   nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
endif
RETURN NIL   


FUNCTION csxBegin()

   LOCAL oCnn

SR_BeginTransaction()
oCnn := sr_getconnection()
RETURN iif(oCnn:nTransacCount > 0, 0, -1)

FUNCTION CSXCOMMIT()
sr_committransaction()
RETURN 0
FUNCTION CSXROLLBACK()
sr_rollbacktransaction()
RETURN 0

FUNCTION CSINTRANS()
RETURN SR_TransactionCount() > 0

FUNCTION OraSelNexnCursor, aTableData, nRows)

   LOCAL hData
   LOCAL e
   LOCAL nRet := 0
   LOCAL aRet
   LOCAL aDataRet := {}
   LOCAL nPos
   LOCAL nStart
   LOCAL nEnd
   LOCAL ii

default nRows to -1
BEGIN SEQUENCE

    if aOraClipCursors[nCursor]["completed"]
       aOraClipCursors[nCursor]["data"] := {}
       aTableData := {}
      else
      aOraClipCursors[nCursor]["data"] := {}
      if nRows > -1
          FOR nPos := 1 TO nRows
             OraFetchSelect(nCursor)
             IF LEN(aOraClipCursors[nCursor]["data"]) > 0
                aadd(aDataRet, aOraClipCursors[nCursor]["data"])
             ENDIF
          NEXT nPos
      else
          DO WHILE OraFetchSelect(nCursor) == 0
             IF LEN(aOraClipCursors[nCursor]["data"]) > 0
                aadd(aDataRet, aOraClipCursors[nCursor]["data"])
             ENDIF
          ENDDO
      endif
         aTableData := aDataRet
      endif


//
//    hData := aOraClipCursors[nCursor]
//    if len(hData["ret"]) > 0
//       aRet := hData["ret"]
//       nStart := hData["curpos"]
//
//       if nRows == -1
//          DO WHILE nStart <= len(aRet)
//             aadd(aDataRet, aRet[nStart])
//             nStart ++
//          ENDDO
//          aTableData := aDataRet
//          aOraClipCursors[nCursor]["curpos"] := len(aRet) +1
//
//       else
//
//          nEnd   := hData["curpos"] + nRows
//          ii := 0
//          FOR nPos := nStart TO nEnd
//             aadd(aDataRet, aRet[nStart])
//             ii++
//             if ii == nRows
//                exit
//             endif
//          NEXT nPos
//          aTableData := aDataRet
//          aOraClipCursors[nCursor]["curpos"] := nEnd +1
//       endif
//
//    endif
RECOVER USING e
   nRet := -1
END SEQUENCE
RETURN nRet




FUNCTION csExecSQL(nCursor, cSQL, aVarSust)

   LOCAL nRet
   LOCAL hData
   LOCAL oSql
   LOCAL cBind
   LOCAL i
   LOCAL aItem
   LOCAL nerror

BEGIN SEQUENCE
hData := aOraClipCursors[nCursor]
osql := sr_getconnection()
if upper(substr(cSql, 6)) == "BEGIN "
   if pCount() == 3

      if HB_ISARRAY(aVarSust)
         FOR i := len(aVarSust) TO 1 STEP -1
            cBind := ":" + alltrim(str(i) )
            cSQL := strtran(cSQL, cBind, sr_cdbvalue(aVarSust[i]))
         NEXT i
      endif

   endif
   oracleprePARE(osql:hdbc, cSQL)
   nRet := OracleExecDir(osql:hDbc)
   nlasterror := 0
   aOraClipCursors[nCursor]["errormsg"]  := ""
   if nRet == 0
      aOraClipCursors[nCursor]["error"]  := 0
      aOraClipCursors[nCursor]["lastsql"] := cSql
      aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
   else
      aOraClipCursors[nCursor]["error"]  := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[nCursor]["errormsg"]  := SQLO_GETERRORDESCR(osql:hDBC)
      aOraClipCursors[nCursor]["lastsql"] := ""
      aOraClipCursors[ncursor]["rowaffected"] := 0
   endif

else
   nRet := osql:exec(cSql,,.F.)
   nlasterror := 0
   aOraClipCursors[nCursor]["errormsg"]  := ""
   if nRet == 0
      aOraClipCursors[nCursor]["error"]  := 0
      aOraClipCursors[nCursor]["lastsql"] := cSql
      aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
   else
      aOraClipCursors[nCursor]["error"]  := osql:lasterror()
      aOraClipCursors[nCursor]["errormsg"]  := SQLO_GETERRORDESCR(osql:hDBC)
      nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
      aOraClipCursors[nCursor]["lastsql"] := cSql
      aOraClipCursors[ncursor]["rowaffected"] := 0
   endif
endif
RECOVER USING e
nret := -1
END SEQUENCE
RETURN nRet

FUNCTION csErrMsg(nCursor)

   LOCAL nRet
   LOCAL hData
   LOCAL oSql
   LOCAL e
   LOCAL cRet := ""

BEGIN SEQUENCE
   hData := aOraClipCursors[nCursor]
   osql := sr_getconnection()
   cRet :=  hData["errormsg"]
RECOVER USING e
END SEQUENCE
RETURN cRet


FUNCTION CSVALIDCNX(nCursor)

   LOCAL lRet := .F.
   LOCAL hData
   LOCAL oSql
   LOCAL e
   LOCAL cRet := ""

BEGIN SEQUENCE
   hData := aOraClipCursors[nCursor]
   osql := sr_getconnection()
   lRet := hData["nRet"] >0
RECOVER USING e
lRet := .F.
END SEQUENCE
RETURN lRet


FUNCTION CSUSER(nCursor)

   LOCAL hData
   LOCAL oSql
   LOCAL e
   LOCAL cRet := ""

BEGIN SEQUENCE
   hData := aOraClipCursors[nCursor]
   osql := sr_getconnection()
   cRet := hData["user"]
RECOVER USING e
   cRet := ""
END SEQUENCE
RETURN cRet


FUNCTION CSVALIDCURSOR(nCursor)

   LOCAL lRet
   LOCAL hDAta
   LOCAL e

BEGIN SEQUENCE
hData := aOraClipCursors[nCursor]
lRet := .T.
RECOVER
lRet := .F.
END SEQUENCE
RETURN lRet

FUNCTION CSXSETRDD
RETURN NIL



FUNCTION OraExists(nCursor, cTable, cWhere, aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL i
   LOCAL cwhere1
   LOCAL cBind

if pcount() < 3
   RETURN NIL
endif
cSql := "select * from " +cTable

   
if pCount() == 3
   cSql +=  " where " + cwhere
elseif pCount() == 4
   FOR i := 1 TO len(aVarSust)
      cBind := ":" + alltrim(str(i))
      cwhere := strtran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
   NEXT i
   cSql += " where " +  cwhere 

endif
nErro := sr_Getconnection():exec(cSql, , .T., @aret)
if nErro ==0 
   RETURN len(aRet) > 0
endif
RETURN .F.


FUNCTION OraMin(nCursor, cTable, cColumn , cWhere , aVarSust)

   LOCAL nlen := 0
   LOCAL aRet := {}
   LOCAL nErro
   LOCAL cSql
   LOCAL cwhere1
   LOCAL cBind
   LOCAL i

if pcount() < 3
   RETURN NIL
endif
cSql := "select mim( " +cColumn + " ) from " +cTable

   
if pCount() == 4
   cSql +=  " where " + cwhere
elseif pCount() == 5
   FOR i := len(aVarSust) TO 1 STEP -1
      cBind := ":" + alltrim(str(i))
      cwhere := strtran(cwhere, cBind, sr_cdbvalue(aVarSust[i]))
   NEXT i
   cSql += " where " +  cwhere 

endif
nErro := sr_Getconnection():exec(cSql, , .T., @aret)
if nErro ==0 
   aOraClipCursors[nCursor]["error"]  := 0
   aOraClipCursors[nCursor]["lastsql"] := cSql
   aOraClipCursors[ncursor]["rowaffected"] := GETAFFECTROWS(sr_getconnection():hdbc)
   nlasterror := 0
   RETURN aRet[1, 1]
else
   aOraClipCursors[nCursor]["error"]  := SQLO_GETERRORCODE(sr_getconnection():hDBC)      
   nlasterror := SQLO_GETERRORCODE(sr_getconnection():hDBC)
   aOraClipCursors[nCursor]["lastsql"] := cSql
   aOraClipCursors[ncursor]["rowaffected"] := 0
endif
RETURN NIL   


#define _ORATBROWSE_EXIT             1
#define _ORATBROWSE_REFRESHALL       2
#define _ORATBROWSE_REFRESHCURRENT   3
#define _ORATBROWSE_METHOD           4
#define _ORATBROWSE_SEARCH           5
#define _ORATBROWSE_SEARCH_NEXT      6
#define _ORATBROWSE_FILTER           7
#define _ORATBROWSE_FILTER_BACK      8
#define _ORATBROWSE_FILTER_RESET     9
#define _ORATBROWSE_ORDER_BY        10
#define _ORATBROWSE_ORDER_RESET     11


FUNCTION OraTBrNew(nTop, nLeft, nBottom, nRight)
RETURN tbrowsedb(nTop, nLeft, nBottom, nRight)

#define COMPILE(cExp) &("{||"+cExp+"}")
FUNCTION OraColumnNew(cHeading, bBlock)
RETURN TBColumnNew(cHeading, COMPILE(bBlock))

FUNCTION OraTBrowse(nCursor1, cSql, c, oBrowse, bBLock)

   LOCAL cTempFile
   LOCAL aReg := {}
   LOCAL i
   LOCAL aRet := {}
   LOCAL lRet := .T.
   LOCAL nKey
   LOCAL oSql := sr_getconnection()
   LOCAL oCol

fclose(HB_FTEMPCREATEEX(@cTempFile, , "tmp", ".dbf"))

osql:exec(cSql, , .T., , cTempFile)

while lRet
   obrowse:forcestable()
   aReg := {}
   FOR i := 1 TO fcount()
//       aadd(aReg, eVal(obrowse:GetColumn(i):Block))
      oCol := oBrowse:getcolumn(i)
      aadd(aReg, fieldget(i))
   NEXT i
   nKey := inkey(0) 
   aRet := eval(bBLock, nkey, obrowse, aReg)
   IF Aret == NIL
      loop
   endif
   SWITCH aRet[1]
   CASE _ORATBROWSE_METHOD
      oBrowse:applykey(nKey)
      EXIT
   CASE _ORATBROWSE_REFRESHALL
      zap
      osql:exec(cSql, , .T., , cTempFile)
      go top
      EXIT
   CASE  _ORATBROWSE_EXIT
     lRet := .F.
     EXIT
   ENDSWITCH

enddo
   
RETURN 0



FUNCTION ORALASTSQL()
RETURN NIL
 
INIT FUNCTION OVERRIDESIZE
   OVERRIDE METHOD SQLLen IN CLASS SR_CONNECTION WITH MySQLLen
STATIC FUNCTION mySQLLen(nType, nLen, nDec)

   LOCAL cType := "U"
   LOCAL Self := QSelf()

   DEFAULT nDec TO -1

   SWITCH nType
   CASE SQL_CHAR
   CASE SQL_VARCHAR
   CASE SQL_NVARCHAR
      IF IIf(SR_SetNwgCompat(), nLen != 4000 .AND. nLen != 2000, .T.)
      ENDIF
      EXIT
   CASE SQL_SMALLINT
   CASE SQL_TINYINT
      IF ::lQueryOnly
         nLen := 10
      ELSE
         nLen := 1
      ENDIF
      EXIT
   CASE SQL_BIT
      nLen := 1
      EXIT
   CASE SQL_NUMERIC
   CASE SQL_DECIMAL
   CASE SQL_INTEGER
   CASE SQL_FLOAT
   CASE SQL_REAL
   CASE SQL_DOUBLE
      IF nLen > 19 .AND. nDec > 10 .AND. !(nLen = 38 .AND. nDec = 0)
         nLen := 20
         nDec := 6
      ENDIF
      IF nDec > 3 .AND. !(nLen = 38 .AND. nDec = 0)
         nLen := 14
      ENDIF
      IF !(nLen = 38 .AND. nDec = 0)
         nLen := min(nLen, 20)
         nLen := max(nLen, 1)
      ENDIF
      EXIT
   CASE SQL_DATE
   CASE SQL_TIMESTAMP
   CASE SQL_TYPE_TIMESTAMP
   CASE SQL_TYPE_DATE
   CASE SQL_DATETIME
      nLen := 8
      EXIT
   CASE SQL_TIME
      nLen := 8
      EXIT
   CASE SQL_LONGVARCHAR
   CASE SQL_LONGVARBINARY
   CASE SQL_FAKE_LOB
      nLen := 10
      EXIT
   CASE SQL_GUID
      nLen := 36
   ENDSWITCH

RETURN nLen


FUNCTION orarownum(nCursor)
RETURN aOraClipCursors[nCursor]["curpos"]

FUNCTION oraGoto(n, aDados, nRow)

   LOCAL nRet := 0
   LOCAL e

default aDados to {}
   aOraClipCursors[n]["curpos"] := nRow
   BEGIN SEQUENCE
      aOraClipCursors[n]["curpos"] := nRow
      aDados := aOraClipCursors[n]["ret"][aOraClipCursors[n]["curpos"]]
   RECOVER USING e
      nRet := -1
   END SEQUENCE
RETURN nRet




FUNCTION ORAROWCOUNT(nCursor)
RETURN aOraClipCursors[nCursor]["rowaffected"]







FUNCTION OraFName(n, nPos)

   LOCAL aTmp

if len(aOraClipCursors[n]["aFields"]) == 0 .OR. nPos <=0
   aOraClipCursors[n]["errormsg"]  := "vetor vazio ou Posicao <= 0"
   RETURN NIL
endif
if len(aOraClipCursors[n]["aFields"]) >1 .AND. nPos <= len(aOraClipCursors[n]["aFields"])
   aTmp := aOraClipCursors[n]["aFields"]
   RETURN Alltrim(aTmp[nPos, 1])
endif

   aOraClipCursors[n]["errormsg"]  := "Indice do campo invalido"
RETURN NIL

FUNCTION SR_AdjustNum(a)

   LOCAL b := aClone(a)
   LOCAL i
   LOCAL lNwgOldCompat := .F.

   FOR i := 1 TO len(b)

      //If lNwgOldCompat
         If b[i, 2] = "N"
            b[i, 3] ++
         EndIf
      //EndIf

      If b[i, 2] = "N" .AND. b[i, 3] > 18
         b[i, 3] := 19
      EndIf

      If lNwgOldCompat
         If b[i, 2] = "N" .AND. b[i, 4] >= (b[i, 3] - 1)
            b[i, 4] := abs(b[i, 3] - 2)
         EndIf
      EndIf
      if b[i, 2] == "N" .AND. b[i, 4] >= 5
         b[i, 3] +=4
      endif

      If b[i, 2] = "M"
         b[i, 3] := 10
      EndIf

   NEXT i

RETURN b


STATIC FUNCTION ExecuteSql(csql, cursor, n)
// BEGIN SEQUENCE
//   nError := OraclePrepare(SR_GetConnection():hdbc, cSql, .T.)
// RECOVER USING e
//   nError := -1
// END SEQUENCE
// If nError > 0

    nError := Sqlo_Execute(SR_GetConnection():hdbc, cSql)
//   nError := sr_Getconnection():executeraw(cSql)

   cursor := GETORAHANDLE(SR_GetConnection():hdbc)


// EndIf


RETURN nError

STATIC FUNCTION OraFetch(n)

   LOCAL oSql := sr_getconnection()
   LOCAL hDBC := oSql:hdbc
   LOCAL nError
   LOCAL hDBCHandle := aOraClipCursors[n]["cursor"]
   LOCAL i
   LOCAL aArray
   LOCAL cCampo
   LOCAL cAlias := aOraClipCursors[n]["aliastmp"]
   LOCAL aDb

SETORAHANDLE(hDBC, hDBCHandle)



If aOraClipCursors[n]["curpos"] <= (cAlias)->(RecCount()) .AND. aOraClipCursors[n]["curpos"] <> 0
   (cAlias)->(dBGoto(aOraClipCursors[n]["curpos"]))
Elseif !aOraClipCursors[n]["completed"]

  nError := oSql:Fetch(, aOraClipCursors[n]["aFields"])

  aOraClipCursors[n]["eof"] := nError <> 0
  aOraClipCursors[n]["data"] := {}
  If nError == 0

     aArray := Array(Len(aOraClipCursors[n]["aFields"]))

     (cAlias)->(dBAppend())
     FOR i := 1 TO Len(aOraClipCursors[n]["aFields"])
         (cAlias)->(FieldPut(i, oSql:FieldGet(i, aOraClipCursors[n]["aFields"])))
     NEXT i
     (cAlias)->(dBUnlock())
  Else
//     FOR i := 1 TO len(aOraClipCursors[n]["data"])
       aDb := aOraClipCursors[n]["aFields"]
      FOR i := 1 TO len(aDb)
         SWITCH adb[i, 2]
         CASE "C"
            aadd(aOraClipCursors[n]["data"], "")
            EXIT
         CASE "N"
            aadd(aOraClipCursors[n]["data"], 0)
            EXIT
         CASE "D"
            aadd(aOraClipCursors[n]["data"], ctod(""))
            EXIT
         CASE "L"
            aadd(aOraClipCursors[n]["data"], .F.)
         ENDSWITCH
      NEXT i
         aOraClipCursors[n]["completed"] := .T.
         aOraClipCursors[n]["eof"] := .T.

//          oSql:FreeStatement()
      aOraClipCursors[n]["cursoropen"] := .F.
      SQLO_CLOSESTMT(hDBC)

      if select(aOraClipCursors[n]["aliastmp"]) >0
         (aOraClipCursors[n]["aliastmp"])->(dbclosearea())
         ferase(aOraClipCursors[n]["tmpfile"])
      endif

  EndIf

Else
   (cAlias)->(dBGoto(aOraClipCursors[n]["curpos"]))
EndIf
if select(aOraClipCursors[n]["aliastmp"])>0
   FOR i := 1 TO Len(aOraClipCursors[n]["aFields"])
      AADD(aOraClipCursors[n]["data"], (cAlias)->(FieldGet(i)))
   NEXT i
endif

RETURN nError


STATIC FUNCTION OraFetchSelect(n)

   LOCAL oSql := sr_getconnection()
   LOCAL hDBC := oSql:hdbc
   LOCAL nError
   LOCAL hDBCHandle := aOraClipCursors[n]["cursor"]
   LOCAL i
   LOCAL aArray
   LOCAL cCampo
   LOCAL aret := {}

SETORAHANDLE(hDBC, hDBCHandle)

  nError := oSql:Fetch()
  
  aOraClipCursors[n]["eof"] := nError <> 0

  If nError == 0
   
      aOraClipCursors[n]["data"] := {}

      aArray := Array(Len(aOraClipCursors[n]["aFields"]))
  
     
     FOR i := 1 TO Len(aOraClipCursors[n]["aFields"])
         aadd(aOraClipCursors[n]["data"], oSql:FieldGet(i, aOraClipCursors[n]["aFields"]) )
     NEXT i
     
  Else 

      aOraClipCursors[n]["completed"] := .T.
      aOraClipCursors[n]["cursoropen"] := .F.
//       oSql:FreeStatement()
      SQLO_CLOSESTMT(hDBC)

  EndIf


RETURN nError


STATIC FUNCTION GerGhost(uDat)
if HB_ISCHAR(uDat)
   RETURN ""
elseif HB_ISNUMERIC(uDat)   
   RETURN 0
elseif HB_ISLOGICAL(uDat)
   RETURN .F.
elseif HB_ISDATE(uDat)
   RETURN ctod("")
endif
RETURN ""

FUNCTION getOraclipCursor(ncursor)
RETURN aOraClipCursors[ncursor]

STATIC FUNCTION closecursor(n)

   LOCAL osql := sr_getconnection()
   LOCAL hdbc := osql:hdbc

   BEGIN SEQUENCE
      hDBCHandle := aOraClipCursors[n]["cursor"]
      if aOraClipCursors[n]["cursoropen"]
         SETORAHANDLE(hDBC, hDBCHandle)
//       oSql:FreeStatement()      // fecha  o cursor antes da tabela
         SQLO_CLOSESTMT(hDBC)
         aOraClipCursors[n]["cursoropen"] := .F.
      endif
      if select(aOraClipCursors[n]["aliastmp"]) >0

         (aOraClipCursors[n]["aliastmp"])->(dbclosearea())
         ferase(aOraClipCursors[n]["tmpfile"])
      endif
   RECOVER USING e
   END SEQUENCE
RETURN NIL

#pragma BEGINDUMP

#include "hbapi.h"
#include "hbapiitm.h"

typedef int sqlo_stmt_handle_t;

typedef struct _ORA_BIND_COLS
{
   char * col_name;
   short sVal;
   double  dValue;
   int iType;
   ULONG  ulValue;
   char sDate[7];
   int iValue;
   char sValue[31];
//    OCIRowId * RowId;
} ORA_BIND_COLS ;

typedef struct _OCI_SESSION
{
   int dbh;                      // Connection handler
   int stmt;                     // Current statement handler
   int status;                   // Execution return value
   int numcols;                  // Result set columns
   char server_version[128];
   //bellow for bind vars
   sqlo_stmt_handle_t stmtParam;
   ORA_BIND_COLS *  pLink;
   unsigned int   ubBindNum;
   sqlo_stmt_handle_t stmtParamRes;
   unsigned int uRows;
} OCI_SESSION;

typedef OCI_SESSION * POCI_SESSION;

HB_FUNC( GETORAHANDLE )
{
   OCI_SESSION* p  = ( OCI_SESSION* ) hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

   if ( p ) {
      hb_retni(p->stmt);
   }
}

HB_FUNC( SETORAHANDLE )
{
   OCI_SESSION* p  = ( OCI_SESSION* ) hb_itemGetPtr(hb_param(1, HB_IT_POINTER));

   if( p ) {
      p->stmt = hb_parni(2);
   }
}

#pragma BEGINDUMP
