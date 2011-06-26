/***
HHI_mprovno_sys.do

do file for constructing NEW HHI hospital market stucture variables and intermediaries that takes into account hospital systems
last updated: 23Jun2011
author: Angela Wang amwang@stanford.edu

input: 	aha_extract2008.dta
		master1.dta-master14.dta
		
output: HHI_mprovno_sys.dta

***/

local size 100
local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/`size'/statanew

clear all
capture log close
set more off
set mem 10g
set matsize 11000
cd `path'

use aha_extract2008, clear
drop id year
rename mcrnum mprovno
tostring(mprovno), replace format(%06.0f)
duplicates drop mprovno sysid, force
duplicates tag mprovno, gen(dup)
drop if dup==1 & sysid==""
drop if mprovno=="."
drop if mprovno=="313032"
compress
save aha_sysid, replace

forval r=1/14 {
	*load regression results into memory
	use master`r', clear
	keep mprovno pzip phat_ij count
	
	merge m:1 mprovno using aha_sysid, norep nogen keep(1 3)
	gen mprovno_sys=sysid
	replace mprovno_sys=mprovno if mprovno_sys==""
	
	expand count

	*1-1. generate ahat_jk
	*a. numerator: collapse phat to zip and hospital level (var: pzip, mprovno, sum_phat_kj, count_kj)
	preserve
	collapse (sum) sum_phat_kj=phat_ij, by(pzip mprovno)
	save tmp_sum_phat_kj, replace
	*b. denominator: collapse 1a. to zip level (var: pzip, sum_phat_k, count_k)
	collapse (sum) sum_phat_k=sum_phat_kj, by(pzip)
	save tmp_sum_phat_k, replace
	*c. calculate ahat_jk (zip-hospital level) (var: pzip, mprovno, sum_phat_kj, sum_phat_k, count_kj, count_k, ahat_jk, sq_ahat_jk)
	merge 1:m pzip using tmp_sum_phat_kj, nogen norep
	gen ahat_jk = sum_phat_kj/sum_phat_k
	save tmp_ahat_jk, replace

	*1-2. generate ahat_sys
	restore
	collapse (sum) sum_phat_kj2=phat_ij, by(pzip mprovno_sys)
	save tmp_sum_phat_kj_sys, replace
	*b. denominator: collapse 1a. to zip level (var: pzip, sum_phat_k, count_k)
	collapse (sum) sum_phat_k2=sum_phat_kj2, by(pzip)
	save tmp_sum_phat_k_sys, replace
	*c. calculate ahat_jk (zip-hospital level) (var: pzip, mprovno, sum_phat_kj, sum_phat_k, count_kj, count_k, ahat_jk, sq_ahat_jk)
	merge 1:m pzip using tmp_sum_phat_kj_sys, nogen norep
	gen ahat_sys = sum_phat_kj2/sum_phat_k2
	gen sq_ahat_sys = ahat_sys^2
	save tmp_ahat_sys, replace

	*2. generate HHI_pat_k using 1c. to zip-level (var: HHI_pat_k, count_k, pzip)
	collapse (sum) sum_sq_ahat_sys=sq_ahat_sys, by(pzip)
	rename sum_sq_ahat_sys HHI_pat_k
	save tmp_HHI_pat_k_sys, replace

	*3. generate bhat_kj
	*a. denominator: collapse 1a. to hosp-level (var: sum_phat_j, count_j, mprovno)
	use tmp_sum_phat_kj, clear
	collapse (sum) sum_phat_j=sum_phat_kj, by(mprovno)
	save tmp_sum_phat_j, replace
	*b. calculate bhat_kj (zip hospital level) (var: pzip, mprovno, sum_phat_kj, count_kj, sum_phat_j, count_j, bhat_kj)
	use tmp_sum_phat_kj, clear
	merge m:1 mprovno using tmp_sum_phat_j, nogen norep
	gen bhat_kj = sum_phat_kj/sum_phat_j
	save tmp_bhat_kj, replace

	*4. generate HHI_hosp_j (hosp level) (var: HHI_hosp_j, count_j, mprovno)
	merge m:1 pzip using tmp_HHI_pat_k_sys, nogen norep
	gen HHI_hosp_kj= bhat_kj*HHI_pat_k
	collapse (sum) HHI_hosp_j=HHI_hosp_kj, by(mprovno)
	save tmp_HHI_hosp_j_sys, replace

	*5. generate HHI_pat_k_star (zip-level) (var: HHI_pat_k_star, count_k, pzip)
	merge 1:m mprovno using tmp_ahat_jk, nogen norep
	gen HHI_pat_jk_star= ahat_jk*HHI_hosp_j
	collapse (sum) HHI_sys=HHI_pat_jk_star, by(pzip)
	save tmp_HHI_mprovno_sys, replace
	
	**create zip-level market structure file
	duplicates drop pzip, force
	if `r'==1 {
		save HHI_mprovno_sys, replace
	}
	else {
		append using HHI_mprovno_sys
		save HHI_mprovno_sys, replace
	}
}

shell rm -f tmp*
