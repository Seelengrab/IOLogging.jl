using Pkg
Pkg.activate(".")

using IOLogging
using Logging
using Logging: Debug, Info, Warn, Error, BelowMinLevel, with_logger, min_enabled_level
using Test

# TODO make some real tests sets

# Declare
module MyModule1
    module MySubModule1
        sayhello() = @info "MyModule1.MySubModule1 sayhello"

        module MySubSubModule1
        end
    end
    module MySubModule2
        sayhello() = @info "MyModule1.MySubModule2 sayhello"
    end
end

module MyModule2
    module MySubModule1
        sayhello() = @info "MyModule2.MySubModule1 sayhello"
    end
    module MySubModule2
        sayhello() = @info "MyModule2.MySubModule2 sayhello"
    end
end

module MyModule3
    sayhello() = @info "MyModule3 sayhello"
end

#
# Configure the log files
#
fileDef1 = FileDefForMultifilesLogger("first.log",
                                      [(MyModule1.MySubModule1,Info),
                                       (MyModule1.MySubModule2,Info)],
                                      )

fileDef2 = FileDefForMultifilesLogger("second.log",
                                        [(MyModule2,Info)],
                                        )

fileDef3 = FileDefForMultifilesLogger("main.log",
                                        [(Main,Info)];
                                        append = false
                                        )

# Create the logger and set it as the global logger
multifilesLogger =
    MultifilesLogger([fileDef1,fileDef2,fileDef3])

global_logger(multifilesLogger)

# First test with a module that is explicitely associated to a log file
MyModule1.MySubModule1.sayhello()

# Test the fallback mechanism when the module is not associated to a log file
#  but one of its ancestors is.
MyModule2.MySubModule1.sayhello()

# Test the logging for the 'Main' module
@info "Should appear in main.log"

# Test what happens when there is no IO on the Main module and that a module
#   is missing its IO
multifilesLogger =
    MultifilesLogger([fileDef1,fileDef2])

global_logger(multifilesLogger)

MyModule3.sayhello()
