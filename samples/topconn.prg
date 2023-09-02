/*
* SQLRDD TopConnect compatibility test
* Sample application to test compatibility with TopConnect RDD
* Copyright (c) 2006 - Marcelo Lombardo  <lombardo@uol.com.br>
* All Rights Reserved
*/

#include "sqlrdd.ch"
#include "dbinfo.ch"

#define SQL_DBMS_NAME                       17
#define SQL_DBMS_VER                        18

FUNCTION MAIN(cDsn)

   LOCAL oSql
   LOCAL i
   LOCAL n
   LOCAL aFiles
   LOCAL aOpt := {}
   LOCAL aTabs := {}
   LOCAL nTab

   Connect(cDSN)    // see connect.prg

   SR_SetlUseDBCatalogs(.T.)    // Diz ao SQLRDD para usar os índices do catálogo do banco de dados

   ? "Connected to :", SR_GetConnectionInfo(, SQL_DBMS_NAME), SR_GetConnectionInfo(, SQL_DBMS_VER)
   ? "RDD Version  :", SR_Version()
   ? " "
   ? "Abrindo tabela SA1010"

   IF sr_existtable("SA1010")     // Verifica se a tabela existe no banco de dados

      USE SA1010 via "SQLRDD"       // Abre a tabela e os índices!!

      ? "Estrutura da tabela :"
      WAIT SR_ShowVector(dbStruct())

      dbGoTop()

      ? " "
      ? "Indices             :"
      FOR i := 1 TO 100
         IF empty(OrdName(i))
            EXIT
         ENDIF
         ? OrdName(i), OrdKey(i) //, OrdKeyCount(i)
      NEXT i

      ? ""
      ? "SEEK ", dbSeek("  " + strZero(65, 10))

      WAIT "Pressione qualquer tecla para executar o browse()"
      CLEAR

      browse()
      USE

   ELSE
      WAIT "Tabela não existe: " + "SA1010"
      // RETURN
   ENDIF

   CLEAR

   ? "Listando todas as tabelas do banco de dados com suas chaves de indice"
   ? " "
   WAIT "Pressione qualquer tecla para iniciar"
   ? " "

   aFiles := SR_ListTables()                    // Busca todas as tabelas do banco de dados

   FOR n := 1 TO len(aFiles)
      IF left(aFiles[n], 3) $ "SR_;TOP;SYS;DTP"       // Não queremos tabelas de catálogo
         Loop
      ENDIF
      BEGIN SEQUENCE
         USE (aFiles[n]) VIA "SQLRDD"
         ? "Table " + aFiles[n] + " Lastrec() ", lastrec(), " Keys "
         FOR i := 1 TO 100
            IF empty(OrdName(i))
               EXIT
            ENDIF
            ?? OrdName(i) + " "
         NEXT i
         aadd(aOpt, aFiles[n] + " Lastrec() :" + str(lastrec()) + " Indices :" + str(i - 1))
         aadd(aTabs, aFiles[n])
      //CATCH
      END SEQUENCE
   NEXT n

   WAIT

   nTab := 1

   DO WHILE .T.

      CLEAR

      @ 1, 5 SAY "Escolha uma das tabelas para abrir, ESC para sair"

      nTab := achoice(3, 10, 27, 60, aOpt, , , nTab)

      IF nTab > 0
         USE (aTabs[nTab]) VIA "SQLRDD"
         browse()
      ELSE
         EXIT
      ENDIF

   ENDDO

   CLEAR

RETURN

/*------------------------------------------------------------------------*/

#include "connect.prg"

/*------------------------------------------------------------------------*/
