include("../src/coefexp_ab.jl")

using Printf


function _printnumstr( num::BigFloat)
    str = @sprintf("%1.200e", num)
    println("parse(")
    println("    BigFloat," )
    println("    \"$(str[1:70])\" *")
    println("    \"$(str[71:140])\" *")
    println("    \"$(str[141:end])\"")
    print(") ")
end

function print_for_test(
    order, 
    epsilon::Rational{BigInt}, 
    n_tau, dt::Rational{BigInt}, 
    list_j
)
    
    prec=precision(BigFloat)
    setprecision(1024)
    coef_tau = [collect(0:n_tau / 2 - 1); collect(-n_tau / 2:-1)]
    par = CoefExpABRational(order, float(epsilon), coef_tau, float(dt) )
    ordp1=order+1
    println("# CoefExpAB order=$order epsilon=$epsilon n_tau =$n_tau dt=$dt")
    println("# tab_res_coef is AB coefficient for each value from 1 to n_tau")
    println("# this file is generated by gendatacoefexp.jl file")
    println("function get_coef_ab_for_test()")
    println("    tabres = zeros(Complex{BigFloat}, $n_tau, $ordp1, $ordp1)")
    for j in list_j
        println("    tabres[ :, :, $j] .= [")
        for i_ell=1:n_tau
            print("    ")
            res = view(par.tab_coef, i_ell, :, j)
            for i = 1:ordp1
                if i <= j
                    _printnumstr(real(res[i]))
                    print("+ im * ")
                    _printnumstr(imag(res[i]))
                else
                    print(" 0")
                end
            end
            println("")
        end
        println("]")
    end
    println("    return tabres list_j")
    println("end")
    setprecision(prec)
end

print_for_test(15, big"1"//10, 32, big"1"//10000, [1,5,10,16])
