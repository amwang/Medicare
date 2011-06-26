/***
hmo_status_byhicbic.sas

sas file for assigns TM or MA status and weights to all benes based on hmo, buy-in, and death status from denom

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	denom100_2008.sas7bdat
		
output: hicbic.sas7bdat

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*create hmo status file;
*keep distinct hicbic;
data tmp.hicbic (keep= hicbic MA1--MA12 weightMA weightTM death_dt hmo1 buy1 drop switch);
	set tmp.denom&size._&year. (keep=hicbic hmo1--hmo12 buy1--buy12 death_dt);
	length default=3;
	length buyall hmoall thmoall deadall eall MAall $12;
	death_mo = month(death_dt);
	death_yr = year(death_dt);
	array buy {12} buy1-buy12;
	array hmo{12} hmo1-hmo12;
	array thmo {12} $1. thmo1-thmo12;
	array dead {12} 3. d1-d12;
	array e {12} 3. e1-e12;
	array MA {12} 3. MA1-MA12;
	array iMA {11} 3. iMA2-iMA12;
	array oMA {11} 3. oMA2-oMA12;
	array ie {11} 3. ie2-ie12;
	array oe {11} 3. oe2-oe12;

	*determine eligibility and death;
	do i = 1 to 12;
		*create true hmo status;
		thmo{i}=hmo{i};
		*dummies for months after death;
		if death_mo~=. and death_mo+1<=i and death_yr<=2008 then dead{i}=1;
		else dead{i}=0;
		*dummies for eligibility: buyin yes and not dead;
		if dead{i}~=1 then e{i}=(buy{i}~='0');
		else e{i}=0;
		*recode hmo to missing if not eligible;
		if e{i}=0 then thmo{i}='.';
		*create MA dummy for month;
		if thmo{i}~='.' then MA{i}=(thmo{i}~='0' and thmo{i}~='4');
		else MA{i}=.;
	end;

	*count switches and eligibility changes;
	do i = 1 to 11;
		*switch into MA;
		iMA{i}=(MA{i}=0 and MA{i+1}=1);
		*switch out of MA;
		oMA{i}=(MA{i}=1 and MA{i+1}=0);
		*eligibility:no->yes;
		ie{i}=(e{i}=0 and e{i+1}=1);
		*eligibility:yes->no;
		oe{i}=(e{i}=1 and e{i+1}=0);
	end;

	*total switches and eligibility changes;
	switch=sum(of iMA2-iMA12)+sum(of oMA2-oMA12);
	enroll=sum(of ie2-ie12)+sum(of oe2-oe12);
	e_months=sum(of e1-e12);

	*create categorical variable for drops;
	*1+ MA/TM switches;
	if switch>1 then xswitch=1;
	else xswitch=0;
	*noncontinous eligibility;
	if enroll>1 then xenroll=1;
	else xenroll=0;
	*never eligibile;
	if e_months=0 then noenroll=1;
	else noenroll=0;
	*aged into medicare;
	if e1=0 then agein=1;
	else agein=0;
	*drop;
	drop=(xswitch=1 or xenroll=1 or noenroll=1 or agein=1);

	*create weights;
	if death_yr=2008 then 
		do;
			weightMA=sum(of MA1-MA12)/n(of MA1-MA12);
			weightTM=1-weightMA;
		end;
	else 
		do;
			weightMA=sum(of MA1-MA12)/12;
			weightTM=n(of MA1-MA12)/12-weightMA;
		end;

	*cat of monthly variables;
	buyall=cats(of buy1-buy12);
	hmoall=cat(of hmo1-hmo12);
	thmoall=cat(of thmo1-thmo12);
	deadall=cats(of d1-d12);
	eall=cats(of e1-e12);
	MAall=cat(of MA1-MA12);
run;

*cleanup;
x "mv denom100_2008.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hicbic.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
