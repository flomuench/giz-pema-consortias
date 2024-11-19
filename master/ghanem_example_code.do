* Generate simulated data:

    clear
    set seed 12345
    set obs 1000

 *   Treatment status:
    randtreat, generate(treat) replace

*    Baseline covariates that are determinants of the outcome:
    gen w1_b = 0.5*rnormal()
    gen w2_b = 0.7*rnormal()

*    Baseline outcome:
    gen y_b = 1 + 0.25*w1_b + 0.25*w2_b + rnormal()

*    Outcome-specific response status at follow-up:
    gen resp_y = (uniform() < .5)

*    Generate strata variable:
    gen id = _n
    gen random = runiform()
    sort random
    gen sex = _n <= 500


*    1) Tests of internal validity for completely randomized experiment:
    attregtest y_b, treatvar(treat) respvar(resp_y)

*    2) Tests of internal validity for completely randomized experiment, including baseline covariates:
    attregtest y_b w1_b w2_b, treatvar(treat) respvar(resp_y)

*    3) Tests of internal validity for stratified randomized experiment:
    randtreat, generate(treat) replace strata(sex)
    attregtest y_b, treatvar(treat) respvar(resp_y) stratavar(sex)

*    4) Tests of internal validity for stratified randomized experiment, including baseline covariates:
    randtreat, generate(treat) replace strata(sex)
    attregtest y_b w1_b w2_b, treatvar(treat) respvar(resp_y) stratavar(sex)

    attregtest y_b, treatvar(treat) respvar(resp_y) stratavar(sex)
