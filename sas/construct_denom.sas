/***
construct_denom.sas

sas file for constructing denom from raw files

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	den&size._&year.&j..sas7bdat.bz2
		
output: denom&size._&year..sas7dat

***/
*personal sas options for output;
options nocenter pagesize=max;
*macros that can be referenced later on;
%let size=100;
%let year=2008;
%let f1=1;
%let f2=100;

*change directory to working;
x "cd /space/wanga/test/&size.";
*specify library name so that sas can find all your files;
libname tmp "/space/wanga/test/&size.";

*make a blank table using sql with all the variables and variable sizes we need for more efficent append processing;
proc sql;
create table tmp.denom&size._&year. 
(hicbic char(15), sex char(1), race char(1), bene_dob num(4) format=DATE9., death_dt num(4) format=DATE9., zip char(9), state_cd char(2), cnty_cd char(3), hmo1 char(1), hmo2 char(1), hmo3 char(1), hmo4 char(1), hmo5 char(1), hmo6 char(1), hmo7 char(1), hmo8 char(1), hmo9 char(1), hmo10 char(1), hmo11 char(1), hmo12 char(1), buy1 char(1), buy2 char(1), buy3 char(1), buy4 char(1), buy5 char(1), buy6 char(1), buy7 char(1), buy8 char(1), buy9 char(1), buy10 char(1), buy11 char(1), buy12 char(1));

*append files together for full denominator file;
%macro append;
%do j=&f1. %to &f2.;
	*change directory to where the raw data is;
	x "cd /disk/agedisk1/medicare/data.NOBACKUP/u/c/&size.pct/denom/&year.";
	*copy over all of the zipped denom files to your working directory;
	x "cp den&size._&year._&j..sas7bdat.bz2 /space/wanga/test/&size.";
	*change back into our working directory;
	x "cd /space/wanga/test/&size.";
	*change the permissions of the files so that we can work with them;
	x "chmod 700 den&size._&year._&j..sas7bdat.bz2";
	*unzip the files;
	x "bunzip2 -f den&size._&year._&j..sas7bdat.bz2";
	
	*append file to the base constructed above;
	proc append base=tmp.denom&size._&year. data=tmp.den&size._&year._&j. 
	(keep=bene_id sex race bene_dob death_dt bene_zip state_cd cnty_cd HMOIND01-HMOIND12 BUYIN01-BUYIN12 
		rename=(bene_id=hicbic HMOIND01-HMOIND12=hmo1-hmo12 BUYIN01-BUYIN12=buy1-buy12 bene_zip=zip));
	
	*clean up and remove our partitioned files;
	x "rm -rf den&size._&year._&j..sas7bdat";
	
%end;
%mend;
%append;
quit;