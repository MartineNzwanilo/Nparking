const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function update() {
  await prisma.parkingSession.updateMany({ data: { isPreCheckIn: true } });
  console.log('Updated all sessions to isPreCheckIn: true');
  await prisma.$disconnect();
}
update();
