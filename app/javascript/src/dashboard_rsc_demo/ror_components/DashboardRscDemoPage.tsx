import * as React from "react";

import DashboardComparisonPage, { type DashboardComparisonPageProps } from "../DashboardComparisonPage";

export default function DashboardRscDemoPage(props: DashboardComparisonPageProps) {
  return <DashboardComparisonPage {...props} variant="rsc" />;
}
