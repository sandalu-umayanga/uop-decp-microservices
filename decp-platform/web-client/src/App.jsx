import { BrowserRouter, Routes, Route } from 'react-router-dom';
import Navbar from './components/Navbar';
import Register from './pages/Register';
import LoginPage from "./pages/LoginPage.jsx";
import FeedPage from "./pages/FeedPage.jsx"; // <-- Notice the updated path!


function App() {
    return (
        <BrowserRouter>
            <div className="App">
                {/* The Navbar sits outside the Routes so it renders on every page */}
                <Navbar />

                <div style={{ padding: '20px' }}>
                    <Routes>
                        <Route path="/" element={<h1>Welcome to DECP</h1>} />
                        <Route path="/login" element={<LoginPage />} />
                        <Route path="/register" element={<Register />} />
                        <Route path="/feed" element={<FeedPage />} />
                    </Routes>
                </div>
            </div>
        </BrowserRouter>
    );
}

export default App;