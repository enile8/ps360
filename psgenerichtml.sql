REM psgenerichtml.sql
set head off
break on report
SPOOL OFF

REM put xlat values in the plan table
declare
  l_recname VARCHAR2(15) := '&&recname';
  l_xlatstring VARCHAR2(4000);
begin
  DELETE FROM plan_table 
  WHERE  statement_id = l_recname;

  for i in (
    SELECT f.fieldnum, x.fieldvalue, x.xlatlongname
    ,      row_number() over (partition by f.fieldnum ORDER BY x.fieldvalue) seq
    ,      row_number() over (partition by f.fieldnum ORDER BY x.fieldvalue DESC) qes
    FROM   psrecfielddb f
    ,      psxlatitem x
    WHERE  f.recname = l_recname
    AND    x.fieldname = f.fieldname
    AND    x.eff_status = 'A'
    AND    x.effdt = (SELECT MAX(x1.effdt)
                      FROM   psxlatitem x1
                      WHERE  x1.fieldname = f.fieldname
                      AND    x1.effdt <= SYSDATE)
    ORDER BY f.fieldnum, x.fieldvalue
  ) LOOP
    IF i.seq = 1 THEN
      l_xlatstring := i.fieldvalue||' = '||i.xlatlongname;
    ELSE
      l_xlatstring := l_xlatstring||'<br/>'||i.fieldvalue||' = '||i.xlatlongname;
    END IF;
    IF i.qes = 1 THEN
      INSERT INTO plan_table (statement_id, plan_id, remarks)
      VALUES (l_recname, i.fieldnum, l_xlatstring);
    END IF;
  END LOOP;
end;
/

EXEC :sql_text_display := REPLACE(REPLACE(TRIM(CHR(10) FROM :sql_text)||';', '<', CHR(38)||'lt;'), '>', CHR(38)||'gt;');

PRO
DEF dbname = "''";
DEF section = "&&lrecname";
DEF htmlspool = "&&ps_prefix._&&psdbname._&&repcol._&&section..&&htmlsuffix";

DEF report_title = "&&section: &&recdescr";
DEF report_abstract_1 = "<br>&&descrlong";

COLUMN remarks ENTMAP OFF heading 'XLAT Values'
SPOOL &&pstemp
select 'COLUMN '||f.fieldname||' FORMAT A'||LENGTH(f.fieldname)
from   psrecfielddb f
,      psdbfield d
where f.recname = '&&recname'
and   f.fieldname = d.fieldname
and   d.fieldtype IN(0,1,8,9) /*VARCHAR2*/
and   d.length >0
and   d.length <LENGTH(f.fieldname)
order by f.fieldnum
/
select 'COLUMN '||f.fieldname||' FORMAT '||RPAD('9',LENGTH(f.fieldname)-d.decimalpos,'9')
||CASE WHEN d.decimalpos>0 THEN RPAD('.',d.decimalpos+1,'9') END 
from   psrecfielddb f
,      psdbfield d
where f.recname = '&&recname'
and   f.fieldname = d.fieldname
and   d.fieldtype IN (2,3) /*NUMBER*/
and   d.length >0
and   d.length <LENGTH(f.fieldname)
order by f.fieldnum
/
Spool off
@@&&pstemp

SPOOL &&pstemp
PRINT :sql_text
PRO /
SPOOL OFF

SPO &&htmlspool;
PRO <head>
PRO <meta http-equiv="Content-Type" content="text/html;charset=utf-8" />
PRO <title>&&report_title</title>

@@pshtmlstyle

PRO <script type="text/javascript" src="sorttable.js"></script>

PRO </head>
PRO <body>
PRO <h1>&&ps_report_prefix &&report_title.</h1>
PRO &&report_abstract_1
PRO &&report_abstract_2
PRO &&report_abstract_3
PRO &&report_abstract_4
PRO <br />

-- body
SET head on pages 50000 MARK HTML ON TABLE "class=sortable" ENTMAP ON
@@&&pstemp
SET pages 0 head off MARK HTML OFF 

PRO <p>

PRO  #: click on a column heading to sort on it
PRO <pre>
COLUMN descrlong FORMAT a50 wrap on
SET head on pages 50000 MARK HTML ON TABLE "class=sortable" ENTMAP ON
select f.fieldnum, f.fieldname, l.longname
,      RTRIM(d.descrlong) descrlong
,      x.remarks
from   psrecfielddb f
	   left outer join plan_table x
	   on x.statement_id = f.recname
	   and x.plan_id = f.fieldnum
	   left outer join psdbfldlabl l
	   on l.fieldname = f.fieldname
	   and l.default_label = 1         
,      psdbfield d
where f.recname = '&&recname'
and   f.fieldname = d.fieldname
order by f.fieldnum
/
SET lines 80 pages 0 head off MARK HTML OFF 

DESC &&table_name
SET LIN 32767 
PRINT :sql_text
PRO /
PRO </pre>

PRO </body>
PRO </html>

SPO OFF;
DEF report_abstract_1 = "";
DEF report_abstract_2 = "";
DEF report_abstract_3 = "";
DEF report_abstract_4 = "";

ROLLBACK;
@@pszipit
REM HOS del &&pstemp