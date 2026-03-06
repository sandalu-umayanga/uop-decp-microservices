import { useState, useEffect } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function FeedPage() {
    const [posts, setPosts] = useState([]);
    const [newPostContent, setNewPostContent] = useState(''); // State for the text box
    const [error, setError] = useState('');
    const navigate = useNavigate();

    useEffect(() => {
        const token = localStorage.getItem('token');
        if (!token) {
            navigate('/login');
            return;
        }
        fetchPosts();
    }, [navigate]);

    const fetchPosts = async () => {
        try {
            const response = await axios.get('http://localhost:8080/api/feed');
            const sortedPosts = response.data.sort((a, b) =>
                new Date(b.createdAt) - new Date(a.createdAt)
            );
            setPosts(sortedPosts);
        } catch (err) {
            setError('Failed to load the feed. Is the Gateway running?');
            console.error(err);
        }
    };

    // Function to handle submitting a new post
    const handleCreatePost = async (e) => {
        e.preventDefault();
        if (!newPostContent.trim()) return; // Don't submit empty posts

        // Grab the logged-in user's details from local storage
        const authorId = localStorage.getItem('userId');
        const authorName = localStorage.getItem('userName');

        try {
            await axios.post('http://localhost:8080/api/feed', {
                authorId: authorId,
                authorName: authorName,
                content: newPostContent
            });

            setNewPostContent(''); // Clear the text box
            fetchPosts(); // Refresh the feed to show the new post instantly!
        } catch (err) {
            console.error("Failed to create post", err);
            setError("Failed to publish post.");
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '600px', margin: '0 auto' }}>
            <h2>Department Feed</h2>
            {error && <p style={{ color: 'red' }}>{error}</p>}

            {/* --- NEW CREATE POST BOX --- */}
            <form onSubmit={handleCreatePost} style={{ marginBottom: '30px', display: 'flex', flexDirection: 'column', gap: '10px' }}>
        <textarea
            rows="4"
            placeholder="What's happening in the department?"
            value={newPostContent}
            onChange={(e) => setNewPostContent(e.target.value)}
            style={{ padding: '10px', borderRadius: '5px', border: '1px solid #ccc', resize: 'vertical' }}
        />
                <button type="submit" style={{ padding: '10px', cursor: 'pointer', backgroundColor: '#0056b3', color: 'white', border: 'none', borderRadius: '5px' }}>
                    Post Announcement
                </button>
            </form>
            {/* --------------------------- */}

            <div style={{ display: 'flex', flexDirection: 'column', gap: '15px' }}>
                {posts.length === 0 ? (
                    <p>No posts yet. It is pretty quiet in here!</p>
                ) : (
                    posts.map((post) => (
                        <div key={post.id} style={{
                            border: '1px solid #ccc', padding: '15px', borderRadius: '8px', backgroundColor: '#f9f9f9'
                        }}>
                            <div style={{ fontWeight: 'bold', marginBottom: '8px' }}>
                                {post.authorName}
                                <span style={{ color: '#777', fontSize: '0.85em', marginLeft: '10px' }}>
                  {new Date(post.createdAt).toLocaleString()}
                </span>
                            </div>
                            <div style={{ fontSize: '1.1em', lineHeight: '1.4' }}>
                                {post.content}
                            </div>
                        </div>
                    ))
                )}
            </div>
        </div>
    );
}