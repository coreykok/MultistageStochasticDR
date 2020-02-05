#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020
Script         : Trains each SDDP model according to each risk measure
Author         : Corey Kok
Project        : -

Parameters:   - Stopping criteria to indicate when model is sufficiently trained

Input:        - Model definitions for each risk measure
              - Risk measure descriptions

Output:       - Trained models for each risk measure
=========================================================================
=#

# TRAIN MODEL
for r = 1:length(Risk_name)
    eval(quote
        SDDP.train(
            $(model_list[r]),
            risk_measure = $(Risk_list[r]),
            cut_type = SDDP.SINGLE_CUT,
            time_limit = 10.0, 
            run_numerical_stability_report = false,
        )
    end)
end
