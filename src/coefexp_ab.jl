#=
polylagrange:
- Julia version: 
- Author: ymocquar
- Date: 2019-11-25
=#
include("polyexp.jl")
using Polynomials
function getpolylagrange(k::Int64, j::Int64, N::DataType)
    @assert k <= j "_getpolylagrange(k=$k,j=$j) k must be less or equal to j"
    @assert N<:Signed "the type $N must be an Integer"
    result = Poly([one(Complex{Rational{N}})])
    for l=0:j
        if l != k
            result *= Poly([l//1,1//1])/(l-k)
        end
    end
    return result
end
struct CoefExpABRational
    tab_coef
    function CoefExpABRational(order::Int64, epsilon::AbstractFloat, list_tau, dt::AbstractFloat)
        n_tau = size(list_tau,1)
        T = typeof(epsilon)
        tab_coef = zeros(Complex{T}, n_tau, order+1, order+1)
        N = T == BigFloat ? BigInt : Int64
        epsilon = rationalize(N,epsilon, tol=epsilon*10*Base.eps(T) )
        dt = rationalize(N,dt, tol=dt*10*Base.eps(T) )
        list_tau = rationalize.(N,list_tau)
        pol_x = Poly([0//1,1//dt])
        for j=0:order
            for k=0:j
                res = view(tab_coef, :, k+1, j+1)
                pol = getpolylagrange(k, j, N)
                pol2 = pol(pol_x)
                for ind=1:n_tau
                    ell = list_tau[ind]
                    pol3 = undef
                    pol_int = if ell == 0
                        # in this case the exponentiel value is always 1
                        Polynomials.polyint(pol2)
                    else
                        pol3=PolyExp(pol2, im*ell/epsilon, -im*ell*dt/epsilon)
                        polyint(pol3)
                    end
                    res[ind] = pol_int(dt)-pol_int(0)
                end
            end
        end
        return new(tab_coef)
    end
end
struct CoefExpAB
    tab_coef
    tab_coef_neg
    function CoefExpAB(order::Int64, epsilon::AbstractFloat, n_tau, dt)
        T=typeof(epsilon)
        N, coef = T == BigFloat ? (BigInt, 10) : (Int64, 1)
        prec = 0
        new_prec = precision(BigFloat)
        if T == BigFloat
            new_prec += order*16
        end
        setprecision(BigFloat,new_prec) do
            list_tau = [collect(0:n_tau / 2 - 1); collect(-n_tau / 2:-1)]
            T2 = BigFloat 
            epsilon=T2(epsilon)
            dt=T2(dt)
            tab_coef = zeros(Complex{T2}, n_tau, order+1, order+1)
            pol_x = Poly([0, 1/dt])
            for j=0:order
                for k=0:j
                    res = view(tab_coef, :, k+1,j+1)
                    pol = getpolylagrange(k, j, N)
                    pol2 = pol(pol_x)
                    for ind=1:n_tau
                        ell = list_tau[ind]
                        pol_int = if ell == 0
                            # in this case the exponentiel value is always 1
                            Polynomials.polyint(pol2)
                        else
                            polyint(PolyExp(pol2, im*ell/epsilon, -im*ell*dt/epsilon))
                        end
                        res[ind] = pol_int(dt)-pol_int(0)
                    end
                end
            end # end of for j=....
        end # end of setprecision(...)
        # conversion to the new precision
        tab_coef = T.(real(tab_coef)) + im * T.(imag(tab_coef))
        tab_coef_neg = -conj(tab_coef)
        return new(tab_coef, tab_coef_neg)
    end
end

