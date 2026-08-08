// SQLRDD++
// Valida a navegacao por comparacao de linha - (a,b,c) >= (x,y,z) - contra
// a forma anterior, que expandia a mesma condicao em varias alternativas
// unidas por UNION.
//
// O teste percorre a tabela inteira para frente e para tras, e faz uma
// bateria de SEEKs, DUAS vezes: uma com SR_SetRowCompare(.F.) (forma
// antiga) e outra com .T. (forma nova). As duas sequencias de registros
// tem que ser identicas - e essa e a unica coisa que importa. O tempo de
// cada percurso e mostrado junto, mas e informacao secundaria.
//
// Para compilar:
// hbmk2 testrowcompare
//
// Para executar:
// testrowcompare --server <servidor> --port <porta> --uid <usuario> --pwd <senha> --dtb <banco>

#ifdef __XHARBOUR__
#xtranslate HB_PVALUE([<x,...>]) => PVALUE(<x>)
#endif

#include "sqlrdd.ch"
#include "inkey.ch"

#define RDD_NAME "SQLRDD"
#define TABLE_NAME "testrowc"
#define NUM_REC 2000

REQUEST SQLRDD
REQUEST SR_PGS

STATIC s_SERVER := "localhost"
STATIC s_PORT   := ""
STATIC s_UID    := "postgres"
STATIC s_PWD    := "password"
STATIC s_DTB    := "dbtest"

PROCEDURE Main()

   LOCAL nConnection
   LOCAL n
   LOCAL stringConect
   LOCAL aVelhoFwd, aNovoFwd
   LOCAL aVelhoBwd, aNovoBwd
   LOCAL aVelhoSeek, aNovoSeek
   LOCAL nTVelhoF, nTNovoF, nTVelhoB, nTNovoB
   LOCAL lOk := .T.

   n := 1
   DO WHILE n <= PCount()
      DO CASE
      CASE HB_PValue(n) == "--server" ; s_SERVER := HB_PValue(++n)
      CASE HB_PValue(n) == "--port"   ; s_PORT := HB_PValue(++n)
      CASE HB_PValue(n) == "--uid"    ; s_UID := HB_PValue(++n)
      CASE HB_PValue(n) == "--pwd"    ; s_PWD := HB_PValue(++n)
      CASE HB_PValue(n) == "--dtb"    ; s_DTB := HB_PValue(++n)
      OTHERWISE
         ? "Parametro desconhecido:", HB_PValue(n)
      ENDCASE
      ++n
   ENDDO

   SET DATE ANSI
   SET CENTURY ON

   rddSetDefault(RDD_NAME)

   stringConect := "pgs=" + s_SERVER + IIf(Empty(s_PORT), "", ";prt=" + s_PORT) + ;
                   ";uid=" + s_UID + ";pwd=" + s_PWD + ";dtb=" + s_DTB

   ? "Conectando em " + s_SERVER + "/" + s_DTB + " ..."

   nConnection := sr_AddConnection(CONNECT_POSTGRES, stringConect)

   IF nConnection < 0
      ? "Erro de conexao. Veja sqlerror.log para detalhes."
      WAIT
      QUIT
   ENDIF

   CriaTabela()
   CriaIndice()

   ? ""
   ? "=============================================================="
   ? " Percorrendo com a forma ANTIGA (UNION)"
   ? "=============================================================="

   SR_SetRowCompare(.F.)
   nTVelhoF := Seconds() ; aVelhoFwd := PercorreFrente() ; nTVelhoF := Seconds() - nTVelhoF
   nTVelhoB := Seconds() ; aVelhoBwd := PercorreTras()   ; nTVelhoB := Seconds() - nTVelhoB
   aVelhoSeek := BateriaSeek()

   ? "  para frente : " + AllTrim(Str(Len(aVelhoFwd))) + " registros em " + Str(nTVelhoF, 8, 3) + "s"
   ? "  para tras   : " + AllTrim(Str(Len(aVelhoBwd))) + " registros em " + Str(nTVelhoB, 8, 3) + "s"
   ? "  seeks       : " + AllTrim(Str(Len(aVelhoSeek)))

   ? ""
   ? "=============================================================="
   ? " Percorrendo com a forma NOVA (comparacao por linha)"
   ? "=============================================================="

   SR_SetRowCompare(.T.)
   nTNovoF := Seconds() ; aNovoFwd := PercorreFrente() ; nTNovoF := Seconds() - nTNovoF
   nTNovoB := Seconds() ; aNovoBwd := PercorreTras()   ; nTNovoB := Seconds() - nTNovoB
   aNovoSeek := BateriaSeek()

   ? "  para frente : " + AllTrim(Str(Len(aNovoFwd))) + " registros em " + Str(nTNovoF, 8, 3) + "s"
   ? "  para tras   : " + AllTrim(Str(Len(aNovoBwd))) + " registros em " + Str(nTNovoB, 8, 3) + "s"
   ? "  seeks       : " + AllTrim(Str(Len(aNovoSeek)))

   ? ""
   ? "=============================================================="
   ? " Comparacao"
   ? "=============================================================="

   lOk := Compara("percurso para frente", aVelhoFwd, aNovoFwd) .AND. lOk
   lOk := Compara("percurso para tras  ", aVelhoBwd, aNovoBwd) .AND. lOk
   lOk := Compara("bateria de seeks    ", aVelhoSeek, aNovoSeek) .AND. lOk

   ? ""

   IF lOk
      ? "RESULTADO: as duas formas devolvem exatamente a mesma sequencia."
      IF nTVelhoF > 0
         ? "Ganho no percurso para frente: " + Str(nTVelhoF / Max(nTNovoF, 0.001), 8, 1) + "x"
      ENDIF
   ELSE
      ? "RESULTADO: DIVERGENCIA. A forma nova NAO e equivalente - veja acima."
   ENDIF

   CLOSE DATABASE
   sr_DropTable(TABLE_NAME)
   sr_EndConnection(nConnection)

   ? ""
   WAIT "Pressione uma tecla..."

RETURN

//--------------------------------------------------------------------
// Tabela com chave de 4 colunas e muita repeticao nas colunas da
// esquerda, que e o caso em que a expansao em UNION mais cresce

STATIC PROCEDURE CriaTabela()

   LOCAL i

   ? ""
   ? "Criando " + TABLE_NAME + " com " + AllTrim(Str(NUM_REC)) + " registros..."

   IF sr_ExistTable(TABLE_NAME)
      sr_DropTable(TABLE_NAME)
   ENDIF

   dbCreate(TABLE_NAME, {{"TIPO",   "C",  1, 0}, ;
                         {"GRUPO",  "C",  3, 0}, ;
                         {"CODIGO", "C",  8, 0}, ;
                         {"DESCR",  "C", 30, 0}, ;
                         {"VALOR",  "N", 12, 2}}, RDD_NAME)

   USE (TABLE_NAME) EXCLUSIVE NEW VIA (RDD_NAME)

   FOR i := 1 TO NUM_REC
      dbAppend()
      FIELD->TIPO   := SubStr("EVS", (i % 3) + 1, 1)
      FIELD->GRUPO  := StrZero(i % 7, 3)
      FIELD->CODIGO := StrZero(i % 400, 8)
      FIELD->DESCR  := "Registro " + StrZero(i, 6)
      FIELD->VALOR  := i * 1.5
   NEXT i

   dbCommit()
   CLOSE DATABASE

RETURN

//--------------------------------------------------------------------

STATIC PROCEDURE CriaIndice()

   ? "Criando indice de 4 colunas (TIPO + GRUPO + CODIGO + recno)..."

   USE (TABLE_NAME) EXCLUSIVE NEW VIA (RDD_NAME)
   INDEX ON TIPO + GRUPO + CODIGO TAG ("TESTROWC1") TO ("TESTROWC")
   CLOSE DATABASE

RETURN

//--------------------------------------------------------------------
// Percorre do topo ao fim colhendo a chave de cada registro

STATIC FUNCTION PercorreFrente()

   LOCAL aRet := {}

   USE (TABLE_NAME) SHARED NEW VIA (RDD_NAME)
   SET INDEX TO ("TESTROWC") ADDITIVE
   SET ORDER TO TAG ("TESTROWC1")

   dbGoTop()

   DO WHILE !Eof()
      AAdd(aRet, Chave())
      dbSkip(1)
   ENDDO

   CLOSE DATABASE

RETURN aRet

//--------------------------------------------------------------------

STATIC FUNCTION PercorreTras()

   LOCAL aRet := {}

   USE (TABLE_NAME) SHARED NEW VIA (RDD_NAME)
   SET INDEX TO ("TESTROWC") ADDITIVE
   SET ORDER TO TAG ("TESTROWC1")

   dbGoBottom()

   DO WHILE !Bof()
      AAdd(aRet, Chave())
      dbSkip(-1)
   ENDDO

   CLOSE DATABASE

RETURN aRet

//--------------------------------------------------------------------
// SEEK em chaves existentes e inexistentes, exato e soft

STATIC FUNCTION BateriaSeek()

   LOCAL aRet := {}
   LOCAL i
   LOCAL cKey

   USE (TABLE_NAME) SHARED NEW VIA (RDD_NAME)
   SET INDEX TO ("TESTROWC") ADDITIVE
   SET ORDER TO TAG ("TESTROWC1")

   FOR i := 0 TO 399 STEP 7

      cKey := "E" + StrZero(i % 7, 3) + StrZero(i, 8)
      dbSeek(cKey)
      AAdd(aRet, IIf(Found(), Chave(), "<nao achou> " + cKey))

      dbSeek(cKey, .T.)                       // soft seek
      AAdd(aRet, IIf(Eof(), "<eof> " + cKey, Chave()))

      cKey := "X" + StrZero(i % 7, 3)         // prefixo inexistente
      dbSeek(cKey, .T.)
      AAdd(aRet, IIf(Eof(), "<eof> " + cKey, Chave()))

   NEXT i

   CLOSE DATABASE

RETURN aRet

//--------------------------------------------------------------------

STATIC FUNCTION Chave()
RETURN FIELD->TIPO + "|" + FIELD->GRUPO + "|" + FIELD->CODIGO + "|" + Str(RecNo(), 8)

//--------------------------------------------------------------------

STATIC FUNCTION Compara(cDesc, aVelho, aNovo)

   LOCAL i
   LOCAL nDif := 0

   IF Len(aVelho) != Len(aNovo)
      ? "  " + cDesc + " => DIFERENTE: " + AllTrim(Str(Len(aVelho))) + " x " + ;
        AllTrim(Str(Len(aNovo))) + " registros"
      RETURN .F.
   ENDIF

   FOR i := 1 TO Len(aVelho)
      IF !(aVelho[i] == aNovo[i])
         nDif++
         IF nDif <= 3
            ? "    posicao " + AllTrim(Str(i)) + ": [" + aVelho[i] + "] x [" + aNovo[i] + "]"
         ENDIF
      ENDIF
   NEXT i

   IF nDif == 0
      ? "  " + cDesc + " => OK (" + AllTrim(Str(Len(aVelho))) + " registros identicos)"
      RETURN .T.
   ENDIF

   ? "  " + cDesc + " => DIVERGENTE em " + AllTrim(Str(nDif)) + " posicoes"

RETURN .F.
