import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Users,
  Briefcase,
  Clock,
  BookOpen,
  CheckCircle,
  XCircle,
  Award
} from 'lucide-react';

import {
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  ResponsiveContainer
} from 'recharts';

import StatCard from '../../components/common/StatCard';
import PageHeader from '../../components/common/PageHeader';
import Badge from '../../components/common/Badge';
import { db } from '../../config/firebase';
import { collection, onSnapshot } from 'firebase/firestore';

import './Dashboard.css';

const PIE_COLORS = ['#10B981', '#06B6D4', '#6366F1', '#F59E0B', '#EF4444'];

const ACTIVE_STATUSES = new Set(['pending', 'accepted', 'on_my_way', 'arrived', 'Pending', 'Accepted', 'On my way', 'Arrived']);
const COMPLETED_STATUSES = new Set(['completed', 'Completed']);
const CANCELLED_STATUSES = new Set(['cancelled', 'Cancelled']);

export default function Dashboard() {
  const navigate = useNavigate();

  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Stats
  const [stats, setStats] = useState({
    customersCount: 0,
    workersCount: 0,
    approvedWorkersCount: 0,
    pendingRequestsCount: 0,
    activeOrdersCount: 0,
    completedOrdersCount: 0,
    cancelledOrdersCount: 0,
  });

  // Chart data derived from real orders
  const [serviceDistribution, setServiceDistribution] = useState([]);
  const [orderStatusOverview, setOrderStatusOverview] = useState([]);
  const [recentOrdersList, setRecentOrdersList] = useState([]);
  const [recentWorkersList, setRecentWorkersList] = useState([]);

  useEffect(() => {
    let usersLoaded = false;
    let requestsLoaded = false;
    let ordersLoaded = false;

    const checkLoadingDone = () => {
      if (usersLoaded && requestsLoaded && ordersLoaded) {
        setLoading(false);
      }
    };

    // 1. Subscribe to users collection
    const unsubUsers = onSnapshot(
      collection(db, 'users'),
      (snapshot) => {
        let customers = 0;
        let workers = 0;
        let approvedWorkers = 0;

        snapshot.docs.forEach((doc) => {
          const data = doc.data() || {};
          const userType = data.userType || 'customer';
          const workerStatus = data.workerStatus || '';

          if (userType === 'worker') {
            workers++;
            if (workerStatus === 'approved') {
              approvedWorkers++;
            }
          } else {
            customers++;
          }
        });

        setStats((prev) => ({
          ...prev,
          customersCount: customers,
          workersCount: workers,
          approvedWorkersCount: approvedWorkers,
        }));

        usersLoaded = true;
        checkLoadingDone();
      },
      (err) => {
        console.error("Error loading users:", err);
        setError("Failed to stream user data.");
        usersLoaded = true;
        checkLoadingDone();
      }
    );

    // 2. Subscribe to worker_requests collection
    const unsubRequests = onSnapshot(
      collection(db, 'worker_requests'),
      (snapshot) => {
        let pending = 0;
        const recentApproved = [];

        snapshot.docs.forEach((doc) => {
          const data = doc.data() || {};
          const status = data.status || 'pending';

          if (status === 'pending') {
            pending++;
          } else if (status === 'approved') {
            recentApproved.push({
              id: doc.id,
              name: data.name || 'Worker',
              workType: data.workType || 'Service Provider',
              area: data.area || 'N/A',
              status: 'Approved',
            });
          }
        });

        setStats((prev) => ({
          ...prev,
          pendingRequestsCount: pending,
        }));

        setRecentWorkersList(recentApproved.slice(0, 5));
        requestsLoaded = true;
        checkLoadingDone();
      },
      (err) => {
        console.error("Error loading worker requests:", err);
        setError("Failed to stream worker requests.");
        requestsLoaded = true;
        checkLoadingDone();
      }
    );

    // 3. Subscribe to orders collection
    const unsubOrders = onSnapshot(
      collection(db, 'orders'),
      (snapshot) => {
        let active = 0;
        let completed = 0;
        let cancelled = 0;

        const categoryCounts = {};
        const ordersList = [];

        snapshot.docs.forEach((doc) => {
          const data = doc.data() || {};
          const status = data.status || 'pending';
          const serviceType = data.serviceType || 'Other';

          // Group by status
          if (ACTIVE_STATUSES.has(status)) {
            active++;
          } else if (COMPLETED_STATUSES.has(status)) {
            completed++;
          } else if (CANCELLED_STATUSES.has(status)) {
            cancelled++;
          }

          // Category distribution
          categoryCounts[serviceType] = (categoryCounts[serviceType] || 0) + 1;

          ordersList.push({
            id: doc.id,
            customer: data.customerName || data.customerEmail || 'Customer',
            service: serviceType,
            status: status,
            createdAt: data.createdAt ? (data.createdAt.toDate ? data.createdAt.toDate().toLocaleDateString() : '') : '',
          });
        });

        setStats((prev) => ({
          ...prev,
          activeOrdersCount: active,
          completedOrdersCount: completed,
          cancelledOrdersCount: cancelled,
        }));

        // Format pie chart data
        const pieData = Object.keys(categoryCounts).map((key) => ({
          name: key,
          value: categoryCounts[key],
        }));
        setServiceDistribution(pieData);

        // Format bar chart data (Overview of order statuses)
        setOrderStatusOverview([
          { name: 'Active', count: active },
          { name: 'Completed', count: completed },
          { name: 'Cancelled', count: cancelled },
        ]);

        setRecentOrdersList(ordersList.slice(0, 5));
        ordersLoaded = true;
        checkLoadingDone();
      },
      (err) => {
        console.error("Error loading orders:", err);
        setError("Failed to stream order data.");
        ordersLoaded = true;
        checkLoadingDone();
      }
    );

    return () => {
      unsubUsers();
      unsubRequests();
      unsubOrders();
    };
  }, []);

  if (loading) {
    return (
      <div className="dashboard animate-fade" style={{ textAlign: 'center', padding: '60px 20px' }}>
        <p style={{ fontSize: '16px', color: '#6B7280' }}>Loading live dashboard metrics...</p>
      </div>
    );
  }

  return (
    <div className="dashboard animate-fade">
      <PageHeader
        title="Admin Dashboard"
        subtitle="Live metrics and system overview across Tech Drive."
      />

      {error && (
        <div style={{ padding: '12px 16px', backgroundColor: '#FEE2E2', color: '#DC2626', borderRadius: '8px', marginBottom: '20px' }}>
          {error}
        </div>
      )}

      {/* Stats Grid */}
      <div className="dashboard__stats">
        <div onClick={() => navigate('/users')} className="dashboard__stat-click">
          <StatCard
            title="Total Customers"
            value={stats.customersCount.toLocaleString()}
            icon={Users}
            color="blue"
          />
        </div>

        <div onClick={() => navigate('/providers')} className="dashboard__stat-click">
          <StatCard
            title="Total Workers"
            value={stats.workersCount.toLocaleString()}
            icon={Briefcase}
            color="cyan"
          />
        </div>

        <div onClick={() => navigate('/providers')} className="dashboard__stat-click">
          <StatCard
            title="Approved Workers"
            value={stats.approvedWorkersCount.toLocaleString()}
            icon={Award}
            color="green"
          />
        </div>

        <div onClick={() => navigate('/verification')} className="dashboard__stat-click">
          <StatCard
            title="Pending Requests"
            value={stats.pendingRequestsCount.toLocaleString()}
            icon={Clock}
            color="yellow"
          />
        </div>

        <div onClick={() => navigate('/bookings')} className="dashboard__stat-click">
          <StatCard
            title="Active Orders"
            value={stats.activeOrdersCount.toLocaleString()}
            icon={BookOpen}
            color="indigo"
          />
        </div>

        <div onClick={() => navigate('/bookings')} className="dashboard__stat-click">
          <StatCard
            title="Completed Orders"
            value={stats.completedOrdersCount.toLocaleString()}
            icon={CheckCircle}
            color="green"
          />
        </div>

        <div onClick={() => navigate('/bookings')} className="dashboard__stat-click">
          <StatCard
            title="Cancelled Orders"
            value={stats.cancelledOrdersCount.toLocaleString()}
            icon={XCircle}
            color="red"
          />
        </div>
      </div>

      {/* Charts Row */}
      <div className="dashboard__charts">
        {/* Order Status Breakdown */}
        <div className="chart-card">
          <div className="chart-card__header">
            <h3 className="chart-card__title">Orders Overview</h3>
            <span className="chart-card__badge">Live Data</span>
          </div>

          <ResponsiveContainer width="100%" height={240}>
            <BarChart data={orderStatusOverview} barGap={4}>
              <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
              <XAxis dataKey="name" tick={{ fontSize: 12, fill: 'var(--text-secondary)' }} axisLine={false} tickLine={false} />
              <YAxis allowDecimals={false} tick={{ fontSize: 12, fill: 'var(--text-secondary)' }} axisLine={false} tickLine={false} />
              <Tooltip
                contentStyle={{
                  backgroundColor: 'var(--card-bg)',
                  borderColor: 'var(--border)',
                  borderRadius: '12px',
                  boxShadow: 'var(--shadow-lg)',
                  color: 'var(--text-primary)'
                }}
              />
              <Bar dataKey="count" name="Orders Count" fill="var(--primary)" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* Service Distribution */}
        <div className="chart-card">
          <div className="chart-card__header">
            <h3 className="chart-card__title">Service Distribution</h3>
          </div>

          {serviceDistribution.length === 0 ? (
            <div style={{ height: 260, display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#9CA3AF' }}>
              No orders recorded yet.
            </div>
          ) : (
            <ResponsiveContainer width="100%" height={260}>
              <PieChart>
                <Pie
                  data={serviceDistribution}
                  cx="50%"
                  cy="50%"
                  outerRadius={85}
                  innerRadius={40}
                  dataKey="value"
                  nameKey="name"
                  paddingAngle={3}
                >
                  {serviceDistribution.map((_, i) => (
                    <Cell key={i} fill={PIE_COLORS[i % PIE_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip
                  contentStyle={{
                    backgroundColor: 'var(--card-bg)',
                    borderColor: 'var(--border)',
                    borderRadius: '12px',
                    color: 'var(--text-primary)'
                  }}
                />
                <Legend />
              </PieChart>
            </ResponsiveContainer>
          )}
        </div>
      </div>

      {/* Activity Section */}
      <div className="dashboard__activity">
        {/* Recent Orders */}
        <div className="activity-card">
          <div className="chart-card__header">
            <h3 className="chart-card__title">Recent Orders</h3>
            <span className="chart-card__badge chart-card__badge--link" onClick={() => navigate('/bookings')}>
              View all
            </span>
          </div>

          <div className="activity-list">
            {recentOrdersList.length === 0 ? (
              <p style={{ padding: '16px', color: '#9CA3AF', textAlign: 'center' }}>No orders found.</p>
            ) : (
              recentOrdersList.map((order) => (
                <div key={order.id} className="activity-item">
                  <div className="activity-item__info">
                    <p className="activity-item__primary">{order.customer}</p>
                    <p className="activity-item__secondary">{order.service}</p>
                  </div>
                  <Badge
                    label={order.status}
                    type={
                      COMPLETED_STATUSES.has(order.status) ? 'success'
                      : CANCELLED_STATUSES.has(order.status) ? 'danger'
                      : 'info'
                    }
                  />
                </div>
              ))
            )}
          </div>
        </div>

        {/* Recently Approved Workers */}
        <div className="activity-card">
          <div className="chart-card__header">
            <h3 className="chart-card__title">Recently Approved Workers</h3>
            <span className="chart-card__badge chart-card__badge--link" onClick={() => navigate('/verification')}>
              View all
            </span>
          </div>

          <div className="activity-list">
            {recentWorkersList.length === 0 ? (
              <p style={{ padding: '16px', color: '#9CA3AF', textAlign: 'center' }}>No approved workers yet.</p>
            ) : (
              recentWorkersList.map((worker) => (
                <div key={worker.id} className="activity-item">
                  <div className="activity-item__avatar">
                    {worker.name.charAt(0).toUpperCase()}
                  </div>
                  <div className="activity-item__info">
                    <p className="activity-item__primary">{worker.name}</p>
                    <p className="activity-item__secondary">{worker.workType} · {worker.area}</p>
                  </div>
                  <Badge label="Approved" type="success" />
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
