#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020
Script         : Defines framework of simulation, then performs simulation
Author         : Corey Kok
Project        : -

Parameters:   - Stopping criteria to indicate when model is sufficiently trained

Input:        - Model definitions for each risk measure
              - Risk measure descriptions

Output:       - Completed simulation using each trained model's policy with
                    - c_up, c_dn, d_dn, d_ct, and W stored as output in the
                      simulation
=========================================================================
=#

#SIMULATE MODEL
for r = 1:length(Risk_name)
    eval(quote
        SampleScheme = SDDP.OutOfSampleMonteCarlo(
            $(model_list[r]),
            use_insample_transition = true,
        ) do t
            noise_terms = [SDDP.Noise(
                (Wind = ω.Wind, fuel_multiplier = ω.fuel_multiplier),
                p,
            ) for (ω, p) in zip(Ω, probability)]
            return noise_terms
        end
        $(sim_list[r]) = SDDP.simulate($(model_list[r]),
        SIM_NUM,
        [:c_up, :c_dn, :d_dn, :d_ct, :e_DL, :e_DL_ct, :W],
        sampling_scheme = SampleScheme,
        )
    end)
end
