// SQLRDD++
// Teste dos indices de expressao no PostgreSQL via conexao ODBC
//
// Demonstra que, tambem na conexao ODBC (lib generica sqlrddpp), indices
// criados com funcoes padrao do Harbour (UPPER, SUBSTR, LEFT, STRZERO,
// DTOS, STR) usam indices de expressao nativos do PostgreSQL, SEM criar
// a coluna extra INDKEY_. Apenas indices com funcao proprietaria (UDF)
// continuam criando a coluna sintetica.
//
// IMPORTANTE: o recurso vale para o RDD SQLRDD. O RDD SQLEX monta as
// consultas em nivel C a partir das colunas do indice e nao suporta
// indices de expressao (indices criados com UDF/sinteticos continuam
// funcionando normalmente no SQLEX).
//
// Para compilar (na pasta tests, que linka a lib generica sqlrddpp):
// hbmk2 odbcpgsqlexprindex
//
// Para executar:
// odbcpgsqlexprindex --driver <driverodbc> --server <servidor> --port <porta> --uid <usuario> --pwd <senha> --database <banco>
// NOTA: o banco de dados deve existir antes de rodar o teste.

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"
#include "inkey.ch"

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "testexpo"
#define NUM_REC 200

REQUEST SQLRDD
REQUEST SR_ODBC

REQUEST STRZERO
REQUEST PADR
REQUEST PADL
REQUEST SUBSTR
REQUEST DTOS

STATIC s_ODBC_DRIVER   := "PostgreSQL Unicode"
STATIC s_ODBC_SERVER   := "localhost"
STATIC s_ODBC_PORT     := "5432"
STATIC s_ODBC_UID      := "postgres"
STATIC s_ODBC_PWD      := "password"
STATIC s_ODBC_DATABASE := "dbtest"
STATIC s_ODBC_OPTIONS  := "BoolsAsChar=0;TrueIsMinus1;" // DO NOT CHANGE

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL cOpt
   LOCAL stringConect

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--driver"   ; s_ODBC_DRIVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--server"   ; s_ODBC_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"     ; s_ODBC_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"      ; s_ODBC_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"      ; s_ODBC_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--database" ; s_ODBC_DATABASE := HB_PValue(++n)
      CASE HB_PValue(n) == "--options"  ; s_ODBC_OPTIONS := HB_PValue(++n)
      OTHERWISE
         ? "Parâmetro desconhecido:", HB_PValue(n)
      ENDCASE
      ++n
   ENDDO

   SET DATE ANSI
   SET CENTURY ON

   rddSetDefault(RDD_NAME)

   stringConect := "Driver="   + s_ODBC_DRIVER   + ";" + ;
                   "Server="   + s_ODBC_SERVER   + ";" + ;
                   "Port="     + s_ODBC_PORT     + ";" + ;
                   "Database=" + s_ODBC_DATABASE + ";" + ;
                   "Uid="      + s_ODBC_UID      + ";" + ;
                   "Pwd="      + s_ODBC_PWD      + ";" + ;
                   ""          + s_ODBC_OPTIONS  + ";"

   ? "Conectando via ODBC em " + s_ODBC_SERVER + ":" + s_ODBC_PORT + "/" + s_ODBC_DATABASE + " ..."
   ? "String de conexao: " + stringConect

   nConnection := sr_AddConnection(CONNECT_ODBC, stringConect)

   IF nConnection < 0
      ? "Erro de conexao. Veja sqlerror.log para detalhes."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   CriaTabela()
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
      ? " SQLRDD++ - Indices de expressao via ODBC (PostgreSQL)"
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

STATIC PROCEDURE CriaIndices()

   ? ""
   ? "Criando indices (INDEX ON ... TAG <tabela+seq> TO <tabela>)..."
   ? ""

   ? "  TAG testexpo1: UPPER(NOME)                    => expressao (sem coluna extra)"
   INDEX ON UPPER(NOME) TAG testexpo1 TO testexpo

   ? "  TAG testexpo2: SUBSTR(CIDADE,1,10)            => expressao (sem coluna extra)"
   INDEX ON SUBSTR(CIDADE, 1, 10) TAG testexpo2 TO testexpo

   ? "  TAG testexpo3: STRZERO(SALDO,12,2)            => expressao com decimais (sem coluna extra)"
   INDEX ON STRZERO(SALDO, 12, 2) TAG testexpo3 TO testexpo

   ? "  TAG testexpo4: DTOS(ADMISSAO)+STRZERO(ID,10)  => data crua + expressao (sem coluna extra)"
   INDEX ON DTOS(ADMISSAO) + STRZERO(ID, 10) TAG testexpo4 TO testexpo

   ? "  TAG testexpo5: MYUDF(NOME)                    => UDF: sintetico (CRIA coluna INDKEY_)"
   INDEX ON MYUDF(NOME) TAG testexpo5 TO testexpo

RETURN

//--------------------------------------------------------------------
// Funcao proprietaria (nao existe no PostgreSQL): forca indice sintetico

FUNCTION MYUDF(cNome)

RETURN Upper(Right(RTrim(cNome), 4)) + Upper(Left(cNome, 3))

//--------------------------------------------------------------------

STATIC PROCEDURE MostraColunasExtras()

   LOCAL oCnn := SR_GetConnection()
   LOCAL aRes := {}
   LOCAL aLinha

   ? ""
   ? "Colunas INDKEY_/INDFOR_ existentes na tabela (esperado: apenas 1, do indice via UDF):"

   oCnn:Exec("select column_name from information_schema.columns where table_name = '" + ;
             Lower(TABLE_NAME) + "' and (column_name like 'indkey_%' or column_name like 'indfor_%') order by 1", .F., .T., @aRes)

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
   ? "Indices fisicos no PostgreSQL (observe as expressoes rtrim/upper/substr/lpad):"

   oCnn:Exec("select indexname, indexdef from pg_indexes where tablename = '" + ;
             Lower(TABLE_NAME) + "' order by 1", .F., .T., @aRes)

   FOR EACH aLinha IN aRes
      ? "  " + PadR(AllTrim(aLinha[1]), 22) + SubStr(AllTrim(aLinha[2]), At("(", AllTrim(aLinha[2])))
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

   IF !SetOrderByTag("TESTEXPO1")
      ? "AVISO: ordem TESTEXPO1 nao encontrada - testes de SEEK cancelados"
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

   IF !SetOrderByTag("TESTEXPO2")
      ? "AVISO: ordem TESTEXPO2 nao encontrada"
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

   IF !SetOrderByTag("TESTEXPO3")
      ? "AVISO: ordem TESTEXPO3 nao encontrada"
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

   IF !SetOrderByTag("TESTEXPO4")
      ? "AVISO: ordem TESTEXPO4 nao encontrada"
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

   IF !SetOrderByTag("TESTEXPO5")
      ? "AVISO: ordem TESTEXPO5 nao encontrada"
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
