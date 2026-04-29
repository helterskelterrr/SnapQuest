import { useState } from 'react';
import { useNavigate } from 'react-router';
import { ArrowLeft, Heart, Trophy, Zap, Bell, Camera, Star, CheckCheck, Trash2 } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';

type NotifType = 'vote' | 'challenge' | 'achievement' | 'rank' | 'system';
type Notif = { id: number; type: NotifType; title: string; body: string; time: string; read: boolean; group: string; userInitial?: string; userBg?: string; userTextColor?: string; };

const ALL_NOTIFS: Notif[] = [
  { id: 1,  type: 'vote',        title: 'budi_foto memvote fotomu',    body: 'Foto "Lingkaran ban" mendapat vote baru',           time: '2 mnt lalu',  read: false, group: 'Hari Ini', userInitial: 'BF', userBg: '#F2C3B9', userTextColor: '#8C4A36' },
  { id: 2,  type: 'challenge',   title: 'Tantangan Baru!',             body: 'Challenge hari ini: "Foto berbentuk lingkaran"',    time: '1 jam lalu',  read: false, group: 'Hari Ini' },
  { id: 3,  type: 'achievement', title: 'Pencapaian Baru!',            body: 'Kamu meraih badge "7 Hari Streak". Pertahankan!',   time: '3 jam lalu',  read: false, group: 'Hari Ini' },
  { id: 4,  type: 'vote',        title: 'citra_lens memvote fotomu',   body: 'Foto "Warna merah" mendapat vote baru',             time: '5 jam lalu',  read: true,  group: 'Hari Ini', userInitial: 'CL', userBg: '#97B3AE', userTextColor: '#2C5450' },
  { id: 5,  type: 'rank',        title: 'Ranking kamu naik!',          body: 'Kamu naik dari #15 ke #12 di leaderboard',         time: '8 jam lalu',  read: true,  group: 'Hari Ini' },
  { id: 6,  type: 'vote',        title: 'eko_snap memvote fotomu',     body: 'Foto "Tekstur kayu" mendapat vote baru',           time: 'Kemarin',    read: true,  group: 'Kemarin', userInitial: 'ES', userBg: '#D2E0D3', userTextColor: '#3D6645' },
  { id: 7,  type: 'challenge',   title: 'Tantangan Kemarin Berakhir',  body: 'Pemenang: budi_foto dengan 247 votes!',            time: 'Kemarin',    read: true,  group: 'Kemarin' },
  { id: 8,  type: 'vote',        title: '3 orang memvote fotomu',      body: '"Gradien langit" populer hari ini',                time: '2 hari lalu', read: true,  group: 'Lebih Lama' },
  { id: 9,  type: 'achievement', title: 'Level Up!',                   body: 'Naik dari "Amateur" ke "Rising Shooter"!',         time: '3 hari lalu', read: true,  group: 'Lebih Lama' },
  { id: 10, type: 'system',      title: 'Selamat Datang di SnapQuest!',body: 'Akun berhasil dibuat. Mulai tantangan hari ini!',  time: '7 hari lalu', read: true,  group: 'Lebih Lama' },
];

const TABS = [
  { key: 'all',         label: 'Semua' },
  { key: 'vote',        label: 'Vote' },
  { key: 'challenge',   label: 'Challenge' },
  { key: 'achievement', label: 'Pencapaian' },
] as const;
type TabKey = typeof TABS[number]['key'];

const ICON_CFG: Record<NotifType, { Icon: React.ElementType; bg: string; color: string }> = {
  vote:        { Icon: Heart,   bg: '#F0DDD6', color: '#E07B65' },
  challenge:   { Icon: Camera,  bg: '#D2E0D3', color: '#4A706B' },
  achievement: { Icon: Star,    bg: '#F2C3B9', color: '#8C4A36' },
  rank:        { Icon: Trophy,  bg: '#D2E0D3', color: '#97B3AE' },
  system:      { Icon: Bell,    bg: '#D6CBBF', color: '#627370' },
};

export function NotificationsScreen() {
  const navigate = useNavigate();
  const [notifs, setNotifs] = useState(ALL_NOTIFS);
  const [tab, setTab] = useState<TabKey>('all');

  const unread = notifs.filter(n => !n.read).length;

  const filtered = (tab === 'all' ? notifs : notifs.filter(n => n.type === tab))
    .filter(n => !n._deleted);

  const groups = ['Hari Ini', 'Kemarin', 'Lebih Lama'];
  const byGroup = groups.map(g => ({ group: g, items: filtered.filter(n => n.group === g) })).filter(g => g.items.length > 0);

  const markRead  = (id: number) => setNotifs(p => p.map(n => n.id === id ? { ...n, read: true } : n));
  const markAll   = () => setNotifs(p => p.map(n => ({ ...n, read: true })));
  const deleteOne = (id: number) => setNotifs(p => p.map(n => n.id === id ? { ...n, _deleted: true } as typeof n & { _deleted: boolean } : n));

  return (
    <div style={{ height: '800px', background: '#F0EEEA', display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      <div style={{ height: '4px', background: 'linear-gradient(90deg, #97B3AE, #F2C3B9, #D2E0D3)', flexShrink: 0 }} />

      {/* Header */}
      <div style={{ padding: '14px 20px 12px', flexShrink: 0, background: 'white', borderBottom: '1px solid #F0EEEA' }}>
        <div className="flex items-center gap-3 mb-3">
          <button onClick={() => navigate(-1)}
            style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0 }}>
            <ArrowLeft size={20} color="#627370" />
          </button>
          <div className="flex-1">
            <div className="flex items-center gap-2">
              <h2 style={{ color: '#2C3A37', fontSize: '20px', fontWeight: 800 }}>Notifikasi</h2>
              <AnimatePresence>
                {unread > 0 && (
                  <motion.div initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }}
                    style={{ padding: '2px 8px', borderRadius: '20px', background: '#F2C3B9', color: 'white', fontSize: '11px', fontWeight: 700 }}>
                    {unread}
                  </motion.div>
                )}
              </AnimatePresence>
            </div>
          </div>
          {unread > 0 && (
            <button onClick={markAll}
              style={{ background: 'transparent', border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px', color: '#97B3AE', fontSize: '12px', fontWeight: 600 }}>
              <CheckCheck size={14} />
              Baca semua
            </button>
          )}
        </div>

        {/* Tabs */}
        <div className="flex gap-2 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
          {TABS.map(({ key, label }) => (
            <button key={key} onClick={() => setTab(key)}
              style={{ flexShrink: 0, padding: '6px 14px', borderRadius: '20px', background: tab === key ? '#97B3AE' : '#F0EEEA', border: `1.5px solid ${tab === key ? '#97B3AE' : '#E8E0D8'}`, color: tab === key ? 'white' : '#9EAEAD', fontSize: '12px', fontWeight: 600, cursor: 'pointer', transition: 'all 0.2s', boxShadow: tab === key ? '0 3px 10px rgba(151,179,174,0.3)' : 'none' }}>
              {label}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
        {byGroup.length === 0 ? (
          <div className="flex flex-col items-center justify-center gap-3 py-20">
            <div style={{ width: '64px', height: '64px', borderRadius: '20px', background: '#F0EEEA', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <Bell size={28} color="#D6CBBF" />
            </div>
            <p style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 700 }}>Belum Ada Notifikasi</p>
            <p style={{ color: '#B8C9C7', fontSize: '13px' }}>Notifikasi baru akan muncul di sini</p>
          </div>
        ) : (
          byGroup.map(({ group, items }) => (
            <div key={group}>
              <div style={{ padding: '12px 20px 6px' }}>
                <p style={{ color: '#9EAEAD', fontSize: '11px', fontWeight: 700, letterSpacing: '0.06em', textTransform: 'uppercase' }}>{group}</p>
              </div>
              <div style={{ padding: '0 16px' }}>
                {items.map((notif, idx) => {
                  const { Icon, bg, color } = ICON_CFG[notif.type];
                  return (
                    <motion.div key={notif.id}
                      initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: idx * 0.04 }}
                      layout
                    >
                      <div
                        onClick={() => markRead(notif.id)}
                        className="flex gap-3 p-3 mb-2 relative"
                        style={{ borderRadius: '14px', background: notif.read ? 'white' : 'rgba(151,179,174,0.07)', border: `1.5px solid ${notif.read ? '#E8E0D8' : 'rgba(151,179,174,0.3)'}`, cursor: 'pointer', boxShadow: '0 1px 6px rgba(44,58,55,0.05)', transition: 'all 0.2s' }}>
                        {notif.userInitial ? (
                          <div style={{ width: '44px', height: '44px', borderRadius: '50%', background: notif.userBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 800, color: notif.userTextColor, flexShrink: 0 }}>
                            {notif.userInitial}
                          </div>
                        ) : (
                          <div style={{ width: '44px', height: '44px', borderRadius: '14px', background: bg, display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
                            <Icon size={20} color={color} />
                          </div>
                        )}
                        <div className="flex-1 min-w-0">
                          <p style={{ color: '#2C3A37', fontSize: '13px', fontWeight: notif.read ? 500 : 700, lineHeight: 1.4, marginBottom: '2px' }}>{notif.title}</p>
                          <p style={{ color: '#9EAEAD', fontSize: '12px', lineHeight: 1.4, marginBottom: '4px' }}>{notif.body}</p>
                          <p style={{ color: '#C4D0CE', fontSize: '11px' }}>{notif.time}</p>
                        </div>
                        <div className="flex flex-col items-end gap-2" style={{ flexShrink: 0 }}>
                          {!notif.read && <div style={{ width: '8px', height: '8px', borderRadius: '50%', background: '#97B3AE', marginTop: '2px' }} />}
                          <button onClick={(e) => { e.stopPropagation(); deleteOne(notif.id); }}
                            style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: '4px', opacity: 0.4 }}>
                            <Trash2 size={13} color="#9EAEAD" />
                          </button>
                        </div>
                      </div>
                    </motion.div>
                  );
                })}
              </div>
            </div>
          ))
        )}
        <div style={{ height: '20px' }} />
      </div>
    </div>
  );
}
