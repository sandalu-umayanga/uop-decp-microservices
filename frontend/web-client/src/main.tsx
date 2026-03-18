import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import App from "./App";
import "./index.css";

// SockJS depends on a Node-style `global` object in some builds.
if (typeof window !== "undefined" && !(window as any).global) {
  (window as any).global = window;
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
