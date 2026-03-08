import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function CareersPage() {
    const [jobs, setJobs] = useState([]);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');
    const currentUserName = localStorage.getItem('userName');

    const [newJob, setNewJob] = useState({
        title: '', company: '', description: '', type: 'JOB'
    });

    const [selectedJob, setSelectedJob] = useState(null);
    const [applicationData, setApplicationData] = useState({ coverLetter: '', resumeUrl: '' });
    const [applyStatus, setApplyStatus] = useState('');

    const [jobApplicants, setJobApplicants] = useState({});
    const [expandedJobId, setExpandedJobId] = useState(null);

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) {
            navigate('/login');
            return;
        }
        fetchJobs();
    }, [navigate]);

    const fetchJobs = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get('/api/jobs', {
                headers: { Authorization: `Bearer ${token}` }
            });
            setJobs(response.data);
        } catch (err) {
            setError('Failed to load careers.');
        }
    };

    const handleCreateJob = async (e) => {
        e.preventDefault();
        const token = localStorage.getItem('token');
        try {
            await axios.post('/api/jobs', newJob, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setNewJob({ title: '', company: '', description: '', type: 'JOB' });
            fetchJobs();
        } catch (err) {
            setError("Failed to publish job posting.");
        }
    };

    const handleDeleteJob = async (jobId) => {
        if (!window.confirm("Delete this job posting?")) return;
        const token = localStorage.getItem('token');
        try {
            await axios.delete(`/api/jobs/${jobId}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchJobs();
        } catch (err) {
            console.error("Failed to delete job", err);
        }
    };

    const handleSubmitApplication = async (e) => {
        e.preventDefault();
        setApplyStatus('Submitting...');
        const token = localStorage.getItem('token');

        try {
            await axios.post(`/api/jobs/${selectedJob.id}/apply`, {
                coverLetter: applicationData.coverLetter,
                resumeUrl: applicationData.resumeUrl
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });

            setApplyStatus('success');
            setTimeout(() => {
                setSelectedJob(null);
                setApplyStatus('');
                setApplicationData({ coverLetter: '', resumeUrl: '' });
            }, 2000);

        } catch (err) {
            setApplyStatus('error');
        }
    };

    const handleToggleApplicants = async (jobId) => {
        if (expandedJobId === jobId) {
            setExpandedJobId(null);
            return;
        }

        const token = localStorage.getItem('token');
        try {
            const response = await axios.get(`/api/jobs/applications/job/${jobId}`, {
                headers: { Authorization: `Bearer ${token}` }
            });

            setJobApplicants({ ...jobApplicants, [jobId]: response.data });
            setExpandedJobId(jobId);
        } catch (err) {
            console.error("Failed to fetch applicants", err);
        }
    };

    return (
        <div className="container" style={{ maxWidth: '800px' }}>
            <h2 style={{ marginBottom: '25px' }}>Career Opportunities</h2>
            {error && <p style={{ color: 'var(--danger-color)', marginBottom: '15px' }}>{error}</p>}

            {!selectedJob && (
                <div className="card" style={{ border: '1px solid #dddfe2' }}>
                    <h3 style={{ marginBottom: '15px', color: 'var(--text-secondary)', fontSize: '1.2rem' }}>Post a New Opportunity</h3>
                    <form onSubmit={handleCreateJob}>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '15px', marginBottom: '15px' }}>
                            <div className="form-group">
                                <label className="label">Job Title</label>
                                <input required placeholder="e.g. Software Engineer" className="input" value={newJob.title} onChange={e => setNewJob({...newJob, title: e.target.value})} />
                            </div>
                            <div className="form-group">
                                <label className="label">Company Name</label>
                                <input required placeholder="e.g. Google" className="input" value={newJob.company} onChange={e => setNewJob({...newJob, company: e.target.value})} />
                            </div>
                        </div>
                        <div className="form-group">
                            <label className="label">Job Type</label>
                            <select value={newJob.type} className="select" onChange={e => setNewJob({...newJob, type: e.target.value})}>
                                <option value="JOB">Job (Full-Time / Part-Time)</option>
                                <option value="INTERNSHIP">Internship</option>
                            </select>
                        </div>
                        <div className="form-group" style={{ marginTop: '15px' }}>
                            <label className="label">Job Description</label>
                            <textarea required rows="4" className="textarea" placeholder="Describe the role and requirements..." value={newJob.description} onChange={e => setNewJob({...newJob, description: e.target.value})} />
                        </div>
                        <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '10px' }}>
                            <button type="submit" className="btn btn-primary" style={{ padding: '8px 24px' }}>Post Job</button>
                        </div>
                    </form>
                </div>
            )}

            <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                {jobs.map((job) => {
                    const isOwner = String(job.postedBy) === String(currentUserId);
                    return (
                        <div key={job.id} className="card" style={{ position: 'relative' }}>
                            {isOwner && (
                                <button onClick={() => handleDeleteJob(job.id)} className="btn btn-danger" style={{ position: 'absolute', top: '20px', right: '20px', padding: '5px 10px', fontSize: '0.8rem' }}>Delete</button>
                            )}
                            <div style={{ marginBottom: '15px' }}>
                                <h3 style={{ margin: '0 0 5px 0' }}>{job.title}</h3>
                                <div style={{ display: 'flex', gap: '10px', alignItems: 'center' }}>
                                    <span style={{ fontWeight: '600', color: 'var(--text-secondary)' }}>{job.company}</span>
                                    <span style={{ color: '#ccc' }}>•</span>
                                    <span className={`badge ${job.type === 'INTERNSHIP' ? 'badge-green' : 'badge-blue'}`}>{job.type}</span>
                                </div>
                            </div>
                            
                            <div style={{ fontSize: '1rem', lineHeight: '1.6', color: '#1c1e21', whiteSpace: 'pre-wrap', backgroundColor: '#f8f9fa', padding: '15px', borderRadius: '6px' }}>
                                {job.description}
                            </div>

                            <div style={{ marginTop: '20px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <button onClick={() => setSelectedJob(job)} className="btn btn-primary" style={{ borderRadius: '4px' }}>
                                    Apply Internally
                                </button>
                                <small style={{ color: 'var(--text-secondary)' }}>Posted by {job.postedBy}</small>
                            </div>

                            {isOwner && (
                                <div style={{ marginTop: '20px', paddingTop: '15px', borderTop: '1px solid #eee' }}>
                                    <button
                                        onClick={() => handleToggleApplicants(job.id)}
                                        className="btn btn-secondary"
                                        style={{ padding: '6px 15px', fontSize: '0.85rem' }}
                                    >
                                        {expandedJobId === job.id ? 'Hide Applicants' : 'View Applicants'}
                                    </button>

                                    {expandedJobId === job.id && (
                                        <div style={{ marginTop: '15px', backgroundColor: '#f8f9fa', padding: '15px', borderRadius: '8px', border: '1px solid #e9ecef' }}>
                                            <h4 style={{ margin: '0 0 15px 0', fontSize: '1.1rem' }}>Applicant Dashboard</h4>
                                            {(!jobApplicants[job.id] || jobApplicants[job.id].length === 0) ? (
                                                <p style={{ margin: 0, color: '#666', fontSize: '0.9em' }}>No applications yet.</p>
                                            ) : (
                                                jobApplicants[job.id].map(app => (
                                                    <div key={app.id} className="card" style={{ marginBottom: '10px', padding: '15px', boxShadow: 'none', border: '1px solid #eee' }}>
                                                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '8px' }}>
                                                            <strong style={{ fontSize: '1.05rem' }}>Applicant ID: {app.applicantId}</strong>
                                                            <span style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>
                                                                {new Date(app.submittedAt).toLocaleDateString()}
                                                            </span>
                                                        </div>
                                                        <p style={{ margin: '8px 0', fontSize: '0.95em', whiteSpace: 'pre-wrap' }}>
                                                            {app.coverLetter}
                                                        </p>
                                                        <a href={app.resumeUrl} target="_blank" rel="noopener noreferrer" style={{ fontSize: '0.9rem', color: 'var(--primary-color)', textDecoration: 'none', fontWeight: 'bold' }}>
                                                            📄 View Resume/Portfolio
                                                        </a>
                                                    </div>
                                                ))
                                            )}
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>
                    );
                })}
            </div>

            {selectedJob && (
                <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', backgroundColor: 'rgba(0,0,0,0.6)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
                    <div className="card" style={{ width: '90%', maxWidth: '500px', position: 'relative', padding: '30px' }}>
                        <button onClick={() => { setSelectedJob(null); setApplyStatus(''); }} style={{ position: 'absolute', top: '20px', right: '20px', border: 'none', background: 'none', fontSize: '1.5rem', cursor: 'pointer', color: '#999' }}>&times;</button>
                        <h3 style={{ margin: '0 0 8px 0' }}>Apply for {selectedJob.title}</h3>
                        <p style={{ color: 'var(--text-secondary)', marginBottom: '25px' }}>at {selectedJob.company}</p>

                        <form onSubmit={handleSubmitApplication} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                            <div className="form-group">
                                <label className="label">Cover Letter / Note</label>
                                <textarea
                                    required rows="5" placeholder="Why are you a good fit?"
                                    value={applicationData.coverLetter}
                                    className="textarea"
                                    onChange={e => setApplicationData({...applicationData, coverLetter: e.target.value})}
                                />
                            </div>
                            <div className="form-group">
                                <label className="label">Resume Link (Google Drive/Portfolio)</label>
                                <input
                                    required placeholder="https://..."
                                    value={applicationData.resumeUrl}
                                    className="input"
                                    onChange={e => setApplicationData({...applicationData, resumeUrl: e.target.value})}
                                />
                            </div>
                            <button type="submit" className="btn btn-primary" style={{ padding: '12px', marginTop: '10px' }}>
                                Submit Application
                            </button>
                        </form>
                        {applyStatus === 'success' && <p style={{ textAlign: 'center', marginTop: '15px', fontWeight: 'bold', color: 'var(--success-color)' }}>Application Submitted Successfully!</p>}
                        {applyStatus === 'error' && <p style={{ textAlign: 'center', marginTop: '15px', fontWeight: 'bold', color: 'var(--danger-color)' }}>Failed to submit application. Try again.</p>}
                    </div>
                </div>
            )}
        </div>
    );
}