module Parameters

struct ParameterData
  instName::String
  method::String ### mip, rf
  form::String ### std
  solver::String
  maxtime::Int
  tolgap::Float64
  printsol::Int
  disablesolver::Int
  maxnodes::Int
  horsizerf::Int
  fixsizerf::Int
  maxtimerf::Int
  tolgaprf::Float64
end

export ParameterData, readInputParameters

function readInputParameters(ARGS)
  ### Set standard values for the parameters ###
  instName = "instances/sifaleras/52_1.txt"
  method = "rf"
  form = "std"
  solver = "Gurobi"
  maxtime = 3600
  tolgap = 0.000001
  printsol = 0
  disablesolver = 0
  maxnodes = 10000000.0

  horsizerf = 3
  fixsizerf = 2
  maxtimerf = 60
  tolgaprf = 0.0001

  ### Read the parameters and set correct values whenever provided ###
  for param in 1:length(ARGS)
    if ARGS[param] == "--inst"
      instName = ARGS[param+1]
      param += 1
    elseif ARGS[param] == "--method"
      method = ARGS[param+1]
      param += 1
    elseif ARGS[param] == "--form"
      form = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--solver"
      solver = ARGS[param+1]
      param += 1
    elseif ARGS[param] == "--maxtime"
      maxtime = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--tolgap"
      tolgap = parse(Float64,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--printsol"
      printsol = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--disablesolver"
      disablesolver = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--maxnodes"
      maxnodes = parse(Float64,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--horsizerf"
      horsizerf = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--fixsizerf"
      fixsizerf = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--maxtimerf"
      maxtimerf = parse(Int,ARGS[param+1])
      param += 1
    elseif ARGS[param] == "--tolgaprf"
      tolgaprf = parse(Float64,ARGS[param+1])
      param += 1
    end
  end

  params = ParameterData(instName,method,form,solver,maxtime,tolgap,printsol,disablesolver,maxnodes,horsizerf,fixsizerf,maxtimerf,tolgaprf)

  return params

end ### end readInputParameters

end ### end module
