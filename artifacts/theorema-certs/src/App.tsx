import { Switch, Route, Router as WouterRouter } from "wouter";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import NotFound from "@/pages/not-found";
import DashboardPage from "@/pages/dashboard";
import CertificatesPage from "@/pages/certificates";
import CertificateDetailPage from "@/pages/certificates/[moduleId]";
import MiegakurePage from "@/pages/miegakure";
import WalkthroughPage from "@/pages/walkthrough";
import FoundationsPage from "@/pages/foundations";
import { Layout } from "@/components/layout";

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: false,
      refetchOnWindowFocus: false,
    },
  },
});

function Router() {
  return (
    <Layout>
      <Switch>
        <Route path="/" component={DashboardPage} />
        <Route path="/certificates" component={CertificatesPage} />
        <Route path="/certificates/:moduleId" component={CertificateDetailPage} />
        <Route path="/miegakure" component={MiegakurePage} />
        <Route path="/walkthrough" component={WalkthroughPage} />
        <Route path="/foundations" component={FoundationsPage} />
        <Route component={NotFound} />
      </Switch>
    </Layout>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <TooltipProvider>
        <WouterRouter base={import.meta.env.BASE_URL.replace(/\/$/, "")}>
          <Router />
        </WouterRouter>
        <Toaster />
      </TooltipProvider>
    </QueryClientProvider>
  );
}

export default App;
