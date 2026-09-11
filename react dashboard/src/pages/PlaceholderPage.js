import React from 'react';

export default function PlaceholderPage({ title }) {
  return (
    <div style={{ padding: '40px', textAlign: 'center' }}>
      <h1 style={{ fontSize: '24px', color: 'var(--text-primary)' }}>{title}</h1>
      <p style={{ color: 'var(--text-secondary)', marginTop: '8px' }}>
        This page is under construction.
      </p>
    </div>
  );
}