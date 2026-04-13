import getEnvironment from "./environment.js";

export default async () => {
  const environment = getEnvironment();
  return (await import(`./${environment}.js`)).default;
};
