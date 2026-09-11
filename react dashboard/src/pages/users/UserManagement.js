import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { db } from '../../config/firebase';
import { collection, onSnapshot } from 'firebase/firestore';
import {
  Users,
  Search,
  Eye,
  Mail,
  Phone,
  Calendar,
  Briefcase,
  AlertCircle,
  Clock,
  X,
  Star,
  ChevronLeft,
  ChevronRight,
  RefreshCw,
  Tag,
  ShieldCheck
} from 'lucide-react';
import PageHeader from '../../components/common/PageHeader';
import Badge from '../../components/common/Badge';
import './UserManagement.css';

const USERS_PER_PAGE = 10;

export default function UserManagement() {
  // Firestore Snapshot States
  const [users, setUsers] = useState([]);
  const [workerRequestsMap, setWorkerRequestsMap] = useState({});
  const [workerDocsMap, setWorkerDocsMap] = useState({});
  const [orders, setOrders] = useState([]);
  const [ratings, setRatings] = useState([]);
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Filtering & Pagination State
  const [activeTab, setActiveTab] = useState('All Users'); // 'All Users', 'Customers', 'Workers', 'Approved Workers', 'Pending Verification'
  const [searchQuery, setSearchQuery] = useState('');
  const [roleFilter, setRoleFilter] = useState('All');
  const [verificationFilter, setVerificationFilter] = useState('All');
  const [currentPage, setCurrentPage] = useState(1);

  // Selected User for Detailed Profile Modal
  const [selectedUser, setSelectedUser] = useState(null);

  // Real-time Firestore Listeners
  useEffect(() => {
    setLoading(true);
    let loadedCount = 0;
    const totalCollections = 6;

    const checkFinished = () => {
      loadedCount++;
      if (loadedCount >= totalCollections) {
        setLoading(false);
      }
    };

    const unsubUsers = onSnapshot(
      collection(db, 'users'),
      (snap) => {
        const uList = snap.docs.map((dSnap) => ({
          id: dSnap.id,
          uid: dSnap.id,
          ...dSnap.data()
        }));
        setUsers(uList);
        checkFinished();
      },
      (err) => {
        console.error("Error loading users:", err);
        setError("Failed to load user directory.");
        checkFinished();
      }
    );

    const unsubRequests = onSnapshot(
      collection(db, 'worker_requests'),
      (snap) => {
        const reqMap = {};
        snap.docs.forEach((dSnap) => {
          reqMap[dSnap.id] = dSnap.data();
        });
        setWorkerRequestsMap(reqMap);
        checkFinished();
      },
      (err) => {
        console.error("Error loading worker_requests:", err);
        checkFinished();
      }
    );

    const unsubDocs = onSnapshot(
      collection(db, 'worker_documents'),
      (snap) => {
        const dMap = {};
        snap.docs.forEach((dSnap) => {
          const data = dSnap.data() || {};
          dMap[dSnap.id] = data.documents || data;
        });
        setWorkerDocsMap(dMap);
        checkFinished();
      },
      (err) => {
        console.error("Error loading worker_documents:", err);
        checkFinished();
      }
    );

    const unsubOrders = onSnapshot(
      collection(db, 'orders'),
      (snap) => {
        setOrders(snap.docs.map((dSnap) => ({ id: dSnap.id, ...dSnap.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading orders:", err);
        checkFinished();
      }
    );

    const unsubRatings = onSnapshot(
      collection(db, 'ratings'),
      (snap) => {
        setRatings(snap.docs.map((dSnap) => ({ id: dSnap.id, ...dSnap.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading ratings:", err);
        checkFinished();
      }
    );

    const unsubComplaints = onSnapshot(
      collection(db, 'complaints'),
      (snap) => {
        setComplaints(snap.docs.map((dSnap) => ({ id: dSnap.id, ...dSnap.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading complaints:", err);
        checkFinished();
      }
    );

    return () => {
      unsubUsers();
      unsubRequests();
      unsubDocs();
      unsubOrders();
      unsubRatings();
      unsubComplaints();
    };
  }, []);

  // Compute Completed Orders per user map
  const completedOrdersCountMap = useMemo(() => {
    const map = {};
    orders.forEach((o) => {
      if ((o.status || '').toLowerCase() === 'completed') {
        if (o.customerId) map[o.customerId] = (map[o.customerId] || 0) + 1;
        if (o.workerId) map[o.workerId] = (map[o.workerId] || 0) + 1;
      }
    });
    return map;
  }, [orders]);

  // Compute Average Rating per worker map
  const workerRatingMap = useMemo(() => {
    const map = {};
    const sumMap = {};
    const countMap = {};

    ratings.forEach((r) => {
      const wId = r.workerId;
      const num = Number(r.rating);
      if (wId && !isNaN(num) && num > 0) {
        sumMap[wId] = (sumMap[wId] || 0) + num;
        countMap[wId] = (countMap[wId] || 0) + 1;
      }
    });

    Object.keys(sumMap).forEach((wId) => {
      map[wId] = (sumMap[wId] / countMap[wId]).toFixed(1);
    });

    return map;
  }, [ratings]);

  // Helper to format timestamps safely
  const formatTimestamp = useCallback((ts) => {
    if (!ts) return 'N/A';
    try {
      const date = ts.toDate ? ts.toDate() : new Date(ts);
      if (isNaN(date.getTime())) return 'N/A';
      return date.toLocaleDateString('en-US', {
        day: '2-digit',
        month: 'short',
        year: 'numeric'
      });
    } catch (e) {
      return 'N/A';
    }
  }, []);

  // Helper to extract user profile image URL
  const getUserProfileImage = useCallback((userObj) => {
    if (!userObj) return null;
    const uid = userObj.id || userObj.uid;
    const docs = workerDocsMap[uid] || {};
    return docs.profile || docs.avatar || userObj.profileImage || userObj.photoURL || null;
  }, [workerDocsMap]);

  // User Tab & Search Filter logic
  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      const uType = (u.userType || 'customer').toLowerCase();
      const reqObj = workerRequestsMap[u.id] || {};
      const vStatus = (u.workerStatus || reqObj.status || 'N/A').toLowerCase();

      // Tab Filtering
      let matchesTab = true;
      if (activeTab === 'Customers') {
        matchesTab = uType === 'customer';
      } else if (activeTab === 'Workers') {
        matchesTab = uType === 'worker' || (u.workerStatus || '').length > 0;
      } else if (activeTab === 'Approved Workers') {
        matchesTab = vStatus === 'approved';
      } else if (activeTab === 'Pending Verification') {
        matchesTab = vStatus === 'pending';
      }

      // Dropdown Role Filter
      let matchesRole = true;
      if (roleFilter !== 'All') {
        matchesRole = uType === roleFilter.toLowerCase();
      }

      // Verification Status Filter
      let matchesVerification = true;
      if (verificationFilter !== 'All') {
        matchesVerification = vStatus === verificationFilter.toLowerCase();
      }

      // Multi-Field Search
      const fullName = (u.name || u.fullName || reqObj.name || '').toLowerCase();
      const email = (u.email || '').toLowerCase();
      const phone = (u.phone || reqObj.phone || '').toLowerCase();
      const uidStr = (u.id || u.uid || '').toLowerCase();
      const category = (u.workType || reqObj.workType || '').toLowerCase();
      const dateStr = formatTimestamp(u.createdAt).toLowerCase();

      const term = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !term ||
        fullName.includes(term) ||
        email.includes(term) ||
        phone.includes(term) ||
        uidStr.includes(term) ||
        category.includes(term) ||
        vStatus.includes(term) ||
        dateStr.includes(term);

      return matchesTab && matchesRole && matchesVerification && matchesSearch;
    });
  }, [users, activeTab, roleFilter, verificationFilter, searchQuery, workerRequestsMap, formatTimestamp]);

  // Tab Counts
  const getTabCount = (tabId) => {
    if (tabId === 'All Users') return users.length;
    if (tabId === 'Customers') return users.filter((u) => (u.userType || 'customer').toLowerCase() === 'customer').length;
    if (tabId === 'Workers') return users.filter((u) => (u.userType || '').toLowerCase() === 'worker' || (u.workerStatus || '').length > 0).length;
    if (tabId === 'Approved Workers') return users.filter((u) => (u.workerStatus || workerRequestsMap[u.id]?.status || '').toLowerCase() === 'approved').length;
    if (tabId === 'Pending Verification') return users.filter((u) => (u.workerStatus || workerRequestsMap[u.id]?.status || '').toLowerCase() === 'pending').length;
    return 0;
  };

  // Pagination Calculations
  const totalPages = Math.ceil(filteredUsers.length / USERS_PER_PAGE) || 1;
  const paginatedUsers = useMemo(() => {
    const start = (currentPage - 1) * USERS_PER_PAGE;
    return filteredUsers.slice(start, start + USERS_PER_PAGE);
  }, [filteredUsers, currentPage]);

  // Reset page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [activeTab, searchQuery, roleFilter, verificationFilter]);

  if (loading) {
    return (
      <div className="user-management animate-fade" style={{ textAlign: 'center', padding: '60px 20px' }}>
        <RefreshCw className="spin-icon" size={32} style={{ color: '#10B981', marginBottom: '12px' }} />
        <p style={{ color: '#6B7280', fontSize: '15px' }}>Loading real-time user directory...</p>
      </div>
    );
  }

  return (
    <div className="user-management animate-fade">
      <PageHeader
        title="User & Worker Management"
        subtitle="Explore customer accounts, technician profiles, verification statuses, and order histories."
      />

      {error && (
        <div className="ch-error-banner">
          <AlertCircle size={18} />
          <span>{error}</span>
        </div>
      )}

      {/* TOOLBAR: TABS & SEARCH & FILTERS */}
      <div className="users-toolbar">
        <div className="users-toolbar__filters">
          {/* Directory Tabs */}
          <div className="users-tabs-group">
            {['All Users', 'Customers', 'Workers', 'Approved Workers', 'Pending Verification'].map((tab) => (
              <button
                key={tab}
                type="button"
                className={`tab-pill ${activeTab === tab ? 'tab-pill--active' : ''}`}
                onClick={() => setActiveTab(tab)}
              >
                {tab}
                <span className="tab-badge">{getTabCount(tab)}</span>
              </button>
            ))}
          </div>

          <div className="filter-group-divider" />

          {/* Role Filter */}
          <span className="filter-group-label">Role:</span>
          <select
            value={roleFilter}
            onChange={(e) => setRoleFilter(e.target.value)}
            className="filter-select"
          >
            <option value="All">All Roles</option>
            <option value="Customer">Customer</option>
            <option value="Worker">Worker</option>
          </select>

          {/* Verification Status Filter */}
          <span className="filter-group-label">Verification:</span>
          <select
            value={verificationFilter}
            onChange={(e) => setVerificationFilter(e.target.value)}
            className="filter-select"
          >
            <option value="All">All Statuses</option>
            <option value="Approved">Approved</option>
            <option value="Pending">Pending</option>
            <option value="Rejected">Rejected</option>
          </select>
        </div>

        {/* Multi-Field Search Box */}
        <div className="users-search-box">
          <Search size={16} className="search-icon" />
          <input
            type="text"
            placeholder="Search by name, email, phone, UID, category..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <X size={14} className="clear-search" onClick={() => setSearchQuery('')} />
          )}
        </div>
      </div>

      {/* USER DIRECTORY TABLE */}
      <div className="table-card">
        {filteredUsers.length === 0 ? (
          <div className="users-empty-state">
            <Users size={48} style={{ opacity: 0.4, marginBottom: '12px' }} />
            <h3>No Users Found</h3>
            <p>No user records match the active tab and search query.</p>
          </div>
        ) : (
          <>
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>User / Profile</th>
                    <th>User Type</th>
                    <th>Contact Info</th>
                    <th>Category & Exp</th>
                    <th>Verification Status</th>
                    <th>Completed Orders</th>
                    <th>Rating</th>
                    <th>Joined Date</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedUsers.map((u) => {
                    const uid = u.id || u.uid;
                    const reqObj = workerRequestsMap[uid] || {};
                    const isWorker = (u.userType || '').toLowerCase() === 'worker' || (u.workerStatus || '').length > 0;
                    const fullName = u.name || u.fullName || reqObj.name || 'User';
                    const email = u.email || 'N/A';
                    const phone = u.phone || reqObj.phone || 'N/A';
                    const category = u.workType || reqObj.workType || (isWorker ? 'Technician' : 'N/A');
                    const experience = reqObj.experience !== undefined ? `${reqObj.experience} yrs` : 'N/A';
                    const vStatus = (u.workerStatus || reqObj.status || (isWorker ? 'pending' : 'N/A')).toLowerCase();
                    const completedOrders = completedOrdersCountMap[uid] || 0;
                    const rating = workerRatingMap[uid] || u.avgRating || 'N/A';
                    const profileImg = getUserProfileImage(u);

                    return (
                      <tr key={uid} className="user-table-row">
                        {/* Profile Cell */}
                        <td>
                          <div className="user-profile-cell">
                            <div className="user-avatar-frame">
                              {profileImg ? (
                                <img src={profileImg} alt={fullName} className="user-avatar-img" />
                              ) : (
                                <span className="user-avatar-initials">{fullName.charAt(0).toUpperCase()}</span>
                              )}
                            </div>
                            <div>
                              <p className="user-name-text">
                                {fullName}
                                {vStatus === 'approved' && (
                                  <ShieldCheck size={14} className="text-green" title="Verified Worker" />
                                )}
                              </p>
                              <span className="user-uid-code">UID: #{uid.slice(0, 6)}</span>
                            </div>
                          </div>
                        </td>

                        {/* User Type Badge */}
                        <td>
                          <Badge
                            label={isWorker ? 'Worker' : 'Customer'}
                            type={isWorker ? 'info' : 'primary'}
                          />
                        </td>

                        {/* Contact Info */}
                        <td>
                          <div className="user-contact-info">
                            <p className="user-email-text"><Mail size={12} /> {email}</p>
                            <p className="user-phone-text"><Phone size={12} /> {phone}</p>
                          </div>
                        </td>

                        {/* Category & Experience */}
                        <td>
                          <div className="category-cell">
                            <span className="cat-name">{category}</span>
                            {isWorker && <span className="exp-text">Exp: {experience}</span>}
                          </div>
                        </td>

                        {/* Verification Status */}
                        <td>
                          {isWorker ? (
                            <span className={`badge ${vStatus}`}>
                              {vStatus.toUpperCase()}
                            </span>
                          ) : (
                            <span className="text-muted" style={{ fontSize: '12px' }}>Registered</span>
                          )}
                        </td>

                        {/* Completed Orders */}
                        <td>
                          <span className="orders-count-badge">{completedOrders} jobs</span>
                        </td>

                        {/* Rating */}
                        <td>
                          {rating !== 'N/A' ? (
                            <span className="rating-pill">
                              <Star size={12} fill="#d97706" /> {rating}
                            </span>
                          ) : (
                            <span className="text-muted" style={{ fontSize: '12px' }}>N/A</span>
                          )}
                        </td>

                        {/* Joined Date */}
                        <td>
                          <span className="user-date-cell">
                            <Calendar size={13} />
                            {formatTimestamp(u.createdAt)}
                          </span>
                        </td>

                        {/* Action Buttons */}
                        <td>
                          <div className="user-table-actions">
                            <button
                              className="u-act-btn u-act-btn--view"
                              title="View Full Profile"
                              onClick={() => setSelectedUser(u)}
                            >
                              <Eye size={12} />
                              <span>View Profile</span>
                            </button>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* PAGINATION BAR */}
            <div className="pagination-bar">
              <span className="pagination-info">
                Showing {((currentPage - 1) * USERS_PER_PAGE) + 1} to {Math.min(currentPage * USERS_PER_PAGE, filteredUsers.length)} of {filteredUsers.length} users
              </span>
              <div className="pagination-controls">
                <button
                  className="page-btn"
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                >
                  <ChevronLeft size={16} /> Prev
                </button>
                <span className="page-number">Page {currentPage} of {totalPages}</span>
                <button
                  className="page-btn"
                  disabled={currentPage === totalPages}
                  onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                >
                  Next <ChevronRight size={16} />
                </button>
              </div>
            </div>
          </>
        )}
      </div>

      {/* DETAILED USER PROFILE MODAL */}
      {selectedUser && (
        <div className="ch-modal-backdrop" onClick={() => setSelectedUser(null)}>
          <div className="user-profile-modal" onClick={(e) => e.stopPropagation()}>
            {/* MODAL HEADER */}
            <div className="user-modal-header">
              <div className="profile-header-left">
                <div className="large-avatar">
                  {getUserProfileImage(selectedUser) ? (
                    <img src={getUserProfileImage(selectedUser)} alt="Profile" />
                  ) : (
                    <span>{(selectedUser.name || selectedUser.fullName || 'U').charAt(0).toUpperCase()}</span>
                  )}
                </div>
                <div>
                  <h2>{selectedUser.name || selectedUser.fullName || 'User Profile'}</h2>
                  <div className="header-badges">
                    <Badge label={selectedUser.userType || 'Customer'} type="primary" />
                    {(selectedUser.workerStatus || workerRequestsMap[selectedUser.id]?.status) && (
                      <span className={`badge ${selectedUser.workerStatus || workerRequestsMap[selectedUser.id]?.status}`}>
                        {(selectedUser.workerStatus || workerRequestsMap[selectedUser.id]?.status).toUpperCase()}
                      </span>
                    )}
                  </div>
                </div>
              </div>
              <button className="ch-modal-close" onClick={() => setSelectedUser(null)}>
                <X size={20} />
              </button>
            </div>

            {/* MODAL BODY */}
            <div className="user-modal-body">
              {/* PERSONAL & WORKER INFORMATION */}
              <div className="info-two-col">
                <div className="info-card">
                  <h4><Users size={16} /> Personal Information</h4>
                  <div className="info-row"><span className="i-label">Full Name:</span><span className="i-val">{selectedUser.name || selectedUser.fullName || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Email:</span><span className="i-val">{selectedUser.email || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Phone:</span><span className="i-val">{selectedUser.phone || workerRequestsMap[selectedUser.id]?.phone || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Age:</span><span className="i-val">{selectedUser.age ? `${selectedUser.age} yrs` : 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Address:</span><span className="i-val">{selectedUser.address || workerRequestsMap[selectedUser.id]?.area || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">User UID:</span><span className="i-val code-val">{selectedUser.id}</span></div>
                </div>

                <div className="info-card">
                  <h4><Briefcase size={16} /> Worker & Verification Info</h4>
                  <div className="info-row"><span className="i-label">Work Category:</span><span className="i-val">{selectedUser.workType || workerRequestsMap[selectedUser.id]?.workType || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Verification Status:</span><span className="i-val">{selectedUser.workerStatus || workerRequestsMap[selectedUser.id]?.status || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Experience:</span><span className="i-val">{workerRequestsMap[selectedUser.id]?.experience !== undefined ? `${workerRequestsMap[selectedUser.id]?.experience} yrs` : 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Quiz Score:</span><span className="i-val">{workerRequestsMap[selectedUser.id]?.score !== undefined ? `${workerRequestsMap[selectedUser.id]?.score}/${workerRequestsMap[selectedUser.id]?.total}` : 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Completed Jobs:</span><span className="i-val">{completedOrdersCountMap[selectedUser.id] || 0}</span></div>
                  <div className="info-row"><span className="i-label">Avg Rating:</span><span className="i-val">{workerRatingMap[selectedUser.id] || 'N/A'}</span></div>
                </div>
              </div>

              {/* RELATED ORDERS HISTORY */}
              <div className="detail-section-box">
                <h4><Tag size={16} /> Related Order History</h4>
                {orders.filter((o) => o.customerId === selectedUser.id || o.workerId === selectedUser.id).length > 0 ? (
                  <div className="mini-table-wrapper">
                    <table className="mini-table">
                      <thead>
                        <tr>
                          <th>Order ID</th>
                          <th>Service Type</th>
                          <th>Status</th>
                          <th>Date</th>
                        </tr>
                      </thead>
                      <tbody>
                        {orders
                          .filter((o) => o.customerId === selectedUser.id || o.workerId === selectedUser.id)
                          .slice(0, 5)
                          .map((o) => (
                            <tr key={o.id}>
                              <td className="code-val">#{o.id.slice(0, 8)}</td>
                              <td>{o.serviceType || 'Service'}</td>
                              <td><span className="badge">{o.status || 'pending'}</span></td>
                              <td>{formatTimestamp(o.createdAt)}</td>
                            </tr>
                          ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <p className="no-images-text">No order history recorded for this user.</p>
                )}
              </div>

              {/* RELATED COMPLAINTS HISTORY */}
              <div className="detail-section-box">
                <h4><AlertCircle size={16} /> Related Complaints History</h4>
                {complaints.filter((c) => c.complainantId === selectedUser.id || c.againstUserId === selectedUser.id).length > 0 ? (
                  <div className="mini-table-wrapper">
                    <table className="mini-table">
                      <thead>
                        <tr>
                          <th>Complaint ID</th>
                          <th>Category</th>
                          <th>Status</th>
                          <th>Date</th>
                        </tr>
                      </thead>
                      <tbody>
                        {complaints
                          .filter((c) => c.complainantId === selectedUser.id || c.againstUserId === selectedUser.id)
                          .slice(0, 5)
                          .map((c) => (
                            <tr key={c.id}>
                              <td className="code-val">#{c.id.slice(0, 8)}</td>
                              <td>{c.category || 'General'}</td>
                              <td><span className="badge">{c.status || 'open'}</span></td>
                              <td>{formatTimestamp(c.createdAt)}</td>
                            </tr>
                          ))}
                      </tbody>
                    </table>
                  </div>
                ) : (
                  <p className="no-images-text">No complaints associated with this user.</p>
                )}
              </div>

              {/* TIMELINE BASED ONLY ON EXISTING FIELDS */}
              <div className="detail-section-box">
                <h4><Clock size={16} /> User Timeline</h4>
                <ul className="timeline-list">
                  <li>
                    <span className="t-dot t-dot-blue"></span>
                    <div className="t-content">
                      <strong>Registered Account:</strong> {formatTimestamp(selectedUser.createdAt)}
                    </div>
                  </li>
                  {(selectedUser.workerRequestedAt || workerRequestsMap[selectedUser.id]?.createdAt) && (
                    <li>
                      <span className="t-dot t-dot-amber"></span>
                      <div className="t-content">
                        <strong>Worker Verification Requested:</strong> {formatTimestamp(selectedUser.workerRequestedAt || workerRequestsMap[selectedUser.id]?.createdAt)}
                      </div>
                    </li>
                  )}
                  {(selectedUser.approvedAt || workerRequestsMap[selectedUser.id]?.approvedAt) && (
                    <li>
                      <span className="t-dot t-dot-green"></span>
                      <div className="t-content">
                        <strong>Worker Approved:</strong> {formatTimestamp(selectedUser.approvedAt || workerRequestsMap[selectedUser.id]?.approvedAt)}
                      </div>
                    </li>
                  )}
                </ul>
              </div>
            </div>

            {/* MODAL FOOTER */}
            <div className="ch-modal-footer">
              <button className="btn-cancel" onClick={() => setSelectedUser(null)}>
                Close Profile
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
