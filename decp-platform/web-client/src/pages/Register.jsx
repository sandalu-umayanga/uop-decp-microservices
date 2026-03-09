import { useState } from 'react';
import axios from 'axios';
import { Link } from 'react-router-dom';

export default function Register() {
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        password: '',
        role: 'STUDENT'
    });
    const [message, setMessage] = useState('');
    const [status, setStatus] = useState('');

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setMessage('');
        setStatus('');
        try {
            const response = await axios.post('/api/users/register', formData);
            setMessage(`Success! Welcome, ${response.data.name}.`);
            setStatus('success');
            setFormData({ name: '', email: '', password: '', role: 'STUDENT' });
        } catch (error) {
            setStatus('error');
            if (error.response && typeof error.response.data === 'string') {
                setMessage(error.response.data);
            } else {
                setMessage("An error occurred. Please check your details.");
            }
        }
    };

    return (
        <div className="auth-container" style={{ padding: '40px 24px' }}>
            <div className="uc-card" style={{ maxWidth: '480px', width: '100%', textAlign: 'center', padding: '40px' }}>
                <div style={{ background: 'var(--uc-primary)', width: '60px', height: '60px', borderRadius: '16px', display: 'flex', alignItems: 'center', justifyContent: 'center', color: 'white', fontWeight: 'bold', fontSize: '32px', margin: '0 auto 24px' }}>U</div>
                <h2 style={{ fontSize: '28px', fontWeight: '800', marginBottom: '8px', letterSpacing: '-1px' }}>Join the community</h2>
                <p style={{ color: 'var(--uc-text-muted)', marginBottom: '32px', fontSize: '15px' }}>Connect with students and alumni from your department</p>

                {message && (
                    <div style={{ 
                        backgroundColor: status === 'success' ? '#f0fdf4' : '#fef2f2',
                        color: status === 'success' ? '#16a34a' : '#dc2626',
                        padding: '16px',
                        borderRadius: '12px',
                        marginBottom: '24px',
                        fontSize: '14px',
                        fontWeight: '700',
                        border: `1px solid ${status === 'success' ? '#bbf7d0' : '#fecaca'}`
                    }}>
                        {message}
                    </div>
                )}

                <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', textAlign: 'left' }}>
                    <div style={{ marginBottom: '20px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontSize: '13px', fontWeight: '700', color: 'var(--uc-text-main)', textTransform: 'uppercase' }}>Full Name</label>
                        <input type="text" name="name" className="li-input" placeholder="John Doe" required
                               onChange={handleChange} value={formData.name} style={{ borderRadius: '12px', padding: '12px' }} />
                    </div>

                    <div style={{ marginBottom: '20px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontSize: '13px', fontWeight: '700', color: 'var(--uc-text-main)', textTransform: 'uppercase' }}>University Email</label>
                        <input type="email" name="email" className="li-input" placeholder="name@eng.pdn.ac.lk" required
                               onChange={handleChange} value={formData.email} style={{ borderRadius: '12px', padding: '12px' }} />
                    </div>

                    <div style={{ marginBottom: '20px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontSize: '13px', fontWeight: '700', color: 'var(--uc-text-main)', textTransform: 'uppercase' }}>Password</label>
                        <input type="password" name="password" className="li-input" placeholder="••••••••" required
                               onChange={handleChange} value={formData.password} style={{ borderRadius: '12px', padding: '12px' }} />
                    </div>

                    <div style={{ marginBottom: '32px' }}>
                        <label style={{ display: 'block', marginBottom: '8px', fontSize: '13px', fontWeight: '700', color: 'var(--uc-text-main)', textTransform: 'uppercase' }}>I am a...</label>
                        <select name="role" className="li-input" onChange={handleChange} value={formData.role} style={{ borderRadius: '12px', padding: '12px', appearance: 'none', background: 'white' }}>
                            <option value="STUDENT">Student</option>
                            <option value="ALUMNI">Alumni</option>
                            <option value="ADMIN">Admin</option>
                        </select>
                    </div>

                    <button type="submit" className="uc-btn uc-btn-primary" style={{ width: '100%', padding: '14px' }}>
                        Get Started
                    </button>
                </form>

                <p style={{ marginTop: '32px', fontSize: '14px', color: 'var(--uc-text-muted)' }}>
                    Already have an account? <Link to="/login" style={{ color: 'var(--uc-primary)', fontWeight: '700', textDecoration: 'none' }}>Sign In</Link>
                </p>
            </div>
        </div>
    );
}