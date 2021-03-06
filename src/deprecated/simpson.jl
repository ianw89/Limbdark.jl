# This is the Kuncir (1961) adaptive simpson algorithm.
function simpson(a::T, b::T, f::Function, I_of_f::T, i::T, eps::T, N::Int64) where {T <: Real}

# value a, b, eps, N; 
# integer N;
# real a, b, I_of_f, i, eps; 
# real procedure f;
# comment This procedure integrates the function f(x) using a modified 
# Simpson's Rule quadrature formula. The quadrature is performed over j 
# subintervals of [a,b] forming the total area I_of_f. Convergence in each 
# subinterval of length (b-a)/2^n is indicated when the relative difference 
# between successive three-point and five-point area approximations
#  A_{3,j} = (b-a)(g_o + 4g_2 + g_4)/(3*2^{n+1})
#  A_{5,j} = (b-a)(g_o + 4g_1 + 2g_2 + 4g_3 + g_4)/(3*2{n+2})
# is less than or equal to an appropriate portion of the over-all tolerance 
# eps (i.e., |(A_{5,j} - A_{3,j})/A_{5,j}| \le  \eps/2^n with n \le N). 
# SIMPSON will reduce the size of each interval until this condition is satisfied.
# Complete integration over [a,b] is indicated by i = b. A value 
# a =< i < b indicates that the integration was terminated, leaving I_of_f the true 
# area under f in [a,i]. Further integration over [i,b] will necessitate either 
# the assignment of a larger N, a larger eps, or an integral substitution reducing 
# the slope of the integrand in that interval. It is recommended that this 
# procedure be used between known integrand maxima and minima.

g=Array{Float64}(5)
A=Array{Float64}(3)
S=Array{Float64}(N,3)
I_of_f=zero(T)
i=zero(T)
m=0; n=0
g[1] = f(a)
g[3] = f(0.5*(a+b))
g[5] = f(b)
# println("g[1]: ",g[1]," g[3]: ",g[3]," g[5]: ",g[5])
bma = b-a
A[1] = 0.5*bma*(g[1]+4*g[3]+g[5])
@label AA
d = 2^n
h = 0.25*bma/d
g[2] = f(a+h*(4*m+1))
g[4] = f(a+h*(4*m+3))
A[2] = h*(g[1]+4*g[2]+g[3])
A[3] = h*(g[3]+4*g[4]+g[5])
#if abs(((A[2]+A[3])-A[1])/(A[2]+A[3])) > eps/d
#if abs((A[2]+A[3])-A[1]) > eps/d
if abs((A[2]+A[3])-A[1]) > 3*eps
#  println("A[2]+A[3])-A[1]: ",A[2]+A[3]-A[1]," 3*eps: ",3*eps," d: ",d)
  m *=2
  n +=1
  if n > N
    @goto CC
  end
  A[1] = A[2]
  S[n,1] = A[3]
  S[n,2] = g[4]
  S[n,3] = g[5]
  g[5] = g[3]
  g[3] = g[2]
  @goto AA
else
  I_of_f += (A[2]+A[3])/3
#  println("I(f): ",I_of_f)
  m += 1
  i = a+m*bma/d
  @label BB
  if iseven(m)
    m = div(m,2)
    n -= 1
    @goto BB
  end
  if (m != 1) || (n != 0)
    A[1] = S[n,1]
    g[1] = g[5]
    g[3] = S[n,2]
    g[5] = S[n,3]
    @goto AA
  end
end
@label CC
#println("I(f): ",I_of_f)
return I_of_f
end
