import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function CareersPage() {
    const [jobs, setJobs] = useState([]);
    const [error, setError] = useState('');
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');
    const currentUserName = localStorage.getItem('userName');

    // Job Posting State
    const [newJob, setNewJob] = useState({
        title: '', company: '', description: '', location: '', employmentType: 'Full-Time', applyLink: ''
    });

    // Application Modal State
    const [selectedJob, setSelectedJob] = useState(null);
    const [applicationData, setApplicationData] = useState({ coverLetter: '', resumeLink: '' });
    const [applyStatus, setApplyStatus] = useState('');

    // --- NEW: ATS Dashboard State ---
    const [jobApplicants, setJobApplicants] = useState({}); // Stores applicants mapped by jobId
    const [expandedJobId, setExpandedJobId] = useState(null); // Tracks which job's applicants are visible

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
            const response = await axios.get('http://localhost:8080/api/careers', {
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
            await axios.post('http://localhost:8080/api/careers', {
                ...newJob,
                postedByUserId: currentUserId,
                postedByUserName: currentUserName
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setNewJob({ title: '', company: '', description: '', location: '', employmentType: 'Full-Time', applyLink: '' });
            fetchJobs();
        } catch (err) {
            setError("Failed to publish job posting.");
        }
    };

    const handleDeleteJob = async (jobId) => {
        if (!window.confirm("Delete this job posting?")) return;
        const token = localStorage.getItem('token');
        try {
            await axios.delete(`http://localhost:8080/api/careers/${jobId}`, {
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
            await axios.post('http://localhost:8080/api/careers/applications', {
                jobId: selectedJob.id,
                applicantId: currentUserId,
                applicantName: currentUserName,
                coverLetter: applicationData.coverLetter,
                resumeLink: applicationData.resumeLink
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });

            setApplyStatus('Application Submitted Successfully!');
            setTimeout(() => {
                setSelectedJob(null);
                setApplyStatus('');
                setApplicationData({ coverLetter: '', resumeLink: '' });
            }, 2000);

        } catch (err) {
            setApplyStatus('Failed to submit application. Try again.');
        }
    };

    // --- NEW: Fetch and Toggle Applicants ---
    const handleToggleApplicants = async (jobId) => {
        // If it's already open, close it
        if (expandedJobId === jobId) {
            setExpandedJobId(null);
            return;
        }

        const token = localStorage.getItem('token');
        try {
            const response = await axios.get(`http://localhost:8080/api/careers/applications/job/${jobId}`, {
                headers: { Authorization: `Bearer ${token}` }
            });

            // Save the applicants into state and expand this job's dashboard
            setJobApplicants({ ...jobApplicants, [jobId]: response.data });
            setExpandedJobId(jobId);
        } catch (err) {
            console.error("Failed to fetch applicants", err);
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '800px', margin: '0 auto', position: 'relative' }}>
            <h2>Career Opportunities</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}

            {/* Post Job Form */}
            {!selectedJob && (
                <form onSubmit={handleCreateJob} style={{ marginBottom: '40px', padding: '20px', border: '1px solid #ccc', borderRadius: '8px', backgroundColor: '#f4f7f6' }}>
                    <h3>Post a New Opportunity</h3>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px', marginBottom: '10px' }}>
                        <input required placeholder="Job Title" value={newJob.title} onChange={e => setNewJob({...newJob, title: e.target.value})} style={{ padding: '8px' }} />
                        <input required placeholder="Company Name" value={newJob.company} onChange={e => setNewJob({...newJob, company: e.target.value})} style={{ padding: '8px' }} />
                        <input required placeholder="Location" value={newJob.location} onChange={e => setNewJob({...newJob, location: e.target.value})} style={{ padding: '8px' }} />
                        <select value={newJob.employmentType} onChange={e => setNewJob({...newJob, employmentType: e.target.value})} style={{ padding: '8px' }}>
                            <option value="Full-Time">Full-Time</option>
                            <option value="Internship">Internship</option>
                            <option value="Contract">Contract</option>
                        </select>
                    </div>
                    <textarea required rows="3" placeholder="Job Description..." value={newJob.description} onChange={e => setNewJob({...newJob, description: e.target.value})} style={{ width: '100%', padding: '8px', marginBottom: '10px', boxSizing: 'border-box' }} />
                    <button type="submit" style={{ padding: '10px 20px', backgroundColor: '#28a745', color: 'white', border: 'none', borderRadius: '5px', cursor: 'pointer' }}>Post Job</button>
                </form>
            )}

            {/* Job Listings */}
            <div style={{ display: 'flex', flexDirection: 'column', gap: '20px' }}>
                {jobs.map((job) => {
                    const isOwner = String(job.postedByUserId) === String(currentUserId);
                    return (
                        <div key={job.id} style={{ border: '1px solid #ddd', padding: '20px', borderRadius: '8px', position: 'relative', boxShadow: '0 2px 4px rgba(0,0,0,0.1)' }}>
                            {isOwner && (
                                <button onClick={() => handleDeleteJob(job.id)} style={{ position: 'absolute', top: '20px', right: '20px', backgroundColor: '#dc3545', color: 'white', border: 'none', borderRadius: '4px', padding: '5px 10px', cursor: 'pointer' }}>Delete</button>
                            )}
                            <h3 style={{ margin: '0 0 5px 0', color: '#0056b3' }}>{job.title}</h3>
                            <h4 style={{ margin: '0 0 15px 0', color: '#555' }}>{job.company} • {job.location} • <span style={{ backgroundColor: '#e9ecef', padding: '3px 8px', borderRadius: '12px', fontSize: '0.85em' }}>{job.employmentType}</span></h4>
                            <p style={{ whiteSpace: 'pre-wrap', lineHeight: '1.5' }}>{job.description}</p>

                            <div style={{ marginTop: '15px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                                <button onClick={() => setSelectedJob(job)} style={{ backgroundColor: '#007bff', color: 'white', padding: '8px 15px', borderRadius: '5px', border: 'none', cursor: 'pointer' }}>
                                    Apply Internally
                                </button>
                                <small style={{ color: '#888' }}>Posted by {job.postedByUserName}</small>
                            </div>

                            {/* --- NEW: THE APPLICANT DASHBOARD (Only visible to job owner) --- */}
                            {isOwner && (
                                <div style={{ marginTop: '20px', paddingTop: '15px', borderTop: '1px solid #eee' }}>
                                    <button
                                        onClick={() => handleToggleApplicants(job.id)}
                                        style={{ backgroundColor: '#6c757d', color: 'white', padding: '6px 12px', borderRadius: '4px', border: 'none', cursor: 'pointer', fontSize: '0.9em' }}
                                    >
                                        {expandedJobId === job.id ? 'Hide Applicants' : 'View Applicants'}
                                    </button>

                                    {expandedJobId === job.id && (
                                        <div style={{ marginTop: '15px', backgroundColor: '#f8f9fa', padding: '15px', borderRadius: '5px', border: '1px solid #e9ecef' }}>
                                            <h4 style={{ margin: '0 0 10px 0' }}>Applications</h4>
                                            {(!jobApplicants[job.id] || jobApplicants[job.id].length === 0) ? (
                                                <p style={{ margin: 0, color: '#666', fontSize: '0.9em' }}>No applications yet.</p>
                                            ) : (
                                                jobApplicants[job.id].map(app => (
                                                    <div key={app.id} style={{ marginBottom: '15px', paddingBottom: '15px', borderBottom: '1px solid #ddd' }}>
                                                        <strong style={{ fontSize: '1.1em' }}>{app.applicantName}</strong>
                                                        <span style={{ color: '#777', fontSize: '0.85em', marginLeft: '10px' }}>
                                                            {new Date(app.appliedAt).toLocaleDateString()}
                                                        </span>
                                                        <p style={{ margin: '8px 0', fontSize: '0.95em', whiteSpace: 'pre-wrap', backgroundColor: 'white', padding: '10px', borderRadius: '4px', border: '1px solid #eee' }}>
                                                            {app.coverLetter}
                                                        </p>
                                                        <a href={app.resumeLink} target="_blank" rel="noopener noreferrer" style={{ fontSize: '0.9em', color: '#0056b3', textDecoration: 'none', fontWeight: 'bold' }}>
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

            {/* The Application Modal Overlay */}
            {selectedJob && (
                <div style={{ position: 'fixed', top: 0, left: 0, width: '100%', height: '100%', backgroundColor: 'rgba(0,0,0,0.5)', display: 'flex', justifyContent: 'center', alignItems: 'center', zIndex: 1000 }}>
                    <div style={{ backgroundColor: 'white', padding: '30px', borderRadius: '8px', width: '90%', maxWidth: '500px', position: 'relative' }}>
                        <button onClick={() => { setSelectedJob(null); setApplyStatus(''); }} style={{ position: 'absolute', top: '15px', right: '15px', border: 'none', background: 'none', fontSize: '1.5em', cursor: 'pointer' }}>&times;</button>
                        <h3 style={{ marginTop: 0 }}>Apply for {selectedJob.title}</h3>
                        <p style={{ color: '#555', marginBottom: '20px' }}>at {selectedJob.company}</p>

                        <form onSubmit={handleSubmitApplication} style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                            <textarea
                                required rows="5" placeholder="Write your cover letter or note to the poster here..."
                                value={applicationData.coverLetter}
                                onChange={e => setApplicationData({...applicationData, coverLetter: e.target.value})}
                                style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ccc' }}
                            />
                            <input
                                required placeholder="Link to Resume/Portfolio (e.g., Google Drive URL)"
                                value={applicationData.resumeLink}
                                onChange={e => setApplicationData({...applicationData, resumeLink: e.target.value})}
                                style={{ padding: '10px', borderRadius: '4px', border: '1px solid #ccc' }}
                            />
                            <button type="submit" style={{ padding: '10px', backgroundColor: '#0056b3', color: 'white', border: 'none', borderRadius: '4px', cursor: 'pointer', fontSize: '1.1em' }}>
                                Submit Application
                            </button>
                        </form>
                        {applyStatus && <p style={{ textAlign: 'center', marginTop: '15px', fontWeight: 'bold', color: applyStatus.includes('Success') ? 'green' : 'red' }}>{applyStatus}</p>}
                    </div>
                </div>
            )}
        </div>
    );
}