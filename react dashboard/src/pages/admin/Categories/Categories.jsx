import React from 'react';
import { useNavigate } from 'react-router-dom';
import { Droplets, Zap } from 'lucide-react';
import PageHeader from '../../../components/common/PageHeader';
import { mockProviders } from '../../../data/mockData';
import './Categories.css';

const categories = [
  {
    id: 1,
    name: 'Plumbers',
    icon: Droplets,
    description: 'Licensed plumbing professionals for all water and pipe related services.',
    totalProviders: mockProviders.filter(p => p.type === 'Plumber').length,
    activeProviders: mockProviders.filter(p => p.type === 'Plumber' && p.status === 'approved').length,
    pendingProviders: mockProviders.filter(p => p.type === 'Plumber' && p.status === 'pending').length,
    blockedProviders: mockProviders.filter(p => p.type === 'Plumber' && p.status === 'blocked').length,
    color: 'blue',
  },
  {
    id: 2,
    name: 'Electricians',
    icon: Zap,
    description: 'Certified electricians for wiring, repairs, and electrical installations.',
    totalProviders: mockProviders.filter(p => p.type === 'Electrician').length,
    activeProviders: mockProviders.filter(p => p.type === 'Electrician' && p.status === 'approved').length,
    pendingProviders: mockProviders.filter(p => p.type === 'Electrician' && p.status === 'pending').length,
    blockedProviders: mockProviders.filter(p => p.type === 'Electrician' && p.status === 'blocked').length,
    color: 'amber',
  },
];

export default function Categories() {
  const navigate = useNavigate();

  const platformTotal = mockProviders.length;
  const platformActive = mockProviders.filter(p => p.status === 'approved').length;

  return (
    <div className="cat-container animate-fade">
      {/* SECTION 1 — PageHeader */}
      <PageHeader
        title="Service Categories"
        subtitle="Overview of all service types available on the platform."
      />

      {/* SECTION 2 — Category Cards */}
      <div className="cat-grid">
        {categories.map((cat) => (
          <div key={cat.id} className={`cat-card cat-card--${cat.color}`}>
            <div className="cat-card-top">
              <div className="cat-icon-wrapper">
                <cat.icon size={32} />
              </div>
              <div>
                <h2 className="cat-name">{cat.name}</h2>
                <p className="cat-description">{cat.description}</p>
              </div>
            </div>

            <hr className="cat-divider" />

            <div className="cat-stats-row">
              <div className="cat-stat">
                <span className="cat-stat-val">{cat.totalProviders}</span>
                <span className="cat-stat-label">Total</span>
              </div>
              <div className="cat-stat">
                <span className="cat-stat-val">{cat.activeProviders}</span>
                <span className="cat-stat-label">Active</span>
              </div>
              <div className="cat-stat">
                <span className="cat-stat-val">{cat.pendingProviders}</span>
                <span className="cat-stat-label">Pending</span>
              </div>
              <div className="cat-stat">
                <span className="cat-stat-val">{cat.blockedProviders}</span>
                <span className="cat-stat-label">Blocked</span>
              </div>
            </div>

            <button 
              className="cat-btn-view"
              onClick={() => navigate('/providers')}
            >
              View Providers
            </button>
          </div>
        ))}
      </div>

      {/* SECTION 3 — Summary Strip */}
      <div className="cat-summary-strip table-card">
        <div className="cat-summary-item">
          <span className="cat-summary-label">Total Categories</span>
          <span className="cat-summary-val">2</span>
        </div>
        <div className="cat-summary-item">
          <span className="cat-summary-label">Total Providers</span>
          <span className="cat-summary-val">{platformTotal}</span>
        </div>
        <div className="cat-summary-item">
          <span className="cat-summary-label">Total Active</span>
          <span className="cat-summary-val">{platformActive}</span>
        </div>
      </div>
    </div>
  );
}
