import React, { useState } from 'react';
import { useSearch } from '../../context/SearchContext';
import {
  ShieldOff,
  RefreshCw,
  Wrench,
  Zap,
} from 'lucide-react';
import PageHeader from '../../components/common/PageHeader';

import './Blocked.css';

const blockedAccounts = [
  {
    id: 1,
    name: 'Ali Raza',
    type: 'provider',
    category: 'Electrician',
    reason: 'Fake reviews and abusive behavior',
    date: '12 May 2026',
    status: 'Blocked',
  },
  {
    id: 2,
    name: 'Ahmed Khan',
    type: 'provider',
    category: 'Plumber',
    reason: 'Multiple customer complaints',
    date: '10 May 2026',
    status: 'Blocked',
  },
  {
    id: 3,
    name: 'Sara Noor',
    type: 'customer',
    category: '-',
    reason: 'Spam bookings',
    date: '09 May 2026',
    status: 'Blocked',
  },
  {
    id: 4,
    name: 'Usman Tariq',
    type: 'provider',
    category: 'Electrician',
    reason: 'Fraud activity detected',
    date: '07 May 2026',
    status: 'Blocked',
  },
];

export default function Blocked() {
  const { search } = useSearch();
  const [accountType, setAccountType] = useState('all');
  const [providerCategory, setProviderCategory] =
    useState('all');

  const providerIcons = {
    Plumber: <Wrench size={14} />,
    Electrician: <Zap size={14} />,
  };

  const filteredAccounts = blockedAccounts.filter((item) => {
    const matchesSearch = item.name
      .toLowerCase()
      .includes(search.toLowerCase());

    const matchesType =
      accountType === 'all' ||
      item.type === accountType;

    const matchesCategory =
      providerCategory === 'all' ||
      item.category === providerCategory;

    return matchesSearch && matchesType && matchesCategory;
  });

  return (
    <div className="blocked-page animate-fade">
      <PageHeader
        title="Blocked Accounts"
        subtitle="Manage blocked customers and service providers."
      />

      {/* FILTER SECTION */}

      <div className="filter-section">
        <div className="filter-pill-row">
          {['all', 'customer', 'provider'].map((option) => (
            <button
              key={option}
              type="button"
              className={`filter-pill ${accountType === option ? 'filter-pill--active' : ''}`}
              onClick={() => setAccountType(option)}
            >
              {option === 'all' ? 'All Accounts' : option === 'customer' ? 'Customers' : 'Service Providers'}
            </button>
          ))}
        </div>

        {accountType === 'provider' && (
          <div className="filter-pill-row filter-pill-row--nested">
            {['all', 'Plumber', 'Electrician'].map((option) => (
              <button
                key={option}
                type="button"
                className={`filter-pill ${providerCategory === option ? 'filter-pill--active' : ''}`}
                onClick={() => setProviderCategory(option)}
              >
                {option === 'all' ? 'All Providers' : option}
              </button>
            ))}
          </div>
        )}
      </div>

      {/* TABLE */}

      <div className="table-wrapper">
        <table className="blocked-table">
          <thead>
            <tr>
              <th>Account Name</th>
              <th>Type</th>
              <th>Category</th>
              <th>Reason</th>
              <th>Blocked Date</th>
              <th>Status</th>
              <th>Manage</th>
            </tr>
          </thead>

          <tbody>
            {filteredAccounts.map((item) => (
              <tr key={item.id}>
                <td>
                  <div className="user-info">
                    <span>{item.name}</span>
                  </div>
                </td>

                <td>
                  <span
                    className={`badge ${
                      item.type === 'provider'
                        ? 'provider'
                        : 'customer'
                    }`}
                  >
                    {item.type}
                  </span>
                </td>

                <td>
                  {item.category !== '-' ? (
                    <span className="category-badge">
                      {
                        providerIcons[
                          item.category
                        ]
                      }

                      {item.category}
                    </span>
                  ) : (
                    '-'
                  )}
                </td>

                <td className="reason">
                  {item.reason}
                </td>

                <td>{item.date}</td>

                <td>
                  <span className="status">
                    {item.status}
                  </span>
                </td>

                <td>
                  <div className="manage-section">
                    <button className="unblock-btn">
                      <RefreshCw size={15} />
                      Unblock Account
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {filteredAccounts.length === 0 && (
          <div className="empty-state">
            <ShieldOff size={50} />

            <h3>
              No Blocked Accounts Found
            </h3>

            <p>
              Try changing filters or search
              keyword.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}