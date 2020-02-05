Ω_oos = [
    (Wind = 0.5, fuel_multiplier = 1),
    (Wind = 1.0, fuel_multiplier = 1),
    (Wind = 1.5, fuel_multiplier = 1),
    (Wind = 2.0, fuel_multiplier = 1),
    (Wind = 2.5, fuel_multiplier = 1),
    (Wind = 3.0, fuel_multiplier = 1),
    (Wind = 3.5, fuel_multiplier = 1),
    (Wind = 4.0, fuel_multiplier = 1),
    (Wind = 4.5, fuel_multiplier = 1),
    (Wind = 5.0, fuel_multiplier = 1),
    (Wind = 5.5, fuel_multiplier = 1),
    (Wind = 6.0, fuel_multiplier = 1),
    (Wind = 6.5, fuel_multiplier = 1),
    (Wind = 7.0, fuel_multiplier = 1),
    (Wind = 7.5, fuel_multiplier = 1),
    (Wind = 8.0, fuel_multiplier = 1),
    (Wind = 8.5, fuel_multiplier = 1),
    (Wind = 9.0, fuel_multiplier = 1),
    (Wind = 9.5, fuel_multiplier = 1),
    (Wind = 10.0, fuel_multiplier = 1)
]

# Wind Prob
probability_oos = [0.05, 0.05, 0.05, 0.05, 0.05,
                   0.05, 0.05, 0.05, 0.05, 0.05,
                   0.05, 0.05, 0.05, 0.05, 0.05,
                   0.05, 0.05, 0.05, 0.05, 0.05]

#SIMULATE MODEL
for r = 1:length(Risk_name)
    eval(quote
        SampleScheme = SDDP.OutOfSampleMonteCarlo(
            $(model_list[r]),
            use_insample_transition = true,
        ) do t
            probability = probability_oos
            noise_terms = [SDDP.Noise(
                (Wind = ω.Wind, fuel_multiplier = ω.fuel_multiplier),
                p,
            ) for (ω, p) in zip(Ω_oos, probability_oos)]
            return noise_terms
        end
        $(sim_list[r]) = SDDP.simulate(
    $(model_list[r]),
    SIM_NUM,
    [:c_up, :c_dn, :d_dn, :d_ct, :e_DL, :e_DL_ct, :W],
    sampling_scheme = SampleScheme,
        )
    end)
end
