# SQLRDD++

SQLRDD para Harbour, xHarbour, Harbour 3.4 e Harbour++, 

Este projeto é um 'fork' (projeto derivado) da SQLRDD do xHarbour. O projeto original pode ser encontrado aqui:  
https://github.com/xHarbour-org/xharbour/tree/main/xHarbourBuilder/xHarbour-SQLRDD  

## SGBD suportados

| SGBD                   | Versão  | Status                |
| ---------------------- | ------- | --------------------- |
| SQLRDD_RDBMS_ACCESS    |         |                       |
| SQLRDD_RDBMS_ADABAS    |         |                       |
| SQLRDD_RDBMS_AZURE     |         |                       |
| SQLRDD_RDBMS_CACHE     |         |                       |
| CUBRID                 | 11.4    | Trabalho Em Progresso |
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

Note: CUBRID é um trabalho em progresso (não utilizável ainda).

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
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |
| xHarbour    | MinGW            | 32-bit        | Compilando com avisos   | ...                 |
| xHarbour    | MinGW            | 64-bit        | Compilando com avisos   | ...                 |
| xHarbour    | MSVC 2022        | 32-bit        | Compilando com avisos   | ...                 |
| xHarbour    | MSVC 2022        | 64-bit        | Compilando com avisos   | ...                 |
| xHarbour    | Clang            | 32-bit        | Compilando com avisos   | ...                 |
| xHarbour    | Clang            | 64-bit        | Compilando com avisos   | ...                 |
| xHarbour    | BCC 7.3          | 32-bit        | Compilando com avisos   | ...                 |
| xHarbour    | BCC 7.3          | 64-bit        | ...                     | ...                 |
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |
| Harbour 3.4 | MinGW            | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | MinGW            | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | MSVC             | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | MSVC             | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | Clang            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour 3.4 | Clang            | 64-bit        | ...                     | ...                 |
| Harbour 3.4 | BCC 7.3          | 32-bit        | ...                     | ...                 |
| Harbour 3.4 | BCC 7.3          | 64-bit        | ...                     | ...                 |
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |
| Harbour++   | MinGW            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour++   | MinGW            | 64-bit        | Compilando com avisos   | ...                 |
| Harbour++   | MSVC             | 32-bit        | ...                     | ...                 |
| Harbour++   | MSVC             | 64-bit        | ...                     | ...                 |
| Harbour++   | Clang            | 32-bit        | Compilando com avisos   | ...                 |
| Harbour++   | Clang            | 64-bit        | Compilando com avisos   | ...                 |
| Harbour++   | BCC 7.3          | 32-bit        | ...                     | ...                 |
| Harbour++   | BCC 7.3          | 64-bit        | ...                     | ...                 |
| ----------- | ---------------- | ------------- | ----------------------- | ------------------- |

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

### xHarbour

Para compilar para xHarbour, use o script xsqlrddpp.hbp. Veja o arquivo para mais informações.

```Batch
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 xsqlrddpp.hbp -xhb
```

Alternativamente, você pode usar os Makefiles. Consulte os arquivos para obter mais informações.

### Notas

SQLRDD++ não requer a utilização de xhb.hbc (contrib/xhb) para compilar a biblioteca.

Após compilada, a biblioteca é automaticamente instalada na pasta addons (exceto quando estiver usando xHarbour).

Para desativar este comportamento, edite o arquivo sqlrddpp.hbp e desative a linha abaixo:

```
$hb_pkg_install.hbm
```

## Usando o projeto

### Compilando com SQLRDD++ e MySQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibmysql
```

### Compilando com SQLRDD++ e MariaDB
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibmariadb
```

### Compilando com SQLRDD++ e PostgreSQL
```Batch
hbmk2 <filename> sqlrddpp.hbc -llibpq
```

### Compilando com SQLRDD++ e Firebird
```Batch
hbmk2 <filename> sqlrddpp.hbc -lfbclient
```

### Notas

SQLRDD++ não requer a utilização de xhb.hbc (contrib/xhb) para utilizar a biblioteca.

Quando estiver usando xHarbour, adicione o parâmetro -xhb:

```Batch
hbmk2 <filename> sqlrddpp.hbc -xhb ...
```

## Bibliotecas dedicadas

Além da biblioteca principal, existem bibliotecas dedicadas para Firebird, MySQL/MariaDB,
Oracle e PostgreSQL. Siga estas etapas para compilar essas bibliotecas:

1. Para compilar todas as bibliotecas (principal e dedicadas):

```Batch
hbmk2 sqlrddpp-alllibs.hbp
```

2. Para compilar a biblioteca para Firebird:

```Batch
hbmk2 sqlrddpp-firebird.hbp
```

3. Para compilar a biblioteca para MySQL/MariaDB:

```Batch
hbmk2 sqlrddpp-mysql.hbp
```

4. Para compilar a biblioteca para Oracle:

```Batch
hbmk2 sqlrddpp-oracle.hbp
```

5. Para compilar a biblioteca para PostgreSQL:

```Batch
hbmk2 sqlrddpp-postgresql.hbp
```

6. Use o arquivo .hbc equivalente para compilar seus programas:

```Batch
hbmk2 <filename> sqlrddpp-firebird.hbc ...
hbmk2 <filename> sqlrddpp-mysql.hbc ...
hbmk2 <filename> sqlrddpp-oracle.hbc ...
hbmk2 <filename> sqlrddpp-postgresql.hbc ...
```

As bibliotecas dedicadas apresentam o mesmo comportamento da biblioteca principal, mas
o código é mais enxuto e não precisa verificar constantemente qual SGBD está sendo utilizado.

## Problemas na utilização deste projeto

Caso tenha problemas na utilização deste projeto, informe na seção 'Issues':

https://github.com/marcosgambeta/sqlrddpp/issues  

Se possível, tente criar um exemplo autocontido que reproduza o problema.

Outros tópicos podem ser discutidos na seção 'Discussions':

https://github.com/marcosgambeta/sqlrddpp/discussions

## SQLRDD++ v1 vs SQLRDD++ v2

A versão 1 do SQLRDD++ usa a linguagem C e mantém compatibilidade com compiladores C antigos,
como o BCC 5.8.2.

A versão 2 usa a linguagem C++ (C++ moderno) e requer um compilador C++ que suporte o padrão
C++11 ou superior.

Portanto, se você estiver usando um compilador moderno, poderá usar a versão 2 do SQLRDD++
em vez da versão 1 (se desejar, é claro).

Veja o link na seção abaixo.

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

CUBRID  
https://www.cubrid.org  

Harbour++  
https://github.com/marcosgambeta/harbourpp-v1  

SQLRDD++ v2  
https://github.com/marcosgambeta/sqlrddpp-v2  
Versão em C++ para Harbour e Harbour++

## Donativos

Caso deseje apoiar o desenvolvimento deste projeto através de donativos, basta utilizar a chave PIX abaixo:

![Chave PIX](chavepix.png)

A frequência e o valor dos donativos ficam à critério de cada desenvolvedor. Este apoio permitirá
investir mais tempo no desenvolvimento e manutenção deste projeto.
