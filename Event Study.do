/********************* EVENT STUDY STOCK PRICE REACTIONS **********************/

/* Florian Miedema */
/* florianmiedema@hotmail.com */

/******************************************************************************/

clear

/* ssc install outreg2 */
/* h outreg2 */

/* Setting the Working Directory */
cd "C:\Users\flori\OneDrive\Documenten\Master Finance\Thesis\Data Files"

/* Setting the Estimation Window and the Event Window */ 
local EstWindStart = -180
local EstWindEnd = -5
local EventWindStart = 0
local EventWindEnd = 0
local Distance = `EventWindEnd' - `EstWindStart' + 1

/***************************** Return File ************************************/

/* Importing the Return File */
import delimited "return_file.csv", encoding(Big5)

/* Dropping the Unnecessary Variable */
drop v1

/* Transforming the Return Variable to a Numeric Variable*/
destring return, replace force

/* Temporarily Renaming the Date Variable */
rename date date2

/* Destringing the Date Variable */
gen date = date(date2, "YMD")
format date %td

/* Dropping the String Variable */ 
drop date2

/* Setting Up the Trading Dates */
bcal create trdates, from(date) maxgap(10) replace
replace date = bofd("trdates", date)
format date %tbtrdates

/* Setting the Panel Variable and Time Variable */
xtset firmid date

/* Saving the Return File */ 
tempfile returnfile
save `returnfile', replace

clear 

/**************************** Market File *************************************/

/* Importing the Market File */
import delimited "market_file.csv", encoding(Big5)

/* Temporarily Renaming the Date Variable */
rename date date2

/* Destringing the Date Variable */
gen date = date(date2, "DMY")
format date %td

/* Dropping the String Variable */ 
drop date2

/* Setting Up the Trading Dates */
bcal create trdates, from(date) maxgap(10) replace
replace date = bofd("trdates", date)
format date %tbtrdates

/* Renaming the Market Returns */
rename return mktr

/* Saving the Market File */ 
tempfile marketreturn
save `marketreturn', replace

/* Merging the Return File with the Market File */ 
use `returnfile'
merge m:1 date using `marketreturn'
drop _merge

/* Saving the combined file */ 
tempfile combinedfile
save `combinedfile', replace

clear

/***************************** Event File *************************************/

/* Setting up the Event File */ 
import delimited "event_file.csv", encoding(Big5)

/* Temporarily Renaming the Date Variable */
rename date date2

/* Destringing the Date Variable */
gen date = date(date2, "DMY")
format date %td

/* Dropping the String Variable */ 
drop date2

/* Considering the Weekends */ 
gen dow = dow(date)

replace date = date + 1 if dow == 0      
replace date = date + 2 if dow == 6   

drop dow

/* Setting the Event Dates */ 
rename date eventdate
replace eventdate = bofd("trdates", eventdate)
format eventdate %tbtrdates

/* Making an ID for Every Single Event */ 
egen eventid = group(eventdate firmid)

/* Saving the Event File */ 
tempfile eventdates
save `eventdates', replace

/* Creating the Tau */ 
expand `Distance'
bys eventid: gen int tau = _n + `EstWindStart' - 1
assert(tau <=`EventWindEnd')

gen date = eventdate + tau
format date %tbtrdates

/* Merging this file with the combined file */ 
merge m:1 firmid date using `combinedfile'
sort eventid tau
drop if _merge != 3
drop _merge

/* Creating the Normal Returns using the Market Model */ 
qui levelsof eventid, local(eid)
gen NR=.
foreach v in `eid'{
	capture qui reg return mktr if tau <= `EstWindEnd' & tau >= `EstWindStart' & eventid == `v'
	qui predict tmp if eventid == `v', xb
	qui replace NR = tmp if eventid == `v'
	drop tmp
}

/* Creating the Abnormal Returns */ 
gen AR = return - NR

/* Check if Everything Whent Well */ 
sum AR if tau <= `EstWindEnd'
assert(abs(`r(mean)')<0.00001)

/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid)
rename AR CAR

/* Running the Regression On the CARs */ 
reg CAR, vce(robust)
outreg2 using table1.doc, dec(2) replace

sum CAR, d

/* Restoring the Original Data */ 
restore

/*********************** Without outliers ***********************/
/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid)
rename AR CAR

/* Running the Regression On the CARs */ 
reg CAR if eventid != 47, vce(robust)
outreg2 using table1_exc_outliers.doc, dec(2) replace

sum CAR, d

/* Restoring the Original Data */ 
restore

/************************** Per Country *************************/

/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid country)
rename AR CAR

/* Creating Dummies for Each Country, and Taking Belgium as the Base Dummy */
tab country, gen(country_dummy)
drop country_dummy1

asdoc tab country, replace

/* Regressing CARs on the Country Dummies with Heteroscedasticity-
Robust Standard Errors */
reg CAR country_dummy*, vce(robust)

/* Restoring the Original Data */ 
restore

/*************************** Per Gender ***************************/
/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid gender)
rename AR CAR

/* Creating Dummies for Both Genders, and Taking Female as the Base Dummy */
tab gender, gen(gender_dummy)
drop gender_dummy1

asdoc tab gender, replace

/* Regressing CARs on the Gender Dummies with Heteroscedasticity-
Robust Standard Errors */
reg CAR gender_dummy*, vce(robust)

/* Restoring the Original Data */ 
restore

/*************************** Per Position *************************/
/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid position)
rename AR CAR

/* Creating Dummies for Each Position, and Taking Economy as the Base Dummy */
tab position, gen(position_dummy)
drop position_dummy1

asdoc tab position, replace

/* Regressing CARs on the Position Dummies with Heteroscedasticity-
Robust Standard Errors */
reg CAR position_dummy*, vce(robust)

/* Restoring the Original Data */ 
restore

/*************************** Per Industry *************************/
/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid industry)
rename AR CAR

/* Creating Dummies for Each Industry, and Taking Finance as the Base Dummy */
tab industry, gen(industry_dummy)
drop industry_dummy1

asdoc tab industry, replace

/* Regressing CARs on the Industry Dummies with Heteroscedasticity-
Robust Standard Errors */
reg CAR industry_dummy*, vce(robust)

/* Restoring the Original Data */ 
restore

/*************************** Per Period *************************/
/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid period)
rename AR CAR

/* Creating Dummies for Each Period, and Taking 1990s as the Base Dummy */
tab period, gen(period_dummy)
drop period_dummy1

asdoc tab period, replace

/* Regressing CARs on the Period Dummies with Heteroscedasticity-
Robust Standard Errors */
reg CAR period_dummy*, vce(robust)

/* Restoring the Original Data */ 
restore

/************************* Interaction dummy *************************/
/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid interaction)
rename AR CAR

/* Creating the Interaction Dummy, and Taking No Interaction as the Base Dummy */
tab interaction, gen(interaction_dummy)
drop interaction_dummy1

asdoc tab interaction, replace

/* Regressing CARs on the Interaction Dummies with Heteroscedasticity-
Robust Standard Errors */
reg CAR interaction_dummy*, vce(robust)

/* Restoring the Original Data */ 
restore

/****************** Computing Table 13 Seperately *********************/
/* Temporarely Drop the Estimation Window */ 
preserve
drop if tau <= `EstWindEnd'

/* Computing the CARs */ 
collapse (sum) AR, by(eventid firmid position industry)
rename AR CAR

/* Table 13 */
asdoc tabulate position industry, replace

/* Appendix 2 */ 
asdoc tabulate position industry, column row replace

/* Restoring the Original Data */ 
restore
