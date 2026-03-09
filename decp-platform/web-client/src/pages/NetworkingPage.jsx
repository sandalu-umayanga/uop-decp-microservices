import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function NetworkingPage() {
    const [users, setUsers] = useState([]);
    const [search, setSearch] = useState('');
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');

    useEffect(() => {
        if (!localStorage.getItem('token')) { navigate('/login'); return; }
        fetchUsers();
    }, [navigate]);

    const authHeaders = () => ({ headers: { Authorization: `Bearer ${localStorage.getItem('token')}` } });

    const fetchUsers = async () => {
        try {
            const res = await axios.get('/api/users/list', authHeaders());
            setUsers(res.data.filter(u => String(u.id) !== String(currentUserId)));
        } catch { setError('Failed to load users.'); }
    };

    const handleConnect = async (userId) => {
        try {
            await axios.post(`/api/users/${userId}/connect`, {}, authHeaders());
            fetchUsers();
        } catch (err) { console.error(err); }
    };

    const filtered = users.filter(u =>
        u.name.toLowerCase().includes(search.toLowerCase()) ||
        (u.department || '').toLowerCase().includes(search.toLowerCase())
    );

    return (
        <div className="container">
            <div style={{ marginBottom: 28 }}>
                <h2 style={{ fontSize: 26, fontWeight: 800, letterSpacing: '-0.5px' }}>Department Network</h2>
                <p style={{ color: 'var(--uc-text-muted)', fontWeight: 500, marginBottom: 18 }}>Grow your professional circle within the department</p>
                <input className="li-input" placeholder="Search people or departments…" value={search} onChange={e => setSearch(e.target.value)} style={{ maxWidth: 420 }} />
            </div>

            {error && <div className="auth-error">{error}</div>}

            {filtered.length === 0 ? (
                <div className="uc-card" style={{ textAlign: 'center', padding: 48 }}>
                    <div style={{ fontSize: 40, marginBottom: 12 }}>🔍</div>
                    <p style={{ fontWeight: 700, color: 'var(--uc-text-muted)' }}>No members found</p>
                </div>
            ) : (
                <div className="responsive-grid">
                    {filtered.map(user => (
                        <div key={user.id} className="uc-card" style={{ textAlign: 'center', padding: '28px 20px' }}>
                            <div className="avatar-squircle" style={{ width: 72, height: 72, margin: '0 auto 16px', fontSize: 30 }}>
                                {user.name.charAt(0).toUpperCase()}
                            </div>
                            <div style={{ fontWeight: 800, fontSize: 17, marginBottom: 4 }}>{user.name}</div>
                            <div style={{ fontSize: 13, color: 'var(--uc-primary)', fontWeight: 700, marginBottom: 18, minHeight: 20 }}>{user.department || 'University Member'}</div>
                            <button onClick={() => handleConnect(user.id)} className="uc-btn uc-btn-primary" style={{ width: '100%' }}>Connect</button>
                        </div>
                    ))}
                </div>
            )}
        </div>
    );
}