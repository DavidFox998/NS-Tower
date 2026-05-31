import { Link } from "wouter";
import { ArrowLeft, Download, ShieldCheck, AlertTriangle, Infinity as InfinityIcon } from "lucide-react";
import { Card } from "@/components/ui/card";
import zoeSource from "@lean/Towers/Hodge/ZoeComparisonTest.lean?raw";

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

interface Fact {
  claim: string;
  detail: string;
}

const MACHINE_CHECKED: Fact[] = [
  {
    claim: "C(5,2) = 10,  C(5,2) + C(5,4) = 15,  15 > 10",
    detail:
      "The combinatorics behind Paper 2's Hankel rank. The 15 is the Hankel rank (a Paper-2 input datum), the order-10 recurrence test fails because 15 > 10.",
  },
  {
    claim: "Z ≤ p = 2   (capped at 2, NOT 15)",
    detail:
      "The Zoe invariant satisfies the proven bound 1 ≤ Z ≤ p, and for X₅ the relevant p = 2 — so Z is capped at 2. The Zoe invariant Z and the Hankel rank 15 are different quantities; the machine-checked content is the bound, never the conflation Z = 15.",
  },
  {
    claim: "𝔗(ω, s) is ENTIRE  (radius of convergence R = ∞)",
    detail:
      "For any Z, b = q^s ≥ 0 and ANY Frobenius pairing obeying the geometric Weil bound |⟨ω, Frobⁿω⟩| ≤ C·Bⁿ, the term sequence is absolutely summable. The (n!)² denominator overwhelms any geometric growth.",
  },
  {
    claim: "C(1, 2) = 0   (Step-3 degeneracy)",
    detail:
      "An axiom-free refutation of Lemma 7.6's Step 3: the literal bound Z ≤ C(dim NS, p) collapses to C(1,2) = 0, which would forbid the very classes it invokes. Step 3 conflates the wedge-of-NS dimension with the tensor rank. Refutes the step, not Hodge.",
  },
];

function lineCount(source: string): number {
  return source.split("\n").length;
}

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

export default function HodgePage() {
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
          Hodge conjecture · X₅ = Jac(y² = x¹¹ − x)
        </div>
        <h2 className="text-3xl font-bold font-sans tracking-tight mb-2">
          The Zoe Comparison Test — an honest reduction
        </h2>
        <p className="text-sm font-mono text-muted-foreground">
          WHERE THE ARITHMETIC STOPS AND THE ANALYTIC HYPOTHESIS BEGINS · HODGE
          STATUS: OPEN
        </p>
      </header>

      <Card className="p-6 border-primary/50 bg-primary/5">
        <div className="font-mono text-[10px] text-primary uppercase tracking-[0.18em] mb-2">
          What this page is
        </div>
        <p className="font-serif text-base leading-relaxed">
          This page studies the <strong>Zoe Comparison Test</strong>, the
          generating function
          <span className="block my-2 text-center">
            <span className={mono}>
              𝔗(ω, s) = Σ_(n≥0)  Z(ω)ⁿ / (n!)²  ·  ⟨ω, Frobⁿ ω⟩  ·  q^(ns)
            </span>
          </span>
          attached to a Hodge class <span className={mono}>ω</span> on the
          genus-5 Jacobian <span className={mono}>X₅ = Jac(y² = x¹¹ − x)</span>.
          It reduces the Hodge question for <span className={mono}>X₅</span> to a{" "}
          <strong>single named, open analytic hypothesis</strong>, with every
          arithmetic fact machine-checked in Lean (sorry-free, axiom footprint{" "}
          <span className={mono}>{TRIO}</span>). It does <strong>not</strong>{" "}
          prove or disprove any instance of the Hodge conjecture. See the honesty
          box for the scope limits.
        </p>
      </Card>

      <Card className="p-6 border-green-500/50 bg-green-500/5">
        <div className="flex items-center gap-2 font-mono text-[11px] text-green-700 dark:text-green-400 uppercase tracking-[0.18em] mb-4 border-b border-green-500/30 pb-2">
          <ShieldCheck className="w-4 h-4" />
          Machine-checked — sorry-free · axioms = {TRIO}
        </div>
        <div
          className="mb-4 px-3 py-2 border border-green-500/40 bg-green-500/10 font-mono text-[11px] text-green-800 dark:text-green-300 leading-relaxed"
          data-testid="badge-hodge-summary"
        >
          Z ≤ p = 2 · rank = 15 &gt; 10 · 𝔗 entire / R = ∞ ·
          AnalyticObstruction OPEN · HODGE_STATUS: OPEN
        </div>
        <div className="space-y-4">
          {MACHINE_CHECKED.map((f) => (
            <div
              key={f.claim}
              className="border border-border bg-muted/20 p-4"
              data-testid={`fact-${f.claim.slice(0, 8)}`}
            >
              <div className="font-mono text-sm font-bold text-foreground mb-1.5">
                {f.claim}
              </div>
              <p className="font-serif text-sm leading-relaxed text-foreground/80">
                {f.detail}
              </p>
            </div>
          ))}
        </div>
      </Card>

      <Section index="§ 1" title="Z = 2, not 15 — two different numbers">
        <p>
          The source trilogy attaches two integers to{" "}
          <span className={mono}>X₅</span>, and it is essential not to confuse
          them. The <strong>Zoe invariant</strong>{" "}
          <span className={mono}>Z(A) = |Gal(E*/F*)/H|</span> obeys the proven
          bound <span className={mono}>1 ≤ Z(A) ≤ p</span>; for the relevant CM
          model of <span className={mono}>X₅</span> one has{" "}
          <span className={mono}>p = 2</span>, so <strong>Z is capped at 2</strong>{" "}
          (<span className={mono}>1 ≤ Z ≤ 2</span>). The{" "}
          <strong>Hankel rank</strong> <span className={mono}>rank(H) = 15</span>{" "}
          is an entirely different quantity — the rank of the Hankel matrix from
          Paper 2, equal to{" "}
          <span className={mono}>C(5,2) + C(5,4) = 10 + 5</span>, which exceeds
          the order-10 recurrence test (<span className={mono}>15 &gt; 10</span>),
          so the test returns False. Both numbers are real; writing
          &ldquo;Z = 15&rdquo; conflates them. The Lean leaf keeps them as
          separately-named, separately-checked facts.
        </p>
      </Section>

      <Section
        index="§ 2"
        title="The series is entire — it supplies no obstruction"
      >
        <p>
          The decisive analytic fact is the <strong>(n!)²</strong> denominator.
          The Weil bounds give a geometric growth ceiling on the Frobenius
          pairing, <span className={mono}>|⟨ω, Frobⁿ ω⟩| ≤ C·Bⁿ</span>. Any
          geometric growth is annihilated by a factorial, let alone a squared
          factorial: comparing to the classical exponential series{" "}
          <span className={mono}>Σ rⁿ/n!</span> shows{" "}
          <span className={mono}>Σ |aₙ|</span> converges for{" "}
          <em>every</em> <span className={mono}>s</span>. So{" "}
          <span className={mono}>𝔗(ω, s)</span> is <strong>entire</strong>:{" "}
          <span className={mono}>R = ∞</span>.
        </p>
        <p className="border-l-4 border-primary pl-4 bg-muted/30 py-2 font-serif text-base leading-relaxed">
          This is the <strong>opposite</strong> of the earlier
          &ldquo;radius&nbsp;0, pole at <span className={mono}>s = 1</span>&rdquo;
          framing. As literally defined, the Zoe Comparison Test{" "}
          <strong>diverges nowhere</strong> — and a series that never diverges
          supplies <strong>no</strong> divergence-based obstruction to any class
          being algebraic. We record this as a machine-checked finding; we do not
          manufacture a divergence.
        </p>
      </Section>

      <Section index="§ 3" title="The one open hypothesis the reduction rests on">
        <p>
          What remains is purely an analytic bridge:{" "}
          <em>
            if the test were to diverge for a class, that class would be
            transcendental (hence non-algebraic, an obstruction to Hodge).
          </em>{" "}
          In the Lean leaf this appears <strong>only</strong> as a conditional
          combinator, <span className={mono}>hodge_obstruction_conditional</span>,
          over a single named-open <span className={mono}>Prop</span>{" "}
          <span className={mono}>
            AnalyticObstruction := (Diverges ω → Transcendental ω)
          </span>
          . The goal is closed from that hypothesis (<span className={mono}>
            exact h h_div
          </span>) with <strong>zero sorry</strong> — the same named-open-Prop
          pattern as the YM (Wall256) and NS (Wall300) scaffolds. The Prop is
          never discharged.
        </p>
        <p>
          Crucially this combinator is <strong>vacuous for the real object</strong>
          : §&nbsp;2 proved <span className={mono}>𝔗</span> is entire, so the
          divergence antecedent is never met. It therefore proves the
          transcendence of <strong>no actual class</strong>. The predicates{" "}
          <span className={mono}>Transcendental</span> and{" "}
          <span className={mono}>Diverges</span>, the class type, and the
          Frobenius pairing are all abstract symbols. Discharging this hypothesis
          — or constructing a genuine obstruction another way — is research-grade
          work that this repo does not attempt.
        </p>
      </Section>

      <Section index="§ 4" title="Appendix A — superseded prior work">
        <p>
          The earlier &ldquo;Lemma 7.6&rdquo; (the &ldquo;M.S. bound&rdquo;) was
          machine-generated and its proof is unsound; it is{" "}
          <strong>uncertified and superseded</strong>, and is never stamped as an
          obstruction here. The companion <strong>M* Transform</strong>,{" "}
          <span className={mono}>M*(ω) = (12/11)·(1/Z)</span>, is a{" "}
          <em>bijection of Z</em> (<span className={mono}>M* = 4/55 ⟺ Z = 15</span>),
          so &ldquo;M* ⇒ Hodge fails&rdquo; is just Lemma 7.6's contrapositive
          renamed — it carries no independent proof content and is likewise
          superseded. The earlier claim that &ldquo;200 classes are
          transcendental via Lemma 7.6&rdquo; is <strong>retracted</strong>; it is
          replaced by the honest machine-checked statements above.
        </p>
      </Section>

      <Card className="p-6 border-amber-500/60 bg-amber-500/5">
        <div className="flex items-center gap-2 font-mono text-[11px] text-amber-700 dark:text-amber-400 uppercase tracking-[0.18em] mb-3 border-b border-amber-500/30 pb-2">
          <AlertTriangle className="w-4 h-4" />
          Honesty box — scope limits (do not over-read)
        </div>
        <div className="space-y-3 font-serif text-base leading-relaxed text-foreground/90">
          <p>
            The machine-checked content is exactly: the combinatorics
            (<span className={mono}>C(5,2)=10</span>,{" "}
            <span className={mono}>rank = 15 &gt; 10</span>), the Zoe bound{" "}
            <span className={mono}>Z ≤ p = 2</span>, the entirety of{" "}
            <span className={mono}>𝔗</span> (<span className={mono}>R = ∞</span>),
            and the <span className={mono}>C(1,2) = 0</span> Step-3 refutation.
            That is the whole of what this page claims as proven.
          </p>
          <p>
            <strong>The Hodge conjecture is OPEN</strong> (Clay / CMI). Nothing
            here proves or disproves it for <span className={mono}>X₅</span> or any
            other variety. No class is shown algebraic or transcendental. The
            divergence&nbsp;⇒&nbsp;transcendence step is a{" "}
            <strong>named open analytic hypothesis</strong>, carried but never
            discharged; the Weil bound is a carried hypothesis, not re-proved
            here.
          </p>
          <p>
            The conditional combinator is <strong>vacuous</strong> for the real
            series, and the symbols in it are abstract. This page documents a
            clean reduction and refutes an earlier &ldquo;radius 0&rdquo; framing
            — nothing more.
          </p>
        </div>
      </Card>

      <Card className="p-6 border-border bg-card">
        <div className="flex items-center gap-2 font-mono text-[11px] text-muted-foreground uppercase tracking-[0.18em] mb-2 border-b border-border pb-2">
          <Download className="w-4 h-4" />
          Download the verified source
        </div>
        <p className="font-serif text-sm leading-relaxed text-foreground/80 mb-5">
          The as-verified Lean leaf, bundled directly from the proof tree.
          Sorry-free; classical-trio axiom footprint on the analytic theorems,
          axiom-free on the conditional and arithmetic ones. Verified via the
          direct-lean bypass (raw <span className={mono}>lean</span> v4.12.0,
          EXIT = 0).
        </p>
        <div
          className="border border-border bg-muted/20 p-4 flex flex-col gap-3 md:flex-row md:items-start md:justify-between"
          data-testid="lean-file-ZoeComparisonTest.lean"
        >
          <div className="min-w-0 space-y-1.5">
            <div className="flex items-baseline gap-2 flex-wrap">
              <span className="font-mono text-sm font-bold text-foreground">
                ZoeComparisonTest.lean
              </span>
              <span className="font-sans text-xs text-muted-foreground">
                · Hodge X₅ Zoe Comparison Test
              </span>
              <span className="font-mono text-[10px] text-muted-foreground">
                ({lineCount(zoeSource)} lines)
              </span>
            </div>
            <p className="font-serif text-sm leading-relaxed text-foreground/80">
              Standalone leaf for X₅. Machine-checks the combinatorics, the Zoe
              bound (Z ≤ 2), and that 𝔗 is entire (R = ∞); lands the SORRY-free
              conditional obstruction combinator over one named-open hypothesis.
              NOT a brick, not in BRICKS, not a lakefile root; touches no YM/NS
              surface. Hodge stays OPEN.
            </p>
            <div className="inline-flex items-center gap-1 px-2 py-0.5 border border-green-500/50 bg-green-500/10 font-mono text-[10px] font-bold uppercase text-green-700 dark:text-green-400">
              <ShieldCheck className="w-3 h-3" /> sorry-free · axioms = {TRIO}
            </div>
          </div>
          <button
            type="button"
            onClick={() => downloadLean("ZoeComparisonTest.lean", zoeSource)}
            className="flex-shrink-0 inline-flex items-center gap-2 px-3 py-1.5 text-xs font-mono uppercase tracking-wider bg-primary text-primary-foreground hover:opacity-90 transition-opacity self-start"
            data-testid="button-download-ZoeComparisonTest.lean"
          >
            <Download className="w-3.5 h-3.5" /> .lean
          </button>
        </div>
      </Card>

      <div className="flex items-center justify-center gap-2 text-[10px] font-mono text-muted-foreground text-center pt-2">
        <InfinityIcon className="w-3 h-3" />
        Entangled Technologies · Hodge X₅ reduction · 𝔗 entire (R = ∞) · Hodge
        status: OPEN
      </div>
    </div>
  );
}
