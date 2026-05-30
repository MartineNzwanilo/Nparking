import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const adminExists = await prisma.user.findFirst({
    where: { role: 'ADMIN' },
  });

  if (!adminExists) {
    const hashedPassword = await bcrypt.hash('password123', 10);
    await prisma.user.create({
      data: {
        name: 'System Admin',
        phone: '0000000000',
        email: 'admin@parking.co',
        password: hashedPassword,
        role: 'ADMIN',
      },
    });
    console.log('Admin user seeded: admin@parking.co / password123');
  } else {
    console.log('Admin user already exists');
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
