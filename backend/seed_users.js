const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  let site = await prisma.parkingSite.findFirst();
  if (!site) {
    site = await prisma.parkingSite.create({
      data: { name: 'Main Parking Zone', location: 'HQ', capacity: 100 },
    });
  }

  // UPSERT ADMIN
  const admin = await prisma.user.upsert({
    where: { phone: '0999000000' },
    update: {
      password: 'admin',
      role: 'ADMIN'
    },
    create: {
      phone: '0999000000',
      password: 'admin',
      name: 'System Admin',
      role: 'ADMIN',
      siteId: site.id,
    },
  });

  // UPSERT WATCHMAN
  const watchman = await prisma.user.upsert({
    where: { phone: '0000000000' },
    update: {
      password: 'watch',
      role: 'WATCHMAN'
    },
    create: {
      phone: '0000000000',
      password: 'watch',
      name: 'Default Watchman',
      role: 'WATCHMAN',
      siteId: site.id,
    },
  });

  console.log('Successfully created/updated users:');
  console.log('ADMIN:', admin.phone, admin.password);
  console.log('WATCHMAN:', watchman.phone, watchman.password);
}

main()
  .catch(e => console.error(e))
  .finally(async () => {
    await prisma.$disconnect();
  });
