import { BrowserRouter, Routes, Route } from "react-router-dom";
import { AuthProvider } from "./context/AuthContext";
import { NotificationProvider } from "./context/NotificationContext";
import { ChatProvider } from "./context/ChatContext";
import { ThemeProvider } from "./context/ThemeContext";
import AuthGuard from "./components/auth/AuthGuard";
import Navbar from "./components/layout/Navbar";
import Footer from "./components/layout/Footer";
import LoginPage from "./pages/LoginPage";
import DashboardPage from "./pages/DashboardPage";
import JobsPage from "./pages/JobsPage";
import EventsPage from "./pages/EventsPage";
import ResearchPage from "./pages/ResearchPage";
import ChatPage from "./pages/ChatPage";
import MentorshipPage from "./pages/MentorshipPage";
import ProfilePage from "./pages/ProfilePage";
import SettingsPage from "./pages/SettingsPage";
import NotificationsPage from "./pages/NotificationsPage";
import AdminPage from "./pages/AdminPage";
import NotFoundPage from "./pages/NotFoundPage";

function AppLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="app-shell relative flex min-h-screen flex-col overflow-x-hidden transition-colors">
      <div className="pointer-events-none absolute -left-24 -top-28 h-72 w-72 rounded-full bg-primary-300/25 blur-3xl dark:bg-primary-700/20" />
      <div className="pointer-events-none absolute -right-24 top-1/4 h-64 w-64 rounded-full bg-emerald-300/25 blur-3xl dark:bg-emerald-600/20" />
      <Navbar />
      <main className="relative z-10 flex-1 py-4 sm:py-6">{children}</main>
      <Footer />
    </div>
  );
}

export default function App() {
  return (
    <BrowserRouter>
      <ThemeProvider>
        <AuthProvider>
          <NotificationProvider>
            <ChatProvider>
              <Routes>
                <Route path="/login" element={<LoginPage />} />
                <Route
                  path="*"
                  element={
                    <AuthGuard>
                      <AppLayout>
                        <Routes>
                          <Route path="/" element={<DashboardPage />} />
                          <Route path="/jobs" element={<JobsPage />} />
                          <Route path="/events" element={<EventsPage />} />
                          <Route path="/research" element={<ResearchPage />} />
                          <Route path="/chat" element={<ChatPage />} />
                          <Route
                            path="/mentorship"
                            element={<MentorshipPage />}
                          />
                          <Route path="/profile" element={<ProfilePage />} />
                          <Route
                            path="/profile/:userId"
                            element={<ProfilePage />}
                          />
                          <Route path="/settings" element={<SettingsPage />} />
                          <Route
                            path="/notifications"
                            element={<NotificationsPage />}
                          />
                          <Route path="/admin" element={<AdminPage />} />
                          <Route path="*" element={<NotFoundPage />} />
                        </Routes>
                      </AppLayout>
                    </AuthGuard>
                  }
                />
              </Routes>
            </ChatProvider>
          </NotificationProvider>
        </AuthProvider>
      </ThemeProvider>
    </BrowserRouter>
  );
}
