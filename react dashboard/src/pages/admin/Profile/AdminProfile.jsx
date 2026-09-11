import React, { useState, useEffect, useRef } from 'react';
import { User, Mail, Phone, Shield, Calendar, Camera, Save, Activity, Loader2 } from 'lucide-react';
import { doc, onSnapshot, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../../config/firebase';
import { useAuth } from '../../../context/AuthContext';
import { uploadImageToCloudinary } from '../../../services/cloudinary';
import PageHeader from '../../../components/common/PageHeader';
import { useNavigate } from 'react-router-dom';
import './AdminProfile.css';

export default function AdminProfile() {
  const { currentUser } = useAuth();
  const navigate = useNavigate();
  const fileInputRef = useRef(null);

  const [isSaved, setIsSaved] = useState(false);
  const [isSaving, setIsSaving] = useState(false);
  const [isUploading, setIsUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');
  const [error, setError] = useState('');

  const [profileData, setProfileData] = useState({
    name: '',
    email: '',
    phone: '',
    role: '',
    joinedDate: '',
    status: '',
    profileImage: ''
  });

  useEffect(() => {
    if (!currentUser) {
      navigate('/login');
      return;
    }

    const docRef = doc(db, 'admins', currentUser.uid);
    const unsubscribe = onSnapshot(docRef, (docSnap) => {
      if (docSnap.exists()) {
        const data = docSnap.data();
        let joinedDateStr = 'Unknown';
        if (data.createdAt) {
          const date = data.createdAt.toDate ? data.createdAt.toDate() : new Date(data.createdAt);
          joinedDateStr = date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
        }

        setProfileData(prev => ({
          ...prev,
          name: data.name || '',
          email: data.email || currentUser.email || '',
          phone: data.phone || '',
          role: data.role || 'Admin',
          joinedDate: joinedDateStr,
          status: data.status || 'Active',
          profileImage: data.profileImage || ''
        }));
      }
    }, (err) => {
      console.error("Error fetching admin profile:", err);
      setError("Failed to load profile data.");
    });

    return () => unsubscribe();
  }, [currentUser, navigate]);

  const handleSave = async (e) => {
    e.preventDefault();
    if (!currentUser) return;
    
    setIsSaving(true);
    setError('');
    
    try {
      const docRef = doc(db, 'admins', currentUser.uid);
      await updateDoc(docRef, {
        name: profileData.name,
        phone: profileData.phone,
        updatedAt: serverTimestamp()
      });
      setIsSaved(true);
      setTimeout(() => setIsSaved(false), 3000);
    } catch (err) {
      console.error("Error updating profile:", err);
      setError("Failed to update profile.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;

    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/jpg'];
    if (!validTypes.includes(file.type)) {
      setUploadError("Invalid file type. Please upload JPG, PNG or WEBP.");
      setTimeout(() => setUploadError(''), 3000);
      return;
    }

    // Validate size (5MB limit)
    if (file.size > 5 * 1024 * 1024) {
      setUploadError("Image too large. Maximum size is 5MB.");
      setTimeout(() => setUploadError(''), 3000);
      return;
    }

    setIsUploading(true);
    setUploadError('');

    try {
      const imageUrl = await uploadImageToCloudinary(file);
      
      const docRef = doc(db, 'admins', currentUser.uid);
      await updateDoc(docRef, {
        profileImage: imageUrl,
        updatedAt: serverTimestamp()
      });
    } catch (err) {
      console.error("Error uploading image:", err);
      setUploadError(err.message || "Failed to upload image.");
    } finally {
      setIsUploading(false);
      // clear the input
      if (fileInputRef.current) {
        fileInputRef.current.value = '';
      }
    }
  };

  const getInitials = (name) => {
    if (!name) return 'A';
    return name.charAt(0).toUpperCase();
  };

  return (
    <div className="ap-container">

      <div className="ap-header">
        <PageHeader
          title="Admin Profile"
          subtitle="Manage your personal admin identity and information."
        />

        <div className="ap-status-pill">
          <span className="ap-pulse-dot"></span>
          System Admin {profileData.status}
        </div>
      </div>

      <div className="ap-grid">

        {/* LEFT PROFILE */}
        <div className="ap-card ap-profile-card">

          <div className="ap-avatar-wrapper">
            {profileData.profileImage ? (
              <img src={profileData.profileImage} alt="Profile" className="ap-avatar-large" style={{ objectFit: 'cover' }} />
            ) : (
              <div className="ap-avatar-large">{getInitials(profileData.name)}</div>
            )}
            <button 
              className="ap-avatar-overlay" 
              onClick={() => fileInputRef.current?.click()} 
              disabled={isUploading}
              style={{ cursor: isUploading ? 'not-allowed' : 'pointer' }}
            >
              {isUploading ? <Loader2 size={14} className="ap-animate-spin" /> : <Camera size={14} />}
            </button>
            <input 
              type="file" 
              ref={fileInputRef} 
              onChange={handleImageUpload} 
              style={{ display: 'none' }} 
              accept="image/jpeg, image/png, image/webp" 
            />
          </div>
          {uploadError && <p className="ap-error-text" style={{ color: 'red', fontSize: '12px', marginTop: '8px' }}>{uploadError}</p>}

          <h2 className="ap-profile-name">{profileData.name || 'Loading...'}</h2>
          <p className="ap-profile-email">{profileData.email}</p>
          <span className="ap-role-tag">{profileData.role}</span>

          <div className="ap-details-list">
            <div className="ap-detail-item">
              <Shield size={16} />
              <span>{profileData.role}</span>
            </div>

            <div className="ap-detail-item">
              <Calendar size={16} />
              <span>{profileData.joinedDate}</span>
            </div>

            <div className="ap-detail-item">
              <Activity size={16} />
              <span className="ap-text-success">{profileData.status}</span>
            </div>
          </div>
        </div>

        {/* RIGHT EDIT */}
        <div className="ap-card">

          <h3 className="ap-card-title">
            <User size={16} />
            Edit Profile
          </h3>

          {error && <div className="ap-error-banner" style={{ color: 'red', marginBottom: '16px', fontSize: '13px' }}>{error}</div>}

          <form onSubmit={handleSave} className="ap-form">

            <div className="ap-form-grid">

              <div className="ap-form-group">
                <label>Name</label>
                <input
                  className="ap-input"
                  value={profileData.name}
                  onChange={(e) =>
                    setProfileData({ ...profileData, name: e.target.value })
                  }
                  required
                />
              </div>

              <div className="ap-form-group">
                <label>Email</label>
                <input
                  className="ap-input"
                  value={profileData.email}
                  disabled
                  title="Email cannot be changed here"
                  style={{ opacity: 0.6, cursor: 'not-allowed' }}
                />
              </div>

              <div className="ap-form-group">
                <label>Phone</label>
                <input
                  className="ap-input"
                  value={profileData.phone}
                  onChange={(e) =>
                    setProfileData({ ...profileData, phone: e.target.value })
                  }
                  placeholder="+92-300-0000000"
                />
              </div>

              <div className="ap-form-group">
                <label>Role</label>
                <input
                  className="ap-input"
                  value={profileData.role}
                  disabled
                  style={{ opacity: 0.6, cursor: 'not-allowed' }}
                />
              </div>

            </div>

            <div className="ap-form-footer">

              <button type="submit" className="ap-btn-save" disabled={isSaving} style={{ opacity: isSaving ? 0.7 : 1 }}>
                {isSaving ? <Loader2 size={16} className="ap-animate-spin" /> : <Save size={16} />}
                {isSaving ? 'Saving...' : 'Save Changes'}
              </button>

              {isSaved && (
                <span className="ap-success-toast">
                  Saved successfully
                </span>
              )}

            </div>

          </form>
        </div>

      </div>
    </div>
  );
}