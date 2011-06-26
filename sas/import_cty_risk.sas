/***
import_cty_risk.sas

sas file for importing the cty_risk benchmarks;

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	cty_risk.xpt
		
output: cty_risk.sas7bdat

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;

libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*copy for use;
x "mv /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata/cty_risk.sas7bdat /space/wanga/test/&size.";

libname tranfile xport '/space/wanga/test/100/cty_risk.xpt';
data tmp.cty_risk;
set tranfile.cty_risk;
run;

*clean up;
x "mv cty_risk.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv cty_risk.xpt /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";