/***
clean_hosp_geocode.sas

sas file for getting to a clean version of hospital geocodes and zipcodes

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	hosp_geocodes.sas7bdat
		aha_extract2007.dta
		aha_extract2008.dta
		
output: aha_2007.sas7bdat
		aha_2008.sas7bdat
		hosp_geocode_clean.sas7bdat

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
x "cd /space/wanga/test/&size.";
libname tmp "/space/wanga/test/&size.";

*hospital geocodes from scott;
*determine unique number of hospitals in cost files;
proc sql;
	create table mprovno as
	select distinct mprovno
	from tmp.hosp_geocodes;
quit;

*3560 total hospitals/3686 total records;
proc sql;
	select count(*) as total
	from mprovno; 
quit;

*leading zeros to mprovno, zip, lat and lon fix;
proc sql;
	create table hosp_geocodes as
	select zip,
	round(latitude*10, 0.0001) as lat,
	case 
		when abs(longitude) < 2 then round(longitude*100, 0.0001)
		else round(longitude*10, 0.0001)
	end as lon,
	put(mprovno,z6.) as mprovno
	from tmp.hosp_geocodes
	order by mprovno;
quit;

*minus 28 for incorrectly coded zipcodes;
data hosp_geocodes;
	set hosp_geocodes;
	if mprovno="010073" and zip="36521" then delete;
	if mprovno="040016" and zip="72212" then delete;
	if mprovno="050243" and zip="92263" then delete;
	if mprovno="050230" then zip="92843";
	if mprovno="050243" and zip="92263" then delete;
	if mprovno="050315" and zip="93306" then delete;
	if mprovno="070033" and zip="06783" then delete;
	if mprovno="100014" then zip="32170";
	if mprovno="100062" and zip="34471" then delete;
	if mprovno="100090" and zip="32806" then delete;
	if mprovno="100137" and zip="33845" then delete;
	if mprovno="100220" and zip="33901" then delete;
	if mprovno="110087" and zip="30046" then delete;
	if mprovno="110161" and zip="30042" then delete;
	if mprovno="140164" and zip="62901" then delete;
	if mprovno="140189" and zip="61920" then delete;
	if mprovno="180012" and zip="92701" then delete;
	if mprovno="190008" and zip="70361" then delete;
	if mprovno="210003" and zip="20707" then delete;
	if mprovno="230054" and zip="49833" then delete;
	if mprovno="230207" and zip="48383" then delete;
	if mprovno="250067" and zip="38873" then delete;
	if mprovno="280009" then zip="68848";
	if mprovno="280123" and zip="68130" then delete;
	if mprovno="330196" and zip="10312" then delete;
	if mprovno="330385" and zip="10461" then delete;
	if mprovno="340131" and zip="28561" then delete;
	if mprovno="340138" and zip="27603" then delete;
	if mprovno="340160" and zip="28904" then delete;
	if mprovno="380027" and zip="97470" then delete;
	if mprovno="390131" and zip="15203" then delete;
	if mprovno="450090" and lat<34 then delete;
	if mprovno="520195" and zip="53211" then delete;
	/*fix miscoded zips*/
	if mprovno="220052" then zip="02302";
	if mprovno="220062" then zip="01605";
	if mprovno="220080" then zip="01844";
	if mprovno="330140" then zip="13203";
	if mprovno="510046" then zip="24740";
	if mprovno="490038" then zip="24354";
	if mprovno="510082" then zip="26651";
	if mprovno="420038" then zip="29325";
	if mprovno="110018" then zip="30014";
	if mprovno="110192" then zip="30078";
	if mprovno="110039" then zip="30904";
	if mprovno="110194" then zip="39845";
	if mprovno="100249" then zip="34428";
	if mprovno="100023" then zip="34452";
	if mprovno="100072" then zip="32763";
	if mprovno="100110" then zip="34741";
	if mprovno="010143" then zip="35055";
	if mprovno="010112" then zip="36732";
	if mprovno="180027" then zip="42071";
	if mprovno="180105" then zip="42167";
	if mprovno="140179" then zip="60805";
	if mprovno="140202" then zip="60048";
	if mprovno="260178" then zip="65201";
	if mprovno="190014" then zip="70381";
	if mprovno="370025" then zip="74401";
	if mprovno="460047" then zip="84124";
	if mprovno="320004" then zip="88310";
	if mprovno="050329" then zip="92882";
	if mprovno="050694" then zip="92555";/*should be 050765*/
	if mprovno="050684" then zip="92585";
	if mprovno="050336" then zip="95240";
	if mprovno="050589" then zip="92870";
	if mprovno="050693" then zip="92663";/*should be 050224*/
	if mprovno="050017" then zip="95819";
	if mprovno="020024" then zip="99669";
run;

*minus 62 for duplicate keys;
proc sort nodupkey;
	by mprovno zip lat lon;
run;

*identify hosp with one geocode;
proc sql;
	create table hosp_1 as
	select mprovno, zip, lat, lon,
	freq(mprovno) as nummprovno
	from hosp_geocodes
	group by mprovno
	having nummprovno LT 2;
quit;

*average lat/lon over mprovno for hospitals that have more than one geocode;
proc sql;
	create table hosp_2 as
	select distinct mprovno, zip, freq(mprovno) as nummprovno,
	avg(lat) as lat, avg(lon) as lon
   from hosp_geocodes
   group by mprovno
   having nummprovno GE 2;
quit;

*merge hosp together;
proc sql;
	create table hosp_geocodes as
	select mprovno, zip, lat, lon
	from hosp_1
	union
	select mprovno, zip, lat, lon
	from hosp_2
quit;

*AHA (amer. hosp assoc files for comparison);
*build_aha.sas;
proc import out=tmp.aha_2007 file="aha_extract2007.dta" replace;
run;
proc import out=tmp.aha_2008 file="aha_extract2008.dta" replace;
run;
proc sql;
	create table tmp.aha_2008 as
	select lat, lon,
	put(MCRNUM, z6.) as mprovno
	from tmp.aha_2008;
quit;

*join 2007 and 2008;
proc sql;
	create table join as
	select HCFAID as mprovno, lat, lon, 2007 as yr
	from tmp.aha_2007
	union 
	select mprovno, lat, lon, 2008 as yr
	from tmp.aha_2008
	order by mprovno;
quit;

*drop duplicates;
proc sort nodupkey;
	by mprovno lat lon;
run;

*unique hospitals: 3414;
proc sql;
	create table aha_hosp as
	select mprovno, avg(lat) as lat, avg(lon) as lon
	from join
	group by mprovno;
quit;

*merge aha with CMS geocodes;
*20 hosptials lat/lon updated using aha, 147 not present in aha;
*updated if lat and long differ by more than 0.5 radians;
proc sql;
	create table tmp.hosp_geocode_clean as
	select a.mprovno, zip,
	case 
		when ((abs(a.lat-b.lat) > 0.5) and (abs(a.lon-b.lon) > 0.5)) then b.lat
		else a.lat
	end as lat,
	case 
		when ((abs(a.lat-b.lat) > 0.5) and (abs(a.lon-b.lon) > 0.5)) then b.lon
		else a.lon
	end as lon,
	case 
		when ((abs(a.lat-b.lat) > 0.5) and (abs(a.lon-b.lon) > 0.5)) then 1
		else 0
	end as latlonnew,
	case
		when (b.lat and b.lon) then 0
		else 1
	end as miss_aha
	from hosp_geocodes a 
	left join aha_hosp b on a.mprovno=b.mprovno;
quit;

*clean up*; 
proc datasets lib=work kill;
run;

x "mv hosp_geocodes.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv aha_extract2007.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv aha_extract2008.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv aha_2007.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv aha_2008.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hosp_geocode_clean.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";