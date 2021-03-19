module RelaxAndFix

using JuMP
using Gurobi
using CPLEX
using Data
using Parameters

export RelaxAndFixStandardFormulation

function RelaxAndFixStandardFormulation(inst::InstanceData, params)
  
  N = inst.N

  nbsubprob = ceil(N/params.fixsizerf)
  maxtimesubprob = params.maxtimerf/nbsubprob

  ### select solver ###
  if params.solver == "Gurobi"
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "TimeLimit", params.maxtimerf)
    set_optimizer_attribute(model, "MIPGap", params.tolgaprf)
    set_optimizer_attribute(model, "Threads", 1)
  elseif params.solver == "Cplex"
    model = Model(Cplex.Optimizer)
    set_optimizer_attribute(model, "CPX_PARAM_TILIM", params.maxtimerf)
    set_optimizer_attribute(model, "CPX_PARAM_EPGAP", params.tolgaprf)
    set_optimizer_attribute(model, "Threads", 1)
  else
    println("No solver selected")
    return 0
  end

  ### Defining variables ###
  ### variables ###
  @variable(model,0 <= x[t=1:N] <= Inf)
  @variable(model,0 <= xr[t=1:N] <= Inf)
  @variable(model, y[t=1:N], Bin)
  @variable(model, yr[t=1:N], Bin)
  @variable(model,0 <= s[t=1:N] <= Inf)
  @variable(model,0 <= sr[t=1:N] <= Inf)

  ### Objective function ###
  @objective(model, Min, sum(inst.P[t]*x[t] + inst.H[t]*s[t] + inst.F[t]*y[t] for t=1:N) + sum(inst.PR[t]*xr[t] + inst.HR[t]*sr[t] + inst.FR[t]*yr[t] for t=1:N))

  ### Balance constraints ###
  @constraint(model, balance0, x[1] + xr[1] - s[1] == inst.D[1])

  @constraint(model, balance[t=2:N], s[t-1] + x[t] + xr[t] - s[t] == inst.D[t])

  @constraint(model, balanceR0, -xr[1] - sr[1] == - inst.R[1])

  @constraint(model, balanceR[t=2:N], sr[t-1] - xr[t] - sr[t] == - inst.R[t])

  @constraint(model, setup[t=1:N], x[t] <= sum(inst.D[k] for k in t:inst.N)*y[t])

  @constraint(model, setupR[t=1:N], xr[t] <= min(sum(inst.D[k] for k in t:N),sum(inst.R[k] for k in 1:t))*yr[t])
  
  #@constraint(model, setupR[t=1:inst.N], xr[t] <= min(SD[1,t],SR[t,inst.N])*yr[t])

  undo_relax = relax_integrality(model)
  
  ## set k and kprime according to the initial parameters
  k = params.horsizerf
  kprime = params.fixsizerf

  time = 0
  alpha = 1
  beta = min(alpha + k - 1, N)
  
  while(beta <= N)
  
    println("********** RELAX AND FIX [$(alpha), $(beta)] **********")
    t1 = time_ns()
    
    if(alpha > 1)
    
      println("%%%%%%%%%% Fixed variables %%%%%%%%%%")
      
      ### Define fixed variables y ###
      for t in 1:alpha-1
        if value(y[t]) >= 0.9
          if is_binary(y[t])
            unset_binary(y[t])
          end
          set_lower_bound(y[t],1.0)
        end
      end
      
      ### Define fixed variables yr ###
      for t in 1:alpha-1
        if value(yr[t]) >= 0.9
          if is_binary(yr[t])
            unset_binary(yr[t])
          end
          set_lower_bound(yr[t],1.0)
        end
      end

    end

    println("%%%%%%%%%% Integer variables %%%%%%%%%%")
    ### Define integer variables y ###
    for t in alpha:beta
      set_binary(y[t])
    end
    
    ### Define integer variables yr ###
    for t in alpha:beta
      set_binary(yr[t])
    end

    println("%%%%%%%%%% Relax variables %%%%%%%%%%")
    ### Define relax variables y ###
    for t in beta+1:N
      if is_binary(y[t]) == true
        unset_binary(y[t])
      end
    end

    ### Define relax variables yr ###
    for t in beta+1:N
      if is_binary(yr[t]) == true
        unset_binary(yr[t])
      end
    end

    status = optimize!(model)

    alpha = alpha + kprime
    if beta == N
      beta = N+1
    else
      beta = min(alpha + k -1,N)
    end
    t2 = time_ns()
    time += (t2-t1)/1.0e9
  end

  bestsol = objective_value(model)
  ysol = ones(Int,N)
  for t in 1:N
    if value(y[t]) >= 0.99
      ysol[t] = 1
    else
      ysol[t] = 0
    end
  end

  ### Reset integrality requirements and bounds to default
  for t in 1:N
    if is_binary(y[t])
      unset_binary(y[t])
    end
    set_lower_bound(y[t],0.0)
  end
  
  for t in 1:N
    if is_binary(yr[t])
      unset_binary(yr[t])
    end
    set_lower_bound(yr[t],0.0)
  end
  
  ### print solutions ###
  if params.method == "rf"
    open("saida.txt","a") do f
      write(f,";$(params.method);$bestsol;$time\n")
    end
  end
  
  return ysol, bestsol, time

end

end
