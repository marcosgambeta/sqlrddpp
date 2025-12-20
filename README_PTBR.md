# SQLRDD++

SQLRDD para Harbour e Harbour++

## SGBD suportados

| SGBD                   | Versão  | Status         |
| ---------------------- | ------- | -------------- |
| SQLRDD_RDBMS_ACCESS    |         |                |
| SQLRDD_RDBMS_ADABAS    |         |                |
| SQLRDD_RDBMS_AZURE     |         |                |
| SQLRDD_RDBMS_CACHE     |         |                |
| SQLRDD_RDBMS_FIREBR    |         |                |
| SQLRDD_RDBMS_FIREBR3   |         |                |
| SQLRDD_RDBMS_FIREBR4   |         |                |
| SQLRDD_RDBMS_FIREBR5   |         |                |
| SQLRDD_RDBMS_IBMDB2    |         |                |
| SQLRDD_RDBMS_INFORM    |         |                |
| SQLRDD_RDBMS_INGRES    |         |                |
| SQLRDD_RDBMS_MARIADB   |         |                |
| SQLRDD_RDBMS_MSSQL6    |         |                |
| SQLRDD_RDBMS_MSSQL7    |         |                |
| SQLRDD_RDBMS_MYSQL     |         |                |
| SQLRDD_RDBMS_ORACLE    |         |                |
| SQLRDD_RDBMS_OTERRO    |         |                |
| SQLRDD_RDBMS_PERVASIVE |         |                |
| SQLRDD_RDBMS_POSTGR    |         |                |
| SQLRDD_RDBMS_SQLANY    |         |                |
| SQLRDD_RDBMS_SQLBAS    |         |                |
| SQLRDD_RDBMS_SYBASE    |         |                |

## Compiladores C++ suportados

| Projeto     | Compilador C/C++ | 32-bit/64-bit | Status                  | Parâmetros extras   |
| ---------   | ---------------- | ------------- | ----------------------- | ------------------- |
| Harbour     | MinGW            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour     | MinGW            | 64-bit        | Compilando com avisos   | ...                 |
| Harbour     | MSVC 2019        | 32-bit        | Compilando com avisos   | ...                 |
| Harbour     | MSVC 2019        | 64-bit        | Compilando com avisos   | ...                 |
| Harbour     | MSVC 2022        | 32-bit        | Compilando com avisos   | ...                 |
| Harbour     | MSVC 2022        | 64-bit        | Compilando com avisos   | ...                 |
| Harbour     | MSVC 2026        | 32-bit        | Compilando com avisos   | ...                 |
| Harbour     | MSVC 2026        | 64-bit        | Compilando com avisos   | ...                 |
| Harbour     | Clang            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour     | Clang            | 64-bit        | Compilando com avisos   | ...                 |
| Harbour     | BCC 5.8.2        | 32-bit        | Compilando com avisos   | -aflag=/P64         |
| Harbour 3.4 | MinGW            | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | MinGW            | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | MSVC             | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | MSVC             | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | Clang            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour 3.4 | Clang            | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | BCC 7.3          | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | BCC 7.3          | 64-bit        | ...                     | ...                 |
| Harbour++   | MinGW            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour++   | MinGW            | 64-bit        | Compilando com avisos   | ...                 |
| Harbour++   | MSVC             | 32-bit        | ...                     | ...                 |
| Harbour++   | MSVC             | 64-bit        | ...                     | ...                 |
| Harbour++   | Clang            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour++   | Clang            | 64-bit        | Compilando com avisos   | ...                 |
| Harbour++   | BCC 7.3          | 32-bit        | ...                     | ...                 |
| Harbour++   | BCC 7.3          | 64-bit        | ...                     | ...                 |

## Compilando o projeto

### Windows - Como obter o código-fonte e compilar  
```Batch
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

Veja os parâmetros extras na tabela acima.

Exemplo:

Para compilar com BCC 5.8.2:

```Batch
hbmk2 sqlrddpp.hbp -aflag=/P64
```

### Ubuntu - Como obter o código-fonte e compilar  
```Batch
sudo apt install unixodbc-dev
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

### OpenSuse - Como obter o código-fonte e compilar  
```Batch
sudo zypper install unixODBC-devel
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

### Notas

SQLRDD++ não requer a utilização de xhb.hbc (contrib/xhb) para compilar a biblioteca.

Após compilada, a biblioteca é automaticamente instalada na pasta addons.

Para desativar este comportamento, edite o arquivo sqlrddpp.hbp e desative a linha abaixo:

```
$hb_pkg_install.hbm
```

## Usando o projeto

### Compilando com SQLRDD e MySQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibmysql
```

### Compilando com SQLRDD e PostgreSQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibpq
```

### Compilando com SQLRDD e Firebird
```Batch
hbmk2 <filename> sqlrddpp.hbc -lfbclient
```

### Notas

SQLRDD++ não requer a utilização de xhb.hbc (contrib/xhb) para utilizar a biblioteca.

## Problemas na utilização

Caso tenha problemas na utilização deste projeto, informe na seção 'Issues':

https://github.com/marcosgambeta/sqlrddpp/issues  

## Links

SQLRDD para xHarbour e Harbour  
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
Versão em C++ para Harbour++
