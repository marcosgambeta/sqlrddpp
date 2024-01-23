REQUEST ADS
#include "ads.ch"

STATIC hHashData := hb_hash()

STATIC TRACE_STRUCT := { ;
                         {"USUARIO",    "C", 10, 0},;
                         {"DATA",       "D", 08, 0},;
                         {"HORA",       "C", 08, 0},;
                         {"CONTADOR",   "C", 01, 0},;
                         {"TRANSCOUNT", "N", 10, 0},;
                         {"PROCESSED",  "L",  1, 0},;
                         {"COMANDO",    "M", 10, 0} ;
                       }

/*
 * xHarbour Project source code:
 * DBEDIT() function
 *
 * Copyright 2003 Mauricio Abre <maurifull@datafull.com>
 * www - http://www.xharbour.org
 * www - http://www.harbour-project.org
 *
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
 * As a special exception, the Harbour Project gives permission for
 * additional uses of the text contained in its release of Harbour.
 *
 * The exception is that, if you link the Harbour libraries with other
 * files to produce an executable, this does not by itself cause the
 * resulting executable to be covered by the GNU General Public License.
 * Your use of that executable is in no way restricted on account of
 * linking the Harbour library code into it.
 *
 * This exception does not however invalidate any other reasons why
 * the executable file might be covered by the GNU General Public License.
 *
 * This exception applies only to the code released by the Harbour
 * Project under the name Harbour.  If you copy code from other
 * Harbour Project or Free Software Foundation releases into a copy of
 * Harbour, as the General Public License permits, the exception does
 * not apply to the code that you add in this way.  To avoid misleading
 * anyone as to the status of such modified files, you must delete
 * this exception notice from them.
 *
 * If you write modifications of your own for Harbour, it is your choice
 * whether to permit this exception to apply to your modifications.
 * If you do not wish that, delete this exception notice.
 *
 */

/*
 * NOTE: This is a total rewrite with all features previous dbedit() had
 *       plus a few more.
 *       It works with or w/o 5.3 extensions
 *       + Using 5.3 extensions gives mouse event handling :)
 *       + Features previous dbedit() had are:
 *         - User func can be a codeblock
 *         - No coords = full screen
 *         - No columns = fill with db structure
 *       + New features in this version:
 *         - Any column can be also a codeblock instead of a string
 *         - Heading/footing separator is single line instead of double line
 *           (see below in the code)
 *         - Columns are movable via K_CTRL_UP / K_CTRL_DOWN
 *         - A column can be an array of 2 items
 *           In this case, the second is the codeblock to do coloring :)
 *         - Userfunc is called with a third parameter, the actual TBRowse object
 *           This is very useful, it increases A LOT the power of dbedit()
 *         - UserFunc is also called once with nMode == -1 (initialization)
 *           Prior to begin browsing
 *         - You can pass pre/post blocks for later using in user func
 *           (combinated with the GET system)
 *
 * DBEdit() is no more deprecated :)
 * Have fun
 *                      Mauricio
 *
 */

#include "dbedit.ch"
#include "inkey.ch"
#include "setcurs.ch"
#include "hbsetup.ch"
#include "common.ch"
#include "tbrowse.ch"

/* E.F. 2006/04/22 - The #define DE_APPEND is for Append mode in dbEdit.
 * I have used tbrowse "cargo" to assign true/false for that.
 * (Append mode is undocumented Clipper's dbEdit feature)
 */

#ifndef DE_APPEND
#define DE_APPEND  3
#endif

#define HB_COMPAT_C53

STATIC nAliasTmp := 0

FUNCTION OraEdit(nCursors, cTable, cWhere, aVarSust, nTop, nLeft, nBottom, ;
   nRight, axColumns, xUserFunc, acColumnSayPictures, acColumnHeaders, ;
   acHeadingSep, acColumnSep, acFootingSep, acColumnFootings, bPreBlock, ;
   bPostBlock )

   LOCAL oTBR
   LOCAL oTBC
   LOCAL i
   LOCAL nRet
   LOCAL nKey
   LOCAL bFunc
   LOCAL nCursor
   LOCAL cHdr
   LOCAL nIndex
   LOCAL lAppend
   LOCAL lExcept
   LOCAL cSql
   LOCAL cCount
   LOCAL n
   LOCAL cBind
   LOCAL nAt
   LOCAL cFile
   LOCAL nPosOrderBY
   LOCAL cCols := ""
   LOCAL nOldArea := Select()
   LOCAL cAlias
   LOCAL cQueryPage := ""
   LOCAL nHigerBound
   LOCAL nLowerBound
   LOCAL nStep := 100
   LOCAL aRet := {}
   LOCAL cFiletoDelete := ""
   LOCAL lInEof := .F.
   LOCAL aTemp
   LOCAL aPk
   LOCAL cdesc := ""
   LOCAL nRecno
   LOCAL lDescIndex := .F.
   LOCAL aTempCols := {}
   LOCAL nApeStart := 1
   LOCAL acolsadded := {}
   LOCAL cTmp

   //hHashData := hb_hash()
   SET SERVER LOCAL
   SR_SetRDDTemp("ADT")
   IF Empty(axColumns) .OR. !HB_ISARRAY(axColumns)
      cCols := " * "
   ELSE
      FOR EACH i IN axColumns
         IF "||" $ I
            cTmp := "TMP" + strzero(nApeStart++, 3)
            cCols += i + " as " + cTmp + ","
            AADD(atempcols, {cTmp, hb_atokens(i, "||"), i})
         ELSE
            cCols += i + ","
         ENDIF
      NEXT

      //cCols := substr(cCols, 1, len(cCols) - 1)

      FOR EACH acolsadded IN aTempCols
         FOR EACH n IN acolsadded[2]
            cCols += n + ","
         NEXT
      NEXT

      aPk := GETPRIMARYKEY(cTable)

      FOR EACH cTmp IN aPk
         IF At(Upper(cTmp), Upper(cCols)) == 0
            cCols += cTmp + ","
         ENDIF
      NEXT

      cCols := substr(cCols, 1, len(cCols) - 1)
   ENDIF

   cSql := "Select  " + cCols + "  from " + cTable
   cCount := "select count(*) from " + cTable

   IF !empty(cWhere) .AND. HB_ISARRAY(aVarSust)

      FOR i := 1 TO len(aVarSust)
         cBind := ":" + alltrim(str(i))
         cWhere := strtran(cWhere, cBind, sr_cdbvalue(aVarSust[i]))
      NEXT i
     // nat := at
   ENDIF
   IF !empty(cWhere)
      IF "ORDER BY" $ upper(cwhere)
         IF " DESC" $ upper(cwhere)
            lDescIndex := .T.
         ENDIF
         nPosOrderBY := AT("ORDER BY" , upper(cwhere))

         IF !"WHERE " $ upper(cWhere) .AND. nPosOrderBY > 1
            cSql += " where " + cWhere
            cCount += " where  " + cWhere
         ELSE
            cSql += "  " + cWhere
            cCount += "  " + cWhere
         ENDIF
      ELSE
         aPk := GETPRIMARYKEY(cTable)
         IF len(aPk) > 0
            FOR EACH aTemp IN aPk
               cdesc += atemp + " ,"
            NEXT
            cdesc := substr(cdesc, 1, len(cdesc) - 1)
         ENDIF
         IF !empty(cDesc)
            cSql += " where " + cWhere + " ORDER BY " +cDesc
            cCount += " where  " + cWhere
         ELSE
            cSql += " where " + cWhere
            cCount += " where  " + cWhere
         ENDIF
      ENDIF
   ELSE
      cSql += " ORDER BY 1"
   ENDIF

   cSql :=  "select * from ( select a.*, rownum r from ( " + cSql + ") a where rownum <= :HigerBound  ) where r >= :LowerBound"
   sr_getconnection():exec(ccount, , .T., @aret)
   IF len(aRet) > 0
      IF aret[1, 1] < 100
         nHigerBound := aret[1, 1]
         nLowerBound := 1
         nStep := aret[1, 1]
      ELSE
         nHigerBound := 100
         nLowerBound :=1
         nStep := 100
      ENDIF
   ELSE
      nHigerBound := 100
      nLowerBound :=1
      nStep := 100
   ENDIF
   fclose(HB_FTEMPCREATE(".", "tmp", , @cFile))
   nRet := DE_CONT
   lAppend := .F.
   hHashData[nAliasTmp] := hb_hash()

   IF nAliasTmp == 0
      cAlias := "tmpedit"
      nAliasTmp++
      hHashData[nAliasTmp] := hb_hash()
      hHashData[nAliasTmp]["cFile"] := strtran(cfile, ".tmp", "")
   ELSE
      cAlias := "tmpedit" + strzero(nAliasTmp, 3)
      nAliasTmp++
      hHashData[nAliasTmp] := hb_hash()
      hHashData[nAliasTmp]["cFile"] := strtran(cfile, ".tmp", "")
   ENDIF
   hHashData[nAliasTmp]["eof"] := .F.
   refreshFullData(csql, cAlias, cfile, nHigerBound, nLowerBound, nStep)

   createkeyfrompk(calias, ctable, lDescIndex) //cria o indice temporatio em cima da pk
   cFiletoDelete := (calias)->(dbinfo(10))
   nLowerBound += nHigerBound

   IF !Used()
#ifdef HB_C52_STRICT
      dbgobottom() /* Clipper compliance: call dbgobotom() to forces error message. */
#else
      /* Call Errorsys() with error 2001 if not database in use. */
      Throw(ErrorNew("DBCMD", 0, 2001, procname(), "Workarea not in use"))
#endif
   ELSEIF eof() .AND. Lastrec() > 0
      /* DbEdit() moves cursor to the bottom record if eof() is reached at init. */
      dbGoBottom()
   ENDIF

   DEFAULT nTop TO 0
   DEFAULT nLeft TO 0
   DEFAULT nRight TO MaxCol()
   DEFAULT nBottom TO MaxRow()

   // NOTE: Heading/footing separator is SINGLE line instead of DOUBLE line
   //       this is because most codepages (unicode too) don't have DOUBLE line chars
   //       so the output is ugly with them
   //
   DEFAULT acHeadingSep TO Chr(196) + Chr(194) + Chr(196)
   DEFAULT acColumnSep  TO " " + Chr(179) + " "
   DEFAULT acColumnFootings TO ""

   IF Empty(axColumns) .OR. !HB_ISARRAY(axColumns)

      axColumns := Array(FCount())

      FOR EACH i IN axColumns
         i := FieldName(i:__EnumIndex())
      NEXT

   ENDIF

   /* 17/05/2006 - E.F. - Check parameters type before continue.
    * 1) Clipper avoid argument values if it is invalid.
    *    xHarbour call a run time error. IMHO this is better solution to
         avoid old errors in code and bad practices inherited from Clipper's days.
    * 2) There is no error base reserved to dbEdit function, then I have
    *    assigned the 1127 for this.
   */

   /* Note: The column's type doesn't need to verify. If any column type is
           invalid or empty, then the dbEdit() will ignore it. */

   IF !HB_IsNil(nTop) .AND. !HB_IsNumeric(nTop)
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(nTop) + ">", Procname() + " <nTop>"))
   ENDIF
   IF !HB_IsNil(nLeft) .AND. !HB_IsNumeric(nLeft)
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(nLeft) + ">", Procname() + " <nLeft>"))
   ENDIF
   IF !HB_IsNil(nBottom) .AND. !HB_IsNumeric(nBottom)
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(nBottom) + ">", Procname() + " <nBottom>"))
   ENDIF
   IF !HB_IsNil(nRight) .AND. !HB_IsNumeric(nRight)
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(nRight) + ">", Procname() + " <nRight>"))
   ENDIF

   nTop    := Max(0, nTop)
   nLeft   := Max(0, nLeft)
   nBottom := Min(MaxRow(), nBottom)
   nRight  := Min(MaxCol(), nRight)

   /* In Clipper the <cUserFunc> paramenter only can be a
    * string or NIL, but in xHarbour can be a codeblock also.
   */
   IF !HB_IsNil(xUserFunc) .AND. (!HB_IsString(xUserFunc) .AND. !HB_IsBlock(xUserFunc) .AND. !HB_IsLogical(xUserFunc))
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(xUserFunc) + ">", Procname() + " <xUserFunc>"))
   ELSE
      IF HB_IsString(xUserFunc) .AND. Empty(xUserFunc)
         xUserFunc := NIL
      ENDIF
      IF HB_IsLogical(xUserFunc) .AND. xUserFunc
         xUserFunc := NIL
      ENDIF
   ENDIF

   IF !HB_IsNil(acColumnSayPictures) .AND. (!HB_IsString(acColumnSayPictures) .AND. !HB_IsArray(acColumnSayPictures))
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(acColumnSayPictures) + ">", Procname() + " <acColumnSayPictures|cColumnSayPicture>"))
   ENDIF

   IF !HB_IsNil(acColumnHeaders) .AND. (!HB_IsString(acColumnHeaders) .AND. !HB_IsArray(acColumnHeaders))
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(acColumnHeaders) + ">", Procname() + " <acColumnHeaders|cColumnHeader>"))
   ENDIF

   IF !HB_IsNil(acHeadingSep) .AND. (!HB_IsString(acHeadingSep) .AND. !HB_IsArray(acHeadingSep))
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(acHeadingSep) + ">", Procname() + " <acHeadingSeparators|cHeadingSeparator>"))
   ENDIF

   IF !HB_IsNil(acColumnSep) .AND. (!HB_IsString(acColumnSep) .AND. !HB_IsArray(acColumnSep))
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(acColumnSep) + ">", Procname() + " <acColumnSeparators|cColumnSeparator>"))
   ENDIF

   IF !HB_IsNil(acFootingSep) .AND. (!HB_IsString(acFootingSep) .AND. !HB_IsArray(acFootingSep))
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(acFootingSep) + ">", Procname() + " <acFootingSeparators|cFootingSeparator>"))
   ENDIF

   IF !HB_IsNil(acColumnFootings) .AND. (!HB_IsString(acColumnFootings) .AND. !HB_IsArray(acColumnFootings))
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(acColumnFootings) + ">", Procname() + " <acColumnFootings|cColumnFooting>"))
   ENDIF

   IF !HB_IsNil(bPreBlock) .AND. !HB_IsBlock(bPreBlock)
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(bPreBlock) + ">", Procname() + " <bPreBlockBlock>"))
   ENDIF

   IF !HB_IsNil(bPostBlock) .AND. !HB_IsBlock(bPostBlock)
      Throw(ErrorNew("BASE", 0, 1127, "Argument type error <" + valtype(bPostBlock) + ">", Procname() + " <bPostBlockBlock>"))
   ENDIF

   IF HB_ISBLOCK(bPreBlock)
      i := bPreBlock
      bPreBlock := Array(Len(axColumns))
      AFill(bPreBlock, i)
   END

   IF HB_ISBLOCK(bPostBlock)
      i := bPostBlock
      bPostBlock := Array(Len(axColumns))
      aFill(bPostBlock, i)
   END

   // Save previous cursor shape and position.
   nCursor := SetCursor(SC_NONE)

   iif(HB_ISNIL(acFootingSep) .AND. !Empty(acColumnFootings), acFootingSep := Chr(196) + Chr(193) + Chr(196), .T.)

   /* 2007/JAN/30 - EF - To avoid dbedit blinking. */
   DispBegin()

   /* Create Tbrowse object */
   oTBR := TBrowseDB(nTop, nLeft, nBottom, nRight)

   /* E.F. 2006/04/22 - Set append mode off by default */
   oTBR:Cargo := .F.

   /* E.F. 2006/04/22 - Use a custom 'skipper' to handle append mode */
   oTBR:SkipBlock := {|x|dbe_Skipper(x, oTBR, calias)}
   //oTBR:SkipBlock := {|x|Skipped(x, lappend)}

   IF HB_ISSTRING(acHeadingSep)
      oTBR:headSep := acHeadingSep
   END

   IF HB_ISSTRING(acFootingSep)
      oTBR:footSep := acFootingSep
   END

   IF HB_ISSTRING(acColumnSep)
     oTBR:colSep := acColumnSep
   END

#ifdef HB_COMPAT_C53
   // EXTENSION: Move columns inside dbedit :)
   oTBR:setKey(K_CTRL_UP, {||_MoveCol(oTBR, K_CTRL_UP), 0})
   oTBR:setKey(K_CTRL_DOWN, {||_MoveCol(oTBR, K_CTRL_DOWN), 0})
#endif

   // Build columns
   //
   FOR EACH i IN axColumns

      IF !Empty(i)

         nIndex := i:__EnumIndex()
         cTmp := ""
         IF "||" $ i
            n := Ascan(atempcols, {|x|x[3] == i})
            IF n > 0
               cTmp := atempcols[n, 1]
            ENDIF
         ENDIF

         IF HB_ISARRAY(i)
            bFunc := IIf(HB_ISBLOCK(i[1]), i[1], &("{||" + i[1] + "}"))
         ELSE
            IF !Empty(cTmp)
               bFunc := IIf(HB_ISBLOCK(cTmp), cTmp, &("{||" + cTmp + "}"))
            ELSE
               bFunc := IIf(HB_ISBLOCK(i), i, &("{||" + i + '}'))
            ENDIF
         ENDIF

         IF HB_ISMEMO(Eval(bFunc))
            bFunc := {||"  <Memo>  "}
         ENDIF

         cHdr := i

         IF HB_ISSTRING(acColumnHeaders)
            cHdr := acColumnHeaders
         ELSEIF HB_ISARRAY(acColumnHeaders) .AND. Len(acColumnHeaders) >= nIndex .AND. acColumnHeaders[nIndex] != NIL // handle empty column headers
            cHdr := acColumnHeaders[nIndex]
         ENDIF

         IF HB_ISBLOCK(cHdr)
            cHdr := "<block>"
         ENDIF

         oTBC := TBColumnNew(cHdr, bFunc)

         IF HB_ISARRAY(i)
            oTBC:colorBlock := i[2]
         ENDIF

         IF HB_ISARRAY(acColumnSep)
            oTBC:colSep := acColumnSep[nIndex]
         ENDIF

         IF HB_ISARRAY(acHeadingSep)
            oTBC:headSep := acHeadingSep[nIndex]
         ENDIF

         IF HB_ISARRAY(acFootingSep)
            oTBC:footSep := acFootingSep[nIndex]
         ENDIF

         IF HB_ISARRAY(acColumnFootings)
            oTBC:footing := acColumnFootings[nIndex]
         ELSEIF HB_ISSTRING(acColumnFootings)
            oTBC:footing := acColumnFootings
         ENDIF

         IF HB_ISARRAY(acColumnSayPictures) .AND. Len(acColumnSayPictures) >= nIndex
            oTBC:picture := acColumnSayPictures[nIndex]
         ELSEIF HB_ISSTRING(acColumnSayPictures)
            oTBC:picture := acColumnSayPictures
         ENDIF

         IF HB_ISARRAY(bPreBlock)

            IF HB_ISLOGICAL(bPreBlock[nIndex])
               bPreBlock[nIndex] := IIf(bPreBlock[nIndex], {||.T.}, {||.F.})
            ENDIF

            oTBC:preBlock := bPreBlock[nIndex]

         ENDIF

         IF HB_ISARRAY(bPostBlock)

            IF HB_ISLOGICAL(bPostBlock[nIndex])
               bPostBlock[nIndex] := IIf(bPostBlock[nIndex], {||.T.}, {||.F.})
            ENDIF

            oTBC:postBlock := bPostBlock[nIndex]

         ENDIF

         oTBR:addColumn(oTBC)

      ENDIF

   NEXT

   DispEnd()

   IF Len(axColumns) == 1
      oTBR:setKey(K_LEFT, NIL)
      oTBR:setKey(K_RIGHT, NIL)
   ENDIF

   IF Empty(xUserFunc)
      bFunc := {||IIf(HB_ISNUMERIC(nKey) .AND. (Chr(LastKey()) $ Chr(K_ESC) + Chr(K_ENTER)), DE_ABORT, DE_CONT)}
   ELSEIF !HB_IsLogical(xUserFunc)
      bFunc := IIf(HB_ISBLOCK(xUserFunc), xUserFunc, &("{|x, y, z|" + xUserFunc + "(x,y,z)}"))
      oTBR:setKey(K_ESC, NIL)
   ENDIF

#ifdef HB_EXTENSION
   // xHarbour extension: call UDF with DE_INIT mode.
   nRet := dbe_CallUDF(bFunc, DE_INIT, oTBR:colPos, , oTBR, csql, cCount, cfile, calias, @nHigerBound, @nLowerBound, nStep, cTable)
#endif

   oTBR:ForceStable()
   oTBR:DeHilite()

   IF hb_IsLogical(xUserFunc) .AND. xUserFunc = .F.
      nRet := DE_ABORT
   ENDIF

   nKey := 0
   lAppend := oTBR:Cargo
   lExcept := .F.

   /////////////////////
   // PROCESSING LOOP //
   /////////////////////

   DO WHILE nRet != DE_ABORT

      IF nRet = DE_CONT

         oTBR:RefreshCurrent()
         //oTBR:RefreshAll()

      ELSEIF nRet = DE_REFRESH

         oTBR:RefreshAll()

         IF lAppend
            lAppend := .F.
            oTBR:Cargo := .F.
            oTBR:GoBottom()
         ENDIF

         nRet := DE_CONT

      ENDIF

      oTBR:ForceStable()
      IF (eof() .OR. hHashData[nAliasTmp]["eof"])

         nRecno := recno()

         sr_getconnection():exec(ccount, , .T., @aret)
         IF len(aRet) >0
            IF (calias)->(lastrec()) < aret[1, 1]
               nHigerBound += nStep
               refreshFullData(csql, cAlias, cfile, nHigerBound, nLowerBound, nStep)
               nLowerBound += nStep
               otbr:refreshall()
               dbgoto(nrecno)
               oTbr:forcestable()
               oTbr:down():forcestable()
            ENDIF
         ENDIF
         //oTbr:up():forcestable()
      ENDIF
      hHashData[nAliasTmp]["eof"] := .F.
      IF nRet = DE_CONT

         IF !lExcept

            IF dbe_emptydb()
               nRet := dbe_CallUDF(bFunc, DE_EMPTY, oTBR:colPos, GetCurValue(calias), oTBR, csql, cCount, cfile, calias, @nHigerBound, @nLowerBound, nStep, cTable)

            ELSEIF oTBR:HitTop
               oTBR:HitTop := .F.
               nRet := dbe_CallUDF(bFunc, DE_HITTOP, oTBR:colPos, GetCurValue(calias), oTBR, csql, cCount, cfile, calias, @nHigerBound, @nLowerBound, nStep, cTable)

            ELSEIF oTBR:HitBottom
               oTBR:HitBottom := .F.
               nRet := dbe_CallUDF(bFunc, DE_HITBOTTOM, oTBR:colPos, GetCurValue(calias), oTBR, csql, cCount, cfile, calias, @nHigerBound, @nLowerBound, nStep, cTable)

            ENDIF

         ELSE

            //nRet := dbe_CallUDF(bFunc, DE_EXCEPT, oTBR:colPos, GetCurValue(calias), oTBR, , , , , , , cTable)
            lExcept := .F.
            IF lastkey() == K_ENTER
               oTBR:RefreshCurrent()
            ENDIF
         ENDIF

         // No keystrokes pending...
         IF NextKey() = 0
            dbe_CallUDF(bFunc, DE_IDLE, oTBR:colPos, GetCurValue(calias), oTBR, csql, cCount, cfile, calias, @nHigerBound, @nLowerBound, nStep, cTable)
            // force dbedit DE_CONT state after IDLE mode.
            nRet := DE_CONT
         ENDIF

      ENDIF

      IF nRet == DE_ABORT
         EXIT

      ELSEIF nRet == DE_REFRESH
         LOOP

      //ELSEIF nRet == DE_APPEND .AND. !oTBR:Cargo
      //
      //   oTBR:Cargo := .T.
      //   lAppend := .T.
      //
      //   IF !eof() .OR. !dbe_emptydb()
      //      oTBR:Down()
      //   ENDIF
      //
      //   oTBR:RefreshCurrent()
      //   oTBR:ForceStable()
      //   nRet := DE_CONT

      ENDIF

      oTBR:Hilite()

      IF Nextkey() != 0
         nKey := Inkey()
      ELSE
         nKey := Inkey(0)
      ENDIF

      IF nKey != 0

         nRet := dbe_CallUDF(bFunc, DE_EXCEPT, oTBR:colPos, GetCurValue(calias), oTBR, csql, cCount, cfile, calias, @nHigerBound, @nLowerBound, nStep, ctable)

         IF nRet == DE_ABORT
            EXIT
         ENDIF

         IF dbe_ProcessKey(nKey, oTBR) = DE_ABORT
            EXIT
         ENDIF

         IF HB_ISBLOCK(SetKey(nKey))
            Eval(SetKey(nKey), ProcName(1), ProcLine(1), "")
         ENDIF

         lExcept := !dbe_cursorkey(nKey)

      ENDIF

   ENDDO

   SetCursor(nCursor)
   SetPos(row(), 0)
   IF select(cAlias ) > 0
      (cAlias)->(dbclosearea())
   ENDIF
   IF nOldArea > 0
      select(nOldArea)
   ENDIF
   IF file(hHashData[nAliasTmp]["cFile"] + "sqllog.dbf")
      ferase(hHashData[nAliasTmp]["cFile"] + "sqllog.dbf")
      ferase(hHashData[nAliasTmp]["cFile"] + "sqllog.dbt")
   ENDIF
   IF nAliasTmp > 0
      nAliasTmp--
   ENDIF
   ferase(cFiletoDelete)
   IF file(strtran(cFiletoDelete, ".tmp", ".adi"))
      ferase(strtran(cFiletoDelete, ".tmp", ".adi"))
   ENDIF

/* Clipper's NG says that DBEdit always returns NIL, but doesn't. */
RETURN 0 //.T.

//-----------------------------------------------------//
STATIC FUNCTION dbe_CallUDF(bFunc, nMode, nColPos, avalue, oTBR, csql, cCount, cfile, calias, nHigerBound, nLowerBound, nStep, cTable)
//-----------------------------------------------------//

   LOCAL nRet
   LOCAL nRec
   LOCAL nKey
   LOCAL nLastRec
   LOCAL lDeleted
   LOCAL lChanged
   LOCAL aret := {}
   LOCAL aField
   LOCAL aVal
   LOCAL cValues
   LOCAL aValues := {}

   nRet := DE_CONT

   IF nMode == DE_INIT

      nKey := NextKey()

      IF nKey == K_ENTER .OR. nKey == K_ESC
         inkey()
         RETURN DE_ABORT
      ENDIF

      DO WHILE nKey != 0
         inkey()
         dbe_ProcessKey(nKey, oTBR)
         nRet := dbe_return(Eval(bFunc, DE_EXCEPT, nColPos, GetCurValue(calias)))
         IF nRet == DE_ABORT
            EXIT
         ELSEIF nRet == DE_REFRESH
            //refreshFullData(csql, calias)
            oTBR:RefreshAll()
            oTBR:ForceStable()
         ELSEIF nRet == DE_CONT
            oTBR:RefreshCurrent()
            oTBR:ForceStable()
         ENDIF
         nKey := NextKey()
      ENDDO

      IF nRet != DE_ABORT
         nRet := dbe_return(Eval(bFunc, DE_INIT, nColPos, GetCurValue(calias), oTBR))
      ENDIF

      RETURN nRet

   ELSEIF nMode == DE_EXCEPT

      oTBR:DeHilite()
      oTBR:ColorRect({oTBR:rowpos, oTBR:colpos, oTBR:rowpos, oTBR:colpos}, {1, 2})

   ELSEIF nMode == DE_IDLE .OR. nMode == DE_EMPTY

      KEYBOARD chr(0)
      inkey()

   ENDIF

   lDeleted := Deleted()
   nRec     := RecNo()
   nLastRec := (cAlias)->(LastRec())

   // Call UDF
   aValues := GetCurValue(calias)
   nkey := lastkey()
   IF nKey == K_ENTER .OR. nKey == K_DEL
      GETREFRESHCURVALUE(cAlias, ctable)
      aValues := GetCurValue(calias)
   ENDIF
   SR_StartLog()
   nRet := dbe_return(Eval(bFunc, nMode, nColPos,  aValues, oTBR))
   SR_StopLog()

   IF nRet == DE_REFRESH

      IF nKey == K_DEL
         if IsPrimaryKeyDeleted(cAlias, cTable)
            (calias)->(rlock())
            (calias)->(dbdelete())
            (calias)->(dbunlock())
         ENDIF
         sr_getconnection():Exec(cCount, , .T., @aret)
      ELSEIF nKey == K_INS

         //nHigerBound++
         //refreshFullData(csql, cAlias, cfile, nHigerBound, nLowerBound, nStep)
         //nLowerBound += 1
         //nLastRec := (cAlias)->(LastRec())
         insertupdated(cAlias, cTable)
         otbr:refreshall()
         //cSql := sr_getconnection():cLastcomm
         //IF upper(ctable) $ upper(cSql) .AND. "INSERT" $ upper(cSql )
         //   cValues := substr(cSql, at("VALUES", upper(cSql)))
         //   cSql := strtran(csql, cvalues, "")
         //   cvalues := alltrim(values)
         //   cSql := alltrim(cSql)
         //   cSql := substr(csql, at("(", csql) + 1)
         //   csql :=strtran(csql, ")", "")
         //   cvalues := alltrim(cvalues)
         //   cvalues := substr(cvalues, at("(", cvalues) + 1)
         //   cvalues :=strtran(cvalues, ")", "")
         //   aField := hb_atokens(csql, ",")
         //   aVal := hb_atokens(cvalues, ",")
         //   (calias)->(dbappend())
         //   FOR i := 1 TO len(afield)
         //      BEGIN SEQUENCE WITH __BreakBlock()
         //         (calias)->(fieldput((calias)->(fieldpos(aField[i])), aval[i]))
         //      RECOVER
         //      END SEQUENCE
         //   NEXT i
         //ENDIF
         //
         sr_getconnection():Exec(cCount, , .T., @aret)
         //
      ELSE
         IF nKey == K_ENTER
            GETREFRESHCURVALUE(cAlias, cTable)
            //aValues := GetCurValue(calias)
         ENDIF
         sr_getconnection():Exec(cCount, , .T., @aret)
      ENDIF

   ENDIF
   // A change was occurred on UDF (append, delete or skip).
   lChanged := (nLastRec != (cAlias)->(lastrec()) .OR. Deleted() != lDeleted .OR. nRec != Recno())

   IF len(aret ) > 0 .AND. nRet == DE_REFRESH
      lChanged := lChanged .OR. reccount() != aret[1, 1]
   ENDIF
   IF nRet == DE_ABORT .OR. nRet = DE_APPEND
      RETURN nRet
   ENDIF

   // The UDF has changed db/record, so dbedit need to be refreshed.
   IF nRet == DE_REFRESH
      //refreshFullData(csql, calias, cfile)
      otbr:refreshall()
   ENDIF
   IF lChanged

      IF (cAlias)->(LastRec()) > nLastRec // append.

         nKey := nextkey()
         //refreshFullData(csql, calias)

         IF (nKey != 0 .AND. !dbe_CursorKey(nKey)) .OR. (calias)->(ordkeyno()) < oTBR:RowPos
            oTBR:Gotop()
         ENDIF
         //IF (Set(_SET_DELETED) .AND. Deleted()) .OR. (!Empty(dbfilter()) .AND. !&(dbFilter()))
         //   dbSkip()
         //ENDIF
         //IF EOF()
         //   dbGoBottom()
         //ENDIF
         //
         //otbr:forceStable()
         //

      ELSEIF (calias)->(LastRec()) < nLastRec .OR. aret[1, 1] < (calias)->(reccount()) // pack

         oTBR:RowPos := 1

      ELSEIF (calias)->(Deleted()) .AND. (cAlias)->(LastRec()) != 0 .OR. aret[1, 1] <= (calias)->(reccount()) // deleted

         IF SET(_SET_DELETED)
            DO WHILE !eof() .AND. deleted()
               dbSkip()
            ENDDO
         ELSE
            dbe_syncpos(oTBR)
         ENDIF

      ELSEIF nRec != Recno() // moved.

         dbe_syncpos(oTBR)

      ENDIF

      IF (eof() .AND. (cAlias)->(LastRec()) > 0)

         dbskip(-1)

         oTBR:Up():forceStable()
         //hHashData[calias]["eof"] := .F.
         // // dbgobottom()
         //culik comentado para teste
         //nHigerBound += nStep
         //refreshFullData(csql, cAlias, cfile, nHigerBound, nLowerBound, nStep)
         //nLowerBound += nStep
      ENDIF

      nRet := DE_REFRESH

   ENDIF
   IF eof()
      //dbskip(-1)

      //oTBR:Up():forceStable()
      //culik comentado para teste
      //nHigerBound += nStep
      //refreshFullData(csql, cAlias, cfile, nHigerBound, nLowerBound, nStep)
      //nLowerBound += nStep
   ELSEIF bof()
      //IF nHigerBound > nStep
      //   nHigerBound -= nStep
      //   nLowerBound -= nStep
      //   refreshFullData(csql, cAlias, cfile, nHigerBound, nLowerBound, nStep)
      //   nLowerBound += nStep
      //ELSE
      //   nLowerBound :=100
      //   nLowerBound := 1
      //   refreshFullData(csql, cAlias, cfile, nHigerBound, nLowerBound, nStep)
      //   nLowerBound += nStep
      //ENDIF
      //
   ENDIF

RETURN nRet

/***
*
*  dbe_Skipper()
*
*  Handle record movement requests from Tbrowse object.
*
*  This is a special "skipper" that handles append mode. It
*  takes two parameters instead of the usual one. The second
*  parameter is a reference to the Tbrowse object itself. The
*  Tbrowse's "cargo" variable contains information on whether
*  append mode is turned on. This function was based from:
*  clipper\source\samples\tbdemo.prg
*/

//---------------------------------------//
STATIC FUNCTION dbe_Skipper(nSkip, oTb, calias)
//---------------------------------------//

   LOCAL lAppend := oTb:Cargo
   LOCAL i := 0

   lEof := .F.
   DO CASE
   CASE (nSkip = 0 .OR. lastrec() = 0)
      // Skip 0 (significant on a network)
      dbSkip(0)
   CASE (nSkip > 0 .AND. !eof())
      DO WHILE (i < nSkip) // Skip Foward
         dbskip(1)
         i++
         IF eof() .AND. !lAppend
            hHashData[nAliastmp]["eof"] := .T.
            dbskip(-1)
            i--
            EXIT
         ENDIF
      ENDDO
   CASE (nSkip < 0)
      DO WHILE (i > nSkip) // Skip backward
         dbskip(-1)
         IF bof()
            EXIT
         ENDIF
         i--
      ENDDO
   ENDCASE

RETURN i

#ifdef HB_COMPAT_C53
STATIC FUNCTION _MoveCol(oTBR, nKey)

   LOCAL oTBR1
   LOCAL oTBR2

   IF nKey == K_CTRL_DOWN .AND. oTBR:colPos < oTBR:colCount
      oTBR1 := oTBR:getColumn(oTBR:colPos)
      oTBR2 := oTBR:getColumn(oTBR:colPos + 1)
      oTBR:setColumn(oTBR:colPos, oTBR2)
      oTBR:SetColumn(oTBR:colPos + 1, oTBR1)
      oTBR:colPos++
      oTBR:invalidate()
   ELSEIF nKey == K_CTRL_UP .AND. oTBR:colPos > 1
      oTBR1 := oTBR:getColumn(oTBR:colPos)
      oTBR2 := oTBR:getColumn(oTBR:colPos - 1)
      oTBR:setColumn(oTBR:colPos, oTBR2)
      oTBR:SetColumn(oTBR:colPos - 1, oTBR1)
      oTBR:colPos--
      oTBR:invalidate()
   ENDIF

RETURN NIL
#endif

//-----------------------------------//
STATIC FUNCTION dbe_emptydb()
//-----------------------------------//
// Verify if the current dbf is empty.
//------------------------------------*

   LOCAL lEmpty

   IF LastRec() == 0
      RETURN .T.
   ENDIF

   IF !Empty(dbFilter())
      lEmpty := (Eof() .OR. Recno() > Lastrec())
   ELSEIF IndexOrd() == 0
      lEmpty := ((Eof() .OR. Recno() > LastRec()) .AND. Bof())
   ELSE
      //lEmpty := (OrdKeyCount() == 0) // this code decrease dbedit's speed at large table.
      lEmpty := (OrdKeyNo() == 0)
   ENDIF

RETURN lEmpty

//----------------------------------------//
STATIC FUNCTION dbe_processKey(nKey, oTb)
//----------------------------------------//

   LOCAL nRet := DE_CONT

#ifdef HB_COMPAT_C53
   IF oTb:ApplyKey(nKey) == TBR_EXIT
      nRet := DE_ABORT
   ENDIF
#else
   // xHarbour without 5.3 extensions code
   SWITCH nKey
   CASE K_DOWN       ; oTb:down()     ; EXIT
   CASE K_UP         ; oTb:up()       ; EXIT
   CASE K_LEFT       ; oTb:left()     ; EXIT
   CASE K_RIGHT      ; oTb:right()    ; EXIT
   CASE K_PGDN       ; oTb:pageDown() ; EXIT
   CASE K_PGUP       ; oTb:pageUp()   ; EXIT
   CASE K_CTRL_PGUP  ; oTb:goTop()    ; EXIT
   CASE K_CTRL_PGDN  ; oTb:goBottom() ; EXIT
   CASE K_HOME       ; oTb:home()     ; EXIT
   CASE K_END        ; oTb:end()      ; EXIT
   CASE K_CTRL_HOME  ; oTb:panHome()  ; EXIT
   CASE K_CTRL_END   ; oTb:panEnd()   ; EXIT
   CASE K_CTRL_LEFT  ; oTb:panLeft()  ; EXIT
   CASE K_CTRL_RIGHT ; oTb:panRight() ; EXIT
   ENDSWITCH
#endif

RETURN nRet

//--------------------------------//
STATIC FUNCTION dbe_Return(n)
//--------------------------------//

   IF !hb_isnumeric(n)
      n := DE_CONT
   ELSEIF n < DE_ABORT .OR. n > DE_APPEND
      n := DE_CONT
   ENDIF

RETURN n

//----------------------------------//
STATIC FUNCTION dbe_cursorkey(nKey)
//----------------------------------//

   LOCAL aKeys := {K_LEFT, ;
                   K_RIGHT, ;
                   K_CTRL_LEFT, ;
                   K_CTRL_RIGHT, ;
                   K_UP, ;
                   K_DOWN, ;
                   K_HOME, ;
                   K_END, ;
                   K_CTRL_HOME, ;
                   K_CTRL_END, ;
                   K_PGUP, ;
                   K_PGDN, ;
                   K_CTRL_PGUP, ;
                   K_CTRL_PGDN}

RETURN (AScan(aKeys, nKey) != 0)

//------------------------------//
STATIC FUNCTION dbe_syncpos(oTb)
//------------------------------//

   LOCAL nRec := Recno()
   LOCAL nKeyNo := 0
   LOCAL nDel := 0
   LOCAL lDeleted := .F.

   IF IndexOrd() != 0

      nKeyNo := OrdKeyNo()
      dbSkip(-1)

      IF bof()
         oTb:RowPos := 1
      ELSE
         lDeleted := Set(_SET_DELETED, .F.)
         IF !lDeleted
            dbGoto(nRec)
            oTb:RowPos := nKeyNo
         ELSE
            dbGotop()
            DO WHILE !eof() .AND. recno() != nRec
               IF deleted()
                  nDel++
               ENDIF
               dbskip()
            ENDDO
            dbGoto(nRec)
            oTb:RowPos := nKeyNo - nDel
         ENDIF
         Set(_SET_DELETED, lDeleted)
      ENDIF

   ELSE

      IF nRec < oTb:RowCount
         oTb:RowPos := nRec
      ENDIF

   ENDIF

RETURN NIL

FUNCTION GetCurValue(calias)

   LOCAL n
   LOCAL aTemp := {}

   FOR n := 1 TO (cAlias)->(fcount())
      aadd(aTemp,(cAlias)->(fieldget(n)))
   NEXT n
   aadd(aTemp,(calias)->(recno()))

RETURN aTemp

STATIC FUNCTION refreshFullData(csql, cAlias, cfile, nHigh, nLow, nStep)

   LOCAL nRecno := 0
   LOCAL ckey
   LOCAL nBeforeTotRec := 0
   LOCAL nAfterRec := 0

   DEFAULT cFile TO (calias)->(dbinfo(10))

   //IF select(caLias) > 0
   //   ZAP
   //ENDIF
   //cSql := strtran(csql, ":HigerBound", str(nHigh))
   //cSql := strtran(csql, ":LowerBound", str(nLow))
   //
   //sr_getconnection():exec(cSql, , .T., , cfile, cAlias)
   //(calias)->(dbgotop())
   nBeforeTotRec := (calias)->(reccount())
   IF select(caLias) > 0
      IF (calias)->(eof())
         nRecno := nBeforeTotRec
      ELSE
         nRecno := (calias)->(recno())
      ENDIF
   ENDIF
   cSql := strtran(csql, ":HigerBound", str(nHigh))
   cSql := strtran(csql, ":LowerBound", str(nLow))

   sr_getconnection():exec(cSql, , .T., , cfile, cAlias)
   nAfterRec := (calias)->(reccount())

   IF nAfterRec > nrecno .AND. nBeforeTotRec<nAfterRec
      IF nrecno == 0
         (calias)->(dbgotop())
      ELSE
         (calias)->(dbgoto(nrecno + 1))
      ENDIF
   ENDIF

RETURN NIL

FUNCTION GETPRIMARYKEY(cTable)

   LOCAL aRet := {}
   LOCAL aFields := {}
   LOCAL aTemp
   LOCAL cSql

   IF "." $ CTABLE
      CSQL :=  "SELECT cols.table_name, cols.column_name, cols.position, cons.status, cons.owner FROM all_constraints cons, all_cons_columns cols WHERE cols.table_name = " + sr_cdbvalue(upper(alltrim(SUBSTR(cTable, AT('.', CTABLE) + 1))) ) + " AND cons.constraint_type = 'P' AND cons.constraint_name = cols.constraint_name AND cons.owner = cols.owner ORDER BY cols.table_name, cols.position"
   ELSE
      CSQL :=  "SELECT cols.table_name, cols.column_name, cols.position, cons.status, cons.owner FROM all_constraints cons, all_cons_columns cols WHERE cols.table_name = " + sr_cdbvalue(upper(alltrim(cTable)) ) + " AND cons.constraint_type = 'P' AND cons.constraint_name = cols.constraint_name AND cons.owner = cols.owner ORDER BY cols.table_name, cols.position"
   ENDIF
   sr_getconnection():exec(cSql, , .T., @aret)
   IF len(aRet) > 0
      FOR EACH aTemp IN aRet
         aadd(aFields, alltrim(aTemp[2]))
      NEXT
   ENDIF

RETURN aFields

FUNCTION GETREFRESHCURVALUE(calias, ctable)

   //LOCAL cTable := (calias)->(dbinfo(10))
   LOCAL aFields := GETPRIMARYKEY(cTable)
   LOCAL aFields2
   LOCAL aTemp
   LOCAL i := 1
   LOCAL cSql := ""
   LOCAL aret := {}
   LOCAL adb := (calias)->(dbstruct())
   LOCAL nPos
   LOCAL ckey
   LOCAL aTmp

   IF len(aFields) > 0
      cSql := "select * from " + ctable
      cSql += " where "

      FOR EACH aTemp IN aFields
         cKey := (calias)->(fieldGet((cAlias)->(fieldpos(aTemp))))
         IF empty(ckey)
            cSql += " " + aTemp  + " is null "
         ELSE
            cSql += " " + aTemp  + " = " + sr_cdbvalue(ckey)
         ENDIF
         cSql += " AND "
      NEXT
      cSql := substr(cSql, 1, len(csql) - 4)

      sr_getconnection():exec(cSql, , .T., @aret)
      aFields2 := sr_getconnection():aFields
      IF len(aret) > 0
         (calias)->(rlock())
         aTemp := aret[1]
         FOR EACH aTmp IN aFields2
            nPos := ascan(adb,{|x|x[1] == aFields2[i, 1]})
            IF nPos > 0
               (cAlias)->(fieldput((cAlias)->(fieldpos(adb[nPos, 1])), aTemp[i]))
            ENDIF
            i++
         NEXT
         (calias)->(dbunlock())
         nrecno := (calias)->(recno())
         (calias)->(dbgoto(nrecno))
      ENDIF
   ENDIF

RETURN NIL

FUNCTION GETREFRESHCURINSVALUE(calias, ctable, calias2)

   //LOCAL cTable := (calias)->(dbinfo(10))
   LOCAL aFields := GETPRIMARYKEY(cTable)
   LOCAL aFields2
   LOCAL aTemp
   LOCAL i := 1
   LOCAL cSql := ""
   LOCAL aret := {}
   LOCAL nrec
   LOCAL uDat
   LOCAL cfile := (calias2)->(dbinfo(10))
   LOCAL cfield
   LOCAL aTmpField
   LOCAL nposf
   LOCAL aTmp

   IF len(aFields) > 0
      cSql := "select * from " + ctable
      cSql += " where "

      FOR EACH aTemp IN aFields
         cSql += " " + aTemp  + " = " + sr_cdbvalue((calias)->(fieldGet((cAlias)->(fieldpos(aTemp)))))
         cSql += " AND "
      NEXT

      cSql := substr(cSql, 1, len(csql) - 4)
      //corrigido neste ponto
      //sr_getconnection():exec(cSql, , .T., , cfile, cAlias2, 1)
      //(calias2)->(dbgobottom())
      //endif

      sr_getconnection():exec(cSql, , .T., @aret)
      aFields2 := sr_getconnection():aFields

      IF len(aret) > 0
   
         //FOR EACH aTemp IN aRet
         (calias2)->(dbappend())
         //tracelog(valtoprg(atemp), aFields2[i, 1])
         i := 1
         aTemp := aret[1]
         FOR EACH aTmpField IN aFields2
            cField := aTmpField[1]
            nposf := (cAlias2)->(fieldpos(cField))
            (cAlias2)->(fieldput(nposf, aTemp[i]))
            ++i
         NEXT
         (calias2)->(dbcommit())
         (calias2)->(dbunlock())
         //NEXT
   
         //nrec := (cAlias2)->(recno())
         //(calias2)->(dbgoto(nrec))
   
      ENDIF

   ENDIF

RETURN NIL

FUNCTION IsPrimaryKeyDeleted(calias, cTable)

   LOCAL aret := {}
   LOCAL aFields := GETPRIMARYKEY(cTable)
   LOCAL aFields2
   LOCAL aTemp
   LOCAL i := 1
   LOCAL cSql := ""
   LOCAL nFieldPos
   LOCAL xVal

   IF len(aFields) > 0
      cSql := "select * from " + ctable
      cSql += " where "
      FOR EACH aTemp IN aFields
         nFieldPos := (cAlias)->(fieldpos(aTemp))
         xval := (calias)->(fieldGet(nfieldPos))
         IF empty(xval)
            cSql += " " + aTemp + " is null "
         ELSE
            cSql += " " + aTemp + " = " + sr_cdbvalue(xVal)
         ENDIF
         cSql += " AND "
      NEXT
      cSql := substr(cSql, 1, len(csql) - 4)

      sr_getconnection():exec(cSql, , .T., @aret)
      IF len(aRet ) == 0
         RETURN .T.
      ENDIF
   ENDIF

RETURN .F.

FUNCTION insertupdated(calias, ctable)

   LOCAL aFields := GETPRIMARYKEY(cTable)
   LOCAL cFields := ""
   LOCAL cDesc := ""
   LOCAL ctemp := (calias)->(dbinfo(10))
   LOCAL cFileDrive := substr(cTemp, 1, rat("\", cTemp) - 2)
   LOCAL cFile := substr(cTemp, rat("\", cTemp) + 1)
   LOCAL aVal
   LOCAL cSqlTmp := ""
   LOCAL aTemp
   LOCAL atemp2 := {}
   LOCAL adb := (calias)->(dbstruct())
   LOCAL nPos
   LOCAL i := 1
   LOCAL nrec
   LOCAL cInsert := ""
   LOCAL csql := ""
   LOCAL cvalues := ""
   LOCAL aField

   cFile := substr(cfile, 1, at(".", cfile) - 1)
   IF len(aFields) > 0
      FOR EACH aTemp IN afields
         cFields += aTemp + ","
         cdesc += atemp + " DESC,"
         nPos := ascan(adb,{|x|upper(x[1]) == aTemp})
         IF nPos >0
            aadd(aTemp2, adb[npos, 2])
         ENDIF
      NEXT
      cdesc := substr(cdesc, 1, len(cdesc) - 1)
      cFields := substr(cFields, 1, len(cFields) - 1)
      cSql :=GetLastInsertCommand(cTable)

      IF !empty(cSql)
         cValues := substr(cSql, at("VALUES", upper(cSql)))
         cSql := strtran(csql, cvalues, "")
         cvalues := alltrim(cvalues)
         cSql := alltrim(cSql)
         cSql := substr(csql, at("(", csql) + 1)
         csql :=strtran(csql, ")", "")

         cSql := alltrim(cSql)
         cvalues := alltrim(cvalues)
         cvalues := substr(cvalues, at("(", cvalues) + 1)
         cvalues :=strtran(cvalues, ")", "")
         //cvalues := strtran(cvalues, "'", "")
         aField := hb_atokens(csql, ",")
         aVal := hb_atokens(cvalues, ",")
         //(calias)->(dbappend())
         //FOR i := 1 TO len(afield)
         //   BEGIN SEQUENCE WITH __BreakBlock()
         //      (calias)->(fieldput((calias)->(fieldpos(aField[i])), aval[i]))
         //   RECOVER
         //   END SEQUENCE
         //NEXT i

         cSql := "select " + cfields + " from " + cTable  + " where "
         FOR EACH aTemp IN aFields
            nPos := ascan(afield,{|x|upper(x) == upper(aTemp)})
            IF nPos > 0
               IF "TO_DATE(" $ upper(aval[npos])
                  aval[nPos] := substr(aval[npos], at("TO_DATE(", upper(aval[nPos])) + 8)
                  aval[npos] := strtran(aval[npos], "'", "")
                  aval[npos] := stod(aval[npos])
               ENDIF
               IF HB_ISCHAR(aval[npos])
                  cSql += " " + aTemp  + " = " +  aVal[nPos]
               ELSEIF HB_ISNUMERIC(aval[npos]) .OR. HB_ISDATE(aval[npos])
                  cSql += " " + aTemp  + " = " +  sr_cdbvalue(aVal[nPos])
               ENDIF
               cSql += " AND "
            ENDIF
         NEXT
         cSql := substr(cSql, 1, len(csql) - 4)
      ELSE
         csql := "select " + cfields + " from " + ctable + " where rownum <4  order by " + cDesc
      ENDIF
      USE (csql) NEW alias "INSSQLTMP" VIA "SQLRDD"
      if INSSQLTMP->(reccount()) > 0

         inssqltmp->(dbgotop())
         DO WHILE !inssqltmp->(eof())
            cSqlTmp := ""
            i := 1
            FOR EACH aTemp IN aFields
               nPos := ascan(adb,{|x|upper(x[1]) == aTemp})
               IF nPos > 0
                  IF inssqltmp->(fieldtype(i)) == "C"
                     cSqlTmp += inssqltmp->(fieldget(i))
                  ELSEIF inssqltmp->(fieldtype(i)) == "N"
                     IF adb[npos, 4] > 0
                        cSqlTmp += str(inssqltmp->(fieldget(i)), adb[npos, 3], adb[npos, 4])
                     ELSE
                        cSqlTmp += str(inssqltmp->(fieldget(i)), adb[npos, 3])
                     ENDIF
                  ELSEIF inssqltmp->(fieldtype(i)) == "D"
                     cSqlTmp += dtos(inssqltmp->(fieldget(i)))
                  ENDIF
               ENDIF
               i++
            NEXT

            //USE (cSqlTmp) NEW Alias "INSSQLTMP2" VIA "ADSADT"

            IF !(calias)->(dbseek(csqltmp))
               GETREFRESHCURINSVALUE("INSSQLTMP", ctable, calias)
            ENDIF

            //endif
            INSSQLTMP->(dbskip())
         ENDDO
      ENDIF
      INSSQLTMP->(dbclosearea())
   ENDIF

   //(calias)->(dbgoto((calias)->(lastrec())))
   select(calias)

RETURN NIL

//(calias)->(dbappend())
//FOR i := 1 TO len(afield)
//   BEGIN SEQUENCE WITH __BreakBlock()
//      (calias)->(fieldput((calias)->(fieldpos(aField[i])), aval[i]))
//   RECOVER
//   END SEQUENCE
//NEXT i

FUNCTION createkeyfrompk(calias, ctable, lDescIndex)

   LOCAL aFields := GETPRIMARYKEY(cTable)
   LOCAL aTemp
   LOCAL ckey := ""
   LOCAL i := 1
   LOCAL aDb := (calias)->(dbstruct())
   LOCAL lnumtostr := .F.
   LOCAL lDatetoStr := .F.
   LOCAL nPos
   LOCAL aTemp2 := {}

   DEFAULT lDescIndex TO .F.

   IF len(aFields) > 0
      IF len(afields) == 1
         cKey := afields[1]
      ELSE
         FOR EACH aTemp IN afields
            nPos := ascan(adb,{|x|upper(x[1]) == aTemp})
            IF nPos > 0
               aadd(aTemp2, adb[npos, 2])
            ENDIF
         NEXT

         FOR EACH aTemp IN afields
            nPos := ascan(adb,{|x|upper(x[1]) == aTemp})
            IF nPos >0
               IF adb[npos, 2] == "C"
                  ckey += atemp + "+"
               ELSEIF adb[npos, 2] == "N"
                  IF adb[npos, 4] > 0
                     ckey += "str(" + atemp + "," + str(adb[npos, 3]) + "," + str(adb[npos, 4]) + ")+"
                  ELSE
                     ckey += "str(" + atemp + "," + str(adb[npos, 3]) + ")+"
                  ENDIF
               ELSEIF adb[npos, 2] == "D"
                  ckey += "dtos(" + atemp + ")+"
               ENDIF
            ENDIF
         NEXT
         ckey := alltrim(ckey)
         IF substr(ckey, -1, 1) == "+"
            cKey := substr(cKey, 1, len(ckey) - 1)
         ENDIF
      ENDIF
      IF lDescIndex
         INDEX ON &(ckey) TAG T0001 DESC
      ELSE
         INDEX ON &(ckey) TAG T0001
      ENDIF
      SET ORDER TO 1
      GO TOP
   ENDIF

RETURN NIL

STATIC FUNCTION Skipped(nRecs, lAppend)

   LOCAL nSkipped := 0

   IF LastRec() != 0
      IF nRecs == 0
         IF EOF() .AND. !lAppend
            dbSkip(-1)
            nSkipped := -1
         ELSE
            dbSkip(0)
         ENDIF
      ELSEIF nRecs > 0 .AND. RecNo() != LastRec() + 1
         DO WHILE nSkipped < nRecs
            dbSkip()
            IF Eof()
               IF lAppend
                  nSkipped++
               ELSE
                  dbSkip(-1)
               ENDIF
               EXIT
            ENDIF
            nSkipped++
         ENDDO
      ELSEIF nRecs < 0
         DO WHILE nSkipped > nRecs
            dbSkip(-1)
            IF Bof()
               EXIT
            ENDIF
            nSkipped--
         ENDDO
      ENDIF
   ENDIF

   RETURN nSkipped

FUNCTION SR_WriteDbLog(cComm, oCnn)

   LOCAL nAlAtual := Select()
   LOCAL cPre := hHashData[nAliasTmp]["cFile"]

   HB_SYMBOL_UNUSED(oCnn)

   DEFAULT cComm to ""

   BEGIN SEQUENCE WITH __BreakBlock()

      IF !sr_phFile(cpre + "sqllog.dbf")
         dbCreate(cpre + "sqllog.dbf", TRACE_STRUCT, "DBFNTX")
      ENDIF

      DO WHILE .T.
         dbUseArea(.T., "DBFNTX", cpre + "sqllog.dbf", "SQLLOG", .T., .F.)
         IF !NetErr()
            EXIT
         ENDIF
         hb_idleSleep(500 / 1000)
      ENDDO
      IF "INSERT" $ upper(cComm)
         SQLLOG->(dbAppend())
         REPLACE SQLLOG->DATA      WITH Date()
         REPLACE SQLLOG->HORA      WITH Time()
         REPLACE SQLLOG->COMANDO   WITH cComm
         REPLACE SQLLOg->PROCESSED WITH .F.
      ENDIF
      SQLLOG->(dbCloseArea())

   RECOVER

   END SEQUENCE

   dbSelectArea(nAlAtual)

RETURN NIL

FUNCTION GetLastInsertCommand(cTable)

   LOCAL CrET := ""
   LOCAL nAlAtual := Select()
   LOCAL cPre := hHashData[nAliasTmp]["cFile"]

   IF !sr_phFile(cpre + "sqllog.dbf")
      dbCreate(cpre + "sqllog.dbf", TRACE_STRUCT, "DBFNTX")
   ENDIF
   DO WHILE .T.
      dbUseArea(.T., "DBFNTX", cpre + "sqllog.dbf", "SQLLOG", .T., .F.)
      IF !NetErr()
         EXIT
      ENDIF
      hb_idleSleep(500 / 1000)
   ENDDO

   SQLLOG->(dbgobottom())
   DO WHILE !SQLLOG->(BOF())
      IF !SQLLOG->PROCESSED .AND. UPPER(CTABLE) $ UPPER(SQLLOG->COMANDO)
         CRET := SQLLOG->COMANDO
         SQLLOG->(RLOCK())
         REPLACE SQLLOg->PROCESSED WITH .T.
         SQLLOG->(DBUNLOCK())
         EXIT
      ENDIF
      SQLLOG->(DBSKIP(-1))
   ENDDO
   SQLLOG->(dbCloseArea())
   dbSelectArea(nAlAtual)

RETURN CRET
