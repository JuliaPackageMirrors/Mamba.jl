#################### Fallback Methods ####################

link(d::Distribution, x) = x
invlink(d::Distribution, x) = x

function logpdf(d::UnivariateDistribution, x, transform::Bool)
  insupport(d, x) ? logpdf(d, x) : -Inf
end

function logpdf(d::MultivariateDistribution, x, transform::Bool)
  insupport(d, x) ? logpdf(d, x) : -Inf
end

function logpdf(d::MatrixDistribution, x, transform::Bool)
  insupport(d, x) ? logpdf(d, x) : -Inf
end


#################### Null Distribution ####################

type NullDistribution <: Distribution end


#################### Flat Distribution ####################

immutable Flat <: Distribution
  length::Integer
  Flat(length::Real) = new(integer(length))
end

minimum(d::Flat) = -Inf
maximum(d::Flat) = Inf
insupport{T<:Real}(d::Flat, x::Union(T, Vector{T})) = d.length == length(x)

function logpdf{T<:Real}(d::Flat, x::Union(T, Vector{T}), transform::Bool)
  d.length == length(x) ? 0.0 : throw(BoundsError())
end


#################### TransformDistribution ####################

typealias TransformDistribution{T<:ContinuousUnivariateDistribution}
  Union(T, Truncated{T, Continuous})

function minimum(d::Truncated)
  max(d.lower, minimum(d.untruncated))
end

function maximum(d::Truncated)
  min(d.upper, maximum(d.untruncated))
end

function link(d::TransformDistribution, x)
  a, b = minimum(d), maximum(d)
  lowerbounded, upperbounded = isfinite(a), isfinite(b)
  if lowerbounded && upperbounded
    logit((x - a) ./ (b - a))
  elseif lowerbounded
    log(x - a)
  elseif upperbounded
    log(b - x)
  else
    x
  end
end

function invlink(d::TransformDistribution, x)
  a, b = minimum(d), maximum(d)
  lowerbounded, upperbounded = isfinite(a), isfinite(b)
  if lowerbounded && upperbounded
    (b - a) * invlogit(x) + a
  elseif lowerbounded
    exp(x) + a
  elseif upperbounded
    b - exp(x)
  else
    x
  end
end

function logpdf(d::TransformDistribution, x::Real, transform::Bool)
  insupport(d, x) || return -Inf
  value = logpdf(d, x)
  if transform
    a, b = minimum(d), maximum(d)
    lowerbounded, upperbounded = isfinite(a), isfinite(b)
    if lowerbounded && upperbounded
      y = (x - a) / (b - x)
      value += log((b - a) * y / (y + 1.0)^2)
    elseif lowerbounded
      value += log(x - a)
    elseif upperbounded
      value += log(b - x)
    end
  end
  value
end