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
local mrkt HHI_sys CAP_pat_k_star hosp_char*
local ages a7074 a7579 a8089 a9099 
local case female black fb
local age_x_case female_* black_* fb_*
local demo_ctrl `ages' `case' `age_x_case' `hcc'
local ma_hat_IV ma_hat ma_hat_HHI_sys ma_hat_CAP_pat_k_star ma_hat_hosp_char*
local ma_mrkt ma_HHI_sys ma_CAP_pat_k_star ma_hosp_char*
local dep_var lntotchrg lncost lnrevenue
local cont `mrkt' `ma_hat_IV' `ma_mrkt'
local dummy `demo_ctrl'

use iv_rcc, clear

drop ma_hat_hosp_char_3_pat_k_star ma_hosp_char_3_pat_k_star hosp_char_3_pat_k_star
drop ma_hat_hosp_char_6_pat_k_star ma_hosp_char_6_pat_k_star hosp_char_6_pat_k_star

gen charge0 = (totchrg==1)
gen posy = (totchrg>1)

/*
foreach dep of varlist `dep_var' {
ivreg `dep' `demo_ctrl' `mrkt' (ma `ma_mrkt' = `ma_hat_IV') [pw=weight], first cluster(pzip)
estimates save iv_rcc, append

reg `dep' `demo_ctrl' `mrkt', vce(cluster pzip) 
estimates save iv_rcc, append

}

foreach dep of varlist `dep_var' {
*Pr(totchrg>1)
ivreg `dep' `demo_ctrl' `mrkt' (ma `ma_mrkt' = `ma_hat_IV') [pw=weight] if totchrg>1, cluster(pzip)
estimates save iv_rcc, append
ivreg `dep' `demo_ctrl' `mrkt' charge0 (ma `ma_mrkt' = `ma_hat_IV') [pw=weight], cluster(pzip)
estimates save iv_rcc, append
}
*/

logit posy `demo_ctrl' `mrkt' ma `ma_mrkt' `ma_hat_IV' [pw=weight], cluster(pzip)
local rsqv = e(b)

ivreg `dep' `demo_ctrl' `mrkt' (ma `ma_mrkt' = `ma_hat_IV') [pw=weight] if totchrg>1, cluster(pzip)

*first define the program used to calculate marginal effects and bootstrap standard errors

capture program drop tpm_ols_mfx
program define tpm_ols_mfx, rclass

	preserve
	probit lntotexpgt0 $indv, robust
	mfx, var(lninc unins) at(median)
	sca prgt0 = e(Xmfx_y)
	mat mfx1 = e(Xmfx_dydx)
	mat mfx11 = mfx1["r1","lninc"]
	mat mfx12 = mfx1["r1","unins"]

	reg lntotexp $indv if lntotexp>0, robust
	mfx, var(lninc unins) at(median)
	sca ey = e(Xmfx_y)
	mat mfx2 = e(Xmfx_dydx)
	mat mfx21 = mfx2["r1","lninc"]
	mat mfx22 = mfx2["r1","unins"]

	mat t1 = (prgt0*mfx21)
	mat t2 = (ey*mfx11)
	return scalar m1 = t1[1,1] + t2[1,1]
	mat t1 = prgt0*mfx22
	mat t2 = ey*mfx12
	return scalar m2 = t1[1,1] + t2[1,1]
	restore

end

*end of program
