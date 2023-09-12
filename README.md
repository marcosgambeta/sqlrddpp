# SQLRDD++

SQLRDD for Harbour++ and Harbour

## Notes

### Windows - How to compile
```Batch
cd sqlrddpp
hbmk2 sqlrddpp.hbp
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

## Links

SQLRDD for xHarbour  
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
