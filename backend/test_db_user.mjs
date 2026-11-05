import { PrismaClient } from "@prisma/client";
import "dotenv/config";

const prisma = new PrismaClient();

async function main() {
  try {
    const email = "soniyagupta0228@gmail.com";
    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true, email: true, createdAt: true, profile: { select: { displayName: true } } },
    });
    if (user) {
      console.log("USER FOUND IN DATABASE:", { id: user.id, email: user.email, displayName: user.profile?.displayName });
    } else {
      console.log("USER NOT FOUND WITH EXACT EMAIL:", email);
      // Let's check case-insensitive
      const allUsers = await prisma.user.findMany({
        take: 5,
        select: { id: true, email: true },
      });
      console.log("Sample user emails in DB:", allUsers.map(u => u.email));
    }
  } catch (err) {
    console.error("DB error:", err.message);
  } finally {
    await prisma.$disconnect();
  }
}

main();

