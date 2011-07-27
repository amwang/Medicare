
options nocenter pagesize=max;
%let d_to_r = constant('pi')/180;
/*
x "cd /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv denom100_2008.sas7bdat /space/wanga/test";
x "mv rcc_bydischarge.sas7bdat /space/wanga/test";
x "mv hosp_region.sas7bdat /space/wanga/test";*/
x "cd /space/wanga/test";

libname tmp "/space/wanga/test";
/*
proc contents data=tmp.rcc_bydischarge;
run;

proc contents data=tmp.hosp_region;
run;

proc contents data=tmp.denom100_2008;
run;

proc contents data=sashelp.zipcode;
run;
*/
proc sql;
	create table tmp.migratory as
			select c.ma, d.pzip, c.mprovno, e.lat1, e.long1, c.lat2, c.long2,
			3949.99 * arcos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(long2 - long1)) as dist format=6.4,
			case
				when calculated dist<100 then 1
				else 0
			end as valid
			from (select hicbic, ma, a.mprovno, input(substr(zip,1,5),BEST5.) as pzip, lat2*&d_to_r. as lat2, long2*&d_to_r. as long2 from tmp.iv_bydischarge a , tmp.hosp_region b where a.mprovno=b.mprovno) c
			left join (select X*&d_to_r. as long1, Y*&d_to_r. as lat1, zip from sashelp.zipcode) d on c.zip=d.pzip;
quit;

proc sql;
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


*clean up;
x "chmod 777 *";
x "chgrp -R medicare *";
/*
x "mv denom100_2008.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv rcc_bydischarge.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hosp_region.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv migratory.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";