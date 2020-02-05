#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020
Script         : Load and process data from .csv files
Author         : Corey Kok
Project        : -
=========================================================================
PARAMETERS     : - r_seed_simulate
                 - SIM_NUM
                 - w
                 - beta
                 - lambda
                 - Max ModifiedChiSquared distance
                 - Set: CONVENTIONAL
                 - Set: DEFERRABLE
                 - Set: TIME
                 - Parameter: Ω - Wind and fuel_multiplier Uncertainty


Input:        - Thermostatically-Controlled-Load data
              - Deferrable-Load data
              - Conventional demand response data
              - Wind and Demand data

Output:       - C_Con_up # Cost for conventional upregulation 
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
              - Defined risk measures of the types
                    - Expected
                    - WorstCase
                    - EAVaR
                    - ModChi
=========================================================================
=#

############# SIMULATION PARAMETERS #############

r_seed_simulate = 12314 # Random seed to simulate model
SIM_NUM = 200 # Number of times model is simulated

# Definition in Worst Case risk function (A little weight on expectation)
w = 1e-4 # Weighting on expectation
WorstCase_RM = w * SDDP.Expectation() + (1 - w) * SDDP.WorstCase()


# Defines a list of risk measures, risk measure names, the variables
# storing the models, and the variables storing the simulations
Risk_list = [
    SDDP.Expectation(),
    WorstCase_RM,
    SDDP.EAVaR(beta=1/2, lambda=0.5),
    SDDP.ModifiedChiSquared(0.2)]
Risk_name = ["Expected","WorstCase","EAVaR","ModChi"]
model_list = [:model_1, :model_2, :model_3, :model_4]
sim_list = [:sim_1, :sim_2, :sim_3, :sim_4]


############# SET DEFINITION #############
CONVENTIONAL = [:i1] # Conventional units
DEFERRABLE = [:j1] # Deferrable load units
TIMES = [1, 2, 3, 4, 5, 6, 7, 8,
         9, 10, 11, 12, 13, 14, 15, 16,
         17, 18, 19, 20, 21, 22, 23, 24] # Time steps


############# EXOGENOUS PARAMETERS #############
# Probability of each scenario at all time steps
probability = [1/4, 1/4, 1/4, 1/4]

# Uncertainty parameter definition (for now only uncertainty in wind output)
# The only uncontrollable source of generation is assumed to come from wind
Ω = [
    (Wind = 2.0, fuel_multiplier = 1),
    (Wind = 3.0, fuel_multiplier = 1),
    (Wind = 4.0, fuel_multiplier = 1),
    (Wind = 5.0, fuel_multiplier = 1),
]

# DEMAND
Demand_dat = CSV.read(join([pwd(),"/Input/Demand.csv"]),
    header=false, delim=',', types = [Int64,Float64]) # Loads demand data .csv
Demand = Dict{Int64, Float64}() # Empty Demand parameter
for i = TIMES
    Demand[i] = Demand_dat[i,2] # Fills parameters using loaded data
end


############# CONVENTIONAL LOAD #############

# Loads data from .csv files
C_Con_up_dat = CSV.read(join([pwd(), "/Input/", "C_Con_up.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
C_Con_dn_dat = CSV.read(join([pwd(), "/Input/", "C_Con_dn.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
C_Con_DA_dat = CSV.read(join([pwd(), "/Input/", "C_Con_DA.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
P_Con_up_dat = CSV.read(join([pwd(), "/Input/", "P_Con_up.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
P_Con_dn_dat = CSV.read(join([pwd(), "/Input/", "P_Con_dn.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])

# Creates Empty Parameters
C_Con_up = Dict{ Tuple{Symbol,Int64}, Float64}()
C_Con_dn = Dict{ Tuple{Symbol,Int64}, Float64}()
C_Con_DA = Dict{ Tuple{Symbol,Int64}, Float64}()
P_Con_up = Dict{ Tuple{Symbol,Int64}, Float64}()
P_Con_dn = Dict{ Tuple{Symbol,Int64}, Float64}()

# Fills parameters using loaded data
for i = 1:length(CONVENTIONAL)
    for j in TIMES
        C_Con_up[(CONVENTIONAL[i], C_Con_up_dat[j, 2])] = C_Con_up_dat[
            (i-1)*length(CONVENTIONAL)+j,
            3,
        ]
        C_Con_dn[(CONVENTIONAL[i], C_Con_dn_dat[j, 2])] = C_Con_dn_dat[
            (i-1)*length(CONVENTIONAL)+j,
            3,
        ]
        C_Con_DA[(CONVENTIONAL[i], C_Con_DA_dat[j, 2])] = C_Con_DA_dat[
            (i-1)*length(CONVENTIONAL)+j,
            3,
        ]
        P_Con_up[(CONVENTIONAL[i], P_Con_up_dat[j, 2])] = P_Con_up_dat[
            (i-1)*length(CONVENTIONAL)+j,
            3,
        ]
        P_Con_dn[(CONVENTIONAL[i], P_Con_dn_dat[j, 2])] = P_Con_dn_dat[
            (i-1)*length(CONVENTIONAL)+j,
            3,
        ]
    end
end

############# DEFERRABLE LOAD #############

# Loads data from .csv files
E_Cap_dat = CSV.read(join([pwd(), "/Input/", "E_Cap.csv"]),
    header=false, delim=',', types = [String,Float64])
C_DL_dn_dat = CSV.read(join([pwd(), "/Input/", "C_DL_dn.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
C_DL_ct_dat = CSV.read(join([pwd(), "/Input/", "C_DL_ct.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
R_up_dat = CSV.read(join([pwd(), "/Input/", "R_up.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
R_dn_dat = CSV.read(join([pwd(), "/Input/", "R_dn.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
P_DL_dn_dat = CSV.read(join([pwd(), "/Input/", "P_DL_dn.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
P_DL_ct_dat = CSV.read(join([pwd(), "/Input/", "P_DL_ct.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])
E_Req_dat = CSV.read(join([pwd(), "/Input/", "E_Req.csv"]),
    header=false, delim=',', types = [String,Int64,Float64])

# Creates Empty Parameters
E_Cap = Dict{ Symbol, Float64}()
C_DL_dn = Dict{ Tuple{Symbol,Int64}, Float64}()
C_DL_ct = Dict{ Tuple{Symbol,Int64}, Float64}()
R_up    = Dict{ Tuple{Symbol,Int64}, Float64}()
R_dn    = Dict{ Tuple{Symbol,Int64}, Float64}()
P_DL_dn = Dict{ Tuple{Symbol,Int64}, Float64}()
P_DL_ct = Dict{ Tuple{Symbol,Int64}, Float64}()
E_Req   = Dict{ Tuple{Symbol,Int64}, Float64}()

# Fills parameters using loaded data
for i = 1:length(DEFERRABLE)
    E_Cap[(DEFERRABLE[i])] = E_Cap_dat[i, 2]
    for j in TIMES
        C_DL_dn[(DEFERRABLE[i], C_DL_dn_dat[j, 2])] = C_DL_dn_dat[
            (i-1)*length(DEFERRABLE)+j,
            3,
        ]
        C_DL_ct[(DEFERRABLE[i], C_DL_ct_dat[j, 2])] = C_DL_ct_dat[
            (i-1)*length(DEFERRABLE)+j,
            3,
        ]
        R_up[(DEFERRABLE[i], R_up_dat[j, 2])] = R_up_dat[
            (i-1)*length(DEFERRABLE)+j,
            3,
        ]
        R_dn[(DEFERRABLE[i], R_dn_dat[j, 2])] = R_dn_dat[
            (i-1)*length(DEFERRABLE)+j,
            3,
        ]
        P_DL_dn[(DEFERRABLE[i], P_DL_dn_dat[j, 2])] = P_DL_dn_dat[
            (i-1)*length(DEFERRABLE)+j,
            3,
        ]
        P_DL_ct[(DEFERRABLE[i], P_DL_ct_dat[j, 2])] = P_DL_ct_dat[
            (i-1)*length(DEFERRABLE)+j,
            3,
        ]
        E_Req[(DEFERRABLE[i], E_Req_dat[j, 2])] = E_Req_dat[
            (i-1)*length(DEFERRABLE)+j,
            3,
        ]
    end
end
