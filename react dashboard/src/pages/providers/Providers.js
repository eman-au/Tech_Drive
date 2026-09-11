import React, { useState, useEffect, useMemo, useCallback } from 'react';
import { db } from '../../config/firebase';
import { collection, onSnapshot } from 'firebase/firestore';
import {
  Users,
  Search,
  Eye,
  Mail,
  Phone,
  Briefcase,
  AlertCircle,
  X,
  Star,
  ChevronLeft,
  ChevronRight,
  RefreshCw,
  Tag,
  ShieldCheck,
  MapPin,
  ExternalLink,
  Wifi,
  WifiOff,
  CheckCircle2,
  XCircle,
  Maximize2
} from 'lucide-react';
import PageHeader from '../../components/common/PageHeader';
import './Providers.css';

const WORKERS_PER_PAGE = 10;

// Existing Flutter order statuses considered active assigned orders
const ACTIVE_ORDER_STATUSES = ['accepted', 'assigned', 'on_my_way', 'arrived'];

export default function Providers() {
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
  const [activeTab, setActiveTab] = useState('All Workers'); // 'All Workers', 'Approved', 'Pending', 'Rejected', 'Online', 'Offline'
  const [searchQuery, setSearchQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('All');
  const [verificationFilter, setVerificationFilter] = useState('All');
  const [onlineFilter, setOnlineFilter] = useState('All');
  const [experienceFilter, setExperienceFilter] = useState('All');
  const [currentPage, setCurrentPage] = useState(1);

  // Modal & Lightbox View States
  const [selectedWorker, setSelectedWorker] = useState(null);
  const [lightboxImage, setLightboxImage] = useState(null);

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
        setError("Failed to load technician directory.");
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

  // Filter users dataset for Service Providers (userType == "worker" or worker record exists)
  const workerList = useMemo(() => {
    return users.filter((u) => {
      const uType = (u.userType || '').toLowerCase();
      const hasWorkerStatus = (u.workerStatus || '').length > 0;
      const hasWorkerReq = workerRequestsMap[u.id] !== undefined;
      return uType === 'worker' || hasWorkerStatus || hasWorkerReq;
    });
  }, [users, workerRequestsMap]);

  // Compute Completed Orders per worker map
  const completedOrdersCountMap = useMemo(() => {
    const map = {};
    orders.forEach((o) => {
      if ((o.status || '').toLowerCase() === 'completed' && o.workerId) {
        map[o.workerId] = (map[o.workerId] || 0) + 1;
      }
    });
    return map;
  }, [orders]);

  // Compute Active/Ongoing Order per worker map
  const activeOrderMap = useMemo(() => {
    const map = {};
    orders.forEach((o) => {
      const st = (o.status || '').toLowerCase();
      if (ACTIVE_ORDER_STATUSES.includes(st) && o.workerId) {
        map[o.workerId] = o;
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
      return date.toLocaleString('en-US', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
      });
    } catch (e) {
      return 'N/A';
    }
  }, []);

  // Helper to extract worker profile image URL
  const getWorkerProfileImage = useCallback((workerObj) => {
    if (!workerObj) return null;
    const uid = workerObj.id || workerObj.uid;
    const docs = workerDocsMap[uid] || {};
    return docs.profile || docs.avatar || workerObj.profileImage || workerObj.photoURL || null;
  }, [workerDocsMap]);

  // Helper to extract all document images for a worker
  const getWorkerDocumentImages = useCallback((workerObj) => {
    if (!workerObj) return [];
    const uid = workerObj.id || workerObj.uid;
    const docs = workerDocsMap[uid] || {};

    const docList = [];
    if (docs.cnicFront) docList.push({ title: 'CNIC Front', url: docs.cnicFront });
    if (docs.cnicBack) docList.push({ title: 'CNIC Back', url: docs.cnicBack });
    if (docs.selfie) docList.push({ title: 'Selfie with CNIC', url: docs.selfie });
    if (docs.tools) docList.push({ title: 'Tools Photo', url: docs.tools });
    if (docs.profile) docList.push({ title: 'Profile Photo', url: docs.profile });
    if (docs.police) docList.push({ title: 'Police Verification', url: docs.police });

    return docList;
  }, [workerDocsMap]);

  // Extract coordinates for Google Maps
  const getWorkerCoordinates = (w) => {
    const lat = w.lat || w.latitude || w.location?.lat || w.location?.latitude;
    const lng = w.lng || w.longitude || w.location?.lng || w.location?.longitude;
    if (lat && lng && !isNaN(Number(lat)) && !isNaN(Number(lng))) {
      return { lat: Number(lat), lng: Number(lng) };
    }
    return null;
  };

  // Open Location Action
  const handleOpenLocationMap = (w) => {
    const coords = getWorkerCoordinates(w);
    if (coords) {
      window.open(`https://www.google.com/maps?q=${coords.lat},${coords.lng}`, '_blank');
    }
  };

  // Worker Tab & Search Filter logic
  const filteredWorkers = useMemo(() => {
    return workerList.filter((w) => {
      const reqObj = workerRequestsMap[w.id] || {};
      const vStatus = (w.workerStatus || reqObj.status || 'pending').toLowerCase();
      const isOnline = w.isOnline === true;
      const experienceNum = Number(w.experience || reqObj.experience || 0);

      // Tab Filtering
      let matchesTab = true;
      if (activeTab === 'Approved') matchesTab = vStatus === 'approved';
      else if (activeTab === 'Pending') matchesTab = vStatus === 'pending';
      else if (activeTab === 'Rejected') matchesTab = vStatus === 'rejected';
      else if (activeTab === 'Online') matchesTab = isOnline;
      else if (activeTab === 'Offline') matchesTab = !isOnline;

      // Verification Status Filter
      let matchesVerification = true;
      if (verificationFilter !== 'All') {
        matchesVerification = vStatus === verificationFilter.toLowerCase();
      }

      // Online/Offline Status Filter
      let matchesOnline = true;
      if (onlineFilter === 'Online') matchesOnline = isOnline;
      if (onlineFilter === 'Offline') matchesOnline = !isOnline;

      // Category / Work Type Filter
      let matchesCategory = true;
      if (categoryFilter !== 'All') {
        const cat = (w.workType || reqObj.workType || '').toLowerCase();
        matchesCategory = cat === categoryFilter.toLowerCase();
      }

      // Experience Range Filter
      let matchesExp = true;
      if (experienceFilter === '0-2') matchesExp = experienceNum <= 2;
      else if (experienceFilter === '3-5') matchesExp = experienceNum >= 3 && experienceNum <= 5;
      else if (experienceFilter === '5+') matchesExp = experienceNum >= 5;

      // Multi-Field Search
      const fullName = (w.name || w.fullName || reqObj.name || '').toLowerCase();
      const email = (w.email || '').toLowerCase();
      const phone = (w.phone || reqObj.phone || '').toLowerCase();
      const uidStr = (w.id || w.uid || '').toLowerCase();
      const workType = (w.workType || reqObj.workType || '').toLowerCase();
      const area = (w.area || reqObj.area || w.serviceArea || w.address || '').toLowerCase();

      const term = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !term ||
        fullName.includes(term) ||
        email.includes(term) ||
        phone.includes(term) ||
        uidStr.includes(term) ||
        workType.includes(term) ||
        area.includes(term);

      return (
        matchesTab &&
        matchesVerification &&
        matchesOnline &&
        matchesCategory &&
        matchesExp &&
        matchesSearch
      );
    });
  }, [
    workerList,
    activeTab,
    verificationFilter,
    onlineFilter,
    categoryFilter,
    experienceFilter,
    searchQuery,
    workerRequestsMap
  ]);

  // Tab Counts
  const getTabCount = (tabId) => {
    if (tabId === 'All Workers') return workerList.length;
    if (tabId === 'Approved') return workerList.filter((w) => (w.workerStatus || workerRequestsMap[w.id]?.status || '').toLowerCase() === 'approved').length;
    if (tabId === 'Pending') return workerList.filter((w) => (w.workerStatus || workerRequestsMap[w.id]?.status || '').toLowerCase() === 'pending').length;
    if (tabId === 'Rejected') return workerList.filter((w) => (w.workerStatus || workerRequestsMap[w.id]?.status || '').toLowerCase() === 'rejected').length;
    if (tabId === 'Online') return workerList.filter((w) => w.isOnline === true).length;
    if (tabId === 'Offline') return workerList.filter((w) => w.isOnline !== true).length;
    return 0;
  };

  // Pagination Calculations
  const totalPages = Math.ceil(filteredWorkers.length / WORKERS_PER_PAGE) || 1;
  const paginatedWorkers = useMemo(() => {
    const start = (currentPage - 1) * WORKERS_PER_PAGE;
    return filteredWorkers.slice(start, start + WORKERS_PER_PAGE);
  }, [filteredWorkers, currentPage]);

  // Reset page when filters change
  useEffect(() => {
    setCurrentPage(1);
  }, [activeTab, searchQuery, categoryFilter, verificationFilter, onlineFilter, experienceFilter]);

  if (loading) {
    return (
      <div className="providers-page animate-fade" style={{ textAlign: 'center', padding: '60px 20px' }}>
        <RefreshCw className="spin-icon" size={32} style={{ color: '#10B981', marginBottom: '12px' }} />
        <p style={{ color: '#6B7280', fontSize: '15px' }}>Loading real-time technician directory...</p>
      </div>
    );
  }

  return (
    <div className="providers-page animate-fade">
      <PageHeader
        title="Service Providers Management"
        subtitle="Real-time directory of field technicians, verification credentials, active jobs, and live status updates."
      />

      {error && (
        <div className="ch-error-banner">
          <AlertCircle size={18} />
          <span>{error}</span>
        </div>
      )}

      {/* TOOLBAR: TABS & SEARCH & FILTERS */}
      <div className="providers-toolbar">
        <div className="providers-toolbar__filters">
          {/* Main Directory Tabs */}
          <div className="providers-tabs-group">
            {['All Workers', 'Approved', 'Pending', 'Rejected', 'Online', 'Offline'].map((tab) => (
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

          {/* Verification Status Filter */}
          <span className="filter-group-label">Verification:</span>
          <select
            value={verificationFilter}
            onChange={(e) => setVerificationFilter(e.target.value)}
            className="filter-select"
          >
            <option value="All">All Verification</option>
            <option value="Approved">Approved</option>
            <option value="Pending">Pending</option>
            <option value="Rejected">Rejected</option>
          </select>

          {/* Online/Offline Status Filter */}
          <span className="filter-group-label">Status:</span>
          <select
            value={onlineFilter}
            onChange={(e) => setOnlineFilter(e.target.value)}
            className="filter-select"
          >
            <option value="All">All States</option>
            <option value="Online">Online</option>
            <option value="Offline">Offline</option>
          </select>

          {/* Category Dropdown Filter */}
          <span className="filter-group-label">Category:</span>
          <select
            value={categoryFilter}
            onChange={(e) => setCategoryFilter(e.target.value)}
            className="filter-select"
          >
            <option value="All">All Categories</option>
            <option value="Electrician">Electrician</option>
            <option value="Plumber">Plumber</option>
          </select>

          {/* Experience Filter */}
          <span className="filter-group-label">Exp:</span>
          <select
            value={experienceFilter}
            onChange={(e) => setExperienceFilter(e.target.value)}
            className="filter-select"
          >
            <option value="All">All Experience</option>
            <option value="0-2">0 - 2 Years</option>
            <option value="3-5">3 - 5 Years</option>
            <option value="5+">5+ Years</option>
          </select>
        </div>

        {/* Multi-Field Search Box */}
        <div className="providers-search-box">
          <Search size={16} className="search-icon" />
          <input
            type="text"
            placeholder="Search by name, email, phone, UID, category, area..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
          />
          {searchQuery && (
            <X size={14} className="clear-search" onClick={() => setSearchQuery('')} />
          )}
        </div>
      </div>

      {/* TECHNICIANS TABLE */}
      <div className="table-card">
        {filteredWorkers.length === 0 ? (
          <div className="providers-empty-state">
            <Briefcase size={48} style={{ opacity: 0.4, marginBottom: '12px' }} />
            <h3>No Technicians Found</h3>
            <p>No service provider records match the selected tab and search filters.</p>
          </div>
        ) : (
          <>
            <div className="table-responsive">
              <table className="data-table">
                <thead>
                  <tr>
                    <th>Technician / Profile</th>
                    <th>Category & Exp</th>
                    <th>Contact Info</th>
                    <th>Verification</th>
                    <th>Online State</th>
                    <th>Service Area</th>
                    <th>Active Job</th>
                    <th>Completed</th>
                    <th>Rating</th>
                    <th style={{ textAlign: 'right' }}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {paginatedWorkers.map((w) => {
                    const uid = w.id || w.uid;
                    const reqObj = workerRequestsMap[uid] || {};
                    const fullName = w.name || w.fullName || reqObj.name || 'Technician';
                    const email = w.email || 'N/A';
                    const phone = w.phone || reqObj.phone || 'N/A';
                    const category = w.workType || reqObj.workType || 'Technician';
                    const experience = reqObj.experience !== undefined ? `${reqObj.experience} yrs` : (w.experience ? `${w.experience} yrs` : 'N/A');
                    const vStatus = (w.workerStatus || reqObj.status || 'pending').toLowerCase();
                    const isOnline = w.isOnline === true;
                    const area = w.area || reqObj.area || w.serviceArea || w.address || 'N/A';
                    const completedOrders = completedOrdersCountMap[uid] || 0;
                    const rating = workerRatingMap[uid] || w.avgRating || 'N/A';
                    const activeOrder = activeOrderMap[uid];
                    const coords = getWorkerCoordinates(w);
                    const profileImg = getWorkerProfileImage(w);

                    return (
                      <tr key={uid} className="provider-table-row">
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

                        {/* Category & Experience */}
                        <td>
                          <div className="category-cell">
                            <span className="cat-name">{category}</span>
                            <span className="exp-text">Exp: {experience}</span>
                          </div>
                        </td>

                        {/* Contact Info */}
                        <td>
                          <div className="user-contact-info">
                            <p className="user-email-text"><Mail size={12} /> {email}</p>
                            <p className="user-phone-text"><Phone size={12} /> {phone}</p>
                          </div>
                        </td>

                        {/* Verification Status */}
                        <td>
                          <span className={`badge ${vStatus}`}>
                            {vStatus.toUpperCase()}
                          </span>
                        </td>

                        {/* Online/Offline State */}
                        <td>
                          <span className={`online-pill ${isOnline ? 'online-true' : 'online-false'}`}>
                            {isOnline ? <Wifi size={12} /> : <WifiOff size={12} />}
                            {isOnline ? 'ONLINE' : 'OFFLINE'}
                          </span>
                        </td>

                        {/* Service Area */}
                        <td>
                          <span className="area-text">{area}</span>
                        </td>

                        {/* Active Order Indicator */}
                        <td>
                          {activeOrder ? (
                            <span className="active-job-badge" title={`Order #${activeOrder.id.slice(0, 6)}`}>
                              <Tag size={12} /> {activeOrder.status.toUpperCase()}
                            </span>
                          ) : (
                            <span className="text-muted" style={{ fontSize: '12px' }}>None</span>
                          )}
                        </td>

                        {/* Completed Jobs */}
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

                        {/* Action Buttons */}
                        <td>
                          <div className="user-table-actions">
                            <button
                              className="u-act-btn u-act-btn--view"
                              title="View Technician Profile"
                              onClick={() => setSelectedWorker(w)}
                            >
                              <Eye size={12} />
                              <span>View</span>
                            </button>

                            {coords && (
                              <button
                                className="u-act-btn u-act-btn--map"
                                title="Open Live Location Map"
                                onClick={() => handleOpenLocationMap(w)}
                              >
                                <MapPin size={12} />
                                <span>Location</span>
                              </button>
                            )}
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
                Showing {((currentPage - 1) * WORKERS_PER_PAGE) + 1} to {Math.min(currentPage * WORKERS_PER_PAGE, filteredWorkers.length)} of {filteredWorkers.length} technicians
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

      {/* DETAILED WORKER PROFILE MODAL */}
      {selectedWorker && (
        <div className="ch-modal-backdrop" onClick={() => setSelectedWorker(null)}>
          <div className="worker-profile-modal" onClick={(e) => e.stopPropagation()}>
            {/* MODAL HEADER */}
            <div className="worker-modal-header">
              <div className="profile-header-left">
                <div className="large-avatar">
                  {getWorkerProfileImage(selectedWorker) ? (
                    <img src={getWorkerProfileImage(selectedWorker)} alt="Profile" />
                  ) : (
                    <span>{(selectedWorker.name || selectedWorker.fullName || 'W').charAt(0).toUpperCase()}</span>
                  )}
                </div>
                <div>
                  <h2>{selectedWorker.name || selectedWorker.fullName || 'Service Provider'}</h2>
                  <div className="header-badges">
                    <span className={`badge ${selectedWorker.workerStatus || workerRequestsMap[selectedWorker.id]?.status || 'pending'}`}>
                      {(selectedWorker.workerStatus || workerRequestsMap[selectedWorker.id]?.status || 'pending').toUpperCase()}
                    </span>
                    <span className={`online-pill ${selectedWorker.isOnline === true ? 'online-true' : 'online-false'}`}>
                      {selectedWorker.isOnline === true ? 'ONLINE' : 'OFFLINE'}
                    </span>
                  </div>
                </div>
              </div>
              <button className="ch-modal-close" onClick={() => setSelectedWorker(null)}>
                <X size={20} />
              </button>
            </div>

            {/* MODAL BODY */}
            <div className="worker-modal-body">
              {/* PERSONAL & WORK DETAILS */}
              <div className="info-two-col">
                <div className="info-card">
                  <h4><Users size={16} /> Personal & Contact Information</h4>
                  <div className="info-row"><span className="i-label">Full Name:</span><span className="i-val">{selectedWorker.name || selectedWorker.fullName || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Email:</span><span className="i-val">{selectedWorker.email || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Phone:</span><span className="i-val">{selectedWorker.phone || workerRequestsMap[selectedWorker.id]?.phone || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Age:</span><span className="i-val">{selectedWorker.age ? `${selectedWorker.age} yrs` : 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Service Area:</span><span className="i-val">{selectedWorker.area || workerRequestsMap[selectedWorker.id]?.area || selectedWorker.address || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Email Verified:</span><span className="i-val">{selectedWorker.emailVerified ? <CheckCircle2 size={14} className="text-green" /> : <XCircle size={14} style={{ color: '#EF4444' }} />}</span></div>
                  <div className="info-row"><span className="i-label">Phone Verified:</span><span className="i-val">{selectedWorker.phoneVerified ? <CheckCircle2 size={14} className="text-green" /> : <XCircle size={14} style={{ color: '#EF4444' }} />}</span></div>
                  <div className="info-row"><span className="i-label">UID:</span><span className="i-val code-val">{selectedWorker.id}</span></div>
                </div>

                <div className="info-card">
                  <h4><Briefcase size={16} /> Professional & Status Information</h4>
                  <div className="info-row"><span className="i-label">Work Type:</span><span className="i-val">{selectedWorker.workType || workerRequestsMap[selectedWorker.id]?.workType || 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Experience:</span><span className="i-val">{workerRequestsMap[selectedWorker.id]?.experience !== undefined ? `${workerRequestsMap[selectedWorker.id]?.experience} yrs` : (selectedWorker.experience ? `${selectedWorker.experience} yrs` : 'N/A')}</span></div>
                  <div className="info-row"><span className="i-label">Verification Status:</span><span className="i-val">{selectedWorker.workerStatus || workerRequestsMap[selectedWorker.id]?.status || 'pending'}</span></div>
                  <div className="info-row"><span className="i-label">Quiz Score:</span><span className="i-val">{workerRequestsMap[selectedWorker.id]?.score !== undefined ? `${workerRequestsMap[selectedWorker.id]?.score}/${workerRequestsMap[selectedWorker.id]?.total}` : 'N/A'}</span></div>
                  <div className="info-row"><span className="i-label">Online State:</span><span className="i-val">{selectedWorker.isOnline ? 'Online' : 'Offline'}</span></div>
                  <div className="info-row"><span className="i-label">Last Status Update:</span><span className="i-val">{formatTimestamp(selectedWorker.lastStatusUpdate)}</span></div>
                  <div className="info-row"><span className="i-label">Joined Date:</span><span className="i-val">{formatTimestamp(selectedWorker.createdAt)}</span></div>
                </div>
              </div>

              {/* CURRENT ACTIVE / ONGOING ORDER (IF EXISTS) */}
              {activeOrderMap[selectedWorker.id] && (
                <div className="active-order-box">
                  <div className="active-order-header">
                    <h4><Tag size={16} /> Current Active Order</h4>
                    <span className="badge warning">
                      {activeOrderMap[selectedWorker.id].status.toUpperCase()}
                    </span>
                  </div>
                  <div className="info-two-col" style={{ marginTop: '8px' }}>
                    <div className="info-row"><span className="i-label">Order ID:</span><span className="i-val code-val">#{activeOrderMap[selectedWorker.id].id}</span></div>
                    <div className="info-row"><span className="i-label">Customer Name:</span><span className="i-val">{activeOrderMap[selectedWorker.id].customerName || 'Customer'}</span></div>
                    <div className="info-row"><span className="i-label">Service Type:</span><span className="i-val">{activeOrderMap[selectedWorker.id].serviceType || 'N/A'}</span></div>
                    <div className="info-row"><span className="i-label">Address:</span><span className="i-val">{activeOrderMap[selectedWorker.id].address || 'N/A'}</span></div>
                  </div>
                </div>
              )}

              {/* WORKER CLOUDINARY DOCUMENTS VIEWER */}
              <div className="detail-section-box">
                <h4><Eye size={16} /> Cloudinary Document Verification Photos</h4>
                {getWorkerDocumentImages(selectedWorker).length > 0 ? (
                  <div className="doc-images-grid">
                    {getWorkerDocumentImages(selectedWorker).map((docObj, dIdx) => (
                      <div key={dIdx} className="doc-img-card" onClick={() => setLightboxImage(docObj.url)}>
                        <img src={docObj.url} alt={docObj.title} />
                        <span className="doc-img-title">{docObj.title}</span>
                        <div className="doc-img-hover">
                          <Maximize2 size={16} />
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="no-images-text">No document photos uploaded to Cloudinary for this worker.</p>
                )}
              </div>

              {/* LOCATION MAP COORDINATES & ACTION */}
              <div className="detail-section-box">
                <h4><MapPin size={16} /> Technician Location Coordinates</h4>
                {getWorkerCoordinates(selectedWorker) ? (
                  <div className="location-coords-bar">
                    <div>
                      <strong>Latitude:</strong> {getWorkerCoordinates(selectedWorker).lat.toFixed(6)} | <strong>Longitude:</strong> {getWorkerCoordinates(selectedWorker).lng.toFixed(6)}
                    </div>
                    <button
                      className="btn-open-map"
                      onClick={() => handleOpenLocationMap(selectedWorker)}
                    >
                      <ExternalLink size={14} /> Open in Google Maps
                    </button>
                  </div>
                ) : (
                  <p className="no-images-text">Location coordinates not reported for this worker.</p>
                )}
              </div>

              {/* RATINGS & REVIEWS LIST */}
              <div className="detail-section-box">
                <h4><Star size={16} /> Ratings & Customer Reviews ({ratings.filter((r) => r.workerId === selectedWorker.id).length})</h4>
                {ratings.filter((r) => r.workerId === selectedWorker.id).length > 0 ? (
                  <div className="reviews-list">
                    {ratings
                      .filter((r) => r.workerId === selectedWorker.id)
                      .slice(0, 5)
                      .map((r) => (
                        <div key={r.id} className="review-item">
                          <div className="review-header">
                            <span className="rating-pill"><Star size={12} fill="#d97706" /> {r.rating}</span>
                            <span className="review-date">{formatTimestamp(r.createdAt)}</span>
                          </div>
                          {r.comment && <p className="review-comment">"{r.comment}"</p>}
                        </div>
                      ))}
                  </div>
                ) : (
                  <p className="no-images-text">No customer ratings submitted for this technician.</p>
                )}
              </div>

              {/* COMPLAINT HISTORY */}
              <div className="detail-section-box">
                <h4><AlertCircle size={16} /> Related Complaints History ({complaints.filter((c) => c.againstUserId === selectedWorker.id || c.complainantId === selectedWorker.id).length})</h4>
                {complaints.filter((c) => c.againstUserId === selectedWorker.id || c.complainantId === selectedWorker.id).length > 0 ? (
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
                          .filter((c) => c.againstUserId === selectedWorker.id || c.complainantId === selectedWorker.id)
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
                  <p className="no-images-text">No complaint records found for this technician.</p>
                )}
              </div>
            </div>

            {/* MODAL FOOTER */}
            <div className="ch-modal-footer">
              {getWorkerCoordinates(selectedWorker) && (
                <button
                  className="btn-open-map"
                  onClick={() => handleOpenLocationMap(selectedWorker)}
                >
                  <MapPin size={14} /> View Location on Map
                </button>
              )}
              <button className="btn-cancel" onClick={() => setSelectedWorker(null)}>
                Close Profile
              </button>
            </div>
          </div>
        </div>
      )}

      {/* LIGHTBOX FOR CLOUDINARY IMAGES */}
      {lightboxImage && (
        <div className="ch-modal-backdrop lightbox-backdrop" onClick={() => setLightboxImage(null)}>
          <div className="lightbox-content" onClick={(e) => e.stopPropagation()}>
            <button className="lightbox-close" onClick={() => setLightboxImage(null)}>
              <X size={24} />
            </button>
            <img src={lightboxImage} alt="Document Preview" />
          </div>
        </div>
      )}
    </div>
  );
}