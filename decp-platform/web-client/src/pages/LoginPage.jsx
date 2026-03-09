import { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';

export default function LoginPage() {
    const [credentials, setCredentials] = useState({ email: '', password: '' });
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const handleChange = (e) => {
        setCredentials({ ...credentials, [e.target.name]: e.target.value });
    };

    const handleLogin = async (e) => {
        e.preventDefault();
        try {
            const response = await axios.post('/api/users/login', credentials);
            localStorage.setItem('token', response.data.token);
            localStorage.setItem('role', response.data.role);
            localStorage.setItem('userId', response.data.id);
            localStorage.setItem('userName', response.data.name);
            navigate('/feed');
        } catch (err) {
            setError('Invalid email or password.');
        }
    };

    return (
        <div className="auth-container">
            <div className="uc-card" style={{ maxWidth: '400px', width: '100%', textAlign: 'center', padding: '40px' }}>
                <div style={{ background: 'var(--uc-primary)', width: '60px', height: '60px', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold', fontSize: '32px', margin: '0 auto 24px' }}>U</div>
                <h2 style={{ fontSize: '28px', fontWeight: '800', marginBottom: '8px', letterSpacing: '-1px' }}>Welcome back</h2>
                <p style={{ color: 'var(--uc-text-muted)', marginBottom: '32px', fontSize: '15px' }}>Enter your credentials to access your account</p>
                
                {error && <p style={{ color: '#f43f5e', marginBottom: '20px', fontSize: '14px', fontWeight: '600' }}>{error}</p>}
                
                <form onSubmit={handleLogin} style={{ display: 'flex', flexDirection: 'column', textAlign: 'left' }}>
                    <div style={{ marginBottom: '20px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontSize: '13px', fontWeight: '700', color: 'var(--uc-text-main)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Email Address</label>
                        <input type="email" name="email" className="li-input" placeholder="name@eng.pdn.ac.lk" required
                               onChange={handleChange} value={credentials.email} style={{ borderRadius: '12px', padding: '12px' }} />
                    </div>

                    <div style={{ marginBottom: '32px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontSize: '13px', fontWeight: '700', color: 'var(--uc-text-main)', textTransform: 'uppercase', letterSpacing: '0.5px' }}>Password</label>
                        <input type="password" name="password" className="li-input" placeholder="••••••••" required
                               onChange={handleChange} value={credentials.password} style={{ borderRadius: '12px', padding: '12px' }} />
                    </div>

                    <button type="submit" className="uc-btn uc-btn-primary" style={{ width: '100%', padding: '14px' }}>
                        Sign In
                    </button>
                </form>
                
                <p style={{ marginTop: '32px', fontSize: '14px', color: 'var(--uc-text-muted)' }}>
                    New member? <Link to="/register" style={{ color: 'var(--uc-primary)', fontWeight: '700', textDecoration: 'none' }}>Create an account</Link>
                </p>
            </div>
        </div>
    );
}