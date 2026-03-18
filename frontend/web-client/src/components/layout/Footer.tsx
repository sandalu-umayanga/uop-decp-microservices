export default function Footer() {
  return (
    <footer className="mx-4 mt-6 rounded-2xl glass-panel py-6 sm:mx-6">
      <div className="mx-auto max-w-7xl px-4 text-center text-sm ink-muted">
        <p>
          &copy; {new Date().getFullYear()} PeraLink &mdash; Department
          Engagement &amp; Career Platform
        </p>
        <p className="mt-1">
          University of Peradeniya &middot; CO528 Applied Software Architecture
        </p>
      </div>
    </footer>
  );
}
