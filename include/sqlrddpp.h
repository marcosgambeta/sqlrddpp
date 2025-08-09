// SQLRDD++ Project
// Copyright (c) 2025 Marcos Antonio Gambeta <marcosgambeta@outlook.com>

#ifndef SQLRDDPP_H
#define SQLRDDPP_H

// Define SR_NULLPTR:
// If the compiler is a C++ compiler and the standard is C++11 or upper, define SR_NULLPTR as nullptr.
// If the compiler is a C compiler and the standard is C23 or upper, define SR_NULLPTR as nullptr.
// Otherwise, define as NULL.
#if defined(__cplusplus)
#if __cplusplus >= 201103L
#define SR_NULLPTR nullptr
#else
#define SR_NULLPTR NULL
#endif
#else
#ifdef __STDC_VERSION__
#if __STDC_VERSION__ >= 202311L
#define SR_NULLPTR nullptr
#else
#define SR_NULLPTR NULL
#endif
#else
#define SR_NULLPTR NULL
#endif
#endif

#endif // SQLRDDPP_H
