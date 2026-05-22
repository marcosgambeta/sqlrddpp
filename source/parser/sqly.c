
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton implementation for Bison's Yacc-like parsers in C

      Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005, 2006
   Free Software Foundation, Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <http://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.4.1"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1

/* Using locations.  */
#define YYLSP_NEEDED 0

/* Substitute the variable and function names.  */
#define yyparse sql_yyparse
#define yylex sql_yylex
#define yyerror sql_yyerror
#define yylval sql_yylval
#define yychar sql_yychar
#define yydebug sql_yydebug
#define yynerrs sql_yynerrs

/* Copy the first part of user declarations.  */

/* Line 189 of yacc.c  */
#line 7 "sql.y"

/*
 * SQLPARSER
 * SQL YACC Rules and Actions
 * Copyright (c) 2003 - Marcelo Lombardo  <lombardo@uol.com.br>
 * All Rights Reserved
 */
#ifdef HB_THREAD_SUPPORT
#undef HB_THREAD_SUPPORT
#endif

#include "hbsql.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <ctype.h>

#include "msg.ch"
#include "hbapi.h"
#include "hbapiitm.h"

/* These symbols are used internally in bison.simple */

#undef alloca
#define alloca hb_xgrab
#undef malloc
#define malloc hb_xgrab
#undef free
#define free hb_xfree

/* Line 189 of yacc.c  */
#line 115 ".hbmk/win/mingw/sqly.c"

/* Enabling traces.  */
#ifndef YYDEBUG
#define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
#undef YYERROR_VERBOSE
#define YYERROR_VERBOSE 1
#else
#define YYERROR_VERBOSE 0
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
#define YYTOKEN_TABLE 0
#endif

/* Tokens.  */
#ifndef YYTOKENTYPE
#define YYTOKENTYPE
/* Put the tokens into the symbol table, so that GDB and other debuggers
   know about them.  */
enum yytokentype
{
  ERRORVAL = 258,
  INTEGERVAL = 259,
  STRINGVAL = 260,
  REALVAL = 261,
  DATEVAL = 262,
  BINDVAR = 263,
  NULLVAL = 264,
  PARAM = 265,
  PARAM_NOT_NULL = 266,
  IDENT = 267,
  QUOTED_IDENT = 268,
  ASTERISK = 269,
  EQUALS = 270,
  COMPARE = 271,
  OPERATOR = 272,
  IS_OP = 273,
  AND_OP = 274,
  OR = 275,
  IN_OP = 276,
  INSERT = 277,
  UPDATE = 278,
  SELECT = 279,
  DELETE_SQL = 280,
  ALL = 281,
  DISTINCT = 282,
  WHERE = 283,
  ORDER = 284,
  LIMIT = 285,
  ASC = 286,
  DESC = 287,
  FROM = 288,
  INTO = 289,
  BY = 290,
  VALUES = 291,
  SET = 292,
  NOT = 293,
  AS = 294,
  UNION = 295,
  LEFT = 296,
  OUTER = 297,
  JOIN = 298,
  GROUP = 299,
  RIGHT = 300,
  LOCK = 301,
  LIKE = 302,
  COUNT = 303,
  MAX = 304,
  MIN = 305,
  TOKEN_ISNULL = 306,
  SUBSTR = 307,
  ABS = 308,
  POWER = 309,
  ROUND = 310,
  TRIM = 311,
  SUM = 312,
  AVG = 313,
  CURRENT_DATE = 314
};
#endif

#if !defined YYSTYPE && !defined YYSTYPE_IS_DECLARED
typedef union YYSTYPE {

/* Line 214 of yacc.c  */
#line 40 "sql.y"

  int int_val;
  double real_val;
  PHB_ITEM item_val;
  int param;
  int iOperator;

/* Line 214 of yacc.c  */
#line 220 ".hbmk/win/mingw/sqly.c"
} YYSTYPE;
#define YYSTYPE_IS_TRIVIAL 1
#define yystype YYSTYPE /* obsolescent; will be withdrawn */
#define YYSTYPE_IS_DECLARED 1
#endif

/* Copy the second part of user declarations.  */

/* Line 264 of yacc.c  */
#line 48 "sql.y"

int yyerror(void *stmt, const char *msg);
int yyparse(void *stmt);
int yylex(YYSTYPE *yylvaluep, void *s);

/* Line 264 of yacc.c  */
#line 239 ".hbmk/win/mingw/sqly.c"

#ifdef short
#undef short
#endif

#ifdef YYTYPE_UINT8
typedef YYTYPE_UINT8 yytype_uint8;
#else
typedef unsigned char yytype_uint8;
#endif

#ifdef YYTYPE_INT8
typedef YYTYPE_INT8 yytype_int8;
#elif (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
typedef signed char yytype_int8;
#else
typedef short int yytype_int8;
#endif

#ifdef YYTYPE_UINT16
typedef YYTYPE_UINT16 yytype_uint16;
#else
typedef unsigned short int yytype_uint16;
#endif

#ifdef YYTYPE_INT16
typedef YYTYPE_INT16 yytype_int16;
#else
typedef short int yytype_int16;
#endif

#ifndef YYSIZE_T
#ifdef __SIZE_TYPE__
#define YYSIZE_T __SIZE_TYPE__
#elif defined size_t
#define YYSIZE_T size_t
#elif !defined YYSIZE_T && (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
#include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#define YYSIZE_T size_t
#else
#define YYSIZE_T unsigned int
#endif
#endif

#define YYSIZE_MAXIMUM ((YYSIZE_T)-1)

#ifndef YY_
#if YYENABLE_NLS
#if ENABLE_NLS
#include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#define YY_(msgid) dgettext("bison-runtime", msgid)
#endif
#endif
#ifndef YY_
#define YY_(msgid) msgid
#endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if !defined lint || defined __GNUC__
#define YYUSE(e) ((void)(e))
#else
#define YYUSE(e) /* empty */
#endif

/* Identity function, used to suppress warnings about constant conditions.  */
#ifndef lint
#define YYID(n) (n)
#else
#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static int YYID(int yyi)
#else
static int YYID(yyi)
int yyi;
#endif
{
  return yyi;
}
#endif

#if !defined yyoverflow || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

#ifdef YYSTACK_USE_ALLOCA
#if YYSTACK_USE_ALLOCA
#ifdef __GNUC__
#define YYSTACK_ALLOC __builtin_alloca
#elif defined __BUILTIN_VA_ARG_INCR
#include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#elif defined _AIX
#define YYSTACK_ALLOC __alloca
#elif defined _MSC_VER
#include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#define alloca _alloca
#else
#define YYSTACK_ALLOC alloca
#if !defined _ALLOCA_H && !defined _STDLIB_H &&                                                                        \
    (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
#include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#ifndef _STDLIB_H
#define _STDLIB_H 1
#endif
#endif
#endif
#endif
#endif

#ifdef YYSTACK_ALLOC
/* Pacify GCC's `empty if-body' warning.  */
#define YYSTACK_FREE(Ptr)                                                                                              \
  do                                                                                                                   \
  { /* empty */                                                                                                        \
    ;                                                                                                                  \
  } while (YYID(0))
#ifndef YYSTACK_ALLOC_MAXIMUM
/* The OS might guarantee only one guard page at the bottom of the stack,
   and a page size can be as small as 4096 bytes.  So we cannot safely
   invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
   to allow for a few compiler-allocated temporary stack slots.  */
#define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#endif
#else
#define YYSTACK_ALLOC YYMALLOC
#define YYSTACK_FREE YYFREE
#ifndef YYSTACK_ALLOC_MAXIMUM
#define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#endif
#if (defined __cplusplus && !defined _STDLIB_H &&                                                                      \
     !((defined YYMALLOC || defined malloc) && (defined YYFREE || defined free)))
#include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#ifndef _STDLIB_H
#define _STDLIB_H 1
#endif
#endif
#ifndef YYMALLOC
#define YYMALLOC malloc
#if !defined malloc && !defined _STDLIB_H &&                                                                           \
    (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
void *malloc(YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#endif
#endif
#ifndef YYFREE
#define YYFREE free
#if !defined free && !defined _STDLIB_H &&                                                                             \
    (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
void free(void *); /* INFRINGES ON USER NAME SPACE */
#endif
#endif
#endif
#endif /* ! defined yyoverflow || YYERROR_VERBOSE */

#if (!defined yyoverflow && (!defined __cplusplus || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc {
  yytype_int16 yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
#define YYSTACK_GAP_MAXIMUM (sizeof(union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
#define YYSTACK_BYTES(N) ((N) * (sizeof(yytype_int16) + sizeof(YYSTYPE)) + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
#ifndef YYCOPY
#if defined __GNUC__ && 1 < __GNUC__
#define YYCOPY(To, From, Count) __builtin_memcpy(To, From, (Count) * sizeof(*(From)))
#else
#define YYCOPY(To, From, Count)                                                                                        \
  do                                                                                                                   \
  {                                                                                                                    \
    YYSIZE_T yyi;                                                                                                      \
    for (yyi = 0; yyi < (Count); yyi++)                                                                                \
      (To)[yyi] = (From)[yyi];                                                                                         \
  } while (YYID(0))
#endif
#endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
#define YYSTACK_RELOCATE(Stack_alloc, Stack)                                                                           \
  do                                                                                                                   \
  {                                                                                                                    \
    YYSIZE_T yynewbytes;                                                                                               \
    YYCOPY(&yyptr->Stack_alloc, Stack, yysize);                                                                        \
    Stack = &yyptr->Stack_alloc;                                                                                       \
    yynewbytes = yystacksize * sizeof(*Stack) + YYSTACK_GAP_MAXIMUM;                                                   \
    yyptr += yynewbytes / sizeof(*yyptr);                                                                              \
  } while (YYID(0))

#endif

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL 24
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST 595

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS 64
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS 46
/* YYNRULES -- Number of rules.  */
#define YYNRULES 141
/* YYNRULES -- Number of states.  */
#define YYNSTATES 288

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK 2
#define YYMAXUTOK 314

#define YYTRANSLATE(YYX) ((unsigned int)(YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const yytype_uint8 yytranslate[] = {
    0,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  61, 62, 2,  2,  60, 2,  63, 2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,
    2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  1,  2,  3,  4,  5,
    6,  7,  8,  9,  10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34,
    35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const yytype_uint16 yyprhs[] = {
    0,   0,   3,   7,   9,   11,  13,  15,  17,  19,  23,  28,  32,  37,  47,  48,  52,  54,  58,  60,  63,
    66,  67,  70,  79,  85,  90,  92,  96,  100, 101, 105, 107, 111, 113, 117, 119, 120, 122, 124, 129, 132,
    134, 138, 140, 141, 144, 147, 150, 152, 156, 160, 164, 170, 176, 178, 182, 186, 190, 194, 198, 204, 212,
    218, 224, 230, 234, 238, 242, 245, 247, 253, 257, 261, 263, 267, 270, 275, 276, 278, 280, 282, 284, 287,
    288, 291, 292, 296, 298, 302, 304, 312, 318, 322, 323, 325, 329, 331, 335, 337, 340, 342, 346, 350, 354,
    359, 365, 371, 378, 385, 391, 397, 401, 405, 409, 414, 418, 424, 430, 434, 436, 437, 439, 441, 447, 449,
    451, 453, 455, 457, 459, 461, 463, 465, 468, 472, 476, 478, 480, 484, 489, 491};

/* YYRHS -- A `-1'-separated list of the rules' RHS.  */
static const yytype_int8 yyrhs[] = {
    65,  0,  -1,  66,  97,  69,  -1,  73,  -1,  74,  -1,  75,  -1,  1,   -1,  68,  -1,  67,  -1,  67, 40,  68, -1,
    67,  40, 26,  68,  -1,  68,  40,  68,  -1,  68,  40,  26,  68,  -1,  24,  104, 82,  72,  83,  33, 89,  93, 94,
    -1,  -1, 29,  35,  70,  -1,  71,  -1,  70,  60,  71,  -1,  108, -1,  108, 31,  -1,  108, 32,  -1, -1,  30, 4,
    -1,  22, 34,  92,  78,  36,  61,  80,  62,  -1,  23,  90,  37,  76,  93,  -1,  25,  33,  90,  93, -1,  77, -1,
    76,  60, 77,  -1,  109, 15,  86,  -1,  -1,  61,  79,  62,  -1,  109, -1,  79,  60,  109, -1,  81, -1,  80, 60,
    81,  -1, 107, -1,  -1,  26,  -1,  27,  -1,  83,  60,  84,  85,  -1,  84,  85,  -1,  86,  -1,  12, 63,  14, -1,
    14,  -1, -1,  39,  5,   -1,  39,  12,  -1,  39,  13,  -1,  87,  -1,  61,  86,  62,  -1,  86,  17, 87,  -1, 86,
    14,  87, -1,  86,  17,  61,  86,  62,  -1,  86,  14,  61,  86,  62,  -1,  106, -1,  48,  88,  62, -1,  48, 14,
    62,  -1, 53,  88,  62,  -1,  49,  88,  62,  -1,  50,  88,  62,  -1,  51,  88,  60,  88,  62,  -1, 52,  88, 60,
    88,  60, 88,  62,  -1,  52,  88,  60,  88,  62,  -1,  54,  88,  60,  88,  62,  -1,  55,  88,  60, 88,  62, -1,
    56,  88, 62,  -1,  57,  88,  62,  -1,  58,  88,  62,  -1,  59,  62,  -1,  106, -1,  51,  88,  60, 88,  62, -1,
    88,  17, 105, -1,  88,  14,  105, -1,  90,  -1,  89,  60,  90,  -1,  92,  91,  -1,  61,  66,  62, 91,  -1, -1,
    12,  -1, 12,  -1,  13,  -1,  10,  -1,  8,   12,  -1,  -1,  28,  98,  -1,  -1,  44,  35,  95,  -1, 96,  -1, 95,
    60,  96, -1,  108, -1,  52,  108, 60,  107, 60,  107, 62,  -1,  52,  108, 60,  107, 62,  -1,  56, 108, 62, -1,
    -1,  99, -1,  98,  20,  99,  -1,  100, -1,  99,  19,  100, -1,  101, -1,  38,  101, -1,  102, -1, 61,  98, 62,
    -1,  86, 15,  86,  -1,  108, 47,  107, -1,  108, 38,  47,  107, -1,  108, 21,  61,  66,  62,  -1, 108, 21, 61,
    103, 62, -1,  108, 38,  21,  61,  66,  62,  -1,  108, 38,  21,  61,  103, 62,  -1,  86,  15,  61, 68,  62, -1,
    86,  16, 61,  68,  62,  -1,  86,  16,  86,  -1,  86,  18,  9,   -1,  106, 38,  9,   -1,  86,  18, 38,  9,  -1,
    108, 43, 108, -1,  108, 41,  42,  43,  108, -1,  108, 45,  42,  43,  108, -1,  103, 60,  107, -1, 107, -1, -1,
    46,  -1, 106, -1,  51,  106, 60,  106, 62,  -1,  107, -1,  108, -1,  4,   -1,  6,   -1,  5,   -1, 9,   -1, 7,
    -1,  10, -1,  11,  -1,  8,   12,  -1,  12,  63,  13,  -1,  12,  63,  12,  -1,  13,  -1,  12,  -1, 12,  63, 10,
    -1,  12, 63,  8,   12,  -1,  12,  -1,  13,  -1};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const yytype_uint16 yyrline[] = {
    0,   175, 175, 181, 187, 193, 199, 210, 215, 223, 228, 233, 238, 246, 254, 258, 266, 270, 277, 282, 287,
    295, 300, 308, 315, 322, 329, 334, 341, 348, 352, 359, 363, 370, 374, 381, 388, 393, 398, 406, 411, 419,
    423, 428, 436, 441, 446, 451, 459, 464, 469, 474, 479, 484, 492, 497, 502, 507, 512, 517, 522, 527, 532,
    537, 542, 547, 552, 557, 562, 570, 575, 580, 585, 593, 598, 606, 611, 619, 624, 632, 637, 642, 647, 655,
    660, 668, 673, 681, 686, 694, 697, 702, 707, 714, 720, 725, 733, 738, 746, 751, 759, 763, 771, 776, 781,
    786, 791, 796, 801, 806, 811, 816, 821, 826, 831, 836, 841, 846, 854, 859, 867, 872, 880, 884, 892, 897,
    905, 910, 915, 920, 925, 930, 935, 940, 948, 953, 958, 963, 968, 973, 981, 986};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] = {"$end",
                                      "error",
                                      "$undefined",
                                      "ERRORVAL",
                                      "INTEGERVAL",
                                      "STRINGVAL",
                                      "REALVAL",
                                      "DATEVAL",
                                      "BINDVAR",
                                      "NULLVAL",
                                      "PARAM",
                                      "PARAM_NOT_NULL",
                                      "IDENT",
                                      "QUOTED_IDENT",
                                      "ASTERISK",
                                      "EQUALS",
                                      "COMPARE",
                                      "OPERATOR",
                                      "IS_OP",
                                      "AND_OP",
                                      "OR",
                                      "IN_OP",
                                      "INSERT",
                                      "UPDATE",
                                      "SELECT",
                                      "DELETE_SQL",
                                      "ALL",
                                      "DISTINCT",
                                      "WHERE",
                                      "ORDER",
                                      "LIMIT",
                                      "ASC",
                                      "DESC",
                                      "FROM",
                                      "INTO",
                                      "BY",
                                      "VALUES",
                                      "SET",
                                      "NOT",
                                      "AS",
                                      "UNION",
                                      "LEFT",
                                      "OUTER",
                                      "JOIN",
                                      "GROUP",
                                      "RIGHT",
                                      "LOCK",
                                      "LIKE",
                                      "COUNT",
                                      "MAX",
                                      "MIN",
                                      "TOKEN_ISNULL",
                                      "SUBSTR",
                                      "ABS",
                                      "POWER",
                                      "ROUND",
                                      "TRIM",
                                      "SUM",
                                      "AVG",
                                      "CURRENT_DATE",
                                      "','",
                                      "'('",
                                      "')'",
                                      "'.'",
                                      "$accept",
                                      "sql_expression",
                                      "select_final",
                                      "union_expression",
                                      "select_expression",
                                      "opt_order_by",
                                      "order_by_item_commalist",
                                      "order_by_item",
                                      "opt_limit",
                                      "insert_final",
                                      "update_final",
                                      "delete_final",
                                      "update_item_commalist",
                                      "update_item",
                                      "insert_item_expression",
                                      "insert_item_commalist",
                                      "insert_value_commalist",
                                      "insert_col_value",
                                      "opt_dist",
                                      "select_item_commalist",
                                      "select_item",
                                      "opt_as",
                                      "column",
                                      "select_col_constructor",
                                      "col_constructor_expr",
                                      "table_reference_commalist",
                                      "table_reference",
                                      "opt_table_alias",
                                      "table",
                                      "opt_where",
                                      "opt_group",
                                      "group_by_item_commalist",
                                      "group_by_col_expr",
                                      "opt_having",
                                      "conditional_expression",
                                      "conditional_term",
                                      "conditional_factor",
                                      "conditional_primary",
                                      "simple_condition",
                                      "scalar_expression_commalist",
                                      "opt_lock",
                                      "col_constructor2",
                                      "col_constructor",
                                      "col_value",
                                      "col_name",
                                      "col_list_name",
                                      0};
#endif

#ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const yytype_uint16 yytoknum[] = {0,   256, 257, 258, 259, 260, 261, 262, 263, 264, 265, 266, 267, 268, 269, 270,
                                         271, 272, 273, 274, 275, 276, 277, 278, 279, 280, 281, 282, 283, 284, 285, 286,
                                         287, 288, 289, 290, 291, 292, 293, 294, 295, 296, 297, 298, 299, 300, 301, 302,
                                         303, 304, 305, 306, 307, 308, 309, 310, 311, 312, 313, 314, 44,  40,  41,  46};
#endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const yytype_uint8 yyr1[] = {
    0,   64,  65,  65,  65,  65,  65,  66,  66,  67,  67,  67,  67,  68,  69,  69,  70,  70,  71,  71,  71,
    72,  72,  73,  74,  75,  76,  76,  77,  78,  78,  79,  79,  80,  80,  81,  82,  82,  82,  83,  83,  84,
    84,  84,  85,  85,  85,  85,  86,  86,  86,  86,  86,  86,  87,  87,  87,  87,  87,  87,  87,  87,  87,
    87,  87,  87,  87,  87,  87,  88,  88,  88,  88,  89,  89,  90,  90,  91,  91,  92,  92,  92,  92,  93,
    93,  94,  94,  95,  95,  96,  96,  96,  96,  97,  98,  98,  99,  99,  100, 100, 101, 101, 102, 102, 102,
    102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 102, 103, 103, 104, 104, 105, 105, 106, 106,
    107, 107, 107, 107, 107, 107, 107, 107, 108, 108, 108, 108, 108, 108, 109, 109};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const yytype_uint8 yyr2[] = {
    0, 2, 3, 1, 1, 1, 1, 1, 1, 3, 4, 3, 4, 9, 0, 3, 1, 3, 1, 2, 2, 0, 2, 8, 5, 4, 1, 3, 3, 0, 3, 1, 3, 1, 3, 1,
    0, 1, 1, 4, 2, 1, 3, 1, 0, 2, 2, 2, 1, 3, 3, 3, 5, 5, 1, 3, 3, 3, 3, 3, 5, 7, 5, 5, 5, 3, 3, 3, 2, 1, 5, 3,
    3, 1, 3, 2, 4, 0, 1, 1, 1, 1, 2, 0, 2, 0, 3, 1, 3, 1, 7, 5, 3, 0, 1, 3, 1, 3, 1, 2, 1, 3, 3, 3, 4, 5, 5, 6,
    6, 5, 5, 3, 3, 3, 4, 3, 5, 5, 3, 1, 0, 1, 1, 5, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 3, 3, 1, 1, 3, 4, 1, 1};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const yytype_uint8 yydefact[] = {
    0,   6,   0,   0,   120, 0,   0,  93,  8,   7,  3,   4,  5,   0,   0,   81,  79,  80,  0,  0,   77,  121, 36,  0,
    1,   14,  0,   0,   29,  82,  0,  0,   78,  75, 37,  38, 21,  83,  0,   2,   0,   9,   0,  11,  0,   0,   77,  140,
    141, 83,  26,  0,   0,   0,   0,  25,  0,   10, 12,  0,  31,  0,   76,  0,   24,  0,   22, 126, 128, 127, 130, 0,
    129, 131, 132, 137, 136, 43,  0,  0,   0,   0,  0,   0,  0,   0,   0,   0,   0,   0,   0,  0,   44,  41,  48,  54,
    124, 125, 137, 0,   0,   0,   84, 94,  96,  98, 100, 54, 125, 15,  16,  18,  0,   30,  0,  27,  28,  133, 0,   0,
    0,   0,   69,  0,   0,   0,   0,  0,   0,   0,  0,   0,  0,   68,  0,   0,   0,   0,   40, 0,   0,   0,   99,  0,
    0,   0,   0,   0,   0,   0,   0,  0,   0,   0,  0,   0,  0,   0,   19,  20,  32,  0,   33, 35,  0,   138, 135, 134,
    42,  56,  0,   0,   0,   55,  58, 59,  0,   0,  57,  0,  0,   65,  66,  67,  49,  83,  73, 44,  45,  46,  47,  0,
    51,  0,   50,  101, 0,   102, 0,  111, 112, 0,  95,  97, 113, 0,   0,   0,   0,   115, 0,  103, 17,  0,   23,  139,
    0,   0,   72,  122, 71,  0,   0,  0,   0,   0,  85,  39, 0,   0,   0,   0,   114, 0,   0,  119, 0,   104, 0,   0,
    34,  0,   0,   60,  0,   62,  63, 64,  74,  0,  13,  53, 52,  109, 110, 105, 0,   106, 0,  0,   116, 117, 70,  0,
    0,   0,   118, 107, 108, 0,   61, 0,   0,   86, 87,  89, 123, 0,   0,   0,   0,   92,  88, 0,   0,   91,  0,   90};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_int16 yydefgoto[] = {-1,  6,   7,   8,   9,   39,  109, 110, 53,  10,  11,  12, 49, 50, 45,  59,
                                         161, 162, 36,  91,  92,  138, 101, 94,  121, 185, 19,  33, 20, 55, 250, 273,
                                         274, 25,  102, 103, 104, 105, 106, 234, 22,  218, 122, 96, 97, 51};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -102
static const yytype_int16 yypact[] = {
    167,  -102, -23,  2,    10,   -5,   64,   -102, 46,   51,   -102, -102, -102, 188,  65,   -102, -102, -102,
    90,   95,   152,  -102, 126,  2,    -102, 107,  173,  197,  82,   -102, 110,  28,   -102, -102, -102, -102,
    151,  175,  174,  -102, 90,   -102, 90,   -102, 28,   177,  152,  -102, -102, -12,  -102, 205,  268,  226,
    248,  -102, 282,  -102, -102, 58,   -102, 212,  -102, 28,   -102, 327,  -102, -102, -102, -102, -102, 296,
    -102, -102, -102, 262,  -102, -102, 237,  496,  496,  496,  496,  496,  496,  496,  496,  496,  496,  280,
    327,  49,   308,  190,  -102, -102, -102, -102, 286,  385,  248,  275,  331,  333,  -102, -102, -102, 315,
    303,  309,  -102, 127,  28,   -102, 554,  -102, 190,  -102, 161,  310,  496,  25,   -102, 48,   55,   30,
    37,   57,   62,   146,  61,   66,   71,   -102, 94,   2,    226,  14,   -102, 399,  413,  202,  -102, 43,
    5,    471,  485,  12,   248,  248,  359,  312,  60,   329,  282,  332,  554,  282,  -102, -102, -102, 166,
    -102, -102, 375,  -102, -102, -102, -102, -102, 148,  544,  544,  -102, -102, -102, 496,  496,  -102, 496,
    496,  -102, -102, -102, -102, -11,  -102, 308,  -102, -102, -102, 327,  -102, 327,  -102, -102, 306,  190,
    306,  190,  -102, 390,  333,  -102, -102, 507,  339,  554,  358,  -102, 370,  -102, -102, 554,  -102, -102,
    496,  258,  -102, -102, -102, 99,   6,    120,  124,  2,    371,  -102, 125,  131,  340,  352,  -102, 354,
    260,  -102, 507,  -102, 282,  282,  -102, 133,  367,  -102, 496,  -102, -102, -102, -102, 393,  -102, -102,
    -102, -102, -102, -102, 554,  -102, 368,  261,  -102, -102, -102, 258,  140,  314,  -102, -102, -102, 369,
    -102, 282,  282,  372,  -102, -102, -102, 425,  383,  314,  554,  -102, -102, 283,  554,  -102, 397,  -102};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] = {-102, -102, -17,  -102, -18,  -102, -102, 272,  -102, -102, -102, -102,
                                       -102, 410,  -102, -102, -102, 273,  -102, -102, 351,  301,  31,   189,
                                       -50,  -102, -20,  453,  497,  -45,  -102, -102, 266,  -102, 466,  419,
                                       420,  469,  -102, 334,  -102, 400,  -47,  -101, -54,  -39};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -1
static const yytype_uint16 yytable[] = {
    108, 30,  111, 37,  64,  60,  95,  107, 41,  43,  14,  13,  15,  163, 16,  17,  54,  54,  95,  188, 171, 200, 57,
    172, 58,  148, 189, 190, 23,  123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 171, 47,  48,  172, 95,  171, 108,
    108, 172, 63,  225, 201, 171, 107, 107, 172, 211, 21,  139, 145, 146, 140, 147, 171, 18,  24,  172, 244, 195, 245,
    171, 170, 171, 172, 160, 172, 171, 171, 29,  172, 172, 171, 206, 135, 172, 93,  171, 26,  173, 172, 95,  176, 27,
    95,  95,  108, 108, 116, 177, 95,  95,  209, 107, 107, 111, 235, 184, 237, 207, 139, 136, 174, 140, 163, 171, 4,
    186, 172, 175, 112, 178, 113, 134, 179, 181, 219, 219, 221, 222, 182, 223, 224, 143, 31,  183, 171, 235, 38,  172,
    171, 139, 226, 172, 140, 44,  95,  139, 95,  171, 140, 95,  172, 95,  34,  35,  171, 266, 184, 172, 158, 159, 171,
    243, 171, 172, 32,  172, 241, 93,  1,   164, 242, 165, 46,  166, 167, 168, 197, 199, 230, 283, 231, 52,  246, 286,
    260, 261, 247, 251, 233, 2,   3,   4,   5,   252, 264, 262, 14,  4,   15,  40,  16,  17,  270, 54,  139, 248, 180,
    140, 216, 56,  164, 275, 165, 61,  166, 167, 269, 277, 278, 258, 65,  4,   228, 42,  229, 275, 213, 134, 214, 134,
    67,  68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  67,  68,  69,  70,  71,  72,  73,  74,  98,  76,  119, 67,
    68,  69,  70,  71,  72,  73,  74,  98,  76,  67,  68,  69,  70,  71,  72,  73,  74,  98,  76,  66,  114, 78,  79,
    80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  99,  90,  120, 139, 145, 146, 140, 147, 98,  76,  78,  79,  80,
    81,  82,  83,  84,  85,  86,  87,  88,  89,  117, 100, 67,  68,  69,  70,  71,  72,  73,  74,  98,  76,  256, 256,
    257, 268, 151, 118, 98,  76,  192, 194, 4,   67,  68,  69,  70,  71,  72,  73,  74,  98,  76,  152, 133, 284, 153,
    285, 154, 137, 155, 141, 156, 148, 149, 150, 78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  271, 90,
    204, 157, 272, 208, 169, 205, 210, 78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  215, 90,  67,  68,
    69,  70,  71,  72,  73,  74,  98,  76,  232, 236, 238, 253, 67,  68,  69,  70,  71,  72,  73,  74,  98,  76,  239,
    254, 249, 255, 67,  68,  69,  70,  71,  72,  73,  74,  98,  76,  263, 265, 212, 267, 276, 279, 78,  79,  80,  81,
    82,  83,  84,  85,  86,  87,  88,  89,  281, 100, 78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  287,
    191, 78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  115, 193, 67,  68,  69,  70,  71,  72,  73,  74,
    98,  76,  280, 240, 187, 227, 67,  68,  69,  70,  71,  72,  73,  74,  98,  76,  62,  67,  68,  69,  70,  71,  72,
    73,  74,  98,  76,  28,  67,  68,  69,  70,  71,  72,  73,  74,  78,  79,  80,  81,  82,  83,  84,  85,  86,  87,
    88,  89,  4,   196, 78,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  282, 198, 120, 67,  68,  69,  70,
    71,  72,  73,  74,  98,  76,  67,  68,  69,  70,  71,  72,  73,  74,  144, 202, 142, 203, 259, 0,   220, 0,   0,
    0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   0,   217};

static const yytype_int16 yycheck[] = {
    54,  18,  56,  23,  49,  44,  53,  54,  26,  27,  8,   34,  10,  114, 12,  13,  28,  28,  65,  5,   14,  9,   40,
    17,  42,  20,  12,  13,  33,  79,  80,  81,  82,  83,  84,  85,  86,  87,  88,  14,  12,  13,  17,  90,  14,  99,
    100, 17,  60,  60,  38,  14,  99,  100, 17,  156, 46,  14,  15,  16,  17,  18,  14,  61,  0,   17,  60,  62,  62,
    14,  120, 14,  17,  112, 17,  14,  14,  12,  17,  17,  14,  21,  33,  17,  53,  14,  40,  62,  17,  136, 60,  40,
    139, 140, 148, 149, 65,  60,  145, 146, 154, 148, 149, 157, 205, 62,  207, 47,  14,  60,  62,  17,  213, 14,  24,
    135, 17,  62,  60,  62,  62,  90,  60,  62,  171, 172, 176, 177, 62,  179, 180, 100, 37,  62,  14,  236, 29,  17,
    14,  14,  185, 17,  17,  61,  191, 14,  193, 14,  17,  196, 17,  198, 26,  27,  14,  256, 62,  17,  31,  32,  14,
    62,  14,  17,  12,  17,  216, 136, 1,   8,   217, 10,  62,  12,  13,  14,  145, 146, 196, 280, 198, 30,  62,  284,
    238, 239, 62,  62,  205, 22,  23,  24,  25,  62,  244, 62,  8,   24,  10,  26,  12,  13,  62,  28,  14,  225, 60,
    17,  60,  35,  8,   265, 10,  36,  12,  13,  263, 271, 272, 236, 15,  24,  191, 26,  193, 279, 60,  196, 62,  198,
    4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  14,  4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  14,  4,
    5,   6,   7,   8,   9,   10,  11,  12,  13,  4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  4,   61,  48,  49,
    50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  38,  61,  51,  14,  15,  16,  17,  18,  12,  13,  48,  49,  50,
    51,  52,  53,  54,  55,  56,  57,  58,  59,  12,  61,  4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  60,  60,
    62,  62,  21,  63,  12,  13,  139, 140, 24,  4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  38,  62,  60,  41,
    62,  43,  39,  45,  63,  47,  20,  19,  38,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  52,  61,
    9,   60,  56,  42,  62,  61,  42,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  12,  61,  4,   5,
    6,   7,   8,   9,   10,  11,  12,  13,  9,   61,  43,  62,  4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  43,
    62,  44,  62,  4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  60,  35,  157, 62,  62,  60,  48,  49,  50,  51,
    52,  53,  54,  55,  56,  57,  58,  59,  62,  61,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  62,
    61,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  63,  61,  4,   5,   6,   7,   8,   9,   10,  11,
    12,  13,  60,  213, 136, 187, 4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  46,  4,   5,   6,   7,   8,   9,
    10,  11,  12,  13,  13,  4,   5,   6,   7,   8,   9,   10,  11,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,
    58,  59,  24,  61,  48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  279, 61,  51,  4,   5,   6,   7,
    8,   9,   10,  11,  12,  13,  4,   5,   6,   7,   8,   9,   10,  11,  100, 148, 99,  149, 236, -1,  172, -1,  -1,
    -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  -1,  51};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const yytype_uint8 yystos[] = {
    0,  1,   22,  23,  24,  25,  65,  66,  67,  68, 73,  74,  75,  34,  8,   10,  12,  13, 61, 90,  92, 46, 104,
    33, 0,   97,  40,  40,  92,  12,  66,  37,  12, 91,  26,  27,  82,  90,  29,  69,  26, 68, 26,  68, 61, 78,
    62, 12,  13,  76,  77,  109, 30,  72,  28,  93, 35,  68,  68,  79,  109, 36,  91,  60, 93, 15,  4,  4,  5,
    6,  7,   8,   9,   10,  11,  12,  13,  14,  48, 49,  50,  51,  52,  53,  54,  55,  56, 57, 58,  59, 61, 83,
    84, 86,  87,  106, 107, 108, 12,  38,  61,  86, 98,  99,  100, 101, 102, 106, 108, 70, 71, 108, 60, 62, 61,
    77, 86,  12,  63,  14,  51,  88,  106, 88,  88, 88,  88,  88,  88,  88,  88,  88,  88, 62, 86,  33, 60, 39,
    85, 14,  17,  63,  101, 86,  98,  15,  16,  18, 20,  19,  38,  21,  38,  41,  43,  45, 47, 60,  31, 32, 109,
    80, 81,  107, 8,   10,  12,  13,  14,  62,  88, 14,  17,  62,  62,  62,  60,  60,  62, 60, 60,  62, 62, 62,
    62, 89,  90,  84,  5,   12,  13,  61,  87,  61, 87,  62,  61,  86,  61,  86,  9,   38, 99, 100, 9,  61, 21,
    47, 42,  108, 42,  107, 71,  60,  62,  12,  60, 51,  105, 106, 105, 88,  88,  88,  88, 60, 93,  85, 86, 86,
    68, 68,  9,   66,  103, 107, 61,  107, 43,  43, 81,  88,  106, 62,  60,  62,  62,  62, 90, 44,  94, 62, 62,
    62, 62,  62,  60,  62,  66,  103, 108, 108, 62, 60,  88,  35,  107, 62,  62,  106, 62, 52, 56,  95, 96, 108,
    62, 108, 108, 60,  60,  62,  96,  107, 60,  62, 107, 62};

#define yyerrok (yyerrstatus = 0)
#define yyclearin (yychar = YYEMPTY)
#define YYEMPTY (-2)
#define YYEOF 0

#define YYACCEPT goto yyacceptlab
#define YYABORT goto yyabortlab
#define YYERROR goto yyerrorlab

/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL goto yyerrlab

#define YYRECOVERING() (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                                                                         \
  do                                                                                                                   \
    if (yychar == YYEMPTY && yylen == 1)                                                                               \
    {                                                                                                                  \
      yychar = (Token);                                                                                                \
      yylval = (Value);                                                                                                \
      yytoken = YYTRANSLATE(yychar);                                                                                   \
      YYPOPSTACK(1);                                                                                                   \
      goto yybackup;                                                                                                   \
    }                                                                                                                  \
    else                                                                                                               \
    {                                                                                                                  \
      yyerror(stmt, YY_("syntax error: cannot back up"));                                                              \
      YYERROR;                                                                                                         \
    }                                                                                                                  \
  while (YYID(0))

#define YYTERROR 1
#define YYERRCODE 256

/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
#define YYLLOC_DEFAULT(Current, Rhs, N)                                                                                \
  do                                                                                                                   \
    if (YYID(N))                                                                                                       \
    {                                                                                                                  \
      (Current).first_line = YYRHSLOC(Rhs, 1).first_line;                                                              \
      (Current).first_column = YYRHSLOC(Rhs, 1).first_column;                                                          \
      (Current).last_line = YYRHSLOC(Rhs, N).last_line;                                                                \
      (Current).last_column = YYRHSLOC(Rhs, N).last_column;                                                            \
    }                                                                                                                  \
    else                                                                                                               \
    {                                                                                                                  \
      (Current).first_line = (Current).last_line = YYRHSLOC(Rhs, 0).last_line;                                         \
      (Current).first_column = (Current).last_column = YYRHSLOC(Rhs, 0).last_column;                                   \
    }                                                                                                                  \
  while (YYID(0))
#endif

/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
#if YYLTYPE_IS_TRIVIAL
#define YY_LOCATION_PRINT(File, Loc)                                                                                   \
  fprintf(File, "%d.%d-%d.%d", (Loc).first_line, (Loc).first_column, (Loc).last_line, (Loc).last_column)
#else
#define YY_LOCATION_PRINT(File, Loc) ((void)0)
#endif
#endif

/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
#define YYLEX yylex(&yylval, YYLEX_PARAM)
#else
#define YYLEX yylex(&yylval, stmt)
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

#ifndef YYFPRINTF
#include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#define YYFPRINTF fprintf
#endif

#define YYDPRINTF(Args)                                                                                                \
  do                                                                                                                   \
  {                                                                                                                    \
    if (yydebug)                                                                                                       \
      YYFPRINTF Args;                                                                                                  \
  } while (YYID(0))

#define YY_SYMBOL_PRINT(Title, Type, Value, Location)                                                                  \
  do                                                                                                                   \
  {                                                                                                                    \
    if (yydebug)                                                                                                       \
    {                                                                                                                  \
      YYFPRINTF(stderr, "%s ", Title);                                                                                 \
      yy_symbol_print(stderr, Type, Value, stmt);                                                                      \
      YYFPRINTF(stderr, "\n");                                                                                         \
    }                                                                                                                  \
  } while (YYID(0))

/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static void yy_symbol_value_print(FILE *yyoutput, int yytype, YYSTYPE const *const yyvaluep, void *stmt)
#else
static void yy_symbol_value_print(yyoutput, yytype, yyvaluep, stmt) FILE *yyoutput;
int yytype;
YYSTYPE const *const yyvaluep;
void *stmt;
#endif
{
  if (!yyvaluep)
    return;
  YYUSE(stmt);
#ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT(yyoutput, yytoknum[yytype], *yyvaluep);
#else
  YYUSE(yyoutput);
#endif
  switch (yytype)
  {
  default:
    break;
  }
}

/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static void yy_symbol_print(FILE *yyoutput, int yytype, YYSTYPE const *const yyvaluep, void *stmt)
#else
static void yy_symbol_print(yyoutput, yytype, yyvaluep, stmt) FILE *yyoutput;
int yytype;
YYSTYPE const *const yyvaluep;
void *stmt;
#endif
{
  if (yytype < YYNTOKENS)
    YYFPRINTF(yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF(yyoutput, "nterm %s (", yytname[yytype]);

  yy_symbol_value_print(yyoutput, yytype, yyvaluep, stmt);
  YYFPRINTF(yyoutput, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static void yy_stack_print(yytype_int16 *yybottom, yytype_int16 *yytop)
#else
static void yy_stack_print(yybottom, yytop) yytype_int16 *yybottom;
yytype_int16 *yytop;
#endif
{
  YYFPRINTF(stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
  {
    int yybot = *yybottom;
    YYFPRINTF(stderr, " %d", yybot);
  }
  YYFPRINTF(stderr, "\n");
}

#define YY_STACK_PRINT(Bottom, Top)                                                                                    \
  do                                                                                                                   \
  {                                                                                                                    \
    if (yydebug)                                                                                                       \
      yy_stack_print((Bottom), (Top));                                                                                 \
  } while (YYID(0))

/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static void yy_reduce_print(YYSTYPE *yyvsp, int yyrule, void *stmt)
#else
static void yy_reduce_print(yyvsp, yyrule, stmt) YYSTYPE *yyvsp;
int yyrule;
void *stmt;
#endif
{
  int yynrhs = yyr2[yyrule];
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF(stderr, "Reducing stack by rule %d (line %lu):\n", yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
  {
    YYFPRINTF(stderr, "   $%d = ", yyi + 1);
    yy_symbol_print(stderr, yyrhs[yyprhs[yyrule] + yyi], &(yyvsp[(yyi + 1) - (yynrhs)]), stmt);
    YYFPRINTF(stderr, "\n");
  }
}

#define YY_REDUCE_PRINT(Rule)                                                                                          \
  do                                                                                                                   \
  {                                                                                                                    \
    if (yydebug)                                                                                                       \
      yy_reduce_print(yyvsp, Rule, stmt);                                                                              \
  } while (YYID(0))

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
#define YYDPRINTF(Args)
#define YY_SYMBOL_PRINT(Title, Type, Value, Location)
#define YY_STACK_PRINT(Bottom, Top)
#define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */

/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
#define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
#define YYMAXDEPTH 10000
#endif

#if YYERROR_VERBOSE

#ifndef yystrlen
#if defined __GLIBC__ && defined _STRING_H
#define yystrlen strlen
#else
/* Return the length of YYSTR.  */
#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static YYSIZE_T yystrlen(const char *yystr)
#else
static YYSIZE_T yystrlen(yystr) const char *yystr;
#endif
{
  YYSIZE_T yylen;
  for (yylen = 0; yystr[yylen]; yylen++)
    continue;
  return yylen;
}
#endif
#endif

#ifndef yystpcpy
#if defined __GLIBC__ && defined _STRING_H && defined _GNU_SOURCE
#define yystpcpy stpcpy
#else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static char *yystpcpy(char *yydest, const char *yysrc)
#else
static char *yystpcpy(yydest, yysrc)
char *yydest;
const char *yysrc;
#endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#endif
#endif

#ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T yytnamerr(char *yyres, const char *yystr)
{
  if (*yystr == '"')
  {
    YYSIZE_T yyn = 0;
    char const *yyp = yystr;

    for (;;)
      switch (*++yyp)
      {
      case '\'':
      case ',':
        goto do_not_strip_quotes;

      case '\\':
        if (*++yyp != '\\')
          goto do_not_strip_quotes;
        /* Fall through.  */
      default:
        if (yyres)
          yyres[yyn] = *yyp;
        yyn++;
        break;

      case '"':
        if (yyres)
          yyres[yyn] = '\0';
        return yyn;
      }
  do_not_strip_quotes:;
  }

  if (!yyres)
    return yystrlen(yystr);

  return yystpcpy(yyres, yystr) - yyres;
}
#endif

/* Copy into YYRESULT an error message about the unexpected token
   YYCHAR while in state YYSTATE.  Return the number of bytes copied,
   including the terminating null byte.  If YYRESULT is null, do not
   copy anything; just return the number of bytes that would be
   copied.  As a special case, return 0 if an ordinary "syntax error"
   message will do.  Return YYSIZE_MAXIMUM if overflow occurs during
   size calculation.  */
static YYSIZE_T yysyntax_error(char *yyresult, int yystate, int yychar)
{
  int yyn = yypact[yystate];

  if (!(YYPACT_NINF < yyn && yyn <= YYLAST))
    return 0;
  else
  {
    int yytype = YYTRANSLATE(yychar);
    YYSIZE_T yysize0 = yytnamerr(0, yytname[yytype]);
    YYSIZE_T yysize = yysize0;
    YYSIZE_T yysize1;
    int yysize_overflow = 0;
    enum
    {
      YYERROR_VERBOSE_ARGS_MAXIMUM = 5
    };
    char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
    int yyx;

#if 0
      /* This is so xgettext sees the translatable formats that are
	 constructed on the fly.  */
      YY_("syntax error, unexpected %s");
      YY_("syntax error, unexpected %s, expecting %s");
      YY_("syntax error, unexpected %s, expecting %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s");
      YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
#endif
    char *yyfmt;
    char const *yyf;
    static char const yyunexpected[] = "syntax error, unexpected %s";
    static char const yyexpecting[] = ", expecting %s";
    static char const yyor[] = " or %s";
    char yyformat[sizeof yyunexpected + sizeof yyexpecting - 1 +
                  ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2) * (sizeof yyor - 1))];
    char const *yyprefix = yyexpecting;

    /* Start YYX at -YYN if negative to avoid negative indexes in
   YYCHECK.  */
    int yyxbegin = yyn < 0 ? -yyn : 0;

    /* Stay within bounds of both yycheck and yytname.  */
    int yychecklim = YYLAST - yyn + 1;
    int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
    int yycount = 1;

    yyarg[0] = yytname[yytype];
    yyfmt = yystpcpy(yyformat, yyunexpected);

    for (yyx = yyxbegin; yyx < yyxend; ++yyx)
      if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
      {
        if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
        {
          yycount = 1;
          yysize = yysize0;
          yyformat[sizeof yyunexpected - 1] = '\0';
          break;
        }
        yyarg[yycount++] = yytname[yyx];
        yysize1 = yysize + yytnamerr(0, yytname[yyx]);
        yysize_overflow |= (yysize1 < yysize);
        yysize = yysize1;
        yyfmt = yystpcpy(yyfmt, yyprefix);
        yyprefix = yyor;
      }

    yyf = YY_(yyformat);
    yysize1 = yysize + yystrlen(yyf);
    yysize_overflow |= (yysize1 < yysize);
    yysize = yysize1;

    if (yysize_overflow)
      return YYSIZE_MAXIMUM;

    if (yyresult)
    {
      /* Avoid sprintf, as that infringes on the user's name space.
         Don't have undefined behavior even if the translation
         produced a string with the wrong number of "%s"s.  */
      char *yyp = yyresult;
      int yyi = 0;
      while ((*yyp = *yyf) != '\0')
      {
        if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
        {
          yyp += yytnamerr(yyp, yyarg[yyi++]);
          yyf += 2;
        }
        else
        {
          yyp++;
          yyf++;
        }
      }
    }
    return yysize;
  }
}
#endif /* YYERROR_VERBOSE */

/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

/*ARGSUSED*/
#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
static void yydestruct(const char *yymsg, int yytype, YYSTYPE *yyvaluep, void *stmt)
#else
static void yydestruct(yymsg, yytype, yyvaluep, stmt) const char *yymsg;
int yytype;
YYSTYPE *yyvaluep;
void *stmt;
#endif
{
  YYUSE(yyvaluep);
  YYUSE(stmt);

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT(yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
  {

  default:
    break;
  }
}

/* Prevent warnings from -Wmissing-prototypes.  */
#ifdef YYPARSE_PARAM
#if defined __STDC__ || defined __cplusplus
int yyparse(void *YYPARSE_PARAM);
#else
int yyparse();
#endif
#else /* ! YYPARSE_PARAM */
#if defined __STDC__ || defined __cplusplus
int yyparse(void *stmt);
#else
int yyparse();
#endif
#endif /* ! YYPARSE_PARAM */

/*-------------------------.
| yyparse or yypush_parse.  |
`-------------------------*/

#ifdef YYPARSE_PARAM
#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
int yyparse(void *YYPARSE_PARAM)
#else
int yyparse(YYPARSE_PARAM) void *YYPARSE_PARAM;
#endif
#else /* ! YYPARSE_PARAM */
#if (defined __STDC__ || defined __C99__FUNC__ || defined __cplusplus || defined _MSC_VER)
int yyparse(void *stmt)
#else
int yyparse(stmt) void *stmt;
#endif
#endif
{
  /* The lookahead symbol.  */
  int yychar;

  /* The semantic value of the lookahead symbol.  */
  YYSTYPE yylval;

  /* Number of syntax errors so far.  */
  int yynerrs;

  int yystate;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;

  /* The stacks and their tools:
     `yyss': related to states.
     `yyvs': related to semantic values.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  yytype_int16 yyssa[YYINITDEPTH];
  yytype_int16 *yyss;
  yytype_int16 *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs;
  YYSTYPE *yyvsp;

  YYSIZE_T yystacksize;

  int yyn;
  int yyresult;
  /* Lookahead token as an internal (translated) token number.  */
  int yytoken;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;

#if YYERROR_VERBOSE
  /* Buffer for error messages, and its allocated size.  */
  char yymsgbuf[128];
  char *yymsg = yymsgbuf;
  YYSIZE_T yymsg_alloc = sizeof yymsgbuf;
#endif

#define YYPOPSTACK(N) (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  yytoken = 0;
  yyss = yyssa;
  yyvs = yyvsa;
  yystacksize = YYINITDEPTH;

  YYDPRINTF((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY; /* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */
  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

  /*------------------------------------------------------------.
  | yynewstate -- Push a new state, which is found in yystate.  |
  `------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;

yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
  {
    /* Get the current used size of the three stacks, in elements.  */
    YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
    {
      /* Give user a chance to reallocate the stack.  Use copies of
         these so that the &'s don't force the real ones into
         memory.  */
      YYSTYPE *yyvs1 = yyvs;
      yytype_int16 *yyss1 = yyss;

      /* Each stack pointer address is followed by the size of the
         data in use in that stack, in bytes.  This used to be a
         conditional around just the two extra args, but that might
         be undefined if yyoverflow is a macro.  */
      yyoverflow(YY_("memory exhausted"), &yyss1, yysize * sizeof(*yyssp), &yyvs1, yysize * sizeof(*yyvsp),
                 &yystacksize);

      yyss = yyss1;
      yyvs = yyvs1;
    }
#else /* no yyoverflow */
#ifndef YYSTACK_RELOCATE
    goto yyexhaustedlab;
#else
    /* Extend the stack our own way.  */
    if (YYMAXDEPTH <= yystacksize)
      goto yyexhaustedlab;
    yystacksize *= 2;
    if (YYMAXDEPTH < yystacksize)
      yystacksize = YYMAXDEPTH;

    {
      yytype_int16 *yyss1 = yyss;
      union yyalloc *yyptr = (union yyalloc *)YYSTACK_ALLOC(YYSTACK_BYTES(yystacksize));
      if (!yyptr)
        goto yyexhaustedlab;
      YYSTACK_RELOCATE(yyss_alloc, yyss);
      YYSTACK_RELOCATE(yyvs_alloc, yyvs);
#undef YYSTACK_RELOCATE
      if (yyss1 != yyssa)
        YYSTACK_FREE(yyss1);
    }
#endif
#endif /* no yyoverflow */

    yyssp = yyss + yysize - 1;
    yyvsp = yyvs + yysize - 1;

    YYDPRINTF((stderr, "Stack size increased to %lu\n", (unsigned long int)yystacksize));

    if (yyss + yystacksize - 1 <= yyssp)
      YYABORT;
  }

  YYDPRINTF((stderr, "Entering state %d\n", yystate));

  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid lookahead symbol.  */
  if (yychar == YYEMPTY)
  {
    YYDPRINTF((stderr, "Reading a token: "));
    yychar = YYLEX;
  }

  if (yychar <= YYEOF)
  {
    yychar = yytoken = YYEOF;
    YYDPRINTF((stderr, "Now at end of input.\n"));
  }
  else
  {
    yytoken = YYTRANSLATE(yychar);
    YY_SYMBOL_PRINT("Next token is", yytoken, &yylval, &yylloc);
  }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
  {
    if (yyn == 0 || yyn == YYTABLE_NINF)
      goto yyerrlab;
    yyn = -yyn;
    goto yyreduce;
  }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the shifted token.  */
  yychar = YYEMPTY;

  yystate = yyn;
  *++yyvsp = yylval;

  goto yynewstate;

/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;

/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1 - yylen];

  YY_REDUCE_PRINT(yyn);
  switch (yyn)
  {
  case 2:

/* Line 1455 of yacc.c  */
#line 175 "sql.y"
  {
    // printf( "Found select_final\n" );
    ((sql_stmt *)stmt)->pArray =
        (PHB_ITEM)SQLpCodeGenArrayJoin((yyvsp[(1) - (3)].item_val), (yyvsp[(3) - (3)].item_val));
    (yyval.item_val) = ((sql_stmt *)stmt)->pArray;
    YYACCEPT;
    ;
  }
  break;

  case 3:

/* Line 1455 of yacc.c  */
#line 181 "sql.y"
  {
    // printf( "Found insert_final\n" );
    ((sql_stmt *)stmt)->pArray = (yyvsp[(1) - (1)].item_val);
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    YYACCEPT;
    ;
  }
  break;

  case 4:

/* Line 1455 of yacc.c  */
#line 187 "sql.y"
  {
    // printf( "Found update_final\n" );
    ((sql_stmt *)stmt)->pArray = (yyvsp[(1) - (1)].item_val);
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    YYACCEPT;
    ;
  }
  break;

  case 5:

/* Line 1455 of yacc.c  */
#line 193 "sql.y"
  {
    // printf( "Found delete_final\n" );
    ((sql_stmt *)stmt)->pArray = (yyvsp[(1) - (1)].item_val);
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    YYACCEPT;
    ;
  }
  break;

  case 6:

/* Line 1455 of yacc.c  */
#line 199 "sql.y"
  {
    // printf( "Parse error.\n" );
    if (((sql_stmt *)stmt)->pTemp)
    {
      hb_itemRelease(((sql_stmt *)stmt)->pTemp);
    }
    YYABORT;
    ;
  }
  break;

  case 7:

/* Line 1455 of yacc.c  */
#line 210 "sql.y"
  {
    // printf( "Select expression\n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 8:

/* Line 1455 of yacc.c  */
#line 215 "sql.y"
  {
    // printf( "Select expression with UNION\n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 9:

/* Line 1455 of yacc.c  */
#line 223 "sql.y"
  {
    // printf( "Double UNION\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_SELECT_UNION),
                                            (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 10:

/* Line 1455 of yacc.c  */
#line 228 "sql.y"
  {
    // printf( "Double UNION ALL\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (4)].item_val), SQL_PCODE_SELECT_UNION_ALL), (yyvsp[(4) - (4)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 11:

/* Line 1455 of yacc.c  */
#line 233 "sql.y"
  {
    // printf( "UNION\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_SELECT_UNION),
                                            (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 12:

/* Line 1455 of yacc.c  */
#line 238 "sql.y"
  {
    // printf( "UNION ALL\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (4)].item_val), SQL_PCODE_SELECT_UNION_ALL), (yyvsp[(4) - (4)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 13:

/* Line 1455 of yacc.c  */
#line 246 "sql.y"
  {
    // printf( "Found a SELECT\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayJoin(
            SQLpCodeGenArrayJoin(
                SQLpCodeGenArrayInt(
                    SQLpCodeGenArrayJoin(
                        SQLpCodeGenArrayJoin(
                            SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt((yyvsp[(2) - (9)].item_val), SQL_PCODE_SELECT),
                                                 (yyvsp[(3) - (9)].item_val)),
                            (yyvsp[(4) - (9)].item_val)),
                        (yyvsp[(5) - (9)].item_val)),
                    SQL_PCODE_SELECT_FROM),
                (yyvsp[(7) - (9)].item_val)),
            (yyvsp[(8) - (9)].item_val)),
        (yyvsp[(9) - (9)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 14:

/* Line 1455 of yacc.c  */
#line 254 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_SELECT_NO_ORDER);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 15:

/* Line 1455 of yacc.c  */
#line 258 "sql.y"
  {
    // printf( "opt_order_by\n" );
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_SELECT_ORDER, (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 16:

/* Line 1455 of yacc.c  */
#line 266 "sql.y"
  {
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 17:

/* Line 1455 of yacc.c  */
#line 270 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR), (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 18:

/* Line 1455 of yacc.c  */
#line 277 "sql.y"
  {
    // printf( "Found order_by_item col_name\n" );
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_SELECT_ORDER_ASC, (yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 19:

/* Line 1455 of yacc.c  */
#line 282 "sql.y"
  {
    // printf( "Found order_by_item col_name ASC\n" );
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_SELECT_ORDER_ASC, (yyvsp[(1) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 20:

/* Line 1455 of yacc.c  */
#line 287 "sql.y"
  {
    // printf( "Found order_by_item col_name DESC\n" );
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_SELECT_ORDER_DESC, (yyvsp[(1) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 21:

/* Line 1455 of yacc.c  */
#line 295 "sql.y"
  {
    // printf( "No Limit\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_SELECT_NO_LIMIT);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 22:

/* Line 1455 of yacc.c  */
#line 300 "sql.y"
  {
    // printf( "Limit %i\n", $2 );
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_SELECT_LIMIT, SQLpCodeGenInt((int)(yyvsp[(2) - (2)].int_val)));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 23:

/* Line 1455 of yacc.c  */
#line 308 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenIntArray(SQL_PCODE_INSERT, (yyvsp[(3) - (8)].item_val)),
                                                 (yyvsp[(4) - (8)].item_val)),
                            SQL_PCODE_INSERT_VALUES),
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_START_EXPR, (yyvsp[(7) - (8)].item_val)),
                            SQL_PCODE_STOP_EXPR));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 24:

/* Line 1455 of yacc.c  */
#line 315 "sql.y"
  {
    (yyval.item_val) =
        SQLpCodeGenArrayJoin(SQLpCodeGenArrayJoin(SQLpCodeGenIntArray(SQL_PCODE_UPDATE, (yyvsp[(2) - (5)].item_val)),
                                                  (yyvsp[(4) - (5)].item_val)),
                             (yyvsp[(5) - (5)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 25:

/* Line 1455 of yacc.c  */
#line 322 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayJoin(SQLpCodeGenIntArray(SQL_PCODE_DELETE, (yyvsp[(3) - (4)].item_val)),
                                            (yyvsp[(4) - (4)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 26:

/* Line 1455 of yacc.c  */
#line 329 "sql.y"
  {
    // printf( "Update commanlist ITEM\n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 27:

/* Line 1455 of yacc.c  */
#line 334 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR), (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 28:

/* Line 1455 of yacc.c  */
#line 341 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            (yyvsp[(2) - (3)].iOperator)),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 29:

/* Line 1455 of yacc.c  */
#line 348 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_INSERT_NO_LIST);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 30:

/* Line 1455 of yacc.c  */
#line 352 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_START_EXPR, (yyvsp[(2) - (3)].item_val)),
                                           SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 31:

/* Line 1455 of yacc.c  */
#line 359 "sql.y"
  {
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 32:

/* Line 1455 of yacc.c  */
#line 363 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR), (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 33:

/* Line 1455 of yacc.c  */
#line 370 "sql.y"
  {
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 34:

/* Line 1455 of yacc.c  */
#line 374 "sql.y"
  {
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR), (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 35:

/* Line 1455 of yacc.c  */
#line 381 "sql.y"
  {
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 36:

/* Line 1455 of yacc.c  */
#line 388 "sql.y"
  {
    // printf( "OPT ALL\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_SELECT_ALL);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 37:

/* Line 1455 of yacc.c  */
#line 393 "sql.y"
  {
    // printf( "OPT ALL\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_SELECT_ALL);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 38:

/* Line 1455 of yacc.c  */
#line 398 "sql.y"
  {
    // printf( "DISTINCT\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_SELECT_DISTINCT);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 39:

/* Line 1455 of yacc.c  */
#line 406 "sql.y"
  {
    // printf( "select_item_commalist BY select_item_commalist, select_item\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt((yyvsp[(1) - (4)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR),
                             (yyvsp[(3) - (4)].item_val)),
        (yyvsp[(4) - (4)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 40:

/* Line 1455 of yacc.c  */
#line 411 "sql.y"
  {
    // printf( "select_item_commalist BY select_item\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin((yyvsp[(1) - (2)].item_val), (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 41:

/* Line 1455 of yacc.c  */
#line 419 "sql.y"
  {
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 42:

/* Line 1455 of yacc.c  */
#line 423 "sql.y"
  {
    // printf( "%s.*\n", hb_itemGetCPtr((PHB_ITEM)$1) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_SELECT_ITEM_ALIAS_ASTER, (yyvsp[(1) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 43:

/* Line 1455 of yacc.c  */
#line 428 "sql.y"
  {
    // printf( "*\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_SELECT_ITEM_ASTERISK);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 44:

/* Line 1455 of yacc.c  */
#line 436 "sql.y"
  {
    // printf( "NO AS\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_COLUMN_NO_AS);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 45:

/* Line 1455 of yacc.c  */
#line 441 "sql.y"
  {
    // printf( "AS %s \n", hb_itemGetCPtr((PHB_ITEM)$2) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_AS, (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 46:

/* Line 1455 of yacc.c  */
#line 446 "sql.y"
  {
    // printf( "AS %s \n", hb_itemGetCPtr((PHB_ITEM)$2) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_AS, (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 47:

/* Line 1455 of yacc.c  */
#line 451 "sql.y"
  {
    // printf( "AS_QUOTE %s \n", hb_itemGetCPtr((PHB_ITEM)$2) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_AS, (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 48:

/* Line 1455 of yacc.c  */
#line 459 "sql.y"
  {
    // printf( "column BY select_col_constructor\n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 49:

/* Line 1455 of yacc.c  */
#line 464 "sql.y"
  {
    // printf( "column BY ( column )\n" );
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_START_EXPR, (yyvsp[(2) - (3)].item_val)),
                                           SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 50:

/* Line 1455 of yacc.c  */
#line 469 "sql.y"
  {
    // printf( "column BY column OPERATOR select_col_constructor\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            (yyvsp[(2) - (3)].iOperator)),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 51:

/* Line 1455 of yacc.c  */
#line 474 "sql.y"
  {
    // printf( "column BY  column ASTERISK select_col_constructor\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            (yyvsp[(2) - (3)].iOperator)),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 52:

/* Line 1455 of yacc.c  */
#line 479 "sql.y"
  {
    // printf( "column BY column OPERATOR ( column )\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (5)].item_val)),
                            (yyvsp[(2) - (5)].iOperator)),
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_START_EXPR, (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 53:

/* Line 1455 of yacc.c  */
#line 484 "sql.y"
  {
    // printf( "column BY column ASTERISK ( column )\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (5)].item_val)),
                            (yyvsp[(2) - (5)].iOperator)),
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_START_EXPR, (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 54:

/* Line 1455 of yacc.c  */
#line 492 "sql.y"
  {
    // printf( "col constructor\n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 55:

/* Line 1455 of yacc.c  */
#line 497 "sql.y"
  {
    // printf( "COUNT() function\n" );
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_COUNT, (yyvsp[(2) - (3)].item_val)),
                                           SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 56:

/* Line 1455 of yacc.c  */
#line 502 "sql.y"
  {
    // printf( "COUNT(*) \n" );
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenInt(SQL_PCODE_FUNC_COUNT_AST), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 57:

/* Line 1455 of yacc.c  */
#line 507 "sql.y"
  {
    // printf( "ABS() function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_ABS, (yyvsp[(2) - (3)].item_val)), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 58:

/* Line 1455 of yacc.c  */
#line 512 "sql.y"
  {
    // printf( "MAX() function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_MAX, (yyvsp[(2) - (3)].item_val)), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 59:

/* Line 1455 of yacc.c  */
#line 517 "sql.y"
  {
    // printf( "MIN() function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_MIN, (yyvsp[(2) - (3)].item_val)), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 60:

/* Line 1455 of yacc.c  */
#line 522 "sql.y"
  {
    // printf( "ISNULL( , ) function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_ISNULL,
                                                                                         (yyvsp[(2) - (5)].item_val)),
                                                                     SQL_PCODE_COLUMN_LIST_SEPARATOR),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 61:

/* Line 1455 of yacc.c  */
#line 527 "sql.y"
  {
    // printf( "SUBSTR( , , ) function\n" );
    (yyval.item_val) = SQLpCodeGenArrayInt(
        SQLpCodeGenArrayJoin(
            SQLpCodeGenArrayInt(
                SQLpCodeGenArrayJoin(
                    SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_SUBSTR2, (yyvsp[(2) - (7)].item_val)),
                                        SQL_PCODE_COLUMN_LIST_SEPARATOR),
                    (yyvsp[(4) - (7)].item_val)),
                SQL_PCODE_COLUMN_LIST_SEPARATOR),
            (yyvsp[(6) - (7)].item_val)),
        SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 62:

/* Line 1455 of yacc.c  */
#line 532 "sql.y"
  {
    // printf( "SUBSTR( , ) function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_SUBSTR,
                                                                                         (yyvsp[(2) - (5)].item_val)),
                                                                     SQL_PCODE_COLUMN_LIST_SEPARATOR),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 63:

/* Line 1455 of yacc.c  */
#line 537 "sql.y"
  {
    // printf( "power( , ) function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenIntArray(SQL_PCODE_FUNC_POWER, (yyvsp[(2) - (5)].item_val)),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 64:

/* Line 1455 of yacc.c  */
#line 542 "sql.y"
  {
    // printf( "ROUND( , ) function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenIntArray(SQL_PCODE_FUNC_ROUND, (yyvsp[(2) - (5)].item_val)),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 65:

/* Line 1455 of yacc.c  */
#line 547 "sql.y"
  {
    // printf( "TRIM() function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_TRIM, (yyvsp[(2) - (3)].item_val)), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 66:

/* Line 1455 of yacc.c  */
#line 552 "sql.y"
  {
    // printf( "SUM() function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_SUM, (yyvsp[(2) - (3)].item_val)), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 67:

/* Line 1455 of yacc.c  */
#line 557 "sql.y"
  {
    // printf( "AVG() function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_AVG, (yyvsp[(2) - (3)].item_val)), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 68:

/* Line 1455 of yacc.c  */
#line 562 "sql.y"
  {
    // printf( "DATE() function\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_FUNC_DATE);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 69:

/* Line 1455 of yacc.c  */
#line 570 "sql.y"
  {
    // printf( "col constructor_expr\n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 70:

/* Line 1455 of yacc.c  */
#line 575 "sql.y"
  {
    // printf( "ISNULL( , ) function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_ISNULL,
                                                                                         (yyvsp[(2) - (5)].item_val)),
                                                                     SQL_PCODE_COLUMN_LIST_SEPARATOR),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 71:

/* Line 1455 of yacc.c  */
#line 580 "sql.y"
  {
    // printf( "col constructor_expr OPERATOR: %i\n", $2 );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            (yyvsp[(2) - (3)].iOperator)),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 72:

/* Line 1455 of yacc.c  */
#line 585 "sql.y"
  {
    // printf( "col constructor_expr ASTERISK: %i\n", $2 );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            (yyvsp[(2) - (3)].iOperator)),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 73:

/* Line 1455 of yacc.c  */
#line 593 "sql.y"
  {
    // printf( "table_reference_commalist \n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 74:

/* Line 1455 of yacc.c  */
#line 598 "sql.y"
  {
    // printf( "table_reference_commalist \n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR), (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 75:

/* Line 1455 of yacc.c  */
#line 606 "sql.y"
  {
    // printf( "table_reference\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin((yyvsp[(1) - (2)].item_val), (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 76:

/* Line 1455 of yacc.c  */
#line 611 "sql.y"
  {
    // printf( "table_reference - SUBQUERY\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_START_EXPR, (yyvsp[(2) - (4)].item_val)),
                                                 SQL_PCODE_STOP_EXPR),
                             (yyvsp[(4) - (4)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 77:

/* Line 1455 of yacc.c  */
#line 619 "sql.y"
  {
    // printf( "NO TABLE_ALIAS" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_TABLE_NO_ALIAS);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 78:

/* Line 1455 of yacc.c  */
#line 624 "sql.y"
  {
    // printf( "TABLE Alias %s \n", hb_itemGetCPtr((PHB_ITEM)$1) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_TABLE_ALIAS, (yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 79:

/* Line 1455 of yacc.c  */
#line 632 "sql.y"
  {
    // printf( "TABLE identifier: %s \n", hb_itemGetCPtr((PHB_ITEM)$1) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_TABLE_NAME, (yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 80:

/* Line 1455 of yacc.c  */
#line 637 "sql.y"
  {
    // printf( "TABLE identifier (quoted): %s \n", hb_itemGetCPtr((PHB_ITEM)$1) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_TABLE_NAME, (yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 81:

/* Line 1455 of yacc.c  */
#line 642 "sql.y"
  {
    // printf( "PARAMETER table_reference %i\n", $1 );
    (yyval.item_val) =
        SQLpCodeGenIntItem(SQL_PCODE_TABLE_PARAM, hb_itemPutNI(hb_itemNew(NULL), (yyvsp[(1) - (1)].param)));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 82:

/* Line 1455 of yacc.c  */
#line 647 "sql.y"
  {
    // printf( "BINDVAR table_reference: %s\n", hb_itemGetCPtr((PHB_ITEM)$2) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_TABLE_BINDVAR, (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 83:

/* Line 1455 of yacc.c  */
#line 655 "sql.y"
  {
    // printf( "Do not have a WHERE clause\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_NO_WHERE);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 84:

/* Line 1455 of yacc.c  */
#line 660 "sql.y"
  {
    // printf( "WHERE clause\n" );
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_WHERE, (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 85:

/* Line 1455 of yacc.c  */
#line 668 "sql.y"
  {
    // printf( "NO GROUP_BY\n" );
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_SELECT_NO_GROUPBY);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 86:

/* Line 1455 of yacc.c  */
#line 673 "sql.y"
  {
    // printf( "opt_group_by\n" );
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_SELECT_GROUPBY, (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 87:

/* Line 1455 of yacc.c  */
#line 681 "sql.y"
  {
    // printf( "group_by_item_commalist col_name\n" );
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 88:

/* Line 1455 of yacc.c  */
#line 686 "sql.y"
  {
    // printf( "group_by_item_commalist , colname\n" );
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR), (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 89:

/* Line 1455 of yacc.c  */
#line 694 "sql.y"
  {
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    ;
  }
  break;

  case 90:

/* Line 1455 of yacc.c  */
#line 697 "sql.y"
  {
    // printf( "SUBSTR( , , ) function in ORDER BY\n" );
    (yyval.item_val) = SQLpCodeGenArrayInt(
        SQLpCodeGenArrayJoin(
            SQLpCodeGenArrayInt(
                SQLpCodeGenArrayJoin(
                    SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_SUBSTR2, (yyvsp[(2) - (7)].item_val)),
                                        SQL_PCODE_COLUMN_LIST_SEPARATOR),
                    (yyvsp[(4) - (7)].item_val)),
                SQL_PCODE_COLUMN_LIST_SEPARATOR),
            (yyvsp[(6) - (7)].item_val)),
        SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 91:

/* Line 1455 of yacc.c  */
#line 702 "sql.y"
  {
    // printf( "SUBSTR( , ) function in ORDER BY\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_SUBSTR,
                                                                                         (yyvsp[(2) - (5)].item_val)),
                                                                     SQL_PCODE_COLUMN_LIST_SEPARATOR),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 92:

/* Line 1455 of yacc.c  */
#line 707 "sql.y"
  {
    // printf( "TRIM() function in ORDER BY\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_TRIM, (yyvsp[(2) - (3)].item_val)), SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 94:

/* Line 1455 of yacc.c  */
#line 720 "sql.y"
  {
    // printf("conditional_expression\n");
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 95:

/* Line 1455 of yacc.c  */
#line 725 "sql.y"
  {
    // printf("OR operator\n");
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            SQL_PCODE_OPERATOR_OR),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 96:

/* Line 1455 of yacc.c  */
#line 733 "sql.y"
  {
    // printf("conditional_term\n");
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 97:

/* Line 1455 of yacc.c  */
#line 738 "sql.y"
  {
    // printf("AND operator\n");
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            SQL_PCODE_OPERATOR_AND),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 98:

/* Line 1455 of yacc.c  */
#line 746 "sql.y"
  {
    // printf("conditional_primary\n");
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 99:

/* Line 1455 of yacc.c  */
#line 751 "sql.y"
  {
    // printf("NOT conditional_primary\n");
    (yyval.item_val) = SQLpCodeGenIntArray(SQL_PCODE_NOT_EXPR, (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 100:

/* Line 1455 of yacc.c  */
#line 759 "sql.y"
  {
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 101:

/* Line 1455 of yacc.c  */
#line 763 "sql.y"
  {
    // printf("(conditional_primary_parentisis)\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_START_EXPR, (yyvsp[(2) - (3)].item_val)),
                                           SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 102:

/* Line 1455 of yacc.c  */
#line 771 "sql.y"
  {
    // printf("comparison_operator %i\n", $2);
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            (yyvsp[(2) - (3)].iOperator)),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 103:

/* Line 1455 of yacc.c  */
#line 776 "sql.y"
  {
    // printf("like_operator %i\n", $2);
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            SQL_PCODE_OPERATOR_LIKE),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 104:

/* Line 1455 of yacc.c  */
#line 781 "sql.y"
  {
    // printf("not like_operator %i\n", $2);
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (4)].item_val)),
                            SQL_PCODE_OPERATOR_NOT_LIKE),
        (yyvsp[(4) - (4)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 105:

/* Line 1455 of yacc.c  */
#line 786 "sql.y"
  {
    // printf("in_condition subquery\n");
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenArrayIntInt((yyvsp[(1) - (5)].item_val),
                                                                        SQL_PCODE_OPERATOR_IN, SQL_PCODE_START_EXPR),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 106:

/* Line 1455 of yacc.c  */
#line 791 "sql.y"
  {
    // printf("in_condition scalar expression\n");
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenArrayIntInt((yyvsp[(1) - (5)].item_val),
                                                                        SQL_PCODE_OPERATOR_IN, SQL_PCODE_START_EXPR),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 107:

/* Line 1455 of yacc.c  */
#line 796 "sql.y"
  {
    // printf("in_condition subquery\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(
        SQLpCodeGenArrayJoin(
            SQLpCodeGenArrayIntInt((yyvsp[(1) - (6)].item_val), SQL_PCODE_OPERATOR_IN + 1, SQL_PCODE_START_EXPR),
            (yyvsp[(5) - (6)].item_val)),
        SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 108:

/* Line 1455 of yacc.c  */
#line 801 "sql.y"
  {
    // printf("in_condition scalar expression\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(
        SQLpCodeGenArrayJoin(
            SQLpCodeGenArrayIntInt((yyvsp[(1) - (6)].item_val), SQL_PCODE_OPERATOR_IN + 1, SQL_PCODE_START_EXPR),
            (yyvsp[(5) - (6)].item_val)),
        SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 109:

/* Line 1455 of yacc.c  */
#line 806 "sql.y"
  {
    // printf("equals subquery\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(
        SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE,
                                                                                         (yyvsp[(1) - (5)].item_val)),
                                                                     (yyvsp[(2) - (5)].iOperator)),
                                                 SQL_PCODE_START_EXPR),
                             (yyvsp[(4) - (5)].item_val)),
        SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 110:

/* Line 1455 of yacc.c  */
#line 811 "sql.y"
  {
    // printf("equals subquery\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(
        SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE,
                                                                                         (yyvsp[(1) - (5)].item_val)),
                                                                     (yyvsp[(2) - (5)].iOperator)),
                                                 SQL_PCODE_START_EXPR),
                             (yyvsp[(4) - (5)].item_val)),
        SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 111:

/* Line 1455 of yacc.c  */
#line 816 "sql.y"
  {
    // printf("comparison_operator %i\n", $2);
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            (yyvsp[(2) - (3)].iOperator)),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 112:

/* Line 1455 of yacc.c  */
#line 821 "sql.y"
  {
    // printf("comparison_operator == NULL\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                                           SQL_PCODE_OPERATOR_IS_NULL);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 113:

/* Line 1455 of yacc.c  */
#line 826 "sql.y"
  {
    // printf("comparison_operator == NOT NULL\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                                           SQL_PCODE_OPERATOR_IS_NOT_NULL);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 114:

/* Line 1455 of yacc.c  */
#line 831 "sql.y"
  {
    // printf("comparison_operator == NOT NULL\n");
    (yyval.item_val) = SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (4)].item_val)),
                                           SQL_PCODE_OPERATOR_IS_NOT_NULL);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 115:

/* Line 1455 of yacc.c  */
#line 836 "sql.y"
  {
    // printf("Simple JOIN\n");
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_BASE, (yyvsp[(1) - (3)].item_val)),
                            SQL_PCODE_OPERATOR_JOIN),
        (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 116:

/* Line 1455 of yacc.c  */
#line 841 "sql.y"
  {
    // printf("LEFT OUTER JOIN\n");
    (yyval.item_val) =
        SQLpCodeGenArrayJoin(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_LEFT_OUTER_JOIN, (yyvsp[(1) - (5)].item_val)),
                             (yyvsp[(5) - (5)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 117:

/* Line 1455 of yacc.c  */
#line 846 "sql.y"
  {
    // printf("RIGHT OUTER JOIN\n");
    (yyval.item_val) =
        SQLpCodeGenArrayJoin(SQLpCodeGenIntArray(SQL_PCODE_OPERATOR_RIGHT_OUTER_JOIN, (yyvsp[(1) - (5)].item_val)),
                             (yyvsp[(5) - (5)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 118:

/* Line 1455 of yacc.c  */
#line 854 "sql.y"
  {
    // printf("scalar_expression_commalist ,col_value\n");
    (yyval.item_val) = SQLpCodeGenArrayJoin(
        SQLpCodeGenArrayInt((yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_LIST_SEPARATOR), (yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 119:

/* Line 1455 of yacc.c  */
#line 859 "sql.y"
  {
    // printf("scalar_expression_commalist col_value\n");
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 120:

/* Line 1455 of yacc.c  */
#line 867 "sql.y"
  {
    // printf("NO_LOCK\n");
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_NOLOCK);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 121:

/* Line 1455 of yacc.c  */
#line 872 "sql.y"
  {
    // printf("LOCK\n");
    (yyval.item_val) = SQLpCodeGenInt(SQL_PCODE_LOCK);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 122:

/* Line 1455 of yacc.c  */
#line 880 "sql.y"
  {
    // printf("col_constructor - col value\n");
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    ;
  }
  break;

  case 123:

/* Line 1455 of yacc.c  */
#line 884 "sql.y"
  {
    // printf( "ISNULL( , ) function\n" );
    (yyval.item_val) =
        SQLpCodeGenArrayInt(SQLpCodeGenArrayJoin(SQLpCodeGenArrayInt(SQLpCodeGenIntArray(SQL_PCODE_FUNC_ISNULL,
                                                                                         (yyvsp[(2) - (5)].item_val)),
                                                                     SQL_PCODE_COLUMN_LIST_SEPARATOR),
                                                 (yyvsp[(4) - (5)].item_val)),
                            SQL_PCODE_STOP_EXPR);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 124:

/* Line 1455 of yacc.c  */
#line 892 "sql.y"
  {
    // printf("col_constructor - col value\n");
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 125:

/* Line 1455 of yacc.c  */
#line 897 "sql.y"
  {
    // printf("col_constructor - col name\n");
    (yyval.item_val) = (yyvsp[(1) - (1)].item_val);
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 126:

/* Line 1455 of yacc.c  */
#line 905 "sql.y"
  {
    // printf("INTEGERVAL col value %i\n", $1);
    (yyval.item_val) =
        SQLpCodeGenIntItem(SQL_PCODE_COLUMN_BY_VALUE, hb_itemPutNI(hb_itemNew(NULL), (yyvsp[(1) - (1)].int_val)));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 127:

/* Line 1455 of yacc.c  */
#line 910 "sql.y"
  {
    // printf("REALVAL col value %f\n", $1);
    (yyval.item_val) =
        SQLpCodeGenIntItem(SQL_PCODE_COLUMN_BY_VALUE, hb_itemPutND(hb_itemNew(NULL), (yyvsp[(1) - (1)].real_val)));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 128:

/* Line 1455 of yacc.c  */
#line 915 "sql.y"
  {
    // printf("STRING col value: %s\n", hb_itemGetCPtr((PHB_ITEM)$1) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_BY_VALUE, (yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 129:

/* Line 1455 of yacc.c  */
#line 920 "sql.y"
  {
    // printf("NULLVAL col value\n");
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_BY_VALUE, hb_itemNew(NULL));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 130:

/* Line 1455 of yacc.c  */
#line 925 "sql.y"
  {
    // printf("DATEVAL col value\n");
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_BY_VALUE, (yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 131:

/* Line 1455 of yacc.c  */
#line 930 "sql.y"
  {
    // printf("PARAM col value %i\n", $1);
    (yyval.item_val) =
        SQLpCodeGenIntItem(SQL_PCODE_COLUMN_PARAM, hb_itemPutNI(hb_itemNew(NULL), (yyvsp[(1) - (1)].param)));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 132:

/* Line 1455 of yacc.c  */
#line 935 "sql.y"
  {
    // printf("PARAM_NOT_NULL col value %i\n", $1);
    (yyval.item_val) =
        SQLpCodeGenIntItem(SQL_PCODE_COLUMN_PARAM_NOTNULL, hb_itemPutNI(hb_itemNew(NULL), (yyvsp[(1) - (1)].param)));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 133:

/* Line 1455 of yacc.c  */
#line 940 "sql.y"
  {
    // printf("BINDVAR col value : %s\n", hb_itemGetCPtr((PHB_ITEM)$2) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_BINDVAR, (yyvsp[(2) - (2)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 134:

/* Line 1455 of yacc.c  */
#line 948 "sql.y"
  {
    // printf( "ALIASED_QUOTED_COL_NAME : %s - %s\n", hb_itemGetCPtr((PHB_ITEM)$1), hb_itemGetCPtr((PHB_ITEM)$3) );
    (yyval.item_val) = SQLpCodeGenIntItem2(SQL_PCODE_COLUMN_ALIAS, (PHB_ITEM)(yyvsp[(1) - (3)].item_val),
                                           SQL_PCODE_COLUMN_NAME, (PHB_ITEM)(yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 135:

/* Line 1455 of yacc.c  */
#line 953 "sql.y"
  {
    // printf( "ALIASED_COL_NAME : %s - %s\n", hb_itemGetCPtr((PHB_ITEM)$1), hb_itemGetCPtr((PHB_ITEM)$3) );
    (yyval.item_val) = SQLpCodeGenIntItem2(SQL_PCODE_COLUMN_ALIAS, (PHB_ITEM)(yyvsp[(1) - (3)].item_val),
                                           SQL_PCODE_COLUMN_NAME, (PHB_ITEM)(yyvsp[(3) - (3)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 136:

/* Line 1455 of yacc.c  */
#line 958 "sql.y"
  {
    // printf( "QUOTED_COL_NAME : %s\n", hb_itemGetCPtr((PHB_ITEM)$1) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_NAME, (PHB_ITEM)(yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 137:

/* Line 1455 of yacc.c  */
#line 963 "sql.y"
  {
    // printf( "COL_NAME : %s\n", hb_itemGetCPtr((PHB_ITEM)$1) );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_NAME, (PHB_ITEM)(yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 138:

/* Line 1455 of yacc.c  */
#line 968 "sql.y"
  {
    // printf("ALIASED PARAM col value: %s . %i\n", hb_itemGetCPtr((PHB_ITEM)$1),$3 );
    (yyval.item_val) =
        SQLpCodeGenIntItem2(SQL_PCODE_COLUMN_ALIAS, (PHB_ITEM)(yyvsp[(1) - (3)].item_val), SQL_PCODE_COLUMN_NAME_PARAM,
                            hb_itemPutNI(hb_itemNew(NULL), (yyvsp[(3) - (3)].param)));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 139:

/* Line 1455 of yacc.c  */
#line 973 "sql.y"
  {
    // printf("BINDVAR col value : %s\n", hb_itemGetCPtr((PHB_ITEM)$3) );
    (yyval.item_val) = SQLpCodeGenIntItem2(SQL_PCODE_COLUMN_ALIAS, (PHB_ITEM)(yyvsp[(1) - (4)].item_val),
                                           SQL_PCODE_COLUMN_NAME_BINDVAR, (PHB_ITEM)(yyvsp[(4) - (4)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 140:

/* Line 1455 of yacc.c  */
#line 981 "sql.y"
  {
    // printf( "col_list_name" );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_NAME, (PHB_ITEM)(yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

  case 141:

/* Line 1455 of yacc.c  */
#line 986 "sql.y"
  {
    // printf( "col_list_name QUOTED IDENT" );
    (yyval.item_val) = SQLpCodeGenIntItem(SQL_PCODE_COLUMN_NAME, (PHB_ITEM)(yyvsp[(1) - (1)].item_val));
    // ((sql_stmt *) stmt)->pTemp = (PHB_ITEM) $$;
    ;
  }
  break;

/* Line 1455 of yacc.c  */
#line 3286 ".hbmk/win/mingw/sqly.c"
  default:
    break;
  }
  YY_SYMBOL_PRINT("-> $$ =", yyr1[yyn], &yyval, &yyloc);

  YYPOPSTACK(yylen);
  yylen = 0;
  YY_STACK_PRINT(yyss, yyssp);

  *++yyvsp = yyval;

  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;

/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
  {
    ++yynerrs;
#if !YYERROR_VERBOSE
    yyerror(stmt, YY_("syntax error"));
#else
    {
      YYSIZE_T yysize = yysyntax_error(0, yystate, yychar);
      if (yymsg_alloc < yysize && yymsg_alloc < YYSTACK_ALLOC_MAXIMUM)
      {
        YYSIZE_T yyalloc = 2 * yysize;
        if (!(yysize <= yyalloc && yyalloc <= YYSTACK_ALLOC_MAXIMUM))
          yyalloc = YYSTACK_ALLOC_MAXIMUM;
        if (yymsg != yymsgbuf)
          YYSTACK_FREE(yymsg);
        yymsg = (char *)YYSTACK_ALLOC(yyalloc);
        if (yymsg)
          yymsg_alloc = yyalloc;
        else
        {
          yymsg = yymsgbuf;
          yymsg_alloc = sizeof yymsgbuf;
        }
      }

      if (0 < yysize && yysize <= yymsg_alloc)
      {
        (void)yysyntax_error(yymsg, yystate, yychar);
        yyerror(stmt, yymsg);
      }
      else
      {
        yyerror(stmt, YY_("syntax error"));
        if (yysize != 0)
          goto yyexhaustedlab;
      }
    }
#endif
  }

  if (yyerrstatus == 3)
  {
    /* If just tried and failed to reuse lookahead token after an
   error, discard it.  */

    if (yychar <= YYEOF)
    {
      /* Return failure if at end of input.  */
      if (yychar == YYEOF)
        YYABORT;
    }
    else
    {
      yydestruct("Error: discarding", yytoken, &yylval, stmt);
      yychar = YYEMPTY;
    }
  }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;

/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (/*CONSTCOND*/ 0)
    goto yyerrorlab;

  /* Do not reclaim the symbols of the rule which action triggered
     this YYERROR.  */
  YYPOPSTACK(yylen);
  yylen = 0;
  YY_STACK_PRINT(yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;

/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3; /* Each real token shifted decrements this.  */

  for (;;)
  {
    yyn = yypact[yystate];
    if (yyn != YYPACT_NINF)
    {
      yyn += YYTERROR;
      if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
      {
        yyn = yytable[yyn];
        if (0 < yyn)
          break;
      }
    }

    /* Pop the current state because it cannot handle the error token.  */
    if (yyssp == yyss)
      YYABORT;

    yydestruct("Error: popping", yystos[yystate], yyvsp, stmt);
    YYPOPSTACK(1);
    yystate = *yyssp;
    YY_STACK_PRINT(yyss, yyssp);
  }

  *++yyvsp = yylval;

  /* Shift the error token.  */
  YY_SYMBOL_PRINT("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;

/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#if !defined(yyoverflow) || YYERROR_VERBOSE
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror(stmt, YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEMPTY)
    yydestruct("Cleanup: discarding lookahead", yytoken, &yylval, stmt);
  /* Do not reclaim the symbols of the rule which action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK(yylen);
  YY_STACK_PRINT(yyss, yyssp);
  while (yyssp != yyss)
  {
    yydestruct("Cleanup: popping", yystos[*yyssp], yyvsp, stmt);
    YYPOPSTACK(1);
  }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE(yyss);
#endif
#if YYERROR_VERBOSE
  if (yymsg != yymsgbuf)
    YYSTACK_FREE(yymsg);
#endif
  /* Make sure YYID is used.  */
  return YYID(yyresult);
}

/* Line 1675 of yacc.c  */
#line 993 "sql.y"
