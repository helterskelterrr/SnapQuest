import React from 'react';
import { Outlet } from 'react-router';
import { BottomNav } from '../components/BottomNav';

export function MainLayout() {
  return (
    <div
      className="flex flex-col"
      style={{ height: '800px', background: '#F0EEEA' }}
    >
      <div
        className="flex-1 overflow-hidden"
        style={{ scrollbarWidth: 'none', msOverflowStyle: 'none' } as React.CSSProperties}
      >
        <Outlet />
      </div>
      <BottomNav />
    </div>
  );
}