import { app } from "./app.js";
import { prisma } from "./db.js";

const port = Number.parseInt(process.env.PORT ?? "8081", 10);
const server = app.listen(port, "0.0.0.0", () => {
  console.log(`Roamora API listening at http://localhost:${port} (bound on all interfaces)`);
  console.log(`Database readiness: http://localhost:${port}/health`);
});

function shutdown() {
  server.close(() => {
    void prisma.$disconnect().finally(() => process.exit(0));
  });
}

process.on("SIGINT", shutdown);
process.on("SIGTERM", shutdown);
