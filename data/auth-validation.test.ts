import { describe, expect, it } from "vitest";
import { getRegistrationFieldErrors, isAdultDateOfBirth, isValidAuthInput, isValidEmail } from "@/lib/auth-validation";

const emptyValues = {
  displayName: "",
  city: "",
  birthDate: "",
  email: "",
  password: "",
  passwordConfirmation: "",
};

describe("sign-in form validation", () => {
  it("rejects empty submissions and malformed email addresses", () => {
    expect(isValidAuthInput("login", emptyValues)).toBe(false);
    expect(isValidEmail("not-an-email")).toBe(false);
    expect(isValidAuthInput("login", { ...emptyValues, email: "not-an-email", password: "long-enough-password" })).toBe(false);
  });

  it("accepts valid login credentials and enforces the server password limits", () => {
    expect(isValidAuthInput("login", {
      ...emptyValues,
      email: "person@example.com",
      password: "valid-password",
    })).toBe(true);
    expect(isValidAuthInput("login", {
      ...emptyValues,
      email: "person@example.com",
      password: "short-pass",
    })).toBe(true);
    expect(isValidAuthInput("login", {
      ...emptyValues,
      email: "person@example.com",
      password: "",
    })).toBe(false);
    expect(isValidAuthInput("register", {
      ...emptyValues,
      displayName: "Roamora User",
      city: "Sample City",
      birthDate: "1990-05-10",
      email: "person@example.com",
      password: "short-pass",
      passwordConfirmation: "short-pass",
    })).toBe(false);
  });
});

describe("registration form validation", () => {
  it("requires a name, city, adult date of birth, and matching passwords", () => {
    const validRegistration = {
      displayName: "Roamora User",
      city: "Sample City",
      birthDate: "1990-05-10",
      email: "person@example.com",
      password: "valid-password",
      passwordConfirmation: "valid-password",
    };

    expect(isValidAuthInput("register", validRegistration)).toBe(true);
    expect(isValidAuthInput("register", { ...validRegistration, passwordConfirmation: "different-password" })).toBe(false);
    expect(isValidAuthInput("register", { ...validRegistration, birthDate: "" })).toBe(false);
    expect(isValidAuthInput("register", { ...validRegistration, displayName: " " })).toBe(false);
  });

  it("requires users to be at least 18 on the current UTC calendar date", () => {
    const today = new Date("2026-10-31T12:00:00.000Z");
    expect(isAdultDateOfBirth("2008-10-31", today)).toBe(true);
    expect(isAdultDateOfBirth("2008-11-01", today)).toBe(false);
    expect(isAdultDateOfBirth("2008-02-31", today)).toBe(false);
  });

  it("reports a useful validation error for each invalid registration field", () => {
    expect(getRegistrationFieldErrors(emptyValues)).toEqual({
      displayName: "Enter your name.",
      city: "Enter your city.",
      birthDate: "Enter your date of birth.",
      email: "Enter a valid email address.",
      password: "Use at least 12 characters.",
      passwordConfirmation: "Confirm your password.",
    });

    expect(getRegistrationFieldErrors({
      ...emptyValues,
      displayName: "Roamora User",
      city: "Sample City",
      birthDate: "2010-01-01",
      email: "person@example.com",
      password: "valid-password",
      passwordConfirmation: "different-password",
    })).toMatchObject({
      birthDate: "You must be at least 18 years old.",
      passwordConfirmation: "Your passwords don’t match.",
    });
  });
});
