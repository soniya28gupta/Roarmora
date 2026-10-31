import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

try {
  const tables = await prisma.$queryRaw`
    SELECT tablename
    FROM pg_tables
    WHERE schemaname = 'public'
    ORDER BY tablename
  `;

  const constraints = await prisma.$queryRaw`
    SELECT table_name, constraint_name
    FROM information_schema.table_constraints
    WHERE table_schema = 'public'
      AND constraint_name = 'reports_target_user_id_fkey'
  `;

  console.log("DATABASE TABLES:");
  console.log(tables);

  console.log("REPORTS FOREIGN KEY:");
  console.log(constraints);
} catch (error) {
  console.error(error);
} finally {
  await prisma.$disconnect();
}