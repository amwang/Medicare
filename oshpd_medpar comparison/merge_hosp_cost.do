/**************
	 Merge the two data, medicare ID and revenue-charage ratio, for each hospital in CA
	 based on the fac_no variable. (VERSION 2)
	  
	  Date: 07/11/2011
	  Author: Kunhee Kim  kunhee.kim@stanford.edu

	  input: hafd_ID_final.csv
	  		 oshpd-hafd2009-revcharge-ratio-ver2-7-12-11.csv
	  output: merge_hafd.dta
**************/

log using rc_ratio_compare_ver2, replace text

cd "/Users/kunheekim/Dropbox/Kunhee/kunhee_hafd"

insheet using hafd_ID_final.csv, clear
gen mprovno = string(mcar_pro_rev)
replace mprovno = "0"+mprovno if mprovno !="."
drop mcar_pro_rev
duplicates drop
sort fac_no
save hafd_id, replace

insheet using oshpd-hafd2009-revcharge-ratio-ver2-7-12-11.csv, clear
sort fac_no
merge 1:m fac_no using hafd_id, nogen
save new_hosp_cost_vers2, replace

drop if mprovno==""|mprovno=="."
duplicates drop mprovno, force
merge 1:m mprovno using hosp_costs, keep(3) nogen
keep fac_no mprovno rc_ratio_ca npr_ccr_ratio 
destring rc_ratio_ca, replace i("#DIV!/")
recode rc_ratio_ca 0 = .
gen diff = rc_ratio_ca - npr_ccr_ratio
egen avg = mean(diff)
di avg
sum rc_ratio_ca npr_ccr
list fac_no mprovno rc_ratio_ca npr_ccr diff

/*calculate net payment ratio(npr) and cost to charge ratio(ccr)
med_nt_pmt=sum(med_nt_pps,med_nt_tfr,med_nt_cst);
npr=(tot_nt_rev-med_nt_pmt)/(tot_gr_rev-med_ip_chg);
tot_cost=tot_cost_1+tot_cost_2;
ccr=tot_cost/tot_gr_rev;
*/

log close
