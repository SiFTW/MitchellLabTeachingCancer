function combineModels(modulesToInclude)
    ################################################
    ### Create a combined model from the modules ###
    ################################################
    #first lets tell Julia where the files are

    linkingModuleName="linking"
    combinedModelLocation="combinedModelDefinitionFiles/"
    mkpath(combinedModelLocation)


    #first lets load the linking file so we know to skip any reactions 
    #which are doubly described by the linking file and one of the modules
    linkingReactions=""
    if(delay)
        linkingReactions = DataFrame(CSV.File(moduleDefinitionFilesFolder*linkingModuleName*"/reactions_withDelay.csv",stringtype=String,types=String))
    else
        linkingReactions = DataFrame(CSV.File(moduleDefinitionFilesFolder*linkingModuleName*"/reactions.csv",stringtype=String,types=String))
    end
    linkingParameters = DataFrame(CSV.File(moduleDefinitionFilesFolder*linkingModuleName*"/parameters.csv",stringtype=String,types=String))
    linkingrateLaws = DataFrame(CSV.File(moduleDefinitionFilesFolder*linkingModuleName*"/rateLaws.csv",stringtype=String,types=String))

    #missing values mess things up so replace with empty strings
    replace!(linkingReactions.Substrate, missing => "")
    replace!(linkingReactions.Products, missing => "")

    #we know we need all the linking reactions in the combined model
    reactionsCombined=linkingReactions
    parametersCombined=linkingParameters
    linkingParameters[:,1]=linkingParameters[:,1].*("-"*"linking")
    theseParams=linkingReactions.Parameters
    replacementParams=""
    newParams=theseParams
    thisLine=1
    for param in theseParams
        if ismissing(param)
            thisLine=thisLine+1
        else
            eachParam=split(param," ")
            eachParam=[i*"-"*"linking" for i in eachParam]
            replacementParams=join(eachParam," ")
            newParams[thisLine]=replacementParams
            thisLine=thisLine+1
        end
    end
    linkingReactions.Parameters=newParams
    rateLawsCombined=linkingrateLaws

    # loop through each model
    for mod in modulesToInclude
        print("adding $(mod) module\n")

        thisModule=moduleDefinitionFilesFolder*mod
        #the NFkB file can have delays but the rest do not
        reactionFile=""
        if mod=="NFkB" && delay
            reactionFile=thisModule*"/reactions_withDelay.csv"
        else
            reactionFile=thisModule*"/reactions.csv"
        end
        parameterFile=thisModule*"/parameters.csv"
        rateLawsFile=thisModule*"/rateLaws.csv"

        parameterDF = CSV.read(parameterFile,DataFrame,stringtype=String,types=String)
        rateLawDF = CSV.read(rateLawsFile,DataFrame,stringtype=String,types=String)
        reactionDF = CSV.read(reactionFile,DataFrame,stringtype=String,types=String)
        #not every entry in the reaction database is filled in and missing data can cause a problem
        replace!(reactionDF.Substrate, missing => "")
        replace!(reactionDF.Products, missing => "")

        #keep track of rows to remove
        #these are rows that appear in individual module reaction files 
        #and are replaced by reactions in the linking module.
        rowsToRemove=[]
        thisRow=1
        for row in eachrow(reactionDF)
            if nrow(linkingReactions[(linkingReactions[!,"Substrate"].==row.Substrate).&(linkingReactions[!,"Products"].==row.Products),:])>0
                print("removing: $(row.Substrate) -> $(row.Products) as it is included in linking file\n")
                push!(rowsToRemove,thisRow)
            end
            thisRow=thisRow+1
        end
        delete!(reactionDF, rowsToRemove)
        print("adding module $(mod) to combined reaction array\n")

        #we need to append a module ID on each parameter name in the reactions file 
        #because some parameters have the same name in multiple modules
        theseParams=reactionDF.Parameters
        replacementParams=""
        newParams=theseParams
        thisLine=1
        for param in theseParams
            eachParam=split(param," ")
            eachParam=[i*"-"*mod for i in eachParam]
            replacementParams=join(eachParam," ")
            newParams[thisLine]=replacementParams
            thisLine=thisLine+1
        end
        reactionDF.Parameters=newParams
        append!(reactionsCombined,reactionDF)

        #do the same, prepending in the parameters file for the combined model
        parameterDF = CSV.read(parameterFile,DataFrame,stringtype=String,types=String)
        rowsToRemove=[]
        thisRow=1
        for row in eachrow(parameterDF)
            if nrow(linkingParameters[(linkingParameters[!,"parameter"].==row.parameter),:])>0
                print("removing: $(row.parameter) as it is included in linking file\n")
                push!(rowsToRemove,thisRow)
#             elseif occursin("p[",row.value)
#                 print("removing: $(row.parameter) as it includes p[t]\n")
#                 push!(rowsToRemove,thisRow)
            end

            thisRow=thisRow+1
        end
        delete!(parameterDF, rowsToRemove)

        theseParams=parameterDF.parameter
        parameterDF.parameter=parameterDF.parameter.*("-"*mod)

        append!(parametersCombined,parameterDF)

        #rate law duplication seems ok and unambiguous for now
        rateLawsDF=CSV.read(rateLawsFile,DataFrame;stringtype=String,types=String)
        append!(rateLawsCombined,rateLawsDF)

        print("finished $(mod)\n\n")
    end
    #write out the combined model
    CSV.write(combinedModelLocation*"reactions.csv", reactionsCombined)
    CSV.write(combinedModelLocation*"parameters.csv", parametersCombined)
    CSV.write(combinedModelLocation*"rateLaws.csv", rateLawsCombined)
    print("finished combining all modules\n")
    return combinedModelLocation
end