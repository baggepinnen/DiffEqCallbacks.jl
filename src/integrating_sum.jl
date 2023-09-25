#=
# allocate_zeros
function allocate_zeros(p::AbstractArray{T}) where {T}
    integral = similar(p)
    fill!(integral, zero(T))
    return integral
end
allocate_zeros(p::Tuple) = allocate_zeros.(p)
allocate_zeros(p::NamedTuple{F}) where {F} = NamedTuple{F}(allocate_zeros(values(p)))
allocate_zeros(p) = fmap(allocate_zeros, p)

# axpy!
recursive_axpy!(α, x::AbstractArray, y::AbstractArray) = axpy!(α, x, y)
recursive_axpy!(α, x::Tuple, y::Tuple) = recursive_axpy!.(α, x, y)
function recursive_axpy!(α, x::NamedTuple{F}, y::NamedTuple{F}) where {F}
    return NamedTuple{F}(recursive_axpy!(α, values(x), values(y)))
end
recursive_axpy!(α, x, y) = fmap(Base.Fix1(recursive_axpy!, α), x, y)

# scalar_mul!
recursive_scalar_mul!(x::AbstractArray, α) = x .*= α
recursive_scalar_mul!(x::Tuple, α) = recursive_scalar_mul!.(x, α)
function recursive_scalar_mul!(x::NamedTuple{F}, α) where {F}
    return NamedTuple{F}(recursive_scalar_mul!(values(x), α))
end
recursive_scalar_mul!(x, α) = fmap(Base.Fix1(recursive_scalar_mul!, α), x)
=#

# addition
recursive_add!(x::AbstractArray, y::AbstractArray) = x .+= y
recursive_add!(x::Tuple, y::Tuple) = recursive_add!.(x, y)
function recursive_add!(x::NamedTuple{F}, y::NamedTuple{F}) where {F}
    return NamedTuple{F}(recursive_add!(values(x), values(y)))
end

#=
"""
    gauss_points::Vector{Vector{Float64}}

Precomputed Gaussian nodes up to degree 2*10-1 = 19.
Computed using FastGaussQuadrature.jl with the command `[gausslegendre(i)[1] for i in 1:10]`
"""
gauss_points = [[0.0],
    [-0.5773502691896258, 0.5773502691896258],
    [-0.7745966692414834, 0.0, 0.7745966692414834],
    [-0.8611363115940526, -0.3399810435848563, 0.3399810435848563, 0.8611363115940526],
    [-0.906179845938664, -0.5384693101056831, 0.0, 0.5384693101056831, 0.906179845938664],
    [
        -0.932469514203152,
        -0.6612093864662645,
        -0.2386191860831969,
        0.2386191860831969,
        0.6612093864662645,
        0.932469514203152,
    ],
    [
        -0.9491079123427586,
        -0.7415311855993945,
        -0.4058451513773972,
        0.0,
        0.4058451513773972,
        0.7415311855993945,
        0.9491079123427586,
    ],
    [
        -0.9602898564975363,
        -0.7966664774136267,
        -0.525532409916329,
        -0.1834346424956498,
        0.1834346424956498,
        0.525532409916329,
        0.7966664774136267,
        0.9602898564975363,
    ],
    [
        -0.9681602395076261,
        -0.8360311073266358,
        -0.6133714327005904,
        -0.3242534234038089,
        0.0,
        0.3242534234038089,
        0.6133714327005904,
        0.8360311073266358,
        0.9681602395076261,
    ],
    [
        -0.9739065285171717,
        -0.8650633666889845,
        -0.6794095682990244,
        -0.4333953941292472,
        -0.14887433898163122,
        0.14887433898163122,
        0.4333953941292472,
        0.6794095682990244,
        0.8650633666889845,
        0.9739065285171717,
    ]]
"""
    gauss_weights::Vector{Vector{Float64}}

Precomputed Gaussian node weights up to degree 2*10-1 = 19.
Computed using FastGaussQuadrature.jl with the command `[gausslegendre(i)[2] for i in 1:10]`
"""
gauss_weights = [[2.0],
    [1.0, 1.0],
    [0.5555555555555556, 0.8888888888888888, 0.5555555555555556],
    [0.34785484513745385, 0.6521451548625462, 0.6521451548625462, 0.34785484513745385],
    [
        0.23692688505618908,
        0.47862867049936647,
        0.5688888888888889,
        0.47862867049936647,
        0.23692688505618908,
    ],
    [
        0.17132449237917025,
        0.3607615730481385,
        0.46791393457269126,
        0.46791393457269126,
        0.3607615730481385,
        0.17132449237917025,
    ],
    [
        0.1294849661688702,
        0.2797053914892766,
        0.3818300505051189,
        0.4179591836734694,
        0.3818300505051189,
        0.2797053914892766,
        0.1294849661688702,
    ],
    [
        0.10122853629037676,
        0.22238103445337445,
        0.31370664587788744,
        0.36268378337836193,
        0.36268378337836193,
        0.31370664587788744,
        0.22238103445337445,
        0.10122853629037676,
    ],
    [
        0.08127438836157437,
        0.18064816069485742,
        0.2606106964029354,
        0.31234707704000275,
        0.3302393550012598,
        0.31234707704000275,
        0.2606106964029354,
        0.18064816069485742,
        0.08127438836157437,
    ],
    [
        0.06667134430868821,
        0.14945134915058056,
        0.21908636251598207,
        0.2692667193099965,
        0.2955242247147529,
        0.2955242247147529,
        0.2692667193099965,
        0.21908636251598207,
        0.14945134915058056,
        0.06667134430868821,
    ]]
=#
"""
    IntegrandValues{integrandType}

A struct used to save values of the integrand values in `integrand::Vector{integrandType}`.
"""
mutable struct IntegrandValuesSum{integrandType}
    integrand::integrandType
end

"""
    IntegrandValues(integrandType::DataType)

Return `IntegrandValues{integrandType}` with empty storage vectors.
"""
function IntegrandValuesSum(::Type{integrandType}) where {integrandType}
    IntegrandValuesSum{integrandType}(integrandType)
end

function Base.show(io::IO, integrand_values::IntegrandValuesSum)
    integrandType = eltype(integrand_values.integrand)
    print(io, "IntegrandValuesSum{integrandType=", integrandType, "}",
        "\nintegrand:\n", integrand_values.integrand)
end

mutable struct SavingIntegrandSumAffect{IntegrandFunc, integrandType, integrandCacheType}
    integrand_func::IntegrandFunc
    integrand_values::IntegrandValuesSum{integrandType}
    integrand_cache::integrandCacheType
end

function (affect!::SavingIntegrandSumAffect)(integrator)
    n = 0
    if typeof(integrator.sol.prob) <: Union{SDEProblem, RODEProblem}
        n = 10
    else
        n = div(SciMLBase.alg_order(integrator.alg) + 1, 2)
    end
    integral = allocate_zeros(integrator.p)
    for i in 1:n
        t_temp = ((integrator.t - integrator.tprev) / 2) * gauss_points[n][i] +
                 (integrator.t + integrator.tprev) / 2
        if DiffEqBase.isinplace(integrator.sol.prob)
            curu = first(get_tmp_cache(integrator))
            integrator(curu, t_temp)
            if affect!.integrand_cache == nothing
                recursive_axpy!(gauss_weights[n][i],
                    affect!.integrand_func(curu, t_temp, integrator), integral)
            else
                affect!.integrand_func(affect!.integrand_cache, curu, t_temp, integrator)
                recursive_axpy!(gauss_weights[n][i], affect!.integrand_cache, integral)
            end
        else
            recursive_axpy!(gauss_weights[n][i],
                affect!.integrand_func(integrator(t_temp), t_temp, integrator), integral)
        end
    end
    recursive_scalar_mul!(integral, -(integrator.t - integrator.tprev) / 2)
    #print(typeof(affect!.integrand_values.integrand))
    #print(typeof(integral))
    #if isempty(affect!.integrand_values.integrand)
    #    affect!.integrand_values.integrand = integral
    #else
    recursive_add!(affect!.integrand_values.integrand, integral)
    #end
    u_modified!(integrator, false)
end

"""
```julia
IntegratingCallback(integrand_func,
    integrand_values::IntegrandValues,
    cache = nothing)
```

Lets one define a function `integrand_func(u, t, integrator)` which
returns Integral(integrand_func(u(t),t)dt over the problem tspan.

## Arguments

  - `integrand_func(out, u, t, integrator)` for in-place problems and `out = integrand_func(u, t, integrator)` for
    out-of-place problems. Returns the quantity in the integral for computing dG/dp.
    Note that for out-of-place problems, this should allocate the output (not as a view to `u`).
  - `integrand_values::IntegrandValues` is the types that `integrand_func` will return, i.e.
    `integrand_func(t, u, integrator)::integrandType`. It's specified via
    `IntegrandValues(integrandType)`, i.e. give the type
    that `integrand_func` will output (or higher compatible type).
  - `cache` is provided to store `integrand_func` output for in-place problems.
    if `cache` is `nothing` but the problem is in-place, then `integrand_func`
    is assumed to not be in-place and will be called as `out = integrand_func(u, t, integrator)`.

The outputted values are saved into `integrand_values`. The values are found
via `integrand_values.integrand`.

!!! note

    This method is currently limited to ODE solvers of order 10 or lower. Open an issue if other
    solvers are required.

    If `integrand_func` is in-place, you must use `cache` to store the output of `integrand_func`.
"""
function IntegratingSumCallback(integrand_func, integrand_values::IntegrandValuesSum,
    cache = nothing)
    affect! = SavingIntegrandSumAffect(integrand_func, integrand_values, cache)
    condition = (u, t, integrator) -> true
    DiscreteCallback(condition, affect!, save_positions = (false, false))
end

export IntegratingSumCallback, IntegrandValuesSum
