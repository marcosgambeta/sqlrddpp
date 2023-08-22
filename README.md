# sqlrddpp
SQLRDD for Harbour and Harbour++

## Notes

### Windows - How to compile
```Batch
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

### Windows - How to compile (old way)
```Batch
rem add bison.exe to path
set PATH=C:\GnuWin32\bin;%PATH%
cd sqlrddpp
cd source
hbmk2 sqlrdd.hbp
```

### Ubuntu - How to get and compile
```Batch
sudo apt install unixodbc-dev
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
hbmk2 sqlrddpp.hbp
```

### Ubuntu - How to get and compile (old way)
```Batch
sudo apt install bison
sudo apt install unixodbc-dev
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrddpp
cd source
hbmk2 sqlrdd.hbp
```

## Links

SQLRDD for xHarbour  
https://github.com/ronpinkas/xharbour  
https://github.com/ronpinkas/xharbour/tree/main/xHarbourBuilder/xHarbour-SQLRDD  

Bison  
https://gnuwin32.sourceforge.net/packages/bison.htm  
