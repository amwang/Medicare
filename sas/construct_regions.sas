/***
construct_regions.sas

sas file to create regions for hospital market structure regressions

last updated: 02May2011
author: Angela Wang amwang@stanford.edu

regions:*1: CT, ME, NH, RI, and VT *2: MA *3: Bronx, East Long Island, Manhattan HRRs *4: all NY, NJ or PA HRRs (except NYC);
*5: DE, DC, FL, GA, MD, NC, SC, VA, and WV *6: IN and OH *7: MI and WI *8: IL *9: AL, KY, MS, and TN;
*10: IA, KS, MN, MO, NE, ND, and SD *11: AR, LA, OK, and TX *12: AZ, CO, ID, MT, NV, NM, UT, and WY;
*13: AK, HI, OR, WA, and all of CA except the LA HRR *14: LA HRR;

input: 	hosp_geocode_clean.sas7bdat
		zip_to_region_xwalk.txt
		denom100_2008.sas7bdat
		medpar100.sas7bdat
		hosp_chars.sas7bdat
		sashelp.zipcode.sas7bdat
		
output: hosp.sas7bdat
		zip_to_r.sas7bdat
		hosp_region.sas7bdat
		medpar_group.sas7bdat
		medpar_age.sas7bdat
		medpar_region.sas7bdat
		zip_region.sas7bdat
		analysis&j..sas7bdat
		stata&j..sas7bdat
		stata&j..xpt
		
***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
%let r1=1; /*region 1*/
%let r2=14; /*region 2*/
%let d_to_r = constant('pi')/180;

x "cd /space/wanga/test/&size.";
libname tmp "/space/wanga/test/&size.";

*create working hospital file;
proc sql;
	create table tmp.hosp as 
		select mprovno, zip format = $5. length = 5,
		lat as lat2,
		lon as long2
		from tmp.hosp_geocode_clean;
quit;

*import zip-to-region xwalk;
data tmp.zip_to_r;
	%let _EFIERR_ = 0;
	infile 'zip_to_region_xwalk.txt' delimiter='09'x MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat hrr 3. ;
	informat region 2. ;
	informat zip5 $5. ;
	format hrr 3. ;
	format region 2. ;
	format zip5 $5. ;
	input hrr region zip5 $;
	if _ERROR_ then call symputx('_EFIERR_',1);
run;

*assign regions to hospitals based on zip;
proc sql;
	create table tmp.hosp_region as
		select a.mprovno, a.zip as zip5, lat2, long2, b.REGION as region, b.HRR as hrr
		from tmp.hosp a, tmp.zip_to_r b
		where a.zip=b.zip5;
quit;

*create working denominator file;
data denomchar (keep= hicbic bthdate dthdate female black zip5 state_cd cnty_cd);
	set tmp.denom&size._&year.;
	
	length bthdate 5;
	bthdate=bene_dob;
	attrib bthdate format=mmddyy10.;

	length dthdate 5;
	dthdate=death_dt;
	attrib dthdate format=mmddyy10.;

	* Get death cases with death dates in the CY only;
	if dthdate>"31Dec2008"D then dthdate=.;

	length female 3;
	female=.;
	if sex='1' then female=0;
	if sex='2' then female=1;

	length black 3;
	black=0;
	if race='2' then black=1;
	
	zip5 = substr(zip,1,5);
run;

proc sort nodupkey;
	by hicbic;
run;

*create working medpar file;
data age;
	set tmp.medpar&size. (keep=hicbic admsndt dschrgdt mprovno) ;
	format admsndt mmddyy10.;
	format dschrgdt mmddyy10.;
run;

*generate age dummies;
proc sql;
	create table medpar_age as
		select a.hicbic, mprovno, zip5, state_cd || cnty_cd as SSA, female, black, dschrgdt, admsndt,
		floor((intck('month',bthdate,admsndt)- (day(admsndt) < day(bthdate))) / 12) as ageadmit,
		floor((intck('month',bthdate,'01JAN2008'd)- (day('01JAN2008'd) < day(bthdate))) / 12) as agejan08,
		(calculated ageadmit<65) as a_less65admit length=3,
		(65<=calculated ageadmit<70) as a6569admit length=3,
		(70<=calculated ageadmit<75) as a7074admit length=3,
		(75<=calculated ageadmit<80) as a7579admit length=3,
		(80<=calculated ageadmit<90) as a8089admit length=3,
		(90<=calculated ageadmit<100) as a9099admit length=3,
		(calculated ageadmit>=100) as a100admit length=3,
		(calculated agejan08<65) as a_less65jan08 length=3,
		(65<=calculated agejan08<70) as a6569jan08 length=3,
		(70<=calculated agejan08<75) as a7074jan08 length=3,
		(75<=calculated agejan08<80) as a7579jan08 length=3,
		(80<=calculated agejan08<90) as a8089jan08 length=3,
		(90<=calculated agejan08<100) as a9099jan08 length=3,
		(calculated agejan08>=100) as a100jan08 length=3
		from age a, denomchar b
		where a.hicbic=b.hicbic
		order by zip5;
quit;

*reduce individual hicbics to collapsed hospital-choice-demographics by zip;
proc sql;
	create table tmp.medpar_group as
		select distinct zip5, mprovno, female, black, a6569jan08, a7074jan08, a7579jan08, a8089jan08, a9099jan08,
		count(hicbic) as count, count(distinct hicbic) as bene
		from medpar_age
		where (a_less65jan08~=1 and a100jan08~=1)
		group by zip5, mprovno, female, black, a6569jan08, a7074jan08, a7579jan08, a8089jan08;
quit;

proc sql;
	create table tmp.medpar_age as
		select a.*, monotonic() as id
		from tmp.medpar_group a;
quit;

*assign regions to cases based on zip;
proc sql;
	create table tmp.medpar_region as
		select a.*, b.REGION as region, b.HRR as hrr
		from tmp.medpar_age a, tmp.zip_to_r b
		where a.zip5=b.zip5;
quit;

*reformat zipcode;
data tmp.medpar_region;
	set tmp.medpar_region;
	ZIP=input(zip5,BEST5.);
	format ZIP z5.;
run;

*create zip-to-region xwalk;
proc sql;
	create table tmp.zip_region as
		select distinct ZIP, hrr, region, zip5
		from tmp.medpar_age;
quit;

data tmp.hosp_chars (rename=(own_fp=hchar1 own_np=hchar2 own_gv=hchar3 small_beds=hchar4 med_beds=hchar5 large_beds=hchar6 teaching=hchar7));
	set tmp.hosp_chars;
run;

*macro that splits hospitals and zipcodes into regions and crosses them; 
%macro analysis();
%do j=&r1. %to &r2.;

	data zip_geocode;
		set sashelp.zipcode (keep = X Y ZIP);
	run;

	*region hospitals;
	data hosp&j.;
		set tmp.hosp_region;
		if region="&j.";
		ZIP=input(zip5,BEST5.);
		format ZIP z5.;
	run;
	proc sort nodupkey;
		by mprovno;
	run;

	*region zipcodes;
	data zip&j.;
		set tmp.zip_region (keep=ZIP hrr region);
		if region="&j.";
	run;
	proc sort nodupkey;
		by ZIP;
	run;

	*valid MedPAR records (both hospital and zipcode in region);
	proc sql;
		create table medpar_region&j. as
			select c.*
			from (select a.* from tmp.medpar_region a, hosp&j. b where a.mprovno=b.mprovno) c, zip&j. d
			where c.ZIP=d.ZIP;
	quit;

	*add geocodes and convert to radians;
	proc sql;
		create table zip&j._geocode as
			select a.ZIP, X*&d_to_r. as long1, Y*&d_to_r. as lat1
			from zip&j. a, zip_geocode b
			where a.ZIP=b.ZIP;
	quit;

	proc sql;
		create table hosp&j._geocode as
			select mprovno, a.ZIP, lat2*&d_to_r. as lat2, long2*&d_to_r. as long2
			from hosp&j. a;
	quit;

	*cross join hicbic and hosptial lat/lon, calculate distance and keep patient/hospital pairs <100miles;
	proc sql;
		create table zip_hospital_dist&j. as
				select a.ZIP as pzip, lat1, long1, mprovno, b.ZIP as hzip, lat2, long2,
				3949.99 * arcos(sin(lat1) * sin(lat2) + cos(lat1) * cos(lat2) * cos(long2 - long1)) as dist format=6.4
				from zip&j._geocode a, hosp&j._geocode b
				where calculated dist<100
				order by a.ZIP;
	quit;

	*drop any duplicates;
	proc sort nodupkey data=zip_hospital_dist&j.;
		by lat1 long1 lat2 long2;
	run;

	proc sql;
		create table tmp.analysis&j. as 
			select a.*, beds,
			hchar1 label='ownership for-profit', hchar2 label='ownership non-profit', 
			hchar3 label='ownership government', hchar4 label='small', 
			hchar5 label='medium', hchar6 label='large', hchar7 label='teaching'
			from zip_hospital_dist&j. a, tmp.hosp_chars b
		  	where a.mprovno=b.mprovno
			order by mprovno;
	quit;

	proc sort nodupkey data=tmp.analysis&j.;
		by lat1 long1 lat2 long2;
	run;

	*clean up;
	proc datasets lib=work kill;
	run;
	
%end;
%mend;
%analysis;

*macro that determines differential differences;
%macro hosp();
%do j=&r1. %to &r2.;

	data analysis;
		set tmp.analysis&j.;
	run;
	
	proc sort data=analysis;
		by pzip;
	run;
	
	*create file with 2 closest hospitals;
	proc means noprint data=analysis;
	 class pzip hchar1 hchar2 hchar3 hchar4 hchar5 hchar6 hchar7;
	 types pzip * (hchar1 hchar2 hchar3 hchar4 hchar5 hchar6 hchar7);
	 var dist;
	 output out=product
		 idgroup (min(dist) out[2] (dist mprovno) =dist mprovno);
	run;

	proc sort data=product;
		by pzip;
	run;
	
	%macro hchar();
	%do k=1 %to 7;
		*keep relevant characteristic only;
		data product&k.;
			set product;
			if hchar&k.~=.;
		run;

		*find dsame for each zip-characteristic;
		proc sql;
			create table analysis&k. as
		select mprovno, a.pzip,
		case
			when mprovno ne mprovno_1 then dist_1
			else dist_2
			end as dsame&k.
		from analysis a, product&k. b
		where (a.pzip=b.pzip) and (a.hchar&k.=b.hchar&k.);
		quit;
	%end;
	%mend;
	%hchar;

	*merge all distances back with analysis to one file;
	proc sql;
		create table analysis_char as
		select a.*, dsame1, dsame2, dsame3, dsame4, dsame5, dsame6, dsame7
		from analysis a left join analysis1 b on (a.pzip=b.pzip and a.mprovno=b.mprovno)
		left join analysis2 c on (a.pzip=c.pzip and a.mprovno=c.mprovno)
		left join analysis3 d on (a.pzip=d.pzip and a.mprovno=d.mprovno)
		left join analysis4 e on (a.pzip=e.pzip and a.mprovno=e.mprovno)
		left join analysis5 f on (a.pzip=f.pzip and a.mprovno=f.mprovno)
		left join analysis6 g on (a.pzip=g.pzip and a.mprovno=g.mprovno)
		left join analysis7 h on (a.pzip=h.pzip and a.mprovno=h.mprovno);
	quit;

	*create opp characteristic dummies in analysis;
	data analysis_alt;
	 set analysis;
	 ophchar1=(hchar1=0);
	 ophchar2=(hchar2=0);
	 ophchar3=(hchar3=0);
	 ophchar4=(hchar4=0);
	 ophchar5=(hchar5=0);
	 ophchar6=(hchar6=0);
	 ophchar7=(hchar7=0);
	run;
	
	*create file with flipped characteristics;
	data product_alt;
	 set product (rename=(hchar1=ophchar1 hchar2=ophchar2 hchar3=ophchar3
		hchar4=ophchar4 hchar5=ophchar5 hchar6=ophchar6 hchar7=ophchar7));
	run;

	*find dsame for each zip-characteristic;
	%macro ophchar();
	%do k=1 %to 7;
		*keep relevant characteristic only;
		data product_alt&k.;
			set product_alt;
			if ophchar&k.~=.;
		run;
	
		*find dopp for each zip-characteristic;
		proc sql;
			create table analysis_alt&k. as
			select mprovno, a.pzip,
			case
				when mprovno ne mprovno_1 then dist_1
				else dist_2
			end as dopp&k.
			from analysis_alt a left join product_alt&k. b
			on a.pzip=b.pzip and a.ophchar&k.=b.ophchar&k.;
		quit;
	%end;
	%mend;
	%ophchar;

	*merge distances back with analysis;
	proc sql;
		create table analysis_full as
		select a.*, dopp1, dopp2, dopp3, dopp4, dopp5, dopp6, dopp7
		from analysis_char a left join analysis_alt1 b on (a.pzip=b.pzip and a.mprovno=b.mprovno)
		left join analysis_alt2 c on (a.pzip=c.pzip and a.mprovno=c.mprovno)
		left join analysis_alt3 d on (a.pzip=d.pzip and a.mprovno=d.mprovno)
		left join analysis_alt4 e on (a.pzip=e.pzip and a.mprovno=e.mprovno)
		left join analysis_alt5 f on (a.pzip=f.pzip and a.mprovno=f.mprovno)
		left join analysis_alt6 g on (a.pzip=g.pzip and a.mprovno=g.mprovno)
		left join analysis_alt7 h on (a.pzip=h.pzip and a.mprovno=h.mprovno);
	quit;
	
	proc sort data=analysis_full;
		by pzip;
	run;

	*calculate differential distances;
	data final_analysis&j. (drop= dopp1-dopp7 dsame1-dsame7);
	 set analysis_full;
	 ddsame1= dist-dsame1;
	 ddsame2= dist-dsame2;
	 ddsame3= dist-dsame3;
	 ddsame4= dist-dsame4;
	 ddsame5= dist-dsame5;
	 ddsame6= dist-dsame6;
	 ddsame7= dist-dsame7;
	 ddopp1=  dist-dopp1;
	 ddopp2=  dist-dopp2;
	 ddopp3=  dist-dopp3;
	 ddopp4=  dist-dopp4;
	 ddopp5=  dist-dopp5;
	 ddopp6=  dist-dopp6;
	 ddopp7=  dist-dopp7;
	run;

	*add bene characteristics;
	proc sql;
		create table tmp.stata&j. as
		select id, a.ZIP, female, black, a6569jan08, a7074jan08, a7579jan08, a8089jan08, a9099jan08, count, bene, b.*,
		case
			when b.mprovno=a.mprovno then 1
			else 0
		end as choice,
		sum(calculated choice) as choice_present
		from medpar_region&j. a, final_analysis&j. b
		where a.ZIP=b.pzip
		group by id
		having sum(calculated choice) ge 1;
	quit;

	proc datasets nolist lib=tmp;
	MODIFY stata&j.;
	FORMAT _all_;
	run;

	libname x xport "/space/wanga/test/&size./stata&j..xpt";
	options VALIDVARNAME=V6;
	proc copy in=tmp out=x memtype=data; 
	   select stata&j.;
	run;

	x "cp stata&j..xpt 	/disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/&size./statanew";
	x "rm -rf stata&j..xpt";
	x "rm -rf stata&j..sas7bdat";
	x "rm -rf analysis&j..sas7bdat";
	
	*clean up;
	proc datasets lib=work kill;
	run;

%end;
%mend;
%hosp;

