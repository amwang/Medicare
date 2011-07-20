/**************
Merge the two data, medicare ID and revenue-charage ratio (rc_ratio_ca & rc_ratio_ca_rev), for each hospital in CA based on the fac_no variable. 

  	  Version 1: defines rc_ratio_ca as net patient revenue by only MA payers divided by 
	  gross revenue for only MA.)

  	  Version 2: defines rc_ratio_ca_rev as net patient revenue by all other payers 
	  except for TM divided by gross charges except for gross inpatient revenue by TM.)

	  Date: 07/11/2011
	  Author: Kunhee Kim  kunhee.kim@stanford.edu

	  input: hafd_ID_final.csv
	  		 oshpd-hafd2009-revcharge-ratio-ver2-7-12-11.csv
	  		 hosp_cost.dta
	  output: hafd_id.dta
	  	  new_hosp_cost.dta
	  	  rc_ratio_compare.log
**************/

log using rc_ratio_compare, replace text

cd "/Users/kunheekim/Documents/kessler/medicare/kunhee_hafd"


** Version 1 **

* Create data "hafd_id.dta" containing FAC_NO (hospital ID) and MPROVNO (medicare bene-ID)
insheet using hafd_ID_final.csv, clear
gen mprovno = string(mcar_pro_rev)
replace mprovno = "0"+mprovno if mprovno !="."
drop mcar_pro_rev
duplicates drop
sort fac_no
save hafd_id, replace

* Merge data containing CA hospitals' net revenue to charge ratio info with ID data above
insheet using oshpd-rc-ratio-ca.csv, clear
sort fac_no
merge 1:m fac_no using hafd_id, nogen
save new_hosp_cost, replace

* Merge CA hospital financial data created above with our existing national hospital-level financial data for comparison 
use new_hosp_cost, clear
drop if mprovno==""|mprovno=="."
duplicates drop mprovno, force
merge 1:m mprovno using hosp_costs, keep(3) nogen

/* rc_ratio_ca
	= (net patient revenue by only MA payers)/(gross revenue for only MA)
	= (Net Patient Revenue MA)/(Gross Inpatient Revenue MA + Gross
Outpatient Revenue MA).  */

keep mprovno fac_no npr rc_ratio_ca rc_ratio_ca_rev
destring rc_ratio_ca, replace i("#DIV!/")
recode rc_ratio_ca 0 = .
gen diff = rc_ratio_ca - npr
egen avg = mean(diff)
di avg
sum rc_ratio_ca npr
*save rc_ratio1_oshpd, replace

/*calculate net payment ratio(npr) and cost to charge ratio(ccr)
med_nt_pmt=sum(med_nt_pps,med_nt_tfr,med_nt_cst);
npr=(tot_nt_rev-med_nt_pmt)/(tot_gr_rev-med_ip_chg);
tot_cost=tot_cost_1+tot_cost_2;
ccr=tot_cost/tot_gr_rev;
*/


** Version 2 **

/* Create data "hafd_id.dta" containing FAC_NO (hospital ID) and MPROVNO (medicare bene-ID)
insheet using hafd_ID_final.csv, clear
gen mprovno = string(mcar_pro_rev)
replace mprovno = "0"+mprovno if mprovno !="."
drop mcar_pro_rev
duplicates drop
sort fac_no
save hafd_id, replace*/

/* Merge data containing CA hospitals' net revenue to charge ratio info with ID data above
insheet using oshpd-rc-ratio-ca.csv, clear
sort fac_no
merge 1:m fac_no using hafd_id, nogen
save new_hosp_cost_vers2, replace*/

/* Merge CA hospital financial data created above with our existing national hospital-level financial data for comparison 
drop if mprovno==""|mprovno=="."
duplicates drop mprovno, force
merge 1:m mprovno using hosp_costs, keep(3) nogen*/

/* rc_ratio_ca_rev 
	= net patient revenue by all other payers except
for TM)/(gross charges for TM)
	= (Net patient revenue by all other payers, including MA, except for
TM)/(gross inpatient revenue total - gross inpatient revenue by TM +
gross outpatient revenue total).  */

destring rc_ratio_ca_rev, replace i("#DIV!/")
recode rc_ratio_ca_rev 0 = .
gen diff2 = rc_ratio_ca_rev - npr
egen avg2 = mean(diff2)
di avg2
sum rc_ratio_ca_rev npr, detail
*save rc_ratio2_oshpd, replace

*merge m:m mprovno fac_no using rc_ratio1_oshpd, keep(3) nogen
order rc_ratio_ca, before(rc_ratio_ca_rev)
save rc_ratio_compare, replace


/*calculate net payment ratio(npr) and cost to charge ratio(ccr)
med_nt_pmt=sum(med_nt_pps,med_nt_tfr,med_nt_cst);
npr=(tot_nt_rev-med_nt_pmt)/(tot_gr_rev-med_ip_chg);
tot_cost=tot_cost_1+tot_cost_2;
ccr=tot_cost/tot_gr_rev;
*/

** Create a cost-to-charge ratio (CCR) for CA hospitals using OSHPD data **

use new_hosp_cost, clear
gen ccr = tot_cost/tot_charge
save new_hosp_cost, replace

log close
