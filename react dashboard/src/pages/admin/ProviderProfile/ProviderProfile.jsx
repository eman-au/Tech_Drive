import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { ArrowLeft, Star, Phone, MapPin, Briefcase, Shield, CheckCircle, XCircle } from 'lucide-react';
import Badge from '../../../components/common/Badge';
import { mockProviders } from '../../../data/mockData';
import './ProviderProfile.css';

const mockReviews = [
  { id: 1, reviewer: 'Ahmed Khan', rating: 5, date: '2025-05-10', text: 'Excellent work, very professional and on time.', verified: true },
  { id: 2, reviewer: 'Sara Malik', rating: 4, date: '2025-05-03', text: 'Good service but arrived a bit late.', verified: true },
  { id: 3, reviewer: 'Usman Ali', rating: 3, date: '2025-04-28', text: 'Average experience, work was okay.', verified: false },
  { id: 4, reviewer: 'Fatima Noor', rating: 5, date: '2025-04-20', text: 'Very satisfied, will hire again.', verified: true },
  { id: 5, reviewer: 'Bilal Sheikh', rating: 2, date: '2025-04-15', text: 'Not happy with the quality of work.', verified: false },
];

const mockRatingBreakdown = [
  { stars: 5, count: 42 },
  { stars: 4, count: 28 },
  { stars: 3, count: 15 },
  { stars: 2, count: 8 },
  { stars: 1, count: 3 },
];

const statusMap = {
  approved: 'success',
  pending:  'warning',
  blocked:  'danger',
};

export default function ProviderProfile() {
  const { id } = useParams();
  const navigate = useNavigate();

  const provider = mockProviders.find(p => p.id.toString() === id);

  if (!provider) {
    return (
      <div className="pp-container animate-fade">
        <div className="pp-header">
          <button className="pp-back-btn" onClick={() => navigate(-1)}>
            <ArrowLeft size={20} /> Back
          </button>
        </div>
        <div className="table-card" style={{ padding: '40px', textAlign: 'center' }}>
          <h3>Provider not found</h3>
          <p className="text-muted">The provider you are looking for does not exist.</p>
        </div>
      </div>
    );
  }

  const isPass = provider.quizScore >= 70;
  const isMaxAttempts = provider.attempts >= 3;

  return (
    <div className="pp-container animate-fade">
      {/* SECTION 1 — Page Header */}
      <div className="pp-header">
        <button className="pp-back-btn" onClick={() => navigate('/providers')}>
          <ArrowLeft size={20} /> Back
        </button>

        <div className="pp-header-content">
          <div className="pp-header-left">
            <div className="pp-avatar">
              {provider.name.charAt(0)}
            </div>
            <div className="pp-header-info">
              <h1 className="pp-name">{provider.name}</h1>
              <div className="pp-header-meta">
                <Badge label={provider.type} type={provider.type === 'Electrician' ? 'info' : 'primary'} />
                <span className="pp-city"><MapPin size={14} /> {provider.city}</span>
                <Badge label={provider.status} type={statusMap[provider.status]} />
              </div>
            </div>
          </div>

          <div className="pp-header-actions">
            {provider.status !== 'approved' && provider.status !== 'blocked' && (
              <button className="pp-btn pp-btn--success">
                <CheckCircle size={16} /> Approve
              </button>
            )}
            {provider.status !== 'blocked' && (
              <button className="pp-btn pp-btn--danger">
                <Shield size={16} /> Block
              </button>
            )}
            {provider.status === 'blocked' && (
              <button className="pp-btn pp-btn--success">
                <XCircle size={16} /> Unblock
              </button>
            )}
          </div>
        </div>
      </div>

      {/* SECTION 2 — Info Cards Row (4 cards) */}
      <div className="pp-stats-grid">
        <div className="table-card pp-stat-card">
          <p className="pp-stat-label">Quiz Score</p>
          <h2 className={`pp-stat-value ${provider.quizScore !== null ? (isPass ? 'pp-text-success' : 'pp-text-danger') : ''}`}>
            {provider.quizScore !== null ? `${provider.quizScore}%` : '—'}
          </h2>
        </div>
        <div className="table-card pp-stat-card">
          <p className="pp-stat-label">Attempts</p>
          <h2 className={`pp-stat-value ${isMaxAttempts ? 'pp-text-warning' : ''}`}>
            {provider.attempts}/3
          </h2>
        </div>
        <div className="table-card pp-stat-card">
          <p className="pp-stat-label">Rating</p>
          <h2 className="pp-stat-value pp-rating-value">
            {provider.rating ? provider.rating : '—'} <Star size={20} className="pp-star-icon" fill={provider.rating ? 'currentColor' : 'none'} />
          </h2>
        </div>
        <div className="table-card pp-stat-card">
          <p className="pp-stat-label">Completed Jobs</p>
          <h2 className="pp-stat-value">{provider.completedJobs}</h2>
        </div>
      </div>

      {/* SECTION 3 — Two column layout */}
      <div className="pp-main-grid">
        <div className="table-card pp-details-card">
          <h3 className="pp-card-title">Provider Details</h3>
          <div className="pp-details-list">
            <div className="pp-detail-item">
              <Phone size={18} className="pp-detail-icon" />
              <div>
                <p className="pp-detail-label">Phone Number</p>
                <p className="pp-detail-val">{provider.phone}</p>
              </div>
            </div>
            <div className="pp-detail-item">
              <MapPin size={18} className="pp-detail-icon" />
              <div>
                <p className="pp-detail-label">City</p>
                <p className="pp-detail-val">{provider.city}</p>
              </div>
            </div>
            <div className="pp-detail-item">
              <Briefcase size={18} className="pp-detail-icon" />
              <div>
                <p className="pp-detail-label">Service Type</p>
                <p className="pp-detail-val">{provider.type}</p>
              </div>
            </div>
            <div className="pp-detail-item">
              <Shield size={18} className="pp-detail-icon" />
              <div>
                <p className="pp-detail-label">Current Status</p>
                <p className="pp-detail-val pp-capitalize">{provider.status}</p>
              </div>
            </div>
          </div>
        </div>

        <div className="table-card pp-rating-card">
          <h3 className="pp-card-title">Rating Summary</h3>
          <div className="pp-rating-summary">
            <div className="pp-rating-left">
              <h1 className="pp-rating-avg">{provider.rating ? provider.rating : '0.0'}</h1>
              <div className="pp-rating-stars">
                {[1, 2, 3, 4, 5].map(star => (
                  <Star key={star} size={18} className={provider.rating && provider.rating >= star ? 'pp-star-filled' : 'pp-star-empty'} fill={provider.rating && provider.rating >= star ? 'currentColor' : 'none'} />
                ))}
              </div>
              <p className="pp-rating-count">Based on 96 reviews</p>
            </div>
            <div className="pp-rating-bars">
              {mockRatingBreakdown.map(bar => (
                <div key={bar.stars} className="pp-rating-bar-row">
                  <span className="pp-bar-label">{bar.stars} <Star size={12} fill="currentColor" /></span>
                  <div className="pp-bar-track">
                    <div className="pp-bar-fill" style={{ width: `${(bar.count / 42) * 100}%` }}></div>
                  </div>
                  <span className="pp-bar-count">{bar.count}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      {/* SECTION 4 — Reviews List */}
      <div className="table-card pp-reviews-section">
        <h3 className="pp-card-title">Customer Reviews</h3>
        {mockReviews.length > 0 ? (
          <div className="pp-reviews-list">
            {mockReviews.map(review => (
              <div key={review.id} className="pp-review-card">
                <div className="pp-review-header">
                  <div className="pp-review-author">
                    <div className="pp-review-avatar">{review.reviewer.charAt(0)}</div>
                    <div>
                      <p className="pp-reviewer-name">
                        {review.reviewer}
                        {review.verified && <CheckCircle size={14} className="pp-verified-icon" />}
                      </p>
                      <p className="pp-review-date">{review.date}</p>
                    </div>
                  </div>
                  <div className="pp-review-stars">
                    {[1, 2, 3, 4, 5].map(star => (
                      <Star key={star} size={14} className={review.rating >= star ? 'pp-star-filled' : 'pp-star-empty'} fill={review.rating >= star ? 'currentColor' : 'none'} />
                    ))}
                  </div>
                </div>
                <p className="pp-review-text">{review.text}</p>
              </div>
            ))}
          </div>
        ) : (
          <div className="pp-empty-reviews">
            <Star size={32} className="pp-text-muted" />
            <p>No customer reviews yet.</p>
          </div>
        )}
      </div>
    </div>
  );
}
