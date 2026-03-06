import { Link } from 'react-router-dom';

export default function Navbar() {
    return (
        <nav style={{
            display: 'flex',
            gap: '15px',
            padding: '15px',
            backgroundColor: '#f4f4f4',
            borderBottom: '1px solid #ddd'
        }}>
            <strong style={{ marginRight: 'auto' }}>DECP</strong>
            <Link to="/">Home</Link>
            <Link to="/feed">Feed</Link>
            <Link to="/login">Login</Link>
            <Link to="/register">Register</Link>
        </nav>
    );
}