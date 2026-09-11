import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Bell, Search, ChevronDown, LogOut, Settings, UserCircle, ShieldOff } from 'lucide-react';
import './Navbar.css';
import { useSearch } from '../../context/SearchContext';

export default function Navbar({ sidebarCollapsed, onLogout }) {
  const navigate = useNavigate();
  const [showNotif, setShowNotif] = useState(false);
  const [showProfileMenu, setShowProfileMenu] = useState(false);
  const { search, setSearch } = useSearch();

  const notifications = [
    { id: 1, text: 'New provider registration: Ahmed Khan', time: '2m ago', type: 'info' },
    { id: 2, text: 'Complaint submitted by Customer #1042', time: '15m ago', type: 'warning' },
    { id: 3, text: 'Provider Ali Raza passed verification', time: '1h ago', type: 'success' },
    { id: 4, text: 'Account auto-blocked after 3 failures', time: '3h ago', type: 'danger' },
  ];

  return (
    <header
      className="navbar"
      style={{ left: `var(--sidebar-${sidebarCollapsed ? 'collapsed' : 'width'})` }}
    >
      <div className="navbar__left">
        <div className="navbar__search">
          <Search size={16} className="navbar__search-icon" />
          <input
            type="text"
            placeholder="Search anything..."
            className="navbar__search-input"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <div className="navbar__right">
        {/* Notification bell */}
        <div className="navbar__notif-wrapper">
          <button
            className="navbar__icon-btn"
            onClick={() => setShowNotif(!showNotif)}
          >
            <Bell size={20} />
            <span className="navbar__badge">4</span>
          </button>

          {showNotif && (
            <div className="notif-dropdown">
              <div className="notif-dropdown__header">
                <h3>Notifications</h3>
                <button className="notif-dropdown__mark-all">Mark all read</button>
              </div>
              <div className="notif-dropdown__list">
                {notifications.map(n => (
                  <div key={n.id} className={`notif-item notif-item--${n.type}`}>
                    <div className={`notif-item__dot notif-item__dot--${n.type}`} />
                    <div>
                      <p className="notif-item__text">{n.text}</p>
                      <span className="notif-item__time">{n.time}</span>
                    </div>
                  </div>
                ))}
              </div>
              <div className="notif-dropdown__footer">
                <button onClick={() => { navigate('/notifications'); setShowNotif(false); }}>
                  View all notifications
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Admin profile */}
        <div className="navbar__profile-container">
          <div className="navbar__profile" onClick={() => setShowProfileMenu(!showProfileMenu)}>
            <div className="navbar__avatar">A</div>
            <div className="navbar__profile-info">
              <span className="navbar__profile-name">Admin</span>
              <span className="navbar__profile-role">Super Admin</span>
            </div>
            <ChevronDown size={14} className={`navbar__profile-arrow ${showProfileMenu ? 'navbar__profile-arrow--active' : ''}`} />
          </div>

          {showProfileMenu && (
            <>
              <div className="profile-dropdown-backdrop" onClick={() => setShowProfileMenu(false)} />
              <div className="profile-dropdown">
                <div className="profile-dropdown__header">
                  <div className="navbar__avatar navbar__avatar--dropdown">A</div>
                  <div>
                    <h4 className="profile-dropdown__name">Admin User</h4>
                    <p className="profile-dropdown__role">Super Admin</p>
                  </div>
                </div>
                <div className="profile-dropdown__list">
                  <button className="profile-dropdown__item" onClick={() => { navigate('/profile'); setShowProfileMenu(false); }}>
                    <UserCircle size={16} />
                    <span>Admin Profile</span>
                  </button>
                  <button className="profile-dropdown__item" onClick={() => { navigate('/settings'); setShowProfileMenu(false); }}>
                    <Settings size={16} />
                    <span>Settings</span>
                  </button>
                  <button className="profile-dropdown__item" onClick={() => { navigate('/blocked'); setShowProfileMenu(false); }}>
                    <ShieldOff size={16} />
                    <span>Blocked Accounts</span>
                  </button>
                  <div className="profile-dropdown__divider" />
                  <button 
                    className="profile-dropdown__item profile-dropdown__item--logout" 
                    onClick={() => {
                      setShowProfileMenu(false);
                      onLogout();
                    }}
                  >
                    <LogOut size={16} />
                    <span>Logout</span>
                  </button>
                </div>
              </div>
            </>
          )}
        </div>
      </div>
    </header>
  );
}