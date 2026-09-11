import React, { useState, useEffect } from 'react';
import { db, auth } from '../../config/firebase';
import { doc, onSnapshot, updateDoc, serverTimestamp } from 'firebase/firestore';
import { 
  EmailAuthProvider, 
  reauthenticateWithCredential, 
  updatePassword, 
  sendPasswordResetEmail 
} from 'firebase/auth';
import { useAuth } from '../../context/AuthContext';
import {
  User,
  Shield,
  Key,
  Moon,
  Sun,
  Mail,
  Save,
  CheckCircle2,
  AlertCircle,
  Clock,
  Send,
  Eye,
  EyeOff,
  RefreshCw,
  Info
} from 'lucide-react';
import PageHeader from '../../components/common/PageHeader';
import './Settings.css';

export default function Settings() {
  const { currentUser } = useAuth();

  // Admin Document Data from Firestore admins/{uid}
  const [adminData, setAdminData] = useState({
    name: '',
    email: '',
    phone: '',
    role: '',
    status: '',
    profileImage: '',
    createdAt: null,
  });

  // Admin Profile Form State (Editing Name & Phone ONLY)
  const [nameInput, setNameInput] = useState('');
  const [phoneInput, setPhoneInput] = useState('');
  const [profileSaving, setProfileSaving] = useState(false);
  const [profileFeedback, setProfileFeedback] = useState(null);

  // Security Form State
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [showCurrentPassword, setShowCurrentPassword] = useState(false);
  const [showNewPassword, setShowNewPassword] = useState(false);
  const [passwordSaving, setPasswordSaving] = useState(false);
  const [passwordFeedback, setPasswordFeedback] = useState(null);

  // Password Reset Email State
  const [resetEmailSending, setResetEmailSending] = useState(false);
  const [resetEmailFeedback, setResetEmailFeedback] = useState(null);

  // Appearance State (Dark Mode ONLY)
  const [darkMode, setDarkMode] = useState(localStorage.getItem('darkMode') === 'true');

  // Real-time Listener on admins/{uid}
  useEffect(() => {
    if (!currentUser) return;

    const adminRef = doc(db, 'admins', currentUser.uid);
    const unsub = onSnapshot(
      adminRef,
      (docSnap) => {
        if (docSnap.exists()) {
          const data = docSnap.data();
          setAdminData({
            name: data.name || '',
            email: data.email || currentUser.email || '',
            phone: data.phone || '',
            role: data.role || 'Admin',
            status: data.status || 'Active',
            profileImage: data.profileImage || '',
            createdAt: data.createdAt || null,
          });

          // Initialize form inputs
          setNameInput(data.name || '');
          setPhoneInput(data.phone || '');
        } else {
          setAdminData((prev) => ({
            ...prev,
            email: currentUser.email || '',
          }));
        }
      },
      (err) => {
        console.error('Error listening to admin doc:', err);
      }
    );

    return () => unsub();
  }, [currentUser]);

  // Dark Mode Toggle & LocalStorage Sync
  const handleDarkModeToggle = (e) => {
    const isChecked = e.target.checked;
    setDarkMode(isChecked);
    localStorage.setItem('darkMode', isChecked ? 'true' : 'false');
    if (isChecked) {
      document.body.classList.add('dark-theme');
    } else {
      document.body.classList.remove('dark-theme');
    }
  };

  // Save Admin Profile (Edits Name & Phone ONLY in admins/{uid})
  const handleSaveProfile = async (e) => {
    e.preventDefault();
    if (!currentUser) return;

    setProfileFeedback(null);
    setProfileSaving(true);

    try {
      const adminRef = doc(db, 'admins', currentUser.uid);
      await updateDoc(adminRef, {
        name: nameInput.trim(),
        phone: phoneInput.trim(),
        updatedAt: serverTimestamp(),
      });

      setProfileFeedback({
        type: 'success',
        message: 'Admin profile updated successfully!',
      });
    } catch (err) {
      console.error('Error updating admin profile:', err);
      setProfileFeedback({
        type: 'error',
        message: 'Failed to update profile: ' + (err.message || 'Firestore error.'),
      });
    } finally {
      setProfileSaving(false);
    }
  };

  // Change Password via Firebase Auth
  const handleChangePassword = async (e) => {
    e.preventDefault();
    if (!auth.currentUser) return;

    setPasswordFeedback(null);

    if (newPassword.length < 6) {
      setPasswordFeedback({
        type: 'error',
        message: 'New password must be at least 6 characters long.',
      });
      return;
    }

    if (newPassword !== confirmPassword) {
      setPasswordFeedback({
        type: 'error',
        message: 'New password and confirmation do not match.',
      });
      return;
    }

    setPasswordSaving(true);

    try {
      // 1. Re-authenticate admin with current credentials
      const credential = EmailAuthProvider.credential(
        auth.currentUser.email,
        currentPassword
      );
      await reauthenticateWithCredential(auth.currentUser, credential);

      // 2. Update password in Firebase Auth
      await updatePassword(auth.currentUser, newPassword);

      setPasswordFeedback({
        type: 'success',
        message: 'Password changed successfully!',
      });

      // Clear password inputs
      setCurrentPassword('');
      setNewPassword('');
      setConfirmPassword('');
    } catch (err) {
      console.error('Error updating password:', err);
      let errorMsg = 'Failed to change password.';
      if (err.code === 'auth/wrong-password' || err.code === 'auth/invalid-credential') {
        errorMsg = 'Current password is incorrect.';
      } else if (err.code === 'auth/weak-password') {
        errorMsg = 'The new password is too weak.';
      } else if (err.message) {
        errorMsg = err.message;
      }

      setPasswordFeedback({
        type: 'error',
        message: errorMsg,
      });
    } finally {
      setPasswordSaving(false);
    }
  };

  // Send Password Reset Email via Firebase Auth
  const handleSendResetEmail = async () => {
    if (!auth.currentUser || !auth.currentUser.email) return;

    setResetEmailFeedback(null);
    setResetEmailSending(true);

    try {
      await sendPasswordResetEmail(auth, auth.currentUser.email);
      setResetEmailFeedback({
        type: 'success',
        message: `Password reset link sent to ${auth.currentUser.email}. Check your inbox.`,
      });
    } catch (err) {
      console.error('Error sending reset email:', err);
      setResetEmailFeedback({
        type: 'error',
        message: 'Failed to send password reset email: ' + (err.message || 'Auth error.'),
      });
    } finally {
      setResetEmailSending(false);
    }
  };

  // Helper to format Member Since timestamp
  const formatMemberSince = () => {
    if (adminData.createdAt) {
      try {
        const d = adminData.createdAt.toDate
          ? adminData.createdAt.toDate()
          : new Date(adminData.createdAt);
        if (!isNaN(d.getTime())) {
          return d.toLocaleDateString('en-US', {
            year: 'numeric',
            month: 'long',
            day: 'numeric',
          });
        }
      } catch (e) {}
    }
    if (currentUser && currentUser.metadata && currentUser.metadata.creationTime) {
      try {
        const d = new Date(currentUser.metadata.creationTime);
        return d.toLocaleDateString('en-US', {
          year: 'numeric',
          month: 'long',
          day: 'numeric',
        });
      } catch (e) {}
    }
    return 'N/A';
  };

  return (
    <div className="settings animate-fade">
      <PageHeader
        title="Admin Settings & Account Controls"
        subtitle="Manage administrator profile details, authentication security, theme preferences, and account metadata."
      />

      <div className="settings-grid">
        {/* LEFT COLUMN: ADMIN PROFILE & ACCOUNT SECURITY */}
        <div className="settings-column">
          {/* SECTION 1: ADMIN PROFILE */}
          <div className="settings-card">
            <div className="settings-card__header">
              <div className="icon-box icon-box--theme">
                <User size={20} />
              </div>
              <div>
                <h3>Admin Profile</h3>
                <p>View profile avatar and edit administrator name and phone number</p>
              </div>
            </div>

            <div className="settings-card__body">
              {/* DISPLAY PROFILE IMAGE OR AVATAR (NO UPLOAD) */}
              <div className="admin-profile-avatar-bar">
                <div className="admin-avatar-frame">
                  {adminData.profileImage ? (
                    <img src={adminData.profileImage} alt="Admin Profile" />
                  ) : (
                    <span>{(adminData.name || currentUser?.email || 'A').charAt(0).toUpperCase()}</span>
                  )}
                </div>
                <div className="admin-avatar-info">
                  <span className="admin-avatar-name">{adminData.name || 'Administrator'}</span>
                  <span className="admin-avatar-email">{adminData.email}</span>
                </div>
              </div>

              {profileFeedback && (
                <div className={`settings-alert settings-alert--${profileFeedback.type}`}>
                  {profileFeedback.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
                  <span>{profileFeedback.message}</span>
                </div>
              )}

              {/* PROFILE FORM: NAME & PHONE ONLY */}
              <form onSubmit={handleSaveProfile}>
                <div className="form-group">
                  <label>Full Name</label>
                  <input
                    type="text"
                    placeholder="Administrator Full Name"
                    value={nameInput}
                    onChange={(e) => setNameInput(e.target.value)}
                    required
                  />
                </div>

                <div className="form-group">
                  <label>Phone Number</label>
                  <input
                    type="text"
                    placeholder="+92 300 1234567"
                    value={phoneInput}
                    onChange={(e) => setPhoneInput(e.target.value)}
                  />
                </div>

                <button
                  type="submit"
                  disabled={profileSaving}
                  className="btn-settings-primary"
                >
                  {profileSaving ? (
                    <>
                      <RefreshCw size={14} className="spin-icon" />
                      <span>Saving Profile...</span>
                    </>
                  ) : (
                    <>
                      <Save size={14} />
                      <span>Save Profile Changes</span>
                    </>
                  )}
                </button>
              </form>
            </div>
          </div>

          {/* SECTION 2: ACCOUNT SECURITY */}
          <div className="settings-card">
            <div className="settings-card__header">
              <div className="icon-box icon-box--security">
                <Shield size={20} />
              </div>
              <div>
                <h3>Account Security</h3>
                <p>Update authentication password and request security reset links</p>
              </div>
            </div>

            <div className="settings-card__body">
              {/* CHANGE PASSWORD FORM */}
              <form onSubmit={handleChangePassword} style={{ marginBottom: '24px' }}>
                <h4 className="subsection-title"><Key size={14} /> Change Password</h4>

                {passwordFeedback && (
                  <div className={`settings-alert settings-alert--${passwordFeedback.type}`}>
                    {passwordFeedback.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
                    <span>{passwordFeedback.message}</span>
                  </div>
                )}

                <div className="form-group">
                  <label>Current Password</label>
                  <div className="pwd-input-wrap">
                    <input
                      type={showCurrentPassword ? 'text' : 'password'}
                      placeholder="Enter current password"
                      value={currentPassword}
                      onChange={(e) => setCurrentPassword(e.target.value)}
                      required
                    />
                    <button
                      type="button"
                      className="pwd-toggle-btn"
                      onClick={() => setShowCurrentPassword(!showCurrentPassword)}
                    >
                      {showCurrentPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>

                <div className="form-group">
                  <label>New Password</label>
                  <div className="pwd-input-wrap">
                    <input
                      type={showNewPassword ? 'text' : 'password'}
                      placeholder="At least 6 characters"
                      value={newPassword}
                      onChange={(e) => setNewPassword(e.target.value)}
                      required
                    />
                    <button
                      type="button"
                      className="pwd-toggle-btn"
                      onClick={() => setShowNewPassword(!showNewPassword)}
                    >
                      {showNewPassword ? <EyeOff size={16} /> : <Eye size={16} />}
                    </button>
                  </div>
                </div>

                <div className="form-group">
                  <label>Confirm New Password</label>
                  <input
                    type="password"
                    placeholder="Re-enter new password"
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    required
                  />
                </div>

                <button
                  type="submit"
                  disabled={passwordSaving}
                  className="btn-settings-primary"
                >
                  {passwordSaving ? (
                    <>
                      <RefreshCw size={14} className="spin-icon" />
                      <span>Updating Password...</span>
                    </>
                  ) : (
                    <>
                      <Save size={14} />
                      <span>Update Password</span>
                    </>
                  )}
                </button>
              </form>

              <hr className="card-divider" />

              {/* PASSWORD RESET EMAIL ACTION */}
              <div style={{ marginTop: '20px' }}>
                <h4 className="subsection-title"><Mail size={14} /> Password Reset Email</h4>
                <p className="subsection-desc">
                  Send an official Firebase Authentication password reset email to <strong>{currentUser?.email}</strong>.
                </p>

                {resetEmailFeedback && (
                  <div className={`settings-alert settings-alert--${resetEmailFeedback.type}`}>
                    {resetEmailFeedback.type === 'success' ? <CheckCircle2 size={16} /> : <AlertCircle size={16} />}
                    <span>{resetEmailFeedback.message}</span>
                  </div>
                )}

                <button
                  type="button"
                  onClick={handleSendResetEmail}
                  disabled={resetEmailSending}
                  className="btn-settings-secondary"
                >
                  {resetEmailSending ? (
                    <>
                      <RefreshCw size={14} className="spin-icon" />
                      <span>Sending Reset Email...</span>
                    </>
                  ) : (
                    <>
                      <Send size={14} />
                      <span>Send Password Reset Email</span>
                    </>
                  )}
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT COLUMN: APPEARANCE & ACCOUNT INFORMATION */}
        <div className="settings-column">
          {/* SECTION 3: APPEARANCE (DARK MODE ONLY) */}
          <div className="settings-card">
            <div className="settings-card__header">
              <div className="icon-box icon-box--theme">
                {darkMode ? <Moon size={20} /> : <Sun size={20} />}
              </div>
              <div>
                <h3>Appearance</h3>
                <p>Customize dashboard interface visual theme</p>
              </div>
            </div>

            <div className="settings-card__body">
              <div className="setting-row">
                <div className="setting-info">
                  <span className="setting-title">Dark Mode Theme</span>
                  <span className="setting-desc">Switch portal to high-contrast dark theme mode</span>
                </div>
                <label className="toggle-switch">
                  <input
                    type="checkbox"
                    checked={darkMode}
                    onChange={handleDarkModeToggle}
                  />
                  <span className="toggle-slider"></span>
                </label>
              </div>
            </div>
          </div>

          {/* SECTION 4: ACCOUNT INFORMATION */}
          <div className="settings-card">
            <div className="settings-card__header">
              <div className="icon-box icon-box--info">
                <Info size={20} />
              </div>
              <div>
                <h3>Account Information</h3>
                <p>Read-only administrator account and authorization details</p>
              </div>
            </div>

            <div className="settings-card__body">
              <div className="account-info-list">
                <div className="info-item">
                  <span className="info-label">Admin UID:</span>
                  <span className="info-val code-val">{currentUser?.uid || 'N/A'}</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Email Address:</span>
                  <span className="info-val">{currentUser?.email || adminData.email || 'N/A'}</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Role:</span>
                  <span className="info-val badge-role">{adminData.role || 'Admin'}</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Account Status:</span>
                  <span className="info-val badge-status">{adminData.status || 'Active'}</span>
                </div>
                <div className="info-item">
                  <span className="info-label">Member Since:</span>
                  <span className="info-val"><Clock size={12} /> {formatMemberSince()}</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}