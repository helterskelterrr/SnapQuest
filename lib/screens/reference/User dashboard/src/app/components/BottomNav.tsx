import { useNavigate, useLocation } from 'react-router';
import { Home, Newspaper, Trophy, User } from 'lucide-react';

const tabs = [
  { icon: Home, label: 'Home', path: '/home' },
  { icon: Newspaper, label: 'Feed', path: '/feed' },
  { icon: Trophy, label: 'Ranking', path: '/leaderboard' },
  { icon: User, label: 'Profil', path: '/profile' },
];

export function BottomNav() {
  const navigate = useNavigate();
  const location = useLocation();

  return (
    <div
      className="flex items-center justify-around flex-shrink-0"
      style={{
        height: '64px',
        background: '#FAFAF8',
        borderTop: '1px solid #E8E0D8',
      }}
    >
      {tabs.map(({ icon: Icon, label, path }) => {
        const isActive = location.pathname === path;
        return (
          <button
            key={path}
            onClick={() => navigate(path)}
            className="flex flex-col items-center justify-center gap-0.5"
            style={{ minWidth: '64px', minHeight: '48px', position: 'relative' }}
          >
            {isActive && (
              <div
                style={{
                  position: 'absolute',
                  top: 0,
                  left: '50%',
                  transform: 'translateX(-50%)',
                  width: '24px',
                  height: '2px',
                  borderRadius: '0 0 2px 2px',
                  background: '#97B3AE',
                }}
              />
            )}
            <Icon
              size={22}
              color={isActive ? '#4A706B' : '#C4D0CE'}
              strokeWidth={isActive ? 2.5 : 1.5}
            />
            <span
              style={{
                fontSize: '10px',
                color: isActive ? '#4A706B' : '#C4D0CE',
                fontWeight: isActive ? 700 : 400,
              }}
            >
              {label}
            </span>
          </button>
        );
      })}
    </div>
  );
}
