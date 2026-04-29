import React, { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { Flag, Heart, Camera, RefreshCw, ChevronDown } from 'lucide-react';
import { useNavigate } from 'react-router';
import { Toast } from '../components/Toast';

const CIRCULAR_IMG = 'https://images.unsplash.com/photo-1753469805532-537f677c27b4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXJjdWxhciUyMHJvdW5kJTIwc2hhcGVzJTIwcGhvdG9ncmFwaHl8ZW58MXx8fHwxNzc3MDMzNzA5fDA&ixlib=rb-4.1.0&q=80&w=1080';
const STREET_IMG  = 'https://images.unsplash.com/photo-1556620286-5e892be0cfbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2xvcmZ1bCUyMHN0cmVldCUyMHBob3RvZ3JhcGh5JTIwdXJiYW58ZW58MXx8fHwxNzc3MDMzNzEwfDA&ixlib=rb-4.1.0&q=80&w=1080';
const NATURE_IMG  = 'https://images.unsplash.com/photo-1730626476382-5f18297a30b9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuYXR1cmUlMjB0ZXh0dXJlJTIwY2xvc2UlMjB1cCUyMG1hY3JvfGVufDF8fHx8MTc3NzAzMzcxMHww&ixlib=rb-4.1.0&q=80&w=1080';

const INITIAL_POSTS = [
  { id: 1, user: 'citra_lens',   initial: 'CL', avatarBg: '#97B3AE', avatarText: '#4A706B', time: '2 mnt lalu',  image: CIRCULAR_IMG, caption: 'Nemuin ban sepeda tua di pojok gang',     votes: 42,  voted: false, reported: false, reportCount: 0 },
  { id: 2, user: 'budi_foto',    initial: 'BF', avatarBg: '#F2C3B9', avatarText: '#8C4A36', time: '15 mnt lalu', image: STREET_IMG,   caption: 'Roda gerobak pedagang keliling! Penuh warna', votes: 89,  voted: true,  reported: false, reportCount: 0 },
  { id: 3, user: 'dian_capture', initial: 'DC', avatarBg: '#D2E0D3', avatarText: '#3D6645', time: '32 mnt lalu', image: NATURE_IMG,   caption: 'Lingkaran tahun pohon dari hutan pinus',   votes: 156, voted: false, reported: false, reportCount: 0 },
];

function SkeletonCard() {
  return (
    <div style={{ borderRadius: '16px', background: 'white', border: '1.5px solid #E8E0D8', overflow: 'hidden', marginBottom: '14px', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
      <div className="flex items-center gap-3 px-4 py-3">
        <div style={{ width: '38px', height: '38px', borderRadius: '50%', background: 'linear-gradient(90deg, #F0EEEA 0%, #E2EDE9 50%, #F0EEEA 100%)', backgroundSize: '200% 100%', animation: 'shimmer 1.4s infinite', flexShrink: 0 }} />
        <div className="flex-1 flex flex-col gap-2">
          <div style={{ width: '100px', height: '11px', borderRadius: '6px', background: 'linear-gradient(90deg, #F0EEEA 0%, #E2EDE9 50%, #F0EEEA 100%)', backgroundSize: '200% 100%', animation: 'shimmer 1.4s infinite' }} />
          <div style={{ width: '65px', height: '9px', borderRadius: '6px', background: 'linear-gradient(90deg, #F0EEEA 0%, #E2EDE9 50%, #F0EEEA 100%)', backgroundSize: '200% 100%', animation: 'shimmer 1.4s infinite' }} />
        </div>
      </div>
      <div style={{ aspectRatio: '4/3', background: 'linear-gradient(90deg, #F0EEEA 0%, #E2EDE9 50%, #F0EEEA 100%)', backgroundSize: '200% 100%', animation: 'shimmer 1.4s infinite' }} />
      <div style={{ padding: '12px 16px 14px', display: 'flex', flexDirection: 'column', gap: '6px' }}>
        <div style={{ width: '80%', height: '10px', borderRadius: '5px', background: 'linear-gradient(90deg, #F0EEEA 0%, #E2EDE9 50%, #F0EEEA 100%)', backgroundSize: '200% 100%', animation: 'shimmer 1.4s infinite' }} />
        <div style={{ width: '55%', height: '10px', borderRadius: '5px', background: 'linear-gradient(90deg, #F0EEEA 0%, #E2EDE9 50%, #F0EEEA 100%)', backgroundSize: '200% 100%', animation: 'shimmer 1.4s infinite' }} />
      </div>
    </div>
  );
}

function ReportSheet({ onClose, onConfirm }: { onClose: () => void; onConfirm: (r: string) => void }) {
  const [selected, setSelected] = useState('');
  const reasons = ['Konten tidak pantas', 'Spam atau iklan', 'Tidak sesuai tantangan', 'Foto bukan milik sendiri', 'Lainnya'];
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
      style={{ position: 'absolute', inset: 0, background: 'rgba(44,58,55,0.45)', zIndex: 100, display: 'flex', alignItems: 'flex-end' }} onClick={onClose}>
      <motion.div initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '100%' }} transition={{ type: 'spring', stiffness: 300, damping: 30 }}
        onClick={(e) => e.stopPropagation()}
        style={{ width: '100%', borderRadius: '24px 24px 0 0', background: 'white', padding: '20px 20px 32px', border: '1px solid #E8E0D8' }}>
        <div style={{ width: '36px', height: '4px', borderRadius: '2px', background: '#D6CBBF', margin: '0 auto 20px' }} />
        <h3 style={{ color: '#2C3A37', fontSize: '17px', fontWeight: 800, marginBottom: '4px' }}>Laporkan Konten</h3>
        <p style={{ color: '#9EAEAD', fontSize: '13px', marginBottom: '16px' }}>Pilih alasan pelaporan:</p>
        <div className="flex flex-col gap-2 mb-5">
          {reasons.map((r) => (
            <button key={r} onClick={() => setSelected(r)}
              style={{ padding: '13px 16px', borderRadius: '12px', background: selected === r ? 'rgba(151,179,174,0.1)' : '#FAFAF8', border: `1.5px solid ${selected === r ? '#97B3AE' : '#E8E0D8'}`, color: selected === r ? '#2C3A37' : '#627370', fontSize: '14px', fontWeight: selected === r ? 600 : 400, textAlign: 'left', cursor: 'pointer', transition: 'all 0.15s' }}>
              {r}
            </button>
          ))}
        </div>
        <div className="flex gap-3">
          <button onClick={onClose} style={{ flex: 1, height: '50px', borderRadius: '14px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', color: '#9EAEAD', fontSize: '14px', fontWeight: 600, cursor: 'pointer' }}>Batal</button>
          <button onClick={() => selected && onConfirm(selected)} disabled={!selected}
            style={{ flex: 1, height: '50px', borderRadius: '14px', background: selected ? '#E07B65' : '#F0EEEA', border: 'none', color: selected ? 'white' : '#C4D0CE', fontSize: '14px', fontWeight: 700, cursor: selected ? 'pointer' : 'not-allowed', transition: 'all 0.2s', boxShadow: selected ? '0 4px 16px rgba(224,123,101,0.35)' : 'none' }}>
            Laporkan
          </button>
        </div>
      </motion.div>
    </motion.div>
  );
}

export function FeedScreen() {
  const navigate = useNavigate();
  const [posts, setPosts]         = useState(INITIAL_POSTS);
  const [tab, setTab]             = useState<'terbaru' | 'terpopuler'>('terbaru');
  const [votesLeft, setVotesLeft] = useState(3);
  const [reportId, setReportId]   = useState<number | null>(null);
  const [loading, setLoading]     = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [toast, setToast]         = useState<{ msg: string; type: 'success' | 'error' | 'info' | 'warning' } | null>(null);

  const showT = useCallback((msg: string, type: 'success' | 'error' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 2800);
  }, []);

  useEffect(() => {
    const t = setTimeout(() => setLoading(false), 1400);
    return () => clearTimeout(t);
  }, []);

  const handleVote = (id: number) => {
    setPosts((prev) => prev.map((p) => {
      if (p.id !== id) return p;
      if (p.voted) { setVotesLeft(v => v + 1); return { ...p, voted: false, votes: p.votes - 1 }; }
      if (votesLeft <= 0) { showT('Jatah vote harian kamu sudah habis!', 'warning'); return p; }
      setVotesLeft(v => v - 1);
      if (votesLeft === 1) setTimeout(() => showT('Vote terakhir kamu hari ini sudah digunakan!', 'info'), 300);
      return { ...p, voted: true, votes: p.votes + 1 };
    }));
  };

  const handleReport = (reason: string) => {
    if (reportId === null) return;
    setPosts(prev => prev.map(p => p.id === reportId ? { ...p, reported: true } : p));
    setReportId(null);
    showT('Laporan terkirim. Terima kasih!', 'success');
  };

  const handleRefresh = () => {
    setRefreshing(true);
    setTimeout(() => { setRefreshing(false); showT('Feed diperbarui', 'success'); }, 1200);
  };

  const sortedPosts = tab === 'terpopuler' ? [...posts].sort((a, b) => b.votes - a.votes) : posts;

  return (
    <div style={{ height: '736px', background: '#F0EEEA', display: 'flex', flexDirection: 'column', position: 'relative' }}>
      <AnimatePresence>{toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}</AnimatePresence>

      {/* Header */}
      <div style={{ padding: '16px 20px 0', flexShrink: 0 }}>
        <div className="flex items-center justify-between mb-3">
          <h2 style={{ color: '#2C3A37', fontSize: '22px', fontWeight: 800 }}>Feed Hari Ini</h2>
          <div className="flex items-center gap-2">
            <motion.button whileTap={{ scale: 0.9, rotate: 180 }} onClick={handleRefresh}
              style={{ width: '36px', height: '36px', borderRadius: '10px', background: 'white', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
              <RefreshCw size={15} color={refreshing ? '#97B3AE' : '#C4D0CE'} style={{ transition: 'color 0.2s' }} />
            </motion.button>
            <motion.div
              animate={{ scale: votesLeft === 0 ? [1, 1.05, 1] : 1 }}
              transition={{ repeat: votesLeft === 0 ? Infinity : 0, duration: 2 }}
              style={{ padding: '5px 11px', borderRadius: '20px', background: votesLeft > 0 ? 'rgba(151,179,174,0.12)' : 'rgba(242,195,185,0.25)', border: `1px solid ${votesLeft > 0 ? 'rgba(151,179,174,0.4)' : 'rgba(242,195,185,0.6)'}`, color: votesLeft > 0 ? '#4A706B' : '#8C4A36', fontSize: '12px', fontWeight: 700, display: 'flex', alignItems: 'center', gap: '5px' }}>
              <Heart size={11} color={votesLeft > 0 ? '#4A706B' : '#8C4A36'} fill={votesLeft > 0 ? '#4A706B' : '#8C4A36'} />
              {votesLeft > 0 ? `${votesLeft} vote` : 'Habis'}
            </motion.div>
          </div>
        </div>

        {/* Tabs */}
        <div style={{ background: 'white', borderRadius: '12px', padding: '4px', marginBottom: '12px', border: '1.5px solid #E8E0D8', display: 'flex' }}>
          {(['terbaru', 'terpopuler'] as const).map((t) => (
            <button key={t} onClick={() => setTab(t)}
              style={{ flex: 1, height: '36px', borderRadius: '8px', border: 'none', background: tab === t ? '#97B3AE' : 'transparent', color: tab === t ? 'white' : '#B8C9C7', fontSize: '13px', fontWeight: 600, cursor: 'pointer', transition: 'all 0.2s', boxShadow: tab === t ? '0 3px 10px rgba(151,179,174,0.35)' : 'none' }}>
              {t === 'terbaru' ? 'Terbaru' : 'Terpopuler'}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      <div className="overflow-y-auto flex-1" style={{ padding: '0 20px 16px', scrollbarWidth: 'none' } as React.CSSProperties}>
        {loading ? (
          <><SkeletonCard /><SkeletonCard /><SkeletonCard /></>
        ) : (
          <>
            {sortedPosts.map((post, idx) => (
              <motion.div key={post.id} initial={{ opacity: 0, y: 14 }} animate={{ opacity: 1, y: 0 }} transition={{ delay: idx * 0.07 }}
                style={{ borderRadius: '16px', background: 'white', border: '1.5px solid #E8E0D8', overflow: 'hidden', marginBottom: '14px', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>

                {/* User row */}
                <div className="flex items-center justify-between px-4 py-3" style={{ cursor: 'pointer' }} onClick={() => navigate(`/post/${post.id}`)}>
                  <div className="flex items-center gap-3">
                    <div style={{ width: '38px', height: '38px', borderRadius: '50%', background: post.avatarBg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '12px', fontWeight: 800, color: post.avatarText, flexShrink: 0 }}>
                      {post.initial}
                    </div>
                    <div>
                      <p style={{ color: '#2C3A37', fontSize: '13px', fontWeight: 600 }}>{post.user}</p>
                      <p style={{ color: '#C4D0CE', fontSize: '11px' }}>{post.time}</p>
                    </div>
                  </div>
                  <div style={{ padding: '3px 10px', borderRadius: '20px', background: 'rgba(151,179,174,0.1)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Camera size={10} color="#97B3AE" />
                    <span style={{ color: '#97B3AE', fontSize: '11px', fontWeight: 500 }}>Lingkaran</span>
                  </div>
                </div>

                {/* Photo — full tap area */}
                <motion.div whileTap={{ opacity: 0.9 }} onClick={() => navigate(`/post/${post.id}`)}
                  style={{ position: 'relative', aspectRatio: '4/3', overflow: 'hidden', cursor: 'pointer' }}>
                  <img src={post.image} alt={post.caption}
                    style={{ width: '100%', height: '100%', objectFit: 'cover', filter: post.reported ? 'blur(14px) saturate(0)' : 'none', transition: 'filter 0.3s' }} />
                  {post.reported && (
                    <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', gap: '8px', background: 'rgba(240,238,234,0.65)' }}>
                      <Flag size={28} color="#9EAEAD" />
                      <p style={{ color: '#627370', fontSize: '13px', fontWeight: 600 }}>Konten dilaporkan</p>
                      <p style={{ color: '#B8C9C7', fontSize: '11px' }}>Sedang ditinjau moderator</p>
                    </div>
                  )}
                  {/* Vote count overlay */}
                  <div style={{ position: 'absolute', bottom: '10px', right: '10px', padding: '4px 10px', borderRadius: '20px', background: 'rgba(255,255,255,0.88)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Heart size={12} color={post.voted ? '#E07B65' : '#D6CBBF'} fill={post.voted ? '#E07B65' : 'transparent'} />
                    <span style={{ color: '#2C3A37', fontSize: '12px', fontWeight: 700 }}>{post.votes}</span>
                  </div>
                </motion.div>

                {/* Caption + Actions */}
                <div style={{ padding: '10px 16px 12px' }}>
                  <p style={{ color: '#627370', fontSize: '13px', lineHeight: 1.5, marginBottom: '10px' }}>{post.caption}</p>
                  <div className="flex items-center justify-between">
                    <motion.button whileTap={{ scale: 1.2 }} onClick={() => handleVote(post.id)}
                      style={{ border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px', padding: '7px 14px', borderRadius: '20px', background: post.voted ? 'rgba(242,195,185,0.18)' : 'rgba(240,238,234,0.8)', transition: 'background 0.2s' }}>
                      <motion.div key={post.voted ? 'voted' : 'unvoted'} initial={{ scale: 1.4 }} animate={{ scale: 1 }}>
                        <Heart size={19} color={post.voted ? '#E07B65' : '#D6CBBF'} fill={post.voted ? '#E07B65' : 'transparent'} />
                      </motion.div>
                      <span style={{ color: post.voted ? '#E07B65' : '#B8C9C7', fontSize: '13px', fontWeight: 600 }}>{post.votes}</span>
                    </motion.button>

                    <div className="flex items-center gap-2">
                      <button onClick={() => !post.reported && setReportId(post.id)}
                        style={{ width: '38px', height: '38px', borderRadius: '10px', background: post.reported ? 'rgba(242,195,185,0.15)' : '#FAFAF8', border: `1.5px solid ${post.reported ? '#F2C3B9' : '#E8E0D8'}`, display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: post.reported ? 'default' : 'pointer' }}>
                        <Flag size={14} color={post.reported ? '#E07B65' : '#D6CBBF'} fill={post.reported ? '#F2C3B9' : 'none'} />
                      </button>
                      <motion.button whileTap={{ scale: 0.95 }} onClick={() => handleVote(post.id)}
                        style={{ padding: '9px 18px', borderRadius: '10px', border: 'none', background: post.voted ? 'rgba(242,195,185,0.15)' : votesLeft > 0 ? '#97B3AE' : '#F0EEEA', color: post.voted ? '#E07B65' : votesLeft > 0 ? 'white' : '#C4D0CE', fontSize: '13px', fontWeight: 700, cursor: !post.voted && votesLeft <= 0 ? 'not-allowed' : 'pointer', transition: 'all 0.2s', boxShadow: !post.voted && votesLeft > 0 ? '0 4px 12px rgba(151,179,174,0.35)' : 'none' }}>
                        {post.voted ? 'Voted ✓' : 'Vote'}
                      </motion.button>
                    </div>
                  </div>
                </div>
              </motion.div>
            ))}

            {/* Load more indicator */}
            <motion.button whileTap={{ scale: 0.97 }} onClick={() => showT('Memuat lebih banyak...', 'info')}
              className="w-full flex items-center justify-center gap-2 py-3"
              style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: '#B8C9C7', fontSize: '13px', fontWeight: 600 }}>
              <ChevronDown size={16} color="#C4D0CE" />
              Muat lebih banyak
            </motion.button>
          </>
        )}
      </div>

      <AnimatePresence>
        {reportId !== null && <ReportSheet onClose={() => setReportId(null)} onConfirm={handleReport} />}
      </AnimatePresence>

      <style>{`
        @keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }
      `}</style>
    </div>
  );
}
