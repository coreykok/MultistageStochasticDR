#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020
Script         : Creates empty data frames that will be used to plot input
                 and output
Author         : Corey Kok
Project        : -

Input : -
Output:         - empty df_Input
                - empty df_Solution
                - empty df_Objective
=========================================================================
=#

# SET UP DATA FRAMES FOR OUTPUT
df_Input = DataFrame(
               SimNum = Int[],
               Stage = Int[],
               Scenario = Float64[],
               Demand = Float64[],
               Wind = Float64[],
               c_DA = Float64[],
               Model = String[])
df_Solution = DataFrame(
                SimNum = Int[],
                Stage = Int[],
                Scenario = Float64[],
                Unit = Symbol[],
                C_Con_DA = Float64[],
                C_Con_up = Float64[],
                C_Con_dn = Float64[],
                c_DA = Float64[],
                c_up = Float64[],
                c_dn = Float64[],
                cost_DA = Float64[],
                cost_up = Float64[],
                cost_dn = Float64[],
                C_DL_dn = Float64[],
                C_DL_ct = Float64[],
                d_dn = Float64[],
                d_ct = Float64[],
                e_DL_0 = Float64[],
                e_DL_1 = Float64[],
                e_DL_ct_0 = Float64[],
                e_DL_ct_1 = Float64[],
                cost_d_dn = Float64[],
                cost_d_ct = Float64[],
                Model = String[])
df_Objective = DataFrame(
                SimNum = Int[],
                Stage = Int[],
                Scenario = Float64[],
                Model = String[],
                Cost = Float64[])
