import React from 'react';
import PageHeader from '../../components/common/PageHeader';
import ComplaintsHistory from '../../components/Complaints/ComplaintsHistory';
import './Complaints.css';

export default function Complaints() {
  return (
    <div className="cr-page animate-fade">
      <PageHeader
        title="Complaints Management"
        subtitle="Track customer and worker disputes, review issue details, and resolve complaints."
      />
      <div className="cr-bottom-section">
        <ComplaintsHistory />
      </div>
    </div>
  );
}