import React from 'react';
import { useNavigate } from 'react-router';
import { Edit2, Settings, LogOut, Star, Camera, Trophy, Heart, Flame, Award, Crown, Calendar, Zap, ChevronRight } from 'lucide-react';
import { motion } from 'motion/react';
import { ConfirmSheet } from '../components/ConfirmSheet';
import { useState } from 'react';
import { Toast } from '../components/Toast';

const IMGS = {
  C: 'https://images.unsplash.com/photo-1753469805532-537f677c27b4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXJjdWxhciUyMHJvdW5kJTIwc2hhcGVzJTIwcGhvdG9ncmFwaHl8ZW58MXx8fHwxNzc3MDMzNzA5fDA&ixlib=rb-4.1.0&q=80&w=1080',
  S: 'https://images.unsplash.com/photo-1556620286-5e892be0cfbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2xvcmZ1bCUyMHN0cmVldCUyMHBob3RvZ3JhcGh5JTIwdXJiYW58ZW58MXx8fHwxNzc3MDMzNzEwfDA&ixlib=rb-4.1.0&q=80&w=1080',
  N: 'https://images.unsplash.com/photo-1730626476382-5f18297a30b9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuYXR1cmUlMjB0ZXh0dXJlJTIwY2xvc2UlMjB1cCUyMG1hY3JvfGVufDF8fHx8MTc3NzAzMzcxMHww&ixlib=rb-4.1.0&q=80&w=1080',
  P: 'https://images.unsplash.com/photo-1554454188-f84071b1695f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwb3J0cmFpdCUyMHBlcnNvbiUyMHNtaWxpbmclMjBwaG90b2dyYXBoeXxlbnwxfHx8fDE3NzcwMzM3MTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
  A: 'https://images.unsplash.com/photo-1544730786-12cad2dccc97?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGxpZ2h0JTIwYm9rZWglMjBkYXJrfGVufDF8fHx8MTc3NzAzMzcxMXww&ixlib=rb-4.1.0&q=80&w=1080',
};

const photos = [
  { id: '1', img: IMGS.C, votes: 42 }, { id: '2', img: IMGS.S, votes: 89 },
  { id: '3', img: IMGS.N, votes: 34 }, { id: '4', img: IMGS.P, votes: 67 },
  { id: '5', img: IMGS.A, votes: 21 }, { id: '6', img: IMGS.C, votes: 55 },
];

const achievements = [
  { Icon: Flame,  label: '7 Hari Streak', color: '#E07B65', bg: '#F0DDD6', earned: true  },
  { Icon: Camera, label: 'First Submit',  color: '#4A706B', bg: '#D2E0D3', earned: true  },
  { Icon: Heart,  label: '100 Votes',     color: '#8C4A36', bg: '#F2C3B9', earned: true  },
  { Icon: Award,  label: 'Top 10',        color: '#97B3AE', bg: '#D2E0D3', earned: false },
  { Icon: Crown,  label: 'Champion',      color: '#C5A98A', bg: '#D6CBBF', earned: false },
];

function StatCard({ icon: Icon, color, fillColor, label, value }: { icon: React.ElementType; color: string; fillColor?: string; label: string; value: string }) {
  return (
    <div className="flex-1 flex flex-col items-center py-4" style={{ background: 'white' }}>
      <Icon size={16} color={color} fill={fillColor ?? 'none'} style={{ marginBottom: '5px' }} />
      <p style={{ color: '#2C3A37', fontSize: '17px', fontWeight: 800, lineHeight: 1.2 }}>{value}</p>
      <p style={{ color: '#B8C9C7', fontSize: '10px', fontWeight: 500, textAlign: 'center', lineHeight: 1.3, marginTop: '2px' }}>{label}</p>
    </div>
  );
}

export function ProfileScreen() {
  const navigate = useNavigate();
  const [showLogout, setShowLogout] = useState(false);
  const [toast, setToast] = useState<{ msg: string; type: 'success' | 'error' | 'info' | 'warning' } | null>(null);

  const showT = (msg: string, type: 'success' | 'error' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 2500);
  };

  return (
    <div className="overflow-y-auto relative" style={{ height: '736px', background: '#F0EEEA', scrollbarWidth: 'none' } as React.CSSProperties}>
      {toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}

      {/* Header gradient hero */}
      <div style={{ background: 'linear-gradient(160deg, #D2E0D3 0%, #F0DDD6 60%, #F0EEEA 100%)', padding: '16px 20px 20px' }}>
        <div className="flex items-center justify-between mb-5">
          <h2 style={{ color: '#2C3A37', fontSize: '20px', fontWeight: 800 }}>Profil Saya</h2>
          <button onClick={() => navigate('/settings')}
            style={{ width: '40px', height: '40px', borderRadius: '12px', background: 'rgba(255,255,255,0.7)', border: '1.5px solid rgba(255,255,255,0.6)', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', backdropFilter: 'blur(8px)' }}>
            <Settings size={17} color="#627370" />
          </button>
        </div>

        <div className="flex items-center gap-4">
          <div className="relative">
            <div style={{ width: '84px', height: '84px', borderRadius: '50%', background: '#97B3AE', display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '26px', fontWeight: 800, color: 'white', border: '3px solid white', boxShadow: '0 8px 28px rgba(151,179,174,0.45)' }}>
              AP
            </div>
            <button onClick={() => navigate('/profile/edit')}
              style={{ position: 'absolute', bottom: 0, right: 0, width: '28px', height: '28px', borderRadius: '50%', background: '#F2C3B9', border: '2px solid white', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
              <Camera size={12} color="white" />
            </button>
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-2 mb-1">
              <h3 style={{ color: '#2C3A37', fontSize: '20px', fontWeight: 800 }}>Alex Prasetyo</h3>
              <button onClick={() => navigate('/profile/edit')} style={{ background: 'transparent', border: 'none', cursor: 'pointer', padding: '4px' }}>
                <Edit2 size={14} color="#9EAEAD" />
              </button>
            </div>
            <p style={{ color: '#9EAEAD', fontSize: '13px', marginBottom: '8px' }}>@alex_pras</p>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: '5px', padding: '4px 10px', borderRadius: '20px', background: 'rgba(151,179,174,0.2)', border: '1px solid rgba(151,179,174,0.4)', color: '#4A706B', fontSize: '11px', fontWeight: 700 }}>
              <Zap size={11} color="#4A706B" fill="#4A706B" />Rising Shooter
            </div>
          </div>
        </div>

        <div className="flex items-center gap-4 mt-3">
          <div className="flex items-center gap-1.5">
            <Calendar size={12} color="#9EAEAD" />
            <p style={{ color: '#9EAEAD', fontSize: '12px' }}>Bergabung April 2024</p>
          </div>
          <div className="flex items-center gap-1.5">
            <Flame size={12} color="#E07B65" />
            <p style={{ color: '#9EAEAD', fontSize: '12px' }}>47 hari streak</p>
          </div>
        </div>
      </div>

      {/* Stats strip */}
      <div className="flex px-5 mb-4" style={{ gap: '1px', borderRadius: '16px', overflow: 'hidden', border: '1.5px solid #E8E0D8', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
        <StatCard icon={Star}   color="#E07B65" fillColor="#E07B65" label="Total Poin"     value="2,840" />
        <div style={{ width: '1px', background: '#F0EEEA', flexShrink: 0 }} />
        <StatCard icon={Camera} color="#97B3AE"                      label="Total Submit"  value="47"    />
        <div style={{ width: '1px', background: '#F0EEEA', flexShrink: 0 }} />
        <StatCard icon={Heart}  color="#F2C3B9" fillColor="#F2C3B9"  label="Vote Diterima" value="614"   />
        <div style={{ width: '1px', background: '#F0EEEA', flexShrink: 0 }} />
        <StatCard icon={Trophy} color="#97B3AE"                      label="Kemenangan"    value="3"     />
      </div>

      {/* XP Progress */}
      <div className="px-5 mb-4">
        <div style={{ padding: '14px 16px', borderRadius: '16px', background: 'white', border: '1.5px solid #E8E0D8', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
          <div className="flex items-center justify-between mb-2">
            <div className="flex items-center gap-1.5">
              <Zap size={13} color="#97B3AE" fill="#97B3AE" />
              <p style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 700 }}>Rising Shooter</p>
              <span style={{ color: '#C4D0CE', fontSize: '11px' }}>→ Sharp Eye</span>
            </div>
            <span style={{ padding: '3px 9px', borderRadius: '20px', background: 'rgba(151,179,174,0.12)', color: '#4A706B', fontSize: '12px', fontWeight: 700 }}>340/500 XP</span>
          </div>
          <div style={{ height: '8px', borderRadius: '4px', background: '#F0EEEA', overflow: 'hidden' }}>
            <motion.div initial={{ width: 0 }} animate={{ width: '68%' }} transition={{ duration: 1.2, delay: 0.3, ease: 'easeOut' }}
              style={{ height: '100%', borderRadius: '4px', background: 'linear-gradient(90deg, #97B3AE 0%, #D2E0D3 100%)' }} />
          </div>
          <p style={{ color: '#C4D0CE', fontSize: '10px', marginTop: '4px' }}>160 XP lagi untuk naik level</p>
        </div>
      </div>

      {/* Achievements */}
      <div className="px-5 mb-4">
        <div className="flex items-center gap-2 mb-3">
          <div style={{ width: '3px', height: '16px', borderRadius: '2px', background: 'linear-gradient(to bottom, #97B3AE, #D2E0D3)', flexShrink: 0 }} />
          <h3 style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 700, flex: 1 }}>Pencapaian</h3>
          <span style={{ color: '#B8C9C7', fontSize: '12px' }}>3/5 terbuka</span>
        </div>
        <div className="flex gap-3 overflow-x-auto pb-1" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
          {achievements.map(({ Icon, label, color, bg, earned }) => (
            <motion.div key={label} whileTap={earned ? { scale: 0.95 } : {}}
              className="flex flex-col items-center gap-1.5 flex-shrink-0"
              style={{ width: '68px', padding: '12px 8px', borderRadius: '14px', background: earned ? bg : '#FAFAF8', border: `1.5px solid ${earned ? 'rgba(0,0,0,0.06)' : '#E8E0D8'}`, opacity: earned ? 1 : 0.5, cursor: earned ? 'pointer' : 'default' }}>
              <div style={{ width: '38px', height: '38px', borderRadius: '11px', background: earned ? 'rgba(255,255,255,0.6)' : '#F0EEEA', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                <Icon size={19} color={earned ? color : '#C4D0CE'} />
              </div>
              <p style={{ color: earned ? '#2C3A37' : '#B8C9C7', fontSize: '9px', fontWeight: 600, textAlign: 'center', lineHeight: 1.3 }}>{label}</p>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Photo Grid */}
      <div className="px-5 mb-4">
        <div className="flex items-center gap-2 mb-3">
          <div style={{ width: '3px', height: '16px', borderRadius: '2px', background: 'linear-gradient(to bottom, #97B3AE, #D2E0D3)', flexShrink: 0 }} />
          <h3 style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 700, flex: 1 }}>Riwayat Submission</h3>
          <button onClick={() => navigate('/profile/submissions')}
            style={{ background: 'transparent', border: 'none', color: '#97B3AE', fontSize: '12px', fontWeight: 600, cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '2px', padding: '4px' }}>
            Lihat semua <ChevronRight size={13} />
          </button>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: '3px', borderRadius: '14px', overflow: 'hidden', border: '1.5px solid #E8E0D8' }}>
          {photos.map((photo, idx) => (
            <motion.div key={photo.id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: idx * 0.05 }}
              whileTap={{ opacity: 0.8 }} onClick={() => navigate(`/post/${photo.id}`)}
              style={{ position: 'relative', aspectRatio: '1', cursor: 'pointer' }}>
              <img src={photo.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '4px 6px', background: 'linear-gradient(to top, rgba(44,58,55,0.5), transparent)', display: 'flex', alignItems: 'center', gap: '3px' }}>
                <Star size={9} color="#F0DDD6" fill="#F0DDD6" />
                <span style={{ color: 'white', fontSize: '10px', fontWeight: 600 }}>{photo.votes}</span>
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* Logout */}
      <div className="px-5 pb-8">
        <motion.button whileTap={{ scale: 0.98 }} onClick={() => setShowLogout(true)}
          className="w-full flex items-center justify-center gap-2"
          style={{ height: '50px', borderRadius: '14px', background: 'transparent', border: '1.5px solid rgba(224,123,101,0.3)', color: '#E07B65', fontSize: '14px', fontWeight: 600, cursor: 'pointer' }}>
          <LogOut size={16} />
          Keluar dari Akun
        </motion.button>
      </div>

      <ConfirmSheet
        open={showLogout}
        title="Keluar dari Akun?"
        body="Kamu perlu login kembali untuk mengakses SnapQuest."
        confirmLabel="Ya, Keluar"
        danger
        onConfirm={() => { setShowLogout(false); navigate('/'); }}
        onCancel={() => setShowLogout(false)}
      />
    </div>
  );
}
