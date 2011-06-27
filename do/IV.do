/***
IV.do

do file for running first-pass IVs of MA choice on hospital market structure variables.

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
local mrkt HHI_sys CAP_pat_k_star hosp_char*
local ages a7074 a7579 a8089 a9099 
local case female black fb
local age_x_case female_* black_* fb_*
local demo_ctrl `ages' `case' `age_x_case' `hcc'
local ma_hat_IV ma_hat ma_hat_HHI_sys ma_hat_CAP_pat_k_star ma_hat_hosp_char*
local ma_mrkt ma_HHI_sys ma_CAP_pat_k_star ma_hosp_char*
local dep_var lntotchrg lncost lnrevenue

use iv_rcc, clear

drop ma_hat_hosp_char_3_pat_k_star ma_hosp_char_3_pat_k_star hosp_char_3_pat_k_star
drop ma_hat_hosp_char_6_pat_k_star ma_hosp_char_6_pat_k_star hosp_char_6_pat_k_star

foreach dep of varlist `dep_var' {
ivreg `dep' `demo_ctrl' `mrkt' (ma `ma_mrkt' = `ma_hat_IV') [pw=weight], first vce(cluster pzip)
estimates save iv_rcc, append

reg `dep' `demo_ctrl' `mrkt', vce(cluster zip5)
estimates save iv_rcc, append

}
