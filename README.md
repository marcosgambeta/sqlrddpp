# SQLRDD++

SQLRDD for Harbour, xHarbour, Harbour 3.4 and Harbour++.

This project is a fork of the xHarbour SQLRDD. The original project can be found here:  
https://github.com/xHarbour-org/xharbour/tree/main/xHarbourBuilder/xHarbour-SQLRDD  

## Supported database systems

| RDBMS                  | Version | Status                |
| -------------------    | ------- | --------------------- |
| SQLRDD_RDBMS_ACCESS    |         |                       |
| SQLRDD_RDBMS_ADABAS    |         |                       |
| SQLRDD_RDBMS_AZURE     |         |                       |
| SQLRDD_RDBMS_CACHE     |         |                       | 
| CUBRID                 | 11.4    | Work In Progress      |
| SQLRDD_RDBMS_FIREBR    |         |                       |
| SQLRDD_RDBMS_FIREBR3   |         |                       | 
| SQLRDD_RDBMS_FIREBR4   |         |                       |
| SQLRDD_RDBMS_FIREBR5   |         |                       |
| SQLRDD_RDBMS_IBMDB2    |         |                       |
| SQLRDD_RDBMS_INFORM    |         |                       |
| SQLRDD_RDBMS_INGRES    |         |                       |
| SQLRDD_RDBMS_MARIADB   |         |                       |
| SQLRDD_RDBMS_MSSQL6    |         |                       |
| SQLRDD_RDBMS_MSSQL7    |         |                       |
| SQLRDD_RDBMS_MYSQL     |         |                       |
| SQLRDD_RDBMS_ORACLE    |         |                       |
| SQLRDD_RDBMS_OTERRO    |         |                       |
| SQLRDD_RDBMS_PERVASIVE |         |                       |
| SQLRDD_RDBMS_POSTGR    |         |                       |
| SQLRDD_RDBMS_SQLANY    |         |                       |
| SQLRDD_RDBMS_SQLBAS    |         |                       |
| SQLRDD_RDBMS_SYBASE    |         |                       |

Note: CUBRID is a work in progress (not usable yet).

## C/C++ Compilers Compatibility

| Project     | C/C++ compiler   | 32-bit/64-bit | Status                  | Extra parameters    |
| ---------   | ---------------- | ------------- | ----------------------- | ------------------- |
| Harbour     | MinGW            | 32-bit        | Compiling with warnings | ...                 |
| Harbour     | MinGW            | 64-bit        | Compiling with warnings | ...                 |
| Harbour     | MSVC 2019        | 32-bit        | Compiling with warnings | ...                 |
| Harbour     | MSVC 2019        | 64-bit        | Compiling with warnings | ...                 |
| Harbour     | MSVC 2022        | 32-bit        | Compiling with warnings | ...                 |
| Harbour     | MSVC 2022        | 64-bit        | Compiling with warnings | ...                 |
| Harbour     | MSVC 2026        | 32-bit        | Compiling with warnings | ...                 |
| Harbour     | MSVC 2026        | 64-bit        | Compiling with warnings | ...                 |
| Harbour     | Clang            | 32-bit        | Compiling with warnings | ...                 |
| Harbour     | Clang            | 64-bit        | Compiling with warnings | ...                 |
| Harbour     | BCC 5.8.2        | 32-bit        | Compiling with warnings | -aflag=/P64         |
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |
| xHarbour    | MinGW            | 32-bit        | Compiling with warnings | ...                 |
| xHarbour    | MinGW            | 64-bit        | Compiling with warnings | ...                 |
| xHarbour    | MSVC 2022        | 32-bit        | Compiling with warnings | ...                 |
| xHarbour    | MSVC 2022        | 64-bit        | Compiling with warnings | ...                 |
| xHarbour    | Clang            | 32-bit        | Compiling with warnings | ...                 |
| xHarbour    | Clang            | 64-bit        | Compiling with warnings | ...                 |
| xHarbour    | BCC 7.3          | 32-bit        | Compiling with warnings | ...                 |
| xHarbour    | BCC 7.3          | 64-bit        | ...                     | ...                 |
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |
| Harbour 3.4 | MinGW            | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | MinGW            | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | MSVC             | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | MSVC             | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | Clang            | 32-bit        | Compiling with warnings | ...                 |
| Harbour 3.4 | Clang            | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | BCC 7.3          | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | BCC 7.3          | 64-bit        | ...                     | ...                 |
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |
| Harbour++   | MinGW            | 32-bit        | Compiling with warnings | ...                 |
| Harbour++   | MinGW            | 64-bit        | Compiling with warnings | ...                 |
| Harbour++   | MSVC             | 32-bit        | ...                     | ...                 |
| Harbour++   | MSVC             | 64-bit        | ...                     | ...                 |
| Harbour++   | Clang            | 32-bit        | Compiling with warnings | ...                 |
| Harbour++   | Clang            | 64-bit        | Compiling with warnings | ...                 |
| Harbour++   | BCC 7.3          | 32-bit        | ...                     | ...                 |
| Harbour++   | BCC 7.3          | 64-bit        | ...                     | ...                 |
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |

## Building

### Windows - How to compile
```Batch
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

See the extra parameters in the table above.

Example:

To compile with BCC 5.8.2:

```Batch
hbmk2 sqlrddpp.hbp -aflag=/P64
```

### Ubuntu - How to get and compile
```Batch
sudo apt install unixodbc-dev
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

### OpenSuse - How to get and compile
```Batch
sudo zypper install unixODBC-devel
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

### xHarbour

To build for xHarbour, use the script xsqlrddpp.hbp. See the file for more info.

```Batch
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 xsqlrddpp.hbp -xhb
```

Alternatively,  you can use the Makefiles. See the files for more info.

### Notes

SQLRDD++ do not require xhb.hbc (contrib/xhb) to compile the library.

After compiled, the library is automatically installed in the addons folder (except when using xHarbour).

To disable this behaviour, edit the file sqlrddpp.hbp and disable the line below:

```
$hb_pkg_install.hbm
```

## Using

### Compiling with SQLRDD++ and MySQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibmysql
```

### Compiling with SQLRDD++ and MariaDB
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibmariadb
```

### Compiling with SQLRDD++ and PostgreSQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibpq
```

### Compiling with SQLRDD++ and Firebird
```Batch
hbmk2 <filename> sqlrddpp.hbc -lfbclient
```
### Notes

SQLRDD++ do not require xhb.hbc (contrib/xhb) to use the library.

When using xHarbour, add the parameter -xhb:

```Batch
hbmk2 <filename> sqlrddpp.hbc -xhb ...
```

## Problems using this project

If you have any problems using this project, please report them in the 'Issues' section:

https://github.com/marcosgambeta/sqlrddpp/issues  

If possible, try to create a self-contained example that reproduce the problem.

Others topics can be discussed in the 'Discussions' section:

https://github.com/marcosgambeta/sqlrddpp/discussions

## SQLRDD++ v1 vs SQLRDD++ v2

The version 1 of SQLRDD++ use the C language and mantain compatibility with old C compilers
like BCC 5.8.2.

The version 2 use the C++ language (Modern C++) and require a C++ compiler that support the
standard C++11 or upper.

So, if you are using a modern compiler, you can use the version 2 of the SQLRDD++ instead
of the version 1 (if you wish, of course).

See the link in the section below.

## Links

SQLRDD for xHarbour and Harbour  
https://github.com/xHarbour-org/xharbour  
https://github.com/xHarbour-org/xharbour/tree/main/xHarbourBuilder/xHarbour-SQLRDD  

Bison  
https://gnuwin32.sourceforge.net/packages/bison.htm  

MySQL  
https://www.mysql.com  

MariaDB  
https://mariadb.org  

PostgreSQL  
https://www.postgresql.org  

Firebird  
https://firebirdsql.org  

CUBRID  
https://www.cubrid.org  

Harbour++  
https://github.com/marcosgambeta/harbourpp-v1  

SQLRDD++ v2  
https://github.com/marcosgambeta/sqlrddpp-v2  
C++ version for Harbour and Harbour++
