"""
A multiple files logger for logging to files depending on the module.

    fileDef1 = FileDefForMultifilesLogger("first.log",
                                          true, # append
                                          [(MyModule1.MySubModule1,Info),(MyModule1.MySubModule2,Info)],
                                          )

    fileDef2 = FileDefForMultifilesLogger("second.log",
                                            true, # append
                                            [(MyModule2,Info)],
                                            )

    fileDef3 = FileDefForMultifilesLogger("main.log",
                                            true, # append
                                            [(Main,Info)],
                                            )

    # Create the logger and set it as the global logger
    multifilesLogger =
        MultifilesLogger([fileDef1,fileDef2,fileDef3])

    global_logger(multifilesLogger)


"""
struct MultifilesLogger <: _iologger
    filesDefs::Vector{FileDefForMultifilesLogger}
    logIOs::Dict{Module, Tuple{T,LogLevel}} where T <: IO
    messageLimits::Dict{Any, Int}
    flush::Bool

    MultifilesLogger(
        filesDefs::Vector{FileDefForMultifilesLogger};
        flush = true) = (x = new(filesDefs,
                             Dict{Module, Tuple{IO, LogLevel}}(),
                             Dict{Any, Int}(),
                             flush);
                           createIOs!(x);
                           return x
                             )
end

struct FileDefForMultifilesLogger

    filePath::String
    append::Bool
    modulesAndLogLevels::Vector{Tuple{Module,LogLevel}}

end

# CoreLogging.min_enabled_level(logger::MultifilesLogger) = minimum(collect(keys(logger.logPaths)))
CoreLogging.min_enabled_level(logger::MultifilesLogger) = Info

function createIOs!(logger::MultifilesLogger)

    for fileDef in logger.filesDefs

        # Open one IO per Tuple{Module,LogLevel}
        # NOTE: there can be several IOs pointing to the same file
        for t in fileDef.modulesAndLogLevels
            _module = t[1]
            _loglevel = t[2]
            logger.logIOs[_module] =  (open(fileDef.filePath, fileDef.append ? "a" : "w"),
                                       _loglevel)
        end

    end

end

function getIOLevelTuple!(logger::MultifilesLogger,
                         _module::Module,
                         Wlevel::LogLevel)

    # If a module has no IO we try to find one
    if !haskey(logger.logIOs,_module)
        original_module = _module
        # This stop condition is because 'parentmodule(Main) == Main'
        while parentmodule(_module) != _module
            _module = parentmodule(_module)

            # If the parent module has an IO we use it and we update the
            #   logger.logIOs so that the unreferenced module now points to the
            #   same IO as the parent module. This is done for performance
            if haskey(logger.logIOs,_module)
                # println("Update logger.logIOs")
                logger.logIOs[original_module] = logger.logIOs[_module]
                break
            end
        end

        # Throw an exception if no logger could be found for the parents
        if !haskey(logger.logIOs,_module)
            throw(DomainError("There is no logger defined for module[$(string(original_module))]"
                            * " and we were also unable to find a logger in the parents modules,"
                            * " not even a logger for the 'Main' module."))
        end

    end

    tuple_io_loglevel = logger.logIOs[_module]
    return tuple_io_loglevel

end


CoreLogging.handle_message(logger::MultifilesLogger,
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


    io_level_tuple = getIOLevelTuple!(logger, _module, level)

    io = io_level_tuple[1]
    loglevel_limit = io_level_tuple[2]

    # Check the the log level of the call is not below the limit
    if level < loglevel_limit
        return
    end

    log!(io, level, string(message), _module, group, file, line; kwargs...)

    logger.flush ? flush(io) : nothing
    nothing
end
