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

local path /disk/agedisk2/medicare.work/kessler-DUA16444/wanga/analysis_stata/

clear all
capture log close
set more off
set mem 10g
set matsize 11000
cd `path'

forval r=1/14 {
	*create hospital-level dataset to merge in bed number
	use analysis`r', clear
	duplicates drop mprovno, force
	keep mprovno hchar* beds
	save tmp_hosp`r', replace
	desc

	*load regression results into memory
	est use analysis, number(`r')
	use analysis`r', clear

	*create phat: probability of a positive outcome
	predict phat_ij, pc1

	keep mprovno pzip phat_ij count
	compress
	expand count

	*begin hospital market structure variable calculations
	*I. HHI_pat_k_star calculation
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

	*2. generate HHI_pat_k using 1c. to zip-level (var: HHI_pat_k, count_k, pzip)
	collapse (sum) sum_sq_ahat_k=sq_ahat_jk (count) count_k=count_kj, by(pzip)
	rename sum_sq_ahat_k HHI_pat_k
	save tmp_HHI_pat_k, replace

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

	*4. generate HHI_hosp_j (hosp level) (var: HHI_hosp_j, count_j, mprovno)
	merge m:1 pzip using tmp_HHI_pat_k, nogen norep
	gen HHI_hosp_kj= bhat_kj*HHI_pat_k
	collapse (sum) HHI_hosp_j=HHI_hosp_kj (count) count_j=count_kj, by(mprovno)
	save tmp_HHI_hosp_j, replace

	*5. generate HHI_pat_k_star (zip-level) (var: HHI_pat_k_star, count_k, pzip)
	merge 1:m mprovno using tmp_ahat_jk, nogen norep
	gen HHI_pat_jk_star= ahat_jk*HHI_hosp_j
	collapse (sum) HHI_pat_k_star=HHI_pat_jk_star (count) count_k=count_kj, by(pzip)
	save tmp_HHI_pat_k_star, replace


	*II. CAP_pat_k_star calculations
	*1. generate CAP_pat_k (zip level) (var: CAP_pat_k, count_k, pzip)
	use tmp_hosp`r', clear
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk sum_phat_kj count_kj pzip) nogen norep
	gen CAP_pat_jk= ahat_jk*beds/sum_phat_kj
	collapse (sum) CAP_pat_k=CAP_pat_jk (count) count_k=count_kj, by(pzip)
	save tmp_CAP_pat_k, replace

	*2. generate CAP_pat_k_star 
	*a. calculate sum_bhat_kj_CAP_pat_k (hosp level) (var: sum_bhat_kj_CAP_pat_k, count_j, mprovno)
	merge 1:m pzip using tmp_bhat_kj, keepusing(bhat_kj count_kj mprovno) nogen norep
	gen bhat_kj_CAP_pat_k= bhat_kj*CAP_pat_k
	collapse (sum) sum_bhat_kj_CAP_pat_k=bhat_kj_CAP_pat_k (count) count_j=count_kj, by(mprovno)
	save tmp_sum_bhat_kj_CAP_pat_k, replace
	*b. calculate CAP_pat_k_star (zip level) (var: CAP_pat_k_star, count_k, pzip)
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	gen ahat_jk_sum_bhat_kj_CAP_pat_k = ahat_jk*sum_bhat_kj_CAP_pat_k
	rename ahat_jk_sum_bhat_kj_CAP_pat_k CAP_pat_jk_star
	collapse (sum) CAP_pat_k_star=CAP_pat_jk_star (count) count_k=count_kj, by(pzip)
	save tmp_CAP_pat_k_star, replace

	*III. hosp_char_h_pat_k_star calculations
	use tmp_hosp`r', clear
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	save tmp_hosp`r'_ahat_jk, replace

	*1. calculate sum_ahat_jk_Z_`h'_j for each hospital characteristic
	forval h=1/8 {
		use tmp_hosp`r'_ahat_jk, clear
		*a. calculate ahat_jk_Z_`h'_j (zip hosptial level)
		rename hchar`h' Z_`h'_j
		gen ahat_jk_Z_`h'_j = ahat_jk*Z_`h'_j
		*b. calculate sum_ahat_jk_Z_h_j (zip level)
		collapse (sum) sum_ahat_jk_Z_`h'_j=ahat_jk*Z_`h'_j (count) count_k=count_kj, by(pzip)
		save tmp_sum_ahat_jk_Z_`h'_j, replace
		*c. merge all the new calculations to one file (zip level)
		if `h'==1 {
			save tmp_sum_ahat_jk_Z_j, replace
		}
		else {
			use tmp_sum_ahat_jk_Z_j, clear
			merge 1:1 pzip using tmp_sum_ahat_jk_Z_`h'_j, keepusing(sum_ahat_jk_Z_`h'_j) nogen norep
			save, replace
		}
	}

	*2. calculate sum_bhat_kj_sum_ahat_jk_Z_`h'_j (hosp level)
	merge 1:m pzip using tmp_bhat_kj, keepusing(bhat_kj count_kj mprovno) nogen norep
	save tmp_hosp`r'_ahat_jk_bhat_kj, replace

	forval h=1/8 {
		use tmp_hosp`r'_ahat_jk_bhat_kj, clear
		*a. calculate bhat_kj_sum_ahat_jk_Z_`h'_j (zip hospital level)
		gen bhat_kj_sum_ahat_jk_Z_`h'_j = bhat_kj*sum_ahat_jk_Z_`h'_j
		*b. calculate sum_bhat_kj_sum_ahat_jk_Z_`h'_j (hosp level)
		collapse (sum) sum_bhat_kj_sum_ahat_jk_Z_`h'_j=bhat_kj_sum_ahat_jk_Z_`h'_j (count) count_j=count_kj, by(mprovno)
		save tmp_sum_bhat_kj_sum_ahat_jk_Z_`h'_j, replace
		*c. merge all the new calculations to one file (hosp level)
		if `h'==1 {
			save tmp_sum_bhat_kj_sum_ahat_jk_Z_j, replace
		}
		else {
			use tmp_sum_bhat_kj_sum_ahat_jk_Z_j, clear
			merge 1:1 mprovno using tmp_sum_bhat_kj_sum_ahat_jk_Z_`h'_j, keepusing(sum_bhat_kj_sum_ahat_jk_Z_`h'_j) nogen norep
			save, replace
		}
	}

	*3. calculate hosp_char_`h'_pat_k_star (zip level)
	merge 1:m mprovno using tmp_ahat_jk, keepusing(ahat_jk count_kj pzip) nogen norep
	save tmp_hosp`r'_ahat_jk_bhat_kj_ahat_jk, replace

	forval h=1/8 {
		use tmp_hosp`r'_ahat_jk_bhat_kj_ahat_jk, clear
		*a. calculate hosp_char_`h'_pat_jk_star (zip hospital level)
		gen hosp_char_`h'_pat_jk_star = ahat_jk*sum_bhat_kj_sum_ahat_jk_Z_`h'_j
		*b. calculate hosp_char_`h'_pat_k_star (zip level)
		collapse (sum) hosp_char_`h'_pat_k_star=hosp_char_`h'_pat_jk_star (count) count_k=count_kj, by(pzip)
		save tmp_hosp_char_`h'_pat_k_star, replace
		*c. merge all the new calculations to one file (zip level)
		if `h'==1 {
			save tmp_hosp_char_pat_k_star, replace
		}
		else {
			use tmp_hosp_char_pat_k_star, clear
			merge 1:1 pzip using tmp_hosp_char_`h'_pat_k_star, keepusing(hosp_char_`h'_pat_k_star) nogen norep
			save, replace
		}
	}

	**create master file with all calculated variables
/*	restore
	merge m:1 pzip mprovno using tmp_ahat_jk, keepusing(sum_phat_kj sum_phat_k count_kj count_k ahat_jk sq_ahat_jk) nogen norep
	merge m:1 pzip mprovno using tmp_bhat_kj, keepusing(sum_phat_j count_j bhat_kj) nogen norep
	merge m:1 pzip using tmp_HHI_pat_k, keepusing(HHI_pat_k) nogen norep
	merge m:1 pzip using tmp_HHI_pat_k_star, keepusing(HHI_pat_k_star) nogen norep
	merge m:1 pzip using tmp_CAP_pat_k_star, keepusing(CAP_pat_k_star) nogen norep
	merge m:1 pzip using tmp_hosp_char_pat_k_star, keepusing(hosp_char*) nogen norep
	merge m:1 mprovno using tmp_HHI_hosp_j, keepusing(HHI_hosp_j) nogen norep
	compress
	save master`r', replace*/
	
	**create zip-level market structure file
	use tmp_HHI_pat_k_star, clear
	merge 1:1 pzip using tmp_CAP_pat_k_star, keepusing(CAP_pat_k_star) nogen
	merge 1:1 pzip using tmp_hosp_char_pat_k_star, keepusing(hosp_char*) nogen
	keep pzip HHI_pat_k_star CAP_pat_k_star hosp_char*
	if `r'==1 {
		save hosp_mrkt_zip, replace
	}
	else {
		append using hosp_mrkt_zip
		save hosp_mrkt_zip, replace
	}
}

shell rm -f tmp*
