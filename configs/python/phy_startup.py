"""Physics scratchpad — preloaded into the `phy` euporie kernel at boot.

Wired up in home.nix as a Jupyter kernelspec (IPKernelApp.exec_files), driven by
euporie-console inside kitty.

Preloaded names:
  np            numpy
  sp            scipy
  plt           matplotlib.pyplot   (inline; `%matplotlib tk` for a popup window)
  const         scipy.constants     (full module; const.value("..."), const.physical_constants)
  consts        type it to print the table of physical constants below
  + common physical constants in SI units as short names.
"""

import numpy as np
import scipy as sp
import scipy.constants as const
import matplotlib.pyplot as plt

# Most-used physical constants (SI units), CODATA values via scipy.constants.
from scipy.constants import (
    c,          # speed of light            [m/s]
    h,          # Planck constant           [J s]
    hbar,       # reduced Planck constant   [J s]
    G,          # gravitational constant    [m^3 kg^-1 s^-2]
    g,          # standard gravity          [m/s^2]
    e,          # elementary charge         [C]
    k,          # Boltzmann constant        [J/K]
    N_A,        # Avogadro number           [1/mol]
    R,          # molar gas constant        [J/(mol K)]
    sigma,      # Stefan-Boltzmann constant [W m^-2 K^-4]
    alpha,      # fine-structure constant   [-]
    epsilon_0,  # vacuum permittivity       [F/m]
    mu_0,       # vacuum permeability       [N/A^2]
    m_e,        # electron mass             [kg]
    m_p,        # proton mass               [kg]
    m_n,        # neutron mass              [kg]
    pi,
)

# Handy aliases / units.
k_B = k     # Boltzmann constant (common k_B notation)
eV = e      # 1 eV in joules (== elementary charge numerically)

# Plots render inline in the terminal — euporie draws the PNG via kitty's
# graphics protocol. Use `%matplotlib tk` for a zoomable popup window instead
# (it floats under Hyprland). Guarded so kernel boot never fails on this.
try:
    _ip = get_ipython()  # noqa: F821 — injected by the IPython kernel
    if _ip is not None:
        _ip.run_line_magic("matplotlib", "inline")
except Exception:
    pass

# (symbol, full name, value, unit) — rendered by the `consts` table object.
_CONSTANTS = [
    ("c",         "speed of light",            c,         "m/s"),
    ("h",         "Planck constant",           h,         "J·s"),
    ("hbar",      "reduced Planck constant",   hbar,      "J·s"),
    ("G",         "gravitational constant",    G,         "m³·kg⁻¹·s⁻²"),
    ("g",         "standard gravity",          g,         "m/s²"),
    ("e",         "elementary charge",         e,         "C"),
    ("k_B",       "Boltzmann constant",        k_B,       "J/K"),
    ("N_A",       "Avogadro constant",         N_A,       "1/mol"),
    ("R",         "molar gas constant",        R,         "J·mol⁻¹·K⁻¹"),
    ("sigma",     "Stefan–Boltzmann constant", sigma,     "W·m⁻²·K⁻⁴"),
    ("alpha",     "fine-structure constant",   alpha,     "—"),
    ("epsilon_0", "vacuum permittivity",       epsilon_0, "F/m"),
    ("mu_0",      "vacuum permeability",        mu_0,     "N·A⁻²"),
    ("m_e",       "electron mass",             m_e,       "kg"),
    ("m_p",       "proton mass",               m_p,       "kg"),
    ("m_n",       "neutron mass",              m_n,       "kg"),
    ("eV",        "electronvolt",              eV,        "J"),
    ("pi",        "pi",                        pi,        "—"),
]


def _constants_table():
    header = ("symbol", "constant", "value", "unit")
    rows = [(s, n, f"{v:.9g}", u) for s, n, v, u in _CONSTANTS]
    w = [max(len(header[i]), *(len(r[i]) for r in rows)) for i in range(4)]
    fmt = lambda r: "  ".join(col.ljust(w[i]) for i, col in enumerate(r))
    lines = [fmt(header), "  ".join("─" * w[i] for i in range(4))]
    lines += [fmt(r) for r in rows]
    return "\n".join(lines)


class _Constants:
    """Preloaded physical constants — type `consts` to print this table."""

    def __repr__(self):
        return _constants_table()


# euporie can't print at kernel boot, so the table is exposed on demand:
consts = _Constants()
