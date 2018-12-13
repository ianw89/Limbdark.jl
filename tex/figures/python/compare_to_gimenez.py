"""Gimenez comparison."""
import time
import matplotlib.pyplot as pl
import numpy as np
import subprocess
import pytransit
from scipy.optimize import curve_fit
np.random.seed(43)


# Marker size is proportional to log error
def ms(error):
    return 18 + np.log10(error)


def Polynomial(mu, *u):
    """The polynomial limb darkening model."""
    return 1 - np.sum([u[l] * (1 - mu) ** (l + 1) for l in range(len(u))], axis=0)


def PolynomialJac(mu, *u):
    """The derivative matrix of the polynomial model."""
    jac = -np.array([(1 - mu) ** (l + 1) for l in range(len(u))]).transpose()
    return jac


def GetPolynomialCoeffs(g):
    """Get the polynomial coefficents."""
    N = 100
    mu = np.linspace(0, 1, N)
    I = GimenezPolynomial(mu, *g)
    guess = g
    u, _ = curve_fit(Polynomial, mu, I, guess, jac=PolynomialJac)
    IPoly = Polynomial(mu, *u)
    err = np.max(np.abs(I - IPoly))
    return u, err


def GimenezPolynomial(mu, *u):
    """The Gimenez polynomial limb darkening model."""
    return 1 - np.sum([u[l] * (1 - mu ** (l + 1)) for l in range(len(u))], axis=0)


def GimenezPolynomialJac(mu, *u):
    """The derivative matrix of the Gimenez polynomial model."""
    jac = -np.array([(1 - mu ** (l + 1)) for l in range(len(u))]).transpose()
    return jac


def GetGimenezPolynomialCoeffs(u):
    """Get the polynomial coefficents that approximate the nonlinear model."""
    N = 100
    mu = np.linspace(0, 1, N)
    I = Polynomial(mu, *u)
    guess = u
    g, _ = curve_fit(GimenezPolynomial, mu, I, guess, jac=GimenezPolynomialJac)
    IPoly = GimenezPolynomial(mu, *g)
    err = np.max(np.abs(I - IPoly))
    return g, err


Narr = [1, 2, 3, 4, 5, 10, 15, 20, 30, 40, 50]
b = np.linspace(0.0, 1.1, 1000)

agol_time = np.empty(len(Narr))
agol_grad_time = np.empty(len(Narr))
pytransit_time = np.empty(len(Narr))
err_pytransit = np.empty(len(Narr))
err_agol = np.empty(len(Narr))

# Loop over polynomial degree
for i, N in enumerate(Narr):

    u = np.random.randn(N) * np.exp(-np.arange(N) / 5)
    u_g, err = GetGimenezPolynomialCoeffs(u)
    print(err)

    # Feed b(t) to julia
    # HACK: PyJulia is currently broken, so this is how we have to do this...
    np.savetxt("b.txt", X=b)
    np.savetxt("u.txt", X=u)
    foo = subprocess.check_output(['julia', "compare_to_batman.jl"])
    agol_time[i] = float(foo.decode('utf-8'))
    agol_flux = np.loadtxt("flux.txt")
    flux_multi = np.loadtxt("flux_multi.txt")
    foo = subprocess.check_output(['julia', "compare_to_batman_grad.jl"])
    agol_grad_time[i] = float(foo.decode('utf-8'))

    # pytransit
    m = pytransit.Gimenez(nldc=len(u_g), interpolate=False)
    tstart = time.time()
    for k in range(10):
        pytransit_flux = m(b, 0.1, u_g)
    pytransit_time[i] = (time.time() - tstart) / 10

    # Multiprecision
    err_agol[i] = np.nanmedian(np.abs(agol_flux - flux_multi))
    err_pytransit[i] = np.nanmedian(np.abs(pytransit_flux - flux_multi))

# Plot
fig = pl.figure(figsize=(7, 4))
ax = pl.subplot2grid((2, 5), (0, 0), colspan=4, rowspan=2)
axleg1 = pl.subplot2grid((2, 5), (0, 4))
axleg2 = pl.subplot2grid((2, 5), (1, 4))
axleg1.axis('off')
axleg2.axis('off')

for i in range(len(Narr)):
    ax.plot(Narr[i], agol_time[i], 'o', ms=ms(err_agol[i]), color='C0')
ax.plot(Narr, agol_time, '-', lw=0.75, color='C0')
for i in range(len(Narr)):
    ax.plot(Narr[i], agol_grad_time[i], 'o', ms=ms(err_agol[i]), color='C0')
ax.plot(Narr, agol_grad_time, '--', lw=0.75, color='C0')
for i in range(len(Narr)):
    ax.plot(Narr[i], pytransit_time[i], 'o', ms=ms(err_pytransit[i]), color='C4')
ax.plot(Narr, pytransit_time, '-', lw=0.75, color='C4')

# Tweak and save
ax.set_ylabel("Time [s]", fontsize=10)
ax.set_xlabel("Degree of limb darkening", fontsize=10)
ax.set_yscale('log')

# Legend
axleg1.plot([0, 1], [0, 1], color='C0', label='this work', lw=1.5)
axleg1.plot([0, 1], [0, 1], '--', color='C0', label='this work\n(+ gradients)', lw=1.5)
axleg1.plot([0, 1], [0, 1], color='C4', label='PyTransit', lw=1.5)
axleg1.set_xlim(2, 3)
leg = axleg1.legend(loc='center', frameon=False, fontsize=8)
leg.set_title('method', prop={'weight': 'bold'})
for logerr in [-16, -12, -8, -4, 0]:
    axleg2.plot([0, 1], [0, 1], 'o', color='gray',
                ms=ms(10 ** logerr),
                label=r'$%3d$' % logerr)
axleg2.set_xlim(2, 3)
leg = axleg2.legend(loc='center', labelspacing=1, frameon=False)
leg.set_title('log error', prop={'weight': 'bold'})

# Save
fig.savefig("compare_to_gimenez.pdf", bbox_inches='tight')