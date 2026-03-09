import { useState } from 'react';
import axios from 'axios';
import { useNavigate, Link } from 'react-router-dom';

export default function LoginPage() {
    const [credentials, setCredentials] = useState({ email: '', password: '' });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleChange = (e) => {
        setCredentials({ ...credentials, [e.target.name]: e.target.value });
    };

    const handleLogin = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const response = await axios.post('/api/users/login', credentials);
            localStorage.setItem('token', response.data.token);
            localStorage.setItem('role', response.data.role);
            localStorage.setItem('userId', response.data.id);
            localStorage.setItem('userName', response.data.name);
            navigate('/feed');
        } catch (err) {
            setError('Invalid email or password.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-container">
            <div className="uc-card auth-card">
                <div className="auth-brand">U</div>
                <h2 className="auth-title">Welcome back</h2>
                <p className="auth-subtitle">Enter your credentials to access your account</p>

                {error && <div className="auth-error" style={{ marginBottom: 20 }}>{error}</div>}

                <form onSubmit={handleLogin} className="auth-form">
                    <div>
                        <label className="form-label">Email Address</label>
                        <input type="email" name="email" className="li-input" placeholder="name@eng.pdn.ac.lk" required
                               onChange={handleChange} value={credentials.email} />
                    </div>
                    <div>
                        <label className="form-label">Password</label>
                        <input type="password" name="password" className="li-input" placeholder="••••••••" required
                               onChange={handleChange} value={credentials.password} />
                    </div>
                    <button type="submit" className="uc-btn uc-btn-primary" style={{ width: '100%', padding: 14 }} disabled={loading}>
                        {loading ? 'Signing in…' : 'Sign In'}
                    </button>
                </form>

                <p className="auth-footer">
                    New member? <Link to="/register">Create an account</Link>
                </p>
            </div>
        </div>
    );
}