import { useState } from 'react';
import axios from 'axios';

export default function Register() {
    const [formData, setFormData] = useState({
        name: '',
        email: '',
        password: '',
        role: 'STUDENT'
    });
    const [message, setMessage] = useState('');

    const handleChange = (e) => {
        setFormData({ ...formData, [e.target.name]: e.target.value });
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        try {
            // Send the POST request to your API Gateway!
            const response = await axios.post('http://localhost:8080/api/users/register', formData);
            setMessage(response.data); // "User registered successfully..."
        } catch (error) {
            if (error.response) {
                setMessage(error.response.data); // "Error: Email is already registered!"
            } else {
                setMessage("Network error. Is the Gateway running?");
            }
        }
    };

    return (
        <div style={{ padding: '20px', maxWidth: '400px', margin: '0 auto' }}>
            <h2>Create DECP Account</h2>
            <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '10px' }}>

                <input type="text" name="name" placeholder="Full Name" required
                       onChange={handleChange} value={formData.name} />

                <input type="email" name="email" placeholder="University Email" required
                       onChange={handleChange} value={formData.email} />

                <input type="password" name="password" placeholder="Password" required
                       onChange={handleChange} value={formData.password} />

                <select name="role" onChange={handleChange} value={formData.role}>
                    <option value="STUDENT">Student</option>
                    <option value="ALUMNI">Alumni</option>
                    <option value="ADMIN">Admin</option>
                </select>

                <button type="submit" style={{ padding: '10px', cursor: 'pointer' }}>Register</button>
            </form>

            {message && <p style={{ marginTop: '20px', fontWeight: 'bold' }}>{message}</p>}
        </div>
    );
}