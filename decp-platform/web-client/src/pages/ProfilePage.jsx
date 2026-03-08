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
        if (!token) {
            navigate('/login');
            return;
        }
        fetchProfile();
    }, [navigate]);

    const fetchProfile = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get(`/api/users/${currentUserId}/profile`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setProfile(response.data);
            setFormData({
                name: response.data.name || '',
                bio: response.data.bio || '',
                department: response.data.department || '',
                graduationYear: response.data.graduationYear || '',
                researchInterests: response.data.researchInterests || '[]',
                courseProjects: response.data.courseProjects || '[]'
            });
        } catch (err) {
            setError('Failed to load profile.');
        }
    };

    const handleUpdate = async (e) => {
        e.preventDefault();
        setError('');
        setMessage('');
        try {
            const token = localStorage.getItem('token');
            const response = await axios.put(`/api/users/${currentUserId}/profile`, formData, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setProfile(response.data);
            setIsEditing(false);
            setMessage('Profile updated successfully!');
            localStorage.setItem('userName', response.data.name);
        } catch (err) {
            setError('Failed to update profile.');
        }
    };

    if (!profile) return (
        <div className="container" style={{ display: 'flex', justifyContent: 'center', marginTop: '100px' }}>
            <p style={{ color: 'var(--text-secondary)' }}>Loading your profile...</p>
        </div>
    );

    return (
        <div className="container" style={{ maxWidth: '600px' }}>
            <h2 style={{ marginBottom: '25px' }}>Member Profile</h2>
            
            {error && <p style={{ color: 'var(--danger-color)', marginBottom: '15px' }}>{error}</p>}
            {message && <p style={{ color: 'var(--success-color)', marginBottom: '15px', fontWeight: 'bold' }}>{message}</p>}

            {!isEditing ? (
                <div className="card">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '20px', marginBottom: '25px', paddingBottom: '20px', borderBottom: '1px solid #eee' }}>
                        <div style={{ 
                            width: '80px', height: '80px', backgroundColor: 'var(--primary-color)', 
                            color: 'white', borderRadius: '50%', display: 'flex', 
                            alignItems: 'center', justifyContent: 'center', fontWeight: 'bold', fontSize: '2rem' 
                        }}>
                            {profile.name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                            <h2 style={{ margin: '0 0 5px 0' }}>{profile.name}</h2>
                            <span className="badge badge-blue">{profile.role}</span>
                        </div>
                    </div>

                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '20px', marginBottom: '20px' }}>
                        <div>
                            <label className="label">University Email</label>
                            <p style={{ margin: '5px 0', fontSize: '1.05rem', fontWeight: '500' }}>{profile.email}</p>
                        </div>
                        <div>
                            <label className="label">Department</label>
                            <p style={{ margin: '5px 0', fontSize: '1.05rem', fontWeight: '500' }}>{profile.department || 'Not specified'}</p>
                        </div>
                        <div>
                            <label className="label">Graduation Year</label>
                            <p style={{ margin: '5px 0', fontSize: '1.05rem', fontWeight: '500' }}>{profile.graduationYear || 'Not specified'}</p>
                        </div>
                        <div>
                            <label className="label">Member Since</label>
                            <p style={{ margin: '5px 0', fontSize: '1.05rem', fontWeight: '500' }}>{new Date(profile.createdAt).toLocaleDateString()}</p>
                        </div>
                    </div>

                    <div style={{ marginBottom: '25px' }}>
                        <label className="label">Biography</label>
                        <p style={{ margin: '8px 0', fontSize: '1.05rem', lineHeight: '1.6', whiteSpace: 'pre-wrap' }}>
                            {profile.bio || 'No bio provided yet. Tell the department a bit about yourself!'}
                        </p>
                    </div>

                    <button onClick={() => setIsEditing(true)} className="btn btn-primary" style={{ width: '100%', padding: '12px' }}>
                        Edit My Profile
                    </button>
                </div>
            ) : (
                <div className="card">
                    <h3 style={{ marginBottom: '20px' }}>Edit Profile Information</h3>
                    <form onSubmit={handleUpdate} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                        <div className="form-group">
                            <label className="label">Full Name</label>
                            <input type="text" className="input" value={formData.name} onChange={e => setFormData({...formData, name: e.target.value})} required />
                        </div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px' }}>
                            <div className="form-group">
                                <label className="label">Department</label>
                                <input type="text" className="input" value={formData.department} onChange={e => setFormData({...formData, department: e.target.value})} placeholder="e.g. Computer Engineering" />
                            </div>
                            <div className="form-group">
                                <label className="label">Graduation Year</label>
                                <input type="number" className="input" value={formData.graduationYear} onChange={e => setFormData({...formData, graduationYear: e.target.value})} placeholder="e.g. 2024" />
                            </div>
                        </div>
                        <div className="form-group">
                            <label className="label">Biography</label>
                            <textarea className="textarea" value={formData.bio} onChange={e => setFormData({...formData, bio: e.target.value})} rows="5" placeholder="Tell us about your background, interests, and goals..." />
                        </div>
                        <div style={{ display: 'flex', gap: '10px', marginTop: '10px' }}>
                            <button type="submit" className="btn btn-primary" style={{ flex: 1, padding: '12px' }}>Save Changes</button>
                            <button type="button" onClick={() => setIsEditing(false)} className="btn btn-secondary" style={{ padding: '12px 24px' }}>Cancel</button>
                        </div>
                    </form>
                </div>
            )}
        </div>
    );
}