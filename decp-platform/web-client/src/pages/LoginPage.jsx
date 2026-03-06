import { useState } from 'react';
import axios from 'axios';
import { useNavigate } from 'react-router-dom';

export default function LoginPage() {
    const [credentials, setCredentials] = useState({ email: '', password: '' });
    const [message, setMessage] = useState('');
    const navigate = useNavigate(); // Used to redirect the user after login

    const handleChange = (e) => {
        setCredentials({ ...credentials, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            // Send login request to the API Gateway
            const response = await axios.post('http://localhost:8080/api/users/login', credentials);

            // Extract the data from the backend response
            const { token, role, id, name, message: successMsg } = response.data;

            // Save everything to the browser's local storage!
            localStorage.setItem('token', token);
            localStorage.setItem('role', role);
            localStorage.setItem('userId', id);     // <-- Added this
            localStorage.setItem('userName', name); // <-- Added this

            setMessage(successMsg);

            // Redirect to the Feed page after 1 second
            setTimeout(() => {
                navigate('/feed');
            }, 1000);

        } catch (error) {
            if (error.response) {
                // This catches the 401 Unauthorized errors from your Spring Boot backend
                setMessage(error.response.data);
            } else {
                setMessage("Network error. Is the Gateway running?");
            }
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '400px', margin: '0 auto' }}>
            <h2>Login to DECP</h2>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>

                <input
                    type="email"
                    name="email"
                    placeholder="University Email"
                    required
                    onChange={handleChange}
                    value={credentials.email}
                />

                <input
                    type="password"
                    name="password"
                    placeholder="Password"
                    required
                    onChange={handleChange}
                    value={credentials.password}
                />

                <button type="submit" style={{ padding: '10px', cursor: 'pointer' }}>Login</button>
            </form>

            {/* Display error or success messages */}
            {message && <p style={{ marginTop: '20px', fontWeight: 'bold' }}>{message}</p>}
        </div>
    );
}