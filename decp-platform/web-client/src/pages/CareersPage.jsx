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
        if (!localStorage.getItem('token')) { navigate('/login'); return; }
        fetchJobs();
    }, [navigate]);

    const authHeaders = () => ({ headers: { Authorization: `Bearer ${localStorage.getItem('token')}` } });

    const fetchJobs = async () => {
        try {
            const res = await axios.get('/api/jobs', authHeaders());
            setJobs(res.data);
        } catch { setError('Failed to load careers.'); }
    };

    const handleCreateJob = async (e) => {
        e.preventDefault();
        try { await axios.post('/api/jobs', newJob, authHeaders()); setNewJob({ title: '', company: '', description: '', type: 'JOB' }); fetchJobs(); }
        catch { setError('Failed to publish job.'); }
    };

    const handleDeleteJob = async (jobId) => {
        if (!window.confirm('Delete job?')) return;
        try { await axios.delete(`/api/jobs/${jobId}`, authHeaders()); fetchJobs(); }
        catch (err) { console.error(err); }
    };

    const handleSubmitApplication = async (e) => {
        e.preventDefault(); setApplyStatus('submitting');
        try {
            await axios.post(`/api/jobs/${selectedJob.id}/apply`, applicationData, authHeaders());
            setApplyStatus('success');
            setTimeout(() => { setSelectedJob(null); setApplyStatus(''); setApplicationData({ coverLetter: '', resumeUrl: '' }); }, 2000);
        } catch { setApplyStatus('error'); }
    };

    const handleToggleApplicants = async (jobId) => {
        if (expandedJobId === jobId) { setExpandedJobId(null); return; }
        try {
            const res = await axios.get(`/api/jobs/applications/job/${jobId}`, authHeaders());
            setJobApplicants({ ...jobApplicants, [jobId]: res.data }); setExpandedJobId(jobId);
        } catch (err) { console.error(err); }
    };

    return (
        <div className="main-layout">
            {/* ── Left Sidebar ── */}
            <aside className="sidebar-left">
                <div className="uc-card" style={{ padding: 24 }}>
                    <div style={{ fontWeight: 800, fontSize: 17, marginBottom: 20, color: 'var(--uc-primary)' }}>Career Center</div>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                        {['Saved Jobs', 'Applications', 'Interview Hub'].map(label => (
                            <div key={label} style={{ fontSize: 14, fontWeight: 600, cursor: 'pointer', color: 'var(--uc-text-muted)', transition: 'color .15s' }}>{label}</div>
                        ))}
                    </div>
                </div>
            </aside>

            {/* ── Main Content ── */}
            <main>
                {/* Job creation form — Alumni / Admin only */}
                {(role === 'ALUMNI' || role === 'ADMIN') && (
                    <div className="uc-card" style={{ padding: 24 }}>
                        <h3 style={{ fontSize: 18, fontWeight: 800, marginBottom: 18 }}>Post Opportunity</h3>
                        <form onSubmit={handleCreateJob} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                            <div style={{ display: 'grid', gridTemplateColumns: '1fr', gap: 14 }}>
                                <input required placeholder="Position Title" className="li-input" value={newJob.title} onChange={e => setNewJob({ ...newJob, title: e.target.value })} />
                                <input required placeholder="Company" className="li-input" value={newJob.company} onChange={e => setNewJob({ ...newJob, company: e.target.value })} />
                            </div>
                            <select value={newJob.type} className="li-input" onChange={e => setNewJob({ ...newJob, type: e.target.value })}>
                                <option value="JOB">Full-Time</option>
                                <option value="INTERNSHIP">Internship</option>
                            </select>
                            <textarea required rows="3" className="li-input" placeholder="Role description…" value={newJob.description} onChange={e => setNewJob({ ...newJob, description: e.target.value })} style={{ resize: 'none' }} />
                            <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                                <button type="submit" className="uc-btn uc-btn-primary">Post Opportunity</button>
                            </div>
                        </form>
                    </div>
                )}

                {/* Job List */}
                <h3 style={{ fontSize: 18, fontWeight: 800, margin: '8px 0 16px' }}>Latest Openings</h3>

                <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                    {jobs.map((job) => {
                        const isOwner = String(job.postedBy) === String(currentUserId);
                        return (
                            <div key={job.id} className="uc-card" style={{ padding: 0 }}>
                                <div style={{ padding: '20px' }}>
                                    <div style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
                                        <div className="avatar-squircle" style={{ width: 56, height: 56, fontSize: 22, background: '#f1f5f9', color: 'var(--uc-primary)', flexShrink: 0 }}>
                                            {job.company.charAt(0).toUpperCase()}
                                        </div>
                                        <div style={{ flex: 1, minWidth: 0 }}>
                                            <div style={{ fontSize: 17, fontWeight: 800 }}>{job.title}</div>
                                            <div style={{ fontSize: 14, color: 'var(--uc-primary)', fontWeight: 700, marginTop: 2 }}>{job.company}</div>
                                            <div style={{ display: 'flex', gap: 8, marginTop: 10, flexWrap: 'wrap', alignItems: 'center' }}>
                                                <span className={`badge ${job.type === 'INTERNSHIP' ? 'badge-green' : 'badge-blue'}`}>{job.type}</span>
                                                <span style={{ fontSize: 12, color: 'var(--uc-text-muted)' }}>Posted {new Date(job.createdAt).toLocaleDateString()}</span>
                                            </div>
                                            <div style={{ marginTop: 16, fontSize: 14, lineHeight: 1.7, color: 'var(--uc-text-secondary)' }}>{job.description}</div>

                                            <div style={{ marginTop: 20, display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                                                <button onClick={() => setSelectedJob(job)} className="uc-btn uc-btn-primary" style={{ padding: '8px 20px' }}>Apply Now</button>
                                                {isOwner && <button onClick={() => handleToggleApplicants(job.id)} className="uc-btn uc-btn-outline" style={{ padding: '8px 18px' }}>{expandedJobId === job.id ? 'Hide Applicants' : 'Review Applicants'}</button>}
                                                {isOwner && <button onClick={() => handleDeleteJob(job.id)} className="uc-btn uc-btn-danger" style={{ padding: '8px 16px' }}>Delete</button>}
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                {/* Applicant list */}
                                {expandedJobId === job.id && (
                                    <div style={{ padding: '16px 20px 20px', background: 'var(--uc-bg)', borderTop: '1px solid var(--uc-border)' }}>
                                        <h4 style={{ marginBottom: 14, fontSize: 14, fontWeight: 800 }}>Applicant Tracking</h4>
                                        {(!jobApplicants[job.id] || jobApplicants[job.id].length === 0) ? (
                                            <p style={{ fontSize: 13, color: 'var(--uc-text-muted)' }}>No applications received yet.</p>
                                        ) : (
                                            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
                                                {jobApplicants[job.id].map(app => (
                                                    <div key={app.id} style={{ padding: 16, background: 'var(--uc-surface)', borderRadius: 'var(--uc-radius-sm)', border: '1px solid var(--uc-border)' }}>
                                                        <div style={{ fontWeight: 700, fontSize: 14 }}>Applicant #{app.applicantId}</div>
                                                        <div style={{ fontSize: 13, marginTop: 6, color: 'var(--uc-text-secondary)', lineHeight: 1.5 }}>{app.coverLetter}</div>
                                                        <a href={app.resumeUrl} target="_blank" rel="noopener noreferrer" style={{ fontSize: 13, color: 'var(--uc-primary)', fontWeight: 700, display: 'inline-block', marginTop: 10 }}>View Document ↗</a>
                                                    </div>
                                                ))}
                                            </div>
                                        )}
                                    </div>
                                )}
                            </div>
                        );
                    })}

                    {jobs.length === 0 && (
                        <div className="uc-card" style={{ padding: 40, textAlign: 'center', color: 'var(--uc-text-muted)' }}>
                            <div style={{ fontSize: 40, marginBottom: 12 }}>💼</div>
                            <div style={{ fontWeight: 700, fontSize: 16 }}>No openings yet</div>
                            <div style={{ fontSize: 14, marginTop: 4 }}>Check back soon for new opportunities!</div>
                        </div>
                    )}
                </div>
            </main>

            {/* ── Application Modal ── */}
            {selectedJob && (
                <div className="modal-overlay" onClick={(e) => { if (e.target === e.currentTarget) setSelectedJob(null); }}>
                    <div className="uc-card modal-card">
                        <button onClick={() => setSelectedJob(null)} className="modal-close">&times;</button>
                        <h2 style={{ fontSize: 22, fontWeight: 800, marginBottom: 4 }}>Internal Application</h2>
                        <p style={{ fontSize: 15, color: 'var(--uc-primary)', fontWeight: 700, marginBottom: 28 }}>{selectedJob.title} at {selectedJob.company}</p>

                        <form onSubmit={handleSubmitApplication} style={{ display: 'flex', flexDirection: 'column', gap: 18 }}>
                            <div>
                                <label className="form-label">Cover Letter</label>
                                <textarea required rows="5" className="li-input" value={applicationData.coverLetter} onChange={e => setApplicationData({ ...applicationData, coverLetter: e.target.value })} />
                            </div>
                            <div>
                                <label className="form-label">Portfolio / Resume Link</label>
                                <input required className="li-input" value={applicationData.resumeUrl} onChange={e => setApplicationData({ ...applicationData, resumeUrl: e.target.value })} />
                            </div>
                            <button type="submit" className="uc-btn uc-btn-primary" style={{ width: '100%', padding: 14 }}>
                                {applyStatus === 'submitting' ? 'Sending…' : 'Submit Application'}
                            </button>
                        </form>
                        {applyStatus === 'success' && <p style={{ marginTop: 18, color: 'var(--uc-success)', textAlign: 'center', fontWeight: 700 }}>Application sent successfully!</p>}
                    </div>
                </div>
            )}
        </div>
    );
}