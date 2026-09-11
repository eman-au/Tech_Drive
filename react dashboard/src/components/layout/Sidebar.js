import React from 'react';
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard, Users, ClipboardCheck,
  BookOpen, AlertCircle, BarChart2, HelpCircle, Zap
} from 'lucide-react';
import './Sidebar.css';

const menuGroups = [
  {
    items: [
      { label: 'Dashboard', icon: LayoutDashboard, path: '/' },
    ],
  },
  {
    label: 'Operations',
    items: [
      { label: 'Bookings', icon: BookOpen, path: '/bookings' },
      { label: 'Complaints', icon: AlertCircle, path: '/complaints' },
    ],
  },
  {
    label: 'People',
    items: [
      { label: 'User Management', icon: Users, path: '/users' },
      { label: 'Worker Verification', icon: ClipboardCheck, path: '/verification' },
    ],
  },
  {
    label: 'Content & Config',
    items: [
      { label: 'Quiz Questions', icon: HelpCircle, path: '/quiz-questions' },
    ],
  },
  {
    label: 'Insights',
    items: [
      { label: 'Reports & Analytics', icon: BarChart2, path: '/analytics' },
    ],
  },
];

export default function Sidebar({ collapsed, onToggle, mobileOpen, onMobileClose }) {
  return (
    <>
      {mobileOpen && (
        <div className="sidebar-overlay" onClick={onMobileClose} />
      )}

      <aside className={`sidebar ${collapsed ? 'sidebar--collapsed' : ''} ${mobileOpen ? 'sidebar--mobile-open' : ''}`}>
        <div className="sidebar__logo">
          <div className="sidebar__logo-icon">
            <Zap size={20} />
          </div>
          {!collapsed && (
            <span className="sidebar__logo-text">Tech Drive</span>
          )}

          <button
            className="sidebar__toggle"
            onClick={onToggle}
            aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            title={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            <span className="sidebar__toggle-icon">
              {collapsed ? (
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <rect x="1" y="3" width="9" height="1.5" rx="0.75" fill="currentColor"/>
                  <rect x="1" y="7.25" width="9" height="1.5" rx="0.75" fill="currentColor"/>
                  <rect x="1" y="11.5" width="9" height="1.5" rx="0.75" fill="currentColor"/>
                  <path d="M12 5.5L14.5 8L12 10.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              ) : (
                <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
                  <rect x="6" y="3" width="9" height="1.5" rx="0.75" fill="currentColor"/>
                  <rect x="6" y="7.25" width="9" height="1.5" rx="0.75" fill="currentColor"/>
                  <rect x="6" y="11.5" width="9" height="1.5" rx="0.75" fill="currentColor"/>
                  <path d="M4 5.5L1.5 8L4 10.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
                </svg>
              )}
            </span>
          </button>
        </div>

        <nav className="sidebar__nav">
          {menuGroups.map((group, groupIndex) => (
            <div key={groupIndex} className="sidebar__group">
              {group.label && !collapsed && (
                <span className="sidebar__group-label">{group.label}</span>
              )}
              {group.items.map(({ label, icon: Icon, path }) => (
                <NavLink
                  key={path}
                  to={path}
                  end={path === '/'}
                  className={({ isActive }) =>
                    `sidebar__item ${isActive ? 'sidebar__item--active' : ''}`
                  }
                  title={collapsed ? label : ''}
                  onClick={onMobileClose}
                >
                  <Icon size={18} className="sidebar__item-icon" />
                  {!collapsed && <span className="sidebar__item-label">{label}</span>}
                </NavLink>
              ))}
            </div>
          ))}
        </nav>
      </aside>
    </>
  );
}
