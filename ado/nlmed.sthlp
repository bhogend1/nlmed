{smcl}
{title:Title}

{phang} {cmd:nlmed} Mediation analysis of non-linear models {p_end}


{title:Syntax}

{p 4 4 2}
    where the syntax is one of the following:
	
{p 8 17 2}
   {cmd: nlmed}
   {it:model-type}
   {it:depvar}
   {ifin}
   {weight}
{cmd:, } {opt d:ecompose(varname)} {opt m:ediators(varlist)} [ {it: options} ]
{p_end}

{p 8 17 2}
   {cmd: nlmed}
   {it:depvar}
   {ifin}
   {weight}
{cmd:, } {opt d:ecompose(varname)} {opt m:ediators(varlist)} {opth f:amily(gsem_family_and_link_options##family:family)} {opth li:nk(gsem_family_and_link_options##link:link)} [ {it: options} ]
{p_end}


{synoptset 35 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Model}
{synopt:{opt d:ecompose(varname)}}key variable to be decomposed{p_end}
{synopt:{opt m:ediators(varlist)}}mediators of interest{p_end}
{synopt:{opt conf:ounders(varlist)}}mediators-as-controls{p_end}
{synopt:{opt conc:omitants(varlist)}}concomitant controls{p_end}
{synopt:{opt rel:iability(varname # [...])}}reliability of measurement variables{p_end}
{synopt:{opth cons:traints(numlist)}}apply specified linear constraints{p_end}
{synopt:{opth f:amily(gsem_family_and_link_options##family:family)}}distribution of {it:depvar}{p_end}
{synopt:{opth li:nk(gsem_family_and_link_options##link:link)}}link function{p_end}
{synopt:{opt showcmd}}do not fit the model; show {bf:gsem} command instead{p_end}

{syntab:SE/Robust}
{synopt:{opt vce}{cmd:(}{it:{help vcetype} [vce_opts]}{cmd:)}}vcetype may be {cmd:oim}, {cmd:opg}, {cmd:robust}, {cmd:cluster} {it:clustvar}, or {cmd:bootstrap} {it:bs_opts}{p_end}

{syntab:Reporting}
{synopt:{opt l:evel(#)}}set confidence level; default is {cmd:level(95)}{p_end}
{synopt:{opt dis:entangle}}disentangle mediators-as-controls{p_end}
{synopt:{opt patha}}show coefficients from {it:decompose-var} to {it:mediators}{p_end}
{synopt:{opt pathb}}show coefficients from {it:mediators} to {it:depvar}{p_end}
{synopt:{opt nohead:er}}suppress output header{p_end}
{synopt:{opt notab:le}}suppress percentage explained table{p_end}
{synopt:{opt noi:sily}}show structural equation model output{p_end}

{syntab:Advanced}
{synopt:{opth mi:(mi_estimate##spec:mi_opts)}}multiple imputation{p_end}
{synopt:{opt from(matname)}}starting values for the structural equation model{p_end}
{synopt:{opt outmat(matname)}}save coefficients of the structural equation model{p_end}
{synopt:{opt postsem}}post structural equation model and skip decomposition{p_end}
{synopt:{opt fast}}skip standard errors of indirect and total effect{p_end}
{synopt:{it:other}}other {it:{help gsem_model_options:model}} and {it:{help gsem_estimation_options:estimation}} options{p_end}
{synoptline}
{p2colreset}{...}
{pstd} {it:model-type} can be {help regress}, {help logit}, {help probit}, {help cloglog}, {help poisson}, {help mlogit}, or any other model allowed by {help gsem family and link options:gsem}.{p_end}
{pstd}{cmd:fweight}s, {cmd:iweight}s, and {cmd:pweight}s are allowed; see {help weight}.{p_end}


{title:Description}

{pstd}{cmd:nlmed} decomposes effects from non-linear models into a direct and indirect part.
An important use of the method is to conduct a mediation analysis of binary outcomes.
These decompositions can be performed using the KHB-method (Karlson et al. 2011, see {help khb}).
The current command offers a more flexible implementation.{p_end}

{pstd}In linear regression models, decomposing the total effect into direct and indirect effects is straightforward.
The decomposition is done by comparing the coefficient of a key decompose variable of interest between a reduced model (without mediator variables) and a full model (with one or more mediator variables added).
The difference between the coefficients across the two models expresses the amount of mediation, that is, the size of the indirect effect.{p_end}

{pstd}This strategy does not hold in the context of non-linear models, such as logit, because the estimated coefficients of these models are not comparable between different models.
The reason is that these models are rescaled, and the coefficients and the error variance are not separately identified.
The KHB-method solves this problem as follows.
It first estimates a reduced model plus the residuals obtained from a regression of the mediator variables on the decompose variable.
It then estimates the full model with mediator variables as usual.
The difference between the coefficients across the two models expresses the amount of mediation.
Standard errors are computed using the delta method.{p_end}

{pstd}Alternatively, the indirect effect can be computed as the product of coefficients.
The product consists of the coefficients of the decompose variable on the mediator variables and the coefficients of mediator variables on the dependent variable.
These coefficients should be obtained by simultaneous estimation.
The direct effect is then simply the coefficient of the dependent variable on the decompose variable, the indirect effect the product of coefficients, and the total effect the sum of the direct and indirect effects.
This has been made possible with the introduction of generalized structural equation modeling.{p_end}

{pstd}{cmd:nlmed} implements the decomposition of non-linear effects using generalized structural equation modeling.
It is a wrapper around the Stata commands {help gsem} and {help nlcom}.
All models supported by gsem can be decomposed, including logistic, probit, complementary log-log, and Poisson regressions.
It supports several handy options. For example, {it:reliability} conveniently implements corrections to classical measurement error in the mediator variables,
{it:constraints} allows for constraints to be passed on to the structural equation models,
and {it:mi} can be used for multiple imputation.{p_end}


{title:Options}

{phang}{opt m:ediators(varlist)} specifies which variables mediate between the {it:decompose-var} and the {it:depvar}.
For these variables, the disentangled coefficients are returned and a table is shown with the percentage of mediation.{p_end}

{phang}{opt conc:omitants(varlist)} specifies which variables must be held constant in the total, direct, and indirect effect estimates.
These variables are best though of as confounders of the {it:decompose-var} and the {it:depvar}.{p_end}

{phang}{opt conf:ounders(varlist)} specifies which variables must be held constant in the direct and indirect effect estimates.
These variables are best though of as confounders of the {it:mediators} and the {it:depvar}.
Formally speaking, they are additional mediators.
Only their combined effect is reported, unless option {opt dis:entangle} is specified.{p_end}

{phang}{opt rel:iability(varname # [varname # [...]])} allows you to specify the fraction of variance not due to measurement error for measurement variables.
It is intended for the correction of classical measurement error in {it:mediator} variables.
Specify this option according to the syntax of {help sem and gsem option reliability:sem}.
Because mediator variables are endogenous variables in the system of equations, this option corrects the estimates via latent variables, which substantially slows down the estimation.
Note that it is not advisable to correct for measurement error in the {it:decompose-var} or {it:depvar}.
If you want to do so nonetheless, you will need to modify the sourcecode.{p_end}

{phang}{opth cons:traints(numlist)} applies linear constraints that are predefined by the user to the structural equation model.
Because these models contain simultaneous equations, the constraints must refer to the particular equation name.
See {help sem and gsem option constraints:constraints} for examples or use option {it:noisily} to show the equation names.{p_end}

{phang}{opth family:(gsem family and link options##family:family)} and {opth link:(gsem family and link options##family:linkname)} specify a distribution F of the {it:depvar} and a link function g() linking it to the other variables.
These options allow for more models than the simpler {it:model-type} syntax.

{phang}{opt vce}{cmd:(bootstrap} {it:{help bootstrap:bs_opts}}{cmd:)} uses a bootstrap to estimate the standard errors of the structural equation model.
This is not the same as bootstrapping the procedure as a whole.
To do that, use the prefix {it:{help bootstrap:bootstrap:}} with the indirect effect of interest in the {it: exp_list}.{p_end}

{phang}{opt patha} and {opt pathb} request that the coefficients and standard errors of path A and path B are added to the estimation table.
Path A runs from the {it:decompose-var} to the {it:mediators}.
Path B runs from the {it:mediators} to the {it:depvar}.{p_end}

{phang}{opt mi}({it:{help mi_estimate##spec:mi_opts}}{cmd:)} is used for multiply imputed data.
This option estimates the structural equation model on {it:mi} data, after which the indirect effects are computed.
It is the same as applying the prefix {it:{help mi estimate:mi estimate:}} to the procedure as a whole but faster.
If no suboptions are specified, the defaults of {it:mi estimate} apply.{p_end}

{phang}{opt from(matname)} specifies a coefficient matrix (vector) that overrides the default starting values for the structural equation model.
Use of this option implies suboption {it:skip}.
If the provided matrix does not exist or contains a single missing value, the option is ignored.{p_end}

{phang}{opt outmat(matname)} posts the coefficient matrix (vector) from the structural equation model. If you simply want to view the regression, it is better to use {it:noisily}.{p_end}


{title:Example 1: decomposing age differences in the prevalence of diabetes}

{pstd}{cmd: webuse nhanes2d}{p_end}
{pstd}{cmd: logit diabetes age sex}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex)}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) vce(cluster location)}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) vce(cluster location) confounders(sizplace houssiz)}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) vce(cluster location) confounders(sizplace houssiz) fast}{p_end}


{title:Example 2: constraints and corrections for measurement error}

{pstd}{cmd: constraint define 1 [diabetes]copper=[diabetes]iron}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) constraints(1)}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) reliability(zinc 0.83)}{p_end}


{title:Example 3: other model types and other syntax}

{pstd}{cmd: nlmed probit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex)}{p_end}
{pstd}{cmd: nlmed cloglog diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex)}{p_end}
{pstd}{cmd: nlmed diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) family(gaussian) link(log)}{p_end}


{title:Example 4: viewing the structural equation model}

{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) patha pathb}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) noisily}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) showcmd}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) postsem}{p_end}
{pstd}{cmd: predict pred_diabetes, outcome(diabetes) pr}{p_end}


{title:Example 5: different ways of bootstrapping}

{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) vce(bootstrap reps(50) seed(2368))}{p_end}
{pstd}{cmd: bootstrap _b[iron] _b[zinc] _b[copper], reps(50) seed(2368): nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex)}{p_end}


{title:Example 6: multiple imputation}

{pstd}{cmd: drop if diabetes==.}{p_end}
{pstd}{cmd: mi set wide}{p_end}
{pstd}{cmd: mi register regular diabetes age sex iron}{p_end}
{pstd}{cmd: mi register impute zinc copper}{p_end}
{pstd}{cmd: mi impute chained (pmm, knn(5) include(diabetes age sex iron)) zinc copper, add(10) chaindots}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) mi}{p_end}
{pstd}{cmd: nlmed logit diabetes, decompose(age) mediators(iron zinc copper) concomitants(sex) mi(imputations(1/3) noupdate dots) noisily}{p_end}


{title:References}

{pstd} Karlson, K.B., Holm, A., & Breen, R. (2011).
Comparing regression coefficients between same-sample nested models using logit and probit: A new method.
{it:Sociological Methodology, 42}(1), 286-313.{p_end}


{title:Author}

{pstd}Bram Hogendoorn (b.hogendoorn@uva.nl).{p_end}
{pstd}This program is written in Stata, not Mata. Anyone who would like to translate this program is invited to do so.{p_end}

{pstd}Version: October 4th, 2022.{p_end}
