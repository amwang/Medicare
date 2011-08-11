/***
IV0.do

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
local path /disk/agedisk2/medicare.work/kessler-DUA16444/kunhee/analysis_stata
cd `path'
pause on
log using "IV0.log", replace

local hcc p1_max-p177_max
local mrkt HHI* CAP_pat_k_star hosp_char*
local ages a7074 a7579 a8089 a9099 
local case female black fb
local age_x_case female_* black_* fb_*
local demo_ctrl `ages' `case' `age_x_case' `hcc'
local ma_hat_IV ma_hat ma_hat_HHI* ma_hat_CAP_pat_k_star ma_hat_hosp_char*
local ma_mrkt ma_HHI* ma_CAP_pat_k_star ma_hosp_char*
local depvar totchrg cost revenue 
local dep_var lntotchrg lncost lnrevenue
local level byhicbic bydischarge
local benchmark b_minus_ffs b_div_ffs

/*prep datasets for merge
use medpar_hcc_byhicbic, clear
keep hicbic `hcc'
save hcc, replace */

/*use rcc_byhicbic, clear
capture drop drop
gen drop = (revenue==.)|(cost==.)|(revenue<0)|(cost>0 & revenue==0)
count if drop==1
save rcc_byhicbic, replace */

/*use rcc_bydischarge, clear
capture drop drop
gen drop = (revenue==.)|(cost==.)|(revenue<0)|(cost>0 & revenue==0)|(price==.)
count if drop==1
save rcc_bydischarge, replace */

/*use denom_new, clear
*destring(zip5), gen(pzip)
drop zip5
duplicates drop
duplicates tag hicbic ma, gen(dup)
drop if dup==1
drop dup
drop if hicbic=="mmmmmmmUfWWsfGW"|hicbic=="mmmmmmmWDsDWWfD"|hicbic=="mmmmmmmsDWGDfXW"|hicbic=="mmmmmmmsGaDGamD"|hicbic=="mmmmmmmsXfsJDJX"
save denom_new_clean, replace */

*start merging
use denom_new_clean, clear
*merge hccs
merge m:1 hicbic using hcc, keep(1 3) nogen
mvencode `hcc', mv(0) override

*merge hospital structure variables
merge m:1 pzip using hosp_mrkt_zip, keep(3) nogen

*merge new benchmark variables
merge m:1 ssa using benchmark_new, keep(3) keepusing(benchmark b_minus_ffs b_div_ffs) nogen
save base, replace

*construct two different datasets for hicbic-level and discharged based analysis
use base, clear
*merge hicbic based rcc
merge 1:1 hicbic ma using rcc_byhicbic, keep(1 3) keepusing(revenue cost totchrg drop) nogen
drop if ssa=="45762"
drop if pzip>=99000 & pzip<100000
drop if drop==1
save probit0_byhicbic, replace

use base, clear
*merge expenditures for discharge based
merge 1:m hicbic ma using rcc_bydischarge, keep(3) keepusing(revenue cost totchrg price drop) nogen
drop if ssa=="45762"
drop if pzip>=99000 & pzip<100000
drop if drop==1
save probit0_bydischarge, replace

*loop through both hicbic and discharge level data
foreach type in `level' {
	*loop through both benchmarks
	foreach bench in `benchmark' {
		use probit0_`type', clear
		drop benchmar hicbic ssa zip5 death_yr
		
		*construct demo interactions
		gen fb = female*black
		foreach var of varlist `ages' {
			gen byte female_`var'= `var'*female
			gen byte black_`var'=`var'*black
			gen byte fb_`var'=`var'*fb
		}

		*probits for estimating ma_hat
		probit ma `demo_ctrl' `mrkt' `bench' [pweight=weight]
		estimates save probit0_`type', replace
		predict ma_hat
		save probit0_`type'_`bench', replace
		drop if ma_hat==.

		*generate the IVs
		foreach var of varlist `mrkt' {
			gen ma_hat_`var'=ma_hat*`var'
			gen ma_`var'=ma*`var'
		}
		
		*add new DV: markup = 1-cost/rev
		gen markup = 1-cost/revenue
		drop if markup <-1 | markup > 0.5
		
		*recode nonpositive expenditures to 0
		mvencode totchrg cost revenue, mv(0) override
		gen lntotchrg=ln(totchrg+1)
		gen lncost=ln(cost+1)
		gen lnrevenue=ln(revenue+1)
		save iv_`type'_`bench', replace
	}
}
