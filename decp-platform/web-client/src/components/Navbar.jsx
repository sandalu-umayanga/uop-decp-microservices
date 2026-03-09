import { Link, useNavigate, useLocation } from 'react-router-dom';

export default function Navbar() {
    const navigate = useNavigate();
    const location = useLocation();
    const token = localStorage.getItem('token');
    const userName = localStorage.getItem('userName');

    const handleLogout = () => {
        localStorage.clear();
        navigate('/login');
    };

    const isActive = (path) => location.pathname === path ? 'nav-link active' : 'nav-link';

    return (
        <nav className="navbar">
            <div className="nav-content">
                <Link to="/" style={{ display: 'flex', alignItems: 'center', gap: '12px', textDecoration: 'none', marginRight: 'auto' }}>
                    <div style={{ background: 'var(--uc-primary)', width: '40px', height: '40px', borderRadius: '12px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold', fontSize: '22px' }}>U</div>
                    <span style={{ color: 'var(--uc-text-main)', fontWeight: '800', fontSize: '22px', letterSpacing: '-1px' }}>
                        UniConnect
                    </span>
                </Link>

                <div style={{ display: 'flex', gap: '8px', alignItems: 'center' }}>
                    {token ? (
                        <>
                            <Link to="/feed" className={isActive('/feed')}>Feed</Link>
                            <Link to="/network" className={isActive('/network')}>Network</Link>
                            <Link to="/careers" className={isActive('/careers')}>Careers</Link>
                            <Link to="/profile" className={isActive('/profile')}>Profile</Link>
                            
                            <button onClick={handleLogout} className="uc-btn uc-btn-outline" style={{ marginLeft: '12px', padding: '8px 16px', borderRadius: '12px' }}>
                                Logout
                            </button>
                        </>
                    ) : (
                        <>
                            <Link to="/login" className={isActive('/login')}>Sign In</Link>
                            <Link to="/register" className="uc-btn uc-btn-primary">Join Now</Link>
                        </>
                    )}
                </div>
            </div>
        </nav>
    );
}