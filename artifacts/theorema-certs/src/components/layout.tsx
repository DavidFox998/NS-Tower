import { Link, useLocation } from "wouter";
import { Database, FileText, Activity, Box, ScrollText } from "lucide-react";
import { useHealthCheck } from "@workspace/api-client-react";

export function Layout({ children }: { children: React.ReactNode }) {
  const [location] = useLocation();
  const { data: health } = useHealthCheck();

  return (
    <div className="min-h-[100dvh] flex flex-col md:flex-row bg-background">
      {/* Sidebar */}
      <aside className="w-full md:w-64 border-r border-border bg-sidebar flex-shrink-0 flex flex-col">
        <div className="p-6 border-b border-border">
          <div className="font-mono text-[10px] text-muted-foreground uppercase tracking-[0.18em] mb-1">
            Entangled Technologies
          </div>
          <div className="font-mono text-[10px] text-muted-foreground uppercase tracking-wider mb-3">
            presents
          </div>
          <h1 className="font-sans font-bold text-lg tracking-tight leading-tight">
            The Morning Star Project
          </h1>
          <div className="font-mono text-[10px] text-muted-foreground mt-1.5">
            vol. i · Theorema Aureum 143
          </div>
          <div className="flex items-center gap-2 mt-4 text-xs font-mono">
            <div className={`w-2 h-2 ${health?.status === 'ok' ? 'bg-green-500' : 'bg-red-500'}`} />
            <span className="text-muted-foreground">SYS_STATUS: {health?.status || 'UNKNOWN'}</span>
          </div>
        </div>

        <nav className="flex-1 p-4 space-y-1">
          <Link href="/" className={`flex items-center gap-3 px-3 py-2 text-sm font-mono transition-colors ${location === "/" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted hover:text-foreground"}`} data-testid="link-dashboard">
            <Activity className="w-4 h-4" />
            <span>Dashboard</span>
          </Link>
          <Link href="/certificates" className={`flex items-center gap-3 px-3 py-2 text-sm font-mono transition-colors ${location.startsWith("/certificates") ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted hover:text-foreground"}`} data-testid="link-certificates">
            <FileText className="w-4 h-4" />
            <span>Certificates</span>
          </Link>
          <Link href="/miegakure" className={`flex items-center gap-3 px-3 py-2 text-sm font-mono transition-colors ${location === "/miegakure" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted hover:text-foreground"}`} data-testid="link-miegakure">
            <Box className="w-4 h-4" />
            <span>Miegakure</span>
          </Link>
          <Link href="/walkthrough" className={`flex items-center gap-3 px-3 py-2 text-sm font-mono transition-colors ${location === "/walkthrough" ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-muted hover:text-foreground"}`} data-testid="link-walkthrough">
            <ScrollText className="w-4 h-4" />
            <span>Walkthrough</span>
          </Link>
        </nav>

        <div className="p-4 border-t border-border">
          <div className="text-[10px] font-mono text-muted-foreground text-center leading-relaxed">
            W(H₄) · h=30 · |Φ|=120<br/>C₀=320 · {`{1,11,19,29}`}
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0">
        <div className="flex-1 p-6 md:p-10 overflow-auto">
          <div className="max-w-6xl mx-auto">
            {children}
          </div>
        </div>
      </main>
    </div>
  );
}
