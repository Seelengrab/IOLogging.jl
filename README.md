# IOLogging.jl

A simple, thin package providing basic loggers for logging to IO. As the logging functionality from Base might change in the future, so will this package.

## Usage

```julia
julia> using Base.CoreLogging, IOLogging

julia> logger = IOLogger()

julia> oldGlobal = global_logger(logger)

julia> @info "Hello World!"

# prints this (with a current timestamp):
# [Info::2018-09-12T10:50:12.884]  Main@REPL[4]:1 - Hello World!
```

We can also pass our own destinations for Logging:

```julia
julia> logger = IOLogger(Dict(Base.CoreLogging.Info => stderr, Base.CoreLogging.Error => devnull)) # default is stdout for everything above Info
```

The same as above applies to `FileLogger()` as well, but instead of giving destination IO, we specify a destination file.

```julia
julia> logger = FileLogger(Dict(Base.CoreLogging.Info => "info.log", Base.CoreLogging.Error => "error.log")) # default is default.log for everything above Info
```

For more information about the individual loggers, make sure to read `?IOLogger` and `?FileLogger`.

## Known Issues

 * The `maxlog` keyword is theoretically supported, but doesn't work at the moment. See [this](https://github.com/JuliaLang/julia/issues/28786) issue in Base.
