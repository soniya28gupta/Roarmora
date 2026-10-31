export type AuthFormValues = {
  displayName: string;
  city: string;
  birthDate: string;
  email: string;
  password: string;
  passwordConfirmation: string;
};

export type RegistrationField = "displayName" | "city" | "birthDate" | "email" | "password" | "passwordConfirmation";
export type RegistrationFieldErrors = Partial<Record<RegistrationField, string>>;

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email.trim());
}

export function isAdultDateOfBirth(value: string, today = new Date()): boolean {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(value);
  if (!match) return false;

  const [, yearText, monthText, dayText] = match;
  const year = Number(yearText);
  const month = Number(monthText);
  const day = Number(dayText);
  const birthDate = new Date(Date.UTC(year, month - 1, day));
  if (
    birthDate.getUTCFullYear() !== year ||
    birthDate.getUTCMonth() !== month - 1 ||
    birthDate.getUTCDate() !== day
  ) return false;

  const latestEligibleBirthDate = Date.UTC(
    today.getUTCFullYear() - 18,
    today.getUTCMonth(),
    today.getUTCDate(),
  );
  return birthDate.getTime() <= latestEligibleBirthDate;
}

export function getRegistrationFieldErrors(values: AuthFormValues): RegistrationFieldErrors {
  const errors: RegistrationFieldErrors = {};
  const displayName = values.displayName.trim();
  const city = values.city.trim();

  if (!displayName) errors.displayName = "Enter your name.";
  else if (displayName.length > 80) errors.displayName = "Your name must be 80 characters or fewer.";

  if (!city) errors.city = "Enter your city.";
  else if (city.length > 120) errors.city = "Your city must be 120 characters or fewer.";

  if (!values.birthDate) errors.birthDate = "Enter your date of birth.";
  else if (!isAdultDateOfBirth(values.birthDate)) errors.birthDate = "You must be at least 18 years old.";

  if (!isValidEmail(values.email)) errors.email = "Enter a valid email address.";
  else if (values.email.trim().length > 320) errors.email = "Your email must be 320 characters or fewer.";

  if (values.password.length < 12) errors.password = "Use at least 12 characters.";
  else if (values.password.length > 128) errors.password = "Your password must be 128 characters or fewer.";

  if (!values.passwordConfirmation) errors.passwordConfirmation = "Confirm your password.";
  else if (values.password !== values.passwordConfirmation) errors.passwordConfirmation = "Your passwords don’t match.";

  return errors;
}

export function isValidAuthInput(mode: "login" | "register", values: AuthFormValues): boolean {
  if (!isValidEmail(values.email) || values.password.length === 0 || values.password.length > 128) {
    return false;
  }
  if (mode === "login") return true;

  return Object.keys(getRegistrationFieldErrors(values)).length === 0;
}
