# Benchmarks

Set up the benchmark environment from the repository root:

```julia
julia --project=benchmark -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
```

Run and save the suite under a descriptive name:

```julia
julia --project=benchmark -L benchmark/runbenchmarks.jl -e 'run_benchmarks("main")'
```

Generate a standalone report or compare two saved runs:

```julia
julia --project=benchmark -L benchmark/runbenchmarks.jl -e 'generate_report("main")'
julia --project=benchmark -L benchmark/runbenchmarks.jl -e 'generate_report("main", "branch")'
```

Benchmark parameters and results are stored as ignored JSON files under
`benchmark/`.
