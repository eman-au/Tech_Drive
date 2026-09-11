import React from 'react';
import { Link } from 'react-router-dom';
import { ShieldAlert, ArrowLeft } from 'lucide-react';
import './Signup.css';

const Signup = () => {
  return (
    <div className="signup-container">
      <div className="signup-background">
        <div className="shape shape-1"></div>
        <div className="shape shape-2"></div>
        <div className="shape shape-3"></div>
      </div>
      
      <div className="signup-card" style={{ textAlign: 'center', padding: '40px 30px' }}>
        <div className="signup-header">
          <ShieldAlert size={48} style={{ color: '#EF4444', marginBottom: '16px' }} />
          <h2>Admin Registration Restricted</h2>
          <p style={{ marginTop: '12px', lineHeight: '1.6', color: '#4B5563' }}>
            Public registration for administrative access is disabled for security reasons.
            Admin accounts must be provisioned directly by system administrators in Firestore.
          </p>
        </div>

        <div style={{ marginTop: '32px' }}>
          <Link 
            to="/login" 
            className="signup-button"
            style={{ 
              display: 'inline-flex', 
              alignItems: 'center', 
              justifyContent: 'center',
              gap: '8px', 
              textDecoration: 'none' 
            }}
          >
            <ArrowLeft size={18} />
            <span>Return to Login</span>
          </Link>
        </div>
      </div>
    </div>
  );
};

export default Signup;
