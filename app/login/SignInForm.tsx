"use client";

import Link from "next/link";
import { useActionState } from "react";
import { requestSignIn, verifyCode, type SignInState } from "./actions";
import { JOIN_URL } from "@/lib/join";

export function SignInForm({ next, linkFailed }: { next: string; linkFailed: boolean }) {
  const [emailState, sendLink, sending] = useActionState<SignInState, FormData>(requestSignIn, {
    stage: "email",
    error: linkFailed ? "That sign-in link has expired or was already used. Ask for a new one." : undefined,
  });
  const [codeState, checkCode, checking] = useActionState<SignInState, FormData>(verifyCode, {
    stage: "email",
  });

  const codeStage = codeState.stage === "code" ? codeState : emailState.stage === "code" ? emailState : null;

  if (codeStage) {
    return (
      <div className="gate-form">
        <p className="gate-note" role="status">
          If <b>{codeStage.email}</b> belongs to a member or the team, an email is on its way. Open the
          link in it, or type the code here.
        </p>
        <form action={checkCode}>
          <input type="hidden" name="email" value={codeStage.email} />
          <input type="hidden" name="next" value={codeStage.next} />
          <div className="rf">
            <label htmlFor="code">Code from the email</label>
            <input
              id="code"
              name="code"
              inputMode="numeric"
              autoComplete="one-time-code"
              pattern="[0-9 ]*"
              required
              aria-describedby={codeState.error ? "code-error" : undefined}
            />
          </div>
          {codeState.error ? (
            <p className="gate-error" id="code-error" role="alert">
              {codeState.error}
            </p>
          ) : null}
          <button className="btn btn-gold" type="submit" disabled={checking}>
            {checking ? "Checking…" : "Sign in"}
          </button>
        </form>
        <form action={sendLink}>
          <input type="hidden" name="email" value={codeStage.email} />
          <input type="hidden" name="next" value={codeStage.next} />
          <button className="gate-link" type="submit" disabled={sending}>
            {sending ? "Sending…" : "Send a new code"}
          </button>
        </form>
        {emailState.stage === "email" && emailState.error ? (
          <p className="gate-error" role="alert">
            {emailState.error}
          </p>
        ) : null}
        <Link className="gate-link" href={`/login?next=${encodeURIComponent(codeStage.next)}`}>
          Use a different email
        </Link>
      </div>
    );
  }

  return (
    <div className="gate-form">
      <form action={sendLink}>
        <input type="hidden" name="next" value={next} />
        <div className="rf">
          <label htmlFor="email">Your email</label>
          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            defaultValue={emailState.email}
            required
            aria-describedby={emailState.error ? "email-error" : undefined}
          />
        </div>
        {emailState.error ? (
          <p className="gate-error" id="email-error" role="alert">
            {emailState.error}
          </p>
        ) : null}
        <button className="btn btn-gold" type="submit" disabled={sending}>
          {sending ? "Sending…" : "Email me a sign-in link"}
        </button>
      </form>
      <p className="gate-note">
        Not a member yet?{" "}
        <a href={JOIN_URL} target="_blank" rel="noopener noreferrer">
          Join the flock
        </a>
      </p>
      <Link className="gate-link" href="/" prefetch={false}>
        Back to Flocking Birds
      </Link>
    </div>
  );
}
