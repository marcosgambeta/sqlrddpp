PROCEDURE Main()

   LOCAL a
   LOCAL n

   // list all data sources
   a := SR_ListODBCDataSources()
   ? "len(a)=", len(a), "(all data sources)"
   FOR n := 1 TO len(a)
      ? "DSN=", a[n, 1], "DRIVER=", a[n, 2]
   NEXT n
   WAIT

   // list all data sources
   a := SR_ListODBCDataSources(2) // SQL_FETCH_FIRST
   ? "len(a)=", len(a), "(all data sources)"
   FOR n := 1 TO len(a)
      ? "DSN=", a[n, 1], "DRIVER=", a[n, 2]
   NEXT n
   WAIT

   // list only user data sources
   a := SR_ListODBCDataSources(31) // SQL_FETCH_FIRST_USER
   ? "len(a)=", len(a), "(user data sources)"
   FOR n := 1 TO len(a)
      ? "DSN=", a[n, 1], "DRIVER=", a[n, 2]
   NEXT n
   WAIT

   // list only system data sources
   a := SR_ListODBCDataSources(32) // SQL_FETCH_FIRST_SYSTEM
   ? "len(a)=", len(a), "(system data sources)"
   FOR n := 1 TO len(a)
      ? "DSN=", a[n, 1], "DRIVER=", a[n, 2]
   NEXT n
   WAIT


   // list only user data sources
   a := SR_ListODBCUserDataSources()
   ? "len(a)=", len(a), "(user data sources)"
   FOR n := 1 TO len(a)
      ? "DSN=", a[n, 1], "DRIVER=", a[n, 2]
   NEXT n
   WAIT

   // list only system data sources
   a := SR_ListODBCSystemDataSources()
   ? "len(a)=", len(a), "(system data sources)"
   FOR n := 1 TO len(a)
      ? "DSN=", a[n, 1], "DRIVER=", a[n, 2]
   NEXT n
   WAIT

RETURN
