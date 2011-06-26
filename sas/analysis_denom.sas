/***
analysis_denom.sas

sas file for duplicating observation and assigning TM/MA weights, adding hicbic characteristics.

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	denom100_2008.sas7bdat
		hicbic.sas7bdat
		
output: trans.sas7bdat
		denom.sas7bdat
		denom.dta

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*duplicate and assign weights for those benes with MA and TM enrollment;
data tmp.trans (drop=drop);
   set tmp.hicbic (drop= MA1--MA12);
	MA=.;
	weight=.;
   array along {2} weightTM weightMA;
		do i=1 to 2;
		MA=i-1;
		weight = along{i};
		if weight>0.01 then output;
		end;
	where drop~=1;
	drop weightMA weightTM i;
run;

*create working denominator to add ages, benchmark, and weights;
*drop benes who are >100 or <65 years old;
proc sql;
	create table tmp.denom (drop= bene_dob death_dt age a_less65 a100 sex race state_cd cnty_cd zip hmo1 buy1) as
	select a.*,
	floor((intck('month',bene_dob,'01JAN2008'd)- (day('01JAN2008'd) < day(bene_dob))) / 12) as age,
	(calculated age<65) as a_less65 length=3,
	(65<=calculated age<70) as a6569 length=3,
	(70<=calculated age<75) as a7074 length=3,
	(75<=calculated age<80) as a7579 length=3,
	(80<=calculated age<90) as a8089 length=3,
	(90<=calculated age<100) as a9099 length=3,
	(calculated age>=100) as a100 length=3,
	(sex='2') as female length=3,
	(race='2') as black length=3,
	substr(zip,1,5) as zip5,
	benchmar, c.*
	from (select hicbic, death_dt, bene_dob, sex, race, zip, hmo1, buy1, state_cd || cnty_cd as SSA from tmp.denom&size._&year.) a
	left join tmp.cty_risk b 
		on a.SSA=b.cty
	/*left*/ join tmp.trans c 
		on a.hicbic=c.hicbic and a.death_dt=c.death_dt and a.hmo1=c.hmo1 and a.buy1=c.buy1
	where calculated a_less65~=1 and calculated a100~=1;
quit;

*stat transfer;
x "st denom.sas7bdat denom.dta";

*cleanup;
x "mv denom.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew";
x "mv denom.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv trans.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv denom100_2008.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
