"""Numerical regression tests for the mpmath L-function backend in
`kernel.probe()`.

These pin the actual numbers the backend writes to the append-only
ledger, so a future refactor (precision change, Euler-factor rewrite,
mpmath bump) can't silently shift what gets recorded.

Cases covered:
  * `probe(1, 1, 0.5, 14.134725)` — first nontrivial zero of ζ.
    Tag `MPMATH_ZETA`, `|L| < 1e-6`.
  * `probe(1, 1, 2, 0)` — ζ(2) = π²/6. Tag `MPMATH_ZETA`,
    `|L - π²/6| < 1e-10`.
  * `probe(1, 19, 0.5, 0)` — principal Dirichlet character mod 19.
    Tag `MPMATH_DIRICHLET_TRIVIAL`; the prime-19 Euler factor is
    stripped, so the value matches `ζ(0.5) · (1 - 19^{-0.5})`.
  * `probe(2, 547, 0, 0)` — out of scope for the mpmath backend.
    Tag `NEEDS_SAGE` with the documented
    `h>=2_out_of_scope_for_mpmath_backend` reason.

Each test monkeypatches `kernel.HITS` to a throwaway file in `tmp_path`
so the real append-only ledger is never touched.
"""

from __future__ import annotations

import mpmath
import pytest

import kernel


@pytest.fixture
def tmp_hits(tmp_path, monkeypatch):
    """Redirect `kernel.HITS` to a throwaway file under tmp_path."""
    fake = tmp_path / "hits.txt"
    monkeypatch.setattr(kernel, "HITS", fake)
    return fake


def test_probe_zeta_first_zero(tmp_hits):
    out = kernel.probe(1, 1, 0.5, 14.134725)
    assert out["tag"] == "MPMATH_ZETA"
    assert out["backend"] == "mpmath"
    assert mpmath.mpf(out["L_abs"]) < mpmath.mpf("1e-6")
    assert tmp_hits.exists()
    assert tmp_hits.read_text(encoding="utf-8").count("\n") == 1


def test_probe_zeta_at_two(tmp_hits):
    out = kernel.probe(1, 1, 2, 0)
    assert out["tag"] == "MPMATH_ZETA"
    assert out["backend"] == "mpmath"
    expected = mpmath.pi ** 2 / 6
    actual = mpmath.mpc(out["L_real"], out["L_imag"])
    assert abs(actual - expected) < mpmath.mpf("1e-10")
    assert out["L_nonvanish"] is True


def test_probe_dirichlet_trivial_strips_prime_19(tmp_hits):
    out = kernel.probe(1, 19, 0.5, 0)
    assert out["tag"] == "MPMATH_DIRICHLET_TRIVIAL"
    assert out["backend"] == "mpmath"
    with mpmath.workdps(50):
        s = mpmath.mpc(0.5, 0)
        expected = mpmath.zeta(s) * (mpmath.mpc(1) - mpmath.power(19, -s))
    actual = mpmath.mpc(out["L_real"], out["L_imag"])
    assert abs(actual - expected) < mpmath.mpf("1e-10")


def test_probe_h_ge_2_needs_sage(tmp_hits):
    out = kernel.probe(2, 547, 0, 0)
    assert out["tag"] == "NEEDS_SAGE"
    assert out["backend"] == "none"
    assert out["L_real"] is None
    assert out["L_imag"] is None
    assert out["L_abs"] is None
    assert out["reason"] == "h>=2_out_of_scope_for_mpmath_backend"
    assert "NEEDS_SAGE" in tmp_hits.read_text(encoding="utf-8")
