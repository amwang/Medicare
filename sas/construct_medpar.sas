/***
construct_medpar.sas

sas file for constructing medpar from raw files

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	med&size._&year._&j..sas7bdat.bz2
		
output: medpar&size..sas7dat

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
%let f1=1;
%let f2=100;
x "cd /space/wanga/test/&size.";
libname tmp "/space/wanga/test/&size.";

proc sql;
create table tmp.medpar&size.
(hicbic char(15),mprovno char(6),ADMSNDT num(4) format=DATE9.,DSCHRGDT num(4) format=DATE9., SPCLUNIT char(1),pmt_amt num(8),ded_amt num(8),coin_amt num(8),blddedam num(8),prpayamt num(8),ghopdcd char(1), DGNSCD1 char(6),DGNSCD2 char(6),DGNSCD3 char(6),DGNSCD4 char(6),DGNSCD5 char(6), DGNSCD6 char(6),DGNSCD7 char(6),DGNSCD8 char(6),DGNSCD9 char(6),DGNSCD10 char(6), PRCDRCD1 char(7),PRCDRCD2 char(7),PRCDRCD3 char(7),PRCDRCD4 char(7),PRCDRCD5 char(7),PRCDRCD6 char(7), drg_cd char(3), totchrg num(8), OUTLRAMT num(8) );

*full medpar file;
	%macro append;
		%do j=&f1. %to &f2.;

			x "cd /disk/agero9/medicare/data/&size.pct/med/&year.";
			x "cp med&size._&year._&j..sas7bdat.bz2 /space/wanga/test/&size.";
			x "cd /space/wanga/test/&size.";
			x "chmod 700 med&size._&year._&j..sas7bdat.bz2";
			x "bunzip2 -f med&size._&year._&j..sas7bdat.bz2";
	
			proc append base=tmp.medpar&size. data=tmp.med&size._&year._&j. 
			(keep=BENE_ID PRVDRNUM ADMSNDT DSCHRGDT SPCLUNIT pmt_amt ded_amt coin_amt blddedam prpayamt ghopdcd DGNSCD1-DGNSCD10 PRCDRCD1-PRCDRCD6 drg_cd totchrg outlramt rename=(BENE_ID=hicbic PRVDRNUM=mprovno) );
			where (substr(mprovno,6,1) notin ('E','F')) and (substr(mprovno,3,4) between "0000" and "0879") and 
			SPCLUNIT notin ('M', 'R', 'S', 'T', 'U', 'V', 'W', 'Y', 'Z') and (substr(mprovno,1,2) notin ('40', '48', '64', '65', '99'));
	
			x "cd /space/wanga/test/&size.";
			x "rm -rf med&size._&year._&j..sas7bdat";
	
		%end;
	%mend;

%append;
quit;

x "mv medpar&size..sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
