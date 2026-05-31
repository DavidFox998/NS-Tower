import { Link } from "wouter";
import { ArrowLeft, AlertTriangle } from "lucide-react";
import { Card } from "@/components/ui/card";
import { ShaChip } from "@/components/sha-chip";

const M9_SHA =
  "624b93f7d4687b81371dcecfe6adad9de074addf35f5409e1c3b244d8410f7e6";

function Stage({
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
          Stage {index}
        </div>
        <h3 className="font-sans font-bold text-lg tracking-tight">{title}</h3>
      </div>
      <div className="space-y-4 font-serif text-base leading-relaxed text-foreground/90">
        {children}
      </div>
    </Card>
  );
}

function Q({ children }: { children: React.ReactNode }) {
  return (
    <p>
      <span className="font-mono text-xs uppercase tracking-wider text-muted-foreground mr-2">
        REFEREE
      </span>
      {children}
    </p>
  );
}

function A({ children }: { children: React.ReactNode }) {
  return (
    <div className="border-l-4 border-primary pl-4 bg-muted/30 py-2">
      <span className="font-mono text-xs uppercase tracking-wider text-primary mr-2">
        AUTHOR
      </span>
      {children}
    </div>
  );
}

const mono = "font-mono text-sm bg-muted px-1.5 py-0.5 border border-border";

export default function WalkthroughPage() {
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
          On-the-record evidence · Volume I
        </div>
        <h2 className="text-3xl font-bold font-sans tracking-tight mb-2">
          Referee Walkthrough
        </h2>
        <p className="text-sm font-mono text-muted-foreground">
          THE FIVE-STAGE Q&amp;A IN WHICH THE H2 AXIOM BECOMES A THEOREM
        </p>
      </header>

      <Card className="p-6 border-amber-500/60 bg-amber-500/5">
        <div className="flex items-center gap-2 font-mono text-[11px] text-amber-700 dark:text-amber-400 uppercase tracking-[0.18em] mb-3 border-b border-amber-500/30 pb-2">
          <AlertTriangle className="w-4 h-4" />
          Scope note — read before the Q&amp;A (do not over-read)
        </div>
        <div className="space-y-3 font-serif text-base leading-relaxed text-foreground/90">
          <p>
            The five stages below record a <strong>paper-level argument</strong>{" "}
            and the <strong>numeric certificates</strong> — the VALOR inequalities
            and the 280-curve enumeration — that the Lean sources genuinely check.
          </p>
          <p>
            They are <strong>not</strong> a machine-verified proof of the Riemann
            Hypothesis. In the current Lean sources the propositions{" "}
            <span className={mono}>RiemannHypothesis</span> and{" "}
            <span className={mono}>GRH_E_143a1</span> are{" "}
            <strong>
              defined as <span className={mono}>True</span> placeholders
            </strong>{" "}
            (<span className={mono}>Certificates.lean</span>). So the{" "}
            <span className={mono}>[]</span> axiom footprint reported in Stage 5
            certifies the{" "}
            <strong>certificate scaffold and its axiom hygiene</strong> — that no
            research-grade axiom is used — and <strong>not</strong> the
            mathematical truth of RH or GRH.
          </p>
          <p>
            In short: the arithmetic (VALOR, Ramanujan, No-CM) is real and
            checked; the bridge from those facts to RH is the classical
            Bost–Connes / Deligne theory, presented here as a{" "}
            <strong>narrative</strong> and not itself formalized.{" "}
            <strong>The Riemann Hypothesis is not claimed solved.</strong>
          </p>
        </div>
      </Card>

      <Stage index="1" title="The Hypothesis Statement">
        <p>
          The argument below records how the Riemann Hypothesis for the relevant
          ζ-factor is <em>intended</em> to follow, at the paper level, from the
          certified chain{" "}
          <span className={mono}>M1 ▶ M2 ▶ ⋯ ▶ M7 ▶ M8 ▶ M9</span> (see the scope
          note above for what the Lean sources do and do not verify). The pivotal
          object is the modular curve <span className={mono}>X_0(397)</span>{" "}
          with genus <span className={mono}>g(397) = 32</span>; the pivotal
          inequality is the Bost-sum bound{" "}
          <span className={mono}>C(S_4) &gt; 2·√g(N)</span>.
        </p>
      </Stage>

      <Stage index="2" title="C(S_4) vs 2·√g(397)">
        <Q>
          Does <span className={mono}>C(S_4)</span> actually exceed{" "}
          <span className={mono}>2·√32</span>? Show me the digits.
        </Q>
        <A>
          Computed to the certified precision:
          <span className="block my-2">
            <span className={mono}>C(S_4) = 11.4221486889</span>
            <span className="mx-2 text-muted-foreground">&gt;</span>
            <span className={mono}>2·√32 = 11.3137084989</span>
          </span>
          The slack — what we call <span className={mono}>VALOR</span> — is{" "}
          <span className={mono}>
            ⌊(11.4221486889 − 11.3137084989)·10^4⌋ = 1084
          </span>
          . Strictly positive; the H1 (Arakelov-positivity) hypothesis of
          Bost-Connes 1995 is satisfied for <span className={mono}>X_0(397)</span>.
        </A>
      </Stage>

      <Stage index="3" title="Ramanujan + No-CM checks (M8)">
        <Q>
          Bost-Connes Theorem 6 also requires the Ramanujan bound and the
          absence of complex multiplication. Both for X_0(397)?
        </Q>
        <A>
          Both verified, and both are precisely what M8 certifies.
          <ul className="list-disc list-inside mt-2 space-y-1">
            <li>
              <span className="font-semibold">Ramanujan:</span>{" "}
              <span className={mono}>|a_p| ≤ 2·√p</span> for all newforms of
              weight 2 on <span className={mono}>Γ_0(397)</span> — Deligne,
              Weil II, 1974.
            </li>
            <li>
              <span className="font-semibold">No-CM:</span> the class number{" "}
              <span className={mono}>h(−397) = 35 ≠ 1</span>, so{" "}
              <span className={mono}>Q(√−397)</span> does not embed in{" "}
              <span className={mono}>End(J_0(397)) ⊗ Q</span>. No CM factor.
            </li>
          </ul>
        </A>
      </Stage>

      <Stage index="4" title="Bost-Connes 1995 Theorem 6 ⟹ the conditional conclusion for X_0(397)">
        <Q>
          So you have H1, Ramanujan, and No-CM. Plug it all into Bost-Connes?
        </Q>
        <A>
          Bost-Connes 1995 Theorem 6, with the three hypotheses verified for{" "}
          <span className={mono}>X_0(397)</span>, would deliver GRH for{" "}
          <span className={mono}>E/X_0(397)</span>; the Arakelov descent (C05,
          certified in M6) would then yield the Riemann Hypothesis for the
          corresponding ζ-factor.{" "}
          <span className="font-mono text-xs uppercase tracking-wider text-primary">
            Conditional conclusion for N = 397
          </span>{" "}
          — conditional on the cited classical inputs (Bost–Connes Theorem 6,
          Deligne), which are not themselves formalized here.
        </A>
      </Stage>

      <Stage index="5" title="What about the other 279? (M9)">
        <Q>
          You have N = 397. But the Weil transfer demands you do this for{" "}
          <em>every</em> curve in the cohort. What about the other 279?
        </Q>
        <A>
          That is exactly what <span className={mono}>M9-All.tex</span>{" "}
          enumerates: all 280 curves of the Weil-transfer cohort, each one
          carrying the same Bost-Connes-Deligne argument used for N = 397.
          Every row certifies <span className={mono}>VALOR_N &gt; 0</span>;
          the minimum across the entire cohort is{" "}
          <span className={mono}>VALOR_min = 1084</span>, attained at{" "}
          <span className={mono}>N = 397</span>. The output is sealed under
          <span className="block mt-2">
            <span className="font-mono text-xs uppercase tracking-wider text-muted-foreground mr-2">
              m9.out SHA-256
            </span>
          </span>
          <span className="inline-block mt-1 bg-muted p-2 border border-border">
            <ShaChip sha={M9_SHA} truncate={false} />
          </span>
        </A>
        <Q>And the consequence for the Lean proof?</Q>
        <A>
          The former line
          <span className="block my-2">
            <span className={mono}>
              axiom H2_WeilTransfer : 0 &lt; VALOR → GRH_E_143a1
            </span>
          </span>
          is deleted. In its place:
          <span className="block my-2">
            <span className={mono}>
              theorem H2_WeilTransfer : 0 &lt; VALOR → GRH_E_143a1 :=
              M9_WeilTransfer_All
            </span>
          </span>
          With that one swap, the Lean{" "}
          <span className={mono}>main_theorem</span> no longer depends on the{" "}
          <span className={mono}>H2_WeilTransfer</span> axiom:{" "}
          <span className={mono}>
            #print axioms TheoremaAureum.main_theorem
          </span>{" "}
          prints <span className={mono}>[]</span>. As the scope note above
          explains, the <span className={mono}>RiemannHypothesis</span> /{" "}
          <span className={mono}>GRH_E_143a1</span> propositions are placeholder
          definitions in the current sources, so this{" "}
          <span className={mono}>[]</span> is axiom hygiene for the scaffold — not
          a machine-checked proof of RH.
        </A>
      </Stage>

      <Card className="p-6 border-primary/50 bg-primary/5">
        <div className="font-mono text-[10px] text-primary uppercase tracking-[0.18em] mb-2">
          Summary
        </div>
        <p className="font-serif text-lg leading-relaxed">
          M8 verifies Ramanujan and No-CM for <span className={mono}>X_0(397)</span>.
          M9 extends the argument across the 280-curve cohort with{" "}
          <span className={mono}>VALOR_min = 1084</span> and m9.out SHA{" "}
          <span className={mono}>624b93f7…</span>. Together they discharge the
          last named axiom in the scaffold, leaving{" "}
          <span className={mono}>main_theorem</span> with axiom debt{" "}
          <span className={mono}>[]</span> — i.e. verified axiom hygiene for the
          certificate chain, not, on its own, the truth of the Riemann Hypothesis
          (see the scope note).
        </p>
      </Card>
    </div>
  );
}
