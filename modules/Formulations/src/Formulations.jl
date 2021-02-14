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

  SD = zeros(Int,N,N)
  SR = zeros(Int,N,N)

  for i=1:N
    SD[i,i] = inst.D[i]
    SR[i,i] = inst.R[i]
    for j=(i+1):N
      SD[i,j] = SD[i,j-1] + inst.D[j]
      SR[i,j] = SR[i,j-1] + inst.R[j]
    end
  end

  if params.solver == "Gurobi"
    model = Model(Gurobi.Optimizer)
    #model = Model(solver = GurobiSolver(TimeLimit=params.maxtime,MIPGap=params.tolgap,CliqueCuts=0, CoverCuts=0, FlowCoverCuts=0,FlowPathCuts=0,MIRCuts=0,NetworkCuts=0,GomoryPasses=0, PreCrush=1,NodeLimit=params.maxnodes))
    #model = Model(solver = GurobiSolver(TimeLimit=params.maxtime,MIPGap=params.tolgap,CliqueCuts=0, CoverCuts=0, FlowCoverCuts=0,FlowPathCuts=0,MIRCuts=0,NetworkCuts=0,GomoryPasses=0, PreCrush=1))
    #model = Model(solver = GurobiSolver(TimeLimit=params.maxtime,MIPGap=params.tolgap,PreCrush=1,NodeLimit=params.maxnodes))
    #model = Model(solver = GurobiSolver(TimeLimit=params.maxtime,MIPGap=params.tolgap,PreCrush=1))
  elseif params.solver == "Cplex"
    #model = Model(solver = CplexSolver(CPX_PARAM_TILIM=params.maxtime,CPX_PARAM_EPGAP=params.tolgap))
    model = Model(Cplex.Optimizer)
  else
    println("No solver selected")
    return 0
  end

  ### Defining variables ###
  @variable(model,0 <= x[t=1:N] <= Inf)
  @variable(model,0 <= xr[t=1:N] <= Inf)
  @variable(model, y[t=1:N], Bin)
  @variable(model, yr[t=1:N], Bin)
  @variable(model,0 <= s[t=0:N] <= Inf)
  @variable(model,0 <= sr[t=0:N] <= Inf)

  ### Objective function ###
  @objective(model, Min, sum(inst.P[t]*x[t] + inst.H[t]*s[t] + inst.F[t]*y[t] for t=1:N) + sum(inst.PR[t]*xr[t] + inst.HR[t]*sr[t] + inst.FR[t]*yr[t] for t=1:N))

  ### Constraints ###
  @constraint(model, balance0, x[1] + xr[1] - s[1] == inst.D[1])

  @constraint(model, balance[t=2:N], s[t-1] + x[t] + xr[t] - s[t] == inst.D[t])

  @constraint(model, balanceR0, -xr[1] - sr[1] == - inst.R[1])

  @constraint(model, balanceR[t=2:N], sr[t-1] - xr[t] - sr[t] == - inst.R[t])

  @constraint(model, setup[t=1:N], x[t] <= sum(inst.D[k] for k in t:inst.N)*y[t])

  @constraint(model, setupR[t=1:N], xr[t] <= min(sum(inst.D[k] for k in t:N),sum(inst.R[k] for k in 1:t))*yr[t])
#  @constraint(model, setupR[t=1:inst.N], xr[t] <= min(SD[1,t],SR[t,inst.N])*yr[t])

  print(model)

  #write_to_file(model,"modelo.lp")

  # Solving the optimization problem
  optimize!(model)

  bestsol = objective_value(model)
  bestbound = objective_bound(model)
  numnodes = node_count(model)
  time = solve_time(model)
  gap = MOI.get(model, MOI.RelativeGap()) 
#  gap = 100*(bestsol-bestbound)/bestsol
  
  open("saida.txt","a") do f
    write(f,";$(params.form);$bestbound;$bestsol;$gap;$time;$numnodes;$(params.disablesolver) \n")
  end

#  if params.printsol == 1
#    printStandardFormulationSolution(inst,x,y,s,xr,yr,sr)
#  end

end #function standardFormulation()

end
