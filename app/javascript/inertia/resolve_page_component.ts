import type { ComponentType, ReactElement, ReactNode } from "react";

export type PageComponent = ComponentType & {
  layout?: (page: ReactNode) => ReactElement;
};

type ResolvePageComponentOptions = {
  errorPrefix?: string;
  onLoad?: (component: PageComponent) => PageComponent;
};

const tsxPages = require.context("../pages", true, /\.tsx$/, "lazy");
const jsxPages = require.context("../pages", true, /\.jsx$/, "lazy");

const loadPageComponent = async (
  context: __WebpackModuleApi.RequireContext,
  request: string,
): Promise<PageComponent | null> => {
  if (!context.keys().includes(request)) return null;

  const page: unknown = await context(request);
  if (page && typeof page === "object" && "default" in page && typeof page.default === "function") {
    return page.default as PageComponent;
  }

  throw new Error(`Invalid page component: ${request}`);
};

export async function resolvePageComponent(
  name: string,
  { errorPrefix = "Page", onLoad }: ResolvePageComponentOptions = {},
): Promise<PageComponent> {
  const component =
    (await loadPageComponent(tsxPages, `./${name}.tsx`)) ??
    (await loadPageComponent(jsxPages, `./${name}.jsx`));

  if (!component) {
    throw new Error(`${errorPrefix} component not found: ${name}`);
  }

  return onLoad ? onLoad(component) : component;
}
