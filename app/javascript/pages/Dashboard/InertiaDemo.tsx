import { usePage } from "@inertiajs/react";
import * as React from "react";

import DashboardComparisonPage, { type DashboardComparisonPageProps } from "$app/src/dashboard_rsc_demo/DashboardComparisonPage";

export default function DashboardInertiaDemo() {
  const props = usePage<DashboardComparisonPageProps>().props;

  return <DashboardComparisonPage {...props} variant="inertia" />;
}
