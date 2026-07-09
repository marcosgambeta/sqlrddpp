PROCEDURE Main()

   LOCAL a
   LOCAL n

   a := SR_ListODBCDrivers()

   ? "len(a)=", len(a)

   FOR n := 1 TO len(a)
      ? "desc=", a[n, 1], "attr=", a[n, 2]
   NEXT n

   WAIT

RETURN
