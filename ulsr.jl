push!(LOAD_PATH, "modules/")
# push!(DEPOT_PATH, JULIA_DEPOT_PATH)
using Pkg
# Pkg.activate(".")
# Pkg.instantiate()
# Pkg.build()

using JuMP
using Gurobi
using CPLEX

import Data
import Parameters
import Formulations
import RelaxAndFix

# Read the parameters from command line
params = Parameters.readInputParameters(ARGS)

# Read instance data
inst = Data.readData(params.instName,params)

if (params.method == "mip")
  if params.form == "std"
    Formulations.standardFormulation(inst, params)
  end
elseif (params.method == "rf")
  ysol, bestsol = RelaxAndFix.RelaxAndFixStandardFormulation(inst, params)
  println("Bestsol = $(bestsol)");
end
