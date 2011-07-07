/***
IV_bydischarge.do

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
log using "IV_bydischarge.log", replace

local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/100/statanew
cd `path'
local hcc p1_max-p177_max
local mrkt HHI_sys CAP_pat_k_star hosp_char*
local ages a7074 a7579 a8089 a9099 
local case female black fb
local age_x_case female_* black_* fb_*
local demo_ctrl `ages' `case' `age_x_case' `hcc'
local ma_hat_IV ma_hat ma_hat_HHI_sys ma_hat_CAP_pat_k_star ma_hat_hosp_char*
local ma_mrkt ma_HHI_sys ma_CAP_pat_k_star ma_hosp_char*
local dep_var lntotchrg lncost lnrevenue
local pos_var poschrg poscost posrev
local cont `mrkt' `ma_hat_IV' `ma_mrkt'
local dummy `demo_ctrl'
local cond0
local cond1 ma
local cond2 ma `ma_mrkt'
local iv1 ma = ma_hat
local iv2 ma `ma_mrkt' = `ma_hat_IV'

use iv_rcc_bydischarge, clear

drop ma_hat_hosp_char_3_pat_k_star ma_hosp_char_3_pat_k_star hosp_char_3_pat_k_star
drop ma_hat_hosp_char_6_pat_k_star ma_hosp_char_6_pat_k_star hosp_char_6_pat_k_star

gen charge0 = (totchrg==1)
gen cost0 = (cost==1)
gen rev0 = (revenue==1)
gen poschrg = (totchrg>1)
gen poscost = (cost>1)
gen posrev = (revenue>1)

capture erase "tpm_discharge.xml"
capture erase "tpm_ols_dis.ster"
capture erase "tpm_iv_dis.ster"

*OLS TPM
forval x=0/2 {
	foreach dep of varlist `dep_var' {
	reg `dep' `demo_ctrl' `mrkt' `cond`x'' [pw=weight] if poschrg==1, cluster(pzip)
	estimates save tpm_ols_dis, append
	outreg2 using tpm_discharge, excel ctitle(ols_tmp2_`dep'_cond`x')
	}
}

*IV TPM
forval x=1/2 {
	foreach dep of varlist `dep_var' {
	ivreg `dep' `demo_ctrl' `mrkt' (`iv`x'') [pw=weight] if poschrg==1, cluster(pzip)
	estimates save tpm_iv_dis, append
	outreg2 using tpm_discharge, excel ctitle(iv_tmp2_`dep'_cond`x')
	}
}

estpost sum
esttab using sum.rtf, cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(0)) max(fmt(0))") nomtitle nonumber append
estpost sum if poschrg==1
esttab using sum.rtf, cells("count(fmt(0)) mean(fmt(3)) sd(fmt(3)) min(fmt(1)) max(fmt(0))") nomtitle nonumber append