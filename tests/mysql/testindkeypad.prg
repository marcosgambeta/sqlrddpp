// SQLRDD++
// Reproduz o erro "Index Column not Found - INDKEY_001  Table : <tabela>"
// no MySQL com conexao nativa (reportado por Mario Sabado, MySQL 9.7.1)
//
// CAUSA
// -----
// IDXCOL_ em SR_MGMNTINDEXES e CHAR(3). O driver nativo do MySQL devolve
// todo valor CHAR preenchido com espacos ate a largura que ele calculou
// para a coluna (MSQLFieldGet(), caso SQL_CHAR), e SR_MYSQueryAttr()
// calcula essa largura dividindo field->length pelo numero de bytes por
// caractere do charset - mas so quando o charset da COLUNA bate com o da
// CONEXAO. A comparacao e feita entre ids de COLLATION
// (field->charsetnr == cs.number), entao utf8mb4_0900_ai_ci (255) numa
// conexao utf8mb4_general_ci (45) nao bate, a divisao nao e aplicada e
// field->length (em BYTES) e usado direto: CHAR(3) em utf8mb4 vira 12.
//
// Com isso IDXCOL_ volta como "001" seguido de 9 espacos, e o nome da
// coluna montado por concatenacao vira "INDKEY_001         ", que nao
// casa mais com os nomes em ::aNames - a busca usa ==, que em Harbour
// exige mesmo comprimento.
//
// O erro aparece no SET INDEX TO (sqlOrderListAdd) e existe tanto se a
// coluna INDKEY_001 existir quanto se nao existir - o problema e o nome
// procurado, nao a coluna.
//
// Para compilar:
// hbmk2 testindkeypad
//
// Para executar:
// testindkeypad --server <servidor> --port <porta> --uid <usuario> --pwd <senha> --dtb <banco>
//
// Opcao --keep: nao apaga a tabela de teste no final (para inspecao manual)
//
// Opcao --forcecs <collation>: converte SR_MGMNTINDEXES para a collation
// informada antes de criar os indices. O erro so aparece quando a
// collation da COLUNA difere da collation da CONEXAO, entao para
// reproduzir basta escolher uma collation utf8mb4 diferente da que a
// conexao negociou (o teste mostra as duas no bloco Ambiente):
//
//   testindkeypad ... --forcecs utf8mb4_general_ci
//
// Com a conexao em utf8mb4_0900_ai_ci isso da a mesma largura de 12 que
// o Mario reportou. Use --forcecs utf8mb4_0900_ai_ci para voltar ao caso
// que funciona e comparar.

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"
#include "inkey.ch"

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "arbankt"
#define BAG_NAME "ARBANKT"
#define TAG_1 "ARBANKT1"
#define TAG_2 "ARBANKT2"

REQUEST SQLRDD
REQUEST SR_MYSQL

REQUEST UPPER

STATIC s_SERVER := "localhost"
STATIC s_PORT   := "3306"
STATIC s_UID    := "root"
STATIC s_PWD    := "password"
STATIC s_DTB    := "dbtest"

STATIC s_nPad := 0      // largura com que IDXCOL_ voltou do driver
STATIC s_COLLATION := ""   // --forcecs

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL lKeep := .F.
   LOCAL stringConect
   LOCAL lFalhou

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--server" ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"   ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"    ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"    ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--dtb"    ; s_DTB := HB_PValue(++n)
      CASE HB_PValue(n) == "--keep"   ; lKeep := .T.
      CASE HB_PValue(n) == "--forcecs"; s_COLLATION := HB_PValue(++n)
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

   nConnection := sr_AddConnection(CONNECT_MYSQL, stringConect)

   IF nConnection < 0
      ? "Erro de conexao. Veja sqlerror.log para detalhes."
      WAIT
      QUIT
   ENDIF

   sr_StartLog(nConnection)

   ForcaCollation()
   MostraAmbiente()
   CriaTabela()
   CriaIndices()
   MedePadding()

   lFalhou := AbreComoNoRelato()

   Veredito(lFalhou)

   IF !lKeep
      CLOSE DATABASE
      sr_DropTable(TABLE_NAME)
   ENDIF

   CLOSE DATABASE
   sr_StopLog(nConnection)
   sr_EndConnection(nConnection)

   ? ""
   WAIT "Pressione uma tecla..."

RETURN

//--------------------------------------------------------------------
// Converte SR_MGMNTINDEXES para a collation pedida em --forcecs.
// O catalogo ja existe neste ponto: SR_SetEnvSQLRDD o cria na conexao.

STATIC PROCEDURE ForcaCollation()

   LOCAL oCnn := SR_GetConnection()
   LOCAL cCharset
   LOCAL nPos

   IF Empty(s_COLLATION)
      RETURN
   ENDIF

   // O charset e o primeiro segmento do nome da collation
   // (utf8mb4_general_ci => utf8mb4, latin1_swedish_ci => latin1)

   nPos := At("_", s_COLLATION)
   cCharset := IIf(nPos == 0, s_COLLATION, Left(s_COLLATION, nPos - 1))

   ? ""
   ? "Convertendo SR_MGMNTINDEXES para " + cCharset + " / " + s_COLLATION + " ..."

   oCnn:Exec("alter table SR_MGMNTINDEXES convert to character set " + ;
             cCharset + " collate " + s_COLLATION, .T.)
   oCnn:Commit()

RETURN

//--------------------------------------------------------------------
// Versao do servidor, charset da conexao e collation do IDXCOL_

STATIC PROCEDURE MostraAmbiente()

   LOCAL oCnn := SR_GetConnection()
   LOCAL aRes := {}
   LOCAL aRow
   LOCAL cCollCnn := ""
   LOCAL cCollCol := ""

   ? ""
   ? "=============================================================="
   ? " Ambiente"
   ? "=============================================================="

   ? "Versao reportada pelo driver : " + AllTrim(SR_Val2Char(oCnn:cSystemVers))

   aRes := {}
   oCnn:Exec("select version()", .F., .T., @aRes)
   IF Len(aRes) > 0
      ? "select version()             : " + AllTrim(SR_Val2Char(aRes[1, 1]))
   ENDIF

   aRes := {}
   oCnn:Exec("show variables like 'character_set_client'", .F., .T., @aRes)
   FOR EACH aRow IN aRes
      ? "character_set_client         : " + AllTrim(SR_Val2Char(aRow[2]))
   NEXT

   aRes := {}
   oCnn:Exec("show variables like 'collation_connection'", .F., .T., @aRes)
   FOR EACH aRow IN aRes
      cCollCnn := AllTrim(SR_Val2Char(aRow[2]))
      ? "collation_connection         : " + cCollCnn
   NEXT

   // Collation real da coluna IDXCOL_ no catalogo

   aRes := {}
   oCnn:Exec("select CHARACTER_SET_NAME, COLLATION_NAME, CHARACTER_MAXIMUM_LENGTH " + ;
             "from information_schema.columns " + ;
             "where TABLE_SCHEMA = database() and TABLE_NAME = 'SR_MGMNTINDEXES' " + ;
             "and COLUMN_NAME = 'IDXCOL_'", .F., .T., @aRes)

   IF Len(aRes) > 0

      cCollCol := AllTrim(SR_Val2Char(aRes[1, 2]))

      ? "IDXCOL_ charset / collation  : " + AllTrim(SR_Val2Char(aRes[1, 1])) + " / " + cCollCol
      ? "IDXCOL_ largura declarada    : " + AllTrim(SR_Val2Char(aRes[1, 3])) + " caracteres"

      ? ""

      IF cCollCol == cCollCnn
         ? ">> Coluna e conexao usam a MESMA collation: a largura e calculada"
         ? "   corretamente e este ambiente nao deve reproduzir o erro."
         ? "   Use --forcecs <outra collation> para provocar a diferenca."
      ELSE
         ? ">> Coluna e conexao usam collations DIFERENTES (" + cCollCol + " x " + cCollCnn + ")."
         ? "   E nesta condicao que a largura da coluna passa a ser contada"
         ? "   em bytes. Veja abaixo o comprimento com que o IDXCOL_ chega."
      ENDIF

   ELSE
      ? "IDXCOL_                      : SR_MGMNTINDEXES ainda nao existe"
   ENDIF

RETURN

//--------------------------------------------------------------------
// Tabela pequena no formato da ARBANK do relato

STATIC PROCEDURE CriaTabela()

   LOCAL aBancos := {"BDO-0001|BANCO DE ORO", ;
                     "BF000001|BANCO FILIPINO", ;
                     "BPI00001|BANK OF THE PHIL ISLANDS", ;
                     "MB000001|METROBANK", ;
                     "UB000001|UNIONBANK"}
   LOCAL cItem
   LOCAL nPos

   ? ""
   ? "=============================================================="
   ? " Criando a tabela de teste"
   ? "=============================================================="

   IF sr_ExistTable(TABLE_NAME)
      ? "Removendo tabela anterior..."
      sr_DropTable(TABLE_NAME)
   ENDIF

   dbCreate(TABLE_NAME, {{"BANK_CODE", "C", 10, 0}, ;
                         {"BANK_NAME", "C", 40, 0}, ;
                         {"ADDRESS",   "C", 40, 0}, ;
                         {"BALANCE",   "N", 14, 2}}, RDD_NAME)

   USE (TABLE_NAME) EXCLUSIVE NEW VIA (RDD_NAME)

   FOR EACH cItem IN aBancos
      nPos := At("|", cItem)
      dbAppend()
      FIELD->BANK_CODE := Left(cItem, nPos - 1)
      FIELD->BANK_NAME := SubStr(cItem, nPos + 1)
      FIELD->ADDRESS   := "MANILA"
      FIELD->BALANCE   := 1000
   NEXT

   dbCommit()

   ? "Tabela " + TABLE_NAME + " criada com " + AllTrim(Str(LastRec())) + " registros"

   CLOSE DATABASE

RETURN

//--------------------------------------------------------------------
// Indices no formato do relato: bag unico, dois tags, caminho sintetico
// classico (SR_SetSyntheticIndex(.T.) + SR_SetExpressionIndex(.F.))

STATIC PROCEDURE CriaIndices()

   ? ""
   ? "=============================================================="
   ? " Criando os indices (caminho sintetico classico)"
   ? "=============================================================="

   SR_SetSyntheticIndex(.T.)
   SR_SetExpressionIndex(.F.)

   USE (TABLE_NAME) EXCLUSIVE NEW VIA (RDD_NAME)

   ? "INDEX ON BANK_CODE        TAG " + TAG_1 + " TO " + BAG_NAME
   INDEX ON BANK_CODE TAG (TAG_1) TO (BAG_NAME)

   ? "INDEX ON UPPER(BANK_NAME) TAG " + TAG_2 + " TO " + BAG_NAME
   INDEX ON UPPER(BANK_NAME) TAG (TAG_2) TO (BAG_NAME)

   CLOSE DATABASE

   MostraCatalogo()

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE MostraCatalogo()

   LOCAL oCnn := SR_GetConnection()
   LOCAL aRes := {}
   LOCAL aRow

   ? ""
   ? "Registros em SR_MGMNTINDEXES:"

   oCnn:Exec("select IDXNAME_, TAG_, IDXCOL_, IDXKEY_ from SR_MGMNTINDEXES " + ;
             "where TABLE_ = '" + Upper(TABLE_NAME) + "' order by TAGNUM_", .F., .T., @aRes)

   FOR EACH aRow IN aRes
      ? "  bag=" + AllTrim(SR_Val2Char(aRow[1])) + ;
        "  tag=" + AllTrim(SR_Val2Char(aRow[2])) + ;
        "  idxcol=[" + SR_Val2Char(aRow[3]) + "]" + ;
        "  key=" + AllTrim(SR_Val2Char(aRow[4]))
   NEXT

   ? ""
   ? "Colunas INDKEY_ existentes na tabela:"

   aRes := {}
   oCnn:Exec("select COLUMN_NAME from information_schema.columns " + ;
             "where TABLE_SCHEMA = database() and TABLE_NAME = '" + Lower(TABLE_NAME) + "' " + ;
             "and COLUMN_NAME like 'INDKEY%' order by COLUMN_NAME", .F., .T., @aRes)

   IF Len(aRes) == 0
      ? "  (nenhuma)"
   ELSE
      FOR EACH aRow IN aRes
         ? "  " + AllTrim(SR_Val2Char(aRow[1]))
      NEXT
   ENDIF

RETURN

//--------------------------------------------------------------------
// O ponto central: le IDXCOL_ pelo driver e mede o comprimento.
// 3 = correto. Qualquer valor maior = padding, e o erro vai acontecer.

STATIC PROCEDURE MedePadding()

   LOCAL oCnn := SR_GetConnection()
   LOCAL aRes := {}
   LOCAL aRow
   LOCAL cVal

   ? ""
   ? "=============================================================="
   ? " Comprimento do IDXCOL_ como o driver o entrega"
   ? "=============================================================="

   oCnn:Exec("select IDXCOL_ from SR_MGMNTINDEXES where TABLE_ = '" + ;
             Upper(TABLE_NAME) + "' order by TAGNUM_", .F., .T., @aRes)

   FOR EACH aRow IN aRes
      cVal := SR_Val2Char(aRow[1])
      s_nPad := Max(s_nPad, Len(cVal))
      ? "  [" + cVal + "] len = " + AllTrim(Str(Len(cVal))) + ;
        "   nome montado: [INDKEY_" + cVal + "]"
   NEXT

   ? ""

   IF s_nPad > 3
      ? "  >> PADDING PRESENTE. IDXCOL_ deveria ter 3 caracteres e veio com " + ;
        AllTrim(Str(s_nPad)) + "."
      ? "  >> O nome procurado carrega " + AllTrim(Str(s_nPad - 3)) + ;
        " espacos a mais e nao vai casar com o nome real da coluna."
   ELSEIF s_nPad == 0
      ? "  >> Nenhum registro sintetico encontrado no catalogo."
   ELSE
      ? "  >> Sem padding (len = 3). Este ambiente NAO reproduz o erro."
   ENDIF

RETURN

//--------------------------------------------------------------------
// Reproduz exatamente a sequencia de abertura do relato

STATIC FUNCTION AbreComoNoRelato()

   LOCAL bOld := ErrorBlock({|e|Break(e)})
   LOCAL oErr
   LOCAL lFalhou := .F.
   LOCAL cOnde := ""

   ? ""
   ? "=============================================================="
   ? " Abrindo a tabela como no relato"
   ? "=============================================================="

   BEGIN SEQUENCE

      cOnde := "USE " + TABLE_NAME + " VIA " + RDD_NAME + " SHARED NEW"
      ? cOnde
      USE (TABLE_NAME) VIA (RDD_NAME) SHARED NEW

      cOnde := "SET INDEX TO " + BAG_NAME + " ADDITIVE"
      ? cOnde
      SET INDEX TO (BAG_NAME) ADDITIVE

      cOnde := "SET ORDER TO TAG " + TAG_1
      ? cOnde
      SET ORDER TO TAG (TAG_1)

      cOnde := ""

   RECOVER USING oErr

      lFalhou := .T.

   END SEQUENCE

   ErrorBlock(bOld)

   IF lFalhou
      ? ""
      ? "  FALHOU em: " + cOnde
      ? "  Erro     : " + AllTrim(SR_Val2Char(oErr:description))
   ELSE
      ? ""
      ? "  Abertura concluida sem erro."
      ? "  Ordem ativa: " + AllTrim(SR_Val2Char(ordName())) + ;
        "   registros: " + AllTrim(Str(LastRec()))
      dbGoTop()
      ? "  Primeiro registro na ordem: " + AllTrim(SR_Val2Char(FIELD->BANK_CODE)) + ;
        " - " + AllTrim(SR_Val2Char(FIELD->BANK_NAME))
   ENDIF

RETURN lFalhou

//--------------------------------------------------------------------

STATIC PROCEDURE Veredito(lFalhou)

   ? ""
   ? "=============================================================="
   ? " Resultado"
   ? "=============================================================="

   DO CASE

   CASE lFalhou .AND. s_nPad > 3
      ? "REPRODUZIDO. O IDXCOL_ veio com " + AllTrim(Str(s_nPad)) + " caracteres em vez de 3,"
      ? "e a abertura falhou - e o mesmo caso do relato."

   CASE lFalhou .AND. s_nPad <= 3
      ? "FALHOU, MAS SEM PADDING. O IDXCOL_ veio com o tamanho correto,"
      ? "entao a causa aqui e outra. Vale olhar o sqlerror.log."

   CASE !lFalhou .AND. s_nPad > 3
      ? "CORRIGIDO. O driver ainda entrega IDXCOL_ com " + AllTrim(Str(s_nPad)) + " caracteres,"
      ? "mas a biblioteca normaliza o valor e a abertura funciona."

   OTHERWISE
      ? "OK, porem sem padding neste ambiente - o teste nao exercitou o problema."
      ? "Veja no README como forcar a diferenca de charset no catalogo."

   ENDCASE

RETURN
