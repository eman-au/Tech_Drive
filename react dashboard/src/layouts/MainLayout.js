import React, { useState } from 'react';
import { Outlet, useNavigate } from 'react-router-dom';
import { LogOut } from 'lucide-react';
import Sidebar from '../components/layout/Sidebar';
import Navbar from '../components/layout/Navbar';
import { SearchProvider } from '../context/SearchContext';
import { useAuth } from '../context/AuthContext';
import './MainLayout.css';

export default function MainLayout() {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [showLogoutModal, setShowLogoutModal] = useState(false);

  const { logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = async () => {
    await logout();
    setShowLogoutModal(false);
    navigate('/login');
  };

  return (
    <div className="main-layout">
      <Sidebar
        collapsed={collapsed}
        onToggle={() => setCollapsed(prev => !prev)}
        mobileOpen={mobileOpen}
        onMobileClose={() => setMobileOpen(false)}
        onLogout={() => setShowLogoutModal(true)}
      />

      <SearchProvider>
        <div
          className={`main-layout__content ${collapsed ? 'main-layout__content--collapsed' : ''}`}
        >
          <Navbar
            onMenuClick={() => setMobileOpen(prev => !prev)}
            sidebarCollapsed={collapsed}
            onLogout={() => setShowLogoutModal(true)}
          />

          <main className="main-layout__main">
            <Outlet />
          </main>
        </div>
      </SearchProvider>

      {showLogoutModal && (
        <div className="logout-modal-overlay">
          <div className="logout-modal">
            <div className="logout-modal__icon">
              <LogOut size={28} />
            </div>
            <h3 className="logout-modal__title">Confirm Logout</h3>
            <p className="logout-modal__message">Are you sure you want to log out of the Tech Drive admin panel?</p>
            <div className="logout-modal__actions">
              <button className="logout-modal__btn logout-modal__btn--cancel" onClick={() => setShowLogoutModal(false)}>
                Cancel
              </button>
              <button className="logout-modal__btn logout-modal__btn--confirm" onClick={handleLogout}>
                Logout
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}