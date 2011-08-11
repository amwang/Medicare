/***
analysis_rcc_bydischarge.sas

sas file for matching cost reports to medpar stays, calculating artifical costs for MA stays and revenue.
collapse to the hicbic, MA level for a regression-ready file

last updated: 10Aug2011
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
libname tmp "/disk/agedisk2/medicare.work/kessler-DUA16444/kunhee/workingdata";
x "cd /disk/agedisk2/medicare.work/kessler-DUA16444/kunhee/workingdata";


/*x "cd /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar_hmo_costs.sas7bdat /space/wanga/test";
x "cd /space/wanga/test"; */

*calculate costs: use ccr;
*calculate revenue: for MA use npr ratio, for TM use medpar_payment;
/*data tmp.medpar_hmo_costs;
	set tmp.medpar_hmo_costs;
	cost=ccr*totchrg;
	if MA=1 then revenue=totchrg*npr;
	else revenue=medpar_payment;
	price=revenue/cost;
run; */

*don't collapse by hicbic, MA;
proc sql;
	create table tmp.rcc_bydischarge as
	select hicbic, mprovno, MA, revenue, cost, totchrg, price
	from tmp.medpar_hmo_costs
	where MA~=. and (revenue>=1000 and revenue<=1000000) and (cost>=1000 and cost<=1000000)
	and (totchrg>=1000 and totchrg<=1000000);
quit; 

*stat-transfer;
x "st rcc_bydischarge.sas7bdat rcc_bydischarge.dta";

*cleanup;
x "rm -rf /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata/rcc_bydischarge.sas7bdat";
x "rm -rf /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/rcc_bydischarge.dta";
x "mv rcc_bydischarge.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv rcc_bydischarge.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata";
x "mv medpar_hmo_costs.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata/";
