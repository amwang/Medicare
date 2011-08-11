/*****

find_migratory.sas

A sas code that finds migratory patients, i.e. those who have discharge data in hospitals 
outside of the 100-mile radius, in our MedPAR dataset

Author: Kunhee Kim (kunhee.kim@stanford.edu)
Date: 8/9/2011

Input:  denom100_2008.sas7bdat
        rcc_bydischarge.sas7bdat
        hosp_region.sas7bdat
		denom100_2008.sas7bdat
		hicbic.sas7bdat
		cty_risk.sas7bdat
		
output: trans.sas7bdat
		denom.sas7bdat
		denom.dta
		
*****/
       
options nocenter pagesize=max;
%let d_to_r = constant('pi')/180;
%let size=100;
%let year=2008;

x "cd /disk/agedisk2/medicare.work/kessler-DUA16444/kunhee/workingdata";
libname tmp "/disk/agedisk2/medicare.work/kessler-DUA16444/kunhee/workingdata";

/*
proc contents data=tmp.rcc_bydischarge;
run;

proc contents data=tmp.hosp_region;
run;

proc contents data=tmp.denom100_2008;
run;

proc contents data=sashelp.zipcode;
run; */

*create working denominator to add ages, benchmark, and weights;
*drop benes who are >100 or <65 years old;
*create a dummy for whether a patient's discharge was made outside of the 100-mile radius;
/*proc sql;
	create table tmp.denom_new (drop= bene_dob death_dt age a_less65 a100 sex race state_cd cnty_cd zip hmo1 buy1) as
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
	substr(a.zip,1,5) as zip5,
	benchmar, c.*, f.hicbic, f.ma, f.mprovno, f.lat2, f.long2, g.lat1, g.long1, g.*,
	3949.99 * arcos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(long2 - long1)) as dist format=6.4,
	case
		when calculated dist<100 then 1
		else 0
	end as valid
	from (select hicbic, death_dt, bene_dob, sex, race, zip, hmo1, buy1, state_cd || cnty_cd as SSA, input(substr(zip,1,5),BEST5.) as pzip from tmp.denom&size._&year.) a
	left join tmp.cty_risk b 
		on a.SSA=b.cty
	left join tmp.trans c 
		on a.hicbic=c.hicbic and a.death_dt=c.death_dt and a.hmo1=c.hmo1 and a.buy1=c.buy1	
	join (select hicbic, ma, d.mprovno, lat2*&d_to_r. as lat2, long2*&d_to_r. as long2 from tmp.rcc_bydischarge d, tmp.hosp_region e where d.mprovno=e.mprovno) f 
		on f.hicbic=a.hicbic
	left join (select X*&d_to_r. as long1, Y*&d_to_r. as lat1, zip from sashelp.zipcode) g 
		on g.zip=a.pzip
	where calculated a_less65~=1 and calculated a100~=1;
quit; */

*stat transfer;
*x "st denom_new.sas7bdat denom_new.dta";

*clean-up;
*x "mv denom_new.dta /disk/agedisk2/medicare.work/kessler-DUA16444/kunhee/analysis_stata";

/*proc contents data=tmp.denom_new;
proc print data=tmp.denom_new (obs=100);
run; */

proc sql;
	create table tmp.count_migrants as
	select pzip, sum(ma) as ma, count(hicbic) as count, count(distinct hicbic) as bene, valid
	from tmp.denom_new
	group by valid
	having count>0;
	*order by count descending;
quit;

proc print data=tmp.count_migrants (obs=200);
run;

/*proc sql;
	create table tmp.zip_with_migrants as
	select pzip, sum(ma) as ma, count(hicbic) as count, count(distinct hicbic) as bene
	from tmp.migratory
	where valid=0
	group by pzip
	having calculated count>0
	order by count descending;
quit;

proc print data=tmp.zip_with_migrants;
run;
*/
