using PackageCompiler 

create_sysimage([:JuMP,:Gurobi,:CPLEX]; sysimage_path="sysimage.dylib", precompile_execution_file="ulsr.jl")
