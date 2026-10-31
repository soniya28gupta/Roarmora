import { NextResponse, type NextRequest } from "next/server";

const publicPaths = new Set(["/", "/login", "/register"]);

export function middleware(request: NextRequest) {
  const pathname = request.nextUrl.pathname;
  if (publicPaths.has(pathname) || request.cookies.has("roamora_session")) {
    return NextResponse.next();
  }

  const loginUrl = new URL("/login", request.url);
  loginUrl.searchParams.set("next", pathname);
  return NextResponse.redirect(loginUrl);
}

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico|icon.svg).*)"],
};
