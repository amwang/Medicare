/***
hosp_mrkt_strct.do

do file for constructing hospital market structure variables and intermediaries:
	*HHI_pat_k_star
	*CAP_pat_k_star
	*hosp_char_h_pat_k_star
variables from Kessler and McClellan QJE May 2000, 588-591

last updated: 25May2011
author: Angela Wang amwang@stanford.edu

input:	analysis1.dta-analysis14.dta
		
output: master1.dta-master14.dta
		hosp_mrkt_zip.dta

***/

local size 100
local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/`size'/statanew

clear all
capture log close
set more off
set mem 10g
set matsize 11000
cd `path'

forval r=1/14 {

	use master`r', clear
	keep mprovno pzip phat_ij count
	preserve
	duplicates drop mprovno, force

	merge m:1 mprovno using aha_sysid, norep nogen keep(1 3)
	gen mprovno_sys=sysid
	replace mprovno_sys=mprovno if mprovno_sys==""
	
	gen hchar8 = (sysid~="")
	save tmp_hosp`r', replace
	
	restore
	*1. generate ahat_jk
	*a. numerator: collapse phat to zip and hospital level (var: pzip, mprovno, sum_phat_kj, count_kj)
	collapse (sum) sum_phat_kj=phat_ij (count) count_kj=count, by(pzip mprovno)
	save tmp_sum_phat_kj, replace
	*b. denominator: collapse 1a. to zip level (var: pzip, sum_phat_k, count_k)
	collapse (sum) sum_phat_k=sum_phat_kj (count) count_k=count_kj, by(pzip)
	save tmp_sum_phat_k, replace
	*c. calculate ahat_jk (zip-hospital level) (var: pzip, mprovno, sum_phat_kj, sum_phat_k, count_kj, count_k, ahat_jk, sq_ahat_jk)
	merge 1:m pzip using tmp_sum_phat_kj, nogen norep
	gen ahat_jk = sum_phat_kj/sum_phat_k
	gen sq_ahat_jk = ahat_jk^2
	save tmp_ahat_jk, replace
	
	*3. generate bhat_kj
	*a. denominator: collapse 1a. to hosp-level (var: sum_phat_j, count_j, mprovno)
	use tmp_sum_phat_kj, clear
	collapse (sum) sum_phat_j=sum_phat_kj (count) count_j=count_kj, by(mprovno)
	save tmp_sum_phat_j, replace
	*b. calculate bhat_kj (zip hospital level) (var: pzip, mprovno, sum_phat_kj, count_kj, sum_phat_j, count_j, bhat_kj)
	use tmp_sum_phat_kj, clear
	merge m:1 mprovno using tmp_sum_phat_j, nogen norep
	gen bhat_kj = sum_phat_kj/sum_phat_j
	save tmp_bhat_kj, replace
	
	*III. hosp_char_h_pat_k_star calculations
	use tmp_hosp`r', clear
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	save tmp_hosp`r'_ahat_jk, replace

	*1. calculate sum_ahat_jk_Z_`h'_j for each hospital characteristic
	forval h=8/8 {
		use tmp_hosp`r'_ahat_jk, clear
		*a. calculate ahat_jk_Z_`h'_j (zip hosptial level)
		rename hchar`h' Z_`h'_j
		gen ahat_jk_Z_`h'_j = ahat_jk*Z_`h'_j
		*b. calculate sum_ahat_jk_Z_h_j (zip level)
		collapse (sum) sum_ahat_jk_Z_`h'_j=ahat_jk*Z_`h'_j (count) count_k=count_kj, by(pzip)
		save tmp_sum_ahat_jk_Z_`h'_j, replace
		*c. merge all the new calculations to one file (zip level)
		save tmp_sum_ahat_jk_Z_j, replace
	}

	*2. calculate sum_bhat_kj_sum_ahat_jk_Z_`h'_j (hosp level)
	merge 1:m pzip using tmp_bhat_kj, keepusing(bhat_kj count_kj mprovno) nogen norep
	save tmp_hosp`r'_ahat_jk_bhat_kj, replace

	forval h=8/8 {
		use tmp_hosp`r'_ahat_jk_bhat_kj, clear
		*a. calculate bhat_kj_sum_ahat_jk_Z_`h'_j (zip hospital level)
		gen bhat_kj_sum_ahat_jk_Z_`h'_j = bhat_kj*sum_ahat_jk_Z_`h'_j
		*b. calculate sum_bhat_kj_sum_ahat_jk_Z_`h'_j (hosp level)
		collapse (sum) sum_bhat_kj_sum_ahat_jk_Z_`h'_j=bhat_kj_sum_ahat_jk_Z_`h'_j (count) count_j=count_kj, by(mprovno)
		save tmp_sum_bhat_kj_sum_ahat_jk_Z_`h'_j, replace
		*c. merge all the new calculations to one file (hosp level)
		save tmp_sum_bhat_kj_sum_ahat_jk_Z_j, replace
	}

	*3. calculate hosp_char_`h'_pat_k_star (zip level)
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	save tmp_hosp`r'_ahat_jk_bhat_kj_ahat_jk, replace

	forval h=8/8 {
		use tmp_hosp`r'_ahat_jk_bhat_kj_ahat_jk, clear
		*a. calculate hosp_char_`h'_pat_jk_star (zip hospital level)
		gen hosp_char_`h'_pat_jk_star = ahat_jk*sum_bhat_kj_sum_ahat_jk_Z_`h'_j
		*b. calculate hosp_char_`h'_pat_k_star (zip level)
		collapse (sum) hosp_char_`h'_pat_k_star=hosp_char_`h'_pat_jk_star (count) count_k=count_kj, by(pzip)
		save tmp_hosp_char_`h'_pat_k_star, replace
		*c. merge all the new calculations to one file (zip level)
		save tmp_hosp_char_pat_k_star, replace
	}
	
	**create zip-level market structure file
	use tmp_hosp_char_pat_k_star, clear
	keep pzip hosp_char_8_pat_k_star
	duplicates drop pzip, force
	if `r'==1 {
		save tmp_hosp_sys, replace
	}
	else {
		append using tmp_hosp_sys
		save tmp_hosp_sys, replace
	}
}

merge 1:1 zip using hosp_mrkt_zip, keepusing(hosp_char_8_pat_k_star)
save hosp_mrkt_zip, replace
shell rm -f tmp*
