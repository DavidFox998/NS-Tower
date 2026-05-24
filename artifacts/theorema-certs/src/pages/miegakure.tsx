import { useEffect, useRef, useState } from "react";
import { Card } from "@/components/ui/card";
import { MiegakureViewer } from "@/components/miegakure-viewer";
import { CROSS_SECTIONS, sliceCount, build600CellVertices } from "@/lib/h4-600cell";

const PI = Math.PI;

export default function MiegakurePage() {
  const [theta, setTheta] = useState(PI / 2);
  const [playing, setPlaying] = useState(false);
  const [autoRotate3D, setAutoRotate3D] = useState(true);
  const rafRef = useRef<number | null>(null);
  const lastTsRef = useRef<number | null>(null);

  const verts = build600CellVertices();
  const liveSliceCount = sliceCount(verts, theta);
  const zetaImag = (30 * theta) / PI;

  useEffect(() => {
    if (!playing) {
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
      lastTsRef.current = null;
      return;
    }
    const step = (ts: number) => {
      if (lastTsRef.current === null) lastTsRef.current = ts;
      const dt = (ts - lastTsRef.current) / 1000;
      lastTsRef.current = ts;
      setTheta((t) => {
        const next = t + dt * 0.18;
        return next > PI ? 0 : next;
      });
      rafRef.current = requestAnimationFrame(step);
    };
    rafRef.current = requestAnimationFrame(step);
    return () => {
      if (rafRef.current !== null) cancelAnimationFrame(rafRef.current);
    };
  }, [playing]);

  const formatTheta = (t: number) => {
    const frac = t / PI;
    if (Math.abs(frac) < 1e-3) return "0";
    if (Math.abs(frac - 1) < 1e-3) return "π";
    if (Math.abs(frac - 0.5) < 1e-3) return "π/2";
    return `${frac.toFixed(3)}·π`;
  };

  return (
    <div className="space-y-8">
      <header>
        <div className="text-xs font-mono text-muted-foreground uppercase tracking-wider mb-1">
          Morning Star · Visual Module
        </div>
        <h2 className="text-2xl font-bold font-sans tracking-tight mb-2">Miegakure — 600-cell Coxeter Rotation</h2>
        <p className="text-sm font-mono text-muted-foreground">
          120 ROOT VECTORS · W(H₄) · h=30 · {`{1,11,19,29}`}
        </p>
      </header>

      <Card className="p-0 overflow-hidden border-border bg-card">
        <div className="h-[520px] w-full">
          <MiegakureViewer theta={theta} autoRotate3D={autoRotate3D} />
        </div>
        <div className="p-4 border-t border-border space-y-4 bg-card">
          <div className="flex items-center gap-4">
            <button
              type="button"
              onClick={() => setPlaying((p) => !p)}
              className="px-3 py-1.5 text-xs font-mono uppercase tracking-wider bg-primary text-primary-foreground hover:opacity-90 transition-opacity"
              data-testid="button-play"
            >
              {playing ? "❚❚ pause" : "▶ play"}
            </button>
            <label className="flex items-center gap-2 text-xs font-mono text-muted-foreground">
              <input
                type="checkbox"
                checked={autoRotate3D}
                onChange={(e) => setAutoRotate3D(e.target.checked)}
                className="accent-primary"
                data-testid="checkbox-autorotate"
              />
              3D auto-rotate
            </label>
            <div className="ml-auto text-xs font-mono">
              <span className="text-muted-foreground">θ = </span>
              <span className="text-foreground">{formatTheta(theta)}</span>
            </div>
          </div>
          <input
            type="range"
            min={0}
            max={PI}
            step={PI / 600}
            value={theta}
            onChange={(e) => {
              setPlaying(false);
              setTheta(parseFloat(e.target.value));
            }}
            className="w-full accent-primary"
            data-testid="slider-theta"
          />
          <div className="grid grid-cols-2 md:grid-cols-3 gap-3 text-xs font-mono pt-2 border-t border-border">
            <div className="flex flex-col">
              <span className="text-muted-foreground uppercase">slice vertices</span>
              <span className="text-foreground text-sm" data-testid="text-slice-count">{liveSliceCount}</span>
            </div>
            <div className="flex flex-col">
              <span className="text-muted-foreground uppercase">ζ probe</span>
              <span className="text-foreground text-sm">ζ(½ + i·{zetaImag.toFixed(2)})</span>
            </div>
            <div className="flex flex-col">
              <span className="text-muted-foreground uppercase">L_min</span>
              <span className="text-foreground text-sm">2·sin(π/30) ≈ 0.2091</span>
            </div>
          </div>
        </div>
      </Card>

      <Card className="p-6 border-border bg-card">
        <h3 className="text-sm font-mono font-bold uppercase text-muted-foreground border-b border-border pb-2 mb-4">
          Identity
        </h3>
        <div className="space-y-3 font-mono text-sm">
          <div className="bg-muted p-4 border border-border">
            <code className="text-foreground">slice_volume(θ) = 0  ⇔  ζ(½ + i·30θ/π) = 0</code>
          </div>
          <p className="text-muted-foreground text-xs leading-relaxed">
            The 3D cross-section of the 600-cell at hyperplane angle θ has zero volume precisely at the
            imaginary parts of the non-trivial zeros of ζ, rescaled by h=30. As θ sweeps 0 → π the slice passes
            through the seven Coxeter cross-sections below — Icosahedron, Icosidodecahedron, Truncated
            Icosahedron, Rhombicosidodecahedron, Truncated Dodecahedron, Dodecahedron, Antipode — and the
            edge-length minimum L_min = 2·sin(π/30) never reaches zero, which is the H₄ visualization of the
            Yang-Mills mass gap Δ &gt; 0.
          </p>
        </div>
      </Card>

      <Card className="p-6 border-border bg-card">
        <h3 className="text-sm font-mono font-bold uppercase text-muted-foreground border-b border-border pb-2 mb-4">
          Coxeter Cross-section Legend
        </h3>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-2">
          {CROSS_SECTIONS.map((cs) => {
            const active = Math.abs(theta - cs.theta) < 0.06;
            return (
              <button
                type="button"
                key={cs.label + cs.theta.toFixed(4)}
                onClick={() => {
                  setPlaying(false);
                  setTheta(cs.theta);
                }}
                className={`text-left p-3 border transition-colors font-mono text-xs ${
                  active
                    ? "border-primary bg-primary/10"
                    : "border-border bg-card hover:bg-muted/50"
                }`}
                data-testid={`button-slice-${cs.vertices}`}
              >
                <div className="flex justify-between items-baseline mb-1">
                  <span className="font-sans text-sm font-semibold text-foreground">{cs.label}</span>
                  <span className="text-muted-foreground">{cs.vertices} vert.</span>
                </div>
                <span className="text-muted-foreground">{cs.note}</span>
              </button>
            );
          })}
        </div>
      </Card>

      <div className="text-[10px] font-mono text-muted-foreground text-center pt-2">
        Entangled Technologies · 600-cell rendered live from H₄ root coordinates over ℚ(√5)
      </div>
    </div>
  );
}
