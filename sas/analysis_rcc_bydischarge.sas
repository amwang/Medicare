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
/*
*isolate denom to medparonly hicbic;
*drop keep only distinct hicbics and drop the ones that have multiple denom entries;
proc sql;
	create table tmp.hicbic_medpar (drop=drop) as 
	select distinct a.*
	from tmp.hicbic(keep= hicbic MA1--MA12 drop) a, tmp.medpar&size. b
	where a.hicbic=b.hicbic and drop~=1;
quit;

*keep hicbics that appear in medpar only to decrease processing time;
proc sql;
	create table tmp.hicbic_medparonly as
	select count(*) as count, *
	from tmp.hicbic_medpar
	group by hicbic
	having calculated count eq 1;
quit;

*wide-to-long reshape;
data tmp.trans_medparonly;
   set tmp.hicbic_medparonly;
   array along {12} MA1-MA12;
   do i=1 to 12;
	  month = i;
      MA = along{i};
	output;
   end;
   drop MA1-MA12 i;
run;

*merge and keep only hmo month=admission month;
*admit month has to be in 2008;
proc sql;
	create table tmp.medpar_hmo as
	select b.amonth, b.hicbic, MA, totchrg, medpar_payment, dschrgdt, admsndt, mprovno
	from (select hicbic, month, MA from tmp.trans_medparonly) a,
	(select hicbic, mprovno, month(admsndt) as amonth, admsndt, dschrgdt, totchrg,
		BLDDEDAM+COIN_AMT+PMT_AMT+PRPAYAMT+DED_AMT as medpar_payment from tmp.medpar&size.) b
	where a.hicbic=b.hicbic and a.month=b.amonth and year(admsndt)=2008;
quit;

*merge in cost-to-charge ratio and net revenue ratio data by mprovno;
proc sql;
	create table tmp.medpar_hmo_costs as
	select a.*, b.ccr, b.npr,
	case 
		when a.dschrgdt > b.FY_END_DT then 1
		else 0
	end as d
	from tmp.medpar_hmo a left join tmp.hosp_costs b
	on a.mprovno=b.mprovno and a.dschrgdt le b.FY_END_DT and a.admsndt ge b.FY_BGN_DT;
quit;

*calculate costs: use ccr;
*calculate revenue: for MA use npr ratio, for TM use medpar_payment;
data tmp.medpar_hmo_costs;
	set tmp.medpar_hmo_costs;
	cost=ccr*totchrg;
	if MA=1 then revenue=totchrg*npr;
	else revenue=medpar_payment;
run;
*/
*collapse by hicbic, MA;
*obs should be unique by hicbic, MA;
proc sql;
	create table tmp.rcc_bydischarge as
	select hicbic, MA, revenue, cost, totchrg
	from tmp.medpar_hmo_costs
	where MA~=.;
quit;

*stat-transfer;
x "st rcc_bydischarge.sas7bdat rcc_bydischarge.dta";

*cleanup;
x "mv rcc_bydischarge.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv rcc_bydischarge.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew";

x "mv medpar_hmo_costs.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
/*
x "mv medpar_hmo.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hosp_costs.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic_medparonly.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic_medpar.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv trans_medparonly.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv medpar100.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
*/
