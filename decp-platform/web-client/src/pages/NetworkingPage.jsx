import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function NetworkingPage() {
    const [users, setUsers] = useState([]);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) { navigate('/login'); return; }
        fetchUsers();
    }, [navigate]);

    const fetchUsers = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get('/api/users/list', { headers: { Authorization: `Bearer ${token}` } });
            setUsers(response.data.filter(u => String(u.id) !== String(currentUserId)));
        } catch (err) { setError('Failed to load users.'); }
    };

    const handleConnect = async (userId) => {
        const token = localStorage.getItem('token');
        try {
            await axios.post(`/api/users/${userId}/connect`, {}, { headers: { Authorization: `Bearer ${token}` } });
            alert("Connection established!");
            fetchUsers();
        } catch (err) { console.error(err); }
    };

    return (
        <div className="container" style={{ marginTop: '40px' }}>
            <div style={{ marginBottom: '32px' }}>
                <h2 style={{ fontSize: '28px', fontWeight: '800', letterSpacing: '-1px' }}>Department Network</h2>
                <p style={{ color: 'var(--uc-text-muted)', fontWeight: '500' }}>Grow your professional circle within the department</p>
            </div>
            
            <div className="responsive-grid">
                {users.map(user => (
                    <div key={user.id} className="uc-card" style={{ textAlign: 'center', padding: '32px 24px' }}>
                        <div className="avatar-squircle" style={{ width: '80px', height: '80px', margin: '0 auto 20px', fontSize: '32px', boxShadow: '0 8px 20px rgba(79, 70, 229, 0.15)' }}>
                            {user.name.charAt(0).toUpperCase()}
                        </div>
                        <div style={{ fontWeight: '800', fontSize: '18px', marginBottom: '4px', color: 'var(--uc-text-main)' }}>{user.name}</div>
                        <div style={{ fontSize: '13px', color: 'var(--uc-primary)', fontWeight: '700', marginBottom: '20px', height: '32px', overflow: 'hidden' }}>{user.department || 'University Member'}</div>
                        <button onClick={() => handleConnect(user.id)} className="uc-btn uc-btn-primary" style={{ width: '100%' }}>Connect</button>
                    </div>
                ))}
            </div>
        </div>
    );
}