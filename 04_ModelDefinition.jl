#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020
Script         : SDDP Problem that is duplicated for each risk measure
Author         : Corey Kok
Project        : -

Input:        - C_Con_up # Cost for conventional upregulation
              - C_Con_dn # Cost for conventional downregulation
              - C_Con_DA # Cost for commitment of day ahead conventional gen
              - P_Con_up # Capacity for conventional upgregulation
              - P_Con_dn # Capacity for conventional downregulation
              - E_Cap # Capacity of deferrable load device
              - C_DL_dn # Cost to charge deferrable load device
              - C_DL_ct # Cost to curtail charging device
              - R_up # Limit on the ramp up rate for the DL device
              - R_dn # Limit on the ramp down rate for the DL device
              - P_DL_dn # Capacity on the charging rate for the DL device
              - P_DL_ct # Maximum power curtailment for the DL device
              - E_Req # Required amount of energy at end of horizon

Output:       - Model definitions for each risk measure
=========================================================================
=#

# Model definition
for r = 1:length(Risk_name)
    eval(quote
        $(model_list[r]) = nothing
        $(model_list[r]) =
            SDDP.LinearPolicyGraph(
                stages = length(TIMES), # Number of stages in model
                sense = :Min, # Minimisation problem
                lower_bound = 0, # Minimum cost across all candidate soltuions
                optimizer = with_optimizer(
                    Gurobi.Optimizer,
                    gurobi_env,
                    OutputFlag = 0,
                ),
            ) do subproblem, t
                # CONTROL VARIABLES
                # Upper and lower bounds on DL and conventional regulation
                @variables(
                    subproblem,
                    begin
                        0 <= d_ct[j = DEFERRABLE] <= P_DL_ct[j, t]
                        0 <= c_up[i = CONVENTIONAL] <= P_Con_up[i, t]
                        0 <= c_dn[i = CONVENTIONAL] <= P_Con_dn[i, t]
                        W
                    end,
                )
                # Upper and lower bounds on Energy Storage
                @variable(
                    subproblem,
                    0 <= e_DL[j = DEFERRABLE] <= E_Cap[j],
                    SDDP.State,
                    initial_value = 0.0,
                )
                # Upper and lower bounds on Energy Storage Curtailed
                @variable(
                    subproblem,
                    0 <= e_DL_ct[j = DEFERRABLE] <= 1000,
                    SDDP.State,
                    initial_value = 0.0,
                )
                # Upper and lower bounds on charging rate of DL device
                @variable(
                    subproblem,
                    0 <= d_dn[j = DEFERRABLE] <= P_DL_dn[j, t],
                    SDDP.State,
                    initial_value = 0.0,
                )
                # Regulation provided = Regulation reqruired
                @constraint(
                    subproblem,
                    sum(c_up[i] - c_dn[i] for i in CONVENTIONAL) -
                    sum(d_dn[j].out for j in DEFERRABLE) == Demand[t] - W,
                )
                # Energy required >= Energy in device
                # Energy in device = Energy in device previously +
                #                    Energy consumed +
                #                    Energy curtailed
                # Ramping constraints
                @constraints(
                    subproblem,
                    begin
                        [j = DEFERRABLE],
                        e_DL_ct[j].out == e_DL_ct[j].in + d_ct[j]
                        [j = DEFERRABLE],
                        e_DL[j].out == e_DL[j].in + d_dn[j].out
                        [j = DEFERRABLE],
                        e_DL[j].out + e_DL_ct[j].out >= E_Req[j, t]
                        [j = DEFERRABLE],
                        d_dn[j].out - d_dn[j].in <= R_up[j, t]
                        [j = DEFERRABLE],
                        d_dn[j].in - d_dn[j].out <= R_dn[j, t]
                    end,
                )
                # Cost = Conventinal regulation cost + DL regulation cost
                SDDP.parameterize(subproblem, Ω, probability) do ω
                    JuMP.fix(W, ω.Wind)
                    @stageobjective(
                        subproblem,
                        sum(C_Con_up[i, t] * c_up[i] +
                            C_Con_dn[i, t] * c_dn[i] for i in CONVENTIONAL) +
                        sum(C_DL_dn[j, t] * d_dn[j].out +
                            C_DL_ct[j, t] * d_ct[j] for j in DEFERRABLE),
                    )
                end
            end
    end)
end
