import React from 'react';
import './StatCard.css';

export default function StatCard({ title, value, icon: Icon, color, change, changeLabel }) {
  return (
    <div className={`stat-card stat-card--${color}`}>
      <div className="stat-card__header">
        <div className={`stat-card__icon stat-card__icon--${color}`}>
          <Icon size={20} />
        </div>
        {change !== undefined && (
          <span className={`stat-card__change ${change >= 0 ? 'up' : 'down'}`}>
            {change >= 0 ? '+' : ''}{change}%
          </span>
        )}
      </div>
      <div className="stat-card__value">{value}</div>
      <div className="stat-card__title">{title}</div>
      {changeLabel && (
        <div className="stat-card__label">{changeLabel}</div>
      )}
    </div>
  );
}