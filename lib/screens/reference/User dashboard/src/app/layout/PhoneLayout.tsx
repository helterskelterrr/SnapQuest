import { Outlet } from 'react-router';

export function PhoneLayout() {
  return (
    <div
      className="min-h-screen flex items-center justify-center overflow-y-auto py-8"
      style={{
        background: 'linear-gradient(145deg, #E2EDE9 0%, #EDE8E3 50%, #F0EEEA 100%)',
        fontFamily: "'Plus Jakarta Sans', sans-serif",
      }}
    >
      {/* Ambient blobs */}
      <div
        className="fixed top-1/4 left-1/4 rounded-full pointer-events-none"
        style={{ width: '320px', height: '320px', background: 'rgba(151,179,174,0.18)', filter: 'blur(80px)' }}
      />
      <div
        className="fixed bottom-1/4 right-1/4 rounded-full pointer-events-none"
        style={{ width: '240px', height: '240px', background: 'rgba(242,195,185,0.18)', filter: 'blur(70px)' }}
      />

      {/* Phone Frame */}
      <div
        className="relative flex-shrink-0"
        style={{
          width: '390px',
          height: '844px',
          background: '#F0EEEA',
          borderRadius: '44px',
          overflow: 'hidden',
          border: '1.5px solid #C8BEB5',
          boxShadow:
            '0 0 0 8px #DDD8D2, 0 0 0 10px #CAC4BE, 0 48px 120px rgba(60,80,75,0.22), 0 0 40px rgba(151,179,174,0.15)',
        }}
      >
        {/* Status Bar */}
        <div
          className="relative flex items-end justify-between px-8 pb-2 flex-shrink-0"
          style={{ height: '44px', background: '#F0EEEA', zIndex: 10 }}
        >
          <span style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 600 }}>9:41</span>
          {/* Dynamic Island */}
          <div
            className="absolute top-3 left-1/2 -translate-x-1/2 rounded-full"
            style={{ width: '126px', height: '37px', background: '#1C2A27' }}
          />
          <div className="flex items-center gap-1.5">
            <svg width="17" height="11" viewBox="0 0 17 11" fill="none">
              <rect x="0" y="4" width="3" height="7" rx="0.5" fill="#2C3A37" opacity="0.3" />
              <rect x="4.5" y="2.5" width="3" height="8.5" rx="0.5" fill="#2C3A37" opacity="0.5" />
              <rect x="9" y="1" width="3" height="10" rx="0.5" fill="#2C3A37" opacity="0.75" />
              <rect x="13.5" y="0" width="3" height="11" rx="0.5" fill="#2C3A37" />
            </svg>
            <svg width="16" height="11" viewBox="0 0 16 11" fill="none">
              <circle cx="8" cy="10" r="1.5" fill="#2C3A37" />
              <path d="M4.5 6.5C5.7 5.3 7.3 4.5 9 4.5" stroke="#2C3A37" strokeWidth="1.5" strokeLinecap="round" opacity="0.6" />
              <path d="M11.5 6.5C10.3 5.3 8.7 4.5 7 4.5" stroke="#2C3A37" strokeWidth="1.5" strokeLinecap="round" opacity="0.6" />
              <path d="M2 4C3.9 2.1 6.3 1 9 1" stroke="#2C3A37" strokeWidth="1.5" strokeLinecap="round" opacity="0.3" />
              <path d="M14 4C12.1 2.1 9.7 1 7 1" stroke="#2C3A37" strokeWidth="1.5" strokeLinecap="round" opacity="0.3" />
            </svg>
            <div className="flex items-center">
              <div
                style={{ width: '25px', height: '13px', border: '1px solid rgba(44,58,55,0.35)', borderRadius: '3px', padding: '2px', display: 'flex' }}
              >
                <div style={{ height: '100%', width: '75%', background: '#97B3AE', borderRadius: '1px' }} />
              </div>
              <div style={{ width: '2px', height: '5px', background: 'rgba(44,58,55,0.3)', borderRadius: '0 1px 1px 0', marginLeft: '1px' }} />
            </div>
          </div>
        </div>

        {/* Screen Content */}
        <div style={{ height: '800px', overflow: 'hidden', fontFamily: "'Plus Jakarta Sans', sans-serif" }}>
          <Outlet />
        </div>
      </div>

      <p
        className="fixed bottom-4 left-1/2 -translate-x-1/2 text-center text-xs"
        style={{ color: 'rgba(100,130,125,0.35)' }}
      >
        SnapQuest — Daily Photo Challenge
      </p>
    </div>
  );
}
