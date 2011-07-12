/***
analysis_rcc_bydischarge.sas

sas file for matching cost reports to medpar stays, calculating artifical costs for MA stays and revenue.
collapse to the hicbic, MA level for a regression-ready file

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	medpar100.sas7bdat
		hicbic.sas7bdat
		hosp_costs.sas7bdat
		
output: medpar_hmo_costs.sas7bdat
		medpar_hmo.sas7bdat
		hicbic_medpar.sas7bdat
		hicbic_medparonly.sas7bdat
		trans_medparonly.sas7bdat
		rcc_byhicbic.sas7bdat
		rcc_byhicbic.dta

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*calculate costs: use ccr;
*calculate revenue: for MA use npr ratio, for TM use medpar_payment;
data tmp.medpar_hmo_costs;
	set tmp.medpar_hmo_costs;
	cost=ccr*totchrg;
	if MA=1 then revenue=totchrg*npr;
	else revenue=medpar_payment;
	if MA=1 then price=npr/ccr;
	else price=revenue/cost;
run;

*don't collapse by hicbic, MA;
proc sql;
	create table tmp.rcc_bydischarge as
	select hicbic, MA, revenue, cost, totchrg, price
	from tmp.medpar_hmo_costs
	where MA~=.;
quit;

*stat-transfer;
x "st rcc_bydischarge.sas7bdat rcc_bydischarge.dta";

*cleanup;
x "mv rcc_bydischarge.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv rcc_bydischarge.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew";

x "mv medpar_hmo_costs.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata/medpar_hmo_costs.sas7bdat";
