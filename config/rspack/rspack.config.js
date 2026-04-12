const getEnvironment = () => {
  if (process.env.NODE_ENV) return process.env.NODE_ENV;
  if (process.env.RAILS_ENV === "test") return "test";
  if (process.env.RAILS_ENV === "production" || process.env.RAILS_ENV === "staging") return "production";
  return process.env.RAILS_ENV || "development";
};

export default async () => {
  const environment = getEnvironment();
  return (await import(`./${environment}.js`)).default;
};
