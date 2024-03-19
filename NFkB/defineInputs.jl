function inputFunc(t)
    if (t<600)
        return 0.01
    else
        return 0.01/(1+((t-20)/60))
    end
#    return maximum([1/(1+((t-10)*10)),0])
end

function inputFuncSS(t)
        return 0   
end
function inputFuncSSHigh(t)
        return 0.005    
end


function inputFuncHigh(t)
    if (t<1)
        return 0.001
    else
        return 0
    end

end
function NIKinputFunc2(t)
# #     if (t>4*60)
# #         return 0.05
# #     else
# #         return 1
# #     end
#     return maximum([),0])
    return 1/(1+(t/60))
end
function NIKFuncSS(t)
    return 1
end


bcrSignalSS=inputFuncSS
bcrSignalSSHigh=inputFuncSSHigh
tlrSignalSS=inputFuncSS
bcrSignalTC=inputFunc
tlrSignalTC=inputFuncHigh
nikSignalSS=NIKFuncSS
nikSignalTC=NIKinputFunc2