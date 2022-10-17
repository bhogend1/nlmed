* load program
capture program drop nlmed
program define nlmed, eclass properties(mi) byable(recall)
version 13.0
syntax anything [if] [in] [fweight iweight pweight], ///
Decompose(varname numeric) Mediators(varlist numeric min=1) [Family(passthru) LInk(passthru) CONComitants(varlist fv ts) CONFounders(varlist numeric) DISentangle RELiability(string asis) CONStraints(passthru) showcmd vce(string) Level(cilevel) patha pathb NOHEADer NOTABle NOIsily MIdefault MIopts(string) from(string) outmat(string) postsem fast *]


* input
// parse
local nanything : word count `anything'
if `nanything'==1 {
	local depvar `anything'
}
else if `nanything'==2 {
	gettoken model depvar : anything
}
else if `nanything'>2 {
	di as error "There should be one {it:model-type} and one {it:depvar}."
	exit
}
local depvar=strtrim("`depvar'")

// check if dependent variable was provided
capture confirm numeric variable `depvar'
if _rc!=0 {
	di as error "{it:Depvar} should be a numeric variable."
	exit
}

// check if model was provided
if "`model'"=="" {
	if "`family'"=="" & "`link'"=="" {
		di as error "You did not specify a {it:model-type}."
		exit
	}
	else {
		local model "`family' `link'"
	}
}
else {
	if "`family'"!="" | "`link'"!="" {
		di as error "Options family() and link() will be ignored, using gsem defaults for {bf:`model'} instead."
	}
}

// check if variance estimator supported
if "`vce'"!="" {
	gettoken vcetype vceopts : vce
	if "`vcetype'"!="oim" & "`vcetype'"!="opg" & "`vcetype'"!="robust" & "`vcetype'"!="cluster" & "`vcetype'"!="bootstrap" & "`vcetype'"!="bs" {
		di as error "Variance estimator should be oim, robust, cluster, or bootstrap."
		exit
	}
	if "`vcetype'"=="oim" | "`vcetype'"=="opg" | "`vcetype'"=="robust" {
		local vce "vce(`vcetype')"
	}
	if "`vcetype'"=="cluster" {
		capture confirm numeric variable `vceopts'
		if _rc!=0 {
			capture confirm string variable `vceopts'
			if _rc!=0 {
				di as error "Clustvar should be string or numeric."
				exit
			}
		}
		local vce "vce(cluster`vceopts')"		
		local clustvar `vceopts'
	}
	if "`vcetype'"=="bootstrap" | "`vcetype'"=="bs" {
		if "`reliability'"!="" {
			di as error "Bootstrap cannot be combined with reliability corrections."
			exit
		}
		if "`weight'"!="" {
			di as error "Bootstrap cannot be combined with weights."
			exit
		}
		if "`midefault'"!="" | "`miopts'"!="" {
			di as error "Bootstrap cannot be combined with multiple imputation. You might try the bootstrap prefix."
			exit
		}
		local vce
		local bsprefix "bootstrap, force`vceopts': "
	}
}
else {
	local vce "vce(oim)"
}
if ("`vce'"=="vce(oim)" | "`vce'"=="vce(opg)") & "`weight'"=="pweight" {
	di as error "`vce' cannot be combined with pweights. Choose vce(robust) or vce(cluster {it:clustvar}) instead."
	exit
}

// check if reliability variables are a subsample of the mediators
if "`reliability'"!="" {
	local nreliability : word count `reliability'
	local relvars
	local relvalues
	local medcomma=subinstr("`mediators'"," ",`"",""',.)
	local medapos `""`medcomma'""'
	forvalues i = 1(2)`nreliability' {
		local x : word `i' of `reliability'
		local relapos `""`x'""'
		if inlist(`relapos', `medapos')==0 {
			di as error "Not all variables specified in reliability() are mediators."
			exit
		}
		local j = `i'+1
		local value : word `j' of `reliability'
		capture confirm number `value'
		if _rc!=0 {
			di as error "Not all variables specified in reliability() have a reliability value assigned."
			exit
		}	
		local relvars "`relvars' `x'"	
	}
	local reliability "reliability(`reliability')"
}

// check if constraints exist and parse
if "`constraints'"!="" {
	local constr_numlist = substr("`constraints'",13,length("`constraints'")-13)
	numlist "`constr_numlist'", integer range(>0)
	local constr_numlist `r(numlist)'
	foreach x in `constr_numlist' {
		constraint get `x'
		if r(defined)==0 {
			di as error "Constraint `x' has not been defined and will be ignored."
		}
	}
}

// check if disentangle is used with confounders
if "`disentangle'"!="" {
	if "`confounders'"=="" {
		di as error "Requested disentangle() without specifying confounders(). Option disentangle will be ignored."
	}
}

// check that postsem is not requested with additional output
if "`postsem'"!="" {
	if "`disentangle'"!="" | "`patha'"!="" | "`pathb'"!="" {
		di as error "Requested postsem() along with effect decomposition output. Options disentangle, patha, and pathb will be ignored."
	}
}

// check content startvalue vector
if "`from'"!="" {
	capture confirm matrix `from'
	if _rc!=0 {
		local from
		di as text "Note: matrix provided in from() does not exist and will be ignored."
	}
	else if colsof(`from')==1 & rowsof(`from')==1 & `from'[1,1]==. {
		local from
		di as text "Note: matrix provided in from() is empty and will be ignored."
	}
	else {
		local from "from(`from', skip)"
	}
}

// check variable length
foreach x in `depvar' `decompose' `mediators' `confounders' `concomitants' `relvars' {
    if strlen("`x'")>25 {
	    di as error "Variable name `x' is longer than 25 characters. Depending on the specified options, this might cause an error."
	}
}

// local: weight
if "`weight'"!="" {
	local weightexpr "[`weight'`exp']"
}

// local: noisily
local disoutput quietly
if "`noisily'"!="" {
	local disoutput
}

// local: noheader
if "`noheader'"!="" {
	local disheader quietly
}

// local: notable
if "`notable'"!="" {
	local distable quietly
}

// local: miprefix
if "`midefault'"!="" {
    local miprefix "mi estimate, cmdok post: "
}
if "`miopts'"!="" {
	local miprefix "mi estimate, cmdok `miopts' post: "
}


* mark the sample
// preserve original data
preserve

// mi data should be flong for correct marking
if "`miprefix'"!="" {
	if "`_dta[_mi_style]'"!="flong" {
		quietly mi convert flong, clear noupdate
	}
}
marksample touse
markout `touse' `depvar' `decompose' `mediators' `confounders' `concomitants' `relvars' `clustvar', strok
if "`'miprefix'"!="" {
	quietly keep if `touse' | _mi_m==0
}
else {
	quietly keep if `touse'
}


* set mediating paths
local nmediators : word count `mediators'
local pathvars `mediators' `confounders'
local npathvars : word count `pathvars'
local firstpaths "( `pathvars' <- `decompose' `concomitants', regress)"
local lastpath "( `depvar' <- `decompose' `pathvars' `concomitants', `model')"
local addpaths


* set model paths with reliability corrections
if "`reliability'"!="" {

	// include latent variables
	foreach x of varlist `relvars' {
		local upper = strupper("`x'")
		capture drop `upper'_LATENT
		quietly gen `upper'_LATENT = `x'
		local addpaths "`addpaths' ( `x' <- `upper'_LATENT@1, regress)"
		local firstpaths=subinword("`firstpaths'","`x'","`upper'_LATENT",.)
		local lastpath=subinword("`lastpath'","`x'","`upper'_LATENT",.)
		
		// redefine the constraints that contain latent variables
		if "`constraints'"!="" {
			foreach y in `constr_numlist' {
				constraint get `y'
				if strpos("`r(contents)'","`x'")>0 {
					constraint define `y' `=subinstr("`r(contents)'","`x'","`upper'_LATENT",.)'
				}
			}
		}
	}
}


* show estimation command if requested
if "`showcmd'"!="" {
	di as text _newline "Stata command: "
	if "`reliability'"!="" {
		di as result _newline "foreach x of varlist`relvars' {"
		di as result "	local upper = strupper(" `"""' "`" "x" "'" `"""' ")"
		di as result "	gen " "`" "upper" "'" "_LATENT = " "`" "x" "'"
		di as result "}"
		if "`constraints'"!="" {
		di _newline(0)
			foreach x of varlist `relvars' {
				local upper = strupper("`x'")
				foreach y in `constr_numlist' {
					constraint get `y'
					if strpos("`r(contents)'","`upper'")>0 {
						di as result "constraint define `y' `r(contents)'"
					}
				}
			}
		}
	}	
	di as result _newline "`miprefix'`bsprefix'gsem "
	di as result " `firstpaths' "
	di as result " `lastpath' "
	if "`reliability'"!="" {
		di as result "`addpaths' "
	}
	di as result " `if' `in' `weightexpr', listwise `reliability' `vce' `constraints' `from' `options'"
	exit
}


* estimate the model
// obtain starting values, if none given
if "`from'"=="" {
	tempname startvals
	
	if "`miprefix'"!="" {
		quietly snapshot save
		local snapnumber = r(snapshot)
		mi extract 0, clear
	}
	
	if "`reliability'"!="" {
		local x_addpaths=subinstr("`addpaths'",", regress"," ",.)
		local x_firstpaths=subinstr("`firstpaths'",", regress"," ",.)
		local x_lastpath=subinstr("`lastpath'",", `model'"," ",.)
		`disoutput' di _newline
		di as text "obtain starting values..." _cont
		`disoutput' sem `x_lastpath' `x_addpaths' `x_firstpaths' `weightexpr', nocnsreport nodescribe noheader nofootnote `reliability' `constraints' `options'
		matrix define `startvals' = e(b)
		`disoutput' gsem `lastpath' `addpaths' `weightexpr', listwise nocnsreport noheader nodvheader `reliability' `constraints' from(`startvals', skip) `options'
		matrix define `startvals' = e(b)
		local from "from(`startvals', skip)"
	}
	else {
		`disoutput' di _newline
		di as text "obtain starting values..." _cont
		`disoutput' gsem `lastpath' `weightexpr', listwise nocnsreport noheader nodvheader `constraints' `options'
		matrix define `startvals' = e(b)
		local from "from(`startvals', skip)"
	}
	
	if "`miprefix'"!="" {
		snapshot restore `snapnumber'
		snapshot erase `snapnumber'
	}
}

// estimate
`disoutput' di _newline
di as text "estimate structural equation model..." _cont
`disoutput' `miprefix' `bsprefix' gsem `lastpath' `firstpaths' `addpaths' `weightexpr', listwise `reliability' `vce' `constraints' `from' `options'

// return coefficient vector if requested
if "`outmat'"!="" {
	matrix `outmat' = e(b)
}

// terminate here if only SEM output requested
if "`postsem'"!="" {
	exit
}

// save VCE information for final output
local vce = e(vce)
local vcetype = e(vcetype)
local clustvar = e(clustvar)
local family = e(family1)
local link = e(link1)
local ll = e(ll)


* path A
if "`patha'"!="" {
	tempname b_patha V_patha
	matrix define `b_patha' = J(1,`nmediators',0)
	matrix define `V_patha' = J(`nmediators',`nmediators',0)
	forvalues i = 1/`nmediators' {
		local x : word `i' of `mediators'
		matrix `b_patha'[1,`i'] 	= _b[`x':`decompose']
		matrix `V_patha'[`i',`i'] 	= (_se[`x':`decompose'])^2
	}
}

* path B
if "`pathb'"!="" {
	tempname b_pathb V_pathb
	matrix define `b_pathb' = J(1,`nmediators',0)
	matrix define `V_pathb' = J(`nmediators',`nmediators',0)
	forvalues i = 1/`nmediators' {
		local x : word `i' of `mediators'
		matrix `b_pathb'[1,`i'] 	= _b[`depvar':`x']
		matrix `V_pathb'[`i',`i'] 	= (_se[`depvar':`x'])^2
	}
}


* obtain effects
// clear data for speed
clear

// direct effect
tempname directcoef directvar
scalar `directcoef' = _b[`depvar':`decompose']
scalar `directvar' = (_se[`depvar':`decompose'])^2

// mediator effects (individual)
tempname b_fin V_fin
matrix define `b_fin' = J(1,`npathvars'+4,0)
matrix define `V_fin' = J(`npathvars'+4,`npathvars'+4,0)

`disoutput' di _newline
di as text "compute mediators..." _cont
`disoutput' di as result " (`nmediators')"

local mediationeffect=0
forvalues i = 1/`nmediators' {
	local x : word `i' of `mediators'
	local nlcomline "_b[`x':`decompose']*_b[`depvar':`x']"
	local mediationeffect "`mediationeffect' + _b[`x':`decompose']*_b[`depvar':`x']"
	if "`reliability'"!="" {
		local relcomma=subinstr("`relvars'"," ",`"",""',.)
		local relapos `""`relcomma'""'
		local medapos `""`x'""'
		if inlist(`medapos', `relapos')==1 {
			local upper = strupper("`x'")
			local mediationeffect=subinstr("`mediationeffect'","`x'","`upper'_LATENT",.)
			local nlcomline=subinstr("`nlcomline'","`x'","`upper'_LATENT",.)
		}
	}
	quietly nlcom `nlcomline'
	`disoutput' di as text "." _cont
	matrix `b_fin'[1,`i'] = r(b)
	matrix `V_fin'[`i',`i'] = r(V)
}

// mediation effect (total)
tempname mediationcoef mediationvar
if "`fast'"!="" {
	matrix define `mediationcoef' = `mediationeffect'
	matrix define `mediationvar' = 0
}
else {
	`disoutput' di _newline
	
	if "`confounders'"=="" {
		di as text "indirect effect..." _cont
	}
	else {
		di as text "mediation effect..." _cont
	}
	quietly nlcom `mediationeffect'
	matrix define `mediationcoef' = r(b)
	matrix define `mediationvar' = r(V)
}

// confounding effects
local confoundingeffect=0
tempname confoundingcoef confoundingvar
if "`confounders'"!="" {
	local nconfounders : word count `confounders'
	if "`disentangle'"!="" {
		`disoutput' di _newline
		di as text "disentangle confounders..." _cont
		`disoutput' di as result " (`nconfounders')"
	}
	forvalues i = 1/`nconfounders' {
		local x : word `i' of `confounders'
		local confoundingeffect "`confoundingeffect' + _b[`x':`decompose']*_b[`depvar':`x']"
		local j=`nmediators'+`i'
		if "`disentangle'"!="" {
			quietly nlcom _b[`x':`decompose']*_b[`depvar':`x']
			matrix `b_fin'[1,`j'] 	= r(b)
			matrix `V_fin'[`j',`j'] = r(V)
			`disoutput' di as text "." _cont			
		}
		else {
			matrix `b_fin'[1,`j'] 	= 0
			matrix `V_fin'[`j',`j'] = 0
		}
	}
	
	if "`fast'"!="" {
		matrix define `confoundingcoef' = `confoundingeffect'
		matrix define `confoundingvar' = 0
	}	
	else {
		`disoutput' di _newline
		di as text "confounding effect..." _cont
		quietly nlcom `confoundingeffect'
		matrix define `confoundingcoef' = r(b)
		matrix define `confoundingvar' = r(V)
	}
}
else {
	matrix define `confoundingcoef' = `confoundingeffect'
	matrix define `confoundingvar' = 0
}

// total effect
tempname totalcoef totalvar
if "`fast'"!="" {
	matrix define `totalcoef' = _b[`depvar':`decompose'] + `mediationeffect' + `confoundingeffect'
	matrix define `totalvar' = 0
}
else {
	`disoutput' di _newline
	di as text "total effect..."
	quietly nlcom _b[`depvar':`decompose'] + `mediationeffect' + `confoundingeffect'
	matrix define `totalcoef' = r(b)
	matrix define `totalvar' = r(V)
}

// restore original data
restore


* prepare matrices
// total, mediation, confounding, direct effect
matrix `b_fin'[1,`npathvars'+1] 			= `totalcoef'
matrix `V_fin'[`npathvars'+1,`npathvars'+1] = `totalvar'
matrix `b_fin'[1,`npathvars'+2] 			= `mediationcoef'
matrix `V_fin'[`npathvars'+2,`npathvars'+2] = `mediationvar'
matrix `b_fin'[1,`npathvars'+3] 			= `confoundingcoef'
matrix `V_fin'[`npathvars'+3,`npathvars'+3] = `confoundingvar'
matrix `b_fin'[1,`npathvars'+4] 			= `directcoef'
matrix `V_fin'[`npathvars'+4,`npathvars'+4] = `directvar'

// coefficients and variance
tempname b V
matrix define `b' = J(1,`npathvars'+4+`nmediators'+`nmediators',0)
matrix define `V' = J(`npathvars'+4+`nmediators'+`nmediators',`npathvars'+4+`nmediators'+`nmediators',0)
matrix `b'[1,1] = `b_fin'
matrix `V'[1,1] = `V_fin'

// incorporate path a and b coefficients (if specified)
if "`patha'"!="" {
	matrix `b'[1,`npathvars'+5] 										= `b_patha'
	matrix `V'[`npathvars'+5,`npathvars'+5] 							= `V_patha'
}
if "`pathb'"!="" {
	matrix `b'[1,`npathvars'+5+`nmediators'] 							= `b_pathb'
	matrix `V'[`npathvars'+5+`nmediators',`npathvars'+5+`nmediators'] 	= `V_pathb'	
}

// name rows and columns
if "`confounders'"=="" {
	local mediationname "Indirect_effect"
}
else {
	local mediationname "Mediation_effect"
}
local names_patha
local names_pathb
foreach x of varlist `mediators' {
	local names_patha "`names_patha' Path_A_`x'"
	local names_pathb "`names_pathb' Path_B_`x'"
}
local addnames "`names_patha' `names_pathb'"
matrix rownames `b' = y1
matrix colnames `b' = `mediators' `confounders' "Total_effect" `mediationname' "Confounding_effect" "Direct_effect" `addnames'
matrix rownames `V' = `mediators' `confounders' "Total_effect" `mediationname' "Confounding_effect" "Direct_effect" `addnames'
matrix colnames `V' = `mediators' `confounders' "Total_effect" `mediationname' "Confounding_effect" "Direct_effect" `addnames'

// additional output matrix with mediation percentages
tempname percexpl
matrix define `percexpl' = (100*`b'[1,1]/`totalcoef'[1,1])
forvalues i = 2/`nmediators' {
	local x : word `i' of `nmediators'
	matrix `percexpl' = (`percexpl' \ 100*`b'[1,`i']/`totalcoef'[1,1])
}
matrix `percexpl' = (`percexpl' \ 100*`b'[1,`npathvars'+2]/`totalcoef'[1,1])
matrix rownames `percexpl' = `mediators' "All mediators"
matrix colnames `percexpl' = "Mediation"


* post results
// retrieve sem information
local N = e(N)
local N_clust = e(N_clust)
tempvar samp_var
gen byte `samp_var' = e(sample)

// return information
ereturn post `b' `V', depname(`depvar') obs(`N') esample(`samp_var')
if `N_clust'!=. {
	ereturn scalar N_clust = `N_clust'
}
if "`clustvar'"!="." {
	ereturn local clustvar `clustvar'
}
if "`vcetype'"!="." {
	ereturn local vcetype `vcetype'
}
ereturn scalar ll = `ll'
ereturn local vce `vce'
ereturn local concomitantvars `concomitants'
ereturn local confoundervars `confounders'
ereturn local mediatorvars `mediators'
ereturn local decomposevar `decompose'
ereturn local link `link'
ereturn local family `family'
ereturn local cmdline "nlmed `0'"
ereturn local cmd "nlmed"
ereturn local title "Generalized effect decomposition"

// display header
`disheader'	di _newline	as text "Family: " 	_column(15) as result "`family'"
`disheader'	di 				as text "Link: " 	_column(15) as result "`link'"
`disheader'	di _newline		as text "Outcome: " 	_column(15) as result "`depvar'"
`disheader'	di 				as text "Decompose: "	_column(15) as result "`decompose'"
`disheader'	di 				as text "Mediators: "	_column(15) as result "`mediators'"
`disheader'	di 				as text "Confounders: "		_column(15) as result "`confounders'"
`disheader'	di 				as text "Concomitants: "	_column(15) as result "`concomitants'"
if "`vcetype'"=="Robust" {
	`disheader' di  _newline as text "Log pseudolikelihood = " as result e(ll) _column(55) as text " Number of obs = " as result %10.0fc e(N)
}
else {
	`disheader' di  _newline as text "Log likelihood = " as result e(ll) _column(55) as text " Number of obs = " as result %10.0fc e(N)
}

// display results
ereturn display, noomitted vsquish level(`level')
if "`reliability'"!="" {
	di as text "After correcting for measurement error in" as result "`relvars'." _newline(2)
}

// display percentage explained
`distable' matlist `percexpl', title("Percentage explained") rowtitle(`decompose') twidth(20)
end
