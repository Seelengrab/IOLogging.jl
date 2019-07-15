using Pkg
Pkg.activate(".")

using Revise

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

#
# Configure the log files
#
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


# First test with a module that is explicitely associated to a log file
MyModule1.MySubModule1.sayhello()

# Test the fallback mechanism when the module is not associated to a log file
#  but one of its ancestors is.
MyModule2.MySubModule1.sayhello()

# Test the logging for the 'Main' module
@info "Should appear in main.log"

# Failed attempt to create some unit tests
# mktempdir(@__DIR__) do dir
#     cd(dir) do
#         @testset "Assertions" begin
#             #
#             # Create the logger and set it as the global logger
#             multifilesLogger =
#                 MultifilesLogger([fileDef1,fileDef2,fileDef3])
#
#             global_logger(multifilesLogger)
#
#             # Let the time to create the log files
#             sleep(2)
#
#             # First test with a module that is explicitely associated to a log file
#             MyModule1.MySubModule1.sayhello()
#
#             # Test the fallback mechanism when the module is not associated to a log file
#             #  but one of its ancestors is.
#             MyModule2.MySubModule1.sayhello()
#
#             # Let the time to go check the content of the log files
#             sleep(15)
#
#             lines = readlines("first.log", keep = true)
#             # println(lines[1])
#             # @test occursin("MyModule1.MySubModule1 sayhello", lines[1])
#         end
#     end
# end
