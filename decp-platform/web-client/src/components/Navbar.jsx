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
            <div style={{ display: 'flex', alignItems: 'center', gap: '10px', marginRight: 'auto' }}>
                <img src="/logoNoBack.png" alt="DECP Logo" style={{ height: '35px' }} />
                <Link to="/" style={{ textDecoration: 'none', color: 'var(--primary-color)', fontWeight: 'bold', fontSize: '1.4rem' }}>
                    UniConnect
                </Link>
            </div>

            <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                <Link to="/" className={isActive('/')}>Home</Link>
                
                {token ? (
                    <>
                        <Link to="/feed" className={isActive('/feed')}>Feed</Link>
                        <Link to="/careers" className={isActive('/careers')}>Careers</Link>
                        <Link to="/profile" className={isActive('/profile')}>Profile</Link>
                        
                        <div style={{ marginLeft: '10px', display: 'flex', alignItems: 'center', gap: '15px' }}>
                            <span style={{ color: 'var(--text-secondary)', fontWeight: '500' }}>
                                Hi, {userName}
                            </span>
                            <button onClick={handleLogout} className="btn btn-danger" style={{ padding: '6px 12px' }}>
                                Logout
                            </button>
                        </div>
                    </>
                ) : (
                    <>
                        <Link to="/login" className={isActive('/login')}>Login</Link>
                        <Link to="/register" className={isActive('/register')}>Register</Link>
                    </>
                )}
            </div>
        </nav>
    );
}