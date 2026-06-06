import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
  // Find a watchman and site to link the parking sessions to
  const user = await prisma.user.findFirst();
  const site = await prisma.parkingSite.findFirst();
  const category = await prisma.vehicleCategory.findFirst();

  if (!user || !site || !category) {
    console.error('Please make sure you have at least one user, site, and vehicle category seeded.');
    return;
  }

  // Create a vehicle
  let vehicle = await prisma.vehicle.findUnique({
    where: { plateNumber: 'T123ABC' },
  });
  if (!vehicle) {
    vehicle = await prisma.vehicle.create({
      data: {
        plateNumber: 'T123ABC',
        categoryId: category.id,
      },
    });
  }

  // Define dates in local time matching 2026-06-06
  const today = new Date();
  today.setHours(10, 0, 0, 0); // today morning

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  yesterday.setHours(10, 0, 0, 0); // yesterday morning

  // 1. Create a session and payment for Yesterday
  const yesterdaySession = await prisma.parkingSession.create({
    data: {
      vehicleId: vehicle.id,
      siteId: site.id,
      watchmanId: user.id,
      amountDue: 10000,
      checkIn: yesterday,
      status: 'CHECKED_OUT',
      checkOut: yesterday,
    },
  });

  await prisma.payment.create({
    data: {
      sessionId: yesterdaySession.id,
      amount: 10000,
      method: 'CASH',
      collectedAt: yesterday,
    },
  });

  // 2. Create a session and payment for Today
  const todaySession = await prisma.parkingSession.create({
    data: {
      vehicleId: vehicle.id,
      siteId: site.id,
      watchmanId: user.id,
      amountDue: 15000,
      checkIn: today,
      status: 'CHECKED_OUT',
      checkOut: today,
    },
  });

  await prisma.payment.create({
    data: {
      sessionId: todaySession.id,
      amount: 15000,
      method: 'CASH',
      collectedAt: today,
    },
  });

  console.log('Seeded test payments successfully!');
  console.log('Yesterday Revenue:', 10000);
  console.log('Today Revenue:', 15000);
  console.log('Expected Change: +50.0%');
}

main()
  .catch((e) => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
