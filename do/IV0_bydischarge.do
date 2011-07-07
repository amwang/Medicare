/***
IV0_bydischarge.do

do file for merging files together for IV regressions, running 0-stage regression to calculate MA_hat for IV construction

last updated: 26May2011
author: Angela Wang amwang@stanford.edu

input: 	medpar_hcc_byhicbic.dta
		rcc_byhicbic.dta
		denom.dta
		HHI_mprovno_sys.dta
		hosp_mrkt_strct.dta
		
		
output: probit0.ster
		probit0.dta
		iv_rcc.dta

***/

clear all
capture log close
set more off
set mem 20g
set matsize 11000
local size 100
local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/`size'/statanew
cd `path'
pause on
log using "IV0_bydischarge.log", replace

local hcc p1_max-p177_max
local mrkt HHI_sys CAP_pat_k_star hosp_char*
local ages a7074 a7579 a8089 a9099 
local case female black fb
local age_x_case female_* black_* fb_*
local demo_ctrl `ages' `case' `age_x_case' `hcc'
local ma_hat_IV ma_hat ma_hat_HHI_sys ma_hat_CAP_pat_k_star ma_hat_hosp_char*
local ma_mrkt ma_HHI_sys ma_CAP_pat_k_star ma_hosp_char*
local dep_var lntotchrg lncost lnrevenue

use medpar_hcc_byhicbic, clear
keep hicbic `hcc'
compress
save hcc, replace

use rcc_bydischarge, clear
gen drop = (revenue==.)|(cost==.)|(revenue<0)|(cost>0 & revenue==0)
save rcc_bydischarge, replace

use denom, clear
destring(zip5), gen(pzip)
duplicates drop
duplicates tag hicbic ma, gen(dup)
drop if dup==1
drop dup
drop if hicbic=="mmmmmmmUfWWsfGW"|hicbic=="mmmmmmmWDsDWWfD"|hicbic=="mmmmmmmsDWGDfXW"|hicbic=="mmmmmmmsGaDGamD"|hicbic=="mmmmmmmsXfsJDJX"
*merge hospital market variables by zip
save denom_clean, replace
use denom_clean, clear

merge 1:m hicbic ma using rcc_bydischarge, keep(3) keepusing(revenue cost totchrg drop) nogen
drop if drop==1
compress

merge m:1 hicbic using hcc, keep(1 3) nogen
mvencode `hcc', mv(0) override

merge m:1 pzip using HHI_mprovno_sys, keep(1 3) nogen
compress
rename pzip zip
merge m:1 zip using hosp_mrkt_zip, keep(1 3) nogen
rename zip pzip

drop HHI_pat_k_star drop death_yr zip5 ssa hicbic

*construct demo interactions
gen fb = female*black

foreach var of varlist `ages' {
	gen byte female_`var'= `var'*female
	gen byte black_`var'=`var'*black
	gen byte fb_`var'=`var'*fb
}

*probits for estimating ma_hat
probit ma `demo_ctrl' `mrkt' benchmar [pweight=weight]
estimates save probit0_bydischarge, replace
predict ma_hat
save probit0_bydischarge, replace

drop if ma_hat==.
foreach var of varlist `mrkt'{
	gen ma_hat_`var'=ma_hat*`var'
	gen ma_`var'=ma*`var'
}

mvencode totchrg cost revenue, mv(1) override
recode revenue 0=1
gen lntotchrg=ln(totchrg)
gen lncost=ln(cost)
gen lnrevenue=ln(revenue)
save iv_rcc_bydischarge, replace
