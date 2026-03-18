import { useState } from "react";
import { useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import type { UserRegistrationRequest } from "../types";
import ErrorAlert from "../components/common/ErrorAlert";

export default function LoginPage() {
  const navigate = useNavigate();
  const { login, register } = useAuth();
  const [isRegister, setIsRegister] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  // Login fields
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  // Register fields
  const [regUsername, setRegUsername] = useState("");
  const [regEmail, setRegEmail] = useState("");
  const [regPassword, setRegPassword] = useState("");
  const [regFullName, setRegFullName] = useState("");
  const [regRole, setRegRole] = useState<"STUDENT" | "ALUMNI">("STUDENT");

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!username.trim() || !password) return;
    setLoading(true);
    setError("");
    try {
      await login({ username: username.trim(), password });
      navigate("/", { replace: true });
    } catch (err: any) {
      const data = err.response?.data;
      setError(
        data?.message ||
          data?.error ||
          (typeof data === "string" ? data : null) ||
          "Login failed. Check your credentials.",
      );
    }
    setLoading(false);
  };

  const handleRegister = async (e: React.FormEvent) => {
    e.preventDefault();
    if (
      !regUsername.trim() ||
      !regEmail.trim() ||
      !regPassword ||
      !regFullName.trim()
    )
      return;
    setLoading(true);
    setError("");
    try {
      const data: UserRegistrationRequest = {
        username: regUsername.trim(),
        email: regEmail.trim(),
        password: regPassword,
        fullName: regFullName.trim(),
        role: regRole,
      };
      await register(data);
      // Auto-login after registration
      await login({ username: regUsername.trim(), password: regPassword });
      navigate("/", { replace: true });
    } catch (err: any) {
      const data = err.response?.data;
      setError(
        data?.message ||
          data?.error ||
          (typeof data === "string" ? data : null) ||
          "Registration failed.",
      );
    }
    setLoading(false);
  };

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden px-4 py-8">
      <div className="pointer-events-none absolute -left-20 -top-20 h-72 w-72 rounded-full bg-primary-400/30 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-24 -right-12 h-80 w-80 rounded-full bg-emerald-400/25 blur-3xl" />
      <div className="stagger-in w-full max-w-md">
        {/* Logo */}
        <div className="mb-8 text-center">
          <div className="mx-auto flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-br from-primary-500 to-emerald-500 text-2xl font-bold text-white shadow-xl shadow-primary-500/30">
            D
          </div>
          <h1 className="mt-4 text-4xl font-bold text-gray-900 dark:text-white">
            {isRegister ? "Create Account" : "Welcome Back"}
          </h1>
          <p className="mt-2 text-sm ink-muted">
            {isRegister
              ? "Join the Department Engagement & Career Platform"
              : "Sign in to PeraLink"}
          </p>
        </div>

        {/* Card */}
        <div className="glass-panel rounded-2xl p-6 sm:p-7">
          <ErrorAlert message={error} onClose={() => setError("")} />

          {!isRegister ? (
            /* Login Form */
            <form onSubmit={handleLogin} className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
                  Username
                </label>
                <input
                  type="text"
                  value={username}
                  onChange={(e) => setUsername(e.target.value)}
                  className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
                  placeholder="Enter your username"
                  required
                  autoFocus
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
                  Password
                </label>
                <input
                  type="password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
                  placeholder="Enter your password"
                  required
                />
              </div>
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 py-2.5 text-sm font-semibold text-white shadow-lg shadow-primary-500/25 transition hover:brightness-110 disabled:opacity-50"
              >
                {loading ? "Signing in..." : "Sign In"}
              </button>
            </form>
          ) : (
            /* Register Form */
            <form onSubmit={handleRegister} className="space-y-4">
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
                  Full Name
                </label>
                <input
                  type="text"
                  value={regFullName}
                  onChange={(e) => setRegFullName(e.target.value)}
                  className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
                  placeholder="John Doe"
                  required
                  autoFocus
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
                  Username
                </label>
                <input
                  type="text"
                  value={regUsername}
                  onChange={(e) => setRegUsername(e.target.value)}
                  className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
                  placeholder="johndoe"
                  required
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
                  Email
                </label>
                <input
                  type="email"
                  value={regEmail}
                  onChange={(e) => setRegEmail(e.target.value)}
                  className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
                  placeholder="john@example.com"
                  required
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
                  Password
                </label>
                <input
                  type="password"
                  value={regPassword}
                  onChange={(e) => setRegPassword(e.target.value)}
                  className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
                  placeholder="Min. 6 characters"
                  required
                  minLength={6}
                />
              </div>
              <div>
                <label className="mb-1 block text-sm font-medium text-gray-700 dark:text-gray-200">
                  Role
                </label>
                <select
                  value={regRole}
                  onChange={(e) =>
                    setRegRole(e.target.value as "STUDENT" | "ALUMNI")
                  }
                  className="w-full rounded-xl border subtle-border bg-white/80 px-3 py-2.5 text-sm shadow-sm outline-none transition focus:border-primary-400 focus:ring-2 focus:ring-primary-400/40 dark:bg-white/5"
                >
                  <option value="STUDENT">Student</option>
                  <option value="ALUMNI">Alumni</option>
                </select>
              </div>
              <button
                type="submit"
                disabled={loading}
                className="w-full rounded-xl bg-gradient-to-r from-primary-600 to-emerald-600 py-2.5 text-sm font-semibold text-white shadow-lg shadow-primary-500/25 transition hover:brightness-110 disabled:opacity-50"
              >
                {loading ? "Creating Account..." : "Create Account"}
              </button>
            </form>
          )}

          {/* Toggle */}
          <p className="mt-5 text-center text-sm ink-muted">
            {isRegister ? "Already have an account?" : "Don't have an account?"}{" "}
            <button
              onClick={() => {
                setIsRegister(!isRegister);
                setError("");
              }}
              className="font-semibold text-primary-600 hover:text-primary-700"
            >
              {isRegister ? "Sign In" : "Create Account"}
            </button>
          </p>
        </div>
      </div>
    </div>
  );
}
