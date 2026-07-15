# Notes about the tests

If the test use native connection with PostgreSQL, the client library will be
necessary in the compilation:

```
hbmk2 <filename> -llibpq
```

If you are using MS-Windows, you can put the DLL inside this folder and compile with:

```
hbmk2 <filename> -L. -llibpq.dll
```

To run the test, the DLL's below are necessary:

libcrypto-1_1-x64.dll  
libintl-8.dll  
libpq.dll  
libssl-1_1-x64.dll  

The client library is not necessary if the test use a ODBC connection:

```
hbmk2 <filename>
```
