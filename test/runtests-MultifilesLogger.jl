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

parentmodule(MyModule1.MySubModule1.MySubSubModule1)
parentmodule(MyModule1)

MyModule1.MySubModule1.sayhello()

# Prepare the configuration
#
logs_paths =  Dict("first.log" =>
                        [(MyModule1.MySubModule1,Info),(MyModule1.MySubModule2,Info)],
                    "second.log" => [(MyModule2,Info)],
                    "Main.log" => [(Main,Info)]
                    )

multifilesLogger = MultifilesLogger(
    logs_paths;flush = true, append = true)


global_logger(multifilesLogger)

MyModule1.MySubModule1.sayhello()
MyModule2.MySubModule1.sayhello()
