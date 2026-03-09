import { Link, useNavigate, useLocation } from 'react-router-dom';
import { useState, useEffect, useRef } from 'react';

export default function Navbar() {
    const navigate = useNavigate();
    const location = useLocation();
    const token = localStorage.getItem('token');
    const userName = localStorage.getItem('userName');
    const [menuOpen, setMenuOpen] = useState(false);
    const menuRef = useRef(null);

    const handleLogout = () => {
        localStorage.clear();
        setMenuOpen(false);
        navigate('/login');
    };

    // Close menu on route change
    useEffect(() => { setMenuOpen(false); }, [location.pathname]);

    // Close menu on outside click
    useEffect(() => {
        const handler = (e) => { if (menuRef.current && !menuRef.current.contains(e.target)) setMenuOpen(false); };
        document.addEventListener('mousedown', handler);
        return () => document.removeEventListener('mousedown', handler);
    }, []);

    const isActive = (path) => location.pathname === path ? 'nav-link active' : 'nav-link';

    const navLinks = token ? (
        <>
            <Link to="/feed" className={isActive('/feed')}>Feed</Link>
            <Link to="/network" className={isActive('/network')}>Network</Link>
            <Link to="/careers" className={isActive('/careers')}>Careers</Link>
            <Link to="/profile" className={isActive('/profile')}>Profile</Link>
            <button onClick={handleLogout} className="uc-btn uc-btn-outline" style={{ padding: '8px 18px', marginLeft: 4 }}>Logout</button>
        </>
    ) : (
        <>
            <Link to="/login" className={isActive('/login')}>Sign In</Link>
            <Link to="/register" className="uc-btn uc-btn-primary" style={{ padding: '8px 20px' }}>Join Now</Link>
        </>
    );

    return (
        <nav className="navbar" ref={menuRef}>
            <div className="nav-content">
                {/* Brand */}
                <Link to="/" className="nav-brand">
                    <div className="nav-brand-icon">U</div>
                    <span className="nav-brand-text">UniConnect</span>
                </Link>

                {/* Desktop links */}
                <div className="nav-links">
                    {navLinks}
                </div>

                {/* Hamburger — mobile only */}
                <button className="nav-hamburger" onClick={() => setMenuOpen(!menuOpen)} aria-label="Menu">
                    {menuOpen ? (
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
                    ) : (
                        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round"><line x1="3" y1="6" x2="21" y2="6"/><line x1="3" y1="12" x2="21" y2="12"/><line x1="3" y1="18" x2="21" y2="18"/></svg>
                    )}
                </button>
            </div>

            {/* Mobile dropdown */}
            <div className={`nav-mobile-menu ${menuOpen ? 'open' : ''}`}>
                {navLinks}
            </div>
        </nav>
    );
}