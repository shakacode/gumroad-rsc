import * as React from "react";

type Props = {
  children: React.ReactNode;
  currentView: "inertia" | "rsc";
  sellerDisplayName: string;
  subtitle: string;
};

const navLinks = [
  {
    href: () => Routes.dashboard_path(),
    label: "Current dashboard",
    view: null,
  },
  {
    href: () => Routes.dashboard_inertia_demo_path(),
    label: "Inertia demo",
    view: "inertia",
  },
  {
    href: () => Routes.dashboard_rsc_demo_path(),
    label: "RSC demo",
    view: "rsc",
  },
];

export default function DashboardRscDemoShell({ children, currentView, sellerDisplayName, subtitle }: Props) {
  return (
    <div className="dd">
      <aside className="dd-side">
        <div className="dd-brand">
          <a href={Routes.dashboard_rsc_demo_path()}>Gumroad</a>
          <p>{subtitle}</p>
        </div>

        <nav className="dd-nav" aria-label="Dashboard comparison routes">
          {navLinks.map((link) => (
            <a key={link.label} href={link.href()} aria-current={link.view === currentView ? "page" : undefined}>
              {link.label}
            </a>
          ))}
        </nav>

        <footer className="dd-meta">
          <strong>{sellerDisplayName}</strong>
          <p>Dashboard comparison surface</p>
        </footer>
      </aside>

      <main className="dd-main">{children}</main>
    </div>
  );
}
