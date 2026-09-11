import React, { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { Mail, ArrowLeft, Send } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import './ForgotPassword.css';

const ForgotPassword = () => {
  const [email, setEmail] = useState('');
  const [message, setMessage] = useState('');
  const [error, setError] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  
  const { resetPassword } = useAuth();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setMessage('');
    
    if (!email) {
      setError('Please enter your email address');
      return;
    }

    setIsLoading(true);
    
    const result = await resetPassword(email);
    
    if (result.success) {
      setMessage('Password reset email sent! Check your inbox.');
    } else {
      let errorMessage = result.error;
      if (errorMessage.includes('auth/user-not-found')) {
        errorMessage = 'No user found with this email.';
      }
      setError(errorMessage);
    }
    
    setIsLoading(false);
  };

  return (
    <div className="forgot-password-container">
      <div className="forgot-password-background">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
      </div>
      
      <div className="forgot-password-card">
        <Link to="/login" className="back-link">
          <ArrowLeft size={20} />
          <span>Back to login</span>
        </Link>
        
        <div className="forgot-password-header">
          <h2>Reset Password</h2>
          <p>Enter your email to receive a password reset link</p>
        </div>

        {error && <div className="forgot-password-error">{error}</div>}
        {message && <div className="forgot-password-success">{message}</div>}

        <form onSubmit={handleSubmit} className="forgot-password-form">
          <div className="input-group">
            <label htmlFor="email">Email Address</label>
            <div className="input-wrapper">
              <Mail className="input-icon" size={20} />
              <input
                id="email"
                type="email"
                placeholder="admin@techdrive.com"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                autoComplete="email"
              />
            </div>
          </div>

          <button 
            type="submit" 
            className={`forgot-password-button ${isLoading ? 'loading' : ''}`}
            disabled={isLoading}
          >
            {isLoading ? (
              <span className="loader"></span>
            ) : (
              <>
                <span>Send Reset Link</span>
                <Send size={20} />
              </>
            )}
          </button>
        </form>
      </div>
    </div>
  );
};

export default ForgotPassword;
