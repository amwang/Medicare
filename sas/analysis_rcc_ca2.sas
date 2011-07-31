/*** 
analysis_rcc_CA.sas

input: denom100_2008.sas7bdat
	   medpar_hmo.sas7bdat
	   hosp_costs_CA.sas7bdat
	   
output: medpar_hmo_costs_CA.sas7bdat
	    rcc_bhicbic_CA.sas7bdat
	    rcc_bydischarge_CA.sas7bdat
	    rcc_bydischarge_CA.dta
	    
***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;

libname tmp "/space/wanga/test";
x "cd /space/wanga/test";
*x "st new_hosp_cost_ca.dta test.csv";

/*proc import out=tmp.text file="test.csv" replace;
run;

proc print data=tmp.text;
run;

proc contents data=tmp.text;
run;

proc datasets lib=tmp;
run;*/
/*
* merge in cost-to-charge ratio and net revenue ratio data by mprovno;
proc sql; 
	create table tmp.medpar_hmo_costs_CA as
	select a.*, c.pzip, b.npr_comp, b.npr_ma,
	case
		when substr(a.mprovno,1,2)~='05' then 1
		else 0
	end as instate
	from (select med.* from tmp.medpar_hmo_costs med) a 
	left join tmp.text b on a.mprovno=b.mprovno and a.dschrgdt le b.fy_end and a.admsndt ge b.fy_begin
	left join (select hicbic, substr(zip,1,5) as pzip
	from tmp.denom&size._&year.) c on a.hicbic=c.hicbic
	where c.pzip>="90001" and c.pzip<="96162";
quit;

proc print data=tmp.medpar_hmo_costs_CA (obs=10);
quit;
*/
proc sql;
select sum(instate) as instate
from tmp.medpar_hmo_costs_CA;
quit;

proc print data=tmp.medpar_hmo_costs_CA (obs=10);
quit;

