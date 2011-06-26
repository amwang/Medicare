/***
npr_ccr_bymprovno.sas

sas file for constructing net payment ratio(npr) and cost to charge ratio(ccr);

last updated: 08Jun2011
author: Angela Wang amwang@stanford.edu

input: 	hosp_chars_new.sas7bdat
		
output: hosp_costs.sas7bdat

***/

options nocenter pagesize=max;
%let size=100;
%let year=2008;
libname tmp "/space/wanga/test/&size.";
x "cd /space/wanga/test/&size.";

*check what's in chris's file;
proc contents data=tmp.hosp_chars_new;
run;

*calculate net payment ratio(npr) and cost to charge ratio(ccr);
data tmp.hosp_costs;
set tmp.hosp_chars_new;
med_nt_pmt=sum(med_nt_pps,med_nt_tfr,med_nt_cst);
npr=(tot_nt_rev-med_nt_pmt)/(tot_gr_rev-med_ip_chg);
tot_cost=tot_cost_1+tot_cost_2;
ccr=tot_cost/tot_gr_rev;
run;

*drop missings;
data tmp.hosp_costs;
set tmp.hosp_costs;
if tot_gr_rev=. or med_ip_chg=. then delete;
if npr<0 or npr>1 then delete;
if ccr>1 then delete;
run;

*cleanup;
x "mv hosp_char_new.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";
x "mv hosp_costs.sas7bdat /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/workingdata";

