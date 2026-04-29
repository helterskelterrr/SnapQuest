import React, { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Crown, Star, Trophy, Zap, Award, Target, Flame, TrendingUp, TrendingDown, Minus } from 'lucide-react';

type Player = { rank: number; user: string; initial: string; bg: string; textColor: string; points: number; tier: string; change?: 'up' | 'down' | 'same'; isMe?: boolean; };

const weeklyData: Player[] = [
  { rank: 1,  user: 'budi_foto',    initial: 'BF', bg: '#D2E0D3', textColor: '#3D6645', points: 1840, tier: 'Pro Shooter',    change: 'up' },
  { rank: 2,  user: 'citra_lens',   initial: 'CL', bg: '#F2C3B9', textColor: '#8C4A36', points: 1620, tier: 'Sharp Eye',      change: 'same' },
  { rank: 3,  user: 'eko_snap',     initial: 'ES', bg: '#D6CBBF', textColor: '#5E4A36', points: 1450, tier: 'Sharp Eye',      change: 'down' },
  { rank: 4,  user: 'fani_click',   initial: 'FC', bg: '#97B3AE', textColor: '#2C5450', points: 1320, tier: 'Rising Shooter', change: 'up' },
  { rank: 5,  user: 'gita_vis',     initial: 'GV', bg: '#F0DDD6', textColor: '#7A4535', points: 1180, tier: 'Rising Shooter', change: 'up' },
  { rank: 6,  user: 'hadi_shot',    initial: 'HS', bg: '#D2E0D3', textColor: '#3D6645', points: 1050, tier: 'Amateur',        change: 'same' },
  { rank: 7,  user: 'indah_pix',    initial: 'IP', bg: '#F2C3B9', textColor: '#8C4A36', points: 980,  tier: 'Amateur',        change: 'down' },
  { rank: 8,  user: 'joko_frame',   initial: 'JF', bg: '#D6CBBF', textColor: '#5E4A36', points: 870,  tier: 'Amateur',        change: 'same' },
  { rank: 9,  user: 'kiki_shots',   initial: 'KS', bg: '#97B3AE', textColor: '#2C5450', points: 760,  tier: 'Newbie',         change: 'up' },
  { rank: 10, user: 'lina_cap',     initial: 'LC', bg: '#F0DDD6', textColor: '#7A4535', points: 650,  tier: 'Newbie',         change: 'down' },
  { rank: 12, user: 'alex_pras',    initial: 'AP', bg: '#97B3AE', textColor: '#2C5450', points: 500,  tier: 'Rising Shooter', change: 'up',  isMe: true },
];

const allTimeData: Player[] = [
  { rank: 1,  user: 'master_snap',  initial: 'MS', bg: '#F0DDD6', textColor: '#7A4535', points: 28400, tier: 'Grandmaster',   change: 'same' },
  { rank: 2,  user: 'budi_foto',    initial: 'BF', bg: '#D2E0D3', textColor: '#3D6645', points: 24100, tier: 'Legend',        change: 'up' },
  { rank: 3,  user: 'pro_lens',     initial: 'PL', bg: '#97B3AE', textColor: '#2C5450', points: 19800, tier: 'Pro Shooter',   change: 'same' },
  { rank: 4,  user: 'citra_lens',   initial: 'CL', bg: '#F2C3B9', textColor: '#8C4A36', points: 17500, tier: 'Pro Shooter',   change: 'up' },
  { rank: 5,  user: 'snap_queen',   initial: 'SQ', bg: '#D6CBBF', textColor: '#5E4A36', points: 15200, tier: 'Sharp Eye',     change: 'down' },
  { rank: 6,  user: 'eko_snap',     initial: 'ES', bg: '#D2E0D3', textColor: '#3D6645', points: 13400, tier: 'Sharp Eye',     change: 'same' },
  { rank: 7,  user: 'fani_click',   initial: 'FC', bg: '#F0DDD6', textColor: '#7A4535', points: 11800, tier: 'Rising Shooter',change: 'up' },
  { rank: 8,  user: 'hadi_shot',    initial: 'HS', bg: '#97B3AE', textColor: '#2C5450', points: 9200,  tier: 'Rising Shooter',change: 'down' },
  { rank: 9,  user: 'gita_vis',     initial: 'GV', bg: '#F2C3B9', textColor: '#8C4A36', points: 7600,  tier: 'Amateur',       change: 'same' },
  { rank: 10, user: 'joko_frame',   initial: 'JF', bg: '#D6CBBF', textColor: '#5E4A36', points: 5800,  tier: 'Amateur',       change: 'down' },
  { rank: 48, user: 'alex_pras',    initial: 'AP', bg: '#97B3AE', textColor: '#2C5450', points: 2840,  tier: 'Rising Shooter',change: 'up',  isMe: true },
];

const TIER_ICONS: Record<string, React.ReactNode> = {
  'Grandmaster': <Crown  size={11} color="#E07B65"  />,
  'Legend':      <Trophy size={11} color="#97B3AE"  />,
  'Pro Shooter': <Award  size={11} color="#4A706B"  />,
  'Sharp Eye':   <Zap    size={11} color="#97B3AE"  />,
  'Rising Shooter': <Star   size={11} color="#E07B65" />,
  'Amateur':     <Target size={11} color="#B8C9C7"  />,
  'Newbie':      <Flame  size={11} color="#F2C3B9"  />,
};

const CROWN_COLORS = { 1: '#E0A87C', 2: '#B8C9C7', 3: '#C5A98A' };
const PODIUM_BG    = {
  1: 'linear-gradient(160deg, #A8C8AA 0%, #7FA885 100%)',
  2: 'linear-gradient(160deg, #C5BAB0 0%, #A8A098 100%)',
  3: 'linear-gradient(160deg, #D6C4BC 0%, #BEA89E 100%)',
};

function ChangeIcon({ change }: { change?: 'up' | 'down' | 'same' }) {
  if (change === 'up')   return <TrendingUp   size={12} color="#4A706B" />;
  if (change === 'down') return <TrendingDown size={12} color="#E07B65" />;
  return <Minus size={12} color="#C4D0CE" />;
}

function PodiumCard({ data, position }: { data: Player; position: 1 | 2 | 3 }) {
  const sizes   = { 1: 62, 2: 50, 3: 46 };
  const heights = { 1: 100, 2: 72, 3: 56 };
  return (
    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: position * 0.1 }}
      className="flex flex-col items-center" style={{ order: position === 1 ? 2 : position === 2 ? 1 : 3 }}>
      <div className="flex flex-col items-center gap-1.5 mb-2">
        <motion.div animate={{ y: [0, -4, 0] }} transition={{ repeat: Infinity, duration: 2.5, ease: 'easeInOut', delay: position * 0.4 }}>
          <Crown size={position === 1 ? 24 : 18} color={CROWN_COLORS[position]} fill={CROWN_COLORS[position]} />
        </motion.div>
        <div style={{ width: `${sizes[position]}px`, height: `${sizes[position]}px`, borderRadius: '50%', background: data.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: position === 1 ? '18px' : '13px', fontWeight: 800, color: data.textColor, border: `3px solid ${CROWN_COLORS[position]}`, boxShadow: `0 0 16px ${CROWN_COLORS[position]}60` }}>
          {data.initial}
        </div>
        <p style={{ color: '#2C3A37', fontSize: '11px', fontWeight: 700, maxWidth: '72px', textAlign: 'center', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{data.user}</p>
        <div style={{ display: 'flex', alignItems: 'center', gap: '3px', padding: '2px 8px', borderRadius: '20px', background: 'rgba(224,168,124,0.15)' }}>
          <Star size={9} color="#E07B65" fill="#E07B65" />
          <span style={{ color: '#E07B65', fontSize: '11px', fontWeight: 700 }}>{data.points.toLocaleString()}</span>
        </div>
      </div>
      <div style={{ width: position === 1 ? '88px' : '74px', height: `${heights[position]}px`, borderRadius: '10px 10px 0 0', background: PODIUM_BG[position], display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <span style={{ color: 'white', fontSize: '22px', fontWeight: 900, textShadow: '0 1px 4px rgba(0,0,0,0.15)' }}>{position}</span>
      </div>
    </motion.div>
  );
}

export function LeaderboardScreen() {
  const [tab, setTab] = useState<'weekly' | 'alltime'>('weekly');
  const data = tab === 'weekly' ? weeklyData : allTimeData;
  const top3 = data.filter(d => d.rank <= 3);
  const rest = data.filter(d => d.rank > 3 && !d.isMe);
  const me = data.find(d => d.isMe);

  return (
    <div style={{ height: '736px', background: '#F0EEEA', display: 'flex', flexDirection: 'column' }}>
      {/* Header */}
      <div style={{ padding: '16px 20px 0', flexShrink: 0 }}>
        <div className="flex items-center gap-2 mb-3">
          <Trophy size={20} color="#E07B65" />
          <h2 style={{ color: '#2C3A37', fontSize: '22px', fontWeight: 800 }}>Leaderboard</h2>
          <div style={{ marginLeft: 'auto', padding: '3px 10px', borderRadius: '20px', background: 'rgba(224,123,101,0.1)', border: '1px solid rgba(224,123,101,0.3)' }}>
            <span style={{ color: '#E07B65', fontSize: '11px', fontWeight: 700 }}>Live</span>
          </div>
        </div>
        <div style={{ background: 'white', borderRadius: '14px', padding: '4px', display: 'flex', marginBottom: '4px', border: '1.5px solid #E8E0D8', boxShadow: '0 2px 8px rgba(44,58,55,0.05)' }}>
          {[{ key: 'weekly', label: 'Minggu Ini' }, { key: 'alltime', label: 'Semua Waktu' }].map(({ key, label }) => (
            <button key={key} onClick={() => setTab(key as 'weekly' | 'alltime')}
              style={{ flex: 1, height: '38px', borderRadius: '10px', border: 'none', background: tab === key ? '#97B3AE' : 'transparent', color: tab === key ? 'white' : '#B8C9C7', fontSize: '13px', fontWeight: 700, cursor: 'pointer', transition: 'all 0.2s', boxShadow: tab === key ? '0 3px 10px rgba(151,179,174,0.35)' : 'none' }}>
              {label}
            </button>
          ))}
        </div>
      </div>

      <div className="flex-1 overflow-y-auto" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
        {/* Podium */}
        <div style={{ padding: '12px 20px 20px', background: 'linear-gradient(to bottom, rgba(210,224,211,0.25), transparent)' }}>
          <div className="flex items-end justify-center gap-3">
            {[2, 1, 3].map(rank => {
              const d = top3.find(t => t.rank === rank);
              if (!d) return null;
              return <PodiumCard key={rank} data={d} position={rank as 1 | 2 | 3} />;
            })}
          </div>
        </div>

        {/* List */}
        <div style={{ padding: '0 20px 8px' }}>
          <AnimatePresence mode="wait">
            <motion.div key={tab} initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.25 }}>
              {rest.map((item, idx) => (
                <motion.div key={item.rank} initial={{ opacity: 0, x: -12 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: idx * 0.04 }}
                  className="flex items-center gap-3 py-3 px-4 mb-2"
                  style={{ borderRadius: '14px', background: 'white', border: '1.5px solid #E8E0D8', boxShadow: '0 1px 6px rgba(44,58,55,0.05)' }}>
                  <div className="flex items-center gap-1" style={{ minWidth: '36px' }}>
                    <span style={{ color: '#B8C9C7', fontSize: '14px', fontWeight: 700 }}>{item.rank}</span>
                    <ChangeIcon change={item.change} />
                  </div>
                  <div style={{ width: '38px', height: '38px', borderRadius: '50%', background: item.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 800, color: item.textColor, flexShrink: 0 }}>
                    {item.initial}
                  </div>
                  <div className="flex-1 min-w-0">
                    <p style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{item.user}</p>
                    <div className="flex items-center gap-1 mt-0.5">
                      {TIER_ICONS[item.tier]}
                      <p style={{ color: '#B8C9C7', fontSize: '11px' }}>{item.tier}</p>
                    </div>
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: '4px', padding: '4px 10px', borderRadius: '20px', background: 'rgba(224,123,101,0.07)' }}>
                    <Star size={11} color="#E07B65" fill="#E07B65" />
                    <span style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 700 }}>{item.points.toLocaleString()}</span>
                  </div>
                </motion.div>
              ))}
            </motion.div>
          </AnimatePresence>
        </div>
      </div>

      {/* My rank sticky */}
      {me && (
        <div style={{ padding: '8px 20px 8px', flexShrink: 0, borderTop: '1px solid #E8E0D8', background: 'white' }}>
          <div className="flex items-center gap-3 py-3 px-4"
            style={{ borderRadius: '14px', background: 'rgba(151,179,174,0.1)', border: '1.5px solid rgba(151,179,174,0.45)' }}>
            <div className="flex items-center gap-1" style={{ minWidth: '36px' }}>
              <span style={{ color: '#4A706B', fontSize: '14px', fontWeight: 800 }}>#{me.rank}</span>
              <ChangeIcon change={me.change} />
            </div>
            <div style={{ width: '38px', height: '38px', borderRadius: '50%', background: me.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 800, color: me.textColor, flexShrink: 0, border: '2px solid #97B3AE' }}>
              {me.initial}
            </div>
            <div className="flex-1">
              <div className="flex items-center gap-1.5">
                <p style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 700 }}>{me.user}</p>
                <span style={{ padding: '1px 7px', borderRadius: '20px', background: '#97B3AE', color: 'white', fontSize: '10px', fontWeight: 700 }}>Kamu</span>
              </div>
              <div className="flex items-center gap-1 mt-0.5">{TIER_ICONS[me.tier]}<p style={{ color: '#9EAEAD', fontSize: '11px' }}>{me.tier}</p></div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '4px', padding: '4px 10px', borderRadius: '20px', background: 'rgba(224,123,101,0.07)' }}>
              <Star size={11} color="#E07B65" fill="#E07B65" />
              <span style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 700 }}>{me.points.toLocaleString()}</span>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
