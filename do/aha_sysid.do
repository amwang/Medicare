/***
aha_sysid.do

do file for processing hospital system ids

last updated: 27Jul2011
author: Angela Wang amwang@stanford.edu

input: aha_extract2008.dta
		
output: aha_sysid.dta


***/


local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/

clear all
capture log close
set more off
set matsize 11000

cd `path'

use aha_extract2008, clear
duplicates drop mcrnum sysid, force
duplicates tag mcrnum, gen(dup)
drop if dup==1 & sysid==""
drop dup id year
drop if mcrnum==313032
drop if mcrnum==.
format mcrnum %06.0f
gen str6 mprovno = string(mcrnum,"%06.0f")
drop mcrnum
save aha_sysid, replace
