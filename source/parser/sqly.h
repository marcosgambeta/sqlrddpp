
/* A Bison parser, made by GNU Bison 2.4.1.  */

/* Skeleton interface for Bison's Yacc-like parsers in C

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

/* Line 1676 of yacc.c  */
#line 40 "sql.y"

  int int_val;
  double real_val;
  PHB_ITEM item_val;
  int param;
  int iOperator;

/* Line 1676 of yacc.c  */
#line 121 ".hbmk/win/mingw/sqly.h"
} YYSTYPE;
#define YYSTYPE_IS_TRIVIAL 1
#define yystype YYSTYPE /* obsolescent; will be withdrawn */
#define YYSTYPE_IS_DECLARED 1
#endif
