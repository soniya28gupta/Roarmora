import { createHash, randomBytes } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import { Router } from "express";
import bcrypt from "bcryptjs";
import { prisma } from "./db.js";
import { HttpError } from "./http.js";
import { loginSchema, registerSchema } from "./validation.js";

export const SESSION_COOKIE = "roamora_session";
const sessionDays = Number.parseInt(process.env.SESSION_DAYS ?? "14", 10);
const cookieOptions = {
  httpOnly: true,
  secure: process.env.COOKIE_SECURE === "true" || process.env.NODE_ENV === "production",
  sameSite: "lax" as const,
  path: "/",
};

export interface AuthenticatedRequest extends Request {
  userId?: string;
}

export function hashToken(token: string): string {
  return createHash("sha256").update(token).digest("hex");
}

export async function requireAuth(request: AuthenticatedRequest, _response: Response, next: NextFunction) {
  try {
    const token = request.cookies?.[SESSION_COOKIE] as string | undefined;
    if (!token) throw new HttpError(401, "Authentication required");
    const session = await prisma.session.findUnique({
      where: { tokenHash: hashToken(token) },
      select: { userId: true, expiresAt: true },
    });
    if (!session || session.expiresAt <= new Date()) {
      throw new HttpError(401, "Session expired");
    }
    request.userId = session.userId;
    next();
  } catch (error) {
    next(error);
  }
}

async function createSession(userId: string, response: Response): Promise<void> {
  const token = randomBytes(32).toString("base64url");
  const expiresAt = new Date(Date.now() + sessionDays * 24 * 60 * 60 * 1000);
  await prisma.session.create({
    data: { userId, tokenHash: hashToken(token), expiresAt },
  });
  response.cookie(SESSION_COOKIE, token, { ...cookieOptions, expires: expiresAt });
}

export const authRouter = Router();

authRouter.post("/register", async (request, response, next) => {
  try {
    const input = registerSchema.parse(request.body);
    const passwordHash = await bcrypt.hash(input.password, 12);
    const user = await prisma.user.create({
      data: {
        email: input.email,
        passwordHash,
        birthDate: new Date(`${input.birthDate}T00:00:00.000Z`),
        profile: {
          create: {
            displayName: input.displayName,
            bio: input.bio,
            city: input.city,
            interests: input.interests,
          },
        },
        preferences: { create: { interests: [] } },
      },
      select: { id: true },
    });
    await createSession(user.id, response);
    response.status(201).json({ id: user.id });
  } catch (error) {
    if (typeof error === "object" && error !== null && "code" in error && error.code === "P2002") {
      next(new HttpError(409, "An account with this email already exists"));
      return;
    }
    next(error);
  }
});

authRouter.post("/login", async (request, response, next) => {
  try {
    const input = loginSchema.parse(request.body);
    const user = await prisma.user.findUnique({ where: { email: input.email }, select: { id: true, passwordHash: true } });
    if (!user || !(await bcrypt.compare(input.password, user.passwordHash))) {
      throw new HttpError(401, "Email or password is incorrect");
    }
    await createSession(user.id, response);
    response.json({ id: user.id });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/logout", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const token = request.cookies?.[SESSION_COOKIE] as string;
    await prisma.session.deleteMany({ where: { tokenHash: hashToken(token) } });
    response.clearCookie(SESSION_COOKIE, cookieOptions);
    response.status(204).end();
  } catch (error) {
    next(error);
  }
});
