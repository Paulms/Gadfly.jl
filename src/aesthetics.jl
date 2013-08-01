
# Aesthetics is a set of bindings of typed values to symbols (Wilkinson calls
# this a Varset). Each variable controls how geometries are realized.
type Aesthetics
    x::Union(Nothing, Vector{Float64}, Vector{Int64})
    y::Union(Nothing, Vector{Float64}, Vector{Int64})
    size::Maybe(Vector{Measure})
    color::Maybe(AbstractDataVector{ColorValue})
    label::Maybe(PooledDataVector)

    x_min::Union(Nothing, Vector{Float64}, Vector{Int64})
    x_max::Union(Nothing, Vector{Float64}, Vector{Int64})
    y_min::Union(Nothing, Vector{Float64}, Vector{Int64})
    y_max::Union(Nothing, Vector{Float64}, Vector{Int64})

    # Boxplot aesthetics
    middle::Maybe(Vector{Float64})
    lower_hinge::Maybe(Vector{Float64})
    upper_hinge::Maybe(Vector{Float64})
    lower_fence::Maybe(Vector{Float64})
    upper_fence::Maybe(Vector{Float64})
    outliers::Maybe(Vector{Vector{Float64}})

    # Subplot aesthetics
    x_group::Maybe(PooledDataVector)
    y_group::Maybe(PooledDataVector)

    # Aesthetics pertaining to guides
    xtick::Maybe(Vector{Float64})
    ytick::Maybe(Vector{Float64})
    xgrid::Maybe(Vector{Float64})
    ygrid::Maybe(Vector{Float64})
    # TODO: make these "x_", "y_" to be consistent.

    # Pesudo-aesthetics used to indicate that drawing might
    # occur beyond any x/y value.
    x_drawmin::Maybe(Float64)
    x_drawmax::Maybe(Float64)
    y_drawmin::Maybe(Float64)
    y_drawmax::Maybe(Float64)

    # Plot viewport extents
    x_viewmin::Maybe(Float64)
    x_viewmax::Maybe(Float64)
    y_viewmin::Maybe(Float64)
    y_viewmax::Maybe(Float64)

    color_key_colors::Maybe(Vector{ColorValue})
    color_key_title::Maybe(String)
    color_key_continuous::Maybe(Bool)

    # Labels. These are not aesthetics per se, but functions that assign lables
    # to values taken by aesthetics. Often this means simply inverting the
    # application of a scale to arrive at the original value.
    x_label::Function
    y_label::Function
    xtick_label::Function
    ytick_label::Function
    color_label::Function

    function Aesthetics()
        aes = new()
        for i in 1:length(Aesthetics.names)-5
            setfield(aes, Aesthetics.names[i], nothing)
        end
        aes.x_label = fmt_float
        aes.y_label = fmt_float
        aes.xtick_label = string
        aes.ytick_label = string
        aes.color_label = string

        aes
    end

    # shallow copy constructor
    function Aesthetics(a::Aesthetics)
        b = new()
        for name in Aesthetics.names
            setfield(b, name, getfield(a, name))
        end
        b
    end
end


# Index as if this were a data frame
function getindex(aes::Aesthetics, i::Integer, j::String)
    getfield(aes, symbol(j))[i]
end


# Return the set of variables that are non-nothing.
function defined_aesthetics(aes::Aesthetics)
    vars = Set{Symbol}()
    for name in Aesthetics.names
        if !is(getfield(aes, name), nothing)
            add!(vars, name)
        end
    end
    vars
end


# Checking aesthetics and giving reasonable error messages.


# Raise an error if any of thu given aesthetics are not defined.
#
# Args:
#   who: A string naming the caller which is printed in the error message.
#   aes: An Aesthetics object.
#   vars: Symbol that must be defined in the aesthetics.
#
function assert_aesthetics_defined(who::String, aes::Aesthetics, vars::Symbol...)
    undefined_vars = setdiff(Set(vars...), defined_aesthetics(aes))
    if !isempty(undefined_vars)
        error(@sprintf("The following aesthetics are required by %s but are not defined: %s\n",
                       who, join(undefined_vars, ", ")))
    end
end


function assert_aesthetics_equal_length(who::String, aes::Aesthetics, vars::Symbol...)
    defined_vars = Symbol[]
    for var in filter(var -> !(getfield(aes, var) === nothing), vars)
        push!(defined_vars, var)
    end

    n = length(getfield(aes, vars[1]))
    for i in 2:length(vars)
        if length(getfield(aes, vars[1])) != n
            error(@sprintf("The following aesthetics are required by %s to be of equal length: %s\n",
                           who, join(vars, ", ")))
        end
    end
end


# Create a shallow copy of an Aesthetics instance.
#
# Args:
#   a: aesthetics to copy
#
# Returns:
#   Copied aesthetics.
#
copy(a::Aesthetics) = Aesthetics(a)


# Replace values in a with non-nothing values in b.
#
# Args:
#   a: Destination.
#   b: Source.
#
# Returns: nothing
#
# Modifies: a
#
function update!(a::Aesthetics, b::Aesthetics)
    for name in Aesthetics.names
        if issomething(getfield(b, name))
            setfield(a, name, getfield(b, name))
        end
    end

    nothing
end


# Serialize aesthetics to JSON.

# Args:
#  a: aesthetics to serialize.
#
# Returns:
#   JSON data as a string.
#
function json(a::Aesthetics)
    join([string(a, ":", json(getfield(a, var))) for var in aes_vars], ",\n")
end


# Concatenate aesthetics.
#
# A new Aesthetics instance is produced with data vectors in each of the given
# Aesthetics concatenated, nothing being treated as an empty vector.
#
# Args:
#   aess: One or more aesthetics.
#
# Returns:
#   A new Aesthetics instance with vectors concatenated.
#
function cat(aess::Aesthetics...)
    cataes = Aesthetics()
    for aes in aess
        for var in Aesthetics.names
            setfield(cataes, var,
                     cat_aes_var!(getfield(cataes, var), getfield(aes, var)))
        end
    end
    cataes
end

cat_aes_var!(a::Nothing, b::Nothing) = a
cat_aes_var!(a::Nothing, b) = copy(b)
cat_aes_var!(a, b::Nothing) = a
cat_aes_var!(a::Function, b::Function) = a === string || a === fmt_float ? b : a
function cat_aes_var!(a, b)
    append!(a, b)
    a
end


function cat_aes_var!{T}(xs::PooledDataVector{T}, ys::PooledDataVector{T})
    newpool = T[x for x in union(Set(xs.pool...), Set(ys.pool...))]
    newdata = vcat(T[x for x in xs], T[y for y in ys])
    PooledDataArray(newdata, newpool, [false for _ in newdata])
end


# Summarizing aesthetics

# Produce a matrix of Aesthetic objects partitioning the ariginal
# Aesthetics object by the cartesian product of x_group and y_group.
#
# This is useful primarily for drawing facets and subplots.
#
# Args:
#   aes: Aesthetics objects to partition.
#
# Returns:
#   A Array{Aesthetics} of size max(1, length(x_group)) by
#   max(1, length(y_group))
#
function aes_by_xy_group(aes::Aesthetics)
    @assert !is(aes.x_group, nothing) || !is(aes.y_group, nothing)
    @assert aes.x_group === nothing || aes.y_group === nothing ||
            length(aes.x_group) == length(aes.y_group)

    xlevels = aes.x_group === nothing ? levels(aes.x_group) : {}
    ylevels = aes.y_group === nothing ? levels(aes.y_gorup) : {}

    xrefs = aes.x_group === nothing ? aes.x_group.refs : [1]
    yrefs = aes.y_group === nothing ? aes.y_group.refs : [1]

    aes_grid = Array(Aesthetics, length(xlevels), length(ylevels))
    staging = Array(Vector{Any}, length(xlevels), length(ylevels))
    for i in 1:length(xlevels), j in 1:length(ylevels)
        aes_grid[i, j] = Aesthetics()
        staging[i, j] = Array(Any, 0)
    end

    for var in Aesthetics.name
        vals = getfield(aes, var)
        if typeof(vals) <: AbstractArray
            if !is(aes.x_group, nothing) && length(vals) != length(aes.x_group) ||
               !is(aes.y_group, nothing) && length(vals) != length(aes.y_group)
                error("Aesthetic $(var) must be the same length as x_group or y_group")
            end

            for i in 1:length(xlevels), j in 1:length(ylevels)
                empty!(staging[i, j])
            end

            for (i, j, v) in zip(cycle(xrefs), cycle(yrefs), vals)
                push!(staging[i, j], v)
            end

            for i in 1:length(xlevels), j in 1:length(ylevels)
                setfield(aes_grid[i, j], var, staging[i, j])
            end
        else
            for i in 1:length(xlevels), j in 1:length(ylevels)
                setfield(aes_grid[i, j], var, vals)
            end
        end
    end

    aes_grid
end


