import React, { useState, useEffect, useMemo } from 'react';
import { db } from '../../config/firebase';
import { useAuth } from '../../context/AuthContext';
import {
  collection,
  onSnapshot,
  doc,
  getDoc,
  writeBatch,
  serverTimestamp
} from 'firebase/firestore';
import {
  AlertCircle,
  CheckCircle2,
  XCircle,
  Clock,
  Search,
  Eye,
  User,
  Briefcase,
  FileText,
  X,
  MessageSquare,
  Check,
  Image as ImageIcon,
  Tag,
  RefreshCw
} from 'lucide-react';
import './ComplaintsHistory.css';

const TABS = [
  { id: 'Open', label: 'Open' },
  { id: 'Under Review', label: 'Under Review' },
  { id: 'Resolved', label: 'Resolved' },
  { id: 'Rejected', label: 'Rejected' },
  { id: 'All', label: 'All Complaints' }
];

export default function ComplaintsHistory() {
  const { currentUser } = useAuth();

  const [complaints, setComplaints] = useState([]);
  const [usersMap, setUsersMap] = useState({});
  const [ordersMap, setOrdersMap] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionProcessingId, setActionProcessingId] = useState(null);
  const [toastMessage, setToastMessage] = useState(null);

  // Active Tab & Search Filter
  const [activeTab, setActiveTab] = useState('Open');
  const [searchTerm, setSearchTerm] = useState('');

  // Selected Complaint for Detailed View Modal
  const [selectedComplaint, setSelectedComplaint] = useState(null);

  // Lightbox for image preview
  const [previewImage, setPreviewImage] = useState(null);

  // Action Confirmation Modals State
  const [actionModal, setActionModal] = useState(null); // { type: 'resolve' | 'reject' | 'review', complaint: obj }
  const [adminRemarks, setAdminRemarks] = useState('');
  const [modalError, setModalError] = useState('');

  // Toast Auto-hide
  useEffect(() => {
    if (toastMessage) {
      const timer = setTimeout(() => setToastMessage(null), 4000);
      return () => clearTimeout(timer);
    }
  }, [toastMessage]);

  // Real-time Firestore Listener for complaints
  useEffect(() => {
    const unsub = onSnapshot(
      collection(db, 'complaints'),
      async (snapshot) => {
        try {
          const list = [];
          const userUidsToFetch = new Set();
          const orderIdsToFetch = new Set();

          snapshot.docs.forEach((docSnap) => {
            const data = docSnap.data() || {};
            const id = docSnap.id;

            list.push({
              id,
              ...data
            });

            if (data.complainantId) userUidsToFetch.add(data.complainantId);
            if (data.againstUserId) userUidsToFetch.add(data.againstUserId);
            if (data.orderId) orderIdsToFetch.add(data.orderId);
          });

          // Fetch related user details
          const userPromises = Array.from(userUidsToFetch).map((uid) =>
            getDoc(doc(db, 'users', uid)).then((snap) => ({
              uid,
              data: snap.exists() ? snap.data() : {}
            }))
          );

          // Fetch related order details
          const orderPromises = Array.from(orderIdsToFetch).map((orderId) =>
            getDoc(doc(db, 'orders', orderId)).then((snap) => ({
              orderId,
              data: snap.exists() ? snap.data() : {}
            }))
          );

          const userResults = await Promise.all(userPromises);
          const orderResults = await Promise.all(orderPromises);

          const uMap = {};
          userResults.forEach((res) => {
            uMap[res.uid] = res.data;
          });

          const oMap = {};
          orderResults.forEach((res) => {
            oMap[res.orderId] = res.data;
          });

          setComplaints(list);
          setUsersMap(uMap);
          setOrdersMap(oMap);
          setLoading(false);
        } catch (err) {
          console.error("Error loading complaints data:", err);
          setError("Failed to load complaints from database.");
          setLoading(false);
        }
      },
      (err) => {
        console.error("Snapshot error on complaints:", err);
        setError("Database connection error for complaints.");
        setLoading(false);
      }
    );

    return () => unsub();
  }, []);

  // Helper to normalize status strings
  const normalizeStatus = (status) => {
    if (!status) return 'open';
    const s = status.toLowerCase().replace('-', '_').replace(' ', '_');
    if (s === 'pending' || s === 'open') return 'open';
    if (s === 'under_review' || s === 'in_progress' || s === 'review') return 'under_review';
    if (s === 'resolved' || s === 'closed') return 'resolved';
    if (s === 'rejected') return 'rejected';
    return s;
  };

  // Filter complaints based on Tab & Search
  const filteredComplaints = useMemo(() => {
    return complaints.filter((item) => {
      const normStatus = normalizeStatus(item.status);
      let matchesTab = true;

      if (activeTab === 'Open') {
        matchesTab = normStatus === 'open';
      } else if (activeTab === 'Under Review') {
        matchesTab = normStatus === 'under_review';
      } else if (activeTab === 'Resolved') {
        matchesTab = normStatus === 'resolved';
      } else if (activeTab === 'Rejected') {
        matchesTab = normStatus === 'rejected';
      }

      const complainant = usersMap[item.complainantId] || {};
      const targetUser = usersMap[item.againstUserId] || {};

      const customerName = (complainant.name || complainant.fullName || item.complaintBy || '').toLowerCase();
      const workerName = (targetUser.name || targetUser.fullName || item.againstUserName || '').toLowerCase();
      const cat = (item.category || '').toLowerCase();
      const desc = (item.description || '').toLowerCase();
      const complaintId = (item.id || '').toLowerCase();
      const orderId = (item.orderId || '').toLowerCase();

      const term = searchTerm.toLowerCase().trim();
      const matchesSearch =
        !term ||
        complaintId.includes(term) ||
        orderId.includes(term) ||
        customerName.includes(term) ||
        workerName.includes(term) ||
        cat.includes(term) ||
        desc.includes(term);

      return matchesTab && matchesSearch;
    });
  }, [complaints, activeTab, searchTerm, usersMap]);

  // Tab counts
  const getTabCount = (tabId) => {
    if (tabId === 'All') return complaints.length;
    const targetNorm = normalizeStatus(tabId);
    return complaints.filter((item) => normalizeStatus(item.status) === targetNorm).length;
  };

  // Format timestamp safely
  const formatTimestamp = (ts) => {
    if (!ts) return 'N/A';
    try {
      const date = ts.toDate ? ts.toDate() : new Date(ts);
      if (isNaN(date.getTime())) return 'N/A';
      return date.toLocaleString('en-US', {
        day: '2-digit',
        month: 'short',
        year: 'numeric',
        hour: '2-digit',
        minute: '2-digit',
        hour12: true
      });
    } catch (e) {
      return 'N/A';
    }
  };

  // Helper to extract Cloudinary image URLs array safely
  const extractComplaintImages = (item) => {
    if (!item) return [];
    const imgs = item.images || item.imageUrls || item.photos || item.imageUrl || item.photo;
    if (Array.isArray(imgs)) {
      return imgs.filter((img) => typeof img === 'string' && img.trim().length > 0);
    }
    if (typeof imgs === 'string' && imgs.trim().length > 0) {
      return [imgs.trim()];
    }
    return [];
  };

  // ================= STATUS UPDATE ACTIONS =================
  const handleUpdateStatus = async (complaintId, newStatus, remarks = '') => {
    if (actionProcessingId) return;

    setActionProcessingId(complaintId);
    setError(null);

    try {
      const batch = writeBatch(db);
      const complaintRef = doc(db, 'complaints', complaintId);

      const updateData = {
        status: newStatus,
        reviewedAt: serverTimestamp(),
        reviewedBy: currentUser?.uid || 'admin',
        updatedAt: serverTimestamp()
      };

      if (remarks.trim()) {
        updateData.adminRemarks = remarks.trim();
      }

      if (newStatus === 'resolved') {
        updateData.resolvedAt = serverTimestamp();
      } else if (newStatus === 'rejected') {
        updateData.rejectedAt = serverTimestamp();
      }

      batch.update(complaintRef, updateData);
      await batch.commit();

      setToastMessage({
        type: 'success',
        text: `Complaint #${complaintId.slice(0, 6)} updated to ${newStatus.replace('_', ' ').toUpperCase()}`
      });

      // Update local state if modal is open
      if (selectedComplaint && selectedComplaint.id === complaintId) {
        setSelectedComplaint((prev) => ({
          ...prev,
          status: newStatus,
          adminRemarks: remarks.trim() || prev?.adminRemarks
        }));
      }

      setActionModal(null);
      setAdminRemarks('');
      setModalError('');
    } catch (err) {
      console.error("Status update error:", err);
      setToastMessage({
        type: 'error',
        text: `Action failed: ${err.message}`
      });
    } finally {
      setActionProcessingId(null);
    }
  };

  const handleConfirmAction = () => {
    if (!actionModal) return;
    const { type, complaint } = actionModal;

    if (type === 'resolve' || type === 'reject') {
      if (type === 'reject' && !adminRemarks.trim()) {
        setModalError("Rejection remarks are required.");
        return;
      }
      const targetStatus = type === 'resolve' ? 'resolved' : 'rejected';
      handleUpdateStatus(complaint.id, targetStatus, adminRemarks);
    } else if (type === 'review') {
      handleUpdateStatus(complaint.id, 'under_review', adminRemarks);
    }
  };

  if (loading) {
    return (
      <div className="ch-card animate-fade" style={{ textAlign: 'center', padding: '60px 20px' }}>
        <RefreshCw className="spin-icon" size={32} style={{ color: '#10B981', marginBottom: '12px' }} />
        <p style={{ color: '#6B7280', fontSize: '15px' }}>Loading Firestore complaints list...</p>
      </div>
    );
  }

  return (
    <div className="ch-card animate-fade">

      {/* TOAST FEEDBACK */}
      {toastMessage && (
        <div className={`ch-toast ch-toast-${toastMessage.type}`}>
          {toastMessage.type === 'success' ? <CheckCircle2 size={18} /> : <AlertCircle size={18} />}
          <span>{toastMessage.text}</span>
          <X size={16} className="toast-close" onClick={() => setToastMessage(null)} />
        </div>
      )}

      {error && (
        <div className="ch-error-banner">
          <AlertCircle size={18} />
          <span>{error}</span>
        </div>
      )}

      {/* FILTERS & SEARCH BAR */}
      <div className="ch-filters-bar">
        <div className="ch-filters">
          {TABS.map((tab) => (
            <button
              key={tab.id}
              className={`ch-filter-btn ${activeTab === tab.id ? 'active' : ''}`}
              onClick={() => setActiveTab(tab.id)}
            >
              {tab.label}
              <span className="ch-badge">{getTabCount(tab.id)}</span>
            </button>
          ))}
        </div>

        <div className="ch-search">
          <Search className="search-icon" size={16} />
          <input
            type="text"
            placeholder="Search by ID, customer, worker, category..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
          />
          {searchTerm && (
            <X size={14} className="clear-search" onClick={() => setSearchTerm('')} />
          )}
        </div>
      </div>

      {/* COMPLAINTS TABLE */}
      <div className="ch-table-container">
        {filteredComplaints.length > 0 ? (
          <table className="ch-table animate-fade">
            <thead>
              <tr>
                <th>Complaint ID</th>
                <th>Order ID</th>
                <th>Complainant</th>
                <th>Target (Against)</th>
                <th>Category</th>
                <th>Priority</th>
                <th>Status</th>
                <th>Date & Time</th>
                <th style={{ textAlign: 'right' }}>Actions</th>
              </tr>
            </thead>
            <tbody>
              {filteredComplaints.map((item) => {
                const normStatus = normalizeStatus(item.status);
                const complainant = usersMap[item.complainantId] || {};
                const targetUser = usersMap[item.againstUserId] || {};

                const customerName = complainant.name || complainant.fullName || item.complaintBy || 'Customer';
                const workerName = targetUser.name || targetUser.fullName || item.againstUserName || 'Worker';
                const priority = item.priority || (normStatus === 'open' ? 'High' : 'Medium');

                return (
                  <tr key={item.id} className="ch-table-row">
                    <td className="ch-col-id">#{item.id.slice(0, 8)}</td>
                    <td className="ch-col-order">#{item.orderId ? item.orderId.slice(0, 8) : 'N/A'}</td>
                    <td>
                      <div className="user-name-cell">
                        <User size={14} className="cell-icon" />
                        <span>{customerName}</span>
                      </div>
                    </td>
                    <td>
                      <div className="user-name-cell">
                        <Briefcase size={14} className="cell-icon" />
                        <span>{workerName}</span>
                      </div>
                    </td>
                    <td>
                      <span className="ch-category-pill">{item.category || 'General Issue'}</span>
                    </td>
                    <td>
                      <span className={`ch-priority-pill ch-priority-${priority.toLowerCase()}`}>
                        {priority}
                      </span>
                    </td>
                    <td>
                      <span className={`ch-status-badge ch-status-${normStatus}`}>
                        {normStatus === 'open' && <Clock size={12} />}
                        {normStatus === 'under_review' && <RefreshCw size={12} />}
                        {normStatus === 'resolved' && <CheckCircle2 size={12} />}
                        {normStatus === 'rejected' && <XCircle size={12} />}
                        {normStatus.replace('_', ' ').toUpperCase()}
                      </span>
                    </td>
                    <td className="ch-col-date">{formatTimestamp(item.createdAt)}</td>
                    <td style={{ textAlign: 'right' }}>
                      <button
                        className="ch-btn-view"
                        onClick={() => setSelectedComplaint(item)}
                      >
                        <Eye size={14} /> View Detail
                      </button>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        ) : (
          <div className="ch-empty-state animate-fade">
            <div className="ch-empty-icon">
              <FileText size={48} />
            </div>
            <h3>No Complaints Found</h3>
            <p>No complaint records match the selected tab and search term.</p>
            {(searchTerm || activeTab !== 'Open') && (
              <button
                className="ch-btn-clear-filters"
                onClick={() => {
                  setSearchTerm('');
                  setActiveTab('Open');
                }}
              >
                Reset Filters
              </button>
            )}
          </div>
        )}
      </div>

      {/* DETAILED VIEW MODAL */}
      {selectedComplaint && (
        <div className="ch-modal-backdrop" onClick={() => setSelectedComplaint(null)}>
          <div className="ch-modal-content" onClick={(e) => e.stopPropagation()}>
            {/* MODAL HEADER */}
            <div className="ch-modal-header">
              <div>
                <h2>Complaint Details #{selectedComplaint.id.slice(0, 8)}</h2>
                <div className="header-meta">
                  <span className={`ch-status-badge ch-status-${normalizeStatus(selectedComplaint.status)}`}>
                    {normalizeStatus(selectedComplaint.status).replace('_', ' ').toUpperCase()}
                  </span>
                  <span className="meta-date">Created: {formatTimestamp(selectedComplaint.createdAt)}</span>
                </div>
              </div>
              <button className="ch-modal-close" onClick={() => setSelectedComplaint(null)}>
                <X size={20} />
              </button>
            </div>

            {/* MODAL BODY */}
            <div className="ch-modal-body">
              {/* DESCRIPTION BOX */}
              <div className="detail-section-box">
                <h4><MessageSquare size={16} /> Complaint Description</h4>
                <p className="desc-text">{selectedComplaint.description || 'No detailed description provided.'}</p>
                <div className="category-meta">
                  <span><strong>Category:</strong> {selectedComplaint.category || 'General'}</span>
                  {selectedComplaint.priority && <span><strong>Priority:</strong> {selectedComplaint.priority}</span>}
                </div>
              </div>

              {/* TWO COLUMN USER & WORKER INFO */}
              <div className="info-two-col">
                {/* Complainant Info */}
                <div className="info-card">
                  <h4><User size={16} /> Customer Information</h4>
                  <div className="info-row">
                    <span className="i-label">Name:</span>
                    <span className="i-val">
                      {usersMap[selectedComplaint.complainantId]?.name ||
                        usersMap[selectedComplaint.complainantId]?.fullName ||
                        selectedComplaint.complaintBy ||
                        'Customer'}
                    </span>
                  </div>
                  <div className="info-row">
                    <span className="i-label">Email:</span>
                    <span className="i-val">{usersMap[selectedComplaint.complainantId]?.email || 'N/A'}</span>
                  </div>
                  <div className="info-row">
                    <span className="i-label">Phone:</span>
                    <span className="i-val">{usersMap[selectedComplaint.complainantId]?.phone || 'N/A'}</span>
                  </div>
                  <div className="info-row">
                    <span className="i-label">User ID:</span>
                    <span className="i-val code-val">{selectedComplaint.complainantId || 'N/A'}</span>
                  </div>
                </div>

                {/* Target Worker Info */}
                <div className="info-card">
                  <h4><Briefcase size={16} /> Worker Information</h4>
                  <div className="info-row">
                    <span className="i-label">Name:</span>
                    <span className="i-val">
                      {usersMap[selectedComplaint.againstUserId]?.name ||
                        usersMap[selectedComplaint.againstUserId]?.fullName ||
                        selectedComplaint.againstUserName ||
                        'Worker'}
                    </span>
                  </div>
                  <div className="info-row">
                    <span className="i-label">Category:</span>
                    <span className="i-val">{usersMap[selectedComplaint.againstUserId]?.workType || 'Service Worker'}</span>
                  </div>
                  <div className="info-row">
                    <span className="i-label">Phone:</span>
                    <span className="i-val">{usersMap[selectedComplaint.againstUserId]?.phone || 'N/A'}</span>
                  </div>
                  <div className="info-row">
                    <span className="i-label">Worker ID:</span>
                    <span className="i-val code-val">{selectedComplaint.againstUserId || 'N/A'}</span>
                  </div>
                </div>
              </div>

              {/* ORDER DETAILS */}
              <div className="detail-section-box">
                <h4><Tag size={16} /> Order & Booking Details</h4>
                <div className="info-row">
                  <span className="i-label">Order ID:</span>
                  <span className="i-val code-val">#{selectedComplaint.orderId || 'N/A'}</span>
                </div>
                {ordersMap[selectedComplaint.orderId] && (
                  <>
                    <div className="info-row">
                      <span className="i-label">Service Type:</span>
                      <span className="i-val">{ordersMap[selectedComplaint.orderId]?.serviceName || ordersMap[selectedComplaint.orderId]?.category || 'General Service'}</span>
                    </div>
                    <div className="info-row">
                      <span className="i-label">Order Status:</span>
                      <span className="i-val">{ordersMap[selectedComplaint.orderId]?.status || 'N/A'}</span>
                    </div>
                  </>
                )}
              </div>

              {/* COMPLAINT IMAGES (Cloudinary URLs) */}
              <div className="detail-section-box">
                <h4><ImageIcon size={16} /> Attached Images</h4>
                {extractComplaintImages(selectedComplaint).length > 0 ? (
                  <div className="images-grid">
                    {extractComplaintImages(selectedComplaint).map((url, idx) => (
                      <div
                        key={idx}
                        className="complaint-img-wrapper"
                        onClick={() => setPreviewImage({ label: `Complaint Photo #${idx + 1}`, url })}
                      >
                        <img src={url} alt={`Complaint attachment ${idx + 1}`} className="complaint-img" />
                        <div className="img-overlay">
                          <Eye size={16} /> Enlarge
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="no-images-text">No images attached to this complaint.</p>
                )}
              </div>

              {/* TIMELINE & AUDIT HISTORY */}
              <div className="detail-section-box">
                <h4><Clock size={16} /> Timeline & Resolution History</h4>
                <ul className="timeline-list">
                  <li>
                    <span className="t-dot t-dot-blue"></span>
                    <div className="t-content">
                      <strong>Complaint Filed:</strong> {formatTimestamp(selectedComplaint.createdAt)}
                    </div>
                  </li>
                  {selectedComplaint.reviewedAt && (
                    <li>
                      <span className="t-dot t-dot-amber"></span>
                      <div className="t-content">
                        <strong>Under Review:</strong> {formatTimestamp(selectedComplaint.reviewedAt)} (By {selectedComplaint.reviewedBy || 'Admin'})
                      </div>
                    </li>
                  )}
                  {selectedComplaint.resolvedAt && (
                    <li>
                      <span className="t-dot t-dot-green"></span>
                      <div className="t-content">
                        <strong>Resolved:</strong> {formatTimestamp(selectedComplaint.resolvedAt)}
                      </div>
                    </li>
                  )}
                  {selectedComplaint.rejectedAt && (
                    <li>
                      <span className="t-dot t-dot-red"></span>
                      <div className="t-content">
                        <strong>Rejected:</strong> {formatTimestamp(selectedComplaint.rejectedAt)}
                      </div>
                    </li>
                  )}
                </ul>

                {selectedComplaint.adminRemarks && (
                  <div className="admin-notes-box">
                    <strong>Admin Remarks:</strong>
                    <p>{selectedComplaint.adminRemarks}</p>
                  </div>
                )}
              </div>
            </div>

            {/* MODAL FOOTER ACTIONS */}
            <div className="ch-modal-footer">
              {normalizeStatus(selectedComplaint.status) !== 'under_review' &&
               normalizeStatus(selectedComplaint.status) !== 'resolved' &&
               normalizeStatus(selectedComplaint.status) !== 'rejected' && (
                <button
                  className="btn-action btn-review"
                  onClick={() => {
                    setActionModal({ type: 'review', complaint: selectedComplaint });
                    setAdminRemarks('');
                  }}
                  disabled={actionProcessingId === selectedComplaint.id}
                >
                  <RefreshCw size={14} /> Mark Under Review
                </button>
              )}

              {normalizeStatus(selectedComplaint.status) !== 'resolved' && (
                <button
                  className="btn-action btn-resolve"
                  onClick={() => {
                    setActionModal({ type: 'resolve', complaint: selectedComplaint });
                    setAdminRemarks('');
                  }}
                  disabled={actionProcessingId === selectedComplaint.id}
                >
                  <Check size={14} /> Resolve Complaint
                </button>
              )}

              {normalizeStatus(selectedComplaint.status) !== 'rejected' && (
                <button
                  className="btn-action btn-reject"
                  onClick={() => {
                    setActionModal({ type: 'reject', complaint: selectedComplaint });
                    setAdminRemarks('');
                  }}
                  disabled={actionProcessingId === selectedComplaint.id}
                >
                  <X size={14} /> Reject Complaint
                </button>
              )}

              <button className="btn-cancel" onClick={() => setSelectedComplaint(null)}>
                Close
              </button>
            </div>
          </div>
        </div>
      )}

      {/* CONFIRMATION & REMARKS ACTION DIALOG */}
      {actionModal && (
        <div className="ch-modal-backdrop action-backdrop">
          <div className="ch-action-modal">
            <h3>
              {actionModal.type === 'resolve' && 'Resolve Complaint'}
              {actionModal.type === 'reject' && 'Reject Complaint'}
              {actionModal.type === 'review' && 'Mark as Under Review'}
            </h3>

            <p className="action-desc">
              {actionModal.type === 'resolve' && 'Confirm resolving this complaint. You can optionally add notes for the customer and worker.'}
              {actionModal.type === 'reject' && 'Please state the reason for rejecting this complaint.'}
              {actionModal.type === 'review' && 'Move this complaint status to Under Review.'}
            </p>

            {modalError && <p className="modal-error">{modalError}</p>}

            <textarea
              rows={3}
              className="action-textarea"
              placeholder={actionModal.type === 'reject' ? 'Enter rejection reason (Required)...' : 'Enter admin notes / remarks (Optional)...'}
              value={adminRemarks}
              onChange={(e) => {
                setAdminRemarks(e.target.value);
                if (modalError) setModalError('');
              }}
            />

            <div className="action-modal-footer">
              <button className="btn-cancel" onClick={() => setActionModal(null)}>
                Cancel
              </button>
              <button
                className={`btn-confirm ${
                  actionModal.type === 'resolve' ? 'btn-resolve' : actionModal.type === 'reject' ? 'btn-reject' : 'btn-review'
                }`}
                onClick={handleConfirmAction}
                disabled={actionProcessingId !== null}
              >
                {actionProcessingId ? 'Processing...' : 'Confirm Action'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* LIGHTBOX FOR CLOUDINARY ATTACHMENT PREVIEW */}
      {previewImage && (
        <div className="lightbox-backdrop" onClick={() => setPreviewImage(null)}>
          <div className="lightbox-content" onClick={(e) => e.stopPropagation()}>
            <div className="lightbox-header">
              <h3>{previewImage.label}</h3>
              <button className="lightbox-close" onClick={() => setPreviewImage(null)}>
                <X size={20} />
              </button>
            </div>
            <div className="lightbox-body">
              <img src={previewImage.url} alt={previewImage.label} />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}