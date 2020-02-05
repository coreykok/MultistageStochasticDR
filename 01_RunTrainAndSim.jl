#=
=========================================================================
(c) Danmarks Tekniske Universitet 2020

Script         : Multistage stochastic DR dispatch - utilising SDDP
Author         : Corey Kok
Project        : -
=========================================================================
Input          : - Description of DR units
                 - Demand and wind forecast

Output         : - Policies with different risk measures used to train the model
                 - .csv files storing the output from simulations that test each
                   policy
=========================================================================
=#

using SDDP, JuMP, Ipopt, GLPK, CSV, DataFrames, Random, Gurobi

gurobi_env = Gurobi.Env()

function string_as_varname(s::String, v::Any)
    s = symbol(s)
    @eval (($s) = ($v))
end

# Load data and train models to create policies that focus on optimising
# different objectives
include("02_LoadInput.jl") # Input loaded from .csv files
include("03_DefineDataFrames.jl") # Empty data frames (used for output) created
include("04_ModelDefinition.jl") # Multistage stochastic problem defined
include("05_TrainModel.jl") # Each model trained according to different measures
include("06_ModelSimulation.jl") # In sample simulation performed
include("07_SimulationToDataframe.jl") # Output from simulation stored to DFs
include("08_SaveOutput.jl") # Data framed stored to .csv files

# Out of sample comparison between models
include("09_LoadInputOutOfSample.jl") # New scenrio and probability measure
include("07_SimulationToDataframe.jl") # Empty data frame created again
include("08_SaveOutput2.jl") # Data stored in new data frames
