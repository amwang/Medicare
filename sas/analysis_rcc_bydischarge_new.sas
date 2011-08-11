/*****

anaylsis_rcc_bydischarge_new.sas

A sas code that finds migratory patients, i.e. those who have discharge data in hospitals 
outside of the 100-mile radius, in our MedPAR dataset

Author: Kunhee Kim (kunhee.kim@stanford.edu)
Date: 8/9/2011

Input: denom100_2008.sas7bdat
       rcc_bydischarge.sas7bdat
       hosp_region.sas7bdat

Output: rcc_bydischarge_new.sas7bdat
		rcc_bydischarge_new.dta
		zip_with_migrants.sas7bdat

*****/
       
options nocenter pagesize=max;
%let d_to_r = constant('pi')/180;

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

proc sql;
	create table tmp.rcc_bydischarge_new as
			select c.*, d.pzip, c.mprovno, e.lat1, e.long1, c.lat2, c.long2,
			3949.99 * arcos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(long2 - long1)) as dist format=6.4,
			case
				when calculated dist<100 then 1
				else 0
			end as valid
			from (select a.*, lat2*&d_to_r. as lat2, long2*&d_to_r. as long2 from tmp.rcc_bydischarge a , tmp.hosp_region b where a.mprovno=b.mprovno) c
			left join (select hicbic, input(substr(zip,1,5),BEST5.) as pzip from tmp.denom100_2008) d on d.hicbic=c.hicbic
			left join (select X*&d_to_r. as long1, Y*&d_to_r. as lat1, zip from sashelp.zipcode) e on e.zip=d.pzip;
quit; 

proc contents data=tmp.rcc_bydischarge_new;
proc print data=tmp.rcc_bydischarge_new (obs=100);
run;

proc sql;
	create table tmp.zip_with_migrants as
	select pzip, sum(ma) as ma, count(hicbic) as count, count(distinct hicbic) as bene
	from tmp.rcc_bydischarge_new
	where valid=0
	group by pzip
	having calculated count>0
	order by count descending;
quit;

proc print data=tmp.zip_with_migrants;
run;

*clean up;
x "st rcc_bydischarge_new.sas7bdat rcc_bydischarge_new.dta"
x "mv rcc_bydischarge_new.dta /disk/agedisk2/medicare.work/kessler-DUA16444/kunhee/analysis_stata";

/*clean up;
x "chmod 777 *";
x "chgrp -R medicare *";

x "mv denom100_2008.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv rcc_bydischarge.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hosp_region.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv migratory.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
*/