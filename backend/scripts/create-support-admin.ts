import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  const phone = '0745633638';
  const name = 'Support Admin';
  const rawPassword = '123qwe';

  console.log(`Checking if user with phone ${phone} exists...`);
  
  const existingUser = await prisma.user.findUnique({
    where: { phone },
  });

  if (existingUser) {
    console.log(`User with phone ${phone} already exists! Updating their password and role to ADMIN...`);
    const hashedPassword = await bcrypt.hash(rawPassword, 10);
    
    await prisma.user.update({
      where: { id: existingUser.id },
      data: {
        password: hashedPassword,
        role: 'ADMIN',
        name: name,
        siteId: null, // Ensure global access
      },
    });
    console.log('✅ Support Admin user updated successfully.');
  } else {
    console.log('Creating new Support Admin user...');
    const hashedPassword = await bcrypt.hash(rawPassword, 10);
    
    await prisma.user.create({
      data: {
        name,
        phone,
        password: hashedPassword,
        role: 'ADMIN',
        isActive: true,
      },
    });
    console.log('✅ Support Admin user created successfully.');
  }
}

main()
  .catch((e) => {
    console.error('❌ Error creating user:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
