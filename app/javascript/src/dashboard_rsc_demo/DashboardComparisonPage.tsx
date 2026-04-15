import * as React from "react";

import { formatPriceCentsWithCurrencySymbol } from "$app/utils/currency";

import DashboardRscDemoShell from "./ror_components/DashboardRscDemoShell";

type CreatorHomeBalanceProps = {
  balance: string;
  last_seven_days_sales_total: string;
  last_28_days_sales_total: string;
  total: string;
};

type CreatorHomeSaleProps = {
  id: string;
  name: string;
  sales: number;
  revenue: number;
  visits: number;
  today: number;
  last_7: number;
  last_30: number;
};

type CreatorHomeActivityItemProps = {
  type: "new_sale" | "follower_added" | "follower_removed";
  timestamp: string;
  details: {
    email?: string | null;
    name?: string | null;
    price_cents?: number;
    product_name?: string;
    product_unique_permalink?: string;
  };
};

export type CreatorHomeRscDemoProps = {
  activity_items?: CreatorHomeActivityItemProps[];
  balances: CreatorHomeBalanceProps;
  sales?: CreatorHomeSaleProps[];
  show_1099_download_notice?: boolean;
  stripe_verification_message?: string | null;
  tax_center_enabled?: boolean;
};

export type DashboardComparisonPageProps = {
  locale: string;
  seller_display_name: string;
  seller_time_zone?: string | null;
  creator_home: CreatorHomeRscDemoProps;
};

type DashboardComparisonVariant = "rsc" | "inertia";

type Props = DashboardComparisonPageProps & {
  variant: DashboardComparisonVariant;
};

const formatCurrency = (amountCents: number) =>
  formatPriceCentsWithCurrencySymbol("usd", amountCents, { symbolFormat: "short", noCentsIfWhole: true });

const formatCompactNumber = (value: number, locale: string) =>
  value.toLocaleString(locale, { notation: "compact", maximumFractionDigits: 1 });

const formatNumber = (value: number, locale: string) => value.toLocaleString(locale);

const formatTimestamp = (timestamp: string, locale: string, timeZone?: string | null) => {
  const date = new Date(timestamp);
  if (Number.isNaN(date.valueOf())) return timestamp;

  try {
    return new Intl.DateTimeFormat(locale, {
      dateStyle: "medium",
      timeStyle: "short",
      ...(timeZone ? { timeZone } : {}),
    }).format(date);
  } catch {
    return date.toLocaleString(locale);
  }
};

const SummaryCards = ({ balances }: { balances: CreatorHomeBalanceProps }) => {
  const cards = [
    { label: "Current balance", value: balances.balance },
    { label: "Last 7 days", value: balances.last_seven_days_sales_total },
    { label: "Last 28 days", value: balances.last_28_days_sales_total },
    { label: "All-time gross", value: balances.total },
  ];

  return (
    <section className="dd-metrics">
      {cards.map((card) => (
        <article key={card.label}>
          <p>{card.label}</p>
          <strong>{card.value}</strong>
        </article>
      ))}
    </section>
  );
};

const BestSellingSection = ({ locale, sales }: { locale: string; sales: CreatorHomeSaleProps[] }) => {
  if (!sales.length) {
    return (
      <div className="dd-empty">
        <p>No product metrics yet. This keeps the benchmark on rendering cost, not dashboard breadth.</p>
        <p>
          <a href={Routes.new_product_path()} className="dd-btn">
            Create a product
          </a>
        </p>
      </div>
    );
  }

  return (
    <div className="dd-table">
      <table>
        <thead>
          <tr>
            <th>Product</th>
            <th>Sales</th>
            <th>Revenue</th>
            <th>Visits</th>
            <th>Today</th>
            <th>Last 7 days</th>
            <th>Last 30 days</th>
          </tr>
        </thead>
        <tbody>
          {sales.map((sale) => (
            <tr key={sale.id}>
              <td>
                <a href={Routes.edit_link_path({ id: sale.id })}>{sale.name}</a>
              </td>
              <td title={formatNumber(sale.sales, locale)}>{formatCompactNumber(sale.sales, locale)}</td>
              <td>{formatCurrency(sale.revenue)}</td>
              <td title={formatNumber(sale.visits, locale)}>{formatCompactNumber(sale.visits, locale)}</td>
              <td>{formatCurrency(sale.today)}</td>
              <td>{formatCurrency(sale.last_7)}</td>
              <td>{formatCurrency(sale.last_30)}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

const ActivitySection = ({
  items,
  locale,
  timeZone,
}: {
  items: CreatorHomeActivityItemProps[];
  locale: string;
  timeZone?: string | null;
}) => {
  if (!items.length) {
    return (
      <div className="dd-empty">
        <p>Followers and sales will show up here as they come in.</p>
      </div>
    );
  }

  return (
    <div className="dd-list">
      {items.map((item, index) => {
        const details = item.details;

        return (
          <article key={`${item.type}-${item.timestamp}-${index}`} className="dd-row">
            <p className="dd-copy">
              {item.type === "new_sale" ? (
                <>
                  <strong>Sale:</strong>{" "}
                  <a href={Routes.edit_link_path({ id: details.product_unique_permalink || "" })}>
                    {details.product_name}
                  </a>{" "}
                  for {formatCurrency(details.price_cents || 0)}
                </>
              ) : (
                <>
                  <strong>{item.type === "follower_added" ? "Follower added:" : "Follower removed:"}</strong>{" "}
                  {details.name || details.email}
                </>
              )}
            </p>
            <time className="dd-stamp">{formatTimestamp(item.timestamp, locale, timeZone)}</time>
          </article>
        );
      })}
    </div>
  );
};

const variantCopy = {
  inertia: {
    title: "Creator home Inertia demo",
    subtitle: "Inertia comparison surface",
    lead: "Client-rendered control using the same seller data and reduced surface as the RSC demo.",
    alert: "Checklist and polling widgets are excluded so this stays a focused control route.",
    compareHref: () => Routes.dashboard_rsc_demo_path(),
    compareLabel: "Open RSC demo",
    bestSellingDescription: "Client-rendered product metrics on the trimmed surface.",
    activityDescription: "Recent followers and sales through the current Inertia stack.",
  },
  rsc: {
    title: "Creator home RSC demo",
    subtitle: "React on Rails Pro + RSC demo",
    lead: "Same seller data, trimmed to the read-heavy slice where server rendering can win.",
    alert: "Checklist and polling widgets are excluded so this stays a focused RSC route.",
    compareHref: () => Routes.dashboard_inertia_demo_path(),
    compareLabel: "Open Inertia demo",
    bestSellingDescription: "Server-rendered product metrics on the same trimmed surface.",
    activityDescription: "Recent followers and sales from the server component tree.",
  },
} satisfies Record<
  DashboardComparisonVariant,
  {
    title: string;
    subtitle: string;
    lead: string;
    alert: string;
    compareHref: () => string;
    compareLabel: string;
    bestSellingDescription: string;
    activityDescription: string;
  }
>;

export default function DashboardComparisonPage({
  locale,
  seller_display_name,
  seller_time_zone,
  creator_home,
  variant,
}: Props) {
  const previousYear = new Date().getFullYear() - 1;
  const copy = variantCopy[variant];
  const activityItems = creator_home.activity_items ?? [];
  const sales = creator_home.sales ?? [];

  return (
    <DashboardRscDemoShell currentView={variant} sellerDisplayName={seller_display_name} subtitle={copy.subtitle}>
      <header className="dd-header">
        <div>
          <h1>{copy.title}</h1>
          <p>{copy.lead}</p>
        </div>

        <div className="dd-actions">
          <a href={copy.compareHref()} className="dd-btn">
            {copy.compareLabel}
          </a>
          <a href={Routes.dashboard_path()} className="dd-btn">
            Open current dashboard
          </a>
        </div>
      </header>

      <div className="dd-body">
        <p className="dd-note">{copy.alert}</p>

        {creator_home.stripe_verification_message ? (
          <p className="dd-note is-warning">
            {creator_home.stripe_verification_message} <a href={Routes.settings_payments_path()}>Update</a>
          </p>
        ) : null}

        {creator_home.show_1099_download_notice ? (
          <p className="dd-note is-info">
            Your 1099 tax form for {previousYear} is ready.{" "}
            {creator_home.tax_center_enabled ? (
              <a href={Routes.tax_center_path({ year: previousYear })}>Download it here</a>
            ) : (
              <a href={Routes.dashboard_download_tax_form_path()}>Download it from the current dashboard</a>
            )}
            .
          </p>
        ) : null}

        <SummaryCards balances={creator_home.balances} />

        <section className="dd-section">
          <header>
            <h2>Best selling</h2>
            <p>{copy.bestSellingDescription}</p>
          </header>
          <BestSellingSection locale={locale} sales={sales} />
        </section>

        <section className="dd-section">
          <header>
            <h2>Recent activity</h2>
            <p>{copy.activityDescription}</p>
          </header>
          <ActivitySection items={activityItems} locale={locale} timeZone={seller_time_zone} />
        </section>
      </div>
    </DashboardRscDemoShell>
  );
}
