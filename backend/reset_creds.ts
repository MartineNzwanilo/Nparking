import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function reset() {
  const hashedPassword = await bcrypt.hash('admin123', 10);
  
  // Update system admin
  await prisma.user.upsert({
    where: { phone: '0999000000' },
    update: {
      password: hashedPassword,
      role: 'ADMIN'
    },
    create: {
      phone: '0999000000',
      password: hashedPassword,
      name: 'System Admin',
      role: 'ADMIN'
    }
  });

  // Update default watchman
  const hashedWatch = await bcrypt.hash('watch123', 10);
  await prisma.user.upsert({
    where: { phone: '0000000000' },
    update: {
      password: hashedWatch,
      role: 'WATCHMAN'
    },
    create: {
      phone: '0000000000',
      password: hashedWatch,
      name: 'Default Watchman',
      role: 'WATCHMAN'
    }
  });

  console.log('RESET DONE:');
  console.log('ADMIN: phone 0999000000 / password admin123');
  console.log('WATCHMAN: phone 0000000000 / password watch123');
}

reset()
  .catch(e => console.error(e))
  .finally(() => prisma.$disconnect());
