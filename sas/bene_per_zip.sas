/***
bene_per_zip.sas

sas file for constructing a dataset for beneficiaries per zip code
last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: denom&size._&year..sas7bdat

output: bene_per_zip.sas7bdat
		bene_per_zip.dta

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*number of benes in each zip;
proc sql;
create table tmp.bene_per_zip as
select distinct count(*) as count, substr(zip,1,5) as zip5
from tmp.denom&size._&year.
group by calculated zip5;
quit;

*stat-transfer;
x "st bene_per_zip.sas7bdat bene_per_zip.dta";

*cleanup;
x "mv denom100_2008.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv bene_per_zip.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv bene_per_zip.dta /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew";