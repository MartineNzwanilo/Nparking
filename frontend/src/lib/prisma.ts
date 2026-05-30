import { PrismaClient } from "@prisma/client";

const prismaClientSingleton = () => {
  return new PrismaClient();
};

declare global {
  var prisma: undefined | ReturnType<typeof prismaClientSingleton>;
}

const prisma = globalThis.prisma ?? prismaClientSingleton();

// Ensure types are explicitly exported for IDE synchronization
export type { PrismaClient };
export default prisma;

if (process.env.NODE_ENV !== "production") globalThis.prisma = prisma;
