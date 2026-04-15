import { createInertiaApp } from "@inertiajs/react";
import React, { createElement } from "react";
import { createRoot } from "react-dom/client";

import AdminAppWrapper, { GlobalProps } from "../inertia/admin_app_wrapper";
import { PageComponent, resolvePageComponent } from "../inertia/resolve_page_component.ts";
import Layout from "../layouts/Admin";

const AdminLayout = (page: React.ReactNode) => React.createElement(Layout, { children: page });

void createInertiaApp<GlobalProps>({
  progress: false,
  resolve: (name: string) =>
    resolvePageComponent(name, {
      errorPrefix: "Admin page",
      onLoad: (component: PageComponent) => {
        component.layout = AdminLayout;
        return component;
      },
    }),
  setup({ el, App, props }) {
    const global = props.initialPage.props;

    const root = createRoot(el);
    root.render(createElement(AdminAppWrapper, { global, children: createElement(App, props) }));
  },
  title: (title: string) => (title ? `${title} - Admin` : "Admin"),
});
