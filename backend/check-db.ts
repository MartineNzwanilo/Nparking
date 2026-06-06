import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  const today = new Date();
  today.setHours(0, 0, 0, 0);

  const yesterdayStart = new Date();
  yesterdayStart.setDate(yesterdayStart.getDate() - 1);
  yesterdayStart.setHours(0, 0, 0, 0);

  const yesterdayEnd = new Date();
  yesterdayEnd.setHours(0, 0, 0, 0);

  const allPayments = await prisma.payment.findMany();
  console.log('All payments:', allPayments);

  const todaysPayments = await prisma.payment.findMany({
    where: {
      collectedAt: {
        gte: today,
      },
    },
  });
  console.log("Today's payments:", todaysPayments);

  const yesterdaysPayments = await prisma.payment.findMany({
    where: {
      collectedAt: {
        gte: yesterdayStart,
        lt: yesterdayEnd,
      },
    },
  });
  console.log("Yesterday's payments:", yesterdaysPayments);

  // Check sessions
  const sessions = await prisma.parkingSession.findMany();
  console.log('All sessions:', sessions);
}

main()
  .catch((e) => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
