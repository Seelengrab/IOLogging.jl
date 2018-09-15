"""
A generic file logger for logging to files. Flushes the necessary output stream after each write (i.e. after each logging event) and closes the files on finalizing.

    FileLogger(logPaths = Dict(Info => "default.log"))

Logs logging events with LogLevel greater than or equal to `Info` to "default.log", should no `logPaths` be given. In case two LogLevels are present, e.g. `Info` and `Error`, all logging events from `Info` up to (but excluding) `Error` will be logged to the file given by `Info`. `Error` and above will be logged to the file given by `Error`. It is possible to "clamp" logging events, by providing an upper bound that's logging to `/dev/null` on Unix/Mac or `NUL` on Windows. Beware, as the message will still be composed before writing to the actual file (no hotwiring).

By default, exceptions occuring during logging are not caught. This is expected to change in the future, once it's decided how exceptions during logging should be handled.
"""
struct FileLogger <: _iologger
    logPaths::Dict{LogLevel, AbstractString}
    logIOs::Dict{LogLevel, T} where T <: IO
    messageLimits::Dict{Any, Int}

    FileLogger(logPaths::Dict{LogLevel, String} = Dict(Info => "default.log")) = new(logPaths, Dict{LogLevel,IO}(), Dict{Any, Int}())
end

CoreLogging.min_enabled_level(logger::FileLogger) = minimum(collect(keys(logger.logPaths)))

function getIO(logger::FileLogger, level::LogLevel)
    posFiles = filter(l -> l[1] <= level, collect(logger.logPaths))
    if !isempty(posFiles)
        chosenLevel = sort(posFiles, by = x -> x[1], rev = true)[1][1]
        # Make sure the IO is open
        if !haskey(logger.logIOs, chosenLevel)
            log = open(logger.logPaths[chosenLevel], "a")
            finalizer(_ -> close(log), log) # close flushes
            logger.logIOs[chosenLevel] = log
        end

        logger.logIOs[chosenLevel]
    else
        devnull
    end
end

CoreLogging.handle_message(logger::FileLogger,
                        level,
                        message,
                        _module,
                        group,
                        id,
                        file,
                        line;
                        maxlog = nothing,
                        kwargs...) = begin
    # Should we log this?
    if !checkLimits(logger, id, maxlog)
        return
    end

    io = getIO(logger, level)
    log!(io, level, string(message), _module, group, file, line; kwargs...)
    flush(io)
    nothing
end
