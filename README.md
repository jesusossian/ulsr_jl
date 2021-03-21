# ulsr_jl

uncapacitated lot size problem with return

Configurar arquivo 
modules/Parameters/src/Parameters.jl
com informações dos parametros a serem utilizado.

Instancia:
  instName = "instances/sifaleras/52_1.txt"

Resolvendo o exato:
  method = "mip"
  
Formulação: 
  form = "std"
  
Definindo o solver:
  solver = "Gurobi"
  maxtime = 3600
  tolgap = 0.000001
  printsol = 0
  disablesolver = 0
  maxnodes = 10000000.0
  
Método relax-and-fix
  method = "rf"
  
Parametros do relax-and-fix:
  horsizerf = 3
  fixsizerf = 2
  maxtimerf = 360
  tolgaprf = 0.000001
  
Método fix-and-optimize
  method = "rffo"
  
Parametros do fix-and-optimize
  horsizefo = 3
  maxhorsizefo = 3
  fixsizefo = 2
  maxfixsizefo = 2
  maxtimefo = 360
  tolgapfo = 0.000001
  

Julia 1.5.3
"Gurobi" => v"0.9.11"
"CPLEX"  => v"0.7.6"
"JuMP"   => v"0.21.6"
