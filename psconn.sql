REM psconn.sql
DEF recname = 'PSCONN'
@@psrecdefn

BEGIN
  :sql_text := '
SELECT row_number() over (order by CONNGATEWAYID) row_num
, t.*
FROM &&table_name t
ORDER BY row_num
'; 
END;				
/

@@psgenerichtml.sql
