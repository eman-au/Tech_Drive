import React from 'react';
import './Badge.css';

export default function Badge({ label, type = 'default' }) {
  return (
    <span className={`badge badge--${type}`}>{label}</span>
  );
}