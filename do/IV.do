/***
IV.do

do file for running first-pass IVs of MA choice on hospital market structure variables

last updated: 23Jun2011
author: Angela Wang amwang@stanford.edu

input: iv_rcc.dta
		
output: iv_rcc.ster

***/

clear all
capture log close
set more off
set mem 30g
set matsize 11000
pause on
log using "IV.log", replace

local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/
cd `path'
local hcc p1_max-p177_max
local mrkt HHI* CAP_pat_k_star hosp_char*
local ages a7074 a7579 a8089 a9099 
local case female black fb
local age_x_case female_* black_* fb_*
local demo_ctrl `ages' `case' `age_x_case' `hcc'
local ma_hat_IV ma_hat ma_hat_HHI* ma_hat_CAP_pat_k_star ma_hat_hosp_char*
local ma_mrkt ma_HHI* ma_CAP_pat_k_star ma_hosp_char*
local dep_var lntotchrg lncost lnrevenue
local pos_var poschrg poscost posrev
local cont `mrkt' `ma_hat_IV' `ma_mrkt'
local dummy `demo_ctrl'
local cond0
local cond1 ma
local cond2 ma `ma_mrkt'
local iv1 ma = ma_hat
local iv2 ma `ma_mrkt' = `ma_hat_IV'
local level byhicbic bydischarge
local benchmark b_minus_ffs b_div_ffs

/*
*first pass
foreach dep of varlist `dep_var' {
	ivreg `dep' `demo_ctrl' `mrkt' (ma `ma_mrkt' = `ma_hat_IV') [pw=weight], first cluster(pzip)
	estimates save iv_rcc, append

	reg `dep' `demo_ctrl' `mrkt', vce(cluster pzip) 
	estimates save iv_rcc, append
}


*TPM-1
foreach pos of varlist `pos_var' {
ivreg `pos' `demo_ctrl' `mrkt' (ma `ma_mrkt' = `ma_hat_IV') [pw=weight], cluster(pzip)
estimates save tpm, append
}
foreach dep of varlist `dep_var' {
ivreg `dep' `demo_ctrl' `mrkt' (ma `ma_mrkt' = `ma_hat_IV') [pw=weight] if poschrg==1, cluster(pzip)
estimates save tpm, append
}
*/

foreach type in `level' {
	*loop through both benchmarks
	foreach bench in `benchmark' {
		use probit0_by_discharge, clear
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
		save probit0_by_discharge_"`bench'", replace
		drop if ma_hat==.

		*generate the IVs
		foreach var of varlist `mrkt' {
			gen ma_hat_`var'=ma_hat*`var'
			gen ma_`var'=ma*`var'
		}
		
		*recode nonpositive expenditures to 0
		mvencode totchrg cost revenue, mv(0) override
		gen lntotchrg=ln(totchrg+1)
		gen lncost=ln(cost+1)
		gen lnrevenue=ln(revenue+1)
		save iv_by_discharge_"`bench'", replace
	}
}


foreach type in `level' {
	*loop through both benchmarks
	foreach bench in `benchmark' {
		di "`type'_`bench'"
		use iv_by_discharge_"`bench'", clear

		drop ma_hat_hosp_char_3_pat_k_star ma_hosp_char_3_pat_k_star hosp_char_3_pat_k_star
		drop ma_hat_hosp_char_6_pat_k_star ma_hosp_char_6_pat_k_star hosp_char_6_pat_k_star

		gen poschrg = (totchrg>0)
		gen poscost = (cost>0)
		gen posrev = (revenue>0)
		
		*OLS TPM
		forval x=0/2 {
			if by_discharge == "byhicbic" {
				reg poschrg `demo_ctrl' `mrkt' `cond`x'' [pw=weight], cluster(pzip)
				estimates save tpm2, append
				outreg2 using tpm2, excel ctitle(ols_tpm1_cond`x'_`bench'_`type')
			}

			foreach dep of varlist `dep_var' {
				reg `dep' `demo_ctrl' `mrkt' `cond`x'' [pw=weight] if poschrg==1, cluster(pzip)
				estimates save tpm2, append
				outreg2 using tpm2, excel ctitle(ols_tpm2_`dep'_cond`x'_`bench'_`type')
			}
			
			if by_discharge == "bydischarge" {
				gen price = cost/revenue
				reg price `demo_ctrl' `mrkt' `cond`x'' [pw=weight] if poschrg==1, cluster(pzip)
				estimates save tpm2, append
				outreg2 using tpm2, excel ctitle(ols_tpm2_price_cond`x'_`bench'_`type')
			}
			
		}
		
		*IV TPM
		forval x=1/2 {
			if by_discharge == "byhicbic" {
				ivreg poschrg `demo_ctrl' `mrkt' (`iv`x'') [pw=weight], cluster(pzip)
				estimates save tpm2, append
				outreg2 using tpm2, excel ctitle(iv_tpm1_cond`x'_`bench'_`type')
			}

			foreach dep of varlist `dep_var' {
				ivreg `dep' `demo_ctrl' `mrkt' (`iv`x'') [pw=weight] if poschrg==1, cluster(pzip)
				estimates save tpm2, append
				outreg2 using tpm2, excel ctitle(iv_tpm2_`dep'_cond`x'_`bench'_`type')
			}
			
			if by_discharge == "bydischarge" {
				ivreg price `demo_ctrl' `mrkt' (`iv`x'') [pw=weight] if poschrg==1, cluster(pzip)
				estimates save tpm2, append
				outreg2 using tpm2, excel ctitle(iv_tpm2_price_cond`x'_`bench'_`type')
			}
		}
	}
}

