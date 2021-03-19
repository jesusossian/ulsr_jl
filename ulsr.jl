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
import FixAndOptimize

# Read the parameters from command line
params = Parameters.readInputParameters(ARGS)

# Read instance data
inst = Data.readData(params.instName, params)

if (params.method == "mip")
  if params.form == "std"
    Formulations.standardFormulation(inst, params)
  end
elseif (params.method == "rf" || params.method ==  "rffo")
  ysol, bestsol, timerf = RelaxAndFix.RelaxAndFixStandardFormulation(inst, params)
  if params.method == "rffo"
    FixAndOptimize.FixAndOptimizeStandardFormulation(inst, params, ysol, bestsol, timerf)
  end
end
