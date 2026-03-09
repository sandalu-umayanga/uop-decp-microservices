import { useState } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';

export default function Register() {
    const [formData, setFormData] = useState({ name: '', email: '', password: '', role: 'STUDENT' });
    const [message, setMessage] = useState('');
    const [status, setStatus] = useState('');
    const [loading, setLoading] = useState(false);

    const handleChange = (e) => setFormData({ ...formData, [e.target.name]: e.target.value });

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage(''); setStatus(''); setLoading(true);
        try {
            const response = await axios.post('/api/users/register', formData);
            setMessage(`Success! Welcome, ${response.data.name}.`);
            setStatus('success');
            setFormData({ name: '', email: '', password: '', role: 'STUDENT' });
        } catch (error) {
            setStatus('error');
            setMessage(error.response?.data && typeof error.response.data === 'string' ? error.response.data : 'An error occurred. Please check your details.');
        } finally { setLoading(false); }
    };

    return (
        <div className="auth-container">
            <div className="uc-card auth-card" style={{ maxWidth: 480 }}>
                <div className="auth-brand">U</div>
                <h2 className="auth-title">Join the community</h2>
                <p className="auth-subtitle">Connect with students and alumni from your department</p>

                {message && <div className={status === 'success' ? 'auth-success' : 'auth-error'} style={{ marginBottom: 20 }}>{message}</div>}

                <form onSubmit={handleSubmit} className="auth-form">
                    <div>
                        <label className="form-label">Full Name</label>
                        <input type="text" name="name" className="li-input" placeholder="John Doe" required
                               onChange={handleChange} value={formData.name} />
                    </div>
                    <div>
                        <label className="form-label">University Email</label>
                        <input type="email" name="email" className="li-input" placeholder="name@eng.pdn.ac.lk" required
                               onChange={handleChange} value={formData.email} />
                    </div>
                    <div>
                        <label className="form-label">Password</label>
                        <input type="password" name="password" className="li-input" placeholder="••••••••" required
                               onChange={handleChange} value={formData.password} />
                    </div>
                    <div>
                        <label className="form-label">I am a…</label>
                        <select name="role" className="li-input" onChange={handleChange} value={formData.role}>
                            <option value="STUDENT">Student</option>
                            <option value="ALUMNI">Alumni</option>
                            <option value="ADMIN">Admin</option>
                        </select>
                    </div>
                    <button type="submit" className="uc-btn uc-btn-primary" style={{ width: '100%', padding: 14 }} disabled={loading}>
                        {loading ? 'Creating account…' : 'Get Started'}
                    </button>
                </form>

                <p className="auth-footer">
                    Already have an account? <Link to="/login">Sign In</Link>
                </p>
            </div>
        </div>
    );
}