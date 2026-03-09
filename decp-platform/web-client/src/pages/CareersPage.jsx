import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function CareersPage() {
    const [jobs, setJobs] = useState([]);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');
    const role = localStorage.getItem('role');

    const [newJob, setNewJob] = useState({ title: '', company: '', description: '', type: 'JOB' });
    const [selectedJob, setSelectedJob] = useState(null);
    const [applicationData, setApplicationData] = useState({ coverLetter: '', resumeUrl: '' });
    const [applyStatus, setApplyStatus] = useState('');
    const [jobApplicants, setJobApplicants] = useState({});
    const [expandedJobId, setExpandedJobId] = useState(null);

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) { navigate('/login'); return; }
        fetchJobs();
    }, [navigate]);

    const fetchJobs = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get('/api/jobs', { headers: { Authorization: `Bearer ${token}` } });
            setJobs(response.data);
        } catch (err) { setError('Failed to load careers.'); }
    };

    const handleCreateJob = async (e) => {
        e.preventDefault();
        const token = localStorage.getItem('token');
        try {
            await axios.post('/api/jobs', newJob, { headers: { Authorization: `Bearer ${token}` } });
            setNewJob({ title: '', company: '', description: '', type: 'JOB' });
            fetchJobs();
        } catch (err) { setError("Failed to publish job."); }
    };

    const handleDeleteJob = async (jobId) => {
        if (!window.confirm("Delete job?")) return;
        const token = localStorage.getItem('token');
        try {
            await axios.delete(`/api/jobs/${jobId}`, { headers: { Authorization: `Bearer ${token}` } });
            fetchJobs();
        } catch (err) { console.error(err); }
    };

    const handleSubmitApplication = async (e) => {
        e.preventDefault();
        setApplyStatus('submitting');
        const token = localStorage.getItem('token');
        try {
            await axios.post(`/api/jobs/${selectedJob.id}/apply`, applicationData, { headers: { Authorization: `Bearer ${token}` } });
            setApplyStatus('success');
            setTimeout(() => { setSelectedJob(null); setApplyStatus(''); setApplicationData({ coverLetter: '', resumeUrl: '' }); }, 2000);
        } catch (err) { setApplyStatus('error'); }
    };

    const handleToggleApplicants = async (jobId) => {
        if (expandedJobId === jobId) { setExpandedJobId(null); return; }
        const token = localStorage.getItem('token');
        try {
            const response = await axios.get(`/api/jobs/applications/job/${jobId}`, { headers: { Authorization: `Bearer ${token}` } });
            setJobApplicants({ ...jobApplicants, [jobId]: response.data });
            setExpandedJobId(jobId);
        } catch (err) { console.error(err); }
    };

    return (
        <div className="main-layout">
            <aside className="sidebar-left">
                <div className="uc-card" style={{ padding: '24px' }}>
                    <div style={{ fontWeight: '800', fontSize: '18px', marginBottom: '20px', color: 'var(--uc-primary)' }}>Career Center</div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <div style={{ fontSize: '14px', fontWeight: '600', cursor: 'pointer', color: 'var(--uc-text-muted)' }}>Saved Jobs</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', cursor: 'pointer', color: 'var(--uc-text-muted)' }}>Applications</div>
                        <div style={{ fontSize: '14px', fontWeight: '600', cursor: 'pointer', color: 'var(--uc-text-muted)' }}>Interview Hub</div>
                    </div>
                </div>
            </aside>

            <main>
                {(role === 'ALUMNI' || role === 'ADMIN') && (
                    <div className="uc-card" style={{ padding: '24px' }}>
                        <h3 style={{ fontSize: '20px', fontWeight: '800', marginBottom: '20px' }}>Post Opportunity</h3>
                        <form onSubmit={handleCreateJob} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '16px' }}>
                                <input required placeholder="Position Title" className="li-input" value={newJob.title} onChange={e => setNewJob({...newJob, title: e.target.value})} style={{ borderRadius: '12px' }} />
                                <input required placeholder="Company" className="li-input" value={newJob.company} onChange={e => setNewJob({...newJob, company: e.target.value})} style={{ borderRadius: '12px' }} />
                            </div>
                            <select value={newJob.type} className="li-input" onChange={e => setNewJob({...newJob, type: e.target.value})} style={{ borderRadius: '12px', appearance: 'none', background: 'white' }}>
                                <option value="JOB">Full-Time</option>
                                <option value="INTERNSHIP">Internship</option>
                            </select>
                            <textarea required rows="3" className="li-input" placeholder="Role description..." value={newJob.description} onChange={e => setNewJob({...newJob, description: e.target.value})} style={{ borderRadius: '12px', resize: 'none' }} />
                            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                                <button type="submit" className="uc-btn uc-btn-primary">Post Opportunity</button>
                            </div>
                        </form>
                    </div>
                )}

                <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                    <h3 style={{ fontSize: '20px', fontWeight: '800', margin: '8px 0' }}>Latest Openings</h3>
                    {jobs.map((job) => {
                        const isOwner = String(job.postedBy) === String(currentUserId);
                        return (
                            <div key={job.id} className="uc-card" style={{ padding: '24px' }}>
                                <div style={{ display: 'flex', gap: '20px' }}>
                                    <div className="avatar-squircle" style={{ width: '64px', height: '64px', fontSize: '24px', flexShrink: 0, background: '#f1f5f9', color: 'var(--uc-primary)' }}>
                                        {job.company.charAt(0).toUpperCase()}
                                    </div>
                                    <div style={{ flex: 1 }}>
                                        <div style={{ fontSize: '18px', fontWeight: '800', color: 'var(--uc-text-main)' }}>{job.title}</div>
                                        <div style={{ fontSize: '15px', color: 'var(--uc-primary)', fontWeight: '700', marginTop: '2px' }}>{job.company}</div>
                                        <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
                                            <span className={`badge ${job.type === 'INTERNSHIP' ? 'badge-green' : 'badge-blue'}`}>{job.type}</span>
                                            <span style={{ fontSize: '12px', color: 'var(--uc-text-muted)', display: 'flex', alignItems: 'center' }}>Posted {new Date(job.createdAt).toLocaleDateString()}</span>
                                        </div>
                                        
                                        <div style={{ marginTop: '20px', fontSize: '14px', lineHeight: '1.6', color: 'var(--uc-text-main)' }}>{job.description}</div>
                                        
                                        <div style={{ marginTop: '24px', display: 'flex', gap: '12px' }}>
                                            <button onClick={() => setSelectedJob(job)} className="uc-btn uc-btn-primary">Apply Now</button>
                                            {isOwner && (
                                                <button onClick={() => handleToggleApplicants(job.id)} className="uc-btn uc-btn-outline">
                                                    {expandedJobId === job.id ? 'Hide Applicants' : 'Review Applicants'}
                                                </button>
                                            )}
                                            {isOwner && <button onClick={() => handleDeleteJob(job.id)} className="li-btn li-btn-ghost" style={{ color: '#f43f5e' }}>Delete</button>}
                                        </div>

                                        {expandedJobId === job.id && (
                                            <div style={{ marginTop: '24px', padding: '20px', background: '#f8fafc', borderRadius: '16px', border: '1px solid var(--uc-border)' }}>
                                                <h4 style={{ margin: '0 0 16px 0', fontSize: '15px', fontWeight: '800' }}>Applicant Tracking</h4>
                                                {(!jobApplicants[job.id] || jobApplicants[job.id].length === 0) ? (
                                                    <p style={{ fontSize: '13px', color: 'var(--uc-text-muted)' }}>No applications received yet.</p>
                                                ) : (
                                                    <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                                                        {jobApplicants[job.id].map(app => (
                                                            <div key={app.id} style={{ padding: '16px', background: 'white', borderRadius: '12px', border: '1px solid var(--uc-border)' }}>
                                                                <div style={{ fontWeight: '700', fontSize: '14px' }}>Applicant #{app.applicantId}</div>
                                                                <div style={{ fontSize: '13px', marginTop: '8px', color: 'var(--uc-text-main)' }}>{app.coverLetter}</div>
                                                                <a href={app.resumeUrl} target="_blank" rel="noopener noreferrer" style={{ fontSize: '13px', color: 'var(--uc-primary)', textDecoration: 'none', fontWeight: '700', display: 'inline-block', marginTop: '12px' }}>View Document ↗</a>
                                                            </div>
                                                        ))}
                                                    </div>
                                                )}
                                            </div>
                                        )}
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            </main>

            {selectedJob && (
                <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', background: 'rgba(15, 23, 42, 0.6)', backdropFilter: 'blur(4px)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 2000 }}>
                    <div className="uc-card" style={{ width: '90%', maxWidth: '500px', padding: '32px', position: 'relative' }}>
                        <button onClick={() => setSelectedJob(null)} style={{ position: 'absolute', right: '24px', top: '24px', background: 'none', border: 'none', fontSize: '24px', cursor: 'pointer', color: 'var(--uc-text-muted)' }}>&times;</button>
                        <h2 style={{ fontSize: '24px', fontWeight: '800', marginBottom: '8px' }}>Internal Application</h2>
                        <p style={{ fontSize: '15px', color: 'var(--uc-primary)', fontWeight: '700', marginBottom: '32px' }}>{selectedJob.title} at {selectedJob.company}</p>
                        
                        <form onSubmit={handleSubmitApplication} style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                            <div>
                                <label style={{ fontSize: '13px', fontWeight: '700', display: 'block', marginBottom: '8px', textTransform: 'uppercase' }}>Cover Letter</label>
                                <textarea required rows="5" className="li-input" value={applicationData.coverLetter} onChange={e => setApplicationData({...applicationData, coverLetter: e.target.value})} style={{ borderRadius: '12px' }} />
                            </div>
                            <div>
                                <label style={{ fontSize: '13px', fontWeight: '700', display: 'block', marginBottom: '8px', textTransform: 'uppercase' }}>Portfolio/Resume Link</label>
                                <input required className="li-input" value={applicationData.resumeUrl} onChange={e => setApplicationData({...applicationData, resumeUrl: e.target.value})} style={{ borderRadius: '12px' }} />
                            </div>
                            <button type="submit" className="uc-btn uc-btn-primary" style={{ padding: '14px' }}>
                                {applyStatus === 'submitting' ? 'Sending...' : 'Submit Application'}
                            </button>
                        </form>
                        {applyStatus === 'success' && <p style={{ marginTop: '20px', color: '#16a34a', textAlign: 'center', fontWeight: '700' }}>Application sent successfully!</p>}
                    </div>
                </div>
            )}
        </div>
    );
}