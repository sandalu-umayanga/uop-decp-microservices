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
        const token = localStorage.getItem('token');
        if (!token) { navigate('/login'); return; }
        fetchProfile();
    }, [navigate]);

    const fetchProfile = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get(`/api/users/${currentUserId}/profile`, { headers: { Authorization: `Bearer ${token}` } });
            setProfile(response.data);
            setFormData({
                name: response.data.name || '',
                bio: response.data.bio || '',
                department: response.data.department || '',
                graduationYear: response.data.graduationYear || ''
            });
        } catch (err) { setError('Failed to load profile.'); }
    };

    const handleUpdate = async (e) => {
        e.preventDefault();
        setError('');
        setMessage('');
        try {
            const token = localStorage.getItem('token');
            const response = await axios.put(`/api/users/${currentUserId}/profile`, formData, { headers: { Authorization: `Bearer ${token}` } });
            setProfile(response.data);
            setIsEditing(false);
            setMessage('Profile updated successfully!');
            localStorage.setItem('userName', response.data.name);
        } catch (err) { setError('Failed to update profile.'); }
    };

    if (!profile) return <div className="main-layout" style={{ justifyContent: 'center', marginTop: '100px' }}><p>Loading profile...</p></div>;

    return (
        <div className="main-layout" style={{ gridTemplateColumns: '1fr 320px' }}>
            <main>
                <div className="uc-card" style={{ position: 'relative', padding: '0' }}>
                    <div style={{ height: '200px', background: 'linear-gradient(135deg, var(--uc-primary) 0%, #a855f7 100%)' }}></div>
                    <div style={{ padding: '0 32px 32px' }}>
                        <div className="avatar-squircle" style={{ width: '160px', height: '160px', border: '6px solid white', background: '#fff', marginTop: '-80px', fontSize: '64px', boxShadow: '0 10px 25px rgba(0,0,0,0.1)' }}>
                            {profile.name.charAt(0).toUpperCase()}
                        </div>
                        <div style={{ marginTop: '24px', display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', flexWrap: 'wrap', gap: '20px' }}>
                            <div>
                                <h1 style={{ fontSize: '32px', fontWeight: '800', marginBottom: '4px', letterSpacing: '-1px' }}>{profile.name}</h1>
                                <p style={{ fontSize: '18px', color: 'var(--uc-primary)', fontWeight: '700', marginBottom: '8px' }}>{profile.department || 'Add department'}</p>
                                <div style={{ display: 'flex', gap: '20px', alignItems: 'center' }}>
                                    <span style={{ fontSize: '14px', color: 'var(--uc-text-muted)', fontWeight: '600' }}>🎓 Class of {profile.graduationYear || '...'}</span>
                                    <span style={{ color: '#cbd5e1' }}>•</span>
                                    <span style={{ fontSize: '14px', color: 'var(--uc-primary)', fontWeight: '700' }}>{profile.connections} Connections</span>
                                </div>
                            </div>
                            <div style={{ display: 'flex', gap: '12px' }}>
                                <button onClick={() => setIsEditing(true)} className="uc-btn uc-btn-primary">Edit Profile</button>
                                <button className="uc-btn uc-btn-outline">Share</button>
                            </div>
                        </div>
                    </div>
                </div>

                <div className="uc-card" style={{ padding: '32px' }}>
                    <h2 style={{ fontSize: '20px', fontWeight: '800', marginBottom: '16px', color: 'var(--uc-text-main)' }}>Biography</h2>
                    <p style={{ fontSize: '16px', lineHeight: '1.7', color: 'var(--uc-text-main)', whiteSpace: 'pre-wrap' }}>
                        {profile.bio || 'Tell the community about your journey and goals...'}
                    </p>
                </div>

                {isEditing && (
                    <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', background: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(4px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2000 }}>
                        <div className="uc-card" style={{ width: '90%', maxWidth: '600px', padding: '32px', position: 'relative' }}>
                            <button onClick={() => setIsEditing(false)} style={{ position: 'absolute', right: '24px', top: '24px', background: 'none', border: 'none', fontSize: '24px', cursor: 'pointer', color: 'var(--uc-text-muted)' }}>&times;</button>
                            <h2 style={{ fontSize: '24px', fontWeight: '800', marginBottom: '32px' }}>Update Intro</h2>
                            <form onSubmit={handleUpdate} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                                <div>
                                    <label style={{ fontSize: '13px', fontWeight: '700', display: 'block', marginBottom: '8px', textTransform: 'uppercase' }}>Display Name</label>
                                    <input type="text" className="li-input" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} required style={{ borderRadius: '12px' }} />
                                </div>
                                <div style={{ display: 'flex', gap: '16px' }}>
                                    <div style={{ flex: 1 }}>
                                        <label style={{ fontSize: '13px', fontWeight: '700', display: 'block', marginBottom: '8px', textTransform: 'uppercase' }}>Department</label>
                                        <input type="text" className="li-input" value={formData.department} onChange={e => setFormData({...formData, department: e.target.value})} style={{ borderRadius: '12px' }} />
                                    </div>
                                    <div style={{ flex: 1 }}>
                                        <label style={{ fontSize: '13px', fontWeight: '700', display: 'block', marginBottom: '8px', textTransform: 'uppercase' }}>Graduation Year</label>
                                        <input type="number" className="li-input" value={formData.graduationYear} onChange={e => setFormData({...formData, graduationYear: e.target.value})} style={{ borderRadius: '12px' }} />
                                    </div>
                                </div>
                                <div>
                                    <label style={{ fontSize: '13px', fontWeight: '700', display: 'block', marginBottom: '8px', textTransform: 'uppercase' }}>Short Bio</label>
                                    <textarea rows="5" className="li-input" value={formData.bio} onChange={e => setFormData({...formData, bio: e.target.value})} style={{ borderRadius: '12px' }} />
                                </div>
                                <button type="submit" className="uc-btn uc-btn-primary" style={{ padding: '14px' }}>Save Changes</button>
                            </form>
                        </div>
                    </div>
                )}
            </main>

            <aside className="sidebar-right">
                <div className="uc-card" style={{ padding: '24px' }}>
                    <div style={{ fontWeight: '800', fontSize: '16px', marginBottom: '16px' }}>Analytics</div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <div>
                            <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--uc-primary)' }}>{profile.profileViews}</div>
                            <div style={{ fontSize: '13px', color: 'var(--uc-text-muted)', fontWeight: '600' }}>Profile Views</div>
                        </div>
                        <div>
                            <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--uc-primary)' }}>{profile.connections}</div>
                            <div style={{ fontSize: '13px', color: 'var(--uc-text-muted)', fontWeight: '600' }}>Professional Connections</div>
                        </div>
                    </div>
                </div>
            </aside>
        </div>
    );
}