import React from 'react';
import { Inbox } from 'lucide-react';
import './EmptyState.css';

export default function EmptyState({ title = 'No data found', subtitle = 'Nothing to display here yet.' }) {
  return (
    <div className="empty-state">
      <Inbox size={40} className="empty-state__icon" />
      <h3 className="empty-state__title">{title}</h3>
      <p className="empty-state__subtitle">{subtitle}</p>
    </div>
  );
}