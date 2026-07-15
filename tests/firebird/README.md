# Notes about the tests

If the test use native connection with Firebird, the client library will be
necessary in the compilation:

```
hbmk2 <filename> -lfbclient
```

If you are using MS-Windows, you can put the DLL inside this folder and compile with:

```
hbmk2 <filename> -L. -lfbclient.dll
```

The client library is not necessary if the test use a ODBC connection:

```
hbmk2 <filename>
```
