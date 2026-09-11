import React, { useState } from 'react';
import { useSearch } from '../../context/SearchContext';
import PageHeader from '../../components/common/PageHeader';
import Badge from '../../components/common/Badge';
import EmptyState from '../../components/common/EmptyState';
import { mockBookings } from '../../data/mockData';
import { Briefcase, Calendar, DollarSign, Clock, Shield } from 'lucide-react';
import './Bookings.css';

const statusMap = {
  completed: 'success',
  active:    'info',
  pending:   'warning',
  cancelled: 'danger',
};

export default function Bookings() {
  const { search, setSearch } = useSearch();
  const [filter, setFilter] = useState('all');

  const filtered = mockBookings.filter(b => {
    const matchSearch =
      b.customer.toLowerCase().includes(search.toLowerCase()) ||
      b.provider.toLowerCase().includes(search.toLowerCase()) ||
      b.service.toLowerCase().includes(search.toLowerCase()) ||
      b.id.toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === 'all' || b.status === filter;
    return matchSearch && matchFilter;
  });

  return (
    <div className="bookings animate-fade">
      <PageHeader
        title="Active Bookings"
        subtitle="Real-time service tracking, client bookings, operational status toggles, and payout monitoring."
      />

      <div className="bookings__toolbar">
        <div className="bookings__toolbar-left" />
        <div className="bookings__filters">
          {['all','active','completed','cancelled'].map(f => (
            <button
              key={f}
              className={`bookings-filter-btn ${filter === f ? 'bookings-filter-btn--active' : ''}`}
              onClick={() => setFilter(f)}
            >
              {f.charAt(0).toUpperCase() + f.slice(1)}
            </button>
          ))}
        </div>
      </div>

      <div className="bookings-table-card">
        {filtered.length === 0 ? (
          <EmptyState title="No Bookings Found" subtitle="Try adjusting your filter settings or searching a different term." />
        ) : (
          <table className="bookings-data-table">
            <thead>
              <tr>
                <th>Customer Name</th>
                <th>Assigned Provider</th>
                <th>Requested Service</th>
                <th>Scheduled Date & Time</th>
                <th>Total Amount</th>
                <th>Status</th>
              </tr>
            </thead>
            <tbody>
              {filtered.map(b => (
                <tr key={b.id} className="booking-row-premium">
                  <td>
                    <div className="bookings-user-cell">
                      <div className="bookings-user-avatar">
                        {b.customer.charAt(0)}
                      </div>
                      <span className="bookings-user-name">{b.customer}</span>
                    </div>
                  </td>
                  <td>
                    <div className="bookings-user-cell">
                      <div className="bookings-provider-avatar">
                        {b.provider.charAt(0)}
                      </div>
                      <span className="bookings-user-name">{b.provider}</span>
                    </div>
                  </td>
                  <td>
                    <span className="bookings-service-tag">
                      <Briefcase size={11} />
                      {b.service}
                    </span>
                  </td>
                  <td>
                    <div className="bookings-datetime-cell">
                      <span className="datetime-date">
                        <Calendar size={11} />
                        {b.date}
                      </span>
                      <span className="datetime-time">
                        <Clock size={11} />
                        {b.time}
                      </span>
                    </div>
                  </td>
                  <td>
                    <span className="booking-amount-value">
                      Rs. {b.amount.toLocaleString()}
                    </span>
                  </td>
                  <td>
                    <Badge label={b.status} type={statusMap[b.status]} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
}