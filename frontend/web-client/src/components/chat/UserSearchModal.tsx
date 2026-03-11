import { useState, useEffect, useRef } from "react";
import { userService } from "../../services/user";
import type { User } from "../../types";

interface UserSearchModalProps {
  open: boolean;
  onClose: () => void;
  onSelectUser: (user: User) => void | Promise<void>;
  title?: string;
  loading?: boolean;
}

export default function UserSearchModal({
  open,
  onClose,
  onSelectUser,
  title = "Search Users",
  loading = false,
}: UserSearchModalProps) {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<User[]>([]);
  const [searching, setSearching] = useState(false);
  const [error, setError] = useState("");
  const debounceRef = useRef<ReturnType<typeof setTimeout> | null>(null);

  // Real-time search with debounce
  useEffect(() => {
    if (!open || !query.trim()) {
      setResults([]);
      setError("");
      return;
    }
    setSearching(true);
    setError("");
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(async () => {
      try {
        const res = await userService.searchByUsername(query.trim());
        const users = Array.isArray(res.data) ? res.data : [res.data];
        setResults(users);
        if (users.length === 0) setError("No users found");
      } catch {
        setResults([]);
        setError("No users found");
      }
      setSearching(false);
    }, 300);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, query]);

  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div className="w-full max-w-md rounded-xl bg-white p-6 shadow-xl dark:bg-gray-900">
        <div className="flex items-center justify-between">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">{title}</h3>
          <button
            onClick={onClose}
            className="text-gray-400 hover:text-gray-600 dark:hover:text-gray-300"
          >
            ✕
          </button>
        </div>
        <div className="mt-4">
          <input
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search by username..."
            className="w-full rounded-lg border border-gray-200 bg-white px-3 py-2 text-sm focus:border-primary-500 focus:outline-none focus:ring-1 focus:ring-primary-500 dark:border-gray-700 dark:bg-gray-800 dark:text-white dark:placeholder-gray-400"
            autoFocus
          />
        </div>
        {error && <p className="mt-3 text-sm text-red-500">{error}</p>}
        {searching && <p className="mt-3 text-sm text-gray-500">Searching...</p>}
        {results.length > 0 ? (
          <div className="mt-4 max-h-60 overflow-y-auto">
            {results.map((user) => (
              <div
                key={user.id}
                className={`flex items-center justify-between rounded-lg border border-gray-200 p-3 mb-2 hover:bg-primary-50 cursor-pointer dark:border-gray-700 dark:hover:bg-primary-900/50 ${loading ? 'opacity-50 pointer-events-none' : ''}`}
                onClick={async () => {
                  await onSelectUser(user);
                  onClose();
                }}
              >
                <div className="flex items-center gap-3">
                  <div className="flex h-10 w-10 items-center justify-center rounded-full bg-primary-100 text-sm font-semibold text-primary-700 dark:bg-primary-900/50 dark:text-primary-300">
                    {user.fullName?.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <p className="text-sm font-medium text-gray-900 dark:text-white">{user.fullName}</p>
                    <p className="text-xs text-gray-500 dark:text-gray-400">@{user.username} · {user.role}</p>
                  </div>
                </div>
                <button
                  className="rounded-lg bg-primary-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-primary-700"
                  disabled={loading}
                >
                  {loading ? "Starting..." : "Select"}
                </button>
              </div>
            ))}
          </div>
        ) : (
          !searching && !error && (
            <p className="mt-4 text-sm text-gray-500 text-center dark:text-gray-400">Type to search for users by username.</p>
          )
        )}
      </div>
    </div>
  );
}
