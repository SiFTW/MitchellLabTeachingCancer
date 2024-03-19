parametersFile=combinedModelLocation*"parameters.csv"
reactionsFile=combinedModelLocation*"reactions.csv"
rateLawsFile=combinedModelLocation*"rateLaws.csv"
parametersDF = DataFrame(CSV.File(parametersFile,types=Dict(:parameter=>String, :value=>String)))
originalParams=deepcopy(parametersDF)

thisModelName="odeModel.jl"
thisParamFile=parametersFile
arguments=[reactionsFile, thisParamFile, rateLawsFile,thisModelName]
cmd=`python3 $locationOfCSV2Julia $arguments param`

#lets run csv2julia (requires python to be installed)
run(cmd)

include(thisModelName)
mkpath("distributedModelFiles")
mv(thisModelName,"distributedModelFiles/"*thisModelName, force=true)
println("Model generated for all conditions")