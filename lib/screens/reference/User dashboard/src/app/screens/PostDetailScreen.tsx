import { useState, useRef } from 'react';
import { useNavigate, useParams } from 'react-router';
import { ArrowLeft, Heart, Flag, Share2, Star, Camera, Trophy, BookmarkPlus, Bookmark } from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { Toast } from '../components/Toast';

const IMGS = {
  C: 'https://images.unsplash.com/photo-1753469805532-537f677c27b4?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjaXJjdWxhciUyMHJvdW5kJTIwc2hhcGVzJTIwcGhvdG9ncmFwaHl8ZW58MXx8fHwxNzc3MDMzNzA5fDA&ixlib=rb-4.1.0&q=80&w=1080',
  S: 'https://images.unsplash.com/photo-1556620286-5e892be0cfbb?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxjb2xvcmZ1bCUyMHN0cmVldCUyMHBob3RvZ3JhcGh5JTIwdXJiYW58ZW58MXx8fHwxNzc3MDMzNzEwfDA&ixlib=rb-4.1.0&q=80&w=1080',
  N: 'https://images.unsplash.com/photo-1730626476382-5f18297a30b9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxuYXR1cmUlMjB0ZXh0dXJlJTIwY2xvc2UlMjB1cCUyMG1hY3JvfGVufDF8fHx8MTc3NzAzMzcxMHww&ixlib=rb-4.1.0&q=80&w=1080',
  P: 'https://images.unsplash.com/photo-1554454188-f84071b1695f?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxwb3J0cmFpdCUyMHBlcnNvbiUyMHNtaWxpbmclMjBwaG90b2dyYXBoeXxlbnwxfHx8fDE3NzcwMzM3MTF8MA&ixlib=rb-4.1.0&q=80&w=1080',
  A: 'https://images.unsplash.com/photo-1544730786-12cad2dccc97?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w3Nzg4Nzd8MHwxfHNlYXJjaHwxfHxhYnN0cmFjdCUyMGxpZ2h0JTIwYm9rZWglMjBkYXJrfGVufDF8fHx8MTc3NzAzMzcxMXww&ixlib=rb-4.1.0&q=80&w=1080',
};

const POSTS: Record<string, { img: string; user: string; initial: string; bg: string; textColor: string; caption: string; votes: number; challenge: string; date: string; rank: number; won: boolean }> = {
  '1': { img: IMGS.C, user: 'citra_lens',   initial: 'CL', bg: '#97B3AE', textColor: '#2C5450', caption: 'Nemuin ban sepeda tua di pojok gang, ternyata jadi objek yang menarik!',   votes: 42,  challenge: 'Foto sesuatu berbentuk lingkaran', date: '24 Apr 2025', rank: 4, won: false },
  '2': { img: IMGS.S, user: 'budi_foto',    initial: 'BF', bg: '#F2C3B9', textColor: '#8C4A36', caption: 'Roda gerobak pedagang keliling! Penuh warna dan cerita',                  votes: 89,  challenge: 'Warna Merah',  date: '23 Apr 2025', rank: 1, won: true  },
  '3': { img: IMGS.N, user: 'dian_capture', initial: 'DC', bg: '#D2E0D3', textColor: '#3D6645', caption: 'Lingkaran tahun pohon dari hutan pinus yang sudah tumbang',               votes: 156, challenge: 'Tekstur Alam', date: '22 Apr 2025', rank: 1, won: true  },
  '4': { img: IMGS.P, user: 'alex_pras',    initial: 'AP', bg: '#97B3AE', textColor: '#2C5450', caption: 'Senyum itu juga bentuk lengkung, bukan?',                                  votes: 67,  challenge: 'Potret',       date: '21 Apr 2025', rank: 3, won: false },
  '5': { img: IMGS.A, user: 'fani_click',   initial: 'FC', bg: '#D6CBBF', textColor: '#5E4A36', caption: 'Bokeh lampu malam hari menciptakan lingkaran cahaya yang dreamy',          votes: 21,  challenge: 'Cahaya & Bayangan', date: '20 Apr 2025', rank: 7, won: false },
};

const RELATED = [
  { id: '1', img: IMGS.C, votes: 42 }, { id: '3', img: IMGS.N, votes: 156 },
  { id: '4', img: IMGS.P, votes: 67 }, { id: '5', img: IMGS.A, votes: 21 },
];

function HeartBurst({ x, y }: { x: number; y: number }) {
  return (
    <motion.div initial={{ scale: 0, opacity: 1, x, y }} animate={{ scale: 2.5, opacity: 0, y: y - 60 }} transition={{ duration: 0.6 }}
      style={{ position: 'absolute', pointerEvents: 'none', zIndex: 50, top: 0, left: 0 }}>
      <Heart size={48} color="#E07B65" fill="#E07B65" />
    </motion.div>
  );
}

export function PostDetailScreen() {
  const navigate = useNavigate();
  const { id }   = useParams<{ id: string }>();
  const post = POSTS[id ?? '1'] ?? POSTS['1'];

  const [voted,    setVoted]    = useState(false);
  const [votes,    setVotes]    = useState(post.votes);
  const [saved,    setSaved]    = useState(false);
  const [imgLoaded,setImgLoaded]= useState(false);
  const [burst,    setBurst]    = useState<{ x: number; y: number } | null>(null);
  const [toast, setToast]       = useState<{ msg: string; type: 'success' | 'error' | 'info' | 'warning' } | null>(null);
  const lastTap = useRef(0);

  const showT = (msg: string, type: 'success' | 'error' | 'info' | 'warning' = 'info') => {
    setToast({ msg, type });
    setTimeout(() => setToast(null), 2500);
  };

  const handleVote = () => {
    if (voted) { setVoted(false); setVotes(v => v - 1); }
    else       { setVoted(true);  setVotes(v => v + 1); showT('+1 vote dikirim!', 'success'); }
  };

  const handleDoubleTap = (e: React.MouseEvent) => {
    const now = Date.now();
    if (now - lastTap.current < 350) {
      const rect = (e.currentTarget as HTMLDivElement).getBoundingClientRect();
      setBurst({ x: e.clientX - rect.left - 24, y: e.clientY - rect.top - 24 });
      setTimeout(() => setBurst(null), 700);
      if (!voted) { setVoted(true); setVotes(v => v + 1); showT('+1 vote! ', 'success'); }
    }
    lastTap.current = now;
  };

  return (
    <div style={{ height: '800px', background: '#F0EEEA', display: 'flex', flexDirection: 'column', overflow: 'hidden', position: 'relative' }}>
      <AnimatePresence>{toast && <Toast message={toast.msg} type={toast.type} onDismiss={() => setToast(null)} />}</AnimatePresence>

      {/* Top bar */}
      <div style={{ padding: '14px 20px', display: 'flex', alignItems: 'center', gap: '12px', flexShrink: 0, background: 'white', borderBottom: '1px solid #F0EEEA' }}>
        <button onClick={() => navigate(-1)}
          style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer', flexShrink: 0 }}>
          <ArrowLeft size={20} color="#627370" />
        </button>
        <div className="flex-1">
          <p style={{ color: '#2C3A37', fontSize: '16px', fontWeight: 700 }}>Detail Foto</p>
          <p style={{ color: '#B8C9C7', fontSize: '12px' }}>{post.challenge}</p>
        </div>
        <button onClick={() => { setSaved(!saved); showT(saved ? 'Dihapus dari simpanan' : 'Disimpan ke koleksimu!', saved ? 'info' : 'success'); }}
          style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <motion.div animate={{ scale: saved ? [1, 1.3, 1] : 1 }} transition={{ duration: 0.3 }}>
            {saved ? <Bookmark size={18} color="#97B3AE" fill="#97B3AE" /> : <BookmarkPlus size={18} color="#C4D0CE" />}
          </motion.div>
        </button>
        <button onClick={() => showT('Link disalin ke clipboard!', 'success')}
          style={{ width: '44px', height: '44px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
          <Share2 size={18} color="#C4D0CE" />
        </button>
      </div>

      <div className="flex-1 overflow-y-auto" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
        {/* Photo with double-tap */}
        <div style={{ margin: '16px 20px 0', borderRadius: '20px', overflow: 'hidden', background: '#E8E0D8', position: 'relative' }}
          onClick={handleDoubleTap}>
          {!imgLoaded && (
            <div style={{ position: 'absolute', inset: 0, background: 'linear-gradient(90deg, #F0EEEA 0%, #E2EDE9 50%, #F0EEEA 100%)', backgroundSize: '200% 100%', animation: 'shimmer 1.4s infinite', borderRadius: '20px' }} />
          )}
          <img src={post.img} alt="" onLoad={() => setImgLoaded(true)}
            style={{ width: '100%', aspectRatio: '4/3', objectFit: 'cover', display: 'block', opacity: imgLoaded ? 1 : 0, transition: 'opacity 0.4s' }} />

          <AnimatePresence>
            {burst && <HeartBurst x={burst.x} y={burst.y} />}
          </AnimatePresence>

          {post.won && (
            <div style={{ position: 'absolute', top: '12px', left: '12px', padding: '5px 12px', borderRadius: '20px', background: '#F2C3B9', display: 'flex', alignItems: 'center', gap: '5px' }}>
              <Trophy size={12} color="white" />
              <span style={{ color: 'white', fontSize: '11px', fontWeight: 700 }}>Pemenang Challenge</span>
            </div>
          )}
          <div style={{ position: 'absolute', bottom: '10px', right: '10px', padding: '4px 10px', borderRadius: '20px', background: 'rgba(255,255,255,0.88)', backdropFilter: 'blur(6px)', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <span style={{ color: '#9EAEAD', fontSize: '10px' }}>Ketuk 2x untuk vote</span>
          </div>
        </div>

        {/* Info card */}
        <div style={{ margin: '12px 20px 0', padding: '16px', borderRadius: '16px', background: 'white', border: '1.5px solid #E8E0D8', boxShadow: '0 2px 10px rgba(44,58,55,0.06)' }}>
          <div className="flex items-center justify-between mb-3">
            <div className="flex items-center gap-3">
              <div style={{ width: '46px', height: '46px', borderRadius: '50%', background: post.bg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: '14px', fontWeight: 800, color: post.textColor, flexShrink: 0 }}>
                {post.initial}
              </div>
              <div>
                <p style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 700 }}>{post.user}</p>
                <p style={{ color: '#B8C9C7', fontSize: '12px' }}>{post.date}</p>
              </div>
            </div>
            <div style={{ padding: '5px 10px', borderRadius: '20px', background: 'rgba(151,179,174,0.1)', border: '1px solid rgba(151,179,174,0.35)', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Trophy size={11} color="#97B3AE" />
              <span style={{ color: '#4A706B', fontSize: '12px', fontWeight: 600 }}>Rank #{post.rank}</span>
            </div>
          </div>

          <div className="flex items-center gap-2 mb-3 pb-3" style={{ borderBottom: '1px solid #F0EEEA' }}>
            <Camera size={13} color="#97B3AE" />
            <span style={{ color: '#9EAEAD', fontSize: '13px' }}>Challenge:</span>
            <span style={{ color: '#4A706B', fontSize: '13px', fontWeight: 600 }}>{post.challenge}</span>
          </div>

          <p style={{ color: '#627370', fontSize: '14px', lineHeight: 1.7, marginBottom: '14px' }}>{post.caption}</p>

          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Star size={14} color="#E07B65" fill="#E07B65" />
              <span style={{ color: '#2C3A37', fontSize: '18px', fontWeight: 800 }}>{votes}</span>
              <span style={{ color: '#B8C9C7', fontSize: '13px' }}>votes</span>
            </div>
            <div className="flex items-center gap-2">
              <button onClick={() => showT('Laporan terkirim. Terima kasih!', 'success')}
                style={{ width: '42px', height: '42px', borderRadius: '12px', background: '#FAFAF8', border: '1.5px solid #E8E0D8', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}>
                <Flag size={15} color="#D6CBBF" />
              </button>
              <motion.button whileTap={{ scale: 0.92 }} onClick={handleVote}
                style={{ padding: '11px 24px', borderRadius: '12px', border: 'none', background: voted ? 'rgba(242,195,185,0.18)' : '#97B3AE', color: voted ? '#E07B65' : 'white', fontSize: '14px', fontWeight: 700, cursor: 'pointer', transition: 'all 0.2s', display: 'flex', alignItems: 'center', gap: '6px', boxShadow: voted ? 'none' : '0 4px 14px rgba(151,179,174,0.4)' }}>
                <motion.div key={String(voted)} initial={{ scale: 1.3 }} animate={{ scale: 1 }}>
                  <Heart size={16} color={voted ? '#E07B65' : 'white'} fill={voted ? '#E07B65' : 'white'} />
                </motion.div>
                {voted ? 'Voted' : 'Vote'}
              </motion.button>
            </div>
          </div>
        </div>

        {/* Related */}
        <div style={{ padding: '20px 20px 8px' }}>
          <div className="flex items-center gap-2 mb-3">
            <div style={{ width: '3px', height: '16px', borderRadius: '2px', background: 'linear-gradient(to bottom, #97B3AE, #D2E0D3)', flexShrink: 0 }} />
            <h3 style={{ color: '#2C3A37', fontSize: '15px', fontWeight: 700 }}>Foto Lain di Challenge Ini</h3>
          </div>
          <div className="flex gap-3 overflow-x-auto pb-2" style={{ scrollbarWidth: 'none' } as React.CSSProperties}>
            {RELATED.filter(r => r.id !== id).map((rel) => (
              <motion.div key={rel.id} whileTap={{ scale: 0.96 }} onClick={() => navigate(`/post/${rel.id}`)}
                style={{ flexShrink: 0, width: '112px', height: '112px', borderRadius: '14px', overflow: 'hidden', cursor: 'pointer', position: 'relative', border: '1.5px solid #E8E0D8' }}>
                <img src={rel.img} alt="" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
                <div style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: '6px 8px', background: 'linear-gradient(to top, rgba(44,58,55,0.5), transparent)', display: 'flex', alignItems: 'center', gap: '3px' }}>
                  <Heart size={10} color="white" fill="white" />
                  <span style={{ color: 'white', fontSize: '11px', fontWeight: 700 }}>{rel.votes}</span>
                </div>
              </motion.div>
            ))}
          </div>
        </div>
        <div style={{ height: '20px' }} />
      </div>

      <style>{`@keyframes shimmer { 0% { background-position: -200% 0; } 100% { background-position: 200% 0; } }`}</style>
    </div>
  );
}
