/***
tables.sas

code for creating various summary/frequency tables throughout the project

last updated: 25Jun2011
author: Angela Wang amwang@stanford.edu

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*define format for missing;
proc format;
value miss 
. = 'missing'
other = 'nonmissing';
run;

*frequency counts by TM and MA weights.;
proc freq data=tmp.hicbic;
tables weightTM weightMA / list missing nocum nocol nopercent norow;
run;

*count missing values in hospital charge report data;
proc freq data=tmp.hosp_chars_new;
tables tot_gr_rev tot_nt_rev med_ip_chg med_nt_pps med_nt_tfr tot_cost_1 tot_cost_2/ nocum missing;
format _numeric_ miss.;
run;

*count number of nonmissing data points reports;
proc sql;
select MA, count(ccr) as ccr, count(npr) as npr, count(MA) as MAokay
from tmp.medpar_hmo_costs
group by MA;
quit;

*count no cost report match by MA status;
proc sql;
select MA, count(*) as nocostrptmatch
from tmp.medpar_hmo_costs
where d=1
group by MA;
quit;

*count MA status undeterminable by month;
proc sql;
	select amonth, count(*) as nomatchMA
	from tmp.medpar_hmo_costs
	where MA=.
	group by amonth;
quit;

*frequency tables for diagnosis codes;
data dgnscd;
	set tmp.medpar&size. (keep= hicbic dgnscd1-dgnscd10);
	array dxarray[10] dgnscd1-dgnscd10;
	do i=1 to 10;
		dx=dxarray[i];
		if dx ne . then output;
	end;
	keep hicbic dx;
run;

proc freq data=dgnscd;
   title "Frequency Counts for dgnscd";
   tables dgnscd/ nocum nopercent;
run;


*12985781 total valid hmo status assignments;
*TM:11072426 (85.3%);
*MA:1913355 (14.7%);
proc univariate data=tmp.hmo_status plots plotsize=30;
var TM MA;
run;


*proc contents;
proc contents data=tmp.trans_medparonly;
run;
proc contents data=tmp.medpar&size.;
run;
proc contents data=tmp.hosp_costs;
run;