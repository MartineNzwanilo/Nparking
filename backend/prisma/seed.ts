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

  // Ensure Support Admin exists or is updated
  const supportPhone = '0745633638';
  const supportAdmin = await prisma.user.findUnique({
    where: { phone: supportPhone },
  });

  const hashedSupportPassword = await bcrypt.hash('123qwe', 10);
  
  if (supportAdmin) {
    await prisma.user.update({
      where: { id: supportAdmin.id },
      data: { password: hashedSupportPassword, role: 'ADMIN', name: 'Support Admin', siteId: null },
    });
    console.log('Support Admin updated to ADMIN role and global site!');
  } else {
    await prisma.user.create({
      data: {
        phone: supportPhone,
        name: 'Support Admin',
        password: hashedSupportPassword,
        role: 'ADMIN',
        isActive: true,
      },
    });
    console.log('Support Admin created!');
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
