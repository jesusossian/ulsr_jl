module FixAndOptimize

using JuMP
using Gurobi
using CPLEX
using Data
using Parameters

export FixAndOptimizeStandardFormulation

function FixAndOptimizeStandardFormulation(inst::InstanceData, params, ysol, bestsol,timerf)

  N = inst.N
  
  bestsolrf = bestsol
  
  nbsubprob = ceil(N/params.fixsizefo)
  maxtimesubprob = params.maxtimefo/nbsubprob

  ### select solver ###
  if params.solver == "Gurobi"
    model = Model(Gurobi.Optimizer)
    set_optimizer_attribute(model, "TimeLimit", params.maxtimefo)
    set_optimizer_attribute(model, "MIPGap", params.tolgapfo)
    set_optimizer_attribute(model, "Threads", 1)
  elseif params.solver == "Cplex"
    model = Model(Cplex.Optimizer)
    set_optimizer_attribute(model, "CPX_PARAM_TILIM", params.maxtimefo)
    set_optimizer_attribute(model, "CPX_PARAM_EPGAP", params.tolgapfo)
    set_optimizer_attribute(model, "Threads", 1)
  else
    println("No solver selected")
    return 0
  end

  ### Defining variables ###
  ### variables ###
  @variable(model, 0 <= x[t=1:N] <= Inf)
  @variable(model, 0 <= xr[t=1:N] <= Inf)
  @variable(model, y[t=1:N], Bin)
  @variable(model, yr[t=1:N], Bin)
  @variable(model, 0 <= s[t=1:N] <= Inf)
  @variable(model, 0 <= sr[t=1:N] <= Inf)

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

  ### Fix and optimize ###
  println("********** FIX AND OPTIMIZE **********")

  k = params.horsizefo
  kprime = params.fixsizefo
  maxk = params.maxhorsizefo
  maxkprime = params.maxfixsizefo

  time = 0

  alpha = 1
  beta = min(alpha + k - 1, N)

  for t in 1:N
    set_start_value(y[t], ysol[t])
  end

  for it2 in kprime:maxkprime
    #println(kprime, "  ", maxkprime)
    #println(k, " ", kprime+1, " <? ", maxk)
    
    for it in max(k, kprime+1):maxk
      println("########## RESTARTING FIX AND OPTIMIZE with k=$(it) and kprime=$(it2) ##########")
      proceed = true
    
      while (proceed && time + maxtimesubprob <= params.maxtimefo )
        proceed = false
        
        alpha = 1
    	beta = min(alpha + k - 1, N)
    
    	while(beta <= N && time + maxtimesubprob <= params.maxtimefo)
    	  println("########## FIX AND OPTIMIZE [$(alpha), $(beta)] ##########")
          
          t1 = time_ns()
          
          for t in 1:N
            if ysol[t] == 1
              set_lower_bound(y[t], 1) ## problem
            else
		      set_lower_bound(y[t], 0) ## problem
            end
    	  end
		  
          for t in alpha:beta
    	    set_lower_bound(y[t], 0) ## problem
		  end

		  optimize!(model)
    
    	  if objective_value(model) < bestsol - 0.01
    	  
    	    if objective_value(model) < bestsol - 0.5
    		  proceed = true
    		end
    
    		bestsol = objective_value(model)   
    	    for t in 1:N
              if value(y[t]) >= 0.99
    	        ysol[t] = 1
    		  else
    			ysol[t] = 0
    		  end
            end
            
          end

          alpha = alpha + kprime
		  if beta == N
		    beta = N+1
		  else
		    beta = min(alpha + k -1, N)
		  end

		  t2 = time_ns()
		  time += (t2-t1)/1.0e9
		  
        end
      end
    end
  end

  ### print solutions ###
  if params.method == "rffo"
    open("saida.txt","a") do f
      write(f,";$(params.method);$bestsolrf;$timerf;$bestsol;$time\n")
    end
  end

  return ysol

end

end
