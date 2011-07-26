/***
IV_CA.do

do file for using OSHPD-derived cost/charge/revenue data 

input:


output:

***/

clear all
capture log close
set mem 20g
set matsize 11000
local size 100
pause on

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
local dep_var lntotchrg lncost lnrevenue lnrevenue_CA1 lnrevenue_CA2
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

*** CA only discharge level regressions ***
/*use base, clear
keep if pzip>=90001 & pzip<=96162
cd ca
save base_ca, replace*/

cd `path'
use rcc_bydischarge, clear
cd ca
merge m:1 hicbic ma using base_ca, keep(3) nogen
keep if substr(mprovno,1,2)=="05"

merge m:1 mprovno using npr_CA, keep(1 3) keepusing(npr1 npr2)
save tmp, replace
count if npr1==.|npr2==.
keep if npr1!=. & npr2!=.

gen revenue_CA1 = npr1*totchrg
gen revenue_CA2 = npr2*totchrg
gen price_CA1=revenue_CA1/cost
gen price_CA2=revenue_CA2/cost
drop npr1 npr2
preserve
drop if _merge==1
save probit0_bydischarge_ca, replace

*** CA only hicbic level regressions ***
restore 
collapse (sum) cost totchrg revenue revenue_CA1 revenue_CA2, by(hicbic ma)
merge 1:1 hicbic ma using base_ca, keep(3) nogen
save probit0_byhicbic_ca, replace

*** zero-stage regressions ***
foreach type in `level' {
	*loop through both benchmarks
	foreach bench in `benchmark' {
		use probit0_`type'_ca, clear
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
		predict ma_hat
		drop if ma_hat==.

		*generate the IVs
		foreach var of varlist `mrkt' {
			gen ma_hat_`var'=ma_hat*`var'
			gen ma_`var'=ma*`var'
		}
		
		*recode nonpositive expenditures to 0
		mvencode totchrg cost revenue revenue_CA1 revenue_CA2, mv(0) override
		gen lntotchrg=ln(totchrg+1)
		gen lncost=ln(cost+1)
		gen lnrevenue=ln(revenue+1)
		gen lnrevenue_CA1=ln(revenue_CA1+1)
		gen lnrevenue_CA2=ln(revenue_CA2+1)
		save iv_`type'_`bench'_ca, replace
	}
}

/*
*** two-part models ***
*** by hicbic ***
*loop through both benchmarks
foreach bench in "b_minus_ffs" "b_div_ffs" {
	di "byhicbic_`bench'"
	use iv_byhicbic_`bench', clear

	drop ma_hat_hosp_char_3_pat_k_star ma_hosp_char_3_pat_k_star hosp_char_3_pat_k_star
	drop ma_hat_hosp_char_6_pat_k_star ma_hosp_char_6_pat_k_star hosp_char_6_pat_k_star

	gen poschrg = (totchrg>0)
	gen poscost = (cost>0)
	gen posrev = (revenue>0)
	
	*OLS TPM
	forval x=0/2 {
		
		reg poschrg `demo_ctrl' `mrkt' `cond`x'' [pw=weight], cluster(pzip)
		estimates save tpm2, append
		outreg2 using tpm2, excel ctitle(ols_tpm1_cond`x'_`bench'_byhicbic)
		
		foreach dep of varlist `dep_var' {
			reg `dep' `demo_ctrl' `mrkt' `cond`x'' [pw=weight] if poschrg==1, cluster(pzip)
			estimates save tpm2, append
			outreg2 using tpm2, excel ctitle(ols_tpm2_`dep'_cond`x'_`bench'_byhicbic)
		}
	}
	
	*IV TPM
	forval x=1/2 {
		
		ivreg poschrg `demo_ctrl' `mrkt' (`iv`x'') [pw=weight], cluster(pzip)
		estimates save tpm2, append
		outreg2 using tpm2, excel ctitle(iv_tpm1_cond`x'_`bench'_byhicbic)
		
		foreach dep of varlist `dep_var' {
			ivreg `dep' `demo_ctrl' `mrkt' (`iv`x'') [pw=weight] if poschrg==1, cluster(pzip)
			estimates save tpm2, append
			outreg2 using tpm2, excel ctitle(iv_tpm2_`dep'_cond`x'_`bench'_byhicbic)
		}
	}
}

*** by discharge ***
foreach bench in "b_minus_ffs" "b_div_ffs" {
	di "bydischarge_`bench'"
	use iv_bydischarge_`bench', clear

	drop ma_hat_hosp_char_3_pat_k_star ma_hosp_char_3_pat_k_star hosp_char_3_pat_k_star
	drop ma_hat_hosp_char_6_pat_k_star ma_hosp_char_6_pat_k_star hosp_char_6_pat_k_star

	gen poschrg = (totchrg>0)
	gen poscost = (cost>0)
	gen posrev = (revenue>0)
	
	*OLS TPM
	forval x=0/2 {
		foreach dep of varlist `dep_var' {
			reg `dep' `demo_ctrl' `mrkt' `cond`x'' [pw=weight] if poschrg==1, cluster(pzip)
			estimates save tpm2, append
			outreg2 using tpm2, excel ctitle(ols_tpm2_`dep'_cond`x'_`bench'_bydischarge)
		}
			
			reg price `demo_ctrl' `mrkt' `cond`x'' [pw=weight] if poschrg==1, cluster(pzip)
			estimates save tpm2, append
			outreg2 using tpm2, excel ctitle(ols_tpm2_price_cond`x'_`bench'_bydischarge)
		
	}
	
	*IV TPM
	forval x=1/2 {
		foreach dep of varlist `dep_var' {
			ivreg `dep' `demo_ctrl' `mrkt' (`iv`x'') [pw=weight] if poschrg==1, cluster(pzip)
			estimates save tpm2, append
			outreg2 using tpm2, excel ctitle(iv_tpm2_`dep'_cond`x'_`bench'_bydischarge)
		}
		
			ivreg price `demo_ctrl' `mrkt' (`iv`x'') [pw=weight] if poschrg==1, cluster(pzip)
			estimates save tpm2, append
			outreg2 using tpm2, excel ctitle(iv_tpm2_price_cond`x'_`bench'_bydischarge)
	}
}
*/
