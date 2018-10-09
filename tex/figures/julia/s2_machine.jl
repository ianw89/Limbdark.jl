# Uses new formulation from limbdark paper.

#include("s2_stable.jl")
include("../../../src/s2.jl")

s2diff(b,r) = s2(r,b)-convert(Float64,s2(big(r),big(b)))

# Run some tests:

using PyPlot

nb = 1024; nr = 1024
fig,axes = subplots(3,2, figsize=(9, 10))

# Compute r = b+-\epsilon
epsilon = 1e-8
fepsp= zeros(Float64,nb)
fepsbigp= zeros(Float64,nb)
fepsm= zeros(Float64,nb)
fepsbigm= zeros(Float64,nb)
b=linspace(epsilon,2.0,nr)
for ib=1:nb
  fepsbigp[ib] = float(s2(big(b[ib]+epsilon),big(b[ib])))
  fepsp[ib] = float(s2(b[ib]+epsilon,b[ib]))
  fepsbigm[ib] = float(s2(big(b[ib]-epsilon),big(b[ib])))
  fepsm[ib] = float(s2(b[ib]-epsilon,b[ib]))
end

ax = axes[1]
ax[:plot](b,s2.(b,b),"-", lw=2)
ax[:plot](b,fepsp,"--", lw=2)
ax[:plot](b,fepsm,":", lw=2)
ax[:set_ylabel](L"$S_1$", fontsize=14)
ax[:set_title](L"$S_1(b \pm \epsilon, b)$", fontsize=16)

ax = axes[2]
ax[:plot](b,(fepsp-s2.(b,b))/epsilon,lw=2)
ax[:plot](b,(fepsbigp-s2.(b,b))/epsilon,linewidth=2,linestyle="--")
ax[:plot](b,(fepsm-s2.(b,b))/epsilon,lw=2)
ax[:plot](b,(fepsbigm-s2.(b,b))/epsilon,linewidth=2,linestyle="--")
ax[:set_ylabel](L"$\Delta S_1 / \epsilon$", fontsize=14)

ax = axes[3]
ax[:plot](b,1e15 * s2diff.(b,b+epsilon))
ax[:plot](b,1e15 * s2diff.(b,b-epsilon),linewidth=2,linestyle="--")
ax[:set_ylabel](L"$\mathrm{error}\ \times 10^{15}$", fontsize=14)
ax[:set_xlabel](L"$b$", fontsize=14)

# Compute b+r = 1+-\epsilon
epsilon = 1e-8
b=linspace(0.0,2.0,nr)
for ib=1:nr
  fepsbigp[ib] = float(s2(big(1.0-b[ib]+epsilon),big(b[ib])))
  fepsp[ib] = float(s2(1.0-b[ib]+epsilon,b[ib]))
  fepsbigm[ib] = float(s2(big(1.0-b[ib]-epsilon),big(b[ib])))
  fepsm[ib] = float(s2(1.0-b[ib]-epsilon,b[ib]))
end

ax = axes[4]
ax[:plot](b,s2.(1.0-b,b),"-",label=L"$r$",lw=2)
ax[:plot](b,fepsp,"--",label=L"$r+\epsilon$",lw=2)
ax[:plot](b,fepsm,":",label=L"$r-\epsilon$",lw=2)
ax[:legend](loc="lower right",fontsize=10)
ax[:set_title](L"$S_1(1 - b \pm \epsilon, b)$", fontsize=16)

ax = axes[5]
ax[:plot](b,(fepsp-s2.(1.0-b,b))/epsilon,lw=2,label=L"$r+\epsilon$")
ax[:plot](b,(fepsbigp-s2.(1.0-b,b))/epsilon,lw=2,linestyle="--",label=L"$r+\epsilon\ [\mathrm{BigFloat}]$")
ax[:plot](b,(fepsm-s2.(1.0-b,b))/epsilon,lw=2,label=L"$r-\epsilon$")
ax[:plot](b,(fepsbigm-s2.(1.0-b,b))/epsilon,lw=2,linestyle="--",linestyle="--",label=L"$r-\epsilon\ [\mathrm{BigFloat}]$")
ax[:legend](loc="lower right",fontsize=10)

ax = axes[6]
ax[:plot](b,1e15*s2diff.(1.0-b+epsilon,b),label=L"$r+\epsilon$")
ax[:plot](b,1e15*s2diff.(1.0-b-epsilon,b),linewidth=2,linestyle="--",label=L"$r-\epsilon$")
ax[:legend](loc="lower right",fontsize=10)
ax[:set_xlabel](L"$b$", fontsize=14)

savefig("s2_machine.pdf", bbox_inches="tight")
