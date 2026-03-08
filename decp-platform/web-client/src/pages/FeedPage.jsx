import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

const CommentItem = ({ post, comment, currentUserId, onRefresh, depth = 0 }) => {
    const [isReplying, setIsReplying] = useState(false);
    const [isEditing, setIsEditing] = useState(false);
    const [replyText, setReplyText] = useState('');
    const [editText, setEditText] = useState(comment.text);
    const [showReplies, setShowReplies] = useState(true);

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
        <div style={{ marginLeft: depth > 0 ? '20px' : '0', borderLeft: depth > 0 ? '2px solid #ddd' : 'none', paddingLeft: depth > 0 ? '10px' : '0', marginTop: '10px' }}>
            <div style={{ backgroundColor: '#f0f2f5', padding: '10px', borderRadius: '12px', position: 'relative' }}>
                <div style={{ fontWeight: '600', fontSize: '0.85rem' }}>{comment.userName}</div>
                
                {isEditing ? (
                    <div style={{ marginTop: '5px' }}>
                        <textarea className="textarea" value={editText} onChange={(e) => setEditText(e.target.value)} style={{ padding: '5px', fontSize: '0.9rem' }} />
                        <div style={{ display: 'flex', gap: '5px', marginTop: '5px' }}>
                            <button onClick={handleEdit} className="btn btn-primary" style={{ padding: '2px 8px', fontSize: '0.75rem' }}>Save</button>
                            <button onClick={() => setIsEditing(false)} className="btn btn-secondary" style={{ padding: '2px 8px', fontSize: '0.75rem' }}>Cancel</button>
                        </div>
                    </div>
                ) : (
                    <>
                        <div style={{ fontSize: '0.9rem', marginTop: '2px' }}>{comment.text}</div>
                        <div style={{ display: 'flex', gap: '15px', marginTop: '5px', fontSize: '0.75rem', color: 'var(--text-secondary)' }}>
                            <span>{new Date(comment.createdAt).toLocaleString()}</span>
                            <button onClick={() => setIsReplying(!isReplying)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--primary-color)', fontWeight: 'bold' }}>Reply</button>
                            {String(comment.userId) === String(currentUserId) && (
                                <>
                                    <button onClick={() => setIsEditing(true)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-secondary)' }}>Edit</button>
                                    <button onClick={handleDelete} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--danger-color)' }}>Delete</button>
                                </>
                            )}
                        </div>
                    </>
                )}
            </div>

            {isReplying && (
                <div style={{ marginTop: '5px', marginLeft: '20px' }}>
                    <input type="text" className="input" placeholder="Write a reply..." value={replyText} onChange={(e) => setReplyText(e.target.value)} style={{ padding: '5px 10px', borderRadius: '15px', fontSize: '0.85rem' }} />
                    <div style={{ display: 'flex', gap: '5px', marginTop: '5px' }}>
                        <button onClick={handleReply} className="btn btn-primary" style={{ padding: '2px 10px', fontSize: '0.75rem', borderRadius: '15px' }}>Send</button>
                        <button onClick={() => setIsReplying(false)} className="btn btn-secondary" style={{ padding: '2px 10px', fontSize: '0.75rem', borderRadius: '15px' }}>Cancel</button>
                    </div>
                </div>
            )}

            {comment.replies && comment.replies.length > 0 && (
                <>
                    <button onClick={() => setShowReplies(!showReplies)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--text-secondary)', fontSize: '0.75rem', marginTop: '5px', marginLeft: '20px' }}>
                        {showReplies ? 'Hide' : 'Show'} {comment.replies.length} {comment.replies.length === 1 ? 'reply' : 'replies'}
                    </button>
                    {showReplies && comment.replies.map(reply => (
                        <CommentItem key={reply.id} post={post} comment={reply} currentUserId={currentUserId} onRefresh={onRefresh} depth={depth + 1} />
                    ))}
                </>
            )}
        </div>
    );
};

export default function FeedPage() {
    const [posts, setPosts] = useState([]);
    const [newPostContent, setNewPostContent] = useState('');
    const [error, setError] = useState('');
    const [commentTexts, setCommentTexts] = useState({});
    const [expandedComments, setExpandedComments] = useState({});
    const navigate = useNavigate();

    const currentUserId = localStorage.getItem('userId');
    const userName = localStorage.getItem('userName');

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) {
            navigate('/login');
            return;
        }
        fetchPosts().catch(err => console.error('Failed to fetch posts:', err));
    }, [navigate]);

    const fetchPosts = async () => {
        try {
            const token = localStorage.getItem('token');
            const response = await axios.get('/api/posts/feed', {
                headers: { Authorization: `Bearer ${token}` }
            });

            const sortedPosts = response.data.sort((a, b) =>
                new Date(b.createdAt) - new Date(a.createdAt)
            );
            setPosts(sortedPosts);
        } catch (err) {
            setError('Failed to load the feed.');
            console.error(err);
        }
    };

    const handleCreatePost = async (e) => {
        e.preventDefault();
        if (!newPostContent.trim()) return;
        const token = localStorage.getItem('token');
        try {
            await axios.post('/api/posts', { text: newPostContent }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setNewPostContent('');
            fetchPosts();
        } catch (err) { setError("Failed to publish post."); }
    };

    const handleDeletePost = async (postId) => {
        if (!window.confirm("Are you sure?")) return;
        const token = localStorage.getItem('token');
        try {
            await axios.delete(`/api/posts/${postId}`, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchPosts();
        } catch (err) { setError("Failed to delete post."); }
    };

    const handleToggleLike = async (postId) => {
        const token = localStorage.getItem('token');
        try {
            await axios.post(`/api/posts/${postId}/likes`, {}, {
                headers: { Authorization: `Bearer ${token}` }
            });
            fetchPosts();
        } catch (err) { console.error(err); }
    };

    const handleAddComment = async (postId) => {
        const text = commentTexts[postId];
        if (!text || !text.trim()) return;
        const token = localStorage.getItem('token');
        try {
            await axios.post(`/api/posts/${postId}/comments`, { text }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            setCommentTexts({ ...commentTexts, [postId]: '' });
            fetchPosts();
        } catch (err) { console.error(err); }
    };

    return (
        <div className="container" style={{ maxWidth: '650px' }}>
            <h2 style={{ marginBottom: '25px' }}>Department Feed</h2>
            {error && <p style={{ color: 'var(--danger-color)', marginBottom: '15px' }}>{error}</p>}

            <div className="card" style={{ padding: '20px', border: '1px solid #dddfe2' }}>
                <form onSubmit={handleCreatePost}>
                    <textarea rows="4" className="textarea" placeholder={`What's happening, ${userName}?`} value={newPostContent} onChange={(e) => setNewPostContent(e.target.value)} />
                    <div style={{ display: 'flex', justifyContent: 'flex-end', marginTop: '10px' }}>
                        <button type="submit" className="btn btn-primary">Post Announcement</button>
                    </div>
                </form>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                {posts.map((post) => (
                    <div key={post.id} className="card" style={{ position: 'relative' }}>
                        <div style={{ display: 'flex', justifyContent: 'space-between', marginBottom: '12px' }}>
                            <div style={{ display: 'flex', gap: '12px', alignItems: 'center' }}>
                                <div style={{ width: '40px', height: '40px', backgroundColor: 'var(--primary-color)', color: 'white', borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center', fontWeight: 'bold' }}>
                                    {post.authorName ? post.authorName.charAt(0).toUpperCase() : '?'}
                                </div>
                                <div>
                                    <div style={{ fontWeight: '600' }}>{post.authorName}</div>
                                    <div style={{ color: 'var(--text-secondary)', fontSize: '0.85rem' }}>{new Date(post.createdAt).toLocaleString()}</div>
                                </div>
                            </div>
                            {String(post.authorId) === String(currentUserId) && (
                                <button onClick={() => handleDeletePost(post.id)} className="btn btn-danger" style={{ padding: '4px 10px', fontSize: '0.8rem' }}>Delete</button>
                            )}
                        </div>
                        <div style={{ fontSize: '1.05rem', lineHeight: '1.6', marginBottom: '15px' }}>{post.text}</div>
                        <div style={{ paddingTop: '10px', borderTop: '1px solid #eee', display: 'flex', gap: '20px' }}>
                            <button onClick={() => handleToggleLike(post.id)} style={{ background: 'none', border: 'none', color: post.likes && post.likes.includes(Number(currentUserId)) ? 'var(--primary-color)' : 'var(--text-secondary)', cursor: 'pointer', fontWeight: '600' }}>
                                {post.likes && post.likes.includes(Number(currentUserId)) ? '❤️' : '👍'} {post.likes ? post.likes.length : 0}
                            </button>
                            <button onClick={() => setExpandedComments({ ...expandedComments, [post.id]: !expandedComments[post.id] })} style={{ background: 'none', border: 'none', color: 'var(--text-secondary)', cursor: 'pointer', fontWeight: '600' }}>
                                💬 {post.comments ? post.comments.length : 0}
                            </button>
                        </div>

                        {expandedComments[post.id] && (
                            <div style={{ marginTop: '15px', paddingTop: '15px', borderTop: '1px solid #eee' }}>
                                {post.comments && post.comments.map(comment => (
                                    <CommentItem key={comment.id} post={post} comment={comment} currentUserId={currentUserId} onRefresh={fetchPosts} />
                                ))}
                                <div style={{ display: 'flex', gap: '10px', marginTop: '15px' }}>
                                    <input type="text" className="input" placeholder="Write a comment..." value={commentTexts[post.id] || ''} onChange={(e) => setCommentTexts({ ...commentTexts, [post.id]: e.target.value })} style={{ borderRadius: '20px' }} />
                                    <button onClick={() => handleAddComment(post.id)} className="btn btn-primary" style={{ borderRadius: '20px' }}>Send</button>
                                </div>
                            </div>
                        )}
                    </div>
                ))}
            </div>
        </div>
    );
}