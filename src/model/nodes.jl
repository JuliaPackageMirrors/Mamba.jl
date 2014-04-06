#################### MCMCNode Methods ####################

function Base.show(io::IO, n::MCMCNode)
  msg = string(ifelse(n.monitor, "A ", "An un"),
               "monitored node of type \"", summary(n), "\"\n")
  print(io, msg)
  show(io, n.data)
  print(io, "\n")
end

function Base.showall(io::IO, n::MCMCNode)
  show(io, n)
  print(io, "\nFunction:\n")
  show(io, n.eval.code)
  print(io, "\n\nNode Dependencies:\n")
  show(io, n.deps)
  print(io, "\n")
end

identity(n::MCMCNode, x) = x

invlink(n::MCMCNode, x) = x

link(n::MCMCNode, x) = x

logpdf(n::MCMCNode, transform::Bool=false) = 0.0


#################### MCMCLogical Constructors ####################

function MCMCLogical(data, expr::Expr, monitor::Bool)
  MCMCLogical(data, monitor, paramfx(expr), paramdeps(expr))
end

function MCMCLogical(expr::Expr, monitor::Bool=true)
  data = convert(VariateType, NaN)
  MCMCLogical(data, expr, monitor)
end

function MCMCLogical(length::Integer, expr::Expr, monitor::Bool=true)
  data = Array(VariateType, length)
  fill!(data, NaN)
  MCMCLogical(data, expr, monitor)
end

function MCMCLogical(m::Integer, n::Integer, expr::Expr, monitor::Bool=true)
  data = Array(VariateType, m, n)
  fill!(data, NaN)
  MCMCLogical(data, expr, monitor)
end


#################### MCMCLogical Methods ####################

setinits!(l::MCMCLogical, m::MCMCModel, x=nothing) = update!(l, m)

function update!(l::MCMCLogical, m::MCMCModel)
  l[:] = l.eval(m)
  l
end


#################### MCMCStochastic Constructors ####################

function MCMCStochastic{T}(data::T, expr::Expr, monitor::Bool)
  MCMCStochastic(data, monitor, paramfx(expr), paramdeps(expr),
                 NullDistribution())
end

function MCMCStochastic(expr::Expr, monitor::Bool=true)
  data = convert(VariateType, NaN)
  MCMCStochastic(data, expr, monitor)
end

function MCMCStochastic(length::Integer, expr::Expr, monitor::Bool=true)
  data = Array(VariateType, length)
  fill!(data, NaN)
  MCMCStochastic(data, expr, monitor)
end

function MCMCStochastic(m::Integer, n::Integer, expr::Expr, monitor::Bool=true)
  data = Array(VariateType, m, n)
  fill!(data, NaN)
  MCMCStochastic(data, expr, monitor)
end


#################### MCMCStochastic Methods ####################

function Base.showall(io::IO, s::MCMCStochastic)
  show(io, s)
  print(io, "\n\nDistribution:\n")
  show(io, s.distr)
  print(io, "\nFunction:\n")
  show(io, s.eval.code)
  print(io, "\n\nNode Dependencies:\n")
  show(io, s.deps)
  print(io, "\n")
end

function setinits!(s::MCMCStochastic, m::MCMCModel, x)
  s[:] = convert(typeof(s.data), x)
  update!(s, m)
  if isa(s.distr, Array) && size(s.data) != size(s.distr)
    error("stochastic parameter and distribution dimensions must match")
  end
  s
end

insupport(s::MCMCStochastic) = all(mapdistr(insupport, s, s.data))

invlink(s::MCMCStochastic, x) = mapdistr(invlink, s, x)

link(s::MCMCStochastic, x) =  mapdistr(link, s, x)

function logpdf(s::MCMCStochastic, transform::Bool=false)
  +(mapdistr(logpdf, s, s.data, transform))
end

function mapdistr(f::Function, s::MCMCStochastic, x, args...)
  if isa(s.distr, Array)
    n = length(s.distr)
    length(x) == n ||
      error("dimension of stochastic distribution and argument must match")
    map(i -> f(s.distr[i], x[i], args...), 1:n)
  else
    f(s.distr, x, args...)
  end
end

function update!(s::MCMCStochastic, m::MCMCModel)
  s.distr = s.eval(m)
  s
end


#################### Utility Functions ####################

function paramdeps(expr::Expr)
  if expr.head == :ref && expr.args[1] == :model && isa(expr.args[2], String)
    String[expr.args[2]]
  else
    mapreduce(paramdeps, union, expr.args)
  end
end

function paramdeps(expr)
  String[]
end

function paramfx(expr::Expr)
  eval(Main, Expr(:function, :(model::MCMCModel,), expr))
end