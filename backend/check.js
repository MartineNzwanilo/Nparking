require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function check() {
  const session = await prisma.parkingSession.findFirst({ orderBy: { checkIn: 'desc' } });
  console.log('LATEST SESSION:', session);
  await prisma.$disconnect();
}
check();
