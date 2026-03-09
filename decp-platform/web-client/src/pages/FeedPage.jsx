import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const CommentItem = ({ post, comment, currentUserId, onRefresh, depth = 0 }) => {
    const [isReplying, setIsReplying] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [replyText, setReplyText] = useState('');
    const [editText, setEditText] = useState(comment.text);

    const handleReply = async () => {
        if (!replyText.trim()) return;
        const token = localStorage.getItem('token');
        try {
            await axios.post(`/api/posts/${post.id}/comments/${comment.id}/replies`, { text: replyText }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setReplyText('');
            setIsReplying(false);
            onRefresh();
        } catch (err) { console.error(err); }
    };

    const handleEdit = async () => {
        if (!editText.trim()) return;
        const token = localStorage.getItem('token');
        try {
            await axios.put(`/api/posts/${post.id}/comments/${comment.id}`, { text: editText }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setIsEditing(false);
            onRefresh();
        } catch (err) { console.error(err); }
    };

    const handleDelete = async () => {
        if (!window.confirm("Delete this comment?")) return;
        const token = localStorage.getItem('token');
        try {
            await axios.delete(`/api/posts/${post.id}/comments/${comment.id}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            onRefresh();
        } catch (err) { console.error(err); }
    };

    return (
        <div style={{ marginLeft: depth > 0 ? '32px' : '0', borderLeft: depth > 0 ? '2px solid var(--uc-border)' : 'none', paddingLeft: depth > 0 ? '16px' : '0', marginTop: '16px' }}>
            <div style={{ display: 'flex', gap: '12px' }}>
                <div className="avatar-squircle" style={{ width: '36px', height: '36px', flexShrink: 0, fontSize: '14px' }}>
                    {comment.userName.charAt(0).toUpperCase()}
                </div>
                <div style={{ flex: 1 }}>
                    <div style={{ background: 'white', padding: '12px 16px', borderRadius: '16px', border: '1px solid var(--uc-border)' }}>
                        <div style={{ fontWeight: '700', fontSize: '14px', color: 'var(--uc-primary)', marginBottom: '4px' }}>{comment.userName}</div>
                        
                        {isEditing ? (
                            <div style={{ marginTop: '8px' }}>
                                <textarea className="li-input" value={editText} onChange={(e) => setEditText(e.target.value)} style={{ borderRadius: '12px', minHeight: '60px' }} />
                                <div style={{ display: 'flex', gap: '8px', marginTop: '8px' }}>
                                    <button onClick={handleEdit} className="uc-btn uc-btn-primary" style={{ padding: '6px 16px', fontSize: '12px' }}>Save</button>
                                    <button onClick={() => setIsEditing(false)} className="uc-btn uc-btn-outline" style={{ padding: '6px 16px', fontSize: '12px' }}>Cancel</button>
                                </div>
                            </div>
                        ) : (
                            <div style={{ fontSize: '14px', color: 'var(--uc-text-main)', lineHeight: '1.5' }}>{comment.text}</div>
                        )}
                    </div>
                    
                    {!isEditing && (
                        <div style={{ display: 'flex', gap: '16px', marginTop: '6px', fontSize: '12px', color: 'var(--uc-text-muted)', paddingLeft: '4px' }}>
                            <button onClick={() => setIsReplying(!isReplying)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--uc-primary)', fontWeight: '700' }}>Reply</button>
                            {String(comment.userId) === String(currentUserId) && (
                                <>
                                    <button onClick={() => setIsEditing(true)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'inherit' }}>Edit</button>
                                    <button onClick={handleDelete} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#f43f5e' }}>Delete</button>
                                </>
                            )}
                            <span>{new Date(comment.createdAt).toLocaleDateString()}</span>
                        </div>
                    )}

                    {isReplying && (
                        <div style={{ marginTop: '12px', display: 'flex', gap: '8px' }}>
                            <input type="text" className="li-input" placeholder="Write a reply..." value={replyText} onChange={(e) => setReplyText(e.target.value)} style={{ borderRadius: '12px' }} />
                            <button onClick={handleReply} className="uc-btn uc-btn-primary" style={{ padding: '8px 16px' }}>Send</button>
                        </div>
                    )}

                    {comment.replies && comment.replies.length > 0 && (
                        <div>
                            {comment.replies.map(reply => (
                                <CommentItem key={reply.id} post={post} comment={reply} currentUserId={currentUserId} onRefresh={onRefresh} depth={depth + 1} />
                            ))}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
};

export default function FeedPage() {
    const [posts, setPosts] = useState([]);
    const [stats, setStats] = useState({ profileViews: 0, connections: 0 });
    const [newPostContent, setNewPostContent] = useState('');
    const [commentTexts, setCommentTexts] = useState({});
    const [expandedComments, setExpandedComments] = useState({});
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');
    const userName = localStorage.getItem('userName');
    const role = localStorage.getItem('role');

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) { navigate('/login'); return; }
        fetchPosts();
        fetchStats();
    }, [navigate]);

    const fetchPosts = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get('/api/posts/feed', { headers: { Authorization: `Bearer ${token}` } });
            setPosts(response.data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
        } catch (err) { console.error(err); }
    };

    const fetchStats = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get(`/api/users/${currentUserId}/profile`, { headers: { Authorization: `Bearer ${token}` } });
            setStats({ profileViews: response.data.profileViews, connections: response.data.connections });
        } catch (err) { console.error(err); }
    };

    const handleCreatePost = async (e) => {
        e.preventDefault();
        if (!newPostContent.trim()) return;
        const token = localStorage.getItem('token');
        try {
            await axios.post('/api/posts', { text: newPostContent }, { headers: { Authorization: `Bearer ${token}` } });
            setNewPostContent('');
            fetchPosts();
        } catch (err) { console.error(err); }
    };

    const handleDeletePost = async (postId) => {
        if (!window.confirm("Delete post?")) return;
        const token = localStorage.getItem('token');
        try {
            await axios.delete(`/api/posts/${postId}`, { headers: { Authorization: `Bearer ${token}` } });
            fetchPosts();
        } catch (err) { console.error(err); }
    };

    const handleToggleLike = async (postId) => {
        const token = localStorage.getItem('token');
        try {
            await axios.post(`/api/posts/${postId}/likes`, {}, { headers: { Authorization: `Bearer ${token}` } });
            fetchPosts();
        } catch (err) { console.error(err); }
    };

    const handleAddComment = async (postId) => {
        const text = commentTexts[postId];
        if (!text || !text.trim()) return;
        const token = localStorage.getItem('token');
        try {
            await axios.post(`/api/posts/${postId}/comments`, { text }, { headers: { Authorization: `Bearer ${token}` } });
            setCommentTexts({ ...commentTexts, [postId]: '' });
            fetchPosts();
        } catch (err) { console.error(err); }
    };

    return (
        <div className="main-layout">
            <aside className="sidebar-left">
                <div className="uc-card" style={{ textAlign: 'center', overflow: 'hidden' }}>
                    <div style={{ height: '80px', background: 'linear-gradient(45deg, var(--uc-primary), #a855f7)' }}></div>
                    <div className="avatar-squircle" style={{ width: '80px', height: '80px', background: '#fff', border: '4px solid white', margin: '-40px auto 12px', fontSize: '32px', boxShadow: '0 4px 12px rgba(0,0,0,0.1)', position: 'relative', color: 'var(--uc-primary)' }}>
                        {userName ? userName.charAt(0).toUpperCase() : '?'}
                    </div>
                    <div style={{ padding: '0 16px 20px' }}>
                        <div style={{ fontWeight: '800', fontSize: '18px' }}>{userName}</div>
                        <div style={{ fontSize: '13px', color: 'var(--uc-text-muted)', marginTop: '4px', fontWeight: '500' }}>{role} • Computer Engineering</div>
                        
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px', marginTop: '20px', borderTop: '1px solid var(--uc-border)', paddingTop: '20px' }}>
                            <div>
                                <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--uc-primary)' }}>{stats.connections}</div>
                                <div style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '1px', color: 'var(--uc-text-muted)', fontWeight: '700' }}>Connections</div>
                            </div>
                            <div>
                                <div style={{ fontSize: '20px', fontWeight: '800', color: 'var(--uc-primary)' }}>{stats.profileViews}</div>
                                <div style={{ fontSize: '11px', textTransform: 'uppercase', letterSpacing: '1px', color: 'var(--uc-text-muted)', fontWeight: '700' }}>Views</div>
                            </div>
                        </div>
                    </div>
                </div>
            </aside>

            <main>
                <div className="uc-card" style={{ padding: '24px' }}>
                    <div style={{ display: 'flex', gap: '16px', alignItems: 'center' }}>
                        <div className="avatar-squircle" style={{ width: '48px', height: '48px', fontSize: '20px', flexShrink: 0 }}>
                            {userName?.charAt(0).toUpperCase()}
                        </div>
                        <button onClick={() => document.getElementById('post-area').focus()} className="post-input-trigger">
                            Share something with the department...
                        </button>
                    </div>
                    <div style={{ marginTop: '16px' }}>
                        <textarea id="post-area" className="li-input" rows="3" placeholder="What's on your mind?" value={newPostContent} onChange={(e) => setNewPostContent(e.target.value)} style={{ border: 'none', background: 'transparent', padding: '0', fontSize: '16px', resize: 'none' }} />
                        {newPostContent.trim() && (
                            <div style={{ display: 'flex', justifyContent: 'flex-end', borderTop: '1px solid var(--uc-border)', paddingTop: '16px', marginTop: '12px' }}>
                                <button onClick={handleCreatePost} className="uc-btn uc-btn-primary">Publish Post</button>
                            </div>
                        )}
                    </div>
                </div>

                <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
                    {posts.map((post) => (
                        <div key={post.id} className="uc-card" style={{ padding: '0' }}>
                            <div className="post-header">
                                <div className="avatar-squircle" style={{ width: '48px', height: '48px', fontSize: '20px', flexShrink: 0 }}>
                                    {post.authorName?.charAt(0).toUpperCase()}
                                </div>
                                <div style={{ display: 'flex', flexDirection: 'column' }}>
                                    <span style={{ fontWeight: '700', color: 'var(--uc-text-main)' }}>{post.authorName}</span>
                                    <span style={{ fontSize: '12px', color: 'var(--uc-text-muted)' }}>{new Date(post.createdAt).toLocaleDateString()} • Global Feed</span>
                                </div>
                                {String(post.authorId) === String(currentUserId) && (
                                    <button onClick={() => handleDeletePost(post.id)} className="li-btn li-btn-ghost" style={{ marginLeft: 'auto', color: '#f43f5e' }}>Remove</button>
                                )}
                            </div>
                            <div className="post-content">{post.text}</div>
                            
                            <div className="post-actions-unique">
                                <button onClick={() => handleToggleLike(post.id)} className={`action-chip ${post.likes?.includes(Number(currentUserId)) ? 'active' : ''}`}>
                                    {post.likes?.includes(Number(currentUserId)) ? '❤️ Liked' : '👍 Like'} ({post.likes?.length || 0})
                                </button>
                                <button onClick={() => setExpandedComments({ ...expandedComments, [post.id]: !expandedComments[post.id] })} className="action-chip">
                                    💬 Comments ({post.comments?.length || 0})
                                </button>
                                <button className="action-chip">🔗 Share</button>
                            </div>

                            {expandedComments[post.id] && (
                                <div style={{ padding: '20px', background: 'white', borderTop: '1px solid var(--uc-border)' }}>
                                    <div style={{ display: 'flex', gap: '12px', marginBottom: '20px' }}>
                                        <div className="avatar-squircle" style={{ width: '32px', height: '32px', fontSize: '12px' }}>{userName?.charAt(0).toUpperCase()}</div>
                                        <div style={{ flex: 1, position: 'relative' }}>
                                            <input type="text" className="li-input" placeholder="Add a comment..." value={commentTexts[post.id] || ''} onChange={(e) => setCommentTexts({ ...commentTexts, [post.id]: e.target.value })} style={{ borderRadius: '12px', paddingRight: '80px' }} />
                                            {commentTexts[post.id]?.trim() && <button onClick={() => handleAddComment(post.id)} className="uc-btn uc-btn-primary" style={{ position: 'absolute', right: '4px', top: '4px', padding: '6px 12px', fontSize: '12px', borderRadius: '10px' }}>Post</button>}
                                        </div>
                                    </div>
                                    {post.comments?.map(comment => <CommentItem key={comment.id} post={post} comment={comment} currentUserId={currentUserId} onRefresh={fetchPosts} />)}
                                </div>
                            )}
                        </div>
                    ))}
                </div>
            </main>

            <aside className="sidebar-right">
                <div className="uc-card" style={{ padding: '24px' }}>
                    <h3 style={{ fontSize: '16px', fontWeight: '800', marginBottom: '16px', display: 'flex', alignItems: 'center', gap: '8px' }}>
                        <span style={{ color: 'var(--uc-primary)' }}>✨</span> Trending Now
                    </h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
                        <div style={{ cursor: 'pointer' }}>
                            <div style={{ fontSize: '14px', fontWeight: '700' }}># PeradeniyaEngineering</div>
                            <div style={{ fontSize: '12px', color: 'var(--uc-text-muted)' }}>4.2k members interacting</div>
                        </div>
                        <div style={{ cursor: 'pointer' }}>
                            <div style={{ fontSize: '14px', fontWeight: '700' }}># FinalYearProjects</div>
                            <div style={{ fontSize: '12px', color: 'var(--uc-text-muted)' }}>842 people posting</div>
                        </div>
                    </div>
                </div>
            </aside>
        </div>
    );
}