#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020
Script         : Reads output from simulations to data frames
Author         : Corey Kok
Project        : -

Input:        - Completed simulation using each trained model's policy with
                    - c_up, c_dn, d_dn, d_ct, and W stored as output in the
                      simulation
              - C_Con_DA
              - C_Con_up
              - C_Con_dn
              - C_DL_dn
              - C_DL_ct

Output:       - df_Objective
              - df_Input
              - df_Solution
=========================================================================
=#

# Store data into data frames
for r = 1:length(Risk_name)
    eval(quote
        temp_sim = $(sim_list[r])
    end)
    for sim = 1:SIM_NUM
        for t in TIMES
            df_Temp = DataFrame(
                SimNum = sim,
                Stage = t,
                Scenario = temp_sim[sim][t][:noise_term].Wind,
                Model = Risk_name[r],
                Cost = temp_sim[sim][t][:stage_objective],
            )
            append!(df_Objective, df_Temp)
        end
    end
    for sim = 1:SIM_NUM
        for t in TIMES
            df_Temp = DataFrame(
                SimNum = sim,
                Stage = t,
                Scenario = temp_sim[sim][t][:noise_term].Wind,
                Demand = Demand[t],
                Wind = temp_sim[sim][t][:W],
                c_DA = 0.0,
                Model = Risk_name[r],
            )
            append!(df_Input, df_Temp)
        end
    end
    for sim = 1:SIM_NUM
        for t in TIMES
            for i in CONVENTIONAL
                df_Temp = DataFrame(
                    SimNum = sim,
                    Stage = t,
                    Scenario = temp_sim[sim][t][:noise_term].Wind,
                    Unit = i,
                    C_Con_DA = C_Con_DA[i, t],
                    C_Con_up = C_Con_up[i, t],
                    C_Con_dn = C_Con_dn[i, t],
                    c_DA = 0.0,
                    c_up = temp_sim[sim][t][:c_up][i],
                    c_dn = temp_sim[sim][t][:c_dn][i],
                    cost_DA = C_Con_DA[i, t] * 0.0,
                    cost_up = C_Con_up[i, t] * temp_sim[sim][t][:c_up][i],
                    cost_dn = C_Con_dn[i, t] * temp_sim[sim][t][:c_dn][i],
                    C_DL_dn = 0.0,
                    C_DL_ct = 0.0,
                    d_dn = 0.0,
                    d_ct = 0.0,
                    e_DL_0 = 0.0,
                    e_DL_1 = 0.0,
                    e_DL_ct_0 = 0.0,
                    e_DL_ct_1 = 0.0,
                    cost_d_dn = 0.0,
                    cost_d_ct = 0.0,
                    Model = Risk_name[r],
                )
                append!(df_Solution, df_Temp)
            end
            for j in DEFERRABLE
                df_Temp = DataFrame(
                    SimNum = sim,
                    Stage = t,
                    Scenario = temp_sim[sim][t][:noise_term].Wind,
                    Unit = j,
                    C_Con_DA = 0.0,
                    C_Con_up = 0.0,
                    C_Con_dn = 0.0,
                    c_DA = 0.0,
                    c_up = 0.0,
                    c_dn = 0.0,
                    cost_DA = 0.0,
                    cost_up = 0.0,
                    cost_dn = 0.0,
                    C_DL_dn = C_DL_dn[j, t],
                    C_DL_ct = C_DL_ct[j, t],
                    d_dn = temp_sim[sim][t][:d_dn][j].out,
                    d_ct = temp_sim[sim][t][:d_ct][j],
                    e_DL_0 = temp_sim[sim][t][:e_DL][j].in,
                    e_DL_1 = temp_sim[sim][t][:e_DL][j].out,
                    e_DL_ct_0 = temp_sim[sim][t][:e_DL_ct][j].in,
                    e_DL_ct_1 = temp_sim[sim][t][:e_DL_ct][j].out,                       
                    cost_d_dn = C_DL_dn[j, t] * temp_sim[sim][t][:d_dn][j].out,
                    cost_d_ct = C_DL_ct[j, t] * temp_sim[sim][t][:d_ct][j],
                    Model = Risk_name[r],
                )
                append!(df_Solution, df_Temp)
            end
        end
    end
end
