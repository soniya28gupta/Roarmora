"use client";

import { createContext, useContext, useEffect, useMemo, useState, type ReactNode } from "react";
import { AlertCircle, Check, LoaderCircle, Sparkles } from "lucide-react";
import type { PreviewDataState } from "@/types/roamora";

interface DemoStateContextValue {
  state: PreviewDataState;
  setState: (state: PreviewDataState) => void;
}

const DemoStateContext = createContext<DemoStateContextValue | null>(null);
const previewStates: PreviewDataState[] = ["data", "loading", "empty", "error"];

export function DemoStateProvider({ children, previewMode = true }: { children: ReactNode; previewMode?: boolean }) {
  const [state, setStateValue] = useState<PreviewDataState>("data");

  useEffect(() => {
    if (!previewMode) {
      setStateValue("data");
      return;
    }
    const queryState = new URLSearchParams(window.location.search).get("previewState");
    const savedState = window.localStorage.getItem("roamora-preview-state");
    const initialState = previewStates.includes(queryState as PreviewDataState)
      ? (queryState as PreviewDataState)
      : previewStates.includes(savedState as PreviewDataState)
        ? (savedState as PreviewDataState)
        : "data";
    setStateValue(initialState);
  }, [previewMode]);

  const setState = (nextState: PreviewDataState) => {
    setStateValue(nextState);
    window.localStorage.setItem("roamora-preview-state", nextState);
    const url = new URL(window.location.href);
    if (nextState === "data") url.searchParams.delete("previewState");
    else url.searchParams.set("previewState", nextState);
    window.history.replaceState({}, "", url.toString());
  };
  const value = useMemo(() => ({ state, setState }), [state]);

  return <DemoStateContext.Provider value={value}>{children}</DemoStateContext.Provider>;
}

export function useDemoState() {
  const context = useContext(DemoStateContext);
  if (!context) throw new Error("useDemoState must be used within DemoStateProvider");
  return context;
}

export function DemoStateSwitcher() {
  const { state, setState } = useDemoState();
  const options: { value: PreviewDataState; label: string }[] = [
    { value: "data", label: "Sample data" },
    { value: "loading", label: "Loading" },
    { value: "empty", label: "Empty" },
    { value: "error", label: "Error" },
  ];

  return (
    <div className="demo-switcher">
      <span className="demo-switcher-label"><Sparkles size={14} /> Demo view</span>
      <div className="demo-switcher-options" role="group" aria-label="Preview demo states">
        {options.map((option) => (
          <button
            aria-pressed={state === option.value}
            className={state === option.value ? "demo-option is-selected" : "demo-option"}
            key={option.value}
            onClick={() => setState(option.value)}
            type="button"
          >
            {state === option.value && <Check size={12} />}
            {option.label}
          </button>
        ))}
      </div>
    </div>
  );
}

export function DemoStateSurface({
  children,
  emptyTitle = "Nothing here just yet",
  emptyCopy = "There’s always something new around the corner.",
}: {
  children: ReactNode;
  emptyTitle?: string;
  emptyCopy?: string;
}) {
  const { state, setState } = useDemoState();

  if (state === "data") return <>{children}</>;
  if (state === "loading") {
    return (
      <div aria-label="Loading demo content" className="loading-grid" role="status">
        <LoaderCircle className="loading-icon" size={22} />
        <span>Gathering a few good things…</span>
        <div className="skeleton-row"><i /><i /><i /></div>
      </div>
    );
  }
  if (state === "error") {
    return (
      <div className="state-card state-error" role="alert">
        <AlertCircle size={25} />
        <h2>That didn’t load quite right</h2>
        <p>This is only a local preview. Give it another try.</p>
        <button className="button button-dark" onClick={() => setState("data")} type="button">Try again</button>
      </div>
    );
  }
  return (
    <div className="state-card state-empty">
      <span className="empty-sparkle"><Sparkles size={22} /></span>
      <h2>{emptyTitle}</h2>
      <p>{emptyCopy}</p>
      <button className="button button-outline" onClick={() => setState("data")} type="button">Show sample content</button>
    </div>
  );
}
