#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020
Script         : Stores data frames into .csv files
Author         : Corey Kok
Project        : -

Input:        - df_Objective
              - df_Input
              - df_Solution

Output:       - Objective.csv
              - input.csv
              - Solution.csv
=========================================================================
=#

CSV.write(
    join([pwd(), "/Output/Objective.csv"]),
    DataFrame(df_Objective),
    writeheader = true,
)
CSV.write(
    join([pwd(), "/Output/Input.csv"]),
    DataFrame(df_Input),
    writeheader = true,
)
CSV.write(
    join([pwd(), "/Output/Solution.csv"]),
    DataFrame(df_Solution),
    writeheader = true,
)
