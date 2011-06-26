/***

Chris Afendulis
Last modified 17 Nov 2009

This program takes the 1996-2000 denominator files and creates two extracts: a hic-year-level file with demographic information, and a hic-level file with monthly hmo enrollment information.  It does these two things for the index strokes only.

Input datasets:
	/disk/agedisk2/medicare/nberwest/tape100/denom100_&year..sas7bdat.gz (1996-2000)
	/disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/strokes_index_97_99.sas7bdat.gz

Output dataset:
	/disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/denom9600.sas7bdat.gz
	/disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/hmo9600.sas7bdat.gz

***/

libname tmp "/space/cafendul/";
options mprint;

* Get stroke file first;
x "cd /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
x "cp strokes_index_97_99.sas7bdat.gz /space/cafendul";
x "cd /space/cafendul/";
x "chmod 700 strokes_index_97_99.sas7bdat.gz";
x "gunzip -f strokes_index_97_99.sas7bdat.gz";

* Keep only those cases that show up in the index strokes file;
data strokes;
	set tmp.strokes_index_97_99 (keep=hicbic);
run;

proc sort nodupkey;
	by hicbic;
run;

* Remove temporary stroke file;
x "cd /space/cafendul/";
x "rm -r strokes_index_97_99.sas7bdat";

%macro denom(year);

* Get file and unzip;
x "cd /disk/agedisk2/medicare/nberwest/tape100";
x "cp denom100_&year..sas7bdat.gz /space/cafendul";
x "cd /space/cafendul/";
x "chmod 700 denom100_&year..sas7bdat.gz";
x "gunzip -f denom100_&year..sas7bdat.gz";

/*
proc contents data=tmp.denom100_&year.;
run;
*/

* Keep only the variables you need, and recode birthdate, deathdate female and black;
data denom&year. (drop=dstate dsex drace dbdate dddate);
%if &year.<=1997 %then %do;
	set tmp.denom100_&year. (keep=hicbic dstate dsex drace dhmoi01-dhmoi09 dhmoi10-dhmoi12 dbdate dddate dzip5 
	rename=(dhmoi01=hmo1 dhmoi02=hmo2 dhmoi03=hmo3 dhmoi04=hmo4 dhmoi05=hmo5 dhmoi06=hmo6
		dhmoi07=hmo7 dhmoi08=hmo8 dhmoi09=hmo9 dhmoi10=hmo10 dhmoi11=hmo11 dhmoi12=hmo12
		dzip5=zip) /*obs=100000*/);
	%end;

%if &year.>1997 %then %do;
	set tmp.denom100_&year. (keep=hicbic dstate dsex drace dhmoi01-dhmoi09 dhmoi10-dhmoi12 dbdate dddate zip5 
	rename=(dhmoi01=hmo1 dhmoi02=hmo2 dhmoi03=hmo3 dhmoi04=hmo4 dhmoi05=hmo5 dhmoi06=hmo6
		dhmoi07=hmo7 dhmoi08=hmo8 dhmoi09=hmo9 dhmoi10=hmo10 dhmoi11=hmo11 dhmoi12=hmo12 
		zip5=zip) /*obs=100000*/);
	%end;

	length bthdate 5;
	bthdate=dbdate;
	attrib bthdate format=mmddyy10.;

	length dthdate 5;
	dthdate=dddate;
	attrib dthdate format=mmddyy10.;

	* Get death cases with death dates in the CY only;
	if dthdate>"31Dec&year."D then dthdate=.;

	length female 3;
	female=.;
	if dsex='1' then female=0;
	if dsex='2' then female=1;
	
	length black 3;
	black=0;
	if drace='2' then black=1;

	length year 3;
	year=&year.;

	* Drop if outside 50 states and DC;
	if dstate in ('40','48') or dstate> '53' then delete;

run;

* Remove temporary file;
x "cd /space/cafendul/";
x "rm -r denom100_&year..sas7bdat";

proc sort data=denom&year.;
	by hicbic;
run;

* Keep records for stroke patients only;
data denom&year.;
	merge strokes(in=a) denom&year.(in=b);
	by hicbic;
	if a=1 and b=1;
run;

* Create a file with hic and hmo variables only, and change the names so that they indicate month and year;
data hmo&year.;
     set denom&year. (keep=hicbic hmo1-hmo12 rename=(
		hmo1=hmo_1_&year. hmo2=hmo_2_&year. hmo3=hmo_3_&year. hmo4=hmo_4_&year. hmo5=hmo_5_&year. hmo6=hmo_6_&year. 
		hmo7=hmo_7_&year. hmo8=hmo_8_&year. hmo9=hmo_9_&year. hmo10=hmo_10_&year. hmo11=hmo_11_&year. hmo12=hmo_12_&year.
		));
run;

* Append demographic data to data from earlier years;
data tmp.denom9600;
%if &year.=1996 %then %do;
	set denom&year. (drop=hmo1-hmo12);
	%end;
%if &year.>1996 %then %do;
	set tmp.denom9600 denom&year. (drop=hmo1-hmo12);
	%end;
run;

* Remove earlier file;
proc datasets nolist;
     delete denom&year.;
run;

* Merge HMO data to data from earlier years;
* First sort by hicbic;
proc sort data=hmo&year.;
	by hicbic;
run;

data tmp.hmo9600;
%if &year.=1996 %then %do;
	set hmo&year.;
	%end;
%if &year.>1996 %then %do;
	merge tmp.hmo9600 hmo&year.;
	by hicbic;
	%end;
run;

* Remove earlier file;
proc datasets nolist;
     delete hmo&year.;
run;

%mend denom;

%denom(1996);
%denom(1997);
%denom(1998);
%denom(1999);
%denom(2000);

proc contents data=tmp.denom9600;
run;

proc contents data=tmp.hmo9600;
run;

* Zip up files;
x "cd /space/cafendul/";
x "chmod 700 denom9600.sas7bdat";
x "chmod 700 hmo9600.sas7bdat";
x "gzip -f denom9600.sas7bdat";
x "gzip -f hmo9600.sas7bdat";
x "mv -f denom9600.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
x "mv -f hmo9600.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";
