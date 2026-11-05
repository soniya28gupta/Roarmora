import { createHash, randomBytes, randomInt } from "node:crypto";
import type { NextFunction, Request, Response } from "express";
import { Router } from "express";
import bcrypt from "bcryptjs";
import { prisma } from "./db.js";
import { fixedWindowLimit, HttpError } from "./http.js";
import {
  googleAuthSchema,
  loginSchema,
  otpSendSchema,
  otpVerifySchema,
  registerSchema,
} from "./validation.js";

export const SESSION_COOKIE = "roamora_session";
export const OTP_EXPIRY_SECONDS = 60;
export const OTP_MAX_ATTEMPTS = 5;

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

export function generateSixDigitOtp(): string {
  return randomInt(100000, 1000000).toString();
}

export async function requireAuth(request: AuthenticatedRequest, _response: Response, next: NextFunction) {
  try {
    const authHeader = request.headers.authorization;
    const bearerToken = authHeader && authHeader.toLowerCase().startsWith("bearer ")
      ? authHeader.slice(7).trim()
      : undefined;
    const token = (request.cookies?.[SESSION_COOKIE] as string | undefined) || bearerToken;
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

async function createSession(userId: string, response: Response): Promise<string> {
  const token = randomBytes(32).toString("base64url");
  const expiresAt = new Date(Date.now() + sessionDays * 24 * 60 * 60 * 1000);
  await prisma.session.create({
    data: { userId, tokenHash: hashToken(token), expiresAt },
  });
  response.cookie(SESSION_COOKIE, token, { ...cookieOptions, expires: expiresAt });
  return token;
}

interface VerifiedGoogleProfile {
  sub: string;
  email: string;
  emailVerified: boolean;
  name?: string;
  picture?: string;
}

async function verifyGoogleToken(params: { idToken?: string; accessToken?: string }): Promise<VerifiedGoogleProfile> {
  if (params.idToken) {
    const res = await fetch(
      `https://oauth2.googleapis.com/tokeninfo?id_token=${encodeURIComponent(params.idToken)}`,
    );
    if (!res.ok) {
      throw new HttpError(401, "Invalid or expired Google ID token");
    }
    const payload = (await res.json()) as Record<string, unknown>;
    const allowedAudiences = [
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_ANDROID_CLIENT_ID,
      process.env.GOOGLE_WEB_CLIENT_ID,
    ].filter((v): v is string => Boolean(v && v.trim()));

    if (allowedAudiences.length > 0 && typeof payload.aud === "string" && !allowedAudiences.includes(payload.aud)) {
      throw new HttpError(401, "Google ID token audience mismatch");
    }

    const email = typeof payload.email === "string" ? payload.email.trim().toLowerCase() : "";
    const sub = typeof payload.sub === "string" ? payload.sub : "";
    const emailVerified = payload.email_verified === true || payload.email_verified === "true";

    if (!email || !sub || !emailVerified) {
      throw new HttpError(401, "Google account email is not verified");
    }

    return {
      sub,
      email,
      emailVerified,
      name: typeof payload.name === "string" ? payload.name : undefined,
      picture: typeof payload.picture === "string" ? payload.picture : undefined,
    };
  }

  if (params.accessToken) {
    const res = await fetch("https://www.googleapis.com/oauth2/v3/userinfo", {
      headers: { Authorization: `Bearer ${params.accessToken}` },
    });
    if (!res.ok) {
      throw new HttpError(401, "Invalid or expired Google access token");
    }
    const payload = (await res.json()) as Record<string, unknown>;
    const email = typeof payload.email === "string" ? payload.email.trim().toLowerCase() : "";
    const sub = typeof payload.sub === "string" ? payload.sub : "";
    const emailVerified = payload.email_verified === true || payload.email_verified === "true";

    if (!email || !sub || !emailVerified) {
      throw new HttpError(401, "Google account email is not verified");
    }

    return {
      sub,
      email,
      emailVerified,
      name: typeof payload.name === "string" ? payload.name : undefined,
      picture: typeof payload.picture === "string" ? payload.picture : undefined,
    };
  }

  throw new HttpError(400, "Google authentication token is required");
}

async function deliverOtpEmail(email: string, code: string): Promise<{ delivered: boolean; provider: string }> {
  const resendApiKey = process.env.RESEND_API_KEY;
  const fromAddress = process.env.EMAIL_FROM ?? "Pookie Match <no-reply@pookiematch.app>";

  if (resendApiKey) {
    const res = await fetch("https://api.resend.com/emails", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${resendApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        from: fromAddress,
        to: [email],
        subject: "Your Pookie Match 6-Digit Verification Code",
        html: `<div style="font-family:sans-serif;max-width:480px;margin:0 auto;padding:24px;border:1px solid #E9E0E2;border-radius:16px;">
          <h2 style="color:#292536;margin-top:0;">Verify your Pookie Match account</h2>
          <p style="color:#777182;font-size:15px;">Enter the 6-digit verification code below. For your security, this code expires in exactly <strong>60 seconds</strong>.</p>
          <div style="background:#FFF1F0;color:#DF5961;font-size:32px;font-weight:700;letter-spacing:8px;text-align:center;padding:16px;border-radius:12px;margin:20px 0;">${code}</div>
          <p style="color:#777182;font-size:12px;">If you did not request this code, you can safely ignore this email.</p>
        </div>`,
      }),
    });
    if (!res.ok) {
      throw new HttpError(502, "Failed to dispatch verification email via configured email provider");
    }
    return { delivered: true, provider: "resend" };
  }

  const sendgridApiKey = process.env.SENDGRID_API_KEY;
  if (sendgridApiKey) {
    const res = await fetch("https://api.sendgrid.com/v3/mail/send", {
      method: "POST",
      headers: {
        Authorization: `Bearer ${sendgridApiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        personalizations: [{ to: [{ email }] }],
        from: { email: fromAddress.replace(/.*<|>.*/g, "") },
        subject: "Your Pookie Match 6-Digit Verification Code",
        content: [
          {
            type: "text/plain",
            value: `Your Pookie Match verification code is ${code}. It expires in exactly 60 seconds.`,
          },
        ],
      }),
    });
    if (!res.ok) {
      throw new HttpError(502, "Failed to dispatch verification email via SendGrid");
    }
    return { delivered: true, provider: "sendgrid" };
  }

  return { delivered: false, provider: "unconfigured" };
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
            ...(input.gender ? { gender: input.gender } : {}),
            ...(input.lookingFor ? { lookingFor: input.lookingFor } : {}),
            ...(input.connectionGoal ? { connectionGoal: input.connectionGoal } : {}),
          },
        },
        preferences: { create: { interests: [] } },
      },
      select: { id: true },
    });
    const token = await createSession(user.id, response);
    response.status(201).json({
      id: user.id,
      email: input.email,
      token,
      isNewUser: true,
      isEmailVerified: false,
      onboardingCompleted: false,
    });
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
    const user = await prisma.user.findUnique({
      where: { email: input.email },
      select: { id: true, passwordHash: true },
    });
    if (!user || !(await bcrypt.compare(input.password, user.passwordHash))) {
      throw new HttpError(401, "Email or password is incorrect");
    }
    const token = await createSession(user.id, response);
    response.json({ id: user.id, email: input.email, token });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/google", async (request, response, next) => {
  try {
    const input = googleAuthSchema.parse(request.body);
    const googleUser = await verifyGoogleToken({
      idToken: input.idToken,
      accessToken: input.accessToken,
    });

    // Enforce One Email ID = One Profile
    const existingUser = await prisma.user.findFirst({
      where: {
        OR: [
          { email: googleUser.email },
          { googleId: googleUser.sub },
        ],
      },
      include: { profile: true },
    });

    let userId: string;
    let isNewUser = false;
    let onboardingCompleted = false;

    if (existingUser) {
      const updated = await prisma.user.update({
        where: { id: existingUser.id },
        data: {
          googleId: existingUser.googleId ?? googleUser.sub,
          isEmailVerified: true,
        },
        select: { id: true, onboardingCompleted: true },
      });
      userId = updated.id;
      onboardingCompleted = updated.onboardingCompleted || Boolean(
        existingUser.profile &&
        existingUser.profile.displayName &&
        existingUser.profile.interests.length > 0,
      );
    } else {
      isNewUser = true;
      const randomPasswordHash = await bcrypt.hash(randomBytes(32).toString("hex"), 12);
      const defaultBirthDate = input.birthDate
        ? new Date(`${input.birthDate}T00:00:00.000Z`)
        : new Date("2000-01-01T00:00:00.000Z");
      const displayName = (input.displayName || googleUser.name || googleUser.email.split("@")[0]).slice(0, 80);

      const created = await prisma.user.create({
        data: {
          email: googleUser.email,
          passwordHash: randomPasswordHash,
          googleId: googleUser.sub,
          isEmailVerified: true,
          onboardingCompleted: false,
          birthDate: defaultBirthDate,
          profile: {
            create: {
              displayName,
              bio: "",
              city: "Nearby",
              interests: [],
              ...(googleUser.picture ? { imageUrl: googleUser.picture, photos: [googleUser.picture] } : {}),
            },
          },
          preferences: { create: { interests: [] } },
        },
        select: { id: true, onboardingCompleted: true },
      });
      userId = created.id;
      onboardingCompleted = created.onboardingCompleted;
    }

    const token = await createSession(userId, response);
    response.status(isNewUser ? 201 : 200).json({
      id: userId,
      email: googleUser.email,
      token,
      isNewUser,
      isEmailVerified: true,
      onboardingCompleted,
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/otp/send", fixedWindowLimit(10, 10 * 60 * 1000), async (request, response, next) => {
  try {
    const { email } = otpSendSchema.parse(request.body);
    const now = new Date();

    // Check if an active OTP was generated less than 60 seconds ago and invalidate prior unused codes
    await prisma.otpCode.updateMany({
      where: { email, usedAt: null },
      data: { usedAt: now },
    });

    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });

    const rawCode = generateSixDigitOtp();
    const expiresAt = new Date(now.getTime() + OTP_EXPIRY_SECONDS * 1000);

    await prisma.otpCode.create({
      data: {
        userId: user?.id ?? null,
        email,
        codeHash: hashToken(rawCode),
        expiresAt,
      },
    });

    const delivery = await deliverOtpEmail(email, rawCode);

    response.status(200).json({
      sent: delivery.delivered,
      email,
      expiresInSeconds: OTP_EXPIRY_SECONDS,
      expiresAt: expiresAt.toISOString(),
      provider: delivery.provider,
      message: delivery.delivered
        ? "A 6-digit verification code has been sent to your email. It expires in 60 seconds."
        : "OTP generated with 60-second expiry. Configure RESEND_API_KEY or SENDGRID_API_KEY in backend environment to deliver emails.",
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/otp/verify", fixedWindowLimit(20, 10 * 60 * 1000), async (request, response, next) => {
  try {
    const { email, code } = otpVerifySchema.parse(request.body);
    const now = new Date();

    const latestOtp = await prisma.otpCode.findFirst({
      where: { email },
      orderBy: { createdAt: "desc" },
    });

    if (!latestOtp) {
      throw new HttpError(400, "No verification code found for this email. Please request a new OTP.");
    }

    if (latestOtp.usedAt !== null) {
      throw new HttpError(400, "This verification code has already been used or superseded. Please request a new OTP.");
    }

    if (latestOtp.expiresAt.getTime() <= now.getTime()) {
      throw new HttpError(400, "Verification code has expired (60-second limit). Please tap Resend OTP.");
    }

    if (latestOtp.attempts >= OTP_MAX_ATTEMPTS) {
      throw new HttpError(429, "Maximum verification attempts exceeded. Please request a new OTP.");
    }

    const candidateHash = hashToken(code);
    if (candidateHash !== latestOtp.codeHash) {
      await prisma.otpCode.update({
        where: { id: latestOtp.id },
        data: { attempts: { increment: 1 } },
      });
      throw new HttpError(400, "Invalid 6-digit verification code. Please check and try again.");
    }

    await prisma.otpCode.update({
      where: { id: latestOtp.id },
      data: { usedAt: now },
    });

    const user = await prisma.user.findUnique({
      where: { email },
      select: { id: true },
    });

    if (user) {
      await prisma.user.update({
        where: { id: user.id },
        data: { isEmailVerified: true },
      });
    }

    response.status(200).json({
      verified: true,
      email,
      verifiedAt: now.toISOString(),
    });
  } catch (error) {
    next(error);
  }
});

authRouter.post("/logout", requireAuth, async (request: AuthenticatedRequest, response, next) => {
  try {
    const token = (request.cookies?.[SESSION_COOKIE] as string | undefined) ||
      (request.headers.authorization?.startsWith("Bearer ") ? request.headers.authorization.slice(7).trim() : undefined);
    if (token) {
      await prisma.session.deleteMany({ where: { tokenHash: hashToken(token) } });
    }
    response.clearCookie(SESSION_COOKIE, cookieOptions);
    response.status(204).end();
  } catch (error) {
    next(error);
  }
});
