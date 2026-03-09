import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function ProfilePage() {
    const [profile, setProfile] = useState(null);
    const [isEditing, setIsEditing] = useState(false);
    const [formData, setFormData] = useState({});
    const [error, setError] = useState('');
    const [message, setMessage] = useState('');
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');

    useEffect(() => {
        if (!localStorage.getItem('token')) { navigate('/login'); return; }
        fetchProfile();
    }, [navigate]);

    const authHeaders = () => ({ headers: { Authorization: `Bearer ${localStorage.getItem('token')}` } });

    const fetchProfile = async () => {
        try {
            const res = await axios.get(`/api/users/${currentUserId}/profile`, authHeaders());
            setProfile(res.data);
            setFormData({ name: res.data.name || '', bio: res.data.bio || '', department: res.data.department || '', graduationYear: res.data.graduationYear || '' });
        } catch { setError('Failed to load profile.'); }
    };

    const handleUpdate = async (e) => {
        e.preventDefault(); setError(''); setMessage('');
        try {
            const res = await axios.put(`/api/users/${currentUserId}/profile`, formData, authHeaders());
            setProfile(res.data); setIsEditing(false); setMessage('Profile updated successfully!');
            localStorage.setItem('userName', res.data.name);
        } catch { setError('Failed to update profile.'); }
    };

    if (!profile) return (
        <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', minHeight: '60vh' }}>
            <div className="uc-card" style={{ padding: 40, textAlign: 'center', minWidth: 200 }}>
                <div className="skeleton" style={{ width: 80, height: 80, borderRadius: '28%', margin: '0 auto 16px' }} />
                <div className="skeleton" style={{ width: 160, height: 20, margin: '0 auto 8px' }} />
                <div className="skeleton" style={{ width: 120, height: 14, margin: '0 auto' }} />
            </div>
        </div>
    );

    return (
        <div className="profile-layout">
            <main>
                {/* Profile Header Card */}
                <div className="uc-card" style={{ padding: 0 }}>
                    <div className="profile-banner" />
                    <div style={{ padding: '0 20px 28px' }}>
                        <div className="avatar-squircle" style={{ width: 100, height: 100, border: '5px solid white', marginTop: -50, fontSize: 42, boxShadow: 'var(--uc-shadow-lg)' }}>
                            {profile.name.charAt(0).toUpperCase()}
                        </div>
                        <div style={{ marginTop: 16 }}>
                            <h1 style={{ fontSize: 26, fontWeight: 800, letterSpacing: '-0.5px', marginBottom: 4 }}>{profile.name}</h1>
                            <p style={{ fontSize: 16, color: 'var(--uc-primary)', fontWeight: 700, marginBottom: 8 }}>{profile.department || 'Add department'}</p>
                            <div style={{ display: 'flex', gap: 16, alignItems: 'center', flexWrap: 'wrap', fontSize: 14, color: 'var(--uc-text-muted)', fontWeight: 600 }}>
                                <span>🎓 Class of {profile.graduationYear || '…'}</span>
                                <span style={{ color: 'var(--uc-border)' }}>•</span>
                                <span style={{ color: 'var(--uc-primary)', fontWeight: 700 }}>{profile.connections} Connections</span>
                            </div>
                        </div>
                        <div style={{ display: 'flex', gap: 10, marginTop: 20, flexWrap: 'wrap' }}>
                            <button onClick={() => setIsEditing(true)} className="uc-btn uc-btn-primary">Edit Profile</button>
                            <button className="uc-btn uc-btn-outline">Share</button>
                        </div>
                    </div>
                </div>

                {/* Bio Card */}
                <div className="uc-card" style={{ padding: '24px 20px' }}>
                    <h2 style={{ fontSize: 18, fontWeight: 800, marginBottom: 12 }}>Biography</h2>
                    <p style={{ fontSize: 15, lineHeight: 1.7, whiteSpace: 'pre-wrap', color: profile.bio ? 'var(--uc-text-secondary)' : 'var(--uc-text-muted)' }}>
                        {profile.bio || 'Tell the community about your journey and goals…'}
                    </p>
                </div>

                {message && <div className="auth-success" style={{ marginBottom: 20 }}>{message}</div>}

                {/* Edit Modal */}
                {isEditing && (
                    <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setIsEditing(false); }}>
                        <div className="uc-card modal-card">
                            <button onClick={() => setIsEditing(false)} className="modal-close">&times;</button>
                            <h2 style={{ fontSize: 22, fontWeight: 800, marginBottom: 28 }}>Update Intro</h2>
                            <form onSubmit={handleUpdate} style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                                <div>
                                    <label className="form-label">Display Name</label>
                                    <input type="text" className="li-input" value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} required />
                                </div>
                                <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 14 }}>
                                    <div>
                                        <label className="form-label">Department</label>
                                        <input type="text" className="li-input" value={formData.department} onChange={e => setFormData({ ...formData, department: e.target.value })} />
                                    </div>
                                    <div>
                                        <label className="form-label">Graduation Year</label>
                                        <input type="number" className="li-input" value={formData.graduationYear} onChange={e => setFormData({ ...formData, graduationYear: e.target.value })} />
                                    </div>
                                </div>
                                <div>
                                    <label className="form-label">Short Bio</label>
                                    <textarea rows="5" className="li-input" value={formData.bio} onChange={e => setFormData({ ...formData, bio: e.target.value })} />
                                </div>
                                <button type="submit" className="uc-btn uc-btn-primary" style={{ width: '100%', padding: 14 }}>Save Changes</button>
                            </form>
                        </div>
                    </div>
                )}
            </main>

            {/* Right Sidebar — Analytics */}
            <aside>
                <div className="uc-card" style={{ padding: 24 }}>
                    <div style={{ fontWeight: 800, fontSize: 15, marginBottom: 18 }}>Analytics</div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                        <div>
                            <div className="stat-value">{profile.profileViews}</div>
                            <div className="stat-label">Profile Views</div>
                        </div>
                        <div>
                            <div className="stat-value">{profile.connections}</div>
                            <div className="stat-label">Professional Connections</div>
                        </div>
                    </div>
                </div>
            </aside>
        </div>
    );
}