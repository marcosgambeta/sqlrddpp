// SQLRDD++
// Teste dos indices de expressao (functional indexes) no MySQL
//
// Demonstra que indices criados com funcoes padrao do Harbour
// (UPPER, SUBSTR, LEFT, STRZERO, DTOS, STR) usam indices funcionais
// nativos do MySQL, SEM criar a coluna extra INDKEY_. Apenas indices
// com funcao proprietaria (UDF) continuam criando a coluna sintetica.
//
// REQUISITO: MySQL 8.0.13 ou superior (indices funcionais). Em versoes
// anteriores e no MariaDB o comportamento classico e mantido (todas as
// chaves com funcao criam coluna INDKEY_).
//
// Para compilar:
// hbmk2 testexprindex
//
// Para executar:
// testexprindex --server <servidor> --port <porta> --uid <usuario> --pwd <senha> --dtb <banco>
// NOTA: o banco de dados deve existir antes de rodar o teste.
//
// Opcao --diag: executa passo a passo (em SQL puro) o mesmo DDL que a
// biblioteca usa no caminho do indice sintetico, mostrando o retorno e a
// mensagem de erro de cada comando. Util para identificar qual etapa falha
// em servidores antigos.

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"
#include "inkey.ch"

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "testexpm"
#define NUM_REC 200

REQUEST SQLRDD
REQUEST SR_MYSQL

REQUEST STRZERO
REQUEST PADR
REQUEST PADL
REQUEST SUBSTR
REQUEST DTOS

STATIC s_SERVER := "localhost"
STATIC s_PORT   := "3306"
STATIC s_UID    := "root"
STATIC s_PWD    := "password"
STATIC s_DTB    := "dbtest"

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL cOpt
   LOCAL stringConect
   LOCAL lDiag := .F.

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--server" ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"   ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"    ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"    ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--dtb"    ; s_DTB := HB_PValue(++n)
      CASE HB_PValue(n) == "--diag"   ; lDiag := .T.
      OTHERWISE
         ? "Parametro desconhecido:", HB_PValue(n)
      ENDCASE
      ++n
   ENDDO

   SET DATE ANSI
   SET CENTURY ON

   rddSetDefault(RDD_NAME)

   stringConect := "MySQL=" + s_SERVER + ";PORT=" + s_PORT + ";UID=" + s_UID + ";PWD=" + s_PWD + ";DTB=" + s_DTB

   ? "Conectando em " + s_SERVER + ":" + s_PORT + "/" + s_DTB + " ..."
   ? "String de conexao: " + stringConect

   nConnection := sr_AddConnection(CONNECT_MYSQL, stringConect)

   IF nConnection < 0
      ? "Erro de conexao. Veja sqlerror.log para detalhes."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   MostraVersao()
   CriaTabela()

   IF lDiag
      Diagnostico()
      CLOSE DATABASE
      sr_StopLog(nConnection)
      sr_EndConnection(nConnection)
      ? ""
      WAIT "Diagnostico concluido. Pressione uma tecla..."
      QUIT
   ENDIF

   CriaIndices()
   MostraColunasExtras()
   MostraIndicesFisicos()

   ? ""
   ? "Pressione uma tecla para iniciar os testes de SEEK..."
   Inkey(0)

   TestaSeeks()

   // Reabre a tabela para testar tambem a reabertura dos indices
   // de expressao registrados em SR_MGMNTINDEXES

   CLOSE DATABASE
   ? ""
   ? "Reabrindo a tabela (indices carregados do SR_MGMNTINDEXES)..."
   USE (TABLE_NAME) SHARED VIA (RDD_NAME)

   // Menu interativo com DBEDIT para avaliacao visual

   DO WHILE .T.
      CLS
      ? "=============================================================="
      ? " SQLRDD++ - Teste de indices de expressao (MySQL)"
      ? "=============================================================="
      ? ""
      MostraOrdens()
      ? ""
      ? " 1..5 - Navegar (DBEDIT) na ordem escolhida"
      ? " 0    - Navegar em ordem natural (sem indice)"
      ? " S    - Repetir testes de SEEK"
      ? " C    - Mostrar colunas INDKEY_ da tabela"
      ? " Q    - Sair"
      ? ""
      ACCEPT "Opcao: " TO cOpt
      cOpt := Upper(AllTrim(cOpt))

      DO CASE
      CASE cOpt == "Q"
         EXIT
      CASE cOpt == "S"
         CLS
         TestaSeeks()
         WAIT
      CASE cOpt == "C"
         CLS
         MostraColunasExtras()
         MostraIndicesFisicos()
         WAIT
      CASE Val(cOpt) >= 0 .AND. Val(cOpt) <= OrdCount()
         DBSetOrder(Val(cOpt))
         DBGoTop()
         CLS
         @ 0, 0 SAY PadR("Ordem: " + LTrim(Str(IndexOrd())) + "  Tag: " + ordName() + "  Chave: " + ordKey(), MaxCol() + 1)
         DBEdit(1, 0, MaxRow(), MaxCol())
      ENDCASE
   ENDDO

   CLS
   ? "Remover a tabela de teste '" + TABLE_NAME + "' ? (S/N)"
   IF Upper(Chr(Inkey(0))) == "S"
      CLOSE DATABASE
      sr_DropTable(TABLE_NAME)
      ? "Tabela removida."
   ELSE
      CLOSE DATABASE
      ? "Tabela mantida para inspecao manual."
   ENDIF

   sr_StopLog(nConnection)
   sr_EndConnection(nConnection)

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE MostraVersao()

   LOCAL oCnn := SR_GetConnection()
   LOCAL cVers := AllTrim(SR_Val2Char(oCnn:cSystemVers))
   LOCAL aRes := {}

   ? ""
   ? "Versao reportada pelo driver: " + cVers + ;
     IIf(Val(cVers) >= 80013, "  (indices funcionais suportados)", ;
                              "  (SEM indices funcionais - sera usado o indice sintetico)")

   // Confirmacao direta no servidor (o driver pode reportar a versao do
   // protocolo/proxy em vez da versao real do servidor)

   oCnn:Exec("select version()", .F., .T., @aRes)

   IF Len(aRes) > 0
      ? "Versao retornada por select version(): " + AllTrim(SR_Val2Char(aRes[1, 1]))
   ENDIF

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE CriaTabela()

   LOCAL n
   LOCAL aNomes := {"Ana Souza", "bruno LIMA", "CARLA Mendes", "diego costa", "Elisa RAMOS", ;
                    "FABIO silva", "Gustavo Reis", "helena DIAS", "Igor MOURA", "julia castro"}
   LOCAL aCidades := {"Sao Paulo", "RIO DE JANEIRO", "belo horizonte", "Curitiba", "PORTO ALEGRE", ;
                      "salvador", "Fortaleza", "MANAUS", "recife", "Goiania"}

   IF sr_ExistTable(TABLE_NAME)
      ? "Removendo tabela anterior..."
      sr_DropTable(TABLE_NAME)
   ENDIF

   ? "Criando tabela " + TABLE_NAME + "..."

   dbCreate(TABLE_NAME, {{"ID      ", "N", 10, 0}, ;
                         {"NOME    ", "C", 30, 0}, ;
                         {"CIDADE  ", "C", 20, 0}, ;
                         {"ADMISSAO", "D",  8, 0}, ;
                         {"SALDO   ", "N", 12, 2}}, RDD_NAME)

   USE (TABLE_NAME) EXCLUSIVE VIA (RDD_NAME)

   ? "Populando com " + LTrim(Str(NUM_REC)) + " registros..."

   FOR n := 1 TO NUM_REC
      APPEND BLANK
      REPLACE ID       WITH n
      REPLACE NOME     WITH aNomes[((n - 1) % Len(aNomes)) + 1] + " " + StrZero(n, 4)
      REPLACE CIDADE   WITH aCidades[((n - 1) % Len(aCidades)) + 1]
      REPLACE ADMISSAO WITH Date() - n
      REPLACE SALDO    WITH n * 10.50
   NEXT n

RETURN

//--------------------------------------------------------------------

// Executa, em SQL puro, a mesma sequencia usada pela biblioteca ao criar
// um indice sintetico, mostrando o retorno de cada comando

STATIC PROCEDURE Diagnostico()

   LOCAL oCnn := SR_GetConnection()
   LOCAL cTbl := Lower(TABLE_NAME)
   LOCAL aRes := {}

   ? ""
   ? "=== DIAGNOSTICO DO CAMINHO SINTETICO (SQL puro) ==="

   ExecDiag(oCnn, "ALTER TABLE " + cTbl + " ADD `indkey_999` CHAR (45)")
   ExecDiag(oCnn, "UPDATE " + cTbl + " SET `indkey_999` = 'TESTE' WHERE `sr_recno` = 1")
   ExecDiag(oCnn, "DROP INDEX " + cTbl + "_diag ON " + cTbl + "   (pode falhar: indice ainda nao existe)")
   ExecDiag(oCnn, "CREATE INDEX " + cTbl + "_diag ON " + cTbl + " (`indkey_999`)")

   ExecDiag(oCnn, "DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(TABLE_NAME) + "'")
   ExecDiag(oCnn, "INSERT INTO " + SR_GetToolsOwner() + "SR_MGMNTINDEXES " + ;
                  "(TABLE_,SIGNATURE_,IDXNAME_,PHIS_NAME_,IDXKEY_,IDXFOR_,IDXCOL_,TAG_,TAGNUM_) VALUES ( '" + ;
                  Upper(TABLE_NAME) + "','" + DToS(Date()) + " " + Time() + " A','" + Upper(TABLE_NAME) + "','" + ;
                  cTbl + "_diag','UPPER(NOME)','','999','DIAGTAG','000001' )")

   oCnn:Commit()

   ? ""
   ? "Linhas em SR_MGMNTINDEXES para " + Upper(TABLE_NAME) + " (esperado: 1):"
   aRes := {}
   oCnn:Exec("SELECT TABLE_,IDXNAME_,TAG_,IDXCOL_,IDXKEY_ FROM " + SR_GetToolsOwner() + ;
             "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(TABLE_NAME) + "'", .F., .T., @aRes)
   ? "  registros retornados: " + LTrim(Str(Len(aRes)))
   AEval(aRes, {|a|QOut("  IDXNAME_=[" + AllTrim(SR_Val2Char(a[2])) + "] TAG_=[" + AllTrim(SR_Val2Char(a[3])) + ;
                        "] IDXCOL_=[" + AllTrim(SR_Val2Char(a[4])) + "] IDXKEY_=[" + AllTrim(SR_Val2Char(a[5])) + "]")})

   ? ""
   ? "Estrutura da tabela (procure por indkey_999):"
   aRes := {}
   oCnn:Exec("SELECT column_name, data_type FROM information_schema.columns WHERE table_schema = database() AND table_name = '" + ;
             cTbl + "' ORDER BY ordinal_position", .F., .T., @aRes)
   AEval(aRes, {|a|QOut("  " + AllTrim(SR_Val2Char(a[1])) + " " + AllTrim(SR_Val2Char(a[2])))})

   // Limpeza
   ExecDiag(oCnn, "DELETE FROM " + SR_GetToolsOwner() + "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(TABLE_NAME) + "'")
   oCnn:Commit()

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE ExecDiag(oCnn, cSql)

   LOCAL nRet
   LOCAL cShow := cSql

   IF "   (pode falhar" $ cShow
      cSql := Left(cSql, At("   (pode falhar", cSql) - 1)
   ENDIF

   nRet := oCnn:Exec(cSql, .F.)

   ? ""
   ? "SQL: " + Left(cShow, 110)
   ? "  retorno: " + LTrim(Str(nRet)) + ;
     IIf(nRet == SQL_SUCCESS, "  (SQL_SUCCESS)", "  ERRO: " + AllTrim(SR_Val2Char(oCnn:LastError())))

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE CriaIndices()

   ? ""
   ? "Criando indices (INDEX ON ... TAG <tabela+seq> TO <tabela>)..."
   ? ""

   CriaIndice("testexpm1: UPPER(NOME)", "testexpm1", "UPPER(NOME)", {||Upper(FIELD->NOME)})
   CriaIndice("testexpm2: SUBSTR(CIDADE,1,10)", "testexpm2", "SUBSTR(CIDADE,1,10)", {||SubStr(FIELD->CIDADE, 1, 10)})
   CriaIndice("testexpm3: STRZERO(SALDO,12,2)", "testexpm3", "STRZERO(SALDO,12,2)", {||StrZero(FIELD->SALDO, 12, 2)})
   CriaIndice("testexpm4: DTOS(ADMISSAO)+STRZERO(ID,10)", "testexpm4", "DTOS(ADMISSAO)+STRZERO(ID,10)", ;
              {||DToS(FIELD->ADMISSAO) + StrZero(FIELD->ID, 10)})
   CriaIndice("testexpm5: MYUDF(NOME)", "testexpm5", "MYUDF(NOME)", {||MYUDF(FIELD->NOME)})

RETURN

//--------------------------------------------------------------------
// Cria um indice reportando o erro (em vez de abortar) e mostrando o
// que ficou registrado em SR_MGMNTINDEXES

STATIC PROCEDURE CriaIndice(cDesc, cTag, cKey, bKey)

   LOCAL bOld := ErrorBlock({|e|Break(e)})
   LOCAL oErr
   LOCAL lOk := .F.

   BEGIN SEQUENCE
      ordCreate(TABLE_NAME, cTag, cKey, bKey, .F.)
      lOk := .T.
   RECOVER USING oErr
      lOk := .F.
   END SEQUENCE

   ErrorBlock(bOld)

   ? "  " + PadR(cDesc, 42) + IIf(lOk, "=> OK", "=> ERRO: " + AllTrim(SR_Val2Char(oErr:description)))

   IF !lOk
      MostraRegistros("  registros em SR_MGMNTINDEXES apos a falha:")
   ENDIF

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE MostraRegistros(cTitulo)

   LOCAL oCnn := SR_GetConnection()
   LOCAL aRes := {}

   ? cTitulo
   oCnn:Exec("SELECT IDXNAME_,TAG_,IDXCOL_,IDXKEY_,PHIS_NAME_ FROM " + SR_GetToolsOwner() + ;
             "SR_MGMNTINDEXES WHERE TABLE_ = '" + Upper(TABLE_NAME) + "' ORDER BY TAGNUM_", .F., .T., @aRes)

   IF Len(aRes) == 0
      ? "    (nenhum registro - a criacao nao foi registrada)"
   ELSE
      AEval(aRes, {|a|QOut("    IDXNAME_=[" + AllTrim(SR_Val2Char(a[1])) + "] TAG_=[" + AllTrim(SR_Val2Char(a[2])) + ;
                           "] IDXCOL_=[" + AllTrim(SR_Val2Char(a[3])) + "] IDXKEY_=[" + AllTrim(SR_Val2Char(a[4])) + ;
                           "] PHIS_NAME_=[" + AllTrim(SR_Val2Char(a[5])) + "]")})
   ENDIF

RETURN

//--------------------------------------------------------------------
// Funcao proprietaria (nao existe no MySQL): forca indice sintetico

FUNCTION MYUDF(cNome)

RETURN Upper(Right(RTrim(cNome), 4)) + Upper(Left(cNome, 3))

//--------------------------------------------------------------------

STATIC PROCEDURE MostraColunasExtras()

   LOCAL oCnn := SR_GetConnection()
   LOCAL aRes := {}
   LOCAL aLinha

   ? ""
   ? "Colunas INDKEY_/INDFOR_ existentes na tabela (esperado: apenas 1, do indice via UDF):"

   oCnn:Exec("select column_name from information_schema.columns where table_schema = database() and table_name = '" + ;
             Lower(TABLE_NAME) + "' and (column_name like 'indkey!_%' escape '!' or column_name like 'indfor!_%' escape '!') order by 1", .F., .T., @aRes)

   IF Len(aRes) == 0
      ? "  (nenhuma coluna extra)"
   ELSE
      FOR EACH aLinha IN aRes
         ? "  - " + AllTrim(aLinha[1])
      NEXT
   ENDIF

   IF Len(aRes) == 1
      ? "  RESULTADO: OK - somente o indice com UDF criou coluna extra"
   ELSE
      ? "  RESULTADO: VERIFICAR - quantidade de colunas extras diferente do esperado (" + LTrim(Str(Len(aRes))) + ")"
   ENDIF

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE MostraIndicesFisicos()

   LOCAL oCnn := SR_GetConnection()
   LOCAL aRes := {}
   LOCAL aLinha

   ? ""
   ? "Indices fisicos no MySQL (observe as expressoes rtrim/upper/substr/lpad):"

   oCnn:Exec("select index_name, ifnull(column_name, expression) from information_schema.statistics " + ;
             "where table_schema = database() and table_name = '" + Lower(TABLE_NAME) + "' order by index_name, seq_in_index", .F., .T., @aRes)

   FOR EACH aLinha IN aRes
      ? "  " + PadR(AllTrim(aLinha[1]), 22) + AllTrim(SR_Val2Char(aLinha[2]))
   NEXT

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE MostraOrdens()

   LOCAL i

   FOR i := 1 TO OrdCount()
      ? " " + LTrim(Str(i)) + " - " + PadR(ordName(i), 12) + " chave: " + ordKey(i)
   NEXT i

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE TestaSeeks()

   LOCAL n
   LOCAL cNome
   LOCAL cCidade
   LOCAL dData
   LOCAL nOk
   LOCAL nErro

   // ------------------------------------------------ UPPER(NOME)

   IF !SetOrderByTag("TESTEXPM1")
      ? "AVISO: ordem TESTEXPM1 nao encontrada - testes de SEEK cancelados"
      RETURN
   ENDIF
   ? ""
   ? "SEEK em UPPER(NOME) - ordem: " + ordName() + " => " + ordKey()
   nOk := nErro := 0
   FOR n := 1 TO NUM_REC
      DBGoTo(n)
      cNome := Upper(RTrim(FIELD->NOME))
      SEEK cNome
      IF Found() .AND. Upper(RTrim(FIELD->NOME)) == cNome
         nOk++
      ELSE
         nErro++
      ENDIF
   NEXT n
   SEEK "ZZZZZZZZ_NAO_EXISTE"
   IF !Found()
      nOk++
   ELSE
      nErro++
   ENDIF
   ? "  encontrados:", nOk, " falhas:", nErro, IIf(nErro == 0, "=> OK", "=> ERRO")

   // Seek parcial (prefixo)
   SEEK "ANA"
   ? "  SEEK parcial 'ANA' =>", IIf(Found(), "encontrado: " + RTrim(FIELD->NOME) + " => OK", "NAO encontrado => ERRO")

   // ------------------------------------------------ SUBSTR(CIDADE,1,10)

   IF !SetOrderByTag("TESTEXPM2")
      ? "AVISO: ordem TESTEXPM2 nao encontrada"
      RETURN
   ENDIF
   ? ""
   ? "SEEK em SUBSTR(CIDADE,1,10) - ordem: " + ordKey()
   nOk := nErro := 0
   FOR n := 1 TO NUM_REC
      DBGoTo(n)
      cCidade := SubStr(FIELD->CIDADE, 1, 10)
      SEEK cCidade
      IF Found() .AND. SubStr(FIELD->CIDADE, 1, 10) == cCidade
         nOk++
      ELSE
         nErro++
      ENDIF
   NEXT n
   ? "  encontrados:", nOk, " falhas:", nErro, IIf(nErro == 0, "=> OK", "=> ERRO")

   // ------------------------------------------------ STRZERO(SALDO,12,2)

   IF !SetOrderByTag("TESTEXPM3")
      ? "AVISO: ordem TESTEXPM3 nao encontrada"
      RETURN
   ENDIF
   ? ""
   ? "SEEK em STRZERO(SALDO,12,2) - ordem: " + ordKey()
   nOk := nErro := 0
   FOR n := 1 TO NUM_REC
      SEEK StrZero(n * 10.50, 12, 2)
      IF Found() .AND. FIELD->SALDO == n * 10.50
         nOk++
      ELSE
         nErro++
      ENDIF
   NEXT n
   SEEK StrZero((NUM_REC + 500) * 10.50, 12, 2)
   IF !Found()
      nOk++
   ELSE
      nErro++
   ENDIF
   ? "  encontrados:", nOk, " falhas:", nErro, IIf(nErro == 0, "=> OK", "=> ERRO")

   // ------------------------------------------------ DTOS(ADMISSAO)+STRZERO(ID,10)

   IF !SetOrderByTag("TESTEXPM4")
      ? "AVISO: ordem TESTEXPM4 nao encontrada"
      RETURN
   ENDIF
   ? ""
   ? "SEEK em DTOS(ADMISSAO)+STRZERO(ID,10) - ordem: " + ordKey()
   nOk := nErro := 0
   FOR n := 1 TO NUM_REC
      dData := Date() - n
      SEEK DToS(dData) + StrZero(n, 10)
      IF Found() .AND. FIELD->ID == n .AND. FIELD->ADMISSAO == dData
         nOk++
      ELSE
         nErro++
      ENDIF
   NEXT n
   ? "  encontrados:", nOk, " falhas:", nErro, IIf(nErro == 0, "=> OK", "=> ERRO")

   // ------------------------------------------------ MYUDF(NOME)  (sintetico)

   IF !SetOrderByTag("TESTEXPM5")
      ? "AVISO: ordem TESTEXPM5 nao encontrada"
      RETURN
   ENDIF
   ? ""
   ? "SEEK em MYUDF(NOME) (indice sintetico com INDKEY_) - ordem: " + ordKey()
   nOk := nErro := 0
   FOR n := 1 TO NUM_REC
      DBGoTo(n)
      cNome := MYUDF(FIELD->NOME)
      SEEK cNome
      IF Found() .AND. MYUDF(FIELD->NOME) == cNome
         nOk++
      ELSE
         nErro++
      ENDIF
   NEXT n
   ? "  encontrados:", nOk, " falhas:", nErro, IIf(nErro == 0, "=> OK", "=> ERRO")

RETURN

//--------------------------------------------------------------------

STATIC FUNCTION SetOrderByTag(cTag)

   LOCAL i

   FOR i := 1 TO OrdCount()
      IF Upper(AllTrim(ordName(i))) == Upper(AllTrim(cTag))
         DBSetOrder(i)
         RETURN .T.
      ENDIF
   NEXT i

   DBSetOrder(0)

RETURN .F.
