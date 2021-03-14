module Formulations

using JuMP
using Gurobi
using CPLEX
using Data
using Parameters

mutable struct stdFormVars
  x
  y
  s
  xr
  yr
  sr
end

export standardFormulation, stdFormVars

function standardFormulation(inst::InstanceData, params::ParameterData)

  N = inst.N

#  SD = zeros(Int,N,N)
#  SR = zeros(Int,N,N)

#  for i=1:N
#    SD[i,i] = inst.D[i]
#    SR[i,i] = inst.R[i]
#    for j=(i+1):N
#      SD[i,j] = SD[i,j-1] + inst.D[j]
#      SR[i,j] = SR[i,j-1] + inst.R[j]
#    end
#  end

  ### select solver ###
  if params.solver == "Gurobi"
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "TimeLimit", params.maxtime) # Time limit
    set_optimizer_attribute(model, "MIPGap", params.tolgap) # Relative MIP optimality gap
    set_optimizer_attribute(model, "NodeLimit", params.maxnodes) # MIP node limit
#    set_optimizer_attribute(model, "Cuts", 2) # Global cut aggressiveness setting. 
    # Use value 0 to shut off cuts, 1 for moderate cut generation, 2 for aggressive cut generation, and 3 for very aggressive cut generation. 
    # This parameter is overridden by the parameters that control individual cut types (e.g., CliqueCuts).
    # Only affects mixed integer programming (MIP) models
#    set_optimizer_attribute(model, "CliqueCuts", 0) # Clique cut generation
#    set_optimizer_attribute(model, "CoverCuts", 0) # Cover cut generation
#    set_optimizer_attribute(model, "FlowCoverCuts", 0) # Flow cover cut generation
#    set_optimizer_attribute(model, "FlowPathCuts", 0) # Flow path cut generation
#    set_optimizer_attribute(model, "MIRCuts", 1) # MIR cut generation
#    set_optimizer_attribute(model, "NetworkCuts", 0) # Network cut generation
#    set_optimizer_attribute(model, "GomoryPasses", 0) # Root Gomory cut pass limit
#    set_optimizer_attribute(model, "PreCrush", 1) # Controls presolve reductions that affect user cuts
#    set_optimizer_attribute(model, "VarBranch", -1) # Branch variable selection strategy
    # Controls the branch variable selection strategy. 
    # The default -1 setting makes an automatic choice, depending on problem characteristics. 
    # Available alternatives are Pseudo Reduced Cost Branching (0), Pseudo Shadow Price Branching (1), Maximum Infeasibility Branching (2), and Strong Branching (3).
    #set_optimizer_attribute(model, "NodeMethod", 0) # Method used to solve MIP node relaxations
    # Algorithm used for MIP node relaxations (except for the root node, see Method). 
    # Options are: -1=automatic, 0=primal simplex, 1=dual simplex, and 2=barrier. 
    # Note that barrier is not an option for MIQP node relaxations.
#    set_optimizer_attribute(model, "BranchDir", -1) # Preferred branch direction
    # Determines which child node is explored first in the branch-and-cut search. 
    # The default value chooses automatically. 
    # A value of -1 will always explore the down branch first, while a value of 1 will always explore the up branch first.
#    set_optimizer_attribute(model, "Presolve", -1) # Controls the presolve level
    # A value of -1 corresponds to an automatic setting. 
    # Other options are off (0), conservative (1), or aggressive (2). 
    # More aggressive application of presolve takes more time, but can sometimes lead to a significantly tighter model.
#    set_optimizer_attribute(model, "Method", -1)
    # Algorithm used to solve continuous models or the root node of a MIP model. 
    # Options are: -1=automatic, 0=primal simplex, 1=dual simplex, 2=barrier, 3=concurrent, 4=deterministic concurrent, 5=deterministic concurrent simplex.
    set_optimizer_attribute(model, "Threads", 1)
    # Controls the number of threads to apply to parallel algorithms (concurrent LP, parallel barrier, parallel MIP, etc.). 
    # The default value of 0 is an automatic setting. 
    # It will generally use all of the cores in the machine, but it may choose to use fewer.

  elseif params.solver == "Cplex"
    model = Model(Cplex.Optimizer)
    set_optimizer_attribute(model, "CPX_PARAM_TILIM", params.maxtime)
    set_optimizer_attribute(model, "CPX_PARAM_EPGAP", params.tolgap)
  else
    println("No solver selected")
    return 0
  end

  ### variables ###
  @variable(model,0 <= x[t=1:N] <= Inf)
  @variable(model,0 <= xr[t=1:N] <= Inf)
  @variable(model, y[t=1:N], Bin)
  @variable(model, yr[t=1:N], Bin)
  @variable(model,0 <= s[t=1:N] <= Inf)
  @variable(model,0 <= sr[t=1:N] <= Inf)

  ### objective function ###
  @objective(model, Min, sum(inst.P[t]*x[t] + inst.H[t]*s[t] + inst.F[t]*y[t] for t=1:N) + sum(inst.PR[t]*xr[t] + inst.HR[t]*sr[t] + inst.FR[t]*yr[t] for t=1:N))

  ### constraints ###
  @constraint(model, balance0, x[1] + xr[1] - s[1] == inst.D[1])

  @constraint(model, balance[t=2:N], s[t-1] + x[t] + xr[t] - s[t] == inst.D[t])

  @constraint(model, balanceR0, -xr[1] - sr[1] == - inst.R[1])

  @constraint(model, balanceR[t=2:N], sr[t-1] - xr[t] - sr[t] == - inst.R[t])

  @constraint(model, setup[t=1:N], x[t] <= sum(inst.D[k] for k in t:inst.N)*y[t])

  @constraint(model, setupR[t=1:N], xr[t] <= min(sum(inst.D[k] for k in t:N),sum(inst.R[k] for k in 1:t))*yr[t])
  
  #@constraint(model, setupR[t=1:inst.N], xr[t] <= min(SD[1,t],SR[t,inst.N])*yr[t])

  #print(model)

  if params.method == "lp" 
    undo_relax = relax_integrality(model)
  end

  #write_to_file(model,"modelo.lp")

  ### solving the optimization problem ###
  optimize!(model)

  if termination_status(model) == MOI.OPTIMAL    
    println("status = ", termination_status(model))
  else
    #error("O modelo não foi resolvido corretamente!")
    println("status = ", termination_status(model))
    return 0
  end
    
  ### get solutions ###
  bestsol = objective_value(model)
  if params.method == "mip"
    bestbound = objective_bound(model)
    numnodes = node_count(model)
    gap = MOI.get(model, MOI.RelativeGap())
  end
  time = solve_time(model) 
  
  ### print solutions ###
  open("saida.txt","a") do f
    if params.method == "mip"
      write(f,";$(params.form);$bestbound;$bestsol;$gap;$time;$numnodes;$(params.disablesolver) \n")
    else
      write(f,";$(params.form);$bestsol;$time;$(params.disablesolver) \n")
    end
  end
  
  if params.printsol == 1
    printStandardFormulationSolution(inst,x,y,s,xr,yr,sr)
  end

end #function standardFormulation()

end
