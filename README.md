# sqlrddpp
SQLRDD for Harbour and Harbour++

## Notes

### Windows - How to compile
```Batch
rem add bison.exe to path
set PATH=C:\GnuWin32\bin;%PATH%
cd sqlrddpp
cd source
hbmk2 sqlrdd.hbp
```

### Ubuntu - How to install and compile
```Batch
sudo apt install bison
sudo apt install unixodbc-dev
git clone https://github.com/marcosgambeta/sqlrddpp
cd sqlrdd
cd source
hbmk2 sqlrdd.hbp
```

## Links

https://gnuwin32.sourceforge.net/packages/bison.htm  
