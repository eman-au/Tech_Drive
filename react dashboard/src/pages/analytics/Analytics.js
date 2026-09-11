import React, { useState, useEffect, useMemo, useCallback } from 'react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  BarChart,
  Bar,
  LineChart,
  Line,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend
} from 'recharts';
import PageHeader from '../../components/common/PageHeader';
import { db } from '../../config/firebase';
import { collection, onSnapshot } from 'firebase/firestore';
import {
  TrendingUp,
  Users,
  CheckCircle2,
  Clock,
  XCircle,
  Star,
  AlertCircle,
  Briefcase,
  Tag,
  DollarSign,
  Calendar,
  RefreshCw,
  Award,
  FileText
} from 'lucide-react';
import './Analytics.css';

export default function Analytics() {
  // Firestore raw snapshot data states
  const [orders, setOrders] = useState([]);
  const [users, setUsers] = useState([]);
  const [workerRequests, setWorkerRequests] = useState([]);
  const [ratings, setRatings] = useState([]);
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Date Filter State
  const [dateFilter, setDateFilter] = useState('30days'); // 'today', '7days', '30days', 'month', 'year', 'custom'
  const [customStartDate, setCustomStartDate] = useState('');
  const [customEndDate, setCustomEndDate] = useState('');

  // Real-time listeners for all analytics Firestore collections
  useEffect(() => {
    setLoading(true);
    let loadedCount = 0;
    const totalCollections = 5;

    const checkFinished = () => {
      loadedCount++;
      if (loadedCount >= totalCollections) {
        setLoading(false);
      }
    };

    const unsubOrders = onSnapshot(
      collection(db, 'orders'),
      (snap) => {
        setOrders(snap.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading orders for analytics:", err);
        setError("Failed to load orders dataset.");
        checkFinished();
      }
    );

    const unsubUsers = onSnapshot(
      collection(db, 'users'),
      (snap) => {
        setUsers(snap.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading users for analytics:", err);
        checkFinished();
      }
    );

    const unsubRequests = onSnapshot(
      collection(db, 'worker_requests'),
      (snap) => {
        setWorkerRequests(snap.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading worker_requests for analytics:", err);
        checkFinished();
      }
    );

    const unsubRatings = onSnapshot(
      collection(db, 'ratings'),
      (snap) => {
        setRatings(snap.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading ratings for analytics:", err);
        checkFinished();
      }
    );

    const unsubComplaints = onSnapshot(
      collection(db, 'complaints'),
      (snap) => {
        setComplaints(snap.docs.map((doc) => ({ id: doc.id, ...doc.data() })));
        checkFinished();
      },
      (err) => {
        console.error("Error loading complaints for analytics:", err);
        checkFinished();
      }
    );

    return () => {
      unsubOrders();
      unsubUsers();
      unsubRequests();
      unsubRatings();
      unsubComplaints();
    };
  }, []);

  // Helper to parse Firestore dates safely
  const parseDocDate = useCallback((item) => {
    const ts = item.createdAt || item.completedAt || item.workerRequestedAt || item.reviewedAt;
    if (!ts) return null;
    try {
      if (ts.toDate) return ts.toDate();
      if (typeof ts === 'number') return new Date(ts);
      if (typeof ts === 'string') return new Date(ts);
    } catch (e) {
      return null;
    }
    return null;
  }, []);

  // Helper to check if a document timestamp falls within selected date filter range
  const isDateInFilterRange = useCallback((docDate) => {
    if (!docDate) return true; // If no date, include in general totals

    const now = new Date();
    const target = new Date(docDate.getTime());

    if (dateFilter === 'today') {
      return (
        target.getDate() === now.getDate() &&
        target.getMonth() === now.getMonth() &&
        target.getFullYear() === now.getFullYear()
      );
    }

    if (dateFilter === '7days') {
      const past7 = new Date();
      past7.setDate(now.getDate() - 7);
      return target >= past7;
    }

    if (dateFilter === '30days') {
      const past30 = new Date();
      past30.setDate(now.getDate() - 30);
      return target >= past30;
    }

    if (dateFilter === 'month') {
      return (
        target.getMonth() === now.getMonth() &&
        target.getFullYear() === now.getFullYear()
      );
    }

    if (dateFilter === 'year') {
      return target.getFullYear() === now.getFullYear();
    }

    if (dateFilter === 'custom' && customStartDate && customEndDate) {
      const start = new Date(customStartDate);
      const end = new Date(customEndDate);
      end.setHours(23, 59, 59, 999);
      return target >= start && target <= end;
    }

    return true;
  }, [dateFilter, customStartDate, customEndDate]);

  // Filtered collections based on date filter
  const filteredOrders = useMemo(() => {
    return orders.filter((o) => isDateInFilterRange(parseDocDate(o)));
  }, [orders, isDateInFilterRange, parseDocDate]);

  const filteredUsers = useMemo(() => {
    return users.filter((u) => isDateInFilterRange(parseDocDate(u)));
  }, [users, isDateInFilterRange, parseDocDate]);

  const filteredComplaints = useMemo(() => {
    return complaints.filter((c) => isDateInFilterRange(parseDocDate(c)));
  }, [complaints, isDateInFilterRange, parseDocDate]);

  // ================= KPI CALCULATIONS =================
  const kpiData = useMemo(() => {
    const totalOrdersCount = filteredOrders.length;

    let completedOrdersCount = 0;
    let pendingOrdersCount = 0;
    let cancelledOrdersCount = 0;

    filteredOrders.forEach((o) => {
      const st = (o.status || 'pending').toLowerCase();
      if (st === 'completed') {
        completedOrdersCount++;
      } else if (st === 'cancelled') {
        cancelledOrdersCount++;
      } else {
        pendingOrdersCount++;
      }
    });

    // Customers & Workers breakdown from users / worker_requests
    const userPool = filteredUsers.length > 0 ? filteredUsers : users;
    const customerUsers = userPool.filter(
      (u) => (u.userType || 'customer').toLowerCase() === 'customer'
    );
    const workerUsers = userPool.filter(
      (u) => (u.userType || '').toLowerCase() === 'worker' || (u.workerStatus || '').length > 0
    );

    const approvedWorkersCount = users.filter(
      (u) => (u.workerStatus || '').toLowerCase() === 'approved'
    ).length || workerRequests.filter((r) => (r.status || '').toLowerCase() === 'approved').length;

    // Open Complaints count
    const openComplaintsCount = complaints.filter((c) => {
      const st = (c.status || 'open').toLowerCase();
      return st === 'pending' || st === 'open';
    }).length;

    // Average Customer Rating from ratings collection
    let avgRatingValue = 'Data unavailable';
    if (ratings.length > 0) {
      const validRatings = ratings
        .map((r) => Number(r.rating))
        .filter((r) => !isNaN(r) && r > 0);
      if (validRatings.length > 0) {
        const sum = validRatings.reduce((acc, curr) => acc + curr, 0);
        avgRatingValue = (sum / validRatings.length).toFixed(1);
      }
    }

    // Revenue Calculation: check if any order has numeric price/amount/fare/earning
    let totalRevenueSum = 0;
    let hasNumericPriceField = false;

    orders.forEach((o) => {
      const amt = Number(o.price || o.amount || o.fare || o.earning || o.cost);
      if (!isNaN(amt) && amt > 0) {
        hasNumericPriceField = true;
        totalRevenueSum += amt;
      }
    });

    const revenueDisplay = hasNumericPriceField
      ? `Rs ${totalRevenueSum.toLocaleString()}`
      : 'Data unavailable';

    return {
      totalOrders: totalOrdersCount,
      completedOrders: completedOrdersCount,
      pendingOrders: pendingOrdersCount,
      cancelledOrders: cancelledOrdersCount,
      totalCustomers: customerUsers.length,
      totalWorkers: workerUsers.length || workerRequests.length,
      approvedWorkers: approvedWorkersCount,
      openComplaints: openComplaintsCount,
      avgRating: avgRatingValue,
      revenue: revenueDisplay,
      hasFinancialData: hasNumericPriceField
    };
  }, [filteredOrders, filteredUsers, users, workerRequests, complaints, ratings, orders]);

  // ================= CHART VISUALIZATIONS DATA =================

  // 1. Orders Trend over time (grouped by Month/Date)
  const ordersTrendData = useMemo(() => {
    const countsMap = {};
    filteredOrders.forEach((o) => {
      const d = parseDocDate(o) || new Date();
      const label = d.toLocaleString('en-US', { month: 'short', day: 'numeric' });
      countsMap[label] = (countsMap[label] || 0) + 1;
    });

    const result = Object.keys(countsMap).map((label) => ({
      date: label,
      orders: countsMap[label]
    }));

    return result.length > 0
      ? result
      : [
          { date: 'Mon', orders: 0 },
          { date: 'Tue', orders: 0 },
          { date: 'Wed', orders: 0 }
        ];
  }, [filteredOrders, parseDocDate]);

  // 2. Order Status Breakdown (PieChart)
  const orderStatusChartData = useMemo(() => {
    return [
      { name: 'Completed', value: kpiData.completedOrders, color: '#10B981' },
      { name: 'Pending / Ongoing', value: kpiData.pendingOrders, color: '#F59E0B' },
      { name: 'Cancelled', value: kpiData.cancelledOrders, color: '#EF4444' }
    ].filter((item) => item.value > 0);
  }, [kpiData]);

  // 3. Orders by Service Category (BarChart)
  const serviceCategoryChartData = useMemo(() => {
    const categoryMap = {};
    filteredOrders.forEach((o) => {
      const cat = o.serviceType || o.category || 'General';
      categoryMap[cat] = (categoryMap[cat] || 0) + 1;
    });

    return Object.keys(categoryMap).map((cat) => ({
      category: cat,
      orders: categoryMap[cat]
    }));
  }, [filteredOrders]);

  // 4. User Registration Growth over time (Customers vs Workers)
  const userGrowthChartData = useMemo(() => {
    const monthMap = {};
    users.forEach((u) => {
      const d = parseDocDate(u);
      if (d) {
        const key = d.toLocaleString('en-US', { month: 'short', year: '2-digit' });
        if (!monthMap[key]) monthMap[key] = { month: key, customers: 0, workers: 0 };
        const type = (u.userType || 'customer').toLowerCase();
        if (type === 'worker') monthMap[key].workers++;
        else monthMap[key].customers++;
      }
    });

    return Object.values(monthMap);
  }, [users, parseDocDate]);

  // 5. Complaint Status Distribution
  const complaintStatusChartData = useMemo(() => {
    const statusCounts = { open: 0, under_review: 0, resolved: 0, rejected: 0 };
    filteredComplaints.forEach((c) => {
      const st = (c.status || 'open').toLowerCase();
      if (st === 'pending' || st === 'open') statusCounts.open++;
      else if (st === 'under_review' || st === 'in_progress') statusCounts.under_review++;
      else if (st === 'resolved' || st === 'closed') statusCounts.resolved++;
      else if (st === 'rejected') statusCounts.rejected++;
    });

    return [
      { name: 'Open', value: statusCounts.open, color: '#F59E0B' },
      { name: 'Under Review', value: statusCounts.under_review, color: '#3B82F6' },
      { name: 'Resolved', value: statusCounts.resolved, color: '#10B981' },
      { name: 'Rejected', value: statusCounts.rejected, color: '#EF4444' }
    ].filter((item) => item.value > 0);
  }, [filteredComplaints]);

  // ================= SUMMARY TABLES DATA =================

  // Top 5 Workers by Completed Jobs and Rating
  const topWorkersTable = useMemo(() => {
    const workerJobCounts = {};
    orders.forEach((o) => {
      if ((o.status || '').toLowerCase() === 'completed' && o.workerId) {
        workerJobCounts[o.workerId] = (workerJobCounts[o.workerId] || 0) + 1;
      }
    });

    const workerList = users.filter(
      (u) => (u.userType || '').toLowerCase() === 'worker' || (u.workerStatus || '').length > 0
    );

    return workerList
      .map((w) => ({
        id: w.id,
        name: w.name || w.fullName || 'Technician',
        category: w.workType || 'General Worker',
        completedJobs: workerJobCounts[w.id] || 0,
        rating: w.avgRating || (w.rating ? Number(w.rating).toFixed(1) : '5.0')
      }))
      .sort((a, b) => b.completedJobs - a.completedJobs || b.rating - a.rating)
      .slice(0, 5);
  }, [orders, users]);

  // Top 5 Services by Number of Bookings
  const topServicesTable = useMemo(() => {
    const serviceMap = {};
    orders.forEach((o) => {
      const cat = o.serviceType || o.category || 'General Service';
      serviceMap[cat] = (serviceMap[cat] || 0) + 1;
    });

    return Object.keys(serviceMap)
      .map((cat) => ({
        name: cat,
        bookings: serviceMap[cat]
      }))
      .sort((a, b) => b.bookings - a.bookings)
      .slice(0, 5);
  }, [orders]);

  // Recent Complaints (Latest 5)
  const recentComplaintsTable = useMemo(() => {
    return [...complaints]
      .sort((a, b) => (parseDocDate(b) || 0) - (parseDocDate(a) || 0))
      .slice(0, 5);
  }, [complaints, parseDocDate]);

  // Recent Completed Orders (Latest 5)
  const recentCompletedOrdersTable = useMemo(() => {
    return orders
      .filter((o) => (o.status || '').toLowerCase() === 'completed')
      .sort((a, b) => (parseDocDate(b) || 0) - (parseDocDate(a) || 0))
      .slice(0, 5);
  }, [orders, parseDocDate]);

  if (loading) {
    return (
      <div className="analytics-page animate-fade" style={{ textAlign: 'center', padding: '60px 20px' }}>
        <RefreshCw className="spin-icon" size={32} style={{ color: '#10B981', marginBottom: '12px' }} />
        <p style={{ color: '#6B7280', fontSize: '15px' }}>Loading real-time Firestore analytics data...</p>
      </div>
    );
  }

  return (
    <div className="analytics-page animate-fade">
      <PageHeader
        title="Reports & Analytics"
        subtitle="Platform performance metrics, service analytics, and real-time operational insights."
      />

      {error && (
        <div style={{ padding: '12px 16px', backgroundColor: '#FEE2E2', color: '#DC2626', borderRadius: '8px', marginBottom: '20px' }}>
          <AlertCircle size={18} style={{ display: 'inline', marginRight: '6px' }} />
          {error}
        </div>
      )}

      {/* DATE RANGE FILTER BAR */}
      <div className="analytics-filter-bar">
        <div className="filter-pills">
          <button
            className={`filter-pill-btn ${dateFilter === 'today' ? 'active' : ''}`}
            onClick={() => setDateFilter('today')}
          >
            Today
          </button>
          <button
            className={`filter-pill-btn ${dateFilter === '7days' ? 'active' : ''}`}
            onClick={() => setDateFilter('7days')}
          >
            Last 7 Days
          </button>
          <button
            className={`filter-pill-btn ${dateFilter === '30days' ? 'active' : ''}`}
            onClick={() => setDateFilter('30days')}
          >
            Last 30 Days
          </button>
          <button
            className={`filter-pill-btn ${dateFilter === 'month' ? 'active' : ''}`}
            onClick={() => setDateFilter('month')}
          >
            This Month
          </button>
          <button
            className={`filter-pill-btn ${dateFilter === 'year' ? 'active' : ''}`}
            onClick={() => setDateFilter('year')}
          >
            This Year
          </button>
          <button
            className={`filter-pill-btn ${dateFilter === 'custom' ? 'active' : ''}`}
            onClick={() => setDateFilter('custom')}
          >
            Custom Range
          </button>
        </div>

        {dateFilter === 'custom' && (
          <div className="custom-date-inputs">
            <Calendar size={16} style={{ color: '#6B7280' }} />
            <input
              type="date"
              value={customStartDate}
              onChange={(e) => setCustomStartDate(e.target.value)}
            />
            <span style={{ fontSize: '12px', color: '#6B7280' }}>to</span>
            <input
              type="date"
              value={customEndDate}
              onChange={(e) => setCustomEndDate(e.target.value)}
            />
          </div>
        )}
      </div>

      {/* KPI CARDS GRID */}
      <div className="kpi-grid">
        <div className="kpi-card">
          <div>
            <div className="kpi-title">Total Orders</div>
            <div className="kpi-value">{kpiData.totalOrders}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-blue">
            <TrendingUp size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Completed Orders</div>
            <div className="kpi-value">{kpiData.completedOrders}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-green">
            <CheckCircle2 size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Pending / Ongoing</div>
            <div className="kpi-value">{kpiData.pendingOrders}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-amber">
            <Clock size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Cancelled Orders</div>
            <div className="kpi-value">{kpiData.cancelledOrders}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-red">
            <XCircle size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Total Customers</div>
            <div className="kpi-value">{kpiData.totalCustomers}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-purple">
            <Users size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Total Workers</div>
            <div className="kpi-value">{kpiData.totalWorkers}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-cyan">
            <Briefcase size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Approved Workers</div>
            <div className="kpi-value">{kpiData.approvedWorkers}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-green">
            <Award size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Open Complaints</div>
            <div className="kpi-value">{kpiData.openComplaints}</div>
          </div>
          <div className="kpi-icon-box kpi-icon-amber">
            <AlertCircle size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Average Rating</div>
            <div className="kpi-value">
              {kpiData.avgRating !== 'Data unavailable' ? `${kpiData.avgRating} ★` : <span className="kpi-unavailable">Data unavailable</span>}
            </div>
          </div>
          <div className="kpi-icon-box kpi-icon-amber">
            <Star size={22} />
          </div>
        </div>

        <div className="kpi-card">
          <div>
            <div className="kpi-title">Total Revenue</div>
            <div className="kpi-value">
              {kpiData.hasFinancialData ? kpiData.revenue : <span className="kpi-unavailable">Data unavailable</span>}
            </div>
          </div>
          <div className="kpi-icon-box kpi-icon-green">
            <DollarSign size={22} />
          </div>
        </div>
      </div>

      {/* ANALYTICS VISUALIZATIONS (RECHARTS) */}
      <div className="charts-grid">
        {/* Orders Volume Trend */}
        <div className="analytics-chart-card chart-card-full">
          <div className="chart-header">
            <h3>Orders Volume Trend</h3>
            <span className="chart-badge">Real-time Firestore</span>
          </div>
          <ResponsiveContainer width="100%" height={260}>
            <AreaChart data={ordersTrendData}>
              <defs>
                <linearGradient id="orderGrad" x1="0" y1="0" x2="0" y2="1">
                  <stop offset="5%" stopColor="#3B82F6" stopOpacity={0.3} />
                  <stop offset="95%" stopColor="#3B82F6" stopOpacity={0} />
                </linearGradient>
              </defs>
              <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
              <XAxis dataKey="date" tick={{ fontSize: 12 }} />
              <YAxis tick={{ fontSize: 12 }} />
              <Tooltip />
              <Area type="monotone" dataKey="orders" stroke="#3B82F6" strokeWidth={3} fill="url(#orderGrad)" />
            </AreaChart>
          </ResponsiveContainer>
        </div>

        {/* Order Status Distribution (Completed vs Cancelled vs Pending) */}
        <div className="analytics-chart-card">
          <div className="chart-header">
            <h3>Order Status Breakdown</h3>
            <span className="chart-badge">Distribution</span>
          </div>
          {orderStatusChartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={240}>
              <PieChart>
                <Pie
                  data={orderStatusChartData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  outerRadius={80}
                  label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                >
                  {orderStatusChartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="unavailable-chart-box">
              <FileText size={32} />
              <p>No order status distribution data for selected range.</p>
            </div>
          )}
        </div>

        {/* Orders by Service Category */}
        <div className="analytics-chart-card">
          <div className="chart-header">
            <h3>Orders by Service Category</h3>
            <span className="chart-badge">Services</span>
          </div>
          {serviceCategoryChartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={240}>
              <BarChart data={serviceCategoryChartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="category" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Bar dataKey="orders" fill="#10B981" radius={[4, 4, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          ) : (
            <div className="unavailable-chart-box">
              <Tag size={32} />
              <p>No category order data available.</p>
            </div>
          )}
        </div>

        {/* Customer & Worker Registration Growth */}
        <div className="analytics-chart-card">
          <div className="chart-header">
            <h3>User Registrations Over Time</h3>
            <span className="chart-badge">Growth</span>
          </div>
          {userGrowthChartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={240}>
              <LineChart data={userGrowthChartData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="month" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Legend />
                <Line type="monotone" dataKey="customers" name="Customers" stroke="#3B82F6" strokeWidth={3} />
                <Line type="monotone" dataKey="workers" name="Workers" stroke="#8B5CF6" strokeWidth={3} />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="unavailable-chart-box">
              <Users size={32} />
              <p>User registration dates unavailable.</p>
            </div>
          )}
        </div>

        {/* Complaint Status Distribution */}
        <div className="analytics-chart-card">
          <div className="chart-header">
            <h3>Complaint Status Distribution</h3>
            <span className="chart-badge">Support</span>
          </div>
          {complaintStatusChartData.length > 0 ? (
            <ResponsiveContainer width="100%" height={240}>
              <PieChart>
                <Pie
                  data={complaintStatusChartData}
                  dataKey="value"
                  nameKey="name"
                  cx="50%"
                  cy="50%"
                  innerRadius={45}
                  outerRadius={75}
                  paddingAngle={5}
                >
                  {complaintStatusChartData.map((entry, index) => (
                    <Cell key={`cell-c-${index}`} fill={entry.color} />
                  ))}
                </Pie>
                <Tooltip />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          ) : (
            <div className="unavailable-chart-box">
              <AlertCircle size={32} />
              <p>No complaint records for selected range.</p>
            </div>
          )}
        </div>

        {/* Revenue Trend / Fallback Card */}
        <div className="analytics-chart-card chart-card-full">
          <div className="chart-header">
            <h3>Revenue / Platform Earnings Trend</h3>
            <span className="chart-badge">Financial</span>
          </div>
          {kpiData.hasFinancialData ? (
            <ResponsiveContainer width="100%" height={240}>
              <LineChart data={ordersTrendData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#e5e7eb" />
                <XAxis dataKey="date" tick={{ fontSize: 12 }} />
                <YAxis tick={{ fontSize: 12 }} />
                <Tooltip />
                <Line type="monotone" dataKey="orders" stroke="#10B981" strokeWidth={3} />
              </LineChart>
            </ResponsiveContainer>
          ) : (
            <div className="unavailable-chart-box">
              <DollarSign size={36} />
              <h4>Revenue Data Unavailable</h4>
              <p>Financial/pricing fields are not stored on current order documents. Revenue analytics unavailable in current schema.</p>
            </div>
          )}
        </div>
      </div>

      {/* SUMMARY TABLES GRID */}
      <div className="tables-grid">
        {/* Top 5 Workers by Completed Jobs & Rating */}
        <div className="table-card">
          <div className="table-header">
            <h3>Top 5 Service Workers</h3>
            <span className="chart-badge">By Performance</span>
          </div>
          {topWorkersTable.length > 0 ? (
            <table className="analytics-table">
              <thead>
                <tr>
                  <th>Worker</th>
                  <th>Category</th>
                  <th>Completed Jobs</th>
                  <th>Rating</th>
                </tr>
              </thead>
              <tbody>
                {topWorkersTable.map((w, idx) => (
                  <tr key={idx}>
                    <td><strong>{w.name}</strong></td>
                    <td>{w.category}</td>
                    <td>{w.completedJobs} jobs</td>
                    <td>
                      <span className="rating-pill">
                        <Star size={12} fill="#d97706" /> {w.rating}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="table-empty">No worker performance metrics recorded.</div>
          )}
        </div>

        {/* Top 5 Services by Number of Bookings */}
        <div className="table-card">
          <div className="table-header">
            <h3>Most-Booked Services</h3>
            <span className="chart-badge">Popularity</span>
          </div>
          {topServicesTable.length > 0 ? (
            <table className="analytics-table">
              <thead>
                <tr>
                  <th>Service Category</th>
                  <th>Total Bookings</th>
                </tr>
              </thead>
              <tbody>
                {topServicesTable.map((s, idx) => (
                  <tr key={idx}>
                    <td><strong>{s.name}</strong></td>
                    <td>{s.bookings} bookings</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="table-empty">No service bookings recorded.</div>
          )}
        </div>

        {/* Recent Complaints */}
        <div className="table-card">
          <div className="table-header">
            <h3>Recent Complaints</h3>
            <span className="chart-badge">Support Logs</span>
          </div>
          {recentComplaintsTable.length > 0 ? (
            <table className="analytics-table">
              <thead>
                <tr>
                  <th>Category</th>
                  <th>Complainant</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {recentComplaintsTable.map((c, idx) => (
                  <tr key={idx}>
                    <td><strong>{c.category || 'General'}</strong></td>
                    <td>{c.againstUserName || c.complaintBy || 'User'}</td>
                    <td>{(c.status || 'open').toUpperCase()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="table-empty">No recent complaints filed.</div>
          )}
        </div>

        {/* Recent Completed Orders */}
        <div className="table-card">
          <div className="table-header">
            <h3>Recent Completed Orders</h3>
            <span className="chart-badge">Completed</span>
          </div>
          {recentCompletedOrdersTable.length > 0 ? (
            <table className="analytics-table">
              <thead>
                <tr>
                  <th>Order ID</th>
                  <th>Customer</th>
                  <th>Service</th>
                </tr>
              </thead>
              <tbody>
                {recentCompletedOrdersTable.map((o, idx) => (
                  <tr key={idx}>
                    <td><strong>#{o.id.slice(0, 8)}</strong></td>
                    <td>{o.customerName || 'Customer'}</td>
                    <td>{o.serviceType || 'Service'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          ) : (
            <div className="table-empty">No completed orders found.</div>
          )}
        </div>
      </div>
    </div>
  );
}