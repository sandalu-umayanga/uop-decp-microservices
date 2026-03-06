import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Register from './pages/Register'; // <-- Notice the updated path!
// (Update to './pages/RegisterPage' if you renamed the file)

function App() {
    return (
        <BrowserRouter>
            <div className="App">
                {/* The Navbar sits outside the Routes so it renders on every page */}
                <Navbar />

                <div style={{ padding: '20px' }}>
                    <Routes>
                        <Route path="/" element={<h1>Welcome to DECP</h1>} />
                        <Route path="/login" element={<h2>Login Page Coming Soon</h2>} />
                        <Route path="/register" element={<Register />} />
                        <Route path="/feed" element={<h2>Feed Page Coming Soon</h2>} />
                    </Routes>
                </div>
            </div>
        </BrowserRouter>
    );
}

export default App;