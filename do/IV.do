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
set mem 40g
set matsize 11000
pause on
log using "IV.log", replace

local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew
cd `path'
local hcc p1_max-p177_max
local mrkt HHI* CAP_pat_k_star hosp_char*
local ages a7074 a7579 a8089 a9099 
local case female black fb
local age_x_case female_* black_* fb_*
local demo_ctrl `ages' `case' `age_x_case' `hcc'
local ma_hat_IV ma_hat ma_hat_HHI* ma_hat_CAP_pat_k_star ma_hat_hosp_char*
local ma_mrkt ma_HHI* ma_CAP_pat_k_star ma_hosp_char*
local dep_var lntotchrg lncost lnrevenue price
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
	foreach bench in `benchmark' {
		use iv_`type'_`bench', clear

		drop ma_hat_hosp_char_3_pat_k_star ma_hosp_char_3_pat_k_star hosp_char_3_pat_k_star
		drop ma_hat_hosp_char_6_pat_k_star ma_hosp_char_6_pat_k_star hosp_char_6_pat_k_star

		gen poschrg = (totchrg>0)
		gen poscost = (cost>0)
		gen posrev = (revenue>0)
		
		*OLS TPM
		forval x=0/2 {
			if `type'=="byhicbic" {
				reg poschrg `demo_ctrl' `mrkt' `cond`x'' [pw=weight], cluster(pzip)
				estimates save tpm_ols, append
				outreg2 using tpm, excel ctitle(ols_tmp1_cond`x')
			}

			foreach dep of varlist `dep_var' {
				reg `dep' `demo_ctrl' `mrkt' `cond`x'' [pw=weight] if poschrg==1, cluster(pzip)
				estimates save tpm_ols, append
				outreg2 using tpm, excel ctitle(ols_tmp2_`dep'_cond`x')
			}
		}
		
		*IV TPM
		forval x=1/2 {
			if `type'=="byhicbic" {
				ivreg poschrg `demo_ctrl' `mrkt' (`iv`x'') [pw=weight], cluster(pzip)
				estimates save tpm_iv, append
				outreg2 using tpm, excel ctitle(iv_tmp1_cond`x')
			}

			foreach dep of varlist `dep_var' {
				ivreg `dep' `demo_ctrl' `mrkt' (`iv`x'') [pw=weight] if poschrg==1, cluster(pzip)
				estimates save tpm_iv, append
				outreg2 using tpm, excel ctitle(iv_tmp2_`dep'_cond`x')
			}
		}
	}
}

