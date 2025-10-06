# SQLRDD++

SQLRDD for Harbour++ and Harbour

## Supported database systems

| SGBD               | Status         |
| ------------------ | -------------- |
| SYSTEMID_ACCESS    |                |
| SYSTEMID_ADABAS    |                |
| SYSTEMID_AZURE     |                |
| SYSTEMID_CACHE     |                |
| SYSTEMID_FIREBR    |                |
| SYSTEMID_FIREBR3   |                |
| SYSTEMID_FIREBR4   |                |
| SYSTEMID_FIREBR5   |                |
| SYSTEMID_IBMDB2    |                |
| SYSTEMID_INFORM    |                |
| SYSTEMID_INGRES    |                |
| SYSTEMID_MARIADB   |                |
| SYSTEMID_MSSQL6    |                |
| SYSTEMID_MSSQL7    |                |
| SYSTEMID_MYSQL     |                |
| SYSTEMID_ORACLE    |                |
| SYSTEMID_OTERRO    |                |
| SYSTEMID_PERVASIVE |                |
| SYSTEMID_POSTGR    |                |
| SYSTEMID_SQLANY    |                |
| SYSTEMID_SQLBAS    |                |
| SYSTEMID_SYBASE    |                |

## C/C++ Compilers Compatibility

| Project   | C/C++ compiler   | Status                  | Extra parameters    |
| --------- | ---------------- | ----------------------- | ------------------- |
| Harbour   | MinGW32          | Compiling with warnings | ...                 |
| Harbour   | MinGW64          | Compiling with warnings | ...                 |
| Harbour   | MSVC 2019 32-bit | Compiling with warnings | ...                 |
| Harbour   | MSVC 2019 64-bit | Compiling with warnings | ...                 |
| Harbour   | MSVC 2022 32-bit | Compiling with warnings | ...                 |
| Harbour   | MSVC 2022 64-bit | Compiling with warnings | ...                 |
| Harbour   | MSVC 2026 32-bit | Compiling with warnings | ...                 |
| Harbour   | MSVC 2026 64-bit | Compiling with warnings | ...                 |
| Harbour   | Clang32          | ...                     | ...                 |
| Harbour   | Clang64          | ...                     | ...                 |
| Harbour   | BCC 5.8.2        | Compiling with warnings | -aflag=/P64         |
| Harbour++ | MinGW32          | ...                     | ...                 |
| Harbour++ | MinGW64          | ...                     | ...                 |
| Harbour++ | MSVC32           | ...                     | ...                 |
| Harbour++ | MSVC64           | ...                     | ...                 |
| Harbour++ | Clang32          | ...                     | ...                 |
| Harbour++ | Clang64          | ...                     | ...                 |
| Harbour++ | BCC 7.3 32-bit   | ...                     | ...                 |
| Harbour++ | BCC 7.3 64-bit   | ...                     | ...                 |

## Building

### Windows - How to compile
```Batch
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

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

### Notes

SQLRDD++ do not require xhb.hbc (contrib/xhb) to compile the library.

After compiled, the library is automatically installed in the addons folder.

To disable this behaviour, edit the file sqlrddpp.hbp and disable the line below:

```
$hb_pkg_install.hbm
```

## Using

### Compiling with SQLRDD and MySQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibmysql
```

### Compiling with SQLRDD and PostgreSQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibpq
```

### Compiling with SQLRDD and Firebird
```Batch
hbmk2 <filename> sqlrddpp.hbc -lfbclient
```
### Notes

SQLRDD++ do not require xhb.hbc (contrib/xhb) to use the library.

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

Harbour++  
https://github.com/marcosgambeta/harbourpp-v1  

SQLRDD++ v2  
https://github.com/marcosgambeta/sqlrddpp-v2  
C++ version for Harbour++
