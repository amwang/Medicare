/**************
	  Compare the number of discharges for patients in TM & MA in each hospital in CA (OSHPD)
	  with the number of discharges calculated using our national data (CMS).
		  
	  Date: 07/13/2011
	  Author: Kunhee Kim  kunhee.kim@stanford.edu

	  input: hafd_ID_final.csv
	  		 oshpd-hafd2009-revcharge-ratio-7-11-11.csv
	  output: hafd_id.dta
	  		  new_hosp_cost.dta
	  		  rc_ratio_compare.log
**************/

log using medpar_oshpd_compare_discharge, replace text

cd "/Users/kunheekim/Documents/kessler/medicare/kunhee_hafd"

insheet using medpar_oshpd_discharge.csv, clear
gen mprov = string(mprovno)
replace mprov = "0"+ mprov if mprov !="."
drop mprovno
rename mprov mprovno
order mprovno, before(fac_no)
drop if mprovno==""|mprovno=="."
drop if ma==.
duplicates drop
save medpar_oshpd_discharge, replace

merge m:1 mprovno fac_no using new_hosp_cost, keep(3) nogen
keep mprovno fac_no ma tm ma_osh dis_mcar_tr dis_mcar_mc
destring dis_mcar_tr, replace
destring dis_mcar_mc, replace
gen diff_tm = tm - dis_mcar_tr
egen avg_tm = mean(diff_tm)
gen diff_ma = ma - dis_mcar_mc
egen avg_ma = mean(diff_ma)
di avg_tm
di avg_ma
summarize ma tm ma_osh dis_mcar_tr dis_mcar_mc, detail

log close
