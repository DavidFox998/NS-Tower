import { useParams } from "wouter";
import {
  useGetCertificate,
  getGetCertificateQueryKey,
  useGetCertificateSummary,
} from "@workspace/api-client-react";
import { ShaChip } from "@/components/sha-chip";
import { StatusBadge } from "@/components/status-badge";
import { PdfUploader } from "@/components/pdf-uploader";
import { LeanAxiomChip } from "@/components/lean-axiom-chip";
import { ArrowLeft, FileText, Code2, Clock } from "lucide-react";
import { Link } from "wouter";
import { Card } from "@/components/ui/card";
import { format } from "date-fns";

function getStaticPdfPath(moduleId: string): string | null {
  const match = moduleId.match(/^M([1-8])$/i);
  if (!match) return null;
  return `${import.meta.env.BASE_URL}pdfs/m${match[1]}.pdf`;
}

export default function CertificateDetailPage() {
  const params = useParams();
  const moduleId = params.moduleId!;

  const { data: cert, isLoading } = useGetCertificate(moduleId, {
    query: { enabled: !!moduleId, queryKey: getGetCertificateQueryKey(moduleId) }
  });
  const { data: summary } = useGetCertificateSummary();

  if (isLoading) {
    return <div className="animate-pulse space-y-4">
      <div className="h-8 w-32 bg-muted mb-6"></div>
      <div className="h-64 bg-muted border border-border"></div>
    </div>;
  }

  if (!cert) {
    return <div className="text-destructive font-mono text-sm">CERTIFICATE NOT FOUND</div>;
  }

  const staticPdf = getStaticPdfPath(cert.moduleId);
  const pdfSrc = cert.pdfObjectPath
    ? `/api/storage${cert.pdfObjectPath.startsWith("/objects/") ? cert.pdfObjectPath : `/objects/${cert.pdfObjectPath}`}`
    : staticPdf;
  const hasAnyPdf = !!pdfSrc;

  return (
    <div className="space-y-6">
      <Link href="/certificates" className="inline-flex items-center text-xs font-mono text-muted-foreground hover:text-foreground transition-colors mb-4">
        <ArrowLeft className="w-3 h-3 mr-2" /> BACK TO LEDGER
      </Link>

      <header className="flex flex-col md:flex-row md:items-start justify-between gap-4 border-b border-border pb-6">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h2 className="text-3xl font-bold font-sans tracking-tight">{cert.moduleId}</h2>
            <StatusBadge status={cert.status} />
          </div>
          <h1 className="text-xl font-sans text-foreground/90">{cert.title}</h1>
        </div>
        <div className="flex items-center gap-2">
          {!hasAnyPdf && <PdfUploader moduleId={cert.moduleId} />}
        </div>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">Mathematical Claim</h3>
            <p className="font-serif text-lg leading-relaxed text-foreground/90 bg-muted/30 p-4 border-l-4 border-primary">
              {cert.claim}
            </p>
          </Card>

          {cert.moduleId === "M3" && (
            <Card className="p-6 border-primary/50 bg-card" data-testid="card-p5-bridge">
              <h3 className="text-xs font-mono font-bold text-primary uppercase tracking-wider mb-4 border-b border-border pb-2">
                P5 Bridge: 191·κ¹⁶ Approximation
              </h3>
              <div className="bg-muted/40 border-l-4 border-primary p-4 font-mono text-sm leading-relaxed space-y-1 overflow-x-auto">
                <div>q=191 · m=16 · k=4302500806252</div>
                <div>
                  | 191·κ¹⁶ − P5 − k·π | ={" "}
                  <span className="text-primary font-bold">error=0.0382906</span> &lt; 1 ✓
                </div>
                <div className="text-muted-foreground">
                  ratio=9.588e-15 · κ = 4.84330141945946 (15 digits)
                </div>
              </div>
              <p className="font-serif text-sm leading-relaxed text-foreground/85 mt-4">
                The P5 bridge is a numerical observation, verifiable only at P5 with a
                15-digit κ. No new mathematics is claimed.
              </p>
              <div className="flex flex-wrap items-center gap-3 mt-4 font-mono text-xs">
                <Link
                  href="/desert-map#P5"
                  className="text-primary underline underline-offset-2"
                  data-testid="link-back-desert-map-p5"
                >
                  ← Back to Desert Map · P5
                </Link>
                <span className="text-muted-foreground">Related:</span>
                <Link
                  href="/certificates/M1"
                  className="text-primary underline underline-offset-2"
                  data-testid="link-m3-to-m1"
                >
                  M1
                </Link>
                <Link
                  href="/certificates/M4"
                  className="text-primary underline underline-offset-2"
                  data-testid="link-m3-to-m4"
                >
                  M4
                </Link>
                <Link
                  href="/certificates/M5"
                  className="text-primary underline underline-offset-2"
                  data-testid="link-m3-to-m5"
                >
                  M5
                </Link>
              </div>
            </Card>
          )}

          {cert.moduleId === "M1" && (
            <Card className="p-6 border-border bg-card" data-testid="card-m1-crossref">
              <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">
                Cross-reference
              </h3>
              <p className="font-serif text-sm leading-relaxed text-foreground/85">
                The classical set S₄ = {"{2, 3, 19, 191}"} anchors the
                exceptional-prime desert map.
              </p>
              <div className="mt-3 font-mono text-xs">
                <Link
                  href="/desert-map#S4"
                  className="text-primary underline underline-offset-2"
                  data-testid="link-m1-to-desert-map-s4"
                >
                  → Desert Map · S₄ classical regime
                </Link>
              </div>
            </Card>
          )}

          <Card className="p-0 border-border bg-card overflow-hidden flex flex-col">
            <div className="p-4 border-b border-border bg-muted/30 flex items-center justify-between">
              <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider flex items-center gap-2">
                <FileText className="w-4 h-4" /> Proof Document
              </h3>
            </div>
            <div className="bg-background min-h-[400px] lg:min-h-[600px] flex-1 relative">
              {pdfSrc ? (
                <iframe
                  src={pdfSrc}
                  className="absolute inset-0 w-full h-full border-0"
                  title={`Proof Document for ${cert.moduleId}`}
                />
              ) : (
                <div className="absolute inset-0 flex flex-col items-center justify-center text-muted-foreground font-mono text-sm">
                  <FileText className="w-12 h-12 mb-4 opacity-20" />
                  <div>NO PROOF DOCUMENT ATTACHED</div>
                  <div className="mt-4"><PdfUploader moduleId={cert.moduleId} /></div>
                </div>
              )}
            </div>
          </Card>
        </div>

        <div className="space-y-6">
          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">Cryptographic Fingerprints</h3>
            <div className="space-y-4">
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Source Output (STDOUT)</div>
                <div className="bg-muted p-2 border border-border">
                  <ShaChip sha={cert.stdoutSha} truncate={false} />
                </div>
              </div>
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Source File</div>
                {cert.sourceFile ? (
                  <div className="font-mono text-xs text-foreground bg-muted p-2 border border-border">
                    {cert.sourceFile}
                  </div>
                ) : (
                  <div className="font-mono text-xs text-muted-foreground">N/A</div>
                )}
              </div>
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Source Digest</div>
                <div className="bg-muted p-2 border border-border">
                  <ShaChip sha={cert.sourceSha} truncate={false} />
                </div>
              </div>
            </div>
          </Card>

          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">DAG Lineage</h3>
            <div className="space-y-3">
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">DAG Position</div>
                <div className="font-mono text-sm">{cert.dagPosition} / {summary?.totalModules ?? "—"}</div>
              </div>
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-2 uppercase">Parent Bindings</div>
                {cert.parentShas.length > 0 ? (
                  <ul className="space-y-2">
                    {cert.parentShas.map((sha, idx) => (
                      <li key={idx} className="bg-muted p-2 border border-border">
                        <ShaChip sha={sha} truncate={true} />
                      </li>
                    ))}
                  </ul>
                ) : (
                  <div className="font-mono text-xs text-muted-foreground">ROOT NODE - NO PARENTS</div>
                )}
              </div>
            </div>
          </Card>

          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">Metadata</h3>
            <div className="space-y-4">
              {cert.leanBinding && (
                <div>
                  <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase flex items-center gap-1">
                    <Code2 className="w-3 h-3" /> Lean 4 Binding
                  </div>
                  <div className="font-mono text-xs text-primary bg-primary/10 p-2 border border-primary/20">
                    {cert.leanBinding}
                  </div>
                  <div className="mt-2">
                    <LeanAxiomChip leanBinding={cert.leanBinding} size="md" />
                  </div>
                </div>
              )}
              {cert.notes && (
                <div>
                  <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Committee Notes</div>
                  <p className="text-sm text-foreground/80 leading-snug">
                    {cert.notes}
                  </p>
                </div>
              )}
              {cert.updatedAt && (
                <div>
                  <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase flex items-center gap-1">
                    <Clock className="w-3 h-3" /> Last Updated
                  </div>
                  <div className="font-mono text-xs">
                    {format(new Date(cert.updatedAt), "yyyy-MM-dd HH:mm:ss 'UTC'")}
                  </div>
                </div>
              )}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
