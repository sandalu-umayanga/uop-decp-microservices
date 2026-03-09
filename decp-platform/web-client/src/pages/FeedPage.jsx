import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

/* ── Recursive Comment Component ────────────────────────────── */
const CommentItem = ({ post, comment, currentUserId, onRefresh, depth = 0 }) => {
    const [isReplying, setIsReplying] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [replyText, setReplyText] = useState('');
    const [editText, setEditText] = useState(comment.text);

    const token = localStorage.getItem('token');
    const headers = { Authorization: `Bearer ${token}` };

    const handleReply = async () => {
        if (!replyText.trim()) return;
        try {
            await axios.post(`/api/posts/${post.id}/comments/${comment.id}/replies`, { text: replyText }, { headers });
            setReplyText(''); setIsReplying(false); onRefresh();
        } catch (err) { console.error(err); }
    };

    const handleEdit = async () => {
        if (!editText.trim()) return;
        try {
            await axios.put(`/api/posts/${post.id}/comments/${comment.id}`, { text: editText }, { headers });
            setIsEditing(false); onRefresh();
        } catch (err) { console.error(err); }
    };

    const handleDelete = async () => {
        if (!window.confirm('Delete this comment?')) return;
        try {
            await axios.delete(`/api/posts/${post.id}/comments/${comment.id}`, { headers });
            onRefresh();
        } catch (err) { console.error(err); }
    };

    const isOwner = String(comment.userId) === String(currentUserId);

    return (
        <div style={{ marginLeft: depth > 0 ? 24 : 0, borderLeft: depth > 0 ? '2px solid var(--uc-border)' : 'none', paddingLeft: depth > 0 ? 14 : 0, marginTop: 14 }}>
            <div style={{ display: 'flex', gap: 10 }}>
                <div className="avatar-squircle" style={{ width: 32, height: 32, fontSize: 13, flexShrink: 0 }}>
                    {comment.userName?.charAt(0).toUpperCase()}
                </div>
                <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ background: 'var(--uc-surface)', padding: '10px 14px', borderRadius: 14, border: '1px solid var(--uc-border)' }}>
                        <div style={{ fontWeight: 700, fontSize: 13, color: 'var(--uc-primary)', marginBottom: 2 }}>{comment.userName}</div>
                        {isEditing ? (
                            <div style={{ marginTop: 6 }}>
                                <textarea className="li-input" value={editText} onChange={(e) => setEditText(e.target.value)} rows={2} />
                                <div style={{ display: 'flex', gap: 8, marginTop: 8 }}>
                                    <button onClick={handleEdit} className="uc-btn uc-btn-primary" style={{ padding: '5px 14px', fontSize: 12 }}>Save</button>
                                    <button onClick={() => setIsEditing(false)} className="uc-btn uc-btn-outline" style={{ padding: '5px 14px', fontSize: 12 }}>Cancel</button>
                                </div>
                            </div>
                        ) : (
                            <div style={{ fontSize: 14, lineHeight: 1.5, color: 'var(--uc-text-main)' }}>{comment.text}</div>
                        )}
                    </div>

                    {!isEditing && (
                        <div style={{ display: 'flex', gap: 14, marginTop: 4, fontSize: 12, paddingLeft: 4, flexWrap: 'wrap' }}>
                            <button onClick={() => setIsReplying(!isReplying)} className="uc-btn-ghost" style={{ padding: 0, background: 'none', border: 'none', cursor: 'pointer', fontWeight: 700, fontSize: 12, color: 'var(--uc-primary)' }}>Reply</button>
                            {isOwner && (
                                <>
                                    <button onClick={() => setIsEditing(true)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--uc-text-muted)', fontSize: 12 }}>Edit</button>
                                    <button onClick={handleDelete} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--uc-danger)', fontSize: 12 }}>Delete</button>
                                </>
                            )}
                            <span style={{ color: 'var(--uc-text-muted)' }}>{new Date(comment.createdAt).toLocaleDateString()}</span>
                        </div>
                    )}

                    {isReplying && (
                        <div style={{ marginTop: 10, display: 'flex', gap: 8 }}>
                            <input type="text" className="li-input" placeholder="Write a reply…" value={replyText} onChange={(e) => setReplyText(e.target.value)} style={{ flex: 1 }} />
                            <button onClick={handleReply} className="uc-btn uc-btn-primary" style={{ padding: '8px 14px', flexShrink: 0 }}>Send</button>
                        </div>
                    )}

                    {comment.replies?.map(reply => (
                        <CommentItem key={reply.id} post={post} comment={reply} currentUserId={currentUserId} onRefresh={onRefresh} depth={depth + 1} />
                    ))}
                </div>
            </div>
        </div>
    );
};

/* ── Feed Page ──────────────────────────────────────────────── */
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
        if (!localStorage.getItem('token')) { navigate('/login'); return; }
        fetchPosts(); fetchStats();
    }, [navigate]);

    const authHeaders = () => ({ headers: { Authorization: `Bearer ${localStorage.getItem('token')}` } });

    const fetchPosts = async () => {
        try {
            const res = await axios.get('/api/posts/feed', authHeaders());
            setPosts(res.data.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt)));
        } catch (err) { console.error(err); }
    };

    const fetchStats = async () => {
        try {
            const res = await axios.get(`/api/users/${currentUserId}/profile`, authHeaders());
            setStats({ profileViews: res.data.profileViews, connections: res.data.connections });
        } catch (err) { console.error(err); }
    };

    const handleCreatePost = async (e) => {
        e.preventDefault();
        if (!newPostContent.trim()) return;
        try {
            await axios.post('/api/posts', { text: newPostContent }, authHeaders());
            setNewPostContent(''); fetchPosts();
        } catch (err) { console.error(err); }
    };

    const handleDeletePost = async (postId) => {
        if (!window.confirm('Delete post?')) return;
        try { await axios.delete(`/api/posts/${postId}`, authHeaders()); fetchPosts(); }
        catch (err) { console.error(err); }
    };

    const handleToggleLike = async (postId) => {
        try { await axios.post(`/api/posts/${postId}/likes`, {}, authHeaders()); fetchPosts(); }
        catch (err) { console.error(err); }
    };

    const handleAddComment = async (postId) => {
        const text = commentTexts[postId];
        if (!text?.trim()) return;
        try {
            await axios.post(`/api/posts/${postId}/comments`, { text }, authHeaders());
            setCommentTexts({ ...commentTexts, [postId]: '' }); fetchPosts();
        } catch (err) { console.error(err); }
    };

    return (
        <div className="main-layout">
            {/* ── Left Sidebar: User card ── */}
            <aside className="sidebar-left">
                <div className="uc-card" style={{ textAlign: 'center', overflow: 'hidden' }}>
                    <div style={{ height: 72, background: 'linear-gradient(135deg, var(--uc-primary), #a78bfa)' }} />
                    <div className="avatar-squircle" style={{ width: 72, height: 72, border: '4px solid white', margin: '-36px auto 10px', fontSize: 28, boxShadow: 'var(--uc-shadow)', position: 'relative' }}>
                        {userName?.charAt(0).toUpperCase() ?? '?'}
                    </div>
                    <div style={{ padding: '0 16px 20px' }}>
                        <div style={{ fontWeight: 800, fontSize: 17 }}>{userName}</div>
                        <div style={{ fontSize: 13, color: 'var(--uc-text-muted)', marginTop: 2, fontWeight: 500 }}>{role} • Computer Engineering</div>
                        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginTop: 18, borderTop: '1px solid var(--uc-border)', paddingTop: 18 }}>
                            <div><div className="stat-value">{stats.connections}</div><div className="stat-label">Connections</div></div>
                            <div><div className="stat-value">{stats.profileViews}</div><div className="stat-label">Views</div></div>
                        </div>
                    </div>
                </div>
            </aside>

            {/* ── Main Feed Column ── */}
            <main>
                {/* Create Post */}
                <div className="uc-card" style={{ padding: '20px' }}>
                    <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
                        <div className="avatar-squircle" style={{ width: 44, height: 44, fontSize: 18 }}>{userName?.charAt(0).toUpperCase()}</div>
                        <button onClick={() => document.getElementById('post-area')?.focus()} className="post-input-trigger">
                            Share something with the department…
                        </button>
                    </div>
                    <div style={{ marginTop: 14 }}>
                        <textarea id="post-area" className="li-input" rows="3" placeholder="What's on your mind?" value={newPostContent}
                            onChange={(e) => setNewPostContent(e.target.value)}
                            style={{ border: 'none', background: 'transparent', padding: 0, fontSize: 15, resize: 'none' }} />
                        {newPostContent.trim() && (
                            <div style={{ display: 'flex', justifyContent: 'flex-end', borderTop: '1px solid var(--uc-border)', paddingTop: 14, marginTop: 10 }}>
                                <button onClick={handleCreatePost} className="uc-btn uc-btn-primary">Publish Post</button>
                            </div>
                        )}
                    </div>
                </div>

                {/* Post List */}
                <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                    {posts.map((post) => {
                        const isOwner = String(post.authorId) === String(currentUserId);
                        const liked = post.likes?.includes(Number(currentUserId));
                        return (
                            <div key={post.id} className="uc-card" style={{ padding: 0 }}>
                                <div className="post-header">
                                    <div className="avatar-squircle" style={{ width: 44, height: 44, fontSize: 18 }}>
                                        {post.authorName?.charAt(0).toUpperCase()}
                                    </div>
                                    <div style={{ flex: 1, minWidth: 0 }}>
                                        <span style={{ fontWeight: 700 }}>{post.authorName}</span>
                                        <div style={{ fontSize: 12, color: 'var(--uc-text-muted)' }}>{new Date(post.createdAt).toLocaleDateString()} • Global Feed</div>
                                    </div>
                                    {isOwner && <button onClick={() => handleDeletePost(post.id)} className="uc-btn uc-btn-danger" style={{ fontSize: 13 }}>Remove</button>}
                                </div>

                                <div className="post-content">{post.text}</div>

                                <div className="post-actions-unique">
                                    <button onClick={() => handleToggleLike(post.id)} className={`action-chip ${liked ? 'active' : ''}`}>
                                        {liked ? '❤️ Liked' : '👍 Like'} ({post.likes?.length || 0})
                                    </button>
                                    <button onClick={() => setExpandedComments({ ...expandedComments, [post.id]: !expandedComments[post.id] })} className="action-chip">
                                        💬 Comments ({post.comments?.length || 0})
                                    </button>
                                    <button className="action-chip">🔗 Share</button>
                                </div>

                                {expandedComments[post.id] && (
                                    <div className="comment-section">
                                        <div style={{ display: 'flex', gap: 10, marginBottom: 16 }}>
                                            <div className="avatar-squircle" style={{ width: 32, height: 32, fontSize: 12 }}>{userName?.charAt(0).toUpperCase()}</div>
                                            <div style={{ flex: 1, position: 'relative' }}>
                                                <input type="text" className="li-input" placeholder="Add a comment…"
                                                    value={commentTexts[post.id] || ''}
                                                    onChange={(e) => setCommentTexts({ ...commentTexts, [post.id]: e.target.value })}
                                                    onKeyDown={(e) => e.key === 'Enter' && handleAddComment(post.id)}
                                                    style={{ paddingRight: commentTexts[post.id]?.trim() ? 72 : 16 }} />
                                                {commentTexts[post.id]?.trim() && (
                                                    <button onClick={() => handleAddComment(post.id)} className="uc-btn uc-btn-primary"
                                                        style={{ position: 'absolute', right: 4, top: 4, padding: '6px 12px', fontSize: 12 }}>Post</button>
                                                )}
                                            </div>
                                        </div>
                                        {post.comments?.map(c => <CommentItem key={c.id} post={post} comment={c} currentUserId={currentUserId} onRefresh={fetchPosts} />)}
                                    </div>
                                )}
                            </div>
                        );
                    })}
                    {posts.length === 0 && (
                        <div className="uc-card" style={{ padding: 40, textAlign: 'center', color: 'var(--uc-text-muted)' }}>
                            <div style={{ fontSize: 40, marginBottom: 12 }}>📝</div>
                            <div style={{ fontWeight: 700, fontSize: 16 }}>No posts yet</div>
                            <div style={{ fontSize: 14, marginTop: 4 }}>Be the first to share something!</div>
                        </div>
                    )}
                </div>
            </main>

            {/* ── Right Sidebar: Trending ── */}
            <aside className="sidebar-right">
                <div className="uc-card" style={{ padding: 24 }}>
                    <h3 style={{ fontSize: 15, fontWeight: 800, marginBottom: 16, display: 'flex', alignItems: 'center', gap: 8 }}>
                        <span style={{ color: 'var(--uc-primary)' }}>✨</span> Trending Now
                    </h3>
                    <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
                        {[{ tag: '# PeradeniyaEngineering', count: '4.2k members' }, { tag: '# FinalYearProjects', count: '842 people posting' }, { tag: '# InternshipSeason', count: '391 active' }].map((t, i) => (
                            <div key={i} style={{ cursor: 'pointer' }}>
                                <div style={{ fontSize: 14, fontWeight: 700 }}>{t.tag}</div>
                                <div style={{ fontSize: 12, color: 'var(--uc-text-muted)' }}>{t.count}</div>
                            </div>
                        ))}
                    </div>
                </div>
            </aside>
        </div>
    );
}