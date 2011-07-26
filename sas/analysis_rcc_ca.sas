/***
analysis_rcc_CA.sas

sas file for matching cost reports to medpar stays, calculating artifical costs for MA stays and revenue.
collapse to the hicbic, MA level for a regression-ready file
also includes discharge level code that does not collapse dataset

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input:  denom100_2008.sas7bdat
		medpar_hmo.sas7bdat
		hosp_costs_CA.sas7bdat
		
output: medpar_hmo_costs_CA.sas7bdat
		rcc_byhicbic_CA.sas7bdat
		rcc_byhicbic.dta
		rcc_bydischarge_CA.sas7bdat
		rcc_bydischarge_CA.dta

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;

libname tmp "/space/wanga/test";
x "cd /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar_hmo.sas7bdat /space/wanga/test";
x "cd /space/wanga/test";

proc contents data=tmp.medpar_hmo;
run;

*merge in cost-to-charge ratio and net revenue ratio data by mprovno;
proc sql;
	create table tmp.medpar_hmo_costs_CA as
	select a.*, c.pzip, b.npr1, b.npr2,
	case 
		when a.dschrgdt > b.FY_END_DT then 1
		else 0
	end as d
	from (tmp.medpar_hmo where substr(mprovno,1,2)="05") a 
	left join tmp.hosp_costs_CA b on a.mprovno=b.mprovno and a.dschrgdt le b.FY_END_DT and a.admsndt ge b.FY_BGN_DT
	left join (select hicbic, substr(zip,1,5) as pzip from tmp.denom&size._&year.) c on a.hicbic=c.hicbic
	where c.pzip>="90001" and c.pzip<="96162";
quit;

proc sql;
	select count(*) as count
	from tmp.medpar_hmo_costs_CA
	where d=1;
quit;

*calculate costs: use ccr;
*calculate revenue: for MA use npr ratio, for TM use medpar_payment;
data tmp.medpar_hmo_costs_CA;
	set tmp.medpar_hmo_costs;
	cost=ccr*totchrg;
	if MA=1 then revenue1=totchrg*npr1;
	else revenue1=medpar_payment;
	if MA=1 then revenue2=totchrg*npr2;
	else revenue2=medpar_payment;
run;

*collapse by hicbic, MA;
*obs should be unique by hicbic, MA;
proc sql;
	create table tmp.rcc_byhicbic_CA as
	select hicbic, mprovno, MA, sum(revenue1) as revenue1, sum(revenue1) as revenue1, sum(cost) as cost, sum(totchrg) as totchrg, count(*) as stays
	from tmp.medpar_hmo_costs_CA
	where MA~=.
	group by hicbic, MA;
quit;

*discharge level, no collapse;
proc sql;
	create table tmp.rcc_bydischarge_CA as
	select hicbic, mprovno, MA, revenue1, revenue2, cost, totchrg, price, count(*) as stays
	from tmp.medpar_hmo_costs_CA
	where MA~=.;
quit;

*stat-transfer;
x "st rcc_byhicbic_CA.sas7bdat rcc_byhicbic_CA.dta";
x "st rcc_bydischarge_CA.sas7bdat rcc_bydischarge_CA.dta";

*cleanup;
x "mv rcc_byhicbic_CA.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata ";
x "mv rcc_byhicbic_CA.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew";

x "mv medpar_hmo_costs.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar_hmo.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hosp_costs.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic_medparonly.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic_medpar.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv trans_medparonly.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar100.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
