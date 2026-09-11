import React, { useState, useEffect, useMemo } from "react";
import PageHeader from '../../components/common/PageHeader';
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
  CheckCircle, 
  XCircle, 
  FileText, 
  User, 
  Phone, 
  Mail, 
  Briefcase, 
  Award, 
  Eye,
  X,
  Search,
  Check,
  Tag
} from 'lucide-react';
import "./Verification.css";

// Helper function to extract document image URL flexibly from Firestore data sources
function extractImageUrl(docsData, reqData, userData, fieldKeys) {
  const sources = [
    docsData?.documents,
    docsData,
    reqData?.documents,
    reqData,
    userData?.documents,
    userData,
  ];

  for (const src of sources) {
    if (!src || typeof src !== 'object') continue;
    for (const key of fieldKeys) {
      const val = src[key];
      if (val && typeof val === 'string' && val.trim().length > 0) {
        return val.trim();
      }
    }
  }
  return null;
}

export default function Verification() {
  const { currentUser } = useAuth();

  const [requests, setRequests] = useState([]);
  const [documentsMap, setDocumentsMap] = useState({});
  const [usersMap, setUsersMap] = useState({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [processingId, setProcessingId] = useState(null);
  
  // Selected / Expanded worker state
  const [openId, setOpenId] = useState(null);
  const [statusFilter, setStatusFilter] = useState("pending"); // "pending", "approved", "rejected", "all"
  const [searchTerm, setSearchTerm] = useState("");

  // Lightbox / Image modal state
  const [previewImage, setPreviewImage] = useState(null); // { label, url }

  // Rejection modal state
  const [rejectionModalId, setRejectionModalId] = useState(null);
  const [rejectionReason, setRejectionReason] = useState("");
  const [rejectionError, setRejectionError] = useState("");

  useEffect(() => {
    // Stream worker_requests collection in real-time
    const unsubRequests = onSnapshot(
      collection(db, 'worker_requests'),
      async (snapshot) => {
        const allDocs = [];
        const docPromises = [];
        const userPromises = [];

        snapshot.docs.forEach((docSnap) => {
          const data = docSnap.data() || {};
          const uid = docSnap.id;

          allDocs.push({
            uid: uid,
            id: uid,
            ...data,
          });

          // Fetch worker_documents for this applicant (store entire document data for flexible lookup)
          docPromises.push(
            getDoc(doc(db, 'worker_documents', uid)).then((dSnap) => ({
              uid,
              docsData: dSnap.exists() ? dSnap.data() || {} : {},
            }))
          );

          // Fetch users collection for user email, name, phone, age
          userPromises.push(
            getDoc(doc(db, 'users', uid)).then((uSnap) => ({
              uid,
              userData: uSnap.exists() ? uSnap.data() || {} : {},
            }))
          );
        });

        // Resolve associated documents and user profiles
        const docResults = await Promise.all(docPromises);
        const userResults = await Promise.all(userPromises);

        const newDocsMap = {};
        docResults.forEach((item) => {
          newDocsMap[item.uid] = item.docsData || {};
        });

        const newUsersMap = {};
        userResults.forEach((item) => {
          newUsersMap[item.uid] = item.userData || {};
        });

        setRequests(allDocs);
        setDocumentsMap(newDocsMap);
        setUsersMap(newUsersMap);
        setLoading(false);
      },
      (err) => {
        console.error("Error loading worker requests:", err);
        setError("Failed to load worker verification applications.");
        setLoading(false);
      }
    );

    return () => unsubRequests();
  }, []);

  // Filter requests based on status tab and search keyword
  const filteredRequests = useMemo(() => {
    return requests.filter((req) => {
      const status = (req.status || 'pending').toLowerCase();
      
      let matchesStatus = true;
      if (statusFilter === 'pending') {
        matchesStatus = status === 'pending' || status === 'quiz_completed';
      } else if (statusFilter === 'approved') {
        matchesStatus = status === 'approved';
      } else if (statusFilter === 'rejected') {
        matchesStatus = status === 'rejected';
      }

      const userObj = usersMap[req.uid] || {};
      const name = (req.name || userObj.name || '').toLowerCase();
      const email = (userObj.email || req.email || '').toLowerCase();
      const phone = (req.phone || userObj.phone || '').toLowerCase();
      const workType = (req.workType || '').toLowerCase();

      const term = searchTerm.toLowerCase().trim();
      const matchesSearch = !term || 
        name.includes(term) || 
        email.includes(term) || 
        phone.includes(term) || 
        workType.includes(term);

      return matchesStatus && matchesSearch;
    });
  }, [requests, statusFilter, searchTerm, usersMap]);

  // Count pending applications
  const pendingCount = useMemo(() => {
    return requests.filter(r => {
      const st = (r.status || 'pending').toLowerCase();
      return st === 'pending' || st === 'quiz_completed';
    }).length;
  }, [requests]);

  // ================= APPROVE WORKER =================
  const handleApprove = async (workerUid) => {
    if (processingId) return;

    if (!window.confirm("Are you sure you want to approve this worker?")) {
      return;
    }

    setProcessingId(workerUid);
    setError(null);

    try {
      // 1. Re-read current status to prevent duplicate actions
      const freshReqSnap = await getDoc(doc(db, 'worker_requests', workerUid));
      if (freshReqSnap.exists()) {
        const currentStatus = freshReqSnap.data()?.status;
        if (currentStatus === 'approved' || currentStatus === 'rejected') {
          alert(`This application has already been ${currentStatus}.`);
          setProcessingId(null);
          return;
        }
      }

      // 2. Perform WriteBatch: update worker_requests and users collections
      const batch = writeBatch(db);

      const userRef = doc(db, 'users', workerUid);
      const requestRef = doc(db, 'worker_requests', workerUid);

      batch.update(userRef, {
        userType: 'worker',
        workerStatus: 'approved',
      });

      batch.update(requestRef, {
        status: 'approved',
        approvedAt: serverTimestamp(),
        reviewedAt: serverTimestamp(),
        reviewedBy: currentUser?.uid || 'admin',
      });

      await batch.commit();

      alert("Worker application approved successfully!");
    } catch (err) {
      console.error("Approval transaction failed:", err);
      alert(`Approval failed: ${err.message}`);
    } finally {
      setProcessingId(null);
    }
  };

  // ================= REJECT WORKER =================
  const openRejectionModal = (workerUid) => {
    setRejectionModalId(workerUid);
    setRejectionReason("");
    setRejectionError("");
  };

  const handleConfirmReject = async () => {
    const workerUid = rejectionModalId;
    if (!workerUid || processingId) return;

    const trimmedReason = rejectionReason.trim();
    if (!trimmedReason) {
      setRejectionError("Rejection reason cannot be empty.");
      return;
    }

    setProcessingId(workerUid);
    setError(null);

    try {
      // 1. Re-read current status to prevent duplicate actions
      const freshReqSnap = await getDoc(doc(db, 'worker_requests', workerUid));
      if (freshReqSnap.exists()) {
        const currentStatus = freshReqSnap.data()?.status;
        if (currentStatus === 'approved' || currentStatus === 'rejected') {
          alert(`This application has already been ${currentStatus}.`);
          setRejectionModalId(null);
          setProcessingId(null);
          return;
        }
      }

      // 2. Perform WriteBatch: update worker_requests and users collections
      const batch = writeBatch(db);

      const requestRef = doc(db, 'worker_requests', workerUid);
      const userRef = doc(db, 'users', workerUid);

      batch.update(requestRef, {
        status: 'rejected',
        rejectionReason: trimmedReason,
        rejectedAt: serverTimestamp(),
        reviewedAt: serverTimestamp(),
        reviewedBy: currentUser?.uid || 'admin',
      });

      batch.update(userRef, {
        workerStatus: 'rejected',
      });

      await batch.commit();

      alert("Worker application rejected.");
      setRejectionModalId(null);
    } catch (err) {
      console.error("Rejection transaction failed:", err);
      alert(`Rejection failed: ${err.message}`);
    } finally {
      setProcessingId(null);
    }
  };

  if (loading) {
    return (
      <div className="verification-page animate-fade" style={{ textAlign: 'center', padding: '60px 20px' }}>
        <p style={{ fontSize: '16px', color: '#6B7280' }}>Loading pending worker verifications...</p>
      </div>
    );
  }

  return (
    <div className="verification-page animate-fade">
      <PageHeader
        title="Worker Verification Management"
        subtitle="Review technician verification applications, documents, and quiz results."
      />

      {error && (
        <div style={{ padding: '12px 16px', backgroundColor: '#FEE2E2', color: '#DC2626', borderRadius: '8px', marginBottom: '20px' }}>
          {error}
        </div>
      )}

      {/* FILTER & SEARCH TOOLBAR */}
      <div className="verification-toolbar">
        <div className="toolbar-left">
          <div className="status-tabs">
            <button
              className={`tab-btn ${statusFilter === 'pending' ? 'tab-btn--active' : ''}`}
              onClick={() => setStatusFilter('pending')}
            >
              Pending Verification
              {pendingCount > 0 && <span className="tab-badge">{pendingCount}</span>}
            </button>
            <button
              className={`tab-btn ${statusFilter === 'approved' ? 'tab-btn--active' : ''}`}
              onClick={() => setStatusFilter('approved')}
            >
              Approved
            </button>
            <button
              className={`tab-btn ${statusFilter === 'rejected' ? 'tab-btn--active' : ''}`}
              onClick={() => setStatusFilter('rejected')}
            >
              Rejected
            </button>
            <button
              className={`tab-btn ${statusFilter === 'all' ? 'tab-btn--active' : ''}`}
              onClick={() => setStatusFilter('all')}
            >
              All Applications
            </button>
          </div>
        </div>

        <div className="toolbar-right">
          <div className="search-box">
            <Search size={16} className="search-icon" />
            <input
              type="text"
              placeholder="Search by name, email, phone..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
            />
            {searchTerm && (
              <X size={14} className="clear-search" onClick={() => setSearchTerm("")} />
            )}
          </div>
        </div>
      </div>

      {/* WORKERS LIST */}
      {filteredRequests.length === 0 ? (
        <div className="empty-state-card">
          <CheckCircle size={48} style={{ color: '#10B981', marginBottom: '12px' }} />
          <h3>No Applications Found</h3>
          <p>
            {statusFilter === 'pending'
              ? "All worker verification requests have been processed."
              : "No worker applications match the selected criteria."}
          </p>
        </div>
      ) : (
        <div className="cards-grid">
          {filteredRequests.map((w) => {
            const uid = w.uid;
            const userObj = usersMap[uid] || {};
            const docsObj = documentsMap[uid] || {};

            // 11 Required Fields extraction:
            const fullName = w.name || userObj.name || userObj.fullName || 'Applicant';
            const email = userObj.email || w.email || 'N/A';
            const phone = w.phone || userObj.phone || 'N/A';
            const age = userObj.age || w.age || userObj.userAge || 'N/A';
            const experience = w.experience !== undefined && w.experience !== null ? `${w.experience} yrs` : 'N/A';
            const serviceCategory = w.workType || w.serviceCategory || 'General Worker';
            
            // Cloudinary Document Image URLs with complete field name fallback support
            const cnicFront = extractImageUrl(docsObj, w, userObj, ['cnicFront', 'cnic_front', 'cnicFrontUrl', 'cnic_front_url', 'cnicFrontImage', 'cnic_front_image', 'cnic1']);
            const cnicBack = extractImageUrl(docsObj, w, userObj, ['cnicBack', 'cnic_back', 'cnicBackUrl', 'cnic_back_url', 'cnicBackImage', 'cnic_back_image', 'cnic2']);
            const selfie = extractImageUrl(docsObj, w, userObj, ['selfie', 'selfieWithCnic', 'selfie_with_cnic', 'selfieUrl', 'selfie_url', 'selfieImage', 'selfie_image']);
            const toolsPhoto = extractImageUrl(docsObj, w, userObj, ['tools', 'toolsPhoto', 'tools_photo', 'toolsUrl', 'tools_url', 'toolsPicture', 'tools_picture']);
            const profilePic = extractImageUrl(docsObj, w, userObj, ['profile', 'profilePic', 'profile_pic', 'profilePicture', 'profile_picture', 'profileUrl', 'profile_url', 'avatar']);
            const policeVerification = extractImageUrl(docsObj, w, userObj, ['police', 'policeVerification', 'police_verification', 'policeUrl', 'police_url', 'policeVerificationUrl']);

            // Quiz Status & Result
            const score = w.score !== undefined && w.score !== null ? w.score : null;
            const total = w.total !== undefined && w.total !== null ? w.total : null;
            const quizPassed = w.passed;
            const quizStatusText = score !== null && total !== null 
              ? `${score} / ${total} (${quizPassed === true ? 'Passed' : quizPassed === false ? 'Failed' : 'Completed'})` 
              : w.completedAt ? 'Completed' : 'Not Taken';

            const status = (w.status || 'pending').toLowerCase();
            const isOpen = openId === uid;
            const canAct = status === 'pending' || status === 'quiz_completed';

            return (
              <div key={uid} className={`card ${isOpen ? 'card--expanded' : ''}`}>
                {/* CARD HEADER */}
                <div className="top">
                  <div className="user-info">
                    <div className="avatar">{fullName.charAt(0).toUpperCase()}</div>
                    <div>
                      <h3>{fullName}</h3>
                      <div className="role">
                        <Tag size={12} style={{ display: 'inline', marginRight: '4px' }} />
                        {serviceCategory} {w.area ? `· ${w.area}` : ''}
                      </div>
                    </div>
                  </div>
                  <span className={`badge ${status}`}>{status.toUpperCase()}</span>
                </div>

                {/* WORKER DETAILS SUMMARY */}
                <div className="worker-details-grid">
                  <div className="detail-item">
                    <Mail size={14} className="detail-icon" />
                    <div>
                      <span className="detail-label">Email</span>
                      <span className="detail-value">{email}</span>
                    </div>
                  </div>

                  <div className="detail-item">
                    <Phone size={14} className="detail-icon" />
                    <div>
                      <span className="detail-label">Phone</span>
                      <span className="detail-value">{phone}</span>
                    </div>
                  </div>

                  <div className="detail-item">
                    <User size={14} className="detail-icon" />
                    <div>
                      <span className="detail-label">Age</span>
                      <span className="detail-value">{age !== 'N/A' ? `${age} yrs` : 'N/A'}</span>
                    </div>
                  </div>

                  <div className="detail-item">
                    <Briefcase size={14} className="detail-icon" />
                    <div>
                      <span className="detail-label">Experience</span>
                      <span className="detail-value">{experience}</span>
                    </div>
                  </div>

                  <div className="detail-item">
                    <Award size={14} className="detail-icon" />
                    <div>
                      <span className="detail-label">Quiz Result</span>
                      <span className={`detail-value ${quizPassed ? 'text-green' : quizPassed === false ? 'text-red' : ''}`}>
                        {quizStatusText}
                      </span>
                    </div>
                  </div>
                </div>

                {/* TIMESTAMPS / REJECTION REASON IF APPLICABLE */}
                {(w.rejectionReason || w.approvedAt || w.rejectedAt) && (
                  <div className="audit-info">
                    {w.approvedAt && (
                      <div className="audit-line text-green">
                        <CheckCircle size={12} /> Approved
                      </div>
                    )}
                    {w.rejectedAt && (
                      <div className="audit-line text-red">
                        <XCircle size={12} /> Rejected
                      </div>
                    )}
                    {w.rejectionReason && (
                      <div className="rejection-reason-text">
                        <strong>Reason:</strong> {w.rejectionReason}
                      </div>
                    )}
                  </div>
                )}

                {/* ACTIONS & EXPAND BUTTON */}
                <div className="actions">
                  {canAct && (
                    <>
                      <button 
                        className="approve-btn" 
                        disabled={processingId === uid}
                        onClick={() => handleApprove(uid)}
                      >
                        <Check size={14} style={{ marginRight: '4px' }} />
                        Approve
                      </button>
                      <button 
                        className="reject-btn" 
                        disabled={processingId === uid}
                        onClick={() => openRejectionModal(uid)}
                      >
                        <X size={14} style={{ marginRight: '4px' }} />
                        Reject
                      </button>
                    </>
                  )}
                  <button className="view-btn" onClick={() => setOpenId(isOpen ? null : uid)}>
                    <Eye size={14} style={{ marginRight: '4px' }} />
                    {isOpen ? "Hide Verification Details" : "View Full Details"}
                  </button>
                </div>

                {/* EXPANDED VERIFICATION DETAILS & DOCUMENTS */}
                {isOpen && (
                  <div className="expand animate-fade">
                    <h4 className="expand-title">Complete Verification Document Flow</h4>
                    
                    {/* ALL 11 REQUIRED FIELDS SUMMARY TABLE */}
                    <div className="fields-summary-card">
                      <div className="summary-row">
                        <span className="s-label">Full Name:</span>
                        <span className="s-value">{fullName}</span>
                      </div>
                      <div className="summary-row">
                        <span className="s-label">Email Address:</span>
                        <span className="s-value">{email}</span>
                      </div>
                      <div className="summary-row">
                        <span className="s-label">Phone Number:</span>
                        <span className="s-value">{phone}</span>
                      </div>
                      <div className="summary-row">
                        <span className="s-label">Age:</span>
                        <span className="s-value">{age !== 'N/A' ? `${age} years old` : 'N/A'}</span>
                      </div>
                      <div className="summary-row">
                        <span className="s-label">Experience:</span>
                        <span className="s-value">{experience}</span>
                      </div>
                      <div className="summary-row">
                        <span className="s-label">Service Category:</span>
                        <span className="s-value">{serviceCategory}</span>
                      </div>
                        <div className="summary-row">
                        <span className="s-label">Quiz Result / Status:</span>
                        <span className="s-value">{quizStatusText}</span>
                      </div>
                    </div>

                    <h4 className="expand-subtitle">Verification Documents</h4>
                    <div className="docs-grid">
                      {/* CNIC Front */}
                      <DocImageCard 
                        label="CNIC Front Image" 
                        url={cnicFront} 
                        onPreview={(url) => setPreviewImage({ label: "CNIC Front", url })}
                      />
                      
                      {/* CNIC Back */}
                      <DocImageCard 
                        label="CNIC Back Image" 
                        url={cnicBack} 
                        onPreview={(url) => setPreviewImage({ label: "CNIC Back", url })}
                      />
                      
                      {/* Selfie */}
                      <DocImageCard 
                        label="Selfie with CNIC" 
                        url={selfie} 
                        onPreview={(url) => setPreviewImage({ label: "Selfie with CNIC", url })}
                      />

                      {/* Tools Photo */}
                      <DocImageCard 
                        label="Tools Photo" 
                        url={toolsPhoto} 
                        onPreview={(url) => setPreviewImage({ label: "Tools Photo", url })}
                      />

                      {/* Profile Picture */}
                      <DocImageCard 
                        label="Profile Picture" 
                        url={profilePic} 
                        onPreview={(url) => setPreviewImage({ label: "Profile Picture", url })}
                      />

                      {/* Police Verification */}
                      <DocImageCard 
                        label="Police Verification" 
                        url={policeVerification} 
                        onPreview={(url) => setPreviewImage({ label: "Police Verification", url })}
                      />
                    </div>
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* LIGHTBOX IMAGE PREVIEW MODAL */}
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

      {/* REJECTION REASON MODAL */}
      {rejectionModalId && (
        <div className="modal-backdrop">
          <div className="modal-content">
            <h3 className="modal-title">Reject Worker Application</h3>
            <p className="modal-desc">
              Please enter a clear reason for rejecting this application. This explanation will be saved in Firestore and visible to the applicant.
            </p>

            {rejectionError && (
              <p className="modal-error">{rejectionError}</p>
            )}

            <textarea
              rows={4}
              value={rejectionReason}
              onChange={(e) => {
                setRejectionReason(e.target.value);
                if (rejectionError) setRejectionError("");
              }}
              placeholder="Provide reason for rejection..."
              className="modal-textarea"
            />

            <div className="modal-actions">
              <button
                className="btn-cancel"
                onClick={() => setRejectionModalId(null)}
              >
                Cancel
              </button>
              <button
                className="btn-confirm-reject"
                onClick={handleConfirmReject}
                disabled={processingId !== null}
              >
                {processingId ? "Processing..." : "Confirm Rejection"}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// Helper component to render individual verification document card
function DocImageCard({ label, url, onPreview }) {
  const [imgError, setImgError] = useState(false);

  return (
    <div className="doc-image-card">
      <p className="doc-label">{label}</p>
      
      {url && !imgError ? (
        <div className="doc-image-wrapper" onClick={() => onPreview && onPreview(url)}>
          <img 
            src={url} 
            alt={label} 
            onError={() => setImgError(true)}
            className="doc-img"
          />
          <div className="doc-overlay">
            <Eye size={18} />
            <span>Click to Enlarge</span>
          </div>
        </div>
      ) : (
        <div className="doc-placeholder">
          <FileText size={24} style={{ marginBottom: '4px', opacity: 0.5 }} />
          <span>{url ? "Failed to load image" : "Not uploaded"}</span>
        </div>
      )}
    </div>
  );
}
