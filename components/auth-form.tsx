"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { useRef, useState, type FormEvent } from "react";
import {
  ArrowLeft,
  ArrowRight,
  Eye,
  EyeOff,
  Heart,
  LoaderCircle,
  Sparkles,
} from "lucide-react";
import {
  getRegistrationFieldErrors,
  isValidAuthInput,
  isValidEmail,
  type RegistrationField,
  type RegistrationFieldErrors,
} from "@/lib/auth-validation";
import { signIn } from "@/app/login/actions";

type ApiValidationIssue = {
  path?: Array<string | number>;
  message?: string;
};

type AuthResponse = {
  error?: string;
  details?: ApiValidationIssue[];
};

function registrationFieldForApiPath(path: string | number | undefined): RegistrationField | undefined {
  switch (path) {
    case "displayName":
    case "city":
    case "birthDate":
    case "email":
    case "password":
      return path;
    default:
      return undefined;
  }
}

function registrationApiFieldMessage(field: RegistrationField, issue?: ApiValidationIssue): string {
  if (field === "birthDate") return "You must be at least 18 years old to join Pookie Match.";
  if (field === "email" && issue?.message?.toLowerCase().includes("email")) return "Enter a valid email address.";
  if (field === "password") return "Use a password between 12 and 128 characters.";
  if (field === "displayName") return "Enter a name of 80 characters or fewer.";
  if (field === "city") return "Enter a city of 120 characters or fewer.";
  return issue?.message ?? "Please check this field.";
}

function safeNextPath(search: string): string {
  const requestedPath = new URLSearchParams(search).get("next");
  return requestedPath?.startsWith("/") && !requestedPath.startsWith("//") && !requestedPath.includes("\\")
    ? requestedPath
    : "/discover";
}

export function AuthForm({ mode }: { mode: "login" | "register" }) {
  const isRegister = mode === "register";
  const router = useRouter();
  const submitting = useRef(false);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [showConfirmation, setShowConfirmation] = useState(false);
  const [message, setMessage] = useState("");
  const [isError, setIsError] = useState(false);
  const [registrationAttempted, setRegistrationAttempted] = useState(false);
  const [serverFieldErrors, setServerFieldErrors] = useState<RegistrationFieldErrors>({});
  const [displayName, setDisplayName] = useState("");
  const [city, setCity] = useState("");
  const [birthDate, setBirthDate] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [passwordConfirmation, setPasswordConfirmation] = useState("");

  const formIsValid = isValidAuthInput(isRegister ? "register" : "login", {
    displayName,
    city,
    birthDate,
    email,
    password,
    passwordConfirmation,
  });
  const registrationValues = {
    displayName,
    city,
    birthDate,
    email,
    password,
    passwordConfirmation,
  };
  const registrationErrors = getRegistrationFieldErrors(registrationValues);
  const fieldError = (field: RegistrationField) =>
    serverFieldErrors[field] ?? (registrationAttempted ? registrationErrors[field] : undefined);
  const clearServerFieldError = (field: RegistrationField) =>
    setServerFieldErrors((current) => ({ ...current, [field]: undefined }));

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (submitting.current) return;

    if (isRegister) {
      setRegistrationAttempted(true);
      setServerFieldErrors({});
    }
    if (!formIsValid) return;

    submitting.current = true;
    setIsSubmitting(true);
    setMessage("");
    setIsError(false);
    const requestController = new AbortController();
    const requestTimeout = window.setTimeout(() => requestController.abort(), 12_000);

    try {
      if (!isRegister) {
        const result = await signIn(email.trim(), password);
        if (!result.ok) throw new Error(result.message);
        router.replace(safeNextPath(window.location.search));
        router.refresh();
        return;
      }

      const response = await fetch(`/api/v1/auth/register`, {
        method: "POST",
        headers: { "content-type": "application/json" },
        credentials: "same-origin",
        signal: requestController.signal,
        body: JSON.stringify({
          displayName: displayName.trim(),
          city: city.trim(),
          birthDate,
          email: email.trim(),
          password,
        }),
      });

      const result = await response.json().catch((): AuthResponse => ({}));
      if (!response.ok) {
        if (isRegister && response.status === 409) {
          setServerFieldErrors({ email: "An account with this email already exists. Try signing in instead." });
        } else if (isRegister && response.status === 400 && result.details?.length) {
          const errors: RegistrationFieldErrors = {};
          for (const issue of result.details) {
            const field = registrationFieldForApiPath(issue.path?.[0]);
            if (field && !errors[field]) errors[field] = registrationApiFieldMessage(field, issue);
          }
          setServerFieldErrors(errors);
        }
        const errorMessage = response.status === 401
          ? "That email and password don’t match. Please try again."
          : response.status === 409
            ? "An account with this email already exists. Try signing in instead."
            : response.status === 400
              ? isRegister && result.details?.length
                ? "Please correct the highlighted fields."
                : "Please check your details and try again."
              : response.status === 502 || response.status === 503
                ? result.error ?? "Pookie Match authentication service is unavailable. Please check backend connection."
                : response.status >= 500
                  ? result.error ?? "Pookie Match couldn’t complete the request. Please try again later."
              : result.error ?? "We couldn’t complete your request. Please try again.";
        throw new Error(errorMessage);
      }

      setMessage("Your Pookie Match account is ready! Welcome aboard… ✨");
      await new Promise((resolve) => window.setTimeout(resolve, 700));
      router.replace("/discover");
      router.refresh();
    } catch (error) {
      setIsError(true);
      setMessage(error instanceof DOMException && error.name === "AbortError"
        ? `The ${isRegister ? "registration" : "sign-in"} request took too long. Check that the API is running, then try again.`
        : error instanceof TypeError
          ? "We couldn’t connect to Pookie Match API. Check that the API server is running, then try again."
          : error instanceof Error
            ? error.message
            : "Something went wrong. Please try again.");
    } finally {
      window.clearTimeout(requestTimeout);
      submitting.current = false;
      setIsSubmitting(false);
    }
  }

  return (
    <div className="auth-page">
      <div className="auth-visual">
        <div className="auth-visual-top">
          <Link href="/" className="brand brand-light">
            <span className="brand-mark"><Sparkles size={18} /></span>
            <span>Pookie Match<span className="brand-period">.</span></span>
          </Link>
          <span className="auth-illustrative">Gamified Dating Platform</span>
        </div>
        <div className="auth-visual-copy">
          <span className="auth-quote-mark">“</span>
          <h2>Where real sparks meet real-world city adventure.</h2>
          <p>Explore your city radar, collect virtual items, and find your pookie through genuine shared chemistry.</p>
        </div>
        <div className="auth-photo-card">
          <div className="auth-photo" role="img" aria-label="Friends sharing laughter outdoors" />
          <div>
            <span className="auth-photo-label">AI Compatibility & Radar Discovery</span>
            <strong>Find your kind of someone.</strong>
          </div>
        </div>
        <span className="auth-visual-flower">💖</span>
      </div>

      <div className="auth-panel">
        <Link className="auth-back" href="/">
          <ArrowLeft size={16} /> Back to Pookie Match
        </Link>
        <div className="auth-form-wrap">
          <div className="auth-symbol"><Heart size={24} fill="currentColor" className="text-coral" /></div>
          <span className="eyebrow">{isRegister ? "YOUR POOKIE JOURNEY BEGINS" : "WELCOME BACK"}</span>
          <h1>{isRegister ? "Find your spark." : "Good to see you."}</h1>
          <p className="auth-subtitle">
            {isRegister
              ? "Create your free account to swipe, explore the adventure map, and connect."
              : "Sign in to pick up where your romantic city adventures left off."}
          </p>

          <form aria-busy={isSubmitting} className="auth-form" noValidate onSubmit={handleSubmit}>
            {isRegister && (
              <>
                <label htmlFor="display-name">
                  Display name
                  <input
                    aria-describedby={fieldError("displayName") ? "display-name-error" : undefined}
                    aria-invalid={Boolean(fieldError("displayName"))}
                    autoComplete="name"
                    id="display-name"
                    maxLength={80}
                    name="displayName"
                    onChange={(event) => {
                      setDisplayName(event.target.value);
                      clearServerFieldError("displayName");
                    }}
                    placeholder="Your name or nickname"
                    required
                    value={displayName}
                  />
                  {fieldError("displayName") && (
                    <span className="auth-field-hint" id="display-name-error">
                      {fieldError("displayName")}
                    </span>
                  )}
                </label>
                <label htmlFor="city">
                  City
                  <input
                    aria-describedby={fieldError("city") ? "city-error" : undefined}
                    aria-invalid={Boolean(fieldError("city"))}
                    autoComplete="address-level2"
                    id="city"
                    maxLength={120}
                    name="city"
                    onChange={(event) => {
                      setCity(event.target.value);
                      clearServerFieldError("city");
                    }}
                    placeholder="e.g. New Delhi"
                    required
                    value={city}
                  />
                  {fieldError("city") && (
                    <span className="auth-field-hint" id="city-error">
                      {fieldError("city")}
                    </span>
                  )}
                </label>
                <label htmlFor="birth-date">
                  Date of birth (18+ only)
                  <input
                    aria-describedby={fieldError("birthDate") ? "birth-date-error" : undefined}
                    aria-invalid={Boolean(fieldError("birthDate"))}
                    autoComplete="bday"
                    id="birth-date"
                    max={new Date().toISOString().slice(0, 10)}
                    name="birthDate"
                    onChange={(event) => {
                      setBirthDate(event.target.value);
                      clearServerFieldError("birthDate");
                    }}
                    required
                    type="date"
                    value={birthDate}
                  />
                  {fieldError("birthDate") && (
                    <span className="auth-field-hint" id="birth-date-error">
                      {fieldError("birthDate")}
                    </span>
                  )}
                </label>
              </>
            )}

            <label htmlFor="email">
              Email address
              <input
                aria-describedby={fieldError("email") ? "email-error" : undefined}
                aria-invalid={Boolean(fieldError("email")) || (email.length > 0 && !isValidEmail(email))}
                autoComplete="email"
                id="email"
                maxLength={320}
                name="email"
                onChange={(event) => {
                  setEmail(event.target.value);
                  clearServerFieldError("email");
                }}
                placeholder="you@example.com"
                required
                type="email"
                value={email}
              />
              {fieldError("email") && (
                <span className="auth-field-hint" id="email-error">
                  {fieldError("email")}
                </span>
              )}
              {!fieldError("email") && email.length > 0 && !isValidEmail(email) && (
                <span className="auth-field-hint">Enter a valid email address.</span>
              )}
            </label>

            <label htmlFor="password">
              Password
              <span className="password-field">
                <input
                  aria-describedby={fieldError("password") ? "password-error" : undefined}
                  aria-invalid={Boolean(fieldError("password"))}
                  autoComplete={isRegister ? "new-password" : "current-password"}
                  id="password"
                  maxLength={128}
                  minLength={isRegister ? 12 : 1}
                  name="password"
                  onChange={(event) => {
                    setPassword(event.target.value);
                    clearServerFieldError("password");
                  }}
                  onKeyDown={(event) => {
                    if (event.key === "Enter") {
                      event.preventDefault();
                      event.currentTarget.form?.requestSubmit();
                    }
                  }}
                  placeholder={isRegister ? "At least 12 characters" : "Your password"}
                  required
                  type={showPassword ? "text" : "password"}
                  value={password}
                />
                <button
                  aria-label={showPassword ? "Hide password" : "Show password"}
                  onClick={() => setShowPassword(!showPassword)}
                  type="button"
                >
                  {showPassword ? <EyeOff size={17} /> : <Eye size={17} />}
                </button>
              </span>
              {fieldError("password") && (
                <span className="auth-field-hint" id="password-error">
                  {fieldError("password")}
                </span>
              )}
            </label>

            {isRegister && (
              <label htmlFor="password-confirmation">
                Confirm password
                <span className="password-field">
                  <input
                    aria-describedby={fieldError("passwordConfirmation") ? "password-confirmation-error" : undefined}
                    aria-invalid={Boolean(fieldError("passwordConfirmation"))}
                    autoComplete="new-password"
                    id="password-confirmation"
                    maxLength={128}
                    minLength={12}
                    name="passwordConfirmation"
                    onChange={(event) => {
                      setPasswordConfirmation(event.target.value);
                      clearServerFieldError("passwordConfirmation");
                    }}
                    placeholder="Enter your password again"
                    required
                    type={showConfirmation ? "text" : "password"}
                    value={passwordConfirmation}
                  />
                  <button
                    aria-label={showConfirmation ? "Hide password confirmation" : "Show password confirmation"}
                    onClick={() => setShowConfirmation(!showConfirmation)}
                    type="button"
                  >
                    {showConfirmation ? <EyeOff size={17} /> : <Eye size={17} />}
                  </button>
                </span>
                {fieldError("passwordConfirmation") && (
                  <span className="auth-field-hint" id="password-confirmation-error">
                    {fieldError("passwordConfirmation")}
                  </span>
                )}
              </label>
            )}

            {message && (
              <div className={isError ? "form-feedback is-error" : "form-feedback"} role={isError ? "alert" : "status"}>
                {message}
              </div>
            )}

            <button
              className="button button-coral auth-submit font-bold shadow-md"
              disabled={isSubmitting || (!isRegister && !formIsValid)}
              type="submit"
            >
              {isSubmitting && <LoaderCircle aria-hidden="true" className="auth-spinner" size={17} />}
              {isSubmitting ? "Please wait…" : isRegister ? "Create Pookie Match Account" : "Sign in"}
              {!isSubmitting && <ArrowRight size={17} />}
            </button>
          </form>

          <p className="auth-switch">
            {isRegister ? "Already have an account?" : "New to Pookie Match?"}{" "}
            <Link href={isRegister ? "/login" : "/register"}>
              {isRegister ? "Log in" : "Create an account"}
            </Link>
          </p>
          <p className="auth-privacy">
            18+ only. Safe, respectful, consent-first community. <Link href="/profile">Privacy Promise</Link>
          </p>
        </div>
        <span className="auth-bottom-note">Designed for authentic romance, not mindless doomscrolling 💖</span>
      </div>
    </div>
  );
}
