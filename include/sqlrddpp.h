// SQLRDD++ Project
// Copyright (c) 2025 Marcos Antonio Gambeta <marcosgambeta@outlook.com>

#ifndef SQLRDDPP_H
#define SQLRDDPP_H

// Define SR_NULLPTR:
// If the compiler is a C++ compiler and the standard is C++11 or upper, define SR_NULLPTR as nullptr.
// If the compiler is a C compiler and the standard is C23 or upper, define SR_NULLPTR as nullptr.
// Otherwise, define SR_NULLPTR as '((void *)0)'.
#if defined(__cplusplus)
#if __cplusplus >= 201103L
#define SR_NULLPTR nullptr
#else
#define SR_NULLPTR ((void *)0)
#endif
#else
#ifdef __STDC_VERSION__
#if __STDC_VERSION__ >= 202311L
#define SR_NULLPTR nullptr
#else
#define SR_NULLPTR ((void *)0)
#endif
#else
#define SR_NULLPTR ((void *)0)
#endif
#endif

// Supported Database Engines (RDBMS)

// NOTE: needs to be kept in sync with the sqlrddpp.ch file
#define SYSTEMID_UNKNOW                0
#define SYSTEMID_ORACLE                1
#define SYSTEMID_MSSQL6                2
#define SYSTEMID_MSSQL7                3
#define SYSTEMID_SQLANY                4
#define SYSTEMID_SYBASE                5
#define SYSTEMID_ACCESS                6
#define SYSTEMID_INGRES                7
#define SYSTEMID_SQLBAS                8
#define SYSTEMID_ADABAS                9
#define SYSTEMID_INFORM               10
#define SYSTEMID_IBMDB2               11
#define SYSTEMID_MYSQL                12
#define SYSTEMID_POSTGR               13
#define SYSTEMID_FIREBR               14
#define SYSTEMID_CACHE                15
#define SYSTEMID_OTERRO               16
#define SYSTEMID_PERVASIVE            17
#define SYSTEMID_AZURE                18
#define SYSTEMID_MARIADB              19
#define SYSTEMID_FIREBR3              20
#define SYSTEMID_FIREBR4              21
#define SYSTEMID_FIREBR5              22

#endif // SQLRDDPP_H
