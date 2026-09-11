import React, { useState, useEffect, useMemo } from 'react';
import { db } from '../../config/firebase';
import { collection, onSnapshot, doc, setDoc, writeBatch, serverTimestamp } from 'firebase/firestore';
import {
  Bell,
  Send,
  Users,
  User,
  Wrench,
  AlertTriangle,
  Sparkles,
  ShieldAlert,
  CheckCircle2,
  AlertCircle,
  RefreshCw,
  Search,
  Check,
  X,
  FileText
} from 'lucide-react';
import PageHeader from '../../components/common/PageHeader';
import './Notifications.css';

// Preset Notification Templates
const TEMPLATES = [
  {
    id: 'system_alert',
    name: 'System Alert',
    icon: AlertTriangle,
    title: 'Important System Alert',
    body: 'We are currently conducting essential maintenance on the platform. Some services may be temporarily delayed.',
    type: 'system_alert',
  },
  {
    id: 'maintenance',
    name: 'Maintenance Notice',
    icon: Wrench,
    title: 'Scheduled Platform Maintenance',
    body: 'The platform will undergo scheduled system maintenance tonight from 2:00 AM to 4:00 AM. Thank you for your patience.',
    type: 'system_alert',
  },
  {
    id: 'promotion',
    name: 'Promotional Discount',
    icon: Sparkles,
    title: 'Special Offer Available!',
    body: 'Enjoy a special discount on your next home repair service! Book now on Tech Drive.',
    type: 'announcement',
  },
  {
    id: 'safety_reminder',
    name: 'Safety Reminder',
    icon: ShieldAlert,
    title: 'Safety & Security Reminder',
    body: 'Always verify the service provider identity and order details before granting home entry.',
    type: 'announcement',
  },
];

export default function Notifications() {
  // Real-time Users List from Firestore
  const [usersList, setUsersList] = useState([]);
  const [loadingUsers, setLoadingUsers] = useState(true);

  // Form State
  const [targetAudience, setTargetAudience] = useState('single'); // 'single', 'customers', 'workers', 'all'
  const [selectedUserUid, setSelectedUserUid] = useState('');
  const [userSearchQuery, setUserSearchQuery] = useState('');
  
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [notificationType, setNotificationType] = useState('system_alert');

  // Execution States
  const [sending, setSending] = useState(false);
  const [feedback, setFeedback] = useState(null); // { type: 'success'|'error', message: '' }

  // Subscribe to users collection for audience targeting
  useEffect(() => {
    setLoadingUsers(true);
    const unsub = onSnapshot(
      collection(db, 'users'),
      (snap) => {
        const uData = snap.docs.map((d) => ({
          id: d.id,
          uid: d.id,
          ...d.data(),
        }));
        setUsersList(uData);
        setLoadingUsers(false);
      },
      (err) => {
        console.error('Error fetching users:', err);
        setLoadingUsers(false);
      }
    );
    return () => unsub();
  }, []);

  // Filtered users for Single User picker search
  const filteredSearchUsers = useMemo(() => {
    if (!userSearchQuery.trim()) return usersList.slice(0, 10);
    const term = userSearchQuery.toLowerCase();
    return usersList.filter(
      (u) =>
        (u.name || u.fullName || '').toLowerCase().includes(term) ||
        (u.email || '').toLowerCase().includes(term) ||
        (u.phone || '').toLowerCase().includes(term) ||
        (u.id || '').toLowerCase().includes(term)
    ).slice(0, 10);
  }, [usersList, userSearchQuery]);

  // Selected User Object
  const selectedUserObj = useMemo(() => {
    return usersList.find((u) => u.id === selectedUserUid) || null;
  }, [usersList, selectedUserUid]);

  // Compute Target Recipients List
  const targetRecipients = useMemo(() => {
    if (targetAudience === 'single') {
      return selectedUserObj ? [selectedUserObj] : [];
    }
    if (targetAudience === 'customers') {
      return usersList.filter((u) => (u.userType || '').toLowerCase() === 'customer');
    }
    if (targetAudience === 'workers') {
      return usersList.filter(
        (u) => (u.userType || '').toLowerCase() === 'worker' || u.workerStatus
      );
    }
    if (targetAudience === 'all') {
      return usersList;
    }
    return [];
  }, [targetAudience, selectedUserObj, usersList]);

  // Apply Template Preset
  const handleApplyTemplate = (tpl) => {
    setTitle(tpl.title);
    setBody(tpl.body);
    setNotificationType(tpl.type);
    setFeedback({
      type: 'info',
      message: `Applied "${tpl.name}" template.`,
    });
  };

  // Dispatch Notification (Write directly to users/{uid}/notifications/{docId})
  const handleSendNotification = async (e) => {
    e.preventDefault();
    setFeedback(null);

    if (!title.trim()) {
      setFeedback({ type: 'error', message: 'Please enter a notification title.' });
      return;
    }
    if (!body.trim()) {
      setFeedback({ type: 'error', message: 'Please enter notification body content.' });
      return;
    }
    if (targetAudience === 'single' && !selectedUserUid) {
      setFeedback({ type: 'error', message: 'Please select a recipient user.' });
      return;
    }
    if (targetRecipients.length === 0) {
      setFeedback({ type: 'error', message: 'No target recipients found for the selected audience.' });
      return;
    }

    setSending(true);

    try {
      const totalTargets = targetRecipients.length;
      const docType = notificationType.trim() || 'system_alert';

      if (totalTargets === 1) {
        // Single User Dispatch
        const targetUid = targetRecipients[0].id || targetRecipients[0].uid;
        const customDocId = `admin_${Date.now()}_${targetUid.slice(0, 6)}`;
        
        await setDoc(doc(db, 'users', targetUid, 'notifications', customDocId), {
          userId: targetUid,
          receiverId: targetUid,
          senderId: 'admin',
          orderId: '',
          title: title.trim(),
          body: body.trim(),
          type: docType,
          isRead: false,
          createdAt: serverTimestamp(),
        });

        setFeedback({
          type: 'success',
          message: `Successfully sent in-app notification to ${targetRecipients[0].name || targetRecipients[0].email || 'user'}.`,
        });
      } else {
        // Broadcast Dispatch using writeBatch (chunked by 450 targets per batch)
        const BATCH_LIMIT = 450;
        let processedCount = 0;

        for (let i = 0; i < totalTargets; i += BATCH_LIMIT) {
          const chunk = targetRecipients.slice(i, i + BATCH_LIMIT);
          const batch = writeBatch(db);

          let batchCount = 0;
          chunk.forEach((usr) => {
            const targetUid = usr.id || usr.uid;
            if (targetUid) {
              const customDocId = `admin_${Date.now()}_${targetUid.slice(0, 6)}`;
              const notifRef = doc(db, 'users', targetUid, 'notifications', customDocId);
              batch.set(notifRef, {
                userId: targetUid,
                receiverId: targetUid,
                senderId: 'admin',
                orderId: '',
                title: title.trim(),
                body: body.trim(),
                type: docType,
                isRead: false,
                createdAt: serverTimestamp(),
              });
              batchCount++;
            }
          });

          await batch.commit();
          processedCount += batchCount;
        }

        setFeedback({
          type: 'success',
          message: `Successfully broadcasted notification to ${processedCount} users across ${targetAudience.toUpperCase()}.`,
        });
      }

      // Reset Form fields
      setTitle('');
      setBody('');
    } catch (err) {
      console.error('Error dispatching notifications:', err);
      setFeedback({
        type: 'error',
        message: `Failed to send notification: ${err.message || 'Firestore write error.'}`,
      });
    } finally {
      setSending(false);
    }
  };

  return (
    <div className="notif-page animate-fade">
      <PageHeader
        title="Push & In-App Notifications Dispatcher"
        subtitle="Send targeted or platform-wide real-time notifications directly to customer and worker devices."
      />

      {/* FEEDBACK BANNER */}
      {feedback && (
        <div className={`notif-feedback-banner notif-feedback-banner--${feedback.type}`}>
          {feedback.type === 'success' && <CheckCircle2 size={18} />}
          {feedback.type === 'error' && <AlertCircle size={18} />}
          {feedback.type === 'info' && <FileText size={18} />}
          <span>{feedback.message}</span>
          <button className="banner-close-btn" onClick={() => setFeedback(null)}>
            <X size={14} />
          </button>
        </div>
      )}

      {/* TEMPLATES STRIP */}
      <div className="templates-section">
        <h4 className="templates-title">
          <Sparkles size={16} /> Quick Notification Templates
        </h4>
        <div className="templates-grid">
          {TEMPLATES.map((tpl) => {
            const IconComp = tpl.icon;
            return (
              <button
                key={tpl.id}
                type="button"
                className="template-card"
                onClick={() => handleApplyTemplate(tpl)}
              >
                <div className="template-icon">
                  <IconComp size={18} />
                </div>
                <div className="template-info">
                  <span className="template-name">{tpl.name}</span>
                  <span className="template-type">{tpl.type}</span>
                </div>
              </button>
            );
          })}
        </div>
      </div>

      {/* DISPATCH FORM CONTAINER */}
      <div className="notif-form-card">
        <form onSubmit={handleSendNotification}>
          <div className="form-header">
            <h3><Send size={18} /> Compose & Dispatch Notification</h3>
            <span className="recipients-counter">
              Recipients: <strong>{loadingUsers ? '...' : targetRecipients.length}</strong>
            </span>
          </div>

          {/* STEP 1: TARGET AUDIENCE SELECTOR */}
          <div className="form-group">
            <label className="form-label">1. Target Audience</label>
            <div className="audience-selector-grid">
              <button
                type="button"
                className={`audience-btn ${targetAudience === 'single' ? 'active' : ''}`}
                onClick={() => setTargetAudience('single')}
              >
                <User size={16} />
                <span>Single User</span>
              </button>
              <button
                type="button"
                className={`audience-btn ${targetAudience === 'customers' ? 'active' : ''}`}
                onClick={() => setTargetAudience('customers')}
              >
                <Users size={16} />
                <span>All Customers</span>
              </button>
              <button
                type="button"
                className={`audience-btn ${targetAudience === 'workers' ? 'active' : ''}`}
                onClick={() => setTargetAudience('workers')}
              >
                <Wrench size={16} />
                <span>All Workers</span>
              </button>
              <button
                type="button"
                className={`audience-btn ${targetAudience === 'all' ? 'active' : ''}`}
                onClick={() => setTargetAudience('all')}
              >
                <Bell size={16} />
                <span>All Platform Users</span>
              </button>
            </div>
          </div>

          {/* SINGLE USER PICKER SEARCH */}
          {targetAudience === 'single' && (
            <div className="form-group single-user-picker">
              <label className="form-label">Select Recipient User</label>
              <div className="user-search-input-wrap">
                <Search size={16} className="search-icon" />
                <input
                  type="text"
                  placeholder="Search user by name, email, phone, or UID..."
                  value={userSearchQuery}
                  onChange={(e) => setUserSearchQuery(e.target.value)}
                />
              </div>

              <div className="user-picker-results">
                {filteredSearchUsers.map((u) => {
                  const isSelected = selectedUserUid === u.id;
                  return (
                    <div
                      key={u.id}
                      className={`user-picker-item ${isSelected ? 'selected' : ''}`}
                      onClick={() => setSelectedUserUid(u.id)}
                    >
                      <div className="picker-avatar">
                        {(u.name || u.fullName || 'U').charAt(0).toUpperCase()}
                      </div>
                      <div className="picker-details">
                        <span className="picker-name">{u.name || u.fullName || 'User'}</span>
                        <span className="picker-meta">{u.email || u.phone || u.id} • {u.userType || 'User'}</span>
                      </div>
                      {isSelected && <Check size={16} className="picker-check" />}
                    </div>
                  );
                })}
              </div>

              {selectedUserObj && (
                <div className="selected-user-badge">
                  Selected: <strong>{selectedUserObj.name || selectedUserObj.email}</strong> (UID: {selectedUserObj.id})
                </div>
              )}
            </div>
          )}

          {/* STEP 2: NOTIFICATION TYPE */}
          <div className="form-group">
            <label className="form-label">2. Notification Type</label>
            <select
              value={notificationType}
              onChange={(e) => setNotificationType(e.target.value)}
              className="notif-input-select"
            >
              <option value="system_alert">system_alert (Alert / Maintenance)</option>
              <option value="announcement">announcement (Promotions / News)</option>
              <option value="order_update">order_update (Order Notice)</option>
              <option value="admin_notice">admin_notice (General Admin Notice)</option>
            </select>
          </div>

          {/* STEP 3: TITLE & BODY */}
          <div className="form-group">
            <label className="form-label">3. Notification Title</label>
            <input
              type="text"
              placeholder="e.g. Scheduled System Maintenance Notice"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="notif-input-text"
              required
            />
          </div>

          <div className="form-group">
            <label className="form-label">4. Notification Body Content</label>
            <textarea
              rows={4}
              placeholder="Enter full notification message content displayed on customer/worker devices..."
              value={body}
              onChange={(e) => setBody(e.target.value)}
              className="notif-input-textarea"
              required
            />
          </div>

          {/* SUBMIT BUTTON */}
          <div className="form-footer">
            <button
              type="submit"
              disabled={sending}
              className="btn-send-notif"
            >
              {sending ? (
                <>
                  <RefreshCw className="spin-icon" size={16} />
                  <span>Dispatching Notification...</span>
                </>
              ) : (
                <>
                  <Send size={16} />
                  <span>Send Notification to {targetRecipients.length} Recipient{targetRecipients.length !== 1 ? 's' : ''}</span>
                </>
              )}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}