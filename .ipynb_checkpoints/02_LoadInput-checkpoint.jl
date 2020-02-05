# '''
# =========================================================================
# (c) Danmarks Tekniske Universitet 2020
# 
# Script         : Load and process data from .csv files
# Author         : Corey Kok
# Project        : -
# =========================================================================
# Input          : - Thermostatically-Controlled-Load data
#                  - Deferrable-Load data
#                  - Conventional demand response data
#                  - Wind and Demand data
# 
# Output         : - C_Con_up # Cost for conventional upregulation
#                  - C_Con_dn # Cost for conventional downregulation
#                  - C_Con_DA # Cost for commitment of day ahead conventional gen
#                  - P_Con_up # Capacity for conventional upgregulation
#                  - P_Con_dn # Capacity for conventional downregulation
#                  - E_Cap # Capacity of deferrable load device
#                  - C_DL_dn # Cost to charge deferrable load device
#                  - C_DL_ct # Cost to curtail charging device
#                  - R_up # Limit on the ramp up rate for the DL device
#                  - R_dn # Limit on the ramp down rate for the DL device
#                  - P_DL_dn # Capacity on the charging rate for the DL device
#                  - P_DL_ct # Maximum power curtailment for the DL device
#                  - E_Req # Required amount of energy at end of horizon
# =========================================================================
# '''

############# SIMULATION PARAMETERS #############

r_seed_train = 1252 # Random seed multiplier to train model
r_seed_simulate = 12314 # Random seed to simulate model
SIM_NUM = 200 # Number of times model is simulated

# Definition in Worst Case risk function (A little weight on expectation)
lambda = 1e-4 # Weighting on expectation
WorstCase_RM = lambda * SDDP.Expectation() + (1 - lambda) * SDDP.WorstCase()

# Defines an array of random seeds to both train and simulate each model
rand_ST = (1:50) * r_seed_train # Array of training random seeds
rand_SS =  (1:50) * r_seed_simulate # Array of simultaion random seeds

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


############# EXOGENOUS PARAMETERS #############

# Transition matrix definition
T_Matrix = Array{Float64, 2}[
    [1/4 1/4 1/4 1/4],
    [1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4],
    [1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4],
    [1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4],
    [1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4],
    [1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4; 1/4 1/4 1/4 1/4]
]

# Uncertainty parameter definition (for now only uncertainty in wind output)
# The only uncontrollable source of generation is assumed to come from wind
Ω = [
    (Wind = 2.0, fuel_multiplier = 1),
    (Wind = 3.0, fuel_multiplier = 1),
    (Wind = 4.0, fuel_multiplier = 1),
    (Wind = 5.0, fuel_multiplier = 1),
]

# Power demand
Demand_dat = CSV.read(join([pwd(),"/Input/Demand.csv"]),
    header=false, delim=',', types = [Int64,Float64]) # Read demand from .csv
Demand = Dict{Int64, Float64}()
for i = TIMES
    Demand[i] = Demand_dat[i,2] # Load demand data into variable
end


############# CONVENTIONAL LOAD #############

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

C_Con_up = Dict{ Tuple{Symbol,Int64}, Float64}()
C_Con_dn = Dict{ Tuple{Symbol,Int64}, Float64}()
C_Con_DA = Dict{ Tuple{Symbol,Int64}, Float64}()
P_Con_up = Dict{ Tuple{Symbol,Int64}, Float64}()
P_Con_dn = Dict{ Tuple{Symbol,Int64}, Float64}()

for i = 1:length(CONVENTIONAL)
    for j = TIMES
        C_Con_up[(CONVENTIONAL[i],C_Con_up_dat[j,2])] = C_Con_up_dat[(i-1)*length(CONVENTIONAL) + j,3]
        C_Con_dn[(CONVENTIONAL[i],C_Con_dn_dat[j,2])] = C_Con_dn_dat[(i-1)*length(CONVENTIONAL) + j,3]
        C_Con_DA[(CONVENTIONAL[i],C_Con_DA_dat[j,2])] = C_Con_DA_dat[(i-1)*length(CONVENTIONAL) + j,3]
        P_Con_up[(CONVENTIONAL[i],P_Con_up_dat[j,2])] = P_Con_up_dat[(i-1)*length(CONVENTIONAL) + j,3]
        P_Con_dn[(CONVENTIONAL[i],P_Con_dn_dat[j,2])] = P_Con_dn_dat[(i-1)*length(CONVENTIONAL) + j,3]
    end
end

############# DEFERRABLE LOAD #############

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

E_Cap = Dict{ Symbol, Float64}()
C_DL_dn = Dict{ Tuple{Symbol,Int64}, Float64}()
C_DL_ct = Dict{ Tuple{Symbol,Int64}, Float64}()
R_up    = Dict{ Tuple{Symbol,Int64}, Float64}()
R_dn    = Dict{ Tuple{Symbol,Int64}, Float64}()
P_DL_dn = Dict{ Tuple{Symbol,Int64}, Float64}()
P_DL_ct = Dict{ Tuple{Symbol,Int64}, Float64}()
E_Req   = Dict{ Tuple{Symbol,Int64}, Float64}()
for i = 1:length(DEFERRABLE)
    E_Cap[(DEFERRABLE[i])] = E_Cap_dat[i,2]
    for j = TIMES
        C_DL_dn[(DEFERRABLE[i],C_DL_dn_dat[j,2])] = C_DL_dn_dat[(i-1)*length(DEFERRABLE) + j,3]
        C_DL_ct[(DEFERRABLE[i],C_DL_ct_dat[j,2])] = C_DL_ct_dat[(i-1)*length(DEFERRABLE) + j,3]
        R_up[(DEFERRABLE[i],R_up_dat[j,2])] = R_up_dat[(i-1)*length(DEFERRABLE) + j,3]
        R_dn[(DEFERRABLE[i],R_dn_dat[j,2])] = R_dn_dat[(i-1)*length(DEFERRABLE) + j,3]
        P_DL_dn[(DEFERRABLE[i],P_DL_dn_dat[j,2])] = P_DL_dn_dat[(i-1)*length(DEFERRABLE) + j,3]
        P_DL_ct[(DEFERRABLE[i],P_DL_ct_dat[j,2])] = P_DL_ct_dat[(i-1)*length(DEFERRABLE) + j,3]
        E_Req[(DEFERRABLE[i],E_Req_dat[j,2])] = E_Req_dat[(i-1)*length(DEFERRABLE) + j,3]
    end
end

# SET UP DATA FRAMES FOR OUTPUT
df_Input = DataFrame(
               Seed = Int[],
               SimNum = Int[],
               Stage = Int[],
               Scenario = Float64[],
               Demand = Float64[],
               Wind = Float64[],
               c_DA = Float64[],
               Model = String[])
df_Solution = DataFrame(
                Seed = Int[],
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
                cost_d_dn = Float64[],
                cost_d_ct = Float64[],
                Model = String[])
df_Objective = DataFrame(
                Seed = Int[],
                SimNum = Int[],
                Stage = Int[],
                Scenario = Float64[],
                Model = String[],
                Cost = Float64[])