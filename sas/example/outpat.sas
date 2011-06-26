/***

Chris Afendulis
Last modified 25 Feb 2010

This program takes the various outpatient SAF files to create a dataset with dates, expenditure and whether a claim (line item?) had a rehab revenue center code or not.

input datasets:
	/disk/agedisk2/medicare/nberwest/tape102/oph100_&year._&file.e.sas7bdat.gz (1997-1999)
	/disk/agedisk2/medicare/nberwest/tape102/opi100_&year._&file.e.sas7bdat.gz (2000)
	/disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/strokes_index_97_99.sas7bdat.gz

output datasets:
	/disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/outpat9700.sas7bdat.gz

***/

libname tmp "/space/cafendul/";

options mprint;

* Get file of index strokes;
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

%macro readin(year,numfiles,numcodes);

%do file=1 %to &numfiles.;

* Copy and unzip file;
%if &year.>=1997 and &year.<=1998 %then %do;
x "cd /disk/agedisk2/medicare/nberwest/tape102/";
x "cp oph100_&year._&file.e.sas7bdat.gz /space/cafendul/";
x "cd /space/cafendul";
x "chmod 700 oph100_&year._&file.e.sas7bdat.gz";
x "gunzip -f oph100_&year._&file.e.sas7bdat.gz";
x "chmod 700 oph100_&year._&file.e.sas7bdat";
%end;

%if &year.>=1999 and &year.<=2000 %then %do;
x "cd /disk/agedisk2/medicare/nberwest/tape102/";
x "cp opi100_&year._&file.e.sas7bdat.gz /space/cafendul/";
x "cd /space/cafendul";
x "chmod 700 opi100_&year._&file.e.sas7bdat.gz";
x "gunzip -f opi100_&year._&file.e.sas7bdat.gz";
x "chmod 700 opi100_&year._&file.e.sas7bdat";
x "mv opi100_&year._&file.e.sas7bdat oph100_&year._&file.e.sas7bdat";
%end;

data outpat&file.(drop=i rvcntr1-rvcntr&numcodes. pmt_amt ptb_ded ptb_coin prpayamt from_dt thru_dt);
	set tmp.oph100_&year._&file.e (keep=hicbic rvcntr1-rvcntr&numcodes. pmt_amt ptb_ded ptb_coin prpayamt from_dt thru_dt);

	* Calculate expenditure;
	length outpat_exp 5.;
	outpat_exp=sum(pmt_amt,ptb_ded,ptb_coin,prpayamt);

	* Change format of date variables;
	length frmdate 5;
	frmdate=from_dt;
	attrib frmdate format=mmddyy10.;

	length thrdate 5;
	thrdate=thru_dt;
	attrib thrdate format=mmddyy10.;

	* Loop through the revenue code fields to find rehab services;
	array procs{&numcodes.} rvcntr1-rvcntr&numcodes.;
	length rehab 3.;
	rehab=0;

	do i=1 to &numcodes.;
		if procs{i} in 
		(
		'0410', '0412', '0413', '0419', '0420', '0421', '0422', '0423', '0424', '0429', '0430', 
		'0431', '0432', '0433', '0434', '0439', '0440', '0441', '0442', '0443', '0444', '0449'
		)
		then rehab=1;
	end;	

run;

* Remove original file;
x "cd /space/cafendul";
x "rm -f oph100_&year._&file.e.sas7bdat";

* Keep records for stroke patients only;
proc sort;
	by hicbic;
run;

data outpat&file.;
	merge strokes(in=a) outpat&file.(in=b);
	by hicbic;
	if a=1 and b=1;
run;

* Append all of the datasets to each other;
data outpat&year.;
	%if &file.=1 %then %do;
	set outpat&file.;
	%end;
	%else %do;
	set outpat&year. outpat&file.;
	%end;
run;

proc datasets;
	delete outpat&file.;
run;

%end;

* Append yearly files;
data tmp.outpat9700;
	%if &year.=1997 %then %do;
	set outpat&year.;
	%end;
	%else %do;
	set tmp.outpat9700 outpat&year.;
	%end;
run;

proc datasets;
	delete outpat&year.;
run;

%mend readin;

%readin(1997,32,58);
%readin(1998,113,58);
%readin(1999,103,45);
%readin(2000,58,45);

proc contents;
run;

x "cd /space/cafendul/";
x "chmod 700 outpat9700.sas7bdat";
x "gzip -f outpat9700.sas7bdat";
x "mv outpat9700.sas7bdat.gz /disk/agebulk1/medicare.work/kessler-DUA16444/cafendul/hosp_integration/summer09/";