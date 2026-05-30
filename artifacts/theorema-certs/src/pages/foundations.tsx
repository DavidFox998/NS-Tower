import { Link } from "wouter";
import { ArrowLeft, Download, ShieldCheck, AlertTriangle } from "lucide-react";
import { Card } from "@/components/ui/card";
import su3Source from "@lean/Towers/YM/SU3Instances.lean?raw";
import peterWeylSource from "@lean/Towers/YM/PeterWeyl.lean?raw";
import heatVaradhanSource from "@lean/Towers/YM/PeterWeylHeatVaradhan.lean?raw";
import wilsonPositivitySource from "@lean/Towers/YM/WilsonPositivity.lean?raw";

const mono = "font-mono text-sm bg-muted px-1.5 py-0.5 border border-border";

const TRIO = "{propext, Classical.choice, Quot.sound}";

function Section({
  index,
  title,
  children,
}: {
  index: string;
  title: string;
  children: React.ReactNode;
}) {
  return (
    <Card className="p-6 border-border bg-card">
      <div className="flex items-baseline gap-3 mb-4 border-b border-border pb-3">
        <div className="font-mono text-xs text-primary uppercase tracking-[0.18em]">
          {index}
        </div>
        <h3 className="font-sans font-bold text-lg tracking-tight">{title}</h3>
      </div>
      <div className="space-y-4 font-serif text-base leading-relaxed text-foreground/90">
        {children}
      </div>
    </Card>
  );
}

interface LeanFile {
  filename: string;
  source: string;
  title: string;
  scope: string;
}

const LEAN_FILES: LeanFile[] = [
  {
    filename: "SU3Instances.lean",
    source: su3Source,
    title: "SU(3) Haar instance stack",
    scope:
      "Equips SU(3) = specialUnitaryGroup (Fin 3) ℂ with the Group / TopologicalGroup / CompactSpace / Borel instance stack so haarMeasure ⊤ elaborates. Genuine measure-theoretic infrastructure; makes no mass-gap, no μ>0, and does not touch Surface #1.",
  },
  {
    filename: "PeterWeyl.lean",
    source: peterWeylSource,
    title: "SU(3) Peter-Weyl summability",
    scope:
      "Four bricks proving the SU(3) Peter-Weyl heat-kernel spectral series ∑ (dim λ)²·exp(−β·C₂(λ)) is Summable for every β>0. Textbook real-analysis facts; not an OS reconstruction and not a mass-gap bound.",
  },
  {
    filename: "PeterWeylHeatVaradhan.lean",
    source: heatVaradhanSource,
    title: "Heat-kernel envelope (strip-form Varadhan bound)",
    scope:
      "A strip-form Varadhan-shape upper bound on the genuine SU(3) heat-kernel envelope, valid on a bounded t-window [t_lo, t_top]. Honestly documents why the unrestricted small-t shape is mathematically false on a neighbourhood of 0.",
  },
  {
    filename: "WilsonPositivity.lean",
    source: wilsonPositivitySource,
    title: "Strict Wilson-action positivity",
    scope:
      "Proves the SU(3) Wilson plaquette action is strictly positive off the vacuum, via Re tr g ≤ 3 with equality iff g = 1. Scalar-sector action positivity ONLY — not a statement about the real Wilson transfer operator.",
  },
];

function downloadLean(filename: string, source: string) {
  const blob = new Blob([source], { type: "text/plain;charset=utf-8" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  document.body.removeChild(anchor);
  URL.revokeObjectURL(url);
}

function lineCount(source: string): number {
  return source.split("\n").length;
}

export default function FoundationsPage() {
  return (
    <div className="space-y-8">
      <Link
        href="/"
        className="inline-flex items-center text-xs font-mono text-muted-foreground hover:text-foreground transition-colors"
        data-testid="link-back-dashboard"
      >
        <ArrowLeft className="w-3 h-3 mr-2" /> BACK TO DASHBOARD
      </Link>

      <header className="border-b border-border pb-6">
        <div className="font-mono text-[10px] text-muted-foreground uppercase tracking-[0.18em] mb-2">
          Formal foundations · SU(3) measure theory
        </div>
        <h2 className="text-3xl font-bold font-sans tracking-tight mb-2">
          Foundations: Haar &amp; Peter-Weyl
        </h2>
        <p className="text-sm font-mono text-muted-foreground">
          THE MATCHED PAIR AT THE HEART OF THE SU(3) WORK — AND THE VERIFIED LEAN
          SOURCES
        </p>
      </header>

      <Card className="p-6 border-primary/50 bg-primary/5">
        <div className="font-mono text-[10px] text-primary uppercase tracking-[0.18em] mb-2">
          What this page is
        </div>
        <p className="font-serif text-base leading-relaxed">
          This page explains two classical pillars of harmonic analysis on
          compact groups — <strong>Haar measure</strong> (the fair way to average
          on a group) and the <strong>Peter-Weyl theorem</strong> (why that
          averaging decomposes <span className={mono}>L²(G)</span> like a Fourier
          series) — and lets you download the actual verified Lean source files
          that build this infrastructure for <span className={mono}>SU(3)</span>.
          Every file linked below is <strong>sorry-free</strong> and carries the
          classical-trio axiom footprint <span className={mono}>{TRIO}</span>. It
          writes no new mathematics and makes no new claim. See the honesty box
          at the foot of the page for the scope limits.
        </p>
      </Card>

      <Section index="§ 1" title="Haar measure — Lebesgue measure for groups">
        <p>
          On the real line we measure a set by its length, and that length does
          not change when we slide the set sideways: Lebesgue measure is{" "}
          <em>translation-invariant</em>. A Lie group like{" "}
          <span className={mono}>SU(3)</span> has no notion of "length" handed to
          it for free, but it does have a multiplication, and we can ask for the
          analogous object: a measure that does not change when we{" "}
          <em>multiply</em> every point on the left by a fixed group element. That
          is a <strong>left Haar measure</strong>.
        </p>
        <p>
          The 1933 Haar existence theorem (with von Neumann / Weil uniqueness)
          says that on every locally compact group such a measure exists and is
          unique up to a positive scalar. When the group is{" "}
          <strong>compact</strong> — as <span className={mono}>SU(3)</span> is —
          the total mass is finite, so we can normalize it to a{" "}
          <strong>probability measure</strong>:{" "}
          <span className={mono}>∫_(SU(3)) 1 dμ = 1</span>. Left- and
          right-invariance coincide (the group is unimodular), and there is an
          explicit picture via the <em>Weyl integration formula</em>: integrating
          a class function reduces to an integral over the maximal torus weighted
          by the Weyl denominator, i.e. over the eigenvalue triples{" "}
          <span className={mono}>
            (e^{"{iθ₁}"}, e^{"{iθ₂}"}, e^{"{iθ₃}"})
          </span>{" "}
          with <span className={mono}>θ₁ + θ₂ + θ₃ = 0</span>.
        </p>
        <p>
          In the Lean development this is not assumed — it is{" "}
          <em>constructed</em>. The file{" "}
          <span className={mono}>SU3Instances.lean</span> equips mathlib's{" "}
          <span className={mono}>specialUnitaryGroup (Fin 3) ℂ</span> with exactly
          the instance stack that{" "}
          <span className={mono}>MeasureTheory.Measure.haarMeasure</span> needs:{" "}
          <span className={mono}>Group</span> (inverse = conjugate transpose),{" "}
          <span className={mono}>TopologicalGroup</span>,{" "}
          <span className={mono}>CompactSpace</span> (SU(3) is a closed subset of
          the compact poly-disc of matrices with entries bounded by 1), and the
          Borel <span className={mono}>MeasurableSpace</span>. With those in
          place, <span className={mono}>haarMeasure ⊤</span> elaborates — and{" "}
          <span className={mono}>#print axioms</span> reports the classical trio,
          nothing more.
        </p>
      </Section>

      <Section
        index="§ 2"
        title="Peter-Weyl — a Fourier series for the group"
      >
        <p>
          On the circle <span className={mono}>R/Z</span>, classical Fourier
          analysis says every square-integrable function is a sum of characters{" "}
          <span className={mono}>e^{"{2πinx}"}</span>: the exponentials form an
          orthonormal basis of <span className={mono}>L²(R/Z)</span>. The{" "}
          <strong>Peter-Weyl theorem</strong> (Hermann Weyl &amp; Fritz Peter,
          1927) is the exact generalization to any compact group. It states that
          the matrix coefficients of the{" "}
          <em>irreducible unitary representations</em> form an orthogonal basis of{" "}
          <span className={mono}>L²(G)</span>, and that{" "}
          <span className={mono}>L²(G)</span> decomposes as a Hilbert-space direct
          sum
          <span className="block my-2 text-center">
            <span className={mono}>
              L²(G) ≅ ⊕_λ (V_λ ⊗ V_λ*),
            </span>
          </span>
          one block per irreducible representation{" "}
          <span className={mono}>λ</span>, each block of dimension{" "}
          <span className={mono}>(dim V_λ)²</span>.
        </p>
        <p>
          The R/Z ↔ SU(3) analogy is precise: the circle's characters{" "}
          <span className={mono}>e^{"{2πinx}"}</span> are indexed by a single
          integer <span className={mono}>n ∈ Z</span>; the SU(3) irreducibles are
          indexed by a pair of non-negative integers{" "}
          <span className={mono}>(m, n) ∈ ℕ × ℕ</span> (highest weights), with the
          Weyl dimension formula giving{" "}
          <span className={mono}>dim λ_(m,n)</span> and the quadratic Casimir{" "}
          <span className={mono}>C₂(λ_(m,n))</span> playing the role of{" "}
          <span className={mono}>n²</span> in the heat kernel.
        </p>
        <p>
          The file <span className={mono}>PeterWeyl.lean</span> proves the
          concrete analytic consequence the downstream work needs: the SU(3)
          Peter-Weyl heat-kernel spectral series at the identity,
          <span className="block my-2 text-center">
            <span className={mono}>
              ∑_(m,n) (dim λ_(m,n))² · exp(−β · C₂(λ_(m,n))),
            </span>
          </span>
          is <span className={mono}>Summable</span> for every{" "}
          <span className={mono}>β &gt; 0</span> — a textbook real-analysis fact,
          proved against the real polynomial dimension/Casimir forms, not a
          placeholder. The companion file{" "}
          <span className={mono}>PeterWeylHeatVaradhan.lean</span> bounds the same
          envelope by a Varadhan-shaped expression on a bounded{" "}
          <span className={mono}>t</span>-window, and is candid in its own header
          about why the unrestricted small-<span className={mono}>t</span> form is
          false (the on-diagonal heat trace blows up like{" "}
          <span className={mono}>t^(−4)</span>).
        </p>
      </Section>

      <Section index="§ 3" title="The tie — and the one inequality it earns">
        <p>
          Haar and Peter-Weyl are a matched pair:{" "}
          <strong>
            Haar measure is exactly the measure that makes Peter-Weyl work.
          </strong>{" "}
          The orthogonality of matrix coefficients is orthogonality{" "}
          <em>with respect to the Haar inner product</em>; without an invariant
          measure there is no <span className={mono}>L²(G)</span> Hilbert space to
          decompose. The honest chain is:
        </p>
        <p className="border-l-4 border-primary pl-4 bg-muted/30 py-2 font-mono text-sm leading-relaxed">
          Haar exists on compact SU(3) → L²(SU(3)) is a Hilbert space → Peter-Weyl
          gives its block decomposition over irreducibles → on a single plaquette
          the relevant quantity is a character value, and unitarity forces{" "}
          <span className="text-primary">Re tr g ≤ 3</span> with equality iff{" "}
          <span className="text-primary">g = 1</span>.
        </p>
        <p>
          That last inequality is the content of{" "}
          <span className={mono}>WilsonPositivity.lean</span>. For a unitary{" "}
          <span className={mono}>3×3</span> matrix the Hilbert-Schmidt identity{" "}
          <span className={mono}>‖g − 1‖² = 6 − 2·Re tr g</span> together with{" "}
          <span className={mono}>‖g − 1‖² ≥ 0</span> gives{" "}
          <span className={mono}>Re tr g ≤ 3</span>, and the equality case{" "}
          <span className={mono}>Re tr g = 3 ⇔ g = 1</span> follows from{" "}
          <span className={mono}>‖M‖² = 0 ⇔ M = 0</span>. So each plaquette's
          energy <span className={mono}>(3 − Re tr P)/3</span> is non-negative,
          and strictly positive exactly when the plaquette is non-trivial — hence
          the bare Wilson action is strictly positive off the vacuum. This is a
          real, elementary, sorry-free inequality. It is <em>one plaquette's</em>{" "}
          energy bound — see the honesty box for what it is{" "}
          <strong>not</strong>.
        </p>
      </Section>

      <Section index="§ 4" title="The axiom footprint — read honestly">
        <p>
          Every file here closes under the same classical trio,{" "}
          <span className={mono}>{TRIO}</span>, and nothing else. It is worth
          naming why each axiom shows up, <em>as a footprint, not as a
          metaphysical claim</em>:
        </p>
        <ul className="list-disc list-inside space-y-1">
          <li>
            <span className={mono}>Classical.choice</span> — the existence /
            uniqueness of Haar measure is a non-constructive theorem; choosing the
            invariant measure uses choice.
          </li>
          <li>
            <span className={mono}>propext</span> — propositional extensionality,
            pervasive in mathlib's Hilbert-space and representation-theory API
            that Peter-Weyl rides on.
          </li>
          <li>
            <span className={mono}>Quot.sound</span> — quotient soundness,
            underlying the <span className={mono}>L²</span> construction (functions
            modulo almost-everywhere equality) and other quotient types.
          </li>
        </ul>
        <p>
          These three are exactly the axioms mathlib itself is built on. A reader
          can confirm the footprint with{" "}
          <span className={mono}>#print axioms</span> on any declaration in the
          downloaded files. There is no research-grade axiom, and no{" "}
          <span className={mono}>sorry</span>, in any of them.
        </p>
      </Section>

      <Card className="p-6 border-amber-500/60 bg-amber-500/5">
        <div className="flex items-center gap-2 font-mono text-[11px] text-amber-700 dark:text-amber-400 uppercase tracking-[0.18em] mb-3 border-b border-amber-500/30 pb-2">
          <AlertTriangle className="w-4 h-4" />
          Honesty box — scope limits (do not over-read)
        </div>
        <div className="space-y-3 font-serif text-base leading-relaxed text-foreground/90">
          <p>
            Haar measure, the Peter-Weyl decomposition, and the{" "}
            <span className={mono}>‖g − 1‖² ≥ 0</span> /{" "}
            <span className={mono}>Re tr g ≤ 3</span> inequality are{" "}
            <strong>real, verified, sorry-free bricks</strong>. That is the whole
            of what this page claims.
          </p>
          <p>
            They are <strong>not</strong> a proof of the Yang-Mills mass gap. The
            operator used downstream is the{" "}
            <strong>scalar / Perron-sector shadow</strong>{" "}
            <span className={mono}>H = wilsonAction U · 𝟙</span>, which is{" "}
            <strong>not</strong> the real Wilson transfer Hamiltonian on{" "}
            <span className={mono}>L²(∏ SU(3), Haar)</span>. The action positivity
            above is scalar-sector action positivity only.
          </p>
          <p>
            <strong>Surface #1 stays OPEN.</strong> The mass-gap target file{" "}
            <span className={mono}>MassGap574.lean</span> still carries a{" "}
            <span className={mono}>sorry</span> and is untouched by this work; the
            YM tower's status remains <span className={mono}>Open</span>. There is{" "}
            <strong>no μ &gt; 0 claim</strong> and this is{" "}
            <strong>not</strong> the Clay Yang-Mills solution. These files are
            foundational infrastructure, surfaced honestly — nothing more.
          </p>
        </div>
      </Card>

      <Card className="p-6 border-border bg-card">
        <div className="flex items-center gap-2 font-mono text-[11px] text-muted-foreground uppercase tracking-[0.18em] mb-2 border-b border-border pb-2">
          <Download className="w-4 h-4" />
          Download the verified sources
        </div>
        <p className="font-serif text-sm leading-relaxed text-foreground/80 mb-5">
          The four files below are the as-verified Lean sources, bundled directly
          from the proof tree. Each is sorry-free with axiom footprint{" "}
          <span className={mono}>{TRIO}</span>.
        </p>
        <div className="space-y-3">
          {LEAN_FILES.map((file) => (
            <div
              key={file.filename}
              className="border border-border bg-muted/20 p-4 flex flex-col gap-3 md:flex-row md:items-start md:justify-between"
              data-testid={`lean-file-${file.filename}`}
            >
              <div className="min-w-0 space-y-1.5">
                <div className="flex items-baseline gap-2 flex-wrap">
                  <span className="font-mono text-sm font-bold text-foreground">
                    {file.filename}
                  </span>
                  <span className="font-sans text-xs text-muted-foreground">
                    · {file.title}
                  </span>
                  <span className="font-mono text-[10px] text-muted-foreground">
                    ({lineCount(file.source)} lines)
                  </span>
                </div>
                <p className="font-serif text-sm leading-relaxed text-foreground/80">
                  {file.scope}
                </p>
                <div className="inline-flex items-center gap-1 px-2 py-0.5 border border-green-500/50 bg-green-500/10 font-mono text-[10px] font-bold uppercase text-green-700 dark:text-green-400">
                  <ShieldCheck className="w-3 h-3" /> sorry-free · axioms ={" "}
                  {TRIO}
                </div>
              </div>
              <button
                type="button"
                onClick={() => downloadLean(file.filename, file.source)}
                className="flex-shrink-0 inline-flex items-center gap-2 px-3 py-1.5 text-xs font-mono uppercase tracking-wider bg-primary text-primary-foreground hover:opacity-90 transition-opacity self-start"
                data-testid={`button-download-${file.filename}`}
              >
                <Download className="w-3.5 h-3.5" /> .lean
              </button>
            </div>
          ))}
        </div>
      </Card>

      <div className="text-[10px] font-mono text-muted-foreground text-center pt-2">
        Entangled Technologies · verified SU(3) foundations · axiom debt ={" "}
        {TRIO}
      </div>
    </div>
  );
}
